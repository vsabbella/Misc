@isTest
public with sharing class CustomerReceiptVoidTest {
	
	public static TestFuel fuel = new TestFuel();
	//public static TestData.Accounting accting = new TestData.Accounting(fuel.company.Id);	
	public static list<Accounting_Rule__c> lARs;
	public static Customer_Receipt__c custReceipt;
	//KNDY-10268 - deprecating bank file and bank file line objects
	//public static Bank_File__c bankFile;
	//public static Bank_File_Line__c bankFileLine;
	public static Customer_Invoice__c creditMemo;
	public static Customer_Receipt_Line__c creditApplied;
	public static Customer_Invoice__c CustomerInvoice;
	public static Customer_Receipt_Line__c paymentLine;
	public static Customer_Receipt_Line__c deductionLine;
	public static Claim__c claim;
	public static Customer_Receipt_Line__c claimPayment;
	public static Customer_Receipt_Line__c OverPaymentLine;
	public static map<string, id> newmap = new map<string, id>();
	@testSetup static void methodName() {
		system.assert(fuel.periodList.size() > 0,'TestFuel Failure.');

		if(lARs == null)
			{
				lARs = new list<Accounting_Rule__c>();
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'General Deduction',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'General Deduction',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Prepayment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Prepayment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Credit Applied',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Credit Applied',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Claim Payment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id,Effective_Start_Date__c = fuel.effStartDate ));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Claim Payment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id,Effective_Start_Date__c = fuel.effStartDate));
				 
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Payment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.cashGL.id, Amount_Reference__c = null, Company_Ledger__c = true,Effective_Start_Date__c = fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Payment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Amount_Reference__c = null, Company_Ledger__c = true,Effective_Start_Date__c = fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Overpayment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.cashGL.id, Amount_Reference__c = null, Company_Ledger__c = true,Effective_Start_Date__c = fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Customer Receipt', Subtransaction_Type__c = 'Overpayment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.overpaymentGL.id, Amount_Reference__c = null, Company_Ledger__c = true,Effective_Start_Date__c = fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'General Deduction',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'General Deduction',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Prepayment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Prepayment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Credit Applied',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Credit Applied',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Effective_Start_Date__c = fuel.effStartDate));
				
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Claim Payment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id,Effective_Start_Date__c = fuel.effStartDate ));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Claim Payment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id,Effective_Start_Date__c = fuel.effStartDate));
				 
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Payment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.cashGL.id, Amount_Reference__c = null, Company_Ledger__c = true,Effective_Start_Date__c = fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Payment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.receivablesGL.id, Amount_Reference__c = null, Company_Ledger__c = true,Effective_Start_Date__c = fuel.effStartDate));
				
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Overpayment',Rule_Type__c = 'DR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.cashGL.id, Amount_Reference__c = null, Company_Ledger__c = true,Effective_Start_Date__c = fuel.effStartDate));
				lARs.add(new Accounting_Rule__c(Object_Name__c = 'Customer_Receipt__c', Accounting_Standard__c = fuel.accountingStandard.Id, Transaction__c = 'Receipt', Subtransaction_Type__c = 'Overpayment',Rule_Type__c = 'CR', Line_Type__c = null,Default_GL_Account__c = true, GL_Account_Reference_Value__c = null,   GL_Account__c = fuel.overpaymentGL.id, Amount_Reference__c = null, Company_Ledger__c = true,Effective_Start_Date__c = fuel.effStartDate));
				
				insert lARs;
		}
		if(custReceipt == null){
			custReceipt = new Customer_Receipt__c();
			custReceipt.Company__c = fuel.company.Id;
			custReceipt.Customer__c = fuel.customerParent.Id;
			custReceipt.Date_Received__c = system.now();
			custReceipt.Type__c = 'Receipt';
			custReceipt.Currency__c = TestFuel.currencyUSD.id;
			custReceipt.Amount_Received__c = 100;
			custReceipt.Bank_Account_2__c =  fuel.bankAccount.Id;
			custReceipt.Payment_Method_G__c = 'Cash';
        	custReceipt.Reference_Number__c = '123';
			insert custReceipt;
		}	
	
			
		if(creditMemo == null){
			creditMemo = new Customer_Invoice__c();
			creditMemo.Bill_To_Customer__c = fuel.customerBillTo.Id;
            creditMemo.Company__c = fuel.company.Id;
            creditMemo.Invoice_Type__c = 'Credit Memo';
            creditMemo.Status__c = CustomerInvoiceService.STATUS_OPEN;
            creditMemo.Date_Invoiced__c = system.now();
            creditMemo.Currency__c = custReceipt.Currency__c;
			
			insert creditMemo;
			
			Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
			cil.Customer_Invoice__c = creditMemo.Id;
			cil.Quantity_Shipped__c = -1;
			cil.Unit_Price__c = 10;
			insert cil;
			
			creditMemo.Finalized__c = true;
			creditMemo.Transaction_Date__c = system.now();
			update creditMemo;
		
		}	
		if(creditApplied == null){
			creditApplied = new Customer_Receipt_Line__c();
			creditApplied.Amount__c = 10;
			creditApplied.Customer_Receipt__c = custReceipt.Id;
			creditApplied.Customer_Invoice__c = creditMemo.Id; //KNDY-13995
			creditApplied.Type__c = PaymentService.TYPE_CREDIT_MEMO;
			
			insert creditApplied;
		}	
		if(CustomerInvoice == null){
			CustomerInvoice = new Customer_Invoice__c();
			CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
            CustomerInvoice.Company__c = fuel.company.Id;
            CustomerInvoice.Customer_Receipt__c = custReceipt.Id;
            CustomerInvoice.Invoice_Type__c = 'Manual';
            CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
            CustomerInvoice.Date_Invoiced__c = system.now();
            CustomerInvoice.Currency__c = custReceipt.Currency__c;
            CustomerInvoice.Transaction_Date__c = Date.today();
			insert CustomerInvoice;
			
			Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
			cil.Customer_Invoice__c = CustomerInvoice.Id;
			cil.Quantity_Shipped__c = 1;
			cil.Unit_Price__c = 100;
			insert cil;
		}	
		if(paymentLine == null){
			paymentLine = new Customer_Receipt_Line__c();
			paymentLine.Amount__c = 100;
			paymentLine.Customer_Receipt__c = custReceipt.Id;
			paymentLine.Customer_Invoice__c = CustomerInvoice.Id;
			paymentLine.Type__c = PaymentService.TYPE_PAYMENT;
			
			insert paymentLine;
		}	
		if(deductionLine == null){
			deductionLine = new Customer_Receipt_Line__c();
			deductionLine.Amount__c = 100;
			deductionLine.Customer_Receipt__c = custReceipt.Id;
			deductionLine.Reason_Code__c = fuel.deductionCode.Id;
			deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
			deductionLine.Customer__c = fuel.customerBillTo.Id;
			deductionLine.Sold_To_Customer__c = fuel.customerSoldTo.Id;
			
			insert deductionLine;
		}	
		if(claim == null){
			claim = new Claim__c();
			claim.Company__c = fuel.company.Id;
			claim.Parent_Customer__c = fuel.customerParent.Id;
			claim.Bill_To_Customer__c = fuel.customerBillTo.Id;
			claim.Currency__c = TestFuel.currencyUSD.id;
			claim.Amount__c = 100;
			claim.Type__c = PaymentService.TYPE_GEN_DED;
			claim.Status__c = 'Open';
			claim.Approval_Status__c = 'Approved';
			insert claim;
		}	
		if(claimPayment == null){
			claimPayment = new Customer_Receipt_Line__c();
			claimPayment.Amount__c = 100;
			claimPayment.Customer_Receipt__c = custReceipt.Id;
			claimPayment.Claim__c = claim.Id;
			claimPayment.Type__c = PaymentService.TYPE_CLAIM_PAYMENT;
			insert claimPayment;
		}	
		if(OverPaymentLine == null){
			OverPaymentLine = new Customer_Receipt_Line__c();
			OverPaymentLine.Amount__c =10;
			OverPaymentLine.Customer_Receipt__c = custReceipt.Id;
			OverPaymentLine.Type__c = PaymentService.TYPE_OVERPAYMENT;
			OverPaymentLine.Customer__c = fuel.customerBillTo.id;
			insert OverPaymentLine;
		}	
		try{
			custReceipt.Finalized__c = true;
			test.starttest();
			update custReceipt;
			AccountingService cra = new CustomerReceiptAccounting();
        	list <Customer_Receipt_Line__c> crlLines = [select id, name, Customer_Receipt__c from Customer_Receipt_Line__c where Customer_Receipt__c =: custReceipt.id ];
        	cra.execute(crlLines);			
			test.stoptest();
		}catch(exception e){
		
		}
	}
	static testMethod void Void_testAmountReeceivedClaim() 
	{

		custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, 
						(Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r) , (Select id, Name, Transaction_Type__c, has_exceptions__c from Accounting_Entries__r)
						 from Customer_Receipt__c ];

		system.assertEquals(custReceipt.Finalized__c, true, custReceipt.Customer_Receipt_Lines__r + ' '+custReceipt.Amount_unapplied__c);
		
		List<Accounting_Entry_Line__c> ael = [Select id, Name, subtransaction_type__c, line_type__c, GL_Account__c, Accounting_Rule__c, has_Exceptions__c from Accounting_Entry_Line__c where Accounting_Entry__c in :custReceipt.Accounting_Entries__r];
		system.assertNotEquals(ael.size(), 0, 'ael:'+ael );
		list <Customer_Invoice_Line__c> cilines = [Select Id, Customer_Invoice__c, Customer_Invoice__r.Invoice_Type__c from Customer_Invoice_line__c where Customer_Invoice__r.Customer_Receipt__c = :custReceipt.Id];
			
		CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));			
		 test.StartTest();
			AccountingService cia = new CustomerInvoiceAccounting();
	        cia.execute(cilines);
		
	        list<Accounting_Entry__c> ae = [select id,name,has_Exceptions__c, status__c from Accounting_Entry__c  where Customer_Invoice__c =: cilines[0].Customer_Invoice__c ];
	        
			system.assert(!ext.getDisableVoid() == true,ext.getVoidCancelDetails() );
			ext.VoidDocs();
 			
			custReceipt = [Select Id, Finalized__c, Status__c, Void__c, (Select Id, Claim__c, Claim__r.Status__c from Customer_Receipt_Lines__r where Type__c = :PaymentService.TYPE_CLAIM_PAYMENT) from Customer_Receipt__c where id = :custReceipt.Id limit 1];
			
			//system.assertEquals(custReceipt.Finalized__c, true);
			//system.assertEquals(custReceipt.Void__c, true,custReceipt.Status__c);
			
			//system.assertEquals(1, custReceipt.Customer_Receipt_Lines__r.size());
			//system.assertNotEquals('Closed',custReceipt.Customer_Receipt_Lines__r[0].Claim__r.Status__c);
			
			//Bank_File_Line__c bfl = [select Id, bank_File__r.Finalized__c from Bank_File_Line__c  limit 1];
			//system.assertEquals(bfl.Bank_File__r.Finalized__c,true);
			
		test.StopTest();
		
		
		
	}
	static testMethod void Void_testCreditApplied_AdditonalPayment() 
	{
		custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c from Customer_Receipt_Lines__r),
						(Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r)
						 from Customer_Receipt__c  limit 1 ];
		
		
//		system.assertEquals(custReceipt.Finalized__c, true, custReceipt.Customer_Receipt_Lines__r + ' '+custReceipt.Amount_unapplied__c);
//		system.assertEquals(custReceipt.Customer_Invoices__r[0].Invoice_Type__c,PaymentService.TYPE_PREPAYMENT);
		
		creditMemo = [Select Id, Balance__c from Customer_Invoice__c where Invoice_Type__c = 'Credit Memo' limit 1];
		system.assertEquals(creditMemo.Balance__c,0);
	//	system.assert(lARs.size() >0);
				
		
		AccountingService cra = new CustomerReceiptAccounting();
        list <Customer_Receipt_Line__c> crlLines = new list <Customer_Receipt_Line__c>();
//        crlLines.add(creditApplied);
//        crlLines.add(OverPaymentLine);
//        cra.execute(crlLines);
		
		test.StartTest();
			AccountingService cia = new CustomerInvoiceAccounting();
	        list <Customer_Invoice_Line__c> cilines = [Select Id, Customer_Invoice__c from Customer_Invoice_line__c where Customer_Invoice__c = :custReceipt.Customer_Invoices__r[0].Id];
	        cia.execute(cilines);
			
			
			/*for(Accounting_Entry_Line__c ael : [Select Id, SubTransaction_type__c, line_Type__c, Accounting_Entry__c, Accounting_Entry__r.Transaction_Type__c, (select id, subject from Tasks) from Accounting_Entry_Line__c where Accounting_Entry__c in (select Id from Accounting_Entry__c where Customer_Invoice__c = :custReceipt.Customer_Invoices__r[0].Id)])
			{
				system.debug('ael: '+ael);
				system.debug('ael with tasks: '+ael.Tasks);
			}*/
			
			
			custReceipt = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Amount_UnApplied__c, (Select Id, Amount__c, Type__c, Customer_Receipt__c from Customer_Receipt_Lines__r),
							(Select id, Status__c,Amount__c from Claims__r), (Select Id, Has_Exceptions__c from Accounting_Entries__r) 
							 from Customer_Receipt__c where id = :custReceipt.Id limit 1 ];
			
			
			CustomerReceiptVoidCancelExt ext = new CustomerReceiptVoidCancelExt(new ApexPages.standardController(custReceipt));
			system.assert(!ext.getDisableVoid() == true,ext.getVoidCancelDetails());
			
			ext.VoidDocs();
			
			custReceipt = [Select Id, Finalized__c, Status__c,(Select Id, Invoice_Type__c, Status__c, Finalized__c from Customer_Invoices__r) from Customer_Receipt__c where id = :custReceipt.Id limit 1];
			
			system.assertEquals(custReceipt.Finalized__c, true);
			
			
//			system.assertEquals(custReceipt.Status__c, 'Void');
//			system.assertEquals(custReceipt.Customer_Invoices__r.size(),1);
//			system.assertEquals(custReceipt.Customer_Invoices__r[0].Invoice_Type__c,PaymentService.TYPE_PREPAYMENT);
//			system.assertEquals(custReceipt.Customer_Invoices__r[0].Status__c,'Void');
			
			creditMemo = [Select Id, Balance__c from Customer_Invoice__c where id = :creditMemo.Id limit 1];
//			system.assertEquals(creditMemo.Balance__c,-10);
			
			
		test.StopTest();
		
		
	}
			
}