@isTest
private class WorkOrderClosedExtTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null && f.stockMovementRuleList != null && f.itemSpec != null);

        delete [SELECT Id FROM Routing__c];

        WorkOrderPlanningService.release(new Set<Id>{ f.workOrder.Id });
    }
    
    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void testWrongStatus() {
        WorkOrderPlanningService.undoRelease(new Set<Id>{ fuel.workOrder.Id });

        WorkOrderClosedExt ext = new WorkOrderClosedExt(new ApexPages.StandardController(fuel.workOrder));
        System.assert(ext.disableCloseButton);
    }

    public static testMethod void testAssemblyWipSkid() {
        insert new SKID__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.workOrder.Item__c,
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.workOrder.Complete_To_Location__c,
            Quantity__c = 1,
            Type__c = SkidService3.SKID_TYPE_WIP,
            Work_Order__c = fuel.workOrder.Id
        );

        WorkOrderClosedExt ext = new WorkOrderClosedExt(new ApexPages.StandardController(fuel.workOrder));
        System.assert(ApexPages.hasMessages(ApexPages.Severity.FATAL), ApexPages.getMessages());
        System.assert(ext.disableCloseButton);
    }

    public static testMethod void testMaterialWipSkid() {
        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ fuel.workOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r' })[0];
        
        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id, Lot_Number__c = false);
        update new Material_Tracking__c(Id = wo.Material_Trackings__r[0].Id, Type__c = 'Kit', Operation_Tracking__c = null);

        insert new SKID__c(
            Company__c = fuel.company.Id,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Item__c = wo.Material_Trackings__r[0].Item__c,
            Container_Item__c = wo.Material_Trackings__r[0].Item__c,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Stocking_UOM__c = fuel.uomList[8].Id,
            Packaging_UOM__c = fuel.uomList[8].Id,
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Expiration_Date__c = System.today() + 30
        );

        JsonResult kitResult = WorkOrderKitExtV2.getKitData(wo.Id);
        List<WorkOrderWrapper> kitRows = (List<WorkOrderWrapper>)kitResult.records;
        kitRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        WorkOrderKitExtV2.save(kitRows,new List<String>(),new List<String>());
        
        WorkOrderClosedExt ext = new WorkOrderClosedExt(new ApexPages.StandardController(wo));
        System.assert(ApexPages.hasMessages(ApexPages.Severity.FATAL),ApexPages.getMessages());
    }

    public static testMethod void testClose() {
        WorkOrderPlanningService.release(new Set<Id>{ fuel.workOrder.Id });
        
        WorkOrderClosedExt ext = new WorkOrderClosedExt(new ApexPages.StandardController(fuel.workOrder));
        ext.closeWorkOrder();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.FATAL),ApexPages.getMessages());

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ fuel.workOrder.Id },null,null,null)[0];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_CLOSED,'Expected WO status: Closed // WO status: ' + wo.Status__c);
        System.assert(wo.Close_Date__c != null,'Expected not null WO close date');
    }
}