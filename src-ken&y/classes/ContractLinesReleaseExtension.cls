public with sharing class ContractLinesReleaseExtension extends BaseController {
    ApexPages.StandardController con;
    public static string NspaceUU { get { return KSE.NamespaceUU; }} 
    private static SchemaUtil util = SchemaUtil.getInstance();
    public GridRelatedListController.GridRelatedListConfig contractLinesConfig {get; set;}
    public GridRelatedListController.GridRelatedListConfig releaseLinesConfig {get; set;}   
    public String contractLinesFieldList = null;
    public String releaseLinesFieldList = null;
    public Id defaultCompany{ get; set;}
    public Id defaultFacility{ get; set;}
    public List<ContractLineWrapper> cLinesForReleaseList { get;set; }
    public String previousPage { get; set; }
    public GridRelatedListController.GridRelatedListConfig sourcingPolicyConfig {get; set;}
    public String sourcingPolicyFieldList = null;
    public string HelpURL{get;set;}
       
    public map<string,string> queryMapSP{get;set;}
    public string spQuery{get;set;}
    public string spQueryCondition{get;set;}
    
    public map<string,string> queryMapPAL{get;set;}
    public string palQuery{get;set;}
    public string palQueryCondition{get;set;}
    public Id purchaseFromRT{get;set;}
    public boolean showSourcingGrid {get; set;}

    public ContractLinesReleaseExtension(ApexPages.StandardController controller) {
        
        con = controller;
        showSourcingGrid = ContractService.showHideSourcingGrid();
        previousPage = ApexPages.currentPage().getHeaders().get('Referer');
        HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpAgreementRelease';
        List<User_Preference__c> u = [select id, Default_Company__c, Default_Facility__c from User_Preference__c where ownerId = :UserInfo.getUserID() limit 1];    
        if (u.size() > 0){
            if (u[0].Default_Company__c != null)
                defaultCompany = u[0].Default_Company__c;
            if (u[0].Default_Facility__c != null)
                defaultFacility = u[0].Default_Facility__c;
        }       
        purchaseFromRT = KSE.RecordTypeDevNameMap('Supplier__c').get('Purchase_From');
        
        // Contract Lines Grid config
        contractLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        contractLinesConfig.uniqueId = 'ContractLinesGrid';
        contractLinesConfig.title = 'Contract Lines';
        contractLinesConfig.objectName = 'Contract_Line__c';
        contractLinesConfig.fieldset = 'Line_Release';
        contractLinesConfig.buttons = 'cancel, search';
        contractLinesConfig.alwaysUseFullDateTimeFormat = false;
        
        // Release Lines Grid config
        releaseLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        releaseLinesConfig.uniqueId = 'ReleaseLinesGrid';
        releaseLinesConfig.title = 'Release Lines';
        releaseLinesConfig.objectName = 'Contract_Line__c';
        releaseLinesConfig.fieldset = 'Line_Release';
        releaseLinesConfig.buttons = 'cancel, delete, search';
        releaseLinesConfig.alwaysUseFullDateTimeFormat = false;
        
        //sourcing policy Grid config
        sourcingPolicyConfig = new GridRelatedListController.GridRelatedListConfig();
        sourcingPolicyConfig.uniqueId = 'SourcingPolicyGrid';
        sourcingPolicyConfig.title = 'Sourcing Policy';
        sourcingPolicyConfig.objectName = 'Item_Cross_Reference__c';
        sourcingPolicyConfig.fieldset = 'Sourcing_Policy_Agreement_Release';
        sourcingPolicyConfig.buttons = 'search';
        sourcingPolicyConfig.alwaysUseFullDateTimeFormat = false;
        
        queryMapSP = getItemCrossReferenceQuery();
        spQuery = queryMapSP.get('Query');
        spQueryCondition = queryMapSP.get('Condition');
        
        queryMapPAL = getContractLinesQuery();
        palQuery = queryMapPAL.get('Query');
        palQueryCondition = queryMapPAL.get('Condition');
    }
    
    public String getContractLinesConfigJson() {
        String configStr = JSON.serialize(this.contractLinesConfig);
          
        return configStr;
    }
    
    public string getContractLinesFieldList() {
        if (contractLinesFieldList == null && contractLinesConfig != null) {
            FieldInfo fieldInfoItem;
            // get the contract lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(contractLinesConfig.objectName, contractLinesConfig.fieldset);
            Set<String> hiddenFields = new Set<String> { 'Id' };
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                //fieldInfoList[i].field = 'ctLine.' + fieldName;
                fieldInfoList[i].field = fieldName;
                fieldInfoList[i].editable = false;
                fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
                if (KSE.FieldUsedtoReleasePO == 'Available_Quantity__c' && fieldName == 'Remaining_Quantity__c')
                    fieldInfoList[i].hidden = true;
                if (KSE.FieldUsedtoReleasePO == 'Remaining_Quantity__c' && fieldName == 'Available_Quantity__c')
                    fieldInfoList[i].hidden = true;
            }
            
            // set the need date and quantity fields as editable
            fieldInfoItem = new FieldInfo('needDate', Label.NeedDate, 'date', false);
            fieldInfoItem.editable = true;
            fieldInfoItem.format = KendoUtils.DATE_FORMAT;           
            
            fieldInfoList.add(fieldInfoItem);
            
            fieldInfoItem = new FieldInfo('quantityToRelease', Label.Quantity, 'decimal', false);
            fieldInfoItem.editable = true;
            
            fieldInfoList.add(fieldInfoItem);
            
            contractLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return contractLinesFieldList;
    }
    
    public String getReleaseLinesConfigJson() {
        String configStr = JSON.serialize(this.releaseLinesConfig);
          
        return configStr;
    }
    
    public string getReleaseLinesFieldList() {
        if (releaseLinesFieldList == null && releaseLinesConfig != null) {
            List<FieldInfo> additionalFields = new List<FieldInfo>();
            Set<String> releaseLineFields = new Set<String>();
            
            try {
                additionalFields = FieldInfo.fetchJsonFieldInfos('Contract_Line__c', 'Line_Release_AdditionalFields');
            }
            catch (FieldInfo.EmptyFieldSetMemberException e) {
                // Comments By LK On 11/21
                // Ignore EmptyFieldSetMemberException. Need to revisit the this logic so the empty field set would return an empty array instead
            }
            
            FieldInfo fieldInfoItem;
            // get the contract lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(releaseLinesConfig.objectName, releaseLinesConfig.fieldset);
            Set<String> visibleFields = new Set<String> { 'Name', 'Item__c', 'Contract__c' };
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                fieldInfoList[i].field = fieldName;
                fieldInfoList[i].editable = false;
                fieldInfoList[i].hidden = !visibleFields.contains(fieldName);
                releaseLineFields.add(fieldInfoList[i].field);
            }
            
            // add any additional fields
            for(Integer i = 0; i < additionalFields.size(); i++){
                String fieldName = additionalFields[i].field;
                additionalFields[i].field = fieldName;
                
                if (!releaseLineFields.contains(additionalFields[i].field)) {
                    fieldInfoList.add(additionalFields[i]);
                }
            }
            
            // set the need date and quantity fields as editable
            fieldInfoItem = new FieldInfo('needDate', Label.NeedDate, 'date', false);
            fieldInfoItem.editable = false;
            fieldInfoItem.format = KendoUtils.DATE_FORMAT;
            
            fieldInfoList.add(fieldInfoItem);
            
            fieldInfoItem = new FieldInfo('quantityToRelease', Label.Quantity, 'decimal', false);
            fieldInfoItem.editable = false;
            
            fieldInfoList.add(fieldInfoItem);
            
            releaseLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return releaseLinesFieldList;
    }
    
    //@RemoteAction
    //public static JsonResult getContractLines(ID companyId, ID facilityId) {
    
    public map<string,string> getContractLinesQuery() {
        map<string,string> qryMap = new map<string,string>();
        String contractLinesQuery = null;
        Date tday = system.today();
        Integer count = 0;
        
        string whereClause = '';
        string conditionalClause = '';
        
        Id purchaseFromRT = KSE.RecordTypeDevNameMap('Supplier__c').get('Purchase_From');
        
        //:purchaseFromRT
        conditionalClause =  ' Status__c = \'Open\' and '+ KSE.FieldUsedtoReleasePO + '>0 and Contract__r.Approval_Status__c = \'Approved\' and Contract__r.Status__c = \'Open\' and Contract__r.Supplier__r.RecordTypeId = '+ '\''+purchaseFromRT+'\'' +' and Contract__r.Supplier__r.Hold_Purchasing__c = false and Contract__r.Company__c = ';
        //:companyId and Contract__r.Ship_to_Facility__c = :facilityId order by Line__c asc';
        
        contractLinesQuery = util.generateQueryFromFieldSet('Contract_Line__c', 
                        new set<string>{'Line_Release', 'Tiers'},
                        new set<string>{'Id','Line__c','UOM__c','Contract__r.Company__c','Contract_Quantity__c', 'Location__c', 'Quantity_Still_Due__c', 'Invoice_Matching__c',
                            'Purchased_Quantity__c', 'PurchasedValue__c','Quantity_Received__c','Remaining_Quantity__c','Available_Quantity__c','Remaining_Value__c','Remaining_Value_Percent__c','Status__c',
                            'ValueReceived__c','Contract__r.Payment_Term__c', 'Contract__r.Payment_Term__r.id', 'Contract__r.FOB_Term__c', 'Contract__r.FOB_Term__r.id', 'Item__c', 'Item__r.Description__c', 'Contract__r.Supplier__c', 'Contract__r.Supplier__r.Invoice_Matching__c',
                            'Item__r.Buyer_Planner__c','Item__r.Purchasing_UOM__c', 'Contract__r.Transportation_Mode__c', 'Consigned__c', 'Type__c','Contract__r.Contract_Number__c', 'Contract__r.Supplier__c','Contract__c','Contract__r.Supplier__r.Remit_To__c',
                            'Contract__r.Unit_Price_Tolerance_Over__c','Contract__r.Quantity_Tolerance_Over__c','Contract__r.Amount_Tolerance__c','Contract__r.Supplier__r.Default_Receiving_Tolerance__c','Contract__r.Company__r.Default_Transaction_Currency__c', 'Contract__r.Currency__c'},
                         whereClause);
            
        qryMap.put('Query',contractLinesQuery);
        qryMap.put('Condition',conditionalClause);

        
        return qryMap;
    }
    
    // wrapper class to hold the contract line to pass the information    
    public class ContractLineWrapper{
        
        public Contract_Line__c ctLine { get; set;}
        public Date needDate { get; set;}
        public Decimal quantityToRelease = 0.0;
                
        public ContractLineWrapper(){
            this.ctLine = new Contract_Line__c(); 
             
        }   
    }  
    
    public pageReference addRowForRelease(ContractLineWrapper contractLineForRelease) {
        this.cLinesForReleaseList.add(contractLineForRelease);
        
        return null;
    }
    
    /*
        Given a contract line (wrappers) and quantity to release, find the tier that it falls under and return the 
        matching unit price
        TODO Need to bulkify this once UI is ready based on how the qty will be captured in the wrapper
    */
    public static Double getUnitPriceBasedOnTiers(ContractLineWrapper contractLineForRelease, Decimal quantityGiven){
        Double unitPriceBasedOnTier = 0.0;
        Contract_Line__c cLine = contractLineForRelease.ctLine; 
        if (cLine.Type__c == 'Tiered'){
            //KNDY-2300 Replacing the Mins with previous tier's max values, we can infer the mins via this way
            //KNDY-4376 
            if ((quantityGiven > cLine.Tier_9_Max__c && quantityGiven <= cLine.Tier_10_Max__c) || (quantityGiven > cLine.Tier_10_Max__c && (cLine.Tier_10_Max__c != null && cLine.Tier_10_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_10_Price__c; //test fails as it gets this price due to or condition above
            else if ((quantityGiven > cLine.Tier_8_Max__c && quantityGiven <= cLine.Tier_9_Max__c)|| (quantityGiven > cLine.Tier_9_Max__c && (cLine.Tier_9_Max__c != null && cLine.Tier_9_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_9_Price__c;
            else if ((quantityGiven > cLine.Tier_7_Max__c && quantityGiven <= cLine.Tier_8_Max__c)|| (quantityGiven > cLine.Tier_8_Max__c && (cLine.Tier_8_Max__c != null && cLine.Tier_8_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_8_Price__c;       
            else if ((quantityGiven > cLine.Tier_6_Max__c && quantityGiven <= cLine.Tier_7_Max__c)|| (quantityGiven > cLine.Tier_7_Max__c && (cLine.Tier_7_Max__c != null && cLine.Tier_7_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_7_Price__c;
            else if ((quantityGiven > cLine.Tier_5_Max__c && quantityGiven <= cLine.Tier_6_Max__c)|| (quantityGiven > cLine.Tier_6_Max__c && (cLine.Tier_6_Max__c != null && cLine.Tier_6_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_6_Price__c;
            else if ((quantityGiven > cLine.Tier_4_Max__c && quantityGiven <= cLine.Tier_5_Max__c) || (quantityGiven > cLine.Tier_5_Max__c && (cLine.Tier_5_Max__c != null && cLine.Tier_5_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_5_Price__c;
            else if ((quantityGiven > cLine.Tier_3_Max__c && quantityGiven <= cLine.Tier_4_Max__c) || (quantityGiven > cLine.Tier_4_Max__c && (cLine.Tier_4_Max__c != null && cLine.Tier_4_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_4_Price__c;
            else if ((quantityGiven > cLine.Tier_2_Max__c && quantityGiven <= cLine.Tier_3_Max__c)|| (quantityGiven > cLine.Tier_3_Max__c && (cLine.Tier_3_Max__c != null && cLine.Tier_3_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_3_Price__c;
            else if ((quantityGiven > cLine.Tier_1_Max__c && quantityGiven <= cLine.Tier_2_Max__c)|| (quantityGiven > cLine.Tier_2_Max__c && (cLine.Tier_2_Max__c != null && cLine.Tier_2_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_2_Price__c;
            else if ((quantityGiven >= 0 && quantityGiven <= cLine.Tier_1_Max__c)|| (quantityGiven > cLine.Tier_1_Max__c && (cLine.Tier_1_Max__c != null && cLine.Tier_1_Max__c != 0)))
                unitPriceBasedOnTier = cLine.Tier_1_Price__c;
        } else 
            unitPriceBasedOnTier = KSE.addQuantityToField(cLine.Negotiated_Price__c, 0);
        
        return unitPriceBasedOnTier; 
    }
    
    @RemoteAction
    public static JsonResult release(ID companyId, ID facilityId, String contractLinesForRelease, String contractLinesWithAllFields, List<String> dateFields) {
        
        // creating the Contract Lines Wrapper
        List<ContractLineWrapper> ctLineWrapperList = new List<ContractLineWrapper>();
        List<Contract_Line__c> ctLineRecords = null;
        
        // To get the Contract Line Records from the string
        ctLineRecords = (List<Contract_Line__c>)JSON.deserialize(contractLinesForRelease, List<Contract_Line__c>.class);
        
        // To fetch the necessary fields - like NeedDate & quantityToRelease
        List<Object> ctLineDataList  = (List<Object>) JSON.deserializeUntyped(contractLinesWithAllFields);

        for(integer index=0; index < ctLineDataList.size(); ++index){
           Map<String, Object> ctLineDataListObject = (Map<String, Object>)ctLineDataList[index];
            for(Contract_Line__c ctLineObj : ctLineRecords){
                ContractLineWrapper ctLineWrapper = new ContractLineWrapper();
                if(ctLineObj.Id == (Id)ctLineDataListObject.get('Id')){
                  
                    ctLineWrapper.ctLine = ctLineObj;
                    Contract__c ctLineContract  = (Contract__c)JSON.deserializeStrict(JSON.serialize(ctLineDataListObject.get(KSE.NamespaceUU+'Contract__r')),Contract__c.class);
                    ctLineWrapper.ctLine.Contract__r =  ctLineContract;
                    
                    Map<String, Object> ctLineContractData =  (Map<String, Object>)ctLineDataListObject.get(KSE.NamespaceUU+'Contract__r');
                    
                    Payment_Term__c  ctLinePymtTerm  = (Payment_Term__c)JSON.deserializeStrict(JSON.serialize(ctLineContractData.get(KSE.NamespaceUU+'Payment_Term__r')),Payment_Term__c.class);
                    ctLineWrapper.ctLine.Contract__r.Payment_Term__r =  ctLinePymtTerm;
                   
                    Supplier__c  ctLineSupplier  = (Supplier__c)JSON.deserializeStrict(JSON.serialize(ctLineContractData.get(KSE.NamespaceUU+'Supplier__r')),Supplier__c.class);
                    ctLineWrapper.ctLine.Contract__r.Supplier__r =  ctLineSupplier;
                    
                    Item__c ctLineItem = (Item__c)JSON.deserializeStrict(JSON.serialize(ctLineDataListObject.get(KSE.NamespaceUU+'Item__r')),Item__c.class);
                    ctLineWrapper.ctLine.Item__r =  ctLineItem;
                    String needDateStr =  (String)ctLineDataListObject.get('needDate'); 
                    ctLineWrapper.needDate = Date.valueOf(needDateStr);
                    ctLineWrapper.quantityToRelease = Decimal.valueof(String.valueof(ctLineDataListObject.get('quantityToRelease')));
                    
                    ctLineWrapperList.add(ctLineWrapper); 
                    //System.debug(logginglevel.info,ctLineWrapperList);
                    
                }
            } 
         }
           

       //to handle the null date/datetime fields coming from a remoting call  
       for (ContractLineWrapper ctLineWrapper: ctLineWrapperList) { 
            KendoUtils.UpdateDateFields(ctLineWrapper.ctLine, dateFields);
        
            if (ctLineWrapper.needDate == Date.newInstance(0,0,0)) {
                ctLineWrapper.needDate = null;
            }
        }
        
       return releaseContractLines(companyId, facilityId, ctLineWrapperList); 
    }
    
    public static JsonResult releaseContractLines(ID companyId, ID facilityId, List<ContractLineWrapper> ctLineWrapperList) {
        JsonResult result = new JsonResult();
        List<Purchase_Order_Line__c> POLList = new List<Purchase_Order_Line__c>();
        List<Contract_Line__c> ctLineObjList = new List<Contract_Line__c>();
        Map<String, List<ContractLineWrapper>> uniquePOKeysMap = new  Map<String, List<ContractLineWrapper>>();
        Map<ID, Facility__c> facilityMap = new Map<ID, Facility__c>();
        Map<ID, Company__c> compmap = new Map<ID, Company__c>();
        set<Id> itemIds = new set<Id>(); //KNDY-6594
        
        for (Company__c c: [select ID, Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__c, Default_Purchasing_Deliver_To_Facility__c 
                            from Company__c
                            where ID = :companyId]) {
            compmap.put(c.ID, c);
        }
        
        for (Facility__c f: [select ID, Default_Purchasing_Delivery_Location__c 
                            from Facility__c
                            where Company__c = :companyId]) {
            facilityMap.put(f.ID, f);
        }
        
        /*
            Each combination of Supplier, Facility, FOB terms, payment terms and Trans Mode will result in a unique PO created from this release
        */
        for (ContractLineWrapper ctLineWrapper: ctLineWrapperList) {
            itemIds.add(ctLineWrapper.ctLine.Item__c); //Collecting Item Ids to pass to Costing service
            //TODO need to add checks here for qty check and need date check for release
            Decimal qtyToVerify = 0;
            if (KSE.FieldUsedtoReleasePO == 'Remaining_Quantity__c')
                qtyToVerify = ctLineWrapper.ctLine.Remaining_Quantity__c;
            else
                qtyToVerify = ctLineWrapper.ctLine.Available_Quantity__c;
            
            if (ctLineWrapper.quantityToRelease <= qtyToVerify){
                if (ctLineWrapper.needDate == null) {
                    result.addMessage(Label.Need_Date_is_required_for_contract + ctLineWrapper.ctLine.Name, ApexPages.Severity.ERROR);
                }
                else {
                    //if (needdate is outside of date range)
                    Date convertedNeedDate = ctLineWrapper.needDate; //KNDY-4377
                    Date contractStartDate = Datetime.newInstance(ctLineWrapper.ctLine.Contract_Start__c.year(), ctLineWrapper.ctLine.Contract_Start__c.month(), ctLineWrapper.ctLine.Contract_Start__c.day()).date();
                    Date contractEndDate = Datetime.newInstance(ctLineWrapper.ctLine.Contract_End__c.year(), ctLineWrapper.ctLine.Contract_End__c.month(), ctLineWrapper.ctLine.Contract_End__c.day()).date();
    
                    if (convertedNeedDate >= contractStartDate && convertedNeedDate <= contractEndDate){
                    
                        //building unique key combination for generating unique POs
                        String uniqueKey = ctLineWrapper.ctLine.Contract__r.Contract_Number__c + convertedNeedDate; //KNDY-3259
                        if (uniquePOKeysMap.containsKey(uniqueKey)){
                            uniquePOKeysMap.get(uniqueKey).add(ctLineWrapper);
                        }else{
                            uniquePOKeysMap.put(uniqueKey, new List<ContractLineWrapper> {ctLineWrapper});
                        }
                    }else{
                        result.addMessage(Label.Need_Date_should_fall_within_start_and_end_dates + ctLineWrapper.ctLine.Name, ApexPages.Severity.ERROR);
                    }
                }
            }else{
                //KNDY-8415
                if(ctLineWrapper.quantityToRelease != null){
                //TODO build a list of failures 'CTLine cannot be release: ctline.Line__c
                result.addMessage(Label.You_cannot_release_more_than_remaining_quantity + ctLineWrapper.ctLine.Name, ApexPages.Severity.ERROR);
                }else{
                    result.addMessage(Label.Order_Quantity_cannot_be_null_or_empty + ctLineWrapper.ctLine.Name, ApexPages.Severity.ERROR);
                }  
            }
                    
        }
        if (result.messages.size() > 0){
            result.success = false;
        }else {
            
            // TODO the below pieces would need to be moved out into a service class and have MRP call it while doing a release
            Map<String, Purchase_Order__c> mapOfUniqueKeyToPO = new Map<String, Purchase_Order__c>();
            Map<String, List<Purchase_Order_Line__c>> mapOfUniqueKeyToPOLines = new Map<String, List<Purchase_Order_Line__c>>();
                    
                
            for (String uKey: uniquePOKeysMap.keySet()){
                
                // per unique key
                for (ContractLineWrapper ctLineWrapper:uniquePOKeysMap.get(uKey)){
                    //Building PO header objs
                    if (!mapOfUniqueKeyToPO.containsKey(uKey)){ // only create PO header if it doesn't exist
                        Purchase_Order__c POObj = new Purchase_Order__c();       
                        POObj.Approval_Status__c = 'Approved';
                        POObj.Company__c = companyId;
                        POObj.Date_Closed__c = null;
                        POObj.Order_Date__c = system.today();
                        POObj.Status__c = 'Open';
                        POObj.Supplier__c = ctLineWrapper.ctLine.Contract__r.Supplier__c;
                        POObj.Remit_To_Supplier__c = ctLineWrapper.ctLine.Contract__r.Supplier__r.Remit_To__c; //KNDY-4861, KNDY-4946
                     
                        if(!string.isBlank(facilityId)){
                            POObj.Delivery_Facility__c = facilityId;    
                        }else if (ctLineWrapper.ctLine.Contract__r.Ship_to_Facility__c != null) {
                            POObj.Delivery_Facility__c = ctLineWrapper.ctLine.Contract__r.Ship_to_Facility__c;
                        }else if (compmap.get(companyId).Default_Purchasing_Deliver_To_Facility__c != null) {
                            POObj.Delivery_Facility__c = compmap.get(companyId).Default_Purchasing_Deliver_To_Facility__c;   
                        } else {
                            result.addMessage('Select a facility on the Purchase Agreement or Company.', ApexPages.Severity.ERROR);
                            result.success = false;
                            return result;
                        }
                      
                        POObj.Currency__c = ctLineWrapper.ctLine.Contract__r.Currency__c; //KNDY-11822
                        POObj.FOB_Term__c = ctLineWrapper.ctLine.Contract__r.FOB_Term__r.id;
                        POObj.Payment_Term__c = ctLineWrapper.ctLine.Contract__r.Payment_Term__r.id;
                        POObj.Transportation_Mode__c = ctLineWrapper.ctLine.Contract__r.Transportation_Mode__c;
                        POObj.Purchase_Agreement__c = ctLineWrapper.ctLine.Contract__c;//KNDY-3495, KNDY-3146 Copying in the Blanket number to the PO header
                        POObj.Need_Date__c = (ctLineWrapper.needDate != null) ? DateTime.newInstance(ctLineWrapper.needDate.year(),ctLineWrapper.needDate.month(),ctLineWrapper.needDate.day()).dateGMT() : null; //KNDY-3259
                        POObj.Amount_Tolerance__c = (ctLineWrapper.ctLine.Contract__r.Amount_Tolerance__c != null) ? ctLineWrapper.ctLine.Contract__r.Amount_Tolerance__c : null;
                        POObj.Quantity_Tolerance_Over__c = (ctLineWrapper.ctLine.Contract__r.Quantity_Tolerance_Over__c != null) ? ctLineWrapper.ctLine.Contract__r.Quantity_Tolerance_Over__c : null;
                        //POObj.Quantity_Tolerance_Under__c = (ctLineWrapper.ctLine.Contract__r.Quantity_Tolerance_Under__c != null) ? ctLineWrapper.ctLine.Contract__r.Quantity_Tolerance_Under__c : null;
                        POObj.Unit_Price_Tolerance_Over__c = (ctLineWrapper.ctLine.Contract__r.Unit_Price_Tolerance_Over__c != null) ? ctLineWrapper.ctLine.Contract__r.Unit_Price_Tolerance_Over__c : null;
                        //POObj.Unit_Price_Tolerance_Under__c = (ctLineWrapper.ctLine.Contract__r.Unit_Price_Tolerance_Under__c != null) ? ctLineWrapper.ctLine.Contract__r.Unit_Price_Tolerance_Under__c : null;
                        Company__c c = compmap.get(companyId);
                        if (facilityMap.get(POObj.Delivery_Facility__c).Default_Purchasing_Delivery_Location__c != null)
                            POObj.Delivery_Location__c = facilityMap.get(POObj.Delivery_Facility__c).Default_Purchasing_Delivery_Location__c;
                        else {
                            //PTP-19 Error message shown after clicking on a Create Release
                            result.addMessage(Label.Default_purchasing_delivery_location_is_not_available_for_the_facility, ApexPages.Severity.ERROR);
                            result.success = false;
                            return result;
                        }
                                
                        mapOfUniqueKeyToPO.put(uKey, POObj);
                    }
                    
                    //Building PO Lines
                    Purchase_Order_Line__c POLObj = new Purchase_Order_Line__c();
                    POLObj.Company__c = companyId;
                    POLObj.Date_Added__c = system.today();
                    POLObj.Approved__c = true;
                    POLObj.Date_Closed__c = null;
                    POLObj.Date_Last_Changed__c = system.today();
                    if(!string.isBlank(facilityId)){
                            POLObj.Delivery_Facility__c = facilityId;    
                    }else if (ctLineWrapper.ctLine.Contract__r.Ship_to_Facility__c != null) {
                            POLObj.Delivery_Facility__c = ctLineWrapper.ctLine.Contract__r.Ship_to_Facility__c;
                    }else if (compmap.get(companyId).Default_Purchasing_Deliver_To_Facility__c != null) {
                            POLObj.Delivery_Facility__c = compmap.get(companyId).Default_Purchasing_Deliver_To_Facility__c;   
                    } else {
                            result.addMessage('Select a facility on Purchase Agreement or Company.', ApexPages.Severity.ERROR);
                            result.success = false;
                            return result;
                    }
                    POLObj.Delivery_Location__c = mapOfUniqueKeyToPO.get(uKey).Delivery_Location__c;
                            
                    POLObj.Description__c = ctLineWrapper.ctLine.Item__r.Description__c;
                    POLObj.Item__c = ctLineWrapper.ctLine.Item__c;
                    POLObj.Contract_Line__c = ctLineWrapper.ctLine.Id;
                    POLObj.Contracted__c = true;
                    POLObj.Need_Date__c = (ctLineWrapper.needDate != null) ? DateTime.newInstance(ctLineWrapper.needDate.year(),ctLineWrapper.needDate.month(),ctLineWrapper.needDate.day()).dateGMT() : null; //KNDY-4377
                    POLObj.Order_Quantity__c = ctLineWrapper.quantityToRelease;
                    POLObj.Purchase_UOM__c = ctLineWrapper.ctLine.Purchase_UOM__c; //KNDY-10601
                    POLObj.Status__c = 'Open';
                    POLObj.Supplier__c = ctLineWrapper.ctLine.Contract__r.Supplier__c;
                    POLObj.Supplier__r = ctLineWrapper.ctLine.Contract__r.Supplier__r;
                    
                    if(ctLineWrapper.ctLine.Invoice_Matching__c == null || ctLineWrapper.ctLine.Invoice_Matching__c == ''){ 
                    	POLObj.Invoice_Matching__c = ctLineWrapper.ctLine.Contract__r.Supplier__r.Invoice_Matching__c; 
                    }else{
                    	POLObj.Invoice_Matching__c = ctLineWrapper.ctLine.Invoice_Matching__c;   
                    }
                    POLObj.Overage_Percentage__c = KSE.addQuantityToField(ctLineWrapper.ctLine.Contract__r.Supplier__r.Default_Receiving_Tolerance__c, 0);
                    POLObj.Unit_Price__c = KSE.addQuantityToField(getUnitPriceBasedOnTiers(ctLineWrapper, ctLineWrapper.quantityToRelease), 0); // TODO this will change based on UI
                    POLObj.Consigned__c = ctLineWrapper.ctLine.Consigned__c;
                    POLObj.Standard_Cost__c = ItemService.getActiveStandardCostDecimal(itemIds, new set<Id>{facilityId}, companyId, facilityId, system.now(), POLObj.Item__c);//KNDY-6594
                    
                    
                    if (!mapOfUniqueKeyToPOLines.containsKey(uKey)){ // create new PO line
                        mapOfUniqueKeyToPOLines.put(uKey, new List<Purchase_Order_Line__c>{POLObj});
                    }else{ // create new PO line and add to existing list of PO lines
                        mapOfUniqueKeyToPOLines.get(uKey).add(POLObj);
                    }
                }
                
            }
            List<Purchase_Order_Line__c> POLinesToInsert = new List<Purchase_Order_Line__c>();
            Set<ID> poHeadersCreated = new Set<ID>();
            Savepoint sp = Database.setSavepoint();
            try{
                //insert all PO headers
                DML.insertAsUser(mapOfUniqueKeyToPO.values());
                
                for (String uKey: uniquePOKeysMap.keySet()){
                    ID poheaderId = mapOfUniqueKeyToPO.get(uKey).id;
                    poHeadersCreated.add(poheaderId);
                    for (Purchase_Order_Line__c pol: mapOfUniqueKeyToPOLines.get(uKey)){
                        pol.Purchase_Order__c = poheaderId;
                        POLinesToInsert.add(pol); // adding the POL to a list for insertion
                    }
                }
                DML.insertAsUser(POLinesToInsert);
                
                List<String> poHeaderLinks = new List<String>();
                
                for (Purchase_Order__c po: [SELECT ID, Name
                            FROM Purchase_Order__c
                            WHERE ID IN :poHeadersCreated]) {
                    poHeaderLinks.add('<a href="/' + po.Id + '">' + po.Name + '</a>');
                }
                
                result.addMessage(Label.Changes_saved_PurchaseOrder_headers_created  + poHeaderLinks, ApexPages.Severity.CONFIRM);
            }catch(Exception ex){
                Database.rollback( sp );
                result.success = false;
                result.addMessage(ex, ApexPages.Severity.ERROR);
            }
        }
       return result;
    }
    
    //KNDY-2299 , PTP-63 Including another validation to check for tiers 
    @RemoteAction
    //public static JsonResult isWithinMOQ(Contract_Line__c cLine,ID supplierId, ID itemId, ID facilityId,String needDateValue, Double quantityToRelease) {
    public static JsonResult isWithinMOQ(Contract_Line__c cLine,ID supplierId, ID itemId, ID facilityId,String needDateValue, Double quantityToRelease) {
        
        ContractService cs = new ContractService();
        boolean isQtyWithinTiers = cs.isQtyWithinTiers(quantityToRelease, cLine);
        JsonResult result = new JsonResult();
        
        if (isQtyWithinTiers == false){
            result.success = false;
            result.message = Label.Qty_greater_than_Largest_Tier; 
            return result;
        }
        
        Item__c saidItem;
        List<Facility_Item__c> fItem = new List<Facility_Item__c>();
        Decimal conversionFactor = 1.0;
        if (quantityToRelease > 0){ //sanity check
            if( itemId != null ) { // retreive item attr
                saidItem = [ select ID, Name, Approved_Supplier_Required__c, Purchasing_UOM__c, Purchasing_UOM__r.Name from Item__c where ID = :itemId ];
                if (facilityId != null)
                    fItem = [select id, name, Ordering_Multiple__c from Facility_Item__c where facility__c = :facilityID and Item__c = :itemID];
            }
            //PTP-410 Check for Ordering Multiple during release
            if (fItem.size() > 0 ){
                if (fItem[0].Ordering_Multiple__c != null && fItem[0].Ordering_Multiple__c != 0){
                    if (math.mod((long)QuantityToRelease, (long)fItem[0].Ordering_Multiple__c) != 0){
                        result.success = false;
                        result.message = Label.Qty_does_not_meet_Ordering_Multiple + fItem[0].Ordering_Multiple__c;
                        return result;
                    }
                }
            }
            //KNDY-10905 Check if qty to release meets MOQ requirements
            result.success = true;
            Decimal moq = KSE.addQuantitytoField(cLine.Minimum_Order_Quantity__c,0);
            if(quantityToRelease < moq){ 
                result.success = false;
                result.message = Label.Quantity_entered_to_release_is_less_than_minimum_order_quantity  + moq;
            }
        }
        return result;
    }
    
    //KNDY-2465
    public String getSourcingPolicyConfigJson() {
        String configStr = JSON.serialize(this.sourcingPolicyConfig);
          
        return configStr;
    }
    
    public string getSourcingPolicyFieldList() {
        if (sourcingPolicyFieldList == null && sourcingPolicyConfig != null) {
            FieldInfo fieldInfoItem;
            // get the contract lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(sourcingPolicyConfig.objectName, sourcingPolicyConfig.fieldset);
            Set<String> hiddenFields = new Set<String> { 'Id'};
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                fieldInfoList[i].field = fieldName;
                fieldInfoList[i].editable = false;
                fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            }
            
            sourcingPolicyFieldList = JSON.serialize(fieldInfoList);
        }
        
        return sourcingPolicyFieldList;
    }
    
    public  map<string,string> getItemCrossReferenceQuery() {
        
        String sourcingPolicyQuery = null;
        map<string,string> qryMap = new map<string,string>();
        string whereClause = '';
        string conditionalClause = '';
        //conditionalClause = ' Active__c = true AND Approval_Status__c = \'Approved\' AND Cross_Reference_Type__c = \'Supplier\' and (Ship_to_Facility__c = ' + '\''  + facilityId+  '\'' +'OR Ship_to_Facility__c = null)';
        conditionalClause = ' Active__c = true AND Approval_Status__c = \'Approved\' AND Cross_Reference_Type__c = \'Supplier\' and (Ship_to_Facility__c = null  OR Ship_to_Facility__c = ';
        // :facilityId)';
        
        sourcingPolicyQuery = util.generateQueryFromFieldSet('Item_Cross_Reference__c', 
                                                             new set<string>{'Sourcing_Policy_Agreement_Release'},
                                                             new set<string>{'id','Name', 'Active__c', 'Approval_Status__c', 'Item__c', 'Item__r.Name', 'Item__r.Approved_Supplier_Required__c',
                                                                 'Supplier__c', 'Minimum_Order_Quantity__c','Ship_to_Facility__c', 'UOM__c', 'UOM__r.Name'},
                                                             whereClause);
        
        qryMap.put('Query',sourcingPolicyQuery);
        qryMap.put('Condition',conditionalClause);
        
        return qryMap;
    }
}