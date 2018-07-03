public with sharing class CreateRepairDocumentsExt {
    public List<Sales_Order_Line__c> solList{get;set;}
    public List<RepairGridCon.WarrantyWrapper> wrapperList{get;set;}
    public String resultJsonString{get;set;}
    public SOQLUtil soql{get;set;}
    private static SchemaUtil util = SchemaUtil.getInstance();
    private static final set<String> validTypes = new set<String>{'RMA Receipt For Repair'};
    private static final String FIELD_SET = 'RMA_For_Repair';
    public string HelpURL{get;set;}

    public CreateRepairDocumentsExt(ApexPages.StandardController con) {
        solList = new List<Sales_Order_Line__c>();
        wrapperList = new List<RepairGridCon.WarrantyWrapper>();
        Id rdId = con.getId();
        HelpURL=URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpRepairDocuments';
        set<String> queryFields = new set<String>{
                'Id', 'Type__c'
        };
        soql = new SOQLUtil('Receiving_Document__c', TRUE);
        soql.addFields(queryFields);
        soql.setWhereClause('Id = :rdId');
        List<String> solQueryFields = util.getFieldsFromFieldSetString('Sales_Order_Line__c', FIELD_SET);
        List<String> additonalsolFields = new List<String>{'Company__c', 'Quantity_Fulfilled__c'};
        solQueryFields.addAll(additonalsolFields);

        String namespace = String.isBlank(KSE.NamespaceUU) ? '' : KSE.NamespaceUU.toLowerCase();
        Schema.sObjectType sObjType = util.getGlobalDescribe('Sales_Order_Line__c');
        Map<String, Schema.sObjectField> solFieldsMap = sObjType.getDescribe().fields.getMap();

        for(Integer i = 0; i < solQueryFields.size(); i++){

            string fieldPath = string.escapeSingleQuotes(solQueryFields[i]);
            fieldpath = fieldpath.trim();

            Schema.sObjectField sObjField;
            sObjField = solFieldsMap.containsKey(fieldPath) ? solFieldsMap.get(fieldPath) : solFieldsMap.get(namespace + fieldPath);

            if(sObjField != null){
                Schema.DescribeFieldResult dfr = sObjField.getDescribe();

                fieldPath = fieldPath.replace(namespace, '').toLowerCase();
                if(dfr.getType() == Schema.DisplayType.REFERENCE){
                    solQueryFields.add(fieldpath.replace('__c','__r.Name').toLowerCase().trim());
                }
            }

            solQueryFields[i] = 'Sales_Order_Line__r.' + solQueryFields[i];
        }
        //Need to exclude hyperlink field. Apex JSON Parser cannot handle the html
        set<String> excludedFields = new set<String>{'Sales_Order_Line__r.name_hyperlink__c'};
        set<String> subQueryFields = new set<String>{'Id', 'Sales_Order_Line__r.Related_Sales_Order_Line__c', 'Sales_Order_Line__r.Sales_Order__r.Company__c',
                'Sales_Order_Line__r.Sales_Order__r.Customer__c', 'Sales_Order_Line__r.Sales_Order__r.Bill_To__c', 'Sales_Order_Line__r.Sales_Order__r.Pricing_Date__c',
                'Sales_Order_Line__r.Sales_Order__r.Currency__c', 'Sales_Order_Line__r.Sales_Order__r.Ship_To__c', 'Sales_Order_Line__r.Pricebook__c'};
        subQueryFields.addAll(solQueryFields);
        subQueryFields.removeAll(excludedFields);

        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Receipt_Lines__r');
        childRel.addFields(subQueryFields);

        soql.addChildRelationship(childRel);

        List<Receiving_Document__c> rdList = Database.query(soql.getQuery());

        set<Id> originalSOLIds = KSE.grepRelatedIdSetFromList(rdList[0].Receipt_Lines__r, 'Sales_Order_Line__r.Related_Sales_Order_Line__c');

        Datetime nowDateTime = system.now();

        soql = new SOQLUtil('Fulfillment__c', TRUE);
        soql.addFields(new set<String>{'Sales_Order_Line__r.Parent_Sales_Order_Line__c', 'Product__r.Product_Type__c'});
        soql.addFields('Warranty');
        soql.setWhereClause('Sales_Order_Line__r.Parent_Sales_Order_Line__c IN :originalSOLIds AND Product__r.Product_Type__c = \'Warranty\' AND Start_Date__c <= :nowDateTime AND End_Date__c > :nowDateTime');

        List<Fulfillment__c> fList = Database.query(soql.getQuery());

        map<Id, Fulfillment__c> mOriginalSOToFulfillmentMap = new map<Id, Fulfillment__c>();

        for(Fulfillment__c f : fList) {
            mOriginalSOToFulfillmentMap.put(f.Sales_Order_Line__r.Parent_Sales_Order_Line__c, f);
        }

        for (Receipt_Line__c rl : rdList[0].Receipt_Lines__r) {
            Sales_Order_Line__c sol = new Sales_Order_Line__c();
            RepairGridCon.WarrantyWrapper wrapper;
            sol = rl.Sales_Order_Line__r.clone(false, true);
            sol.Customer__c = rl.Sales_Order_Line__r.Sales_Order__r.Customer__c;
            sol.Receipt_Line__c = rl.Id;
            sol.Quantity_Fulfilled__c = null;
            sol.Required_Date__c = null;
            sol.Ship_From_Location__c = null;
            sol.Ship_From_Location__r.Name = null;
            sol.Sales_Order__c = null;
            sol.Quantity_Ordered__c = rl.Sales_Order_Line__r.Quantity_Fulfilled__c != null ? Math.Abs(rl.Sales_Order_Line__r.Quantity_Fulfilled__c) : 0;
            sol.Non_Shippable__c = false;
            sol.Invoiceable__c = false;
            sol.Related_Sales_Order_Line__c = rl.Sales_Order_Line__c;
            sol.Type__c = 'Repair';
            sol.Parent_Sales_Order_Line__c = null;
            if(mOriginalSOToFulfillmentMap.containsKey(rl.Sales_Order_Line__r.Related_Sales_Order_Line__c)) {
                wrapper = new RepairGridCon.WarrantyWrapper(sol, mOriginalSOToFulfillmentMap.get(rl.Sales_Order_Line__r.Related_Sales_Order_Line__c));
            } else {
                wrapper = new RepairGridCon.WarrantyWrapper(sol, null);
            }

            wrapperList.add(wrapper);
        }

        if(validTypes.contains(rdList[0].Type__c)) {
            resultJsonString = JSON.Serialize(wrapperList);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Receiving Document must have valid type for creating Repair Documents'));
        }
    }
}