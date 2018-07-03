public with sharing class AccountingSumOfYearsDepreciation implements FixedAssetService.IDepreciation{
	
	public class cannotDepreciateException extends Exception {} 
	public List<Fixed_Asset_Depreciation__c> execute(List<sObject> sObjRecs, Date depreciateToDate, boolean commitDepreciation){
		
		List<Fixed_Asset_Depreciation__c> upsertFixedAssetDepreciations = new List<Fixed_Asset_Depreciation__c>();
		
		List<Fixed_Asset__c> fixedAssets = (List<Fixed_Asset__c>)sObjRecs;
		
		for(Fixed_Asset__c fa : fixedAssets){
			
			//Setup and define initial data values for the depreciation cycle
			date depreciationDate;
			if(fa.Date_Last_Depreciated__c != null){
				depreciationDate = fa.Date_Last_Depreciated__c;
			}else{
				depreciationDate = fa.In_Service_Date__c;
			}
			integer cycles = 0;
			decimal currentDepreciatedValue = fa.book_value__c;
			
			boolean applyMidConvention = false;
			if(fa.Total_Depreciated_Value__c == 0 && (fa.depreciation_convention__c.contains('Mid') 
			                                            || fa.depreciation_convention__c.contains('Half'))){
				applyMidConvention = true;
			}
			
			system.debug('dep date - to date: ' + depreciationDate + ' - ' + depreciateToDate);
			integer sumOfYears = 0;
			integer numberOfYears = (integer)math.floor(fa.depreciation_life__c/12);
			for(integer i=0; i<=numberOfYears; i++){
				sumOfYears += i;
			}
			
			if(sumOfYears<1){
			  throw new cannotDepreciateException('Depreciation Life in Months should be more than 12  for '+ fa.name);  
			  system.debug('Depreciation Life in Months should be more than 12  for');
			}
			//Run depreciation cycles until the depreciation has been brought up to date
			while(depreciationDate < depreciateToDate){
				 
				
				integer yearsBetween = (integer)math.floor(fa.In_Service_Date__c.monthsBetween(depreciationDate)/12);
				system.debug('yearsBetween: ' + yearsBetween);
				decimal yearNo = numberOfYears - yearsBetween; //fa.depreciation_count__c;
				decimal depreciationRate = yearNo/sumOfYears; 
				decimal depreciationAmount = depreciationRate*currentDepreciatedValue;
				
				if(depreciationAmount > (currentDepreciatedValue - fa.residual_value__c)){
					depreciationAmount = (currentDepreciatedValue - fa.residual_value__c);
				}
				
				if(applyMidConvention){
					depreciationAmount = depreciationAmount/2.0;
					applyMidConvention = false;
				}
				
				currentDepreciatedValue = currentDepreciatedValue - depreciationAmount;
				
				system.debug('currentDepreciatedValue: ' + currentDepreciatedValue);
				//Generate depreciation iff the residual value will not be exceeded
				if(fa.Residual_Value__c <= currentDepreciatedValue && depreciationAmount > 0){
					Fixed_Asset_Depreciation__c iFad = FixedAssetService.generateFixedAssetDepreciation(depreciationAmount, depreciationDate, currentDepreciatedValue, fa, FixedAssetService.TYPE_DEPRECIATION);
					upsertFixedAssetDepreciations.add(iFad);
				}
				
				//You can only depreciate via Sum of Years with an Annual period
				depreciationDate = FixedAssetService.incrementPeriod(depreciationDate, 'Annually');//fa.depreciation_period__c
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
		
		//system.debug('Sum of Years: ' +  upsertFixedAssetDepreciations);
		return upsertFixedAssetDepreciations;
		
	}
}