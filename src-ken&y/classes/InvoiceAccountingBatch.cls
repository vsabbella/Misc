/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class InvoiceAccountingBatch extends AccountingBatchBaseClass 
//implements Database.batchable<sObject>, Process.Runnable2, Database.Stateful 
{
    public InvoiceAccountingBatch()
    {
         super('Invoice__c');
       
    }

    public InvoiceAccountingBatch(set<Id> operatingCompIds){
        super('Invoice__c');
        operatingCompanyIds = operatingCompIds;
        
}    
    //Override abstract method of super to query for specifics with respect to source doc
    public override void createBaseQuery()
    {
        BaseQuery='SELECT Id, invoice__c '
   			    + ' FROM Invoice_Line__c ';
    }
                                                
    public override void createwhereClause()
    {
    	
    	whereclause=    ' WHERE (Invoice__r.From_Company__c IN :operatingCompanyIds OR Invoice__r.To_Company__c IN :operatingCompanyIds)'
	   			+ ' AND Invoice__r.From_Company__c != null '
	   			+ ' AND Invoice__r.To_Company__c != null '
	   			+ ' AND Finalized__c = true '
	   			+ ' AND Invoice__r.Finalized_Date__c != null '
	   			+ ' AND Invoice__r.Transaction_Date__c != null ';
	   			
    	if(processJob != null){
    		
    		if(processJob.Max_Records__c != null){
    			
	    		integer limitRecs = (integer)processJob.Max_Records__c;
	    		limitRecs = limitRecs < 1 ? 1 : limitRecs;
	    		limitRecs = limitRecs > LIMITS.getLimitQueryRows() ? LIMITS.getLimitQueryRows() : limitRecs;
    			
    			system.debug('limitRecs: ' + limitRecs);
    		
    			SOQLUtil soql = new SOQLUtil('Invoice__c');
			    soql.addFields(new Set<String>{'Id'});
	    		soql.setWhereClause('Finalized__c = true AND Company__c IN :operatingCompanyIds' 
	    							+' AND Id NOT IN (SELECT Invoice__c '  
									+ ' FROM Accounting_Entry__c ' 
									+ ' WHERE (Invoice__r.From_Company__c IN :operatingCompanyIds OR Invoice__r.To_Company__c IN :operatingCompanyIds) ' 
									+ ' AND has_exceptions__c = false ' 
									+ ' AND status__c = \'Active\''
									+ ' AND Invoice__c != null ) '
									+ ' LIMIT ' + string.valueOf(limitRecs));
	    		Map<Id, Invoice__c> mNewInvs = new Map<Id, Invoice__c>((List<Invoice__c>)Database.Query(soql.getQuery()));
	    											
	    		recordIds.addAll(mNewInvs.keySet());
    		
	    		integer incrementalLimit = (integer)processJob.Max_Records__c - recordIds.size();
	    		incrementalLimit = (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) < incrementalLimit ? (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) : incrementalLimit;
	    		system.debug('incrementalLimit: ' + incrementalLimit);
	    		
	    		string aeWhereClause = ' Status__c = \'Active\' '
	    					+ ' AND isValidated__c = false '
	    				 	+ ' AND Validation_Ready__c = true '
	    				 	+ ' AND Invoice__c != null '
	    				 	+ ' ORDER BY LastModifiedDate asc '
	    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);
	    				 	
			    soql = new SOQLUtil('Accounting_Entry__c');
			    soql.addFields(new Set<String>{'Invoice__c'});
			    soql.setWhereClause(aeWhereClause);
		    	List<Accounting_Entry__c> incrementalINVs = Database.query(soql.getQuery());
		    	for(Accounting_Entry__c ae : incrementalINVs){
		    		recordIds.add(ae.Invoice__c);
		    	}
    		}
	    	
    	}
    	
    	system.debug('recordIds: ' + recordIds);	
		if(recordIds.size() > 0){
			whereClause += ' AND Invoice__c IN :recordIds';
		}else{
			whereClause += ' AND Invoice__c NOT IN (SELECT Invoice__c FROM Accounting_Entry__c WHERE (Invoice__r.From_Company__c IN :operatingCompanyIds OR Invoice__r.To_Company__c IN :operatingCompanyIds) AND has_exceptions__c = false AND status__c = \'Active\') ';
		}

    }
}