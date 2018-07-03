public with sharing class MRPPlannedPurchaseAgainstAgreementExt extends BaseController{
	
	ApexPages.StandardSetController setCon;
    public Boolean selecterror {get; set;}
     public set <ID> planset  {get; set;}
       
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
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
    public GridRelatedListController.GridRelatedListConfig mrpPlannedPurchaseConfig {get; set;}
    public String mrpPlannedPurchaseFieldList = null;
    public List<Id> mrpItemsList {get;  set;}
    public Set<String> itemUOMKeys = new Set<String>();
	public boolean showSourcingGrid {get; set;}

    public MRPPlannedPurchaseAgainstAgreementExt(ApexPages.StandardSetController controller) {
		showSourcingGrid = ContractService.showHideSourcingGrid();
    	previousPage = ApexPages.currentPage().getHeaders().get('Referer');
        planset = new set<Id>();
    	setCon = controller;
        selecterror = false;
        List<String> errorMsgs = new List<String>();
        Map<Date, MRP__c> rqDates = new Map<Date, MRP__c>();
        Map<Id, MRP__c> facMap = new Map<Id, MRP__c>();
        Map<Id, MRP__c> cmpyMap = new Map<Id, MRP__c>();
        Map<Id, MRP__c> validMRPRecords = new Map<Id, MRP__c>();
        mrpItemsList = new List<Id>();
        Map<Id, Id> mrpItemsMap = new Map<Id, Id>();
        system.debug('selected records: ' + setCon.getSelected());
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_Plans_Selected) );
            selecterror = true;
        }
        
        List<MRP__c> selectedRecords = setCon.getSelected();
        for (MRP__c plan: selectedRecords ) {      
            planset.add(plan.ID);
        }
        selectedRecords = [select ID, Name, Company__c, Item__c, Item__r.Source__c, Item__r.Purchasing_UOM__c,Make_Buy__c, 
                           Item__r.Buyer_Planner__c, Facility__c, Item__r.Packaging_UOM__c, Facility_Item__r.Source__c,
                           Modified_Quantity__c, Planned__c, Required_Date__c
                           from MRP__c
                           where ID in : planset ];
        validMRPRecords.putAll(selectedRecords);
        
        for (MRP__c plan: selectedRecords) {
        	if (!rqDates.containsKey(plan.Required_Date__c))
        		rqDates.put(plan.Required_Date__c, plan);
        		
        	if (!facMap.containsKey(plan.Facility__c))
        		facMap.put(plan.Facility__c, plan);		
        	
        	if (!cmpyMap.containsKey(plan.Company__c))
        		cmpyMap.put(plan.Company__c, plan);
        			
        }
        
        if ((rqDates.keySet().size() > 1) ||  (facMap.keySet().size() > 1) ||  (cmpyMap.keySet().size() > 1)){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                    Label.MRP_Planned_records_with_same_required_date_company_facility_can_be_processed));
            selectedRecords = new List<MRP__c>();
            planSet = new Set<Id>();
            validMRPRecords = new Map<Id, MRP__c>();        
        }else if ((rqDates.keySet().size() == 1) &&  (facMap.keySet().size() == 1) &&  (cmpyMap.keySet().size() == 1)){
        	defaultCompany = cmpyMap.values()[0].Company__c;
        	defaultFacility = facMap.values()[0].Facility__c; //There should only be 1 value
        }
        
        if (selectedRecords.size() > 0){
        	
        	Set<Id> ItemIds = new Set<Id>();
        	Set<Id> FacilityIds = new Set<Id>();
        	
	        for(MRP__c plan: selectedRecords) {
	        	ItemIds.add(plan.Item__c);
	        	FacilityIds.add(plan.Facility__c);
	        }
	        
	        for (MRP__c plan: selectedRecords) {
	             if (plan.Planned__c != true) {
	             	
	                selecterror = true;
	                //errorMsgs.add('\nOnly MRP Planned records can be selected: ' +plan.Name);
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, '\n' + Label.Only_MRP_Planed_records_can_be_selected + plan.Name));
	                if (validMRPRecords.containsKey(plan.Id))
	                	validMRPRecords.remove(plan.Id);
	            }
	            if (plan.Modified_Quantity__c <= 0.0) {
	                selecterror = true;
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, '\n' + Label.Only_plans_with_positive_modified_quantities_can_be_selected +plan.Name));
	                //errorMsgs.add('\nOnly Plans with positive Modified Quantities can be Selected: ' +plan.Name);
	                if (validMRPRecords.containsKey(plan.Id))
	                	validMRPRecords.remove(plan.Id);
	            }
	            if ( ( plan.Facility_Item__c == null && plan.Item__r.Source__c != 'Purchased' ) || ( plan.Facility_Item__c != null && plan.Facility_Item__r.Source__c != 'Purchased'  )) { // neither of Item and Facility Item source is purchased
	                selecterror = true;
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, '\n' + Label.Only_items_with_Source_Purchased_can_be_selected +plan.Name));
	                //errorMsgs.add('Only Items with Source Purchased can be Selected: ' +plan.Name);
	                if (validMRPRecords.containsKey(plan.Id))
	                	validMRPRecords.remove(plan.Id);
	            }
	            if (plan.Item__r.Buyer_Planner__c == null) {
	                selecterror = true;
	                //errorMsgs.add('\nNo Buyer / Planner for Item: ' +plan.Name);
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, '\n' + Label.No_buyer_Planner_for_item +plan.Name));
	                if (validMRPRecords.containsKey(plan.Id))
	                	validMRPRecords.remove(plan.Id);
	            }
	            
	            //KNDY-2170
	            Decimal activeStandardCost = 0.00;
	            activeStandardCost = ItemService.getActiveStandardCostDecimal(ItemIds, FacilityIds, plan.Company__c,plan.Facility__c,System.Now(), plan.Item__c);
	            if (activeStandardCost == null || activeStandardCost == 0.0) {
	                selecterror = true;
	                //errorMsgs.add('\nStandard Cost zero: ' +plan.Name);
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, '\n' + Label.Standard_Cost_zero +plan.Name));
	                if (validMRPRecords.containsKey(plan.Id))
	                	validMRPRecords.remove(plan.Id);
	            }
	        }
        }
        
        if (errorMsgs.size() > 0){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING,
                    Label.Some_records_filtered_out_due_to_following_reasons + errorMsgs));
        }
        planSet = new Set<Id>(); 
        if (!validMRPRecords.isEmpty()){
        	for (MRP__c plan: validMRPRecords.values() ) {      
	            planset.add(plan.ID);
	            mrpItemsMap.put(plan.Item__c, plan.Item__c);
	            
	            String itemUOMKey = '';
	            if (plan.Item__c != null) {
	               itemUOMKey += (String.ValueOf(plan.Item__c)).substring(0, 15) + '/';
	            }   
	            if (plan.Item__r.Purchasing_UOM__c != null){//KNDY-10904
	               itemUOMKey += (String.ValueOf(plan.Item__r.Purchasing_UOM__c)).substring(0, 15);
	            }
	            itemUOMKeys.add(itemUOMKey);
	        }
        }
        mrpItemsList = mrpItemsMap.values();
        
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
        
        //MRP Planned Purchase Grid config
        mrpPlannedPurchaseConfig = new GridRelatedListController.GridRelatedListConfig();
        mrpPlannedPurchaseConfig.uniqueId = 'MRPPlannedPurchaseGrid';
        mrpPlannedPurchaseConfig.title = 'MRP Planned Purchases';
        mrpPlannedPurchaseConfig.objectName = 'MRP__c';
        mrpPlannedPurchaseConfig.fieldset = 'Purchase_Release_Display_List';
        mrpPlannedPurchaseConfig.buttons = 'search';
        mrpPlannedPurchaseConfig.alwaysUseFullDateTimeFormat = false;
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
            	fieldInfoList[i].field = 'ctLine.' + fieldName;
            	fieldInfoList[i].editable = false;
            	fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            }
            
            // set the need date and quantity fields as editable
            fieldInfoItem = new FieldInfo('needDate', Label.NeedDate, 'date', false);
            fieldInfoItem.editable = true;
            
            
            fieldInfoList.add(fieldInfoItem);
            
            fieldInfoItem = new FieldInfo('quantityToRelease', Label.Quantity, 'double', false);
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
            Set<String> visibleFields = new Set<String> { 'Name', 'Item__c', 'Catalog_Line__c', 'Contract__c' };
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
            	String fieldName = fieldInfoList[i].field;
            	fieldInfoList[i].field = 'ctLine.' + fieldName;
            	fieldInfoList[i].editable = false;
            	fieldInfoList[i].hidden = !visibleFields.contains(fieldName);
            	releaseLineFields.add(fieldInfoList[i].field);
            }
            
            // add any additional fields
            for(Integer i = 0; i < additionalFields.size(); i++){
            	String fieldName = additionalFields[i].field;
            	additionalFields[i].field = 'ctLine.' + fieldName;
            	
            	if (!releaseLineFields.contains(additionalFields[i].field)) {
            		fieldInfoList.add(additionalFields[i]);
            	}
            }
            
            // set the need date and quantity fields as editable
            fieldInfoItem = new FieldInfo('needDate', Label.NeedDate, 'date', false);
            fieldInfoItem.editable = false;
            fieldInfoItem.format = KendoUtils.DATE_FORMAT;
            
            fieldInfoList.add(fieldInfoItem);
            
            fieldInfoItem = new FieldInfo('quantityToRelease', Label.Quantity, 'double', false);
            fieldInfoItem.editable = false;
            
            fieldInfoList.add(fieldInfoItem);
            
            releaseLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return releaseLinesFieldList;
    }
    
	@RemoteAction
	public static JsonResult getContractLines(ID companyId, ID facilityId, List<String> itemUOMKeyList){
		JsonResult result = new JsonResult();
		List<ContractLineWrapper> cLineList = new List<ContractLineWrapper>();
        set<ID> releaseCLSet = new set<ID>();        
        Date tday = system.today();
        Integer count = 0;
        
        String whereClause = 'Contract__r.Company__c = :companyId and (Contract__r.Ship_to_Facility__c = :facilityId OR Contract__r.Ship_to_Facility__c = null) and Contract_Start__c <= :tday and Status__c = \'Open\' and '+ KSE.FieldUsedtoReleasePO + '>0 and Contract__r.Approval_Status__c = \'Approved\' and Contract__r.Status__c = \'Open\' and ItemUOMKey__c in :itemUOMKeyList order by Line__c asc';
	        
	    SOQLUtil soql = new SOQLUtil('Contract_Line__c');
	    soql.addFields('Line_Release');
	    soql.addFields('Tiers');
	    soql.addFields(new set<string>{'Id','Line__c','UOM__c','Contract__r.Company__c', 'Contract__r.Company__r.Default_Purchasing_Deliver_To_Facility__c', 'Contract_Quantity__c', 'Location__c', 'Purchase_UOM__c',
        					'Purchased_Quantity__c', 'PurchasedValue__c','Quantity_Received__c','Remaining_Quantity__c','Available_Quantity__c','Remaining_Value__c','Remaining_Value_Percent__c','Status__c',
        					'ValueReceived__c','Contract__r.Payment_Term__c', 'Contract__r.Payment_Term__r.id', 'Contract__r.FOB_Term__c', 'Contract__r.FOB_Term__r.id', 'Item__c', 'Item__r.Stocking_UOM__c', 'Item__r.Description__c', 'Contract__r.Supplier__c', 'Contract__r.Currency__c',
        					'Item__r.Buyer_Planner__c','Item__r.Purchasing_UOM__c', 'Item__r.Packaging_UOM__c', 'Contract__r.Transportation_Mode__c', 'Consigned__c', 'Type__c','Contract__r.Contract_Number__c', 'Contract__r.Supplier__c','Contract__c','Contract__r.Supplier__r.Remit_To__c',
        					'Contract__r.Unit_Price_Tolerance_Over__c','Contract__r.Quantity_Tolerance_Over__c','Contract__r.Amount_Tolerance__c','Contract__r.Supplier__r.Default_Receiving_Tolerance__c'});
	    soql.setWhereClause(whereClause);
		    
        List<Contract_Line__c> clinesList = Database.query(soql.getQuery()); 
        
        /*List<Contract_Line__c> clinesList = 	database.query( 
        			util.generateQueryFromFieldSet('Contract_Line__c', 
        				new set<string>{'Line_Release', 'Tiers'},
        				new set<string>{'Id','Line__c','UOM__c','Contract__r.Company__c','Contract_Quantity__c', 'Location__c', 
        					'Purchased_Quantity__c', 'PurchasedValue__c','Quantity_Received__c','Remaining_Quantity__c','Available_Quantity__c','Remaining_Value__c','Remaining_Value_Percent__c','Status__c',
        					'ValueReceived__c','Contract__r.Payment_Term__c', 'Contract__r.Payment_Term__r.id', 'Contract__r.FOB_Term__c', 'Contract__r.FOB_Term__r.id', 'Item__c', 'Item__r.Description__c', 'Contract__r.Supplier__c', 
        					'Item__r.Buyer_Planner__c','Item__r.Purchasing_UOM__c', 'Contract__r.Transportation_Mode__c', 'Consigned__c', 'Type__c','Contract__r.Contract_Number__c', 'Contract__r.Supplier__c','Contract__c','Contract__r.Supplier__r.Remit_To__c',
        					'Contract__r.Unit_Price_Tolerance_Over__c','Contract__r.Quantity_Tolerance_Over__c','Contract__r.Amount_Tolerance__c','Contract__r.Supplier__r.Default_Receiving_Tolerance__c'},
	    				'  Contract__r.Company__c = :companyId and (Contract__r.Ship_to_Facility__c = :facilityId OR Contract__r.Ship_to_Facility__c = null) and Contract_Start__c <= :tday and Status__c = \'Open\' and '+ KSE.FieldUsedtoReleasePO + '>0 and Contract__r.Approval_Status__c = \'Approved\' and Contract__r.Status__c = \'Open\' and Item__c IN : itemIds order by Line__c asc' ));*/
        
        for(Contract_Line__c cl: clinesList) {
        	
        	// build wrappers based on the lines returned, set the need date to today and qty to remaining qty.
        	ContractLineWrapper contractLineWrapper= new ContractLineWrapper();
        	contractLineWrapper.ctLine = cl;
			//contractLineWrapper.needDate = Datetime.now().getTime();
			cLineList.add(contractLineWrapper);
        	releaseCLSet.add(cl.id);
        	count++;
        	
        }

		result.records = cLineList;
        result.total = cLineList.size();
        
        return result;
	}
 	
 	// wrapper class to hold the contract line to pass the information    
	public class ContractLineWrapper{
		
		public Contract_Line__c ctLine { get; set;}
	    public long needDate { get; set;}
	    public double quantityToRelease = 0;
	    	    
    	public ContractLineWrapper(){
            this.ctLine = new Contract_Line__c(); 
             
	    }	
	}  
	
	public pageReference addRowForRelease(ContractLineWrapper contractLineForRelease) {
		this.cLinesForReleaseList.add(contractLineForRelease);
		
	 	return null;
	}
	
	/*
		Given a the contract line (wrappers) and quantity to release, find the tier that it falls under and return the 
		matching unit price
		TODO Need to bulkify this once UI is ready based on how the qty will be captured in the wrapper
	*/
	public static Double getUnitPriceBasedOnTiers(ContractLineWrapper contractLineForRelease, Double quantityGiven){
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
	public static JsonResult release(ID companyId, ID facilityId, List<ContractLineWrapper> contractLinesForRelease, List<String> dateFields, List<MRP__c> mrpPlannedRows) {
		for (ContractLineWrapper ctLineWrapper: contractLinesForRelease) { 
        	KendoUtils.UpdateDateFields(ctLineWrapper.ctLine, dateFields);
		
        	if (Datetime.newInstance(ctLineWrapper.needDate) == Datetime.newInstance(0)) {
	        	ctLineWrapper.needDate = null;
        	}
		}
		return releaseContractLines(companyId, facilityId, contractLinesForRelease, mrpPlannedRows);
	}
	
	public static JsonResult releaseContractLines(ID companyId, ID facilityId, List<ContractLineWrapper> contractLinesForRelease, List<MRP__c> mrpPlannedRows) {
		JsonResult result = new JsonResult();
		List<Purchase_Order_Line__c> POLList = new List<Purchase_Order_Line__c>();
        List<Contract_Line__c> ctLineObjList = new List<Contract_Line__c>();
        Map<String, List<ContractLineWrapper>> uniquePOKeysMap = new  Map<String, List<ContractLineWrapper>>();
        Map<ID, Facility__c> facilityMap = new Map<ID, Facility__c>();
        Map<ID, Company__c> compmap = new Map<ID, Company__c>();
        Map<ID, List<MRP__c>> itemToMRPMap = new Map<ID, List<MRP__c>>();
        Map<ID, MRP__c> modifiedMRPRecordsToSave = new Map<Id, MRP__c>();
        set<Id> itemIds = new set<Id>(); //KNDY-6594        
        
        Map<Id, List<Id>> itemPackagingUomCache = new Map<Id, List<Id>>();
        for (Company__c c: [select ID, Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__c, Default_Purchasing_Deliver_To_Facility__c 
                            from Company__c
                            where ID = :companyId]) {
            compmap.put(c.ID, c);
        }
        
        for (Facility__c f: [select ID, Default_Purchasing_Delivery_Location__c 
                            from Facility__c
                            where Company__c = :companyId]) {
            facilityMap.put(f.ID, f); //TODO: check why do we query for all the facilities in the company when the facilityId has been passed in ??
        }
        //KNDY-5110, KNDY-2958
        for (MRP__c plan: mrpPlannedRows ) {      
            if (!itemToMRPMap.containsKey(plan.Item__c)) {
            	itemToMRPMap.put(plan.Item__c, new List<MRP__c>{plan});
            }else{
            	itemToMRPMap.get(plan.Item__c).add(plan);
            }
        }
    	/*
        	Each combination of Supplier, Facility, FOB terms, payment terms and Trans Mode will result in a unique PO created from this release
        */
    	for (ContractLineWrapper ctLineWrapper: contractLinesForRelease) { 
    		itemIds.add(ctLineWrapper.ctLine.Item__c); //Collecting Item Ids to pass to Costing service
    		if ( !itemPackagingUomCache.containsKey ( ctLineWrapper.ctLine.Item__c) ) {
                itemPackagingUomCache.put(ctLineWrapper.ctLine.Item__c, (List<Id>) JSON.deserialize(ctLineWrapper.ctLine.Item__r.Packaging_UOM__c, List<Id>.class));
            }
    		
    		//TODO need to add checks here for qty check and need date check for release
    		Decimal qtyToVerify = 0;
        	if (KSE.FieldUsedtoReleasePO == 'Remaining_Quantity__c')
        		qtyToVerify = ctLineWrapper.ctLine.Remaining_Quantity__c;
    		else
    			qtyToVerify = ctLineWrapper.ctLine.Available_Quantity__c;
    			
    		if (ctLineWrapper.quantityToRelease <= qtyToVerify){
    			//if (needdate is outside of date range)
    			Date convertedNeedDate = Datetime.newInstance(ctLineWrapper.needDate).dateGMT(); //KNDY-4377
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
	    	}else{
    			//TODO build a list of failures 'CTLine cannot be release: ctline.Line__c
    	        result.addMessage(Label.You_cannot_release_more_than_remaining_quantity + ctLineWrapper.ctLine.Name, ApexPages.Severity.ERROR);
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
				        POObj.Delivery_Facility__c = !String.isEmpty(facilityId)  ? facilityId  : ctLineWrapper.ctLine.Contract__r.Company__r.Default_Purchasing_Deliver_To_Facility__c;
				        POObj.Currency__c = ctLineWrapper.ctLine.Contract__r.Currency__c; 
				        POObj.FOB_Term__c = ctLineWrapper.ctLine.Contract__r.FOB_Term__r.id;
				        POObj.Payment_Term__c = ctLineWrapper.ctLine.Contract__r.Payment_Term__r.id;
				        POObj.Transportation_Mode__c = ctLineWrapper.ctLine.Contract__r.Transportation_Mode__c;
				        POObj.Purchase_Agreement__c = ctLineWrapper.ctLine.Contract__c;//KNDY-3495, KNDY-3146 Copying in the Blanket number to the PO header
        				POObj.Need_Date__c = (ctLineWrapper.needDate != null) ? Datetime.newInstance(ctLineWrapper.needDate).dateGMT() : system.today(); //KNDY-3259
				        POObj.Amount_Tolerance__c = (ctLineWrapper.ctLine.Contract__r.Amount_Tolerance__c != null) ? ctLineWrapper.ctLine.Contract__r.Amount_Tolerance__c : null;
				        POObj.Quantity_Tolerance_Over__c = (ctLineWrapper.ctLine.Contract__r.Quantity_Tolerance_Over__c != null) ? ctLineWrapper.ctLine.Contract__r.Quantity_Tolerance_Over__c : null;
				        //POObj.Quantity_Tolerance_Under__c = (ctLineWrapper.ctLine.Contract__r.Quantity_Tolerance_Under__c != null) ? ctLineWrapper.ctLine.Contract__r.Quantity_Tolerance_Under__c : null;
				        POObj.Unit_Price_Tolerance_Over__c = (ctLineWrapper.ctLine.Contract__r.Unit_Price_Tolerance_Over__c != null) ? ctLineWrapper.ctLine.Contract__r.Unit_Price_Tolerance_Over__c : null;
				        //POObj.Unit_Price_Tolerance_Under__c = (ctLineWrapper.ctLine.Contract__r.Unit_Price_Tolerance_Under__c != null) ? ctLineWrapper.ctLine.Contract__r.Unit_Price_Tolerance_Under__c : null;
				        
				        if(facilityMap.containskey(facilityId)){
				        	if (facilityMap.get(facilityId).Default_Purchasing_Delivery_Location__c != null){
				        		POObj.Delivery_Location__c = facilityMap.get(facilityId).Default_Purchasing_Delivery_Location__c;
				        	}
				        }	
				        else{
				        	if (compmap.containsKey(companyId)) {
					            Company__c c = compmap.get(companyId);
					            POObj.Delivery_Location__c = c.Default_Purchasing_Deliver_To_Facility__r.Default_Purchasing_Delivery_Location__c;
					        }
				        }
				        		
				        mapOfUniqueKeyToPO.put(uKey, POObj);
		    		}
		    		
		    		// 
		    		Decimal convFactor = KSE.getConversionFactor ( ctLineWrapper.ctLine.Item__c, null, ctLineWrapper.ctLine.Purchase_UOM__c, ctLineWrapper.ctLine.Item__r.Stocking_UOM__c,itemPackagingUomCache.get(ctLineWrapper.ctLine.Item__c) );
		    		
		    		//Building PO Lines
		    		Purchase_Order_Line__c POLObj = new Purchase_Order_Line__c();
                    POLObj.Approved__c = true;
			        POLObj.Company__c = companyId;
			        POLObj.Date_Added__c = system.today();
			        POLObj.Date_Closed__c = null;
			        POLObj.Date_Last_Changed__c = system.today();
			        POLObj.Delivery_Facility__c = mapOfUniqueKeyToPO.get(uKey).Delivery_Facility__c;
			        POLObj.Delivery_Location__c = mapOfUniqueKeyToPO.get(uKey).Delivery_Location__c;
				            
			      	POLObj.Description__c = ctLineWrapper.ctLine.Item__r.Description__c;
			        POLObj.Item__c = ctLineWrapper.ctLine.Item__c;
			        POLObj.Contract_Line__c = ctLineWrapper.ctLine.Id;
			        POLObj.Contracted__c = true;
			        POLObj.Need_Date__c = (ctLineWrapper.needDate != null) ? Datetime.newInstance(ctLineWrapper.needDate).dateGMT() : system.today();
			        POLObj.Order_Quantity__c = ctLineWrapper.quantityToRelease; 
			        POLObj.Purchase_UOM__c = ctLineWrapper.ctLine.Purchase_UOM__c; // KNDY-10905
			        POLObj.Status__c = 'Open';
			        POLObj.Supplier__c = ctLineWrapper.ctLine.Contract__r.Supplier__c;
			        POLObj.Overage_Percentage__c = KSE.addQuantityToField(ctLineWrapper.ctLine.Contract__r.Supplier__r.Default_Receiving_Tolerance__c,0);
			        POLObj.Unit_Price__c = KSE.addQuantityToField(getUnitPriceBasedOnTiers(ctLineWrapper, ctLineWrapper.quantityToRelease), 0); // TODO this will change based on UI
			        POLObj.Consigned__c = ctLineWrapper.ctLine.Consigned__c;
			       	POLObj.Standard_Cost__c = ItemService.getActiveStandardCostDecimal(itemIds, new set<Id>{facilityId}, companyId, facilityId, system.now(),POLObj.Item__c);//KNDY-6594
			        // Contract_Line__c ctLineObj = new Contract_Line__c(id = ctLineWrapper.ctLine.ID);
			        Contract_Line__c ctLineObj = ctLineWrapper.ctLine;
			        ctLineObj.Purchased_Quantity__c += ctLineWrapper.quantityToRelease; //KNDY-2292
			        //ctLineObj.Purchased_Value__c += ctLineWrapper.quantityToRelease * POLObj.Unit_Price__c;
			        ctLineObjList.add(ctLineObj);     
		    		if (!mapOfUniqueKeyToPOLines.containsKey(uKey)){ // create new PO line
		    			mapOfUniqueKeyToPOLines.put(uKey, new List<Purchase_Order_Line__c>{POLObj});
		    		}else{ // create new PO line and add to existing list of PO lines
		    			mapOfUniqueKeyToPOLines.get(uKey).add(POLObj);
		    		}
		    		
		    		//KNDY-5110, KNDY-2958
		    		// Loop through MRP records for the item and start consuming modified quantity as released
		    		if (itemToMRPMap.containsKey(ctLineWrapper.ctLine.Item__c)){
		    			
		    			for (MRP__c mrpRecord: itemToMRPMap.get(ctLineWrapper.ctLine.Item__c)){
		    			    Decimal mrpQty = mrpRecord.Modified_Quantity__c / convFactor;
		    				if (ctLineWrapper.quantityToRelease >= mrpQty){
		    					mrpRecord.Modified_Quantity__c = 0;
		    					ctLineWrapper.quantityToRelease = ctLineWrapper.quantityToRelease - mrpQty;
		    				}else if (ctLineWrapper.quantityToRelease < mrpQty){
		    					mrpRecord.Modified_Quantity__c = mrpRecord.Modified_Quantity__c - ( ctLineWrapper.quantityToRelease * convFactor);
		    					ctLineWrapper.quantityToRelease = 0;
		    				} else {
		    					mrpRecord.Modified_Quantity__c = 0;
		    					ctLineWrapper.quantityToRelease = 0;
		    				}
		    			
		    				modifiedMRPRecordsToSave.put(mrpRecord.id, mrpRecord);
		    			}
		    			
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
	    		DML.updateAsUser(ctLineObjList);
	    		//KNDY-5110
	    		if (modifiedMRPRecordsToSave.size() > 0){
		    		DML.updateAsUser(modifiedMRPRecordsToSave.values());
		    	}
	    	
	    		// Display PO Headers as hyperlinks
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
	public static JsonResult isWithinMOQ(Contract_Line__c cLine, Double quantityToRelease) {
		
		ContractService cs = new ContractService();
		boolean isQtyWithinTiers = cs.isQtyWithinTiers(quantityToRelease, cLine);
		JsonResult result = new JsonResult();
		
		if (isQtyWithinTiers == false){
			result.success = false;
	    	result.message = Label.Qty_greater_than_Largest_Tier;
	    	return result;
		}
		result.success = true;
		Decimal moq = KSE.addQuantitytoField(cLine.Minimum_Order_Quantity__c,0);
		if(quantityToRelease > 0 ){
			if(quantityToRelease < moq){ //KNDY-10905
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
    
    //KNDY-2465 
	@RemoteAction
	public static JsonResult getItemCrossReferenceRecords(ID companyId, ID facilityId, List<Id> mrpItems) {
		JsonResult result = new JsonResult();
		List<Item_Cross_Reference__c> itemCrossRefList = new List<Item_Cross_Reference__c>();
        
        if (String.isNotBlank(companyId) && String.isNotBlank(facilityId)){
        	
	        String whereClause = 'Active__c = true AND Approval_Status__c = \'Approved\' AND Cross_Reference_Type__c = \'Supplier\' and (Ship_to_Facility__c = :facilityId OR Ship_to_Facility__c = null) and Item__c IN :mrpItems order by Item__c asc';
	        
		    SOQLUtil soql = new SOQLUtil('Item_Cross_Reference__c');
		    soql.addFields('Sourcing_Policy_Agreement_Release');
		    soql.addFields(new set<string>{'id','Name', 'Active__c', 'Approval_Status__c', 'Item__c', 'Item__r.Name', 'Item__r.Approved_Supplier_Required__c',
				     						'Supplier__c', 'Minimum_Order_Quantity__c','Ship_to_Facility__c', 'UOM__c', 'UOM__r.Name'});
		    soql.setWhereClause(whereClause);
	    	
	    	itemCrossRefList = Database.query(soql.getQuery()); 
	    	/*
	        itemCrossRefList = 	database.query( 
	        			util.generateQueryFromFieldSet('Item_Cross_Reference__c', 
	        				new set<string>{'Sourcing_Policy_Agreement_Release'},
	        				new set<string>{'id','Name', 'Active__c', 'Approval_Status__c', 'Item__c', 'Item__r.Name', 'Item__r.Approved_Supplier_Required__c',
				     'Supplier__c', 'Minimum_Order_Quantity__c','Ship_to_Facility__c', 'UOM__c', 'UOM__r.Name'},
		    				'  Active__c = true AND Approval_Status__c = \'Approved\' AND Cross_Reference_Type__c = \'Supplier\' and (Ship_to_Facility__c = :facilityId OR Ship_to_Facility__c = null) and Item__c IN :mrpItems order by Item__c asc' ));*/
        }
        
		result.records = itemCrossRefList;
        result.total = itemCrossRefList.size();
        
        return result;
	}

	//KNDY-2958
	public String getMRPPlannedPurchaseConfigJson() {
        String configStr = JSON.serialize(this.mrpPlannedPurchaseConfig);
          
        return configStr;
    }
    
    public string getMRPPlannedPurchaseFieldList() {
        if (mrpPlannedPurchaseFieldList == null && mrpPlannedPurchaseConfig != null) {
        	FieldInfo fieldInfoItem;
        	// get the contract lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(mrpPlannedPurchaseConfig.objectName, mrpPlannedPurchaseConfig.fieldset);
            Set<String> hiddenFields = new Set<String> { 'Id'};
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
            	String fieldName = fieldInfoList[i].field;
            	fieldInfoList[i].field = fieldName;
            	fieldInfoList[i].editable = false;
            	fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            }
            
            mrpPlannedPurchaseFieldList = JSON.serialize(fieldInfoList);
        }
        
        return mrpPlannedPurchaseFieldList;
    }
    
    public String getSelectedMRPIDAsString(){
    	return JSON.serialize(planset);
    }
    
    public String getSelectedMRPItemIDsAsString(){
    	return JSON.serialize(mrpItemsList);
    }
    
    public String getSelectedItemUOMKeysAsString(){//KNDY-10905
        return JSON.serialize(itemUOMKeys);
    }
    
    //KNDY-2958 
	@RemoteAction
	public static JsonResult getMRPPlannedPurchaseRecords(List<ID> plannedRecords) {
		JsonResult result = new JsonResult();
		List<MRP__c> mrpPlannedRecordsList = new List<MRP__c>();
		
		String whereClause = 'ID in :plannedRecords order by Sequence__c asc';
        
	    SOQLUtil soql = new SOQLUtil('MRP__c');
	    soql.addFields('Purchase_Release_Display_List');
	    soql.addFields(new set<string>{'ID', 'Name', 'Company__c', 'Required_Date__c', 'Item__c', 
                           'Item__r.Description__c', 'Item__r.Supplier__c', 'Item__r.Supplier__r.Remit_to__c',
                           'Item__r.Buyer_Planner__c', 'Facility__c', 'Item__r.Purchasing_UOM__c', 'Modified_Quantity__c', 'Sequence__c'});
	    soql.setWhereClause(whereClause);
        
        mrpPlannedRecordsList = Database.query(soql.getQuery());
        
        /*    mrpPlannedRecordsList = 	database.query( 
	        			util.generateQueryFromFieldSet('MRP__c', 
	        				new set<string>{'Purchase_Release_Display_List'},
	        				new set<string>{'ID', 'Name', 'Company__c', 'Required_Date__c', 'Item__c', 
                           'Item__r.Description__c', 'Item__r.Supplier__c', 'Item__r.Supplier__r.Remit_to__c',
                           'Item__r.Buyer_Planner__c', 'Facility__c', 'Item__r.Purchasing_UOM__c', 'Modified_Quantity__c', 'Sequence__c'},
		    				'  ID in :plannedRecords order by Sequence__c asc' ));*/
		    				
        result.records = mrpPlannedRecordsList;
        result.total = mrpPlannedRecordsList.size();
        
        return result;
	}
    
}