global with sharing class MasterControlProgram  implements Schedulable {

    public static Process_Job__c job { get; set; }

    public void execute(SchedulableContext scMain) {         
		executeNext( );
    }

    private static final string query = ' select id, Queueable_Id__c, ownerid, active__c, un_scheduled__c, namespace__c, frequency__c, interval__c, name,  Batch_Size__c, Description__c, Preferred_Run_Hour__c, Process_Job_next__c, last_run__c, next_run__c, exception__c, company__c, Apex_Class__c, Facility__c, max_records__c   from Process_Job__c  ';
	
    private static SOQLUtil soql {
        get {
            if (soql == null) {
                soql = new SOQLUtil('Process_Job__c');
                soql.addAllCustomFields();
                soql.addField('OwnerId');
            }
            return soql;
        } set;
    }
	
    public  static void executeNext() {     // see if any jobs to run, if so, run exactly one 
        Datetime asap = System.now(); 
        soql.setWhereClause('active__c = true AND un_scheduled__c = false AND (next_run__c = null OR next_run__c < :asap ) order by next_run__c asc limit 1');
        executeNow( Database.query(soql.getQuery()));
        //executeNow( Database.query( query + '   where  active__c = true AND un_scheduled__c = false AND (next_run__c = null OR next_run__c < :asap ) order by next_run__c asc  limit 1 ') );
    }

    public static void executeNow( id jobid ) { // run this one now
    	soql.setWhereClause('id = :jobid limit 1');
        executeNow( Database.query(soql.getQuery()));
        //executeNow( Database.query( query + ' where  id = :jobid  limit 1  ')       );
    }
    
    public static void executeName( string class_name ) { // run the one with this class name, now 
        soql.setWhereClause('Apex_Class__c = :class_name limit 1');
        executeNow( Database.query(soql.getQuery()));
        //executeNow( Database.query( query + ' where  Apex_Class__c = :class_name   limit 1  ')  );
    }
    
    public static void executeMyNext() { 	// run one, but it must be one that the current user owns: my next job
        id uid = UserInfo.getUserId();			// when MCP is running uid will match the owner of the process jobs, so check that
        Datetime asap = System.now(); 
        
        soql.setWhereClause('ownerId = :uid AND active__c = true AND un_scheduled__c = false AND (next_run__c = null OR next_run__c < :asap ) order by next_run__c asc  limit 1');
        list<Process_Job__c> jobquery = Database.query(soql.getQuery());
        /*list<Process_Job__c> jobquery = Database.query( query + '   where  ownerId = :uid AND '+
								'  active__c = true AND un_scheduled__c = false AND (next_run__c = null OR next_run__c < :asap ) order by next_run__c asc  limit 1 ');*/
	    if ( jobquery.size() > 0 ) { 
	    		MasterControlProgram.chatterDebug( 2, 'finishedBatch will executeNow()  as:'+ uid);			    
			executeNow( jobquery );
	    } else { 
	    		MasterControlProgram.chatterDebug( 2, 'finishedBatch no additional jobs found for user:'+uid);
	    }
    }
    
    /** 
     * main loop to find the class that we can run, and run it
     * some effort is made to identify mis-spelled class names, and catch
     * exceptions from the actual job run
     */
    public static void executeNow( List<Process_Job__c> jobs  ) {
        
        ApplicationReadWriteMode mode = System.getApplicationReadWriteMode();
        if (mode == ApplicationReadWriteMode.READ_ONLY) 
        {
            // KNDY-6903 Do nothing. If DML operaton is attempted in readonly mode,
            // InvalidReadOnlyUserDmlException will be thrown.
            return;
        } 
        
        MasterControlProgram.chatterDebug( 2, 'executeNow :' +String.valueOf(jobs) );
        
        if ( jobs == null || jobs.size() == 0 ) return;
    
        // executeNow only runs one job, the rest are run after this one finishes
        Process_Job__c requestJob = jobs[0];
        Id jobId = requestJob.Id;
        
        // KNDY-6782 requery the job record we are launching so that we can lock it properly
        soql.setWhereClause('id = :jobId limit 1 FOR UPDATE');
        job = Database.query(soql.getQuery());
        //job = Database.query( query + ' where  id = :jobId limit 1  FOR UPDATE ');
        
        // ensure that the job we are looking at has not been processed by another MCP instance
        // since this time is changed after launching a job, detect another MCP instance processing this job.
        if ( requestJob.Next_Run__c != job.Next_Run__c )
            return;  // someone got to this job first, our work is done
        
        if ( job.Active__c != true ) // only run jobs which are ACTIVE 
        	return;  

        MasterControlProgram.chatterDebug( 1, String.valueOf(job) );  
        
        try { 
            //KNDY-7246: change Inspect.forName to forName method in this class
            System.Type typ = forName( job );  	// resolve the class to a type given info in job record
            MasterControlProgram.chatterDebug( 2, String.valueOf(typ) );
			
            if ( typ == null ) throw new RunningException('Class not found >'+ job.Apex_class__c + '<');
                        
            // ready to execute the batch job using the interface method provided
            // see if this class implements Process.Runnable or Process.Runnable2
            QueueRunBatch queueable = new QueueRunBatch(job);
            
            try { 						// start with Runnable
                queueable.runnable1 = (Process.Runnable)typ.newInstance();
            } catch ( System.TypeException ex) {  // try Runnable2 next
                queueable.runnable2  = (Process.Runnable2)typ.newInstance();                 
            } finally {
                // run this in seperate thread/context so we never fail to update the job time stamps
                job.Queueable_Id__c = System.enqueueJob(queueable);
            }
                            
        } catch ( Exception e ) {
            job.Exception__c = e.getMessage();  
            MasterControlProgram.chatterDebug( 0, 'runBatch exception, job :' +string.valueOf(job));
            Notify.sendEmailBatchFail( job );

        } finally {
            job.Last_Run__c = system.now();
            // KNDY-7367 do not set next run if it's in the future
            if (job.Next_Run__c == null || job.Next_Run__c < job.Last_Run__c) job.Next_Run__c = calcNextRun( job.Last_Run__c );                        
            MasterControlProgram.chatterDebug( 1, 'runBatch completed, job :' +string.valueOf(job));                      
        }
        
        try {    
            DML.updateAsSystem(job);  
            
            if ( ! Test.isRunningTest() ) 
            	Notify.checkFailedAsyncStatus(); 	// report any status errors we see in the async table
            
        } catch ( Exception e ) {
            MasterControlProgram.chatterDebug( 0, 'job record update exception, job :' +e.getMessage()+':'+ e.getStackTraceString());
        }
    }
    
    public class QueueRunBatch implements Queueable {
        Process_Job__c queueableJob { get; set; }
        Process.Runnable runnable1 {get; set;}
        Process.Runnable2 runnable2 { get; set;}    
        
        public QueueRunBatch( Process_Job__c  jinit ) { this.queueableJob = jinit; }
        public void execute(QueueableContext context) {   
            try {   
                MasterControlProgram.chatterDebug( 2, String.valueOf(this) );
                if ( runnable1 != null ) runnable1.runBatch( queueableJob.Company__c );
                else if ( runnable2 != null ) runnable2.runBatch( queueableJob );
            } catch ( Exception e ) {
                queueableJob.Exception__c = e.getMessage();  
                queueableJob.Last_Run__c = system.now();
                queueableJob.Next_Run__c = calcNextRun( job.Last_Run__c );
                MasterControlProgram.chatterDebug( 0, 'runBatch exception, job :' +string.valueOf(queueableJob));
                Notify.sendEmailBatchFail( queueableJob );
                DML.updateAsSystem(job); 
            }
        }
    }
    
    public class DateException extends Exception {}
    
	/*** 
	 * take a range spec like 9-12 and return a list of integer
	 * (9,10,11,12)
	 */
    private static list<integer> parseRange( string spec ) { 
		List<integer> range = new List<Integer>();
		//system.debug(LoggingLevel.INFO, spec );
		//
        if ( spec.indexOf(':') > 0 ) return range; // not a range , probably hh:mm 
		if ( spec.indexOf('-') < 0 ) return range; // it's not a range
		
        for ( string h : spec.split('-') ) { 
            try { range.add( integer.valueof( h.trim() ) ); } 
            catch( System.Typeexception tee) { } // toss bad numbers
        }
        range.sort();
        if ( range.size() == 2 ) { // looks like a range
            integer st = range[0];
            integer en = range[1];
            while ( st < en-1 ) { range.add(++st); }             
        }        
        //system.debug(LoggingLevel.INFO, range);
        return range;
    }
    
    /***
     * take a comma sep list of spec ( integer or range )
     * return a list of all the hours this spec includes
     * or an empty list if the string does not represent a range
     */ 
    public static List <integer> parseHours( string spec ) {
        
        List<integer> ret = new List<Integer>();
        if ( String.isBlank(spec) ) return ret; 
        
        for ( string hr : spec.split(',') ) { 
            try { 
                ret.add( integer.valueof( hr.trim() ) );   
            } 
            catch( System.Typeexception te) { 			
                // may be a range like 9-12			
                ret.addAll( parseRange(hr) );
			}
        } 
        ret.sort(); 
        List<integer> returnList = new list<integer>();
        for ( integer hour : ret) {
            if ( hour >= 0 && hour <= 23 ) // sanity check
                returnList.add(hour); 
        }
        // system.debug(LoggingLevel.INFO, returnList);        
        return  returnList;
    }
    
    /***
     * this must never throw an exception, could cause an infinite loop
     * be careful to catch any bad parsing and just set the default time ahead 1 day
     */     
    public static DateTime calcNextRun( DateTime fromwhen ) {
    	//system.debug(LoggingLevel.INFO, fromwhen);
    	
        integer interval = (Integer)job.interval__c; 
        if ( interval == null ) interval = 1;
        if ( interval < 1 ) interval = 1; 
        
        string freq = job.Frequency__c;
        if ( freq== null ) freq = 'day';
        
        if ( fromwhen== null ) fromwhen = system.now(); 
        
        if ( job.un_scheduled__c ) { // dont set a new schedule, remove existing schedule PTM-503 
            job.Next_Run__c = null; 
            job.Interval__c = null;
            job.Frequency__c = null;
            job.Preferred_Run_Hour__c = null;
            return null;
        }
       	
        if ( freq.containsIgnoreCase('quarter hour') ) fromwhen = fromwhen.addMinutes(15 * interval);   // KNDY-6150
        else if ( freq.containsIgnoreCase('hour') ) fromwhen = fromwhen.addHours( interval );  // KNDY-5801 
        else if ( freq.containsIgnoreCase('day') ) fromwhen = fromwhen.addDays( interval );
        else if ( freq.containsIgnoreCase('week') ) fromwhen = fromwhen.addDays( 7* interval );
        else if ( freq.containsIgnoreCase('month') ) fromwhen = fromwhen.addMonths( interval );
    	//system.debug(LoggingLevel.INFO, fromwhen);
                
        set<integer> hours = new set<integer>(); 
        hours.addAll(parseHours( job.Preferred_Run_Hour__c ));
        integer selectedMin = fromwhen.minute();
        
        integer specifiedMin = 0; 

        // support a simple hour:min  KNDY-7096 
        if ( hours.size() == 0 && job.Preferred_Run_Hour__c != null ) {
            if ( job.Preferred_Run_Hour__c.contains(':') ) {
				list<string> hr_min =  job.Preferred_Run_Hour__c.split(':');
                if ( hr_min.size() == 2 ) {
                    integer hour = integer.valueof( hr_min[0] );
                    integer min = integer.valueof( hr_min[1] );
                    if ( hour >= 0 && hour <= 23 )
						hours.add( hour );
                    else 
                        job.Exception__c = 'Invalid Run Hours :'+job.Preferred_Run_Hour__c;
// KNDY-7208 zero minutes is OK                    
                    if ( min >= 0 && min <=59 )
                        specifiedMin = min;                   
                    else 
                        job.Exception__c = 'Invalid Run Hours :'+job.Preferred_Run_Hour__c;
                }
            }
        }
       
        // see if the time we are on currently is in the allowed hours range 
        // if not we move ahead to find an allowable time 
        if ( hours.size() > 0 ) {
            // KNDY-7367 save day because addhours may cross a day and month boundry finding the correct hour
            DateTime holdDate = fromwhen;
            while ( ! hours.contains( fromwhen.hour() )  ) {
                fromwhen = fromwhen.addHours(1);          // walk to next hour
                selectedMin = 0; // since we are walking ahead
            	//system.debug(LoggingLevel.INFO, fromwhen);
            }
            fromwhen = datetime.newInstance(holdDate.year(), holdDate.month(), holdDate.day(), fromwhen.hour(), selectedMin,0);
        }
        
        if ( specifiedMin > 0 ) selectedMin = specifiedMin;

		// finally construct the new run time 
        return datetime.newInstance(fromwhen.year(), fromwhen.month(), fromwhen.day(), fromwhen.hour(), selectedMin,0);
    }
    
    //  filter by company
    public static List<Process_Job__c> getAllJobs(id cid) { 
        // includes INACTIVE jobs so we can display them
        soql.setWhereClause('Company__c = :cid order by Active__c desc, next_run__c asc');
        return Database.query(soql.getQuery());
        //return Database.query( query + ' where Company__c = :cid order by Active__c desc, next_run__c asc ' ); 
    }

	/** 
     * bootstrap a schedule copy of myself ( schedule to run this class in 1 min )
     */ 
    public static void establishScheduled() {  
        
        Configuration__c run4jobs = Configuration__c.getValues('MCPJOBS');
        if ( run4jobs != null ) {
            // with this config, we run 4 at 15 min intervals
            System.schedule('Master Control 1','0 0 * * * ?',new MasterControlProgram());
            System.schedule('Master Control 2','0 15 * * * ?',new MasterControlProgram());
            System.schedule('Master Control 3','0 30 * * * ?',new MasterControlProgram());
            System.schedule('Master Control 4','0 45 * * * ?',new MasterControlProgram());
        } else { 
            integer nextMin =  System.now().minute()+ 1; 
            if ( nextMin > 59) nextMin = 0;
            string cronstr = '0 ' +nextMin + ' * * * ?'; 
            System.schedule( 'Master Control' , cronstr, new MasterControlProgram() );
        }
    }
    
    /*** 
     * This method is used to determine if the batch job is already running
     * we pass in the context info so we can discriminate our own job from 
     * other coppies of the same class
     */    
    public static boolean IsApexClassRunning( object thisClass, Database.BatchableContext info ) {
       	//KNDY-7246: change Inspect.getClassName to getClassName method in this class
        string className = getClassName( thisClass );        
     

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
         soql = new SOQLUtil('AsyncApexJob', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','status','ApexClass.Name'
        });
        string jId =  info.getJobId();
        soql.setWhereClause('status IN(\'Holding\',\'Queued\',\'Preparing\',\'Processing\') AND ApexClass.Name = :className AND id != :jId ');// dont confuse myself with other jobs which share my class name
        soql.setOrderByClause('CreatedDate desc');
        soql.setLimit(1);
        AsyncApexJob[] runningJob = Database.query(soql.getQuery());



        
		// job IS running if it does appear in the async job table with the status listed above
		return runningJob.size() > 0;
    }
    
    /*** 
     * In this convenience function, we will check to see if a job with the same 'apex class' 
     * has already been launched, and if so, we will throw the batch out
     */
    public static void checkAlreadyRunning( object thisClass, Database.BatchableContext info ) {
        if ( IsApexClassRunning(thisClass, info) ) {
            throw new RunningException( 'Batch already running');
        }
    }
    public class RunningException extends Exception {}

	private static boolean nearLimit( integer currently, integer limitToObey ) {
		Decimal nearPercent = 0.95; // 95% of a limit is NEAR enough 
		integer near = Integer.valueof( limitToObey * nearPercent );
		return currently >= near;
	}
	
    /** 
     * called from any batchable to launch the next class in this particular chain
     * fail silently if there is no chain or a problem launching
     */
    global static void finishedBatch( object thisClass ) {
    		// check CPU and Query, heap limits here KNDY-6961
    		if ( nearLimit( Limits.getCpuTime() , Limits.getLimitCpuTime()  )) return; // out of time 
    		if ( nearLimit( Limits.getDMLStatements() , Limits.getLimitDMLStatements()  )) return; // out of dml 
    		if ( nearLimit( Limits.getHeapSize() , Limits.getLimitHeapSize()  )) return; // out of heap 
    		if ( nearLimit( Limits.getQueryRows() , Limits.getLimitQueries()  )) return; // out of queries 
    		
        if (thisClass == null ) return;
        string whichClassFinished = string.valueof( thisClass );
        MasterControlProgram.chatterDebug( 2, 'finishedBatch class :' +whichClassFinished);

        if ( whichClassFinished == null ) return;
        
        try { 
            
            // string.valueof( class_instance) looks like this : >ShipmentAccountingBatch:[operatingCompanyI.....<
            // we need to reduce to just the classname using substringbefore
            whichClassFinished = whichClassFinished.substringBefore(':');
            try {
            	
			    String whereClause = 'Apex_Class__c = :whichClassFinished limit 1';
			    soql.setWhereClause(whereClause);
		        job = Database.query(soql.getQuery());
		        //job =Database.query( query + ' where  Apex_Class__c = :whichClassFinished   limit 1  ');
            } catch( System.QueryException qe ) {
                job = null; // no apex clas found in job table, ok can happen from MRP where job that started is not the same as the class name that finished
            }

            if ( job != null && job.Process_Job_next__c !=null ) {   
                executeNow( job.Process_Job_next__c );          // next job is stored for us as an id, run that 
            }
            else { 
                	// no chained jobs, see if there are any overdue jobs to run, be sure they are owned by running user
				executeMyNext();                	  
            }
            
        } catch( Exception e ) { 
            MasterControlProgram.chatterDebug( 0, 'finishedBatch saw exception '+e.getMessage()+':'+ e.getStackTraceString());
        }
    }
    
    // if the level we specify is greater than the level stored in the config setting
    // then we will print chatter message 
    // if there is no stored level, do not print
    // return true if we did print a message
    public static boolean chatterDebug( integer level, string msg ) {
        Configuration__c configDebugLevel = Configuration__c.getValues('MCPDebug');
        if ( configDebugLevel == null ) return false; 
        if ( configDebugLevel.Value__c == null ) return false;
        
        if ( integer.valueOf(configDebugLevel.Value__c) < level ) {
            //system.debug(LoggingLevel.INFO, configDebugLevel.Value__c + ' < ' + level );
            return false; // do not send debug below the level specified in the config setting
        } else {
            //system.debug(LoggingLevel.INFO, configDebugLevel.Value__c + ' >= ' + level );
        }
        
        if ( integer.valueOf(configDebugLevel.Value__c) > 2 ) { // 3 or greater, include the CPU limit info
            msg = 'Limits={CPU:' + Limits.getCpuTime() + '/'+ Limits.getLimitCpuTime() + '} msg: '+msg;  
        }
        
        if ( Test.isRunningTest() == false ) {
            if ( msg.length() >1000)  msg=msg.substring(0,1000);

            ConnectApi.ChatterFeeds.postFeedElement(
                null,
                UserInfo.getUserId(),
                ConnectApi.FeedElementType.FeedItem,
                'MasterControlProgram debug : ' + msg
            );
        }
        return true;
    }
    
    
    
    
    
	/* 
	 * KNDY-7246 - MCP Queuable threads stuck forever
	 * Per salesforce support, coping these methods from Inspect.cls to this class
	 * so there is no dependency on Inspect.cls which implements database.stateful
	 * 
	 * Utility methods that are handy for inspection and running batches 
	 *
	 */
	 
	// return the actual class that implemented this virtual class
	public static System.Type forName( string classname ) { 
		System.Type typ = Type.forName('', classname );  						// outside the package
		if ( typ == null ) typ = Type.forName( KSE.Namespace, classname ); // in the package
		if ( typ == null ) 
			throw new InspectException( 'System.Type.forName() could not find :'+classname);
		return typ;
	}
	
	public static System.Type forName( Process_Job__c j) {  
		System.Type typ = Type.forName('', j.Apex_Class__c );  						// outside the package
		if ( typ == null ) typ = Type.forName( KSE.Namespace, j.Apex_Class__c ); // in the package
		if ( typ == null ) typ = Type.forName( j.Namespace__c , j.Apex_Class__c ); // specified namespace
		if ( typ == null ) 
			throw new InspectException( 'System.Type.forName() could not find :'+j.Apex_Class__c);
		return typ;
	}
	
	public class InspectException extends Exception {}
	 
	// return the class name of the object passed in
	public static string getClassName( object thisclass ) {
		return string.valueOf(thisClass).substringBefore(':');  // should we do error checking
	}    
    
}