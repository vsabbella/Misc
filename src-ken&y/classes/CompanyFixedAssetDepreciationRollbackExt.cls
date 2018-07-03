public with sharing class CompanyFixedAssetDepreciationRollbackExt {
	
	private Apexpages.Standardcontroller companyController;
	public integer pageSize {get;set;} { pagesize = 25;}
	public Apexpages.Standardsetcontroller fadStandardSetController {get;set;}
	public boolean disableRollback {get;set;}
	public Map<Id, List<SelectOption>> mTaxBooks {get;set;}
	public List<SelectOption> companyOptions {get;set;}
	public string selectedCompanyId {get;set;}
	public string selectedBookId {get;set;}
	
	public CompanyFixedAssetDepreciationRollbackExt(Apexpages.Standardcontroller controller){
		companyController = controller;
		disableRollback = true;
		if(companyController != null){
			selectedCompanyId = companyController.getId();
		}
		updateCompanyBookOptions();
	}
	
	public void updateFixedAssetDepreciations(){
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Fixed_Asset_Depreciation__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name','depreciation_amount__c','depreciation_date__c','depreciation_type__c','gl_date__c','finalized__c','fixed_asset__c',
			'fixed_asset__r.name','fixed_asset__r.gl_account__c'
		});
		soql.setWhereClause('Fixed_Asset__r.company__c = :selectedCompanyId'+
							' AND Fixed_Asset__r.tax_book__c = :selectedBookId'+
							' AND id not in (Select Fixed_Asset_Depreciation__c from Accounting_Entry__c where void__c = false  and Period_Status__c = \'Closed\')');
		soql.setOrderByClause('fixed_asset__r.name asc, depreciation_date__c desc');
		fadStandardSetController = new ApexPages.StandardSetController(Database.getQueryLocator(soql.getQuery()));

		if(fadStandardSetController.getRecords().size() == 0){
			disableRollback = true;
			fadStandardSetController.setPageSize(pageSize);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, Label.No_depreciation_records_for_rollback));
		}else{
			disableRollback = false;
		}
	}
	
	public void updateCompanyBookOptions(){
		mTaxBooks = new Map<Id, List<SelectOption>>();
		companyOptions = new List<SelectOption>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
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
			}else if(tb.company__c != null){
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
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, Label.Could_not_find_active_tax_books));
			return new List<SelectOption>();			
		}
	}
	
	public List<Fixed_Asset_Depreciation__c> getFixedAssetDepreciations(){
		if(fadStandardSetController == null){
			return new List<Fixed_Asset_Depreciation__c>();	
		}else{
			return fadStandardSetController.getRecords();
		}
	}
	
	/* pagination controls and flags */
	public integer getPageNumber(){
		return fadStandardSetController.getPageNumber();
	}
	
	public boolean getHasNext(){
		return fadStandardSetController.getHasNext();
	}
	
	public boolean getHasPrevious(){
		return fadStandardSetController.getHasPrevious();
	}
	
	public integer getNumberOfPages(){
		decimal noPages = (decimal)fadStandardSetController.getResultSize();
		noPages = noPages.divide(pageSize,0, System.RoundingMode.UP);
		return (integer)noPages;
	}
	
	public void first(){
		fadStandardSetController.first();
	}
	
	public void previous(){
		fadStandardSetController.previous();
	}
	
	public void next(){
		fadStandardSetController.next();
	}
	
	public void last(){
		fadStandardSetController.last();
	}
	
	public void btn_Rollback(){
		try{
			database.executeBatch(new FixedAssetDepreciationRollbackBatch(new Set<Id>{companyController.getId()}));
			disableRollback = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, Label.Batch_job_initiated));
		}catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, Label.Batch_job_could_not_be_started));
		}
	}
	public pageReference cancel(){
		return Page.FixedAssetWorkbench;
	} 
}