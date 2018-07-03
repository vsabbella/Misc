@isTest
public class SegmentValidationServiceTest {
	
	//static TestData td = new TestData();
	static Testfuel td = new Testfuel();
    
    static testMethod void testTrigger(){
        List<Segment_Validation__c> svs = createTestCoreValidationData();
        boolean sawError = false;
        try{
            delete [select id from segment_validation__c];
        }catch(Exception ex){
            sawError = true;
        }
        
        system.assert(sawError);
    }
	
	static testMethod void testCoreComparison(){
		//delete td.acctData.svList;
		List<Segment_Validation__c> svs = createTestCoreValidationData();
		
        List<Segment_Validation__c> deactivateSegVals = [SELECT Id, active__c, segment_1__c, segment_2__c FROM Segment_Validation__c WHERE Id NOT IN :svs];
        for(Segment_Validation__c sv : deactivateSegVals){
            sv.active__c = false;
        }
        
        update deactivateSegVals;

		
		List<SegmentValidationService.SegmentDefinition> segmentDefinitions = new List<SegmentValidationService.SegmentDefinition>();
		SegmentValidationService.SegmentDefinition sd1 = new SegmentValidationService.SegmentDefinition();
		sd1.recordId = '1';
		sd1.segment1 = td.company.name;
		sd1.segment2 = td.cashGL.name;
		segmentDefinitions.add(sd1);
		
		SegmentValidationService.SegmentDefinition sd2 = new SegmentValidationService.SegmentDefinition();
		sd2.recordId = '2';
		sd2.segment1 = td.company.name;
		sd2.segment2 = 'INVALID GL';
		segmentDefinitions.add(sd2);
		
		test.startTest();
			List<SegmentValidationService.SegmentValidationResponse> responses = SegmentValidationService.getInstance().validateSegments(segmentDefinitions);
			system.assert(responses[0].isValid);
        	system.assert(responses[0].recordId == '1', responses[0]);
			system.assert(!responses[1].isValid, responses[1]);
            system.assert(responses[1].recordId == '2', responses[1]);
		test.stopTest();
	}
	
	static testMethod void testAccountingDefaultComparison(){
		
		createBulkValidationData();
		
		List<Accounting_Default__c> ads = new List<Accounting_Default__c>();
		
		for(GL_Account__c gl : td.GLAccountList){
			Accounting_Default__c iAD = new Accounting_Default__c();
			iAD.company__c = td.company.Id;
			iAD.gl_account__c = gl.Id;
			ads.add(iAD);
		}
		
		insert ads;
		
		test.startTest();
			List<SegmentValidationService.SegmentValidationResponse> responses = SegmentValidationService.getInstance().beforeValidateAccountingDefaults(ads);
			for(SegmentValidationService.SegmentValidationResponse svr : responses){
				system.assert(svr.isValid);
			}
		test.stopTest();
		
	}
	
	static testMethod void testAccountingEntryComparison(){
		
		createBulkValidationData();
		
		Accounting_Entry__c ae = new Accounting_Entry__c();
		ae.Company__c = td.company.id;
		//ae.GL_Date__c = system.today();
		ae.Transaction_Date__c = system.now();
		ae.Finalized_Date__c = system.now();
		ae.Currency__c = TestFuel.currencyUSD.id;
		ae.Transaction_Type__c = 'Manual';
		ae.Source_Document_Object_Name__c = 'Manual';
		
		insert ae;
		
		system.debug(LOGGINGLEVEL.INFO+'ae :'+ae);
		system.assertNotEquals (null, ae);
		
		List<Accounting_Entry_Line__c> aeLinesList = new List<Accounting_Entry_Line__c>();
		Accounting_Entry_Line__c iAEL;
	
		for(GL_Account__c gl : td.GLAccountList){
			iAEL = new Accounting_Entry_Line__c();
			iAEL.gl_account__c = gl.Id;
			iAEL.Amount_CR__c = 25;
			iAEL.Accounting_Entry__c = ae.id;
			iAEL.Company__c = ae.Company__c;
			aeLinesList.add(iAEL);
		}
		
		test.startTest();
			system.debug(LOGGINGLEVEL.INFO+'aeLinesList before insert :'+aeLinesList);
			//TODO: Need to determine valid test cases for segment combinations on Accounting Entries
			List<SegmentValidationService.SegmentValidationResponse> responses = SegmentValidationService.getInstance().afterValidateAccountingEntries(aeLinesList);
			for(SegmentValidationService.SegmentValidationResponse svr : responses){
				system.debug('svr :'+svr +' svr.isValid :'+svr.isValid);
				system.assert(svr.isValid);
			}
			
			insert aeLinesList;
		
		system.debug(LOGGINGLEVEL.INFO+'aeLinesList :'+aeLinesList);
		system.assertNotEquals(0,aeLinesList.size());
		system.assertNotEquals(null,aeLinesList.size());
		
		test.stopTest();
	}
	
	
	static List<Segment_Validation__c> createTestCoreValidationData(){
		
		Segment_Validation__c sv1 = new Segment_Validation__c();
		sv1.segment_1__c = td.company.name.left(1) + '*';
		sv1.segment_2__c = td.cashGL.name.left(1) + '*';
		sv1.active__c = true;
		
		insert sv1;
		
        return new List<Segment_Validation__c>{sv1};
		
	}
	
	static void createBulkValidationData(){
		
		List<Segment_Validation__c> svs = new List<Segment_Validation__c>();
		
		for(GL_Account__c gl : td.GLAccountList){
			Segment_Validation__c iSV = new Segment_Validation__c();
			iSV.segment_1__c = td.company.name;//.left(1) + '*';
			iSV.segment_2__c = gl.name;//.left(1) + '*';
			iSV.active__c = true;
			svs.add(iSV);
		}
		
		insert svs;
	}
	
	static testMethod void testdeleteTrigger(){
		Segment_Validation__c sv1 = new Segment_Validation__c();
		sv1.segment_1__c = td.company.name.left(1) + '*';
		sv1.segment_2__c = td.cashGL.name.left(1) + '*';
		sv1.active__c = true;
		
		insert sv1;
		
		system.assert(sv1 != null,'Not expected to have segment validation to be null:'+sv1);
		
		boolean sawException = false;
		String exMsg;
		
		try{
			delete sv1;
		}catch(Exception e){
			sawException = true;
			exMsg = e.getMessage();
		}
		
		system.assert(sawException == true,'Expected to see an exception while deleting a segment validation record:'+ exMsg+'sv1:'+sv1);
	}
}