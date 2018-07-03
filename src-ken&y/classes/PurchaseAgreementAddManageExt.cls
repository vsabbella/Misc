public with sharing class PurchaseAgreementAddManageExt extends BaseController {
	
	ApexPages.StandardController con;
	public string NamespaceUU { get { return KSE.NamespaceUU; }}
	public string pageTitle { get; set; }
	private static SchemaUtil util = SchemaUtil.getInstance();
	public Contract__c purchaseAgreement { get; set; }
    public GridRelatedListController.GridRelatedListConfig purchaseAgreementLinesConfig {get; set;} 
    public String purchaseAgreementLinesFieldList = null;
    public List<Grid_Views_Config__c> customViewList = null;
    public Map<String, FieldInfo> allFieldsMap = new Map<String, FieldInfo>();


	public PurchaseAgreementAddManageExt(ApexPages.StandardController controller) {


        con = controller;
        
        if( controller.getRecord().id != null ){
            purchaseAgreement = (Contract__c) controller.getRecord();
            pageTitle = 'Purchase Agreement ' + purchaseAgreement.Name;
            if (ApexPages.currentPage().getParameters().containsKey('clone') && 
                ApexPages.currentPage().getParameters().get('clone') == '1'){// KNDY-10083
                pageTitle = 'Clone of Purchase Agreement ' + purchaseAgreement.Name;
                purchaseAgreement.Status__c = 'Draft';
                purchaseAgreement.Approval_Status__c = 'Pending Authorization';
                purchaseAgreement.Contract_Start__c = system.today();
            }
        }
        else{
            purchaseAgreement = new Contract__c();
            pageTitle = 'Purchase Agreement';
            purchaseAgreement.Contract_Start__c = system.today();
        }
          
        Set<String> purchaseAgreementLinesAdditionalFields = new Set<String>();

        purchaseAgreementLinesAdditionalFields.addAll(new set<string>{'Id','Name', 'Item__r.Source__c'});
        
        CompanyService compServ = new CompanyService(controller);
        purchaseAgreement.Company__c = CompanyService.getDefaultCompanyId();
        purchaseAgreement.Company__r = compServ.Company;
        purchaseAgreement.Currency__r = CompanyService.defaultTransactionCurrencyRec(purchaseAgreement.Company__c);
        if(purchaseAgreement.Currency__r != null){
        purchaseAgreement.Currency__c = CompanyService.defaultTransactionCurrencyRec(purchaseAgreement.Company__c).Id;
        }
        purchaseAgreement.status__c = 'Draft';
        purchaseAgreement.Approval_Status__c = 'Pending Authorization';
       

        // Purchase Agreement Lines Grid config
        purchaseAgreementLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        purchaseAgreementLinesConfig.uniqueId = 'PurchaseAgreementLinesGrid';
        purchaseAgreementLinesConfig.title = 'Purchase Agreement Lines';
        purchaseAgreementLinesConfig.parentRecord = purchaseAgreement;
        purchaseAgreementLinesConfig.objectName = 'Contract_Line__c';  
        purchaseAgreementLinesConfig.parentField = 'Contract__c';
        purchaseAgreementLinesConfig.buttons = 'create, delete, columnmenu, search';
        purchaseAgreementLinesConfig.sortField = 'Line__c'; //KNDY-10083
        purchaseAgreementLinesConfig.sortOrder = 'ASC'; //KNDY-10083
        purchaseAgreementLinesConfig.additionalFields = String.join(new List<String>(purchaseAgreementLinesAdditionalFields), ',');  
	}

	public String getReturnUrl(){
        PageReference pageRef;
        
        if (purchaseAgreement != null && purchaseAgreement.Id != null ){
            pageRef =  new PageReference('/' + purchaseAgreement.Id);
        }
        else{
            Schema.DescribeSObjectResult dsr = Contract__c.SObjectType.getDescribe();
            pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        }
        
        return pageRef.getUrl();
    }
    
    public String getDeleteUrl(){
        PageReference pageRef;
        
        Schema.DescribeSObjectResult dsr = Contract__c.SObjectType.getDescribe();
        pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        
        return pageRef.getUrl();
    }

    public string getPurchaseAgreementJSON() {
		return JSON.serialize(purchaseAgreement);  
    }



    public string getPurchaseAgreementHeaderFieldList() {
        String purchaseAgreementHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        Set<String> readOnlyFields = new Set<String>();
        
        // get the purchase agreement header field info list
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Contract__c', 'New_Purchase_Agreement');
        
        List<FieldInfo> fieldInfoList_ROfields = FieldInfo.fetchJsonFieldInfos('Contract__c', 'Purchase_Agreement_RO');
        
        for (Integer i = 0; i<fieldInfoList_ROfields.size(); i++){
            readOnlyFields.add(fieldInfoList_ROfields[i].field);
        }
        
        fieldInfoList.remove(0); // Remove Id field from the list
        
        for(Integer i = 0; i < fieldInfoList.size(); i++) {
            if (readOnlyFields.contains(fieldInfoList[i].field)){
                fieldInfoList[i].editable = false;
            }
        }
            
        purchaseAgreementHeaderFieldList = JSON.serialize(fieldInfoList);
        
        return purchaseAgreementHeaderFieldList;
    }

    public string getPurchaseAgreementAddlHeaderFieldList() {
        String purchaseAgreementAddlHeaderFieldList = '';
        List<FieldInfo> result = new List<FieldInfo>();
        Set<String> headerFields = new Set<String>();
        List<FieldInfo> headerList = (List<FieldInfo>) JSON.deserialize(getPurchaseAgreementHeaderFieldList(), List<FieldInfo>.class);
        Set<String> readOnlyFields = new Set<String>();
        
        for(Integer i = 0; i < headerList.size(); i++){
            headerFields.add(headerList[i].field);
        }
        
        try {
            // get the PA addl header field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Contract__c', 'New_Purchase_Agreement_Tolerances');
            
            List<FieldInfo> fieldInfoListRO = FieldInfo.fetchJsonFieldInfos('Contract__c', 'Purchase_Agreement_RO');
            for (Integer i = 0; i<fieldInfoListRO.size(); i++){
                readOnlyFields.add(fieldInfoListRO[i].field);
            } 
            
            fieldInfoList.remove(0);    // Remove Id field from the list
            
            for(Integer i = 0; i < fieldInfoList.size(); i++) {
                if (!headerFields.contains(fieldInfoList[i].field)) {
                	if (fieldInfoList[i].field == 'Status__c') {  
                		fieldInfoList[i].editable = false;
                	}
                    else if (readOnlyFields.contains(fieldInfoList[i].field)){
                        fieldInfoList[i].editable = false;
                    }
                	
                    result.add(fieldInfoList[i]);
                }
            }
            
            purchaseAgreementAddlHeaderFieldList = (result.size() > 0) ? JSON.serialize(result) : '';
        }
        catch (FieldInfo.EmptyFieldSetMemberException e) {
            purchaseAgreementAddlHeaderFieldList = '';
        }
        
        return purchaseAgreementAddlHeaderFieldList;
    }

    public string getPurchaseAgreementLinesConfigJson() {
        String configStr = JSON.serialize(this.purchaseAgreementLinesConfig);
          
        return configStr;
    }

    public string getPurchaseAgreementLinesFieldList() {
        if (purchaseAgreementLinesFieldList == null && purchaseAgreementLinesConfig != null) {
            // get the purchase agreement lines field info list
            getCustomViewFields();
            List<FieldInfo> fieldInfoList = allFieldsMap.values();
            List<FieldInfo> fieldInfoListRO = FieldInfo.fetchJsonFieldInfos('Contract_Line__c', 'Purchase_Agreement_Line_RO');

            Set<String> readOnlyFields = new Set<String>();
            
            for (Integer i = 0; i<fieldInfoListRO.size(); i++){
                readOnlyFields.add(fieldInfoListRO[i].field);
            } 

            //Have fields read only in the PA lines grid
            for(Integer i = 0; i < fieldInfoList.size(); i++) {
                if (readOnlyFields.contains(fieldInfoList[i].field)){
                    fieldInfoList[i].editable = false;
                    fieldInfoList[i].hidden = true;
                }
            }
             
            purchaseAgreementLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return purchaseAgreementLinesFieldList;
    }
    public String getAllFields(){
        if (allFieldsMap.keySet().isEmpty()){
            getCustomViewFields();
        }

        return JSON.serialize(allFieldsMap.keySet());
    }
    /*
     *  getUIFieldNames method prepares and puts the UI field names in a list and returns it.
     *
     *  @param  fieldInfoList
     *  @return List<String>    
     *
     */
    private List<String> getUIFieldNames(List<FieldInfo> fieldInfoList){
        List<String> fieldNames = new List<String>();

        for(FieldInfo f: fieldInfoList){
            if(f.field != 'Id'){
                fieldNames.add(f.field);   
            }
            
        }

        return fieldNames;
    }
    
    /*
     *  getCustomViews method prepares the list of views to be listed on the dropdown box in the UI
     *
     *  @param  fieldInfoList
     *  @param  fieldName
     *  @return Integer    
     *
     */
    public String getCustomViews() { 
        List<SelectListItem> viewList = new List<SelectListItem>();
        List<Grid_Views_Config__c> customViewList = this.customViewList == null ? KSE.getGridViews('PurchaseAgreementLinesGrid') : this.customViewList;
        // use for preventing duplicate field set values in grid views
        Set<String> existingViews = new Set<String>();

        existingViews.add('manage_lines');

        for(Grid_Views_Config__c gvConfig: customViewList){

            if (!existingViews.contains(gvConfig.Fieldset_Name__c.toLowerCase())){

                viewList.add(new SelectListItem(gvConfig.Fieldset_Name__c, gvConfig.View_Name__c));
                existingViews.add(gvConfig.Fieldset_Name__c.toLowerCase());

            }
        }

        if (customViewList.isEmpty() || customViewList[0].View_Dropdown_Index__c == 0){
            viewList.add(new SelectListItem('manage_lines', 'Default'));
        } else {
            viewList.add(0,new SelectListItem('manage_lines', 'Default'));
        }
        return JSON.serialize(viewList);
    }
    /*
     *  getCustomViewFields method fetches list of fields on associated with a fieldset that are part of the custom views
     *
     *  @return String    
     *
     */
    public String getCustomViewFields() {

        Map<String, List<String>> customViewFieldsMap = new Map<String, List<String>>();
        
        List<Grid_Views_Config__c> customViewList = this.customViewList == null ? KSE.getGridViews('PurchaseAgreementLinesGrid') : this.customViewList;

        customViewList.add(new Grid_Views_Config__c(Fieldset_Name__c = 'manage_lines'));

        for(Grid_Views_Config__c gvConfig: customViewList){

            List<String> fieldNames = new List<String>();
            //Ignore the fieldset that has been loaded already
            if(customViewFieldsMap.containsKey(gvConfig.Fieldset_Name__c)){
                continue;
            }

            try {

                List<FieldInfo> fieldList = FieldInfo.fetchJsonFieldInfos('Contract_Line__c', gvConfig.Fieldset_Name__c);
                for (FieldInfo fi : fieldList){
                    if (!allFieldsMap.containsKey(fi.field) || fi.required){
                        allFieldsMap.put(fi.field, fi);
                    }
                }
               
                fieldNames = getUIFieldNames(fieldList);

            } catch (FieldInfo.EmptyFieldSetMemberException e) {
                //ignnore invalid fieldsets
            }
    
            customViewFieldsMap.put(gvConfig.Fieldset_Name__c, fieldNames);
        }
        return JSON.serialize(customViewFieldsMap);
    }

    
    @RemoteAction
    public static JSONResult getCompanyInfo( Id companyId){
    	JSONResult result = new JSONResult();
    	if(companyId != null){
    		Company__c company = CompanyService.getCompanyInfo(companyId);
    		result.success = true;
    		result.records = new List<Company__c>{company};
    		result.total = 1;
    	}
    	return result;
    }
    
    @RemoteAction
    public static JSONResult getSupplierDetails( Id supplierId){
        JSONResult result = new JSONResult();
        list<Supplier__c> suppliers = [ select Id, Invoice_Matching__c, Currency__c, Currency__r.id, Currency__r.name
                                     From Supplier__c where Id = :supplierId ];
        
        if( suppliers.size() == 1 ){
            Supplier__c supp = suppliers[0];
            result.success = true;
            result.total = 1;
            result.records = new List<Supplier__c>{supp};
        }
        return result;
    }

    @RemoteAction 
    public static JsonResult getItemDetails(ID itemId) {
        List<Item__c> items;
        JsonResult result = new JsonResult();
        
        //String queryString = 'Select Id, Name, Purchasing_UOM__c, Purchasing_UOM__r.Name From Item__c Where ID = \'' + itemId + '\' and Active__c = true limit 1';
        
        String whereClause = 'ID = \'' + itemId + '\' and Active__c = true limit 1';
        
	    SOQLUtil soql = new SOQLUtil('Item__c'); // KNDY-10891
	    soql.addFields(new Set<String>{'Id', 'Name', 'Purchasing_UOM__c', 'Purchasing_UOM__r.Name', 'Source__c'});
	    soql.setWhereClause(whereClause);
	    
        items = Database.query(soql.getQuery());    
        
        Integer total = (items != null) ? items.size() : 0;
        result.total = total;
        result.records = items;
        
        return result;
    }

    @RemoteAction
    public static JsonResult getPurchaseAgreementDetails(Id purchaseAgreementId, String clone) { 
        String objectName = 'Contract__c';
        String headerFieldset = 'New_Purchase_Agreement';  
        String addlHeaderFieldset = 'New_Purchase_Agreement_Tolerances';
        Set<String> addlFields = new Set<String> { 'Company__c', 'Supplier__c', 'Supplier__r.Id', 'Supplier__r.Invoice_Matching__c' };      
        string whereClause = 'Id  = :purchaseAgreementId LIMIT 1';
        
        //String queryString = util.generateQueryFromFieldSet(objectName, new Set<string>{ headerFieldset, addlHeaderFieldset }, addlFields, whereClause);
		
		SOQLUtil soql = new SOQLUtil(objectName);
	    soql.addFields(headerFieldset);
	    soql.addFields(addlHeaderFieldset);
	    soql.addFields(addlFields);
	    soql.setWhereClause(whereClause);
	    
        List<Contract__c> purchaseagreement = Database.query(soql.getQuery());   
        if ( clone != null && clone == '1'){ // KNDY-10083
            // Copy the PA
            Contract__c paClone = purchaseagreement[0].clone(false, true);
            // reset fields
            paClone.Status__c = 'Draft';
            paClone.Approval_Status__c = 'Pending Authorization';
            paClone.Contract_Start__c = system.today();
            paClone.Contract_End__c = null;
            User u = [select Id, Name from User where Id = :UserInfo.getUserID()];
            paClone.Corporate_Buyer__c = u.Id;
            paClone.Corporate_Buyer__r = u;
            purchaseagreement.clear();
            purchaseagreement.add(paClone);	
        }
        return new JsonResult(purchaseagreement, purchaseagreement.size());
    }

    @RemoteAction 
    public static JsonResult getPurchaseAgreementLines(GridRelatedListController.GridRelatedListConfig config, String clone, List<String>allFields) {
        list<Contract_Line__c> result = new list<Contract_Line__c>();
        Id parentId = (config.parentRecord != null && String.isNotBlank(config.parentRecord.Id)) ? config.parentRecord.Id : '';
        Set<String> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : new Set<String>();
        String parentfield = (String.isNotBlank(config.parentfield)) ? config.parentfield : '';
        
        string whereClause = parentfield + ' = :parentId';
        
        if(String.isNotBlank(config.sortField)){
            whereClause += ' ORDER BY ' + config.sortField;
            if(String.isNotBlank(config.sortOrder)){
                whereClause += ' ' + config.sortOrder;
            }
        }
 
        //String queryString = util.generateQueryFromFieldSet(config.objectName, new Set<string>{ fieldset }, addlFields, whereClause);
        
        SOQLUtil soql = new SOQLUtil(config.objectName);
        soql.addFields( new Set<String>(allFields) );
	    soql.addFields(addlFields);
	    soql.setWhereClause(whereClause);
	    
        result = Database.query(soql.getQuery());   
        system.debug(Logginglevel.info,'getPurchaseAgreementLines-->>'+ result);
        Integer maxLineNumber = 0;
        if ( clone != null && clone == '1'){ // KNDY-10509
            List<Contract_Line__c> clonedLines = new List<Contract_Line__c>();
            for (Contract_Line__c line : result){
                // Copy the line
                Contract_Line__c clonedLine = line.clone(false,true);
                // Reset field values
                maxLineNumber ++;
                clonedLine.Line__c = maxLineNumber;
                clonedLine.Name = '';
                clonedLine.Status__c = 'Open';
                clonedLine.Approved__c = false;
                clonedLine.Quantity_Received__c = 0;
                clonedLine.Quantity_Still_Due__c = 0;
                clonedLine.Contract_Start__c = system.today();
                clonedLine.Contract_End__c = null;
                clonedLine.Purchased_Quantity__c = 0;
                clonedLine.Quantity_Returned__c = 0;
                clonedLine.Quantity_Received__c = 0;
                clonedLine.Quantity_Still_Due__c = 0;
                clonedLine.Contract__c = null;
                clonedLines.add(clonedLine);
            }
            result.clear();
            result.addAll(clonedLines);
        } 
        return new JsonResult(result, result.size());
    }
    
    @RemoteAction
    public static JsonResult cancelLines(List<Contract_Line__c> paLines ) { 

        JsonResult result = new JsonResult();
        ContractService cs = new ContractService();
        result = cs.cancelContractLines(paLines);
        return result;

    }

    @RemoteAction
    public static JsonResult closeLines(List<Contract_Line__c> paLines ) { 

        JsonResult result = new JsonResult();
        ContractService cs = new ContractService();
        result = cs.closeContractLines(paLines);
        return result;

    }
    
    @RemoteAction 
    public static JsonResult cancel(id purchaseAgreementId ) { 
        
        JsonResult result = new JsonResult();
        ContractService cs = new ContractService();
        result = cs.headerActions(purchaseAgreementId, 'Cancelled'); 
        return result;
    }
    
    @RemoteAction
    public static JsonResult close(id purchaseAgreementId ) { 

        JsonResult result = new JsonResult();
        ContractService cs = new ContractService();
        result = cs.headerActions(purchaseAgreementId, 'Closed'); 
        return result;

    }

    @RemoteAction
    public static JsonResult approve(id purchaseAgreementId ) { 
        
        JsonResult result = new JsonResult();
        ContractService cs = new ContractService();
        Savepoint sp = Database.setSavepoint();
        //KNDY-15871
        Set<String> objectName = new Set<String>();

        if (KSE.NamespaceUU != ''){
            objectName.add(KSE.NamespaceUU+'Contract__c');
            objectName.add(KSE.NamespaceUU+'Contract__Line__c');
        }
        else{
            objectName.add('Contract__c');
            objectName.add('Contract__Line__c');
        }

        Boolean isAdmin = false;
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        if(profileName != null && profileName.equalsIgnoreCase('System Administrator')){
            isAdmin = true;
        }

        List<ProcessDefinition> ProcessDefinitionList = [SELECT TableEnumOrId FROM ProcessDefinition WHERE State = 'Active' and TableEnumOrId in :objectName] ;
        if(!isAdmin && ProcessDefinitionList.size() > 0) {
            result.success = false;
            String errorMsg = Label.You_cant_approve_the_source_document;
            errorMsg = errorMsg.replaceAll('<SOURCE DOC>', 'purchase agreement');
            result.addMessage(errorMsg, ApexPages.Severity.ERROR);
        }else{
        	try{
	            result = cs.headerActions(purchaseAgreementId, 'Approved'); 
	            if(!result.success){
	            	String errorMsg = Label.Unable_to_approve_the_purchase_order;
            		errorMsg = errorMsg.replaceAll('order', 'agreement');
	                result.addMessage(errorMsg, ApexPages.Severity.ERROR);
	            }
	        }
	        catch (Exception e) {
	            Database.rollback(sp);
	            result.success = false;
	            result.addMessage('An Error occured : ' + e.getMessage() , ApexPages.Severity.ERROR);
	        }
        	
        }
        return result;

    }

    @RemoteAction
    public static JsonResult deletepa(id purchaseAgreementId ) { 

        JsonResult result = new JsonResult();
        ContractService cs = new ContractService();
        result = cs.headerActions(purchaseAgreementId, 'Delete'); 
        return result;

    }

    @RemoteAction
    public static JsonResult saveAction(Contract__c purchaseAgreement, List<String> headerDateFields, List<Contract_Line__c> updatedList, List<Contract_Line__c> newList, List<Contract_Line__c> deletedList, List<String> dateFields) {
        KendoUtils.UpdateDateFields(purchaseAgreement, headerDateFields);

        
        if (updatedList.size() > 0) {
            for (Contract_Line__c line : updatedList) {
                KendoUtils.UpdateDateFields(line, dateFields);
            }
        }
        
        if (newList.size() > 0) {
            for (Contract_Line__c line : newList) {
                KendoUtils.UpdateDateFields(line, dateFields);
            }
        }
        
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        list<Contract__c> records = new list<Contract__c>();        
        
        //PTP-452 
        if(updatedList.size()>0 || newList.size()>0){
            // KNDY-10599 Item is required on line.
            DataSourceResult dsr = new DataSourceResult();
            dsr = ContractService.paLineItemnotblank(updatedList, newList);
            if (dsr.success == false){
                result.success = false;
                List<Map<String, String>> errorMsgsList = dsr.messages;
                for (Map<String, String> errorMsgsMap: errorMsgsList){
                    result.addMessage(errorMsgsMap.get('message'), ApexPages.Severity.ERROR);
                }
                return result;
            }

            // KNDY-10599 Minimum Order Qty validations
            result = ContractService.validateMOQ(updatedList, newList);
            if (result.success == false){
                return result;
            }
        }
        if(newList.size()>0){
            ContractService cc = new ContractService();
            map<String,string> errorRec = cc.ValidateItemCrossReference(newList,purchaseAgreement.Supplier__c, purchaseAgreement.Ship_to_Facility__c); 
            if (errorRec.containsKey('ASLOn')){
                if (errorRec.get('ASLOn').length() > 0){
                    result.success = false;
                    result.addMessage(Label.Corresponding_Approved_Cross_Reference_is_missing +errorRec.get('ASLOn'), ApexPages.Severity.ERROR);
                    return result;
                }
            }
        }
        
        if (updatedList.size()>0){ 
            ContractService cc = new ContractService();
            map<String,string> errorRec = cc.ValidateItemCrossReference(updatedList,purchaseAgreement.Supplier__c, purchaseAgreement.Ship_to_Facility__c); 
            if (errorRec.containsKey('ASLOn')){
                if (errorRec.get('ASLOn').length() > 0){
                    result.success = false;
                    result.addMessage(Label.Corresponding_Approved_Cross_Reference_is_missing +errorRec.get('ASLOn'), ApexPages.Severity.ERROR);
                    return result;
                }
            }
        }      

           

        try {
            DML.checkUpsertAsUser(purchaseAgreement); upsert purchaseAgreement;
            
            List<Contract_Line__c> purchaseAgreementLines = new List<Contract_Line__c>();
            
            for (Contract_Line__c line : newList) {
                line.Contract__c = purchaseAgreement.Id;
                if (line.Contract_Start__c == null){
                    line.Contract_Start__c = purchaseAgreement.Contract_Start__c;
                }
                if (line.Contract_End__c == null){
                    line.Contract_End__c = purchaseAgreement.Contract_End__c; 
                }
                purchaseAgreementLines.add(line);
            }
            
            for (Contract_Line__c line : updatedList) {
                purchaseAgreementLines.add(line);
            }
            
            DML.checkUpsertAsUser(purchaseAgreementLines); upsert purchaseAgreementLines;

            if (deletedList.size() > 0) {
                //delete Contract lines;
                DML.deleteAsUser(deletedList);
            }
            
            records.add(purchaseAgreement);
            result.records = records;
            result.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
        }
        catch (DMLException e) {
            Database.rollback(sp);
            result.success = false;
            for(integer i=0;i<e.getNumDml();i++) {
                result.addMessage(e.getDmlMessage(i) , ApexPages.Severity.ERROR);
            }
        }

        return result;
    }
}