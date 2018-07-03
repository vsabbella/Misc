public with sharing class AllocationRuleService {
    public static string DATE_OVERLAP = '{0} : Specified start and end dates overlap with existing allocation rules ({1}) !';
    
    /**
     * Calculates allocation for a rule across shipment and sales order lines, and updates the Allocation_Used__c field on
     * each rule for the same.
     */
    public static void populateUsedAllocation(Allocation_Rule__c[] rules, Set<id> saleOrderLineIds, boolean isSOLDeleted) {
        // saleOrderLineIds used for addmanage error printing
        if(saleOrderLineIds ==  null)
        	  saleOrderLineIds = new set<id>();
        Date smallestDate, biggestDate;

		Set<Id> productIds = new Set<Id> (); 
		set<String> customerIds = new set<String>();
        set<String> facilityids = new set<String>();
		for (Allocation_Rule__c newAr: rules) {
            
            if (smallestDate == null || smallestDate > newAr.Start_Date__c) {
                smallestDate = newAr.Start_Date__c;
			}
            if (biggestDate == null || biggestDate < newAr.End_Date__c) {
                biggestDate = newAr.End_Date__c;
			}
			productIds.add(newAr.product__c);
			if(newAr.Customer__c != null)
				customerIds.add(String.valueOf(newAr.Customer__c).substring(0,15));
			if(newAr.Facility__c != null)
           		facilityIds.add(String.valueOf(newAr.Facility__c).substring(0,15));
		}		
		system.debug('hi, customerids: '+customerIds);
		system.debug('hi, facilityIds: '+facilityIds);
		system.debug('hi, productIds: '+productIds);
		system.debug('hi, smallestDate: '+smallestDate);
        system.debug('hi, biggestDate: '+biggestDate);
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Status__c','Name','Estimated_Ship_Date__c','Quantity_Shipped__c','Quantity_Before_Allocation__c','Sales_Order__r.Reason_Code__c',
			'Sales_Order__c','Quantity_Ordered__c','From_Facility_Id__c','Sales_Order__r.Customer__r.top_Parent_Customer__c','Product__c',
			'Allocation_Rule__c','Has_Exceptions__c'
		});
		Set<String> soOrderTypes = SalesOrderService.STANDARD_ORDER_TYPES;
		soql.setWhereClause(
			'Product__c IN :productIds AND Corporate_parent_Customer_ID__c IN :customerIDs AND From_Facility_ID__c IN :facilityIds ' +
			'AND Status__c IN (\'Open\', \'Draft\', \'Closed\', \'Cancelled\') ' + //, 'On Hold' need to discuss impact of On Hold.. Cancelled --> OTC-660
			'AND Estimated_Ship_Date__c >= :smallestDate AND Estimated_Ship_Date__c <= :biggestDate ' + 
			'AND (Sales_Order__r.Type__c IN : soOrderTypes)'
		);
		soql.setOrderByClause('LastModifiedDate ASC'); // Load by earliest changed rules 
		list<Sales_Order_Line__c> soLines = Database.query(soql.getQuery());

		// OTC-920 removed Allocation rules for Sales_Order__r.Type__c LIKE 'Quantity Adjustment%'

		for (Allocation_Rule__c rule : rules) {
            // clear to start recalculations
            rule.Allocation_Used__c = 0;
           
        }
        //if (soLines.isEmpty()) return;
     
        // Those lines which are adding upto Allocation_Rule__c.Allocation_Used__c field
        Sales_Order_Line__c[] soLinesAddingQtyToRules = new Sales_Order_Line__c[]{};

        // Those lines which have any changes in Allocation Rules or Exception flags
        Map<Id,Sales_Order_Line__c> soLinesForUpdate = new Map<Id,Sales_Order_Line__c>();
        
        // K: SO Line ID V: True/False depending on exception
        Map<Sales_Order_Line__c, Boolean> soLineAllocationExceptionMapping = new Map<Sales_Order_Line__c, Boolean>();
        
        // Allocaton Rules by allocation ID
        Map<Id, Allocation_Rule__c> rulesById = new Map<Id, Allocation_Rule__c>(rules);

        for (Sales_Order_Line__c soLine : soLines) {
            //System.debug(LoggingLevel.INFO, '### Finding rule for SO Line :' + soLine.Name);
            
            Allocation_Rule__c bestMatchedRule = null;
            for (Allocation_Rule__c rule : rules) {
                if (soLine.Product__c == rule.Product__c  && (rule.Start_Date__c <= soLine.Estimated_Ship_Date__c && rule.End_Date__c >= soLine.Estimated_Ship_Date__c))
                {
                    if (soLine.From_Facility_Id__c == rule.facility__c && soLine.Sales_Order__r.Customer__r.top_Parent_Customer__c == rule.customer__c) {
                        bestMatchedRule = rule;
                        break;
                    }
                }
            }

            system.debug('Allocation bestmatchedRule: '+bestmatchedRule);
            if (bestMatchedRule == null) {
                //System.debug(LoggingLevel.INFO, '### No rule found for SO Line : ' + soLine);
                
                // if the line has an Allocation Rule associated with it, make null and add to update list.
                if (soLine.Allocation_Rule__c != null){
                    soLine.Allocation_Rule__c = null;
                    soLinesForUpdate.put(soLine.id, soLine);    
                }
                     
                soLineAllocationExceptionMapping.put(soLine, false);                
            } else {
                //System.debug(LoggingLevel.INFO, '### Add allocation used to Rule:'+ bestMatchedRule.Name
                 //+ '(' + bestMatchedRule.Allocation_Used__c + ') from so line :' + soLine.Name + ' value :'  + soLine.Quantity_Ordered__c);    
				//OTC-346
				system.debug('SO Line: '+soLine);
                if (soLine.Status__c=='Open' || soLine.Status__c == 'Draft') {
                	
               
                    bestMatchedRule.Allocation_Used__c += soLine.Quantity_Ordered__c; 
                    
                }
                else if (soLine.Status__c=='Closed' || soLine.Status__c=='Cancelled'){
                	
                	//decimal used = soLine.Quantity_Ordered__c - soLine.Quantity_Shipped__c == 0 ? 0 : soLine.Quantity_Ordered__c - soLine.Quantity_Shipped__c;
                    bestMatchedRule.Allocation_Used__c += soLine.Quantity_Shipped__c;
                } 
            
                if (soLine.Allocation_Rule__c != bestMatchedRule.Id){
                    soLine.Allocation_Rule__c = bestMatchedRule.Id; 
                    soLinesForUpdate.put(soLine.id, soLine);  // adding to set b/c Rule was updated  
                    
                }

                if ('Draft'.equalsIgnoreCase(soLine.Status__c) || 'Open'.equalsIgnoreCase(soLine.Status__c)){ // soLine Allocation Exception for Draft so Lines only
                	
                	system.debug('exceptions sol'+ soLine);

                    Allocation_Rule__c ar = bestMatchedRule; 
                    
                    if (ar.Allocation__c == null) ar.Allocation__c = 0;
                    if (ar.Allocation_Used__c == null) ar.Allocation_Used__c = 0;
                    
                    Decimal remainingAllocation = ar.Allocation__c - ar.Allocation_Used__c;
                    
                   system.debug('remaining allocation: '+remainingAllocation);
                    if (remainingAllocation < 0 ) {
                        // exception condition

                        if (soLine.Quantity_Ordered__c > 0) {  // ignores adding exception to SOL that are adjustments                  
	                            
	                            // ar.Allocation_Used__c -= soLine.Quantity_Ordered__c; //--> Needs to go 
	                             //soLine.Allocation_Rule__c =null;  --> OTC-637
	                            if (ar.Allocation_Used__c < 0) {
	                                ar.Allocation_Used__c = 0;
	                            }
	                            //System.debug(LoggingLevel.INFO, '### After Calculation: Rule :' + ar.Name +' allocation used :' + ar.Allocation_Used__c);
	                            soLinesForUpdate.put(soLine.id, soLine); 
	                            soLineAllocationExceptionMapping.put(soLine, true);
	                        } 
                    	} else
                    	{
                        	soLineAllocationExceptionMapping.put(soLine, false);                    
                    	}
                }
            }
        }//END FOR LOOP
        system.debug('sales order line ids: '+saleOrderLineIds);
        
        
        if(!isSOLDeleted) //OTC-625 indicates that the sol passed to the method were deleted. so do not want to update the sol with blank alloc rule link. 
        {
        	set<id> SOLwithoutRules = new set<Id>();
        	SOLwithoutRules = saleOrderLineIds.clone();
	        for(Sales_Order_Line__c sol : soLines)
	        {
	        	SOLwithoutRules.remove(sol.Id);
	        }
	        system.debug('sol lines with no rules: '+SOLwithoutRules);
	        if(!SOLwithoutRules.isEmpty())
	        {
	        	for(Id solLine : SOLwithoutRules)
	        		soLinesForUpdate.put(solLine, new Sales_Order_Line__c(Id = solLine, Allocation_Rule__c = null));
	        }
        }
      
        
        if (!soLinesForUpdate.values().isEmpty()) {
            // update existing so lines
            DML.updateAsUser(soLinesForUpdate.values());
        }
        
        system.debug('mapping exceptions: '+soLineAllocationExceptionMapping);
        system.debug('sales order line ids: '+saleOrderLineIds);

        for (Sales_Order_Line__c sol : soLineAllocationExceptionMapping.keySet()) {
          //  if (saleOrderLineIds != null && !saleOrderLineIds.contains(sol.Id)) { // skip if statement if saleOrderLineIds is null.
               // continue;
            //}

            Boolean setOrClearException = soLineAllocationExceptionMapping.get(sol);
            setOrClearException = setOrClearException == null ? false : setOrClearException;
            system.debug('sol: has exception '+ sol+' '+setOrClearException);
  
            if (setOrClearException) {
                SalesOrderLineService.exService.setException(sol, ExceptionUtil.SO_LINE_ALLOCATION_EXCEPTION);                
            } else {
                SalesOrderLineService.exService.clearException(sol, ExceptionUtil.SO_LINE_ALLOCATION_EXCEPTION);                
            }
        }

        // update exceptions
        SalesOrderLineService.exService.finishTasks();
    }
    
		
	/*
	    Validates and returns back rules without any errors. Key validation as of now is for date overlaps
	*/
	public static Allocation_Rule__c [] validate(Allocation_Rule__c [] inboundRules) {
		// Date range to load data within
		Date smallestDate, biggestDate;
		Set<Id> companyIds = new Set<Id> ();
		Set<Id> facilityIds = new Set<Id> (); 
		Set<Id> productIds = new Set<Id> (); 
		Set<Id> customerIds = new Set<Id> ();
		
		for (Allocation_Rule__c newAr: inboundRules) {
			if (smallestDate == null || 
                smallestDate.daysBetween(newAr.Start_Date__c) < 0 // date is sobj is smaller
				) {
                smallestDate = newAr.Start_Date__c;   
			}
			if (biggestDate == null 
                || biggestDate.daysBetween(newAr.End_Date__c) > 0 // date in sobj is bigger
				) {
                biggestDate = newAr.End_Date__c;
			}
			
			companyIds.add(newAr.company__c);
			facilityIds.add(newAr.facility__c);
			productIds.add(newAr.product__c);
			customerIds.add(newAr.customer__c);
		}
		
		//System.debug ('inboundRules : ' + inboundRules);
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Allocation_Rule__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Customer__c','Product__c','Facility__c','Company__c','Start_Date__c','End_Date__c'
		});
		soql.setWhereClause(
			'Customer__c IN :customerIds AND Product__c IN :productIds AND Facility__c IN :facilityIds AND Company__c IN :companyIds ' +
			'AND ( ' +
			'   (Start_Date__c <= :smallestDate AND End_Date__c >=: smallestDate) ' + // floating around smallest date
			'      OR ' +
			'   (Start_Date__c >= :smallestDate AND Start_Date__c <=: biggestDate) ' + // floating between smallest and biggest date
			'      OR ' +
			'   (Start_Date__c <= :biggestDate AND End_Date__c >=: biggestDate) ' + // floating around biggest date
			')'
		);
		Allocation_Rule__c[] dbRules = Database.query(soql.getQuery());

		//System.debug ('dbRules : ' + dbRules);
		// Collect both old and new rules in same bucket so that comparision is fair
		List<Allocation_Rule__c> rulesToMapify = new List<Allocation_Rule__c>();
		rulesToMapify.addAll(dbRules);
		rulesToMapify.addAll(inboundRules);
		
		// K: String in Alloc key template V: list of rules matching that key
		Map<String, Allocation_Rule__c[]> rulesByKey = new Map<String, Allocation_Rule__c[]>();
		for (Allocation_Rule__c ar : rulesToMapify) {
			String key = toAllocationUniqueKey(ar);
			Allocation_Rule__c[] rules = rulesByKey.get(key);
			if (rules == null) {
				rules = new List<Allocation_Rule__c>();
				rulesByKey.put(key, rules);
			}
			rules.add(ar);	
		}
		
		Allocation_Rule__c [] validRules = new Allocation_Rule__c[]{};
		for (Allocation_Rule__c newAr : inboundRules) {
			String key = toAllocationUniqueKey(newAr);
			Allocation_Rule__c[] rules = rulesByKey.get(key);
			if (rules == null || rules.isEmpty()) continue;// nothing to match against

			if (validateRule(newAr, rules)) {
			    validRules.add(newAr);
			}		
		}
		return validRules;
	}
	
	static Boolean validateRule( Allocation_Rule__c newAR , List< Allocation_Rule__c > relatedLines ){
		// These checks could be validation rules ? per Ron the answer is no because it is too complicated and better to handle with code
		for( Allocation_Rule__c eAR : relatedLines ){
			// same rule instance (rare case, when two new in-memory rules are exactly same)
			if( newAR == eAR || ( newAR.id == eAR.id )) continue;			

            if(( newAR.Start_Date__c >= eAR.Start_Date__c ) && ( newAR.Start_Date__c <= eAR.End_Date__c ) 
              ||( newAR.End_Date__c >= eAR.Start_Date__c ) && ( newAR.End_Date__c <= eAR.End_Date__c) 
              || ( newAR.Start_Date__c <= eAR.Start_Date__c ) && ( newAR.End_Date__c >= eAR.End_Date__c) ){
			 	newAR.addError( String.format(DATE_OVERLAP, new String[]{ newAR.Name, eAR.Name }) );
			 	return false;
			 } 
		}
		return true;
	}
	
	// Template key to group relevant rules together
	static final String AllocationRuleKeyTemplate = 'Customer__c:{0} Product__c:{1} Facility__c:{2} Company__c:{3}';
	// Private method to convert an allocation rule to a unique key
	static String toAllocationUniqueKey(Allocation_Rule__c ar) {
		//'Customer__c:{0} Product__c:{1} Facility__c:{2} Company__c:{3}';
		return String.format(AllocationRuleKeyTemplate, new List<String>{
			ar.Customer__c, ar.Product__c, ar.Facility__c, ar.Company__c	
		});
	}
	
}