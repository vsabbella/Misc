@isTest
private class WorkOrderReopenExtTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();

        WorkOrderPlanningService.release(new Set<Id>{ f.workOrder.Id });

        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        update new Work_Order__c(Id = f.workOrder.Id, Status__c = WorkOrderService.WO_STATUS_CLOSED, Close_Date__c = System.now());
        delete [SELECT Id FROM SKID__c WHERE Type__c = :SkidService3.SKID_TYPE_WO_SUPPLY];

        delete c;
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void wrongStatus() {
        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        update new Work_Order__c(Id = fuel.workOrder.Id, Status__c = WorkOrderService.WO_STATUS_IN_PROCESS);

        delete c;

        WorkOrderReopenExt ext = new WorkOrderReopenExt(new ApexPages.StandardController(fuel.workOrder));
        System.assert(ApexPages.hasMessages(ApexPages.Severity.FATAL), ApexPages.getMessages());
        System.assert(ext.disable, ext.disable);
    }

    private static testMethod void fullyComplete() {
        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        update new Work_Order__c(Id = fuel.workOrder.Id, Status__c = WorkOrderService.WO_STATUS_COMPLETE, Quantity_Complete__c = fuel.workOrder.Order_Quantity__c);
        update new Work_Order__c(Id = fuel.workOrder.Id, Status__c = WorkOrderService.WO_STATUS_CLOSED);

        delete c;

        WorkOrderReopenExt ext = new WorkOrderReopenExt(new ApexPages.StandardController(fuel.workOrder));
        ext.reopen();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.FATAL), ApexPages.getMessages());

        Work_Order__c wo = [SELECT Id, Status__c, Close_Date__c, (SELECT Id FROM SKIDs__r WHERE Type__c = :SkidService3.SKID_TYPE_WO_SUPPLY) FROM Work_Order__c WHERE Id = :fuel.workOrder.Id];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_COMPLETE, wo);
        System.assert(wo.Close_Date__c == null, wo);
        System.assert(wo.SKIDs__r.size() == 0, wo.SKIDs__r);
    }

    private static testMethod void hasMaterialQty() {
        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        Material_Tracking__c material = [SELECT Id FROM Material_Tracking__c WHERE Work_Order__c = :fuel.workOrder.Id][0];
        update new Material_Tracking__c(Id = material.Id, Quantity_Completed__c = 1);

        delete c;

        WorkOrderReopenExt ext = new WorkOrderReopenExt(new ApexPages.StandardController(fuel.workOrder));
        ext.reopen();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.FATAL), ApexPages.getMessages());

        Work_Order__c wo = [SELECT Id, Status__c, Close_Date__c, (SELECT Id FROM SKIDs__r WHERE Type__c = :SkidService3.SKID_TYPE_WO_SUPPLY) FROM Work_Order__c WHERE Id = :fuel.workOrder.Id];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS, wo);
        System.assert(wo.Close_Date__c == null, wo);
        System.assert(wo.SKIDs__r.size() == 1, wo.SKIDs__r);
    }

    private static testMethod void hasOperationQty() {
        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        Operation_Tracking__c op = [SELECT Id FROM Operation_Tracking__c WHERE Work_Order__c = :fuel.workOrder.Id][0];
        update new Operation_Tracking__c(Id = op.Id, Quantity_Completed__c = 1);

        delete c;

        WorkOrderReopenExt ext = new WorkOrderReopenExt(new ApexPages.StandardController(fuel.workOrder));
        ext.reopen();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.FATAL), ApexPages.getMessages());

        Work_Order__c wo = [SELECT Id, Status__c, Close_Date__c, (SELECT Id FROM SKIDs__r WHERE Type__c = :SkidService3.SKID_TYPE_WO_SUPPLY) FROM Work_Order__c WHERE Id = :fuel.workOrder.Id];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS, wo);
        System.assert(wo.Close_Date__c == null, wo);
        System.assert(wo.SKIDs__r.size() == 1, wo.SKIDs__r);
    }

    private static testMethod void noQty() {
        WorkOrderReopenExt ext = new WorkOrderReopenExt(new ApexPages.StandardController(fuel.workOrder));
        ext.reopen();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.FATAL), ApexPages.getMessages());

        Work_Order__c wo = [SELECT Id, Status__c, Close_Date__c, (SELECT Id FROM SKIDs__r WHERE Type__c = :SkidService3.SKID_TYPE_WO_SUPPLY) FROM Work_Order__c WHERE Id = :fuel.workOrder.Id];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_RELEASED, wo);
        System.assert(wo.Close_Date__c == null, wo);
        System.assert(wo.SKIDs__r.size() == 1, wo.SKIDs__r);
    }
}