global with sharing virtual class Inspect implements 
                                Database.Batchable<sObject>,  
                                Process.Runnable,
                                Database.Stateful 
{
    
    global id companyid;
    global string objectName = '';	// each sobject used by this class must have Company__c and Ready__c
    
    global Inspect( string value )  {  
        this.objectName = value.replace( NamespaceUU,'');  
        
        // build a list of all the fields and methods that are needed to automate objectName
        autoList = kse.grep( Process_Automation__c.getAll().values(), 'Object_Name__c',objectName);
        
        // only include Active rows from the automation table
        autoList = kse.grep( autoList, 'Active__c', true );
		
		// sort the list by priority so that each method can be run in customer specified order
        kse.sortList( autoList, 'Priority__c', 'asc' );		
    }
                                
	global Inspect(  ) {  }  
	
    global static String Namespace { get {
        if ( Namespace != null ) return Namespace;


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
SOQLUtil soql = new SOQLUtil('ApexClass', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'NameSpacePrefix'
});
soql.setWhereClause('Name = \'Inspect\'');
soql.setLimit(1);
ApexClass ac = Database.query(soql.getQuery());


        Namespace = ac.NameSpacePrefix != null ? ac.NameSpacePrefix : '';
        return Namespace;
    } private set; }
    global static String NamespaceUU { get { return  Namespace != '' ? Namespace+'__' : '' ;    } }
      
    // this uses Database.Stateful to store info across execute invocations
    private list<Process_Automation__c> autoList = new list<Process_Automation__c>();
    
    private integer totalRecords = 0; 
    
    	global virtual Database.QueryLocator start(Database.BatchableContext BC){
    		string query  = 'select id from ' +objectName + ' where id = null';
    		try { 
    			
                if ( autoList.size() == 0 ) {  
                    // no work (config records) found, skip all work by returning an empty query
                    Notify.chatterOnMe( this, new List<Notify.Message>{ 
                        new Notify.Message( 'start : no active process_automation__c records ', 
                                           ' for objectName '+this.objectName ) } );
                    return Database.getQueryLocator( query ); 
                }
                
                /* 
*  build a query from the info we found in Process_Automation__c
* looks like this when done
* 		select id, Status__c from Sales_Order__c where Status__c =  'Draft' 
* when done
* 
* infact we want to add all the fields from this object so that 
* rows can be processed without more queries ( if the use case allows that ) 
*/ 
                
                query = ' select ' +SchemaUtil.getInstance().getFieldsforQuery (objectName);
                
                id theCid = this.companyid;
                //system.debug(Logginglevel.info, 'company id is ' +this.companyid );
                query += ' from ' + objectName + ' where company__c = :theCid  AND Ready__c = true AND '; 
                
                list<string>whereclauses = new list <string>();
                
                for ( Process_Automation__c p: autoList ) { 
                    whereclauses.add( p.field_name__c + ' =  \'' + p.field_value__c  + '\'' ); 
                } 
                query += ' ( ' + string.join( whereclauses, ' OR ')  + ' ) ';
                
            } catch( Exception  e) {
                // log the exception to Chatter, not sure what would cause this since 
                // we are catching inside callProcessAutomationMethod() also
                query = 'select id from ' +objectName + ' where id = null';  // make up a 0 returning query
                // System.debug(LoggingLevel.INFO, e);
                Notify.chatterOnMe( this, new List<Notify.Message>{ 
                    new Notify.Message( 'start :'+e.getTypeName(), e.getMessage() + e.getStackTraceString() ) } );
            }  
            // start the query & batch  
            //system.debug(Logginglevel.info, query );
            return Database.getQueryLocator(query); 
        }
    
    /* 
    * declaring as virtual allows this to be overridden in a class that extends Inspect
    */
    global virtual void execute(	Database.BatchableContext BC, List<sobject> records ) {
        execute( records );
    }
	
    global virtual void execute ( List<sobject> records ) {
        totalRecords += records.size(); // track the total 
        
        boolean recordsModified = false; 
        
        // delegate the work by passing all records to each worker method, 
        // these will modify records and NOT perform any DML
        for ( Process_Automation__c p : autoList ) {	
            if ( p.Method_DML__c == false ) {
                Process.callAutomationMethod( p, records );
                // if any process looked at these, assume we must perform the update
                recordsModified = true; 	
            }				
        }
        
        /*
		 * perform DML on the above records so that the after code has access to updated data
		 * NOTE: an failed DML here will be caught as an unsuccessful saveresult , then marked as not ready 
		 */
        try {  
            
            list<sobject> recordsAfter = new list<sobject>(); 
            list<sobject> notReady = new list<sobject>(); 
            
            if ( recordsModified ) { 
                
                List<Database.Saveresult> results = DML.updateAsSystem(records, false); // all or none == false
                
                /*  
* failed rows get the ready__c set to false,  good rows proceed to next step
*/
                Schema.sObjectType token = records[0].getSObjectType();
                map<id,sobject> recordsMap = new map<id,sobject>();
                for ( sobject so: records ) { recordsMap.put(so.id, so); }
                
                for ( Database.Saveresult sr : results ) {
                    if ( sr.isSuccess() ) { 
                        
                        recordsAfter.add( recordsMap.get(sr.getId()) );  	// collect the good
                        
                    } else {
                        sobject notrdy = token.newSObject();
                        notrdy.id = sr.getId();
                        notrdy.put('Ready__c',false);
                        notReady.add( notrdy ); 										// flag the bad
                    }
                }
                
                if ( notReady.size() > 0 ) { 	
                    DML.updateAsSystem(notReady);					// update ( uncheck) these so they are not processed again
                } 
                
            } else { 
                // no records were modified, pass all to the after phase
                recordsAfter.addAll( records );
            }
            
            // Next, process after records, which MAY perform queries or DML on the records 
            for ( Process_Automation__c p : autoList ) {	
                if ( p.Method_DML__c == true ) {
                    Process.callAutomationMethod( p, recordsAfter );
                }			
            }	
            
        } catch( Exception  e) {
            // log the exception to Chatter, not sure what would cause this since 
            // we are catching inside callProcessAutomationMethod() also
            // System.debug(LoggingLevel.INFO, e);
            Notify.chatterOnMe( this, new List<Notify.Message>{ 
                new Notify.Message( 'execute :'+e.getTypeName(), e.getMessage() ) } );
        } 
    }
	
    global virtual void finish(Database.BatchableContext info){
        
        /* FUTURE mark each of the rows in autoList with the time they can be run next
        * not implemented at this time, review if frequency / chatter volume is too high
        * datetime nowish = system.now();
        for ( Process_Automation__c p: autoList ) { 
        p.next_run_after__c = nowish.addSeconds((integer)p.latency__c);
        }
        DML.updateAsSystem(autoList);  
        */
        
        List<Notify.Message> messages = new List<Notify.Message>();
        messages.add( new Notify.Message('Methods run ', string.valueof(autoList.size()) ));
        messages.add( new Notify.Message('Records processed ', String.valueof(totalRecords) ) );
        BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( null, messages, info);        
        MasterControlProgram.finishedBatch( this );			
	}
 
	/* 
	 * implementation of Process.Runnable that will work with classes which extend this one
	 */
	global virtual void runBatch( id value ) {
   		
   		try { 
	   		
	   		// get name of the class that extended this one (  Inpsect.cls ) 
	   		string classdetail = getClassName(this);  
	   		if ( classdetail == null )
	   			throw new InspectException( 'Inspect could not get Class Name :'+this);
	   			
	   		//system.debug(Logginglevel.info, 'Inspect.runBatch called from :'+ classdetail );
	   		
	   		// build the actual class that implemented this virtual class
			System.Type typ = Inspect.forName( classdetail );  
			
			Inspect batch = (Inspect)typ.newInstance();
			if ( batch == null )
				throw new InspectException( 'Inspect could not create instance :'+classdetail);
				
			batch.companyid = value; 
			

/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
SOQLUtil soql = new SOQLUtil('Process_Job__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','apex_class__c','batch_size__c','company__c'
});
        id cId = batch.companyId;
        soql.setWhereClause('apex_class__c = :classDetail AND company__c = :cId');
soql.setLimit(1);
List<Process_Job__c> jobs = Database.query(soql.getQuery());


									
		
			/* 
			 * running fewer at a time allows more query / statement limits for the worker
			 */
			 integer batchSize = 25;
			 if(jobs.size() > 0 && jobs[0].batch_size__c != null){
			 	batchSize = (integer)jobs[0].batch_size__c;
			 }
			 
			 Database.executeBatch(batch, batchSize);	
		
   		} catch ( exception e ) {
   			// no action, but we can log this type of failure
   			// System.debug(LoggingLevel.INFO, 'run batch error ' + string.valueof(this) + ' ' + e);
   			
   			Notify.chatterOnMe( this, new List<Notify.Message>{ 
													new Notify.Message('Batch Exception ', e.getMessage() )	});   			
   		}        
	}


	/* 
	 * Utility methods that are handy for inspection and running batches 
	 */
	 
	// return the actual class that implemented this virtual class
	global static System.Type forName( string classname ) { 
		System.Type typ = Type.forName('', classname );  						// outside the package
		if ( typ == null ) typ = Type.forName( Namespace, classname ); // in the package
		if ( typ == null ) 
			throw new InspectException( 'System.Type.forName() could not find :'+classname);
		return typ;
	}
	
	global static System.Type forName( Process_Job__c job ) {  
		System.Type typ = Type.forName('', job.Apex_Class__c );  						// outside the package
		if ( typ == null ) typ = Type.forName( Namespace, job.Apex_Class__c ); // in the package
		if ( typ == null ) typ = Type.forName( job.Namespace__c , job.Apex_Class__c ); // specified namespace
		if ( typ == null ) 
			throw new InspectException( 'System.Type.forName() could not find :'+job.Apex_Class__c);
		return typ;
	}
	
	global class InspectException extends Exception {}
	 
	// return the class name of the object passed in
	global static string getClassName( object thisclass ) {
		return string.valueOf(thisClass).substringBefore(':');  // should we do error checking
	}

}