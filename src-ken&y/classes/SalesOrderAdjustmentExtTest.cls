@isTest
private class SalesOrderAdjustmentExtTest {
	// Test no fulfillments created on standard SO release
	testMethod static void testSalesOrderStandardNoFulfillment(){
		
		TestFuel fuel = new TestFuel();

    	Sales_Order__c so = fuel.salesOrder;

    	
		List<Task> tasks = [select id, Status, Subject, WhatID, Exception_Code__c from Task];
        system.assert(tasks.size() == 0, tasks);

		Sales_Order__c[] adjSo = [select id from Sales_Order__c where Type__c IN: SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES ];
		System.assertEquals(0, adjSo.size(), 'Expecting 1');

		SalesOrderService sos = new SalesOrderService();
		sos.plan(new Set<Id>{so.id});

		Fulfillment__c[] ful = [select id, Sales_order_line__r.Sales_Order__c, Sales_order_line__c from Fulfillment__c];
		System.assertEquals(0, ful.size());

		
	}

	testMethod static void testSalesOrderAdjustmentFulfillment(){
		
		TestFuel fuel = new TestFuel();

    	Sales_Order__c so = fuel.salesOrder;

    	so.Type__c = 'Adjustment';
    	so.Ready__c = true;
    	so.Override_Credit_Hold__c = true;
		update so;

		List<Task> tasks = [select id, Status, Subject, WhatID, Exception_Code__c from Task];
        system.assert(tasks.size() == 0, tasks);

		Sales_Order__c[] adjSo = [select id from Sales_Order__c where Type__c IN: SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES ];
		System.assertEquals(1, adjSo.size(), 'Expecting 1');

		SalesOrderService sos = new SalesOrderService();
		sos.plan(new Set<Id>{so.id});

		adjSo = [select id, Override_Credit_Hold__c from Sales_Order__c where Type__c IN: SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES AND Status__c = 'Closed'];
		System.assertEquals(1, adjSo.size(), 'Expecting 1');
		System.assert(adjSo[0].Override_Credit_Hold__c == true);

		Fulfillment__c[] ful = [select id, Sales_order_line__r.Sales_Order__c, Sales_order_line__c from Fulfillment__c];
		System.assertEquals(2, ful.size());

		Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
			Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), 
			rank__c = 1, 
			Group_By_Customer_Hierarchy__c = 'Bill To', 
			Group_By_Sales_Orders__c = true, 
			Company__c = fuel.company.Id
		);
		insert igr;

		igr = [select id, Is_Valid__c, Start_Date__c from Invoice_Grouping_Rule__c where id = :igr.id LIMIT 1];
		system.assert(igr.Is_Valid__c == true);
		system.assert(igr.Start_Date__c <= system.now());
		

		Test.startTest();
    	Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{fuel.company.Id}),10);
        Test.StopTest();

        List<Customer_Invoice__c> lCIs = [Select id, Batch_Job_ID__c,Invoice_Type__c, Finalized__c, Date_Invoiced__c, Has_Exceptions__c, 
        	(Select id, Has_Exceptions__c, Finalized__c from Customer_Invoice_Lines__r) from Customer_Invoice__c];
        
        System.assertEquals(1,lCIs.size());

        // TODO Figure out what the CI exception is
        //for(Customer_Invoice__c ci : lCIs) {
        //	System.assert(ci.Has_Exceptions__c == false);
        //	for (Customer_Invoice_Line__c cil : ci.Customer_Invoice_Lines__r){
        //		system.assert(cil.Has_Exceptions__c == false);
        //		System.assertEquals(true, cil.Finalized__c);
        //	}

        	
        //	System.assertEquals('Adjustment', ci.Invoice_Type__c);
        //	System.assertEquals(jobId, ci.Batch_Job_ID__c);
        //	mInvoicedDates.put(ci.Date_Invoiced__c.date(), ci.Customer_Invoice_Lines__r.size());

        //	System.assertEquals(true, ci.Finalized__c);
        //}
        
        //for(Date d : mInvoicedDates.keySet()) {
        //	if(d.month() == 5)
        //		System.assertEquals(1, mInvoicedDates.get(d));
        //	else
        //		System.assertEquals(2, mInvoicedDates.get(d));
        //}
	}
}