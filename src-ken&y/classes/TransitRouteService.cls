public with sharing class TransitRouteService {
	
	public static void setPrimaryKey(){
		//TO-DO : check if the relevant fields (fieldset??) are changing in the update trigger
		if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
			for(Transit_Route__c transitRoute : (List<Transit_Route__c>) trigger.new){
				transitRoute.Transit_Route_Unique__c = getTransitRouteKey(transitRoute);
			}
		} 
	}	 
	
	public static String getTransitRouteKey(Transit_Route__c transitRoute){
		String transitRouteKey = '';
		// TO-DO : Replace with fieldset??
		transitRouteKey = '' + transitRoute.Means_of_Transport__c + transitRoute.Origin__c + transitRoute.Destination__c + transitRoute.Delivery_Method__c;		
		return transitRouteKey;
	}
	
	public static List<Transit_Route__c> getTransitRoutes(Set<Id> fromAddresses, Set<Id> toAddresses){
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Transit_Route__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Destination__c','Means_of_Transport__c','Origin__c','Primary__c','Transit_Time__c','Delivery_Method__c'
		});
		soql.setWhereClause('Origin__c IN :fromAddresses AND Destination__c IN :toAddresses');

		return Database.query(soql.getQuery());
	}
	
	
	/**
	 * This method is invoked when Fuel Preference Custom settings for OTC (named OTC__C) is updated. 
	 * This requires all transit routes to update them with the best fuel allowances.
	 */ 
	@future
	public static void updateAllTransitRoutesForCompany(Id companyId) {
	    
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Transit_Route__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Fuel_Allowance__c','Distance_Rate__c','Destination__c','Delivery_Method__c'
		});
		soql.setWhereClause('Delivery_Method__c = \'Pickup\'');
		
		Transit_Route__c [] routes = Database.query(soql.getQuery());

        if (routes != null && !routes.isEmpty()){
	        setFuelAllowance(companyId, routes);
            DML.updateAsUser(routes);                
        }    
	}
	
	public static void setFuelAllowance(Transit_Route__c[] routes, Map<Id, Transit_Route__c> oldRoutes) {
	    Id defaultCompanyId =  UserPreference.getInstance().Preference != null ? UserPreference.getInstance().Preference.Default_Company__c : null;
	    
	    if (defaultCompanyId != null) {
    	    Transit_Route__c[] routesToProcess = new Transit_Route__c[]{};
    	    for (Transit_Route__c ntr : routes) {
    	        if (ntr.Destination__c != oldRoutes.get(ntr.Id).Destination__c){ 
	        		routesToProcess.add(ntr);
    	        }
    	    }
    	    
    	    if (!routesToProcess.isEmpty()){ 
    	    	setFuelAllowance(defaultCompanyId, routesToProcess);
    	    }
	    }
	}
	
	
	public static void setFuelAllowance(Transit_Route__c[] routes) {
	    Id defaultCompanyId =  UserPreference.getInstance().Preference != null ? UserPreference.getInstance().Preference.Default_Company__c : null;
	
	    if (defaultCompanyId != null) {
	    	Transit_Route__c[] routesToProcess = new Transit_Route__c[]{};
    	    for (Transit_Route__c ntr : routes) {
	        	if(ntr.Fuel_Allowance__c == null || ntr.Distance_Rate__c == null){
	        		routesToProcess.add(ntr);
		        }
    	    }
    	
    	    if (!routesToProcess.isEmpty()){ 
    	    	setFuelAllowance(defaultCompanyId, routesToProcess);
    	    }
	    }
	}
	
	public static void setFuelAllowance(Id companyId, Transit_Route__c[] routes) {
        /* KNDY-10333
        Map<String, Decimal> fuelRatePrefs = AllowanceRuleService.getFuelAllowancePreferences(companyId);
        Map<String, Decimal> distRatePrefs = AllowanceRuleService.getDistanceRatePreferences(companyId);
        
        if (fuelRatePrefs != null) {
            Set<Id> destIds = KSE.grepRelatedIdSetFromList(routes, 'Destination__c', true);
    	    // K: AccountId V: Fuel Preference
    	    Map<Id, String> fuelPreferenceByAccount = new Map<Id, String>();

    	    //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Address__c','Top_Parent_Customer__c','Top_Parent_Customer__r.Fuel_Preference__c','Fuel_Preference__c','RecordType.DeveloperName'
			});
			soql.setWhereClause('Address__c IN :destIds');

			for (Customer__c c : Database.query(soql.getQuery())){
    	        if (!fuelPreferenceByAccount.containsKey(c.Address__c)){
	    	        if (c.Top_Parent_Customer__c != null){
		    	        fuelPreferenceByAccount.put(c.Address__c, c.Top_Parent_Customer__r.Fuel_Preference__c);
	    	        } else if (c.RecordType.DeveloperName == 'Corporate_Parent'){
	    	        	fuelPreferenceByAccount.put(c.Address__c, c.Fuel_Preference__c);
	    	        } 
	    	    }
    	    }
    	    
    	    for (Transit_Route__c tr : routes) {
                if (tr.Destination__c != null) {
        	        String fuelPref = fuelPreferenceByAccount.get(tr.Destination__c);
        	        if(! String.isBlank(fuelPref)){
	    	        	tr.Fuel_Allowance__c = fuelRatePrefs.get(fuelPref);
	    	        	tr.Distance_Rate__c = distRatePrefs.get(fuelPref);
        	        }
        	    }
    	    }
        }
        */
	}
	
	
    /*
      KNDY-2525 Freight Allowance
      Update Transit route in case Fuel Preference or Address is changed on Customer__c record
     */ 
	public static void updateTransitRouteForCustomerUpdate(List<Customer__c> updatedRecs, Map<Id, Customer__c> oldRecsMap) {
	    /* KNDY-10333
	    // k: developer name of rec type v: rec type id
	    Map<String, String> customerRecTypeIdsByDevName = KSE.RecordTypeDevNameMap('Customer__c');
	    Id customerSoldToRecTypeId = customerRecTypeIdsByDevName.get('Corporate_Parent');
	    
	    // K: Account Id V: Fuel Preference (Weekly, Monthly...)
	    Map<Id, String> fuelPrefsByAccountId = new Map<Id, String>();
	    // Old account ids to clean
	    Set<Id> oldAccountIds = new Set<Id>();
	    
	    // NOTE: Assuming multi company customers will not be updated in one triggerflow.
	    // This needs to be revisited if that is the case
	    Id companyId;
	    
	    for (Customer__c newCust : updatedRecs) {
	        // Only sold to customers matter here
	        if (newCust.RecordTypeId != customerSoldToRecTypeId) continue;
	        
            if (newCust.Address__c != null && KSE.isFieldChanging('Fuel_Preference__c', newCust, Trigger.oldMap)) {
                fuelPrefsByAccountId.put(newCust.Address__c, newCust.Fuel_Preference__c);
                companyId = newCust.Company__c;
            } 
            
            if (KSE.isFieldChanging('Address__c', newCust, Trigger.oldMap)) {
                Customer__c oldCust = oldRecsMap.get(newCust.Id);
                
                if (newCust.Address__c != null) fuelPrefsByAccountId.put(newCust.Address__c, newCust.Fuel_Preference__c);
                
                if (oldCust.Address__c != null) oldAccountIds.add(oldCust.Address__c);
                
                companyId = newCust.Company__c;
            }
	    }
	    
	    if (!fuelPrefsByAccountId.isEmpty() || !oldAccountIds.isEmpty()) {
            // K: Weekly, Monthly... V: Fuel Rate
    	    Map<String, Decimal> fuelAllowPrefs = AllowanceRuleService.getFuelAllowancePreferences(companyId);
    	    // K: Weekly, Monthly... V: Distance rate
    	    Map<String, Decimal> distRatePrefs = AllowanceRuleService.getDistanceRatePreferences(companyId);
    	    
    	    System.debug ('CustomerLoad: companyId='+ companyId + ' fuelAllowPrefs:' + fuelAllowPrefs);
    	    
    	    if (fuelAllowPrefs != null && distRatePrefs != null) {
    	        Set<Id> accountIds = new Set<Id>();
    	        accountIds.addAll(fuelPrefsByAccountId.keySet()); 
    	        accountIds.addAll(oldAccountIds);
    	        
    	        Transit_Route__c[] routes = new Transit_Route__c[]{};
    	        
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('Transit_Route__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Fuel_Allowance__c','Destination__c'
				});
				soql.setWhereClause('Destination__c IN :accountIds and Destination__c != null');

				for (Transit_Route__c tr : Database.query(soql.getQuery())){
    	            if (fuelPrefsByAccountId.containsKey(tr.Destination__c)) {
    	                String fuelPref = fuelPrefsByAccountId.get(tr.Destination__c);
    	                tr.Fuel_Allowance__c = fuelAllowPrefs.get(fuelPref);
    	                tr.Distance_Rate__c = distRatePrefs.get(fuelPref);
    	                routes.add(tr);
    	            } else if (oldAccountIds.contains(tr.Destination__c)) {
    	                // New Fuel preference is always scanned in first if clause, so any pending routes will get cleared only for old stuff
    	                tr.Fuel_Allowance__c = 0;
    	                tr.Distance_Rate__c = 0;
    	                routes.add(tr);
    	            }
    	        }
    	        if (!routes.isEmpty()) DML.updateAsUser(routes);
    	    }
	    }
	    */
	}
}