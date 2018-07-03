public with sharing class PricebookRelatedListExt extends GridRelatedListController {

    public String priceBookLinesFieldList = null;
    public Pricebook__c pricebook {get; set;}
    private static SchemaUtil util = SchemaUtil.getInstance();

    public PricebookRelatedListExt(ApexPages.StandardController con) {
        super();
        Id pbid = con.getId();
        pricebook = [select id, Name, company__c, currency__c from Pricebook__c where Id = : pbid limit 1];

        configurePricebook(con);

    }


    /* Fetch the Pricebook lines field list from fieldset */
    public String getPriceBookLinesFieldList(){

        if(priceBookLinesFieldList == null){

            List<FieldInfo> pbLineFieldInfoList = FieldInfo.fetchJsonFieldInfos('Pricebook_Line__c', 'Pricebook_Related_List');

            priceBookLinesFieldList = JSON.serialize(pbLineFieldInfoList);
        }
        
        return priceBookLinesFieldList;
    }

    public String getHeaderFieldList(){
        List <FieldInfo> fieldInfoList = new List <FieldInfo>();

        String[] headerFields = new String[]{'Company__c','Currency__c','Description__c','Name','Default__c'};
        for (FieldInfo field : FieldInfo.fetchJsonFieldInfos('Pricebook__c', headerFields)){


            field.editable = true;
            fieldInfoList.add(field);


        }

         return JSON.serialize(fieldInfoList);
    }

    @RemoteAction
    public static JsonResult updatePricebook(Pricebook__c pb){
        JsonResult  jsResult = new JsonResult();

        try {
            DML.updateAsUser(pb);
            jsResult.success = true;
            jsResult.records = new List<Pricebook__c>{pb};
            jsResult.total = 1;
        } catch (Exception e){

            System.debug(logginglevel.error, 'Exception: ' + e.getMessage() + ' - ' +  e.getStackTraceString());

            jsResult.success = false;
            jsResult.addMessage(e, ApexPages.Severity.ERROR );
        }

        return jsResult;

    }

    @RemoteAction
    public static JsonResult getPBDetails(String pbId){
        JsonResult  jsResult = new JsonResult();

        try {

            Set<String> addlFields = new Set<String> {'Company__c', 'Name','Currency__c','Description__c','Default__c'};

            string whereClause = 'Id  = :pbId LIMIT 1';


            SOQLUtil soql = new SOQLUtil('Pricebook__c');
            soql.addFields(addlFields);
            soql.setWhereClause(whereClause);

            jsResult.success = true;
            jsResult.records = Database.query(soql.getQuery());
            jsResult.total = jsResult.records.size();

        } catch (Exception e){

            System.debug(logginglevel.error, 'Exception: ' + e.getMessage() + ' - ' +  e.getStackTraceString());

            jsResult.success = false;
            jsResult.addMessage(e, ApexPages.Severity.ERROR );
        }

        return jsResult;
    }

    @RemoteAction
    public static DataSourceResult savePriceBookList(
        GridRelatedListConfig config,
        List<SObject> updatedList,
        List<SObject> newList,
        List<Sobject> deletedList) {

        System.debug(loggingLevel.Error, '*** updatedList: ' + updatedList);
        System.debug(loggingLevel.Error, '*** newList: ' + newList);
        System.debug(loggingLevel.Error, '*** deletedList: ' + deletedList);

        DataSourceResult result = new DataSourceResult();
        Savepoint sp = Database.setSavepoint();

        try {
            if (updatedList.size() > 0) {
                DML.updateAsUser(updatedList);
            }

            if (newList.size() > 0) {
                DML.insertAsUser(newList);
            }

            if (deletedList.size() > 0) {
                // OTC-439 users with Del perm on object can delete any row (even owned by others)
                new DML.WithoutSharing().sobjectDel( deletedList );
            }
            // Leave it from here and let JS handle !
            result.addMessage('Your changes have been saved successfully', ApexPages.Severity.CONFIRM);

        } catch (Exception e) {
            System.debug(loggingLevel.Error, e.getMessage() +  '-' + e.getStackTraceString());

            Database.rollback(sp);
            result.success = false;
            result.addMessage(e, ApexPages.Severity.ERROR );
        }

        return result;
    }

    @RemoteAction
    public static JsonResult getFilteredPBLs(GridRelatedListConfig config, String prodId, String stringStartDate, String stringEndDate, String priceType) {

        JsonResult jsResult = new JsonResult();

        try {
            List<String> filters = new List<String>();


            String parentfield = (String.isNotBlank(config.parentfield)) ? config.parentfield : '';

            string whereClause = '';

            if (prodId != null && prodId != '') {
                whereClause += ' Product__c = :prodId AND ';
            }

            Date startDate = null;
            Date endDate = null;

            if (stringEndDate != null && stringEndDate != '') {
                List<String> dateSplit = stringEndDate.split('/');
                endDate = Date.newInstance(integer.valueOf(dateSplit[2]), integer.valueOf(dateSplit[0]), integer.valueOf(dateSplit[1]));
            }

            if (stringStartDate != null && stringStartDate != '') {
                List<String> dateSplit = stringStartDate.split('/');
                startDate = Date.newInstance(integer.valueOf(dateSplit[2]), integer.valueOf(dateSplit[0]), integer.valueOf(dateSplit[1]));
            }



            if (startDate != null && endDate != null){
                whereClause += ''
                    + ' ( End_Date__c >=: startDate AND Start_Date__c <= :endDate ) AND ';
            } else if (startDate == null && endDate != null){
                whereClause += ''
                    + ' ( Start_Date__c <= :endDate ) AND ';
            } else if (startDate != null && endDate == null){
                whereClause += ''
                    + ' ( End_Date__c >=: startDate ) AND ';
            }

            if (priceType != null && priceType != '') {
                whereClause += ' Price_Type__c = :priceType AND ';
            }

            whereClause += ' Pricebook__c = \'' + config.parentRecord.Id + '\' ';
            whereClause += ' ORDER BY Product__r.Name, Use_Fixed_Pricing__c, Price_Type__c, Start_Date__c, Price__c ASC LIMIT 5000';

            if (String.isNotBlank(config.namespace)) {
                util.namespace = config.namespace;
            }

            SOQLUtil soql = new SOQLUtil(config.objectName);
            soql.addFields(config.fieldset);
            soql.addFields(config.additionalFields);
            soql.setWhereClause(whereClause);

            jsResult.records = Database.query(soql.getQuery());
            jsResult.total = jsResult.records.size();
            jsResult.success = true;


        } catch (Exception ex) {

            System.debug(loggingLevel.Error, ex.getMessage() +  '' + ex.getStackTraceString());
            jsResult.success = false;
            jsResult.addMessage(ex, ApexPages.Severity.ERROR);

        }

        return jsResult;

    }

    public PageReference goback() {

        Schema.DescribeSObjectResult dssResult = Pricebook__c.SObjectType.getDescribe();
        PageReference pageRef = new PageReference('/' + dssResult.getKeyPrefix());

        return pageRef;
    }

    public void configurePricebook(ApexPages.StandardController con) {
        DateTime d = Date.Today() ;
        String dateStr = d.format('yyyy-MM-dd');
        config.uniqueId = 'PBLGrid'; // kendoGridDiv
        config.title = 'Pricebook Lines';
        config.objectName = 'Pricebook_Line__c';
        config.parentField = 'Pricebook__c';
        config.parentRecord = con.getRecord();
        config.fieldset = 'Pricebook_Related_List';
        config.buttons = 'save,cancel,delete,create,search';
        config.readOnlyFields = 'Price_2__c,Price_3__c,Price_4__c,Price_5__c';
        config.additionalFields = 'CreatedDate';
        config.pageSize = 10;
        config.alwaysUseFullDateTimeFormat = false;
        //config.sortField = 'Product__r.Name, Use_Fixed_Pricing__c, Price_Type__c, Start_Date__c ASC LIMIT 5000'; //
        config.addlWhereClause = 'End_Date__c >= ' + dateStr + ' ';
    }

}