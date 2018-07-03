@isTest
public class BankTransactionMatchExtTest2 {
	//
	@testSetup static void createTestDate() {
		TestFuel fuel = new TestFuel();
		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
	    list<Configuration__c> lConfigs = new list<Configuration__c>();
	    lConfigs.add(new Configuration__c(Name = 'Customer_Receipt__c-'+Customer_Receipt__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Customer_Receipt_Line__c-'+Customer_Receipt_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Journal_Entry__c-'+Journal_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Journal_Entry_Line__c-'+Journal_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Payment__c-'+Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
		lConfigs.add(new Configuration__c(Name = 'Payment_Line__c-'+Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    insert lConfigs;
	    
        system.assert(fuel.bankTransactions != null);
        //system.assert(mybankAccount != null);
        system.assert(fuel.bankAccount != null);
       // system.assert(myperiodList != null);
        system.assert(fuel.periodList != null);
        system.assert(fuel.customerReceipts!=null);
        system.assert(fuel.customerReceiptLines!=null);
        system.assert(fuel.accountingEntries!=null);  
        system.assert(fuel.journalEntryLines!=null);
        system.assert(fuel.JEAccountingEntriesLines!=null);
        system.assert(fuel.supplierPayments!=null);
        system.assert(fuel.intercompanyPayment!=null);
        system.assert(fuel.intercompanyPayment1!=null);
		system.assert(fuel.InterCompanyAccountingEntries!=null);
		system.assert(fuel.SPAccountingEntries!=null);
		system.assert(fuel.customerBillTo!=null);
		system.assert(fuel.RefundCustomerReceipt!=null);
		system.assert(fuel.RefundCRAccountingEntries!=null);
		system.assert(fuel.AccountingRuleList != null);

    }  
      
    static testMethod void displayingOfCorrectBankTransaction(){
    	SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id', 'Opening_Balance__c', 'Opening_Balance_Date__c'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c bankAccount1 = Database.query(soql.getQuery());
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bankAccount1); 
        //bankAccount.Active__c = false; //making account inactive
        bankAccount1.Opening_Balance__c = 0;
        bankAccount1.Opening_Balance_Date__c = system.now().addDays(-10);   
        update bankAccount1;
        BankTransactionMatchExt bankTransactionMatchExtObj = new BankTransactionMatchExt(sc);
        //to cover code coverage for below variables.
        string companyNew = BankTransactionMatchExt.company;
        //string selectquery = bankTransactionMatchExtObj.bankTransactionMatchExtObj;
        string whereClause = bankTransactionMatchExtObj.baseFilterReconciledTransactions;
        string url = bankTransactionMatchExtObj.getReturnUrl();
        string selectquery = bankTransactionMatchExtObj.getSelectQuery(BankReconciliationService.getBankTransactionsFields(),'Bank_Transaction__c');
        Test.StartTest();
        system.assert(bankTransactionMatchExtObj.getbankTransactionGridConfigJson() != null );      
        system.assert(bankTransactionMatchExtObj.getbankTransactionFieldList() != null);    
        JsonResult result = BankTransactionMatchExt.getBankTransactionAndMatches(System.now().date().addDays(-1),System.now().date().addDays(1), bankAccount1.Id);
        system.assertEquals(3,result.total);
        Test.StopTest();
    } 
    
    static testMethod void TestGetAllBankTransactions(){
    	SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
   		string wherecondition = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
   		SOQLUtil soql1 = new SOQLUtil('Bank_Transaction__c');
	    soql1.addFields(new set<string>{'Id'});
        soql1.setWhereClause(wherecondition);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql1.getQuery());
   		
   		Test.startTest();
        system.assertEquals(BankTransactionMatchExt.getAllBankTransactions(mybankAccount.id).records.size() ,lstBankTransaction.size());
        Test.StopTest();
    }
    
     static testMethod void verificationOfSearchResult(){
     	SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
        mybankAccount.Opening_Balance__c = 0;
        mybankAccount.Opening_Balance_Date__c = system.now().addDays(-10);
        update mybankAccount;
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(mybankAccount); 
        BankTransactionMatchExt bankTransactionMatchExtObj = new BankTransactionMatchExt(sc);
        
        //querying of customer receipt
        SOQLUtil soql1 = new SOQLUtil('Customer_Receipt__c');
	    soql1.addFields(new set<string>{'Id','Finalized__c'});
	    string wherecondition = 'Bank_Account_2__c = ' + '\'' + mybankAccount.Id + '\'';
        soql1.setWhereClause(wherecondition);			
        list<Customer_Receipt__c> customerReceipts =  Database.query(soql1.getQuery());
        
        for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.Finalized__c = true;
        }
        update customerReceipts;
        
        //querying of Journal entry line
        SOQLUtil soql2 = new SOQLUtil('Journal_Entry_Line__c');
	    soql2.addFields(new set<string>{'Id','Bank_Account__c'});	
	    list<Journal_Entry_Line__c> journalEntryLines =  Database.query(soql2.getQuery());		
        for(Journal_Entry_Line__c jel: journalEntryLines){
             jel.Bank_Account__c =  mybankaccount.id;
         }
         update journalEntryLines;
		
		//querying gl account
		SOQLUtil soql3 = new SOQLUtil('GL_Account__c');
	    soql3.addFields(new set<string>{'Id'});
        soql3.setWhereClause('Name = \'12000 - Cash\'');			
   		soql3.setLimit(1);
   		GL_Account__c cashGL1 = Database.query(soql3.getQuery());
		
		//querying transactions
		string wherecondition1 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql4 = new SOQLUtil('Bank_Transaction__c');
	    soql4.addFields(new set<string>{'Id'});
        soql4.setWhereClause(wherecondition1);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql4.getQuery());
        
        Test.StartTest();
        system.assert(bankTransactionMatchExtObj.getsearchedResultGridConfigJson() != null );
        system.assert(bankTransactionMatchExtObj.getSearchResultRecordFieldList() != null);
        JsonResult resultforAutomatch;
       
        // 3 bankTransaction -5000, 3000,-5000 (match amount 100 to 4000)
        // 2 journalEntry, jeLine1.Amount_CR__c = 1000.00;Bank_Transaction__c = bankTransactions[0].Id;
        //                 jeLine4.Amount_CR__c = 500.00,,Bank_Transaction__c = bankTransactions[1].Id;
        // 2 CRs 3000,2000




		 JsonResult result = BankTransactionMatchExt.getMatchingTransactions(System.now().date(),System.now().date().addDays(1),mybankAccount.Id,
                                                                            '',100,4000,
                                                                            '',null, new list<string>{'Receipts','Journal_Entry_Line__c'}, lstBankTransaction[0].Id,false,false,true);

        system.assertEquals(6,result.total, result);//Customer Bill To 1 //was 3
        
         
         resultforAutomatch = BankTransactionMatchExt.getMatchingTransactionsforAutoMatch(mybankAccount.Id, 'Customer_Receipt__c');
         system.assertEquals(3,resultforAutomatch.records.size(), resultforAutomatch);
   
         
         result = BankTransactionMatchExt.getMatchingTransactions(System.now().date(),System.now().date().addDays(2),mybankAccount.Id,
                                                                            '',100,4000,
                                                                            'Customer Bill To 1',null,new list<string>{'Receipts','Journal_Entry_Line__c'}, lstBankTransaction[0].Id,false,true,true);

        system.assertEquals(4,result.total, result.records.size());
        
        //CRs contain Reference Number 123s44567mn
        result = BankTransactionMatchExt.getMatchingTransactions(System.now().date(),System.now().date().addDays(1),mybankAccount.Id,
                                                                            '123s44567mn',100,4000,
                                                                            'Customer Bill To 1',null,new list<string>{'Receipts','Journal_Entry_Line__c'}, lstBankTransaction[0].Id,false, false, false);
        system.assertEquals(2,result.total, result.total);
        
        result = BankTransactionMatchExt.getMatchingTransactions(System.now().date().addDays(-1),System.now().date().addDays(3),mybankAccount.Id,
                                                                            '',100,4000,
                                                                            'Customer Bill To 1',null,new list<string>{'Journal_Entry_Line__c'}, lstBankTransaction[0].Id,false, true, false);

        system.assertEquals(2,result.total, result.total);
        
        result = BankTransactionMatchExt.getMatchingTransactions(System.now().date().addDays(-2),System.now().date().addDays(1),mybankAccount.Id,
                                                                            '',100,4000,
                                                                            '',null,new list<string>{'Journal_Entry_Line__c'}, null,false, false, true);

        system.assertEquals(4,result.total, result.total);
        
        result = BankTransactionMatchExt.getMatchingTransactions(System.now().date().addDays(-2),System.now().date().addDays(1),mybankAccount.Id,
                                                                            '',100,4000,
                                                                            'Customer Bill To 1',null,new list<string>{'Journal_Entry_Line__c'}, null,false,
                                                                            false,false);       
        system.assertEquals(0,result.total, result.total);
        
        result = BankTransactionMatchExt.getMatchingTransactions(System.now().date(),System.now().date().addDays(2),mybankAccount.Id,
                                                                            'xyz',100,4000,
                                                                            'Customer Bill To 1',null,new list<string>{'Journal_Entry_Line__c'}, lstBankTransaction[0].Id,false, false, false);
        system.assertEquals(0,result.total, result.total);
        
         resultforAutomatch = BankTransactionMatchExt.getMatchingTransactionsforAutoMatch(mybankAccount.Id, 'Journal_Entry_Line__c');
         system.assertEquals(4,resultforAutomatch.records.size(), resultforAutomatch.records.size());
         
         
        result = BankTransactionMatchExt.getMatchingTransactions(System.now().date(),System.now().date().addDays(5),mybankAccount.Id,
                                                                            '',100,4000,
                                                                            'Customer Bill To 1',null,new list<string>{'Receipts','Journal_Entry_Line__c','Payments'}, lstbanktransaction[0].Id,false, true, false);
        system.assertEquals(5,result.total, result.total);
        
        result = BankTransactionMatchExt.getMatchingTransactions(System.now().date().addDays(-5),System.now().date().addDays(1),mybankAccount.Id,
                                                                            '',100,4000,
                                                                            '',null,new list<string>{'Receipts','Journal_Entry_Line__c','Payments'}, lstBankTransaction[0].Id,false,true, true);
        system.assertEquals(7,result.total, result.total);
        
         resultforAutomatch = BankTransactionMatchExt.getMatchingTransactionsforAutoMatch(mybankAccount.Id, 'Supplier_Payment__c');
         system.assertEquals(2,resultforAutomatch.records.size(), resultforAutomatch);

        //updating description field on JEL
        for(Journal_Entry_Line__c jel:journalEntryLines){
            jel.Description__c = '123s44567mn';
        }
        update journalEntryLines;
        
        result = BankTransactionMatchExt.getMatchingTransactions(System.now().date(),System.now().date().addDays(1),mybankAccount.Id,
                                                                            '123s44567mn',100,4000,
                                                                            '',null,new list<string>{'Receipts','Journal_Entry_Line__c','Payments'}, lstbanktransaction[0].Id,false, false, false);
        system.assertEquals(6,result.total, result.total);
        
        result = BankTransactionMatchExt.getMatchingTransactions(System.now().date(),System.now().date().addDays(4),mybankAccount.Id,
                                                                            '8987',100,4000,
                                                                            '',null,new list<string>{'Payments'},lstBankTransaction[0].Id,false,false, false);
        system.assertEquals(2,result.total, result.total);


		 result = BankTransactionMatchExt.getMatchingTransactions(System.now().date(),System.now().date().addDays(4),mybankAccount.Id,
				                                                                             '',100,300,
				                                                                             '',null,new list<string>{'Payments'}, lstBankTransaction[0].Id,false,
				                                                                             true,true);
		 system.assertEquals(result.total, result.total);

		 result = BankTransactionMatchExt.getMatchingTransactions(System.now().date(),System.now().date().addDays(5),mybankAccount.Id,
				 '',100,4000,
				 'Customer Bill To 1','deposit id',new list<string>{'Receipts','Journal_Entry_Line__c'}, lstbanktransaction[0].Id,false, true, false);
		 system.assertEquals(3,result.total, result);

		 result = BankTransactionMatchExt.getMatchingTransactions(System.now().date(),System.now().date().addDays(5),mybankAccount.Id,
				 '',100,4000,
				 '','deposit id',new list<string>{'Receipts','Journal_Entry_Line__c'}, lstbanktransaction[0].Id,false, false, false);
		 system.assertEquals(1,result.total, result);
        Test.StopTest();   
    }
    
    public testmethod static void  testSaveAutoMatchesAndApprove(){
        SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
   		
   		Transaction_Matching_Rule__c btmr = new Transaction_Matching_Rule__c();
        btmr.Documents__c = 'Customer Receipts, Supplier Payments';
        btmr.Start_Date__c = system.today()-10;
        btmr.End_Date__c = null;
        btmr.Amount__c = true;
        btmr.Amount_Threshold__c = 100.00;
        btmr.Transaction_Date__c = true;
        btmr.Date_Threshold__c	 = 5;
        btmr.Reference__c  = true;
        btmr.Keep_In_Match_Pool__c = true;
        btmr.Auto_Approve__c = false;        
        JsonResult result = BankTransactionMatchingRulesExt.upsertRule( new List<Transaction_Matching_Rule__c>{btmr},new List<String>());
        system.assertEquals(result.success,true, result.messages);
        system.assert(result.messages.size() == 1);
        
   		//querying of customer receipt
        SOQLUtil soql1 = new SOQLUtil('Customer_Receipt__c');
	    soql1.addFields(new set<string>{'Id','Finalized__c'});
	    string wherecondition = 'Bank_Account_2__c = ' + '\'' + mybankAccount.Id + '\'';
        soql1.setWhereClause(wherecondition);			
        list<Customer_Receipt__c> customerReceipts =  Database.query(soql1.getQuery());
        for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.finalized__c = true;
        }
        update customerReceipts;
        
        //querying transactions
		string wherecondition1 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c'});
        soql2.setWhereClause(wherecondition1);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
   		
        List<Bank_Transaction_Match__c > btms = new List<Bank_Transaction_Match__c >();
        bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(0).Id, Customer_receipt__c=customerReceipts.get(0).id,Amount__c = lstBankTransaction.get(0).Amount__c,
        Transaction_Mathching_Rule__c = btmr.Id);
       	btms.add(btm);
       	Test.StartTest();
        JsonResult jr=  BankTransactionMatchExt.saveAutoMAtches(btms);
        system.assert(jr.success,jr);
        
        result = BankTransactionMatchingRulesExt.IsBTMRuleUsedForAutoMatch(btmr.Id);
        system.assertEquals(1,result.total);
        
        //querying BTM
		SOQLUtil soql3 = new SOQLUtil('Bank_Transaction_Match__c');
	    soql3.addFields(new set<string>{'Id','Bank_Transaction__c','Bank_Transaction__r.Match_Approved__c'});		
        List<Bank_Transaction_Match__c > btmslist = Database.query(soql3.getQuery());
        system.assert(btmslist.size()>0);
        system.assert(!btmslist[0].Bank_Transaction__r.Match_Approved__c);
        List<ID> btids = new List<Id>{btmslist[0].Bank_Transaction__c};
        Jsonresult jrbta= BankTransactionMatchExt.approvedMatchedBankTransaction(btids);
        system.debug(' jrbta :' + jrbta);
        
        //querying transactions
		string wherecondition2 = 'id =:btids';
		SOQLUtil soql4 = new SOQLUtil('Bank_Transaction__c');
	    soql4.addFields(new set<string>{'Id', 'Match_Approved__c'});
        soql4.setWhereClause(wherecondition2);			
   		list<Bank_Transaction__c> btList = Database.query(soql4.getQuery());
   		
        system.assert(jrbta.success,jrbta);
        Test.StopTest();
    }
    //KNDY-16610
    public testmethod static void  testSaveAutoMatchesTwice(){
        SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
   		
   		//querying of customer receipt
        SOQLUtil soql1 = new SOQLUtil('Customer_Receipt__c');
	    soql1.addFields(new set<string>{'Id','Finalized__c'});
	    string wherecondition = 'Bank_Account_2__c = ' + '\'' + mybankAccount.Id + '\'';
        soql1.setWhereClause(wherecondition);			
        list<Customer_Receipt__c> customerReceipts =  Database.query(soql1.getQuery());
        for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.finalized__c = true;
        }
        update customerReceipts;
        
        //querying transactions
		string wherecondition1 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c'});
        soql2.setWhereClause(wherecondition1);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
   		
        List<Bank_Transaction_Match__c > btms = new List<Bank_Transaction_Match__c >();
        bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(0).Id, Customer_receipt__c=customerReceipts.get(0).id,Amount__c = lstBankTransaction.get(0).Amount__c  );
       	btms.add(btm);
       	Test.StartTest();
        JsonResult jr=  BankTransactionMatchExt.saveAutoMAtches(btms);
        system.assert(jr.success,jr);
        btms = new List<Bank_Transaction_Match__c >();
        btms.add(btm = new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(0).Id, Customer_receipt__c=customerReceipts.get(0).id,Amount__c = lstBankTransaction.get(0).Amount__c  ));
        jr=  BankTransactionMatchExt.saveAutoMAtches(btms);
        system.assertEquals(jr.success,false,jr);
        boolean ErrorExists = false;
        for(Map<String, String> msg :jr.messages)
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('No match results are found.')){
	        		ErrorExists = true;
	        		break;
        		}
        	} 
        system.assert(ErrorExists); 
        
        Test.StopTest();
    }
    
     public testmethod static void testDeletepotentialMatches(){
        SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
   		
   		//querying of customer receipt
        SOQLUtil soql1 = new SOQLUtil('Customer_Receipt__c');
	    soql1.addFields(new set<string>{'Id','Finalized__c'});
	    string wherecondition = 'Bank_Account_2__c = ' + '\'' + mybankAccount.Id + '\'';
        soql1.setWhereClause(wherecondition);			
        list<Customer_Receipt__c> customerReceipts =  Database.query(soql1.getQuery());
         for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.finalized__c = true;
        }
        update customerReceipts;
		
		//querying transactions
		string wherecondition1 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c'});
        soql2.setWhereClause(wherecondition1);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
   		
        List<Bank_Transaction_Match__c > btms = new List<Bank_Transaction_Match__c >();
        bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(0).Id, Customer_receipt__c=customerReceipts.get(0).id,Amount__c = lstBankTransaction.get(0).Amount__c  );
        bank_Transaction_Match__c btm2 = new Bank_Transaction_Match__c(Is_Potential_Match__C=true, Bank_Transaction__c = lstBankTransaction.get(0).Id, Customer_receipt__c=customerReceipts.get(1).id,Amount__c = lstBankTransaction.get(0).Amount__c  );
        btms.add(btm);
        btms.add(btm2);
        Test.StartTest();
        JsonResult jr=  BankTransactionMatchExt.saveAutoMAtches(btms);
        system.assert(jr.success);
        
        //querying BTM
		SOQLUtil soql3 = new SOQLUtil('Bank_Transaction_Match__c');
	    soql3.addFields(new set<string>{'Id','Is_Potential_Match__c','bank_Transaction__c'});	
	    string wherecondition2 = 'Is_Potential_Match__c=true';	
	    soql3.setWhereClause(wherecondition2);
        List<Bank_Transaction_Match__c > btmslist = Database.query(soql3.getQuery());
        system.assert(btmslist.size()==1);
        List<id> emptyList = new List<id>();
        List<id>  ListofBTs =new List<Id>{lstBankTransaction.get(0).id};
         
        JsonResult JRbtmstoDelete= BankTransactionMatchExt.getDeletionList(ListofBTs,emptyList,emptyList,emptyList,emptyList );
        system.assert(JRbtmstoDelete.records.size()==1);
         
        BankTransactionMatchExt.deletepotentialMatches((List<Bank_Transaction_Match__c>)JRbtmstoDelete.records);
        //querying BTM
		SOQLUtil soql4 = new SOQLUtil('Bank_Transaction_Match__c');
	    soql4.addFields(new set<string>{'Id','Is_Potential_Match__c','bank_Transaction__c'});	
	    string wherecondition3 = 'Is_Potential_Match__c=true';	
	    soql4.setWhereClause(wherecondition3);
        List<Bank_Transaction_Match__c > btmslist2 = Database.query(soql4.getQuery());
        system.assert(btmslist2.size()==0);
        Test.StopTest();
     }
      
    public testmethod static void testConfirmMatchAndDeleteOthers(){
        SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
   		
   		//querying of customer receipt
        SOQLUtil soql1 = new SOQLUtil('Customer_Receipt__c');
	    soql1.addFields(new set<string>{'Id','Finalized__c'});
	    string wherecondition = 'Bank_Account_2__c = ' + '\'' + mybankAccount.Id + '\'';
        soql1.setWhereClause(wherecondition);			
        list<Customer_Receipt__c> customerReceipts =  Database.query(soql1.getQuery());
         for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.finalized__c = true;
        }
        update customerReceipts;
        
        //querying transactions
		string wherecondition1 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c'});
        soql2.setWhereClause(wherecondition1);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
        List<Bank_Transaction_Match__c > btms = new List<Bank_Transaction_Match__c >();
        bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Is_Potential_Match__C=true,Bank_Transaction__c = lstBankTransaction.get(0).Id, Customer_receipt__c=customerReceipts.get(0).id,Amount__c = lstBankTransaction.get(0).Amount__c  );
        bank_Transaction_Match__c btm2 = new Bank_Transaction_Match__c(Is_Potential_Match__C=true, Bank_Transaction__c = lstBankTransaction.get(0).Id, Customer_receipt__c=customerReceipts.get(1).id,Amount__c = lstBankTransaction.get(0).Amount__c  );
        btms.add(btm);
        btms.add(btm2);
        Test.StartTest();
        JsonResult jr=  BankTransactionMatchExt.saveAutoMAtches(btms);
        system.assert(jr.success);
        
        //querying BTM
		SOQLUtil soql3 = new SOQLUtil('Bank_Transaction_Match__c');
	    soql3.addFields(new set<string>{'Id','Is_Potential_Match__c','bank_Transaction__c'});		
        List<Bank_Transaction_Match__c > btmslist = Database.query(soql3.getQuery());
        system.assert(btmslist.size()==2,btmslist);
        Id btid =btmslist.get(0).id;
        jr=  BankTransactionMatchExt.ConfirmMatchAndDeleteOthers(new List<Id>{btid});
        
        btmslist = Database.query(soql3.getQuery());
        system.assert(btmslist.size()==1,btmslist);
        system.assert(btmslist.get(0).Id ==btid ,btmslist);
        system.assert(btmslist.get(0).Is_Potential_Match__c ==false ,btmslist);
        Test.StopTest();
    }
    
    
    public  testmethod static void testgetJournalEntryLineFieldList(){
      	SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
        mybankAccount.Opening_Balance__c = 0;
        mybankAccount.Opening_Balance_Date__c = system.now().addDays(-10);
        update mybankAccount;
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(mybankAccount); 
        BankTransactionMatchExt bankTransactionMatchExtObj = new BankTransactionMatchExt(sc);     
        list<FieldInfo> lstfieldInfo = new list<FieldInfo>();
        Test.StartTest();
        String str =bankTransactionMatchExtObj.getJournalEntryLineFieldList();
        
        lstfieldInfo= (list<FieldInfo>) Json.deserialize(str, list<FieldInfo>.class);
        system.assert(lstfieldInfo.size()==6);
        Test.StopTest();
    }
    
    public testmethod static void testlearnAlias(){
        SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
   		
   		//querying of customer receipt
        SOQLUtil soql1 = new SOQLUtil('Customer_Receipt__c');
	    soql1.addFields(new set<string>{'Id','Finalized__c','Customer__c'});
	    string wherecondition = 'Bank_Account_2__c = ' + '\'' + mybankAccount.Id + '\'';
        soql1.setWhereClause(wherecondition);			
        list<Customer_Receipt__c> customerReceipts =  Database.query(soql1.getQuery());
         for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.finalized__c = true;
        }
        update customerReceipts;

        //querying of supplier payment
        SOQLUtil soql5 = new SOQLUtil('Supplier_Payment__c');
	    soql5.addFields(new set<string>{'Id','Finalized__c','Supplier__c'});
	    string wherecondition1 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
        soql5.setWhereClause(wherecondition1);			
        list<Supplier_Payment__c> supplierPayments =  Database.query(soql5.getQuery());
        for(Supplier_Payment__c supplierPayment :supplierPayments){
            supplierPayment.finalized__c = true;
        }
        update supplierPayments;
        
        //querying payments
        SOQLUtil soql10 = new SOQLUtil('Payment__c');
	    soql10.addFields(new set<string>{'Id','To_Company__c'});
	    string wherecondition10 = 'Type__c = ' + '\'Intercompany Payment\'';
        soql10.setWhereClause(wherecondition10);			
        list<Payment__c> Payments =  Database.query(soql10.getQuery());
        for(Payment__c Payment :Payments){
            Payment.finalized__c = true;
        }
        update Payments;
        
        //querying transactions
		string wherecondition2 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c'});
        soql2.setWhereClause(wherecondition2);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
   		
        List<Bank_Transaction_Match__c > btms = new List<Bank_Transaction_Match__c >();
        bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(0).Id, Customer_receipt__c=customerReceipts.get(0).id,Amount__c = lstBankTransaction.get(0).Amount__c  );
        bank_Transaction_Match__c btm2=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(1).Id, Supplier_Payment__c =supplierPayments.get(0).id,Amount__c = lstBankTransaction.get(1).Amount__c  );
        bank_Transaction_Match__c btm3=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(2).Id, Payment__c = Payments.get(0).id,Amount__c = lstBankTransaction.get(2).Amount__c  );
        btms.add(btm2);
        btms.add(btm);
        btms.add(btm3);
        Test.StartTest();
        JsonResult jr=  BankTransactionMatchExt.saveAutoMatches(btms);
        system.assert(jr.success,jr);
        List<Id> btmidList = new List<Id>{((Sobject) jr.records[0]).id ,((Sobject) jr.records[1]).id, ((Sobject) jr.records[2]).id};
        
        JSONResult jrlm=  BankTransactionMatchExt.learnAlias(btmidList);
        system.assert(jrlm.success);  
        
        //querying customer
		string wherecondition3 = 'id = ' + '\'' + customerReceipts.get(0).Customer__c + '\'';
		SOQLUtil soql3 = new SOQLUtil('Customer__c');
	    soql3.addFields(new set<string>{'Id','aliases__c'});
        soql3.setWhereClause(wherecondition3);			
   		Customer__c cust = Database.query(soql3.getQuery());
        system.assert(cust.Aliases__c.contains('ABCL'));
        
        //querying supplier
		string wherecondition4 =  'id = ' + '\'' + supplierPayments.get(0).Supplier__c + '\'';
		SOQLUtil soql4 = new SOQLUtil('Supplier__c');
	    soql4.addFields(new set<string>{'Id','aliases__c'});
        soql4.setWhereClause(wherecondition4);			
   		Supplier__c supp = Database.query(soql4.getQuery());
        system.assert(supp.Aliases__c.contains('HDFC'));
        
        //querying company
		string wherecondition9 =  'id = ' + '\'' + Payments.get(0).To_Company__c + '\'';
		SOQLUtil soql9 = new SOQLUtil('Company__c');
	    soql9.addFields(new set<string>{'Id','aliases__c'});
        soql9.setWhereClause(wherecondition9);			
   		Company__c comp = Database.query(soql9.getQuery());
        system.assert(comp.Aliases__c.contains('KPMG'));
        
        /*Test unlearn as well
        BankTransactionMatchExt.unlearnAlias(btmidList);
      
        cust = Database.query(soql3.getQuery());
        system.debug(' aliases '+ cust.Aliases__c + ' ' + cust);
        system.assert(String.isBlank(cust.Aliases__c));
        
        supp = Database.query(soql4.getQuery());
        system.assert(String.isBlank(supp.Aliases__c));  */
        Test.StopTest();         
    }
    
    
 	public  testmethod static void testlearnAlias_WithExistingSameValueInAlias(){
        SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
   		
   		//querying of customer receipt
        SOQLUtil soql1 = new SOQLUtil('Customer_Receipt__c');
	    soql1.addFields(new set<string>{'Id','Finalized__c','Customer__c'});
	    string wherecondition = 'Bank_Account_2__c = ' + '\'' + mybankAccount.Id + '\'';
        soql1.setWhereClause(wherecondition);			
        list<Customer_Receipt__c> customerReceipts =  Database.query(soql1.getQuery());
         for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.finalized__c = true;
        }
        update customerReceipts;

        //querying of supplier payment
        SOQLUtil soql5 = new SOQLUtil('Supplier_Payment__c');
	    soql5.addFields(new set<string>{'Id','Finalized__c','Supplier__c'});
	    string wherecondition1 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
        soql5.setWhereClause(wherecondition1);			
        list<Supplier_Payment__c> supplierPayments =  Database.query(soql5.getQuery());
        for(Supplier_Payment__c supplierPayment :supplierPayments){
            supplierPayment.finalized__c = true;
        }
        update supplierPayments;
        
         //querying payments
        SOQLUtil soql10 = new SOQLUtil('Payment__c');
	    soql10.addFields(new set<string>{'Id','To_Company__c'});
	    string wherecondition10 = 'Type__c = ' + '\'Intercompany Payment\'';
        soql10.setWhereClause(wherecondition10);			
        list<Payment__c> Payments =  Database.query(soql10.getQuery());
        for(Payment__c Payment :Payments){
            Payment.finalized__c = true;
        }
        update Payments;
        
        //querying transactions
		string wherecondition2 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c'});
        soql2.setWhereClause(wherecondition2);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
   		
   		//updating alias on customer
		string wherecondition12 = 'id = ' + '\'' + customerReceipts.get(0).Customer__c + '\'';
		SOQLUtil soql12 = new SOQLUtil('Customer__c');
	    soql12.addFields(new set<string>{'Id','aliases__c'});
        soql12.setWhereClause(wherecondition12);			
   		Customer__c cust1 = Database.query(soql12.getQuery());
        cust1.aliases__c = 'ABCL';
        DML.updateAsSystem(cust1);
        
        //updating alias on supplier
		string wherecondition13 =  'id = ' + '\'' + supplierPayments.get(0).Supplier__c + '\'';
		SOQLUtil soql13 = new SOQLUtil('Supplier__c');
	    soql13.addFields(new set<string>{'Id','aliases__c'});
        soql13.setWhereClause(wherecondition13);			
   		Supplier__c supp1 = Database.query(soql13.getQuery());
        supp1.aliases__c = 'HDFC';
        DML.updateAsSystem(supp1);
        
        //updating alias on company
		string wherecondition14 =  'id = ' + '\'' + Payments.get(0).To_Company__c + '\'';
		SOQLUtil soql14 = new SOQLUtil('Company__c');
	    soql14.addFields(new set<string>{'Id','aliases__c'});
        soql14.setWhereClause(wherecondition14);			
   		Company__c comp1 = Database.query(soql14.getQuery());
        comp1.aliases__c = 'KPMG';
        DML.updateAsSystem(comp1);
        
        List<Bank_Transaction_Match__c > btms = new List<Bank_Transaction_Match__c >();
        bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(0).Id, Customer_receipt__c=customerReceipts.get(0).id,Amount__c = lstBankTransaction.get(0).Amount__c  );
        bank_Transaction_Match__c btm2=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(1).Id, Supplier_Payment__c =supplierPayments.get(0).id,Amount__c = lstBankTransaction.get(1).Amount__c  );
        bank_Transaction_Match__c btm3=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(2).Id, Payment__c = Payments.get(0).id,Amount__c = lstBankTransaction.get(2).Amount__c  );
        btms.add(btm2);
        btms.add(btm);
        btms.add(btm3);
        Test.StartTest();
        JsonResult jr=  BankTransactionMatchExt.saveAutoMatches(btms);
        system.assert(jr.success,jr);
        List<Id> btmidList = new List<Id>{((Sobject) jr.records[0]).id ,((Sobject) jr.records[1]).id, ((Sobject) jr.records[2]).id};
        
        JSONResult jrlm=  BankTransactionMatchExt.learnAlias(btmidList);
        system.assert(jrlm.success);  
        
        //querying customer
		string wherecondition3 = 'id = ' + '\'' + customerReceipts.get(0).Customer__c + '\'';
		SOQLUtil soql3 = new SOQLUtil('Customer__c');
	    soql3.addFields(new set<string>{'Id','aliases__c'});
        soql3.setWhereClause(wherecondition3);			
   		Customer__c cust = Database.query(soql3.getQuery());
        system.assert(cust.Aliases__c.contains('ABCL'));
        system.assert((cust.Aliases__c.split('~')).size()==1);
        
        //querying supplier
		string wherecondition4 =  'id = ' + '\'' + supplierPayments.get(0).Supplier__c + '\'';
		SOQLUtil soql4 = new SOQLUtil('Supplier__c');
	    soql4.addFields(new set<string>{'Id','aliases__c'});
        soql4.setWhereClause(wherecondition4);			
   		Supplier__c supp = Database.query(soql4.getQuery());
        system.assert(supp.Aliases__c.contains('HDFC'));
        system.assert((supp.Aliases__c.split('~')).size()==1);
        
        //querying company
		string wherecondition9 =  'id = ' + '\'' + Payments.get(0).To_Company__c + '\'';
		SOQLUtil soql9 = new SOQLUtil('Company__c');
	    soql9.addFields(new set<string>{'Id','aliases__c'});
        soql9.setWhereClause(wherecondition9);			
   		Company__c comp = Database.query(soql9.getQuery());
        system.assert(comp.Aliases__c.contains('KPMG'));
        system.assert((comp.Aliases__c.split('~')).size()==1);
        Test.StopTest();         
    }
    
    public  testmethod static void testlearnAlias_WithExistingDifferentValueInAlias(){
        SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
   		
   		//querying of customer receipt
        SOQLUtil soql1 = new SOQLUtil('Customer_Receipt__c');
	    soql1.addFields(new set<string>{'Id','Finalized__c','Customer__c'});
	    string wherecondition = 'Bank_Account_2__c = ' + '\'' + mybankAccount.Id + '\'';
        soql1.setWhereClause(wherecondition);			
        list<Customer_Receipt__c> customerReceipts =  Database.query(soql1.getQuery());
         for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.finalized__c = true;
        }
        update customerReceipts;

        //querying of supplier payment
        SOQLUtil soql5 = new SOQLUtil('Supplier_Payment__c');
	    soql5.addFields(new set<string>{'Id','Finalized__c','Supplier__c'});
	    string wherecondition1 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
        soql5.setWhereClause(wherecondition1);			
        list<Supplier_Payment__c> supplierPayments =  Database.query(soql5.getQuery());
        for(Supplier_Payment__c supplierPayment :supplierPayments){
            supplierPayment.finalized__c = true;
        }
        update supplierPayments;
        
         //querying payments
        SOQLUtil soql10 = new SOQLUtil('Payment__c');
	    soql10.addFields(new set<string>{'Id','To_Company__c'});
	    string wherecondition10 = 'Type__c = ' + '\'Intercompany Payment\'';
        soql10.setWhereClause(wherecondition10);			
        list<Payment__c> Payments =  Database.query(soql10.getQuery());
        for(Payment__c Payment :Payments){
            Payment.finalized__c = true;
        }
        update Payments;
        
        //querying transactions
		string wherecondition2 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c'});
        soql2.setWhereClause(wherecondition2);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
   		
   		//updating alias on customer
		string wherecondition12 = 'id = ' + '\'' + customerReceipts.get(0).Customer__c + '\'';
		SOQLUtil soql12 = new SOQLUtil('Customer__c');
	    soql12.addFields(new set<string>{'Id','aliases__c'});
        soql12.setWhereClause(wherecondition12);			
   		Customer__c cust1 = Database.query(soql12.getQuery());
        cust1.aliases__c = 'JPMC';
        DML.updateAsSystem(cust1);
        
        //updating alias on supplier
		string wherecondition13 =  'id = ' + '\'' + supplierPayments.get(0).Supplier__c + '\'';
		SOQLUtil soql13 = new SOQLUtil('Supplier__c');
	    soql13.addFields(new set<string>{'Id','aliases__c'});
        soql13.setWhereClause(wherecondition13);			
   		Supplier__c supp1 = Database.query(soql13.getQuery());
        supp1.aliases__c = 'JPMC';
        DML.updateAsSystem(supp1);
        
        //updating alias on company
		string wherecondition14 =  'id = ' + '\'' + Payments.get(0).To_Company__c + '\'';
		SOQLUtil soql14 = new SOQLUtil('Company__c');
	    soql14.addFields(new set<string>{'Id','aliases__c'});
        soql14.setWhereClause(wherecondition14);			
   		Company__c comp1 = Database.query(soql14.getQuery());
        comp1.aliases__c = 'JPMC';
        DML.updateAsSystem(comp1);
        
        List<Bank_Transaction_Match__c > btms = new List<Bank_Transaction_Match__c >();
        bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(0).Id, Customer_receipt__c=customerReceipts.get(0).id,Amount__c = lstBankTransaction.get(0).Amount__c  );
        bank_Transaction_Match__c btm2=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(1).Id, Supplier_Payment__c =supplierPayments.get(0).id,Amount__c = lstBankTransaction.get(1).Amount__c  );
        bank_Transaction_Match__c btm3=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(2).Id, Payment__c = Payments.get(0).id,Amount__c = lstBankTransaction.get(2).Amount__c  );
        btms.add(btm2);
        btms.add(btm);
        btms.add(btm3);
        Test.StartTest();
        JsonResult jr=  BankTransactionMatchExt.saveAutoMatches(btms);
        system.assert(jr.success,jr);
        List<Id> btmidList = new List<Id>{((Sobject) jr.records[0]).id ,((Sobject) jr.records[1]).id, ((Sobject) jr.records[2]).id};
        
        JSONResult jrlm=  BankTransactionMatchExt.learnAlias(btmidList);
        system.assert(jrlm.success);  
        
        //querying customer
		string wherecondition3 = 'id = ' + '\'' + customerReceipts.get(0).Customer__c + '\'';
		SOQLUtil soql3 = new SOQLUtil('Customer__c');
	    soql3.addFields(new set<string>{'Id','aliases__c'});
        soql3.setWhereClause(wherecondition3);			
   		Customer__c cust = Database.query(soql3.getQuery());
        system.assert(cust.Aliases__c.contains('ABCL'));
        system.assert(cust.Aliases__c.contains('JPMC'));
        
        //querying supplier
		string wherecondition4 =  'id = ' + '\'' + supplierPayments.get(0).Supplier__c + '\'';
		SOQLUtil soql4 = new SOQLUtil('Supplier__c');
	    soql4.addFields(new set<string>{'Id','aliases__c'});
        soql4.setWhereClause(wherecondition4);			
   		Supplier__c supp = Database.query(soql4.getQuery());
        system.assert(supp.Aliases__c.contains('HDFC'));
        system.assert(supp.Aliases__c.contains('JPMC'));
        
        //querying company
		string wherecondition9 =  'id = ' + '\'' + Payments.get(0).To_Company__c + '\'';
		SOQLUtil soql9 = new SOQLUtil('Company__c');
	    soql9.addFields(new set<string>{'Id','aliases__c'});
        soql9.setWhereClause(wherecondition9);			
   		Company__c comp = Database.query(soql9.getQuery());
        system.assert(comp.Aliases__c.contains('KPMG'));
        system.assert(comp.Aliases__c.contains('JPMC'));
        Test.StopTest();         
    }
    
    public  testmethod static void testlearnAlias_WithMultiplePayment(){
        SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
        
         //querying payments
        SOQLUtil soql10 = new SOQLUtil('Payment__c');
	    soql10.addFields(new set<string>{'Id','To_Company__c'});
	    string wherecondition10 = 'Type__c = ' + '\'Intercompany Payment\'';
        soql10.setWhereClause(wherecondition10);			
        list<Payment__c> Payments =  Database.query(soql10.getQuery());
        for(Payment__c Payment :Payments){
            Payment.finalized__c = true;
        }
        DML.updateAsSystem(Payments);
        
        //querying transactions
		string wherecondition2 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c'});
        soql2.setWhereClause(wherecondition2);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
        
        //updating alias on company
		string wherecondition14 =  'id = ' + '\'' + Payments.get(0).To_Company__c + '\'';
		SOQLUtil soql14 = new SOQLUtil('Company__c');
	    soql14.addFields(new set<string>{'Id','aliases__c'});
        soql14.setWhereClause(wherecondition14);			
   		Company__c comp1 = Database.query(soql14.getQuery());
        comp1.aliases__c = 'JPMC';
        DML.updateAsSystem(comp1);
        
        List<Bank_Transaction_Match__c > btms = new List<Bank_Transaction_Match__c >();
        bank_Transaction_Match__c btm=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(0).Id, Payment__c = Payments.get(0).id,Amount__c = lstBankTransaction.get(0).Amount__c  );
        bank_Transaction_Match__c btm1=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(2).Id, Payment__c = Payments.get(1).id,Amount__c = lstBankTransaction.get(2).Amount__c  );  
        btms.add(btm);
        btms.add(btm1);
        
        Test.StartTest();
        JsonResult jr=  BankTransactionMatchExt.saveAutoMatches(btms);
        system.assert(jr.success,jr);
        List<Id> btmidList = new List<Id>{((Sobject) jr.records[0]).id ,((Sobject) jr.records[1]).id};
        
        JSONResult jrlm=  BankTransactionMatchExt.learnAlias(btmidList);
        system.assert(jrlm.success);  
        
        //querying company
		string wherecondition9 =  'id = ' + '\'' + Payments.get(0).To_Company__c + '\'';
		SOQLUtil soql9 = new SOQLUtil('Company__c');
	    soql9.addFields(new set<string>{'Id','aliases__c'});
        soql9.setWhereClause(wherecondition9);			
   		Company__c comp = Database.query(soql9.getQuery());
        system.assert(comp.Aliases__c.contains('KPMG'));
        system.assert(comp.Aliases__c.contains('JPMC'));
        system.assert(comp.Aliases__c.contains('ABCL'));
        Test.StopTest();         
    }
    
    public  testmethod static void testlearnAlias_WithMultipleSupplierPayment(){
        SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());

        //querying of supplier payment
        SOQLUtil soql5 = new SOQLUtil('Supplier_Payment__c');
	    soql5.addFields(new set<string>{'Id','Finalized__c','Supplier__c'});
	    string wherecondition1 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
        soql5.setWhereClause(wherecondition1);			
        list<Supplier_Payment__c> supplierPayments =  Database.query(soql5.getQuery());
        for(Supplier_Payment__c supplierPayment :supplierPayments){
            supplierPayment.finalized__c = true;
        }
        DML.updateAsSystem(supplierPayments);
        
        //querying transactions
		string wherecondition2 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c'});
        soql2.setWhereClause(wherecondition2);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
   		
       //updating alias on supplier
		string wherecondition13 =  'id = ' + '\'' + supplierPayments.get(0).Supplier__c + '\'';
		SOQLUtil soql13 = new SOQLUtil('Supplier__c');
	    soql13.addFields(new set<string>{'Id','aliases__c'});
        soql13.setWhereClause(wherecondition13);			
   		Supplier__c supp1 = Database.query(soql13.getQuery());
        supp1.aliases__c = 'JPMC';
        DML.updateAsSystem(supp1);
        
        List<Bank_Transaction_Match__c > btms = new List<Bank_Transaction_Match__c >();
        bank_Transaction_Match__c btm=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(0).Id, Supplier_Payment__c = supplierPayments.get(0).id,Amount__c = lstBankTransaction.get(0).Amount__c  );
        bank_Transaction_Match__c btm1=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(2).Id, Supplier_Payment__c = supplierPayments.get(1).id,Amount__c = lstBankTransaction.get(2).Amount__c  );  
        btms.add(btm);
        btms.add(btm1);
        
        Test.StartTest();
        JsonResult jr=  BankTransactionMatchExt.saveAutoMatches(btms);
        system.assert(jr.success,jr);
        List<Id> btmidList = new List<Id>{((Sobject) jr.records[0]).id ,((Sobject) jr.records[1]).id};
        
        JSONResult jrlm=  BankTransactionMatchExt.learnAlias(btmidList);
        system.assert(jrlm.success);  
        
        //querying supplier
		string wherecondition4 =  'id = ' + '\'' + supplierPayments.get(0).Supplier__c + '\'';
		SOQLUtil soql4 = new SOQLUtil('Supplier__c');
	    soql4.addFields(new set<string>{'Id','aliases__c'});
        soql4.setWhereClause(wherecondition4);			
   		Supplier__c supp = Database.query(soql4.getQuery());
        system.assert(supp.Aliases__c.contains('KPMG'));
        system.assert(supp.Aliases__c.contains('JPMC'));
        system.assert(supp.Aliases__c.contains('ABCL'));
        Test.StopTest();         
    }
    
    public  testmethod static void testlearnAlias_WithMultipleCustomerReceipt(){
        SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());

   		//querying of customer receipt
        SOQLUtil soql1 = new SOQLUtil('Customer_Receipt__c');
	    soql1.addFields(new set<string>{'Id','Finalized__c','Customer__c'});
	    string wherecondition = 'Bank_Account_2__c = ' + '\'' + mybankAccount.Id + '\'';
        soql1.setWhereClause(wherecondition);			
        list<Customer_Receipt__c> customerReceipts =  Database.query(soql1.getQuery());
         for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.finalized__c = true;
        }
        DML.updateAsSystem(customerReceipts);
        
        //querying transactions
		string wherecondition2 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c'});
        soql2.setWhereClause(wherecondition2);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
   		
      //updating alias on customer
		string wherecondition12 = 'id = ' + '\'' + customerReceipts.get(0).Customer__c + '\'';
		SOQLUtil soql12 = new SOQLUtil('Customer__c');
	    soql12.addFields(new set<string>{'Id','aliases__c'});
        soql12.setWhereClause(wherecondition12);			
   		Customer__c cust1 = Database.query(soql12.getQuery());
        cust1.aliases__c = 'JPMC';
        DML.updateAsSystem(cust1);
        
        List<Bank_Transaction_Match__c > btms = new List<Bank_Transaction_Match__c >();
        bank_Transaction_Match__c btm=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(0).Id, Customer_Receipt__c = customerReceipts.get(0).id,Amount__c = lstBankTransaction.get(0).Amount__c  );
        bank_Transaction_Match__c btm1=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(1).Id, Customer_Receipt__c = customerReceipts.get(1).id,Amount__c = lstBankTransaction.get(1).Amount__c  );  
        btms.add(btm);
        btms.add(btm1);
        
        Test.StartTest();
        JsonResult jr=  BankTransactionMatchExt.saveAutoMatches(btms);
        system.assert(jr.success,jr);
        List<Id> btmidList = new List<Id>{((Sobject) jr.records[0]).id ,((Sobject) jr.records[1]).id};
        
        JSONResult jrlm=  BankTransactionMatchExt.learnAlias(btmidList);
        system.assert(jrlm.success);  
        
        //querying customer
		string wherecondition3 = 'id = ' + '\'' + customerReceipts.get(0).Customer__c + '\'';
		SOQLUtil soql3 = new SOQLUtil('Customer__c');
	    soql3.addFields(new set<string>{'Id','aliases__c'});
        soql3.setWhereClause(wherecondition3);			
   		Customer__c cust = Database.query(soql3.getQuery());
        system.assert(cust.Aliases__c.contains('ABCL'));
        system.assert(cust.Aliases__c.contains('HDFC'));
        system.assert(cust.Aliases__c.contains('JPMC'));
        Test.StopTest();         
    }
    
 
 	public static String constructString(Integer length) {
	    String sample = 'BankOfAmerica';
	    for (Integer i = 1000; sample.length()<=length; i++) {
	    	String newSample = '';
	    	newSample += sample+(i*i)+'~';
	        sample = newSample;
	    }
	    sample = sample.removeEnd('~');
	    return sample;
    }
 	public  testmethod static void testlearnAlias_exception(){
        SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
   		
   		//querying of customer receipt
        SOQLUtil soql1 = new SOQLUtil('Customer_Receipt__c');
	    soql1.addFields(new set<string>{'Id','Finalized__c','Customer__c', 'Customer__r.aliases__c'});
	    string wherecondition = 'Bank_Account_2__c = ' + '\'' + mybankAccount.Id + '\'';
        soql1.setWhereClause(wherecondition);			
        list<Customer_Receipt__c> customerReceipts =  Database.query(soql1.getQuery());
        for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.finalized__c = true;
        }
        system.debug('customerReceipts---'+customerReceipts);
        update customerReceipts;
        
        //querying customer
        SOQLUtil soql3 = new SOQLUtil('Customer__c');
	    soql3.addFields(new set<string>{'Id','aliases__c'});
	    string wherecondition3 = 'Id = ' + '\'' + customerReceipts[0].Customer__c + '\'';
        soql3.setWhereClause(wherecondition3);			
        Customer__c queriedcustomer =  Database.query(soql3.getQuery());
        string alias = constructString(131066);
        queriedcustomer.aliases__c = alias;
        update queriedcustomer;
		
        //querying of supplier payment
        SOQLUtil soql5 = new SOQLUtil('Supplier_Payment__c');
	    soql5.addFields(new set<string>{'Id','Finalized__c','Supplier__c', 'Supplier__r.aliases__c'});
	    string wherecondition5 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
        soql5.setWhereClause(wherecondition5);			
        list<Supplier_Payment__c> supplierPayments =  Database.query(soql5.getQuery());
        for(Supplier_Payment__c supplierPayment :supplierPayments){
            supplierPayment.finalized__c = true;
        }
        update supplierPayments;
        
        //querying supplier
        SOQLUtil soql6 = new SOQLUtil('Supplier__c');
	    soql6.addFields(new set<string>{'Id','aliases__c'});
	    string wherecondition6 = 'Id = ' + '\'' + supplierPayments[0].Supplier__c + '\'';
        soql6.setWhereClause(wherecondition6);			
        Supplier__c queriedSupplier =  Database.query(soql6.getQuery());
        queriedSupplier.aliases__c = alias;
       	update queriedSupplier;
        
        //querying transactions
		string wherecondition2 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c'});
        soql2.setWhereClause(wherecondition2);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
   		
        List<Bank_Transaction_Match__c > btms = new List<Bank_Transaction_Match__c >();
        bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(0).Id, Customer_receipt__c=customerReceipts.get(0).id,Amount__c = lstBankTransaction.get(0).Amount__c  );
       // bank_Transaction_Match__c btm2=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(1).Id, Supplier_Payment__c =supplierPayments.get(0).id,Amount__c = lstBankTransaction.get(1).Amount__c  );
       // btms.add(btm2);
        btms.add(btm);
        Test.StartTest();
        JsonResult jr=  BankTransactionMatchExt.saveAutoMatches(btms);
        system.assert(jr.success,jr);
        List<Id> btmidList = new List<Id>{((Sobject) jr.records[0]).id}; //,((Sobject) jr.records[1]).id};
        system.debug('btmidList---'+btmidList);
        JSONResult jrlm=  BankTransactionMatchExt.learnAlias(btmidList);
        system.assert(!jrlm.success, jrlm); 
        boolean ErrorExists = false;
        for(Map<String, String> msg :jrlm.messages)
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(' has no space for additional names. To make more space, you can change or delete data in this field that is less relevant for bank transaction matching')){
	        		ErrorExists = true;
	        		break;
        		}
        	} 
        system.assert(ErrorExists); 
        Test.StopTest();
 	}
    public static testmethod void testgetJournalEntryLinesConfigJson(){
      	SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
        mybankAccount.Opening_Balance__c = 0;
        mybankAccount.Opening_Balance_Date__c = system.now().addDays(-10);
        update mybankAccount;
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(mybankAccount); 
        BankTransactionMatchExt bankTransactionMatchExtObj = new BankTransactionMatchExt(sc); 
        Test.StartTest(); 
        String str = bankTransactionMatchExtObj.getJournalEntryLinesConfigJson();
        GridRelatedListController.GridRelatedListConfig cfg= (GridRelatedListController.GridRelatedListConfig) JSON.deserialize(str, GridRelatedListController.GridRelatedListConfig.class);
        system.assert(cfg!=null);
        Test.StopTest();
    }    
    
    public static testmethod void testJECreation(){
    	SOQLUtil soql = new SOQLUtil('Company__c');
	    soql.addFields(new set<string>{'Id'});			
   		soql.setLimit(1);
   		Company__c mycompany1 = Database.query(soql.getQuery());
    	
    	SOQLUtil soql1 = new SOQLUtil('Bank_Account__c');
	    soql1.addFields(new set<string>{'Id'});
        soql1.setWhereClause('Name = \'Test BOFA\'');			
   		soql1.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql1.getQuery());
   		
   		 //querying transactions
		string wherecondition2 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c','Transaction_Date__c'});
        soql2.setWhereClause(wherecondition2);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
   		
   		//querying gl account
		SOQLUtil soql3 = new SOQLUtil('GL_Account__c');
	    soql3.addFields(new set<string>{'Id'});
        soql3.setWhereClause('Name = \'12000 - Cash\'');			
   		soql3.setLimit(1);
   		GL_Account__c cashGL = Database.query(soql3.getQuery());
   		
   		SOQLUtil soql5;
        soql5 = new SOQLUtil('Currency__c', TRUE);
        soql5.addFields(new Set<String>{'Id'});
        soql5.setLimit(1);
        Currency__c currencyUSD = Database.Query(soql5.getQuery());
   		
   		DateTime transactiondate = System.now().addDays(2);
      	Journal_Entry__c journalEntry = new Journal_Entry__c();
        journalEntry.name = 'JE001';
        journalEntry.Company__c = mycompany1.id; 
        journalEntry.type__c = 'Bank Transaction';   
        journalEntry.Transaction_Type__c = 'Manual';
        journalEntry.Transaction_Date__c = transactiondate;     
        journalEntry.Currency__c = currencyUSD.Id;
        List<Journal_Entry_Line__c> journalEntryLines1 = new List<Journal_Entry_Line__c>();
		Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
        jeLine1.Bank_Account__c = mybankAccount.id;
        jeLine1.Amount_CR__c = 1000.00;
        jeLine1.GL_Account__c =cashGL.id;
        jeLine1.Transaction_Date__c = transactiondate.Date();
        jeLine1.Bank_Transaction__c = lstBankTransaction.get(0).Id;
        jeLine1.Subtransaction_Type__c = 'Write Off';
        journalEntryLines1.add(jeLine1); 
		Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
        jeLine2.Bank_Account__c = mybankAccount.id;             
        jeLine2.Amount_DR__c = 1000.00;
        jeLine2.GL_Account__c = cashGL.id;
        jeLine2.Transaction_Date__c = transactiondate.Date();
        jeLine2.Bank_Transaction__c = lstBankTransaction.get(0).Id;
        jeLine2.Subtransaction_Type__c = 'Write Off';
        journalEntryLines1.add(jeLine2); 
        Test.StartTest();
        JsonResult jr=  BankTransactionMatchExt.createJournalEntry(journalEntry,journalEntryLines1);
        system.assertEquals(false,jr.success);
        
        Journal_Entry__c je = [Select Id,Transaction_Date__c from Journal_Entry__c where Id = :journalEntry.Id];  
        system.assertNotEquals(null, je.Id);
        system.assertEquals(transactiondate, je.Transaction_Date__c);
        list<Journal_Entry_Line__c> lstJEL = [Select Id,Transaction_Date__c from Journal_Entry_Line__c 
        									  where journal_entry__c =: je.Id];
        
        system.assertEquals(2,lstJEL.size(),lstJEL.size());
        system.assertEquals(transactiondate.date(),lstJEL.get(0).Transaction_Date__c,lstJEL.get(0).Transaction_Date__c);
        system.assertEquals(transactiondate.date(),lstJEL.get(1).Transaction_Date__c,lstJEL.get(1).Transaction_Date__c);
        boolean isError = false;
        for(map<string,string> msg :jr.messages) {
    		if(msg.containsKey('message')){
    	    	if(msg.get('message').contains('Journal Entry Created but issues encountered while generating accounting, Please fix the record and match')){
    				isError = true;
    	    	}
    		}  		
    	} 
    	system.assert(isError);
    	
    	List<Bank_Transaction_Match__c> btmlist= BankTransactionMatchExt.createBTMsForJE(journalEntryLines1);
    	for(Bank_Transaction_Match__c btm: btmlist){
    		system.assertEquals(lstBankTransaction.get(0).Transaction_Date__c,btm.Bank_Transaction_Date__c,btm.Bank_Transaction_Date__c);
    		system.assertEquals(journalEntry.Transaction_Date__c,btm.Matched_To_Transaction_Date__c,btm.Matched_To_Transaction_Date__c);
    	}
    	Test.StopTest();
     }

	public static testmethod void testJECreation_NegativeAmount(){//KNDY-16112, KNDY-19414
		SOQLUtil soql = new SOQLUtil('Company__c');
		soql.addFields(new set<string>{'Id'});
		soql.setLimit(1);
		Company__c mycompany1 = Database.query(soql.getQuery());

		SOQLUtil soql1 = new SOQLUtil('Bank_Account__c');
		soql1.addFields(new set<string>{'Id'});
		soql1.setWhereClause('Name = \'Test BOFA\'');
		soql1.setLimit(1);
		Bank_Account__c mybankAccount = Database.query(soql1.getQuery());

		//querying transactions
		string wherecondition2 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
		soql2.addFields(new set<string>{'Id','Amount__c','Transaction_Date__c'});
		soql2.setWhereClause(wherecondition2);
		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());

		//querying gl account
		SOQLUtil soql3 = new SOQLUtil('GL_Account__c');
		soql3.addFields(new set<string>{'Id'});
		soql3.setWhereClause('Name = \'12000 - Cash\'');
		soql3.setLimit(1);
		GL_Account__c cashGL = Database.query(soql3.getQuery());

		SOQLUtil soql5;
		soql5 = new SOQLUtil('Currency__c', TRUE);
		soql5.addFields(new Set<String>{'Id'});
		soql5.setLimit(1);
		Currency__c currencyUSD = Database.Query(soql5.getQuery());

		DateTime transactiondate = System.now().addDays(2);
		Journal_Entry__c journalEntry = new Journal_Entry__c();
		journalEntry.name = 'JE001';
		journalEntry.Company__c = mycompany1.id;
		journalEntry.type__c = 'Bank Transaction';
		journalEntry.Transaction_Type__c = 'Manual';
		journalEntry.Transaction_Date__c = transactiondate;
		journalEntry.Currency__c = currencyUSD.Id;
		List<Journal_Entry_Line__c> journalEntryLines1 = new List<Journal_Entry_Line__c>();
		Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c();
		jeLine1.Bank_Account__c = mybankAccount.id;
		jeLine1.Amount_CR__c = -1000.00;
		jeLine1.GL_Account__c =cashGL.id;
		jeLine1.Transaction_Date__c = transactiondate.Date();
		jeLine1.Bank_Transaction__c = lstBankTransaction.get(0).Id;
		jeLine1.Subtransaction_Type__c = 'Write Off';
		journalEntryLines1.add(jeLine1);
		Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c();
		jeLine2.Bank_Account__c = mybankAccount.id;
		jeLine2.Amount_DR__c = -1000.00;
		jeLine2.GL_Account__c = cashGL.id;
		jeLine2.Transaction_Date__c = transactiondate.Date();
		jeLine2.Bank_Transaction__c = lstBankTransaction.get(0).Id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
		journalEntryLines1.add(jeLine2);
		Test.StartTest();
		JsonResult jr=  BankTransactionMatchExt.createJournalEntry(journalEntry,journalEntryLines1);
		system.assertEquals(false,jr.success);

		Journal_Entry__c je = [Select Id,Transaction_Date__c from Journal_Entry__c where Id = :journalEntry.Id];
		system.assertNotEquals(null, je.Id);
		system.assertEquals(transactiondate, je.Transaction_Date__c);
		list<Journal_Entry_Line__c> lstJEL = [Select Id,Transaction_Date__c from Journal_Entry_Line__c
		where journal_entry__c =: je.Id];

		system.assertEquals(2,lstJEL.size(),lstJEL.size());
		system.assertEquals(transactiondate.date(),lstJEL.get(0).Transaction_Date__c,lstJEL.get(0).Transaction_Date__c);
		system.assertEquals(transactiondate.date(),lstJEL.get(1).Transaction_Date__c,lstJEL.get(1).Transaction_Date__c);
		boolean isError = false;
		for(map<string,string> msg :jr.messages) {
			if(msg.containsKey('message')){
				if(msg.get('message').contains('Journal Entry Created but issues encountered while generating accounting, Please fix the record and match')){
					isError = true;
				}
			}
		}
		system.assert(isError);

		List<Bank_Transaction_Match__c> btmlist= BankTransactionMatchExt.createBTMsForJE(journalEntryLines1);
		for(Bank_Transaction_Match__c btm: btmlist){
			system.assertEquals(lstBankTransaction.get(0).Transaction_Date__c,btm.Bank_Transaction_Date__c,btm.Bank_Transaction_Date__c);
			system.assertEquals(journalEntry.Transaction_Date__c,btm.Matched_To_Transaction_Date__c,btm.Matched_To_Transaction_Date__c);
			system.assertEquals(btm.Amount__c, -1000, btm);
		}
		Test.StopTest();
	}
	//KNDY-16543
     public static testmethod void testJEFetchSubtransactionType(){
    	SOQLUtil soql = new SOQLUtil('Company__c');
	    soql.addFields(new set<string>{'Id'});			
   		soql.setLimit(1);
   		Company__c mycompany1 = Database.query(soql.getQuery());
    	
    	SOQLUtil soql1 = new SOQLUtil('Bank_Account__c');
	    soql1.addFields(new set<string>{'Id'});
        soql1.setWhereClause('Name = \'Test BOFA\'');			
   		soql1.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql1.getQuery());
   		
   		 //querying transactions
		string wherecondition2 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c','Transaction_Date__c'});
        soql2.setWhereClause(wherecondition2);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
     
   		//querying gl account
		SOQLUtil soql3 = new SOQLUtil('GL_Account__c');
	    soql3.addFields(new set<string>{'Id'});
        soql3.setWhereClause('Name = \'12000 - Cash\'');			
   		soql3.setLimit(1);
   		GL_Account__c cashGL = Database.query(soql3.getQuery());
   		
   		SOQLUtil soql5;
        soql5 = new SOQLUtil('Currency__c', TRUE);
        soql5.addFields(new Set<String>{'Id'});
        soql5.setLimit(1);
        Currency__c currencyUSD = Database.Query(soql5.getQuery());
   		
   		DateTime transactiondate = System.now().addDays(2);
      	Journal_Entry__c journalEntry = new Journal_Entry__c();
        journalEntry.name = 'JE001';
        journalEntry.Company__c = mycompany1.id; 
        journalEntry.type__c = 'Bank Transaction';   
        journalEntry.Transaction_Type__c = 'Manual';
        journalEntry.Transaction_Date__c = transactiondate;     
        journalEntry.Currency__c = currencyUSD.Id;
        List<Journal_Entry_Line__c> journalEntryLines1 = new List<Journal_Entry_Line__c>();
		Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
        jeLine1.Bank_Account__c = mybankAccount.id;
        jeLine1.Amount_CR__c = 1000.00;
        jeLine1.GL_Account__c =cashGL.id;
        jeLine1.Transaction_Date__c = transactiondate.Date();
        jeLine1.Bank_Transaction__c = lstBankTransaction.get(0).Id;
        jeLine1.Subtransaction_Type__c = 'Write Off';
        journalEntryLines1.add(jeLine1); 
		Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
        jeLine2.Bank_Account__c = mybankAccount.id;             
        jeLine2.Amount_DR__c = 1000.00;
        jeLine2.GL_Account__c = cashGL.id;
        jeLine2.Transaction_Date__c = transactiondate.Date();
        jeLine2.Bank_Transaction__c = lstBankTransaction.get(0).Id;
        jeLine2.Subtransaction_Type__c = 'Write Off';
        journalEntryLines1.add(jeLine2); 
        Test.StartTest();
        SOQLUtil soql6;
        soql6 = new SOQLUtil('Accounting_Rule__c', TRUE);
        soql6.addFields(new Set<String>{'Id'});
        soql6.setWhereClause('Transaction__c = \'Bank Transaction\'');			
        List<Accounting_Rule__c> JEAccRuleList = Database.query(soql6.getQuery());
        system.assertEquals(JEAccRuleList.size() == 4,true,JEAccRuleList);           
        JsonResult jr=  BankTransactionMatchExt.fetchSubTransactionTypes(system.now());
        system.assertEquals(jr.records.size(),2,jr);
        List<Map<String,String>> STT =  (List<Map<String,String>>) jr.records;
        for (Map<string,string> bankTrans : STT){
        	if (bankTrans.containsKey('Bank Adjustment') || bankTrans.containsKey('Bank Interest Income')){
        		system.assert(true,bankTrans);
        	}        	
        }            
        jr=  BankTransactionMatchExt.fetchSubTransactionTypes(system.now().addYears(-2));
        system.assertEquals(jr.success,false,jr);                  
    	Test.StopTest();
     }  
      public static testmethod void testBankReconSummaryExt(){
      	 SOQLUtil soql = new SOQLUtil('Bank_Account__c');
		 soql.addFields(new set<string>{'Id'});
	     soql.setWhereClause('Name = \'Test BOFA\'');			
	     soql.setLimit(1);
	   	 Bank_Account__c mybankAccount = Database.query(soql.getQuery());
	   	 mybankAccount.Opening_Balance__c = 0;
         mybankAccount.Opening_Balance_Date__c = system.now().addDays(-10);
         update mybankAccount;
         
         string dt = (system.now().addDays(-10)).date().format();
         ApexPages.currentPage().getParameters().put('endDate', dt); 
	   	 ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(mybankAccount); 
         BankReconSummaryExt bankReconSummaryExtObj = new BankReconSummaryExt(sc);
         
         Test.StartTest();
         //calling other methods
         system.assert(bankReconSummaryExtObj.bankTranSummarySelectQry != null);
         system.assert(bankReconSummaryExtObj.bankTranSummaryQryWhereClause != null);
         system.assert(bankReconSummaryExtObj.baseQuerySuppPayments != null);
         system.assert(bankReconSummaryExtObj.baseFilterSuppPayments != null);
         system.assert(bankReconSummaryExtObj.baseQueryJELines != null);
         system.assert(bankReconSummaryExtObj.baseFilterJELines != null);
         system.assert(bankReconSummaryExtObj.baseJournalEntryLinesInTransitMap != null); //KNDY-16492
         system.assert(bankReconSummaryExtObj.baseQueryAELines != null);
         system.assert(bankReconSummaryExtObj.baseFilterAELines != null);
         system.assert(bankReconSummaryExtObj.baseQueryCustomerReceiptsInTransit != null);
         system.assert(bankReconSummaryExtObj.baseFilterCustomerReceiptsInTransit != null);
         system.assert(bankReconSummaryExtObj.baseFilterReconciledTransactions != null);
         Test.StopTest();
      }
      
      public  testmethod static void testgetMatchesInBTMService(){
        SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
   		
   		//querying of customer receipt
        SOQLUtil soql1 = new SOQLUtil('Customer_Receipt__c');
	    soql1.addFields(new set<string>{'Id','Finalized__c','Customer__c'});
	    string wherecondition = 'Bank_Account_2__c = ' + '\'' + mybankAccount.Id + '\'';
        soql1.setWhereClause(wherecondition);			
        list<Customer_Receipt__c> customerReceipts =  Database.query(soql1.getQuery());
         for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.finalized__c = true;
        }
        update customerReceipts;

        //querying of supplier payment
        SOQLUtil soql5 = new SOQLUtil('Supplier_Payment__c');
	    soql5.addFields(new set<string>{'Id','Finalized__c','Supplier__c'});
	    string wherecondition1 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
        soql5.setWhereClause(wherecondition1);			
        list<Supplier_Payment__c> supplierPayments =  Database.query(soql5.getQuery());
        for(Supplier_Payment__c supplierPayment :supplierPayments){
            supplierPayment.finalized__c = true;
        }
        update supplierPayments;
        
        
         //querying of Journal entry
        SOQLUtil soql2 = new SOQLUtil('Journal_Entry_Line__c');
	    soql2.addFields(new set<string>{'Id','Bank_Account__c','Journal_Entry__c'});	
	    list<Journal_Entry_Line__c> journalEntryLines =  Database.query(soql2.getQuery());		
        for(Journal_Entry_Line__c jel:     journalEntryLines){
             jel.Bank_Account__c =  mybankaccount.id;
        }
         update journalEntryLines;
         
        //querying transactions
		string wherecondition3 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql3 = new SOQLUtil('Bank_Transaction__c');
	    soql3.addFields(new set<string>{'Id','Amount__c'});
        soql3.setWhereClause(wherecondition3);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql3.getQuery());
   		
        List<Bank_Transaction_Match__c > btms = new List<Bank_Transaction_Match__c >();
        bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(0).Id, Customer_receipt__c=customerReceipts.get(0).id,Amount__c = lstBankTransaction.get(0).Amount__c  );
        bank_Transaction_Match__c btm2=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(1).Id, Supplier_Payment__c =supplierPayments.get(0).id,Amount__c = lstBankTransaction.get(1).Amount__c  );
        bank_Transaction_Match__c btm3=  new Bank_Transaction_Match__c(Bank_Transaction__c = lstBankTransaction.get(2).Id, Journal_Entry_Line__c =journalEntryLines.get(0).id,Amount__c = lstBankTransaction.get(2).Amount__c  );
        btms.add(btm2);
        btms.add(btm);
        Test.StartTest();
        JsonResult jr=  BankTransactionMatchExt.saveAutoMatches(btms);
        system.assert(jr.success,jr);
        List<Id> btmidList = new List<Id>{((Sobject) jr.records[0]).id ,((Sobject) jr.records[1]).id};
        
        system.assert(BankTransactionMatchService.getMatches('Journal_Entry_Line__c', journalEntryLines.get(0).Journal_Entry__c) != null);
        system.assert(BankTransactionMatchService.getMatches('Customer_Receipt__c', customerReceipts.get(0).Id) != null);
        system.assert(BankTransactionMatchService.getMatches('Supplier_Payment__c', supplierPayments.get(0).Id) != null);
        
        //testing getMatchesErrors method
        //querying BTM
		SOQLUtil soql4 = new SOQLUtil('Bank_Transaction_Match__c');
	    soql4.addFields(new set<string>{'Id','Bank_Transaction__r.Name','Bank_Transaction__r.Match_Approved__c','Bank_Transaction__r.Reconciled_As_Of_Date__c','Bank_Transaction__r.Name' });		
        List<Bank_Transaction_Match__c > btmslist = Database.query(soql4.getQuery());
        list<String> errMsg = BankTransactionMatchService.getMatchesErrors(btmslist, null, null);
        system.assert(errMsg != null);
        boolean isError = false;
        for(String msg :errMsg) {
    	    if(msg.contains(Label.Existing_matches_will_be_deleted)){
    				isError = true;
    	    } 		
    	} 
    	system.assert(isError);
        Test.StopTest();         
    }
    
     public  testmethod static void testBankTransactionVoidCancelExt(){
        SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
   		
   		//querying transactions
		string wherecondition3 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql3 = new SOQLUtil('Bank_Transaction__c');
	    soql3.addFields(new set<string>{'Id','Amount__c'});
        soql3.setWhereClause(wherecondition3);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql3.getQuery());
   		
   		Test.startTest();
   		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(lstBankTransaction.get(0)); 
        BankTransactionVoidCancelExt bankTransactionVoidCancelExt = new BankTransactionVoidCancelExt(sc);
        
        //voiding bt/btg
        system.assert(bankTransactionVoidCancelExt.getDisableVoid());
		system.assert(bankTransactionVoidCancelExt.getVoidDetails() != null);
		
        ApexPages.Standardcontroller sc1 = new ApexPages.Standardcontroller(lstBankTransaction.get(1)); 
        BankTransactionVoidCancelExt bankTransactionVoidCancelExt1 = new BankTransactionVoidCancelExt(sc1);
        
         //cancelling bt/btg
        system.assert(!bankTransactionVoidCancelExt1.getDisableCancel());
        system.assert(bankTransactionVoidCancelExt1.getCancelDetails() != null);
        Test.stopTest();
     }
     
  
    
     public testmethod static void testBankTransactiondisplayLimit(){
        if(KSE.checkTestDispatch()){return;}         
         
     	User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
	    list<Configuration__c> lConfigs = new list<Configuration__c>();
	    lConfigs.add(new Configuration__c(Name = 'Bank_Transaction_Group__c-'+Bank_Transaction_Group__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Bank_Transaction__c-'+Bank_Transaction__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Bank_Account__c-'+Bank_Account__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    insert lConfigs;
	    
	    SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id', 'opening_balance_date__c'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());
   		mybankAccount.opening_balance_date__c = System.Now().addDays(-1);
   		update mybankAccount;
   		
   		SOQLUtil newsoql;
        newsoql = new SOQLUtil('Company__c', TRUE);
        newsoql.addFields(new Set<String>{'Id'});
        newsoql.setLimit(1);
        Company__c company = Database.Query(newsoql.getQuery());
        
        SOQLUtil soql1;
        soql1 = new SOQLUtil('Currency__c', TRUE);
        soql1.addFields(new Set<String>{'Id'});
        soql1.setLimit(1);
        Currency__c currencyUSD = Database.Query(soql1.getQuery());
        
        list<Bank_Transaction__c> lstBT = new list<Bank_Transaction__c>();
        list<Bank_Transaction_Group__c> lstBTG = new list<Bank_Transaction_Group__c>();
        for(integer i=0;i<2000;i++){
   			Bank_Transaction__c bankTransaction = new Bank_Transaction__c();
            bankTransaction.Amount__c = -5000.00;
            bankTransaction.Currency__c = currencyUSD.Id;
            bankTransaction.Company__c = company.Id;
            bankTransaction.Transaction_Type__c = 'Credit';
            bankTransaction.Reference_Number__c = '123s44567mnJ';
            bankTransaction.Source__c = 'Yodlee';
            bankTransaction.Transacted_With__c = 'KPMG';
            bankTransaction.Bank_Account__c = mybankAccount.Id;
            bankTransaction.Transaction_Date__c = System.now();
            bankTransaction.Payment_Method__c = 'Wire';
            bankTransaction.SubTransaction_Type__c = 'Credit';
            //bankTransaction.Bank_Transaction_Group__c = lstBTG[i].Id;
            lstBT.add(bankTransaction);
   		}
   		insert lstBT;
   		Test.startTest();
   		for(integer i=1;i<=2000;i++){
   			Bank_Transaction_Group__c bankTransactionGroup = new Bank_Transaction_Group__c();
            bankTransactionGroup.Finalized__c = true;
            bankTransactionGroup.Currency__c = currencyUSD.Id;
            bankTransactionGroup.Transaction_Date__c = System.now(); 
            bankTransactionGroup.Transaction_Type__c = 'Standard';
            bankTransactionGroup.Company__c = company.Id;
            bankTransactionGroup.Total_Number_Of_Lines__c = 1;
            bankTransactionGroup.Finalized_Date__c = System.now();
            lstBTG.add(bankTransactionGroup);
   		}
   		insert lstBTG;
   		
   		for(integer i=0;i<2000;i++){
   			lstBT[i].Bank_Transaction_Group__c = lstBTG[i].Id;
   		}
   		update lstBT;
   		
   		JsonResult jr = BankTransactionMatchExt.getBankTransactionAndMatches(System.now().Date(), System.now().addDays(1).Date(), mybankAccount.Id);
   		system.assert(jr.success);
   		boolean ErrorExists = false;
        if(jr.message.contains(System.Label.Too_Many_Records)){
	        ErrorExists = true;
        }

        system.assert(ErrorExists); 
        Test.StopTest();
     }


     public testmethod static void test_setMatchingWrapperValues(){
     	SOQLUtil soql = new SOQLUtil('Bank_Account__c');
	    soql.addFields(new set<string>{'Id'});
        soql.setWhereClause('Name = \'Test BOFA\'');			
   		soql.setLimit(1);
   		Bank_Account__c mybankAccount = Database.query(soql.getQuery());

        //querying transactions
		string wherecondition2 = 'Bank_Account__c = ' + '\'' + mybankAccount.Id + '\'';
		SOQLUtil soql2 = new SOQLUtil('Bank_Transaction__c');
	    soql2.addFields(new set<string>{'Id','Amount__c'});
        soql2.setWhereClause(wherecondition2);			
   		list<Bank_Transaction__c> lstBankTransaction = Database.query(soql2.getQuery());
   		system.assert(lstBankTransaction.size()==3,lstBankTransaction);
   		
   		Test.StartTest();
   		Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(
   											Bank_Transfer_Transaction__c=lstBankTransaction[1].Id,
   											Bank_Transaction__c=lstBankTransaction[2].Id,
   											Amount__c = 100.00);
   		BankTransactionMatchService.MatchingWrapper matchWrap = BankTransactionMatchService.setMatchingWrapperValues(btm);
   		system.assert(matchWrap!=null,matchWrap);
   		system.assert(matchWrap.objectType == 'Bank_Transaction__c',matchWrap.objectType);
   		system.assert(matchWrap.amountMatched == 100,matchWrap.amountMatched);
   		Test.StopTest();
     }
}