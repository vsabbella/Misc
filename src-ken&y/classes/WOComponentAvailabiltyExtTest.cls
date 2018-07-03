@isTest
public with sharing class WOComponentAvailabiltyExtTest {
    private static testMethod void testInvalidId() {
        TestFuel fuel = new TestFuel();
        Work_Order__c wo = fuel.workOrder;
        wo.Id = null;
        ApexPages.StandardController con = new ApexPages.StandardController(wo);
        WOComponentAvailabiltyExt ext = new WOComponentAvailabiltyExt(con);     
        System.assert(ApexPages.hasMessages(),'Work order should not be found');
    }
    private static testMethod void testNotReleased() {
        TestFuel fuel = new TestFuel();
        Work_Order__c wo = fuel.workOrder;
        ApexPages.StandardController con = new ApexPages.StandardController(wo);
        WOComponentAvailabiltyExt ext = new WOComponentAvailabiltyExt(con);     
        System.assert(ApexPages.hasMessages(),'Work order should not be released');
    }
    private static testMethod void testNoMaterials() {
        TestFuel fuel = new TestFuel();
        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{wo.Id});
        delete [SELECT Id FROM Material_Tracking__c];
        ApexPages.StandardController con = new ApexPages.StandardController(wo);
        WOComponentAvailabiltyExt ext = new WOComponentAvailabiltyExt(con);     
        System.assert(ApexPages.hasMessages(),'No material tracking records should be found');
    }
    private static testMethod void testSuccess() {
        TestFuel fuel = new TestFuel();
        List<SKID__c> skids = fuel.skids;
        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{wo.Id});
        ApexPages.StandardController con = new ApexPages.StandardController(wo);
        WOComponentAvailabiltyExt ext = new WOComponentAvailabiltyExt(con);
        Boolean bool = ext.hasNext;
        bool = ext.hasPrevious;
        Integer i = ext.pageNumber;
        i = ext.numberOfPages;
        ext.first();
        ext.last();
        ext.previous();
        ext.next();
        System.assert(ext.mList != null && ext.mList.size() > 0,'Records should be found');
    }
}