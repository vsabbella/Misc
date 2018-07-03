public with sharing class RepairWorkBenchCon extends GridRelatedListController {
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    private static SchemaUtil util = SchemaUtil.getInstance();
    public string ibFieldList {get; set;}
    public GridRelatedListController.GridRelatedListConfig config{ get; set;} {config = new GridRelatedListController.GridRelatedListConfig();}

    public RepairWorkBenchCon() {
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('SKID__c', 'Repair_WorkBench');
        for( FieldInfo f : fieldInfoList ){
        	f.editable = false;
        }

        fieldInfoList[fieldInfoList.size()-1].editable = true;

        ibFieldList = JSON.serialize(fieldInfoList);

        config = new GridRelatedListController.GridRelatedListConfig();
        config.uniqueId = 'ibSkidsGrid';
        config.objectName = 'SKID__c';
        config.buttons = 'search';
    }

    @RemoteAction
    public static JsonResult searchIBSkids(String customer, String serial) {
        JsonResult result = new JsonResult();
        try {
            String whereClause = '';
            if(customer != '') {
                whereClause = 'Customer__c = :customer AND ';
            }
            SOQLUtil soql = new SOQLUtil('SKID__c', TRUE);
            soql.addFields('Repair_WorkBench');

            String subQueryWhereClause = 'Id = :serial';
            String subWhereCaluse = '';
            if(serial != '') {
                subWhereCaluse += ' AND Id IN (Select SKID__c FROM Serial__c WHERE ' + subQueryWhereClause + ')';
            }

            soql.setWhereClause(whereClause + 'Type__c = \'Install Base\'' + subWhereCaluse);

            List<SKID__c> skidList = Database.query(soql.getQuery());

            result.records = skidList;
            result.total = skidList.size();

        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(), ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult createRepairDocuments(List<SKID__c> ibSkids) {
        JsonResult result = new JsonResult();
        try {
            List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
            List<RepairGridCon.WarrantyWrapper> wrapperList = new List<RepairGridCon.WarrantyWrapper>();
            map<Id,SKID__c> ibSkidMap = new map<Id,SKID__c>(ibSkids);
            set<Id> ibIds = ibSkidMap.keySet();

            List<String> solQueryFields = util.getFieldsFromFieldSetString('Sales_Order_Line__c', 'RMA_For_Repair');
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
            set<String> queryFields = new set<String>{'Id', 'Sales_Order_Line__r.Related_Sales_Order_Line__c',
                    'Sales_Order_Line__r.Sales_Order__r.Customer__c', 'Sales_Order_Line__r.PriceBook__c', 'Sales_Order_Line__r.Sales_Order__r.Bill_To__c',
                    'Sales_Order_Line__r.Sales_Order__r.Ship_To__c','Sales_Order_Line__r.Product__r.Item__r.Stocking_UOM__c', 'Sales_Order_Line__r.Selling_UOM__c',
                    'Sales_Order_Line__r.Product__r.Item__r.Packaging_UOM__c','Sales_OrdeR_Line__r.Ship_From_Location__r.Facility__r.Facility_Identifier__c'
            };
            queryFields.addAll(solQueryFields);
            queryFields.removeAll(excludedFields);

            SOQLUtil soql = new SOQLUtil('SKID__c', TRUE);
            soql.addFields(queryFields);
            soql.setWhereClause('Id IN :ibIds');

            List<SKID__c> skidList = Database.query(soql.getQuery());

            set<Id> originalSOLIds = KSE.grepRelatedIdSetFromList(skidList, 'Sales_Order_Line__c');

            DateTime nowDateTime = system.now();

            soql = new SOQLUtil('Fulfillment__c', TRUE);
            soql.addFields(new set<String>{'Sales_Order_Line__r.Parent_Sales_Order_Line__c', 'Product__r.Product_Type__c'});
            soql.addFields('Warranty');
            soql.setWhereClause('Sales_Order_Line__r.Parent_Sales_Order_Line__c IN :originalSOLIds AND Product__r.Product_Type__c = \'Warranty\' AND Start_Date__c <= :nowDateTime AND End_Date__c > :nowDateTime');

            List<Fulfillment__c> fList = Database.query(soql.getQuery());

            map<Id, Fulfillment__c> mOriginalSOToFulfillmentMap = new map<Id, Fulfillment__c>();

            for(Fulfillment__c f : fList) {
                mOriginalSOToFulfillmentMap.put(f.Sales_Order_Line__r.Parent_Sales_Order_Line__c, f);
            }

            for (SKID__c s : skidList) {
                Sales_Order_Line__c sol = new Sales_Order_Line__c();
                RepairGridCon.WarrantyWrapper wrapper;
                sol = s.Sales_Order_Line__r.clone(false, true);
                sol.SKID__c = s.Id;
                sol.Related_Sales_Order_Line__c = s.Sales_Order_Line__c;
                sol.Quantity_Fulfilled__c = null;
                sol.Required_Date__c = null;
                sol.Ship_From_Location__c = null;
                sol.Ship_From_Location__r.Name = null;
                sol.Sales_Order__c = null;
                sol.Quantity_Ordered__c = ibSkidMap.get(s.Id).Quantity__c / KSE.getConversionFactor(s.Sales_Order_Line__r);
                sol.Non_Shippable__c = true;
                sol.Invoiceable__c = false;
                sol.Parent_Sales_Order_Line__c = null;
                if (mOriginalSOToFulfillmentMap.containsKey(s.Sales_Order_Line__c)) {
                    wrapper = new RepairGridCon.WarrantyWrapper(sol, mOriginalSOToFulfillmentMap.get(s.Sales_Order_Line__c));
                } else {
                    wrapper = new RepairGridCon.WarrantyWrapper(sol, null);
                }

                wrapperList.add(wrapper);
            }
            result.records = wrapperList;
            result.total = wrapperList.size();
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(), ApexPages.Severity.ERROR);
        }
        return result;
    }

}