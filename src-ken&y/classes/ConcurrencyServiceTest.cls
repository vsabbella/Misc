@isTest
private class ConcurrencyServiceTest {

    static testMethod void concurrencyTest() {
    	
    	TestData td = new TestData();
    	List<Concurrency_Configuration__c> ccs = new List<Concurrency_Configuration__c>();
    	
        Concurrency_Configuration__c cc = new Concurrency_Configuration__c();
        cc.name = 'PurchaseOrderLinesAddManage';
        cc.time__c = 90;
        cc.object__c = 'Purchase_Order__c';
        cc.user_field__c = 'Edited_By__c';
        cc.Timestamp_Field__c = 'Edited_Time__c';
        ccs.add(cc);
        
        Concurrency_Configuration__c ccIncorrect = new Concurrency_Configuration__c();
        ccIncorrect.name = 'IncorrectConfig';
        ccIncorrect.time__c = 90;
        ccIncorrect.object__c = 'xyz';
        ccIncorrect.user_field__c = '123';
        ccIncorrect.Timestamp_Field__c = 'incorrect config';
        ccs.add(ccIncorrect);
        
        insert ccs;
        
        Map<String,ID> profiles = new Map<String,ID>();
        List<Profile> ps = [select id, name from Profile where name =  'Standard User' or name = 'System Administrator'];
	    for(Profile p : ps){
	    	profiles.put(p.name, p.id);
	    }

        // Create the user to be used in this test. 
        // First make a new user. 
        User standard = new User(alias = 'standt',
        email='standarduser@testorg.com',
        emailencodingkey='UTF-8',
        lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US',
        profileid = profiles.get('Standard User'),
        timezonesidkey='America/Los_Angeles',
        username='standarduser@testorg.com'+System.currentTimeMillis());
        insert standard;
        
        test.startTest();
        	
        	//Check handled exceptions from improper config
        	ConcurrencyService.ConcurrencyDetail cdIncorrect = ConcurrencyService.checkConcurrency('IncorrectConfig', null);
        	system.assert(!cdIncorrect.concurrencyConflict);
        	ConcurrencyService.releaseConcurrency('IncorrectConfig', null);
        	
        	//Validate proper config
        	ConcurrencyService.ConcurrencyDetail cd = ConcurrencyService.checkConcurrency('PurchaseOrderLinesAddManage', td.purchaseOrder.Id);
        	system.assert(!cd.concurrencyConflict);
        	Purchase_Order__c po = [SELECT id, edited_by__c, edited_time__c
        							FROM Purchase_Order__c 
        							WHERE Id = :td.purchaseOrder.Id];
			//Assert the record was captured by the current user
			system.assert(po.edited_by__c != null);
			system.assert(po.edited_time__c != null);
        	
        	ConcurrencyService.releaseConcurrency('PurchaseOrderLinesAddManage', td.purchaseOrder.Id);
        	po = [SELECT id, edited_by__c, edited_time__c
        							FROM Purchase_Order__c 
        							WHERE Id = :td.purchaseOrder.Id];
			//Assert the record was released
			system.assert(po.edited_by__c == null);
			system.assert(po.edited_time__c == null);
			
			//Reclaim state
			cd = ConcurrencyService.checkConcurrency('PurchaseOrderLinesAddManage', td.purchaseOrder.Id);
			
			//Now attempt check concurrency as another user
			system.runAs(standard){
				ConcurrencyService.ConcurrencyDetail cdStd = ConcurrencyService.checkConcurrency('PurchaseOrderLinesAddManage', td.purchaseOrder.Id);
				system.assert(cdStd.concurrencyConflict);
			}
			
        test.stopTest();
    }
}