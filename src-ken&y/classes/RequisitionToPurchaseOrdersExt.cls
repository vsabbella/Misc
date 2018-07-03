public with sharing class RequisitionToPurchaseOrdersExt extends BaseController{

    private ApexPages.StandardSetController setCon;
    public static String NspaceUU { get { return KSE.NamespaceUU; }} 
    private static SchemaUtil util = SchemaUtil.getInstance();
	public GridRelatedListController.GridRelatedListConfig POLinesConfig {get; set;}
    public GridRelatedListController.GridRelatedListConfig ReqLinesConfig {get; set;}
    public GridRelatedListController.GridRelatedListConfig AgreementLinesConfig {get; set;}
    public GridRelatedListController.GridRelatedListConfig ReqLinesUpdatedConfig {get; set;}
    public GridRelatedListController.GridRelatedListConfig ReqLinesFilterConfig {get; set;}
	public String POLinesFieldList = null;
    public String AgrLinesFieldList = null;
    public String ReqLinesFieldList = null; 
    public String ReqLinesupdateFieldList = null; 
    public String ReqLinesFiltersFieldList = null;
	public String NamespaceUU { get { return KSE.NamespaceUU; }}
    public List<Requisition__c> reqList {get;set;}
    public Id defaultCompany{ get; set;}
    public Id defaultFacility{ get; set;}
    public Id defaultSource {get;set;}
    public String buildOption {get; set;}
    public Boolean tabView { get; set;} { tabView = true; }
    public string HelpURL{get;set;}

    public map<string,string> queryMapPAL{get;set;}
    public string palQuery{get;set;}
    public string palQueryCondition{get;set;}

    // to use build options when we support both manual and automatic release process
    public List<SelectOption> getbuildOptions(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('1', 'Requisition Quantity <= Agreement Quantity'));//   (Requisition will be fulfilled only if the system finds an agreement with the sufficient Quantity)'));
        //options.add(new SelectOption('2', 'Requisition Quantity > Agreement Quantity    (Requisiton will be fulfilled partially when the system finds an agreement)'));
        //options.add(new SelectOption('3', 'Requisition Quantity = Manual PO             (Requisiton will be fulfilled with Manual PO when system does not find any Agreement)'));
        return options;
    }
	
    public RequisitionToPurchaseOrdersExt(ApexPages.StandardSetController standardController)
    {
        setCon = standardController;
        buildOption = '1';
        HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpRequisitionRelease';
        if(setCon.getSelected().size() == 0){
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_Records_Selected) );
        }
        reqList = setCon.getSelected();
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id userId = UserInfo.getUserID();
		
		SOQLUtil soql = new SOQLUtil('User_Preference__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Default_Company__c','Default_Facility__c'
		});
		soql.setWhereClause('ownerId = :userId');
		soql.setLimit(1);

		List<User_Preference__c> u = Database.query(soql.getQuery());

        if (u.size() > 0){
            if (u[0].Default_Company__c != null)
                defaultCompany = u[0].Default_Company__c;
            if (u[0].Default_Facility__c != null)
                defaultFacility = u[0].Default_Facility__c;
        }
        // PO Lines Grid config 
        POLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        POLinesConfig.uniqueId = 'POLinesGrid';
        POLinesConfig.title = 'Purchase Order Lines';
        POLinesConfig.objectName = 'Purchase_Order_Line__c';
        POLinesConfig.fieldset = 'Requisition_Release';
        POLinesConfig.buttons = 'columnmenu, search';   
        POLinesConfig.alwaysUseFullDateTimeFormat = false;

        // Req Lines Grid config
        ReqLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        ReqLinesConfig.uniqueId = 'ReqLinesGrid';
        ReqLinesConfig.title = 'Requisition Lines';
        ReqLinesConfig.objectName = 'Requisition_Line__c';
        ReqLinesConfig.fieldset = 'Requisition_Release';
        ReqLinesConfig.buttons = 'columnmenu, search';  
        ReqLinesConfig.alwaysUseFullDateTimeFormat = false;

        // Req Lines to update the supplier
        ReqLinesUpdatedConfig = new GridRelatedListController.GridRelatedListConfig();
        ReqLinesUpdatedConfig.uniqueId = 'ReqLinesUpdatedGrid';
        ReqLinesUpdatedConfig.title = 'Requisition Lines';
        ReqLinesUpdatedConfig.objectName = 'Requisition_Line__c';
        ReqLinesUpdatedConfig.fieldset = 'Requisition_Release';
        ReqLinesUpdatedConfig.buttons = 'columnmenu, search';  
        ReqLinesUpdatedConfig.alwaysUseFullDateTimeFormat = false;

        // Agreement Lines to update the supplier
        AgreementLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        AgreementLinesConfig.uniqueId = 'AgrLinesGrid';
        AgreementLinesConfig.title = 'Agreement Lines';
        AgreementLinesConfig.objectName = 'Contract_Line__c';
        AgreementLinesConfig.fieldset = 'Line_Release';
        AgreementLinesConfig.buttons = 'columnmenu, search';  
        AgreementLinesConfig.alwaysUseFullDateTimeFormat = false;

        ReqLinesFilterConfig = new GridRelatedListController.GridRelatedListConfig();
        ReqLinesFilterConfig.uniqueId = 'ReqLinesFilterConfigGrid';
        ReqLinesFilterConfig.objectName = 'Requisition_Line__c';
        ReqLinesFilterConfig.fieldset = 'Requisition_Release_Filters';
        
        queryMapPAL = getAgreementLinesQuery();
        palQuery = queryMapPAL.get('Query');
        palQueryCondition = queryMapPAL.get('Condition');
        
    }
	public String getPOLinesConfigJson() {
        String configStr = JSON.serialize(this.POLinesConfig);
          
        return configStr; 
    }
	public string getPOLinesFieldList() {
        if (POLinesFieldList == null && POLinesConfig != null) {
        	FieldInfo fieldInfoItem;
        	// get the contract lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(POLinesConfig.objectName, POLinesConfig.fieldset);
            Set<String> hiddenFields = new Set<String> { 'Id' };
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
            	String fieldName = fieldInfoList[i].field;
            	fieldInfoList[i].field = fieldName;
            	fieldInfoList[i].editable = false;
            	fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            }
            
            POLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return POLinesFieldList;
    }

    public String getReqLinesConfigJson() {
        String configStr = JSON.serialize(this.ReqLinesConfig);
          
        return configStr; 
    }
    public string getReqLinesFieldList() {
        if (ReqLinesFieldList == null && ReqLinesConfig != null) {
            FieldInfo fieldInfoItem;
            // get the contract lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(ReqLinesConfig.objectName, ReqLinesConfig.fieldset);
            Set<String> hiddenFields = new Set<String> { 'Id' };
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                fieldInfoList[i].field = fieldName;
                fieldInfoList[i].editable = false;
                fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            }
            
            ReqLinesFieldList = JSON.serialize(fieldInfoList);
        }
        return ReqLinesFieldList;
    }

    public String getAgrLinesConfigJson() {
        String configStr = JSON.serialize(this.AgreementLinesConfig);
          
        return configStr; 
    }
    public string getAgrLinesFieldList() {
        if (AgrLinesFieldList == null && AgreementLinesConfig != null) {
            FieldInfo fieldInfoItem;
            // get the contract lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(AgreementLinesConfig.objectName, AgreementLinesConfig.fieldset);
            Set<String> hiddenFields = new Set<String> { 'Id' };
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                fieldInfoList[i].field = fieldName;
                fieldInfoList[i].editable = false;
                fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
                if (KSE.FieldUsedtoReleasePO == 'Available_Quantity__c' && fieldName == 'Remaining_Quantity__c')
            		fieldInfoList[i].hidden = true;
        		if (KSE.FieldUsedtoReleasePO == 'Remaining_Quantity__c' && fieldName == 'Available_Quantity__c')
        			fieldInfoList[i].hidden = true;
            }
            
            AgrLinesFieldList = JSON.serialize(fieldInfoList);
        }
        return AgrLinesFieldList;
    }

    public String getReqLinesupdateConfigJson() {
        String configStr = JSON.serialize(this.ReqLinesUpdatedConfig);
          
        return configStr; 
    }
    public string getReqLinesupdateFieldList() {
        integer count = 0;
        if (ReqLinesupdateFieldList == null && ReqLinesUpdatedConfig != null) {
            FieldInfo fieldInfoItem;
            // get the contract lines field info list
            List<FieldInfo> fieldInfoList1 = FieldInfo.fetchJsonFieldInfos(ReqLinesUpdatedConfig.objectName, ReqLinesUpdatedConfig.fieldset);
            List<FieldInfo> fieldInfoList2 = FieldInfo.fetchJsonFieldInfos(AgreementLinesConfig.objectName, AgreementLinesConfig.fieldset);
            List<FieldInfo> fieldInfoList = new List<FieldInfo>();
            Set<String> hiddenFields = new Set<String> { 'Id' };
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList1.size(); i++){
                if (count < 7){
                    String fieldName = fieldInfoList1[i].field;
                    fieldInfoList1[i].field = 'reqLine.'+fieldName;
                    fieldInfoList1[i].editable = false;   
                    fieldInfoList1[i].hidden = hiddenFields.contains(fieldName);
                    fieldInfoList.add(fieldInfoList1[i]);
                    count++;
                    system.debug('fieldInfoList1[i]--'+fieldInfoList1[i]);
                }
            }
            
            count = 0;
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList2.size(); i++){
                if (count < 5){
                    String fieldName = fieldInfoList2[i].field;
                    fieldInfoList2[i].field = 'ctLine.'+fieldName;
                    fieldInfoList2[i].editable = false;   
                    fieldInfoList2[i].hidden = hiddenFields.contains(fieldName);
                    fieldInfoList.add(fieldInfoList2[i]);
                    count++;
                }
            }
            
            ReqLinesupdateFieldList = JSON.serialize(fieldInfoList);
        }
        return ReqLinesupdateFieldList;
    }

    public String getReqLinesFiltersConfigJson() {
        String configStr = JSON.serialize(this.ReqLinesFilterConfig);
          
        return configStr;
    }
    
    public string getReqLinesFiltersFieldList() {
        if (ReqLinesFiltersFieldList == null && ReqLinesFilterConfig != null) {
            FieldInfo fieldInfoItem;
            
            try{
                List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(ReqLinesFilterConfig.objectName, ReqLinesFilterConfig.fieldset);
                fieldInfoList.remove(0); // Remove the ID element from the list
                for (FieldInfo f : fieldInfoList){
                    f.required = false;
                }
                ReqLinesFiltersFieldList = JSON.serialize(fieldInfoList);
            }
            catch(FieldInfo.EmptyFieldSetMemberException e){
                ReqLinesFiltersFieldList = '';
            }
        }
    
        return ReqLinesFiltersFieldList;
    }
    
	@RemoteAction
	public static JsonResult getPOLines(List<Requisition_Line__c> reqLinesList) {
		JsonResult result = new JsonResult();
		List<Purchase_Order_Line__c> cLinesList = new List<Purchase_Order_Line__c>();
        set<id> reqLineIds = new set<id>();
        set<id> poLineIds = new set<id>();

        for (Requisition_Line__c reqLine : reqLinesList){
            reqLineIds.add(reqLine.Id);
        }

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Requisition_Cross_Reference__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Requisition_Line__c','Purchase_Order_Line__c'
		});
		soql.setWhereClause('Requisition_Line__c in :reqLineIds');

		List<Requisition_Cross_Reference__c> reqCrossRefs = Database.query(soql.getQuery());

        for (Requisition_Cross_Reference__c reqCR : reqCrossRefs){
            poLineIds.add(reqCR.Purchase_Order_Line__c);
        }

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','name','Purchase_Order__r.Name','Contract_Line__r.Name','Company__r.Name','Item__r.name','Need_Date__c','Order_Quantity__c',
			'Unit_Price__c'
		});
		soql.setWhereClause('Id in :poLineIds');

		clinesList = Database.query(soql.getQuery());

		result.records = clinesList;
        result.total = clinesList.size();
        
        return result;
	}

    public map<string,string> getAgreementLinesQuery() {
        
        map<string,string> qryMap = new map<string,string>();
        String contractLinesQuery = null;
        
        string whereClause = '';
        string conditionalClause = '';
        
        //KNDY-9478 - Removed the below from query
        //and Contract__r.Ship_to_Facility__c = :facilityId
		
		SOQLUtil soql = new SOQLUtil('Contract_Line__c');
	    soql.addFields('Line_Release');
	    soql.addFields('Tiers');
	    soql.addFields(new set<string>{'Id','Line__c','UOM__c','Purchased_Quantity__c','Invoice_Matching__c','Contract__r.Company__c','Contract__r.Ship_to_Facility__c', 'Contract__r.Currency__c', 'Contract_Quantity__c', 'Location__c', 'Status__c','Contract__r.Payment_Term__c', 'Contract__r.Payment_Term__r.id', 'Contract__r.FOB_Term__c', 
                        'Contract__r.FOB_Term__r.id', 'Contract__r.Supplier__c','Contract__r.Supplier__r.Remit_To__c', 'Contract__r.Transportation_Mode__c', 'Consigned__c', 'Type__c','Contract__r.Contract_Number__c','Contract__c','Contract__r.Supplier__r.Remit_To__c',
                        'Contract__r.Unit_Price_Tolerance_Over__c','Contract__r.Quantity_Tolerance_Over__c','Contract__r.Amount_Tolerance__c',
                        'Contract__r.Supplier__r.Default_Receiving_Tolerance__c','Contract__r.Approval_Status__c','Contract__r.Status__c',
                        'Item__r.Description__c','Item__r.Purchasing_UOM__c'});
	    soql.setWhereClause(whereClause);
	    
	    contractLinesQuery = soql.getQuery();
        
        conditionalClause = 'Status__c = \'Open\' and Remaining_Quantity__c > 0 and Contract__r.Approval_Status__c = \'Approved\' and Contract__r.Status__c = \'Open\' and ';
        
        qryMap.put('Query',contractLinesQuery);
        qryMap.put('Condition',conditionalClause);
        
        return qryMap;
    } 

    @RemoteAction
    public static JsonResult getreqWrapperLines(List<Requisition_Line__c> reqLines) {
        JsonResult result = new JsonResult();
        List<RequisitionService.RequisitionLineWrapper> reqWrapperLines = new List<RequisitionService.RequisitionLineWrapper>();
        system.debug(reqLines);

        Set<id> contractIds = new Set<id>();
        for (Requisition_Line__c reqLine : reqLines){
            if(reqLine.Default_Purchase_Agreement_Line__c != null){
                contractIds.add(reqLine.Default_Purchase_Agreement_Line__c);
            }
        }

        //KNDY-18740 - Get contract line info for all lines that has a Default_Purchase_Agreement_Line__c
        SOQLUtil soql = new SOQLUtil('Contract_Line__c');
        soql.addFields('Line_Release');
        soql.addFields('Tiers');
        soql.addFields(new set<string>{'Id','Line__c','UOM__c','Purchased_Quantity__c','Invoice_Matching__c','Contract__r.Company__c','Contract__r.Ship_to_Facility__c', 'Contract__r.Currency__c', 'Contract_Quantity__c', 'Location__c', 'Status__c','Contract__r.Payment_Term__c', 'Contract__r.Payment_Term__r.id', 'Contract__r.FOB_Term__c',
                'Contract__r.FOB_Term__r.id', 'Contract__r.Supplier__c','Contract__r.Supplier__r.Remit_To__c', 'Contract__r.Transportation_Mode__c', 'Consigned__c', 'Type__c','Contract__r.Contract_Number__c','Contract__c','Contract__r.Supplier__r.Remit_To__c',
                'Contract__r.Unit_Price_Tolerance_Over__c','Contract__r.Quantity_Tolerance_Over__c','Contract__r.Amount_Tolerance__c',
                'Contract__r.Supplier__r.Default_Receiving_Tolerance__c','Contract__r.Approval_Status__c','Contract__r.Status__c',
                'Item__r.Description__c','Item__r.Purchasing_UOM__c'});
        soql.setWhereClause('Id in :contractIds');

        List<Contract_Line__c> contractLines = Database.query(soql.getQuery());
        Map<id, Contract_Line__c> contractLineMap = new Map<id, Contract_Line__c>(contractLines);

        for (Requisition_Line__c reqLine : reqLines){
            RequisitionService.RequisitionLineWrapper r = new RequisitionService.RequisitionLineWrapper();
            r.reqLine = reqLine;
            r.itemID = reqLine.Item__c;
            if(reqLine.Default_Purchase_Agreement_Line__c != null){
              r.ctLine = contractLineMap.get(reqLine.Default_Purchase_Agreement_Line__c);
            }else{
              r.ctLine = new Contract_Line__c();
            }
            reqWrapperLines.add(r);
        }

        result.records = reqWrapperLines;
        result.total = reqWrapperLines.size();
        
        return result;
    } 

    @RemoteAction
    public static JsonResult copyAgreementLines(List<RequisitionService.RequisitionLineWrapper> reqWrapperLines) {
        JsonResult result = new JsonResult();
		List<Contract_Line__c> ctLines = new List<Contract_Line__c>();
		String addlFields = 'name';
        String whereClause = 'Status__c = \'Open\' LIMIT 1';

        SOQLUtil soql = new SOQLUtil('Contract_Line__c');
	    soql.addFields('Line_Release');
	    soql.addFields(addlFields);
	    soql.setWhereClause(whereClause);
	    
        ctLines = Database.query(soql.getQuery());
        system.debug(logginglevel.info,'ctLines--'+ctLines);
        
        for (RequisitionService.RequisitionLineWrapper reqWrapperLine : reqWrapperLines){
            reqWrapperLine.ctLine = ctLines[0];
            }

        result.records = reqWrapperLines;
        result.total = reqWrapperLines.size();
        
        return result;
    }

    @RemoteAction
    public static JsonResult getreqLines(List<KendoUtils.FilterDescriptor> filters, GridRelatedListController.GridRelatedListConfig config, Requisition_Line__c reqLine) {

        JsonResult result = new JsonResult();
        List<Requisition_Line__c> reqLinesList = new List<Requisition_Line__c>(); 
        List<FieldInfo> addlSearchFilterFields = new List<FieldInfo>();

        try{
            addlSearchFilterFields = FieldInfo.fetchJsonFieldInfos('Requisition_Line__c', 'Requisition_Release_Filters');
        }catch(FieldInfo.EmptyFieldSetMemberException e){
            addlSearchFilterFields = new List<FieldInfo>();
        }

        Set<String> addlFields = new Set<String>();
        List<KendoUtils.FilterDescriptor> addSearchFilters = new List<KendoUtils.FilterDescriptor>();
        
        for (FieldInfo fld: addlSearchFilterFields) {
            if (reqLine.get(fld.field) != null && reqLine.get(fld.field) != '')  {
                KendoUtils.FilterDescriptor fd = new KendoUtils.FilterDescriptor();

                fd.field = fld.field;
                fd.value = reqLine.get(fld.field);
                fd.fieldType = fld.fieldType;
                fd.operator = 'eq';
                
                filters.add(fd); 
            }
        }

        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';

        addlFields.addAll(util.getAllCustomFieldsFromObject('Requisition__r.','Requisition__c'));
        /*
        KNDY-18740 - Need not query the contract line related fields here
        addlFields.addAll(util.getAllCustomFieldsFromObject('Default_Purchase_Agreement_Line__r.','Contract_Line__c'));
        addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.Supplier__c');
        addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.Supplier__r.Remit_To__c');
        addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.Supplier__r.Default_Receiving_Tolerance__c');
		addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.FOB_Term__r.id');
		addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.Company__c');
        addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.Payment_Term__c');
        //addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.Quantity_Tolerance_Under__c');
        addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.Quantity_Tolerance_Over__c');
        addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.Ship_to_Facility__c');
        addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.Amount_Tolerance__c');
        addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.Unit_Price_Tolerance_Over__c');
        //addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.Unit_Price_Tolerance_Under__c');
        addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.Update_Open_PO_Lines__c');
        addlFields.add('Default_Purchase_Agreement_Line__r.Contract__r.Transportation_Mode__c');
        addlFields.add('Default_Purchase_Agreement_Line__r.Item__r.name');
        addlFields.add('Default_Purchase_Agreement_Line__r.Item__r.Description__c');
        */
        addlFields.add('Requisition__r.Ship_To_Customer__r.Address__c');
        addlFields.add('Requisition__r.Sales_Order__c');
        addlFields.add('Requisition__r.Sales_Order__r.name');
        addlFields.add('Requisition__r.Sales_Order__r.Credit_Hold__c');
        addlFields.add('Requisition__r.Sales_Order__r.Override_Credit_Hold__c');
		//KNDY-15405 - Adding these fields manually to avoid errors if the user removes them from fieldset
		addlFields.add('Facility__c'); 
		addlFields.add('Item__c'); 
		addlFields.add('Purchasing_UOM__c'); 
		addlFields.add('Requisition__r.Currency__r.Name'); 

        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        String invoiceInvType = 'Invoice';

        for(KendoUtils.FilterDescriptor fd: filters){
            system.debug(LoggingLevel.info,'Filter: ' + fd);
            String tmp = (String)fd.value;
            String filterVal = tmp.trim(); //make sure only if the value is available add it to the filters that form the query
            if (fd.fieldType == 'date' || fd.fieldType == 'datetime') {
                KendoUtils.FilterDescriptor fd1 = new KendoUtils.FilterDescriptor();
                KendoUtils.FilterDescriptor fd2 = new KendoUtils.FilterDescriptor();
                
                fd1.field = fd.field;
                fd1.fieldType = fd.fieldType;
                fd1.value = fd.value;
                fd1.operator = 'gte';
                
                fd2.field = fd.field;
                fd2.fieldType = fd.fieldType;
                fd2.value = fd.value;
                fd2.operator = 'lte';
                
                newFilters.add(fd1);
                newFilters.add(fd2);
            }else if (filterVal.length() > 0){ //condition that checks for value and adds it to the filters
                newFilters.add(fd);
            }

            if (fd.fieldType == 'picklist' || fd.fieldType == 'reference') 
                fd.fieldType = 'string';    
        }

        List<String> filterCriteria = KendoUtils.getFilterCriteria(newFilters);
        filterCriteria.add('Status__c = \'Open\'');
        filterCriteria.add('Remaining_Quantity__c > 0');
        filterCriteria.add('Requisition__r.Status__c = \'Open\'');
        filterCriteria.add('Requisition__r.Approval_Status__c = \'Approved\'');
        
        String whereClause = '';
        
        if (filterCriteria.size() > 0) {
            whereClause += String.join(filterCriteria, ' AND ');
        }
        
        if(String.isNotBlank(config.sortField)){
            whereClause += ' ORDER BY ' + config.sortField;
            if(String.isNotBlank(config.sortOrder)){
                whereClause += ' ' + config.sortOrder;
            }
        }

        //String queryString = util.generateQueryFromFieldSet(config.objectName, new Set<string>{ fieldset }, addlFields, whereClause);
        
        SOQLUtil soql = new SOQLUtil(config.objectName);
	    soql.addFields(fieldset);
	    soql.addFields(addlFields);
	    soql.setWhereClause(whereClause);
	    
        reqLinesList = Database.query(soql.getQuery());   
        system.debug(LoggingLevel.info, 'db result' + reqLinesList);

        result.records = reqLinesList; 
        result.total = reqLinesList.size();
        
        return result;
    }
	
    /*
    Remote action that created PO Lines from Req Lines automatically - Step by step process
        1. Req Lines are sent to the service class
        2. Agreement Lines for the items from step 1 are fetched
        3. With the Req Lines List and Agreement Lines list in step 2, wrapper records are created
            3.1. Wrapper records are created based on quantity check, supplier-facility matching
            3.2. Also validates if the same contract line can be used to fulfill more than 1 req line
        4. Unique PO Map is created looping through all the wrapper records created in step 3
            4.1. Now, the uniqueness is obtained by Req Name (auto number) ie., for every Req a PO is created
            4.2. To create single PO for more than one req, step 4 has to be modified based on the condition defined in the requirements
        5. Loop through unique PO Map and create PO and corresponding lines. Attributes for the PO and POL are taken either from Req Line or from contract Line
        6. Requisition Cross Ref records are created based on Req Line --> Contract Line and Contract Line --> PO Line maps
    */
    @RemoteAction
    public static JsonResult releaseReqLines(ID companyId, ID facilityId, List<Requisition_Line__c> reqLineList) {
        JsonResult result = new JsonResult();
        List<Purchase_Order_Line__c> POLines = new List<Purchase_Order_Line__c>();
        RequisitionService rs = new RequisitionService();

        for (Requisition_Line__c reqLine : reqLineList){
            if (reqLine.Remaining_Quantity__c <= 0){
                result.success = false;
                result.addMessage(Label.Cannot_Release_Requisition_Lines_with_no_remaining_qty, ApexPages.Severity.ERROR);
                return result;
            }
        }

        result = rs.createPOfromReqLines(companyId, facilityId, reqLineList); 
        result.total = reqLineList.size();
        result.records = reqLineList;

        return result;
    }
	
	/*
    Remote action that created PO Lines from Req Lines manually - Step by step process
        1. User establises the link between the req line to contract line, ie., the user actually creates the wrapper records and the wrapper is sent to the service class
        2. With the wrapper records available, steps followed are same as the automatic release from step 4
    */
    @RemoteAction
    public static JsonResult releaseReqLines_manual(List<RequisitionService.RequisitionLineWrapper> reqLineList) {
        JsonResult result = new JsonResult();
        RequisitionService rs = new RequisitionService();
        set<Id> reqFacilities = new set<Id>();

        for (RequisitionService.RequisitionLineWrapper r : reqLineList){
            reqFacilities.add(r.reqLine.Facility__c); 
        }

        result = rs.createPOsfromReqWrapper(reqLineList, false, reqFacilities);
        result.total = reqLineList.size();
        result.records = reqLineList;

        return result;
    }
    
} //End of the Ext class