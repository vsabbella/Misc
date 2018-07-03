/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class CustomerReceiptAccountingBatch extends AccountingBatchBaseClass 
//implements 	Database.batchable<sObject>, Process.Runnable2, Database.Stateful 
{
         // FIN-749 Moved to super class -AccountingBatchBaseClass.
        /*       
    public string query;
    public set<Id> operatingCompanyIds = new set<Id>();
    public List<Notify.Message> messages = new List<Notify.Message>();
    
    public void runBatch( Process_Job__c job ) {     // Process.Runnable2 implementation 
		CustomerReceiptAccountingBatch obj=new CustomerReceiptAccountingBatch(new set<Id>{job.company__c});
		integer defaultBatchSize = 10;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 20 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
        Database.executebatch(obj, defaultBatchSize);
    }*/
    
    public CustomerReceiptAccountingBatch() 
    {
        super('Customer_Receipt__c');
        
    } 
    
    public CustomerReceiptAccountingBatch(set<Id> operatingCompIds){
        super('Customer_Receipt__c'); 
        operatingCompanyIds = operatingCompIds;
        
        // KNDY 1550 / KNDY 1582
        // Commented below logic to fetch dynamic query as we need to flaten the query and the details are already being queried in the GenerateAccountingService class
        //AccountingRuleService ARS = new AccountingRuleService();
        //String dynamicQuery = ARS.getQueryStringList(new List<String>{'Customer Receipt'});
       /* 
        query='select ID, Name, Amount_Received__c, Amount_Unapplied__c, Customer__c, Finalized__c, Company__c,'+ 
                'Currency__c, Date_Received__c' +
                ' from Customer_Receipt__c '+
                ' where Company__c in : operatingCompanyIds'+
                ' and Finalized__c = true'+
                ' and historical__c = false ' + 
                ' and finalized_date__c != null ' + 
                ' and transaction_date__c != null' +
                ' and id not in (Select Customer_Receipt__c from Accounting_Entry__c where company__c in :operatingCompanyIds and void__c = false and period__r.closed__c = true '+
               //FIN-690 Regenerate Accounting for AE with Exceptions
                ' and Has_Exceptions__c=false and status__c=\'Active\') ';*/
                                    
    }
    //FIN-749 Large Data Accounting
    //Override abstract method of super to query for specifics with respect to source doc
    public override void createBaseQuery()
    {
        BaseQuery= 'select ID, Name, Customer_Receipt__c from Customer_Receipt_Line__c ';
    }
                                                
    public override void createwhereClause()
    {
        whereclause=    ' where Customer_Receipt__r.Company__c in : operatingCompanyIds'+
                        ' and Finalized__c = true'+
                        ' and historical__c = false ' + 
                        ' and Customer_Receipt__r.finalized_date__c != null ' + 
                        ' and Customer_Receipt__r.transaction_date__c != null';

		if(processJob != null){
    		
    		if(processJob.Max_Records__c != null){
    			
	    		integer limitRecs = (integer)processJob.Max_Records__c;
	    		limitRecs = limitRecs < 1 ? 1 : limitRecs;
	    		limitRecs = limitRecs > LIMITS.getLimitQueryRows() ? LIMITS.getLimitQueryRows() : limitRecs;
    			
    			system.debug('limitRecs: ' + limitRecs);

                SOQLUtil crQuery = new SOQLUtil('Customer_Receipt__c', TRUE);
                crQuery.addFields(new Set<String>{'Id'});
                //KNDY-10268 - deprecating bank file and bank file line objects . condition removed AND Bank_File__c= null
                crQuery.setWhereClause('Finalized__c = true AND Historical__c = false AND Company__c IN :operatingCompanyIds '
                                                    +' AND Id NOT IN (SELECT Customer_Receipt__c'
                                                                            + ' FROM Accounting_Entry__c '
                                                                            + ' WHERE Company__c IN :operatingCompanyIds'
                                                                            + ' AND has_exceptions__c = false'
                                                                            + ' AND status__c = \'Active\''
										    								+ ' AND Customer_Receipt__c != null  AND related_accounting_entry__c = null ) '
                                                                            );
                crQuery.setLimit(limitRecs);
	    		Map<Id, Customer_Receipt__c> mNewCRs
						= new Map<Id, Customer_Receipt__c>(
	    											(List<Customer_Receipt__c>)Database.Query(crQuery.getQuery()));
	    											
	    		recordIds.addAll(mNewCRs.keySet());
    		
	    		integer incrementalLimit = (integer)processJob.Max_Records__c - recordIds.size();
	    		incrementalLimit = (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) < incrementalLimit ? (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) : incrementalLimit;
	    		system.debug('incrementalLimit: ' + incrementalLimit);
	    		
	    		String aeWhereClause = 'Status__c = \'Active\' '
	    					+ ' AND isValidated__c = false '
	    				 	+ ' AND Validation_Ready__c = true '
	    				 	+ ' AND Customer_Receipt__c != null ';
	    		SOQLUtil aeQuery = new SOQLUtil('Accounting_Entry__c', TRUE);
                aeQuery.addFields(new Set<String>{'Customer_Receipt__c'});
                aeQuery.setWhereClause(aeWhereClause);
                aeQuery.setOrderByClause('LastModifiedDate asc');
                aeQuery.setLimit(incrementalLimit);

		    	List<Accounting_Entry__c> incrementalCRs = Database.query(aeQuery.getQuery());
		    	for(Accounting_Entry__c ae : incrementalCRs){
		    		recordIds.add(ae.customer_receipt__c);
		    	}
    		}
	    	
    	}
    	
    	system.debug('recordIds: ' + recordIds);	
		if(recordIds.size() > 0){
			whereClause += ' AND Customer_Receipt__c IN :recordIds';
		}else{
			//KNDY-10268 - deprecating bank file and bank file line objects. condition removed AND Bank_File__c= null
			whereClause += ' and Customer_Receipt__c not in (Select Customer_Receipt__c from Accounting_Entry__c where company__c in :operatingCompanyIds AND Has_Exceptions__c = false AND status__c=\'Active\''
	    								+ ' AND Customer_Receipt__c != null  AND related_accounting_entry__c = null ) ';
		}
    }  
    // FIN-749 Moved to super class -AccountingBatchBaseClass.
    /*     
    public Database.QueryLocator start(Database.BatchableContext BC){ 
            
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Customer_Receipt__c> scope){
        Set<Id> receiptIds = new Set<Id>();
        Map<Id,Customer_Receipt__c> receiptMapUpd = new Map<Id,Customer_Receipt__c>();
    
        //GenerateAccountingService GAS = new GenerateAccountingService();  
        CustomerReceiptAccounting cra = new CustomerReceiptAccounting();
        
        for(Customer_Receipt__c thisReceipt: scope){
            receiptIds.add(thisReceipt.id);
        }
        Savepoint sp = Database.setSavepoint();
        try{
        	
            //GAS.createCustReceiptAccounting(scope);
            cra.execute(scope);
            
            // KNDY 2196 - Changed the approach to update the Accounted flag on source document.
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