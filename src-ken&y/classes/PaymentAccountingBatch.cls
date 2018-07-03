/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class PaymentAccountingBatch extends AccountingBatchBaseClass 
//implements Database.batchable<sObject>, Process.Runnable2, Database.Stateful 
{
    public paymentAccountingBatch()
    {
         super('Payment__c');
       
    }

    public paymentAccountingBatch(set<Id> operatingCompIds){
        super('Payment__c');
        operatingCompanyIds = operatingCompIds;
        
}    
    //Override abstract method of super to query for specifics with respect to source doc
    public override void createBaseQuery()
    {
        BaseQuery='SELECT Id, Payment__c '
   			    + ' FROM payment_Line__c ';
    }
                                                
    public override void createwhereClause()
    {
    	
    	whereclause=    ' WHERE (payment__r.From_Company__c IN :operatingCompanyIds OR payment__r.to_Company__c IN :operatingCompanyIds)'
	   			+ ' AND payment__r.From_Company__c != null '
	   			+ ' AND payment__r.to_Company__c != null '
	   			+ ' AND Finalized__c = true '
	   			+ ' AND payment__r.Finalized_Date__c != null '
	   			+ ' AND payment__r.Transaction_Date__c != null ';
	   			
    	if(processJob != null){
    		
    		if(processJob.Max_Records__c != null){
    			
	    		integer limitRecs = (integer)processJob.Max_Records__c;
	    		limitRecs = limitRecs < 1 ? 1 : limitRecs;
	    		limitRecs = limitRecs > LIMITS.getLimitQueryRows() ? LIMITS.getLimitQueryRows() : limitRecs;
    			
    			system.debug('limitRecs: ' + limitRecs);
    		
    			SOQLUtil soql = new SOQLUtil('Payment__c');
			    soql.addFields(new Set<String>{'Id'});
	    		soql.setWhereClause('Finalized__c = true AND Company__c IN :operatingCompanyIds ' 
	    											+' AND Id NOT IN (SELECT Payment__c '  
	    																	+ ' FROM Accounting_Entry__c ' 
	    																	+ ' WHERE (payment__r.From_Company__c IN :operatingCompanyIds OR payment__r.to_Company__c IN :operatingCompanyIds) ' 
	    																	+ ' AND has_exceptions__c = false ' 
	    																	+ ' AND status__c = \'Active\''
	    																	+ ' AND Payment__c != null ) '
													+ ' LIMIT ' + string.valueOf(limitRecs));
	    		Map<Id, Payment__c> mNewPayments = new Map<Id, Payment__c>((List<Payment__c>)Database.Query(soql.getQuery()));
	    											
	    		recordIds.addAll(mNewPayments.keySet());
    		
	    		integer incrementalLimit = (integer)processJob.Max_Records__c - recordIds.size();
	    		incrementalLimit = (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) < incrementalLimit ? (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) : incrementalLimit;
	    		system.debug('incrementalLimit: ' + incrementalLimit);
	    		
	    		String aeWhereClause = 'Status__c = \'Active\' '
	    					+ ' AND isValidated__c = false '
	    				 	+ ' AND Validation_Ready__c = true '
	    				 	+ ' AND Payment__c != null '
	    				 	+ ' ORDER BY LastModifiedDate asc '
	    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);
	    				 	
			    soql = new SOQLUtil('Accounting_Entry__c');
			    soql.addFields(new Set<String>{'Payment__c'});
			    soql.setWhereClause(aeWhereClause);
	    		 	
		    	List<Accounting_Entry__c> incrementalPayments = Database.query(soql.getQuery());
		    	for(Accounting_Entry__c ae : incrementalPayments){
		    		recordIds.add(ae.Payment__c);
		    	}
    		}
	    	
    	}
    	
    	system.debug('recordIds: ' + recordIds);	
		if(recordIds.size() > 0){
			whereClause += ' AND Payment__c IN :recordIds';
		}else{
			whereClause += ' AND Payment__c NOT IN (SELECT Payment__c FROM Accounting_Entry__c WHERE (payment__r.From_Company__c IN :operatingCompanyIds OR payment__r.to_Company__c IN :operatingCompanyIds) AND has_exceptions__c = false AND status__c = \'Active\') ';
		}

    }
}