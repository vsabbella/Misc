@isTest
private class PaymentAccountingTest {

    public class SampleData{
        
        public testFuel data = new testFuel();
		Payment__c payment;
        public SampleData(){
            updateData();
        }
        
        
 	    public List<Invoice_Line__c> InvLineList1 = new List<Invoice_Line__c>();
 	    public List<Payment_Line__c> paymentLineList1 = new List<Payment_Line__c>();
	    public List<Invoice__c> InvAEList = new List<Invoice__c>();
	    public Invoice__c Inv1, Inv2;
        public Invoice_Line__c InvLine1, InvLine2, InvLine3, InvLine4;
        public Payment_Line__c pml1, pml2;
        private void updateData(){
            
            Inv1 = new Invoice__c();
            Inv1.From_Company__c = data.company.id;
            Inv1.To_Company__c = data.altCompany.id;
            Inv1.Type__c = 'Intercompany Investment';
            Inv1.Currency__c = TestFuel.currencyUSD.id;
            Inv1.Transaction_Date__c = system.now();
            
            
           	Inv2 = new Invoice__c();
            Inv2.From_Company__c = data.company.id;
            Inv2.To_Company__c = data.altCompany.id;
            Inv2.Type__c = 'Intercompany Cross Charge';
            Inv2.Currency__c = TestFuel.currencyUSD.id;
            Inv2.Transaction_Date__c = system.now();
            
            
            InvAEList.add(Inv1);
            InvAEList.add(Inv2);
            
            insert InvAEList;
            
            Invoice_Line__c InvLine1 = new Invoice_Line__c(); 
            InvLine1.Invoice__c = Inv1.id;
            InvLine1.Extended_Amount__c = 5000;
            InvLineList1.add(InvLine1);
            
            Invoice_Line__c InvLine2 = new Invoice_Line__c(); 
            InvLine2.Invoice__c = Inv1.id;
            InvLine2.Extended_Amount__c = 10000;
            InvLineList1.add(InvLine2);
            
            Invoice_Line__c InvLine3 = new Invoice_Line__c(); 
            InvLine3.Invoice__c = Inv2.id;
            InvLine3.Extended_Amount__c = 5000;
            InvLineList1.add(InvLine3);
            
            Invoice_Line__c InvLine4 = new Invoice_Line__c(); 
            InvLine4.Invoice__c = Inv2.id;
            InvLine4.Extended_Amount__c = 10000;
            InvLineList1.add(InvLine4);
            insert InvLineList1;
            
             Bank_account__c baAlt = data.bankAccount.clone();
             baAlt.GL_Account__c = data.UnappliedCashGL.Id;
             baAlt.company__c= data.altCompany.Id;
            upsert baAlt;
            
			Payment = new Payment__c();
			Payment.From_Company__c = data.company.Id;
			Payment.From_Bank_Account__c = data.bankAccount.id;
			Payment.To_Company__c = data.altCompany.Id;
			Payment.To_Bank_Account__c = baAlt.id;
			Payment.Currency__c = TestFuel.currencyUSD.id;
			Payment.Transaction_Date__c = system.now();
			Payment.Type__c = 'Intercompany Payment';
			Payment.Transaction_Type__c = 'Intercompany Payment';
			insert Payment;
			
			pml1 = new Payment_Line__c();
			pml1.Payment__c = Payment.Id;
			pml1.Amount__c = 10000;
			pml1.Type__c = 'Intercompany Payment';
			paymentLineList1.add(pml1);
			
			pml2 = new Payment_Line__c();
			pml2.Payment__c = Payment.Id;
			pml2.Amount__c = 10000;
			pml2.Type__c = 'Intercompany Payment';
			paymentLineList1.add(pml2);
			
			insert paymentLineList1;
            system.assert(data.periodList.size() >0);
            system.assert(data.altCompanyPeriodList.size() >0);
            system.assert(data.paymentRuleList.size() >0);
            
            Payment.finalized__c = true;
            update payment;
        }
        
        
	    
    }   
    
    static testMethod void unfinalizePayment() {//KNDY-10986
    	
    	SampleData sd = new SampleData();
        
 	    Test.startTest();
	    
	    sd.payment = [Select id, Name, Finalized__c
	                                    from payment__c 
	                                    where id = :sd.Payment.id];
	    system.assertEquals(true, sd.payment.Finalized__c);
	    
	    Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = sd.data.company.id, Amount__c = 10000, Transaction_Date__c = system.now() , 
        												   Bank_Account__c = sd.data.bankAccount.Id);
        insert bt;
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Payment__c = sd.Payment.id, Amount__c = 10000);
        insert btm;
    	
    	BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
    	dateTime reconciledDate = system.now();
        BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.Id}, reconciledDate, sd.data.bankAccount.id);
        
        String tmpId = sd.payment.id;
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', tmpId );
		SourceDocumentUnfinalize srcDocUnfinalizeExt1 = new SourceDocumentUnfinalize();
		ExceptionService.messages.clear();
		try
		{
			srcDocUnfinalizeExt1.unfinalizeSourceDoc();
		}catch(Exception ex)
		{
			system.debug('CR unfinalize exception: '+ex.getMessage()); 
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
		
		sd.payment = [Select id, Name, Finalized__c, Finalized_Date__c
	                                    from payment__c 
	                                    where id = :sd.Payment.id];
		system.assertEquals(sd.payment.Finalized__c, false, sd.payment);
		system.assertEquals(sd.payment.Finalized_Date__c, null, sd.payment);
		
		bt = [select id, Finalized__c, Match_Approved__c, Reconciled_Hidden__c, Reconciled_As_Of_Date__c from Bank_Transaction__c where Id = :bt.Id limit 1];
        system.assertEquals(false, bt.Match_Approved__c, bt);
        system.assertEquals(false, bt.Reconciled_Hidden__c, bt);
        system.assertEquals(null, bt.Reconciled_As_Of_Date__c, bt);
    }  
    static testMethod void PaymentAccountingTest() {
        SampleData sd = new SampleData();
        
 	    Test.startTest();
	    
	    sd.payment = [Select id, Name, Finalized__c
	                                    from payment__c 
	                                    where id = :sd.Payment.id];
	    system.assertEquals(true, sd.payment.Finalized__c);
	    	            
	    paymentAccounting ia = new paymentAccounting();
        list<payment_line__c> pylList = new list<payment_line__c>();
        pylList.addall(sd.paymentLineList1);
		system.debug('pylList'+ pylList);
	    ia.execute(pylList);
	    
	    List<Accounting_Entry__c> acctEntry = [Select id, Name, payment__c,status__c,has_exceptions__c,transaction_type__c,
	                                            (Select id, Name, Amount_CR__c, Amount_DR__c, SubTransaction_Type__c, Line_Type__c
	                                            from Accounting_Entry_Lines__r)
	                                            from Accounting_Entry__c 
	                                            where (payment__c =: sd.Payment.id) order by id];
	        
	    system.debug('acctEntry:'+acctEntry);
	    system.debug('acctEntry:'+acctEntry[0].Accounting_Entry_Lines__r);
	    system.assertnotEquals(null,acctEntry);
	    system.assertEquals(2,acctEntry.size());
    }
}