public with sharing class FixedAssetDepreciationRollbackExt {
	
	private Apexpages.StandardController fixedAssetController;
	public Fixed_Asset_Depreciation__c fad {get;set;}
	public boolean renderRollback {get;set;}
	
	public FixedAssetDepreciationRollbackExt(Apexpages.StandardController controller){
		fixedAssetController = controller;	
		updateRollbackRecord();
	}
	
	public void updateRollbackRecord(){


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    */
//V1
SOQLUtil soql = new SOQLUtil('Fixed_Asset_Depreciation__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','name','depreciation_amount__c','depreciation_date__c','depreciation_type__c','finalized__c','fixed_asset__c','fixed_asset__r.gl_account__c'
});
    string fId = fixedAssetController.getId();        
    soql.setWhereClause('Fixed_Asset__c = :fId AND id not in (Select Fixed_Asset_Depreciation__c from Accounting_Entry__c where void__c = false)');
soql.setOrderByClause('depreciation_date__c desc');
soql.setLimit(1);
    List<Fixed_Asset_Depreciation__c> fads = Database.query(soql.getQuery());
        



		if(fads.size()>0){
			fad = fads[0];
			renderRollback = true;
		}
		else{
			renderRollback = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.No_available_depreciation_records_that_can_be_rolled_back));
		}
	}
	
	public void btn_Rollback(){
		if(fad != null){
			DML.deleteAsUser(new List<Fixed_Asset_Depreciation__c>{fad});
			renderRollback = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, Label.Rollback_Complete));
		}
		else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.No_available_depreciation_records_that_can_be_rolled_back));
		}
	}
}