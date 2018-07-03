@isTest
public with sharing class MasterControlTest {
    //TestData data = TestData.getInstance();
    static Account account = new Account(); 
    static Company__c company;
    static { 
        account = new Account();
        account.name = 'Kenandy';
        account.billingstreet = '303 Twin Dolphin Drive, Suite 500';
        insert account; 
        company = new Company__c();
        company.name = 'Kenandy';
        company.Address__c = account.ID;
        company.A_Days__c = 30;
        company.B_Days__c = 60;
        company.C_Days__c = 180;
        company.Comp_Currency__c = TestFuel.currencySGD.id;
        company.Consol_Currency__c = TestFuel.currencyEUR.id;
        company.Stat_Currency__c = TestFuel.currencyGBP.id;
        company.Subs_Currency__c = TestFuel.currencyUSD.id;
        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;   
        insert company;
    }
    static testmethod void test_mastercontrol_abnormal() {
        Process_Job__c job = new Process_Job__c( name= 'foo' , company__c = company.id, 
                                            apex_class__c = 'notvalid' 
                                            //, frequency_hours__c=1.0 
                                            );
        insert job;
        MasterControlProgram.executeNext();
        system.assert( job.id != null );
        job = [ select Exception__c from Process_Job__c where id = :job.id limit 1];
        system.assert( job.Exception__c.contains( 'notvalid'),  ' expected exception msg ');
    }
    static testmethod void test_mastercontrol_normal() {  
        
        Process_Job__c job = new Process_Job__c( name= 'foo' , company__c = company.id,
                                            apex_class__c = 'MasterControlTest.changeCompanyName' 
                                            // , frequency_hours__c=1.0 
                                            );
        
        insert job;
        
        Test.startTest(); 
        system.assert( MasterControlProgram.getAllJobs(company.id).size() >0 );
        
        // test a few statics 
        MasterControlProgram.executeNow( job.id );
        
        MasterControlProgram.executeName( 'test' );
        
        MasterControlProgram.establishScheduled();
        
        MasterControlProgram mcp = new MasterControlProgram(); 
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, mcp);
        System.assert( jobid != null);
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,       NextFireTime
                FROM CronTrigger WHERE id = :jobId];        

        System.assertEquals(0, ct.TimesTriggered);              
        Test.stopTest();
        
        // verify job was run
        system.assert( [select name from company__c where id = :company.id ].name.contains('runBatch'),'expected update');                  
    }
    
    static testmethod void test_mastercontrol_normal2() {  
        
        Process_Job__c job = new Process_Job__c( 
            name= 'foo' , company__c = company.id,
            apex_class__c = 'MasterControlTest.changeCompanyName2' 
        );
        
        insert job;
        
        Test.startTest(); 
        system.assert( MasterControlProgram.getAllJobs(company.id).size() >0 );
        
        // test a few statics 
        MasterControlProgram.executeNow( job.id );
        
        MasterControlProgram.executeName( 'test' );
        
        MasterControlProgram.establishScheduled();
        
        MasterControlProgram mcp = new MasterControlProgram(); 
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, mcp);
        System.assert( jobid != null);
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,       NextFireTime
                FROM CronTrigger WHERE id = :jobId];        

        System.assertEquals(0, ct.TimesTriggered);              
        Test.stopTest();
        
        // verify job was run
        system.assert( [select name from company__c where id = :company.id ].name.contains('runBatch'),'expected update');                  
    }
    
    
    // test that a job that has not hit it's time is not run
    static testmethod void test_mastercontrol_waiting_for_time() {  
        Process_Job__c job = new Process_Job__c( name= 'foo' , company__c = company.id, 
                                            apex_class__c = 'MasterControlTest.changeCompanyName'
                                            //frequency__c=1.0 
                                            );
        job.next_run__c = System.now().addDays(1);
        insert job;
        
        Test.startTest(); 
        system.assert( MasterControlProgram.getAllJobs(company.id).size() >0 );

        MasterControlProgram.establishScheduled();
        Test.stopTest(); 
        system.assertEquals( company.name, [select name from Company__c where id = :company.id limit 1].name);  
    
        // call finished batch
        Process_Job__c job2 = new Process_Job__c( name= 'foo2' , company__c = company.id, 
                                            apex_class__c = 'changeCompanyName' 
                                            //, frequency_hours__c=1.0 
                                            );  
        insert job2;
        job.process_job_next__c = job2.id; 
        update job;
        
        MasterControlProgram.finishedBatch( new changeCompanyName()  );
    }
    // test that a job that is marked active== false is time is not run
    static testmethod void test_mastercontrol_active_false() {  
        Process_Job__c job = new Process_Job__c( name= 'foo' , company__c = company.id, 
                                            apex_class__c = 'MasterControlTest.changeCompanyName'
                                            //frequency__c=1.0 
                                            );
        job.next_run__c = System.now().addDays(-1);
        job.Active__c = false; 
        insert job;
        
        Test.startTest(); 
        system.assert( MasterControlProgram.getAllJobs(company.id).size() >0 );

        MasterControlProgram.establishScheduled();
        Test.stopTest(); 
        // see that company name has not changed
        system.assertEquals( company.name, [select name from Company__c where id = :company.id limit 1].name);  
    
        // call finished batch
        Process_Job__c job2 = new Process_Job__c( name= 'foo2' , company__c = company.id, 
                                            apex_class__c = 'changeCompanyName' 
                                            //, frequency_hours__c=1.0 
                                            );  
        insert job2;
        job.process_job_next__c = job2.id; 
        update job;
        
        MasterControlProgram.finishedBatch( new changeCompanyName()  );
    }
    
    static testmethod void test_mastercontrol_exception() {  
        Process_Job__c job = new Process_Job__c( name= 'foo' , company__c = company.id, interval__c = 1, frequency__c = 'hours',
                                            apex_class__c = 'badMasterControlTest.changeCompanyName'                );
        Datetime now = system.now();
        job.next_run__c = now;
        insert job;
        
        Test.startTest(); 
            MasterControlProgram.executeNow( job.id );
        
        Test.stopTest(); 
    
        job = [select exception__c, next_run__c from Process_Job__c where id = :job.id limit 1];
        system.assert( job.Exception__c != null );
        system.assert( job.Next_Run__c != now);
    }
    
    public class changeCompanyName implements Process.Runnable { 
        public void runBatch( id companyid ) {
            system.assert( companyid != null );
            company__c c = [ select id, name from company__c where id = :companyid limit 1];
            c.name= c.name+'updated by runBatch';
            update c;
        }
    }
    
    public class changeCompanyName2 implements Process.Runnable2 { 
        public void runBatch( Process_Job__c job ) {
            system.assert( job.company__c != null );
            company__c c = [ select id, name from company__c where id = :job.company__c limit 1];
            c.name= c.name+'updated by runBatch';
            update c;
        }
    }
    static testmethod void test_mastercontrol_parseHours() {
        DateTime tmpDate = system.now();
        system.assertEquals( new List<integer>{1}, MasterControlProgram.parseHours('1') );
        system.assertEquals( new List<integer>{1,3}, MasterControlProgram.parseHours('1,3') );
        system.assertEquals( new List<integer>{1,4,5}, MasterControlProgram.parseHours('1,4-5') );
        system.assertEquals( new List<integer>{1,2,3}, MasterControlProgram.parseHours('1-3') );
        system.assertEquals( new List<integer>{1,7,8,9}, MasterControlProgram.parseHours('1,7-9') );
        system.assertEquals( new List<integer>{1,22}, MasterControlProgram.parseHours('1,22') );
        system.assertEquals( new List<integer>{1,22,23}, MasterControlProgram.parseHours('22-23,1') );
        system.assertEquals( new List<integer>{1,2,3,4,5}, MasterControlProgram.parseHours('1-5') );
    }

    static testmethod void test_mastercontrol_calcNextRun() {
        DateTime tmpDate = system.now();
        MasterControlProgram.job =new Process_Job__c (interval__c = 1, frequency__c = 'day');
        
        system.assertEquals( tmpDate.addDays(1).day(), 
            MasterControlProgram.calcNextRun( tmpDate ).day() ,' expected tomorrow');
        
        MasterControlProgram.job.Frequency__c = 'week';
        system.assertEquals( tmpDate.addDays(7).day(), 
            MasterControlProgram.calcNextRun( tmpDate ).day() ,' expected next week');
        
        MasterControlProgram.job.Frequency__c = 'month';
        system.assertEquals( tmpDate.addMonths(1).day(), 
            MasterControlProgram.calcNextRun( tmpDate ).day() ,' expected next month');
        
        MasterControlProgram.job.Frequency__c = 'hours';
        system.assertEquals( tmpDate.addMinutes(60).hour(), 
            MasterControlProgram.calcNextRun( tmpDate ).hour() ,' expected one hour');
        
        MasterControlProgram.job.Frequency__c = 'quarter hour';
        system.assertEquals( tmpDate.addMinutes(15).minute(), 
            MasterControlProgram.calcNextRun( tmpDate ).minute() ,' expected 15 min');
                
        
        tmpDate = Datetime.newInstance( tmpDate.date(), Time.newInstance(0,0,0,0) ); // 5AM today
        MasterControlProgram.job.Preferred_Run_Hour__c = '7,11';
        system.assertEquals( 7, MasterControlProgram.calcNextRun( tmpDate ).hour() ,' expected 7 AM');
        
       
        MasterControlProgram.job.Preferred_Run_Hour__c = '10-17';
        system.assertEquals( 10, MasterControlProgram.calcNextRun( tmpDate ).hour() );
         
        MasterControlProgram.job.Un_Scheduled__c = true; 
        system.assertEquals( null, MasterControlProgram.calcNextRun( tmpDate ), 'expected unscheduled to return null' );
        
        // test both frequency AND preferred run hour
        tmpDate = Datetime.newInstance( tmpDate.date(), Time.newInstance(0,0,0,0) ); // 5AM today
        MasterControlProgram.job.Preferred_Run_Hour__c = '10,12';
        MasterControlProgram.job.Un_Scheduled__c = false;
        MasterControlProgram.job.Frequency__c = 'quarter hour';
        MasterControlProgram.job.Interval__c = 1; 
        
        tmpDate  =MasterControlProgram.calcNextRun( tmpDate ); // should be 10 AM        
        system.assertEquals( 10, tmpDate.hour(), 'expected 10 am' );
        system.assertEquals( 0, tmpDate.minute(), 'expected 10:00 am' );
        tmpDate  =MasterControlProgram.calcNextRun( tmpDate );
        system.assertEquals( 10, tmpDate.hour(), 'expected 10 am' );
        system.assertEquals( 15, tmpDate.minute(), 'expected 10:15 am' );
        tmpDate  =MasterControlProgram.calcNextRun( tmpDate );
        system.assertEquals( 10, tmpDate.hour(), 'expected 10 am' );
        system.assertEquals( 30, tmpDate.minute(), 'expected 10:30 am' );   
        tmpDate  =MasterControlProgram.calcNextRun( tmpDate );
        system.assertEquals( 10, tmpDate.hour(), 'expected 10 am' );
        system.assertEquals( 45, tmpDate.minute(), 'expected 10:45 am' );         
        tmpDate  =MasterControlProgram.calcNextRun( tmpDate );
        system.assertEquals( 12, tmpDate.hour(), 'expected 12 am' );
        system.assertEquals( 0, tmpDate.minute(), 'expected 12:00 am' ); 
    
	
        // test for a spec that will run hourly from 9PM to 4AM
        MasterControlProgram.job.Preferred_Run_Hour__c = '21-23,0-4';
        MasterControlProgram.job.Frequency__c = 'hour';
        MasterControlProgram.job.Interval__c = 1;
        tmpDate = Datetime.newInstance( system.today(), Time.newInstance(0,0,0,0).addMinutes(-1) ); // 0 GMT today
		tmpDate = MasterControlProgram.calcNextRun( tmpDate ); system.assertEquals( 0, tmpDate.hour());
		tmpDate = MasterControlProgram.calcNextRun( tmpDate ); system.assertEquals( 1, tmpDate.hour());
		tmpDate = MasterControlProgram.calcNextRun( tmpDate ); system.assertEquals( 2, tmpDate.hour());
		tmpDate = MasterControlProgram.calcNextRun( tmpDate ); system.assertEquals( 3, tmpDate.hour());
		tmpDate = MasterControlProgram.calcNextRun( tmpDate ); system.assertEquals( 4, tmpDate.hour());
		tmpDate = MasterControlProgram.calcNextRun( tmpDate ); system.assertEquals( 21, tmpDate.hour());
		tmpDate = MasterControlProgram.calcNextRun( tmpDate ); system.assertEquals( 22, tmpDate.hour());
		tmpDate = MasterControlProgram.calcNextRun( tmpDate ); system.assertEquals( 23, tmpDate.hour());
		tmpDate = MasterControlProgram.calcNextRun( tmpDate ); system.assertEquals( 0, tmpDate.hour());
        
        // test bad data, in this case we ignore the preferred hours, just use the 
        // frequency interval 
        MasterControlProgram.job.Preferred_Run_Hour__c = 'fff bar gack';
        MasterControlProgram.job.Frequency__c = 'quarter hour';
        MasterControlProgram.job.Interval__c = 1;
        tmpDate = Datetime.newInstance( system.today(), Time.newInstance(0,0,0,0) ); // 0 GMT today
        system.assertEquals( tmpDate.hour(), MasterControlProgram.calcNextRun( tmpDate ).hour());
        system.assertEquals( tmpDate.addMinutes(15), MasterControlProgram.calcNextRun( tmpDate ) );
 
        // another bad data test -1 and 24 should be invalid
        MasterControlProgram.job.Preferred_Run_Hour__c = '-1,25,33,9';
        MasterControlProgram.job.Frequency__c = 'hour';
        MasterControlProgram.job.Interval__c = 1;
        tmpDate = Datetime.newInstance( system.today(), Time.newInstance(0,0,0,0) ); // 0 GMT today
        system.assertEquals( 9, MasterControlProgram.calcNextRun( tmpDate ).hour());
    
        // allow a special hour:min format, but not in any list , just a single
        MasterControlProgram.job.Preferred_Run_Hour__c = '22:30';
        MasterControlProgram.job.Frequency__c = 'day';
        MasterControlProgram.job.Interval__c = 1;
        tmpDate = Datetime.newInstance( system.today(), Time.newInstance(0,0,0,0) ); // 0 GMT today
        system.assertEquals( 22, MasterControlProgram.calcNextRun( tmpDate ).hour());
        system.assertEquals( 30, MasterControlProgram.calcNextRun( tmpDate ).minute());
        
        // check hour:min format, for bad time specs
        MasterControlProgram.job.Preferred_Run_Hour__c = '22:90';
        MasterControlProgram.job.Frequency__c = 'day';
        MasterControlProgram.job.Interval__c = 1; 
        MasterControlProgram.job.Exception__c = null;
        tmpDate = Datetime.newInstance( system.today(), Time.newInstance(0,0,0,0) ); // 0 GMT today        
        MasterControlProgram.calcNextRun( tmpDate );
        system.assertNotEquals( null, MasterControlProgram.job.Exception__c, ' expected an exception for 22:90');

        
        MasterControlProgram.job.Preferred_Run_Hour__c = '22:-1';
        MasterControlProgram.job.Frequency__c = 'day';
        MasterControlProgram.job.Interval__c = 1; 
        MasterControlProgram.job.Exception__c = null;
        tmpDate = Datetime.newInstance( system.today(), Time.newInstance(0,0,0,0) ); // 0 GMT today
        MasterControlProgram.calcNextRun( tmpDate );
        system.assertNotEquals( null, MasterControlProgram.job.Exception__c, ' expected an exception for 22:-1');

        // KNDY-16400: Test edge case for daily runs where preferred hours overrun month boundry
        MasterControlProgram.job.Preferred_Run_Hour__c = '13:59';
        MasterControlProgram.job.Frequency__c = 'day';
        MasterControlProgram.job.Interval__c = 1;
        MasterControlProgram.job.Exception__c = null;
        tmpDate = Datetime.newInstance(2017, 02, 27, 14, 55, 0);
        system.assertEquals(2, MasterControlProgram.calcNextRun( tmpDate ).month());
        system.assertEquals(28, MasterControlProgram.calcNextRun( tmpDate ).day());

        //Test for when it would overrun the year
        MasterControlProgram.job.Preferred_Run_Hour__c = '13:59';
        MasterControlProgram.job.Frequency__c = 'day';
        MasterControlProgram.job.Interval__c = 1;
        MasterControlProgram.job.Exception__c = null;
        tmpDate = Datetime.newInstance(2017, 12, 30, 14, 55, 0);
        system.assertEquals(12, MasterControlProgram.calcNextRun( tmpDate ).month());
        system.assertEquals(31, MasterControlProgram.calcNextRun( tmpDate ).day());
        system.assertEquals(2017, MasterControlProgram.calcNextRun( tmpDate ).year());

        // test that the trigger will prevent bad data from getting into the system
        Process_Job__c pjob = new Process_Job__c();
        pjob.Preferred_Run_Hour__c = '3';        insert pjob;
        pjob.Preferred_Run_Hour__c = '03,04';        update pjob;
        pjob.Preferred_Run_Hour__c = '3,4-5,06,7,11 , 12 , 13-19,3';        update pjob;
        pjob.Preferred_Run_Hour__c = '3:45';        update pjob;
        pjob.Preferred_Run_Hour__c = '09:55';        update pjob;
        system.assert( pjob.id != null );
        
    }
    
    // test debug chatter
    static testmethod void test_mastercontrol_chdebug() {
        system.assert( MasterControlProgram.chatterDebug( 1, 'msg') == false, 'expected no debug' ); 
        Configuration__c c = new Configuration__c();
        c.Name = 'MCPDebug';
        c.Value__c = '1';
        insert c;
        system.assert( MasterControlProgram.chatterDebug( 0, 'msg') == true, 'expected debug' );
        system.assert( MasterControlProgram.chatterDebug( 1, 'msg') == true, 'expected debug' );
        system.assert( MasterControlProgram.chatterDebug( 2, 'msg') == false, 'expected no debug' );
        
        Notify.sendEmailBatchFail( new Process_Job__c( company__c = null, apex_class__c ='foo', exception__c ='bad') );
        Test.startTest();
        Notify.checkFailedAsyncStatus();
        Test.stopTest();
    }
}