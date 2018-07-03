/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class AccountingDecliningBalanceDepreciation implements FixedAssetService.IDepreciation{
	
	public List<Fixed_Asset_Depreciation__c> execute(List<sObject> sObjRecs, Date depreciateToDate, boolean commitDepreciation){
		// List of Fixed asset depreciation
		List<Fixed_Asset_Depreciation__c> upsertFixedAssetDepreciations = new List<Fixed_Asset_Depreciation__c>();
		
		List<Fixed_Asset__c> fixedAssets = (List<Fixed_Asset__c>)sObjRecs;
		

		for(Fixed_Asset__c fa : fixedAssets){
			
			//Setup and define initial data values for the depreciation cycle
			integer periods = FixedAssetService.returnPeriodCount(fa.in_service_date__c, fa.estimated_end_of_life__c, fa.depreciation_period__c);
			decimal decliningBalancePercent;
			if(fa.declining_balance__c == '200%'){
				decliningBalancePercent = 2.0;
			}else if(fa.declining_balance__c == '150%'){
				decliningBalancePercent = 1.5;
			}else{
				//Assume Double Declining Model
				decliningBalancePercent = 2.0;
			}
			double depreciationRate = decliningBalancePercent*(1.0/(decimal)periods);
			
			date depreciationDate;
			if(fa.Date_Last_Depreciated__c != null){
				depreciationDate = fa.Date_Last_Depreciated__c;
			}else{
				depreciationDate = fa.In_Service_Date__c;
			}
			integer cycles = 0;
			double currentDepreciatedValue = fa.Book_Value__c; //fa.Depreciable_Basis__c;
			
			//Set Mid convention flag where relevant - will be used and changed on first depreciation cycle
			boolean applyMidConvention = false;
			if(fa.Total_Depreciated_Value__c == 0 && (fa.depreciation_convention__c.contains('Mid') || fa.depreciation_convention__c.contains('Half'))){
				applyMidConvention = true;
			}
			
			//Run depreciation cycles until the depreciation has been brought up to date
			while(depreciationDate < depreciateToDate){
				
				decimal depreciationAmount = depreciationRate*currentDepreciatedValue;
				
				
				if(depreciationAmount > (currentDepreciatedValue - fa.residual_value__c)){
					depreciationAmount = (currentDepreciatedValue - fa.residual_value__c);
				}
				
				if(applyMidConvention){
					depreciationAmount = depreciationAmount/2.0;
					applyMidConvention = false;
				}
				
				currentDepreciatedValue = currentDepreciatedValue - depreciationAmount;
				
				//Generate depreciation iff the residual value will not be exceeded
				if(0 <= currentDepreciatedValue && depreciationAmount > 0){
					Fixed_Asset_Depreciation__c iFad = FixedAssetService.generateFixedAssetDepreciation(depreciationAmount, depreciationDate, currentDepreciatedValue, fa, FixedAssetService.TYPE_DEPRECIATION);
					upsertFixedAssetDepreciations.add(iFad);
				}
				
				depreciationDate = FixedAssetService.incrementPeriod(depreciationDate, fa.depreciation_period__c);
			}
		}
		
		//Run DML if records have accumulated
		if(upsertFixedAssetDepreciations.size() > 0 && commitDepreciation){
			DML.upsertAsSystem(); upsert upsertFixedAssetDepreciations depreciation_key__c;
			List<Fixed_Asset_Depreciation__c> fadList = new List<Fixed_Asset_Depreciation__c>();
			for(Fixed_Asset_Depreciation__c fad : upsertFixedAssetDepreciations){
				fadList.add(new Fixed_Asset_Depreciation__c(id=fad.id,finalized__c = true));// as per KNDY-11088
				//fad.finalized__c = true;
			}
			DML.updateAsSystem(fadList);
			//DML.updateAsSystem(upsertFixedAssetDepreciations);
		}
		
		return upsertFixedAssetDepreciations;
		
	}
}