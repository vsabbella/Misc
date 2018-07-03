public with sharing class RepairGridCon extends GridRelatedListController {
    public String jsonToDeserialize{get;set;}
    public string repairFieldList {get; set;}
    public string warrantyDetailFieldList {get; set; }
    private string jsonString = '';
    private static SchemaUtil util = SchemaUtil.getInstance();
    public string NamespaceUU { get { return KSE.NamespaceUU; } }
    public GridRelatedListController.GridRelatedListConfig config{ get; set;} {config = new GridRelatedListController.GridRelatedListConfig();}

    public RepairGridCon(){

        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Sales_Order_Line__c', 'RMA_For_Repair');

        // set the wrapper class prefix
        for(Integer i = 0; i < fieldInfoList.size(); i++){
            fieldInfoList[i].field = 'sol.' + fieldInfoList[i].field;
        }

        repairFieldList = JSON.serialize(fieldInfoList);

        List<FieldInfo> warrantyDetailfieldInfoList = FieldInfo.fetchJsonFieldInfos('Fulfillment__c', 'Warranty');
        warrantyDetailFieldList = JSON.serialize(warrantyDetailfieldInfoList);

        config = new GridRelatedListController.GridRelatedListConfig();
        config.uniqueId = 'warrantySearchGrid';
        config.objectName = 'Fulfillment__c';
        config.buttons = 'search';
    }

    @RemoteAction
    public static JsonResult getWarrantySearchResults(String sol, String serial) {
        JsonResult result = new JsonResult();
        try {
            Datetime nowDateTime = system.now();

            SOQLUtil soql = new SOQLUtil('Inventory_Transaction__c', TRUE);
            soql.addFields(new set<String>{'Id', 'Sales_Order_Line__c'});
            soql.setWhereClause('Id IN (SELECT Inventory_Transaction__c FROM Serial_Transaction__c WHERE Serial__c = :serial AND Type__c = \'Shipment\')');

            List<Inventory_Transaction__c> itList = Database.query(soql.getQuery());

            set<Id> solIds = KSE.grepRelatedIdSetFromList(itList, 'Sales_Order_Line__c');

            if(sol != '') {
                solIds.add((Id) sol);
            }

            soql = new SOQLUtil('Fulfillment__c', TRUE);
            soql.addFields(new set<String>{'Sales_Order_Line__r.Parent_Sales_Order_Line__c', 'Product__r.Product_Type__c'});
            soql.addAllFields();
            soql.setWhereClause('Sales_Order_Line__r.Parent_Sales_Order_Line__c in :solIds AND Product__r.Product_Type__c = \'Warranty\' AND Start_Date__c <= :nowDateTime AND End_Date__c > :nowDateTime');

            List<Fulfillment__c> fList = Database.query(soql.getQuery());

            for(Inventory_Transaction__c it : itList) {
                fList.addAll(it.Fulfillments__r);
            }
            Set<Fulfillment__c> fSet = new Set<Fulfillment__c>(fList); //Dedupe between both queries
            result.records = new List<Fulfillment__c>(fSet);
            result.total = fSet.size();
        } catch(Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(), ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static DataSourceResult createRepairOrder(List<WarrantyWrapper> wrapperList) {
        DataSourceResult result = new DataSourceResult();
        Savepoint sp = Database.setSavepoint();
        try {
            List<Sales_Order_Line__c> parentSolList = new List<Sales_Order_Line__c>();
            List<Sales_Order_Line__c> childSolList = new List<Sales_Order_Line__c>();
            set<Id> soIds = new set<Id>();
            map<String, Sales_Order_Line__c> mParentToChildReference = new map<String, Sales_Order_Line__c>();
            for(WarrantyWrapper w : wrapperList) {
                if(w.sol.Primary_Key__c != null) {
                    Sales_Order_Line__c sol = w.sol.clone(false, true);
                    mParentToChildReference.put(w.sol.Primary_Key__c, sol);
                    sol.Primary_Key__c = null;
                    parentSolList.add(sol);
                }
            }
            Sales_Order__c so = new Sales_Order__c();
            set<Id> solIds = KSE.grepRelatedIdSetFromList(parentSolList, 'Related_Sales_Order_Line__c');
            SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', TRUE);
            soql.addFields(new set<String>{'Id', 'Sales_Order__r.Company__c', 'Sales_Order__r.Customer__c', 'Sales_Order__r.Bill_To__c',
                    'Sales_Order__r.Ship_To__c'});
            soql.setWhereClause('Id IN :solIds');
            List<Sales_Order_Line__c> soList = Database.query(soql.getQuery());

            so.Type__c = 'Repair';
            so.Company__c = soList[0].Sales_Order__r.Company__c;
            so.Customer__c = soList[0].Sales_Order__r.Customer__c;
            so.Bill_To__c = soList[0].Sales_Order__r.Bill_To__c;
            so.Ship_To__c = soList[0].Sales_Order__r.Ship_To__c;
            so.Related_Sales_Order__c = soList[0].Sales_Order__r.id;
            DML.insertAsUser(so);

            for(Sales_Order_Line__c p : parentSolList) {
                p.Sales_Order__c = so.Id;
            }

            DML.insertAsUser(parentSolList);

            for(WarrantyWrapper w : wrapperList) {
                if(w.parentId != null && mParentToChildReference.containsKey(w.parentId)) {
                    Sales_Order_Line__c sol = w.sol.clone(false, true);
                    sol.Company__c = soList[0].Sales_Order__r.Company__c;
                    sol.Parent_Sales_Order_Line__c = mParentToChildReference.get(w.parentId).Id;
                    sol.Sales_Order__c = so.Id;
                    childSolList.add(sol);
                }
            }

            if(childSolList != null) {
                DML.insertAsUser(childSolList);
            }

            soql = new SOQLUtil('Sales_Order__c', TRUE);
            soql.addFields(new set<String>{'Id', 'Name'});
            String soId = so.Id;
            soql.setWhereClause('Id = :soId');
            Sales_Order__c salesOrder = Database.query(soql.getQuery());
            result.success = true;
            result.addMessage('<a href="/'+ salesOrder.Id + '">' + salesOrder.Name + '</a>' + ' was created successfully', ApexPages.Severity.CONFIRM);
        } catch(Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e, ApexPages.Severity.ERROR);
            result.addMessage(e.getStackTraceString(), ApexPages.Severity.ERROR);
        }

        return result;
    }

    @RemoteAction
    public static Decimal getPriceForProduct(String soLineRec) {

        Sales_Order_Line__c soLine = (Sales_Order_Line__c)JSON.deserialize(soLineRec, Sales_Order_Line__c.class);
        Id productId = soLine.Product__c;
        //Fetch Product information
        Set<String> productQueryFields = new Set<String>{'Id',
                'Name',
                'Description__c',
                'Company__c',
                'Item__c',
                'Item__r.Name',
                'Item__r.Fulfillment_Source__c',
                'Pricebook_Line_Required__c',
                'Product_Group__c',
                'Selling_UOM__r.Name',
                'Units_per_Layer__c',
                'Units_per_Pallet__c',
                'UPC_Code__c',
                'Invoiceable__c',
                'Item__r.Source__c'};

        SOQLUtil soql = new SOQLUtil('Product__c');
        soql.addFields(productQueryFields);
        soql.setWhereClause('Id = :productId');

        List<Product__c> products = Database.query( soql.getQuery() );
        soLine.Product__r = products[0];

        Pricebook_Line__c priceBookLine = new Pricebook_Line__c();
        Map<String, Pricebook_Line__c> solPBL = PricingService.fetchSOLinesPriceBookInfo(new List<Sales_Order_Line__c>{ soLine });

        if(solPBL.containsKey(soLine.Sales_Order__c + '-' + soLine.Line__c)){
            priceBookLine = solPBL.get(soLine.Sales_Order__c + '-' + soLine.Line__c);
        }
        return priceBookLine.price__c;
    }

    public class WarrantyWrapper {
        public Sales_Order_Line__c sol {get;set;}
        public Fulfillment__c warranty {get;set;}
        public Boolean hasChildren {get;set;}
        public String parentId {get;set;}

        public WarrantyWrapper() {
        }

        public WarrantyWrapper(Sales_Order_Line__c sol, Fulfillment__c warranty) {
            this.sol = sol;
            this.warranty = warranty;
        }
    }
}