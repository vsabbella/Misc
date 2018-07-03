@isTest
public with sharing class SalesOrderLineTest {

	// Majority of Tests MOVED TO SalesOrderTest using TestSetup

	/* OTC-724 - Unable to update pricing for a SO that is Closed but CI is not yet generated */
	static testMethod void testPricingDateWhenSOLisInvoiced() {
		TestInvoice data = TestInvoice.getInstance();
		list<Sales_Order_Line__c> lstSalesOrderLines = new list<Sales_Order_Line__c>();
		Reason_Code__c holdCode = new Reason_Code__c();
		holdCode.Company__c = data.company.Id;
		holdCode.Type__c = 'Invoice Hold';
		holdCode.Code__c = 'D001';
		insert holdCode;
		Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015, 5, 30, 0, 0, 0), rank__c = 1,
		        Group_By_Customer_Hierarchy__c = 'Bill To', Group_By_Sales_Orders__c = true, Company__c = data.company.Id);

		insert igr;
		igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
		system.assertEquals(true, igr.is_Valid__c);
		test.startTest();

		// Other pbl for SO pricing date change
		Pricebook_Line__c pbl1 = new Pricebook_Line__c();
		pbl1.pricebook__c = data.pricebook.id;
		pbl1.product__c = data.product.Id;
		pbl1.price__c = 10;
		pbl1.Start_date__c = system.today() + 21;
		pbl1.End_Date__c = System.today() + 41;
		insert pbl1;

		// Set original pricing date to today
		Sales_Order__c salesOrder = data.soList[0];
		salesOrder.Pricing_Date__c = system.today();
		salesOrder.Price_Determination_Date__c = SalesOrderService.PRICE_DET_MANUAL;
		update salesOrder;
		system.assertEquals(2, [select id from Shipment_Line__c where Sales_Order__c = : salesOrder.id].size());
		list<sales_Order_Line__c> lstSOL = new list<sales_Order_Line__c>();
		data.soLineList[0].Unit_Price__c = 100;
		data.soLineList[1].Unit_Price__c = 100;
		data.soLineList[0].Discount_Percent__c = 0;
		data.soLineList[1].Discount_Percent__c = 0;
		data.soLineList[0].Off_Invoice_Rate__c = 0;
		data.soLineList[1].Off_Invoice_Rate__c = 0;
		lstSOL.add(data.soLineList[0]);
		lstSOL.add(data.soLineList[1]);
		update lstSOL;
		salesOrder = [select id, Pricing_Date__c, Total_Quantity_Ordered__c, Total_Quantity_Shipped__c, Currency__c,
		              (select id, unit_price__c, Quantity_Change_Reason__c from sales_Order_Lines__r where Product__c = : data.product.id)
		              from Sales_Order__c where id = : SalesOrder.id];
		system.assertEquals(salesorder.Total_Quantity_Ordered__c, SalesOrder.Total_Quantity_shipped__c);
		Decimal originalPrice = SalesOrder.Sales_order_lines__r[1].Unit_Price__c;

		Date originalDate = salesOrder.Pricing_Date__c;

		system.assertEquals(system.today(), originalDate);
		salesOrder.Pricing_Date__c = system.today() + 30;
		update salesOrder;

		salesOrder = [select id, Pricing_Date__c, Total_Quantity_Ordered__c, Total_Quantity_Shipped__c, Currency__c,
		              (select id, unit_price__c, Product__c, Quantity_Change_Reason__c from sales_Order_Lines__r where Product__c = : data.product.id)
		              from Sales_Order__c where id = : SalesOrder.id];
		system.assertEquals( salesOrder.Pricing_Date__c, system.today() + 30, 'Expected pricing date to change');
		system.assertEquals( pbl1.price__c, SalesOrder.Sales_order_lines__r[0].Unit_Price__c, 'Expected sol unit price to change');

		system.debug(logginglevel.info, 'salesOrder.sales_Order_Lines__r.size-->' + salesOrder.sales_Order_Lines__r.size());
		list<Fulfillment__c> lstFulfillment = new list<Fulfillment__c>();
		Fulfillment__c fulfillment = new Fulfillment__c(
		    Customer__c = data.customerBillTo.Id,
		    Start_Date__c = DateTime.newInstance(2015, 5, 20, 0, 0, 0),
		    Currency__c = TestFuel.currencyUSD.id,
		    Payment_Term__c = data.terms.ID,
		    Sales_Order_Line__c = salesOrder.sales_Order_Lines__r[0].Id,
		    Sales_Order__c = salesOrder.id,
		    Status__c = 'Complete',
		    Name = 'F1',
		    Invoice_Ready__c = true,
		    Unit_Price__c = 100,
		    Quantity__c = 3,
		    Product__c = salesOrder.sales_Order_Lines__r[0].Product__c);
		lstFulfillment.add(fulfillment);

		Fulfillment__c fulfillment1 = new Fulfillment__c(
		    Customer__c = data.customerBillTo.Id,
		    Start_Date__c = DateTime.newInstance(2015, 5, 20, 0, 0, 0),
		    Currency__c = TestFuel.currencyUSD.id,
		    Payment_Term__c = data.terms.ID,
		    Sales_Order_Line__c = salesOrder.sales_Order_Lines__r[1].Id,
		    Sales_Order__c = salesOrder.id,
		    Status__c = 'Complete',
		    Name = 'F1',
		    Invoice_Ready__c = true,
		    Unit_Price__c = 100,
		    Quantity__c = 4,
		    Product__c = salesOrder.sales_Order_Lines__r[1].Product__c);

		lstFulfillment.add(fulfillment1);
		insert lstFulfillment;

		Database.executeBatch( new CustomerInvoiceBatch(new Set<Id> {data.company.id}) );

		test.stopTest();
		Customer_Invoice_Line__c[] cils = [select id, shipment__c, shipment_line__c, Sales_Order__c, sales_Order_Line__r.Quantity_Shipped__c, sales_Order_Line__r.Quantity_Ordered__c,
		                                   sales_Order_Line__r.product__c, sales_Order_Line__c, Customer_Invoice__r.Sales_Order__c, Quantity_Shipped__c
		                                   from Customer_Invoice_Line__c where Sales_Order__c = : salesOrder.id];
		system.assertEquals(2, cils.size());
		// Update should fail.

		try {
			salesOrder.Pricing_Date__c = originalDate;
			salesOrder.Status__c = 'Closed';
			update salesOrder;
		} catch (DmlException e) {
			system.debug(LoggingLevel.info, e);
			system.assertEquals(true, e.getMessage().contains(label.Cannot_change_pricing_date_when_all_Sales_Order_Lines_Invoiced));
		}

		salesOrder = [select id, Pricing_Date__c, (select id, unit_price__c from sales_Order_Lines__r where Product__c = : data.product.id)
		              from Sales_Order__c where id = : SalesOrder.id];

		// In case update is successful, these assertions will fail
		system.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.Error), ApexPages.getMessages() );
		system.assertNotEquals( originalDate, salesOrder.Pricing_Date__c, 'Expected pricing date to not change to the original date - original: ' + originalDate + ', SO pricing date: ' + salesOrder.Pricing_Date__c); // In case we want to prevent the Pricing Date from changing if SOL is invoiced
		system.assertNotEquals( originalPrice, SalesOrder.Sales_order_lines__r[0].Unit_Price__c, 'Expected sol unit price to not change back to the original price since SOL is invoiced');




		// void or cancel CI and change pricing Date.
	}

	// OTC-175
	public static testMethod void test_QueriesToPlan() {

		SalesOrderTestData data = new SalesOrderTestData();
		system.debug(LoggingLevel.INFO, 'Queries ' + Limits.getQueries() );
		system.assertNotEquals(null, data.salesOrder.id);
		Test.startTest();
		system.assertEquals(0, Limits.getQueries(), ' expected  0 queries' );

		new SalesOrderService().plan(data.salesOrder.id);
		system.assert(Limits.getQueries() <= 26, Limits.getQueries() + ' total queries.. expected 25 queries to plan an order including fulfillments' );

		//system.debug(LoggingLevel.INFO, ExceptionService.messages.size());
		//for( map<string,string> l:ExceptionService.messages ) {
		//    system.debug(LoggingLevel.INFO,l);
		//}
		System.assertEquals(false, ExceptionService.hasErrors, ' ExceptionService.messages not empty' );

		system.debug(LoggingLevel.INFO, 'Queries ' + Limits.getQueries() );
	}

	public static testMethod void test_ItemInactive() {

		SalesOrderTestData data = new SalesOrderTestData();
		data.itemList[0].Active__c = false;
		update data.itemList;

		new SalesOrderService().plan(data.salesOrder.id);

		List<Sales_Order_Line__c> soLines = [select id, name, has_exceptions__c from Sales_Order_Line__c where Sales_Order__c = :data.salesOrder.id];
		system.assertEquals(soLines[0].has_exceptions__c, true, 'Expecting an exception as the item is inactive');

		List<Task> taskList = [Select Id, Exception_Code__c, Subject from Task where whatId = :soLines[0].Id];
		system.assertEquals(taskList.size(), 1,'Expecting Item not active exception to be generated');
		system.assertEquals(taskList[0].Exception_Code__c, 'SOL-ITEM00001');
	}

}