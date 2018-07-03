public with sharing class SubstitutionService {
	public static String PRODUCT_BLOCKED_MESSAGE = 'The product is blocked for sale.';
	public static Map<Id, Sales_Order__c> soMap = new Map<Id, Sales_Order__c>();
	public static Map<String, List<Substitution__c>> substitutionsMap = new Map<String, List<Substitution__c>>();
	public static Map<String, List<Substitution__c>> primaryBlockMap = new Map<String, List<Substitution__c>>();
    public static string DATE_OVERLAP = '{0} : Specified Start and end dates overlap with existing substitution rule ({1}).';
	public static Map<Id, Product__c> productMap = new Map<Id, Product__c>();
	public static Map<Id, Location__c> locationsMap = new Map<Id, Location__c>();
	public static ExceptionService exService = new ExceptionService();
	public static Set<String> INCLUDE_SUBSTITUTION_ORDER_TYPES = new Set<String>{'Military', 'Military Dist Credit', 'SPIN'};	
	/**
	*	Substitutes the current product on the sales order line with an effective substitute, 
	*	if found in the substitutions table.
	*
	*	This method can be called ONLY FROM a trigger context. 
	*/
	public static void substituteProduct(){
		List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>();
		
		if(trigger.isBefore){
			if(trigger.isInsert || trigger.isUpdate){
				// Check if the product on a sales order line is filled in  
				// for the first time or has been changed in an update.
				for(Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) trigger.new){
					if(trigger.isInsert || 
					    (trigger.isUpdate && 
					    	(KSE.isFieldChanging('Product__c', sol, trigger.oldMap) ||
					    	 KSE.isFieldChanging('Ship_From_Location__c', sol, trigger.oldMap) ||
					    	 KSE.isFieldChanging('Required_Date__c', sol, trigger.oldMap) || 
					    	 KSE.isFieldChanging('Estimated_Ship_Date__c', sol, trigger.oldMap)
					    	)
					    )
				    ){
					    if(sol.Ship_From_Location__c != null){	
							soLines.add(sol);
					    }
					}
				}
				
				if(soLines.size() > 0){
					substituteProduct(soLines);
				}
			}
		}
	}
	
	/**
	*	Substitutes the current product on the sales order line with an effective substitute, 
	*	if found in the substitutions table.
	*
	*	This method can be called from controller as well as trigger contexts. 
	*/
	public static void substituteProduct(List<Sales_Order_Line__c> soLines){

		SubstitutionService.INCLUDE_SUBSTITUTION_ORDER_TYPES.addAll(SalesOrderService.STANDARD_ORDER_TYPES);
		
		Set<Id> salesOrderIds = new Set<Id> ();
		for (Sales_Order_Line__c sol : soLines) {
			if(sol.Sales_Order__c != null){
				salesOrderIds.add(sol.Sales_Order__c);
			}
		}
		
		if(salesOrderIds.isEmpty()){
			return;
		}
		
		// Required to query sales order to get the ids of the customers.
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Ship_To__c','Ship_To__r.Skip_Substitution__c','Ship_To__r.Parent_Customer__r.Skip_Substitution__c','Ship_To__r.Top_Parent_Customer__r.Skip_Substitution__c',
			'Ship_To__r.Parent_Customer__r.Parent_Customer__r.Skip_Substitution__c','Type__c'
		});
		soql.setWhereClause('Id IN :salesOrderIds');
		
		soMap = new Map<Id, Sales_Order__c>((List<Sales_Order__c>)Database.query(soql.getQuery()));
		
        Date minStartDate;
		Set<Id> productIds = new Set<Id> (); 
		Set<Id> locationIds = new Set<Id> (); 
        List<Sales_Order_Line__c> soLinesToSubstitute = new List<Sales_Order_Line__c>();
        
		for (Sales_Order_Line__c sol : soLines) {
		    
		    if(soMap.containsKey(sol.Sales_Order__c) 
		    	&& SubstitutionService.INCLUDE_SUBSTITUTION_ORDER_TYPES.contains(soMap.get(sol.Sales_Order__c).Type__c) == false){
		    	continue;
		    }
		    
		    // Check if substitutions are allowed on the sold-to customer.
		    if(soMap.get(sol.Sales_Order__c) != null && soMap.get(sol.Sales_Order__c).Ship_To__r.Parent_Customer__r.Skip_Substitution__c != true){
		        soLinesToSubstitute.add(sol);
		    }
		    else{
                // Skip this sales order line from substitution.
		        continue;
		    }
			
			if (minStartDate == null || sol.Estimated_ship_date__c < minStartDate) {
				minStartDate = sol.Estimated_ship_date__c;
			}

			if(sol.Product__c != null){
				productIds.add(sol.Product__c);
			}
			
			if(sol.Ship_From_Location__c != null){
				locationIds.add(sol.Ship_From_Location__c);
			}
		}
		
		if(soLinesToSubstitute.isEmpty()){
			return;
		}
		
		if(productIds.size() > 0){
			productMap = new Map<Id, Product__c>(SalesOrderFlowCache.cachedProductsForIds(productIds));   
		}
		
		if(locationIds.size() > 0){
			locationsMap = new Map<Id, Location__c>(SalesOrderFlowCache.cachedLocationsForIds(locationIds));
		}
		
        SubstitutionService.populateSubstitutionMaps(soLinesToSubstitute);
		
		for(Sales_Order_Line__c sol : soLinesToSubstitute){
			
			Date dateOrdered;
			
			// For now, if the sales order line does not have sales order information or product information on it,
			// skip the substitution process.
			// This could happen if a sales order line was saved without querying for sales order in the tests.
			if(soMap.containsKey(sol.Sales_Order__c) == false || productMap.containsKey(sol.Product__c) == false){
			    continue;
			}
			
			/*if(setPrimaryBlock(sol)){
    			continue;
    		}*/

		    if(setSubstituteOrBlock(sol)){
				continue;
			}    
			
			// If there is no block or substitution, then clear any exception that might have been previously set.
			exService.clearException(sol, ExceptionUtil.PRODUCT_IS_BLOCKED);
   
		}
	}
	
	/*
	*   Return an ordered list of keys to match for substitutions. 
	*/
	static List<String> getSubKeys(Sales_Order_Line__c  sol, boolean isPrimary){
	    List<String> subKeys = new List<String>();
	    
	    // Use the ship from location's facility on the sales order line.
	    String facilityId = locationsMap.containsKey(sol.Ship_From_Location__c) ? locationsMap.get(sol.Ship_From_Location__c).Facility__c : null;
	    
	    // Use upc if checking for primary blocks.
	    String upcCode = productMap.get(sol.Product__c).UPC_Code__c;
	    String productId = sol.Product__c;
	    
	    String shipToId = soMap.get(sol.Sales_Order__c).Ship_To__c;
	    String soldToId = soMap.get(sol.Sales_Order__c).Ship_To__r.Parent_Customer__c;
	    String billToId = soMap.get(sol.Sales_Order__c).Ship_To__r.Parent_Customer__r.Parent_Customer__c;
	    String corpParentId = soMap.get(sol.Sales_Order__c).Ship_To__r.Top_Parent_Customer__c;
	    
	    // Check if there is a matching substitution record for the Ship-to customer at this facility for the product.
	    subKeys.add(getSubKey(facilityId, shipToId, upcCode));
	    subKeys.add(getSubKey(facilityId, shipToId, productId));
	    // Else
		// Check if there is a matching substitution record for the Sold-to customer at this facility for the product.
		subKeys.add(getSubKey(facilityId, soldToId, upcCode)) ;
		subKeys.add(getSubKey(facilityId, soldToId, productId)) ;
		// Else
		// Check if there is a matching substitution record for the Bill-to customer at this facility for the product.
		subKeys.add(getSubKey(facilityId, billToId, upcCode)) ;
		subKeys.add(getSubKey(facilityId, billToId, productId)) ;
		// Else
		// Check if there is a matching substitution record for the Corporate parent customer at this facility for the product.
		subKeys.add(getSubKey(facilityId, corpParentId, upcCode)) ;
		subKeys.add(getSubKey(facilityId, corpParentId, productId)) ;
		// Else
		// Check if there is a matching substitution record for the Ship-to customer at ANY facility for the product.
		subKeys.add(getSubKey(null, shipToId, upcCode)) ;
		subKeys.add(getSubKey(null, shipToId, productId)) ;
		// Else
		// Check if there is a matching substitution record for the Sold-to customer at ANY facility for the product.
		subKeys.add(getSubKey(null, soldToId, upcCode)) ;
		subKeys.add(getSubKey(null, soldToId, productId)) ;
		// Else
		// Check if there is a matching substitution record for the Bill-to customer at ANY facility for the product.
		subKeys.add(getSubKey(null, billToId, upcCode)) ;
		subKeys.add(getSubKey(null, billToId, productId)) ;
		// Else
		// Check if there is a matching substitution record for the Corporate parent customer at ANY facility for the product.
		subKeys.add(getSubKey(null, corpParentId, upcCode)) ;
		subKeys.add(getSubKey(null, corpParentId, productId)) ;
		// Else
		// Check if there is a matching substitution record for ANY customer at this facility for the product.
		subKeys.add(getSubKey(facilityId, null, upcCode)) ;
		subKeys.add(getSubKey(facilityId, null, productId)) ;
		// Else
		// Check if there is a matching substitution record for ANY customer at ANY facility for the product.
		subKeys.add(getSubKey(null, null, upcCode)) ;
		subKeys.add(getSubKey(null, null, productId)) ;
		
		return subKeys;	
	}
	
	/*
	*	Small routine which will be called repeatedly to check if a matching substitution record exists
	*	in the substitutions map and replace the product on the sales order line with the substitute.
	* 	If the product is blocked, instead of substituting the product, it sets an exception and its details on the sales order line.
	*	
	*	Returns true if a substitution exists in the map, even if its blocked (Block__c = true).
	*/
	static boolean setSubstituteOrBlock(Sales_Order_Line__c sol){
		List<Substitution__c> subRules;
		Date estDateShip = sol.Estimated_ship_date__c;
		
		for(String subKey : getSubKeys(sol, false)){ // Get the substitution key list for non-primary products.
				
			if( substitutionsMap.containsKey(subkey) ){
				subRules = substitutionsMap.get(subkey);
				
				for(Substitution__c subRule : subRules){
		            if(subRule.Start_Date__c <= estDateShip && subRule.End_Date__c >= estDateShip){
        				if(subRule.Block__c != true){
        					if(subRule.Substitute_Product__c != null && subRule.Substitute_Product__c != subRule.Current_Product__c){
	        					sol.Product__c = subRule.Substitute_Product__c;
		                        // KNDY-3331: Clear the pricebook and price fields to give rest of the trigger code a chance
		                        // to fix them as per latest product substitution
		                        sol.Pricebook__c = null;
								sol.Unit_Price__c = null;
								sol.Description__c = subRule.Substitute_Product__r.Description__c;
        					}
							exService.clearException(sol, ExceptionUtil.PRODUCT_IS_BLOCKED);
						}else{
							exService.setException(sol, ExceptionUtil.PRODUCT_IS_BLOCKED);
						}
						return true;
					}
				}
			}
		}
		
		// Return false if no matching substitution rule found.
		return false;
	}
	
	/*
	*	Small routine which will be called repeatedly to check if a matching primary block record exists
	*	in the substitutions map and block the product from being used on the sales order lines.
	* 	If the product is blocked, instead of substituting the product, it sets an exception and details on the sales order line.
	*	
	*	Returns true if a matching record exists in the map.
	
	static boolean setPrimaryBlock(Sales_Order_Line__c sol){
		List<Substitution__c> subRules;
		Date estDateShip = sol.Estimated_ship_date__c;
		
		// Get the substitution key list for PRIMARY products.
		// Passing true to indicate that the key needs to match the primary product (UPC), not the current product.
		for(String subKey : getSubKeys(sol, true)){ 
			if( primaryBlockMap.containsKey(subkey) ){
				subRules = primaryBlockMap.get(subkey);
				
				for(Substitution__c subRule : subRules){
                    if(subRule.Start_Date__c <= estDateShip && subRule.End_Date__c >= estDateShip){
						if(subRule.Block__c == false){
							sol.Product__c = subRule.Substitute_Product__c;
	                        // KNDY-3331: Clear the pricebook and price fields to give rest of the trigger code a chance
	                        // to fix them as per latest product substitution
	                        sol.Pricebook__c = null;
							sol.Unit_Price__c = null;
							exService.clearException(sol, ExceptionUtil.PRODUCT_IS_BLOCKED);
						}else{
							exService.setException(sol, ExceptionUtil.PRODUCT_IS_BLOCKED);
						}
						return true;
					}
				}
			}
		}
		
		// Return false if no matching substitution rule found.
		return false;
	}
	*/
	
	/**
	*	Populate the corresponding maps for product block and substitutions for the matching
	*	facilities, customers and products on the sales order lines. 
	*/
	static void populateSubstitutionMaps(List<Sales_Order_Line__c> soLines){
		
		Date minStartDate = system.today();
		Set<Id> facilityIds = new Set<Id>();
		Set<Id> customerIds = new Set<Id>();
		Set<Id> productIds = new Set<Id>();
		Set<String> upcCodes = new Set<String>();
		
		for(Sales_Order_Line__c sol : soLines){
			if(soMap.containsKey(sol.Sales_Order__c)){
				customerIds.add(soMap.get(sol.Sales_Order__c).Ship_To__c); // Ship-to
    			customerIds.add(soMap.get(sol.Sales_Order__c).Ship_To__r.Parent_Customer__c); // Sold-to
    			customerIds.add(soMap.get(sol.Sales_Order__c).Ship_To__r.Parent_Customer__r.Parent_Customer__c); // Bill-to
    			customerIds.add(soMap.get(sol.Sales_Order__c).Ship_To__r.Top_Parent_Customer__c); // Corporate Parent
			}
			
			if(locationsMap.containsKey(sol.Ship_From_Location__c)){
				facilityIds.add(locationsMap.get(sol.Ship_From_Location__c).Facility__c);
			}
			
			if(productMap.containsKey(sol.Product__c)){
				productIds.add(sol.Product__c);
				upcCodes.add(productMap.get(sol.Product__c).UPC_Code__c);
			}
			
			if (minStartDate == null || sol.Estimated_ship_date__c < minStartDate) {
				minStartDate = sol.Estimated_ship_date__c;
			}
		}
		
		substitutionsMap.clear();
		
		// Query for substitutions that are not created for primary product blocks
		// ie., which have a substitute product filled in the record (Substitute_Product__c != null)
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Substitution__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Block__c','Customer__c','Current_Product__c','Current_Product__r.UPC_Code__c','Primary__c','Start_Date__c','End_Date__c',
			'Facility__c','Substitute_Product__c','Substitute_Product__r.Description__c'
		});
		soql.setWhereClause('(Facility__c IN :facilityIds OR Facility__c = null) AND (Customer__c IN :customerIds OR Customer__c = null) '
							+' AND Start_Date__c <= :minStartDate AND (Current_Product__c IN :productIds OR Current_Product__r.UPC_Code__c IN :upcCodes)');

		for(Substitution__c sub : Database.query(soql.getQuery())){

			if(sub.Primary__c == true && sub.Current_Product__r.UPC_Code__c != null){
				String subIndex = getSubKey(sub.Facility__c, sub.Customer__c, sub.Current_Product__r.UPC_Code__c) ;
				  	
				if(substitutionsMap.containsKey(subIndex) == false){
					substitutionsMap.put(subIndex, new List<Substitution__c>());
				}					  	
				substitutionsMap.get(subIndex).add(sub);
			}
			else if(sub.Substitute_Product__c != null){					  	
				String subIndex = getSubKey(sub.Facility__c, sub.Customer__c, sub.Current_Product__c) ;
				  	
				if(substitutionsMap.containsKey(subIndex) == false){
					substitutionsMap.put(subIndex, new List<Substitution__c>());
				}					  	
				substitutionsMap.get(subIndex).add(sub);
			}
		}
	}
	
	static String getSubKey(String facilityId, String customerId, String productIdOrUPC){
	    
	    // Make sure that 'null' is not added to the key. 		
	    // Replace null with '' (blank)							  	
	    String subIndex = '' ;
		subIndex += (facilityId == null ? '' : facilityId);
		subIndex += (customerId == null ? '' : customerId);
		subIndex += (productIdOrUPC == null ? '' : productIdOrUPC);
		
		return subIndex;
	}
	
	/*
	*	Performs validation checks against the substitution rules within a trigger context
	*/
	public static void validateSubstitutionRules(){
		Substitution__c[] rulesToValidate = new List<Substitution__c>();
		
		if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
			for(Substitution__c substitute : (List<Substitution__c>) trigger.new){
				if( trigger.isInsert ||
					( trigger.isUpdate && 
						( KSE.isFieldChanging('Facility__c', substitute, trigger.oldMap) ||
						  KSE.isFieldChanging('Customer__c', substitute, trigger.oldMap) ||
						  KSE.isFieldChanging('Current_Product__c', substitute, trigger.oldMap) ||
                          KSE.isFieldChanging('Start_Date__c', substitute, trigger.oldMap) ||
						  KSE.isFieldChanging('End_Date__c', substitute, trigger.oldMap)
						)
					) 
				){
					rulesToValidate.add(substitute);
				}
			}
		}
		
		if(rulesToValidate.size() > 0){
			validateSubstitutionRules(rulesToValidate);
		}
	}
	
	/*
	*	Performs validation checks against the substitution rules
	*/
	static void validateSubstitutionRules(Substitution__c[] rulesToValidate){
		
		checkForOverlappingRules(rulesToValidate);
	}
	
	/*
    *   Validates that the susbtitution rules does not have overlapping Start date ranges.
	*/
	static Substitution__c[] checkForOverlappingRules(Substitution__c[] rulesToValidate){
		// Date range to load data within
		Date smallestDate, biggestDate;
		
		Set<Id> facilityIds = new Set<Id> (); 
		Set<Id> productIds = new Set<Id> (); 
		Set<Id> customerIds = new Set<Id> ();
		
		for (Substitution__c sub: rulesToValidate) {
            if (smallestDate == null || smallestDate.daysBetween(sub.Start_Date__c) < 0) {
                smallestDate = sub.Start_Date__c;   
			}
			if (biggestDate == null || biggestDate.daysBetween(sub.End_Date__c) > 0) {
				biggestDate = sub.End_Date__c;
			}
			
			facilityIds.add(sub.Facility__c);
			productIds.add(sub.Current_Product__c);
			customerIds.add(sub.Customer__c);
		}
		 
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Substitution__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Customer__c','Current_Product__c','Facility__c','Start_Date__c','End_Date__c'
		});
		soql.setWhereClause('Facility__c IN :facilityIds AND Customer__c IN :customerIds AND Current_Product__c IN :productIds '
							+' AND ( (Start_Date__c <= :smallestDate AND End_Date__c >=: smallestDate) OR (Start_Date__c >= :smallestDate AND End_Date__c <=: biggestDate) '
							+' OR (Start_Date__c <= :biggestDate AND End_Date__c >=: biggestDate) )');

		Substitution__c[] existingRules = Database.query(soql.getQuery());
				
		// Collect both old and new rules in same bucket so that comparision is fair
		List<Substitution__c> rulesToMapify = new List<Substitution__c>();
		rulesToMapify.addAll(existingRules);
		rulesToMapify.addAll(rulesToValidate);
		
		// Key: String returned by getSubKey() 
		// Values: list of rules matching that key
		Map<String, Substitution__c[]> rulesMap = new Map<String, Substitution__c[]>();
		for (Substitution__c sub : rulesToMapify) {
			String subKey = getSubKey(sub.Facility__c, sub.Customer__c, sub.Current_Product__c);
			Substitution__c[] rules = rulesMap.get(subKey);
			if (rules == null) {
				rules = new List<Substitution__c>();
				rulesMap.put(subKey, rules);
			}
			rules.add(sub);	
		}
		
		Substitution__c [] validRules = new Substitution__c[]{};
		for (Substitution__c newSub : rulesToValidate) {
			String subKey = getSubKey(newSub.Facility__c, newSub.Customer__c, newSub.Current_Product__c);
			Substitution__c[] rules = rulesMap.get(subKey);
			if (rules == null || rules.isEmpty()) // nothing to match against
				continue;

			if (validateRule(newSub, rules)) {
			    validRules.add(newSub);
			}		
		}
		return validRules;				
	}
	
	/**
	*   Check if there is any other substitution rule active in the same date ranges.
	*/
	static Boolean validateRule( Substitution__c newSub , List<Substitution__c> similarRules ){
		for( Substitution__c  similarSub : similarRules ){
			// same rule instance (rare case, when two new in-memory rules are exactly same)
			if( newSub.id!= null && similarSub.id!= null && newSub.id == similarSub.id ) 
				continue;
				
			if( newSub == similarSub && similarRules.size() == 1) // Comparing with the same record
				continue;				
			
            if(( newSub.Start_Date__c >= similarSub.Start_Date__c ) && ( newSub.Start_Date__c <= similarSub.End_Date__c ) ||
               ( newSub.End_Date__c >= similarSub.Start_Date__c ) && ( newSub.End_Date__c <= similarSub.End_Date__c) || 
               ( newSub.Start_Date__c <= similarSub.Start_Date__c ) && ( newSub.End_Date__c >= similarSub.End_Date__c) 
			){
			 	newSub.addError( String.format(DATE_OVERLAP, new String[]{ newSub.Name, similarSub.Name }) );
			 	return false;
			} 
		}
		return true;
	}
	
}