public with sharing class FixedAssetDepreciationRollbackBatch implements Database.Batchable<sObject>, Process.Runnable{
	
	public string query;
    public set<Id> operatingCompanyIds = new set<Id>();
    
    public FixedAssetDepreciationRollbackBatch() {}
    
    public void runBatch( id companyid ) { 		// Process.Runnable implementation 
    	Database.executebatch( new FixedAssetDepreciationRollbackBatch(new set<id>{companyid} ), 200);
    }
    
    public FixedAssetDepreciationRollbackBatch(set<Id> operatingCompIds){
    	operatingCompanyIds = operatingCompIds;
    	updateQuery();
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){    
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<sObject> scope){
    	List<Fixed_Asset_Depreciation__c> deleteFads = new List<Fixed_Asset_Depreciation__c>();
    	 Set<Id> fixedAssetList = new Set<Id>();
		for(Fixed_Asset_Depreciation__c fad : (List<Fixed_Asset_Depreciation__c>)scope){
			fad.finalized__c = false;
			fad.finalized_hidden__c = false;
			deleteFads.add(fad);
			fixedAssetList.add( fad.fixed_asset__c);  
		}
    	
    	if(deleteFads.size() > 0){
    		List<Accounting_Entry__c> aeList = [SELECT id,name,Fixed_Asset_Depreciation__c 
                                                    FROM Accounting_Entry__c 
                                                    WHERE Fixed_Asset_Depreciation__c IN :deleteFads ];
            
            //System.DEBUG('all acc entries generated for FADS'+aeList);
            
            for(Accounting_Entry__c ae:aeList){
                ae.Status__c = 'Obsolete';
            }

            DML.updateAsSystem(deleteFads);
            DML.updateAsSystem(aeList);
            DML.deleteAsSystem(deleteFads);
            
            
            //----Query all the fixed assets for which the fads are rollback
      	List<Fixed_Asset__c> fAsAfterRollBack  =  [SELECT id ,status__c 
     													FROM Fixed_Asset__c 
     													WHERE Id IN :fixedAssetList ];  
     	//System.debug('fAsAfterRollBack'+fAsAfterRollBack);  
     	  	
     	//---- Make the status of Fixed Asset back to Active after Rollback------
 		for(Fixed_Asset__c fa:fAsAfterRollBack){
 			List<Fixed_Asset_Depreciation__c> fads = fa.Fixed_Asset_Depreciations__r ;    
 			if(fads.size()==0 && fa.Status__c=='Depreciated'){
 				fa.Status__c = 'Active';	
 			} 
 		} 
 		
 		DML.updateAsSystem(fAsAfterRollBack); 
 		//System.debug('Fixed assets after updating---'+fAsAfterRollBack); 
    	}
    }
    
    public void finish(Database.BatchableContext info){

		Notify.sendEmailBatchFinish( null, new List<Notify.Message>(), info);        
		MasterControlProgram.finishedBatch( this ); 
    }
    
    
    public void updateQuery(){
    	query = 'SELECT Id ,Fixed_Asset__c ' 
				+ 'FROM Fixed_Asset_Depreciation__c '
				+ 'WHERE id not in (Select Fixed_Asset_Depreciation__c from Accounting_Entry__c where void__c = false and Period_Status__c = \'Closed\') ';
    }
}