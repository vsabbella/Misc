@isTest 
public with sharing class ProcessScheduleTest {
    // tests for ProcessScheduleExt
	
	static Account account;	
	static Company__c company, company2; 
	static Process_Job__c job;
	static { 
		account = new Account();
        account.name = 'Kenandy';
        account.billingstreet = '303 Twin Dolphin Drive, Suite 500';
       	insert account; 
       	company = new Company__c();
        company.name = 'Kenandy';
        company.Address__c = account.ID;
        company.Comp_Currency__c = TestFuel.currencySGD.id;
        company.Consol_Currency__c = TestFuel.currencyEUR.id;
        company.Stat_Currency__c = TestFuel.currencyGBP.id;
        company.Subs_Currency__c = TestFuel.currencyUSD.id;
        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id; 
        insert company;
       	company2 = new Company__c();
        company2.name = 'Kenandy2';
        company2.Address__c = account.ID;
        company2.Comp_Currency__c = TestFuel.currencySGD.id;
        company2.Consol_Currency__c = TestFuel.currencyEUR.id;
        company2.Stat_Currency__c = TestFuel.currencyGBP.id;
        company2.Subs_Currency__c = TestFuel.currencyUSD.id;
        company2.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;        
        insert company2;
    
        job = new Process_Job__c( name= 'foo' , company__c = company.id, apex_class__c = 'notvalid' );
        insert job;
    }
    
    static testMethod void test_controller() {
        ApexPages.StandardController con = new Apexpages.Standardcontroller( company );
        ProcessScheduleExt ext =new ProcessScheduleExt( con);
        system.assertNotEquals(0,  ext.jobs.size() );
        system.assert( ext.runNow2() == null );
        //system.assert( ext.incrementCounter() == null );
        system.assert( ext.newJob() != null );
        system.assert( ext.abortJob() == null );
        system.assert( ext.getApexJobList() != null );
        Test.startTest();
        ext.newScheduledJob();
        ext.DefaultJobsBuild();
        system.assert( ext.GETscheduledJobs() != null );
        system.assert( [ select id from Process_job__c where company__c = :company.id ].size() > 0 );
        
        // try with a different company
        con = new Apexpages.Standardcontroller( company2 );
        ext =new ProcessScheduleExt( con);
        ext.DefaultJobsBuild();
        Process_Job__c[] jobs = [ select id , active__c from Process_job__c 
                                        where company__c = :company2.id ];
        system.assertEquals(40, jobs.size(), ' expected correct number of jobs');
        for ( Process_Job__c j: jobs ) {
            system.assertEquals(false, j.Active__c,' expected jobs to be inactive');
        }
        
        system.assert( ProcessScheduleExt.getAsyncCount() != null , 'getAsyncCount');
        Test.stopTest();
        
    }
}
