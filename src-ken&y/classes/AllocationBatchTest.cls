@isTest
private class AllocationBatchTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);

        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;
        update new Sales_Order__c(Id = f.salesOrder.Id, Required_Date__c = System.today() + 5, Ship_From_Location__c = f.location2.Id, Ready__c = true);
        delete c;

        new SalesOrderService().plan(f.salesOrder.Id);
    }

    public static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void noInventory() {
        Test.startTest();
        SalesOrderAllocateBatch batchClass = new SalesOrderAllocateBatch();
        batchClass.runBatch(new Process_Job__c(Company__c = fuel.company.Id, Facility__c = fuel.facility2.Id, Days_Ahead__c = 100));
        Test.stopTest();

        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Type__c = :SkidService3.SKID_TYPE_ALLOCATED AND Shipment_Line__r.Sales_Order__c = :fuel.salesOrder.Id];
        System.assert(skids.size() == 0, skids);
    }

    private static testMethod void partialAllocation() {
        Sales_Order_Line__c sol = fuel.salesOrderLine;

        fuel.setupInventory();
        delete [SELECT Id FROM SKID__c WHERE Item__c != :sol.Product__r.Item__c];

        Test.startTest();
        SalesOrderAllocateBatch batchClass = new SalesOrderAllocateBatch();
        batchClass.runBatch(new Process_Job__c(Company__c = fuel.company.Id, Facility__c = fuel.facility2.Id, Days_Ahead__c = 100));
        Test.stopTest();

        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Type__c = :SkidService3.SKID_TYPE_ALLOCATED AND Shipment_Line__r.Sales_Order__c = :fuel.salesOrder.Id];
        System.assert(skids.size() == 1, skids);
    }

    private static testMethod void fullyAllocateNotEnoughInventory() {
        Sales_Order_Line__c sol = fuel.salesOrderLine;

        fuel.setupInventory();
        delete [SELECT Id FROM SKID__c WHERE Item__c != :sol.Product__r.Item__c];

        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;
        update new Sales_Order__c(Id = sol.Sales_Order__c, Auto_Allocate_Complete__c = true);
        delete c;

        Test.startTest();
        SalesOrderAllocateBatch batchClass = new SalesOrderAllocateBatch();
        batchClass.runBatch(new Process_Job__c(Company__c = fuel.company.Id, Facility__c = fuel.facility2.Id, Days_Ahead__c = 100));
        Test.stopTest();

        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Type__c = :SkidService3.SKID_TYPE_ALLOCATED AND Shipment_Line__r.Sales_Order__c = :fuel.salesOrder.Id];
        System.assert(skids.size() == 0, skids);
    }

    private static testMethod void fullyAllocate() {
        Sales_Order_Line__c sol = fuel.salesOrderLine;
        Sales_Order_Line__c sol2 = fuel.salesOrderLine2;

        fuel.setupInventory();

        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;
        update new Sales_Order__c(Id = sol.Sales_Order__c, Auto_Allocate_Complete__c = true);
        delete c;

        Test.startTest();
        SalesOrderAllocateBatch batchClass = new SalesOrderAllocateBatch();
        batchClass.runBatch(new Process_Job__c(Company__c = fuel.company.Id, Facility__c = fuel.facility2.Id, Days_Ahead__c = 100));
        Test.stopTest();

        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Type__c = :SkidService3.SKID_TYPE_ALLOCATED AND Shipment_Line__r.Sales_Order__c = :fuel.salesOrder.Id];
        System.assert(skids.size() == 2, skids);
    }
}