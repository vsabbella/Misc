@isTest
public with sharing class BankTransactionMatchExtTest {
 
    	@testSetup static void ts() {
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Customer_Receipt__c-'+Customer_Receipt__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Customer_Receipt_Line__c-'+Customer_Receipt_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Journal_Entry__c-'+Journal_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Journal_Entry_Line__c-'+Journal_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
    		TestFuel data = new TestFuel();
        // these asserts cause TestFuelQuery to insert data
        system.assert(      
            data.periodList != null &&
            data.accountingStandard != null &&
            data.bankAccount != null &&
            data.company != null &&
            data.customerParent != null &&
            data.AccountingRuleList != null &&
            data.accountingEntries != null &&
            data.bankTransactions != null && 
            data.customerReceipts != null &&
            data.customerReceiptLines != null &&
            data.journalEntryLines != null &&//inserts journal entry
            data.JEAccountingEntriesLines != null// inserts accounting Entry
        );
    }
    
    static testMethod void displayingOfCorrectBankTransaction(){
    	TestFuelQuery fuel = new TestFuelQuery();  
    	list<Bank_Transaction__c> lstBankTransaction = fuel.bankTransactionList;
    	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(fuel.bankAccount); 
    	Bank_Account__c bankAccount = fuel.bankAccount;
		//bankAccount.Active__c = false; //making account inactive
		bankAccount.Opening_Balance__c = 0;
		bankAccount.Opening_Balance_Date__c = system.now().addDays(-10);   
		update bankAccount;
    	BankTransactionMatchExt bankTransactionMatchExtObj = new BankTransactionMatchExt(sc);
    	//to cover code coverage for below variables.
    	string company = BankTransactionMatchExt.company;
    	//string selectquery = bankTransactionMatchExtObj.bankTransactionMatchExtObj;
    	string whereClause = bankTransactionMatchExtObj.baseFilterReconciledTransactions;
    	string url = bankTransactionMatchExtObj.getReturnUrl();
    	string selectquery = bankTransactionMatchExtObj.getSelectQuery(BankReconciliationService.getBankTransactionsFields(),'Bank_Transaction__c');
    	Test.StartTest();
    	system.assert(bankTransactionMatchExtObj.getbankTransactionGridConfigJson() != null );   	
    	system.assert(bankTransactionMatchExtObj.getbankTransactionFieldList() != null);   	
    	JsonResult result = BankTransactionMatchExt.getBankTransactionAndMatches(System.now().date().addDays(-1),System.now().date().addDays(1),fuel.bankAccount.Id);
    	system.assertEquals(3,result.total);
    	Test.StopTest();
    }
    
    static testMethod void testBTMChunkSize(){
    		TestFuelQuery fuel = new TestFuelQuery();
    		list<Bank_Transaction__c> lstBankTransaction = fuel.bankTransactionList;
    		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(fuel.bankAccount); 
    		Bank_Account__c bankAccount = fuel.bankAccount;
		//bankAccount.Active__c = false; //making account inactive
		bankAccount.Opening_Balance__c = 0;
		bankAccount.Opening_Balance_Date__c = system.now().addDays(-10);   
		update bankAccount;
    		BankTransactionMatchExt bankTransactionMatchExtObj = new BankTransactionMatchExt(sc);
    		system.assertEquals(bankTransactionMatchExtObj.BTMChunkSize, null, '>>>' + bankTransactionMatchExtObj.BTMChunkSize);
    		// set btm Chunk Size
    		list<Configuration__c> lConfigs = new list<Configuration__c>();
    		lConfigs.add(new Configuration__c(Name = 'BTMChunkSize', Value__c = '200'));
		insert lConfigs;
    		bankTransactionMatchExtObj = new BankTransactionMatchExt(sc);
    		system.assertEquals(bankTransactionMatchExtObj.BTMChunkSize, 200, '>>> ' +bankTransactionMatchExtObj.BTMChunkSize);
    }
    
    static testMethod void queryCanceledBT() {
        TestFuelQuery fuel = new TestFuelQuery();
        Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = system.now() , 
                                                           Bank_Account__c = fuel.bankAccount.Id, Currency__c = fuel.company.Default_Transaction_Currency__c);
        insert bt;
        
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Bank_Transaction_Group__c-'+Bank_Transaction_Group__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        bt = [Select Id,Bank_Transaction_Group__c from Bank_Transaction__c where ID = :bt.ID limit 1];
        update new Bank_Transaction_Group__c(Id = bt.Bank_Transaction_Group__c, Finalized__c = false);
        
        Bank_Transaction_Group__c btg = [Select Id, Finalized__c from Bank_Transaction_Group__c where Id = :bt.Bank_Transaction_Group__c limit 1];
        system.assertEquals(btg.Finalized__c, false, btg);
        
        bt = [Select Id, Finalized__c from Bank_Transaction__c where Id = :bt.Id];
        system.assertEquals(bt.Finalized__c, false, bt);

        JsonResult result = BankTransactionMatchExt.getBankTransactionAndMatches(System.now().date().addDays(-1),System.now().date().addDays(1),fuel.bankAccount.Id);
        
        	Integer btmCt = 0;
        for(BankTransactionMatchService.transactionWithMatchesWrapper btmwrapper : (List<BankTransactionMatchService.transactionWithMatchesWrapper>)result.records){
	        Bank_Transaction__c bankTrans = btmwrapper.bankTransaction;
	        if (bankTrans.Id == bt.Id){
	        	   btmCt ++;
	        }
        }
        system.assertEquals(0,btmCt, '>>> bt.Id:' + bt.Id + '>>> result: ' + result);
    }
    
    static testMethod void queryVoidBT() {
        TestFuelQuery fuel = new TestFuelQuery();
        Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = system.now() , 
                                                           Bank_Account__c = fuel.bankAccount.Id, Currency__c = fuel.company.Default_Transaction_Currency__c);
        insert bt;
        
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Bank_Transaction_Group__c-'+Bank_Transaction_Group__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        bt = [Select Bank_Transaction_Group__c from Bank_Transaction__c where ID = :bt.ID limit 1];
        update new Bank_Transaction_Group__c(Id = bt.Bank_Transaction_Group__c, Void__c = true);
        
        JsonResult result = BankTransactionMatchExt.getBankTransactionAndMatches(System.now().date().addDays(-1),System.now().date().addDays(1),fuel.bankAccount.Id);
        	Integer btmCt = 0;
        for(BankTransactionMatchService.transactionWithMatchesWrapper btmwrapper : (List<BankTransactionMatchService.transactionWithMatchesWrapper>)result.records){
	        Bank_Transaction__c bankTrans = btmwrapper.bankTransaction;
	        if (bankTrans.Id == bt.Id){
	        	   btmCt ++;
	        }
        }
        system.assertEquals(0,btmCt, '>>> bt.Id:' + bt.Id + '>>> result: ' + result);
        
        
        
    }
    
    static testMethod void validateInactiveAccount(){
        TestFuelQuery fuel = new TestFuelQuery();
        Bank_Account__c bankAccount = fuel.bankAccount;
        bankAccount.Active__c = false; //making account inactive
        bankAccount.Opening_Balance__c = 0;
        bankAccount.Opening_Balance_Date__c = system.now().addDays(-10);
        update bankAccount;
        
        Test.StartTest();
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bankAccount);
        for(ApexPages.Message msg :  ApexPages.getMessages()) {
            System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
            System.assertEquals(System.label.Inactive_Bank_Account, msg.getSummary());          
        }   
        Test.StopTest();
    }
    
    static testMethod void displayingOfCorrectBankTransactionAndMatches(){
        TestFuelQuery fuel = new TestFuelQuery();
        list<Bank_Transaction__c> lstBankTransaction = fuel.bankTransactionList;
        Bank_Account__c bankAccount = fuel.bankAccount;
        //bankAccount.Active__c = false; //making account inactive
        bankAccount.Opening_Balance__c = 0;
        bankAccount.Opening_Balance_Date__c = system.now().addDays(-100);
        update bankAccount;
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(fuel.bankAccount); 
        BankTransactionMatchExt bankTransactionMatchExtObj = new BankTransactionMatchExt(sc);
        list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1 = 
        new list<BankTransactionMatchService.MatchingWrapper>();
        
        list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2 = 
        new list<BankTransactionMatchService.MatchingWrapper>();

        //Creation of customer receipt
        list<Customer_Receipt__c> customerReceipts = fuel.customerReceiptList;
        list<Accounting_Entry__c> lstAccountingEntry = fuel.accountingEntryList;
        list<Customer_Receipt_Line__c> customerReceiptLines = fuel.customerReceiptLineList;
        for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.finalized__c = true;
        }
        update customerReceipts;
        
        //creation of Journal entry
        list<Journal_Entry_Line__c> journalEntryLines = fuel.journalEntryLineList; 
        list<Accounting_Entry_Line__c> JEAccountingEntriesLines = fuel.JEAccountingEntryLineList;
        
        //creation of wrapper records for customer receipt
        BankTransactionMatchService.MatchingWrapper wrapperRecord = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord.recordId = customerReceipts[0].Id;
        wrapperRecord.recordName = customerReceipts[0].Name;
        wrapperRecord.transactionDate = System.Now().addDays(-1); 
        wrapperRecord.amountMatched = 3000.00;
        wrapperRecord.referenceNumber = '123s44567mnJ';
        wrapperRecord.objectType = 'Customer_Receipt__c';       
        wrapperRecord.transactedWithName = 'Customer Bill To 1';
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1.add(wrapperRecord);
        
        BankTransactionMatchService.MatchingWrapper wrapperRecord1 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord1.recordId = customerReceipts[1].Id;
        wrapperRecord1.recordName = customerReceipts[1].Name;
        wrapperRecord1.transactionDate = wrapperRecord.transactionDate; 
        wrapperRecord1.amountMatched = 2000.00;
        wrapperRecord1.referenceNumber = '123s44567mnJ';
        wrapperRecord1.objectType = 'Customer_Receipt__c';      
        wrapperRecord1.transactedWithName = 'Customer Bill To 1';
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1.add(wrapperRecord1);
        
        //creation of wrapper records for Journal Entry Line
        BankTransactionMatchService.MatchingWrapper wrapperRecord2 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord2.recordId = journalEntryLines[0].Id;
        wrapperRecord2.recordName = journalEntryLines[0].Name;
        wrapperRecord2.transactionDate = System.Now();
        wrapperRecord2.amountMatched = 1000.00;
        wrapperRecord2.objectType = 'Journal_Entry_Line__c';        
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord2);
        
        BankTransactionMatchService.MatchingWrapper wrapperRecord3 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord3.recordId = journalEntryLines[1].Id;
        wrapperRecord3.recordName = journalEntryLines[1].Name;
        wrapperRecord3.transactionDate = System.Now();
        wrapperRecord3.amountMatched = 1000.00;
        wrapperRecord3.objectType = 'Journal_Entry_Line__c';        
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord3);
        
        BankTransactionMatchService.MatchingWrapper wrapperRecord4 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord4.recordId = journalEntryLines[2].Id;
        wrapperRecord4.recordName = journalEntryLines[2].Name;
        wrapperRecord4.transactionDate = System.Now();
        wrapperRecord4.amountMatched = 500.00;
        wrapperRecord4.objectType = 'Journal_Entry_Line__c';        
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord4);
        
        BankTransactionMatchService.MatchingWrapper wrapperRecord5 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord5.recordId = journalEntryLines[3].Id;
        wrapperRecord5.recordName = journalEntryLines[3].Name;
        wrapperRecord5.transactionDate = System.Now();
        wrapperRecord5.amountMatched = 500.00;
        wrapperRecord5.objectType = 'Journal_Entry_Line__c';        
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord5);
        Test.StartTest();   
        
        JsonResult result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1,fuel.bankTransactionList[0]);
        system.assertEquals(2,result.total);
        for(Bank_Transaction_Match__c btm:(list<Bank_Transaction_Match__c>)result.records){
        	system.assert(btm.Matched_To_Transaction_Date__c == wrapperRecord.transactionDate,btm.Matched_To_Transaction_Date__c);
        	system.assert(btm.Bank_Transaction_Date__c == lstBankTransaction[0].Transaction_Date__c,btm.Bank_Transaction_Date__c);
        }
        
        result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2,fuel.bankTransactionList[1]);
        system.assertEquals(4,result.total);
        
        system.assert(bankTransactionMatchExtObj.getbankTransactionGridConfigJson() != null );      
        system.assert(bankTransactionMatchExtObj.getbankTransactionFieldList() != null);    
        
        result = BankTransactionMatchExt.getBankTransactionAndMatches(System.now().date(),System.now().date().addDays(1),fuel.bankAccount.Id);
        system.assertEquals(3,result.total);
        Test.StopTest();
    }
    
     static testMethod void verificationOfBankTransactionWithoutMatches(){
        TestFuelQuery fuel = new TestFuelQuery();
        list<Bank_Transaction__c> lstBankTransaction = fuel.bankTransactionList;
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(fuel.bankAccount); 
        BankTransactionMatchExt bankTransactionMatchExtObj = new BankTransactionMatchExt(sc);
        Test.StartTest();
        JsonResult result = BankTransactionMatchExt.getBankTransactionAndMatches(System.now().date(),System.now().date().addDays(2),fuel.bankAccount.Id);
        system.assertEquals(3,result.total);
        Test.stopTest();                                                                                                 
    }


    
    static testMethod void verifySavingBankTransactionMatching(){
    	TestFuelQuery fuel = new TestFuelQuery();
    	list<Bank_Transaction__c> lstBankTransaction = fuel.bankTransactionList;
    	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(fuel.bankAccount); 
    	BankTransactionMatchExt bankTransactionMatchExtObj = new BankTransactionMatchExt(sc);
    	list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1 = 
    	new list<BankTransactionMatchService.MatchingWrapper>();
    	
    	list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2 = 
    	new list<BankTransactionMatchService.MatchingWrapper>();
    	
    	list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords3 = 
    	new list<BankTransactionMatchService.MatchingWrapper>();

	//Creation of customer receipt
    	list<Customer_Receipt__c> customerReceipts = fuel.customerReceiptList;
    	list<Accounting_Entry__c> lstAccountingEntry = fuel.accountingEntryList;
    	list<Customer_Receipt_Line__c> customerReceiptLines = fuel.customerReceiptLineList;
    	for(Customer_Receipt__c customerReceipt :customerReceipts){
    		customerReceipt.finalized__c = true;
    	}
    	update customerReceipts;
    	
    	//creation of Journal entry
    	list<Journal_Entry_Line__c> journalEntryLines = fuel.journalEntryLineList;
    	list<Accounting_Entry_Line__c> JEAccountingEntriesLines = fuel.JEAccountingEntryLineList;
    	
    	//creation of wrapper records for customer receipt
    	BankTransactionMatchService.MatchingWrapper wrapperRecord = new BankTransactionMatchService.MatchingWrapper();
    	wrapperRecord.recordId = customerReceipts[0].Id;
    	wrapperRecord.recordName = customerReceipts[0].Name;
    	wrapperRecord.transactionDate = System.Now();
    	wrapperRecord.amountMatched = 3000.00;
    	wrapperRecord.referenceNumber = '123s44567mnJ';
    	wrapperRecord.objectType = 'Customer_Receipt__c';    	
    	wrapperRecord.transactedWithName = 'Customer Bill To 1';
        wrapperRecord.IsPotentialMatch=false;
    	lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1.add(wrapperRecord);
    	
    	BankTransactionMatchService.MatchingWrapper wrapperRecord1 = new BankTransactionMatchService.MatchingWrapper();
    	wrapperRecord1.recordId = customerReceipts[1].Id;
    	wrapperRecord1.recordName = customerReceipts[1].Name;
    	wrapperRecord1.transactionDate = System.Now();
    	wrapperRecord1.amountMatched = 2000.00;
    	wrapperRecord1.referenceNumber = '123s44567mnJ';
    	wrapperRecord1.objectType = 'Customer_Receipt__c';    	
    	wrapperRecord1.transactedWithName = 'Customer Bill To 1';
        wrapperRecord1.IsPotentialMatch=false;
    	lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1.add(wrapperRecord1);
    	
    	//creation of wrapper records for Journal Entry Line
    	BankTransactionMatchService.MatchingWrapper wrapperRecord2 = new BankTransactionMatchService.MatchingWrapper();
    	wrapperRecord2.recordId = journalEntryLines[0].Id;
    	wrapperRecord2.recordName = journalEntryLines[0].Name;
    	wrapperRecord2.transactionDate = System.Now();
    	wrapperRecord2.amountMatched = 1000.00;
    	wrapperRecord2.objectType = 'Journal_Entry_Line__c';    	
        wrapperRecord2.IsPotentialMatch=false;
    	lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord2);
    	
    	BankTransactionMatchService.MatchingWrapper wrapperRecord3 = new BankTransactionMatchService.MatchingWrapper();
    	wrapperRecord3.recordId = journalEntryLines[1].Id;
    	wrapperRecord3.recordName = journalEntryLines[1].Name;
    	wrapperRecord3.transactionDate = System.Now();
    	wrapperRecord3.amountMatched = 1000.00;
    	wrapperRecord3.objectType = 'Journal_Entry_Line__c';    	
        wrapperRecord3.IsPotentialMatch=false;
    	lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord3);
    	
    	BankTransactionMatchService.MatchingWrapper wrapperRecord4 = new BankTransactionMatchService.MatchingWrapper();
    	wrapperRecord4.recordId = journalEntryLines[2].Id;
    	wrapperRecord4.recordName = journalEntryLines[2].Name;
    	wrapperRecord4.transactionDate = System.Now();
    	wrapperRecord4.amountMatched = 500.00;
    	wrapperRecord4.objectType = 'Journal_Entry_Line__c';    	
        wrapperRecord4.IsPotentialMatch=false;
    	lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord4);
    	
    	BankTransactionMatchService.MatchingWrapper wrapperRecord5 = new BankTransactionMatchService.MatchingWrapper();
    	wrapperRecord5.recordId = journalEntryLines[3].Id;
    	wrapperRecord5.recordName = journalEntryLines[3].Name;
    	wrapperRecord5.transactionDate = System.Now();
    	wrapperRecord5.amountMatched = 500.00;
    	wrapperRecord5.objectType = 'Journal_Entry_Line__c';    	
        wrapperRecord5.IsPotentialMatch=false;
    	lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord5);
    	
    	lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords3.addAll(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2);
    	lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords3.addAll(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1);
    	
    	Test.StartTest();  	
    	JsonResult result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1,fuel.bankTransactionList[0]);
    	system.assertEquals(2,result.total);
    	
    	result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1,null);
    	system.assertEquals(false,result.success);
    	
    	result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2,fuel.bankTransactionList[1]);
    	system.assertEquals(4,result.total);
    	
    	result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords3,fuel.bankTransactionList[1]);
    	system.assertEquals(false,result.success); // dedup logic added so that no same matches can be added to the same bt
    	Test.StopTest();
    }
    
     static testMethod void verficationOfMatchedResultAndApproval(){
        TestFuelQuery fuel = new TestFuelQuery();
        list<Bank_Transaction__c> lstBankTransaction = fuel.bankTransactionList;
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(fuel.bankAccount); 
        BankTransactionMatchExt bankTransactionMatchExtObj = new BankTransactionMatchExt(sc);
        list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1 = 
        new list<BankTransactionMatchService.MatchingWrapper>();
        
        list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2 = 
        new list<BankTransactionMatchService.MatchingWrapper>();

        //Creation of customer receipt
        list<Customer_Receipt__c> customerReceipts = fuel.customerReceiptList;
        list<Accounting_Entry__c> lstAccountingEntry = fuel.accountingEntryList;
        list<Customer_Receipt_Line__c> customerReceiptLines = fuel.customerReceiptLineList;
        for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.finalized__c = true;
        }
        update customerReceipts;
        
        //creation of Journal entry
        list<Journal_Entry_Line__c> journalEntryLines = fuel.journalEntryLineList;
        list<Accounting_Entry_Line__c> JEAccountingEntriesLines = fuel.JEAccountingEntryLineList;
        Bank_Account__c bankAccount = fuel.bankAccount;
        //bankAccount.Active__c = false; //making account inactive
        bankAccount.Opening_Balance__c = 0;
        bankAccount.Opening_Balance_Date__c = system.now().addDays(-10);
        update bankAccount;
        //creation of wrapper records for customer receipt
        BankTransactionMatchService.MatchingWrapper wrapperRecord = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord.recordId = customerReceipts[0].Id;
        wrapperRecord.recordName = customerReceipts[0].Name;
        wrapperRecord.transactionDate = System.Now();
        wrapperRecord.amountMatched = 3000.00;
        wrapperRecord.referenceNumber = '123s44567mnJ';
        wrapperRecord.objectType = 'Customer_Receipt__c';       
        wrapperRecord.transactedWithName = 'Customer Bill To 1';
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1.add(wrapperRecord);
        
        BankTransactionMatchService.MatchingWrapper wrapperRecord1 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord1.recordId = customerReceipts[1].Id;
        wrapperRecord1.recordName = customerReceipts[1].Name;
        wrapperRecord1.transactionDate = System.Now();
        wrapperRecord1.amountMatched = 2000.00;
        wrapperRecord1.referenceNumber = '123s44567mnJ';
        wrapperRecord1.objectType = 'Customer_Receipt__c';      
        wrapperRecord1.transactedWithName = 'Customer Bill To 1';
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1.add(wrapperRecord1);
        
        //creation of wrapper records for Journal Entry Line
        BankTransactionMatchService.MatchingWrapper wrapperRecord2 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord2.recordId = journalEntryLines[0].Id;
        wrapperRecord2.recordName = journalEntryLines[0].Name;
        wrapperRecord2.transactionDate = System.Now();
        wrapperRecord2.amountMatched = 1000.00;
        wrapperRecord2.objectType = 'Journal_Entry_Line__c';        
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord2);
        
        BankTransactionMatchService.MatchingWrapper wrapperRecord3 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord3.recordId = journalEntryLines[1].Id;
        wrapperRecord3.recordName = journalEntryLines[1].Name;
        wrapperRecord3.transactionDate = System.Now();
        wrapperRecord3.amountMatched = 1000.00;
        wrapperRecord3.objectType = 'Journal_Entry_Line__c';        
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord3);
        
        BankTransactionMatchService.MatchingWrapper wrapperRecord4 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord4.recordId = journalEntryLines[2].Id;
        wrapperRecord4.recordName = journalEntryLines[2].Name;
        wrapperRecord4.transactionDate = System.Now();
        wrapperRecord4.amountMatched = 500.00;
        wrapperRecord4.objectType = 'Journal_Entry_Line__c';        
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord4);
        
        BankTransactionMatchService.MatchingWrapper wrapperRecord5 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord5.recordId = journalEntryLines[3].Id;
        wrapperRecord5.recordName = journalEntryLines[3].Name;
        wrapperRecord5.transactionDate = System.Now();
        wrapperRecord5.amountMatched = 500.00;
        wrapperRecord5.objectType = 'Journal_Entry_Line__c';        
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord5);
        
        Test.StartTest();
        JsonResult result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1,fuel.bankTransactionList[0]);
        system.assertEquals(2,result.total);
        
        result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2,fuel.bankTransactionList[0]);
        system.assertEquals(4,result.total);
        
        result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2,fuel.bankTransactionList[1]);
        system.assertEquals(4,result.total);
        
        system.assert(bankTransactionMatchExtObj.getmatchedChildRecordGridConfigJson() != null );
        system.assert(bankTransactionMatchExtObj.getmatchedRecordFieldList() != null); 
        

        result = BankTransactionMatchExt.approvedMatchedBankTransaction(new list<Id>{fuel.bankTransactionList[1].Id});         
        system.assertEquals(true,result.success);
        Test.StopTest();
    } 
    
    static testMethod void verificationOfUnMatch(){
        TestFuelQuery fuel = new TestFuelQuery();
        list<Bank_Transaction__c> lstBankTransaction = fuel.bankTransactionList;
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(fuel.bankAccount); 
        BankTransactionMatchExt bankTransactionMatchExtObj = new BankTransactionMatchExt(sc);
        list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1 = 
        new list<BankTransactionMatchService.MatchingWrapper>();
        
        list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2 = 
        new list<BankTransactionMatchService.MatchingWrapper>();
        
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        //Creation of customer receipt
        list<Customer_Receipt__c> customerReceipts = fuel.customerReceiptList;
        list<Accounting_Entry__c> lstAccountingEntry = fuel.accountingEntryList;
        list<Customer_Receipt_Line__c> customerReceiptLines = fuel.customerReceiptLineList;
        for(Customer_Receipt__c customerReceipt :customerReceipts){
            customerReceipt.finalized__c = true;
        }
        update customerReceipts;
        
        //creation of Journal entry
        list<Journal_Entry_Line__c> journalEntryLines = fuel.journalEntryLineList;
        list<Accounting_Entry_Line__c> JEAccountingEntriesLines = fuel.JEAccountingEntryLineList;
        
        //creation of wrapper records for customer receipt
        BankTransactionMatchService.MatchingWrapper wrapperRecord = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord.recordId = customerReceipts[0].Id;
        wrapperRecord.recordName = customerReceipts[0].Name;
        wrapperRecord.transactionDate = System.Now();
        wrapperRecord.amountMatched = 3000.00;
        wrapperRecord.referenceNumber = '123s44567mnJ';
        wrapperRecord.objectType = 'Customer_Receipt__c';       
        wrapperRecord.transactedWithName = 'Customer Bill To 1';
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1.add(wrapperRecord);
        
        BankTransactionMatchService.MatchingWrapper wrapperRecord1 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord1.recordId = customerReceipts[1].Id;
        wrapperRecord1.recordName = customerReceipts[1].Name;
        wrapperRecord1.transactionDate = System.Now();
        wrapperRecord1.amountMatched = 2000.00;
        wrapperRecord1.referenceNumber = '123s44567mnJ';
        wrapperRecord1.objectType = 'Customer_Receipt__c';      
        wrapperRecord1.transactedWithName = 'Customer Bill To 1';
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1.add(wrapperRecord1);
        
        //creation of wrapper records for Journal Entry Line
        BankTransactionMatchService.MatchingWrapper wrapperRecord2 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord2.recordId = journalEntryLines[0].Id;
        wrapperRecord2.recordName = journalEntryLines[0].Name;
        wrapperRecord2.transactionDate = System.Now();
        wrapperRecord2.amountMatched = 1000.00;
        wrapperRecord2.objectType = 'Journal_Entry_Line__c';        
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord2);
        
        BankTransactionMatchService.MatchingWrapper wrapperRecord3 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord3.recordId = journalEntryLines[1].Id;
        wrapperRecord3.recordName = journalEntryLines[1].Name;
        wrapperRecord3.transactionDate = System.Now();
        wrapperRecord3.amountMatched = 1000.00;
        wrapperRecord3.objectType = 'Journal_Entry_Line__c';        
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord3);
        
        BankTransactionMatchService.MatchingWrapper wrapperRecord4 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord4.recordId = journalEntryLines[2].Id;
        wrapperRecord4.recordName = journalEntryLines[2].Name;
        wrapperRecord4.transactionDate = System.Now();
        wrapperRecord4.amountMatched = 500.00;
        wrapperRecord4.objectType = 'Journal_Entry_Line__c';        
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord4);
        
        BankTransactionMatchService.MatchingWrapper wrapperRecord5 = new BankTransactionMatchService.MatchingWrapper();
        wrapperRecord5.recordId = journalEntryLines[3].Id;
        wrapperRecord5.recordName = journalEntryLines[3].Name;
        wrapperRecord5.transactionDate = System.Now();
        wrapperRecord5.amountMatched = 500.00;
        wrapperRecord5.objectType = 'Journal_Entry_Line__c';        
        lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2.add(wrapperRecord5);
        
        Test.StartTest();
        JsonResult result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1,fuel.bankTransactionList[0]);
        system.assertEquals(2,result.total);
        
        result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2,fuel.bankTransactionList[1]);
        system.assertEquals(4,result.total);
        list<Bank_Transaction_Match__c> lstBankTransactionMatch = [Select Id from Bank_Transaction_Match__c 
                                                                    where Bank_Transaction__c =: fuel.bankTransactionList[0].Id];
        if(!lstBankTransactionMatch.isEmpty()){
            list<Id> lstBankTransactionMatchId = new list<Id>();
            for(Bank_Transaction_Match__c bankTransactionMatch: lstBankTransactionMatch){
                lstBankTransactionMatchId.add(bankTransactionMatch.Id);
            }
            
            result = BankTransactionMatchExt.ConfirmMatchAndDeleteOthers(lstBankTransactionMatchId);
            system.assertEquals(true,result.success);
            
            Configuration__c conf = new Configuration__c(Name = 'Bank_Transaction__c-'+Bank_Transaction__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id);
            insert conf;
  			update new Bank_Transaction__c(Id=fuel.bankTransactionList[0].Id, Amount__c = 5000);
            result = BankTransactionMatchExt.approvedMatchedBankTransaction(new list<Id>{fuel.bankTransactionList[0].Id});
            system.assertEquals(true,result.success); 
            delete conf;
            system.assertEquals(true,[Select Match_Approved__c from Bank_Transaction__c where Id =:fuel.bankTransactionList[0].Id].Match_Approved__c);
            
            system.assertEquals(6,[Select Id from Bank_Transaction_Match__c].size());
            result = BankTransactionMatchExt.unMatchedBankTransaction(lstBankTransactionMatchId);           
            system.assertEquals(true,result.success);
            system.assertEquals(4,[Select Id from Bank_Transaction_Match__c].size());
            
            system.assertEquals(false,[Select Match_Approved__c from Bank_Transaction__c where Id =:fuel.bankTransactionList[0].Id].Match_Approved__c);
        }
        Test.StopTest();
    }
    
    static testMethod void reconcileBankTransactions() {
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Company__c = fuel.company.Id;
        custReceipt.Customer__c = fuel.customerParent.Id;
        custReceipt.Amount_Received__c = 100;
        custReceipt.bank_Account_2__c = fuel.bankAccount.Id;
        custReceipt.Payment_Method_G__c = 'Check';
        custReceipt.Reference_Number__c = '1234';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Type__c = 'Receipt';
        custReceipt.Currency__c = fuel.company.Default_Transaction_Currency__c;
        insert custReceipt; 
        
        Customer_Receipt_Line__c additionalPayment = new Customer_Receipt_Line__c();
        additionalPayment.Amount__c = 100;
        additionalPayment.Customer_Receipt__c = custReceipt.Id;
        additionalPayment.Type__c = PaymentService.TYPE_PREPAYMENT;
        insert additionalPayment;
        
        custReceipt.Finalized__c = true;
        update custReceipt;
        
        Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = custReceipt.Date_Received__c , 
                                                           Bank_Account__c = fuel.bankAccount.Id);
        insert bt;
        
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Customer_Receipt__c = custReceipt.Id, Amount__c = 100);
        insert btm;
        

        BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
        //String dateToReconcile = '1/25/2016';
        date myDate = date.newInstance(2016, 1, 25);
		String dateToReconcile = myDate.format();
        
        JSONResult result = BankTransactionMatchExt.reconcileBankTransactions(new list<String>{bt.Id}, dateToReconcile, fuel.bankAccount.Id);
        system.assertEquals(true, result.success);
        
        bt = [select id, Reconciled_As_Of_Date__c from Bank_Transaction__c where id = :bt.Id limit 1];
        system.assertEquals(Date.newInstance(2016,1,25), bt.Reconciled_As_Of_Date__c.date());
        
        result = BankTransactionMatchExt.getLatestReconciledDate(fuel.bankAccount.Id);
        system.assertEquals(Date.newInstance(2016,1,25),((datetime) result.records.get(0)).date());
        
    }
    static testMethod void validateWhereClause(){
        TestFuelQuery fuel = new TestFuelQuery();
        Bank_Account__c bankAccount = fuel.bankAccount;     
        
        bankAccount.Opening_Balance__c = 0;
        bankAccount.Opening_Balance_Date__c = system.now().addDays(-10);
        update bankAccount;
        
        Test.StartTest();
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bankAccount);
        BankTransactionMatchExt bankTransactionMatchExtObj = new BankTransactionMatchExt(sc);
        date myDate = date.newInstance(2016, 1, 25);
		String stringDate = myDate.format();
        JSONResult result = BankTransactionMatchExt.getWhereClause(stringDate,(string) bankAccount.Id,(string) fuel.Company.Id);
        system.assertEquals(true, result.success);
        Test.StopTest();
    }
    
   static testmethod void testgetJournalEntryLineFieldList(){ //KNDY-16112
        TestFuelQuery fuel = new TestFuelQuery();
        Bank_Account__c bankAccount = fuel.bankAccount;     
        
        bankAccount.Opening_Balance__c = 0;
        bankAccount.Opening_Balance_Date__c = system.now().addDays(-10);
        update bankAccount;
        
        Test.StartTest();
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bankAccount);
        BankTransactionMatchExt ext = new BankTransactionMatchExt(sc);
        String jsonFieldListStr = ext.getJournalEntryLineFieldList();
        List<FieldInfo> fieldInfoList = (List<FieldInfo>) JSON.deserialize(jsonFieldListStr, List<FieldInfo>.class);
        Boolean hasAmount = false;
        Boolean amountIsVisible = false;
        Boolean amountDRIshidden = false;
        Boolean amountCRIshidden = false;
        for (FieldInfo fi : fieldInfoList){
            if (fi.field == 'Amount'){
               hasAmount = true;
               if (fi.hidden == false){
                   amountIsVisible = true;
               }
            }
            else if (fi.field == 'Amount_CR__c' || fi.field == 'Amount_DR__c'){
               if (fi.field == 'Amount_CR__c' && fi.hidden == true){
                   amountCRIshidden = true;
               }
               if (fi.field == 'Amount_DR__c' && fi.hidden == true){
                   amountDRIshidden = true;
               }
            }
        }
        system.assertEquals( hasAmount,true,jsonFieldListStr);
        system.assertEquals( amountIsVisible,true,jsonFieldListStr);
        system.assertEquals( amountDRIshidden,true,jsonFieldListStr);
        system.assertEquals( amountCRIshidden,true,jsonFieldListStr);
        Test.stopTest();
    }

    static testMethod void testExtensionGetLatestReconciledDate() {
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
        custReceipt.Company__c = fuel.company.Id;
        custReceipt.Customer__c = fuel.customerParent.Id;
        custReceipt.Amount_Received__c = 100;
        custReceipt.bank_Account_2__c = fuel.bankAccount.Id;
        custReceipt.Payment_Method_G__c = 'Check';
        custReceipt.Reference_Number__c = '1234';
        custReceipt.Date_Received__c = system.now();
        custReceipt.Type__c = 'Receipt';
        custReceipt.Currency__c = fuel.company.Default_Transaction_Currency__c;
        insert custReceipt; 
        
        Customer_Receipt_Line__c additionalPayment = new Customer_Receipt_Line__c();
        additionalPayment.Amount__c = 100;
        additionalPayment.Customer_Receipt__c = custReceipt.Id;
        additionalPayment.Type__c = PaymentService.TYPE_PREPAYMENT;
        insert additionalPayment;
        
        custReceipt.Finalized__c = true;
        update custReceipt;
        
        Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = custReceipt.Date_Received__c , 
                                                           Bank_Account__c = fuel.bankAccount.Id);
        insert bt;
        
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Customer_Receipt__c = custReceipt.Id, Amount__c = 100);
        insert btm;
        
        // BT does not have reconciled date
        JSONResult result = BankTransactionMatchExt.getLatestReconciledDate(fuel.bankAccount.Id); 
        system.assertEquals(true, result.success, result);
        system.assertNotEquals(null, result.records, result);
        system.assertEquals(null, result.records[0], result);

        BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
        dateTime reconciledDate = system.now();
        BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.id}, reconciledDate, fuel.bankAccount.id);
        // BT has reconciled date
        result = BankTransactionMatchExt.getLatestReconciledDate(fuel.bankAccount.Id); 
        system.assertEquals(true, result.success);
    }
}