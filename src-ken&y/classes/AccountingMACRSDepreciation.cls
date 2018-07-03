public with sharing class AccountingMACRSDepreciation implements FixedAssetService.IDepreciation{
	/* ------------------------ */
	/* Supporting Documentation */
	/* ------------------------ */
	
	/*
		http://www.irs.gov/pub/irs-pdf/p946.pdf
		http://www.irs.gov/publications/p946/ch04.html#en_US_2012_publink1000107574
		http://en.wikipedia.org/wiki/Depreciation
	*/
	
	public List<Fixed_Asset_Depreciation__c> execute(List<sObject> sObjRecs, Date depreciateToDate, boolean commitDepreciation){

		List<Fixed_Asset_Depreciation__c> upsertFixedAssetDepreciations = new List<Fixed_Asset_Depreciation__c>();
		
		List<Fixed_Asset__c> fixedAssets = (List<Fixed_Asset__c>)sObjRecs;
		
		for(Fixed_Asset__c fa : fixedAssets){
			
			//Setup and define initial data values for the depreciation cycles
			//NOTE: We are tracking Declining Balance and Straight Line side by side as SL will overtake DB at some point during the life of the asset
			integer periods = FixedAssetService.returnPeriodCount(fa.in_service_date__c, fa.estimated_end_of_life__c, fa.depreciation_period__c);
			decimal decliningBalancePercent;
			if(fa.declining_balance__c == '200%'){
				decliningBalancePercent = 2.0;
			}else if(fa.declining_balance__c == '150%'){
				decliningBalancePercent = 1.5;
			}else{
				//Assume Double Decline Model
				decliningBalancePercent = 2.0;
			}
			
			//Set Mid convention flag where relevant - will be used and changed on first depreciation cycle
			boolean applyMidConvention = false;
			if(fa.Total_Depreciated_Value__c == 0 && (fa.depreciation_convention__c.contains('Mid') || fa.depreciation_convention__c.contains('Half'))){
				applyMidConvention = true;
			}
			
			double dbDepreciationRate = decliningBalancePercent*(1.0/(decimal)periods);
			//system.debug('DB Depreciation Rate: ' + dbDepreciationRate);
			
			date depreciationDate;
			if(fa.Date_Last_Depreciated__c != null){
				depreciationDate = fa.Date_Last_Depreciated__c;
			}else{
				depreciationDate = fa.In_Service_Date__c;
			}
			integer cycles = 0;
			decimal currentDepreciatedValue = fa.Book_Value__c;//fa.Depreciable_Basis__c;
			decimal dbCurrentDepreciatedValue = fa.Book_Value__c;//fa.Depreciable_Basis__c;
			decimal slCurrentDepreciatedValue = fa.Book_Value__c;//fa.Depreciable_Basis__c;
			boolean slOvertaken = false;
			decimal slDepreciationAmount = 0;
			
			//Run depreciation cycles until the depreciation has been brought up to date
			while(depreciationDate < depreciateToDate && 0 <= currentDepreciatedValue){
				
				decimal dbDepreciationAmount = dbDepreciationRate*currentDepreciatedValue;
				dbDepreciationAmount = dbDepreciationAmount.setScale(2, System.Roundingmode.HALF_UP);
				
				//decimal remainingPeriods = periods - fa.depreciation_count__c - cycles;
				decimal remainingPeriods = FixedAssetService.returnPeriodCount(depreciationDate, fa.Estimated_End_of_Life__c, fa.Depreciation_Period__c);
				//Prevent divide by zero error
				if(remainingPeriods <= 0 || remainingPeriods == null){
					remainingPeriods = 1;
				}
				system.debug('remainingPeriods: ' + remainingPeriods);
				
				decimal tmpSLDepreciationAmount = (1.0/remainingPeriods)*(currentDepreciatedValue - fa.Residual_Value__c);
				tmpSLDepreciationAmount = tmpSLDepreciationAmount.setScale(2, System.Roundingmode.HALF_UP);
				
				if(tmpSLDepreciationAmount >= dbDepreciationAmount && !slOvertaken){
					slDepreciationAmount = tmpSLDepreciationAmount;
					slOvertaken = true;
				}
				
				system.debug('DB Amount: ' + dbDepreciationAmount);
				system.debug('SL Amount: ' + tmpSLDepreciationAmount);
				
				//Determine which of the two depreciation values is greater, and use that for this cycle
				decimal depreciationAmount;
				if(slOvertaken){
					depreciationAmount = slDepreciationAmount;
				}else{
					depreciationAmount = dbDepreciationAmount;
				}
				
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
				if(0 <= currentDepreciatedValue && depreciationAmount > 0){
					
					Fixed_Asset_Depreciation__c iFad = FixedAssetService.generateFixedAssetDepreciation(depreciationAmount, depreciationDate, currentDepreciatedValue, fa, FixedAssetService.TYPE_DEPRECIATION);
					upsertFixedAssetDepreciations.add(iFad);
					system.debug('iFad: ' + iFad);
				}
				cycles++;
				
				depreciationDate = FixedAssetService.incrementPeriod(depreciationDate, fa.depreciation_period__c);
			}
		}
		
		//Run DML if records have accumulated
		if(upsertFixedAssetDepreciations.size() > 0 && commitDepreciation){
			system.debug('upsertFixedAssetDepreciations: ' + upsertFixedAssetDepreciations.size() + ' - ' + upsertFixedAssetDepreciations);
			DML.upsertAsSystem(); List<Database.Upsertresult> upsertFixedAssetDepreciationsResults = Database.upsert(upsertFixedAssetDepreciations, Fixed_Asset_Depreciation__c.depreciation_key__c, false);
			system.debug('upsertFixedAssetDepreciations: ' + upsertFixedAssetDepreciationsResults);
			//DatabaseService.getInstance().processUpsertResults(upsertFixedAssetDepreciationsResults, upsertFixedAssetDepreciations, 'MACRS Fixed Asset Depreciation');
			DML.upsertAsSystem();
			upsert upsertFixedAssetDepreciations depreciation_key__c;
			
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