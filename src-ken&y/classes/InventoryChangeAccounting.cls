public with sharing class InventoryChangeAccounting extends AccountingService {

	set<id> itemSet = new set<id>();
	set<id> facilitySet = new set<id>();
	list<Datetime> itemCostDates = new list<Datetime>();
	//Map<StandardCostingService.ItemCostDefinition, List<Item_Cost__c>> mICDs = new Map<StandardCostingService.ItemCostDefinition, List<Item_Cost__c>>();
	map<String,String> lineTypeToCostComponentNameMap;
	List<Schema.FieldSetMember> stdCostFields;
    list<id> invTxnsWithExceptions = new list<id>();
	
    public InventoryChangeAccounting(){
        super('Inventory_Change__c');
    }     
       

	public class AmountResultWrapper{
		decimal amount;
		decimal amountFN;
		Exchange_Rate__c exrate;
		boolean nullFlag = false;
		boolean ExSerFlag = false;
	
	}

    public override void execute(List<sObject> inventoryTransactions){
		
		//Note: This requires the source doc header field is specified in the input lines, is there a way to avoid this requirement?
		string bjId = this.batchJobId;
		set<Id> icIds = new set<Id>();
		for(Inventory_Transaction__c it : (List<Inventory_Transaction__c>)inventoryTransactions){
			icIds.add(it.inventory_change__c);
		}

            
         set<string> invChFields = new set<string>{'id', 'name', 'company__c', 'company__r.accounting_standard__c', 'createddate','Company__r.Comp_Currency__c', 'company__r.Default_Transaction_Currency__c', 'currency__c', 'Transaction_Currency__c',
                                            'count_quantity__c', 'computer_quantity__c', 'type__c', 'transaction_type__c', 'item__c','finalized_date__c', 'transaction_date__c', 'total_number_of_lines__c', 'posting_date__c'};          

        
        //string icQuery = 'SELECT ' + string.join(new List<string>(invChFields),', ');
		//icQuery += ' FROM Inventory_Change__c WHERE Id IN :icIds';
        String whereClause1 = 'Id IN :icIds';//KNDY-8796
        SOQLUtil soql1 = new SOQLUtil('Inventory_Change__c',true);
         soql1.addFields(invChFields);
         soql1.setWhereClause(whereClause1);
        
        
        set<string> invChLineFields = new set<string>{'id', 'name', 'standard_cost__c', 'quantity__c', 'type__c', 'item__c', 'item__r.item_type__c', 'Quantity_Stocking_UOM__c',
					'createddate', 'to_location__r.facility__c', 'to_location__r.facility__r.company__c', 'extended_cost__c', 'subtransaction_type__c', 'line_type__c', 'from_standard_cost__c', 'to_standard_cost__c',              
					'from_location__r.facility__r.company__c', 'from_location__r.facility__c', 'to_facility__c', 'Inventory_Change__c', 'Work_Order__c','work_order__r.company__c', 'work_order__r.transaction_date__c', 'inventory_change__r.transaction_date__c'};
        invChLineFields.addAll(segmentReferences);      

        /*    
        string invTrxnQuery = 'SELECT ' + string.join(new List<string>(invChLineFields), ', ');
        invTrxnQuery += ' FROM Inventory_Transaction__c '
                        + 'WHERE Id in :inventoryTransactions '
                        + 'AND isFinalized__c = true '
                        + 'AND Historical__c = false ' 
                        + 'AND Inventory_Change__r.Company__c != null '
                        + 'AND Inventory_Change__r.Currency__c != null '
                        + 'AND Inventory_Change__c NOT IN (SELECT Inventory_Change__c FROM Accounting_Entry__c WHERE Inventory_Change__c IN :icIds AND Related_Accounting_Entry__c = null  AND status__c=\'Active\' AND (period__r.closed__c = true OR period__r.permanently_closed__c = true or period__r.inventory_subledger_closed__c != null ) )' //FIN-889 AND batchjobid__c!=null and batchjobid__c!=:batchJobID) ' 
                        + 'AND Id NOT IN (SELECT Inventory_Transaction__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Inventory_Transaction__c IN :inventoryTransactions AND Accounting_Entry__r.BatchJobId__c = :bjId)  '
                        + 'FOR UPDATE'; */
        
        String whereClause =  ' Id in :inventoryTransactions '
                        + 'AND isFinalized__c = true '
                        + 'AND Historical__c = false ' 
                        + 'AND Inventory_Change__r.Company__c != null '
                        + 'AND (Inventory_Change__r.Currency__c != null or Inventory_Change__r.Transaction_Currency__c != null) '
                        + 'AND Inventory_Change__c NOT IN (SELECT Inventory_Change__c FROM Accounting_Entry__c WHERE Inventory_Change__c IN :icIds AND Related_Accounting_Entry__c = null  AND status__c=\'Active\' AND (period__r.closed__c = true OR period__r.permanently_closed__c = true or period__r.inventory_subledger_closed__c != null ) )' //FIN-889 AND batchjobid__c!=null and batchjobid__c!=:batchJobID) ' 
                        + 'AND Id NOT IN (SELECT Inventory_Transaction__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Inventory_Transaction__c IN :inventoryTransactions AND Accounting_Entry__r.BatchJobId__c = :bjId)  '
                        + 'FOR UPDATE'; //KNDY-8796
        SOQLUtil soql = new SOQLUtil('Inventory_Transaction__c',true);
        soql.addFields(invChLineFields);
        soql.setWhereClause(whereClause);
                               
        Map<Id, Accounting_Entry__c> mSourceDocAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mSourceDocAELs = new Map<Id, List<Accounting_Entry_Line__c>>();
        Map<Id, Inventory_Change__c> mICs = new Map<Id, Inventory_Change__c>();
		Map<Id, Inventory_Transaction__c> mITs = new Map<Id, Inventory_Transaction__c>();
        try{
            //Grab Lines for this scope
        	//mITs = new Map<Id, Inventory_Transaction__c>((List<Inventory_Transaction__c>)Database.query(invTrxnQuery));
            mITs = new Map<Id, Inventory_Transaction__c>((List<Inventory_Transaction__c>)Database.query(soql.getQuery()));
        	//Place the headers in a map for later reference
        	mICs = new Map<Id, Inventory_Change__c>((List<Inventory_Change__c>)Database.Query(soql1.getQuery() ));
        	findExistingDraftAEs(mICs.keySet());
        }catch(Exception ex){
            throw ex;
        }
         List<Datetime>exdates = new List<Datetime>();
         Set<Id>tocurrency = new Set<Id>();
         Set<Id>fromCurrency = new Set<Id>();
         for(Inventory_Change__c ic : mICs.values()){
             exdates.add(ic.transaction_date__c);
             tocurrency.add(ic.Currency__c);
             fromCurrency.add(ic.Company__r.Comp_Currency__c);
         }
         ExchangeRateService.loadExchangeRates(fromCurrency, tocurrency, exdates); 
        
  		//KNDY-9545 
  		//Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
  		//This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
  		//This approach avoids handling all rules for the object and increases efficiency.
  		loadEffRuleDetails(mICs);
  		
		system.debug(LOGGINGLEVEL.INFO,'mRuleDefs'+mRuleDefs);
		
        for(Inventory_Transaction__c it : mITs.values()){
            itemSet.add(it.item__c);
            itemCostDates.add(it.inventory_change__r.transaction_date__c);
           if ( (it.type__c!=null &&  (it.type__c == 'Transfer Order Shipment' ||  it.type__c =='Transfer Shipment'))  
             				|| it.To_Location__r.Facility__c == null )  { 
				facilitySet.add(it.From_Location__r.Facility__c);
			}else{
				facilitySet.add(it.to_location__r.facility__c);
            }
			
        }
        system.debug(logginglevel.info,'facilitySet:'+facilitySet);
        // first call to itemservice to cache data
        ItemService.preCacheCostRecords(itemCostDates, itemSet, facilitySet);
		/*if(itemCostDates != null && itemCostDates.size() > 0){
			Datetime latestDatetime = itemCostDates[itemCostDates.size()-1];
			if(latestDatetime != null){
				Map <Id,Double> mTmpCost = ItemService.getActiveStandardCost(itemSet, facilitySet, facilityCompanyId, facilityId, latestDatetime);
		}
		}*/
		
        
        //mICDs = StandardCostingService.getActiveStandardCostDefinitions(itemSet, new List<Date>{system.today()}); //itemCostDates
        
		//----KNDY-2170
		// Get fields for Item Cost fieldset
		stdCostFields = SObjectType.Item_Cost__c.FieldSets.Cost_Rollup_Fields.getFields();
		system.debug(logginglevel.info,'stdCostFields: '+stdCostFields);          
		

		//build a map of the line types to the cost component field names (the cost component fields labels need to match the accounting rule line types)
		lineTypeToCostComponentNameMap = new map<String,String>();      
		for (Schema.FieldSetMember costComponent: stdCostFields) {
			lineTypeToCostComponentNameMap.put(costComponent.getLabel(),costComponent.getFieldPath());  
		} 


        for(Inventory_Transaction__c it : mITs.values()){
        	
        	Accounting_Entry__c iAE;
        	Inventory_Change__c ic = mICs.get(it.Inventory_Change__c);
        	if(mSourceDocAEs.containsKey(it.Inventory_Change__c)){
        		iAE = mSourceDocAes.get(it.Inventory_Change__c);
        	}else{
        		iAE = generateAccountingEntry(ic, ic.Type__c);
        		mSourceDocAEs.put(ic.Id, iAE);
        	}
        	
			List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
			string transType = iAE.Transaction_Type__c;
			string subTrans = (it.Subtransaction_Type__c != null && it.Subtransaction_Type__c != '') ? it.Subtransaction_Type__c : null;

			//DP: going with custom logic for the line type on these.  overriding what the workflow has set
			//TODO: update the workflow to work correctly with WO Inventory transactions
			if(it.Work_Order__c != null){
				it.Line_Type__c = it.Item__r.Item_Type__c;
			}
			
			//TODO: SK - what are valid scenarios for Inventory Transactions belonging to Inventory Change
			
			iAELs.addAll(ruleAEbuilder(ic, iAE, transType, subTrans, it, it.Line_Type__c, false)); //add all the AEs for the normal accounting rules

			for (String compLineType : lineTypeToCostComponentNameMap.keySet()) { //loop through and generate all the AEs based on the composite costs
				iAELs.addAll(ruleAEbuilder(ic, iAE, transType, subTrans, it, compLineType, true));	
			}
			
			mSourceDocAELs.put(it.Id, iAELs);
		
        	/*Accounting_Entry__c iAE;
        	Inventory_Change__c ic = mICs.get(it.Inventory_Change__c);
        	if(mSourceDocAEs.containsKey(it.Inventory_Change__c)){
        		iAE = mSourceDocAes.get(it.Inventory_Change__c);
        	}else{
        		iAE = generateAccountingEntry(ic, ic.Type__c);
        		mSourceDocAEs.put(ic.Id, iAE);
        	}
        	
            
            List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
            
            string transType = iAE.Transaction_Type__c;
            string subTrans = (it.Subtransaction_Type__c != null && it.Subtransaction_Type__c != '') ? it.Subtransaction_Type__c : null;
            
            //-----KNDY-2170
            // TODO Put in a check to make sure the standard costs are the same
            // If not, then create an inventory transfer variance
            Decimal activeStandardCost = 0;
            if(it.To_Standard_Cost__c != 0 || it.To_Standard_Cost__c != null){
                activeStandardCost = it.To_Standard_Cost__c;
            }
            else if(it.From_Standard_Cost__c !=0 || it.From_Standard_Cost__c != null){
                activeStandardCost = it.From_Standard_Cost__c;     
            }  

		if( it.Type__c == 'Activate Proposed Costs' ){
                    activeStandardCost = it.Standard_Cost__c;
                }  
            
            double amt_adjust;
            double amt_adjust_abs;
            String theLineType;
            if (activeStandardCost != null && it.Quantity__c != null) {
                amt_adjust =  activeStandardCost * it.Quantity__c;  // could be > 0 or < 0  
                amt_adjust_abs = Math.abs(amt_adjust);
                // KNDY #1302
                // Below logic is added as we have a scenario where Inventory Change will have different scenarios 
                // for Type = "Transfer" than other Types "Adjustment/ Activate Poposed Cost/ Cycle Count"                                            
                if(amt_adjust > 0 ){
                    theLineType = 'Increase';
                }else{
                    theLineType = 'Decrease';
                }
            }
            
            //Create the rule definitions for this line
            AccountingRuleService.RuleDefinition iCRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, ic.Company__c, 'Inventory_Change__c', transType, subTrans, it.Line_Type__c);
            AccountingRuleService.RuleDefinition iDRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, ic.Company__c, 'Inventory_Change__c', transType, subTrans, it.Line_Type__c);
            AccountingRuleService.RuleDefinition iNARuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, ic.Company__c, 'Inventory_Change__c', transType, subTrans, it.Line_Type__c);
            
            if(mRuleDefs.containsKey(iNARuleDef)){
                //system.debug(logginglevel.INFO, 'NA Rule Defs: ' + mRuleDefs.get(iNARuleDef).size() + ' - '  + mRuleDefs.get(iNARuleDef));
                //Do nothing when NA rules are identified
                for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
                      referencedRules.add(ar);
                }
                mSourceDocAELs.put(it.Id, new List<Accounting_Entry_Line__c>());
                continue;
            }
            
            if(mRuleDefs.containsKey(iCRRuleDef)){
                for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){
                      
                      decimal iCRAmt = findLineAmount(it, ar, amt_adjust_abs);
                      if(iCRAmt == null){
                           continue;
                      }  
                      
                      Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, ic, it, ar, iCRAmt);
                      iAEL.SubTransaction_Type__c = subtrans;
                      //iAEL.Line_Type__c = theLineType; //TODO: try to get this line type on the inventory trans line, instead of calculating on the fly 
                      iAEL.Inventory_Transaction__c = it.Id;                                             
            
                      SS.assignSegments(ar, it, iAEL);                                        
                      
                      iAELs.add(iAEL);
                      referencedRules.add(ar);
                }     
            }else{
            	iAELs.add(returnLineForMissingRule(iAE, it, iCRRuleDef, amt_adjust_abs));
            }                                         
            
            system.debug('iDRRuleDef: ' + iDRRuleDef);
            
            if(mRuleDefs.containsKey(iDRRuleDef)){
                for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){
                      
                      decimal iDRAmt = findLineAmount(it, ar, amt_adjust_abs);
                      if(iDRAmt == null){
                            continue;
                      }     
                      
                      Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, ic, it, ar, iDRAmt);
                      iAEL.SubTransaction_Type__c = subTrans;
                      //iAEL.Line_Type__c = theLineType;  //TODO: try to get this line type on the inventory trans line, instead of calculating on the fly                                              
                      iAEL.Inventory_Transaction__c = it.Id;                                                
                      
                      SS.assignSegments(ar, it, iAEL);                                        
                      
                      iAELs.add(iAEL);
                      referencedRules.add(ar);
                }
            }else{
            	iAELs.add(returnLineForMissingRule(iAE, it, iDRRuleDef, amt_adjust_abs));
            } 
            
			mSourceDocAELs.put(it.Id, iAELs);
		*/
        }
        
        finish((Map<Id, sObject>)mICs, (Map<Id, sObject>)mITs, mSourceDocAEs, mSourceDocAELs);
    }
	
	private list<Accounting_Entry_Line__c> ruleAEbuilder(Inventory_Change__c ic, Accounting_Entry__c iAE, String transType, String subTrans, Inventory_Transaction__c it, String lineType, boolean isComposite) {
	
		Id locationFacilityId = it.To_Location__r.Facility__c;
		 if (locationFacilityId == null 
         		|| (it.type__c!=null && (it.type__c == 'Transfer Order Shipment' ||  it.type__c =='Transfer Shipment'))) {
             locationFacilityId = it.From_Location__r.Facility__c;
         }       
         Id locationFacilityCompanyId = it.To_Location__r.Facility__r.Company__c;      
         if (locationFacilityCompanyId == null 
                                 || (it.type__c!=null && (it.type__c == 'Transfer Order Shipment' ||  it.type__c =='Transfer Shipment'))) {
             locationFacilityCompanyId = it.From_Location__r.Facility__r.Company__c; 
         }  
		
		List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();     
      
		//Create the rule definitions for this line
		AccountingRuleService.RuleDefinition iCRRuleDef = 
			new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, ic.Company__r.Accounting_Standard__c, 'Inventory_Change__c', transType, subTrans, lineType);
		AccountingRuleService.RuleDefinition iDRRuleDef = 
			new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, ic.Company__r.Accounting_Standard__c, 'Inventory_Change__c', transType, subTrans, lineType);
		AccountingRuleService.RuleDefinition iNARuleDef = 
			new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, ic.Company__r.Accounting_Standard__c, 'Inventory_Change__c', transType, subTrans, lineType);
        
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
		boolean ExSerFlag = false;
		if (mRuleDefs.containsKey(iCRRuleDef)) {
			system.debug(logginglevel.info,'Inside the iCRRuleDef loop');
			Integer outDatedRuleCount =0;
			//system.debug(logginglevel.INFO, 'CR Rule Defs: ' + mRuleDefs.get(iCRRuleDef).size() + ' - '  + mRuleDefs.get(iCRRuleDef));
			for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){                 
				//KNDY-9545
				if((ar.Effective_End_Date__c!=null ? ic.transaction_date__c >= ar.Effective_End_Date__c:false)   || ic.transaction_date__c < ar.Effective_Start_Date__c  )
				{
					//ReturnLine for missing rule
					if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
					{  
						Decimal amount;
						Decimal activeStandardCostFn = ItemService.getActiveStandardCost(itemSet, 
 						                                                                  facilitySet, 
 						                                                                  locationFacilityCompanyId,
 						                                                                  locationFacilityId,
 						                                                                  ic.Transaction_date__c).get(it.item__c);
						Decimal activeStandardCost;
						if(activeStandardCostFn == null){
							nullFlag = true;
						}else{
							activeStandardCost = ExchangeRateService.convertReverseAmount(ic.Company__r.Comp_Currency__c, ic.Currency__c, ic.Transaction_Date__c, activeStandardCostFn);
						}
						if(nullFlag == false && activeStandardCost == null){
							ExSerFlag = true;
						}else if (activeStandardCost != null && it.Quantity_Stocking_UOM__c != null) {
							amount = (activeStandardCost * it.Quantity_Stocking_UOM__c);      
						}						
						/*if(activeStandardCost == null){
							nullFlag = true;
						}else if (activeStandardCost != null && it.Quantity__c != null) {
							amount = (activeStandardCost * it.Quantity__c);      
						}*/
						//System.Debug(LOGGINGLEVEL.INFO,'%%'+isComposite + '--' + isCompositeCost(subTrans, 'CR'));
						if((isComposite && isCompositeCost(subTrans, 'CR')) || (!isComposite && !isCompositeCost(subTrans,'CR'))) {
							if(isComposite){
								amount = findLineAmountforMissingRules(it, lineType, ic);
							}
							iAELs.add(returnLineForMissingEffectiveRule(iAE, it, iCRRuleDef, amount, nullFlag));
						}
								
					}
					outDatedRuleCount++;
					continue;
				}
				AmountResultWrapper result = findLineAmount(it, ar, ic);
				decimal iCRAmt = result.amount;
				//KNDY-4672
				if (result.nullFlag == true) {
					nullFlag = true;
					system.debug(logginglevel.info,'nullFlag1:'+nullFlag);
				}else if (result.ExSerFlag == true) {
					ExSerFlag = true;
					system.debug(logginglevel.info,'ExSerFlag1:'+ExSerFlag);
				}  
				
				if (iCRAmt == null) {
					iCRAmt = 0;
					//continue;
				}  
				
				Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, ic, it, ar, iCRAmt);
				iAEL.SubTransaction_Type__c = subTrans;
				//iAEL.Line_Type__c = it.Line_Type__c;
				if(nullFlag == true){
					iAEL.item_cost_missing__c = true;
                    nullFlag = false;
				}else if(ExSerFlag == true){
					iAEL.Error_Message__c = 'Exchangerate Service Error';
					ExSerFlag = false;
				}else{
					iAEL.Error_Message__c = null;
					iAEL.item_cost_missing__c = false;
				}
				system.debug(logginglevel.info,'iAEL.Error_Message__c:'+iAEL.Error_Message__c+'======iAEL.item_cost_missing__c:'+iAEL.item_cost_missing__c);
				system.debug(logginglevel.info,'nullFlag1:'+nullFlag+'======ExSerFlag1:'+ExSerFlag);             
				SS.assignSegments(ar, it, iAEL);       

				populateLedgers(ar, iAE, iAEL);

				System.debug(LoggingLevel.ERROR, '#### Setting credit: ');
				System.debug(LoggingLevel.ERROR, '#### Rate: ' + result.exrate.Multiplier_Exchange_Rate__c + '\tAmount: ' + result.amountFN);

				iAEL.COMP_Functional_Conversion_Rate__c = result.exrate.Multiplier_Exchange_Rate__c;
				iAEL.COMP_Functional_Currency_Amount_CR__c = result.amountFN;

				if(iAEL.COMP_Functional_Conversion_Rate__c != null){
					iAEL.COMP_Transaction_Currency_Amount_CR__c = (result.amountFN / result.exrate.Multiplier_Exchange_Rate__c).setScale(2,System.Roundingmode.HALF_EVEN);
					iAEL.Amount_CR__c = result.amountFN / result.exrate.Multiplier_Exchange_Rate__c;
				}

				//System.Debug(LOGGINGLEVEL.INFO,'%'+isComposite + '--' + isCompositeCost(subTrans, 'CR'));       
				if((isComposite && isCompositeCost(subTrans, 'CR')) || (!isComposite && !isCompositeCost(subTrans,'CR'))) {
					iAELs.add(iAEL);
				    referencedRules.add(ar);
				}
			} 
		}else{
			system.debug(logginglevel.info,'Inside the iCRRuleDef else loop');
			  
			Decimal amount;
			Decimal activeStandardCostFn = ItemService.getActiveStandardCost(itemSet, 
																			 facilitySet, 
																			 locationFacilityCompanyId,
																			 locationFacilityId,
																			 ic.Transaction_date__c).get(it.item__c);
			Decimal activeStandardCost;
			if(activeStandardCostFn == null){
				nullFlag = true;
			}else{
				activeStandardCost = ExchangeRateService.convertReverseAmount(ic.Company__r.Comp_Currency__c, ic.Currency__c, ic.Transaction_Date__c, activeStandardCostFn);
			}
			/*StandardCostingService.ItemCostDefinition facilityICD = new StandardCostingService.ItemCostDefinition(it.item__c, locationFacilityId, locationFacilityCompanyId);
			StandardCostingService.ItemCostDefinition companyICD = new StandardCostingService.ItemCostDefinition(it.item__c, null, locationFacilityCompanyId);
			Item_Cost__c itmeCost = returnItemCost(system.today(), mICDs.get(facilityICD) != null ? mICDs.get(facilityICD) : mICDs.get(companyICD)); //returnItemCost(it.work_order__r.transaction_date__c, mICDs.get(icd));
			Decimal activeStandardCost = itmeCost == null ? 0 : itmeCost.Standard_Cost__c;*/
			if(nullFlag== false && activeStandardCost == null){
				ExSerFlag = true;
			}else if (activeStandardCost != null && it.Quantity_Stocking_UOM__c != null) {
				amount = (activeStandardCost * it.Quantity_Stocking_UOM__c);      
			}
			system.debug(logginglevel.info,'nullFlag2:'+nullFlag);
			system.debug(logginglevel.info,'ExSerFlag2:'+ExSerFlag);
			//System.Debug(LOGGINGLEVEL.INFO,'%%'+isComposite + '--' + isCompositeCost(subTrans, 'CR'));
			if((isComposite && isCompositeCost(subTrans, 'CR')) || (!isComposite && !isCompositeCost(subTrans,'CR'))) {
				if(isComposite){
					amount = findLineAmountforMissingRules(it, lineType, ic);
				}
				iAELs.add(returnLineForMissingEffectiveRule(iAE, it, iCRRuleDef, amount, nullFlag));
			}
		}          

		//system.debug(logginglevel.INFO, 'iDRRuleDef: ' + iDRRuleDef);
		//system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iDRRuleDef));
		if (mRuleDefs.containsKey(iDRRuleDef)) {
			system.debug(logginglevel.info,'Inside the iDRRuleDef if loop');
			Integer outDatedRuleCount =0;			
			//system.debug(logginglevel.INFO, 'DR Rule Defs: ' + mRuleDefs.get(iDRRuleDef).size() + ' - '  + mRuleDefs.get(iDRRuleDef));
			for (Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)) {
 						
				//KNDY-9545
				if((ar.Effective_End_Date__c!=null ? ic.transaction_date__c >= ar.Effective_End_Date__c:false)    || ic.transaction_date__c < ar.Effective_Start_Date__c  )
				{
					//ReturnLine for missing rule
					if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
					{
						Decimal amount;
						Decimal activeStandardCostFn = ItemService.getActiveStandardCost(itemSet, 
																						facilitySet, 
																						locationFacilityCompanyId,
																						locationFacilityId,
																						ic.Transaction_date__c).get(it.item__c);
						Decimal activeStandardCost;
						system.debug(logginglevel.info,'activeStandardCost in DRRuleDef loop:'+activeStandardCost);
						if(activeStandardCostFn == null){ 
							nullFlag = true;
						}else{
							activeStandardCost = ExchangeRateService.convertReverseAmount(ic.Company__r.Comp_Currency__c, ic.Currency__c, ic.Transaction_Date__c, activeStandardCostFn);
						}
						system.debug(logginglevel.info,'activeStandardCost after exchange rate service call:'+activeStandardCost);
						
						if(nullFlag == false && activeStandardCost == null){ 
							ExSerFlag = true;
						}else if (activeStandardCost != null && it.Quantity_Stocking_UOM__c != null) {
							amount = (activeStandardCost * it.Quantity_Stocking_UOM__c);      
						}						
						system.debug(logginglevel.info,'nullFlag3:'+nullFlag);
						system.debug(logginglevel.info,'ExSerFlag3:'+ExSerFlag);	
										
						/*if(activeStandardCost == null){
							nullFlag = true;
						}else if (activeStandardCost != null && it.Quantity__c != null) {
							amount = (activeStandardCost * it.Quantity__c);      
						}*/
						//System.Debug(LOGGINGLEVEL.INFO,'%%'+isComposite + '--' + isCompositeCost(subTrans, 'CR'));
						if((isComposite && isCompositeCost(subTrans, 'DR')) || (!isComposite && !isCompositeCost(subTrans,'DR'))) {
							if(isComposite){
								amount = findLineAmountforMissingRules(it, lineType, ic);
							}
							iAELs.add(returnLineForMissingEffectiveRule(iAE, it, iDRRuleDef, amount, nullFlag));
						}
								
					}
					outDatedRuleCount++;
					continue;
				}        
				AmountResultWrapper result = findLineAmount(it, ar, ic);
				decimal iDRAmt = result.amount;
				//KNDY-4672
				if (result.nullFlag == true) {
					nullFlag = true;
				} else if (result.ExSerFlag == true) {
					ExSerFlag = true;
				} 
				system.debug(logginglevel.info,'nullFlag3:'+nullFlag+'======ExSerFlag3:'+ExSerFlag); 
				if (iDRAmt == null) {
					iDRAmt = 0;
					//continue;
				} 
				
				Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, ic, it, ar, iDRAmt);
				iAEL.SubTransaction_Type__c = subTrans;
				//iAEL.Line_Type__c = it.Line_Type__c;                
				if(nullFlag == true){
					iAEL.item_cost_missing__c = true;
                    nullFlag = false;
				}else if(ExSerFlag == true){
					iAEL.Error_Message__c = 'Exchangerate Service Error';
					ExSerFlag = false;
				}else{
					iAEL.Error_Message__c = null;
					iAEL.item_cost_missing__c = false;
				}
				system.debug(logginglevel.info,'nullFlag3:'+nullFlag+'======ExSerFlag3:'+ExSerFlag); 
				system.debug(logginglevel.info,'iAEL.Error_Message__c:'+iAEL.Error_Message__c+'======iAEL.item_cost_missing__c:'+iAEL.item_cost_missing__c); 
				
				
				SS.assignSegments(ar, it, iAEL);    

				populateLedgers(ar, iAE, iAEL);

				System.debug(LoggingLevel.ERROR, '#### Setting debit: ');
				System.debug(LoggingLevel.ERROR, '#### Rate: ' + result.exrate.Multiplier_Exchange_Rate__c + '\tAmount: ' + result.amountFN);

				iAEL.COMP_Functional_Conversion_Rate__c = result.exrate.Multiplier_Exchange_Rate__c;
				iAEL.COMP_Functional_Currency_Amount_DR__c = result.amountFN;

				if(iAEL.COMP_Functional_Conversion_Rate__c != null){
					iAEL.COMP_Transaction_Currency_Amount_DR__c = (result.amountFN / result.exrate.Multiplier_Exchange_Rate__c).setScale(2,System.Roundingmode.HALF_EVEN);
					iAEL.Amount_DR__c = result.amountFN / result.exrate.Multiplier_Exchange_Rate__c;
				} 

				//System.Debug(LOGGINGLEVEL.INFO,'%%%'+isComposite + '--' + isCompositeCost(subTrans, 'DR'));          
          		if((isComposite && isCompositeCost(subTrans, 'DR')) || (!isComposite && !isCompositeCost(subTrans,'DR'))) {
					iAELs.add(iAEL);
				    referencedRules.add(ar);
          		}
			}
		}else{
			system.debug(logginglevel.info,'Inside the iDRRuleDef else loop');
			 
			Decimal amount;
			Decimal activeStandardCostFn = ItemService.getActiveStandardCost(itemSet,
																			 facilitySet, 
																			 locationFacilityCompanyId,
																			 locationFacilityId,
																			 ic.Transaction_date__c).get(it.item__c);
			Decimal activeStandardCost;
			if(activeStandardCostFn == null){
				nullFlag = true;
			}else{
				activeStandardCost = ExchangeRateService.convertReverseAmount(ic.Company__r.Comp_Currency__c, ic.Currency__c, ic.Transaction_Date__c, activeStandardCostFn);
			}
			system.debug(logginglevel.info,'nullFlag before 4:'+nullFlag);
			/*StandardCostingService.ItemCostDefinition facilityICD = new StandardCostingService.ItemCostDefinition(it.item__c, locationFacilityId, locationFacilityCompanyId);
			StandardCostingService.ItemCostDefinition companyICD = new StandardCostingService.ItemCostDefinition(it.item__c, null, locationFacilityCompanyId);
			Item_Cost__c itmeCost = returnItemCost(system.today(), mICDs.get(facilityICD) != null ? mICDs.get(facilityICD) : mICDs.get(companyICD)); //returnItemCost(it.work_order__r.transaction_date__c, mICDs.get(icd));
			Decimal activeStandardCost = itmeCost == null ? 0 : itmeCost.Standard_Cost__c;*/
			if(nullFlag == false && activeStandardCost == null){
				ExSerFlag = true;
			}else if (activeStandardCost != null && it.Quantity_Stocking_UOM__c != null) {
				amount = (activeStandardCost * it.Quantity_Stocking_UOM__c);      
			}
			system.debug(logginglevel.info,'nullFlag4:'+nullFlag+'======ExSerFlag5:'+ExSerFlag); 
			//System.Debug(LOGGINGLEVEL.INFO,'%%%%'+isComposite + '--' + isCompositeCost(subTrans, 'DR'));
			if((isComposite && isCompositeCost(subTrans, 'DR')) || (!isComposite && !isCompositeCost(subTrans,'DR'))) {
				if(isComposite){
					amount = findLineAmountforMissingRules(it, lineType, ic);
				}
				iAELs.add(returnLineForMissingEffectiveRule(iAE, it, iDRRuleDef, amount, nullFlag));
			}
		}
              
		return iAELs;
	}

	private decimal findLineAmountforMissingRules (Inventory_transaction__c it,String compLineType, Inventory_Change__c ic) {
		decimal amount;
		
        
         Id locationFacilityId         = it.To_Location__r.Facility__c;
         if (locationFacilityId == null 
         			|| (it.type__c!=null &&  (it.type__c == 'Transfer Order Shipment' ||  it.type__c =='Transfer Shipment'))) {
             locationFacilityId = it.From_Location__r.Facility__c;
         }
         Id locationFacilityCompanyId  = it.To_Location__r.Facility__r.Company__c;
         if (locationFacilityCompanyId == null 
         		    || (it.type__c!=null &&  (it.type__c == 'Transfer Order Shipment' ||  it.type__c =='Transfer Shipment'))) {
             locationFacilityCompanyId = it.From_Location__r.Facility__r.Company__c; 
         }   
			try {	
				if(lineTypeToCostComponentNameMap.containsKey(compLineType)) {
						String costComponentFieldName = lineTypeToCostComponentNameMap.get(compLineType); //get the cost component field name from the line type
						Item_Cost__c tmpCostRecord = ItemService.getActiveStandardCostRecord(itemSet, 
																							 facilitySet, 
																							 locationFacilityCompanyId, 
																							 locationFacilityId,
																							 it.inventory_change__r.transaction_date__c).get(it.Item__c);
						Decimal tmpCostFn;
						Decimal tmpCost;
						if(tmpCostRecord != null) tmpCostFn =  (Decimal) tmpCostRecord.get(costComponentFieldName);	
						if(tmpCostFn != null){
							tmpCost = ExchangeRateService.convertReverseAmount(ic.Company__r.Comp_Currency__c, ic.Currency__c, ic.Transaction_Date__c, tmpCostFn);
						amount = (KSE.addQuantityToField(tmpCost,0) * it.Quantity_Stocking_UOM__c);	
				}
				}
				
			} catch (Exception ex) {
                invTxnsWithExceptions.add(it.id);
		        logs.add('ItemSetIds==>'+String.valueOf(itemSet));
		        logs.add('TransactionsIds'+String.valueOf(invTxnsWithExceptions));
				throw ex;
			}

		return amount;
	}
  
	private AmountResultWrapper findLineAmount (Inventory_transaction__c it, Accounting_Rule__c ar, Inventory_Change__c ic) {
		//decimal amount;   
		Id locationFacilityId = it.To_Location__r.Facility__c;
         if (locationFacilityId == null 
         			|| (it.type__c!=null &&  (it.type__c == 'Transfer Order Shipment' ||  it.type__c =='Transfer Shipment'))) {
             locationFacilityId = it.From_Location__r.Facility__c;
         }      
         Id locationFacilityCompanyId = it.To_Location__r.Facility__r.Company__c;      
         if (locationFacilityCompanyId == null 
         			|| (it.type__c!=null &&  (it.type__c == 'Transfer Order Shipment' ||  it.type__c =='Transfer Shipment'))) {
             locationFacilityCompanyId = it.From_Location__r.Facility__r.Company__c; 
         }  
		AmountResultWrapper result = new AmountResultWrapper();
		if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != '') {
            Decimal activeStandardCostFN = ItemService.getActiveStandardCost(itemSet, 
																					 facilitySet, 
																					 locationFacilityCompanyId, 
																					 locationFacilityId,
																					 it.inventory_change__r.transaction_date__c).get(it.item__c);
            if(activeStandardCostFN != null){
    			result.amount = (decimal)it.get(ar.Amount_Reference__c) == null? 0 : (decimal)it.get(ar.Amount_Reference__c);    
			} else {
                result.amount = null;
                result.nullFlag = true;
            }
		} else {
				if( it.Type__c == 'Activate Proposed Costs' ){
				Decimal activeStandardCost = it.Standard_Cost__c;
				 
	            double amt_adjust;
	            double amt_adjust_abs;
	            String theLineType;
	            if (activeStandardCost != null && it.Quantity_Stocking_UOM__c != null) {
	                amt_adjust =  activeStandardCost * it.Quantity_Stocking_UOM__c;  // could be > 0 or < 0  
	                amt_adjust_abs = Math.abs(amt_adjust);
	            }
	            result.amount = amt_adjust_abs;
				system.debug(logginglevel.info,'ACP amount:'+result.amount);
			}else{
				boolean isComposite = isCompositeCost(ar);
      
				if (isComposite) {
					try {		
						if(lineTypeToCostComponentNameMap.containsKey(ar.Line_Type__c)) {
							String costComponentFieldName = lineTypeToCostComponentNameMap.get(ar.Line_Type__c); //get the cost component field name from the line type
							Item_Cost__c tmpCostRecord = ItemService.getActiveStandardCostRecord(itemSet, 
																								 facilitySet, 
																								 locationFacilityCompanyId, 
																								 locationFacilityId,
																								 it.inventory_change__r.transaction_date__c).get(it.Item__c);

							Decimal tmpCost, tmpCostFN;
							if(tmpCostRecord != null) {
								tmpCostFN =  (Decimal) tmpCostRecord.get(costComponentFieldName);
							}else{
								result.nullFlag = true;
							}
							system.debug(logginglevel.info,'result.nullFlag in if loop:'+result.nullFlag); 
							
							/*StandardCostingService.ItemCostDefinition facilityICD = new StandardCostingService.ItemCostDefinition(it.item__c, it.To_Location__r.Facility__c, it.To_Location__r.Facility__r.Company__c);
							StandardCostingService.ItemCostDefinition companyICD = new StandardCostingService.ItemCostDefinition(it.item__c, null, it.To_Location__r.Facility__r.Company__c);
							Item_Cost__c itemCost = returnItemCost(system.today(), mICDs.get(facilityICD) != null ? mICDs.get(facilityICD) : mICDs.get(companyICD)); //returnItemCost(it.work_order__r.transaction_date__c, mICDs.get(icd));
							Decimal tmpCost = itemCost == null ? 0 : (Decimal)itemCost.get(costComponentFieldName);*/

							if(tmpCostFN != null){
								tmpCost = ExchangeRateService.convertReverseAmount(ic.Company__r.Comp_Currency__c, ic.Currency__c, ic.transaction_date__c, tmpCostFN);
                                if(tmpCost == null){
  									result.ExSerFlag = true;                                
                                }
								result.amount = (KSE.addQuantityToField(tmpCost,0) * it.Quantity_Stocking_UOM__c);	
								result.amountFN = (KSE.addQuantityToField(tmpCostFN,0) * it.Quantity_Stocking_UOM__c);
								result.exrate = ExchangeRateService.getExchangeRate(ic.Currency__c, ic.Company__r.Comp_Currency__c, ic.transaction_date__c);

						}
							system.debug(logginglevel.info,'result.ExSerFlag in if loop::'+result.ExSerFlag); 
						}
					} catch (Exception ex) {
	                    invTxnsWithExceptions.add(it.id);
				        logs.add('ItemSetIds==>'+String.valueOf(itemSet));
				        //logs.add('mICDs==>'+String.valueOf(mICDs));
				        logs.add('TransactionsIds'+String.valueOf(invTxnsWithExceptions));
						throw ex;
						//system.debug(logginglevel.ERROR, 'costComponentAmt exception: ' + ex.getMessage());
					}
				}else {
					//DP: set the facility and the company to the "to" values, if they are null set them to the "from" values.
					//need to double check if this is correct.  Not sure if there are cases when they will both be populated and we need to choose 
					//based on inventory transaction type    
					 
					//Item_Cost__c tmpCostRecord = ItemService.getActiveStandardCostRecord(itemSet, facilitySet, locationFacilityCompanyId, locationFacilityId,it.inventory_change__r.transaction_date__c).get(it.Item__c); 

					Decimal activeStandardCostFN = ItemService.getActiveStandardCost(itemSet, 
																					 facilitySet, 
																					 locationFacilityCompanyId, 
																					 locationFacilityId,
																					 it.inventory_change__r.transaction_date__c).get(it.item__c);
					Decimal activeStandardCost = null;
					Exchange_Rate__c exRate = null;
					System.debug(LoggingLevel.ERROR, '#### standard cost fn: ' + activeStandardCostFN);
					if(activeStandardCostFN == null){
						result.nullFlag = true;
					}else{
						activeStandardCost = ExchangeRateService.convertReverseAmount(ic.Company__r.Comp_Currency__c, ic.Currency__c, ic.Transaction_Date__c, activeStandardCostFN);
						exRate = ExchangeRateService.getExchangeRate(ic.Currency__c, ic.Company__r.Comp_Currency__c,ic.Transaction_Date__c);
					}
					system.debug(logginglevel.info,'result.nullFlag in else loop:'+result.nullFlag); 
					/*StandardCostingService.ItemCostDefinition facilityICD = new StandardCostingService.ItemCostDefinition(it.item__c, locationFacilityId, locationFacilityCompanyId);
					StandardCostingService.ItemCostDefinition companyICD = new StandardCostingService.ItemCostDefinition(it.item__c, null, locationFacilityCompanyId);
					Item_Cost__c itemCost = returnItemCost(system.today(), mICDs.get(facilityICD) != null ? mICDs.get(facilityICD) : mICDs.get(companyICD)); //returnItemCost(it.work_order__r.transaction_date__c, mICDs.get(icd));
					Decimal activeStandardCost = itemCost == null ? 0 : itemCost.Standard_Cost__c;*/
					
					if(result.nullFlag == false && activeStandardCost == null){
						result.ExSerFlag = true;
					}
					system.debug(logginglevel.info,'result.ExSerFlag in else loop::'+result.ExSerFlag); 
					
					if (activeStandardCost != null && it.Quantity_Stocking_UOM__c != null) {
						result.amount = (activeStandardCost * it.Quantity_Stocking_UOM__c);      
						result.amountFN = (activeStandardCostFN * it.Quantity_Stocking_UOM__c);
						result.exrate = exRate;
						System.debug(LoggingLevel.ERROR, '#### result: ' + result); 
        }
				} 
			}

		}
		system.debug('Reched here ******  '+ result);
		return result;    
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
        decimal absAmount;
        Boolean isNegativeITActivateProposedCosts = checkForActivateProposedCosts(acctEntry, it);
        if((amount == null) )
         	{absAmount = null;}
        else if(amount != null){
        	absAmount = math.abs(amount);}
        else{
        	absAmount = 0;}
         
        if(ar.Expected_Sign__c == 'Positive' || ar.Expected_Sign__c == null){
        	if(amount >= 0  && !isNegativeITActivateProposedCosts){
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
        	if(amount <= 0  && !isNegativeITActivateProposedCosts){
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
	
	/*public Item_Cost__c returnItemCost(Date trxnDate, List<Item_Cost__c> itemCosts){
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
    }*/

	/*
    private decimal findLineAmount(Inventory_Transaction__c it, Accounting_Rule__c ar, double amt_adjust_abs){
        decimal amount;
        if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
            amount = (decimal)it.get(ar.Amount_Reference__c);               
        }else{ 
            //DP: commented out for merge 2/24/14
            //if (it.Extended_Cost__c != null) {
            //      amount = Math.abs(it.Extended_Cost__c);   
            //} 
            
            //----KNDY-2170
            if (amt_adjust_abs != null) {
                amount = Decimal.valueOf(amt_adjust_abs); 
            }    
            //---------------                                                   
        }
        return amount;          
    } */
      
}