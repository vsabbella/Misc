@isTest
public with sharing class RecurringAccountingEntryGenBatchTest {
	//TODO SK: Deprecate this class when recurring accounting entry functionality is removed
	/*	
	static testMethod void batchTestSuccess() {
		
		TestData t = new TestData();
		
		test.startTest();
		
		set <id> companies = new set<id>();
		
		companies.add( t.company.id );
		
		
		
		//Create accounting entry
		List<Accounting_Entry__c> AEList = new List<Accounting_Entry__c>(); 
		
		Accounting_Entry__c AE = new Accounting_Entry__c();
		AE.Company__c = t.company.id;
		AE.Currency__c = TestFuel.currencyUSD.id;
		AE.GL_Date__c = System.today();
		AE.Reverse_Next_Period__c = true;
		AEList.add(AE);
		
		insert AEList;
		
		
		List<Accounting_Entry_Line__c> AElines = new List<Accounting_Entry_Line__c>();
		
		Accounting_Entry_Line__c AELineCR = new Accounting_Entry_Line__c();
		AELineCR.Accounting_Entry__c = AE.Id;
		AELineCR.Amount_CR__c = 125;
	    AELineCR.GL_Account__c = t.Acctdata.cashGL.id;
	    AELineCR.Transaction_Date__c = system.today();
	    
	    AElines.add(AELineCR);
	    
	    Accounting_Entry_Line__c AELineDR = new Accounting_Entry_Line__c();
	    AELineDR.Accounting_Entry__c = AE.Id;
	    AELineDR.Amount_DR__c = 125;
	    AELineDR.GL_Account__c = t.Acctdata.cashGL.id;
	    AELineDR.Transaction_Date__c = system.today();
		
		AElines.add(AELineDR);
		
		insert AElines;
		
		RecurringAccountingEntryGenerationBatch Obj=new RecurringAccountingEntryGenerationBatch( companies );
        Obj.operatingCompanyIds =companies;
        Id jobId=Database.executebatch(obj,10);
		
		test.stopTest();
		
		Recurring_Accounting_Entry__c rae = [ select id, type__c, created_from__c from Recurring_Accounting_Entry__c where created_from__c =: AE.id ];
		
		system.assert( rae != null );
		system.assert( rae.Type__c == 'Reverse' );
		
		List<Recurring_Accounting_Entry_Line__c> raeLines = [ select id, Amount_CR__c, Amount_DR__c, GL_Account__c from Recurring_Accounting_Entry_Line__c where 
			Recurring_Accounting_Entry__c =: rae.id ];
			
		system.assert( raeLines.size() == 2 );
		
		for( Recurring_Accounting_Entry_Line__c raeLine :  raeLines ){
			
			system.assert( raeLine.Amount_CR__c == 125 || raeLine.Amount_DR__c == 125 );
		}	
	}
	*/
}