@isTest
public with sharing class WorkOrderContentsExtTest {
    
    private static testMethod void testMissedCases() {
        TestFuel fuel = new TestFuel();
        List<SKID__c> skids = fuel.skids;
        Work_Order__c wo = fuel.workOrder;
        wo.contents__c = '1,2,3,7,8,14,15,16,19,20';
        update wo;
        //expected values
        String completeCases = '1-3,7-8,14-16,19-20';
        String missingCases = '4,5,6,9,10,11,12,13,17,18';
        Integer totalMissingCases = 10;
        WorkOrderPlanningService.release(new Set<Id>{wo.Id});
        ApexPages.StandardController con = new ApexPages.StandardController(wo);
        WorkOrderContentsExt ext = new WorkOrderContentsExt(con);
        
        System.assert(ext.completeCases != null );
        System.assert(ext.missingCases != null );
        System.assert(ext.totalMissingCases != null );
        System.assertEquals(completeCases,ext.completeCases);
        System.assertEquals(missingCases,ext.missingCases);
        System.assertEquals(totalMissingCases,ext.totalMissingCases);
        
    }  
    private static testMethod void testNOMissedCases() {
        TestFuel fuel = new TestFuel();
        List<SKID__c> skids = fuel.skids;
        Work_Order__c wo = fuel.workOrder;
        wo.contents__c = '1,2,3,4,5';
        update wo;
        //expected values
        String completeCases = '1-5';
        WorkOrderPlanningService.release(new Set<Id>{wo.Id});
        ApexPages.StandardController con = new ApexPages.StandardController(wo);
        WorkOrderContentsExt ext = new WorkOrderContentsExt(con);
        
        System.assert(ext.completeCases != null );
        System.assert(ext.missingCases == null );
        System.assert(ext.totalMissingCases == null );
        System.assertEquals(completeCases,ext.completeCases);
        
    }
}