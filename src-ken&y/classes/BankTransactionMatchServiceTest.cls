@isTest
private class BankTransactionMatchServiceTest {

    static testMethod void queryMatchingCR() {
    	User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
    	
    	list<Configuration__c> lConfigs = new list<Configuration__c>();
    	lConfigs.add(new Configuration__c(Name = 'Customer_Receipt__c-'+Customer_Receipt__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Customer_Receipt_Line__c-'+Customer_Receipt_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	
    	insert lConfigs;
    	
    	TestFuel fuel = new TestFuel();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;//dfdf
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Amount_Received__c = 100;
		custReceipt.bank_Account_2__c = fuel.bankAccount.Id;
		custReceipt.Payment_Method_G__c = 'Check';
		custReceipt.Reference_Number__c = '1234';
		custReceipt.Date_Received__c = system.now();
		custReceipt.Transaction_Date__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = TestFuel.currencyUSD.id;
		custReceipt.Finalized__c = true;
		insert custReceipt; 
		
		system.debug('cr '+[select id, amount_Received__c, bank_Account_2__c from Customer_Receipt__c where Id = :custReceipt.Id limit 1]);
		
		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Customer_Receipt__c = custReceipt.id, Status__c = 'Active', Transaction_Type__c = 'Std');
		insert ae;
		system.debug('ae '+[select id, Has_Exceptions__c, Status__c from Accounting_Entry__c where Id = :ae.Id limit 1]);
		Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = custReceipt.Date_Received__c , 
        												   Bank_Account__c = fuel.bankAccount.Id);
        insert bt;
        /*DateTime startDate, DateTime endDate, Id bankAccountId,
			String referenceNumber, Double startAmountMatched, Double EndAmountMatched, String transactedWithName, String depositId, set<String> sObjectTypes, ID bankTransactionID, boolean ignoreAmountRange*/
		list<BankTransactionMatchService.MatchingWrapper>  wrappers = BankTransactionMatchService.getMatchingTransactions(System.now().dateGMT().addDays(-1),System.now().dateGMT().addDays(1), fuel.bankAccount.Id,  
																'12', 90, 110, 'Corp Parent 1', null, new set<String>{'Receipts'}, bt.ID,false);
		
		system.assertEquals(1, wrappers.size());
        
		
        
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Customer_Receipt__c = custReceipt.Id, Amount__c = 100);
        insert btm;
        
         wrappers = BankTransactionMatchService.getMatchingTransactions(system.now().addDays(-1), system.now().addDays(1), fuel.bankAccount.Id,  
																'12', 90, 110, 'Corp Parent 1', null, new set<String>{'Receipts'},  bt.ID,false);
		
		system.assertEquals(0, wrappers.size());
        
    }
    
    static testMethod void queryMatchingSP() {
    	User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
    	
    	list<Configuration__c> lConfigs = new list<Configuration__c>();
    	lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Supplier_Payment_Line__c-'+Supplier_Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	
    	insert lConfigs;
    	
    	TestFuel fuel = new TestFuel();
        Supplier_Payment__c suppPay1 = new Supplier_Payment__c();
        suppPay1.Payment_Amount__c = 100;
        suppPay1.Date_Paid__c = system.now();
        suppPay1.transaction_date__c = system.now();
        suppPay1.Payment_Method_G__c = 'Check';
        suppPay1.Bank_Account__c = fuel.bankAccount.id ;
        suppPay1.Company__c = fuel.company.Id;
        suppPay1.finalized_date__c = system.now();
        suppPay1.Supplier__c = fuel.supplier.Id;
        //KNDY-17923 - deperecated 'Check_Number__c' 
        //suppPay1.Check_Number__c = 1234;
        suppPay1.Reference__c = '1234';
        suppPay1.Currency__c = TestFuel.currencyUSD.id;
        insert suppPay1;
        
       	Supplier_Payment_Line__c  payment1 = new Supplier_Payment_Line__c();
	    payment1.type__c = 'Payment';
	   // payment1.Supplier_Invoice__c = supplierInvList[0].id;
	    payment1.Supplier_Payment__c = suppPay1.id;
	    payment1.Amount__c = 100;
	    insert payment1;
	    
	    suppPay1.Finalized__c = true;
        update suppPay1;
		
		system.debug('suppPay1 '+[select id, Payment_Amount__c, Bank_Account__c from Supplier_Payment__c where Id = :suppPay1.Id limit 1]);
		
		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Supplier_Payment__c = suppPay1.id, Status__c = 'Active', Transaction_Type__c = 'Std');
		insert ae;
		system.debug('ae '+[select id, Has_Exceptions__c, Status__c from Accounting_Entry__c where Id = :ae.Id limit 1]);
		
		list<BankTransactionMatchService.MatchingWrapper>  wrappers = BankTransactionMatchService.getMatchingTransactions(System.now().dateGMT().addDays(-1),System.now().dateGMT().addDays(1), fuel.bankAccount.Id,  
																'1234', 90, 110, 'Supplier-1', null, new set<String>{'Payments'},  null,false);
		
		system.assertEquals(1, wrappers.size());
		system.assertEquals(-100, wrappers[0].amountMatched);
        
    }
    // public static list<MatchingWrapper> getMatchingIntercoReceipts(DateTime startDate, DateTime endDate, Id bankAccountId, 
	//																	String referenceNumber, Double startAmountMatched, Double EndAmountMatched, String transactedWithName)
    
    
     static testMethod void queryMatchingInterCoReceipt() {
    	User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
    	
    	list<Configuration__c> lConfigs = new list<Configuration__c>();
    	lConfigs.add(new Configuration__c(Name = 'Payment__c-'+Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Payment_Line__c-'+Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	 

    	insert lConfigs;
    	
    	TestFuel fuel = new TestFuel();
        Payment__c suppPay1 = new Payment__c();
        suppPay1.Payment_Amount__c = 100;
        suppPay1.transaction_date__c = system.now();
        suppPay1.From_Bank_Account__c = fuel.bankAccount.id ;
        suppPay1.From_Company__c = fuel.company.Id;
         
        suppPay1.To_Bank_Account__c = fuel.bankAccount.id ;
         
        suppPay1.To_Company__c = fuel.company.Id;
         
        suppPay1.finalized_date__c = system.now();
        //suppPay1.Supplier__c = fuel.supplier.Id;
        suppPay1.Reference_Number__c  = '1234';
        suppPay1.Currency__c = TestFuel.currencyUSD.id;
        insert suppPay1;
        
       	Payment_Line__c  payment1 = new Payment_Line__c();
	    payment1.type__c = 'Payment';
	   // payment1.Supplier_Invoice__c = supplierInvList[0].id;
	    payment1.Payment__c = suppPay1.id;
	  //  payment1.Currency__c = TestFuel.currencyUSD.id;
	    payment1.Amount__c = 100;
	    insert payment1;
	    
	    suppPay1.Finalized__c = true;
        update suppPay1;
		
		//system.debug('suppPay1 '+[select id, Payment_Amount__c, Bank_Account__c from Supplier_Payment__c where Id = :suppPay1.Id limit 1]);
		
		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Payment__c = suppPay1.id, Status__c = 'Active', Transaction_Type__c = 'Std');
		insert ae;
		system.debug('ae '+[select id, Has_Exceptions__c, Status__c from Accounting_Entry__c where Id = :ae.Id limit 1]);
		
		list<BankTransactionMatchService.MatchingWrapper>  wrappers = BankTransactionMatchService.getMatchingTransactions(System.now().dateGMT().addDays(-1),System.now().dateGMT().addDays(1), fuel.bankAccount.Id,  
																'1234', 90, 110, null, null, new set<String>{'Receipts'},  null,false);
		
		system.assertEquals(1, wrappers.size());
		system.assertEquals(100, wrappers[0].amountMatched);
        
    }
    
    static testMethod void queryMatchingInterCoPayment() {
    	User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
    	
    	list<Configuration__c> lConfigs = new list<Configuration__c>();
    	lConfigs.add(new Configuration__c(Name = 'Payment__c-'+Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Payment_Line__c-'+Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	 

    	insert lConfigs;
    	
    	TestFuel fuel = new TestFuel();
        Payment__c suppPay1 = new Payment__c();
        suppPay1.Payment_Amount__c = 100;
        suppPay1.transaction_date__c = system.now();
        suppPay1.From_Bank_Account__c = fuel.bankAccount.id ;
        suppPay1.From_Company__c = fuel.company.Id;
         
        suppPay1.To_Bank_Account__c = fuel.bankAccount.id ;
         
        suppPay1.To_Company__c = fuel.company.Id;
         
        suppPay1.finalized_date__c = system.now();
        //suppPay1.Supplier__c = fuel.supplier.Id;
        suppPay1.Reference_Number__c  = '1234';
        suppPay1.Currency__c = TestFuel.currencyUSD.id;
        insert suppPay1;
        
       	Payment_Line__c  payment1 = new Payment_Line__c();
	    payment1.type__c = 'Payment';
	   // payment1.Supplier_Invoice__c = supplierInvList[0].id;
	    payment1.Payment__c = suppPay1.id;
	  //  payment1.Currency__c = TestFuel.currencyUSD.id;
	    payment1.Amount__c = 100;
	    insert payment1;
	    
	    suppPay1.Finalized__c = true;
        update suppPay1;
		
		//system.debug('suppPay1 '+[select id, Payment_Amount__c, Bank_Account__c from Supplier_Payment__c where Id = :suppPay1.Id limit 1]);
		
		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Payment__c = suppPay1.id, Status__c = 'Active', Transaction_Type__c = 'Std');
		insert ae;
		system.debug('ae '+[select id, Has_Exceptions__c, Status__c from Accounting_Entry__c where Id = :ae.Id limit 1]);
		
		list<BankTransactionMatchService.MatchingWrapper>  wrappers = BankTransactionMatchService.getMatchingTransactions(System.now().dateGMT().addDays(-1),System.now().dateGMT().addDays(1), fuel.bankAccount.Id,  
																'1234', 90, 110, null, null, new set<String>{'Payments'}, null,false);
		
		system.assertEquals(1, wrappers.size());
		system.assertEquals(-100, wrappers[0].amountMatched);
        
    }

    
    static testMethod void queryMatchingSPNotFound() {
    	User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
    	
    	list<Configuration__c> lConfigs = new list<Configuration__c>();
    	lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Supplier_Payment_Line__c-'+Supplier_Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	
    	insert lConfigs;
    	
    	TestFuel fuel = new TestFuel();
        Supplier_Payment__c suppPay1 = new Supplier_Payment__c();
        suppPay1.Payment_Amount__c = 100;
        suppPay1.Date_Paid__c = system.now();
        suppPay1.transaction_date__c = system.now();
        suppPay1.Payment_Method_G__c = 'Check';
        suppPay1.Bank_Account__c = fuel.bankAccount.id ;
        suppPay1.Company__c = fuel.company.Id;
        suppPay1.finalized_date__c = system.now();
        suppPay1.Supplier__c = fuel.supplier.Id;
        //KNDY-17923 - deperecated 'Check_Number__c' 
        //suppPay1.Check_Number__c = 1234678;
        suppPay1.Reference__c = '1234678';
        suppPay1.Currency__c = TestFuel.currencyUSD.id;
        insert suppPay1;
        
       	Supplier_Payment_Line__c  payment1 = new Supplier_Payment_Line__c();
	    payment1.type__c = 'Payment';
	   // payment1.Supplier_Invoice__c = supplierInvList[0].id;
	    payment1.Supplier_Payment__c = suppPay1.id;
	    payment1.Amount__c = 100;
	    insert payment1;
	    
	    suppPay1.Finalized__c = true;
        update suppPay1;
		
		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Supplier_Payment__c = suppPay1.id, Status__c = 'Active', Transaction_Type__c = 'Std');
		insert ae;
		
		list<BankTransactionMatchService.MatchingWrapper>  wrappers = BankTransactionMatchService.getMatchingTransactions(System.now().dateGMT().addDays(-1),System.now().dateGMT().addDays(1), fuel.bankAccount.Id,  
																'1234pgr', 90, 110, 'Supplier-1', null, new set<String>{'Payments'},  null,false);
		
		system.assertEquals(0, wrappers.size());
        
    }
    
    static testMethod void queryMatchingJELs() {
    	User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
    	system.debug('currentUser '+currentUser.Id);
    	list<Configuration__c> lConfigs = new list<Configuration__c>();
    	lConfigs.add(new Configuration__c(Name = 'Journal_Entry__c-'+Journal_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Journal_Entry_Line__c-'+Journal_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	
    	insert lConfigs;
    	lConfigs = [Select Name, Value__c from Configuration__c];
    	system.debug('lConfigs '+lConfigs);
    	
    	TestFuel fuel = new TestFuel();
    	
    	 Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = system.now() , 
        												   Bank_Account__c = fuel.bankAccount.Id);
        insert bt;
        
        Journal_Entry__c je1 = new Journal_Entry__c();
		je1.name = 'JE001';
	    je1.Company__c = fuel.company.id;	
	    je1.type__c = 'Manual';   
	    je1.Transaction_Type__c = 'Manual';
	    je1.Transaction_Date__c = System.now();  
		je1.Currency__c = TestFuel.currencyUSD.id;
	 	insert je1;
	 	
		
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = je1.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = fuel.cashGL.id;
		jeLine1.Description__c = 'StartWith 1';
	    insert jeLine1;
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = je1.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 10;
		jeLine2.GL_Account__c = fuel.cashGL.id;
		jeLine2.Bank_Transaction__c = bt.Id;
        jeLine2.Bank_Account__c = fuel.bankaccount.id;
		jeLine2.Description__c = 'StartWith 2';
	    insert jeLine2; 
	    
	    je1.Finalized__c = true;
	    update je1;
		
		system.debug(LoggingLevel.Error, 'je1 '+[select id, Finalized__c, Has_Exceptions__c, Transaction_Date__c from Journal_Entry__c where Id = :je1.Id limit 1]);
		system.debug(LoggingLevel.Error,'jels'+ [Select Id, Amount_DR__c, Amount_CR__c, Bank_Account__c from Journal_Entry_Line__c where Journal_Entry__c = :je1.Id]);
		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Journal_Entry__c = je1.id, Status__c = 'Active', Transaction_Type__c = 'Std');
		insert ae;
		list<Accounting_Entry_Line__c>lAELs = new list<Accounting_Entry_Line__c>();
		lAELs.add(new Accounting_Entry_Line__c( Accounting_Entry__c = ae.Id, Journal_Entry_Line__c = jeLine1.Id));
		lAELs.add(new Accounting_Entry_Line__c( Accounting_Entry__c = ae.Id, Journal_Entry_Line__c = jeLine2.Id));
		insert lAELs;
		system.debug('ae '+[select id, Has_Exceptions__c, Status__c from Accounting_Entry__c where Id = :ae.Id limit 1]);
		
		list<BankTransactionMatchService.MatchingWrapper>  wrappers = BankTransactionMatchService.getMatchingTransactions(System.now().dateGMT().addDays(-1),System.now().dateGMT().addDays(1), fuel.bankaccount.id,
																'StartWith', 1, 10, null, null, new set<String>{'Journal_Entry_Line__c'},  null,false);
	
		system.assertEquals(1, wrappers.size());
        system.assertEquals(10, wrappers[0].amountMatched);//coz JE line wih 10 is tied to Bank Account
        
        wrappers = BankTransactionMatchService.getMatchingTransactions(System.now().dateGMT().addDays(-1),System.now().dateGMT().addDays(1), fuel.bankaccount.id,
																'StartWith', 0, 10, null, null, new set<String>{'Journal_Entry_Line__c'},  null,false);
	
		system.assertEquals(1, wrappers.size());
        system.assertEquals(10, wrappers[0].amountMatched);//coz JE line wih 10 is tied to Bank Account
        	
    }

	static testMethod void queryMatchingJELs_negativeCR() {
		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
		system.debug('currentUser '+currentUser.Id);
		list<Configuration__c> lConfigs = new list<Configuration__c>();
		lConfigs.add(new Configuration__c(Name = 'Journal_Entry__c-'+Journal_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
		lConfigs.add(new Configuration__c(Name = 'Journal_Entry_Line__c-'+Journal_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));

		insert lConfigs;
		lConfigs = [Select Name, Value__c from Configuration__c];
		system.debug('lConfigs '+lConfigs);

		TestFuel fuel = new TestFuel();

		Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = -5, Transaction_Date__c = system.now() ,
				Bank_Account__c = fuel.bankAccount.Id);
		insert bt;

		Journal_Entry__c je1 = new Journal_Entry__c();
		je1.name = 'JE001';
		je1.Company__c = fuel.company.id;
		je1.type__c = 'Manual';
		je1.Transaction_Type__c = 'Manual';
		je1.Transaction_Date__c = System.now();
		je1.Currency__c = TestFuel.currencyUSD.id;
		insert je1;


		Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c();
		jeLine1.Journal_Entry__c = je1.id;
		jeLine1.Amount_CR__c = -5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = fuel.cashGL.id;
		jeLine1.Bank_Account__c = fuel.bankaccount.id;
		jeLine1.Description__c = 'StartWith 1';
		insert jeLine1;

		Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c();
		jeLine2.Journal_Entry__c = je1.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = -5;
		jeLine2.GL_Account__c = fuel.cashGL.id;
		jeLine2.Bank_Transaction__c = bt.Id;
		jeLine2.Description__c = 'StartWith 2';
		insert jeLine2;

		je1.Finalized__c = true;
		update je1;

		system.debug('je1 '+[select id, Finalized__c, Has_Exceptions__c, Transaction_Date__c from Journal_Entry__c where Id = :je1.Id limit 1]);

		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Journal_Entry__c = je1.id, Status__c = 'Active', Transaction_Type__c = 'Std');
		insert ae;
		list<Accounting_Entry_Line__c>lAELs = new list<Accounting_Entry_Line__c>();
		lAELs.add(new Accounting_Entry_Line__c( Accounting_Entry__c = ae.Id, Journal_Entry_Line__c = jeLine1.Id));
		lAELs.add(new Accounting_Entry_Line__c( Accounting_Entry__c = ae.Id, Journal_Entry_Line__c = jeLine2.Id));
		insert lAELs;
		system.debug('ae '+[select id, Has_Exceptions__c, Status__c from Accounting_Entry__c where Id = :ae.Id limit 1]);

		list<BankTransactionMatchService.MatchingWrapper>  wrappers = BankTransactionMatchService.getMatchingTransactions(System.now().dateGMT().addDays(-1),System.now().dateGMT().addDays(1), fuel.bankaccount.id,
				'StartWith', 1, 6, null, null, new set<String>{'Journal_Entry_Line__c'},  null,false);

		system.assertEquals(1, wrappers.size());
		system.assertEquals(-5, wrappers[0].amountMatched);

		wrappers = BankTransactionMatchService.getMatchingTransactions(System.now().dateGMT().addDays(-1),System.now().dateGMT().addDays(1), fuel.bankaccount.id,
				'StartWith', 0, 6, null, null, new set<String>{'Journal_Entry_Line__c'},  null,false);

		system.assertEquals(1, wrappers.size());
		system.assertEquals(-5, wrappers[0].amountMatched);

	}
    
    static testMethod void queryMatchingSP_PaymentMethod() {
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Payment_Line__c-'+Supplier_Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        
        insert lConfigs;
        
        TestFuel fuel = new TestFuel();
        //KNDY-17919 - deprecated next ach number from bank
        //fuel.bankAccount.Next_ACH_Number__c = 0;
        //update fuel.bankAccount;

        
        Supplier_Payment__c suppPay1 = new Supplier_Payment__c();
        suppPay1.Payment_Amount__c = 100;
        suppPay1.Date_Paid__c = system.now();
        suppPay1.transaction_date__c = system.now();
        suppPay1.Payment_Method_G__c = 'ACH';
        suppPay1.Bank_Account__c = fuel.bankAccount.id ;
        suppPay1.Company__c = fuel.company.Id;
        suppPay1.finalized_date__c = system.now();
        suppPay1.Supplier__c = fuel.supplier.Id;
        suppPay1.Currency__c = TestFuel.currencyUSD.id;
        suppPay1.Reference__c = 'abc1';
        insert suppPay1;
        
        Supplier_Payment_Line__c  payment1 = new Supplier_Payment_Line__c();
        payment1.type__c = 'Payment';
        payment1.Supplier_Payment__c = suppPay1.id;
        payment1.Amount__c = 100;
        insert payment1;
        
        suppPay1.Finalized__c = true;
        update suppPay1;
        
        system.debug('suppPay1 '+[select id, Payment_Amount__c, Bank_Account__c from Supplier_Payment__c where Id = :suppPay1.Id limit 1]);
        
        Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Supplier_Payment__c = suppPay1.id, Status__c = 'Active', Transaction_Type__c = 'Std');
        insert ae;
        
        system.debug('ae '+[select id, Has_Exceptions__c, Status__c from Accounting_Entry__c where Id = :ae.Id limit 1]);
        
        list<BankTransactionMatchService.MatchingWrapper>  wrappers = BankTransactionMatchService.getMatchingTransactions(System.now().dateGMT().addDays(-1),System.now().dateGMT().addDays(1), fuel.bankAccount.Id,  
                                                                'abc1', 90, 110, 'Supplier-1', null, new set<String>{'Payments'},  null,false);
        system.assertEquals(1, wrappers.size());
        system.assertEquals(-100, wrappers[0].amountMatched);
        //KNDY-17919 - deprecated next ach number from bank
        //system.assertEquals(String.valueOf(fuel.bankAccount.Next_ACH_Number__c), '0');
        //fuel.bankAccount.Next_ACH_Number__c++;
        //update fuel.bankAccount;

        
        Supplier_Payment__c suppPay2 = new Supplier_Payment__c();
        suppPay2.Payment_Amount__c = 50;
        suppPay2.Date_Paid__c = system.now();
        suppPay2.transaction_date__c = system.now();
        suppPay2.Payment_Method_G__c = 'ACH';
        suppPay2.Bank_Account__c = fuel.bankAccount.id ;
        suppPay2.Company__c = fuel.company.Id;
        suppPay2.finalized_date__c = system.now();
        suppPay2.Supplier__c = fuel.supplier.Id;
        suppPay2.Currency__c = TestFuel.currencyUSD.id;
        //KNDY-17923 - deperecated 'payment_number__c' 	
        suppPay2.Reference__c = '120';
        insert suppPay2;
        
        Supplier_Payment_Line__c  payment2 = new Supplier_Payment_Line__c();
        payment2.type__c = 'Payment';
        payment2.Supplier_Payment__c = suppPay2.id;
        payment2.Amount__c = 50;
        insert payment2;
        
        suppPay2.Finalized__c = true;
        update suppPay2;
        
        Accounting_Entry__c ae1 = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Supplier_Payment__c = suppPay2.id, Status__c = 'Active', Transaction_Type__c = 'Std');
        insert ae1;
        
        list<BankTransactionMatchService.MatchingWrapper>  wrappers1 = BankTransactionMatchService.getMatchingTransactions(System.now().dateGMT().addDays(-1),System.now().dateGMT().addDays(1), fuel.bankAccount.Id,  
                                                                '120', 50, 110, 'Supplier-1', null, new set<String>{'Payments'},  null,false);
        system.assertEquals(1, wrappers1.size());
        system.assertEquals(-50, wrappers1[0].amountMatched);
        //KNDY-17919 - deprecated next ach number from bank
        //system.assertEquals(String.valueOf(fuel.bankAccount.Next_ACH_Number__c), '1');
    }
    
    static testMethod void test_UnMatchExt_NoWarning() {
    	
    	TestFuel fuel = new TestFuel();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Amount_Received__c = 100;
		custReceipt.bank_Account_2__c = fuel.bankAccount.Id;
		custReceipt.Payment_Method_G__c = 'Check';
		custReceipt.Reference_Number__c = '1234';
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = TestFuel.currencyUSD.id;
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
        
        BankTransactionUnMatchExt ext = new BankTransactionUnMatchExt(new ApexPages.StandardController(btm));
        ext.validate();
        list<Bank_Transaction_Match__c> lBTMs = [select id from Bank_Transaction_Match__c where Id = :btm.Id];
        system.assertEquals(0,lBTMs.size(), lBTMs);
    	
    }
    
    static testMethod void test_UnMatchExt_Warning_Approved() {
    	
    	TestFuel fuel = new TestFuel();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Amount_Received__c = 100;
		custReceipt.bank_Account_2__c = fuel.bankAccount.Id;
		custReceipt.Payment_Method_G__c = 'Check';
		custReceipt.Reference_Number__c = '1234';
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = TestFuel.currencyUSD.id;
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
        
        BankTransactionUnMatchExt ext = new BankTransactionUnMatchExt(new ApexPages.StandardController(btm));
        ext.validate();
        boolean ErrorExists = false;
        for( ApexPages.Message msg :ApexPages.GetMessages())
	    	if(msg.getDetail().contains(Label.approved_matches_will_be_deleted))
	    	{
	    		ErrorExists = true;
	    		break;
	    	}
        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
        ext.UnMatch();
        system.assertEquals(true, ext.isDeleted);
        PageReference page = ext.cancel();
        system.assertEquals('/'+Bank_Transaction_Match__c.SObjectType.getDescribe().getKeyPrefix(), page.getURL(), page);
        list<Bank_Transaction_Match__c> lBTMs = [select id from Bank_Transaction_Match__c where Id = :btm.Id];
        system.assertEquals(0,lBTMs.size(), lBTMs);
    	
    }
    
    static testMethod void test_UnMatchExt_Warning_Reconciled() {
    	
    	TestFuel fuel = new TestFuel();
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Amount_Received__c = 100;
		custReceipt.bank_Account_2__c = fuel.bankAccount.Id;
		custReceipt.Payment_Method_G__c = 'Check';
		custReceipt.Reference_Number__c = '1234';
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = TestFuel.currencyUSD.id;
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
        dateTime reconciledDate = system.now();
        BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.id}, reconciledDate, fuel.bankAccount.id);
        
        BankTransactionUnMatchExt ext = new BankTransactionUnMatchExt(new ApexPages.StandardController(btm));
        ext.validate();
        boolean ErrorExists = false;
        for( ApexPages.Message msg :ApexPages.GetMessages())
	    	if(msg.getDetail().contains(Label.bank_transaction_has_been_reconciled))
	    	{
	    		ErrorExists = true;
	    		break;
	    	}
        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
        ext.UnMatch();
        list<Bank_Transaction_Match__c> lBTMs = [select id from Bank_Transaction_Match__c where Id = :btm.Id];
        system.assertEquals(0,lBTMs.size(), lBTMs);
    	
    }
    
     static testMethod void verificationOfBankTransactionAndMatches(){
      TestFuel fuel = new TestFuel();
      list<Bank_Transaction__c> lstBankTransaction = fuel.bankTransactions;
      Bank_Account__c bankAccount = fuel.bankAccount;
		//bankAccount.Active__c = false; //making account inactive
		bankAccount.Opening_Balance__c = 0;
		bankAccount.Opening_Balance_Date__c = system.now();
		update bankAccount;
      ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(fuel.bankAccount); 
      BankTransactionMatchExt bankTransactionMatchExtObj = new BankTransactionMatchExt(sc);
      list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1 = 
      new list<BankTransactionMatchService.MatchingWrapper>();
      
      list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2 = 
      new list<BankTransactionMatchService.MatchingWrapper>();
      User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
      list<Configuration__c> lConfigs = new list<Configuration__c>();
      lConfigs.add(new Configuration__c(Name = 'Customer_Receipt__c-'+Customer_Receipt__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
      lConfigs.add(new Configuration__c(Name = 'Customer_Receipt_Line__c-'+Customer_Receipt_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
      lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
      lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
      lConfigs.add(new Configuration__c(Name = 'Journal_Entry__c-'+Journal_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
      lConfigs.add(new Configuration__c(Name = 'Journal_Entry_Line__c-'+Journal_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
      lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
      insert lConfigs;
    
    //Creation of customer receipt
      list<Customer_Receipt__c> customerReceipts = fuel.customerReceipts;
      list<Accounting_Entry__c> lstAccountingEntry = fuel.accountingEntries;
      list<Customer_Receipt_Line__c> customerReceiptLines = fuel.customerReceiptLines;
      for(Customer_Receipt__c customerReceipt :customerReceipts){
        customerReceipt.finalized__c = true;
      }
      update customerReceipts;
      
      //creation of Journal entry
      list<Journal_Entry_Line__c> journalEntryLines = fuel.journalEntryLines;
      list<Accounting_Entry_Line__c> JEAccountingEntriesLines = fuel.JEAccountingEntriesLines;
      
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
      
      JsonResult result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords1,fuel.bankTransactions[0]);
      system.assertEquals(2,result.total);
      
      result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2,fuel.bankTransactions[1]);
      system.assertEquals(4,result.total);
      
      system.assert(bankTransactionMatchExtObj.getbankTransactionGridConfigJson() != null );     
      system.assert(bankTransactionMatchExtObj.getbankTransactionFieldList() != null);  
    
      list<BankTransactionMatchService.transactionWithMatchesWrapper> lstTransactionWithMatchesWrapper = BankTransactionMatchService.getBankTransactionsAndMatches(
      																									 System.now().dateGMT().addDays(-1),System.now().dateGMT().addDays(1),fuel.bankAccount.Id,System.now().dateGMT().addDays(-10));
      system.assertEquals(3,lstTransactionWithMatchesWrapper.size());
      for(BankTransactionMatchService.transactionWithMatchesWrapper record: lstTransactionWithMatchesWrapper){	
      	  if(record.bankTransaction.Id.equals(fuel.bankTransactions[0].Id)){
      	  	system.assertEquals(2,record.lstMatches.size());	
      	  }else if(record.bankTransaction.Id.equals(fuel.bankTransactions[1].Id)){
      	  	system.assertEquals(4,record.lstMatches.size());	
      	  }else if(record.bankTransaction.Id.equals(fuel.bankTransactions[2].Id)){
      	  	system.assertEquals(null,record.lstMatches);	
      	  }      
      }
      
      result = BankTransactionMatchExt.save(lstmatchedReceiptSupplierPaymentJournalEntryWrapperRecords2,fuel.bankTransactions[2]);
      system.assertEquals(4,result.total);
      
      
      list<BankTransactionMatchService.transactionWithMatchesWrapper> lstTransactionWithMatchesWrapper1 = BankTransactionMatchService.getBankTransactionsAndMatches(
      																									 System.now().dateGMT().addDays(-5),System.now().dateGMT().addDays(2),fuel.bankAccount.Id,System.now().dateGMT().addDays(-10));
      system.assertEquals(3,lstTransactionWithMatchesWrapper1.size());
      for(BankTransactionMatchService.transactionWithMatchesWrapper record: lstTransactionWithMatchesWrapper1){
      	  if(record.bankTransaction.Id.equals(fuel.bankTransactions[0].Id)){
      	  	system.assertEquals(2,record.lstMatches.size());	
      	  }else if(record.bankTransaction.Id.equals(fuel.bankTransactions[1].Id)){
      	  	system.assertEquals(4,record.lstMatches.size());	
      	  }else if(record.bankTransaction.Id.equals(fuel.bankTransactions[2].Id)){
      	  	system.assertEquals(4,record.lstMatches.size());	
      	  }      
      }
      Test.StopTest();
    }
    
    static testMethod void verificationOfBankTransactionWithoutMatches(){
	    TestFuel fuel = new TestFuel();
	    list<Bank_Transaction__c> lstBankTransaction = fuel.bankTransactions;
	    Test.StartTest();
      	list<BankTransactionMatchService.transactionWithMatchesWrapper> lstTransactionWithOutMatchesWrapper = BankTransactionMatchService.getBankTransactionsAndMatches(
      																									 System.now().dateGMT().addDays(-5),System.now().dateGMT().addDays(1),fuel.bankAccount.Id,System.now().dateGMT().addDays(-10));
      	system.assertEquals(3,lstTransactionWithOutMatchesWrapper.size());
      	system.assertEquals(null,lstTransactionWithOutMatchesWrapper[0].lstMatches);
	    system.assertEquals(null,lstTransactionWithOutMatchesWrapper[1].lstMatches);
	    system.assertEquals(null,lstTransactionWithOutMatchesWrapper[2].lstMatches);
	    Test.stopTest();																	 							 
    }
}