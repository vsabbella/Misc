public with sharing class Supplier1099PaymentsExt extends BaseController {
    public Id defaultCompanyId{ get; set;} 
    
    public GridRelatedListController.GridRelatedListConfig spLinesConfig {get; set;}      
    public String spLinesFieldList = null;
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    public static SchemaUtil util = SchemaUtil.getInstance();

    public Supplier1099PaymentsExt(Apexpages.Standardcontroller controller){
        defaultCompanyId = CompanyService.getDefaultCompanyId();
        spLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        spLinesConfig.uniqueId = 'GridSPLs';
        spLinesConfig.title = Label.supplier_1099_payments;
        spLinesConfig.objectName = 'Supplier_Payment_Line__c';  
        spLinesConfig.fieldset = 'X1099_Reportable_Supplier_Payment_Lines';
        spLinesConfig.buttons = ' search, save, cancel, excel, columnmenu';
    }
    
    public string getSPLinesConfigJson() {
        String configStr = JSON.serialize(this.spLinesConfig);
        system.debug(LoggingLevel.Error, '>>> configStr: ' + configStr);
        return configStr;
    }
    
    public String getReturnUrl(){
        PageReference pageRef;
        Schema.DescribeSObjectResult result = Supplier_Payment__c.SObjectType.getDescribe();
        pageRef = new PageReference('/' + result.getKeyPrefix());    
        return pageRef.getUrl();    
    }
    
    @RemoteAction @ReadOnly 
    public static JsonResult getSPLines(GridRelatedListController.GridRelatedListConfig config, String selectedCompanyId, String selectedYear) {
        JsonResult result = new JsonResult();
        
        DateTime startDateTime = DateTime.newInstance(Integer.ValueOf(selectedYear),1,1,0,0,0);
        DateTime endDateTime =  DateTime.newInstance(Integer.ValueOf(selectedYear)+1,1,1,0,0,0);
        String startDateTimeStr = util.formatDateTimeForSOQL(startDateTime);
        String endDateTimeStr = util.formatDateTimeForSOQL(endDateTime);
        
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        string whereClause =  'Supplier_Payment__r.Company__c = :selectedCompanyId and X1099_Relevant__c = true' +
                              ' and Supplier_Payment__r.Finalized__c = true and Supplier_Payment__r.Status__c != \'Void\''+
                              ' and Supplier_Payment__r.Status__c != \'Cancelled\' and '+
                              'Supplier_Payment__r.Date_Paid__c >= ' + startDateTimeStr + ' and Supplier_Payment__r.Date_Paid__c < ' + endDateTimeStr;
        Set<String> additionalFields = new Set<String> {'Supplier_Payment__r.Date_Paid__c', 'Supplier_Payment__r.Supplier__c', 'Supplier_Payment__r.Currency__c'};
        String queryString = util.generateQueryFromFieldSet(config.objectName, new Set<string>{ fieldset }, additionalFields, whereClause);
        List<Supplier_Payment_Line__c> spLinesList = database.query(queryString);
        result.records = spLinesList;
        result.success = true;
        result.total = 0;
        if (result.records != null){
            result.total = result.records.size();
        }
        return result;
    }
    
    public string getSPLinesFieldList() {
        if (spLinesFieldList == null && spLinesConfig != null) {
            FieldInfo fieldInfoItem;
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(spLinesConfig.objectName, spLinesConfig.fieldset);
            Set<String> hiddenFields = new Set<String> { 'Id' ,'Supplier_Payment__r.Date_Paid__c','Supplier_Payment__r.Supplier__c','Supplier_Payment__r.Currency__c'};
           
            
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                
                //Set hyperlinks in UI
                if(fieldName =='Name'){
                    fieldInfoList[i].referenceTo = 'Id';
                    fieldInfoList[i].fieldtype ='Name';
                    fieldInfoList[i].Title = 'Payment Line';
                }else if (fieldName == 'Supplier__c'){
                    fieldInfoList[i].referenceTo = 'Supplier_Payment__r.Supplier__c';
                    fieldInfoList[i].fieldtype ='Name';
                }else if (fieldName == 'Currency__c'){
                    fieldInfoList[i].referenceTo = 'Supplier_Payment__r.Currency__c';
                    fieldInfoList[i].fieldtype ='Name';
                }else if (fieldName == 'Supplier_Invoice__r.Memo__c'){
                    fieldInfoList[i].Title = 'Invoice Memo';
                }else if (fieldName == 'X1099_Box_G__c'){
                    fieldInfoList[i].selectList.remove(0);
                }
                
                // set editable fields in UI
                fieldInfoList[i].filterable = true;
                fieldInfoList[i].field = fieldName;
                fieldInfoList[i].editable = false;
                fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
                if(fieldName == 'X1099_Box_G__c' || fieldName == 'Exclude_From_1099__c'){
                    fieldInfoList[i].editable = true;
                }
            }
            spLinesFieldList = JSON.serialize(fieldInfoList);
        }
        return spLinesFieldList;
    }
    
    @RemoteAction 
    public static JsonResult saveSPLs( List<Supplier_Payment_Line__c> spls){
       JsonResult result = new JsonResult();
       Savepoint sp = Database.setSavepoint();
       try{
            DML.updateAsUser(spls);
            result.success = true;
       }
       catch(Exception e) {
            Database.rollback(sp);
            system.debug(LoggingLevel.Error, 'exception '+e.getMessage()+' '+e.getStackTraceString());
            result.success = false;
            String errorMessage = 'An Error occured : ' + e.getMessage() ;
            if(errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                //You must select a 1099 Box value for a 1099 reportable payment line.: [mydev10__X1099_Box_G__c]
                List<String> tempErr = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
                List<String> error = tempErr[1].split(':');
                errorMessage = error[0];
            }
            result.addMessage(errorMessage, ApexPages.Severity.ERROR);
       }
       return result;
    }
}