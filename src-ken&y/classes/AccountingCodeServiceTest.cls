@isTest
public with sharing class AccountingCodeServiceTest {

	@testSetup static void JournalEntries() {
		Testfuel fuel = new Testfuel();
		Id CompanyId = (fuel.company).id;
		List<Segment_Validation__c> existingSVList = [Select id from Segment_Validation__c];
		if(existingSVList.size() > 0) {
			for(Segment_Validation__c sv: existingSVList){
				sv.active__c = false;
			}			 
			update existingSVList;
		}
		
		Segment_Validation__c sv1;
		List<Segment_Validation__c> svList = new List<Segment_Validation__c>();{
            sv1 = new Segment_Validation__c();
            sv1.segment_1__c = 'Ken*';
            sv1.segment_2__c = '12*';
            sv1.segment_3__c = '*';
            sv1.active__c = true;
            svList.add(sv1);
            insert svList;
            
        }
        system.assert(fuel.periodList != null);
        system.assert(fuel.AccountingRuleList != null);
        List<GL_Account__c> GLList = new List<GL_Account__c>();
        GL_Account__c cashGL = fuel.cashGL;//system.assert(fuel.cashGL != null);
        GL_Account__c GRNIGL=  fuel.GRNIGL;
        GL_Account__c receivablesGL = fuel.receivablesGL ;
        GL_Account__c payablesGL = fuel.payablesGL;
        GLList.add(cashGL);
        GLList.add(GRNIGL);
        GLList.add(receivablesGL);
        GLList.add(payablesGL);
        system.assert(GLList.size() == 4,'GLList:'+GLList);
        
        List<Journal_Entry_Line__c> jeLineList;
		List<Journal_Entry__c> JEList = new List<Journal_Entry__c>();	{
			Journal_Entry__c je1 = new Journal_Entry__c();
			je1.name = 'JE001';
		    je1.Company__c = fuel.company.id;	
		    je1.type__c = 'Manual';   
		    je1.Transaction_Date__c = System.now();  
			je1.Currency__c = TestFuel.currencyUSD.id;
		    JEList.add(je1);
		    
		    insert JEList;    
			
			jeLineList = new List<Journal_Entry_Line__c>();
		    
		    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
		    jeLine1.Journal_Entry__c = JEList[0].id;
			jeLine1.Amount_CR__c = 5;
			jeLine1.Amount_DR__c = 0;
			jeLine1.GL_Account__c = cashGL.id;
		    jeLineList.add(jeLine1); 
		    
		    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
		    jeLine2.Journal_Entry__c = JEList[0].id;
			jeLine2.Amount_CR__c = 0;
			jeLine2.Amount_DR__c = 5;
			jeLine2.GL_Account__c = receivablesGL.id;
		    jeLineList.add(jeLine2); 
	    
		    insert jeLineList;
		    
		    JEList[0].finalized__c = true;
		    update JEList;
		}
	}
	
	
	static testmethod void testaccountingcodegeneration(){
		// run accounting
		//JournalEntries JE = new JournalEntries();
		//List<Segment_Validation__c> svList = [Select id, Name, Segment_1__c, Segment_2__c, Segment_3__c, active__c from Segment_Validation__c];
		//system.assert(svList.size() != 0,'svList:'+svList);
		map<String, GL_Account__c> mGLs = new map <String, GL_Account__c>();
	    List<GL_Account__c> gls = [Select id, Name, GL_Account_Name__c, GL_Account_Number__c from GL_Account__c where GL_Account_Number__c in ('11000','12000','23000','21000')];
	    for(GL_Account__c gl : gls){
	    	mGLs.put(gl.GL_Account_Number__c, gl);
	    }
	    system.assert(mGLS.size() == 4, 'mGLS:'+ mGLs);
	    List<Journal_Entry_Line__c> jelList = [Select id, Name, Journal_Entry__c from Journal_Entry_Line__c];
	    Test.startTest();

	    JournalEntryAccounting jea = new JournalEntryAccounting();
	    jea.execute(jelList);
	    
	    List<Accounting_Entry__c> aeList = [Select id, has_exceptions__c, status__c,
	    										(Select id, Accounting_Code__c, SCOA_Valid__c, has_exceptions__c,
	    											accounting_code__r.gl_account__c 
	    											from Accounting_Entry_Lines__r)
	    											from Accounting_Entry__c
	    											];
	    system.assert(aeList.size() == 1);
	    system.assert(aeList[0].status__c == 'Active','aeList:'+aeList);  
	    
		// Expect to see the accounting code generated and tied to AELs
		// Expect to see the exception on one of the AEL
		for(Accounting_Entry_Line__c ael: aeList[0].Accounting_entry_lines__r){
			system.assert(ael.Accounting_Code__c != null,'ael:'+ael);
			if(ael.accounting_code__r.gl_account__c == mGLs.get('11000').id) {//receivablesGL.id){
				system.assert(ael.has_exceptions__c == true,'ael:'+ael);
			}
		}
		
		// Expect to see the one of the accounting code is valid and other one is not valid
		// Check the valid flag on accounting code and one should be valid and another one invalid
		List<Accounting_Code__c> acctCodes = [Select id, Name, company__c, gl_Account__c, valid__c from Accounting_code__c ];
		
		for(accounting_code__c acctCode: acctCodes){
			if(acctCode.gl_account__c == mGLs.get('11000').id){
				system.assert(acctCode.valid__c == false,'acctCode:'+acctCode);
			}else{
				system.assert(acctCode.valid__c == true,'acctCode:'+acctCode+'====================acctCodes:'+acctCodes);
			}
		}
	
		Test.stopTest();
		
	}
	
	static testmethod void testAccountingCodeValidationBatch(){
		//JournalEntries JE = new JournalEntries();
	    Segment_Validation__c sv2 = new Segment_Validation__c();
        sv2.segment_1__c = 'Ken*';
        sv2.segment_2__c = '11*';
        sv2.segment_3__c = '*';
        sv2.active__c = true;
        insert sv2;
        set<Id> companyIds = new set<Id>();
        Company__c company= [Select id from Company__c LIMIT 1];
        companyIds.add(company.Id);
        List<Accounting_Code__c> acctCodes = [Select id, Name, company__c, gl_Account__c, valid__c from Accounting_code__c ];
        map<String, GL_Account__c> mGLs = new map <String, GL_Account__c>();
	    List<GL_Account__c> gls = [Select id, Name, GL_Account_Name__c, GL_Account_Number__c from GL_Account__c where GL_Account_Number__c in ('11000','12000','23000','21000')];
	    for(GL_Account__c gl : gls){
	    	mGLs.put(gl.GL_Account_Number__c, gl);
	    }
        for(accounting_code__c acctCode: acctCodes){
			if(acctCode.gl_account__c == mGLs.get('11000').id){
				system.assert(acctCode.valid__c == false,'acctCode:'+acctCode);
			}else{
				system.assert(acctCode.valid__c == true,'acctCode:'+acctCode);
			}
		}
		
		// kick off the batch to validate accounting codes
	    Test.startTest();
	    AccountingCodeValidationBatch batch = new AccountingCodeValidationBatch(companyIds);
        database.executebatch(batch);
		test.stopTest();
		
        acctCodes = [Select id, Name, company__c, gl_Account__c, valid__c from Accounting_code__c ];
        
        // Expect to see both the accounting codes validated
        for(accounting_code__c acctCode: acctCodes){
			system.assert(acctCode.valid__c == true,'acctCode:'+acctCode);
			
		}
 
	}
	
	static testmethod void testvalidateSystemFields(){
		boolean sawException = false;
		String exMsg;
		Company__c company= [Select id from Company__c LIMIT 1];
		map<String, GL_Account__c> mGLs = new map <String, GL_Account__c>();
	    List<GL_Account__c> gls = [Select id, Name, GL_Account_Name__c, GL_Account_Number__c from GL_Account__c where GL_Account_Number__c in ('11000','12000','23000','21000')];
	    for(GL_Account__c gl : gls){
	    	mGLs.put(gl.GL_Account_Number__c, gl);
	    }
	    
		Test.startTest();
		
		Accounting_Code__c acctCode1 = new Accounting_Code__c();
		acctCode1.company__c = company.id;
		acctCode1.gl_account__c = mGLs.get('12000').id;
		try{
			insert acctCode1;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		
		exMsg = null;
		sawException = false;
		system.assert(sawException == false,'Not expected to see exception to insert accounting code:'+exMsg);
		
		try{
			acctCode1.last_validated__c = system.now().addDays(1);
			update acctCode1;
		}catch(Exception e){
			exMsg = e.getMessage();
			sawException = true;
		}
		
		system.assert(sawException == true,'Expected to see the exception while updating the accounting code:'+exMsg);
		
		acctCode1 = [Select id, Name, valid__c, company__c, gl_account__c, scoa_key__c, last_validated__c
					from accounting_code__c where id  = :acctCode1.id];
		sawException = false;
		exMsg = null;
		try{
			acctCode1.valid__c = false;
			AccountingCodeService.systemEditable.add(acctCode1.SCOA_Key__c);
			update acctCode1;
		}catch(Exception e){
			sawException = true;
		}
		
		system.assert(sawException == false,'Not expected to see the exception while updating the accounting code when using systemEditable:'+exMsg);
		
		Test.stopTest();
	}
	
	static testmethod void testsegmentValidation(){
		List<Accounting_Code__c> acctCodeList = new List<Accounting_Code__c>();
		
		Company__c company= [Select id from Company__c LIMIT 1];
		map<String, GL_Account__c> mGLs = new map <String, GL_Account__c>();
	    List<GL_Account__c> gls = [Select id, Name, GL_Account_Name__c, GL_Account_Number__c from GL_Account__c where GL_Account_Number__c in ('11000','12000','23000','21000')];
	    for(GL_Account__c gl : gls){
	    	mGLs.put(gl.GL_Account_Number__c, gl);
	    }
	    
		Accounting_Code__c acctCode1 = new Accounting_Code__c();
		acctCode1.company__c = company.id;
		acctCode1.gl_account__c = mGLs.get('12000').id;
		acctCodeList.add(acctCode1);
		Accounting_Code__c acctCode2 = new Accounting_Code__c();
		acctCode2.company__c = company.id;
		acctCode2.gl_account__c = mGLs.get('11000').id;
		acctCodeList.add(acctCode2);
		
		Test.startTest();
			AccountingCodeService.segmentvalidation(acctCodeList);
			insert acctCodeList;
		Test.stopTest();
		
		acctCodeList = [Select id, Name, valid__c, company__c, gl_account__c, scoa_key__c, last_validated__c
					from accounting_code__c where id  in :acctCodeList];
					
		for(accounting_code__c acctCode: acctCodeList){
			if(acctCode.gl_account__c == mGLs.get('11000').id){
				system.assert(acctCode.valid__c == false,'acctCode:'+acctCode);
			}else{
				system.assert(acctCode.valid__c == true,'acctCode:'+acctCode);
			}
		}
		
	}
	
	
	
}