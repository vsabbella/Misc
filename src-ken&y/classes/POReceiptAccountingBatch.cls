/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class POReceiptAccountingBatch extends AccountingBatchBaseClass
//implements Database.batchable<sObject>, Process.Runnable2, Database.Stateful 
{
    // FIN-749 Moved to super class -AccountingBatchBaseClass.  
    /*      
    public string query;
    public set<Id> operatingCompanyIds = new set<Id>();
    public List<Notify.Message> messages = new List<Notify.Message>();
    ReceivingDocumentAccounting rda = new ReceivingDocumentAccounting();
    
	public void runBatch( Process_Job__c job ) {     // Process.Runnable2 implementation 
		POReceiptAccountingBatch obj=new POReceiptAccountingBatch(new set<id>{ job.Company__c});
		integer defaultBatchSize = 10;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 20 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
        Database.executebatch(obj, defaultBatchSize);
    }
    */
  // FIN-749 Pass SD Name to super constructor so that it will instantiate respective Accounting worker class.        
    public POReceiptAccountingBatch() 
    {
        super('Receiving_Document__c');
        
    } 
    
    public POReceiptAccountingBatch(set<Id> operatingCompIds){
        super('Receiving_Document__c');        
        operatingCompanyIds = operatingCompIds;
        
        // KNDY 1550 / KNDY 1582
        // Commented below logic to fetch dynamic query as we need to flaten the query and the details are already being queried in the GenerateAccountingService class
        //AccountingRuleService ARS = new AccountingRuleService();
        //String dynamicQuery = ARS.getQueryStringList(new List<String>{'Purchase Receipt'});
        /*
        query='Select id, Name, Date_Received__c, Company__c, Finalized__c, Currency__c'+
                  ' from Receiving_Document__c'+
               ' where Company__c in :operatingCompanyIds'+
               ' and Finalized__c = true'+
               ' and Status__c != \'Void\''+
               ' and finalized_date__c != null ' + 
               ' and historical__c = false ' + 
               ' and transaction_date__c != null' +
               ' and id not in (Select Receiving_Document__c from Accounting_Entry__c where company__c in :operatingCompanyIds and void__c = false '+
                //FIN-690 Regenerate Accounting for AE with Exceptions
               ' and Has_Exceptions__c=false and status__c=\'Active\') ';
 		*/
 		/*query = 'SELECT Id, Receiving_Document__c, '
 				+ ' FROM Receipt_Line__c '
 				+ ' WHERE Receiving_Document__r.Company__c IN :operatingCompanyIds '
 				+ ' AND Finalized__c = true '
 				+ ' AND Historical__c = false '
 				+ ' AND Receiving_Document__r.Finalized_Date__c != null '
 				+ ' AND Receiving_Document__r.Transaction_Date__c != null '
 				+ ' AND Receiving_Document__c NOT IN (SELECT Receiving_Document__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND related_accounting_entry__c = null AND has_exceptions__c = false AND Status__c = \'Active\')';
         */
     }
     //FIN-749 Large Data Accounting
    //Override abstract method of super to query for specifics with respect to source doc
    public override void createBaseQuery()
    {
        BaseQuery='SELECT Id, Receiving_Document__c '
 			    	+ ' FROM Receipt_Line__c ';
    }
                                                
    public override void createwhereClause()
    {
        whereclause=  ' WHERE Receiving_Document__r.Company__c IN :operatingCompanyIds '
                    + ' AND Finalized__c = true '
                    + ' AND Historical__c = false '
                    + ' AND Receiving_Document__r.Finalized_Date__c != null '
                    + ' AND Receiving_Document__r.Transaction_Date__c != null ';
                   // + ' AND Receiving_Document__c NOT IN (SELECT Receiving_Document__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND related_accounting_entry__c = null AND has_exceptions__c = false AND Status__c = \'Active\')';
 		if(processJob != null){
    		
    		if(processJob.Max_Records__c != null){
    			
	    		integer limitRecs = (integer)processJob.Max_Records__c;
	    		limitRecs = limitRecs < 1 ? 1 : limitRecs;
	    		limitRecs = limitRecs > LIMITS.getLimitQueryRows() ? LIMITS.getLimitQueryRows() : limitRecs;
    			
    			system.debug('limitRecs: ' + limitRecs);
    			// and Bank_File__c =null condition removed for KNDY-10268 removal of bank file object reference
    			String whereClause = 'Finalized__c = true AND Historical__c = false AND Company__c IN :operatingCompanyIds ' 
									+' AND Id NOT IN (SELECT Receiving_Document__c '  
									+ ' FROM Accounting_Entry__c ' 
									+ ' WHERE Company__c IN :operatingCompanyIds ' 
									+ ' AND has_exceptions__c = false ' 
									+ ' AND status__c = \'Active\''
									+ ' AND Receiving_Document__c != null  AND related_accounting_entry__c = null ) '
									+ ' LIMIT ' + string.valueOf(limitRecs);
        
			    SOQLUtil soql = new SOQLUtil('Receiving_Document__c');
			    soql.addFields(new Set<String>{'Id'});
			    soql.setWhereClause(whereClause);
	    
	    		Map<Id, Receiving_Document__c> mNewCIs = new Map<Id, Receiving_Document__c>((List<Receiving_Document__c>)Database.query(soql.getQuery()));
	    		/*Map<Id, Receiving_Document__c> mNewCIs 
						= new Map<Id, Receiving_Document__c>(
	    											(List<Receiving_Document__c>)Database.Query(
	    											'SELECT Id '
	    											+' FROM Receiving_Document__c '
	    											+' WHERE Finalized__c = true AND Historical__c = false ' 
	    											+' AND Id NOT IN (SELECT Receiving_Document__c '  
														+ ' FROM Accounting_Entry__c ' 
														+ ' WHERE Company__c IN :operatingCompanyIds ' 
														+ ' AND has_exceptions__c = false ' 
														+ ' AND status__c = \'Active\''
														+ ' AND Receiving_Document__c != null ) '
													+ ' LIMIT ' + string.valueOf(limitRecs)));*/
	    											
	    		recordIds.addAll(mNewCIs.keySet());
    		
	    		integer incrementalLimit = (integer)processJob.Max_Records__c - recordIds.size();
	    		incrementalLimit = (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) < incrementalLimit ? (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) : incrementalLimit;
	    		/*system.debug('incrementalLimit: ' + incrementalLimit);
	    		
	    		string aeQuery = 'SELECT Receiving_Document__c '
	    					+ ' FROM Accounting_Entry__c '
	    					+ ' WHERE Status__c = \'Active\' '
	    					+ ' AND isValidated__c = false '
	    				 	+ ' AND Validation_Ready__c = true '
	    				 	+ ' AND Receiving_Document__c != null '
	    				 	+ ' ORDER BY LastModifiedDate asc '
	    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);*/
	    		
	    		whereClause = 'Status__c = \'Active\' '
			    					+ ' AND isValidated__c = false '
			    				 	+ ' AND Validation_Ready__c = true '
			    				 	+ ' AND Receiving_Document__c != null '
			    				 	+ ' ORDER BY LastModifiedDate asc '
			    				 	+ ' LIMIT ' + String.valueOf(incrementalLimit);
        
			    soql = new SOQLUtil('Accounting_Entry__c');
			    soql.addFields(new Set<String>{'Receiving_Document__c'});
			    soql.setWhereClause(whereClause);
			    
	    		List<Accounting_Entry__c> incrementalCIs = Database.query(soql.getQuery());
		    	for(Accounting_Entry__c ae : incrementalCIs){
		    		recordIds.add(ae.Receiving_Document__c);
		    	}
    		}
	    	
    	}
    	
    	system.debug('recordIds: ' + recordIds);	
		if(recordIds.size() > 0){
			whereClause += ' AND Receiving_Document__c IN :recordIds';
		}else{
			// and Bank_File__c =null condition removed for KNDY-10268 removal of bank file object reference
			whereClause += ' AND Receiving_Document__c NOT IN (SELECT Receiving_Document__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND has_exceptions__c = false AND status__c = \'Active\' '
									+ ' AND Receiving_Document__c != null  AND related_accounting_entry__c = null ) ';
		}
 		
    }
    /*
    public Database.QueryLocator start(Database.BatchableContext BC){ 
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<sObject> scope){
        
        Savepoint sp = Database.setSavepoint();
        try{
        	
            rda.execute(scope);
                				
        }catch(Exception e){
            Database.rollback(sp);
            messages.add(new Notify.Message(e.getMessage(), e.getStackTraceString()));
        }
    
    }
    
    public void finish(Database.BatchableContext info){
    	
    	if(rda.deleteAEIds.size() > 0){
    		Database.executeBatch(new AccountingEntryLineDeleteBatch(rda.deleteAEIds), 2000);
    	}
    	
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( null, messages, info);        
		MasterControlProgram.finishedBatch( this ); 
    }
   */
}