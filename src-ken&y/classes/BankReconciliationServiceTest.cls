@isTest
private class BankReconciliationServiceTest {
	
	@testSetup static void ts() {
		TestFuel fuel = new TestFuel();
		system.assert(fuel.company.Id != null &&
				      fuel.periodList != null &&
					  fuel.bankAccount.Id != null &&
				      fuel.customerParent.id != null &&
				      TestFuel.currencyUSD.ID != null &&
					  fuel.supplier.Id != null &&
					  fuel.intercompanyInvestmentInvoice.Id != null &&
					  fuel.intercompanyPayment.ID != null);
		
	
	}

    static testMethod void SuccessfulReconcileTest() {
        TestFuelQuery fuel = new TestFuelQuery();
       
        Bank_account__c ba= fuel.bankAccount;
        ba.Opening_balance__C = 100;
        ba.Balance_offset__c=50;
        ba.opening_balance_date__c = system.now().adddays(-30);
        update ba;
        
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Amount_Received__c = 100;
		custReceipt.bank_Account_2__c = ba.Id;
		custReceipt.Payment_Method_G__c = 'Check';
		custReceipt.Reference_Number__c = '1234';
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		insert custReceipt; 
		
		Customer_Receipt_Line__c additionalPayment = new Customer_Receipt_Line__c();
		additionalPayment.Amount__c = 100;
		additionalPayment.Customer_Receipt__c = custReceipt.Id;
		additionalPayment.Type__c = PaymentService.TYPE_PREPAYMENT;
		insert additionalPayment;
		
		custReceipt.Finalized__c = true;
		update custReceipt;
        
        Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = custReceipt.Date_Received__c , 
        												   Bank_Account__c = ba.Id);
        insert bt;
        
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Customer_Receipt__c = custReceipt.Id, Amount__c = 100);
        insert btm;
        
        BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
        dateTime reconciledDate = system.now();
        BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.Id}, reconciledDate, fuel.bankAccount.id);
        
        bt = [select id, Reconciled_As_Of_Date__c, Reconciled_Hidden__c from Bank_Transaction__c where Id = :bt.Id limit 1];
        system.assertEquals(true, bt.Reconciled_Hidden__c, bt);
        system.assertEquals(reconciledDate, bt.Reconciled_As_Of_Date__c, bt);
        
        system.assertEquals(reconciledDate,BankReconciliationService.getLastReconciledDate(fuel.bankAccount.id));
        
        BankReconciliationService.unReconcileBankTransactions(null, reconciledDate.date(), fuel.bankAccount.id);
        bt = [select id, Reconciled_As_Of_Date__c, Reconciled_Hidden__c from Bank_Transaction__c where Id = :bt.Id limit 1];
        system.assertEquals(false, bt.Reconciled_Hidden__c, bt);
        system.assertEquals(null, bt.Reconciled_As_Of_Date__c, bt);
        

    }
    
    static testMethod void testExtensionUnReconcile() {
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
		custReceipt.Currency__c = fuel.currencyUSD.id;
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
        
        
        BankTransactionUnReconcileExt ext = new BankTransactionUnReconcileExt(new ApexPages.standardController(bt));
        JSONResult result = BankTransactionUnReconcileExt.getLatestReconciliationDate(fuel.bankAccount.Id); 
        system.assertEquals(true, result.success);
        
        result = BankTransactionUnReconcileExt.getRecordsToUnReconcile(fuel.bankAccount.Id, reconciledDate);
        system.assertEquals(true, result.success);
        system.assertEquals(1, result.records.size());
        
        result = BankTransactionUnReconcileExt.UnReconcileBankTransactions(new list<Bank_Transaction__c>{bt}, fuel.bankAccount.Id, reconciledDate);
        system.assertEquals(true, result.success);
        
        result = BankTransactionUnReconcileExt.getLatestReconciliationDate(fuel.bankAccount.Id);
        system.assertEquals(false, result.success); 
    }
    
    static testMethod void testQueryForBankTransaction() {
    	 TestFuelQuery fuel = new TestFuelQuery();
    	 Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = system.now() , 
        												   Bank_Account__c = fuel.bankAccount.Id);
    	 Bank_Transaction__c bt1  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = system.now().addDays(-2) , 
        												   Bank_Account__c = fuel.bankAccount.Id);
        insert bt;
        insert bt1;
        
        SchemaUtil util = SchemaUtil.getInstance();
        String query = util.generateQueryFromFieldSet('Bank_Transaction__c', new set<String>{}, new set<String>(BankReconciliationService.getBankTransactionsFields()),
        											  BankReconciliationService.getBankTransactionsWhereClause(system.now().addMinutes(2), fuel.bankAccount.Id, fuel.company.Id,system.now().adddays(-1)));
        
        list<Bank_Transaction__c> lBTs = Database.query(query);
        system.assertEquals(1, lBTs.size());// should only consider bank transactions after Opening balance date
    }
    
    static testMethod void testQueryForBankTransaction_VOIDBTG() {
    	 TestFuelQuery fuel = new TestFuelQuery();
           Bank_account__c ba= fuel.bankAccount;
        ba.Opening_balance__C = 100;
        ba.Balance_offset__c=50;
        ba.opening_balance_date__c = system.now().adddays(-30);
        update ba;
        
    	 Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = system.now() , 
        												   Bank_Account__c = fuel.bankAccount.Id);
        insert bt;
        
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
    	lConfigs.add(new Configuration__c(Name = 'Bank_Transaction_Group__c-'+Bank_Transaction_Group__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
         bt = [Select Bank_Transaction_Group__c  from Bank_Transaction__c where Id = :bt.Id limit 1];
        
        update new Bank_Transaction_Group__c(Id = bt.Bank_Transaction_Group__c, Void__c = true);
        
        SchemaUtil util = SchemaUtil.getInstance();
        String query = util.generateQueryFromFieldSet('Bank_Transaction__c', new set<String>{}, new set<String>(BankReconciliationService.getBankTransactionsFields()),
					   BankReconciliationService.getBankTransactionsWhereClause(system.now().addMinutes(2), fuel.bankAccount.Id, fuel.company.Id, ba.opening_balance_date__c));
        
        list<Bank_Transaction__c> lBTs = Database.query(query);
        system.assertEquals(0, lBTs.size());
    }
    
    static testMethod void testQueryReconciled() {
    	
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
		custReceipt.Currency__c = fuel.currencyUSD.id;
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
        BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.Id}, reconciledDate, fuel.bankAccount.id);
        
        SchemaUtil util = SchemaUtil.getInstance();
        String query = util.generateQueryFromFieldSet('Bank_Transaction__c', new set<String>{}, new set<String>(BankReconciliationService.getReconciledTransactionsFields()),
        											  BankReconciliationService.getReconciledTransactionsWhereClause(system.now(), fuel.bankAccount.Id, fuel.company.Id,system.now().addDays(-1)));
        
        list<Bank_Transaction__c> lBTs = Database.query(query);
        system.assertEquals(1, lBTs.size());
    	
    }
    
    static testMethod void CRinTransit() {
    	User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
    	
    	list<Configuration__c> lConfigs = new list<Configuration__c>();
    	lConfigs.add(new Configuration__c(Name = 'Customer_Receipt__c-'+Customer_Receipt__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Customer_Receipt_Line__c-'+Customer_Receipt_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	
    	insert lConfigs;
    	
    	TestFuelQuery fuel = new TestFuelQuery();
        
         Bank_account__c ba= fuel.bankAccount;
        ba.Opening_balance__C = 100;
        ba.Balance_offset__c=50;
        ba.opening_balance_date__c = system.now().adddays(-30);
        update ba;
        
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Amount_Received__c = 100;
		custReceipt.bank_Account_2__c = fuel.bankAccount.Id;
		custReceipt.Payment_Method_G__c = 'Check';
		custReceipt.Reference_Number__c = '1234';
		custReceipt.Date_Received__c = system.now();
		custReceipt.Transaction_Date__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		custReceipt.Finalized__c = true;
		insert custReceipt; 
		
		system.debug('cr '+[select id, amount_Received__c, bank_Account_2__c from Customer_Receipt__c where Id = :custReceipt.Id limit 1]);
		
		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Customer_Receipt__c = custReceipt.id, Status__c = 'Active', Transaction_Type__c = 'Std');
		insert ae;
		system.debug('ae '+[select id, Has_Exceptions__c, Status__c from Accounting_Entry__c where Id = :ae.Id limit 1]);
		
		SchemaUtil util = SchemaUtil.getInstance();
        String query = util.generateQueryFromFieldSet('Customer_Receipt__c', new set<String>{}, new set<String>(BankReconciliationService.getCustomerReceiptsInTransitFields()),
        											  BankReconciliationService.getCustomerReceiptsInTransitWhereClause(system.now().addMinutes(2), ba.Id, fuel.company.Id, ba.opening_balance_date__c));
        
        list<Customer_Receipt__c> lCR = Database.query(query);
        system.assertEquals(1, lCR.size()); //NO Transactions associated
        
        Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = custReceipt.Date_Received__c , 
        												   Bank_Account__c = fuel.bankAccount.Id);
        insert bt;
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Customer_Receipt__c = custReceipt.Id, Amount__c = 100);
        insert btm;
        
        lCR = Database.query(query);
        system.assertEquals(1, lCR.size()); //Transaction matched against CR, but not approved
        
       BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
        lCR = Database.query(query);
        system.assertEquals(0, lCR.size());//Transaction matched against CR, and approved
        
        dateTime reconciledDate = system.now();
        BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.id}, reconciledDate, fuel.bankAccount.id);
        lCR = Database.query(query);
        system.assertEquals(0, lCR.size());//Transaction matched against CR,  approved and reconciled!
		
    }

	static testMethod void CRinTransit_BTAheadOfReconcileDate() {
		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];

		list<Configuration__c> lConfigs = new list<Configuration__c>();
		lConfigs.add(new Configuration__c(Name = 'Customer_Receipt__c-'+Customer_Receipt__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
		lConfigs.add(new Configuration__c(Name = 'Customer_Receipt_Line__c-'+Customer_Receipt_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));

		insert lConfigs;

		TestFuelQuery fuel = new TestFuelQuery();


		Bank_account__c ba= fuel.bankAccount;
		ba.Opening_balance__C = 100;
		ba.Balance_offset__c=50;
		ba.opening_balance_date__c = system.now().adddays(-30);
		update ba;

		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Amount_Received__c = 100;
		custReceipt.bank_Account_2__c = fuel.bankAccount.Id;
		custReceipt.Payment_Method_2__c = 'Check';
		custReceipt.Reference_Number__c = '1234';
		custReceipt.Date_Received__c = system.now();
		custReceipt.Transaction_Date__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = fuel.currencyUSD.id;
		custReceipt.Finalized__c = true;
		insert custReceipt;

		system.debug('cr '+[select id, amount_Received__c, bank_Account_2__c from Customer_Receipt__c where Id = :custReceipt.Id limit 1]);

		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Customer_Receipt__c = custReceipt.id, Status__c = 'Active', Transaction_Type__c = 'Std');
		insert ae;
		system.debug('ae '+[select id, Has_Exceptions__c, Status__c from Accounting_Entry__c where Id = :ae.Id limit 1]);

		SchemaUtil util = SchemaUtil.getInstance();
		DateTime reconcileAsOfDate = system.now().addMinutes(2);

		String query = util.generateQueryFromFieldSet('Customer_Receipt__c', new set<String>{}, new set<String>(BankReconciliationService.getCustomerReceiptsInTransitFields()),
				BankReconciliationService.getCustomerReceiptsInTransitWhereClause(system.now().addMinutes(2), ba.Id, fuel.company.Id, ba.opening_balance_date__c));

		list<Customer_Receipt__c> lCR = Database.query(query);
		system.assertEquals(1, lCR.size()); //NO Transactions associated

		Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = reconcileAsOfDate.addDays(10) ,
				Bank_Account__c = fuel.bankAccount.Id);
		insert bt;
		Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Customer_Receipt__c = custReceipt.Id, Amount__c = 100);
		insert btm;

		lCR = Database.query(query);
		system.assertEquals(1, lCR.size()); //Transaction matched against CR, but not approved

		BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
		lCR = Database.query(query);
		system.assertEquals(1, lCR.size());//Transaction matched against CR, and approved

		BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.id}, reconcileAsOfDate, fuel.bankAccount.id);
		lCR = Database.query(query);
		system.assertEquals(1, lCR.size());//Transaction matched against CR,  approved and reconciled!

	}

    static testMethod void SPinTransit() {
    	User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
    	
    	list<Configuration__c> lConfigs = new list<Configuration__c>();
    	lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Supplier_Payment_Line__c-'+Supplier_Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
    	
    	insert lConfigs;
    	
    	TestFuelQuery fuel = new TestFuelQuery();
        
        Bank_account__c ba= fuel.bankAccount;
        ba.Opening_balance__C = 100;
        ba.Balance_offset__c=50;
        ba.opening_balance_date__c = system.now().adddays(-30);
        update ba;
        
        Supplier_Payment__c suppPay1 = new Supplier_Payment__c();
        suppPay1.Payment_Amount__c = 100;
        suppPay1.Date_Paid__c = system.now();
        suppPay1.transaction_date__c = system.now();
        suppPay1.Payment_Method_G__c = 'Check';
        suppPay1.Bank_Account__c = fuel.bankAccount.id ;
        suppPay1.Company__c = fuel.company.Id;
        suppPay1.finalized_date__c = system.now();
        suppPay1.Supplier__c = fuel.supplier.Id;
        suppPay1.Reference__c = '1234';
        suppPay1.Currency__c = fuel.currencyUSD.id;
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

		SchemaUtil util = SchemaUtil.getInstance();
        String query = util.generateQueryFromFieldSet('Supplier_Payment__c', new set<String>{}, new set<String>(BankReconciliationService.getSupplierPaymentsInTransitFields()),
        											  BankReconciliationService.getSupplierPaymentsInTransitWhereClause(system.now().addMinutes(1), ba.Id, fuel.company.Id,ba.opening_balance_date__c));

        list<Supplier_Payment__c> lSP = Database.query(query);
        system.assertEquals(1, lSP.size()); //NO Transactions associated

        Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = suppPay1.Transaction_Date__c ,
        												   Bank_Account__c = fuel.bankAccount.Id);
        insert bt;
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Supplier_Payment__c = suppPay1.Id, Amount__c = 100);
        insert btm;

        lSP = Database.query(query);
        system.assertEquals(1, lSP.size()); //Transaction matched against SP, but not approved

        BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
        lSP = Database.query(query);
        system.assertEquals(0, lSP.size());//Transaction matched against SP, and approved

        dateTime reconciledDate = system.now();
        BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.id}, reconciledDate, fuel.bankAccount.id);
        lSP = Database.query(query);
        system.assertEquals(0, lSP.size());//Transaction matched against SP,  approved and reconciled!

    }

	static testMethod void SPinTransit_BTAheadOfReconcileDate() {
		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];

		list<Configuration__c> lConfigs = new list<Configuration__c>();
		lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
		lConfigs.add(new Configuration__c(Name = 'Supplier_Payment_Line__c-'+Supplier_Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));

		insert lConfigs;

		TestFuelQuery fuel = new TestFuelQuery();

		Bank_account__c ba= fuel.bankAccount;
		ba.Opening_balance__C = 100;
		ba.Balance_offset__c=50;
		ba.opening_balance_date__c = system.now().adddays(-30);
		update ba;

		Supplier_Payment__c suppPay1 = new Supplier_Payment__c();
		suppPay1.Payment_Amount__c = 100;
		suppPay1.Date_Paid__c = system.now();
		suppPay1.transaction_date__c = system.now();
		suppPay1.Payment_Method__c = 'Check';
		suppPay1.Bank_Account__c = fuel.bankAccount.id ;
		suppPay1.Company__c = fuel.company.Id;
		suppPay1.finalized_date__c = system.now();
		suppPay1.Supplier__c = fuel.supplier.Id;
		suppPay1.Check_Number__c = 1234;
		suppPay1.Currency__c = fuel.currencyUSD.id;
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

		SchemaUtil util = SchemaUtil.getInstance();

		DateTime reconcileAsOfDate = system.now().addMinutes(1);

		String query = util.generateQueryFromFieldSet('Supplier_Payment__c', new set<String>{}, new set<String>(BankReconciliationService.getSupplierPaymentsInTransitFields()),
				BankReconciliationService.getSupplierPaymentsInTransitWhereClause(reconcileAsOfDate, ba.Id, fuel.company.Id,ba.opening_balance_date__c));

		list<Supplier_Payment__c> lSP = Database.query(query);
		system.assertEquals(1, lSP.size()); //NO Transactions associated

		Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = reconcileAsOfDate.addDays(10),
				Bank_Account__c = fuel.bankAccount.Id);
		insert bt;
		Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Supplier_Payment__c = suppPay1.Id, Amount__c = 100);
		insert btm;

		lSP = Database.query(query);
		system.assertEquals(1, lSP.size()); //Transaction matched against SP, but not approved

		BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
		lSP = Database.query(query);
		system.assertEquals(1, lSP.size());//Transaction matched against SP, and approved

		dateTime reconciledDate = system.now();
		BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.id}, reconciledDate, fuel.bankAccount.id);
		lSP = Database.query(query);
		system.assertEquals(1, lSP.size());//Transaction matched against SP,  approved and reconciled!

	}

    static testMethod void JELsInTransit() {
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

    	TestFuelQuery fuel = new TestFuelQuery();

         Bank_account__c ba= fuel.bankAccount;
        ba.Opening_balance__C = 100;
        ba.Balance_offset__c=50;
        ba.opening_balance_date__c = system.now().adddays(-30);
		ba.Company__c = fuel.company.id;
		update ba;

        Journal_Entry__c je1 = new Journal_Entry__c();
		je1.name = 'JE001';
	    je1.Company__c = fuel.company.id;
	    je1.type__c = 'Manual';
	    je1.Transaction_Type__c = 'Manual';
	    je1.Transaction_Date__c = system.now();
		je1.Currency__c = fuel.currencyUSD.id;
	 	insert je1;


	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c();
	    jeLine1.Journal_Entry__c = je1.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.Bank_account__c = ba.id;
		jeLine1.Description__c = 'StartWith 1';
	    insert jeLine1;

	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c();
	    jeLine2.Journal_Entry__c = je1.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 10;
		jeLine2.Bank_account__c = ba.id;
		jeLine2.Description__c = 'StartWith 2';
	    insert jeLine2;

	    je1.Finalized__c = true;
	    update je1;

		system.debug('je1 '+[select id, Finalized__c, Has_Exceptions__c, Transaction_Date__c from Journal_Entry__c where Id = :je1.Id limit 1]);
		system.debug('jeLines '+[select Id, GL_Account__c from Journal_Entry_Line__c where Journal_Entry__c = :je1.Id limit 1]);
		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Journal_Entry__c = je1.id, Status__c = 'Active', Transaction_Type__c = 'Std', Transaction_Date__c = system.now());
		insert ae;
		list<Accounting_Entry_Line__c>lAELs = new list<Accounting_Entry_Line__c>();
		lAELs.add(new Accounting_Entry_Line__c( Accounting_Entry__c = ae.Id, Journal_Entry_Line__c = jeLine1.Id, GL_Account__c = fuel.bankAccount.GL_Account__c));
		lAELs.add(new Accounting_Entry_Line__c( Accounting_Entry__c = ae.Id, Journal_Entry_Line__c = jeLine2.Id, GL_Account__c = fuel.bankAccount.GL_Account__c));
		insert lAELs;
		system.debug('ae '+[select id, Has_Exceptions__c, Status__c, Transaction_Date__c from Accounting_Entry__c where Id = :ae.Id limit 1]);

		SchemaUtil util = SchemaUtil.getInstance();
        String query = util.generateQueryFromFieldSet('Journal_Entry_Line__c', new set<String>{}, new set<String>(BankReconciliationService.getJournalEntryLinesInTransitFields()),
        											  BankReconciliationService.getJournalEntryLinesInTransitWhereClause(system.now().addMinutes(2), ba.Id, fuel.company.Id,ba.opening_balance_date__c));

        system.debug('query '+query);
        list<Journal_Entry_Line__c> lJELs = Database.query(query);
        system.assertEquals(2, lJELs.size()); //NO Transactions associated

        Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = je1.Transaction_Date__c ,
        												   Bank_Account__c = fuel.bankAccount.Id);
        insert bt;
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Journal_Entry_Line__c = jeLine1.Id, Amount__c = 100);
        insert btm;

        lJELs = Database.query(query);
        system.assertEquals(2, lJELs.size()); //Transaction matched against JEL, but not approved

        BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
        lJELs = Database.query(query);
        system.assertEquals(1, lJELs.size());//Transaction matched against JEL, and approved

        dateTime reconciledDate = system.now();
        BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.id}, reconciledDate, fuel.bankAccount.id);
        lJELs = Database.query(query);
        system.assertEquals(1, lJELs.size());//Transaction matched against JEL,  approved and reconciled!


		//KNDY-17243
		ae = new Accounting_Entry__c (Company__c = fuel.altCompany.Id, name = 'hello', Journal_Entry__c = je1.id, Status__c = 'Active', Transaction_Type__c = 'Std', Transaction_Date__c = system.now());
		insert ae;
		lAELs = new list<Accounting_Entry_Line__c>();
		lAELs.add(new Accounting_Entry_Line__c( Accounting_Entry__c = ae.Id, Journal_Entry_Line__c = jeLine1.Id, GL_Account__c = fuel.bankAccount.GL_Account__c));
		lAELs.add(new Accounting_Entry_Line__c( Accounting_Entry__c = ae.Id, Journal_Entry_Line__c = jeLine2.Id, GL_Account__c = fuel.bankAccount.GL_Account__c));
		insert lAELs;

		query = util.generateQueryFromFieldSet('Accounting_Entry_Line__c', new set<String>{}, new set<String>(BankReconciliationService.getCurrentGLBalanceFields()),
        											  BankReconciliationService.getCurrentGLBalanceWhereClause(system.now().addMinutes(2), fuel.bankAccount.GL_Account__c, fuel.bankAccount.Company__c));
        list<Accounting_Entry_Line__c> lAEs = Database.query(query);
        system.assertEquals(2, lAEs.size());//Transaction matched against JEL,  approved and reconciled!
    }

	static testMethod void JELsInTransit_BTAheadOfReconcileDate() {
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

		TestFuelQuery fuel = new TestFuelQuery();

		Bank_account__c ba= fuel.bankAccount;
		ba.Opening_balance__C = 100;
		ba.Balance_offset__c=50;
		ba.opening_balance_date__c = system.now().adddays(-30);
		ba.Company__c = fuel.company.id;
		update ba;

		Journal_Entry__c je1 = new Journal_Entry__c();
		je1.name = 'JE001';
		je1.Company__c = fuel.company.id;
		je1.type__c = 'Manual';
		je1.Transaction_Type__c = 'Manual';
		je1.Transaction_Date__c = system.now();
		je1.Currency__c = fuel.currencyUSD.id;
		insert je1;


		Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c();
		jeLine1.Journal_Entry__c = je1.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.Bank_account__c = ba.id;
		jeLine1.Description__c = 'StartWith 1';
		insert jeLine1;

		Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c();
		jeLine2.Journal_Entry__c = je1.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 10;
		jeLine2.Bank_account__c = ba.id;
		jeLine2.Description__c = 'StartWith 2';
		insert jeLine2;

		je1.Finalized__c = true;
		update je1;

		system.debug('je1 '+[select id, Finalized__c, Has_Exceptions__c, Transaction_Date__c from Journal_Entry__c where Id = :je1.Id limit 1]);
		system.debug('jeLines '+[select Id, GL_Account__c from Journal_Entry_Line__c where Journal_Entry__c = :je1.Id limit 1]);
		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Journal_Entry__c = je1.id, Status__c = 'Active', Transaction_Type__c = 'Std', Transaction_Date__c = system.now());
		insert ae;
		list<Accounting_Entry_Line__c>lAELs = new list<Accounting_Entry_Line__c>();
		lAELs.add(new Accounting_Entry_Line__c( Accounting_Entry__c = ae.Id, Journal_Entry_Line__c = jeLine1.Id, GL_Account__c = fuel.bankAccount.GL_Account__c));
		lAELs.add(new Accounting_Entry_Line__c( Accounting_Entry__c = ae.Id, Journal_Entry_Line__c = jeLine2.Id, GL_Account__c = fuel.bankAccount.GL_Account__c));
		insert lAELs;
		system.debug('ae '+[select id, Has_Exceptions__c, Status__c, Transaction_Date__c from Accounting_Entry__c where Id = :ae.Id limit 1]);

		SchemaUtil util = SchemaUtil.getInstance();
		DateTime reconcileAsOfDate = system.now().addMinutes(1);

		String query = util.generateQueryFromFieldSet('Journal_Entry_Line__c', new set<String>{}, new set<String>(BankReconciliationService.getJournalEntryLinesInTransitFields()),
				BankReconciliationService.getJournalEntryLinesInTransitWhereClause(reconcileAsOfDate, ba.Id, fuel.company.Id,ba.opening_balance_date__c));

		system.debug('query '+query);
		list<Journal_Entry_Line__c> lJELs = Database.query(query);
		system.assertEquals(2, lJELs.size()); //NO Transactions associated

		Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = reconcileAsOfDate.addDays(10),
				Bank_Account__c = fuel.bankAccount.Id);
		insert bt;
		Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Journal_Entry_Line__c = jeLine1.Id, Amount__c = 100);
		insert btm;

		lJELs = Database.query(query);
		system.assertEquals(2, lJELs.size()); //Transaction matched against JEL, but not approved

		BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
		lJELs = Database.query(query);
		system.assertEquals(2, lJELs.size());//Transaction matched against JEL, and approved

		dateTime reconciledDate = system.now();
		BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.id}, reconciledDate, fuel.bankAccount.id);
		lJELs = Database.query(query);
		system.assertEquals(2, lJELs.size());//Transaction matched against JEL,  approved and reconciled!

	}

	static testMethod void InterCoPaymentInTransit() {
		list<Configuration__c> lConfigs = new list<Configuration__c>();
		lConfigs.add(new Configuration__c(Name = 'Payment__c-'+Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));
		lConfigs.add(new Configuration__c(Name = 'Payment_Line__c-'+Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));


		insert lConfigs;

		TestFuelQuery fuel = new TestFuelQuery();
		DateTime reconcileAsOfDate = system.now();
		Bank_account__c ba= fuel.bankAccount;
		ba.Opening_balance__C = 100;
		ba.Balance_offset__c=50;
		ba.opening_balance_date__c = system.now().adddays(-30);
		update ba;

		Payment__c interCoPayment = new Payment__c();
		interCoPayment.Payment_Amount__c = 100;
		interCoPayment.transaction_date__c = reconcileAsOfDate;
		interCoPayment.From_Bank_Account__c = fuel.bankAccount.id ;
		interCoPayment.From_Company__c = fuel.company.Id;

		interCoPayment.To_Bank_Account__c = fuel.bankAccount.id ;

		interCoPayment.To_Company__c = fuel.company.Id;

		interCoPayment.finalized_date__c = reconcileAsOfDate;
		//interCoPayment.Supplier__c = fuel.supplier.Id;
		interCoPayment.Reference_Number__c  = '1234';
		interCoPayment.Currency__c = fuel.currencyUSD.id;
		insert interCoPayment;

		Payment_Line__c  payment1 = new Payment_Line__c();
		payment1.type__c = 'Payment';
		// payment1.Supplier_Invoice__c = supplierInvList[0].id;
		payment1.Payment__c = interCoPayment.id;
		//  payment1.Currency__c = TestFuel.currencyUSD.id;
		payment1.Amount__c = 100;
		insert payment1;

		interCoPayment.Finalized__c = true;
		update interCoPayment;

		//system.debug('interCoPayment '+[select id, Payment_Amount__c, Bank_Account__c from Supplier_Payment__c where Id = :interCoPayment.Id limit 1]);

		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Payment__c = interCoPayment.id, Status__c = 'Active', Transaction_Type__c = 'Std');
		insert ae;
		system.debug(LoggingLevel.Error, 'ae '+[select id, Has_Exceptions__c, Status__c, Payment__c from Accounting_Entry__c where Id = :ae.Id limit 1]);

		SchemaUtil util = SchemaUtil.getInstance();
		String query = util.generateQueryFromFieldSet('Payment__c', new set<String>{}, new set<String>(BankReconciliationService.getIntercoInTransitFields()),
				BankReconciliationService.getIntercoPaymentsInTransit(reconcileAsOfDate.addMinutes(1), ba.Id, fuel.company.Id, ba.opening_balance_date__c));

		system.debug(LoggingLevel.Error,'query '+query);
		system.debug(LoggingLevel.Error,'payment '+[Select id, Transaction_Date__c, Finalized__c, Payment_Amount__c, From_Company__c, From_Bank_Account__c from Payment__c where id = :interCoPayment.Id]);
		system.debug(LoggingLevel.Error,'from company '+fuel.company.Id);
		system.debug(LoggingLevel.Error,'from ba '+fuel.bankAccount.Id);
		system.debug(LoggingLevel.Error,'reconcileAsOfDate.addMinutes(-1) '+reconcileAsOfDate.addMinutes(-1));
		system.debug(LoggingLevel.Error,'ba.opening_balance_date__c '+ba.opening_balance_date__c);


		system.debug(LoggingLevel.Error,'query from data '+[SELECT id,name, Transaction_Date__c FROM Payment__c WHERE From_Bank_Account__c = :fuel.bankAccount.Id and From_Company__c = :fuel.company.Id and Finalized__c = true and Payment_amount__c > 0
								]);


		list<Payment__c> lPayments = Database.query(query);
		system.assertEquals(1, lPayments.size()); //NO Transactions associated

		Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = reconcileAsOfDate ,
				Bank_Account__c = fuel.bankAccount.Id);
		insert bt;
		Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Payment__c = interCoPayment.Id, Amount__c = 100);
		insert btm;

		lPayments = Database.query(query);
		system.assertEquals(1, lPayments.size()); //Transaction matched against CR, but not approved

		BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
		lPayments = Database.query(query);
		system.assertEquals(0, lPayments.size());//Transaction matched against CR, and approved

		dateTime reconciledDate = system.now();
		BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.id}, reconciledDate, fuel.bankAccount.id);
		lPayments = Database.query(query);
		system.assertEquals(0, lPayments.size());//Transaction matched against CR,  approved and reconciled!




	}

	static testMethod void InterCoPaymentInTransit_BTAheadOfReconcileDate() {
		list<Configuration__c> lConfigs = new list<Configuration__c>();
		lConfigs.add(new Configuration__c(Name = 'Payment__c-'+Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));
		lConfigs.add(new Configuration__c(Name = 'Payment_Line__c-'+Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));


		insert lConfigs;

		TestFuelQuery fuel = new TestFuelQuery();
		DateTime reconcileAsOfDate = system.now();
		Bank_account__c ba= fuel.bankAccount;
		ba.Opening_balance__C = 100;
		ba.Balance_offset__c=50;
		ba.opening_balance_date__c = reconcileAsOfDate.adddays(-30);
		update ba;

		Payment__c interCoPayment = new Payment__c();
		interCoPayment.Payment_Amount__c = 100;
		interCoPayment.transaction_date__c = reconcileAsOfDate;
		interCoPayment.From_Bank_Account__c = fuel.bankAccount.id ;
		interCoPayment.From_Company__c = fuel.company.Id;

		interCoPayment.To_Bank_Account__c = fuel.bankAccount.id ;

		interCoPayment.To_Company__c = fuel.company.Id;

		interCoPayment.finalized_date__c = reconcileAsOfDate;
		//interCoPayment.Supplier__c = fuel.supplier.Id;
		interCoPayment.Reference_Number__c  = '1234';
		interCoPayment.Currency__c = fuel.currencyUSD.id;
		insert interCoPayment;

		Payment_Line__c  payment1 = new Payment_Line__c();
		payment1.type__c = 'Payment';
		// payment1.Supplier_Invoice__c = supplierInvList[0].id;
		payment1.Payment__c = interCoPayment.id;
		//  payment1.Currency__c = TestFuel.currencyUSD.id;
		payment1.Amount__c = 100;
		insert payment1;

		interCoPayment.Finalized__c = true;
		update interCoPayment;

		//system.debug('interCoPayment '+[select id, Payment_Amount__c, Bank_Account__c from Supplier_Payment__c where Id = :interCoPayment.Id limit 1]);

		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Payment__c = interCoPayment.id, Status__c = 'Active', Transaction_Type__c = 'Std');
		insert ae;
		system.debug('ae '+[select id, Has_Exceptions__c, Status__c from Accounting_Entry__c where Id = :ae.Id limit 1]);

		SchemaUtil util = SchemaUtil.getInstance();
		String query = util.generateQueryFromFieldSet('Payment__c', new set<String>{}, new set<String>(BankReconciliationService.getIntercoInTransitFields()),
				BankReconciliationService.getIntercoPaymentsInTransit(reconcileAsOfDate.addMinutes(1), ba.Id, fuel.company.Id, ba.opening_balance_date__c));

		list<Payment__c> lPayments = Database.query(query);
		system.assertEquals(1, lPayments.size()); //NO Transactions associated

		Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 10000, Transaction_Date__c = reconcileAsOfDate.addDays(10) ,
				Bank_Account__c = fuel.bankAccount.Id);
		insert bt;
		Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Payment__c = interCoPayment.Id, Amount__c = 10000);
		insert btm;

		lPayments = Database.query(query);
		system.assertEquals(1, lPayments.size()); //Transaction matched against CR, but not approved

		BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
		lPayments = Database.query(query);
		system.assertEquals(1, lPayments.size());//Transaction matched against CR, and approved

		dateTime reconciledDate = system.now();
		BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.id}, reconciledDate, fuel.bankAccount.id);
		lPayments = Database.query(query);
		system.assertEquals(1, lPayments.size());//Transaction matched against CR,  approved and reconciled!




	}

	static testMethod void InterCoReceiptInTransit() {
		list<Configuration__c> lConfigs = new list<Configuration__c>();
		lConfigs.add(new Configuration__c(Name = 'Payment__c-'+Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));
		lConfigs.add(new Configuration__c(Name = 'Payment_Line__c-'+Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));


		insert lConfigs;

		TestFuelQuery fuel = new TestFuelQuery();
		DateTime reconcileAsOfDate = system.now();
		Bank_account__c ba= fuel.bankAccount;
		ba.Opening_balance__C = 100;
		ba.Balance_offset__c=50;
		ba.opening_balance_date__c = reconcileAsOfDate.adddays(-30);
		update ba;

		Payment__c interCoPayment = new Payment__c();
		interCoPayment.Payment_Amount__c = 100;
		interCoPayment.transaction_date__c = reconcileAsOfDate;
		interCoPayment.From_Bank_Account__c = fuel.bankAccount.id ;
		interCoPayment.From_Company__c = fuel.company.Id;

		interCoPayment.To_Bank_Account__c = fuel.bankAccount.id ;

		interCoPayment.To_Company__c = fuel.company.Id;

		interCoPayment.finalized_date__c = reconcileAsOfDate;
		//interCoPayment.Supplier__c = fuel.supplier.Id;
		interCoPayment.Reference_Number__c  = '1234';
		interCoPayment.Currency__c = fuel.currencyUSD.id;
		insert interCoPayment;

		Payment_Line__c  payment1 = new Payment_Line__c();
		payment1.type__c = 'Payment';
		// payment1.Supplier_Invoice__c = supplierInvList[0].id;
		payment1.Payment__c = interCoPayment.id;
		//  payment1.Currency__c = TestFuel.currencyUSD.id;
		payment1.Amount__c = 100;
		insert payment1;

		interCoPayment.Finalized__c = true;
		update interCoPayment;

		//system.debug('interCoPayment '+[select id, Payment_Amount__c, Bank_Account__c from Supplier_Payment__c where Id = :interCoPayment.Id limit 1]);

		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Payment__c = interCoPayment.id, Status__c = 'Active', Transaction_Type__c = 'Std');
		insert ae;
		system.debug('ae '+[select id, Has_Exceptions__c, Status__c from Accounting_Entry__c where Id = :ae.Id limit 1]);

		SchemaUtil util = SchemaUtil.getInstance();
		String query = util.generateQueryFromFieldSet('Payment__c', new set<String>{}, new set<String>(BankReconciliationService.getIntercoInTransitFields()),
				BankReconciliationService.getIntercoReceiptsInTransit(reconcileAsOfDate.addMinutes(1), ba.Id, fuel.company.Id, ba.opening_balance_date__c));

		list<Payment__c> lPayments = Database.query(query);
		system.assertEquals(1, lPayments.size()); //NO Transactions associated

		Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c = interCoPayment.Transaction_Date__c ,
				Bank_Account__c = fuel.bankAccount.Id);
		insert bt;
		Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Payment__c = interCoPayment.Id, Amount__c = 100);
		insert btm;

		lPayments = Database.query(query);
		system.assertEquals(1, lPayments.size()); //Transaction matched against CR, but not approved

		BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
		lPayments = Database.query(query);
		system.assertEquals(0, lPayments.size());//Transaction matched against CR, and approved

		dateTime reconciledDate = system.now();
		BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.id}, reconciledDate, fuel.bankAccount.id);
		lPayments = Database.query(query);
		system.assertEquals(0, lPayments.size());//Transaction matched against CR,  approved and reconciled!




	}

	static testMethod void InterCoReceiptInTransit_BTAheadOfReconcileDate() {
		list<Configuration__c> lConfigs = new list<Configuration__c>();
		lConfigs.add(new Configuration__c(Name = 'Payment__c-'+Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));
		lConfigs.add(new Configuration__c(Name = 'Payment_Line__c-'+Payment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry__c-'+Accounting_Entry__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));
		lConfigs.add(new Configuration__c(Name = 'Accounting_Entry_Line__c-'+Accounting_Entry_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserID()));


		insert lConfigs;

		TestFuelQuery fuel = new TestFuelQuery();
		DateTime reconcileAsOfDate = system.now();
		Bank_account__c ba= fuel.bankAccount;
		ba.Opening_balance__C = 100;
		ba.Balance_offset__c=50;
		ba.opening_balance_date__c = reconcileAsOfDate.adddays(-30);
		update ba;

		Payment__c interCoPayment = new Payment__c();
		interCoPayment.Payment_Amount__c = 100;
		interCoPayment.transaction_date__c = reconcileAsOfDate;
		interCoPayment.From_Bank_Account__c = fuel.bankAccount.id ;
		interCoPayment.From_Company__c = fuel.company.Id;

		interCoPayment.To_Bank_Account__c = fuel.bankAccount.id ;

		interCoPayment.To_Company__c = fuel.company.Id;

		interCoPayment.finalized_date__c = reconcileAsOfDate;
		//interCoPayment.Supplier__c = fuel.supplier.Id;
		interCoPayment.Reference_Number__c  = '1234';
		interCoPayment.Currency__c = fuel.currencyUSD.id;
		insert interCoPayment;

		Payment_Line__c  payment1 = new Payment_Line__c();
		payment1.type__c = 'Payment';
		// payment1.Supplier_Invoice__c = supplierInvList[0].id;
		payment1.Payment__c = interCoPayment.id;
		//  payment1.Currency__c = TestFuel.currencyUSD.id;
		payment1.Amount__c = 100;
		insert payment1;

		interCoPayment.Finalized__c = true;
		update interCoPayment;

		//system.debug('interCoPayment '+[select id, Payment_Amount__c, Bank_Account__c from Supplier_Payment__c where Id = :interCoPayment.Id limit 1]);

		Accounting_Entry__c ae = new Accounting_Entry__c (Company__c = fuel.company.Id, name = 'hello', Payment__c = interCoPayment.id, Status__c = 'Active', Transaction_Type__c = 'Std');
		insert ae;
		system.debug('ae '+[select id, Has_Exceptions__c, Status__c from Accounting_Entry__c where Id = :ae.Id limit 1]);

		SchemaUtil util = SchemaUtil.getInstance();
		String query = util.generateQueryFromFieldSet('Payment__c', new set<String>{}, new set<String>(BankReconciliationService.getIntercoInTransitFields()),
				BankReconciliationService.getIntercoReceiptsInTransit(reconcileAsOfDate.addMinutes(1), ba.Id, fuel.company.Id, ba.opening_balance_date__c));

		list<Payment__c> lPayments = Database.query(query);
		system.assertEquals(1, lPayments.size()); //NO Transactions associated

		Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 10000, Transaction_Date__c = reconcileAsOfDate.addDays(10) ,
				Bank_Account__c = fuel.bankAccount.Id);
		insert bt;
		Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Payment__c = interCoPayment.Id, Amount__c = 10000);
		insert btm;

		lPayments = Database.query(query);
		system.assertEquals(1, lPayments.size()); //Transaction matched against CR, but not approved

		BankTransactionService.approvedMatchedBankTransaction(new list<Bank_Transaction__c>{bt});
		lPayments = Database.query(query);
		system.assertEquals(1, lPayments.size());//Transaction matched against CR, and approved

		dateTime reconciledDate = system.now();
		BankReconciliationService.updateBankTransactionsAsReconciled(new list<String>{bt.id}, reconciledDate, fuel.bankAccount.id);
		lPayments = Database.query(query);
		system.assertEquals(1, lPayments.size());//Transaction matched against CR,  approved and reconciled!




	}
}
