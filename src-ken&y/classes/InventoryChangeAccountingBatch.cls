public with sharing class InventoryChangeAccountingBatch extends AccountingBatchBaseClass
//implements Database.Batchable<sObject>, Process.Runnable2, Database.Stateful
{
         // FIN-749 Moved to super class -AccountingBatchBaseClass.
        /*        
    public string query;
    public set<Id> operatingCompanyIds = new set<Id>();
    public List<Notify.Message> messages = new List<Notify.Message>();
    InventoryChangeAccounting ica = new InventoryChangeAccounting();  
    
    public void runBatch( Process_Job__c job ) {     // Process.Runnable2 implementation 
		InventoryChangeAccountingBatch obj=new InventoryChangeAccountingBatch(new set<id>{ job.Company__c} );
		integer defaultBatchSize = 10;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 50 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
        Database.executebatch(obj, defaultBatchSize);
    }
   */
  // FIN-749 Pass SD Name to super constructor so that it will instantiate respective Accounting worker class.        
    public InventoryChangeAccountingBatch()
    {
        super('Inventory_Change__c');
 
    }
    
    public InventoryChangeAccountingBatch(set<Id> operatingCompIds){
        super('Inventory_Change__c');
        operatingCompanyIds = operatingCompIds;
        //Just grab the minimum, we requery for everything we need in the GenerateAccountingService processor
        /*
        query= 'SELECT Id, Company__c ' 
               + ' FROM Inventory_Change__c '
               + ' WHERE company__c IN :operatingCompanyIds ' 
               + ' AND finalized__c = true '
               + ' and historical__c = false '  
               + ' and finalized_date__c != null '  
               + ' and transaction_date__c != null' 
               + ' and id not in (Select Inventory_Change__c from Accounting_Entry__c where company__c in :operatingCompanyIds and void__c = false '
                  //FIN-690 Regenerate Accounting for AE with Exceptions
               + ' and Has_Exceptions__c=false and status__c=\'Active\') ';
   		*/
        /*
   		query = 'SELECT Id, inventory_change__c '
   				+ ' FROM Inventory_Transaction__c '
   				+ ' WHERE Inventory_Change__r.Company__c IN :operatingCompanyIds '
   				+ ' AND Finalized__c = true '
   				+ ' AND Historical__c = false '
   				+ ' AND Inventory_Change__r.Finalized_Dated__c != null '
   				+ ' AND Inventory_Change__r.Transaction_Date__c != null '
   				+ ' AND Inventory_Change__c NOT IN (SELECT Inventory_Change__c FROM Accounting_Entry__c where company__c in :operatingCompanyIds and Related_Accounting_Entry__c = null AND Has_Exceptions__c = false AND Status__c = \'Active\' )';
        */
    }
     //FIN-749 Large Data Accounting
    //Override abstract method of super to query for specifics with respect to source doc
    public override void createBaseQuery()
    {
        BaseQuery=  'SELECT Id, inventory_change__c '
   				  + ' FROM Inventory_Transaction__c ';
    }
                                                
    public override void createwhereClause()
    {
        whereclause=  ' WHERE Inventory_Change__r.Company__c IN :operatingCompanyIds '
                    + ' AND isFinalized__c = true '
                    + ' AND Historical__c = false '
                    + ' AND Inventory_Change__r.Finalized_Date__c != null '
                    + ' AND Inventory_Change__r.Transaction_Date__c != null ';
                    //+ ' AND Inventory_Change__c NOT IN (SELECT Inventory_Change__c FROM Accounting_Entry__c where company__c in :operatingCompanyIds and Related_Accounting_Entry__c = null AND Has_Exceptions__c = false AND Status__c = \'Active\' )';
		
		if(processJob != null){
    		
    		if(processJob.Max_Records__c != null){
    			
	    		integer limitRecs = (integer)processJob.Max_Records__c;
	    		limitRecs = limitRecs < 1 ? 1 : limitRecs;
	    		limitRecs = limitRecs > LIMITS.getLimitQueryRows() ? LIMITS.getLimitQueryRows() : limitRecs;
    			
    			system.debug('limitRecs: ' + limitRecs);
    			//AND Bank_File__c= null condition commented for KNDY-10268 removal of bank file object reference
    			String whereClause = 'Finalized__c = true AND Historical__c = false AND Company__c IN :operatingCompanyIds ' 
										+' AND Id NOT IN (SELECT Inventory_Change__c '  
														+ ' FROM Accounting_Entry__c ' 
														+ ' WHERE Company__c IN :operatingCompanyIds ' 
														+ ' AND has_exceptions__c = false ' 
														+ ' AND status__c = \'Active\''
	    												+ ' AND Inventory_Change__c != null  AND related_accounting_entry__c = null ) '
										+ ' LIMIT ' + string.valueOf(limitRecs);
        
			    SOQLUtil soql = new SOQLUtil('Inventory_Change__c');
			    soql.addFields(new Set<String>{'Id'});
			    soql.setWhereClause(whereClause);
			    
	    		Map<Id, Inventory_Change__c> mNewCIs = new Map<Id, Inventory_Change__c>((List<Inventory_Change__c>) Database.query(soql.getQuery()));
	    		/*Map<Id, Inventory_Change__c> mNewCIs 
						= new Map<Id, Inventory_Change__c>(
	    											(List<Inventory_Change__c>)Database.Query(
	    											'SELECT Id '
	    											+' FROM Inventory_Change__c '
	    											+' WHERE Finalized__c = true AND Historical__c = false ' 
	    											+' AND Id NOT IN (SELECT Inventory_Change__c '  
	    																	+ ' FROM Accounting_Entry__c ' 
	    																	+ ' WHERE Company__c IN :operatingCompanyIds ' 
	    																	+ ' AND has_exceptions__c = false ' 
	    																	+ ' AND status__c = \'Active\''
	    																	+ ' AND Inventory_Change__c != null ) '
													+ ' LIMIT ' + string.valueOf(limitRecs)));*/
	    											
	    		recordIds.addAll(mNewCIs.keySet());
    		
	    		integer incrementalLimit = (integer)processJob.Max_Records__c - recordIds.size();
	    		incrementalLimit = (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) < incrementalLimit ? (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) : incrementalLimit;
	    		system.debug('incrementalLimit: ' + incrementalLimit);
	    		
	    		/*string aeQuery = 'SELECT Inventory_Change__c '
	    					+ ' FROM Accounting_Entry__c '
	    					+ ' WHERE Status__c = \'Active\' '
	    					+ ' AND isValidated__c = false '
	    				 	+ ' AND Validation_Ready__c = true '
	    				 	+ ' AND Inventory_Change__c != null '
	    				 	+ ' ORDER BY LastModifiedDate asc '
	    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);*/
	    		
	    		whereClause = 'Status__c = \'Active\' '
	    							+' AND Company__c IN :operatingCompanyIds '
			    					+ ' AND isValidated__c = false '
			    				 	+ ' AND Validation_Ready__c = true '
			    				 	+ ' AND Inventory_Change__c != null '
			    				 	+ ' ORDER BY LastModifiedDate asc '
			    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);
        
			    soql = new SOQLUtil('Accounting_Entry__c');
			    soql.addFields(new Set<String>{'Inventory_Change__c'});
			    soql.setWhereClause(whereClause);
	    		 	
		    	List<Accounting_Entry__c> incrementalCIs = Database.query(soql.getQuery());
		    	for(Accounting_Entry__c ae : incrementalCIs){
		    		recordIds.add(ae.Inventory_Change__c);
		    	}
    		}
	    }
    	
    	system.debug('recordIds: ' + recordIds);	
		if(recordIds.size() > 0){
			whereClause += ' AND Inventory_Change__c IN :recordIds';
		}else{
			whereClause += ' AND Inventory_Change__c NOT IN (SELECT Inventory_Change__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND has_exceptions__c = false AND status__c = \'Active\' AND ( (isValidated__c=false and Validation_Ready__c = false ) OR (isValidated__c=true and Validation_Ready__c = true ) OR (isValidated__c=true and Validation_Ready__c = false ) )  ' 
                            + ' AND Inventory_Change__c != null  AND related_accounting_entry__c = null ) '; 
        } 
    }   
    
        // FIN-749 Moved to super class -AccountingBatchBaseClass.
        /*          
    public Database.QueryLocator start(Database.BatchableContext BC){ 
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<sObject> scope){
        
        Set<Id> inventoryChangeIds = new Set<Id>();
    	
    	for(sObject thisSObj: scope){
            inventoryChangeIds.add(((Inventory_Change__c) thisSObj).id);
        }
        
        Savepoint sp = Database.setSavepoint();
        try{
        	
            ica.execute((List<Inventory_Change__c>)scope);
            
        }catch(Exception e){
            Database.rollback(sp);
            messages.add(new Notify.Message(e.getMessage(), e.getStackTraceString()));
        }
        
    }
    
    public void finish(Database.BatchableContext info){
    	
    	if(ica.deleteAEIds.size() > 0){
    		Database.executeBatch(new AccountingEntryLineDeleteBatch(ica.deleteAEIds), 2000);
    	}
    	
        BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
        Notify.sendEmailBatchFinish( null, messages, info);        
        MasterControlProgram.finishedBatch( this ); 
    }
   */
}