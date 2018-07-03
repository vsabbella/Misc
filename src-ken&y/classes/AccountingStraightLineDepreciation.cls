public with sharing class AccountingStraightLineDepreciation implements FixedAssetService.IDepreciation{
	
	public class cannotDepreciateException extends Exception {} 
	public List<Fixed_Asset_Depreciation__c> execute(List<sObject> sObjRecs, Date depreciateToDate, boolean commitDepreciation){
		system.debug('SL RUNNING');
		List<Fixed_Asset_Depreciation__c> upsertFixedAssetDepreciations = new List<Fixed_Asset_Depreciation__c>();
		
		//Create straight line depreciation records for the fixed assets
		List<Fixed_Asset__c> fixedAssets = (List<Fixed_Asset__c>)sObjRecs;
		 
		for(Fixed_Asset__c fa : fixedAssets){ 
			Date depreciationDate;
			Boolean prorate ;//
			if(fa.Prorate_First_Period__c!=null){
				prorate = fa.Prorate_First_Period__c;
			}
			 
			if(fa.Date_Last_Depreciated__c != null){
				//Dont  prorate if the asset is already depreciated--
                if(fa.Total_Depreciated_Value__c!=0){
                    prorate = false;    
                }
				depreciationDate = fa.Date_Last_Depreciated__c;
			}else{
				depreciationDate = fa.In_Service_Date__c;
			} 
			
		
			if(depreciationDate==null){
			    throw new cannotDepreciateException(Label.In_Service_Date_date_is_missing_for+ fa.name);
			}
			
		    system.debug('-------Depreciation Date(FROMDATE)------'+depreciationDate); 
			
			Integer cycles = 0;
			decimal currentDepreciatedValue = fa.book_value__c;  
			Fixed_Asset_Depreciation__c iFad;  
			boolean applyMidConvention = false;
			
			if(fa.depreciation_convention__c==null){
			   throw new cannotDepreciateException(Label.Depreciation_convention_is_missing_for+ fa.name); 
			}
			
			if(fa.Total_Depreciated_Value__c == 0 && (fa.depreciation_convention__c.contains('Mid') 
													|| fa.depreciation_convention__c.contains('Half'))){
				applyMidConvention = true;
			} 
			 
			decimal depreciationRemaining = fa.Depreciable_Basis__c - fa.Total_Depreciated_Value__c;
			
			integer remainingPeriods	  = FixedAssetService.returnPeriodCount(depreciationDate, fa.Estimated_End_of_Life__c, 
											fa.Depreciation_Period__c);
			if(prorate==true){
				// Get all the periods of the current company
				List<Period__c> allPeriods;
			    Map<Id, List<Period__c>> companyPeriodMap = PeriodService.getAllPeriodsMap(new Set<ID>{fa.company__c});  
			    allPeriods = companyPeriodMap.get(fa.company__c);
			
				Period__c inservice_Period = null;
				Integer totalDays		   =	0;
				for(Period__c eachPeriod:allPeriods){ 
					if(eachPeriod.Period_Start__c < = depreciationDate && depreciationDate < eachPeriod.Period_End__c ){
						inservice_Period = eachPeriod;
					}
				} 
				
				//system.debug('inservice_Period '+inservice_Period );
				if(inservice_Period==null){ 
					throw new cannotDepreciateException(Label.Period_Not_defined_for_the_depreciation_date+depreciationDate +' for asset:'+fa.Name);
				}  
				Date end_of_first_month 				 = inservice_Period.Period_End__c.date(); 
				Integer no_of_days_lapsed_from_period_start  = Math.abs( depreciationDate.daysBetween(inservice_Period.Period_Start__c.date()));
				//Date end_of_first_month 	 =  first_month_period_end; 
			    Integer no_of_prorate_days   =  depreciationDate.daysBetween(end_of_first_month);//Total days lapsed for first month 
			    
			    // Changes as per KNDY-11001 
				if(no_of_days_lapsed_from_period_start>1 && no_of_prorate_days >0){ 
					system.debug('------- prorating----');
					decimal oneMonthAmt 		 =  depreciationRemaining.divide(remainingPeriods, 2, System.RoundingMode.HALF_UP);
					Integer noOfdaysInFirstMonth =  Math.abs( inservice_Period.Period_Start__c.date().daysBetween(inservice_Period.Period_End__c.date()));
					decimal dailyDepAmount	     =  oneMonthAmt.divide(noOfdaysInFirstMonth, 2, System.RoundingMode.HALF_UP);
					decimal depAmtForPendingDays =  no_of_prorate_days *dailyDepAmount; 
					currentDepreciatedValue 	 =  depreciationRemaining - depAmtForPendingDays;
					depreciationRemaining 		 =  depreciationRemaining-depAmtForPendingDays; 
					 
					if(depreciationDate < depreciateToDate){
			   			iFad = FixedAssetService.generateFixedAssetDepreciation(depAmtForPendingDays, depreciationDate, 
											currentDepreciatedValue, fa, FixedAssetService.TYPE_DEPRECIATION);
						upsertFixedAssetDepreciations.add(iFad);
						depreciationDate 			 = end_of_first_month+1; 
					} 	 
					remainingPeriods = remainingPeriods -1;
				}
			}
			 
			decimal depreciationAmount = depreciationRemaining.divide(remainingPeriods, 2, System.RoundingMode.HALF_UP);
			system.debug(' months: ' + remainingPeriods + ' amt  remaining ' + depreciationRemaining + ' - ' + depreciationAmount);
			 
			
			//Run depreciation cycles until the depreciation has been brought up to date
			while(depreciationDate < depreciateToDate){ 
				
				//Default to straight line amount
				decimal iDepreciation = depreciationAmount;
			   if(prorate==false){
			   		if(iDepreciation > (currentDepreciatedValue - fa.residual_value__c)){
						iDepreciation = (currentDepreciatedValue - fa.residual_value__c);
					}  
			  }
				
				
				if(applyMidConvention){
					iDepreciation = iDepreciation/2.0;
					applyMidConvention = false; 
				}
				
				currentDepreciatedValue = currentDepreciatedValue - iDepreciation;
				
				//Generate depreciation iff the residual value will not be exceeded
				if(fa.Residual_Value__c <= currentDepreciatedValue && iDepreciation > 0){
					iFad = FixedAssetService.generateFixedAssetDepreciation(iDepreciation, depreciationDate, currentDepreciatedValue, fa, FixedAssetService.TYPE_DEPRECIATION);
					upsertFixedAssetDepreciations.add(iFad);
				}
				cycles++;
				
				depreciationDate = FixedAssetService.incrementPeriod(depreciationDate, fa.depreciation_period__c);
				system.debug('depreciationDate'+depreciationDate);
				system.debug('depreciationDate to end of month '+depreciateToDate.toStartOfMonth().addMonths(1).addDays(-1));
				 
				if(currentDepreciatedValue>0 && currentDepreciatedValue<1){
				    upsertFixedAssetDepreciations[upsertFixedAssetDepreciations.size()-1].Depreciation_Amount__c 
				    = upsertFixedAssetDepreciations[upsertFixedAssetDepreciations.size()-1].Depreciation_Amount__c +currentDepreciatedValue;
				}
			  
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
 
		system.debug('upsertFixedAssetDepreciations: ' + upsertFixedAssetDepreciations);
		 
 
		//system.debug('upsertFixedAssetDepreciations: ' + upsertFixedAssetDepreciations);
 
		return upsertFixedAssetDepreciations;
		
	}
	
	public static date datetoDateTime(datetime convertDate){
		return date.newinstance(convertDate.year(), convertDate.month(), convertDate.day());
	} 
	
	 
	
}