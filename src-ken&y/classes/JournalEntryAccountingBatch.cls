/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class JournalEntryAccountingBatch extends AccountingBatchBaseClass  
// FIN-749  super class implements batchable and runnable interface.	                                                            
//implements Database.batchable<sObject>, Process.Runnable2, Database.Stateful 
{

   // FIN-749 Moved to super class -AccountingBatchBaseClass.    
   // public string query;
   // public set<Id> operatingCompanyIds = new set<Id>();
   // public List<Notify.Message> messages = new List<Notify.Message>();
   // JournalEntryAccounting jea = new JournalEntryAccounting();

     // FIN-749 Moved to super class -AccountingBatchBaseClass.    
	/*
    public void runBatch( Process_Job__c job ) {     // Process.Runnable2 implementation 
		JournalEntryAccountingBatch obj=new JournalEntryAccountingBatch(new set<id>{ job.Company__c} );
		integer defaultBatchSize = 10;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 20 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
        Database.executebatch(obj, defaultBatchSize);
    }*/
     //FIN-749 Large Data Accounting
    //Override abstract method of super to query for specifics with respect to source doc
    public override void createBaseQuery()
    {
        BaseQuery=  'SELECT Id, Journal_Entry__c '
      				+ ' FROM Journal_Entry_Line__c ';
    }
                                                
    public override void createwhereClause()
    {
        whereclause=   ' WHERE Finalized__c = true';
      				 
      	
      	if(processJob != null){
    		
    		if(processJob.Max_Records__c != null){
    			
	    		integer limitRecs = (integer)processJob.Max_Records__c;
	    		limitRecs = limitRecs < 1 ? 1 : limitRecs;
	    		limitRecs = limitRecs > LIMITS.getLimitQueryRows() ? LIMITS.getLimitQueryRows() : limitRecs;
    			
    			system.debug('limitRecs: ' + limitRecs);
    			
    			String whereClause = 'Finalized__c = true AND Company__c IN :operatingCompanyIds ' 
									+' AND Id NOT IN (SELECT Journal_Entry__c '  
															+ ' FROM Accounting_Entry__c ' 
															+ ' WHERE Company__c IN :operatingCompanyIds ' 
															+ ' AND has_exceptions__c = false ' 
															+ ' AND status__c = \'Active\''
															+ ' AND Journal_Entry__c != null ) '
									+ ' LIMIT ' + string.valueOf(limitRecs);
        
			    SOQLUtil soql = new SOQLUtil('Journal_Entry__c');
			    soql.addFields(new Set<String>{'Id'});
			    soql.setWhereClause(whereClause);
	    
	    		Map<Id, Journal_Entry__c> mNewJEs = new Map<Id, Journal_Entry__c>((List<Journal_Entry__c>) Database.query(soql.getQuery()));
	    		/*Map<Id, Journal_Entry__c> mNewJEs 
						= new Map<Id, Journal_Entry__c>(
	    											(List<Journal_Entry__c>)Database.Query(
	    											'SELECT Id '
	    											+' FROM Journal_Entry__c '
	    											+' WHERE Finalized__c = true ' 
	    											+' AND Id NOT IN (SELECT Journal_Entry__c '  
	    																	+ ' FROM Accounting_Entry__c ' 
	    																	+ ' WHERE Company__c IN :operatingCompanyIds ' 
	    																	+ ' AND has_exceptions__c = false ' 
	    																	+ ' AND status__c = \'Active\''
	    																	+ ' AND Journal_Entry__c != null ) '
													+ ' LIMIT ' + string.valueOf(limitRecs)));*/
	    											
	    		recordIds.addAll(mNewJEs.keySet());
    		
	    		integer incrementalLimit = (integer)processJob.Max_Records__c - recordIds.size();
	    		incrementalLimit = (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) < incrementalLimit ? (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) : incrementalLimit;
	    		system.debug('incrementalLimit: ' + incrementalLimit);
	    		
	    		/*string aeQuery = 'SELECT Journal_Entry__c '
	    					+ ' FROM Accounting_Entry__c '
	    					+ ' WHERE Status__c = \'Active\' '
	    					+ ' AND isValidated__c = false '
	    				 	+ ' AND Validation_Ready__c = true '
	    				 	+ ' AND Journal_Entry__c != null '
	    				 	+ ' ORDER BY LastModifiedDate asc '
	    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);*/
	    		
	    		whereClause = 'Status__c = \'Active\' '
			    					+ ' AND isValidated__c = false '
			    				 	+ ' AND Validation_Ready__c = true '
			    				 	+ ' AND Journal_Entry__c != null '
			    				 	+ ' ORDER BY LastModifiedDate asc '
			    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);
        
			    soql = new SOQLUtil('Accounting_Entry__c');
			    soql.addFields(new Set<String>{'Journal_Entry__c'});
			    soql.setWhereClause(whereClause);
			    		 	
		    	List<Accounting_Entry__c> incrementalJEs = Database.query(soql.getQuery());
		    	for(Accounting_Entry__c ae : incrementalJEs){
		    		recordIds.add(ae.journal_entry__c);
		    	}
    		}
	    	
    	}
    	
    	system.debug('recordIds: ' + recordIds);	
		if(recordIds.size() > 0){
			whereClause += ' AND Journal_Entry__c IN :recordIds';
		}else{
			whereClause += ' AND Journal_Entry__c NOT IN (SELECT Journal_Entry__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND Has_Exceptions__c = false AND status__c=\'Active\')';
		}

    }    
    public JournalEntryAccountingBatch() 
    {
        super('Journal_Entry__c');
    }

    public JournalEntryAccountingBatch(set<Id> operatingCompIds){
        super('Journal_Entry__c');
        operatingCompanyIds = operatingCompIds;
        
        /*
         query='select ID, Name, Finalized__c, Company__c, GL_Date_Time__c ,Currency__c ' +
              ' from Journal_Entry__c where Company__c in :operatingCompanyIds and Finalized__c = true and Type__c != null ' +
              ' and id not in (Select Journal_Entry__c from Accounting_Entry__c where Company__c in :operatingCompanyIds  ' +
              //FIN-690 Regenerate Accounting for AE with Exceptions
              ' and Has_Exceptions__c=false and status__c=\'Active\') ';
       */

       // FIN-749 Moved to super class -AccountingBatchBaseClass.
        /*
      	query = 'SELECT Id, name, Journal_Entry__c '
      				+ ' FROM Journal_Entry_Line__c '
      				+ ' WHERE Finalized__c = true'
      				+ ' AND Journal_Entry__c NOT IN (SELECT Journal_Entry__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND (Period__r.Closed__c = true OR Period__r.Permanently_closed__c = true) AND Has_Exceptions__c = false AND status__c=\'Active\')';

        */
      	
    }
    // FIN-749 Moved to super class -AccountingBatchBaseClass.    
     /*
    public Database.QueryLocator start(Database.BatchableContext BC){ 
         //FIN-749 LargeDataAccounting   
        updateQueryLocator(); 
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Journal_Entry_Line__c> scope){
        system.debug('scope: ' + scope);
        Savepoint sp = Database.setSavepoint();
        try{
 			jea.execute(scope);
        } catch(Exception e) {
        	system.debug('EXCEPTION: ' + e);
            Database.rollback(sp);
            messages.add(new Notify.Message(e.getMessage(), e.getStackTraceString()));
        }
    }
    
    public void finish(Database.BatchableContext info){
    	
    	if(jea.deleteAEIds.size() > 0){
    		Database.executeBatch(new AccountingEntryLineDeleteBatch(jea.deleteAEIds), 2000);
    	}
    	
    	
        BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
        Notify.sendEmailBatchFinish( null, messages, info);        
        MasterControlProgram.finishedBatch( this ); 

    }*/
}