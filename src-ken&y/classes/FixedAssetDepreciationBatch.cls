public with sharing class FixedAssetDepreciationBatch implements Database.Batchable<sObject>, Process.Runnable, Database.Stateful {
	
	public string query;
	public Set<Id> companyIds;
	public Set<Id> fixedAssetIds;
	private Map<string, string> interfaceProcessorMap;
    private date today = system.today();
    public List<Notify.Message> messages = new List<Notify.Message>();
	public class FixedAssetBatchException extends Exception{}
	
	public FixedAssetDepreciationBatch(){ updateAccountingInterface(); }
	
	public void runBatch(Id companyId){
		Database.executeBatch(new FixedAssetDepreciationBatch(new Set<Id>{companyId}),200);
	}
	
	public FixedAssetDepreciationBatch(Set<Id> inCompanyIds){
		companyIds = inCompanyIds;
		updateQuery(); 
		updateAccountingInterface();
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC){  
        return Database.getQueryLocator(query);
    }
    
	public void execute(Database.BatchableContext info, List<sObject> scope){
     	List<Fixed_Asset__c> fixedAssets = (List<Fixed_Asset__c>)scope;
     	List<Fixed_Asset__c> updateFixedAssets = new List<Fixed_Asset__c>();
     	List<Fixed_Asset_Depreciation__c> insertFads = new List<Fixed_Asset_Depreciation__c>();
     	Map<string, List<sObject>> interfaceMap = new Map<string, List<sObject>>();
     	
     	//Loop through the fixed assets in scope, and organize them based on which records need to be delivered to the various processors
     	for(Fixed_Asset__c fa : fixedAssets){
     		
     		fa.Acquisition_Cost__c = fa.Acquisition_Cost__c == null ? 0 : fa.Acquisition_Cost__c;
     		FixedAssetService.systemEditable.add(fa.id);
     		string depreciationMethod = fa.depreciation_method__c;
     		if(fa.status__c == 'Active'){
	     		if(interfaceProcessorMap.containsKey(depreciationMethod)){
	     			
	     			if(interfaceMap.containsKey(depreciationMethod)){
	     				interfaceMap.get(depreciationMethod).add((sObject)fa);
	     			}
	     			else{
	     				interfaceMap.put(depreciationMethod, new List<sObject>{(sObject)fa});
	     			}
	     		}
     		}
     		
     		//KNDY-1860 - Moving capitalization processing out of batch and putting in to service class accessed by pages
     		/*
     		if(fa.status__c == 'Active' && fa.Fixed_Asset_Depreciations__r.size() == 0 && fa.in_service_date__c <= system.today()){
     			//If inactive, and there are no depreciations - make a CIP depreciation entry
     			Fixed_Asset_Depreciation__c iFad = FixedAssetService.generateFixedAssetDepreciation(fa.book_value__c, fa.in_service_date__c, fa.book_value__c, fa, FixedAssetService.TYPE_CIP);
     			iFad.depreciation_type__c = 'CIP';
     			iFad.depreciation_key__c = fa.asset_tag_number__c + 'CIP';
     			iFad.accounting_subtype__c = 'CIP';
     			insertFads.add(iFad);
     			fa.status__c = 'Active';
     			updateFixedAssets.add(fa);
     		}
     		*/
     		//KNDY-1225 - Moving retirement processing out of batch and putting in to FixedAssetRetireExt
     		/*
     		else if(fa.status__c == 'Depreciated' && fa.disposition_date__c == null){
     			//The asset has been fully depreciated and needs to have an entry move to a write off GL account
     			Fixed_Asset_Depreciation__c iFad = FixedAssetService.generateFixedAssetDepreciation(0, system.today(), fa.book_value__c, fa);
     			iFad.depreciation_type__c = 'Write Off';
     			iFad.depreciation_key__c = fa.asset_tag_number__c + 'Write Off';
     			iFad.accounting_subtype__c = 'Write Off';
     			insertFads.add(iFad);
     			fa.disposition_date__c = system.today();
     			updateFixedAssets.add(fa);
     		}
     		*/
     	}
     	
     	//system.debug('interfaceMap: ' + interfaceMap);
     	Date depreciateToDate = system.today().toStartOfMonth().addMonths(1).addDays(-1);
     	//Loop through the organized map and deliver their payload to the specified processor
     	for(string dm : interfaceMap.keySet()){
     		FixedAssetService.IDepreciation depreciation = FixedAssetService.returnDepreciationProcessor(interfaceProcessorMap.get(dm));
     		if(interfaceMap.containsKey(dm)){
     			try{
     				List<Fixed_Asset_Depreciation__c> deps = depreciation.execute(interfaceMap.get(dm), depreciateToDate, true);
     				DML.updateAsSystem(deps);
     			}catch(Exception ex){
     				String errorMessage = ex.getMessage();
            		messages.add(Notify.getErrorMessage(scope, ex.getMessage(), ex.getStackTraceString()));
     			}
     		}
     	}
     	
     	/*
     	if(updateFixedAssets.size() > 0){
     		List<Database.Saveresult> faResults = DML.updateAsSystem(updateFixedAssets, false);
     	}
     	
     	
     	if(insertFads.size() > 0){
     		List<Database.Saveresult> fadResults =  DML.insertAsSystem(insertFads, false);
     	}
     	*/
     	
    }
    
    public void finish(Database.BatchableContext info){
    	BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish(messages.size(), null, messages, info);       
		MasterControlProgram.finishedBatch( this );
    }
    
    private void updateAccountingInterface(){
    	//TODO: Expose this interface through a custom setting if customer overrides are required
    	/*
    	interfaceProcessorMap = new Map<string, string>();
     	interfaceProcessorMap.put('Straight Line', 'AccountingStraightLineDepreciation');
     	interfaceProcessorMap.put('Declining Balance', 'AccountingDecliningBalanceDepreciation');
     	interfaceProcessorMap.put('Sum of Years', 'AccountingSumOfYearsDepreciation');
     	interfaceProcessorMap.put('MACRS', 'AccountingMACRSDepreciation');
     	*/
     	interfaceProcessorMap = FixedAssetService.interfaceProcessorMap;
    }
    
    public void updateQuery(){
    	query = 'SELECT Id, name, status__c, company__c, asset_class__c,prorate_first_period__c, depreciation_count__c, depreciation_life__c, in_service_date__c, '
					+ 'gl_account__c, depreciation_method__c, depreciation_period__c, Estimated_End_of_Life__c, retirement_date__c, '
					+ 'acquisition_cost__c, residual_value__c, book_value__c, date_last_depreciated__c, next_depreciation_date__c, '
					+ 'asset_tag_number__c, fixed_asset_key__c, Company__r.Default_Transaction_Currency__c,Company__r.comp_currency__c, disposition_date__c, '
					+ 'depreciation_convention__c, declining_balance__c, Depreciable_Basis__c, Final_Depreciation_Date__c, total_depreciated_value__c, '
					+ '(SELECT Id, name, depreciation_date__c, depreciation_amount__c, depreciation_type__c, finalized__c '
					+ 'FROM Fixed_Asset_Depreciations__r '
					+ ' WHERE historical__c = false ' 
					+ 'ORDER BY depreciation_date__c desc) '
					+ 'FROM Fixed_Asset__c ';
					//+ 'WHERE status__c = \'Active\' '
					//+ 'WHERE company__c IN :companyIds ';
					//+ 'AND in_service_date__c <= :today ';
					//+ 'AND next_depreciation_date__c <= :today';
		
		//Company Ids are passed from Process.Runnable - fixedAssetIds passed from page controllers			
		if(companyIds != null){
			query += 'WHERE company__c IN :companyIds AND status__c = \'Active\' AND in_service_date__c <= :today ';
		}else if(fixedAssetIds != null){
			query += 'WHERE Id IN :fixedAssetIds AND status__c = \'Active\'  AND in_service_date__c <= :today ';
		}
		
		system.debug('query: ' + query);
    }

}