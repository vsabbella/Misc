/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class CustomerInvoiceAccountingBatch extends AccountingBatchBaseClass 

//implements Database.batchable<sObject>, Process.Runnable2, Database.Stateful
{
    // FIN-749 Moved to super class -AccountingBatchBaseClass.
    /*        
    public string query;
    public set<Id> operatingCompanyIds = new set<Id>();
    public List<Notify.Message> messages = new List<Notify.Message>();
	CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
    public void runBatch( Process_Job__c job ) { 		// Process.Runnable implementation 
        CustomerInvoiceAccountingBatch obj = new CustomerInvoiceAccountingBatch(new set<id>{job.Company__c } );
    	integer defaultBatchSize = 2;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 25 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
        Database.executebatch(obj, defaultBatchSize);
    }*/
   // FIN-749 Pass SD Name to super constructor so that it will instantiate respective Accounting worker class. 
    public CustomerInvoiceAccountingBatch()
    {
         super('Customer_Invoice__c');
       
    }

    public CustomerInvoiceAccountingBatch(set<Id> operatingCompIds){
        super('Customer_Invoice__c');
        operatingCompanyIds = operatingCompIds;
        
        // KNDY 1550 / KNDY 1582
        // Commented below logic to fetch dynamic query as we need to flaten the query and the details are already being queried in the GenerateAccountingService class
        //AccountingRuleService ARS = new AccountingRuleService();
        //String dynamicQuery = ARS.getQueryStringList(new List<String>{'Customer Invoice','Customer Credit Memo','Adjustment'});
        
        /*
        query='select ID, Name, Subtotal__c, Sold_To_Customer__c, Finalized__c, Company__c, Sales_Tax__c,Date_Invoiced__c,Invoice_Type__c,Currency__c' +
              ' from Customer_Invoice__c' + 
              ' where Company__c in :operatingCompanyIds ' +
              ' and Finalized__c = true '+
              ' and historical__c = false ' + 
              ' and finalized_date__c != null ' + 
              ' and transaction_date__c != null' +
              ' and id not in (Select Customer_Invoice__c from Accounting_Entry__c where company__c in :operatingCompanyIds ' +//+
              //' and id not in (Select Customer_Credit_Memo__c from Accounting_Entry__c where company__c in :operatingCompanyIds and void__c = false )' ;
              //FIN-690 Regenerate Accounting for AE with Exceptions
              ' and Has_Exceptions__c=false and status__c=\'Active\') ';
   		*/
   		
   		/*query = 'SELECT Id, customer_invoice__c, '
   			+ ' FROM Customer_Invoice_Line__c '
   			+ ' WHERE Customer_Invoice__r.Company__c IN :operatingCompanyIds '
   			+ ' AND Finalized__c = true '
   			+ ' AND Historical__c = false '
   			+ ' AND Customer_Invoice__r.Finalized_Date__c != null '
   			+ ' AND Customer_Invoice__r.Transaction_Date__c != null '
   			+ ' AND Customer_Invoice__c NOT IN (SELECT Customer_Invoice__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND has_exceptions__c = false AND status__c = \'Active\')';
          */
}    
    //FIN-749 Large Data Accounting
    //Override abstract method of super to query for specifics with respect to source doc
    public override void createBaseQuery()
    {
        BaseQuery='SELECT Id, customer_invoice__c '
   			    + ' FROM Customer_Invoice_Line__c ';
    }
                                                
    public override void createwhereClause()
    {
    	
    	whereclause=    'WHERE Customer_Invoice__r.Company__c IN :operatingCompanyIds '
	   			+ ' AND Finalized__c = true '
	   			+ ' AND Historical__c = false '
	   			+ ' AND Customer_Invoice__r.Finalized_Date__c != null '
	   			+ ' AND Customer_Invoice__r.Transaction_Date__c != null ';
	   			
    	if(processJob != null){
    		
    		if(processJob.Max_Records__c != null){
    			
	    		integer limitRecs = (integer)processJob.Max_Records__c;
	    		limitRecs = limitRecs < 1 ? 1 : limitRecs;
	    		limitRecs = limitRecs > LIMITS.getLimitQueryRows() ? LIMITS.getLimitQueryRows() : limitRecs;
    			
    			system.debug('limitRecs: ' + limitRecs);
    		  SOQLUtil ciQuery = new SOQLUtil('Customer_Invoice__c', TRUE);
          ciQuery.addFields(new Set<String>{'Id'});
          //AND Bank_File__c= null condition commented for KNDY-10268 removal of bank file object reference
          ciQuery.setWhereClause('Finalized__c = true AND Historical__c = false AND Company__c IN :operatingCompanyIds '
                            +' AND Id NOT IN (SELECT Customer_Invoice__c '
                                        + ' FROM Accounting_Entry__c '
                                        + ' WHERE Company__c IN :operatingCompanyIds '
                                        + ' AND has_exceptions__c = false '
                                        + ' AND status__c = \'Active\''
	    								+ ' AND Customer_Invoice__c != null  AND related_accounting_entry__c = null ) '
                                        );
          ciQuery.setLimit(limitRecs);
	    		Map<Id, Customer_Invoice__c> mNewCIs
						= new Map<Id, Customer_Invoice__c>(
	    											(List<Customer_Invoice__c>)Database.Query(ciQuery.getQuery()));
	    											
	    		recordIds.addAll(mNewCIs.keySet());
    		
	    		integer incrementalLimit = (integer)processJob.Max_Records__c - recordIds.size();
	    		incrementalLimit = (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) < incrementalLimit ? (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) : incrementalLimit;
	    		system.debug('incrementalLimit: ' + incrementalLimit);
	    		
	    		string aeWhereClause = 'Status__c = \'Active\' '
	    					+ ' AND isValidated__c = false '
	    				 	+ ' AND Validation_Ready__c = true '
	    				 	+ ' AND Customer_Invoice__c != null ';
	    		SOQLUtil aeQuery = new SOQLUtil('Accounting_Entry__c', TRUE);
          aeQuery.addFields(new Set<String>{'Customer_Invoice__c'});
          aeQuery.setWhereClause(aeWhereClause);
          aeQuery.setOrderByClause('LastModifiedDate asc');
          aeQuery.setLimit(incrementalLimit);
		    	List<Accounting_Entry__c> incrementalCIs = Database.query(aeQuery.getQuery());
		    	for(Accounting_Entry__c ae : incrementalCIs){
		    		recordIds.add(ae.customer_invoice__c);
		    	}
    		}
	    	
    	}
    	
    	system.debug('recordIds: ' + recordIds);	
		if(recordIds.size() > 0){
			whereClause += ' AND Customer_Invoice__c IN :recordIds';
		}else{
			//AND Bank_File__c= null commented for KNDY-10268 removal of bank file object reference
			whereClause += ' AND Customer_Invoice__c NOT IN (SELECT Customer_Invoice__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND has_exceptions__c = false AND status__c = \'Active\' '
	    								+ ' AND Customer_Invoice__c != null  AND related_accounting_entry__c = null  ) ';
		}

    }
    // FIN-749 Moved to super class -AccountingBatchBaseClass.
    /*          
    public Database.QueryLocator start(Database.BatchableContext BC){ 

        MasterControlProgram.checkAlreadyRunning( this, BC );    // KNDY-6780 allow this batch to complete before running again

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<sObject> scope){
        
        // Save point
        Savepoint sp = Database.setSavepoint();
        try{
        	
            cia.execute(scope);
            
        } catch(Exception e) {
            Database.rollback(sp);
            messages.add(new Notify.Message(e.getMessage(), e.getStackTraceString()));
        }
	
    }
    
    public void finish(Database.BatchableContext info){
    	
    	if(cia.deleteAEIds.size() > 0){
    		Database.executeBatch(new AccountingEntryLineDeleteBatch(cia.deleteAEIds), 2000);
    	}
    	
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( null, messages, info);        
	    	MasterControlProgram.finishedBatch( this ); 
    }
   */
}