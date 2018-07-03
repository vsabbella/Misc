public class PurchaseOrderAccountingBatch{
//DEPRECATED CLASS FIN-1046    

/*
* without sharing is intentional.  accounting needs to be run in system mode.

public without sharing class PurchaseOrderAccountingBatch extends AccountingBatchBaseClass 
//implements Database.batchable<sObject>, Process.Runnable2, Database.Stateful 
{/*
    // FIN-749 Moved to super class -AccountingBatchBaseClass.
    /*          
    public string query;
    public set<Id> operatingCompanyIds = new set<Id>();
    public List<Notify.Message> messages = new List<Notify.Message>();

	public void runBatch( Process_Job__c job ) {     // Process.Runnable2 implementation 
		PurchaseOrderAccountingBatch obj=new PurchaseOrderAccountingBatch(new set<id>{ job.Company__c} );
		integer defaultBatchSize = 10;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 20 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
        Database.executebatch(obj, defaultBatchSize);
    }
    
    // FIN-749 Pass SD Name to super constructor so that it will instantiate respective Accounting worker class.           
    public PurchaseOrderAccountingBatch() 
    {
         super('Purchase_Order__c');
       
    }

    public PurchaseOrderAccountingBatch(set<Id> operatingCompIds){
        super('Purchase_Order__c');
        operatingCompanyIds = operatingCompIds;
        
        query = 'select id, name , company__c, supplier__c, finalized__c, finalized_date__c, transaction_currency__c, transaction_date__c, type__c '
                + 'FROM Purchase_Order__c '
                + 'WHERE Company__c in :operatingCompanyIds '
                + 'AND Finalized__c = true '
                + 'AND Company__c != null '
                + 'AND Transaction_Date__c != null '
                + 'AND historical__c = false '  
                + 'AND Transaction_Currency__c != null '
                + 'AND Id NOT IN (SELECT Purchase_Order__c from Accounting_Entry__c WHERE void__c = false '
                //FIN-690 Regenerate Accounting for AE with Exceptions
                + ' and Has_Exceptions__c=false and status__c=\'Active\') ';
    }
    //FIN-749 Large Data Accounting
    //Override abstract method of super to query for specifics with respect to source doc
    public override void createBaseQuery()
    {
        BaseQuery='select id, Purchase_Order__c'
                 + ' FROM Purchase_Order_Line__c ';
    }
                                                
    public override void createwhereClause()
    {
        whereclause=   ' WHERE Purchase_Order__r.Company__c in :operatingCompanyIds '
                    + ' AND Finalized__c = true '
                    + ' AND Company__c != null '
                    + ' AND Purchase_Order__r.Transaction_Date__c != null '
                    + ' AND historical__c = false '  
                    + ' AND Purchase_Order__r.Transaction_Currency__c != null ';
		
		if(processJob != null){
    		
    		if(processJob.Max_Records__c != null){
    			
	    		integer limitRecs = (integer)processJob.Max_Records__c;
	    		limitRecs = limitRecs < 1 ? 1 : limitRecs;
	    		limitRecs = limitRecs > LIMITS.getLimitQueryRows() ? LIMITS.getLimitQueryRows() : limitRecs;
    			
    			system.debug('limitRecs: ' + limitRecs);
    		
	    		Map<Id, Purchase_Order__c> mNewPOs 
						= new Map<Id, Purchase_Order__c>(
	    											(List<Purchase_Order__c>)Database.Query(
	    											'SELECT Id '
	    											+' FROM Purchase_Order__c '
	    											+' WHERE Finalized__c = true AND Historical__c = false ' 
	    											+' AND Id NOT IN (SELECT Purchase_Order__c '  
	    																	+ ' FROM Accounting_Entry__c ' 
	    																	+ ' WHERE Company__c IN :operatingCompanyIds ' 
	    																	+ ' AND has_exceptions__c = false ' 
	    																	+ ' AND status__c = \'Active\''
	    																	+ ' AND Purchase_Order__c != null ) '
													+ ' LIMIT ' + string.valueOf(limitRecs)));
	    											
	    		recordIds.addAll(mNewPOs.keySet());
    		
	    		integer incrementalLimit = (integer)processJob.Max_Records__c - recordIds.size();
	    		incrementalLimit = (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) < incrementalLimit ? (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) : incrementalLimit;
	    		system.debug('incrementalLimit: ' + incrementalLimit);
	    		
	    		string aeQuery = 'SELECT Purchase_Order__c '
	    					+ ' FROM Accounting_Entry__c '
	    					+ ' WHERE Status__c = \'Active\' '
	    					+ ' AND isValidated__c = false '
	    				 	+ ' AND Validation_Ready__c = true '
	    				 	+ ' AND Purchase_Order__c != null '
	    				 	+ ' ORDER BY LastModifiedDate asc '
	    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);
	    				 	
		    	List<Accounting_Entry__c> incrementalPOs = Database.query(aeQuery);
		    	for(Accounting_Entry__c ae : incrementalPOs){
		    		recordIds.add(ae.Purchase_Order__c);
		    	}
    		}
	    	
    	}
    	
    	system.debug('recordIds: ' + recordIds);	
		if(recordIds.size() > 0){
			whereClause += ' AND Purchase_Order__c IN :recordIds';
		}else{
			whereClause += ' AND Purchase_Order__c NOT IN (SELECT Purchase_Order__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND has_exceptions__c = false AND status__c = \'Active\') ';
		}
    }    
        // FIN-749 Moved to super class -AccountingBatchBaseClass.
        /*      
    
    public Database.QueryLocator start(Database.BatchableContext BC){ 
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<sObject> scope){
        PurchaseOrderAccounting poa = new PurchaseOrderAccounting();
        // Save point
        Savepoint sp = Database.setSavepoint();
        try{
        	
            poa.execute(scope);
	        	
        } catch(Exception e) {
            Database.rollback(sp);
            messages.add(new Notify.Message(e.getMessage(), e.getStackTraceString()));
        }
	
    }
    
    public void finish(Database.BatchableContext info){
        BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
        Notify.sendEmailBatchFinish( null, messages, info);        
        MasterControlProgram.finishedBatch( this ); 
    }
*/
}