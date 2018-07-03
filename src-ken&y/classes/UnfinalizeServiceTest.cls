@isTest
private class UnfinalizeServiceTest {
	
	static testMethod void unfinalizeNOAE() {
    	
        TestFuel fuel = new TestFuel();
        List<Period__c> periods = fuel.periodList;
        Period__c currOpenPeriod;
        DateTime currDt = system.now();
        for(Period__c p : periods){
        	if(p.Open__c && p.period_start__c <= currDt && p.period_end__c > currDt){
        		currOpenPeriod = p;
        		break;
        	}
        }
        
		Customer_Invoice__c ci = new Customer_Invoice__c();
        ci.Company__c = fuel.company.id;
        ci.Bill_To_Customer__c = fuel.customerBillTo.id;
        ci.Date_Invoiced__c = currOpenPeriod.period_start__c.addDays(1);
        ci.Transaction_Date__c = currOpenPeriod.period_start__c.addDays(1);
        ci.status__c = 'Open';
        ci.Subtotal__c = 0;
        ci.Currency__c = TestFuel.currencyUSD.id;
        ci.Invoice_Type__c = 'Manual';
        ci.historical__c = false;
        
        insert ci;
        
        Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
        cil.Quantity_Shipped__c = 5;
        cil.Unit_Price__c = 10;
        cil.Product__c = fuel.product.id; 
        cil.Discount_Percent__c = 0;
        cil.Customer_Invoice__c = ci.Id; 
        insert cil;
        
        ci.Finalized_Date__c = currOpenPeriod.period_start__c.addDays(1);
        ci.Finalized__c = true;
        update ci;
        
        test.startTest();
        	List<Accounting_Entry__c> aes = [SELECT Id FROM Accounting_Entry__c WHERE Customer_Invoice__c = :ci.Id];
        	system.assertEquals(0, aes.size(), 'There should not be accounting entries for the source docs: ' + aes);
        	Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{ci});
        	system.assert(mResponses.containsKey(ci.Id), 'The response map should hold the source doc id');
        	system.assertEquals(true, mResponses.get(ci.Id).Success, 'This source doc should be unfinalized: ' + mResponses.get(ci.Id));
        	aes = [SELECT Id FROM Accounting_Entry__c WHERE Customer_Invoice__c = :ci.Id];
        	system.assertEquals(0, aes.size(), 'There should not be accounting entries for the source docs: ' + aes);
        test.stopTest();
    }
    
    static testMethod void unfinalizePriorToSLC() {
    	
        TestFuel fuel = new TestFuel();
        //TestData.Accounting acctData = new TestData.Accounting(fuel.company.Id);
        List<Accounting_Rule__c> ciAccountingRuleList = fuel.ciAccountingRuleList;
        List<Period__c> periods = fuel.periodList;
        Period__c currOpenPeriod;
        DateTime currDt = system.now();
        for(Period__c p : periods){
        	if(p.Open__c && p.period_start__c <= currDt && p.period_end__c > currDt){
        		currOpenPeriod = p;
        		break;
        	}
        }
        
        //currOpenPeriod.AR_Subledger_Cutoff__c = currOpenPeriod.Period_Start__c.addDays(15);
        //update currOpenPeriod;
        
		Customer_Invoice__c ci = new Customer_Invoice__c();
        ci.Company__c = fuel.company.id;
        ci.Bill_To_Customer__c = fuel.customerBillTo.id;
        ci.Date_Invoiced__c = currOpenPeriod.period_start__c.addDays(1);
        ci.Transaction_Date__c = currOpenPeriod.period_start__c.addDays(1);
        ci.status__c = 'Open';
        ci.Subtotal__c = 0;
        ci.Currency__c = TestFuel.currencyUSD.id;
        ci.Invoice_Type__c = 'Manual';
        
        insert ci;
        
        Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
        cil.Quantity_Shipped__c = 5;
        cil.Unit_Price__c = 10;
        cil.Product__c = fuel.product.id; 
        cil.Discount_Percent__c = 0;
        cil.Customer_Invoice__c = ci.Id; 
        insert cil;
        
        ci.Finalized_Date__c = currOpenPeriod.period_start__c.addDays(1);
        ci.Finalized__c = true;
        update ci;
        
        AccountingService cia = new CustomerInvoiceAccounting();
        cia.execute(new List<sObject>{cil});
        
        UnfinalizeService.currDt = currOpenPeriod.AR_Subledger_Cutoff__c.addDays(-1);
        
        test.startTest();
        	List<Accounting_Entry__c> aes = [SELECT Id, transaction_date__c, finalized_date__c, period__c, Has_Exceptions__c,
        									(SELECT Id, name, GL_Account__c FROM Accounting_Entry_Lines__r) 
        									FROM Accounting_Entry__c WHERE Customer_Invoice__c = :ci.Id];
        	system.assertNotEquals(0, aes.size(), 'There should be accounting entries for the source docs: ' + aes);
        	system.assertEquals(false, aes[0].has_exceptions__c, [SELECT Id, subject FROM Task WHERE whatId = :aes[0].Id] + ' ' +  [SELECT Id, subject FROM Task WHERE whatId IN (SELECT Id FROM Accounting_Entry_Line__c WHERE Accounting_Entry__c = :aes[0].Id)]);
        	Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{ci});
        	system.assert(mResponses.containsKey(ci.Id), 'The response map should hold the source doc id');
        	system.assertEquals(true, mResponses.get(ci.Id).Success, 'This source doc should be unfinalized: ' + mResponses.get(ci.Id));
        	aes = [SELECT Id FROM Accounting_Entry__c WHERE Customer_Invoice__c = :ci.Id AND Status__c = 'Obsolete'];
        	system.assertEquals(1, aes.size(), 'There should not be accounting entries for the source docs: ' + aes);
        test.stopTest();
    }
    
    static testMethod void unfinalizePriorToSLCWithExceptions() {
    	
        TestFuel fuel = new TestFuel();
        List<Period__c> periods = fuel.periodList;
        Period__c currOpenPeriod;
        DateTime currDt = system.now();
        for(Period__c p : periods){
        	if(p.Open__c && p.period_start__c <= currDt && p.period_end__c > currDt){
        		currOpenPeriod = p;
        		break;
        	}
        }
        
        //currOpenPeriod.AR_Subledger_Cutoff__c = currOpenPeriod.Period_Start__c.addDays(15);
        //update currOpenPeriod;
        
		Customer_Invoice__c ci = new Customer_Invoice__c();
        ci.Company__c = fuel.company.id;
        ci.Bill_To_Customer__c = fuel.customerBillTo.id;
        ci.Date_Invoiced__c = currOpenPeriod.period_start__c.addDays(1);
        ci.Transaction_Date__c = currOpenPeriod.period_start__c.addDays(1);
        ci.status__c = 'Open';
        ci.Subtotal__c = 0;
        ci.Currency__c = TestFuel.currencyUSD.id;
        ci.Invoice_Type__c = 'Manual';
        
        insert ci;
        
        Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
        cil.Quantity_Shipped__c = 5;
        cil.Unit_Price__c = 10;
        cil.Product__c = fuel.product.id; 
        cil.Discount_Percent__c = 0;
        cil.Customer_Invoice__c = ci.Id; 
        insert cil;
        
        ci.Finalized_Date__c = currOpenPeriod.period_start__c.addDays(1);
        ci.Finalized__c = true;
        update ci;
        
        AccountingService cia = new CustomerInvoiceAccounting();
        cia.execute(new List<sObject>{cil});
        
        UnfinalizeService.currDt = currOpenPeriod.AR_Subledger_Cutoff__c.addDays(-1);
        
        test.startTest();
        	List<Accounting_Entry__c> aes = [SELECT Id, transaction_date__c, finalized_date__c, period__c, Has_Exceptions__c,
        									(SELECT Id, name, GL_Account__c FROM Accounting_Entry_Lines__r) 
        									FROM Accounting_Entry__c WHERE Customer_Invoice__c = :ci.Id];
        	system.assertNotEquals(0, aes.size(), 'There should be accounting entries for the source docs: ' + aes);
        	for(Accounting_Entry_Line__c ael : aes[0].Accounting_Entry_Lines__r){
        		ael.gl_account__c = null;
        	}
        	update aes[0].Accounting_Entry_Lines__r;
        	aes = [SELECT Id, transaction_date__c, finalized_date__c, period__c, Has_Exceptions__c,
					(SELECT Id, name, GL_Account__c FROM Accounting_Entry_Lines__r)
					 FROM Accounting_Entry__c WHERE Id = :aes[0].Id];
			system.assert(aes[0].has_exceptions__c, 'This accounting entry should have exceptions from missing GL Accounts');		 
        	Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{ci});
        	system.assert(mResponses.containsKey(ci.Id), 'The response map should hold the source doc id');
        	system.assertEquals(true, mResponses.get(ci.Id).Success, 'This source doc should be unfinalized: ' + mResponses.get(ci.Id));
        	aes = [SELECT Id FROM Accounting_Entry__c WHERE Customer_Invoice__c = :ci.Id AND Status__c = 'Obsolete'];
        	system.assertEquals(1, aes.size(), 'There should not be accounting entries for the source docs: ' + aes);
        test.stopTest();
    }
    
    static testMethod void unfinalizePastSLC() {
    	
        TestFuel fuel = new TestFuel();
        List<Period__c> periods = fuel.periodList;
        //TestData.Accounting acctData = new TestData.Accounting(fuel.company.Id);
        List<Accounting_Rule__c> ciAccountingRuleList = fuel.ciAccountingRuleList;
        Period__c currOpenPeriod;
        DateTime currDt = system.now();
        for(Period__c p : periods){
        	if(p.Open__c && p.period_start__c <= currDt && p.period_end__c > currDt){
        		currOpenPeriod = p;
        		break;
        	}
        }
        
        //currOpenPeriod.AR_Subledger_Cutoff__c = currOpenPeriod.Period_Start__c.addDays(15);
        //update currOpenPeriod;
        
		Customer_Invoice__c ci = new Customer_Invoice__c();
        ci.Company__c = fuel.company.id;
        ci.Bill_To_Customer__c = fuel.customerBillTo.id;
        ci.Date_Invoiced__c = currOpenPeriod.period_start__c.addDays(1);
        ci.Transaction_Date__c = currOpenPeriod.period_start__c.addDays(1);
        ci.status__c = 'Open';
        ci.Subtotal__c = 0;
        ci.Currency__c = TestFuel.currencyUSD.id;
        ci.Invoice_Type__c = 'Manual';
        
        insert ci;
        
        Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
        cil.Quantity_Shipped__c = 5;
        cil.Unit_Price__c = 10;
        cil.Product__c = fuel.product.id; 
        cil.Discount_Percent__c = 0;
        cil.Customer_Invoice__c = ci.Id; 
        insert cil;
        
        ci.Finalized_Date__c = currOpenPeriod.period_start__c.addDays(1);
        ci.Finalized__c = true;
        update ci;
        
        AccountingService cia = new CustomerInvoiceAccounting();
        cia.execute(new List<sObject>{cil});
        
        //Fast forward past the SLC
        UnfinalizeService.currDt = currOpenPeriod.AR_Subledger_Cutoff__c.addDays(1);
        
        test.startTest();
        	List<Accounting_Entry__c> aes = [SELECT Id, transaction_date__c, finalized_date__c,period__r.Id, Has_Exceptions__c FROM Accounting_Entry__c WHERE Customer_Invoice__c = :ci.Id ];
        	Period__c p  = aes[0].period__r;
        	p.AR_Subledger_Closed__c = system.now();
    		PeriodService.systemEditable.add(p.Id);
        	update p;
        	system.assertNotEquals(0, aes.size(), 'There should be accounting entries for the source docs: ' + aes + ' - ' + currOpenPeriod);
			system.assertEquals(false, aes[0].has_exceptions__c, [SELECT Id, subject FROM Task WHERE whatId = :aes[0].Id] + ' ' +  [SELECT Id, subject FROM Task WHERE whatId IN (SELECT Id FROM Accounting_Entry_Line__c WHERE Accounting_Entry__c = :aes[0].Id)]);
        	try{
        		Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{ci});
        	}Catch(exception e){
        		system.assert(e.getMessage() != null, e.getMessage() + '    ' + 'This source doc should not be unfinalized: ');
        	        	
        	}
   //     	system.assertEquals(false, mResponses.get(ci.Id).Success, 'This source doc should not be unfinalized: ' + mResponses.get(ci.Id) +' - ' + aes + ' - ' + currOpenPeriod);
        	aes = [SELECT Id, transaction_date__c, finalized_date__c, period__c FROM Accounting_Entry__c WHERE Customer_Invoice__c = :ci.Id and status__c = 'Obsolete'];
        	system.assertEquals(0, aes.size(), 'There should still be accounting entries for the source docs: ' + aes);
        test.stopTest();
    }
    
    static testMethod void unfinalizePastSLCWithExceptions() {
    	
        TestFuel fuel = new TestFuel();
        List<Period__c> periods = fuel.periodList;
        Period__c currOpenPeriod;
        DateTime currDt = system.now();
        for(Period__c p : periods){
        	if(p.Open__c && p.period_start__c <= currDt && p.period_end__c > currDt){
        		currOpenPeriod = p;
        		break;
        	}
        }
        
        //currOpenPeriod.AR_Subledger_Cutoff__c = currOpenPeriod.Period_Start__c.addDays(15);
        //update currOpenPeriod;
        
		Customer_Invoice__c ci = new Customer_Invoice__c();
        ci.Company__c = fuel.company.id;
        ci.Bill_To_Customer__c = fuel.customerBillTo.id;
        ci.Date_Invoiced__c = currOpenPeriod.period_start__c.addDays(1);
        ci.Transaction_Date__c = currOpenPeriod.period_start__c.addDays(1);
        ci.status__c = 'Open';
        ci.Subtotal__c = 0;
        ci.Currency__c = TestFuel.currencyUSD.id;
        ci.Invoice_Type__c = 'Manual';
        
        insert ci;
        
        Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
        cil.Quantity_Shipped__c = 5;
        cil.Unit_Price__c = 10;
        cil.Product__c = fuel.product.id; 
        cil.Discount_Percent__c = 0;
        cil.Customer_Invoice__c = ci.Id; 
        insert cil;
        
        ci.Finalized_Date__c = currOpenPeriod.period_start__c.addDays(1);
        ci.Finalized__c = true;
        update ci;
        
        AccountingService cia = new CustomerInvoiceAccounting();
        cia.execute(new List<sObject>{cil});
        
        //Fast forward past the SLC
        UnfinalizeService.currDt = currOpenPeriod.AR_Subledger_Cutoff__c.addDays(1);
        
        test.startTest();
        	List<Accounting_Entry__c> aes = [SELECT Id, transaction_date__c, finalized_date__c, period__c, Has_Exceptions__c,
        									(SELECT Id, name, GL_Account__c FROM Accounting_Entry_Lines__r)
        									 FROM Accounting_Entry__c WHERE Customer_Invoice__c = :ci.Id];
        	system.assertNotEquals(0, aes.size(), 'There should be accounting entries for the source docs: ' + aes + ' - ' + currOpenPeriod);
        	for(Accounting_Entry_Line__c ael : aes[0].Accounting_Entry_Lines__r){
        		ael.gl_account__c = null;
        	}
        	update aes[0].Accounting_Entry_Lines__r;
        	aes = [SELECT Id, transaction_date__c, finalized_date__c, period__c, Has_Exceptions__c,
					(SELECT Id, name, GL_Account__c FROM Accounting_Entry_Lines__r)
					 FROM Accounting_Entry__c WHERE Id = :aes[0].Id];
			system.assert(aes[0].has_exceptions__c, 'This accounting entry should have exceptions from missing GL Accounts');		 
			 
        	Map<Id, UnfinalizeService.UnfinalizeResponse> mResponses = UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{ci});
        	system.assert(mResponses.containsKey(ci.Id), 'The response map should hold the source doc id');
        	system.assertEquals(true, mResponses.get(ci.Id).Success, 'This source doc should be unfinalized: ' + mResponses.get(ci.Id) +' - ' + aes + ' - ' + currOpenPeriod);
        	aes = [SELECT Id, transaction_date__c, finalized_date__c, period__c FROM Accounting_Entry__c WHERE Customer_Invoice__c = :ci.Id AND Status__c = 'Obsolete'];
        	system.assertEquals(1, aes.size(), 'There should not be accounting entries for the source docs: ' + aes);
        test.stopTest();
    }
	
    static testMethod void unfinalizeAPIPriorToSLC() {
    	
        TestFuel fuel = new TestFuel();
        //TestData.Accounting acctData = new TestData.Accounting(fuel.company.Id);
        List<Accounting_Rule__c>ciAccountingRuleList = fuel.ciAccountingRuleList;
        List<Period__c> periods = fuel.periodList;
        Period__c currOpenPeriod;
        DateTime currDt = system.now();
        for(Period__c p : periods){
        	if(p.Open__c && p.period_start__c <= currDt && p.period_end__c > currDt){
        		currOpenPeriod = p;
        		break;
        	}
        }
        
        //currOpenPeriod.AR_Subledger_Cutoff__c = currOpenPeriod.Period_Start__c.addDays(15);
        //update currOpenPeriod;
        
		Customer_Invoice__c ci = new Customer_Invoice__c();
        ci.Company__c = fuel.company.id;
        ci.Bill_To_Customer__c = fuel.customerBillTo.id;
        ci.Date_Invoiced__c = currOpenPeriod.period_start__c.addDays(1);
        ci.Transaction_Date__c = currOpenPeriod.period_start__c.addDays(1);
        ci.status__c = 'Open';
        ci.Subtotal__c = 0;
        ci.Currency__c = TestFuel.currencyUSD.id;
        ci.Invoice_Type__c = 'Manual';
        
        insert ci;
        
        Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
        cil.Quantity_Shipped__c = 5;
        cil.Unit_Price__c = 10;
        cil.Product__c = fuel.product.id; 
        cil.Discount_Percent__c = 0;
        cil.Customer_Invoice__c = ci.Id; 
        insert cil;
        
        ci.Finalized_Date__c = currOpenPeriod.period_start__c.addDays(1);
        ci.Finalized__c = true;
        update ci;
        
        AccountingService cia = new CustomerInvoiceAccounting();
        cia.execute(new List<sObject>{cil});
        
        UnfinalizeService.currDt = currOpenPeriod.AR_Subledger_Cutoff__c.addDays(-1);
        
        test.startTest();
        	List<Accounting_Entry__c> aes = [SELECT Id, transaction_date__c, finalized_date__c, period__c, Has_Exceptions__c,
        									(SELECT Id, name, GL_Account__c FROM Accounting_Entry_Lines__r) 
        									FROM Accounting_Entry__c WHERE Customer_Invoice__c = :ci.Id];
        	system.assertNotEquals(0, aes.size(), 'There should be accounting entries for the source docs: ' + aes);
        	system.assertEquals(false, aes[0].has_exceptions__c, [SELECT Id, subject FROM Task WHERE whatId = :aes[0].Id] + ' ' +  [SELECT Id, subject FROM Task WHERE whatId IN (SELECT Id FROM Accounting_Entry_Line__c WHERE Accounting_Entry__c = :aes[0].Id)]);
        	Map<Id, AccountingAPI.UnfinalizeResponse> mResponses = AccountingAPI.unfinalizeSourceDocs(new List<sObject>{ci});
        	system.assert(mResponses.containsKey(ci.Id), 'The response map should hold the source doc id');
        	system.assertEquals(true, mResponses.get(ci.Id).Success, 'This source doc should be unfinalized: ' + mResponses.get(ci.Id));
        	aes = [SELECT Id FROM Accounting_Entry__c WHERE Customer_Invoice__c = :ci.Id AND Status__c = 'Obsolete'];
        	system.assertEquals(1, aes.size(), 'There should not be accounting entries for the source docs: ' + aes);
        test.stopTest();
    }
	
    static testMethod void testInvoiceunFinalizeinOpenSubledgers(){
    	Testfuel fuel = new Testfuel();
    	
    	Invoice__c inv = fuel.intercompanyInvestmentInvoice;
    	String str;
    	Boolean sawException = false;
    	
    	List<Period__c> periodList = fuel.periodList;
    	system.assert(fuel.altCompanyPeriodList != null);
    	
		inv.Finalized__c = true;
		update inv;
    	
    	Period__c p;
        
        for(Period__c thisPeriod : periodList){
        	if(thisPeriod.open__c){
        		p = thisPeriod;
        		break;
        	}
        }
        
    	inv = [Select id, Name, Finalized__c, Posting_Date__c, Transaction_date__c, (Select id, Name, Invoice__c from Invoice_Lines__r) from Invoice__c where id = :inv.id];
    	
 		AccountingService invAccounting = new InvoiceAccounting();
        invAccounting.execute(new List<sObject>{inv.Invoice_Lines__r});
    	
    	inv = [Select id, Name, Finalized__c, Posting_Date__c, Transaction_date__c, (Select id, Name, Status__c, has_Exceptions__c from Accounting_Entries__r) from Invoice__c where id = :inv.id];
    	
    	system.assert(inv.Finalized__c = true,'Expected to have invoice finalized');
    	system.assert(inv.Transaction_date__c == inv.Posting_Date__c,'Expected to have TD = PD');
    	system.assert(inv.Accounting_Entries__r.size() == 2,'Expected to have 2 AEs created for an intercompany invoice');
    	for(Accounting_Entry__c ae: inv.Accounting_Entries__r){
    		system.assert(ae.status__c == 'Active');
    	}
    	Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', inv.id );
		SourceDocumentUnfinalize srcDocUnfinalizeExt = new SourceDocumentUnfinalize();
		srcDocUnfinalizeExt.unfinalizeSourceDoc();
		srcDocUnfinalizeExt.unfinalize();
    	
    	inv = [Select id, Name, Finalized__c, Posting_Date__c, Transaction_date__c, Finalized_Date__c, (Select id, Name, Status__c, has_Exceptions__c from Accounting_Entries__r) from Invoice__c where id = :inv.id];
    	
    	system.assert(inv.Finalized__c == false,'Expected to have unfinalize invoice ');
    	system.assert(inv.Finalized_Date__c == null ,'Expected to have FD set to null');
    	system.assert(inv.Posting_Date__c == null ,'Expected to have PD set to null');
    	system.assert(inv.Accounting_Entries__r.size() == 2,'Expected to have 2 AEs created for an intercompany invoice');
    	for(Accounting_Entry__c ae: inv.Accounting_Entries__r){
    		system.assert(ae.status__c == 'Obsolete');
    	}
    	
    }
    
    static testMethod void testInvoiceunFinalizeinclosedSubledger(){
    	Testfuel fuel = new Testfuel();
    	
    	Invoice__c inv = fuel.intercompanyInvestmentInvoice;
    	String str;
    	Boolean sawException = false;
    	
    	List<Period__c> periodList = fuel.periodList;
    	List<Period__c> altperiodList = fuel.altCompanyPeriodList;
    	
    	system.assert(fuel.invoiceRuleList != null);
    	
		inv.Finalized__c = true;
		update inv;
    	
    	Period__c p, altp;
        
        for(Period__c thisPeriod : periodList){
        	if(thisPeriod.open__c){
        		p = thisPeriod;
        		break;
        	}
        }
        
        for(Period__c thisPeriod : altperiodList){
        	if(thisPeriod.open__c){
        		altp = thisPeriod;
        		break;
        	}
        }
        
    	inv = [Select id, Name, Finalized__c, Posting_Date__c, Transaction_date__c, (Select id, Name, Invoice__c from Invoice_Lines__r) from Invoice__c where id = :inv.id];
    	
 		AccountingService invAccounting = new InvoiceAccounting();
        invAccounting.execute(new List<sObject>{inv.Invoice_Lines__r});
    	
    	inv = [Select id, Name, Finalized__c, Posting_Date__c, Transaction_date__c, (Select id, Name, Status__c, has_Exceptions__c, Line_Exceptions__c from Accounting_Entries__r) from Invoice__c where id = :inv.id];
    	
    	system.assert(inv.Finalized__c = true,'Expected to have invoice finalized');
    	system.assert(inv.Transaction_date__c == inv.Posting_Date__c,'Expected to have TD = PD');
    	system.assert(inv.Accounting_Entries__r.size() == 2,'Expected to have 2 AEs created for an intercompany invoice'+inv.Accounting_Entries__r);
    	
    	List<Accounting_Entry_Line__c> aels = [Select id, Name, Accounting_entry__c, Accounting_entry__r.Period__c, Accounting_Rule__c, amount_cr__c, amount_dr__c, GL_Account__c,
    											Accounting_Entry__r.Transaction_type__c, Subtransaction_type__c, Accounting_Code__c, SCOA_Valid__c, has_exceptions__c, Role__c 
    											from Accounting_Entry_Line__c where Accounting_Entry__c in :inv.Accounting_Entries__r];
    	system.assert(aels.size() == 4,'aels:'+aels);
    	for(Accounting_Entry__c ae: inv.Accounting_Entries__r){
    		system.assert(ae.status__c == 'Active');
    		system.assert(ae.has_exceptions__c == false,'AE:'+AE);
    	}
    	
    	p.intercompany_Subledger_closed__c = system.now();
        PeriodService.systemEditable.add(p.Id);
		update p;
    	
		altp.intercompany_Subledger_closed__c = system.now();
        PeriodService.systemEditable.add(altp.Id);
		update altp;
    	
    	Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', inv.id );
		SourceDocumentUnfinalize srcDocUnfinalizeExt = new SourceDocumentUnfinalize();
		sawException = false;
		str = null;
		try{
			srcDocUnfinalizeExt.unfinalizeSourceDoc();
			srcDocUnfinalizeExt.unfinalize();
		}catch(Exception e){
			sawException = true;
			str = e.getMessage();
		}
		
    	inv = [Select id, Name, Finalized__c, Posting_Date__c, Transaction_date__c, Finalized_Date__c, (Select id, Name, Status__c, has_Exceptions__c, Line_Exceptions__c  from Accounting_Entries__r) from Invoice__c where id = :inv.id];
    	
    	system.assert(inv.Finalized__c == true,'Expected to have invoice not unfinalized');
    	//TODO:Need to check with SK as to reasoning behind below assert is needed.As per KNDY-10399 for interco txn,TD==PD.
        //system.assert(inv.Finalized_Date__c == inv.Posting_Date__c ,'Expected to have PD = FD '+inv.Finalized_Date__c+' '+inv.Posting_Date__c);
        system.assert(inv.Accounting_Entries__r.size() == 2,'Expected to have 2 AEs created for an intercompany invoice');
    	for(Accounting_Entry__c ae: inv.Accounting_Entries__r){
    		system.assert(ae.status__c != 'Obsolete');
    		system.assert(ae.has_exceptions__c == false,'AE:'+AE);
    	}
    	
    	
    }
	
	
    
}