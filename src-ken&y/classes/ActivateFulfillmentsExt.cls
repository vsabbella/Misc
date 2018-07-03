/**
 * Created by aravindbabusadhanandham on 11/6/17.
 */

global with sharing class ActivateFulfillmentsExt extends BaseController{

    private static SchemaUtil util = SchemaUtil.getInstance();
    public string NamespaceUU { get { return KSE.NamespaceUU; } }
    public GridRelatedListController.GridRelatedListConfig FulfillmentConfig {get; set;}
    public String fulfillmentLinesFieldList = null;
    public Apexpages.Standardcontroller con {get;set;}
    public id agreementId {get;set;}

    public String getfulfillmentLinesConfigJson() {
        String configStr = JSON.serialize(this.FulfillmentConfig);

        return configStr;
    }
    public string getfulfillmentLinesFieldList() {
        if (fulfillmentLinesFieldList == null && FulfillmentConfig != null) {

            // get the contract lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(FulfillmentConfig.objectName, FulfillmentConfig.fieldset);

            FieldInfo f = FieldInfo.getFieldInfo('invoice_ready__c', util.getGlobalDescribe(FulfillmentConfig.objectName));
            fieldInfoList.add(f);
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++) {
                String fieldName = fieldInfoList[i].field;
                fieldInfoList[i].field = fieldName;
                fieldInfoList[i].editable = false;

                //Rename the start and end date on fulfillments
                if (fieldName == 'end_date__c') {
                    fieldInfoList[i].title = 'Fulfillment End Date';
                    fieldInfoList[i].editable = true;
                } else if (fieldName == 'start_date__c') {
                    fieldInfoList[i].title = 'Fulfillment Start Date';
                    fieldInfoList[i].editable = true;
                } else if (fieldName == 'invoice_ready__c') {
                    fieldInfoList[i].editable = true;
                }
            }

            fulfillmentLinesFieldList = JSON.serialize(fieldInfoList);
        }

        return fulfillmentLinesFieldList;
    }

    public ActivateFulfillmentsExt(ApexPages.StandardController controller) {

        this.con = controller;

        if(this.con == null){
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'No agreement is specified.'));
        }else{
            if(!test.isRunningTest()){
                this.con.addFields(new list<String>{'Customer__c', 'Customer__r.RecordType.DeveloperName', 'Status__c', 'Currency__c',//Ship To
                        'Customer__r.Parent_Customer__c', 'Customer__r.Parent_Customer__r.Name', //Sold To
                        'Customer__r.Parent_Customer__r.Parent_Customer__c', 'Customer__r.Parent_Customer__r.Parent_Customer__r.Name', //Bill To
                        'Payment_Terms__c', 'Bill_To__c', 'Sold_To__c', 'Ship_To__c',
                        'Company__c', 'Company__r.Serial_Control__c', //company's serial attribute
                        'Customer__r.Top_Parent_Customer__c', 'Customer__r.Top_Parent_Customer__r.Name'});
            }
            Agreement__c a  = (Agreement__c) con.getRecord();

            agreementId = a.id;

        }

        //Fulfillment Grid config
        FulfillmentConfig = new GridRelatedListController.GridRelatedListConfig();
        FulfillmentConfig.uniqueId = 'FulfillmentGrid';
        FulfillmentConfig.title = 'Fulfillments';
        FulfillmentConfig.objectName = 'Fulfillment__c';
        FulfillmentConfig.fieldset = 'Return';
        FulfillmentConfig.buttons = 'columnmenu, search';
        FulfillmentConfig.alwaysUseFullDateTimeFormat = false;

    }

    @RemoteAction
    global static JsonResult getFulfillments(String id) {

        JsonResult result = new JsonResult();

        List<Fulfillment__c> Fulfillments = new List<Fulfillment__c>();

        List<String> filterCriteria = new List<String>();
        filterCriteria.add('Sales_Order_Line__r.Agreement__c = :id');
        filterCriteria.add('Type__c = \'Rental\'');
        filterCriteria.add('Invoice_Ready__c = false');
        filterCriteria.add('Inventory_Transaction__r.Type__c = \'Sales Order Shipment\'');

        String whereClause = '';
        if (filterCriteria.size() > 0) {
            whereClause += String.join(filterCriteria, ' AND ');
        }

        //List<String> fieldstoQuery = util.getFieldsFromFieldSetString('Fulfillment__c', 'Return');
        //Set<String> fieldSettouseinQuery = new Set<String>(fieldstoQuery);
        //datetime oDate = system.now();
        SOQLUtil soql = new SOQLUtil('Fulfillment__c', TRUE);
        soql.addFields(new Set<String>{'Id', 'Name', 'Company__c', 'SKID__c', 'Product__r.Item__c',
                'Product__r.Item__r.Item_Attribute__c',
                'Product__r.Item__r.Item_Attribute__r.Serial_Number__c', 'Rate_Basis__c' });
        soql.addFields(util.getAllCustomFieldsFromObject('', 'Fulfillment__c'));
        //soql.addFields(fieldSettouseinQuery);
        soql.addFields(util.getAllCustomFieldsFromObject('Sales_Order_Line__r.','Sales_Order_Line__c'));
        soql.setWhereClause(whereClause);
        soql.setOrderByClause('LastModifiedDate');

        system.debug(LoggingLevel.Error, 'soql.getQuery()--'+soql.getQuery());
        Fulfillments = database.query(soql.getQuery());
        system.debug(LoggingLevel.Error, 'Fulfillments--'+Fulfillments);

        result.success = true;
        result.records = Fulfillments;

        return result ;
    }

    @RemoteAction
    global static JsonResult updateFulfillments(List<Fulfillment__c> flmts) {

        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        if (flmts.size() > 0) {
            try{
                for (Fulfillment__c flmt : flmts) {
                    //flmt.Start_Date__c = system.now();
                    //flmt.End_Date__c = null;
                    flmt.End_Date__c = (flmt.End_Date__c != Datetime.newInstance(0)) ? flmt.End_Date__c : null;
                    flmt.Invoice_Ready__c = true;
                }
                DML.updateAsUser(flmts);
                result.addMessage('Selected fulfillments are activated successfully!', ApexPages.Severity.CONFIRM);
            }catch(Exception e){
                Database.rollback(sp);
                result.success = false;
                result.addMessage('Activating fulfillments failed: ' + e.getMessage() , ApexPages.Severity.ERROR);
                system.debug(LoggingLevel.ERROR, '\n' + e.getStackTraceString());
            }
        }


        return result ;
    }

}
