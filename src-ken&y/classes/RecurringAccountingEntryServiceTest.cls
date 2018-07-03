@isTest
private class RecurringAccountingEntryServiceTest {
	//TODO SK: Deprecate this class when recurring accounting entry functionality is removed
	/*	
	static testMethod void myUnitTest() {
		
		TestDataForFinance testData = new TestDataForFinance();
		
		system.assert( testdata.Acctdata.cashGL.id != null, ' expected valid GL account ');
		
		List<Recurring_Accounting_Entry__c> RAEList = new List<Recurring_Accounting_Entry__c>(); 
		
		Recurring_Accounting_Entry__c RAE = new Recurring_Accounting_Entry__c();
		RAE.Company__c = testData.company.id;
		RAE.Start_Period__c = testData.periodList[0].Id;
		RAE.End_Period__c = testData.periodList[1].Id;
		RAE.Currency__c = TestFuel.currencyUSD.id;
		
		RAEList.add(RAE);
		
		insert RAEList;
		
		List<Recurring_Accounting_Entry_Line__c> lines = new List<Recurring_Accounting_Entry_Line__c>();
		
		Recurring_Accounting_Entry_Line__c RAELineCR = new Recurring_Accounting_Entry_Line__c();
		RAELineCR.Recurring_Accounting_Entry__c = RAE.Id;
		RAELineCR.Amount_CR__c = 125;
	    RAELineCR.GL_Account__c = testData.Acctdata.cashGL.id;
	    RAELineCR.Transaction_Date__c = system.today();
	    
	    lines.add(RAELineCR);
	    
	    Recurring_Accounting_Entry_Line__c RAELineDR = new Recurring_Accounting_Entry_Line__c();
	    RAELineDR.Recurring_Accounting_Entry__c = RAE.Id;
	    RAELineDR.Amount_DR__c = 125;
	    RAELineDR.GL_Account__c = testData.Acctdata.cashGL.id;
	    RAELineDR.Transaction_Date__c = system.today();
		
		lines.add(RAELineDR);
		
		insert lines;
		
		
		//Create accounting entry
		List<Accounting_Entry__c> AEList = new List<Accounting_Entry__c>(); 
		
		Accounting_Entry__c AE = new Accounting_Entry__c();
		AE.Company__c = testData.company.id;
		AE.Transaction_Type__c = 'Manual';
		AE.Currency__c = TestFuel.currencyUSD.id;
		AE.GL_Date__c = System.today();
		
		AEList.add(AE);
		
		insert AEList;
		
		
		List<Accounting_Entry_Line__c> AElines = new List<Accounting_Entry_Line__c>();
		
		Accounting_Entry_Line__c AELineCR = new Accounting_Entry_Line__c();
		AELineCR.Accounting_Entry__c = AE.Id;
		AELineCR.Amount_CR__c = 125;
	    AELineCR.GL_Account__c = testData.Acctdata.cashGL.id;
	    AELineCR.Transaction_Date__c = system.today();
	    
	    AElines.add(AELineCR);
	    
	    Accounting_Entry_Line__c AELineDR = new Accounting_Entry_Line__c();
	    AELineDR.Accounting_Entry__c = AE.Id;
	    AELineDR.Amount_DR__c = 125;
	    AELineDR.GL_Account__c = testData.Acctdata.cashGL.id;
	    AELineDR.Transaction_Date__c = system.today();
		
		AElines.add(AELineDR);
		
		insert AElines;
		
		Test.startTest();
		
		RecurringAccountingEntryService Service = RecurringAccountingEntryService.getInstance();
		
		//New Test for bulk
		List<Accounting_Entry__c> result = Service.createAccountingEntryRecurrences(Service.retriveRecurringAccountingEntries(new Period__c[]{testData.periodList[0]}));
		
		List<Accounting_Entry__c> generatedAccountingEntries = [select Id, (select Id from Accounting_Entry_Lines__r) from Accounting_Entry__c where Recurring_Accounting_Entry__c = :RAE.Id];
		
		System.assertEquals(1,generatedAccountingEntries.size());
		
		System.assertEquals(2,generatedAccountingEntries[0].Accounting_Entry_Lines__r.size());
		
		result = Service.createAccountingEntryRecurrences(Service.retriveRecurringAccountingEntries(new Period__c[]{testData.periodList[0]}));
		
		System.assertEquals(1,generatedAccountingEntries.size());
		
		System.assertEquals(2,generatedAccountingEntries[0].Accounting_Entry_Lines__r.size());
		
		//Test create a recurring accounting entry from accounting entry
		Map<Id,Recurring_Accounting_Entry__c> RAEMap = new Map<Id,Recurring_Accounting_Entry__c>();
		
		RAEMap.put(AE.Id,new Recurring_Accounting_Entry__c());
		
		List<Recurring_Accounting_Entry__c> response = Service.convertToRecurringAccountingEntry(AEList,RAEMap);
		
		Set<Id> AEIds = new Set<Id>();
		
		for(Accounting_Entry__c record:generatedAccountingEntries){
			
			AEIds.add(record.Id);
			
		}
		
		List<Accounting_Entry__c> AERecords = Service.retrieveAccountingEntries(AEIds);
		
		
		//Create an instance of recurring accounting entry extension
		ApexPages.StandardController STDcontroller = new ApexPages.StandardController(AE);
		RecurringAccountingEntryExtension extension = new RecurringAccountingEntryExtension(STDcontroller);
		
		extension.initCreateRecurringAEfromAE();
		
		PageReference resultPage = extension.createRecurringAEfromAE();
		
		System.assertEquals( new PageReference( '/' + String.valueOf(AE.Id).substring(0,15) ).getUrl(), extension.cancel().getUrl() );
		
		//Create an instance of recurring accounting entry extension with the set controller
		ApexPages.StandardsetController STDSETController = new ApexPages.StandardsetController(testData.periodList);
		
		RecurringAccountingEntryExtension extension2 = new RecurringAccountingEntryExtension(STDSETController);
		
		extension2.initGenerateRAE();
		
		extension2.generateRAE();
		
		STDSETController.setSelected(testData.periodList);
		extension2 = new RecurringAccountingEntryExtension(STDSETController);
		
		extension2.initGenerateRAE();
		
		extension2.generateRAE();
		
		//Test list of accounting entries to review
		STDSETController = new ApexPages.StandardsetController(AEList);
		
		RecurringAccountingEntryExtension extension3 = new RecurringAccountingEntryExtension(STDSETController);
		
		extension3.initReview();
		
		STDSETController.setSelected(AEList);
		extension3 = new RecurringAccountingEntryExtension(STDSETController);
		
		extension3.initReview();
		
		ApexPages.currentPage().getParameters().put('retURL','/'+AE.Id);
		
		extension3.AEWrapperList[0].selected = true;
		
		extension3.saveChanges();
		
		extension3.goReview();
		
		//Create accounting entry
		AEList = new List<Accounting_Entry__c>(); 
		
		AE = new Accounting_Entry__c();
		AE.Company__c = testData.company.id;
		AE.Transaction_Type__c = 'Manual';
		AE.Currency__c = TestFuel.currencyUSD.id;
		AE.Exception__c = false;
		AE.Period__c = testData.periodList[0].id;
		AE.GL_Date__c = System.today();
		//insert AE;
		
		AEList.add(AE);
		insert AEList;
		
		
		AElines = new List<Accounting_Entry_Line__c>();
		
		AELineCR = new Accounting_Entry_Line__c();
		AELineCR.Accounting_Entry__c = AE.Id;
		AELineCR.Amount_CR__c = 125;
		AELineCR.Exception__c = false;
	    AELineCR.GL_Account__c = testData.Acctdata.cashGL.id;
	    AELineCR.Transaction_Date__c = system.today();
	    
	    AElines.add(AELineCR);
	    
	    AELineDR = new Accounting_Entry_Line__c();
	    AELineDR.Accounting_Entry__c = AE.Id;
	    AELineDR.Amount_DR__c = 125;
		AELineDR.Exception__c = false;
	    AELineDR.GL_Account__c = testData.Acctdata.cashGL.id;
	    AELineDR.Transaction_Date__c = system.today();
		
		AElines.add(AELineDR);
		
		
		insert AElines;
		
		List<Period__c> periodList = [select id, Name, Adjustment_Period__c, Corporate__c, Fiscal__c, Fiscal_Year__c, Period_End__c,
                            Period_Number__c, Period_Start__c, Primary_key__c, Quarter_Number__c, Year_End_Date__c, Year_Start_Date__c
                            from Period__c where open__c = true];
                            
		AE.Period__c = periodList[0].id;
		update AE;
		
		STDSETController.setSelected(AEList);
		
		RecurringAccountingEntryExtension extension4 = new RecurringAccountingEntryExtension(STDSETController);
		
		extension4.initReview();
		
		//ApexPages.currentPage().getParameters().put('retURL','/'+AE.Id);
		

		
		
		//Test reverse accounting entries
		Accounting_Entry__c AERev = new Accounting_Entry__c();
		AERev.Company__c = testData.company.id;
		AERev.Currency__c = TestFuel.currencyUSD.id;
		AERev.GL_Date__c = System.today();
		AERev.Reverse_Next_Period__c = true;
		
		insert AERev;
		
		List<Accounting_Entry_Line__c> AElinesRev = new List<Accounting_Entry_Line__c>();
		
		Accounting_Entry_Line__c AELineCRRev = new Accounting_Entry_Line__c();
		AELineCRRev.Accounting_Entry__c = AERev.Id;
		AELineCRRev.Amount_CR__c = 125;
	    AELineCRRev.GL_Account__c = testData.Acctdata.cashGL.id;
	    AELineCRRev.Transaction_Date__c = system.today();
	    
	    AElinesRev.add(AELineCRRev);
	    
	    Accounting_Entry_Line__c AELineDRRev = new Accounting_Entry_Line__c();
	    AELineDRRev.Accounting_Entry__c = AERev.Id;
	    AELineDRRev.Amount_DR__c = 125;
	    AELineDRRev.GL_Account__c = testData.Acctdata.cashGL.id;
	    AELineDRRev.Transaction_Date__c = system.today();
		
		AElinesRev.add(AELineDRRev);
		
		insert AElinesRev;
		
		result = Service.createAccountingEntryRecurrences(Service.retriveRecurringAccountingEntries(new Period__c[]{testData.periodList[1]}));

		
	}
*/
}