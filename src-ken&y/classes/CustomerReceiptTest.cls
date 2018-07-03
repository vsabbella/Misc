@isTest
public class CustomerReceiptTest {
	@testSetup static void ts() { 
        TestFuel globalTestData = new TestFuel(); 
        system.assert(globalTestData.company.Id != null &&
        			  globalTestData.customerParent.Id != null &&
        			  globalTestData.customerBillTo.Id != null &&
        			  globalTestData.resolutionCode.Id != null &&
        			  globalTestData.deductionCode.Id != null &&
        			  globalTestData.customerSoldTo.Id != null &&
        			  globalTestData.salesOrder.id != null && 
        			  globalTestData.periodList != null &&
        			  globalTestData.bankAccount.Id != null);
	}
	
	static testMethod void changeCustomerOnCR () {
		TestFuelQuery fuel = new TestFuelQuery();
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt; 
		
		Customer_Receipt_Line__c additionalPayment = new Customer_Receipt_Line__c();
		additionalPayment.Amount__c = 1;
		additionalPayment.Customer_Receipt__c = custReceipt.Id;
		additionalPayment.Type__c = PaymentService.TYPE_PREPAYMENT;
		insert additionalPayment;
		
		custReceipt.Customer__c = fuel.customerBillTo.Id;
		try {
			update custReceipt;
		} catch(Exception ex) {
			system.assert(ex.getMessage().contains(Label.Cannot_change_the_customer_on_the_receipt_that_has_lines));
		}
		custReceipt = [select id, Customer__c from Customer_Receipt__c where id  = :custReceipt.id limit 1];
		system.assertEquals(fuel.customerParent.Id,custReceipt.Customer__c);
		
	}
	
	static testMethod void testOverApplyCreditMemo() {
		
		TestFuelQuery fuel = new TestFuelQuery();
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		
		Customer_Invoice__c creditMemo = new Customer_Invoice__c();
		creditMemo.Bill_To_Customer__c = fuel.customerBillTo.Id;
	    creditMemo.Company__c = fuel.company.Id;
	    creditMemo.Invoice_Type__c = 'Credit Memo';
	    creditMemo.Status__c = CustomerInvoiceService.STATUS_OPEN;
	    creditMemo.Date_Invoiced__c = system.now();
	    creditMemo.Currency__c = fuel.currencyUSD.id;
		creditMemo.Transaction_Date__c = system.now();
		insert creditMemo;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = creditMemo.Id;
		cil.Quantity_Shipped__c = -1;
		cil.Unit_Price__c = 10;
		insert cil;
		
		creditMemo.Finalized__c = true;
		update creditMemo;
		
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt; 
		
		Customer_Receipt_Line__c additionalPayment = new Customer_Receipt_Line__c();
		additionalPayment.Amount__c = 12;
		additionalPayment.Customer_Receipt__c = custReceipt.Id;
		additionalPayment.Type__c = PaymentService.TYPE_PREPAYMENT;
		insert additionalPayment;
		
		Customer_Receipt_Line__c OverPaymentLine = new Customer_Receipt_Line__c();
		OverPaymentLine.Amount__c =12;
		OverPaymentLine.Customer_Receipt__c = custReceipt.Id;
		OverPaymentLine.Type__c = PaymentService.TYPE_CREDIT_MEMO;
		OverPaymentLine.Customer_Invoice__c = creditMemo.Id; //KNDY-13995
		OverPaymentLine.Customer__c = fuel.customerBillTo.id;
		insert OverPaymentLine;
		
        System.debug(logginglevel.error,'custReceipt----->>'+custReceipt);
		
		custReceipt.Finalized__c = true;
		boolean errorExists = false;
		try {
			update custReceipt;
		}catch(Exception ex) {
             System.debug(logginglevel.error,'ex.getMessage()----->>'+ex.getMessage());
             if(ex.getMessage().contains('You cannot apply more than the invoice balance.')){
              system.assert(ex.getMessage().contains('You cannot apply more than the invoice balance.'),'Failed with Message 1'+ex.getMessage());
            }else{
              system.assert(ex.getMessage().contains('You cannot apply an amount that is more than the credit memo balance.'),'Failed with Message 2'+ex.getMessage());
            }
            errorExists = true;
		}
		system.assertEquals(true, errorExists,'Should have gotten an error');
	}
	
	static testMethod void negativeAdditionalPayments() {
		TestFuelQuery fuel = new TestFuelQuery();
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt; 
		
		Customer_Receipt_Line__c additionalPayment = new Customer_Receipt_Line__c();
		additionalPayment.Amount__c = -1;
		additionalPayment.Customer_Receipt__c = custReceipt.Id;
		additionalPayment.Type__c = PaymentService.TYPE_PREPAYMENT;
		insert additionalPayment;
		custReceipt = [select id, Total_Number_Of_Lines__c, Has_Exceptions__c, (select id from Customer_Receipt_Lines__r) from Customer_Receipt__c where id  = :custReceipt.id limit 1];
		system.assertEquals(1,custReceipt.Total_Number_Of_Lines__c);
		system.assertEquals(true,custReceipt.Has_Exceptions__c);
		
		task T = [select id, subject from Task where whatId = :custReceipt.Customer_Receipt_Lines__r[0].Id limit 1];
		system.assert(T.subject.equalsIgnoreCase('Prepayment/Overpayment receipt lines cannot be negative'));
		
		
	}
	
	static testMethod void negativeWriteOffPayments() {
        TestFuelQuery fuel = new TestFuelQuery();
        system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
        
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Company__c = fuel.company.Id;
        custReceipt.Customer__c = fuel.customerParent.Id;
        custReceipt.Date_Received__c = system.now();
        custReceipt.Type__c = 'Receipt';
        custReceipt.Currency__c = fuel.currencyUSD.id;
        insert custReceipt; 
        
        Customer_Receipt_Line__c writeoffPayment = new Customer_Receipt_Line__c();
        writeoffPayment.Amount__c = -10;
        writeoffPayment.Customer_Receipt__c = custReceipt.Id;
        writeoffPayment.Type__c = PaymentService.TYPE_WRITEOFF;
        writeoffPayment.Reason_Code__c = fuel.resolutionCode.Id;
        try{
            insert writeoffPayment;
        }catch(DmlException dmlExp){
            System.debug(logginglevel.error,dmlExp.getMessage());
            System.assert(dmlExp.getMessage().contains('The Write Off Amount on an invoice cannot be a negative number. Enter a positive number to continue.'),'The write off amount cannot be a negative amount');
        }catch(Exception exp){
             System.debug(logginglevel.error,exp.getMessage());
        }
    }
    
    static testMethod void writeOffPaymentsRequireReasonCode() {
        TestFuelQuery fuel = new TestFuelQuery();
        system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
        
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Company__c = fuel.company.Id;
        custReceipt.Customer__c = fuel.customerParent.Id;
        custReceipt.Date_Received__c = system.now();
        custReceipt.Type__c = 'Receipt';
        custReceipt.Currency__c = fuel.currencyUSD.id;
        insert custReceipt; 
        
        Customer_Receipt_Line__c writeoffPayment = new Customer_Receipt_Line__c();
        writeoffPayment.Amount__c = 10;
        writeoffPayment.Customer_Receipt__c = custReceipt.Id;
        writeoffPayment.Type__c = PaymentService.TYPE_WRITEOFF;
        try{
            insert writeoffPayment;
        }catch(DmlException dmlExp){
            System.debug(logginglevel.error,dmlExp.getMessage());
            System.assert(dmlExp.getMessage().contains('The Reason Code is required. Enter a Reason Code to continue.'),'The resaon code is required for a write off amount.');
        }catch(Exception exp){
             System.debug(logginglevel.error,exp.getMessage());
        }
    }
    
	static testMethod void UnfinalizeCustomerReceipt()
	{
		TestFuelQuery fuel = new TestFuelQuery();
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt;
		
		Claim__c claim = new Claim__c();
		claim.Company__c = fuel.company.Id;
		claim.Parent_Customer__c = fuel.customerParent.Id;
		claim.Bill_To_Customer__c = fuel.customerBillTo.Id;
		claim.Currency__c = fuel.currencyUSD.id;
		claim.Amount__c = 100;
		claim.Type__c = PaymentService.TYPE_GEN_DED;
		claim.Status__c = 'Open';
		claim.Approval_Status__c = 'Approved';
		insert claim;
		
		Customer_Receipt_Line__c deductionLine = new Customer_Receipt_Line__c();
		deductionLine.Amount__c = 100;
		deductionLine.Customer_Receipt__c = custReceipt.Id;
		deductionLine.Reason_Code__c = fuel.deductionCode.Id;
		deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
		deductionLine.Customer__c = fuel.customerBillTo.Id;
		deductionLine.Sold_To_Customer__c = fuel.customerSoldTo.Id;
		insert deductionLine;
		
		Customer_Receipt_Line__c claimPayment = new Customer_Receipt_Line__c();
		claimPayment.Amount__c = 100;
		claimPayment.Customer_Receipt__c = custReceipt.Id;
		claimPayment.Claim__c = claim.Id;
		claimPayment.Type__c = PaymentService.TYPE_CLAIM_PAYMENT;
		
		insert claimPayment;
		
		custReceipt.finalized__c = true;
		update custReceipt;
		
		custReceipt = [Select Id, Finalized__c, Finalized_Date__c, Date_Received__c, (select id, Type__c, Customer_Invoice__c from Customer_Receipt_Lines__r where Type__c = :PaymentService.TYPE_CLAIM_PAYMENT) from Customer_Receipt__c where id = :custReceipt.Id limit 1];
		
		system.assertEquals(custReceipt.Finalized__c, true, custReceipt);
		system.assertNotEquals(custReceipt.Finalized_Date__c, null, custReceipt);
		system.assertEquals(custReceipt.Customer_Receipt_Lines__r.size(), 1, custReceipt);
		//system.assertNotEquals(custReceipt.Customer_Receipt_Lines__r[0].Customer_Invoice__c, null, custReceipt);
		
		Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = custReceipt.Date_Received__c , 
        												   Bank_Account__c = fuel.bankAccount.Id);
        insert bt;
        
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Customer_Receipt__c = custReceipt.Id, Amount__c = 100);
        insert btm;
        
        BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
        dateTime reconciledDate = system.now();
        BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.Id}, reconciledDate, fuel.bankAccount.id);
        
		
		String tmpId = custReceipt.id;
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', tmpId );
		SourceDocumentUnfinalize srcDocUnfinalizeExt1 = new SourceDocumentUnfinalize();
		ExceptionService.messages.clear();
		try
		{
			srcDocUnfinalizeExt1.unfinalizeSourceDoc();
		}catch(Exception ex)
		{
			system.debug('CR unfinalize exception: '+ex.getMessage()); //AR-87
		}
		
		boolean ErrorExists = false;
        for( ApexPages.Message msg :ApexPages.GetMessages())
        	if(msg.getDetail().contains(Label.transaction_has_been_reconciled))
        	{
        		ErrorExists = true;
        		break;
        	}
        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
		srcDocUnfinalizeExt1.unfinalize();
		
		custReceipt = [Select Id, Finalized__c, Finalized_Date__c, (select id, Type__c, Customer_Invoice__c from Customer_Receipt_Lines__r where Type__c = :PaymentService.TYPE_CLAIM_PAYMENT) from Customer_Receipt__c where id = :custReceipt.Id limit 1];
		
		system.assertEquals(custReceipt.Finalized__c, false, custReceipt);
		system.assertEquals(custReceipt.Finalized_Date__c, null, custReceipt);
		system.assertEquals(custReceipt.Customer_Receipt_Lines__r.size(), 1, custReceipt);
		//system.assertEquals(custReceipt.Customer_Receipt_Lines__r[0].Customer_Invoice__c, null, custReceipt);
		
		bt = [select id, Finalized__c, Match_Approved__c, Reconciled_Hidden__c, Reconciled_As_Of_Date__c from Bank_Transaction__c where Id = :bt.Id limit 1];
        system.assertEquals(false, bt.Match_Approved__c, bt);
        system.assertEquals(false, bt.Reconciled_Hidden__c, bt);
        system.assertEquals(null, bt.Reconciled_As_Of_Date__c, bt);
	}
	
	static testMethod void UnfinalizeCustomerReceipt_Prepayments()
	{
		TestFuelQuery fuel = new TestFuelQuery();
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt;
		
		
		Customer_Receipt_Line__c deductionLine = new Customer_Receipt_Line__c();
		deductionLine.Amount__c = 100;
		deductionLine.Customer_Receipt__c = custReceipt.Id;
		deductionLine.Reason_Code__c = fuel.deductionCode.Id;
		deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
		deductionLine.Customer__c = fuel.customerBillTo.Id;
		deductionLine.Sold_To_Customer__c = fuel.customerSoldTo.Id;
		insert deductionLine;
		
		Customer_Receipt_Line__c PrePaymentLine = new Customer_Receipt_Line__c();
		PrePaymentLine.Amount__c =100;
		PrePaymentLine.Customer_Receipt__c = custReceipt.Id;
		PrePaymentLine.Type__c = PaymentService.TYPE_PREPAYMENT;
		PrePaymentLine.Customer__c = fuel.customerBillTo.id;
		PrePaymentLine.Sales_Order__c = fuel.salesOrder.id;
		insert PrePaymentLine;
		
		custReceipt.finalized__c = true;
		update custReceipt;
		
		custReceipt = [Select Id, Finalized__c, Finalized_Date__c from Customer_Receipt__c where id = :custReceipt.Id limit 1];
		test.startTest();
		system.assertEquals(custReceipt.Finalized__c, true, custReceipt);
		system.assertNotEquals(custReceipt.Finalized_Date__c, null, custReceipt);
		
		CustomerInvoiceService.preventMultipleExecutions = false;
		
		String tmpId = custReceipt.id;
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', tmpId );
		SourceDocumentUnfinalize srcDocUnfinalizeExt1 = new SourceDocumentUnfinalize();
		ExceptionService.messages.clear();
		try
		{
			srcDocUnfinalizeExt1.unfinalizeSourceDoc();
		}catch(Exception ex)
		{
			system.debug('CR unfinalize exception: '+ex.getMessage()); //AR-87
		}
		srcDocUnfinalizeExt1.unfinalize();
		
		custReceipt = [Select Id, Finalized__c, Finalized_Date__c, (select id, Type__c, Sales_Order__c from Customer_Receipt_Lines__r where Type__c = :PaymentService.TYPE_PREPAYMENT) from Customer_Receipt__c where id = :custReceipt.Id limit 1];
		
		system.assertEquals(custReceipt.Finalized__c, false, custReceipt);
		system.assertEquals(custReceipt.Finalized_Date__c, null, custReceipt);
		system.assertEquals(custReceipt.Customer_Receipt_Lines__r.size(), 1, custReceipt);
		
		fuel.salesOrder = [Select Id, Prepayments_Received__c from Sales_Order__c where id = :fuel.salesOrder.Id limit 1];
		system.assertEquals(0,fuel.salesOrder.Prepayments_Received__c);
		test.stopTest();
	}
	
	static testMethod void UnfinalizeCustomerReceipt_PrepaymentCRL()
	{
		TestFuelQuery fuel = new TestFuelQuery();
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Amount_Received__c = 100;
		custReceipt.Bank_Account_2__c = fuel.bankAccount.Id;
		custReceipt.Payment_Method_G__c = 'check';
		custReceipt.Reference_Number__c = '123';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt;
		
		
		Customer_Receipt_Line__c PrePaymentLine = new Customer_Receipt_Line__c();
		PrePaymentLine.Amount__c =100;
		PrePaymentLine.Customer_Receipt__c = custReceipt.Id;
		PrePaymentLine.Type__c = PaymentService.TYPE_PREPAYMENT;
		PrePaymentLine.Customer__c = fuel.customerBillTo.id;
		PrePaymentLine.Sales_Order__c = fuel.salesOrder.id;
		insert PrePaymentLine;

		custReceipt.finalized__c = true;
		update custReceipt;
		
		custReceipt = [Select Id, Finalized__c, Finalized_Date__c from Customer_Receipt__c where id = :custReceipt.Id limit 1];
		system.assertEquals(custReceipt.Finalized__c, true, custReceipt);
		system.assertNotEquals(custReceipt.Finalized_Date__c, null, custReceipt);
		Sales_Order__c cancelledSO = [Select Id,Status__c from Sales_Order__c where Id=:fuel.salesOrder.id];
 		cancelledSO.Status__c = 'Cancelled';
 		update cancelledSO;
		
		CustomerInvoiceService.preventMultipleExecutions = false;
		
		String tmpId = custReceipt.id;
		test.startTest();
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', tmpId );
		SourceDocumentUnfinalize srcDocUnfinalizeExt1 = new SourceDocumentUnfinalize();
		ExceptionService.messages.clear();
		try
		{
			srcDocUnfinalizeExt1.unfinalizeSourceDoc();
		}catch(Exception ex)
		{
			system.debug('CR unfinalize exception: '+ex.getMessage()); //AR-87
		}
		srcDocUnfinalizeExt1.unfinalize();
		
		custReceipt = [Select Id, Finalized__c, Finalized_Date__c, (select id, Type__c, Sales_Order__c from Customer_Receipt_Lines__r where Type__c = :PaymentService.TYPE_PREPAYMENT) from Customer_Receipt__c where id = :custReceipt.Id limit 1];
		
		system.assertEquals(custReceipt.Finalized__c, false, custReceipt);
		system.assertEquals(custReceipt.Finalized_Date__c, null, custReceipt);
		system.assertEquals(custReceipt.Customer_Receipt_Lines__r.size(), 1, custReceipt);
		
		fuel.salesOrder = [Select Id, Prepayments_Received__c from Sales_Order__c where id = :fuel.salesOrder.Id limit 1];
		system.assertEquals(0,fuel.salesOrder.Prepayments_Received__c);
		test.stopTest();
	}
	
	static testMethod void UnfinalizeCustomerReceipt_PrepaymentCRL_CancelledSO()
	{
		TestFuelQuery fuel = new TestFuelQuery();
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt;
		
		Customer_Receipt_Line__c deductionLine = new Customer_Receipt_Line__c();
		deductionLine.Amount__c = 100;
		deductionLine.Customer_Receipt__c = custReceipt.Id;
		deductionLine.Reason_Code__c = fuel.deductionCode.Id;
		deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
		deductionLine.Customer__c = fuel.customerBillTo.Id;
		deductionLine.Sold_To_Customer__c = fuel.customerSoldTo.Id;
		insert deductionLine;
		
		Customer_Receipt_Line__c PrePaymentLine = new Customer_Receipt_Line__c();
		PrePaymentLine.Amount__c =100;
		PrePaymentLine.Customer_Receipt__c = custReceipt.Id;
		PrePaymentLine.Type__c = PaymentService.TYPE_PREPAYMENT;
		PrePaymentLine.Customer__c = fuel.customerBillTo.id;
		PrePaymentLine.Sales_Order__c = fuel.salesOrder.id;
		insert PrePaymentLine;
		test.startTest();
		Sales_Order__c cancelledSO = [Select Id,Status__c from Sales_Order__c where Id=:fuel.salesOrder.id];
 		cancelledSO.Status__c = 'Cancelled';
 		update cancelledSO;
		custReceipt.finalized__c = true;
		try{
			update custReceipt;
		}catch(exception e){
			system.assert(e.getMessage().contains(System.Label.SalesOrderValidation));
		}
		
		custReceipt = [Select Id, Finalized__c, Finalized_Date__c from Customer_Receipt__c where id = :custReceipt.Id limit 1];
		system.assertEquals(custReceipt.Finalized__c, false, custReceipt);
		system.assertEquals(custReceipt.Finalized_Date__c, null, custReceipt);
		test.stopTest();
		
	}
	
	static testMethod void CustomerOnReceipt() //AR-32
	{
		TestFuelQuery fuel = new TestFuelQuery();
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerSoldTo.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		try
		{
			insert custReceipt;
		}
		catch(exception ex)
		{
			system.assert(ex.getMessage().contains('The user must enter either a corporate or a bill to customer'));
		}
		list<Customer_Receipt__c> lCRs = new list<Customer_Receipt__c>([Select id from Customer_Receipt__c]);
		system.assert(lCrs.size() == 0);
		
	}
	
	static testMethod void Test_DuplicateEDT() //OTC-750
	{
		TestFuelQuery fuel = new TestFuelQuery();
		
		Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
		//CustomerInvoice.Finalized__c =true;
		insert CustomerInvoice;
		
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt;
				
				
		Customer_Receipt_Line__c edt = new Customer_Receipt_Line__c();
		edt.Amount__c = 100;
		edt.Customer_Receipt__c = custReceipt.Id;
		edt.Customer_Invoice__c = CustomerInvoice.id;
		edt.Type__c = PaymentService.TYPE_EARNED_DISCOUNT;
		
		insert edt;
		CustomerReceiptLineService.isDupeChecked = false;		
		Customer_Receipt_Line__c edt_Dup = new Customer_Receipt_Line__c();
		edt_Dup.Amount__c = 100;
		edt_Dup.Customer_Receipt__c = custReceipt.Id;
		edt_Dup.Customer_Invoice__c = CustomerInvoice.id;
		edt_Dup.Type__c = PaymentService.TYPE_EARNED_DISCOUNT;
		
		insert edt_Dup;
		
		list<Task> tasks = [Select id, Status, whatId, Type, Subject from Task where whatId = :edt_dup.Id];
		system.assertEquals(tasks.size(), 1);
		system.assertEquals(tasks[0].Type, 'Exception');
		system.assertEquals(tasks[0].Subject, ExceptionUtil.CRL_DUPLICATE_EARNED_TERMS.label);
		
		NewEditCloneDeleteExt extension = new NewEditCloneDeleteExt(new Apexpages.Standardcontroller(tasks[0])); //AR-68
		
		try{
			extension.overrideTask();
		}
		catch(Exception ex)
		{
			system.assert(ex.getMessage().contains('This Exception Task cannot be overridden.'));//AR-12
		}
		tasks = [Select id, Status, whatId, Type, Subject from Task where whatId = :edt_dup.Id];
		system.assertEquals(tasks.size(), 1);
		system.assertEquals(tasks[0].Type, 'Exception');
		system.assertEquals(tasks[0].Subject, ExceptionUtil.CRL_DUPLICATE_EARNED_TERMS.label);
		
		CustomerReceiptLineService.isDupeChecked = false;	
		edt_Dup.Type__c = PaymentService.TYPE_PAYMENT;
		update edt_Dup;	
		tasks = [Select id, Status, whatId, Type, Subject from Task where whatId = :edt_dup.Id];
		system.assertEquals(tasks.size(), 1);

		// KNDY-16113 work on this later, tasks statuses are missing open/closed and looks like sfdc enforcing to have those picklist values
        //system.assertNotEquals(tasks[0].Status, 'Open');
		
	}
	 
		
	


	static testMethod void applyCashToClaim() { //KNDY-7738
		TestFuelQuery fuel = new TestFuelQuery();
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt;
				
				
		Customer_Receipt_Line__c deductionLine = new Customer_Receipt_Line__c();
		deductionLine.Amount__c = 100;
		deductionLine.Customer_Receipt__c = custReceipt.Id;
		deductionLine.Reason_Code__c = fuel.deductionCode.Id;
		deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
		insert deductionLine;
		
		Claim__c claim = new Claim__c(Company__c = fuel.company.Id, Amount__c =100, Parent_Customer__c = fuel.customerParent.Id, Status__c ='New');
		insert claim;		
		Customer_Receipt_Line__c claimPayment = new Customer_Receipt_Line__c();
		claimPayment.Amount__c = 100;
		claimPayment.Customer_Receipt__c = custReceipt.Id;
		claimPayment.Type__c = PaymentService.TYPE_CLAIM_PAYMENT;
		claimPayment.Claim__c = claim.Id;
		
		insert claimPayment;
		system.debug('CLAIMID: '+claimPayment.id);
		custReceipt.Finalized__c = true;
		
		try
		{
			update custReceipt;
		}catch(Exception ex)
		{
			system.debug('inside test method ex - '+ex);
		}
		
		custReceipt = [select id, Finalized__c, Date_Received__c, (Select Id, Claim__c, Claim__r.Status__c, Claim__r.Settlement_Method__c, Claim__r.Settlement_Date__c from Customer_Receipt_Lines__r where Type__c = :PaymentService.TYPE_CLAIM_PAYMENT) from Customer_Receipt__c where id = :custReceipt.id limit 1];
		system.assertEquals(true,custReceipt.Finalized__c,'CR should have finalized');
		
		system.assertEquals(1,custReceipt.Customer_Receipt_Lines__r.size(),'CR should have one line with type = claim payment');
		system.assertEquals(ClaimService.SETTLE_CLAIM_AGAINST_CASH,custReceipt.Customer_Receipt_Lines__r[0].Claim__r.Settlement_Method__c,'The Claim should have the new Payment settlement method');
		DateTime dR = custReceipt.Date_Received__c;
		system.assertEquals(Date.newInstance(dR.year(),dR.month(),dr.day()),custReceipt.Customer_Receipt_Lines__r[0].Claim__r.Settlement_Date__c,'cr DR '+custReceipt.Date_Received__c + ' claim '+custReceipt.Customer_Receipt_Lines__r[0].Claim__r.Settlement_Date__c);

	}

	static testMethod void Test_CannotInsertBFL_CRFinalized() //OTC-89
	{
		TestFuelQuery fuel = new TestFuelQuery();
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt;
				
				
		Customer_Receipt_Line__c deductionLine = new Customer_Receipt_Line__c();
		deductionLine.Amount__c = 100;
		deductionLine.Customer_Receipt__c = custReceipt.Id;
		deductionLine.Reason_Code__c = fuel.deductionCode.Id;
		deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
		
		insert deductionLine;
				
		Customer_Receipt_Line__c overpayment = new Customer_Receipt_Line__c();
		overpayment.Amount__c = 100;
		overpayment.Customer_Receipt__c = custReceipt.Id;
		overpayment.Customer__c = fuel.customerBillTo.Id;
		overpayment.Sold_To_Customer__c = fuel.customerSoldTo.Id;
		overpayment.Type__c = PaymentService.TYPE_OVERPAYMENT;
		
		insert overpayment;
		
		custReceipt.Finalized__c = true;
		
		try
		{
			update custReceipt;
		}catch(Exception ex)
		{
			system.debug('inside test method ex - '+ex);
		}

	}
	static testMethod void Test_CannotUpdateBFL_CRFinalized() //OTC-89
	{
		TestFuelQuery fuel = new TestFuelQuery();
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt;
				
				
		Customer_Receipt_Line__c deductionLine = new Customer_Receipt_Line__c();
		deductionLine.Amount__c = 100;
		deductionLine.Customer_Receipt__c = custReceipt.Id;
		deductionLine.Reason_Code__c = fuel.deductionCode.Id;
		deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
		
		insert deductionLine;
				
		Customer_Receipt_Line__c overpayment = new Customer_Receipt_Line__c();
		overpayment.Amount__c = 100;
		overpayment.Customer_Receipt__c = custReceipt.Id;
		overpayment.Customer__c = fuel.customerBillTo.Id;
		overpayment.Sold_To_Customer__c = fuel.customerSoldTo.Id;
		overpayment.Type__c = PaymentService.TYPE_OVERPAYMENT;
		
		insert overpayment;
			
	}
	static testMethod void Test_BlockFinalize_CR_hasExceptions() //OTC-678
	{
		TestFuelQuery fuel = new TestFuelQuery();
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt;
				
				
		Customer_Receipt_Line__c deductionLine = new Customer_Receipt_Line__c();
		deductionLine.Amount__c = 100;
		deductionLine.Customer_Receipt__c = custReceipt.Id;
		deductionLine.Reason_Code__c = fuel.deductionCode.Id;
		deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
		
		insert deductionLine;
				
		Customer_Receipt_Line__c overpayment = new Customer_Receipt_Line__c();
		overpayment.Amount__c = 100;
		overpayment.Customer_Receipt__c = custReceipt.Id;
		overpayment.Customer__c = fuel.customerBillTo.Id;
		overpayment.Sold_To_Customer__c = fuel.customerSoldTo.Id;
		//overpayment.Type__c = PaymentService.TYPE_PAYMENT;
		
		insert overpayment;
		
		custReceipt.Finalized__c = true;
		
		try
		{
			update custReceipt;
		}catch(Exception ex)
		{
			
		}
		custReceipt = [Select Id, Has_Exceptions__c, Finalized__c from Customer_Receipt__c where Id =:custReceipt.Id Limit 1];
		system.assertEquals(custReceipt.Has_Exceptions__c,true,'Customer Receipt should have exceptions');
		system.assertEquals(custReceipt.Finalized__c,false,'Customer Receipt should not be finalized');
		
	}
	
	static testMethod void Test_CRLookup_AdditionalPaymentsInvoice() //OTC-565
	{
		 TestFuelQuery fuel = new TestFuelQuery();
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt;
				
				
		Customer_Receipt_Line__c deductionLine = new Customer_Receipt_Line__c();
		deductionLine.Amount__c = 100;
		deductionLine.Customer_Receipt__c = custReceipt.Id;
		deductionLine.Reason_Code__c = fuel.deductionCode.Id;
		deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
		
		insert deductionLine;
				
		Customer_Receipt_Line__c overpayment = new Customer_Receipt_Line__c();
		overpayment.Amount__c = 100;
		overpayment.Customer_Receipt__c = custReceipt.Id;
		overpayment.Customer__c = fuel.customerBillTo.Id;
		overpayment.Sold_To_Customer__c = fuel.customerSoldTo.Id;
		overpayment.Type__c = PaymentService.TYPE_OVERPAYMENT;
		
		insert overpayment;
		
		custReceipt.Finalized__c = true;
		update custReceipt;
		//KNDY-13995
		overpayment = [Select id, Customer_Receipt__c, Customer_Invoice__c, Customer_Invoice__r.Bill_To_Customer__c, Customer_Invoice__r.Sold_To_Customer__c from Customer_Receipt_Line__c where Id = :overpayment.id Limit 1];
		
		system.assertEquals(custReceipt.ID,overpayment.Customer_Receipt__c,'Customer Receipt should match');
		
	}
	static testMethod void Test_SoldTo_AdditionalPayments() //OTC-582
	{
		 TestFuelQuery fuel = new TestFuelQuery();
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt;
				
				
		Customer_Receipt_Line__c deductionLine = new Customer_Receipt_Line__c();
		deductionLine.Amount__c = 100;
		deductionLine.Customer_Receipt__c = custReceipt.Id;
		deductionLine.Reason_Code__c = fuel.deductionCode.Id;
		deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
		
		insert deductionLine;
				
		Customer_Receipt_Line__c overpayment = new Customer_Receipt_Line__c();
		overpayment.Amount__c = 100;
		overpayment.Customer_Receipt__c = custReceipt.Id;
		overpayment.Customer__c = fuel.customerBillTo.Id;
		overpayment.Sold_To_Customer__c = fuel.customerSoldTo.Id;
		overpayment.Type__c = PaymentService.TYPE_OVERPAYMENT;
		
		insert overpayment;
		
		custReceipt.Finalized__c = true;
		update custReceipt;
		//KNDY-13995
		overpayment = [Select id, Customer_Invoice__c, Customer_Invoice__r.Bill_To_Customer__c, Customer_Invoice__r.Sold_To_Customer__c from Customer_Receipt_Line__c where Id = :overpayment.id Limit 1];
		
		system.assertEquals(fuel.customerBillTo.Id,overpayment.Customer_Invoice__r.Bill_To_Customer__c,'Bill To should match');
		system.assertEquals(fuel.customerSoldTo.Id,overpayment.Customer_Invoice__r.Sold_To_Customer__c,'Sold To should match');
		
	}

	static testMethod void PopulateBTOnPrepayment() {

		TestFuelQuery fuel = new TestFuelQuery();
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');

		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerBillTo.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		custReceipt.Amount_Received__c = 1;
		custReceipt.Bank_Account_2__c = fuel.bankAccount.Id;
		custReceipt.Payment_Method_G__c = 'Check';
		custReceipt.Reference__c = '224242';
		insert custReceipt;

		Customer_Receipt_Line__c additionalPayment = new Customer_Receipt_Line__c();
		additionalPayment.Amount__c = 1;
		additionalPayment.Customer_Receipt__c = custReceipt.Id;
		additionalPayment.Type__c = PaymentService.TYPE_PREPAYMENT;
		insert additionalPayment;

		custReceipt.Finalized__c = true;

		update custReceipt;

		list<Customer_Invoice__c> lCI = [Select Id, Bill_To_Customer__c, Invoice_Type__c from Customer_Invoice__c where Invoice_Type__c = :PaymentService.TYPE_PREPAYMENT and Customer_Receipt__c = :custReceipt.Id];
		system.assertEquals(1, lCI.size(),'I am expecting to see one prepayment Invoice for the CR '+lCI);
		system.assertEquals(fuel.customerBillTo.Id, lCI[0].Bill_To_Customer__c,'I am expecting to Bill_TO_Customer__c populated on prepayment '+lCI);


	}
	
}