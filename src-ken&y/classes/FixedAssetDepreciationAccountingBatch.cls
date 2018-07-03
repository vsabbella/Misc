/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class FixedAssetDepreciationAccountingBatch extends AccountingBatchBaseClass 
//implements Database.Batchable<sObject>, Process.Runnable
 {
        // FIN-749 Moved to super class -AccountingBatchBaseClass.
        /*      	
	
	public string query;
    public set<Id> operatingCompanyIds = new set<Id>();
    public List<Notify.Message> messages = new List<Notify.Message>();
    
    
    public void runBatch( id companyid ) { 		// Process.Runnable implementation 
    	Database.executebatch( new FixedAssetDepreciationAccountingBatch(new set<id>{companyid} ), 200);
    }*/
  // FIN-749 Pass SD Name to super constructor so that it will instantiate respective Accounting worker class.     
    public FixedAssetDepreciationAccountingBatch() 
    {
        super('Fixed_Asset_Depreciation__c');
    }
    
    public FixedAssetDepreciationAccountingBatch(set<Id> operatingCompIds){
        super('Fixed_Asset_Depreciation__c');        
    	operatingCompanyIds = operatingCompIds;
    	/*AccountingRuleService ARS = new AccountingRuleService();
    	updateQuery();*/
    }
    //FIN-749 Large Data Accounting
    //Override abstract method of super to query for specifics with respect to source doc
    public override void createBaseQuery()
    {
        BaseQuery=    'SELECT id, name, finalized__c, company__c, value_upon_depreciation__c, accounting_subtype__c, '
    				+ 'depreciation_amount__c, depreciation_date__c, depreciation_key__c, depreciation_type__c, fixed_asset__c, fixed_asset__r.gl_account__c, '
    				+ 'currency__c, gl_date__c '
    				+ 'FROM Fixed_Asset_Depreciation__c ';
    }
    
    public override void createwhereClause()
    {
        whereclause=     ' WHERE finalized__c = true '
         				+ ' AND historical__c = false '
        				+ ' AND fixed_asset__r.fixed_asset_type__c = \'Accounting\'';
                        //+' AND id not in (Select Fixed_Asset_Depreciation__c from Accounting_Entry__c where void__c = false '
                         //FIN-690 Regenerate Accounting for AE with Exceptions
                        //+' and Has_Exceptions__c=false and status__c=\'Active\') ';
        
        if(processJob != null){
    		
    		if(processJob.Max_Records__c != null){
    			
	    		integer limitRecs = (integer)processJob.Max_Records__c;
	    		limitRecs = limitRecs < 1 ? 1 : limitRecs;
	    		limitRecs = limitRecs > LIMITS.getLimitQueryRows() ? LIMITS.getLimitQueryRows() : limitRecs;
    			
    			system.debug('limitRecs: ' + limitRecs);
    		
    		    String whereClause = 'Finalized__c = true AND Historical__c = false AND Company__c IN :operatingCompanyIds ' 
	    											+' AND Id NOT IN (SELECT Fixed_Asset_Depreciation__c '  
	    																	+ ' FROM Accounting_Entry__c ' 
	    																	+ ' WHERE Company__c IN :operatingCompanyIds ' 
	    																	+ ' AND has_exceptions__c = false ' 
	    																	+ ' AND status__c = \'Active\''
	    																	+ ' AND Fixed_Asset_Depreciation__c != null ) '
													+ ' LIMIT ' + string.valueOf(limitRecs);//KNDY-8796
				SOQLUtil soql = new SOQLUtil('Fixed_Asset_Depreciation__c',true);
 				soql.addFields(new Set<String>{'Id'});
 				soql.setWhereClause(whereClause);
                Map<Id, Fixed_Asset_Depreciation__c> mNewCIs 
						= new Map<Id, Fixed_Asset_Depreciation__c>(
	    											(List<Fixed_Asset_Depreciation__c>)Database.Query(soql.getQuery()));
                /*
	    		Map<Id, Fixed_Asset_Depreciation__c> mNewCIs 
						= new Map<Id, Fixed_Asset_Depreciation__c>(
	    											(List<Fixed_Asset_Depreciation__c>)Database.Query(
	    											'SELECT Id '
	    											+' FROM Fixed_Asset_Depreciation__c '
	    											+' WHERE Finalized__c = true AND Historical__c = false ' 
	    											+' AND Id NOT IN (SELECT Fixed_Asset_Depreciation__c '  
	    																	+ ' FROM Accounting_Entry__c ' 
	    																	+ ' WHERE Company__c IN :operatingCompanyIds ' 
	    																	+ ' AND has_exceptions__c = false ' 
	    																	+ ' AND status__c = \'Active\''
	    																	+ ' AND Work_Order__c != null ) '
													+ ' LIMIT ' + string.valueOf(limitRecs))); */
	    											
	    		recordIds.addAll(mNewCIs.keySet());
    		
	    		integer incrementalLimit = (integer)processJob.Max_Records__c - recordIds.size();
	    		incrementalLimit = (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) < incrementalLimit ? (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows()) : incrementalLimit;
	    		system.debug('incrementalLimit: ' + incrementalLimit);
	    		
	    		 whereClause = 'Status__c = \'Active\' '
	    					+ ' AND isValidated__c = false '
	    				 	+ ' AND Validation_Ready__c = true '
	    				 	+ ' AND Fixed_Asset_Depreciation__c != null '
	    				 	+ ' ORDER BY LastModifiedDate asc '
	    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);//KNDY-8796
				soql = new SOQLUtil('Accounting_Entry__c',true);
 				soql.addFields(new Set<String>{'Fixed_Asset_Depreciation__c '});
 				soql.setWhereClause(whereClause);
                /*
	    		string aeQuery = 'SELECT Fixed_Asset_Depreciation__c '
	    					+ ' FROM Accounting_Entry__c '
	    					+ ' WHERE Status__c = \'Active\' '
	    					+ ' AND isValidated__c = false '
	    				 	+ ' AND Validation_Ready__c = true '
	    				 	+ ' AND Fixed_Asset_Depreciation__c != null '
	    				 	+ ' ORDER BY LastModifiedDate asc '
	    				 	+ ' LIMIT ' +  string.valueOf(incrementalLimit);
	    				 	
		    	List<Accounting_Entry__c> incrementalCIs = Database.query(aeQuery);*/
                List<Accounting_Entry__c> incrementalCIs = Database.query(soql.getQuery() );
		    	for(Accounting_Entry__c ae : incrementalCIs){
		    		recordIds.add(ae.Fixed_Asset_Depreciation__c);
		    	}
    		}
	    	
    	}
    	
    	system.debug('recordIds: ' + recordIds);	
		if(recordIds.size() > 0){
			whereClause += ' AND id IN :recordIds';
		}else{
			whereClause += ' AND id NOT IN (SELECT Fixed_Asset_Depreciation__c FROM Accounting_Entry__c WHERE Company__c IN :operatingCompanyIds AND has_exceptions__c = false AND status__c = \'Active\') ';
		}               

    }  
        // FIN-749 Moved to super class -AccountingBatchBaseClass.
        /*          
    public Database.QueryLocator start(Database.BatchableContext BC){    
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<sObject> scope){
        
        Savepoint sp = Database.setSavepoint();
    	try{
    		
    		AccountingProcessFixedAssetDepreciation depreciationAccounting = new AccountingProcessFixedAssetDepreciation();
 			depreciationAccounting.execute(scope);
    	}catch(Exception e) {
 			system.debug('exception: ' + e);
            Database.rollback(sp);
            messages.add(new Notify.Message(e.getMessage(), e.getStackTraceString()));
        }
    	
    }
    
    public void finish(Database.BatchableContext info){
        Map<Id, String> chatterMessages = BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
        MasterControlProgram.finishedBatch( this ); 
        KSE.sendEmailBatchCompletion('Generate Fixed Asset Depreciation Accounting Batch Complete.');
    }
    
    
    public void updateQuery(){
    	query = 'SELECT id, name, finalized__c, company__c, value_upon_depreciation__c, accounting_subtype__c, '
    				+ 'depreciation_amount__c, depreciation_date__c, depreciation_key__c, depreciation_type__c, fixed_asset__c, fixed_asset__r.gl_account__c, '
    				+ 'currency__c, gl_date__c '
    				+ 'FROM Fixed_Asset_Depreciation__c '
    				+ 'WHERE finalized__c = true '
    				+' AND id not in (Select Fixed_Asset_Depreciation__c from Accounting_Entry__c where void__c = false '
                     //FIN-690 Regenerate Accounting for AE with Exceptions
                    +' and Has_Exceptions__c=false and status__c=\'Active\') '
    				+ 'AND fixed_asset__r.fixed_asset_type__c = \'Accounting\'';
    }
*/
}