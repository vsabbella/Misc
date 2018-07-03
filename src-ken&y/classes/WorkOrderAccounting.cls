public with sharing class WorkOrderAccounting { // extends AccountingService {
/*  
	set<id> itemSet = new set<id>();
	set<id> facilitySet = new set<id>();
	list<Datetime> itemCostDates = new list<Datetime>();
	//Map<StandardCostingService.ItemCostDefinition, List<Item_Cost__c>> mICDs = new Map<StandardCostingService.ItemCostDefinition, List<Item_Cost__c>>();
	map<String,String> lineTypeToCostComponentNameMap;
	List<Schema.FieldSetMember> stdCostFields;
    list<id> invTxnsWithExceptions = new list<id>();

	public WorkOrderAccounting(){
		super('Work_Order__c');
	}


	public override void execute(List<sObject> inventoryTransactions){
		
		//Note: This requires the source doc header field is specified in the input lines, is there a way to avoid this requirement?
		string bjId = this.batchJobId;
		set<Id> woIds = new set<Id>();
		for(Inventory_Transaction__c it : (List<Inventory_Transaction__c>)inventoryTransactions){
			woIds.add(it.Work_Order__c);
		}
		
		set<string> woFields = new set<string>{'ID', 'Name', 'Company__c', 'Company__r.Accounting_Standard__c', 'Transaction_Date__c', 'Finalized_Date__c',  'transaction_type__c', 'Total_Number_of_Lines__c', 'posting_date__c', 'Currency__c', 'Transaction_Currency__c' };
		// KNDY-10473 FLS Security Fixes for SOQL queries
		SOQLUtil woSoql = new SOQLUtil ( 'Work_Order__c' ) ;
		woSoql.addFields ( woFields ) ;
		woSoql.setWhereClause ( ' Id IN :woIds ' ) ;
					
		set<string> invTrxnFields = new set<string>{'id', 'name', 'standard_cost__c', 'quantity__c', 'type__c', 'item__c', 'item__r.item_type__c', 
					'createddate', 'to_location__r.facility__c', 'to_location__r.facility__r.company__c', 'extended_cost__c', 'subtransaction_type__c', 'line_type__c',               
					'from_location__r.facility__r.company__c', 'from_location__r.facility__c', 'to_facility__c', 'work_order__c', 'work_order__r.company__c', 'work_order__r.transaction_date__c'};
		invTrxnFields.addAll(segmentReferences);
		
		// dummy soqlUtil objects to test FLS for Anti-Joins. Remove this when SOQL Util has been optimized for Anti-Joins
		SOQLUtil aeSoql = new SOQLUtil ( 'Accounting_Entry__c' ) ;
		aeSoql.addField ( 'Work_Order__c' ) ;
		aeSoql.setWhereClause ( ' Work_Order__c IN :woIds AND Related_Accounting_Entry__c = null  AND status__c=\'Active\' AND (period__r.closed__c = true OR period__r.permanently_closed__c = true OR period__r.Inventory_Subledger_Closed__c != null) ' ) ;
		
		SOQLUtil aelSoql = new SOQLUtil ( 'Accounting_Entry_Line__c' ) ;
		aelSoql.addField ( 'Inventory_Transaction__c' ) ;
		aelSoql.setWhereClause ( ' Accounting_Entry__r.Status__c = \'Draft\' AND Inventory_Transaction__c IN :inventoryTransactions AND Accounting_Entry__r.BatchJobId__c = :bjId ' ) ;
		
		SOQLUtil itSoql = new SOQLUtil ( 'Inventory_Transaction__c' ) ;
		itSoql.addFields ( invTrxnFields ) ;
		
		// Remove FOR UPDATE locking stmts from WHERE clause when lock statement setter is made available in SOQLUtil
		itSoql.setWhereClause ( ' Id in :inventoryTransactions '
        						+ ' AND isFinalized__c = true '
        						+ ' AND Work_Order__r.Company__c != null '  
        						+ ' AND Historical__c = false '                          
        						+ ' AND Work_Order__r.Company__r.Default_Transaction_Currency__c != null '
        						+ ' AND Work_Order__r.Transaction_Date__c != null '
        						+ ' AND Work_Order__c NOT IN (SELECT Work_Order__c FROM Accounting_Entry__c WHERE Work_Order__c IN :woIds AND Related_Accounting_Entry__c = null  AND status__c=\'Active\' AND (period__r.closed__c = true OR period__r.permanently_closed__c = true OR period__r.Inventory_Subledger_Closed__c != null))' //FIN-889 AND batchjobid__c!=null and batchjobid__c!=:batchJobID) ' 
                                + ' AND Id NOT IN (SELECT Inventory_Transaction__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Inventory_Transaction__c IN :inventoryTransactions AND Accounting_Entry__r.BatchJobId__c = :bjId) '
                                + ' FOR UPDATE' ) ;
                        
		string invTrxnQuery = 'SELECT ' + string.join(new List<string>(invTrxnFields), ', ');
		invTrxnQuery += ' FROM Inventory_Transaction__c '
						+ ' WHERE Id in :inventoryTransactions '
						+ ' AND isFinalized__c = true '
						+ ' AND Work_Order__r.Company__c != null '  
						+ ' AND Historical__c = false '                          
						+ ' AND Work_Order__r.Company__r.Default_Transaction_Currency__c != null '
						+ ' AND Work_Order__r.Transaction_Date__c != null '
						+ ' AND Work_Order__c NOT IN (SELECT Work_Order__c FROM Accounting_Entry__c WHERE Work_Order__c IN :woIds AND Related_Accounting_Entry__c = null  AND status__c=\'Active\' AND (period__r.closed__c = true OR period__r.permanently_closed__c = true OR period__r.Inventory_Subledger_Closed__c != null))' //FIN-889 AND batchjobid__c!=null and batchjobid__c!=:batchJobID) ' 
                        + ' AND Id NOT IN (SELECT Inventory_Transaction__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Inventory_Transaction__c IN :inventoryTransactions AND Accounting_Entry__r.BatchJobId__c = :bjId) '
                        + ' FOR UPDATE';  
		Map<Id, Accounting_Entry__c> mSourceDocAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mSourceDocAELs = new Map<Id, List<Accounting_Entry_Line__c>>();
        Map<Id, Work_Order__c> mWOs = new Map<Id, Work_Order__c>();
		Map<Id, Inventory_Transaction__c> mITs = new Map<Id, Inventory_Transaction__c>();
		try{
			//Grab Lines for this scope
        	mITs = new Map<Id, Inventory_Transaction__c>((List<Inventory_Transaction__c>)Database.query( itSoql.getQuery() ));
        	//Place the headers in a map for later reference
        	mWOs = new Map<Id, Work_Order__c>((List<Work_Order__c>)Database.Query( woSoql.getQuery() ));
        	findExistingDraftAEs(mWOs.keySet());
		}catch(Exception ex){
           
			throw ex;
		}
  		//KNDY-9545 
  		//Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
  		//This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
  		//This approach avoids handling all rules for the object and increases efficiency.
  		loadEffRuleDetails(mWOs);
  		
		system.debug(LOGGINGLEVEL.INFO,'mRuleDefs'+mRuleDefs);
			
        
        for(Inventory_Transaction__c it : mITs.values()){
            itemSet.add(it.item__c);
            itemCostDates.add(it.Work_Order__r.transaction_date__c);
            if (it.To_Location__r.Facility__c == null) {
				facilitySet.add(it.From_Location__r.Facility__c);
			}else{
				facilitySet.add(it.to_location__r.facility__c);
        }
        
        }
        // first call to itemservice to cache data
        ItemService.preCacheCostRecords(itemCostDates, itemSet, facilitySet);
        
        //mICDs = StandardCostingService.getActiveStandardCostDefinitions(itemSet, new List<Date>{system.today()}); //itemCostDates
        
		//----KNDY-2170
		// Get fields for Item Cost fieldset
		stdCostFields = SObjectType.Item_Cost__c.FieldSets.Cost_Rollup_Fields.getFields();
		system.debug('stdCostFields: '+stdCostFields);          
		

		//build a map of the line types to the cost component field names (the cost component fields labels need to match the accounting rule line types)
		lineTypeToCostComponentNameMap = new map<String,String>();      
		for (Schema.FieldSetMember costComponent: stdCostFields) {
			lineTypeToCostComponentNameMap.put(costComponent.getLabel(),costComponent.getFieldPath());  
		} 

		//----KNDY-2170
		// Build set of items to query item costs
		for(Inventory_Transaction__c invLine : mITs.values()){
			if(invLine.Type__c == 'Work Order Assembly Completion'){
		    	itemSet.add(invLine.Item__c);
			}
		}
		
		
		for (Inventory_Transaction__c it : mITs.values()) {
			
			Accounting_Entry__c iAE;
        	Work_Order__c wo = mWOs.get(it.work_order__c);
        	if(mSourceDocAEs.containsKey(it.work_order__c)){
        		iAE = mSourceDocAes.get(it.work_order__c);
        	}else{
        		iAE = generateAccountingEntry(wo, 'Work Order');
        		mSourceDocAEs.put(wo.Id, iAE);
        	}

			List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
			string transType = iAE.Transaction_Type__c;
			string subTrans = (it.Subtransaction_Type__c != null && it.Subtransaction_Type__c != '') ? it.Subtransaction_Type__c : null;

			//DP: going with custom logic for the line type on these.  overriding what the workflow has set
			//TODO: update the workflow to work correctly with WO Inventory transactions
			it.Line_Type__c = it.Item__r.Item_Type__c;

			iAELs.addAll(ruleAEbuilder(wo, iAE, transType, subTrans, it, it.Line_Type__c, false)); //add all the AEs for the normal accounting rules

			for (String compLineType : lineTypeToCostComponentNameMap.keySet()) { //loop through and generate all the AEs based on the composite costs
				iAELs.addAll(ruleAEbuilder(wo, iAE, transType, subTrans, it, compLineType, true));	
			}
			
			mSourceDocAELs.put(it.Id, iAELs);
		}
    	logs.add('ItemSetIds==>'+String.valueOf(itemSet));
        //logs.add('mICDs==>'+String.valueOf(mICDs));
        logs.add('TransactionsIds'+String.valueOf(invTxnsWithExceptions));
        finish((Map<Id, sObject>)mWOs, (Map<Id, sObject>)mITs, mSourceDocAEs, mSourceDocAELs);
         
	}    
		
	

	private list<Accounting_Entry_Line__c> ruleAEbuilder(Work_Order__c wo, Accounting_Entry__c iAE, String transType, String subTrans, Inventory_Transaction__c it, String lineType, boolean isComposite) {
	
		List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();     
      
		//Create the rule definitions for this line
		AccountingRuleService.RuleDefinition iCRRuleDef = 
			new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, wo.Company__r.Accounting_Standard__c, 'Work_Order__c', transType, subTrans, lineType);
		AccountingRuleService.RuleDefinition iDRRuleDef = 
			new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, wo.Company__r.Accounting_Standard__c, 'Work_Order__c', transType, subTrans, lineType);
		AccountingRuleService.RuleDefinition iNARuleDef = 
			new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, wo.Company__r.Accounting_Standard__c, 'Work_Order__c', transType, subTrans, lineType);
        
        if(mRuleDefs.containsKey(iNARuleDef)){
			//system.debug(logginglevel.INFO, 'NA Rule Defs: ' + mRuleDefs.get(iNARuleDef).size() + ' - '  + mRuleDefs.get(iNARuleDef));
			//Do nothing when NA rules are identified
			for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
				referencedRules.add(ar);
			}
            return iAELs;
		}
        
		//system.debug(logginglevel.INFO, 'iCRRuleDef: ' + iCRRuleDef);
		//system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iCRRuleDef));
		boolean nullFlag = false;
		if (mRuleDefs.containsKey(iCRRuleDef)) {
			Integer outDatedRuleCount =0;			
			system.debug(logginglevel.INFO, 'CR Rule Defs: ' + mRuleDefs.get(iCRRuleDef).size() + ' - '  + mRuleDefs.get(iCRRuleDef));
			for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){                 
				//KNDY-9545
				if((ar.Effective_End_Date__c!=null ? wo.transaction_date__c >= ar.Effective_End_Date__c:false)     || wo.transaction_date__c < ar.Effective_Start_Date__c  )
				{
					//ReturnLine for missing rule
					if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
					{
						Id locationFacilityId = it.To_Location__r.Facility__c;
						if (locationFacilityId == null) {
							locationFacilityId = it.From_Location__r.Facility__c;
						}      
						Id locationFacilityCompanyId = it.To_Location__r.Facility__r.Company__c;      
						if (locationFacilityCompanyId == null) {
							locationFacilityCompanyId = it.From_Location__r.Facility__r.Company__c;	
						}     
						Decimal amount;
						Decimal activeStandardCost = ItemService.getActiveStandardCost(itemSet,facilitySet, locationFacilityCompanyId,locationFacilityId,it.Work_Order__r.transaction_date__c).get(it.item__c);
						
						if(activeStandardCost == null){
							nullFlag = true;
						}else if (activeStandardCost != null && it.Quantity__c != null) {
							amount = (activeStandardCost * it.Quantity__c);      
						}
						//System.Debug(LOGGINGLEVEL.INFO,'%%'+isComposite + '--' + isCompositeCost(subTrans, 'CR'));
						if((isComposite && isCompositeCost(subTrans, 'CR')) || (!isComposite && !isCompositeCost(subTrans,'CR'))) {
							if(isComposite){
								amount = findLineAmountforMissingRules(it, lineType);
							}
							iAELs.add(returnLineForMissingEffectiveRule(iAE, it, iCRRuleDef, amount, nullFlag));
						}
								
					}
					outDatedRuleCount++;
					continue;
				}
				decimal iCRAmt = findLineAmount(it, ar);
				//KNDY-4672
				if (iCRAmt == null) {
					iCRAmt = 0;
					nullFlag = true;
					//continue;
				}  
				
				Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, wo, it, ar, iCRAmt);
				iAEL.SubTransaction_Type__c = subTrans;
				//iAEL.Line_Type__c = it.Line_Type__c;
				if(nullFlag == true){
					iAEL.item_cost_missing__c = true;
				}else{
					iAEL.item_cost_missing__c = false;
				}             
				SS.assignSegments(ar, it, iAEL);       
				//System.Debug(LOGGINGLEVEL.INFO,'%'+isComposite + '--' + isCompositeCost(subTrans, 'CR'));       
				if((isComposite && isCompositeCost(subTrans, 'CR')) || (!isComposite && !isCompositeCost(subTrans,'CR'))) {
					iAELs.add(iAEL);
				    referencedRules.add(ar);
				}
			} 
		}else{
			Id locationFacilityId = it.To_Location__r.Facility__c;
			if (locationFacilityId == null) {
				locationFacilityId = it.From_Location__r.Facility__c;
			}      
			Id locationFacilityCompanyId = it.To_Location__r.Facility__r.Company__c;      
			if (locationFacilityCompanyId == null) {
				locationFacilityCompanyId = it.From_Location__r.Facility__r.Company__c;	
			}     
			Decimal amount;
			Decimal activeStandardCost = ItemService.getActiveStandardCost(itemSet,facilitySet, locationFacilityCompanyId,locationFacilityId,it.Work_Order__r.transaction_date__c).get(it.item__c);
			
			if(activeStandardCost == null){
				nullFlag = true;
			}else if (activeStandardCost != null && it.Quantity__c != null) {
				amount = (activeStandardCost * it.Quantity__c);      
			}
			//System.Debug(LOGGINGLEVEL.INFO,'%%'+isComposite + '--' + isCompositeCost(subTrans, 'CR'));
			if((isComposite && isCompositeCost(subTrans, 'CR')) || (!isComposite && !isCompositeCost(subTrans,'CR'))) {
				if(isComposite){
					amount = findLineAmountforMissingRules(it, lineType);
				}
				iAELs.add(returnLineForMissingRule(iAE, it, iCRRuleDef, amount, nullFlag));
			}
		}          

		//system.debug(logginglevel.INFO, 'iDRRuleDef: ' + iDRRuleDef);
		//system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iDRRuleDef));
		if (mRuleDefs.containsKey(iDRRuleDef)) {
			Integer outDatedRuleCount =0;						
			system.debug(logginglevel.INFO, 'DR Rule Defs: ' + mRuleDefs.get(iDRRuleDef).size() + ' - '  + mRuleDefs.get(iDRRuleDef));
			for (Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)) {
 				//KNDY-9545
				if((ar.Effective_End_Date__c!=null ? wo.transaction_date__c >= ar.Effective_End_Date__c:false)   || wo.transaction_date__c < ar.Effective_Start_Date__c  )
				{
					//ReturnLine for missing rule
					if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
					{
						Id locationFacilityId = it.To_Location__r.Facility__c;
						if (locationFacilityId == null) {
							locationFacilityId = it.From_Location__r.Facility__c;
						}      
						Id locationFacilityCompanyId = it.To_Location__r.Facility__r.Company__c;      
						if (locationFacilityCompanyId == null) {
							locationFacilityCompanyId = it.From_Location__r.Facility__r.Company__c;	
						}     
						Decimal amount;
						Decimal activeStandardCost = ItemService.getActiveStandardCost(itemSet,facilitySet, locationFacilityCompanyId,locationFacilityId,it.Work_Order__r.transaction_date__c).get(it.item__c);
						
						if(activeStandardCost == null){
							nullFlag = true;
						}else if (activeStandardCost != null && it.Quantity__c != null) {
							amount = (activeStandardCost * it.Quantity__c);      
						}
						//System.Debug(LOGGINGLEVEL.INFO,'%%'+isComposite + '--' + isCompositeCost(subTrans, 'CR'));
						if((isComposite && isCompositeCost(subTrans, 'DR')) || (!isComposite && !isCompositeCost(subTrans,'DR'))) {
							if(isComposite){
								amount = findLineAmountforMissingRules(it, lineType);
							}
							iAELs.add(returnLineForMissingEffectiveRule(iAE, it, iDRRuleDef, amount, nullFlag));
						}
								
					}
					outDatedRuleCount++;
					continue;
				}         
				decimal iDRAmt = findLineAmount(it, ar);
				//KNDY-4672
				if (iDRAmt == null) {
					iDRAmt = 0;
					nullFlag = true;
					//continue;
				} 
				
				Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, wo, it, ar, iDRAmt);
				iAEL.SubTransaction_Type__c = subTrans;
				//iAEL.Line_Type__c = it.Line_Type__c;                
				if(nullFlag == true){
					iAEL.item_cost_missing__c = true;
				}else{
					iAEL.item_cost_missing__c = false;
				}
				
				
				SS.assignSegments(ar, it, iAEL);    
				//System.Debug(LOGGINGLEVEL.INFO,'%%%'+isComposite + '--' + isCompositeCost(subTrans, 'DR'));          
          		if((isComposite && isCompositeCost(subTrans, 'DR')) || (!isComposite && !isCompositeCost(subTrans,'DR'))) {
					iAELs.add(iAEL);
				    referencedRules.add(ar);
          		}
			}
		}else{
			Id locationFacilityId = it.To_Location__r.Facility__c;
			if (locationFacilityId == null) {
				locationFacilityId = it.From_Location__r.Facility__c;
			}      
			Id locationFacilityCompanyId = it.To_Location__r.Facility__r.Company__c;      
			if (locationFacilityCompanyId == null) {
				locationFacilityCompanyId = it.From_Location__r.Facility__r.Company__c;	
			}     
			Decimal amount;
			Decimal activeStandardCost = ItemService.getActiveStandardCost(itemSet, facilitySet, locationFacilityCompanyId,locationFacilityId,it.Work_Order__r.transaction_date__c).get(it.item__c);
			
			if(activeStandardCost == null){
				nullFlag = true;
			}else if (activeStandardCost != null && it.Quantity__c != null) {
				amount = (activeStandardCost * it.Quantity__c);      
			}

			//System.Debug(LOGGINGLEVEL.INFO,'%%%%'+isComposite + '--' + isCompositeCost(subTrans, 'DR'));
			if((isComposite && isCompositeCost(subTrans, 'DR')) || (!isComposite && !isCompositeCost(subTrans,'DR'))) {
				if(isComposite){
					amount = findLineAmountforMissingRules(it, lineType);
				}
				iAELs.add(returnLineForMissingEffectiveRule(iAE, it, iDRRuleDef, amount, nullFlag));
			}
		}
              
		return iAELs;
	}

	private decimal findLineAmountforMissingRules (Inventory_transaction__c it,String compLineType) {
		decimal amount;
			try {	
				if(lineTypeToCostComponentNameMap.containsKey(compLineType)) {
						String costComponentFieldName = lineTypeToCostComponentNameMap.get(compLineType); //get the cost component field name from the line type
						Item_Cost__c tmpCostRecord = ItemService.getActiveStandardCostRecord(itemSet, facilitySet, it.To_Location__r.Facility__r.Company__c, it.To_Location__r.Facility__c,it.inventory_change__r.transaction_date__c).get(it.Item__c);
						Decimal tmpCost;
						if(tmpCostRecord != null) tmpCost =  (Decimal) tmpCostRecord.get(costComponentFieldName);	
						amount = (KSE.addQuantityToField(tmpCost,0) * it.Quantity__c);	
				}
				
			} catch (Exception ex) {
                invTxnsWithExceptions.add(it.id);
		        logs.add('ItemSetIds==>'+String.valueOf(itemSet));
		        logs.add('TransactionsIds'+String.valueOf(invTxnsWithExceptions));
				throw ex;
			}

		return amount;
	}
  
	private decimal findLineAmount (Inventory_transaction__c it, Accounting_Rule__c ar) {
		decimal amount;   
		if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != '') {
    		amount = (decimal)it.get(ar.Amount_Reference__c);     
		} else {

			boolean isComposite = isCompositeCost(ar);
      
			if (isComposite) {
				try {		
					if(lineTypeToCostComponentNameMap.containsKey(ar.Line_Type__c)) {
						String costComponentFieldName = lineTypeToCostComponentNameMap.get(ar.Line_Type__c); //get the cost component field name from the line type
						Item_Cost__c tmpCostRecord = ItemService.getActiveStandardCostRecord(itemSet, facilitySet, it.To_Location__r.Facility__r.Company__c, it.To_Location__r.Facility__c,it.inventory_change__r.transaction_date__c).get(it.Item__c);
						Decimal tmpCost;
						if(tmpCostRecord != null) tmpCost =  (Decimal) tmpCostRecord.get(costComponentFieldName);							
						amount = (KSE.addQuantityToField(tmpCost,0) * it.Quantity__c);	
					}
				} catch (Exception ex) {
                    invTxnsWithExceptions.add(it.id);
			        logs.add('ItemSetIds==>'+String.valueOf(itemSet));
			        //logs.add('mICDs==>'+String.valueOf(mICDs));
			        logs.add('TransactionsIds'+String.valueOf(invTxnsWithExceptions));
					throw ex;
					//system.debug(logginglevel.ERROR, 'costComponentAmt exception: ' + ex.getMessage());
				}
			}     
     
			if (!isComposite) {
				//DP: set the facility and the company to the "to" values, if they are null set them to the "from" values.
				//need to double check if this is correct.  Not sure if there are cases when they will both be populated and we need to choose 
				//based on inventory transaction type    
				Id locationFacilityId = it.To_Location__r.Facility__c;
				if (locationFacilityId == null) {
					locationFacilityId = it.From_Location__r.Facility__c;
				}      
				Id locationFacilityCompanyId = it.To_Location__r.Facility__r.Company__c;      
				if (locationFacilityCompanyId == null) {
					locationFacilityCompanyId = it.From_Location__r.Facility__r.Company__c;	
				}     
  
				Decimal activeStandardCost = ItemService.getActiveStandardCost(itemSet, facilitySet, locationFacilityCompanyId,locationFacilityId,it.Work_Order__r.transaction_date__c).get(it.item__c);
				
				if (activeStandardCost != null && it.Quantity__c != null) {
					amount = (activeStandardCost * it.Quantity__c);      
				}
			} 

		}
		return amount;    
	} 

	private boolean isCompositeCost(Accounting_Rule__c ar) {
		boolean isComposite = false;
      
		if ((ar.SubTransaction_Type__c =='Work Order Assembly Completion') && (ar.Rule_Type__c == 'CR')) {
  			isComposite = true;
  		} 		
		if ((ar.SubTransaction_Type__c =='Work Order Assembly Uncompletion') && (ar.Rule_Type__c == 'DR')) {
			isComposite = true;
		} 
		//FIN-310	   
		if ((ar.SubTransaction_Type__c =='Work Order Assembly Scrap') && (ar.Rule_Type__c == 'CR')) { //DR
			isComposite = true;
		}		   	

		return isComposite;
	}

	private boolean isCompositeCost(String subTrans, String ruleType) {
		boolean isComposite = false;
      
		if ((subTrans =='Work Order Assembly Completion') && (ruleType == 'CR')) {
  			isComposite = true;
  		} 		
		if ((subTrans =='Work Order Assembly Uncompletion') && (ruleType == 'DR')) {
			isComposite = true;
		} 	   
		//FIN-310
		if ((subTrans =='Work Order Assembly Scrap') && (ruleType == 'CR')) { //DR
			isComposite = true;
		}		   	

		return isComposite;
	}
  
	public override Accounting_Entry_Line__c generateAccountingEntryLine(Accounting_Entry__c acctEntry, sObject wo, sObject it, Accounting_Rule__c ar, decimal amount){
		Accounting_Entry_Line__c ael = new Accounting_Entry_Line__c();
		ael.Transaction_Date__c = (Datetime.valueof(it.get('CreatedDate')) != null? Datetime.valueof(it.get('CreatedDate')).date() : null);        
		//ael.SubTransaction_Type__c = it.subtransaction_type__c;
		ael.Line_Type__c = String.valueof(it.get('Line_Type__c'));
		//ael.Accounting_Entry__c = acctEntry.id;
		ael.Company__c = acctEntry.Company__c;
		ael.Source_ID__c = String.valueof(it.get('Id'));
		ael.Source_Name__c = String.valueof(it.get('name'));
		ael.Inventory_Transaction__c = it.Id;
		ael.Accounting_Entry__r = new Accounting_Entry__c(source_key__c = acctEntry.source_key__c);
		ael.accounting_rule__c = ar.Id;
		if (isCompositeCost(ar)) {
			//on these the line type comes from the rule instead of the inventory transaction
			//this allows for >1 line types for each inventory transaction
			ael.Line_Type__c = ar.Line_Type__c; 
		}
		
		//FIN-368
		decimal absAmount = math.abs(amount);
        if(ar.Expected_Sign__c == 'Positive' || ar.Expected_Sign__c == null){
        	if(amount >= 0){
        		if(ar.Rule_Type__c == 'CR'){
        			ael.amount_CR__c = absAmount;
        			ael.amount_DR__c = 0;
        		}else if(ar.Rule_Type__c == 'DR'){
        			ael.amount_CR__c = 0;
        			ael.amount_DR__c = absAmount;
        		}
        	}else{
				if(ar.Rule_Type__c == 'CR'){
        			ael.amount_CR__c = 0;
        			ael.amount_DR__c = absAmount;
        		}else if(ar.Rule_Type__c == 'DR'){
        			ael.amount_CR__c = absAmount;
        			ael.amount_DR__c = 0;
        		}        		
        	}
        }else if(ar.Expected_Sign__c == 'Negative'){
        	if(amount <= 0){
	        	if(ar.Rule_Type__c == 'CR'){
	        		ael.amount_CR__c = absAmount;
        			ael.amount_DR__c = 0;
	        	}else if(ar.Rule_Type__c == 'DR'){
	        		ael.amount_CR__c = 0;
        			ael.amount_DR__c = absAmount;
	        	}
        	}else{
        		if(ar.Rule_Type__c == 'CR'){
        			ael.amount_CR__c = 0;
        			ael.amount_DR__c = absAmount;
        		}else if(ar.Rule_Type__c == 'DR'){
        			ael.amount_CR__c = absAmount;
        			ael.amount_DR__c = 0;
        		}   
        	}
       	}

        return ael;
	}
	
	public Item_Cost__c returnItemCost(Date trxnDate, List<Item_Cost__c> itemCosts){
		//system.debug('checking: ' + itemCosts);
		Item_Cost__c activeCost;
		if(itemCosts == null){
			return null;
		}else{
			for(Item_Cost__c ic : itemCosts){
				if(trxnDate >= ic.Date_Activated__c){
					activeCost = ic;
					break;
				}
			}
		}
		system.debug('returning activeCost: ' + activeCost);
		return activeCost;
	}
*/	
  
}