@isTest
private class ClaimMassResolveExtTest {
	static Testfuel tdf = new Testfuel();
		 
    
	
    static testMethod void testMassResolve() {
       
        Customer_Invoice__c custInvoice;
		 Customer_Invoice_Line__c custInvoiceLine;
		 Customer_Receipt__c custReceipt;
		 List<Customer_Receipt_Line__c> pmtLines;
		 Reason_Code__c resolution;
         Reason_Code__c deductionCode;
    	List<Period__c> periodList = tdf.periodList;
			custInvoice = new Customer_Invoice__c();
			custInvoice.Company__c = tdf.company.Id;
			custInvoice.Customer__c = tdf.customerParent.Id;
            custInvoice.Bill_To_Customer__c = tdf.customerbillto.Id;
			custInvoice.Currency__c = TestFuel.currencyUSD.id;
			custInvoice.Invoice_Type__c = 'Ship Invoice';
			custInvoice.Status__c = 'Open';
			custInvoice.Sales_Order__c = tdf.salesOrder.Id;
			insert custInvoice;
			
			custInvoiceLine = new Customer_Invoice_Line__c();
			custInvoiceLine.Customer_Invoice__c = custInvoice.Id;
			custInvoiceLine.Product__c = tdf.product.Id;
			custInvoiceLine.Quantity_Shipped__c = 10;
			custInvoiceLine.Unit_Price__c = 10;
			custInvoiceLine.Extended_Price__c = 100;
			insert custInvoiceLine;
			
			custReceipt = new Customer_Receipt__c();
			custReceipt.Company__c = tdf.company.Id;
			custReceipt.Type__c = CustomerReceiptService.TYPE_RECEIPT;
			custReceipt.Customer__c = tdf.customerbillto.Id;
			custReceipt.Date_Received__c = system.today();
			insert custReceipt;
			
        	deductionCode = new Reason_Code__c();
            deductionCode.Type__c = 'Deductions';
            deductionCode.Code__c = 'D001';
            insert deductionCode;
			
			pmtLines = new List<Customer_Receipt_Line__c>();
	    	Customer_Receipt_Line__c pmtCash = new Customer_Receipt_Line__c();
	    	pmtCash.Amount__c = 90;
	    	pmtCash.Type__c = 'Payment';
	    	pmtCash.Customer_Invoice__c = custInvoice.Id;
	    	pmtCash.Customer_Receipt__c = custReceipt.Id;
	    	pmtLines.add(pmtCash);
	    	
	    	Customer_Receipt_Line__c pmtInvDed1 = new Customer_Receipt_Line__c();
	    	pmtInvDed1.Amount__c = 5 ;
	    	pmtInvDed1.Type__c = 'Invoice Deduction';
            pmtInvDed1.Reason_Code__c = deductionCode.Id;
	    	pmtInvDed1.Customer_Invoice__c = custInvoice.Id;
	    	pmtInvDed1.Customer_Receipt__c = custReceipt.Id;
	    	pmtLines.add(pmtInvDed1);
	    	
	    	Customer_Receipt_Line__c pmtInvDed2 = new Customer_Receipt_Line__c();
	    	pmtInvDed2.Amount__c = 5;
	    	pmtInvDed2.Type__c = 'Invoice Deduction';
	        pmtInvDed2.Reason_Code__c = deductionCode.Id;
	    	pmtInvDed2.Customer_Invoice__c = custInvoice.Id;
	    	pmtInvDed2.Customer_Receipt__c = custReceipt.Id;
	    	pmtLines.add(pmtInvDed2);
	    	
	    	Customer_Receipt_Line__c genDeduction = new Customer_Receipt_Line__c();
	    	genDeduction.Amount__c = 90;
	    	genDeduction.Type__c = PaymentService.TYPE_GEN_DED;
            genDeduction.Reason_Code__c = deductionCode.Id; 
	    	genDeduction.Customer_Receipt__c = custReceipt.Id;
	    	pmtLines.add(genDeduction);
	    	
	    	insert pmtLines;
	    	
	    	resolution = new Reason_Code__c();
	    	resolution.name = 'Unsaleables';
	    	resolution.type__c = 'Resolution';
	    	insert resolution;
	    	 test.startTest();
	    	custReceipt.finalized__c = true;
	    	custReceipt.Amount_Unapplied__c = 0;
	    	update custReceipt;
    	List<Claim__c> claims = [SELECT Id, name, status__c FROM Claim__c WHERE Customer_Receipt_Line__c IN :pmtLines];
        for(Claim__c c : claims){
        	c.Resolution_Code__c = resolution.Id;
        }
        update claims;
        Apexpages.standardsetcontroller ssCon = new Apexpages.Standardsetcontroller(claims);
        ssCon.setSelected(claims);
        
        ClaimMassResolveExt ext = new ClaimMassResolveExt(ssCon);
    	system.assertEquals(ext.availableClaims.size(), 3, 'We are expecting three claims to be available for resolution.');
    	ext.resolve();
        
        claims = [SELECT Id, name, Claim_Balance__c, status__c, settlement_method__c, settlement_date__c FROM Claim__c WHERE ID in :claims];
        for(Claim__c c : claims){
        	system.assertEquals(c.status__c, ClaimService.STATUS_CLOSED, 'This claim should be closed after manual resolution '+c);
        	system.assertEquals(c.settlement_method__c, ClaimService.SETTLE_MANUAL, 'This claim should reflect a settlement method of manual.');
        	system.assertEquals(c.settlement_date__c, system.today(), 'This claim should be closed today.');
        }
        
        ext = new ClaimMassResolveExt(ssCon);
        system.assertEquals(ext.availableClaims.size(), 0, 'We should not see claims available for resolution anymore');
        system.assertEquals(ext.disabled, true, 'The resolution button should be disabled');
        
        test.stopTest();
        
        
    }
}