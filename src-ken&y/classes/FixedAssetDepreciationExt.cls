public with sharing class FixedAssetDepreciationExt {
	
	public Apexpages.Standardsetcontroller ssCon {get;set;}
	public boolean disableDepreciation {get;set;}
	public boolean hasSelected {get;set;}
	public boolean isBatch {get;set;}
	public string selectedCompanyId {get;set;}
	public string selectedBookId {get;set;}
	public Map<Id, List<SelectOption>> mTaxBooks {get;set;}
	public List<SelectOption> companyOptions {get;set;}
	
		
	public FixedAssetDepreciationExt(Apexpages.Standardsetcontroller ssController){
		ssCon = ssController;
		if(ssCon.getSelected().size() > 0){
			isBatch = false;
			disableDepreciation = false;
			hasSelected = true;
		}else{
			isBatch = true;
			disableDepreciation = true;
			hasSelected = false;
			updateCompanyBookOptions();
		}
	}
	
	public void updateCompanyBookOptions(){
		mTaxBooks = new Map<Id, List<SelectOption>>();
		companyOptions = new List<SelectOption>();


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    */
SOQLUtil soql = new SOQLUtil('Tax_Book__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','name','company__c','company__r.name','active__c'
});
soql.setWhereClause('active__c = true');
soql.setOrderByClause('company__r.name, name');
List<Tax_Book__c> taxBooks = Database.query(soql.getQuery());


		for(Tax_Book__c tb : taxBooks){
			if(mTaxBooks.containsKey(tb.company__c)){
				mTaxBooks.get(tb.company__c).add(new SelectOption(tb.Id, tb.name));
			}else{
				companyOptions.add(new SelectOption(tb.company__c, tb.company__r.name));
				mTaxBooks.put(tb.company__c, new List<SelectOption>{new SelectOption('', '- Select One -'), new SelectOption(tb.Id, tb.name)});
			}
		}
		//if(companyOptions.size() == 1){
			selectedCompanyId = companyOptions[0].getValue();
		//}
	}
	
	public List<SelectOption> getTaxBookOptions(){
		if(mTaxBooks.containsKey(selectedCompanyId)){
			return mTaxBooks.get(selectedCompanyId);
		}else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, Label.Could_not_find_any_active_tax_books_for_this_company));
			return new List<SelectOption>();			
		}
	}
	
	public void updateDepreciableFixedAssets(){
		List<Fixed_Asset__c> selectedRecs = ssCon.getSelected();
		
		system.debug('selectedRecs: ' + selectedRecs);
		string activeStatus = FixedAssetService.STATUS_ACTIVE;
        
        String whereClause = ' company__c = :selectedCompanyId AND tax_book__c = :selectedBookId AND status__c = :activeStatus';//KNDY-8796
		SOQLUtil soql = new SOQLUtil('Fixed_Asset__c');
 		soql.addFields('Fixed_Asset_Detail');
 		soql.setWhereClause(whereClause);
        /*
		string query = SchemaUtil.getInstance().generateQueryFromFieldSet(
														'Fixed_Asset__c', 
														new set<String>{'Fixed_Asset_Detail'}, 
														new set<String>(), 
														' company__c = :selectedCompanyId AND tax_book__c = :selectedBookId AND status__c = :activeStatus'); // AND status__c = :activeStatus'
		List<Fixed_Asset__c> fas = database.Query(query);*/
        List<Fixed_Asset__c> fas = database.Query(soql.getQuery());
		if(fas.size() > 0){
			ssCon = new Apexpages.Standardsetcontroller(fas);
			ssCon.setSelected(fas);
			disableDepreciation = false;
			hasSelected = true;
		}else{
			disableDepreciation = true;
			hasSelected = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, Label.Could_not_find_any_active_assets_for_depreciation));
		}
		
	}
	
	public void btn_RunDepreciation(){
		
		disableDepreciation = true;
		try{
			if(isBatch){
				FixedAssetDepreciationBatch fadBatch = new FixedAssetDepreciationBatch(new Set<Id>{selectedCompanyId});
				fadBatch.query += 'AND tax_book__c = \'' + selectedBookId + '\'';
				database.executebatch(fadBatch);
			}else{
				Map<Id, Fixed_Asset__c> mFixedAssets = new Map<Id, Fixed_Asset__c>((List<Fixed_Asset__c>)ssCon.getSelected());
				FixedAssetDepreciationBatch fadBatch = new FixedAssetDepreciationBatch();
				fadBatch.companyIds = null;
				fadBatch.fixedAssetIds = mFixedAssets.keySet();
				fadBatch.updateQuery();
				database.executebatch(fadBatch);
			}
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, Label.Batch_job_initiated));
		}catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
		}
	}
	
	public pageReference btn_Workbench(){
		return Page.FixedAssetWorkbench;
	}
	
	/* pagination controls and flags */
	public integer getPageNumber(){
		return ssCon.getPageNumber();
	}
	
	public boolean getHasNext(){
		return ssCon.getHasNext();
	}
	
	public boolean getHasPrevious(){
		return ssCon.getHasPrevious();
	}
	
	public integer getNumberOfPages(){
		decimal noPages = (decimal)ssCon.getResultSize();
		noPages = noPages.divide(25,0, System.RoundingMode.UP);
		return (integer)noPages;
	}
	
	public void first(){
		ssCon.first();
	}
	
	public void previous(){
		ssCon.previous();
	}
	
	public void next(){
		ssCon.next();
	}
	
	public void last(){
		ssCon.last();
	}
	
}