/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class SupplierInvoiceAccountingBatch extends AccountingBatchBaseClass 
//implements Database.batchable<sObject>, Process.Runnable2, Database.Stateful
{
    // FIN-749 Moved to super class -AccountingBatchBaseClass.
    /*          
    public string query;
    public set<Id> operatingCompanyIds = new set<Id>();
    public List<Notify.Message> messages = new List<Notify.Message>();
    SupplierInvoiceAccounting sia = new SupplierInvoiceAccounting();
    
    public void runBatch( Process_Job__c job ) { 		// Process.Runnable2 implementation 
    	SupplierInvoiceAccountingBatch batch = new SupplierInvoiceAccountingBatch(new set<id>{job.Company__c});
    	integer defaultBatchSize = 10;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 100 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
        Database.executebatch(batch, defaultBatchSize);
    } */
    
    public SupplierInvoiceAccountingBatch() 
    {
        super('Supplier_Invoice__c');
    }
    
    public SupplierInvoiceAccountingBatch(set<Id> operatingCompIds)
    {
        super('Supplier_Invoice__c');        
        operatingCompanyIds = operatingCompIds;
        
        // KNDY 1550 / KNDY 1582
        // Commented below logic to fetch dynamic query as we need to flaten the query and the details are already being queried in the GenerateAccountingService class
        //AccountingRuleService ARS = new AccountingRuleService();
        //String dynamicQuery = ARS.getQueryStringList(new List<String>{'Supplier Invoice'});
        /*
        query= 'Select id, Name, Supplier__c, Finalized__c, Company__c,Amount_Due__c, Date_Invoiced__c, Currency__c'+
                ' from Supplier_Invoice__c' + 
                ' where Company__c in :operatingCompanyIds' + 
                ' and Finalized__c = true' + 
                ' and finalized_date__c != null ' + 
                ' and historical__c = false ' + 
                ' and transaction_date__c != null' +
                ' and id not in (Select Supplier_Invoice__c from Accounting_Entry__c where company__c in :operatingCompanyIds and void__c = false '+
                //FIN-690 Regenerate Accounting for AE with Exceptions
                ' and Has_Exceptions__c=false and status__c=\'Active\') ';
        */
        /*query = 'SELECT Id, supplier_invoice__c '
        		+ ' FROM Supplier_Invoice_Line__c ' 
        		+ ' WHERE Supplier_Invoice__r.Company__c IN :operatingCompanyIds '
        		+ ' AND Finalized__c = true '
        		+ ' AND Historical__c = false '
        		+ ' AND Supplier_Invoice__r.Transaction_Date__c != null '
        		+ ' AND Supplier_Invoice__r.Finalized_Date__c != null '
        		+ ' AND Supplier_Invoice__c NOT IN (SELECT Supplier_Invoice__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND related_accounting_entry__c = null AND and Has_Exceptions__c = false and status__c=\'Active\')';    
        */
    }
    //FIN-749 Large Data Accounting
    //Override abstract method of super to query for specifics with respect to source doc
    public override void createBaseQuery()
    {
        BaseQuery=  'SELECT Id, Name, supplier_invoice__c '
        		  + ' FROM Supplier_Invoice_Line__c ' ;
    }
                                                
    public override void createwhereClause()
    {
        whereclause=  ' WHERE Supplier_Invoice__r.Company__c IN :operatingCompanyIds '
                    + ' AND Finalized__c = true '
                    + ' AND Historical__c = false '
                    + ' AND Supplier_Invoice__r.Transaction_Date__c != null '
                    + ' AND Supplier_Invoice__r.Finalized_Date__c != null ';

		if(processJob != null){
    		
    		if(processJob.Max_Records__c != null){
    			
	    		integer limitRecs = (integer)processJob.Max_Records__c;
	    		limitRecs = limitRecs < 1 ? 1 : limitRecs;
	    		limitRecs = limitRecs > LIMITS.getLimitQueryRows() ? LIMITS.getLimitQueryRows() : limitRecs;
    			
    			system.debug('limitRecs: ' + limitRecs);
    			//KNDY-10268 - deprecating bank file and bank file line objects
    			//AND Bank_File__c= null
    			String whereClause = 'Finalized__c = true AND Historical__c = false AND Company__c IN :operatingCompanyIds ' 
										+' AND Id NOT IN (SELECT Supplier_Invoice__c '  
										+ ' FROM Accounting_Entry__c ' 
										+ ' WHERE Company__c IN :operatingCompanyIds ' 
										+ ' AND has_exceptions__c = false ' 
										+ ' AND status__c = \'Active\''
										+ ' AND Supplier_Invoice__c!= null  AND related_accounting_entry__c = null ) '
										+ ' LIMIT ' + string.valueOf(limitRecs);
        
			    SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c');
			    soql.addFields(new Set<String>{'Id', 'Name'});
			    soql.setWhereClause(whereClause);
	    
	    		Map<Id, Supplier_Invoice__c> mNewSIs = new Map<Id, Supplier_Invoice__c>((List<Supplier_Invoice__c>)Database.query(soql.getQuery()));
	    		
	    		/*
	    		Map<Id, Supplier_Invoice__c> mNewSIs 
						= new Map<Id, Supplier_Invoice__c>(
	    											(List<Supplier_Invoice__c>)Database.Query(
	    											'SELECT Id '
	    											+' FROM Supplier_Invoice__c '
	    											+' WHERE Finalized__c = true AND Historical__c = false ' 
	    											+' AND Id NOT IN (SELECT Supplier_Invoice__c '  
	    																	+ ' FROM Accounting_Entry__c ' 
	    																	+ ' WHERE Company__c IN :operatingCompanyIds ' 
	    																	+ ' AND has_exceptions__c = false ' 
	    																	+ ' AND status__c = \'Active\''
	    																	+ ' AND Supplier_Invoice__c != null ) '
													+ ' LIMIT ' + string.valueOf(limitRecs)));
	    		*/
	    											
	    		recordIds.addAll(mNewSIs.keySet());
    		
	    		integer incrementalLimit = (integer)processJob.Max_Records__c - recordIds.size();
	    		incrementalLimit = (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) < incrementalLimit ? (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) : incrementalLimit;
	    		system.debug('incrementalLimit: ' + incrementalLimit);
	    		
	    		/*string aeQuery = 'SELECT Supplier_Invoice__c '
	    					+ ' FROM Accounting_Entry__c '
	    					+ ' WHERE Status__c = \'Active\' '
	    					+ ' AND isValidated__c = false '
	    				 	+ ' AND Validation_Ready__c = true '
	    				 	+ ' AND Supplier_Invoice__c != null '
	    				 	+ ' ORDER BY LastModifiedDate asc '
	    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);*/
	    		
	    		whereClause = 'Status__c = \'Active\' '
				    					+ ' AND isValidated__c = false '
				    				 	+ ' AND Validation_Ready__c = true '
				    				 	+ ' AND Supplier_Invoice__c != null '
				    				 	+ ' ORDER BY LastModifiedDate asc '
				    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);
        
			    soql = new SOQLUtil('Accounting_Entry__c');
			    soql.addFields(new Set<String>{'Supplier_Invoice__c'});
			    soql.setWhereClause(whereClause);
	    		 	
		    	List<Accounting_Entry__c> incrementalSIs = Database.query(soql.getQuery());
		    	for(Accounting_Entry__c ae : incrementalSIs){
		    		recordIds.add(ae.Supplier_Invoice__c);
		    	}
    		}
	    	
    	}
    	
    	system.debug('recordIds: ' + recordIds);	
		if(recordIds.size() > 0){
			whereClause += ' AND Supplier_Invoice__c IN :recordIds';
		}else{
			//KNDY-10268 - deprecating bank file and bank file line objects
			//AND Bank_File__c= null
			whereClause += ' AND Supplier_Invoice__c NOT IN (SELECT Supplier_Invoice__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND related_accounting_entry__c = null AND Has_Exceptions__c = false and status__c=\'Active\''
						+ ' AND Supplier_Invoice__c!= null  AND related_accounting_entry__c = null ) ';
		}
    }     
    /*
    public Database.QueryLocator start(Database.BatchableContext BC){ 
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<sObject> scope){
        
        Set<Id> scopeIds = new Set<Id>();

        for(Supplier_Invoice_Line__c thisInvoiceLine : (List<Supplier_Invoice_Line__c>)scope){
            scopeIds.add(thisInvoiceLine.id);
        }
 
		Savepoint sp = Database.setSavepoint();
        try{
        	
            sia.execute(scope);
            
        } catch(Exception e) {
            Database.rollback(sp);
            messages.add(new Notify.Message('Records picked up in this batch: ' + scopeIds + '. Failure message: ' + e.getMessage(), e.getStackTraceString())); //KNDY-3379 Added an ID to the failure message.
        }
    }
    
    public void finish(Database.BatchableContext info){
    	
    	if(sia.deleteAEIds.size() > 0){
    		Database.executeBatch(new AccountingEntryLineDeleteBatch(sia.deleteAEIds), 2000);
    	}
    	
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( null, messages, info);        
		MasterControlProgram.finishedBatch( this ); 
    }
    */
}