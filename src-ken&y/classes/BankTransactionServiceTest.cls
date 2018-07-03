@isTest
public class BankTransactionServiceTest {
    
     static testMethod void testBankTransaction() {
		TestFuel fuel = new TestFuel();
        
       Bank_Transaction__c bt = new Bank_Transaction__c(Amount__c = 100, Transaction_Date__c = system.now(), Bank_Account__c = fuel.BankAccount.Id,			
        												Company__c = fuel.Company.Id);
        Test.startTest();
        system.assertEquals(0,[Select Finalized__c from Bank_Transaction_Group__c].size());												
        insert bt;
        bt = [Select Finalized_2__c, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Finalized__c from Bank_Transaction__c where Id =: bt.Id];
        system.assertEquals(true,bt.Finalized_2__c);    
        system.assertNotEquals(null,bt.Bank_Transaction_Group__c);
        system.assertEquals(true, bt.Bank_Transaction_Group__r.Finalized__c); 
        Test.stopTest();
    }
    
    static testMethod void testBTFinalizeUnfinalize() {
		TestFuel fuel = new TestFuel();
        
        Bank_Transaction__c bt = new Bank_Transaction__c(Amount__c = 100, Transaction_Date__c = system.now(), Bank_Account__c = fuel.BankAccount.Id,			
        												Company__c = fuel.Company.Id);
        insert bt;
        bt = [Select Finalized_2__c, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Finalized__c from Bank_Transaction__c where Id =: bt.Id];    
       
        Test.startTest();											
        system.assertEquals(true,bt.Finalized_2__c);    
        system.assertNotEquals(null,bt.Bank_Transaction_Group__c);
        system.assertEquals(true,bt.Bank_Transaction_Group__r.Finalized__c); 
        
        //unfinalize by unchecking Finalize checkbox on BT
        bt.Finalized_2__c = false;
        boolean updated = true;
        try{
        	update bt;
        }catch(exception ex){
        	updated = false;
        	system.assert(ex.getmessage().contains(System.label.Click_Unfinalize));
        }
        bt = [Select Finalized_2__c, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Finalized__c,  
        	  Bank_Transaction_Group__r.Finalized_Date__c
        	  from Bank_Transaction__c where Id =: bt.Id];
        system.assertEquals(false, updated);
        system.assertEquals(true,bt.Finalized_2__c);    
        system.assertEquals(true,bt.Bank_Transaction_Group__r.Finalized__c); 
        system.assertNotEquals(null,bt.Bank_Transaction_Group__r.Finalized_Date__c); 
        
        //unfinalize from button
        Test.setCurrentPage(Page.SourceDocumentUnfinalize);
    	Apexpages.currentPage().getParameters().put('id', bt.Bank_Transaction_Group__c);
    	SourceDocumentUnfinalize srcDocUnfinalizeExt = new SourceDocumentUnfinalize();    
        srcDocUnfinalizeExt.unfinalizeSourceDoc();
        srcDocUnfinalizeExt.unfinalize();
        bt = [Select Finalized_2__c, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Finalized__c,  
        	  Bank_Transaction_Group__r.Finalized_Date__c
        	  from Bank_Transaction__c where Id =: bt.Id];
        system.debug(logginglevel.error,'error--->'+Apexpages.getmessages());
        system.assertEquals(false,bt.Finalized_2__c);    
        system.assertEquals(false,bt.Bank_Transaction_Group__r.Finalized__c); 
        system.assertEquals(null,bt.Bank_Transaction_Group__r.Finalized_Date__c); 
        
        //finalize
        bt.Finalized_2__c = true;
        update bt;
        bt = [Select Finalized_2__c, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Finalized__c,  
        	  Bank_Transaction_Group__r.Finalized_Date__c
        	  from Bank_Transaction__c where Id =: bt.Id];
        system.assertEquals(true,bt.Finalized_2__c); 
        system.assertEquals(true,bt.Bank_Transaction_Group__r.Finalized__c); 
        system.assertNotEquals(null,bt.Bank_Transaction_Group__r.Finalized_Date__c); 
        Test.stopTest();
    }
    
    static testMethod void testUnfinalizedBTDeletion() {
		TestFuel fuel = new TestFuel();
        
        Bank_Transaction__c bt = new Bank_Transaction__c(Amount__c = 100, Transaction_Date__c = system.now(), Bank_Account__c = fuel.BankAccount.Id,			
        												Company__c = fuel.Company.Id);
        insert bt;
        bt = [Select Finalized_2__c, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Finalized__c from Bank_Transaction__c where Id =: bt.Id];    
       
        Test.startTest();											
        system.assertEquals(true,bt.Finalized_2__c);    
        system.assertNotEquals(null,bt.Bank_Transaction_Group__c);
        system.assertEquals(true,bt.Bank_Transaction_Group__r.Finalized__c); 
               
        //unfinalize from button
        Test.setCurrentPage(Page.SourceDocumentUnfinalize);
    	Apexpages.currentPage().getParameters().put('id', bt.Bank_Transaction_Group__c);
    	SourceDocumentUnfinalize srcDocUnfinalizeExt = new SourceDocumentUnfinalize();    
        srcDocUnfinalizeExt.unfinalizeSourceDoc();
        srcDocUnfinalizeExt.unfinalize();
        bt = [Select Finalized_2__c, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Finalized__c,  
        	  Bank_Transaction_Group__r.Finalized_Date__c
        	  from Bank_Transaction__c where Id =: bt.Id];
        system.debug(logginglevel.error,'error--->'+Apexpages.getmessages());
        system.assertEquals(false,bt.Finalized_2__c);    
        system.assertEquals(false,bt.Bank_Transaction_Group__r.Finalized__c); 
        system.assertEquals(null,bt.Bank_Transaction_Group__r.Finalized_Date__c); 
        
        //deleting bank transaction
        Id btgId = bt.Bank_Transaction_Group__c;
        Id btId = bt.Id;
        delete bt;
        system.assertEquals(0,[Select Id from Bank_Transaction__c where Id =:btId].size());    
        system.assertEquals(0,[Select Id from Bank_Transaction_Group__c where Id =:btgId].size()); 
 
        Test.stopTest();
    }
    
    static testMethod void testfinalizedBTDeletion() {
		TestFuel fuel = new TestFuel();
        
        Bank_Transaction__c bt = new Bank_Transaction__c(Amount__c = 100, Transaction_Date__c = system.now(), Bank_Account__c = fuel.BankAccount.Id,			
        												Company__c = fuel.Company.Id);
        insert bt;
        bt = [Select Finalized_2__c, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Finalized__c from Bank_Transaction__c where Id =: bt.Id];    
       
        Test.startTest();											       
        //deleting bank transaction
        Id btgId = bt.Bank_Transaction_Group__c;
        Id btId = bt.Id;
        boolean Isdeleted = true;
        try{ 
        	delete bt;
        }catch(exception ex){
        	Isdeleted = false;
        	system.assert(ex.getmessage().contains(Label.BT_cannot_be_deleted));
        }
        system.assertEquals(false,Isdeleted);
        system.assertEquals(1,[Select Id from Bank_Transaction__c where Id =:btId].size());    
        system.assertEquals(1,[Select Id from Bank_Transaction_Group__c where Id =:btgId].size()); 
 
        Test.stopTest();
    }
    
    static testMethod void testBTtoBTGSync() {
		TestFuel fuel = new TestFuel();
        
        Bank_Transaction__c bt = new Bank_Transaction__c(Amount__c = 100, Transaction_Date__c = system.now(), Bank_Account__c = fuel.BankAccount.Id,			
        												Company__c = fuel.Company.Id);
        insert bt;
        bt = [Select Finalized_2__c, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Finalized__c from Bank_Transaction__c where Id =: bt.Id];    
       
        Test.startTest();											
        system.assertEquals(true,bt.Finalized_2__c);    
        system.assertNotEquals(null,bt.Bank_Transaction_Group__c);
        system.assertEquals(true,bt.Bank_Transaction_Group__r.Finalized__c); 
        
        //unfinalize from button
        Test.setCurrentPage(Page.SourceDocumentUnfinalize);
    	Apexpages.currentPage().getParameters().put('id', bt.Bank_Transaction_Group__c);
    	SourceDocumentUnfinalize srcDocUnfinalizeExt = new SourceDocumentUnfinalize();    
        srcDocUnfinalizeExt.unfinalizeSourceDoc();
        srcDocUnfinalizeExt.unfinalize();
        bt = [Select Finalized_2__c, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Finalized__c,  
        	  Bank_Transaction_Group__r.Finalized_Date__c
        	  from Bank_Transaction__c where Id =: bt.Id];
        system.assertEquals(false,bt.Finalized_2__c);    
        system.assertEquals(false,bt.Bank_Transaction_Group__r.Finalized__c); 
        system.assertEquals(null,bt.Bank_Transaction_Group__r.Finalized_Date__c); 
        
        bt.Transaction_Date__c = system.now().addDays(-2);
        update bt;
        
        bt = [Select Finalized_2__c, Bank_Transaction_Group__c, Bank_Transaction_Group__r.Transaction_Date__c,  
        	  Transaction_Date__c
        	  from Bank_Transaction__c where Id =: bt.Id];
        system.assertEquals(bt.Transaction_Date__c, bt.Bank_Transaction_Group__r.Transaction_Date__c);
        Test.stopTest();
    }
}