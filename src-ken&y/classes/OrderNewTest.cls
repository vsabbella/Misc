@isTest

public with sharing class OrderNewTest {
	public static testMethod void testOrderInsert() {
	 	/* 
	 	 * assemble the minimum transfer order
	 	 */
	 	Test.StartTest(); 
		TestFuel fuel = new TestFuel();
	 	Order__c o = fuel.newTransferOrder();
	 	o.Receiving_Company__c = null;
	 	
	 	PageReference pageRef = Page.OrderNew;
    	Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        OrderNewExt ordNew = new OrderNewExt( sc );
        
        ApexPages.currentPage().getParameters().put('companyId', o.Shipping_Company__c);
        ordNew.chg_save();
        system.assert(o.Receiving_Company__c == o.Shipping_Company__c);
        
        Pagereference p0 = ordNew.Save();
        system.assert( p0 != null );

		Order__c o1 = [ select id, status__c from Order__c limit 1];
		system.assertEquals('Draft', o1.Status__c, ' expected new order to be Draft');
		
	}  
	
	public static testMethod void testOrderError() {
	 	/* 
	 	 * assemble the minimum transfer order
	 	 */
	 	Test.StartTest(); 
		TestFuel fuel = new TestFuel();
	 	Order__c o = fuel.newTransferOrder();
	 	o.Receiving_Company__c = null;
	 	
	 	PageReference pageRef = Page.OrderNew;
    	Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        OrderNewExt ordNew = new OrderNewExt( sc );
        Pagereference p0 = ordNew.Save();
        system.assert( p0 == null );
		
	}    
}