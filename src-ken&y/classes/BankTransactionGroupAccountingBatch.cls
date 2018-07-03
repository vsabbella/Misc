/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class BankTransactionGroupAccountingBatch extends AccountingBatchBaseClass  {
     public BankTransactionGroupAccountingBatch()
        {
             super('Bank_Transaction_Group__c');
           
        }

    public BankTransactionGroupAccountingBatch(set<Id> operatingCompIds){
        super('Bank_Transaction_Group__c');
        operatingCompanyIds = operatingCompIds;
        

    }    
    //Override abstract method of super to query for specifics with respect to source doc
    public override void createBaseQuery(){
        BaseQuery='SELECT Id, Bank_Transaction_Group__c '
   			    + ' FROM Bank_Transaction__c ';
    }
                                                
    public override void createwhereClause()
    {
    	
    	whereclause=    'WHERE Bank_Transaction_Group__r.Company__c IN :operatingCompanyIds '
	   			+ ' AND Finalized__c = true '
	   			+ ' AND Historical__c = false '
	   			+ ' AND Bank_Transaction_Group__r.Finalized_Date__c != null '
	   			+ ' AND Bank_Transaction_Group__r.Transaction_Date__c != null ';
	   			
    	if(processJob != null){
    		
    		if(processJob.Max_Records__c != null){
    			
	    		integer limitRecs = (integer)processJob.Max_Records__c;
	    		limitRecs = limitRecs < 1 ? 1 : limitRecs;
	    		limitRecs = limitRecs > LIMITS.getLimitQueryRows() ? LIMITS.getLimitQueryRows() : limitRecs;
    			
    			system.debug('limitRecs: ' + limitRecs);
    		
	    		Map<Id, Bank_Transaction_Group__c> mNewBtgs 
						= new Map<Id, Bank_Transaction_Group__c>(
	    											(List<Bank_Transaction_Group__c>)Database.Query(
	    											'SELECT Id '
	    											+' FROM Bank_Transaction_Group__c '
	    											+' WHERE Finalized__c = true AND Historical__c = false AND Company__c IN :operatingCompanyIds ' 
	    											+' AND Id NOT IN (SELECT Bank_Transaction_Group__c '  
	    																	+ ' FROM Accounting_Entry__c ' 
	    																	+ ' WHERE Company__c IN :operatingCompanyIds ' 
	    																	+ ' AND has_exceptions__c = false ' 
	    																	+ ' AND status__c = \'Active\''
	    																	+ ' AND Bank_Transaction_Group__c != null ) '
													+ ' LIMIT ' + string.valueOf(limitRecs)));
	    											
	    		recordIds.addAll(mNewBtgs.keySet());
    		
	    		integer incrementalLimit = (integer)processJob.Max_Records__c - recordIds.size();
	    		incrementalLimit = (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) < incrementalLimit ? (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) : incrementalLimit;
	    		system.debug('incrementalLimit: ' + incrementalLimit);
	    		
	    		string aeQuery = 'SELECT Bank_Transaction_Group__c '
	    					+ ' FROM Accounting_Entry__c '
	    					+ ' WHERE Status__c = \'Active\' '
	    					+ ' AND isValidated__c = false '
	    				 	+ ' AND Validation_Ready__c = true '
	    				 	+ ' AND Bank_Transaction_Group__c != null '
	    				 	+ ' ORDER BY LastModifiedDate asc '
	    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);
	    				 	
		    	List<Accounting_Entry__c> incrementalBTGs = Database.query(aeQuery);
		    	for(Accounting_Entry__c ae : incrementalBTGs){
		    		recordIds.add(ae.Bank_Transaction_Group__c);
		    	}
    		}
	    	
    	}
    	
    	system.debug('recordIds: ' + recordIds);	
		if(recordIds.size() > 0){
			whereClause += ' AND Bank_Transaction_Group__c IN :recordIds';
		}else{
			whereClause += ' AND Bank_Transaction_Group__c NOT IN (SELECT Bank_Transaction_Group__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND has_exceptions__c = false AND status__c = \'Active\') ';
		}

    }
}