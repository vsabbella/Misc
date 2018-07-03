@isTest
public with sharing class WorkOrderUndoReleaseTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.workOrder != null);
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void testUndoReleaseNoneSelected() {
        List<Work_Order__c> workOrders  = new List<Work_Order__c>{ fuel.workOrder }; 
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(workOrders);
        WOUndoReleaseExtension ext = new WOUndoReleaseExtension(sc);
        System.assert(ApexPages.hasMessages(ApexPages.Severity.FATAL),ApexPages.getMessages());
    }
    private static testMethod void testUndoReleaseNotReleased() {
        List<Work_Order__c> workOrders  = new List<Work_Order__c>{ fuel.workOrder }; 
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(workOrders);
        sc.setSelected(workOrders);
        WOUndoReleaseExtension ext = new WOUndoReleaseExtension(sc);
        System.assert(ApexPages.hasMessages(ApexPages.Severity.FATAL),ApexPages.getMessages());
    }
    private static testMethod void testUndoRelease() {
        WorkOrderPlanningService.release(new Set<Id>{ fuel.workOrder.Id });
        
        List<Work_Order__c> workOrders  = new List<Work_Order__c>{ fuel.workOrder }; 
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(workOrders);
        sc.setSelected(workOrders);
        WOUndoReleaseExtension ext = new WOUndoReleaseExtension(sc);
        System.assert(ext.undoRelease() != null,ApexPages.getMessages());
    }

    public static testMethod void testUndoReleaseNotReleased2() {
        WorkOrderUndoReleaseExt ext = new WorkOrderUndoReleaseExt(new ApexPages.StandardController(fuel.workOrder));
        System.assert(ext.undoRelease() == null,ApexPages.getMessages());
        System.assert(ApexPages.hasMessages(ApexPages.Severity.FATAL),ApexPages.getMessages());
    }
    public static testMethod void testUndoRelease2() {
        WorkOrderPlanningService.release(new Set<Id>{ fuel.workOrder.Id });

        WorkOrderUndoReleaseExt ext = new WorkOrderUndoReleaseExt(new ApexPages.StandardController(fuel.workOrder));
        System.assert(ext.undoRelease() != null,ApexPages.getMessages());
        
        Work_Order__c workOrder = [SELECT Id,Name,Status__c,Release_Date__c FROM Work_Order__c WHERE Id = :fuel.workOrder.Id LIMIT 1];
        System.assert(workOrder.Status__c == 'Draft' && workOrder.Release_Date__c == null,'Work order should not be released');
        System.assert([SELECT Id FROM Material_Tracking__c WHERE Work_Order__c = :fuel.workOrder.Id].size() == 0,'Should have 0 materials');
        System.assert([SELECT Id FROM Operation_Tracking__c WHERE Work_Order__c = :fuel.workOrder.Id].size() == 0,'Should have 0 operations');
    }
}