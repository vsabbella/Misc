/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class  SupplierPaymentAccountingBatch extends AccountingBatchBaseClass 
//implements Database.batchable<sObject>, Process.Runnable, Database.Stateful 
{
    // FIN-749 Moved to super class -AccountingBatchBaseClass.
    /*       
    public string query;
    public set<Id> operatingCompanyIds = new set<Id>();
    public List<Notify.Message> messages = new List<Notify.Message>();
    
    public void runBatch( id companyid ) { 		// Process.Runnable implementation 
    	Database.executebatch( new SupplierPaymentAccountingBatch(new set<id>{companyid} ), 10);
    } 
	*/
    
    public SupplierPaymentAccountingBatch() 
    {
        super('Supplier_Payment__c');
    }
    
    public SupplierPaymentAccountingBatch(set<Id> operatingCompIds){
        super('Supplier_Payment__c');
        operatingCompanyIds = operatingCompIds;
        
        // KNDY 1550 / KNDY 1582
        // Commented below logic to fetch dynamic query as we need to flaten the query and the details are already being queried in the GenerateAccountingService class
        //AccountingRuleService ARS = new AccountingRuleService();
        //String dynamicQuery = ARS.getQueryStringList(new List<String>{'Supplier Payment'});
        
		/*
        query='select ID, Name, Payment_Amount__c, Bank_Account__c, Date_Paid__c, Supplier__c, Finalized__c, Company__c, Currency__c, Payment_Method__c'+ 
              ' from Supplier_Payment__c where Company__c in : operatingCompanyIds' +
              ' and Finalized__c = true' +
              ' and finalized_date__c != null ' + 
              ' and historical__c = false ' + 
              ' and transaction_date__c != null' +
              ' and id not in (Select Supplier_Payment__c from Accounting_Entry__c where company__c in :operatingCompanyIds and void__c = false  ' +
              //FIN-690 Regenerate Accounting for AE with Exceptions
              ' and Has_Exceptions__c=false and status__c=\'Active\') ';*/
       
    }
    //FIN-749 Large Data Accounting
    //Override abstract method of super to query for specifics with respect to source doc
    public override void createBaseQuery()
    {
        BaseQuery='select ID, Supplier_Payment__c '+ 
                 + ' from Supplier_Payment_Line__c';
    }
                                                
    public override void createwhereClause()
    {
        whereclause=    ' where Supplier_Payment__r.Company__c in : operatingCompanyIds' +
                        ' and Finalized__c = true' +
                        ' and Supplier_Payment__r.finalized_date__c != null ' + 
                        ' and historical__c = false ' + 
                        ' and Supplier_Payment__r.transaction_date__c != null';
                        
		
		if(processJob != null){
    		
    		if(processJob.Max_Records__c != null){
    			
	    		integer limitRecs = (integer)processJob.Max_Records__c;
	    		limitRecs = limitRecs < 1 ? 1 : limitRecs;
	    		limitRecs = limitRecs > LIMITS.getLimitQueryRows() ? LIMITS.getLimitQueryRows() : limitRecs;
    			
    			system.debug('limitRecs: ' + limitRecs);
    			
    			SOQLUtil soql = new SOQLUtil('Supplier_Payment__c');
			    soql.addFields(new Set<String>{'Id'});
			    ////KNDY-10268 - deprecating bank file and bank file line objects
			    // AND Bank_File__c= null
			    soql.setWhereClause('Finalized__c = true AND Historical__c = false AND Company__c IN :operatingCompanyIds ' 
									+' AND Id NOT IN (SELECT Supplier_Payment__c '  
									+ ' FROM Accounting_Entry__c ' 
									+ ' WHERE Company__c IN :operatingCompanyIds ' 
									+ ' AND has_exceptions__c = false ' 
									+ ' AND status__c = \'Active\''
									+ ' AND Supplier_Payment__c!= null  AND related_accounting_entry__c = null ) '
									+ ' LIMIT ' + string.valueOf(limitRecs));
	    		
	    		Map<Id, Supplier_Payment__c> mNewSPs = new Map<Id, Supplier_Payment__c>( (List<Supplier_Payment__c>) Database.query(soql.getQuery()));
	    											
	    		/*Map<Id, Supplier_Payment__c> mNewSPs 
						= new Map<Id, Supplier_Payment__c>(
	    											(List<Supplier_Payment__c>)Database.Query(
	    											'SELECT Id '
	    											+' FROM Supplier_Payment__c '
	    											+' WHERE Finalized__c = true AND Historical__c = false ' 
	    											+' AND Id NOT IN (SELECT Supplier_Payment__c '  
	    																	+ ' FROM Accounting_Entry__c ' 
	    																	+ ' WHERE Company__c IN :operatingCompanyIds ' 
	    																	+ ' AND has_exceptions__c = false ' 
	    																	+ ' AND status__c = \'Active\''
	    																	+ ' AND Supplier_Payment__c != null ) '
													+ ' LIMIT ' + string.valueOf(limitRecs)));*/
	    											
	    		recordIds.addAll(mNewSPs.keySet());
    		
	    		integer incrementalLimit = (integer)processJob.Max_Records__c - recordIds.size();
	    		incrementalLimit = (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) < incrementalLimit ? (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) : incrementalLimit;
	    		system.debug('incrementalLimit: ' + incrementalLimit);
	    		
	    		/*string aeQuery = 'SELECT Supplier_Payment__c '
	    					+ ' FROM Accounting_Entry__c '
	    					+ ' WHERE Status__c = \'Active\' '
	    					+ ' AND isValidated__c = false '
	    				 	+ ' AND Validation_Ready__c = true '
	    				 	+ ' AND Supplier_Payment__c != null '
	    				 	+ ' ORDER BY LastModifiedDate asc '
	    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);*/
	    		
	    		String aeWhereClause = 'Status__c = \'Active\' '
			    					+ ' AND isValidated__c = false '
			    				 	+ ' AND Validation_Ready__c = true '
			    				 	+ ' AND Supplier_Payment__c != null '
			    				 	+ ' ORDER BY LastModifiedDate asc '
			    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);
        
			    soql = new SOQLUtil('Accounting_Entry__c');
			    soql.addFields(new Set<String>{'Supplier_Payment__c'});
			    soql.setWhereClause(aeWhereClause);
	    		 	
		    	List<Accounting_Entry__c> incrementalSPs = Database.query(soql.getQuery());
		    	for(Accounting_Entry__c ae : incrementalSPs){
		    		recordIds.add(ae.supplier_payment__c);
		    	}
    		}
	    	
    	}
    	
    	system.debug('recordIds: ' + recordIds);	
		if(recordIds.size() > 0){
			whereClause += ' AND Supplier_Payment__c IN :recordIds';
		}else{
			//KNDY-10268 - deprecating bank file and bank file line objects
			// AND Bank_File__c= null
			whereClause += ' AND Supplier_Payment__c NOT IN (SELECT Supplier_Payment__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND has_exceptions__c = false AND status__c = \'Active\''
							+ ' AND Supplier_Payment__c!= null  AND related_accounting_entry__c = null ) ';
		}
    }  
        // FIN-749 Moved to super class -AccountingBatchBaseClass.
        /*          
    public Database.QueryLocator start(Database.BatchableContext BC){ 
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Supplier_Payment__c> scope){
        List<Accounting_Entry__c> acctEntryList = new List<Accounting_Entry__c>();
        //GenerateAccountingService GAS = new GenerateAccountingService();
        SupplierPaymentAccounting spa = new SupplierPaymentAccounting();
          
        Set<Id> supplierPaymentIds = new Set<Id>();
        Map<Id,Supplier_Payment__c> sPaymentMapUpd = new Map<Id,Supplier_Payment__c>();
                
        for(Supplier_Payment__c thisSPayment: scope){
            supplierPaymentIds.add(thisSPayment.id);
        }
        Savepoint sp = Database.setSavepoint();
        try{
            //GAS.createSupplierPaymentAccounting(scope);
            spa.execute(scope);
                			
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