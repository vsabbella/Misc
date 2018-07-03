public with sharing class RequisitionAddManageExt extends BaseController {
    ApexPages.StandardController con;
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    private static SchemaUtil util = SchemaUtil.getInstance();
    public string pageTitle { get; set; }
    public Requisition__c requisition { get; set; }

    public GridRelatedListController.GridRelatedListConfig requisitionLinesConfig {get; set;}      
    public String requisitionLinesFieldList = null;
    public List<Grid_Views_Config__c> customViewList = null;
    public Map<String, FieldInfo> allFieldsMap = new Map<String, FieldInfo>();
    public Integer max_line_number {get; set;}

    public RequisitionAddManageExt(ApexPages.StandardController controller) {
        con = controller;
        
        if( controller.getRecord().id != null ){
            requisition = (Requisition__c) controller.getRecord();
            pageTitle = 'Requisition ' + requisition.Name;
        }
        else{
            requisition = new Requisition__c();
            pageTitle = 'Requisition';
        }
          
        Set<String> requisitionLinesAdditionalFields = new Set<String>();

        requisitionLinesAdditionalFields.addAll(new set<string>{'Id','Name','Item__r.Source__c','Quantity_Released__c','Approved__c'}); //KNDY-10903
        
        CompanyService compServ = new CompanyService(controller);
        UserPreference usp = UserPreference.getInstance();

        
        //requisition.Transaction_Date__c = System.Today();
        requisition.Type__c = 'Purchase Requisition';
        //PTP-577
        requisition.Source__c = 'Online';
        requisition.Status__c = 'Draft';
        requisition.Approval_Status__c = 'Pending Authorization';
        requisition.Transaction_Date__c = system.today();
        requisition.Company__c = CompanyService.getDefaultCompanyId();
        requisition.Company__r = compServ.Company;
        requisition.Currency__r = CompanyService.defaultTransactionCurrencyRec(requisition.Company__c);
        if(requisition.Currency__r != null){
        requisition.Currency__c = CompanyService.defaultTransactionCurrencyRec(requisition.Company__c).Id;
        }  
        requisition.Requester__c = usp.preference.User__c;
        requisition.Requester__r = usp.preference.User__r;
        
        if(requisition.Company__c != null){
        	Company__c defaultCompany = CompanyService.getCompanyInfo(requisition.Company__c);
        	requisition.Company__r = defaultCompany;
        	requisition.Delivery_Facility__c = defaultCompany.Default_Purchasing_Deliver_To_Facility__c;
        	requisition.Delivery_Facility__r = defaultCompany.Default_Purchasing_Deliver_To_Facility__r;
        }
        
        // Requisition Lines Grid config
        requisitionLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        requisitionLinesConfig.uniqueId = 'RequisitionLinesGrid';
        requisitionLinesConfig.title = 'Requisition Lines';
        requisitionLinesConfig.parentRecord = requisition;
        requisitionLinesConfig.objectName = 'Requisition_Line__c';  
        requisitionLinesConfig.parentField = 'Requisition__c';
        requisitionLinesConfig.buttons = 'create, delete, clone, columnmenu, search';
        requisitionLinesConfig.sortField = 'createdDate';
        requisitionLinesConfig.additionalFields = String.join(new List<String>(requisitionLinesAdditionalFields), ',');  

        max_line_number = getMaxLineNumber(requisition.ID);
    }

    /*
     *  getCustomViews method prepares the list of views to be listed on the dropdown box in the UI
     *
     *  @param  fieldInfoList
     *  @param  fieldName
     *  @return Integer    
     *
     */
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
    public String getCustomViews() {
        List<SelectListItem> viewList = new List<SelectListItem>();
        List<Grid_Views_Config__c> customViewList = this.customViewList == null ? KSE.getGridViews('RequisitionLinesGrid') : this.customViewList;
        Set<String> existingViews = new Set<String>();
         // use for preventing duplicate field set values in custom views
        existingViews.add('requisition_line');
        
        for(Grid_Views_Config__c gvConfig: customViewList){

            if (!existingViews.contains(gvConfig.Fieldset_Name__c.toLowerCase())){

                viewList.add(new SelectListItem(gvConfig.Fieldset_Name__c, gvConfig.View_Name__c));
                existingViews.add(gvConfig.Fieldset_Name__c.toLowerCase());

            }
        }

        if (customViewList.isEmpty() || customViewList[0].View_Dropdown_Index__c == 0){
            viewList.add(new SelectListItem('requisition_line', 'Default'));
        } else {
            viewList.add(0,new SelectListItem('requisition_line', 'Default'));
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
        
        List<Grid_Views_Config__c> customViewList = this.customViewList == null ? KSE.getGridViews('RequisitionLinesGrid') : this.customViewList;

        customViewList.add(new Grid_Views_Config__c(Fieldset_Name__c = 'requisition_line'));

        for(Grid_Views_Config__c gvConfig: customViewList){

            List<String> fieldNames = new List<String>();
            //Ignore the fieldset that has been loaded already
            if(customViewFieldsMap.containsKey(gvConfig.Fieldset_Name__c)){
                continue;
            }

            try {

                List<FieldInfo> fieldList = FieldInfo.fetchJsonFieldInfos(requisitionLinesConfig.objectName, gvConfig.Fieldset_Name__c);
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

    public string getRequisitionJson() {
		return JSON.serialize(requisition);  
    }
    
    public string getRequisitionHeaderFieldList() {
        String requisitionHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        Set<String> readOnlyFields = new Set<String>();
        
        // get the requisition header field info list
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Requisition__c', 'Requisition_Header');
        //PTP-577 Have fields read only on the Requisition Header
        List<FieldInfo> fieldInfoListRO = FieldInfo.fetchJsonFieldInfos('Requisition__c', 'Requisition_Header_RO');
        for (Integer i = 0; i<fieldInfoListRO.size(); i++){
            readOnlyFields.add(fieldInfoListRO[i].field);
        }
        
		fieldInfoList.remove(0); // Remove Id field from the list
        
        for(Integer i = 0; i < fieldInfoList.size(); i++) {
            if (readOnlyFields.contains(fieldInfoList[i].field)){
                fieldInfoList[i].editable = false;
            }
        }
            
        requisitionHeaderFieldList = JSON.serialize(fieldInfoList);
        
        return requisitionHeaderFieldList;
    }
    
    public string getRequisitionAddlHeaderFieldList() {
        String requisitionAddlHeaderFieldList = '';
        List<FieldInfo> result = new List<FieldInfo>();
        Set<String> headerFields = new Set<String>();
        List<FieldInfo> headerList = (List<FieldInfo>) JSON.deserialize(getRequisitionHeaderFieldList(), List<FieldInfo>.class);
        Set<String> readOnlyFields = new Set<String>();
        
        for(Integer i = 0; i < headerList.size(); i++){
            headerFields.add(headerList[i].field);
        }
        
        try {
            // get the requisition addl header field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Requisition__c', 'Requisition_Additional_Info_Header');
            
            List<FieldInfo> fieldInfoListRO = FieldInfo.fetchJsonFieldInfos('Requisition__c', 'Requisition_Header_RO');
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
            
            requisitionAddlHeaderFieldList = (result.size() > 0) ? JSON.serialize(result) : '';
        }
        catch (FieldInfo.EmptyFieldSetMemberException e) {
            requisitionAddlHeaderFieldList = '';
        }
        
        return requisitionAddlHeaderFieldList;
    }
    
    public string getRequisitionLinesConfigJson() {
        String configStr = JSON.serialize(this.requisitionLinesConfig);
          
        return configStr;
    }
    
    public string getRequisitionLinesFieldList() {
        if (requisitionLinesFieldList == null && requisitionLinesConfig != null) {
            // get the requisition lines field info list
            getCustomViewFields();
            List<FieldInfo> fieldInfoList = allFieldsMap.values();

            List<FieldInfo> fieldInfoListRO = FieldInfo.fetchJsonFieldInfos('Requisition_Line__c', 'Requisition_Line_RO');

            Set<String> readOnlyFields = new Set<String>();
            
            for (Integer i = 0; i<fieldInfoListRO.size(); i++){
                readOnlyFields.add(fieldInfoListRO[i].field);
            }
            //PTP-577 Have fields read only in the requisition lines grid
            for(Integer i = 0; i < fieldInfoList.size(); i++) {
                if (readOnlyFields.contains(fieldInfoList[i].field)){
                    fieldInfoList[i].editable = false;
                }
                if (fieldInfoList[i].field == 'Approved__c'){
                    fieldinfoList[i].hidden = true;
            	}
                if (fieldInfoList[i].field == 'Quantity_Released__c'){
                    fieldinfoList[i].hidden = true;
                }
            }
            requisitionLinesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return requisitionLinesFieldList;
    }
    
    @RemoteAction 
    public static JsonResult getItemDetails(ID itemId) { //KNDY-10903
        List<Item__c> items;
        JsonResult result = new JsonResult();
        String whereClause = 'ID = \'' + itemId + '\' and Active__c = true limit 1';
        
        SOQLUtil soql = new SOQLUtil('Item__c');
        soql.addFields(new Set<String>{'Id', 'Name', 'Purchasing_UOM__c', 'Purchasing_UOM__r.Name', 'Source__c'});
        soql.setWhereClause(whereClause);
        
        items = Database.query(soql.getQuery());    
        
        Integer total = (items != null) ? items.size() : 0;
        result.total = total;
        result.records = items;
        
        return result;
    }
    
    public String getReturnUrl(){
        PageReference pageRef;
        
        if (requisition != null && requisition.Id != null ){
            pageRef =  new PageReference('/' + requisition.Id);
        }
        else{
            Schema.DescribeSObjectResult dsr = Requisition__c.SObjectType.getDescribe();
            pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        }
        
        return pageRef.getUrl();
    }
    
    public String getDeleteUrl(){
        PageReference pageRef;
        
        Schema.DescribeSObjectResult dsr = Requisition__c.SObjectType.getDescribe();
        pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        
        return pageRef.getUrl();
    }
    
    @RemoteAction
    public static JsonResult getRequisitionDetails(Id requisitionId) { 
        String objectName = 'Requisition__c';
        String headerFieldset = 'Requisition_Header';  
        String addlHeaderFieldset = 'Requisition_Additional_Info_Header';
        Set<String> addlFields = new Set<String> { 'Company__c' };      
        string whereClause = 'Id  = :requisitionId LIMIT 1';
        
        //String queryString = util.generateQueryFromFieldSet(objectName, new Set<string>{ headerFieldset, addlHeaderFieldset }, addlFields, whereClause);
		
		SOQLUtil soql = new SOQLUtil(objectName);
	    soql.addFields(headerFieldset);
	    soql.addFields(addlHeaderFieldset);
	    soql.addFields(addlFields);
	    soql.setWhereClause(whereClause);
	    
        List<Requisition__c> requisition = Database.query(soql.getQuery());   
 
        return new JsonResult(requisition, requisition.size());
    }
    
    @RemoteAction 
    public static JsonResult cancel(id requisitionId ) { 
        
        JsonResult result = new JsonResult();
        RequisitionService rs = new RequisitionService();
        result = rs.headerActions(requisitionId, 'Cancelled'); 
        return result;

    }
    
    @RemoteAction
    public static JsonResult close(id requisitionId ) { 

        JsonResult result = new JsonResult();
        RequisitionService rs = new RequisitionService();
        result = rs.headerActions(requisitionId, 'Closed'); 
        return result;

    }

    @RemoteAction
    public static JsonResult approve(id requisitionId ) { 

        JsonResult result = new JsonResult();
        RequisitionService rs = new RequisitionService();
        Set<String> objectName = new Set<String>();

        if (KSE.NamespaceUU != ''){
            objectName.add(KSE.NamespaceUU+'Requisition__c');
            objectName.add(KSE.NamespaceUU+'Requisition_Line__c');
        }
        else{
            objectName.add('Requisition__c');
            objectName.add('Requisition_Line__c');
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
            errorMsg = errorMsg.replaceAll('<SOURCE DOC>', 'requisition');
            result.addMessage(errorMsg, ApexPages.Severity.ERROR);
        }else{
        	result = rs.headerActions(requisitionId, 'Approved'); 
        }
        return result;

    }

    @RemoteAction
    public static JsonResult deletereq(id requisitionId ) { 

        JsonResult result = new JsonResult();
        RequisitionService rs = new RequisitionService();
        result = rs.headerActions(requisitionId, 'Delete'); 
        return result;

    }

    @RemoteAction
    public static JsonResult clone (id requisitionId ) { 

        JsonResult result = new JsonResult();
        RequisitionService rs = new RequisitionService();
        result = rs.clone(requisitionId);
        return result;

    }

    @RemoteAction
    public static JsonResult cancelLines(List<Requisition_Line__c> reqLines ) { 

        JsonResult result = new JsonResult();
        RequisitionService rs = new RequisitionService();
        result = rs.cancelReqLines(reqLines);
        return result;

    }

    @RemoteAction
    public static JsonResult closeLines(List<Requisition_Line__c> reqLines ) { 

        JsonResult result = new JsonResult();
        RequisitionService rs = new RequisitionService();
        result = rs.closeReqLines(reqLines);
        return result;

    }

    @RemoteAction 
    public static Integer getMaxLineNumber(ID requisitionid) {
        Integer maxLineNumber = 0;

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Requisition_Line__c', true, true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'MAX(Line__c) maxLineNum'
		});
		soql.setWhereClause('Requisition__c = :requisitionid');

		AggregateResult[] aggrResult = Database.query(soql.getQuery());

        maxLineNumber = Integer.valueOf( aggrResult[0].get('maxLineNum'));
        
        if (maxLineNumber == null) {
            maxLineNumber = 0;
        }
        
        return maxLineNumber;
    }

    @RemoteAction 
    public static JsonResult getRequisitionLines(GridRelatedListController.GridRelatedListConfig config, List<String>allFields) {
        list<Requisition_Line__c> result = new list<Requisition_Line__c>();
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
	    soql.addFields( new Set<String> (allFields) );
	    soql.addFields(addlFields);
	    soql.setWhereClause(whereClause);
        result = database.query(soql.getQuery());  
        
        return new JsonResult(result, result.size());
    }
    
    @RemoteAction
    public static JsonResult saveAction(Requisition__c requisition, List<String> headerDateFields, List<Requisition_Line__c> updatedList, List<Requisition_Line__c> newList, List<Requisition_Line__c> deletedList, List<String> dateFields) {
        KendoUtils.UpdateDateFields(requisition, headerDateFields);

        
        if (updatedList.size() > 0) {
            for (Requisition_Line__c line : updatedList) {
                KendoUtils.UpdateDateFields(line, dateFields);
            }
        }
        
        if (newList.size() > 0) {
            for (Requisition_Line__c line : newList) {
                KendoUtils.UpdateDateFields(line, dateFields);
            }
        }
        
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        list<Requisition__c> records = new list<Requisition__c>();  
        
        if(newList.size() > 0 && requisition.Source__c == 'Drop Ship'){
        	result.addMessage(Label.Cannot_update_Drop_Ship_Requisition, ApexPages.Severity.ERROR);
        	result.success = false;
        	return result;	
        }      
        
        //KNDY-14444
        if(newList.size() > 0 && requisition.Source__c == 'Back To Back'){
        	result.addMessage(Label.Cannot_update_Back_To_Back_Requisition, ApexPages.Severity.ERROR);
        	result.success = false;
        	return result;	
        } 
       
        result = validateSave(updatedList, newList); //KNDY-10903
        if (result.success == false){
            return result;
        }
        
        try {
        	    
            DML.checkUpsertAsUser(requisition); upsert requisition;
            
            List<Requisition_Line__c> requisitionLines = new List<Requisition_Line__c>();
            
            for (Requisition_Line__c line : newList) {
                line.Requisition__c = requisition.Id;
                //Set the supplier on Req Line only if Req Line's supplier is blank and if req has a supplier
                if (line.Supplier__c == null && requisition.Supplier__c != null){
                    line.Supplier__c = requisition.Supplier__c;
                }
                requisitionLines.add(line);
            }
            
            for (Requisition_Line__c line : updatedList) {
                requisitionLines.add(line);
            }
            
            DML.checkUpsertAsUser(requisitionLines); upsert requisitionLines;

            if (deletedList.size() > 0) {
                DML.deleteAsUser(deletedList);
            }
            
            records.add(requisition);
            result.records = records;
            result.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
        }
        catch (DMLException e) {
            Database.rollback(sp);
            result.success = false;
            for(integer i=0;i<e.getNumDml();i++) {
            	result.addMessage('An Error occured : ' + e.getDmlMessage(i) , ApexPages.Severity.ERROR);
            }
        }

        return result;
    }
    
    //KNDY-10903 UOM is validated in page as controller method cannot accept any reference fields such as Item__r.Source__c
    public static JSONResult validateSave(List<Requisition_Line__c> updatedList, List<Requisition_Line__c> newList) {
        List<Requisition_Line__c> linesWithMissingRequiredFields = new List<Requisition_Line__c>();
        List<Requisition_Line__c> linesToValidate = new List<Requisition_Line__c>();
        JSONResult result = new JSONResult();
        result.success = true;
        linesToValidate.addAll(updatedList);
        linesToValidate.addAll(newList);
        if (linesToValidate.size() > 0){
            for (Requisition_Line__c line : linesToValidate){
                if (//line.Item__c == null ||
                    line.Quantity_Ordered__c == null ||
                    line.Facility__c == null ){ 
                    linesWithMissingRequiredFields.add(line);
                }
            }
        }
        // process lines
        if (linesWithMissingRequiredFields.size() > 0){
            result.success = false;
            String lineNumbersStr1 = getErrorLineNumbers(linesWithMissingRequiredFields);
            result.addMessage(Label.Please_enter_required_fields + '- Lines ' + lineNumbersStr1 , ApexPages.Severity.ERROR);
        }
        return result;
     }
     
     private static String getErrorLineNumbers(List<Requisition_Line__c> linesWithErrors){
         List<Decimal> lineNumbers = new List<Decimal>();
         for (Requisition_Line__c line: linesWithErrors) {
               lineNumbers.add(line.Line__c);
         }
         lineNumbers.sort();
         String lineNumbersStr = String.join(lineNumbers, ',');
         lineNumbersStr = lineNumbersStr.removeEnd(',');
         return lineNumbersStr;
     }
}