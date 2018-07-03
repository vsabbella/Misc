public with sharing class FixedAssetWorkbenchCon {
	
	
	public FixedAssetWorkbenchCon(){
		
	}
	
	public pageReference manageAdjustments(){
		return Page.FixedAssetManageAdjustments;
	}
	
	public pageReference capitalizeFixedAssets(){
		return Page.FixedAssetCapitalize;
	}
	
	public pageReference runDepreciation(){
		return Page.FixedAssetDepreciation;
	}
	
	public pageReference rollbackDepreciation(){
		return Page.CompanyFixedAssetDepreciationRollback;
	}
	
	public pageReference undoSplit(){
		return Page.FixedAssetUndoSplit;
	}
	
	public pageReference splitAsset(){
		pageReference newPage = Page.FixedAssetNew;
		newPage.getParameters().put('isSplit','1');
		return newPage;
	}
	
}