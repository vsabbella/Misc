@isTest
public class CustomerReceiptManageGatewayExtTest {
	
	@testSetup static void ts() { 
		TestFuel data = new TestFuel();	
		// these asserts cause TestFuelQuery to insert data
		system.assert(		
			data.company != null &&
			data.customerSoldTo != null &&
			data.customerBillTo != null &&
			data.customerParent != null &&
			data.product_Misc != null &&
			data.product != null &&
			data.periodList != null &&
			data.salesOrder != null &&
			data.salesOrderLines != null
						
		);
		system.assert(data.paymentProfile != null &&
			data.paymentMethod != null &&
			data.custInv1 != null &&
			data.bankAccount != null);
	}
	
    public class MockRestServiceResponse implements HttpCalloutMock {
		
	    public HttpResponse respond(HttpRequest req) {
	    	
	    	string xmlBody = req.getBody();
	    	Dom.Document doc = new Dom.Document();
	    	doc.load(xmlBody);
	    	Dom.XMLNode reqRoot = doc.getRootElement();
	    	string reqRootName = reqRoot.getName();
	    	system.debug('reqRootName: ' + reqRootName);
	    	
	    	HttpResponse resp = new HttpResponse();
	    	resp.setHeader('Content-Type', 'text/xml');
	    	resp.setStatusCode(200);
	        resp.setBody(requestResponseBodies.get(reqRootName));
	    	return resp;
	    }
	}
    
    // Refund Prepayment
    static testMethod void testExtensionRefundTransaction_FullAmount(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        TestFuelQuery fuel = new TestFuelQuery();
        Company__c company = fuel.company;
        system.assertNotEquals(null, fuel.bankAccount.Id);
        List<Period__c> periods = fuel.periodList;
        Customer__c custParent = fuel.customerParent;
        Sales_Order__c so = fuel.salesOrder;
		
		Customer_Receipt__c cr = new Customer_Receipt__c();
		cr.Amount_Received__c = 10;
		cr.Transaction_Date__c = system.now();
		cr.Transaction_Currency__c = 'USD';
		cr.Company__c = company.Id;
		cr.Customer__c = custParent.Id;
		cr.Payment_Method_3__c = fuel.paymentMethod.Id;
		cr.Transaction_ID__c = 'abc123';
		cr.Type__c = 'Receipt';
		
		insert cr;
		system.assertEquals(null,[SELECT Id, Amount_In_Words__c from Customer_Receipt__c where Id =:cr.Id].Amount_In_Words__c);
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Prepayment';
		crl.Sales_Order__c = so.Id;
		insert crl;
		
		cr.Finalized__c = true;
		update cr;
		
		system.assertEquals(null,[SELECT Id, Amount_In_Words__c from Customer_Receipt__c where Id =:cr.Id].Amount_In_Words__c);
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
       	requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
        Test.startTest();
        CustomerReceiptManageGatewayExt ext = new CustomerReceiptManageGatewayExt(new Apexpages.Standardcontroller(cr));
        ext.updateTransactionDetails();
        system.assert(ext.isRefundable);
        ext.refundPayment(10);
        Test.stopTest();
        
        List<Customer_Receipt__c> refunds = [SELECT Id, status__c, Amount_Received__c,Amount_In_Words__c,finalized__c, Payment_Method_3__c FROM Customer_Receipt__c WHERE Id != :cr.Id AND Payment_Method_3__c = :fuel.paymentMethod.Id AND Type__c = 'Refund'];
        system.assertEquals(1, refunds.size());
        system.assertEquals('Ten and 00/100',refunds[0].Amount_In_Words__c,refunds[0].Amount_In_Words__c); 
        system.assertEquals(-10, refunds[0].Amount_Received__c);
        system.assertEquals(true, refunds[0].finalized__c);
        system.assertNotEquals(null, refunds[0].Payment_Method_3__c);
        
        Customer_Invoice__c ci = [Select Id, balance__c from Customer_Invoice__c where Invoice_Type__c = 'Prepayment' and Customer_Receipt__c = :cr.ID limit 1];
        system.assertEquals(0,ci.balance__c);
        String tmpId = refunds[0].id;
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', tmpId );
		SourceDocumentUnfinalize srcDocUnfinalizeExt1 = new SourceDocumentUnfinalize();
		ExceptionService.messages.clear();
		boolean errorExists = false;
		srcDocUnfinalizeExt1.unfinalizeSourceDoc();
		errorExists = true;
		for(ApexPages.Message msg: apexPages.getMessages()) {
			if(msg.getDetail().contains('Cannot Unfinalize payments via Credit Cards.')) 
				errorExists = true;
		}
		system.assertEquals(true, errorExists, ApexPages.getMessages());
        
    }
    
    // Refund parital amount on an unapplied prepayment CR
    static testMethod void testExtensionRefundTransaction_PartAmount(){
        Set<String> expectedCRLTypes = new set<String>{PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT};

        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        TestFuelQuery fuel = new TestFuelQuery();
        Company__c company = fuel.company;
        system.assertNotEquals(null, fuel.bankAccount.Id);
        List<Period__c> periods = fuel.periodList;
        Customer__c custParent = fuel.customerParent;
        Sales_Order__c so = fuel.salesOrder;
		
		Customer_Receipt__c cr = new Customer_Receipt__c();
		cr.Amount_Received__c = 10;
		cr.Transaction_Date__c = system.now();
		cr.Currency__c = company.Default_Transaction_Currency__c;
		cr.Company__c = company.Id;
		cr.Customer__c = custParent.Id;
		cr.Payment_Method_3__c = fuel.paymentMethod.Id;
		cr.Transaction_ID__c = 'abc123';
		cr.Type__c = 'Receipt';
		
		insert cr;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Prepayment';
		crl.Sales_Order__c = so.Id;
		
		insert crl;
		
		cr.Finalized__c = true;
		update cr;
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
       	requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
        Test.startTest();
        	CustomerReceiptManageGatewayExt ext = new CustomerReceiptManageGatewayExt(new Apexpages.Standardcontroller(cr));
        	ext.updateTransactionDetails();
            system.assert(ext.isRefundable);
        	ext.refundPayment(5);
        Test.stopTest();
        
        
        List<Customer_Receipt__c> refunds = [SELECT Id, status__c, Amount_Received__c, 
        							finalized__c, Payment_Method_3__c,Amount_In_Words__c, 
        								(Select Id, Amount__c, Type__c 
        								from Customer_Receipt_Lines__r) 
        							FROM Customer_Receipt__c WHERE 
        							Id != :cr.Id AND Payment_Method_3__c = :fuel.paymentMethod.Id 
        							AND Type__c = 'Refund'];
        system.assertEquals(1, refunds.size());
        system.assertEquals('Five and 00/100',refunds[0].Amount_In_Words__c,refunds[0].Amount_In_Words__c); 
        system.assertEquals(-5, refunds[0].Amount_Received__c);
        system.assertEquals(true, refunds[0].finalized__c);
        system.assertNotEquals(null, refunds[0].Payment_Method_3__c);
        system.assertEquals(1, refunds[0].Customer_Receipt_Lines__r.size(), '>>>> refunds[0].Customer_Receipt_Lines__r: ' + refunds[0].Customer_Receipt_Lines__r);
        set<String> crlTypes = new set<String>();
        for(Customer_Receipt_Line__c receiptLine : refunds[0].Customer_Receipt_Lines__r) {
            crlTypes.add(receiptLine.Type__c);
        }
        system.assert(crlTypes.containsAll(expectedCRLTypes), '>>> crlTypes: ' + crlTypes);
        
        // Balance should increase on CI
        Customer_Invoice__c ci = [Select Id, balance__c from Customer_Invoice__c where Invoice_Type__c = 'Prepayment' and Customer_Receipt__c = :cr.ID limit 1];
        system.assertEquals(-5,ci.balance__c);
        
    }
    
    // Refund Prepayment
    static testMethod void testExtensionRefundTransaction_twoReceiptLines(){
        Set<String> expectedCRLTypes = new set<String>{PaymentService.TYPE_REFUND_APPLIED_PREPAYMENT, PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT};
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
       	requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
        
		
        
        TestFuelQuery fuel = new TestFuelQuery();
        Company__c company = fuel.company;
        system.assertNotEquals(null, fuel.bankAccount.Id);
        List<Period__c> periods = fuel.periodList;
        Customer__c custParent = fuel.customerParent;
        Sales_Order__c so = fuel.salesOrder;
        
		// Create prepayment received for a Sales Order
		// The below CR will have a Sales Order lookup in live scenario
		Customer_Receipt__c prepaymentCR = new Customer_Receipt__c();
		prepaymentCR.Amount_Received__c = 10;
		prepaymentCR.Transaction_Date__c = system.now();
		prepaymentCR.Transaction_Currency__c = 'USD';
		prepaymentCR.Company__c = company.Id;
		prepaymentCR.Customer__c = custParent.Id;
		prepaymentCR.Payment_Method_3__c = fuel.paymentMethod.Id;
		prepaymentCR.Transaction_ID__c = 'abc123';
		prepaymentCR.Type__c = 'Receipt';
		insert prepaymentCR;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = prepaymentCR.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Prepayment';
		crl.Sales_Order__c = so.Id;
		insert crl;
		
		prepaymentCR.Finalized__c = true;
		update prepaymentCR;
		
		// Prepayment CI will be created for $10, Sales Order lookup will be populated in real scenario
		Customer_Invoice__c ci = [Select Id, balance__c, Amount_Paid__c from Customer_Invoice__c where Invoice_Type__c = 'Prepayment' and Customer_Receipt__c = :prepaymentCR.ID limit 1];
		
		// User the above prepayment to pay for another CI
		Customer_Receipt__c prepaymentAppliedCR = new Customer_Receipt__c();
		prepaymentAppliedCR.Amount_To_Apply__c = 10;
		prepaymentAppliedCR.Amount_Unapplied__c = 0;
		prepaymentAppliedCR.Transaction_Date__c = system.now();
		prepaymentAppliedCR.Transaction_Currency__c = 'USD';
		prepaymentAppliedCR.Company__c = company.Id;
		prepaymentAppliedCR.Customer__c = custParent.Id;
		prepaymentAppliedCR.Payment_Method_3__c = fuel.paymentMethod.Id;
		prepaymentAppliedCR.Type__c = 'Receipt';
		insert prepaymentAppliedCR;
		
		system.assertEquals(null,[SELECT Id, Amount_In_Words__c from Customer_Receipt__c where Id =:prepaymentAppliedCR.Id].Amount_In_Words__c);
		
		// User prepayment ci of 10$, to pay for TestFuelQuery.custInv1
		Customer_Receipt_Line__c crl2 = new Customer_Receipt_Line__c();
		crl2.Customer_Receipt__c = prepaymentAppliedCR.Id;
		crl2.Amount__c = 5;
		crl2.Type__c = 'Prepayment Applied';
		crl2.Customer_Invoice__c = ci.Id;//KNDY-13995
		
		Customer_Receipt_Line__c crl3 = new Customer_Receipt_Line__c();
		crl3.Customer_Receipt__c = prepaymentAppliedCR.Id;
		crl3.Amount__c = 5;
		crl3.Type__c = 'Payment';
		crl3.Customer_Invoice__c = fuel.custInv1.Id;// another CI with SO lookup;
		List<Customer_Receipt_Line__c> crls = new List<Customer_Receipt_Line__c>();
		crls.add(crl2);
		crls.add(crl3);
		insert crls;

		prepaymentAppliedCR.Finalized__c = true;
		system.assertEquals(null,[SELECT Id, Amount_In_Words__c from Customer_Receipt__c where Id =:prepaymentAppliedCR.Id].Amount_In_Words__c);
		
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Customer_Receipt__c-'+Customer_Receipt__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Customer_Receipt_Line__c-'+Customer_Receipt_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        update prepaymentAppliedCR;
        
        ci.Credit_Applied__c = 5;
        Customer_invoice__c ciStd = fuel.custInv1;
        ciStd.Amount_Paid__c = 5;
        
        update new list<Customer_Invoice__c> {ci, ciStd};
        delete lConfigs;
        
        // CI should have a balance
		ci = [Select Id, balance__c, Amount_Paid__c, Total_Amount__c,Credit_Applied__c, Deduction_Amount__c,Write_Off_Amount__c,Discount_Taken__c from Customer_Invoice__c where Invoice_Type__c = 'Prepayment' and Customer_Receipt__c = :prepaymentCR.ID limit 1];
		system.assert(ci.balance__c == -5);
        Test.startTest();
        // Refund prepaymet CR for full amount of $10
        	CustomerReceiptManageGatewayExt ext = new CustomerReceiptManageGatewayExt(new Apexpages.Standardcontroller(prepaymentCR));
        	ext.updateTransactionDetails();
            system.assert(ext.isRefundable);
        	ext.refundPayment(10);
        
        List<Customer_Receipt__c> refunds = [SELECT Id, status__c, Amount_Received__c, 
        							finalized__c, Payment_Method_3__c, Amount_In_Words__c,
        								(Select Id, Amount__c, Type__c, Customer_Invoice__c 
        								from Customer_Receipt_Lines__r) 
        							FROM Customer_Receipt__c WHERE 
        							Id != :prepaymentCR.Id AND Payment_Method_3__c = :fuel.paymentMethod.Id 
        							AND Type__c = 'Refund'];
        system.assertEquals(1, refunds.size());
        system.assertEquals(-10, refunds[0].Amount_Received__c);
        system.assertEquals('Ten and 00/100',refunds[0].Amount_In_Words__c,refunds[0].Amount_In_Words__c); 
        system.assertEquals(true, refunds[0].finalized__c);
        system.assertNotEquals(null, refunds[0].Payment_Method_3__c);
        system.assertEquals(2, refunds[0].Customer_Receipt_Lines__r.size(), '>>>> refunds[0].Customer_Receipt_Lines__r: ' + refunds[0].Customer_Receipt_Lines__r);
        set<String> crlTypes = new set<String>();
        for(Customer_Receipt_Line__c receiptLine : refunds[0].Customer_Receipt_Lines__r) {
            crlTypes.add(receiptLine.Type__c);
            if (receiptLine.Type__c == PaymentService.TYPE_REFUND_APPLIED_PREPAYMENT){
                system.assert(receiptLine.Customer_Invoice__c == fuel.custInv1.Id, '>>>REFUND_APPLIED_PREPAYMENT receiptLine: ' + receiptLine);
            }
        }
        system.assert(crlTypes.containsAll(expectedCRLTypes), '>>> crlTypes: ' + crlTypes);
        Test.stopTest();
    }

    // Refund Prepayment
    static testMethod void testExtensionRefundTransaction_Twice(){ //KNDY-12895
        Set<String> expectedCRLTypes = new set<String>{PaymentService.TYPE_REFUND_APPLIED_PREPAYMENT, PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT};
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        // turn triggers off for the listed sobjects
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Customer_Receipt__c-'+Customer_Receipt__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Customer_Receipt_Line__c-'+Customer_Receipt__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        TestFuelQuery fuel = new TestFuelQuery();
        Company__c company = fuel.company;
        system.assertNotEquals(null, fuel.bankAccount.Id);
        List<Period__c> periods = fuel.periodList;
        Customer__c custParent = fuel.customerParent;
        Sales_Order__c so = fuel.salesOrder;
        
		// Create prepayment received for a Sales Order
		// The below CR will have a Sales Order lookup in live scenario
		Customer_Receipt__c prepaymentCR = new Customer_Receipt__c();
		prepaymentCR.Amount_Received__c = 10;
		prepaymentCR.Transaction_Date__c = system.now();
		prepaymentCR.Currency__c = company.Default_Transaction_Currency__c;
		prepaymentCR.Company__c = company.Id;
		prepaymentCR.Customer__c = custParent.Id;
		prepaymentCR.Payment_Method_3__c = fuel.paymentMethod.Id;
		prepaymentCR.Transaction_ID__c = 'abc123';
		prepaymentCR.Type__c = 'Receipt';
		prepaymentCR.Status__c = 'Closed';
		insert prepaymentCR;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = prepaymentCR.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Prepayment';
		crl.Currency__c = company.Default_Transaction_Currency__c;
		crl.Sales_Order__c = so.Id;
		insert crl;
		
		prepaymentCR.Finalized__c = true;
		update prepaymentCR;
		
		Customer_Invoice__c ci = createPrepaymentCI(-10, prepaymentCR);
		ci.Currency__c = company.Default_Transaction_Currency__c;
		insert ci;
		Customer_Invoice_Line__c ciline = createCILine( ci, 1, -10);
		insert ciline;
		
		//ciline = [Select Id, Extended_Price__c from Customer_Invoice_Line__c where Id = :ciline.Id];
		//system.assert(ciline.Extended_Price__c == -10, '>>> ciline: ' + ciline);
		// Prepayment CI will be created for $10, Sales Order lookup will be populated in real scenario
		ci = [Select Id, balance__c, Amount_Paid__c, Total_Amount__c,Credit_Applied__c, Deduction_Amount__c,Write_Off_Amount__c,Discount_Taken__c from Customer_Invoice__c where Invoice_Type__c = 'Prepayment' and Customer_Receipt__c = :prepaymentCR.ID limit 1];
		system.assert(ci.balance__c == -10, '>>> ci: ' + ci);
		// Use the above prepayment to pay for another CI
		Customer_Receipt__c prepaymentAppliedCR = new Customer_Receipt__c();
		prepaymentAppliedCR.Amount_To_Apply__c = 10;
		prepaymentAppliedCR.Amount_Unapplied__c = 0;
		prepaymentAppliedCR.Transaction_Date__c = system.now();
		prepaymentAppliedCR.Currency__c = company.Default_Transaction_Currency__c;
		prepaymentAppliedCR.Company__c = company.Id;
		prepaymentAppliedCR.Customer__c = custParent.Id;
		prepaymentAppliedCR.Payment_Method_3__c = fuel.paymentMethod.Id;
		prepaymentAppliedCR.Type__c = 'Receipt';
		prepaymentAppliedCR.Status__c = 'Closed';
		insert prepaymentAppliedCR;
		
		// Use prepayment ci of 10$, to pay for TestFuelQuery.custInv1
		Customer_Receipt_Line__c crl2 = new Customer_Receipt_Line__c();
		crl2.Customer_Receipt__c = prepaymentAppliedCR.Id;
		crl2.Amount__c = 6;
		crl2.Type__c = 'Prepayment Applied';
		crl2.Currency__c = company.Default_Transaction_Currency__c;
		crl2.Customer_Invoice__c = ci.Id; //KNDY-13995
		Customer_Receipt_Line__c crl3 = new Customer_Receipt_Line__c();
		crl3.Customer_Receipt__c = prepaymentAppliedCR.Id;
		crl3.Amount__c = 6;
		crl3.Type__c = 'Payment';
		crl3.Currency__c = company.Default_Transaction_Currency__c;
		crl3.Customer_Invoice__c = fuel.custInv1.Id;// another CI with SO lookup;
		List<Customer_Receipt_Line__c> crls = new List<Customer_Receipt_Line__c>();
		crls.add(crl2);
		crls.add(crl3);
		insert crls;

	    prepaymentAppliedCR.Finalized__c = true;
		update prepaymentAppliedCR;
		
		
		// CI should have a balance
		//ci = [Select Id, balance__c, Amount_Paid__c, Total_Amount__c,Credit_Applied__c, Deduction_Amount__c,Write_Off_Amount__c,Discount_Taken__c from Customer_Invoice__c where Invoice_Type__c = 'Prepayment' and Customer_Receipt__c = :prepaymentCR.ID limit 1];
		//system.assert(1 != 1, '>>> ci total amount balance : ' + ci);
		//Customer_Invoice__c:{Id=a0fj0000003nx0MAAQ, KINS__Balance__c=-4.00, 
		//KINS__Amount_Paid__c=0.00, KINS__Total_Amount__c=-10.00, KINS__Credit_Applied__c=6.00, 
		//KINS__Deduction_Amount__c=0.00, KINS__Write_Off_Amount__c=0.00, KINS__Discount_Taken__c=0.00}
		//system.assert(ci.balance__c == -4);

		// Create Refund CR (Refund 7$)
		Customer_Receipt__c refundCR = new Customer_Receipt__c();
		refundCR.Amount_Received__c = -7;
		refundCR.Amount_Unapplied__c = 0;
		refundCR.Transaction_Date__c = system.now();
		refundCR.Currency__c = company.Default_Transaction_Currency__c;
		refundCR.Company__c = company.Id;
		refundCR.Customer__c = custParent.Id;
		refundCR.Payment_Method_3__c = fuel.paymentMethod.Id;
		refundCR.Related_Customer_Receipt__c = prepaymentCR.Id;
		refundCR.Type__c = 'Refund';
		refundCR.Status__c = 'Closed';
		insert refundCR;
		
		//Insert CRLines for refund CR
		//TYPE_REFUND_APPLIED_PREPAYMENT - 3$ tied to fuel custInv1
		//TYPE_REFUND_UNAPPLIED_PREPAYMENT - 4$ tied to prepayment ci
		Customer_Receipt_Line__c crl5 = new Customer_Receipt_Line__c();
		crl5.Customer_Receipt__c = refundCR.Id;
		crl5.Amount__c = -3;
		crl5.Currency__c = company.Default_Transaction_Currency__c;
		crl5.Type__c = PaymentService.TYPE_REFUND_APPLIED_PREPAYMENT;
		crl5.Customer_Invoice__c = fuel.custInv1.Id; // ci lookup to which it was applied before the refund
		Customer_Receipt_Line__c crl4 = new Customer_Receipt_Line__c();
		crl4.Customer_Receipt__c = refundCR.Id;
		crl4.Amount__c = -4;
		crl4.Currency__c = company.Default_Transaction_Currency__c;
		crl4.Type__c = PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT;
		crl4.Customer_Invoice__c = ci.Id;// prepayment ci lookup //KNDY-13995
		crls = new List<Customer_Receipt_Line__c>();
		crls.add(crl4);
		crls.add(crl5);
		insert crls;

		delete lConfigs;// activate triggers
		
		refundCR.Finalized__c = true;
		update refundCR;
		
		system.assertEquals('Seven and 00/100',[SELECT Id, Amount_In_Words__c from Customer_Receipt__c where Id =:refundCR.Id].Amount_In_Words__c);
		
		Test.startTest();
		
		// Balance should be 0 on prepayment CI after the refund
		ci = [Select Id, balance__c, Amount_Paid__c, Total_Amount__c,Credit_Applied__c, Deduction_Amount__c,Write_Off_Amount__c,Discount_Taken__c from Customer_Invoice__c where Invoice_Type__c = 'Prepayment' and Customer_Receipt__c = :prepaymentCR.ID limit 1];
		//Balance = KINS__Total_Amount__c+KINS__Credit_Applied__c-KINS__Debit_Applied__c-
        //(KINS__Amount_Paid__c + KINS__Deduction_Amount__c + KINS__Write_Off_Amount__c + KINS__Discount_Taken__c)
        	// Customer_Invoice__c:{Id=a0fj0000003nx0vAAA, KINS__Balance__c=0.00, KINS__Amount_Paid__c=0.00, 
		// KINS__Total_Amount__c=-10.00, KINS__Credit_Applied__c=6.00, KINS__Deduction_Amount__c=0.00, 
		// KINS__Write_Off_Amount__c=0.00, KINS__Discount_Taken__c=0.00}
		system.assert(ci.balance__c == 0,'>>> ci total amount balance : ' + ci);
		
		// Balance should be reduced by 3
		Decimal origBalance = 0; // balance is null in testfuel custInv1
		Customer_Invoice__c fuelCustInv1 = [Select Id, Balance__c, Amount_Paid__c, Total_Amount__c,Credit_Applied__c, Deduction_Amount__c,Write_Off_Amount__c,Discount_Taken__c from Customer_Invoice__c where Id = :fuel.custInv1.Id];
		//system.assert(1 != 1, '>>> fuelCustInv1 total amount balance : ' + fuelCustInv1);
		system.assert(fuelCustInv1.Balance__c == (origBalance-3) );
		
		// Prepayment CR ($10 total) was first refunded for $7, Now Refund it for $3
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
       	requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
        	CustomerReceiptManageGatewayExt ext = new CustomerReceiptManageGatewayExt(new Apexpages.Standardcontroller(prepaymentCR));
        	ext.updateTransactionDetails();
            system.assert(ext.isRefundable);
        	ext.refundPayment(3);
        
        List<Customer_Receipt__c> refunds = [SELECT Id, status__c, Amount_Received__c, 
        							finalized__c, Payment_Method_3__c,Amount_In_Words__c, 
        								(Select Id, Amount__c, Type__c, Customer_Invoice__c 
        								from Customer_Receipt_Lines__r) 
        							FROM Customer_Receipt__c WHERE 
        							Id != :prepaymentCR.Id AND Id != :refundCR.Id AND 
        							Payment_Method_3__c = :fuel.paymentMethod.Id 
        							AND Type__c = 'Refund'];
        system.assertEquals(1, refunds.size());
        system.assertEquals(-3, refunds[0].Amount_Received__c);
        system.assertEquals('Three and 00/100', refunds[0].Amount_In_Words__c);
        system.assertEquals(true, refunds[0].finalized__c);
        system.assertNotEquals(null, refunds[0].Payment_Method_3__c);
        system.assertEquals(1, refunds[0].Customer_Receipt_Lines__r.size(), '>>>> refunds[0].Customer_Receipt_Lines__r: ' + refunds[0].Customer_Receipt_Lines__r);
        for(Customer_Receipt_Line__c receiptLine : refunds[0].Customer_Receipt_Lines__r) {
            system.assert(receiptLine.Type__c == PaymentService.TYPE_REFUND_APPLIED_PREPAYMENT, '>>>REFUND_APPLIED_PREPAYMENT receiptLine: ' + receiptLine);
            system.assert(receiptLine.Customer_Invoice__c == fuel.custInv1.Id, '>>>REFUND_APPLIED_PREPAYMENT receiptLine: ' + receiptLine);
        }
		// Balance on fuel custInv1 should go up after refund
    		Double expectedBalance = -3+3;
		fuelCustInv1 = [Select Id, Balance__c, Amount_Paid__c, Total_Amount__c,Credit_Applied__c, Deduction_Amount__c,Write_Off_Amount__c,Discount_Taken__c from Customer_Invoice__c where Id = :fuel.custInv1.Id];
		//system.assert(1 != 1, '>>> fuelCustInv1 total amount balance : ' + fuelCustInv1);
		system.assert(fuelCustInv1.Balance__c == expectedBalance );
    		
    		Test.stopTest();
    }
    
    // Refund Prepayment
    static testMethod void testNotRefundable_AlreadyRefunded() {
    	insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        TestFuelQuery fuel = new TestFuelQuery();
        Company__c company = fuel.company;
        List<Period__c> periods = fuel.periodList;
        Customer__c custParent = fuel.customerParent;
        
       
		
		Customer_Receipt__c cr = new Customer_Receipt__c();
		cr.Amount_Received__c = 10;
		cr.Transaction_Date__c = system.now();
		cr.Currency__c = company.Default_Transaction_Currency__c;
		cr.Company__c = company.Id;
		cr.Customer__c = custParent.Id;
		cr.Payment_Method_3__c = fuel.paymentMethod.Id;
		cr.Transaction_ID__c = 'abc123';
		cr.Type__c = 'Receipt';
		
		insert cr;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Prepayment';
		insert crl;
		
		cr.Finalized__c = true;
		update cr;
		
		Customer_Receipt__c refundCR = new Customer_Receipt__c();
		refundCR.Amount_Received__c = -10;
		refundCR.Type__c = 'Refund';
		refundCR.Transaction_Date__c = system.now();
		refundCR.Transaction_Currency__c = 'USD';
		refundCR.Company__c = company.Id;
		refundCR.Customer__c = custParent.Id;
		refundCR.Payment_Method_3__c = fuel.paymentMethod.Id;
		refundCR.Transaction_ID__c = 'abc123';
		refundCR.Type__c = 'Receipt';
		refundCR.Related_Customer_Receipt__c = cr.Id;
		
		insert refundCR;
		
		Customer_Receipt_Line__c crl1 = new Customer_Receipt_Line__c();
		crl1.Customer_Receipt__c = refundCR.Id;
		crl1.Amount__c = -10;
		crl1.Type__c = PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT;
		insert crl1;
		
		CustomerReceiptService.isCodeExecuted = false;
		refundCR.Finalized__c = true;
		update refundCR;
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
       	requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
        Test.startTest();
        	CustomerReceiptManageGatewayExt ext = new CustomerReceiptManageGatewayExt(new Apexpages.Standardcontroller(cr));
        	ext.updateTransactionDetails();
            system.assertNotEquals(true,ext.isRefundable);
            
            boolean ErrorExists = false;
	        for( ApexPages.Message msg :ApexPages.GetMessages())
		    	if(msg.getDetail().contains('Cannot refund this transaction as the enitre amount has been already refunded'))
		    	{
		    		ErrorExists = true;
		    		break;
		    	}
	        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
        	
        Test.stopTest();
		
		
		
    }
    
    // Refund Prepayment
    static testMethod void testNotRefundable_RefundAmountHigher() {
    	insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        TestFuelQuery fuel = new TestFuelQuery();
        Company__c company = fuel.company;
        List<Period__c> periods = fuel.periodList;
        Customer__c custParent = fuel.customerParent;
        
        
		Customer_Receipt__c cr = new Customer_Receipt__c();
		cr.Amount_Received__c = 10;
		cr.Transaction_Date__c = system.now();
		cr.Transaction_Currency__c = 'USD';
		cr.Company__c = company.Id;
		cr.Customer__c = custParent.Id;
		cr.Payment_Method_3__c = fuel.paymentMethod.Id;
		cr.Transaction_ID__c = 'abc123';
		cr.Type__c = 'Receipt';
		
		insert cr;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Prepayment';
		insert crl;
		
		cr.Finalized__c = true;
		update cr;
		
		
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
       	requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
        Test.startTest();
        	CustomerReceiptManageGatewayExt ext = new CustomerReceiptManageGatewayExt(new Apexpages.Standardcontroller(cr));
        	ext.updateTransactionDetails();
            system.assertEquals(true,ext.isRefundable);
            ext.amountToRefund = 15;
            ext.validateRefundAmount();
            boolean ErrorExists = false;
	        for( ApexPages.Message msg :ApexPages.GetMessages())
		    	if(msg.getDetail().contains('Cannot refund an amount higher than the amount received on orginal transaction'))
		    	{
		    		ErrorExists = true;
		    		break;
		    	}
	        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
        	
        Test.stopTest();
		
		
		
    }
    
	// Refund Prepayment for amount higher than available amount
	static testMethod void testExtRefundPrepayment_AmountHigherThanAvailable(){
		insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
		
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c company = fuel.company;
		List<Period__c> periods = fuel.periodList;
		Customer__c custParent = fuel.customerParent;
		
		
		
		// Create prepayment received for a Sales Order
		// The below CR will have a Sales Order lookup in live scenario
		Customer_Receipt__c prepaymentCR = new Customer_Receipt__c();
		prepaymentCR.Amount_Received__c = 10;
		prepaymentCR.Transaction_Date__c = system.now();
		prepaymentCR.Transaction_Currency__c = 'USD';
		prepaymentCR.Company__c = company.Id;
		prepaymentCR.Customer__c = custParent.Id;
		prepaymentCR.Payment_Method_3__c = fuel.paymentMethod.Id;
		prepaymentCR.Transaction_ID__c = 'abc123';
		prepaymentCR.Type__c = 'Receipt';
		insert prepaymentCR;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = prepaymentCR.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Prepayment';
		insert crl;
		
		prepaymentCR.Finalized__c = true;
		update prepaymentCR;
	
		// Prepayment CI will be created for $10, Sales Order lookup will be populated in real scenario
		Customer_Invoice__c ci = [Select Id, balance__c, Amount_Paid__c from Customer_Invoice__c where Invoice_Type__c = 'Prepayment' and Customer_Receipt__c = :prepaymentCR.ID limit 1];
		system.assert(ci != null);
		
		// Refund some of the prepayment CR
		Customer_Receipt__c refundCR = new Customer_Receipt__c();
		refundCR.Amount_Received__c = -5;
		refundCR.Type__c = 'Refund';
		refundCR.Transaction_Date__c = system.now();
		refundCR.Transaction_Currency__c = 'USD';
		refundCR.Company__c = company.Id;
		refundCR.Customer__c = custParent.Id;
		refundCR.Payment_Method_3__c = fuel.paymentMethod.Id;
		refundCR.Transaction_ID__c = 'abc1234';
		refundCR.Type__c = 'Receipt';
		refundCR.Related_Customer_Receipt__c = prepaymentCR.Id;
		
		insert refundCR;
		
		Customer_Receipt_Line__c crl1 = new Customer_Receipt_Line__c();
		crl1.Customer_Receipt__c = refundCR.Id;
		crl1.Amount__c = -5;
		crl1.Type__c = PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT;
		insert crl1;
		
		CustomerReceiptService.isCodeExecuted = false;
		refundCR.Finalized__c = true;
		update refundCR;
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
		Test.startTest();
		
		// Attempt to refund full amount on prepayment CR
		CustomerReceiptManageGatewayExt ext = new CustomerReceiptManageGatewayExt(new Apexpages.Standardcontroller(prepaymentCR));
		ext.updateTransactionDetails();
		system.assertEquals(true,ext.isRefundable);
		ext.amountToRefund = 10;
		ext.validateRefundAmount();
		boolean ErrorExists = false;
		for( ApexPages.Message msg :ApexPages.GetMessages()){
			if(msg.getDetail().contains('Cannot refund an amount higher than amount available to refund'))
			{
				ErrorExists = true;
				break;
			}
		}
		system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
		Test.stopTest();
	}
	
	// Refund Payment CR
	static testMethod void testPaymentRefund_NoTransactionId() {
		insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
		
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		c.Credit_Card_Bank_Account__c = fuel.bankAccount.Id;
		update c;
		List<Period__c> periods = fuel.periodList;
		Customer__c custParent = fuel.customerParent;
		
		

		// Create Payment CR against CI
		Customer_Receipt__c cr = new Customer_Receipt__c();
		cr.Amount_Received__c = 10;
		cr.Amount_To_Apply__c = 10;
		cr.Amount_Unapplied__c = 0;
		cr.Transaction_Date__c = system.now();
		cr.Date_Received__c = cr.Transaction_Date__c;
		cr.Transaction_Currency__c = 'USD';
		cr.Company__c = c.Id;
		cr.Customer__c = custParent.Id;
		cr.Payment_Method_3__c = fuel.paymentMethod.Id;
		//cr.Transaction_ID__c = 'abc123';
		cr.Type__c = 'Receipt';
		cr.Reference_Number__c = 'abc123';
		cr.Bank_Account_2__c = c.Credit_Card_Bank_Account__c ;
		insert cr;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Payment';
		crl.Customer_Invoice__c = fuel.custInv1.Id;
		insert crl;
		
		cr.Finalized__c = true;
		update cr;
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
		Test.startTest();
		CustomerReceiptManageGatewayExt ext = new CustomerReceiptManageGatewayExt(new Apexpages.Standardcontroller(cr));
		ext.updateTransactionDetails();
		system.assertEquals(false,ext.isRefundable);
		boolean ErrorExists = false;
		for( ApexPages.Message msg :ApexPages.GetMessages()){
			if(msg.getDetail().contains('Cannot refund this CR as it does not have a Transaction Id'))
			{
				ErrorExists = true;
				break;
			}
		}
		system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
		Test.stopTest();
	}
	
	// Refund Payment CR
	static testMethod void testPaymentRefund_AmountHigherReceived() {
		insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
		
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		c.Credit_Card_Bank_Account__c = fuel.bankAccount.Id;
		update c;
		List<Period__c> periods = fuel.periodList;
		Customer__c custParent = fuel.customerParent;
		
		
		// Create Payment CR against CI
		Customer_Receipt__c cr = new Customer_Receipt__c();
		cr.Amount_Received__c = 10;
		cr.Amount_To_Apply__c = 10;
		cr.Amount_Unapplied__c = 0;
		cr.Transaction_Date__c = system.now();
		cr.Date_Received__c = cr.Transaction_Date__c;
		cr.Transaction_Currency__c = 'USD';
		cr.Company__c = c.Id;
		cr.Customer__c = custParent.Id;
		cr.Payment_Method_3__c = fuel.paymentMethod.Id;
		cr.Transaction_ID__c = 'abc123';
		cr.Type__c = 'Receipt';
		cr.Reference_Number__c = 'abc123';
		cr.Bank_Account_2__c = c.Credit_Card_Bank_Account__c ;
		insert cr;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Payment';
		crl.Customer_Invoice__c = fuel.custInv1.Id;
		insert crl;
		
		cr.Finalized__c = true;
		update cr;
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
		Test.startTest();
		CustomerReceiptManageGatewayExt ext = new CustomerReceiptManageGatewayExt(new Apexpages.Standardcontroller(cr));
		ext.updateTransactionDetails();
		system.assertEquals(true,ext.isRefundable);
		
		// Refund amount higher than amount received on payment
		ext.amountToRefund = 15;
		ext.validateRefundAmount();
		boolean ErrorExists = false;
		for( ApexPages.Message msg :ApexPages.GetMessages()){
			if(msg.getDetail().contains('Cannot refund an amount higher than the amount received on orginal transaction'))
			{
				ErrorExists = true;
				break;
			}
		}
		system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
		Test.stopTest();
	}
	
	// Refund Payment for amount higher than available amount
	static testMethod void testPaymentRefund_AmountHigherThanAvailable(){
		insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
		
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		c.Credit_Card_Bank_Account__c = fuel.bankAccount.Id;
		update c;
		List<Period__c> periods = fuel.periodList;
		Customer__c custParent = fuel.customerParent;
		
		

		// Create Payment CR against CI
		Customer_Receipt__c cr = new Customer_Receipt__c();
		cr.Amount_Received__c = 10;
		cr.Amount_To_Apply__c = 10;
		cr.Amount_Unapplied__c = 0;
		cr.Transaction_Date__c = system.now();
		cr.Date_Received__c = cr.Transaction_Date__c;
		cr.Transaction_Currency__c = 'USD';
		cr.Company__c = c.Id;
		cr.Customer__c = custParent.Id;
		cr.Payment_Method_3__c = fuel.paymentMethod.Id;
		cr.Transaction_ID__c = 'abc123';
		cr.Type__c = 'Receipt';
		cr.Reference_Number__c = 'abc123';
		cr.Bank_Account_2__c = c.Credit_Card_Bank_Account__c ;
		insert cr;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Payment';
		crl.Customer_Invoice__c = fuel.custInv1.Id;
		insert crl;
		
		cr.Finalized__c = true;
		update cr;
		
		// Refund some of the payment CR
		Customer_Receipt__c refundCR = new Customer_Receipt__c();
		refundCR.Amount_Received__c = -5;
		refundCR.Type__c = 'Refund';
		refundCR.Transaction_Date__c = system.now();
		refundCR.Transaction_Currency__c = 'USD';
		refundCR.Company__c = c.Id;
		refundCR.Customer__c = custParent.Id;
		refundCR.Payment_Method_3__c = fuel.paymentMethod.Id;
		refundCR.Transaction_ID__c = 'abc1234';
		refundCR.Type__c = 'Receipt';
		refundCR.Related_Customer_Receipt__c = cr.Id;
		insert refundCR;
		
		Customer_Receipt_Line__c crl1 = new Customer_Receipt_Line__c();
		crl1.Customer_Receipt__c = refundCR.Id;
		crl1.Amount__c = -5;
		crl1.Type__c = PaymentService.TYPE_REFUND_APPLIED_PAYMENT;
		insert crl1;
		
		CustomerReceiptService.isCodeExecuted = false;
		refundCR.Finalized__c = true;
		update refundCR;
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
		Test.startTest();
		
		// Attempt to refund full amount on payment CR
		CustomerReceiptManageGatewayExt ext = new CustomerReceiptManageGatewayExt(new Apexpages.Standardcontroller(cr));
		ext.updateTransactionDetails();
		system.assertEquals(true,ext.isRefundable);
		ext.amountToRefund = 10;
		ext.validateRefundAmount();
		boolean ErrorExists = false;
		for( ApexPages.Message msg :ApexPages.GetMessages()){
			if(msg.getDetail().contains('Cannot refund an amount higher than amount available to refund'))
			{
				ErrorExists = true;
				break;
			}
		}
		system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
		Test.stopTest();
	}
	
	// Refund Payment for available amount
	static testMethod void testPaymentRefund_AvailableAmount(){
		Set<String> expectedCRLTypes = new set<String>{PaymentService.TYPE_REFUND_APPLIED_PAYMENT};
		
		insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
		
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		c.Credit_Card_Bank_Account__c = fuel.bankAccount.Id;
		update c;
		List<Period__c> periods = fuel.periodList;
		Customer__c custParent = fuel.customerParent;
		
		

		// Create Payment CR against CI
		Customer_Receipt__c cr = new Customer_Receipt__c();
		cr.Amount_Received__c = 10;
		cr.Amount_To_Apply__c = 10;
		cr.Amount_Unapplied__c = 0;
		cr.Transaction_Date__c = system.now();
		cr.Date_Received__c = cr.Transaction_Date__c;
		cr.Transaction_Currency__c = 'USD';
		cr.Company__c = c.Id;
		cr.Customer__c = custParent.Id;
		cr.Payment_Method_3__c = fuel.paymentMethod.Id;
		cr.Transaction_ID__c = 'abc123';
		cr.Type__c = 'Receipt';
		cr.Reference_Number__c = 'abc123';
		cr.Bank_Account_2__c = c.Credit_Card_Bank_Account__c ;
		insert cr;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Payment';
		crl.Customer_Invoice__c = fuel.custInv1.Id;
		insert crl;
		
		cr.Finalized__c = true;
		update cr;
		
		// Refund some of the payment CR
		Customer_Receipt__c refundCR = new Customer_Receipt__c();
		refundCR.Amount_Received__c = -5;
		refundCR.Type__c = 'Refund';
		refundCR.Transaction_Date__c = system.now();
		refundCR.Transaction_Currency__c = 'USD';
		refundCR.Company__c = c.Id;
		refundCR.Customer__c = custParent.Id;
		refundCR.Payment_Method_3__c = fuel.paymentMethod.Id;
		refundCR.Transaction_ID__c = 'abc1234';
		refundCR.Type__c = 'Receipt';
		refundCR.Related_Customer_Receipt__c = cr.Id;
		insert refundCR;
		
		Customer_Receipt_Line__c crl1 = new Customer_Receipt_Line__c();
		crl1.Customer_Receipt__c = refundCR.Id;
		crl1.Amount__c = -5;
		crl1.Type__c = PaymentService.TYPE_REFUND_APPLIED_PAYMENT;
		insert crl1;
		
		CustomerReceiptService.isCodeExecuted = false;
		refundCR.Finalized__c = true;
		update refundCR;
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
		Test.startTest();
		
		// Attempt to refund full amount on payment CR
		CustomerReceiptManageGatewayExt ext = new CustomerReceiptManageGatewayExt(new Apexpages.Standardcontroller(cr));
		ext.updateTransactionDetails();
		system.assertEquals(true,ext.isRefundable);
		ext.updateTransactionDetails();
		system.assert(ext.isRefundable);
		ext.refundPayment(5);

		Test.stopTest();
		
		List<Customer_Receipt__c> refunds = [SELECT Id, status__c, Amount_Received__c, 
									finalized__c, Payment_Method_3__c, 
										(Select Id, Amount__c, Type__c, Customer_Invoice__c 
										from Customer_Receipt_Lines__r) 
									FROM Customer_Receipt__c WHERE 
									Id != :cr.Id AND Payment_Method_3__c = :fuel.paymentMethod.Id 
									AND Type__c = 'Refund'];
		system.assertEquals(1, refunds.size());
		system.assertEquals(-5, refunds[0].Amount_Received__c);
		system.assertEquals(true, refunds[0].finalized__c);
		system.assertNotEquals(null, refunds[0].Payment_Method_3__c);
		system.assertEquals(1, refunds[0].Customer_Receipt_Lines__r.size(), '>>>> refunds[0].Customer_Receipt_Lines__r: ' + refunds[0].Customer_Receipt_Lines__r);
		set<String> crlTypes = new set<String>();
		for(Customer_Receipt_Line__c receiptLine : refunds[0].Customer_Receipt_Lines__r) {
			crlTypes.add(receiptLine.Type__c);
		}
		system.assert(crlTypes.containsAll(expectedCRLTypes), '>>> crlTypes: ' + crlTypes);
		Customer_Receipt_Line__c crline = refunds[0].Customer_Receipt_Lines__r[0];
		system.assert(crline.Customer_Invoice__c == fuel.custInv1.Id, '>>> crline: '+crline);
		
		Customer_Invoice__c ci = [Select Id, balance__c from Customer_Invoice__c where Id = :fuel.custInv1.Id];
		system.assertEquals(-5,ci.balance__c);
	}
    static testMethod void testCancelTransaction(){
    	
    	insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	TestFuelQuery fuel = new TestFuelQuery();
    	Company__c c = fuel.Company;
		List<Period__c> periods = fuel.periodList;
		Customer__c custParent = fuel.customerParent;
		
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
		
		Customer_Receipt__c cr = new Customer_Receipt__c();
		cr.Amount_Received__c = 10;
		cr.Transaction_Date__c = system.now();
		cr.Currency__c = c.Default_Transaction_Currency__c;
		cr.Company__c = c.Id;
		cr.Customer__c = custParent.Id;
		cr.Payment_Method_3__c = pm.Id;
		cr.Transaction_ID__c = 'abc123';
		cr.Type__c = 'Receipt';
		
		insert cr;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Prepayment';
		insert crl;
		
		cr.Finalized__c = true;
		update cr;
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		Test.startTest();
		
		JSONResult result = CustomerReceiptVoidCancelExt.voidTransaction(cr.Id, cr.Transaction_ID__c);
		
		Test.stopTest();
		
		system.assertEquals(true, result.success,result.messages);
		
		
    }

	static testMethod void testVoidCancelSettledTransaction(){ //KNDY-18799
		insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		List<Period__c> periods = fuel.periodList;
		Customer__c custParent = fuel.customerParent;
		
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
		
		Customer_Receipt__c cr = new Customer_Receipt__c();
		cr.Amount_Received__c = 10;
		cr.Transaction_Date__c = system.now();
		cr.Currency__c = c.Default_Transaction_Currency__c;
		cr.Company__c = c.Id;
		cr.Customer__c = custParent.Id;
		cr.Payment_Method_3__c = pm.Id;
		cr.Transaction_ID__c = '12345';
		cr.Type__c = 'Receipt';
		
		insert cr;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Prepayment';
		insert crl;
		
		cr.Finalized__c = true;
		update cr;
		
		requestResponseBodies.put('getTransactionDetailsRequest', requestResponseBodies.get('getTransactionDetailsRequest').replace('capturedPendingSettlement','settledSuccessfully'));
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		Test.startTest();
		Map<Id, VoidCancelService.VoidCancelDetail> vcdMap = new CustomerReceiptVoidCancelService().getBusinessVoidCancelDetails(new List<sObject>{cr});
		VoidCancelService.VoidCancelDetail vcd = vcdMap.get(cr.Id);
		Boolean foundCannotVoidMessage = false;
		system.assert(vcd.cancelMessages[0].contains(Label.Cannot_cancel_settled_customer_receipt), vcd );
		for (String msg: vcd.voidMessages){
			if (msg.contains(Label.Cannot_void_settled_customer_receipt)){
				foundCannotVoidMessage = true;
			}
		}
		system.assertEquals(foundCannotVoidMessage, true, vcd );
		Test.stopTest();
	}
    
    private static Customer_Invoice__c  createPrepaymentCI(Decimal balance, Customer_Receipt__c prepaymentCR){
       Customer_Invoice__c ci = new Customer_Invoice__c();
       //ci.balance__c = -10;
       ci.Amount_Paid__c = 0;
      // ci.Total_Amount__c = -10;
       //ci.Credit_Applied__c, 
       ci.Invoice_Type__c = 'Prepayment';
       ci.Customer_Receipt__c = prepaymentCR.ID;
       return ci;
    }
    
    /* Extended Price = (Quantity_Shipped__c*
  (Unit_Price__c - NULLVALUE(Off_Invoice_Rate__c, 0))) *
   (1- NULLVALUE(Discount_Percent__c, 0)) -NULLVALUE(Freight_Allowance__c,0) -NULLVALUE(Allowances__c,0)
,2)
    */
    private static Customer_Invoice_Line__c createCILine(Customer_Invoice__c ci, Decimal unitPrice, Integer qtyShipped){
        Customer_Invoice_Line__c ciline = new Customer_Invoice_Line__c();
        ciline.Quantity_Shipped__c = qtyShipped;
        ciline.Unit_Price__c = unitPrice;
        ciline.Customer_Invoice__c = ci.Id;
        return ciline;
    }
    
    @testVisible
    private static map<string, string> requestResponseBodies = new map<string, string>{
    	'getCustomerProfileRequest' 			=> 	'<?xml version="1.0" encoding="utf-8"?> <getCustomerProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <profile> <merchantCustomerId>custId123</merchantCustomerId> <description>some description</description> <email>mark@example.com</email> <customerProfileId>10000</customerProfileId> <paymentProfiles> <billTo> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> <faxNumber></faxNumber> </billTo> <customerPaymentProfileId>20000</customerPaymentProfileId> <payment> <creditCard> <cardNumber>XXXX1111</cardNumber> <expirationDate>XXXX</expirationDate> </creditCard> </payment> </paymentProfiles> <paymentProfiles> <customerPaymentProfileId>20001</customerPaymentProfileId> <payment> <bankAccount> <accountType>checking</accountType> <routingNumber>XXXX0000</routingNumber> <accountNumber>XXXX0000</accountNumber> <nameOnAccount>John Doe</nameOnAccount> <bankName>Bank of Washington</bankName> </bankAccount> </payment> </paymentProfiles> <shipToList> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> <faxNumber></faxNumber> </shipToList> <shipToList> <firstName>Jane</firstName> <lastName>Doe</lastName> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> </shipToList> </profile> </getCustomerProfileResponse>',
    	'createCustomerProfileRequest' 			=>	'<?xml version="1.0" encoding="UTF-8"?> <createCustomerProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <customerProfileId>38545475</customerProfileId> <customerPaymentProfileIdList> <numericString>35049701</numericString> </customerPaymentProfileIdList> <customerShippingAddressIdList /> <validationDirectResponseList> <string>1,1,1,(TESTMODE) This transaction has been approved.,000000,P,0,none,Test transaction for ValidateCustomerPaymentProfile.,1.00,CC,auth_only,Cust_Id_1450292633,,,,,,,,,,,ryan.sieve@kenandy.com,,,,,,,,,0.00,0.00,0.00,FALSE,none,939D83D40EDEAB16DCEC897FE84C3C85,,,,,,,,,,,,,XXXX1111,Visa,,,,,,,,,,,,,,,,</string> </validationDirectResponseList> </createCustomerProfileResponse>',
    	'createCustomerPaymentProfileRequest'	=>	'<?xml version="1.0" encoding="utf-8"?> <createCustomerPaymentProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <customerPaymentProfileId>20000</customerPaymentProfileId> <validationDirectResponse>1,1,1,This transaction has been approved.,000000,Y,2000000000,none,Test transaction for ValidateCustomerPaymentProfile.,0.01,CC,auth_only,custId123, John,Doe,,123 Main St.,Bellevue,WA,98004,USA,000-000-0000,,mark@example.com,,,,,,,,,0.00,0.00,0.00,,none, D18EB6B211FE0BBF556B271FDA6F92EE,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, </validationDirectResponse> </createCustomerPaymentProfileResponse>',
    	'createTransactionRequest'				=> 	'<?xml version="1.0" encoding="utf-8"?> <createTransactionResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <refId>123456</refId> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <transactionResponse> <responseCode>1</responseCode> <authCode>UGELQC</authCode> <avsResultCode>E</avsResultCode> <cavvResultCode /> <transId>2148061808</transId> <refTransID /> <transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash> <accountNumber>XXXX0015</accountNumber> <accountType>MasterCard</accountType> <message> <code>1</code> <description>This transaction has been approved.</description> </message> <userFields> <userField> <name>MerchantDefinedFieldName1</name> <value>MerchantDefinedFieldValue1</value> </userField> <userField> <name>favorite_color</name> <value>lavender</value> </userField> </userFields> </transactionResponse> </createTransactionResponse>',
    	'authenticateTestRequest'				=> 	'<?xml version="1.0" encoding="utf-8"?> <authenticateTestResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> </authenticateTestResponse>',
    	'getTransactionDetailsRequest'			=> 	'<?xml version="1.0" encoding="utf-8"?> <getTransactionDetailsResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <transaction> <transId>12345</transId> <refTransId>12345</refTransId> <splitTenderId>12345</splitTenderId> <submitTimeUTC>2010-08-30T17:49:20.757Z</submitTimeUTC> <submitTimeLocal>2010-08-30T13:49:20.757</submitTimeLocal> <transactionType>authCaptureTransaction</transactionType> <transactionStatus>capturedPendingSettlement</transactionStatus> <responseCode>1</responseCode> <responseReasonCode>1</responseReasonCode> <responseReasonDescription> Approval</responseReasonDescription> <authCode>000000</authCode> <AVSResponse>X</AVSResponse> <cardCodeResponse>M</cardCodeResponse> <CAVVResponse>2</CAVVResponse> <FDSFilterAction>authAndHold</FDSFilterAction> <FDSFilters> <FDSFilter> <name>Hourly Velocity Filter</name> <action>authAndHold</action> </FDSFilter> <FDSFilter> <name>Amount Filter</name> <action>report</action> </FDSFilter> </FDSFilters> <batch> <batchId>12345</batchId> <settlementTimeUTC>2010-08-30T17:49:20.757Z</settlementTimeUTC> <settlementTimeLocal>2010-08-30T13:49:20.757</settlementTimeLocal> <settlementState>settledSuccessfully</settlementState> </batch> <order> <invoiceNumber>INV00001</invoiceNumber> <description>some description</description> <purchaseOrderNumber>PO000001</purchaseOrderNumber> </order> <requestedAmount>5.00</requestedAmount> <authAmount>2.00</authAmount> <settleAmount>2.00</settleAmount> <tax> <amount>1.00</amount> <name>WA state sales tax</name> <description>Washington state sales tax</description> </tax> <shipping> <amount>2.00</amount> <name>ground based shipping</name> <description>Ground based 5 to 10 day shipping</description> </shipping> <duty> <amount>1.00</amount> </duty> <lineItems> <lineItem> <itemId>ITEM00001</itemId> <name>name of item sold</name> <description>Description of item sold</description> <quantity>1</quantity> <unitPrice>6.95</unitPrice> <taxable>true</taxable> </lineItem> <lineItem> <itemId>ITEM00001</itemId> <name>name of item sold</name> <description>Description of item sold</description> <quantity>1</quantity> <unitPrice>6.95</unitPrice> <taxable>true</taxable> </lineItem> </lineItems> <prepaidBalanceRemaining>30.00</prepaidBalanceRemaining> <taxExempt>false</taxExempt> <payment> <!-- either creditCard or bankAccount will be here --> <creditCard> <cardNumber>XXXX1111</cardNumber> <expirationDate>XXXX</expirationDate> <accountType>Visa</accountType> </creditCard> <!--<bankAccount> <routingNumber>XXXX0000</routingNumber> <accountNumber>XXXX0000</accountNumber> <nameOnAccount>John Doe</nameOnAccount> <echeckType>WEB</echeckType> </bankAccount>--> </payment> <customer> <type>individual</type> <id>ABC00001</id> <email>mark@example.com</email> </customer> <billTo> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> <faxNumber></faxNumber> </billTo> <shipTo> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> </shipTo> <recurringBilling>false</recurringBilling> <customerIP>0.0.0.0</customerIP> <subscription> <id>145521</id> <paynum>1</paynum> <marketType>eCommerce</marketType> <product>Card Not Present</product> <returnedItems> <returnedItem> <id>2148878904</id> <dateUTC>2014-05-12T21:22:44Z</dateUTC> <dateLocal>2014-05-12T14:22:44</dateLocal> <code>R02</code> <description>Account Closed</description> </returnedItem> </returnedItems> <solution> <id>A1000004</id> <name>Shopping Cart</name> </solution> <mobileDeviceId>2354578983274523978</mobileDeviceId> </subscription> </transaction> </getTransactionDetailsResponse>'									
    };
}