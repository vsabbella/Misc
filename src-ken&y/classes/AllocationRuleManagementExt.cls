/* 
	Rule by month starting date ?
	How to handle overlap with week wise date ranges starting on sunday ?
	What should be done with Name field ?
*/      
public with sharing class AllocationRuleManagementExt {
    public static Schema.Picklistentry TYPE_PICKVAL_FB {get; set;}
    public static Schema.Picklistentry TYPE_PICKVAL_HFS {get; set;}
    public static Schema.Picklistentry TYPE_PICKVAL_M {get; set;}
    
    static {
    	Schema.DescribeFieldResult typeDFR = Allocation_Rule__c.Type__c.getDescribe();
		List<Schema.PicklistEntry> typeVals = typeDFR.getPicklistValues();
    	for (Schema.Picklistentry tv : typeVals) {
    		if (tv.getValue().indexOfIgnoreCase('forward') != -1) {
    			TYPE_PICKVAL_FB = tv; 	
    		} else if (tv.getValue().indexOfIgnoreCase('fair') != -1) {
    			TYPE_PICKVAL_HFS = tv; 	
    		} else if (tv.getValue().indexOfIgnoreCase('manual') != -1) {
    			TYPE_PICKVAL_M = tv; 	
    		}   
    	}
    }
    
    // thrown when page is missing required params to proceed
    public class BadPageStateException extends Exception {} 
    public class AllocationRuleManagementException extends Exception {}
    public AllocationRuleManagementExt(ApexPages.StandardController scon) {
	    if (scon == null || scon.getId() == null )  {
	    	ExceptionService.addMessage( MessageUtil.Severity.Error.name(), Label.Page_accessed_via_invalid_path_retry_from_product_detail_page_or_tab, '');
	    	//throw new BadPageStateException('This page was accessed via an invalid path.  Please retry from either the product detail page or the tab');             
    	}
    	
    	if(ExceptionService.hasErrors){
            // Update Page messages for display on UI
			for (Map<String, String> msg : ExceptionService.messages) {
			    ApexPages.addMessage(MessageUtil.toApexPageMessage(msg));
			}	 
        	return;
        }
    }
    
    // Exposing as private static variable to ensure good coverage by setting this one to a bad record type name 
    @TestVisible 
    private static String CorpCustomerRecordTypeName = 'Corporate_Parent';           	
    
    // Exception thrown when Corp customer record type is not found as expected
    public class NoCorpCustomerRecordTypeException extends Exception {}
    
    public Id getCorpCustomerRecordTypeId() {
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('RecordType', false); //enforceFLS=false, running in system mode
		soql.addFields(new set<string>{
			'Id'
		});
		String cust = KSE.NamespaceUU+'Customer__c';
		soql.setWhereClause('IsActive = true AND DeveloperName like :CorpCustomerRecordTypeName AND SobjectType = :cust');
		RecordType[] rts = Database.query(soql.getQuery());

    	if (rts.isEmpty()) {
    	    throw new NoCorpCustomerRecordTypeException(Label.Missing_CorporateParent_record_type_for_customer_object);
		} else {
			return rts[0].Id;
		}
    }
 	
    public String getNamespacePrefix(){
    	return KSE.NamespaceUU;
    }
	
	public String getDefaultFieldInfos() {
		// load defaults
		return JSON.serialize(getFieldInfos(TYPE_PICKVAL_FB.getValue()));	
	}
	
	 
   /* @RemoteAction
	public static Long getBiggestNextSequenceNumber() {
		return AllocationRuleService.getBiggestNextSequenceNumber(); 
	}*/
	
	@RemoteAction 
    public static JsonResult saveRules(List<AllocationRule> updatedList, List<AllocationRule> newList, List<AllocationRule> deletedList, List<String> dateFields) {
       // throw new BadPageStateException('on saverules '+updatedList);
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
		List<Allocation_Rule__c> upsertList = new List<Allocation_Rule__c>();
		
        try {
        	system.debug('lists update, new, deleted '+updatedList + ' '+newList+' '+deletedList);
            if (!updatedList.isEmpty()) {
            	//System.debug(toRuleObjects(updatedList));             	
                upsertList.addAll(toRuleObjects(updatedList)); 
                
                
            }
            
            if (!newList.isEmpty()) {            
                upsertList.addAll(toRuleObjects(newList));                  
            }
            system.debug('upsert list: '+upsertList );
            if(upsertList != null && upsertList.size() > 0 ){
            	DML.checkUpsertAsUser(upsertList); upsert upsertList;
            }
            
            if (!deletedList.isEmpty()) {
                DML.deleteAsUser(toRuleObjects(deletedList));
            }
            
            // Leave it from here and let JS handle !
            result.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);

        } catch (Exception e) {
        	System.debug(Logginglevel.ERROR, e.getStackTraceString());
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e, ApexPages.Severity.ERROR);
        }

        return result;
    }
	
	public class FilterInfo {
		// props mapped to JSON request data
		public String productId;
		public String companyId; 
		public String suggestedName; 
		public String ruleType;
		public Long fromDateMillis;
		public Long toDateMillis;
		public Long histFromDateMillis;
		public Long histToDateMillis;
		public Decimal quantityToAllocate;
		public Boolean showWarningsForExistingRules;
		
		// for internal use
		public Date fromDate, toDate, histFromDate, histToDate;
		//list<String> temp = Datetime.newInstance(this.fromDateMillis).format('yyyy/MM/dd').split('/');
	    //fromDate = date.newInstance(integer.valueOf(temp[0]), integer.valueOf(temp[1]), integer.valueOf(temp[2]));
		public void parse() {
			if (this.fromDateMillis > 0) {
				system.debug('fromdateMills '+ fromDateMillis);
				system.debug('formatted: '+Datetime.newInstance(this.fromDateMillis).format('yyyy/MM/dd'));
				list<String> temp = Datetime.newInstance(this.fromDateMillis).format('yyyy/MM/dd').split('/');
	    		fromDate = date.newInstance(integer.valueOf(temp[0]), integer.valueOf(temp[1]), integer.valueOf(temp[2]));
	            
	        }
	        if (this.toDateMillis > 0) {
	        	list<String> temp = Datetime.newInstance(this.toDateMillis).format('yyyy/MM/dd').split('/');
	    		toDate = date.newInstance(integer.valueOf(temp[0]), integer.valueOf(temp[1]), integer.valueOf(temp[2]));
               
	        }
	
			if (this.histFromDateMillis > 0) {
				list<String> temp = Datetime.newInstance(this.histFromDateMillis).format('yyyy/MM/dd').split('/');
	    		histFromDate = date.newInstance(integer.valueOf(temp[0]), integer.valueOf(temp[1]), integer.valueOf(temp[2]));
	           
	        }
	        
	        if (this.histToDateMillis > 0) {
	        	list<String> temp = Datetime.newInstance(this.histToDateMillis).format('yyyy/MM/dd').split('/');
	    		histToDate = date.newInstance(integer.valueOf(temp[0]), integer.valueOf(temp[1]), integer.valueOf(temp[2]));
               
	        }
	
	        if (fromDate == null || toDate == null) {
	        	throw new BadFiltersException(Label.From_To_dates_required_to_load_rules);
	        }
		}
	} 
	
	
	@RemoteAction
	public static AllocationRule newRule(FilterInfo info) {
		info.parse();
		AllocationRule rule = new AllocationRule(info);
		return rule;
	}
	
	public class BadFiltersException extends Exception{}
	
	@RemoteAction
	public static JSONResult loadRules(FilterInfo ctx) {
	    JSONResult result = new JSONResult();
	    result.records = new List<Object>();
	    
		// prepared derived state and validate inputs
		ctx.parse();
		System.debug (ctx);
		
		Date efsd = ctx.fromDate;
		Date efed = ctx.toDate;
		Id productId = ctx.productId;
		Id companyId = ctx.companyId;

        SOQLUtil soql = new SOQLUtil('Allocation_Rule__c', TRUE);
        soql.addFields(new Set<String>{'Id', 'Type__c', 'Active__c', 'Product__c', 'Name', 'Sequence__c', 'Historical_Percent__c', 'History_From__c', 'History_To__c',
                                        'Facility__c', 'Facility__r.Name', 'Customer__c', 'Customer__r.Name', 'Start_Date__c', 'End_Date__c', 'Company__c', 'Business_Process_Type__c',
                                        'Allocation__c', 'Allocation_Used__c'});
        soql.setWhereClause('Product__c =:productId AND Company__c =:companyId '
                                        + ' AND Business_Process_Type__c like \'OTC\' '
                                        //+ ' AND Facility__c != null '
                                        + ' AND '
                                        + ' ( '
                                        + '     (Start_Date__c <= :efsd AND End_Date__c  >=: efsd) '// floating around smallest date
                                        + '     OR '
                                        + '     (Start_Date__c >= :efsd AND Start_Date__c  <=: efed) '// floating around smallest date
                                        + ' ) ');

        if (ctx.ruleType == TYPE_PICKVAL_FB.getValue()) {
            soql.setOrderByClause('Start_Date__c asc ');
        }
        
        if (ctx.ruleType == TYPE_PICKVAL_HFS.getValue()) {
            soql.setOrderByClause('Customer__c asc, Start_Date__c asc');
        }
        
		System.debug (soql.getQuery());
		Allocation_Rule__c[] existingRuleObjs = Database.query(soql.getQuery());
        
        if (existingRuleObjs != null && !existingRuleObjs.isEmpty()) {
            for (Allocation_Rule__c ar : existingRuleObjs) {
				AllocationRule rule = new AllocationRule(ar);
				result.records.add(rule);
            }
            
            if (ctx.showWarningsForExistingRules) {
                result.addMessage(Label.Quantity_already_allocated_for_this_time_period, ApexPages.Severity.Warning);
            }
            system.debug('load rules - existing rules - '+ result.records);
            result.success = false;
            return result;
        }
        
        Map<Allocation_Rule__c, Decimal> allocationUsedByRule = new Map<Allocation_Rule__c, Decimal>();
        
        // No historic calculations for manual rules
        if (ctx.ruleType != TYPE_PICKVAL_M.getValue() && ctx.histFromDate != null && ctx.histToDate != null) {
            allocationUsedByRule = calculateUsedAllocation( ctx.histFromDate, 
                                                        	ctx.histToDate, 
                                                        	ctx.companyId,
                                                        	new Set<Id> {ctx.productId}
                                                          );
        }        							 
                                                    
        if (ctx.ruleType == TYPE_PICKVAL_M.getValue()) {
            for (Allocation_Rule__c ar : allocationUsedByRule.keySet()) {
                ar.Allocation__c = allocationUsedByRule.get(ar);
                ar.Type__c = ctx.ruleType;
                ar.name = ctx.suggestedName;
                ar.Start_Date__c = ctx.fromDate;
                ar.End_Date__c = ctx.toDate;
                ar.History_From__c = ctx.histFromDate != null ? ctx.histFromDate : null;
                ar.History_To__c = ctx.histToDate != null ? ctx.histToDate : null;
                result.records.add(new AllocationRule(ar));
            }
            system.debug('load rules - manual rules - '+ result.records);
        } 
        else
        if (ctx.ruleType == TYPE_PICKVAL_FB.getValue()) {
        	
        	Map<String, Decimal> totalAllocation = new Map<String, Decimal>(); 
                
           
                
            for (Allocation_Rule__c ar : allocationUsedByRule.keySet()) {
            	Decimal totalHistoricalAllocation = allocationUsedByRule.get(ar);
            	system.debug(LoggingLevel.INFO, 'totalHistoricalAllocation: '+totalHistoricalAllocation);
				Integer historicDays = ctx.histFromDate.daysBetween(ctx.histToDate);
				Decimal averageHistoricAllocation = totalHistoricalAllocation / historicDays;
				system.debug(LoggingLevel.INFO, 'historicDays: '+historicDays);
				system.debug(LoggingLevel.INFO, 'averageHistoricAllocation: '+averageHistoricAllocation);
				Integer forwardDays = ctx.fromDate.daysBetween(ctx.toDate);
            	system.debug(LoggingLevel.INFO, 'forwardDays: '+forwardDays);
                ar.Allocation__c = Math.floor(forwardDays * averageHistoricAllocation); //OTC-534
                ar.Type__c = ctx.ruleType;
                ar.name = ctx.suggestedName;
                ar.Start_Date__c = ctx.fromDate;
                ar.End_Date__c = ctx.toDate;
                ar.History_From__c = ctx.histFromDate != null ? ctx.histFromDate : null;
                ar.History_To__c = ctx.histToDate != null ? ctx.histToDate : null;
                
                system.debug('inside forward buy : ar - '+ ar);
                
                result.records.add(new AllocationRule(ar));
                
            }
            system.debug('load rules - forward buy rules - '+ result.records);
        } 
        else { // Historical fair share
            if (ctx.quantityToAllocate != null && ctx.quantityToAllocate > 0) {
                
                Decimal totalHistoricalAllocation = 0;
                for (Decimal alloc : allocationUsedByRule.values()) {
                    totalHistoricalAllocation += alloc;
                }
                
                for (Allocation_Rule__c ar : allocationUsedByRule.keySet()) {
                    Decimal historicTotal = allocationUsedByRule.get(ar);
                    // set other attributes
                    ar.Type__c = ctx.ruleType;
                    ar.name = ctx.suggestedName;
                    ar.Start_Date__c = ctx.fromDate;
                    ar.End_Date__c = ctx.toDate;
                    ar.History_From__c = ctx.histFromDate != null ? ctx.histFromDate : null;
                    ar.History_To__c = ctx.histToDate != null ? ctx.histToDate : null;
                    
                    AllocationRule ruleWrap = new AllocationRule(ar);
                    
                    /*System.debug(Logginglevel.DEBUG, ' > historicTotal: ' + historicTotal + ' totalHistoricalAllocation: ' 
                                    + totalHistoricalAllocation + ' ctx.quantityToAllocate: ' + ctx.quantityToAllocate );*/
                    
                    if (historicTotal == null) 
                    	historicTotal = 0;
                    
                    if (totalHistoricalAllocation > 0) {
                        // calculate the historical percent value
                        ar.Historical_Percent__c = historicTotal / totalHistoricalAllocation * 100;
                        // Adjust current allocated quantity according to the same
                        ar.Allocation__c = math.floor(ar.Historical_Percent__c / 100 * ctx.quantityToAllocate);//OTC-534
                    }
                    
                    result.records.add(ruleWrap);
                }
                system.debug('load rules - historical rules - '+ result.records);
            }
        }
        
        if (result.records.isEmpty()) {
            // create a blank rule if nothing matching could be created out of historical data
            result.records.add( newRule(ctx) );
        }
		
		return result; 
	} 
	
	@RemoteAction 
	public static List<FieldInfo> getFieldInfos(String ruleType) {
		List<FieldInfo> fieldsInfos = new List<FieldInfo>();
		FieldInfo fi;
		
		fi = FieldInfo.getFieldInfo(Allocation_Rule__c.Active__c.getDescribe());
		fi.field = 'sobj.Active__c';
		fi.editable = true;
		fi.width = 80;
		fi.title = null;
		fi.sortable = false;
		fieldsInfos.add(fi);

		fi = FieldInfo.getFieldInfo(Allocation_Rule__c.Type__c.getDescribe());
		fi.field = 'sobj.Type__c';
		fi.editable = false;
		fi.width = 130;
		fieldsInfos.add(fi);

		fi = FieldInfo.getFieldInfo(Allocation_Rule__c.Name.getDescribe());
		fi.field = 'sobj.Name';
		fi.title = 'Name';
		fi.required = true;
		fi.width = 80;
		fieldsInfos.add(fi);

		fi = FieldInfo.getFieldInfo(Allocation_Rule__c.Product__c.getDescribe());
		fi.field = 'sobj.Product__c';
		fi.editable = false;
		fi.hidden = true;
		fieldsInfos.add(fi);
		
		fi = FieldInfo.getFieldInfo(Allocation_Rule__c.Company__c.getDescribe());
		fi.field = 'sobj.Company__c';
		fi.editable = false;
		fi.hidden = true;
		fieldsInfos.add(fi);
		
		fi = FieldInfo.getFieldInfo(Allocation_Rule__c.Customer__c.getDescribe());
		fi.field = 'sobj.Customer__c';
		fieldsInfos.add(fi);
		
		fi = FieldInfo.getFieldInfo(Allocation_Rule__c.Facility__c.getDescribe());
		fi.field = 'sobj.Facility__c';
		fieldsInfos.add(fi);			
		
		if (ruleType == TYPE_PICKVAL_HFS.getValue()) {
		    fi = FieldInfo.getFieldInfo(Allocation_Rule__c.Historical_Percent__c.getDescribe());
    		fi.field = 'sobj.Historical_Percent__c';
    		fi.width = 80;
    		fieldsInfos.add(fi); 
		}
		
		fi = FieldInfo.getFieldInfo(Allocation_Rule__c.Allocation__c.getDescribe());
		fi.field = 'sobj.Allocation__c';
		fi.validation = new Map<String, Object>{'required' => true, 'min' => 1};
		fi.required = true;
		fi.width = 80;
		fieldsInfos.add(fi);
	    
	    /*
		fi = FieldInfo.getFieldInfo(Allocation_Rule__c.Allocation_Used__c.getDescribe());
		fi.field = 'sobj.Allocation_Used__c';
		fi.editable = false;
		fieldsInfos.add(fi);
		
		fieldsInfos.add(newDoubleFieldInfo('remainingAllocation', 'Remaining Allocation', false));
        */
        
        fi = newDateFieldInfo('histFromDateTime', Label.History_From , false);
		fi.width = 140;
		fieldsInfos.add(fi);
		
        fi = newDateFieldInfo('histToDateTime', Label.History_To , false);
		fi.width = 140;
		fieldsInfos.add(fi);
        
		fi = newDateFieldInfo('fromDateTime', Schema.SobjectType.Allocation_Rule__c.fields.Start_Date__c.label , true);
		fi.width = 140;
		fieldsInfos.add(fi);
		
		fi = newDateFieldInfo('toDateTime', Schema.SobjectType.Allocation_Rule__c.fields.End_Date__c.label , true);
		fi.width = 140;
		fieldsInfos.add(fi);
		
		return fieldsInfos;			
	}

	static Allocation_Rule__c[] toRuleObjects(AllocationRule[] rules) {
		Allocation_Rule__c[] ruleObjs = new Allocation_Rule__c[]{};
    	for (AllocationRule ar : rules) {
    		System.debug ('ar::' + ar);
    		// bad empty new rules, which are not in active state 
    		if (ar.sobj.Id == null && (ar.sobj.Active__c == null || !ar.sobj.Active__c)) continue;
    		if(ar.sobj.Customer__c == null || ar.sobj.Facility__c == null)
    			throw new AllocationRuleManagementException('Please enter Corporate Customer and Facility to save the Rule');
    		ruleObjs.add(ar.toRuleSobject());
    	}
    	return ruleObjs;
	}

	static FieldInfo newDoubleFieldInfo(String fieldName, String fieldLabel, Boolean editable) {
		FieldInfo fi = newFieldInfo('double', fieldName, fieldLabel, editable, null);
		fi.precision = 18;
		fi.scale = 6;
		return fi;
	}

	static FieldInfo newIntegerFieldInfo(String fieldName, String fieldLabel, Boolean editable) {
		FieldInfo fi = newFieldInfo('integer', fieldName, fieldLabel, editable, null);
		fi.precision = 18;
		fi.scale = 0;
		return fi;
	}

	static FieldInfo newDateFieldInfo(String fieldName, String fieldLabel, Boolean editable) {
		FieldInfo fi = newFieldInfo('date', fieldName, fieldLabel, editable, null);
		fi.format = 'M/d/yyyy';	
		return fi;
	}
	
	

	static FieldInfo newStringFieldInfo(String fieldName, String fieldLabel, Boolean editable) {
		FieldInfo fi = newFieldInfo('string', fieldName, fieldLabel, editable, null);
		return fi;
	}

	static FieldInfo newFieldInfo(String fieldType, String fieldName, String fieldLabel, Boolean editable, Boolean hidden) {
		FieldInfo fi = new FieldInfo();
		fi.editable = editable;
		fi.field = fieldName;
		fi.title = fieldLabel;
		fi.sortable = true;
		fi.hidden = hidden;
		fi.fieldtype = fieldType;
		return fi;
	}
    
    // Calculates used allocation within date range
    public static Map<Allocation_Rule__c, Decimal> calculateUsedAllocation(Date startDate, Date endDate, String companyId, Set<Id> productIds) {
        productIds.remove(null);
        //System.debug (logginglevel.info, String.format('startDate:{0}, endDate:{1}, productIds:{3}' , new String[]{''+startDate, ''+endDate, ''+productIds}) );
        
        String whereClause = 'Product__c IN :productIds '
							  + ' AND Shipment__r.Date_Shipped__c >= :startDate '
							  + ' AND Shipment__r.Date_Shipped__c <= :endDate '
							  + ' AND Shipment__r.Status__c IN (\'Confirmed\', \'Delivered\') ';
        SOQLUtil soql = new SOQLUtil('Shipment_Line__c', TRUE);
        soql.addFields(new Set<String>{'Quantity_Shipped__c', 'Company__c', 'Location__r.Facility__c', 'Location__r.Facility__r.Name', 'Product__c',
                                        'Shipment__r.Customer__r.Top_Parent_Customer__c', 'Shipment__r.Customer__r.Top_Parent_Customer__r.Name'});
        soql.setWhereClause(whereClause);
        /*
        String soLineSoql = 'Select Quantity_Ordered__c, Product__c, Company__c, From_Facility_Id__c, Ship_From_Location__r.Facility__r.Name, ' 
                            + ' Sales_Order__r.Customer__r.Top_Parent_Customer__c, Sales_Order__r.Customer__r.Top_Parent_Customer__r.Name '
                            + ' From Sales_Order_Line__c '
							+ ' Where Product__c IN :productIds '
							+ ' AND Status__c IN (\'Open\', \'Draft\', \'On Hold\') '
							+ ' AND Sales_Order__r.Date_Time_Ordered__c >= :startDate '
							+ ' AND Sales_Order__r.Date_Time_Ordered__c <= :endDate ';
        
         
        System.debug (LoggingLevel.info, shipmentSoql + '\n' + soLineSoql);
        */
        
        // K: Allocation Rule Record V: Total allocation so far for the date range
        Map<Allocation_Rule__c, Decimal> usedAllocationByRule = new Map<Allocation_Rule__c, Decimal>();
        for (Shipment_Line__c shipLine : Database.query(soql.getQuery())) {
            Allocation_Rule__c ar = new Allocation_Rule__c(
                                        Active__c = true,
                                        Company__c = shipLine.Company__c,
                                        Facility__c = shipLine.Location__r.Facility__c,
                                        Facility__r = shipLine.Location__r.Facility__r,
                                        Product__c = shipLine.Product__c,
                                        Customer__c = shipLine.Shipment__r.Customer__r.Top_Parent_Customer__c,
                                        Customer__r = shipLine.Shipment__r.Customer__r.Top_Parent_Customer__r
                                    );
                                    
            Decimal allocationTotal = usedAllocationByRule.get(ar);                                    
            allocationTotal = KSE.addQuantityToField(allocationTotal, shipLine.Quantity_Shipped__c);
            
            // update value back in map
            usedAllocationByRule.put(ar, allocationTotal);
	    }
	    /* OTC-493
	    for (Sales_Order_Line__c soLine : Database.query(soLineSoql)) {
	        System.debug ('soLine: From_Facility_Id__c = '  + soLine.From_Facility_Id__c 
	                        + '  Facility__r = ' + soLine.Ship_From_Location__r.Facility__r
	                        + '  Customer__c = ' + soLine.Sales_Order__r.Customer__r.Top_Parent_Customer__c 
	                        + ' Customer__r = '  + soLine.Sales_Order__r.Customer__r.Top_Parent_Customer__r
	                     );
	        Allocation_Rule__c ar = new Allocation_Rule__c(
	                                    Active__c = true,
                                        Company__c = soLine.Company__c,
                                        Facility__c = soLine.From_Facility_Id__c,
                                        Facility__r = soLine.Ship_From_Location__r.Facility__r,
                                        Product__c = soLine.Product__c,
                                        Customer__c = soLine.Sales_Order__r.Customer__r.Top_Parent_Customer__c,
                                        Customer__r = soLine.Sales_Order__r.Customer__r.Top_Parent_Customer__r
                                    );
            Decimal allocationTotal = usedAllocationByRule.get(ar);                                    
            if (allocationTotal == null) {
                allocationTotal = 0;
            }                       
            
            allocationTotal += soLine.Quantity_Ordered__c;
            // update value back in map
            usedAllocationByRule.put(ar, allocationTotal);
		}*/
	    //System.debug (Logginglevel.info, 'usedAllocationByRule:' + usedAllocationByRule);
	    return usedAllocationByRule;
    }    
    
	//
	// Wrapper classes start here 
	//
	public virtual class AllocationRule {
		
		public Allocation_Rule__c sobj {get;set;}
		public Date fromDateTime {get;set;}
		public Date toDateTime {get;set;}
		
		public Date histFromDateTime {get;set;}
		public Date histToDateTime {get;set;}
		 
		// Currently readonly if rule is in past date
		public boolean readOnly {get;set;}
		
		// init block to make sure their is a valid sobject always
		{
			sobj = new Allocation_Rule__c(
				Allocation__c = 0,
				Active__c = true, // default all rules are active
				Historical_Percent__c = 0
			);			
			//histFromDateTime = null;
			//histToDateTime = ;
		}		
	    
	    public AllocationRule(FilterInfo ctx) {
	    	
	    	this.fromDateTime = ctx.fromDate; 
            this.toDateTime = ctx.toDate;
	        this.histFromDateTime = ctx.histFromDate;
            this.histToDateTime = ctx.histToDate;
            
	        this.sobj.Type__c = ctx.ruleType;
            this.sobj.name = ctx.suggestedName;
            this.sobj.Product__c = ctx.productId;
            this.sobj.Company__c = ctx.companyId; 
            //this.sobj.Sequence__c = biggestNextSequenceNumber;
		    populateReadOnly();
	    }
	    
		public AllocationRule(Allocation_Rule__c ar) {
			this.sobj = ar;
			//this constructor converts date to datetime.getTime(). loss of time data results in wrong data when calling save Rules  --> toRuleSobject();
			system.debug('in constructor');
            this.fromDateTime = ar.Start_Date__c; 
            this.toDateTime = ar.End_Date__c;
			if ( ar.History_From__c != null ) {
			    this.histFromDateTime = ar.History_From__c; 
			}
			if ( ar.History_To__c != null ) {
			    this.histToDateTime = ar.History_To__c;
			}
			
			populateReadOnly();
		}		

		public Allocation_Rule__c toRuleSobject() {
			
			system.debug(this);
			
			sobj.Start_Date__c = this.fromDateTime;
            
             sobj.End_Date__c = this.toDateTime;
			if (this.histFromDateTime != null) {
				sobj.History_From__c = this.histFromDateTime;
			} else {
			    sobj.History_From__c = null;
			}
			
			if (this.histToDateTime != null) {
				sobj.History_To__c =  this.histToDateTime;
			   
			} else {
			    sobj.History_To__c = null;
			}
			
			System.debug (sobj);        	
			return  sobj;
		}
		
		void populateReadOnly() {
			
			
		    readOnly = System.today().daysBetween( this.fromDateTime ) <= 0;
		}
		
	}
	
}