/**
 *  tests for the class CustomerReceiptUnapplyPaymentExt
 */
@isTest
private class CustomerReceiptUnapplyTest {
	
	/*

	public static testMethod void test_unapply_w_on_account_credit_memo() {
        TestDataForFinance data = new TestDataForFinance();
        system.assert( data != null );
		// https://kenandy.atlassian.net/browse/KNDY-1344
    		
		
		Test.StartTest();
		Bank_Account__c bankAcct = new Bank_Account__c();
            bankAcct.Name = 'BOFA1';
            bankAcct.account_type__c = 'Checking';
            bankAcct.GL_Account__c = data.Acctdata.cashGL.id;  
            bankAcct.active__c = true;
            insert bankAcct;
        
		Customer_Invoice__c custInvoice = new Customer_Invoice__c();
        custInvoice.Company__c = data.company.id;
        custInvoice.Customer__c = data.customer.id;
        custInvoice.Sales_Order__c = data.salesOrder1.id;
        custInvoice.Bill_To_Customer__c = data.customer_Billto.Id;
        custInvoice.Sold_to_Customer__c  = data.customerList[0].id;
        custInvoice.Date_Invoiced__c = System.now();
        custInvoice.Finalized__c = true;
        custInvoice.status__c = 'Open';
        custInvoice.Subtotal__c = 7540.0; 
        custInvoice.Invoice_Type__c =  'Ship Invoice'; 
        custInvoice.Currency__c = TestFuel.currencyUSD.id;
        insert custInvoice;
        
        Customer_Invoice_Line__c ciLine = new Customer_Invoice_Line__c();
        ciLine.Customer_Invoice__c = custInvoice.Id;
        ciLine.Product__c = data.product.Id;
        ciLine.Quantity_Shipped__c = 1;
        ciLine.Unit_Price__c = 7540;
        ciLine.Extended_Price__c = 7540;
        insert ciLine;
        
    	Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Amount_Received__c = 15.0;
		//custReceipt.Bank_Account__c = bankAcct.id; 
		custReceipt.Company__c = data.company.Id;
		custReceipt.Customer__c = data.customer_Billto.Id;
		custReceipt.Date_Received__c = system.today();
		//custReceipt.Payment_Method__c = 'Check';
		custReceipt.Currency__c = TestFuel.currencyUSD.id;
		custReceipt.Type__c = CustomerReceiptService.TYPE_RECEIPT;
		//custReceipt.Finalized__c = true;
		insert custReceipt;

        string custInvName = SchemaUtil.getInstance().getLocalNameFromObject(new Customer_Invoice__c());
		
        Customer_Invoice__c cm = new Customer_Invoice__c();
        cm.Company__c = custReceipt.Company__c;
        cm.bill_to_customer__c = custReceipt.Customer__c;
        cm.Date_Invoiced__c = System.now();
        cm.Finalized__c = true;
        cm.status__c = 'Open';
        cm.Invoice_Type__c = 'Credit Memo';
        cm.Currency__c = TestFuel.currencyUSD.id;
        cm.finalized__c = true;
        insert cm;
        
        Customer_Invoice_Line__c cml = new Customer_Invoice_Line__c();
        cml.Customer_Invoice__c = cm.Id;
        cml.Quantity_Shipped__c = -1;
        cml.Unit_Price__c = 10;
        insert cml;
        
        Customer_Invoice__c ci = [select id, Status__c, Balance__c, Date_Invoiced__c, Amount_Paid__c from Customer_Invoice__c where id =: custInvoice.id];
        
        system.debug('ci: ' + ci);
        
        system.assertEquals(0, ci.Amount_Paid__c, ' mis-match amount paid');
        		
        List<Customer_Receipt_Line__c> lines = new List<Customer_Receipt_Line__c>();
        Customer_Receipt_Line__c crlPmt = new Customer_Receipt_Line__c();
        crlPmt.customer_receipt__c = custReceipt.Id;
        crlPmt.Type__c = PaymentService.TYPE_PAYMENT;
        crlPmt.Customer_Invoice__c = custInvoice.Id;
        crlPmt.amount__c = 16;
        lines.add(crlPmt);
        
        Customer_Receipt_Line__c crlCred = new Customer_Receipt_Line__c();
        crlCred.customer_receipt__c = custReceipt.Id;
        crlCred.Type__c = PaymentService.TYPE_CREDIT_MEMO;
        crlCred.Customer_Credit_Memo__c = cm.Id;
        crlCred.amount__c = 1;
        lines.add(crlCred);
        
        insert lines;
        
        //Assert the payment and credit amounts, and the reduced balance on the invoice
        ci = [select id, Amount_Paid__c, balance__c from Customer_Invoice__c where id =: custInvoice.id];
        
        // save above creates payment lines, fetch those
		Customer_Receipt__c cr = [ SELECT Id,
										(SELECT Type__c, Customer_Credit_memo__c, Customer_invoice__c,  Amount__c
											FROM Customer_Receipt_Lines__r) 
									FROM Customer_Receipt__c c  
									WHERE id = :custReceipt.id];
									
		List<Customer_Receipt_Line__c> plines = cr.Customer_Receipt_Lines__r; 
		decimal tot = 0;
        for(Customer_Receipt_Line__c p : plines){ 
    		tot+= p.amount__c;
        } 
		system.assertEquals(17,tot);
        
        cm = [ select id , Balance__c, Total_Amount__c 
        					from  Customer_Invoice__c where id =: cm.id limit 1];
        system.assertEquals(-9, cm.Balance__c, 'Balance__c ->' + cm);
     	system.assert( cm.Total_Amount__c == -10.0 , 'expected -10 ' +cm.Total_Amount__c);
     	
     	//Unapply the payment
        CustomerReceiptUnapplyPaymentExt CRUPExt = new CustomerReceiptUnapplyPaymentExt(new Apexpages.Standardcontroller(cr));
    	CRUPExt.initUnapply();
    	system.assert( CRUPExt.unapplyDisabled == false );
    	CRUPExt.unapplyPayment();
        
        //Assert a successful unapply
        system.assert( Apexpages.hasMessages() == false , Apexpages.getMessages() );
        	
        //Sum the payment lines, assert they have been removed
    	cr = [ Select (Select Amount__c From Customer_Receipt_Lines__r) From Customer_Receipt__c c  where id = :custReceipt.id limit 1];
		plines = cr.Customer_Receipt_Lines__r; 
		tot = 0 ;
		for ( Customer_Receipt_Line__c p : plines ) { 
    		tot+= p.Amount__c;	
		} 
		system.assertEquals(0,tot);
		
		//Assert the balance has been readjusted on the credit memo
		cm = [ select id , Balance__c from  Customer_Invoice__c where id =: cm.id limit 1];
        system.assertEquals(-10, cm.Balance__c, 'Balance__c ->' + cm);
        
	}
	
	*/
}