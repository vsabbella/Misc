@isTest
public class SalesOrderUndoReleaseTest {

	public static testMethod void testUndoRelease(){
        
        TestFuel fuel = new TestFuel();
        
        List<Period__c> periodList = fuel.periodList;
        Sales_Order__c salesOrder = fuel.salesOrder;
        List<SKID__c> skids = fuel.skids;    

        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;

        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SOPlanExt soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();
        System.assertEquals(false, soPlanExt.hasErrors, ApexPages.getMessages());
        
        for (Sales_Order_Line__c SOL : [SELECT Id, Status__c
        								  FROM Sales_Order_Line__c]){
        	System.assertEquals(SalesOrderLineService.SO_LINE_STATUS_OPEN, SOL.Status__c);	
        }

        Test.startTest();

        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);
        system.assert( SOAExt.solWrapperList.size() == 2 );
        
        con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderUndoReleaseExt SOUndoReleaseExt = new SalesOrderUndoReleaseExt(con);
        SOUndoReleaseExt.undoRelease(); // Undo release
        System.assertEquals(false, SOUndoReleaseExt.hasErrors, ApexPages.getMessages());
        
        for (Sales_Order_Line__c SOL : [SELECT Id, Status__c 
        								  FROM Sales_Order_Line__c]){
        	System.assertEquals(SalesOrderLineService.SOL_STATUS_DRAFT, SOL.Status__c);
        }

        Test.stopTest();
    }
    
}