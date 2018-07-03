public with sharing class FixedAssetCapitalizeExt {
	
	public Apexpages.Standardsetcontroller ssCon {get;set;}
	public Apexpages.standardcontroller con {get;set;}
	public boolean hasInvalid {get;set;}
	public boolean isValid {get;set;}
	public boolean missingRecs {get;set;}
	public Map<Id, Boolean> mValidations {get;set;}
	
	public FixedAssetCapitalizeExt(Apexpages.Standardsetcontroller ssController){
		ssCon = ssController;
		validateCapitalizations();
		addCapitalizeMessages();
	}
	
	
	public FixedAssetCapitalizeExt(Apexpages.Standardcontroller controller){
		con = controller;
		isValid = validateCapitalization();
	}
	
	/* Single Asset */
	public boolean validateCapitalization(){
		boolean isValid = true;


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    */
SOQLUtil soql = new SOQLUtil('Fixed_Asset__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','depreciation_count__c','depreciable_basis__c','tax_book__r.corporate__c','in_service_date__c'
});
    string cId = con.getId();
    soql.setWhereClause('Id = :cId');
Fixed_Asset__c fa = Database.query(soql.getQuery());


		if(fa.depreciation_count__c > 0){
			isValid = false;
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, Label.Cannot_capitalize_asset_that_has_undergone_depreciation_or_capitalization));
		}
		if(fa.depreciable_basis__c <= 0){
			isValid = false;
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, Label.The_depreciable_basis_must_be_greater_than_zero));
		}
		if(!fa.Tax_Book__r.corporate__c){
			isValid = false;
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, Label.Use_a_Corporate_Tax_Book_to_capitalize_fixed_assets));
		}
		if(fa.in_service_date__c > system.today()){
			isValid = false;
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, Label.Cannot_capitalize_asset_that_has_future_in_service_date));
		}
		return isValid;
	}
	
	public void btn_Capitalize(){
		//Revalidate this asset can still be capitalized, and perform capitalization
		if(validateCapitalization()){
			Savepoint sp = Database.setSavePoint();
			try{
				Fixed_Asset__c fa = (Fixed_Asset__c)con.getRecord();
				fa.status__c = FixedAssetService.STATUS_ACTIVE;
				DML.updateAsSystem(fa);
				FixedAssetService.capitalizeFixedAssets(new Set<Id>{fa.Id});
				Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.CONFIRM, Label.Successfully_capitalized_this_fixed_asset));
			}catch(Exception ex){
				Database.rollback(sp);
				Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
				system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
			}
			isValid = false;
		}
	}
	
	/* Multiple Assets */
	public void validateCapitalizations(){
		mValidations = new Map<Id, Boolean>();
		hasInvalid = false;
		isValid = false;

/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    */
SOQLUtil soql = new SOQLUtil('Fixed_Asset__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','depreciation_count__c','depreciable_basis__c','tax_book__r.corporate__c','in_service_date__c'
});
    
    set<SObject> sCid = new set<SObject>(ssCon.getSelected());        
    soql.setWhereClause('Id IN :sCid');
List<Fixed_Asset__c> fas = Database.query(soql.getQuery());


		system.debug('selected fas: ' + fas);
		missingRecs = fas.size() > 0 ? true : false;
								
		for(Fixed_Asset__c fa : fas){
			boolean faValid = true;
			if(fa.depreciation_count__c > 0){
				faValid = false;
			}
			if(fa.depreciable_basis__c <= 0){
				faValid = false;
			}
			if(!fa.Tax_Book__r.corporate__c){
				faValid = false;
			}
			if(fa.in_service_date__c > system.today()){
				faValid = false;
			}
			
			if(faValid){
				isValid = true;
			}else{
				hasInvalid = true;	
			}
			mValidations.put(fa.Id, faValid);
		}	
		system.debug('isValid: ' + isValid);
		system.debug('hasInvalid: ' + hasInvalid);
	}
	
	public void addCapitalizeMessages(){
		if(!isValid){
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, Label.There_are_no_FixedAssets_that_are_valid_for_capitalization));
		}else if(hasInvalid){
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.WARNING, Label.There_are_one_or_more_FixedAssets_that_are_not_valid_for_capitalization));
		}
	}
	
	public void btn_CapitalizeAssets(){
		//Revalidate this asset can still be capitalized, and perform capitalization
		validateCapitalizations();
		Savepoint sp = Database.setSavePoint();
		try{
			Set<Id> fixedAssetIds = new Set<Id>();
			Map<Id, Fixed_Asset__c> mFixedAssets = new Map<Id, Fixed_Asset__c>();
			for(Fixed_Asset__c fa : (List<Fixed_Asset__c>)ssCon.getSelected()){
				if(mValidations.containsKey(fa.Id)){
					if(mValidations.get(fa.Id)){
						fa.status__c = FixedAssetService.STATUS_ACTIVE;
						mFixedAssets.put(fa.Id, fa);
					}
				}
			}
			if(mFixedAssets.values().size() > 0){
				DML.updateAsUser(mFixedAssets.values());
				FixedAssetService.capitalizeFixedAssets(mFixedAssets.keySet());
				Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.CONFIRM, Label.Successfully_capitalized_valid_FixedAssets));
			}else{
				Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, Label.Select_a_FixedAsset_to_capitalize));
			}
		}catch(Exception ex){
			Database.rollback(sp);
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
		}
		isValid = false;
	}
	
}