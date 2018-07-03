@isTest
private class ComponentIssueTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.itemAttrObj2 != null);
        update new Work_Order__c(Id = f.workorder.Id, Contents__c = 'Contents', Completed__c = 1);
        delete [SELECT Id FROM Routing__c];
        update new Component__c(Id = [SELECT Id FROM Component__c][0].Id, Type__c = ComponentService.TYPE_KIT);
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    @isTest
    private static void noComponents() {
        delete [SELECT Id FROM Component__c];

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c op = wo.Operation_Trackings__r[0];
        
        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, op, true).records[0];
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Lot_Number__c = 'LOT1';
        assembly.skid.Item__r = wo.Item__r;

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, op, null, assembly, null, null, true) });

        Test.startTest();
        ComponentIssueBatch job = new ComponentIssueBatch();
        job.runBatch(new Process_Job__c(Name = 'Component Issue'));
        Test.stopTest();

        List<Inventory_Transaction__c> itList = [SELECT Id FROM Inventory_Transaction__c WHERE Item__c != :wo.Item__c];
        System.assert(itList.size() == 0, itList);
    }

    @isTest
    private static void serialTracked() {
        fuel.setupInventory(true, true);

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c op = wo.Operation_Trackings__r[0];
        
        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, op, true).records[0];
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Lot_Number__c = 'LOT1';
        assembly.serialList = new List<Serial__c>{ new Serial__c(Name = 'SERIAL1', Temporary_Value_Holder__c = 'Complete') };
        assembly.skid.Item__r = wo.Item__r;

        Test.startTest();
        
        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, op, null, assembly, null, null, true) });
        
        ComponentIssueBatch job = new ComponentIssueBatch();
        job.runBatch(new Process_Job__c(Name = 'Component Issue'));
        
        Test.stopTest();

        List<Inventory_Transaction__c> itList = [SELECT Id FROM Inventory_Transaction__c WHERE Item__c != :wo.Item__c];
        System.assert(itList.size() == 0, itList);
    }

    @isTest
    private static void noInventory() {
        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c op = wo.Operation_Trackings__r[0];
        
        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, op, true).records[0];
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Lot_Number__c = 'LOT1';
        assembly.skid.Item__r = wo.Item__r;

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, op, null, assembly, null, null, true) });

        Test.startTest();
        ComponentIssueBatch job = new ComponentIssueBatch();
        job.runBatch(new Process_Job__c(Name = 'Component Issue'));
        Test.stopTest();

        List<Inventory_Transaction__c> itList = [SELECT Id FROM Inventory_Transaction__c WHERE Item__c != :wo.Item__c];
        System.assert(itList.size() == 0, itList);
    }

    @isTest
    private static void success() {
        fuel.setupInventory(true);

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        List<WorkOrderWrapper> kitRows = WorkOrderService.getKitData(new Set<Id>{ wo.Id });
        kitRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        WorkOrderService.kit(kitRows);

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c op = wo.Operation_Trackings__r[0];
        
        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, op, true).records[0];
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Lot_Number__c = 'LOT1';
        assembly.skid.Item__r = wo.Item__r;

        Test.startTest();

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, op, null, assembly, null, null, true) });

        ComponentIssueBatch job = new ComponentIssueBatch();
        job.runBatch(new Process_Job__c(Name = 'Component Issue'));

        Test.stopTest();

        List<Inventory_Transaction__c> itList = [SELECT Id FROM Inventory_Transaction__c WHERE Item__c != :wo.Item__c AND Inventory_Change__r.Type__c = 'Work Order Complete'];
        System.assert(itList.size() == 3, itList);
    }

    @isTest
    private static void noSMRs() {
        delete fuel.itemAttrObj;
        delete [SELECT Id FROM Stock_Movement_Rule__c];

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c op = wo.Operation_Trackings__r[0];
        
        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, op, true).records[0];
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Item__r = wo.Item__r;

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, op, null, assembly, null, null, true) });

        Test.startTest();
        ComponentIssueBatch job = new ComponentIssueBatch();
        job.runBatch(new Process_Job__c(Name = 'Component Issue'));
        Test.stopTest();

        List<Inventory_Transaction__c> itList = [SELECT Id FROM Inventory_Transaction__c WHERE Item__c != :wo.Item__c];
        System.assert(itList.size() == 0, itList);
    }

    @isTest
    private static void noInventoryNoAttributes() {
        delete fuel.itemAttrObj;

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c op = wo.Operation_Trackings__r[0];
        
        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, op, true).records[0];
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Item__r = wo.Item__r;

        Test.startTest();

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, op, null, assembly, null, null, true) });

        ComponentIssueBatch job = new ComponentIssueBatch();
        job.runBatch(new Process_Job__c(Name = 'Component Issue'));
        Test.stopTest();

        List<Inventory_Transaction__c> itList = [SELECT Id, Type__c, From_SKID__c, From_SKID__r.Quantity__c FROM Inventory_Transaction__c WHERE Item__c != :wo.Item__c];
        System.assert(itList.size() == 2, itList);
        for (Inventory_Transaction__c it:itList) {
            if (it.Type__c == 'Work Order Component Issue') System.assert(it.From_SKID__c != null && it.From_SKID__r.Quantity__c < 0, it);
        }
    }
}