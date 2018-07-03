/**
 * @description:	Contains test methods for SalesOrderCloseExt.cls
 */
@isTest
public with sharing class SalesOrderCloseExtTest {
	static TestData globalTestData = new TestData();
	
	static testMethod void testSalesOrderCloseExt(){
		
		Test.startTest();
		
		globalTestData.salesOrder.Status__c = 'Closed';
		update globalTestData.salesOrder;
		
		ApexPages.StandardController con = new ApexPages.StandardController(globalTestData.salesOrder);
		
		SalesOrderCloseExt soce = new SalesOrderCloseExt(con);
		System.assertEquals(false, soce.showConfirm);
		
		globalTestData.salesOrder.Status__c = 'Open';
		update globalTestData.salesOrder;
		
		Sales_Order__c SO = [SELECT Id, Total_Product_Weight__c, (select id, Status__c from sales_order_lines__r) FROM Sales_Order__c WHERE Id = :globalTestData.salesOrder.Id];
		System.assert(SO.Total_Product_Weight__c > 0, SO.Total_Product_Weight__c);

		Sales_Order_Line__c[] solList = so.sales_order_lines__r;
		for (sales_order_line__c sol : solList){
			sol.Status__c = SalesOrderService.SO_STATUS_OPEN;
		}
		update solList;

		globalTestData.salesOrder.Status__c = 'Cancelled';
		update globalTestData.salesOrder;
		
		// OTC-485
		SO = [SELECT Id, Total_Product_Weight__c FROM Sales_Order__c WHERE Id = :globalTestData.salesOrder.Id];
		System.assertEquals(0, SO.Total_Product_Weight__c);

		con = new ApexPages.StandardController(globalTestData.salesOrder);
		
		soce = new SalesOrderCloseExt(con);
		System.assertEquals(false, soce.showConfirm);
		
		globalTestData.salesOrder.Status__c = 'Open';

		try {
			update globalTestData.salesOrder;
			System.assertEquals(false, true, 'Cannot update a Cancelled sales order status');
		} catch(Exception e) {
			System.debug(e.getMessage());
		}	
		
		Test.stopTest();
		
	}
	
	static testMethod void testCloseSalesOrder(){
		Test.startTest();
		
		globalTestData.salesOrder.Status__c = 'Open';
		update globalTestData.salesOrder;
		
		for(Sales_Order_Line__c sol : globalTestData.SalesOrderLines){
			sol.Status__c = 'Open';
		}
		
		update globalTestData.SalesOrderLines;
		
		ApexPages.StandardController con = new ApexPages.StandardController(globalTestData.salesOrder);
		
		SalesOrderCloseExt soce = new SalesOrderCloseExt(con);
		
		System.assertEquals(true, soce.showConfirm);

		Test.stopTest();
	}
	
	//Moved the below test from SalesOrderCloneExt
 	public static testMethod void t1() {
        //TestData data = new TestData();
        Test.StartTest(); 
        ApexPages.StandardController sc = new ApexPages.StandardController( globalTestData.salesOrder );
        SalesOrderCloneExt soc = new SalesOrderCloneExt( sc );
        Pagereference p0 = soc.Save();
        system.assert( p0 != null );
     }	
	
}