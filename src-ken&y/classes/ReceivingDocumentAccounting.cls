public with sharing class ReceivingDocumentAccounting extends AccountingService {
 	set<Id> itemSet = new set<Id>();
	//Map<StandardCostingService.ItemCostDefinition, List<Item_Cost__c>> mICDs = new Map<StandardCostingService.ItemCostDefinition, List<Item_Cost__c>>();
    set<Id> facilitySet = new set <Id>();
    List<Datetime> itemCostDates = new List<Datetime>();
    
	public ReceivingDocumentAccounting(){
		super('Receiving_Document__c');
	}	
	
	public override void execute(List<sObject> receiptLines){
		string bjId = this.batchJobId;
		//Note: This requires the source doc header field is specified in the input lines, is there a way to avoid this requirement?
		
		set<Id> rdIds = new set<Id>();
		
		for(Receipt_Line__c rl : (List<Receipt_Line__c>)receiptLines){
			rdIds.add(rl.Receiving_Document__c);
		}
		
		set<string> recDocFields = new set<string>{'id', 'name', 'date_received__c', 'company__c', 'company__r.accounting_standard__c', 'finalized__c','Transaction_Currency__c', 'currency__c', 'Currency__r.ISO_Code__c','finalized_date__c', 'transaction_date__c', 'type__c','transaction_type__c', 'void__c', 'void_date__c', 'total_number_of_lines__c', 'posting_date__c','Company__r.comp_currency__c','Company__r.consol_currency__c','Company__r.Stat_Currency__c', 'Company__r.Subs_Currency__c'};		
		
		/*string rdQuery = 'SELECT ' + string.join(new List<string>(recDocFields),', ');
		rdQuery += ' FROM Receiving_Document__c WHERE Id IN :rdIds';
		*/
		set<string> recDocLineFields = new set<string>{'id', 'name', 'unit_price__c', 'item__c', 'item__r.source__c', 'purchase_order_line__r.order_quantity__c', 'facility__c',
                               'extended_cost__c','purchase_price__c', 'purchase_order__c', 'purchase_order_line__c', 'purchase_order_line__r.company__c', 'quantity_received__c', 'quantity_declared__c',
                               'receiving_document__c', 'status__c', 'receiving_document__r.company__c', 'company__c', 'item__r.class__r.type__c', 'line_type__c', 'subtransaction_type__c', 
                               'receiving_document__r.transaction_date__c' , 'receiving_document__c', 'receiving_document__r.currency__c', 'receiving_document__r.company__r.company_currency__c'};
		recDocLineFields.addAll(segmentReferences);	
		
		/*string receiptLineQuery = 'SELECT ' + string.join(new List<string>(recDocLineFields), ', ');
		receiptLineQuery += ' FROM Receipt_Line__c '
							+ 'WHERE Id in :receiptLines '
                            + 'AND Finalized__c = true '
                            + 'AND Receiving_Document__r.Company__c != null '
                            + 'AND Receiving_Document__r.Transaction_Date__c != null '
                            + 'AND Receiving_Document__r.Finalized_Date__c != null '
                            + 'AND Historical__c = false ' 
                            + 'AND Receiving_Document__r.Currency__c != null '
							+ 'AND Receiving_Document__c NOT IN (SELECT Receiving_Document__c FROM Accounting_Entry__c WHERE Receiving_Document__c IN :rdIds AND Related_Accounting_Entry__c = null  AND status__c=\'Active\' AND (period__r.closed__c = true OR period__r.permanently_closed__c = true or period__r.receiving_subledger_closed__c != null) ) ' //FIN-889 AND batchjobid__c!=null and batchjobid__c!=:batchJobID 
                            + 'AND Id NOT IN (SELECT Receipt_Line__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Receipt_Line__c IN :receiptLines AND Accounting_Entry__r.BatchJobId__c = :bjId) '
                            + 'FOR UPDATE';
        */
                             
		Map<Id, Accounting_Entry__c> mSourceDocAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mSourceDocAELs = new Map<Id, List<Accounting_Entry_Line__c>>();
        Map<Id, Receiving_Document__c> mRDs = new Map<Id, Receiving_Document__c>();
		Map<Id, Receipt_Line__c> mRLs = new Map<Id, Receipt_Line__c>();                       
        try{
        	
        	String whereClause = 'Id in :receiptLines '
	                            + 'AND Finalized__c = true '
	                            + 'AND Receiving_Document__r.Company__c != null '
	                            + 'AND Receiving_Document__r.Transaction_Date__c != null '
	                            + 'AND Receiving_Document__r.Finalized_Date__c != null '
	                            + 'AND Historical__c = false ' 
	                            + 'AND (Receiving_Document__r.Currency__c != null or Receiving_Document__r.Transaction_Currency__c != null) '
								+ 'AND Receiving_Document__c NOT IN (SELECT Receiving_Document__c FROM Accounting_Entry__c WHERE Receiving_Document__c IN :rdIds AND Related_Accounting_Entry__c = null  AND status__c=\'Active\' AND (period__r.closed__c = true OR period__r.permanently_closed__c = true or period__r.receiving_subledger_closed__c != null) ) ' //FIN-889 AND batchjobid__c!=null and batchjobid__c!=:batchJobID 
	                            + 'AND Id NOT IN (SELECT Receipt_Line__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Receipt_Line__c IN :receiptLines AND Accounting_Entry__r.BatchJobId__c = :bjId) '
	                            + 'FOR UPDATE';
        
		    SOQLUtil soql = new SOQLUtil('Receipt_Line__c');
		    soql.addFields(recDocLineFields);
		    soql.setWhereClause(whereClause);
		    
        	//Grab Lines for this scope
        	mRLs = new Map<Id, Receipt_Line__c>((List<Receipt_Line__c>)Database.query(soql.getQuery()));
        	
		    soql = new SOQLUtil('Receiving_Document__c');
		    soql.addFields(recDocFields);
		    soql.setWhereClause('Id IN :rdIds');
		    
        	//Place the headers in a map for later reference
        	mRDs = new Map<Id, Receiving_Document__c>((List<Receiving_Document__c>)Database.query(soql.getQuery()));
        	
        	findExistingDraftAEs(mRDs.keySet());
        }catch(Exception ex){
        	throw ex;
        }
        //system.debug('finalReceipts: ' + finalReceipts);
        
  		//KNDY-9545 
  		//Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
  		//This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
  		//This approach avoids handling all rules for the object and increases efficiency.
  		loadEffRuleDetails(mRDs);
  		
		system.debug(LOGGINGLEVEL.INFO,'mRuleDefs'+mRuleDefs);    
    
    	for(Receipt_Line__c rl : mRLs.values()){
    		itemSet.add(rl.item__c);
    		itemCostDates.add(rl.Receiving_Document__r.transaction_date__c);
			facilitySet.add(rl.Facility__c);
    	}
		
		findExchangeRates(itemCostDates);


		// first call to itemservice to cache data => tmp cost
//		ItemService.preCacheCostRecords(itemCostDates, itemSet, facilitySet);
		/*if(itemCostDates != null && itemCostDates.size() > 0){
			Datetime latestDatetime = itemCostDates[itemCostDates.size()-1];
			if(latestDatetime != null){
				Map <Id,Double> mTmpCost = ItemService.getActiveStandardCost(itemSet, facilitySet, facilityCompanyId, facilityId, latestDatetime);
		}
		}*/
    	
        //mICDs = StandardCostingService.getActiveStandardCostDefinitions(itemSet, new List<Date>{system.today()}); //itemCostDates
		system.debug(logginglevel.info, 'mRLs: ' + mRLs.values().size() + ' - ' + mRLs.values());
 		for(Receipt_Line__c rl : mRLs.values()){
 				
 			Accounting_Entry__c iAE;
        	Receiving_Document__c rd = mRDs.get(rl.Receiving_Document__c);
        	if(mSourceDocAEs.containsKey(rl.Receiving_Document__c)){
        		iAE = mSourceDocAes.get(rl.Receiving_Document__c);
        	}else{
        		iAE = generateAccountingEntry(rd, rd.Type__c);
        		mSourceDocAEs.put(rd.Id, iAE);
        	}
 			    
		    List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
 			    
			string transType = iAE.Transaction_Type__c;
			string subTrans = (rl.Subtransaction_Type__c != null && rl.Subtransaction_Type__c != '') ? rl.Subtransaction_Type__c : null;
				
			AccountingRuleService.RuleDefinition iCRRuleDef = 
				new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, rd.Company__r.Accounting_Standard__c, 'Receiving_Document__c', transType, subTrans, rl.Line_Type__c);
			AccountingRuleService.RuleDefinition iDRRuleDef = 
				new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, rd.Company__r.Accounting_Standard__c, 'Receiving_Document__c', transType, subTrans, rl.Line_Type__c);
			AccountingRuleService.RuleDefinition iNARuleDef = 
				new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, rd.Company__r.Accounting_Standard__c, 'Receiving_Document__c', transType, subTrans, rl.Line_Type__c);
						
			
			if(mRuleDefs.containsKey(iNARuleDef)){
				//system.debug(logginglevel.INFO, 'NA Rule Defs: ' + mRuleDefs.get(iNARuleDef).size() + ' - '  + mRuleDefs.get(iNARuleDef));
				//Do nothing when NA rules are identified
				for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
					referencedRules.add(ar);
				}
				mSourceDocAELs.put(rl.Id, new List<Accounting_Entry_Line__c>());
				continue;
			}
			
			//system.debug(logginglevel.INFO, 'iCRRuleDef: ' + iDRRuleDef);
			//system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iCRRuleDef));
			boolean nullFlag = false;
			if(mRuleDefs.containsKey(iCRRuleDef)){
				Integer outDatedRuleCount =0;									
				//system.debug(logginglevel.INFO, 'CR Rule Defs: ' + mRuleDefs.get(iCRRuleDef).size() + ' - '  + mRuleDefs.get(iCRRuleDef));
				for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){
					//KNDY-9545
					if((ar.Effective_End_Date__c!=null ? rd.transaction_date__c >= ar.Effective_End_Date__c:false)    || rd.transaction_date__c < ar.Effective_Start_Date__c  )
					{
						//ReturnLine for missing rule
						if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
						{
							iAELs.add(returnLineForMissingEffectiveRule(iAE, rl, iCRRuleDef, rl.Purchase_Price__c));							
						}
						outDatedRuleCount++;
						continue;
					}
					decimal iCRAmt = findLineAmount(rl, ar);
					//if(iCRAmt == null){
					//	continue;
					//}	
					if(iCRAmt == null){
						system.debug(logginglevel.info,'iCRAmt is null');
						//iCRAmt = 0;
					}	
					
					Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, rd, rl, ar, iCRAmt);
					iAEL.SubTransaction_Type__c = subTrans;
					iAEL.Line_Type__c = rl.Line_Type__c;
					iAEL.Receipt_Line__c = rl.Id;														
					SS.assignSegments(ar, rl, iAEL);							
					
					iAELs.add(iAEL);
					referencedRules.add(ar);
				}	
			}else{
				iAELs.add(returnLineForMissingEffectiveRule(iAE, rl, iCRRuleDef, rl.Purchase_Price__c));
				//iAELs.add(returnLineForMissingRule(iAE, rl, iCRRuleDef, rl.Extended_Cost__c));
			}							
			
			//system.debug(logginglevel.INFO, 'iDRRuleDef: ' + iDRRuleDef);
			//system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iDRRuleDef));
			if(mRuleDefs.containsKey(iDRRuleDef)){
				Integer outDatedRuleCount =0;				
				//system.debug(logginglevel.INFO, 'DR Rule Defs: ' + mRuleDefs.get(iDRRuleDef).size() + ' - '  + mRuleDefs.get(iDRRuleDef));
				for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){
					//KNDY-9545
					if((ar.Effective_End_Date__c!=null ? rd.transaction_date__c >= ar.Effective_End_Date__c:false)    || rd.transaction_date__c < ar.Effective_Start_Date__c  )
					{
						//ReturnLine for missing rule
						if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
						{
							iAELs.add(returnLineForMissingEffectiveRule(iAE, rl, iDRRuleDef, rl.Purchase_Price__c));							
						}
						outDatedRuleCount++;
						continue;
					}					
					
					decimal iDRAmt = findLineAmount(rl, ar);
					//if(iDRAmt == null){
					//	continue;
					//}	
					
					if(iDRAmt == null){
						system.debug(logginglevel.info,'iDRAmt is null');
						//iDRAmt = 0;
					}	
					
					Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, rd, rl, ar, iDRAmt);
					iAEL.SubTransaction_Type__c = subTrans;
					iAEL.Line_Type__c = rl.Line_Type__c;								
					iAEL.Receipt_Line__c = rl.Id;								
					SS.assignSegments(ar, rl, iAEL);							
					
					iAELs.add(iAEL);
					referencedRules.add(ar);
				}
			}else{
				iAELs.add(returnLineForMissingEffectiveRule(iAE, rl, iDRRuleDef, rl.Purchase_Price__c));
				//iAELs.add(returnLineForMissingRule(iAE, rl, iDRRuleDef, rl.Extended_Cost__c));
			}
			
			mSourceDocAELs.put(rl.Id, iAELs);
		}
		system.debug(logginglevel.info,'mSourceDocAELs:'+mSourceDocAELs);
	    finish((Map<Id, sObject>)mRDs, (Map<Id, sObject>)mRLs, mSourceDocAEs, mSourceDocAELs);
            
	}

	
	private decimal findLineAmount(Receipt_Line__c rl, Accounting_Rule__c ar){
		decimal amount;		
		if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
			amount = (decimal)rl.get(ar.Amount_Reference__c) == null ? 0 : (decimal)rl.get(ar.Amount_Reference__c);	
		}else{									
/*			//KNDY-7712 Commenting the below logic to pick purchase price for all Receiving documents
			if(isMiscOrExpense(rl)){

				if((rl.Purchase_Price__c != null && rl.Purchase_Price__c != 0) && (rl.Quantity_Received__c != null && rl.Quantity_Received__c != 0)){												
					amount = rl.Purchase_Price__c ;
				if(rl.Unit_Price__c != null && rl.Quantity_Received__c != null){												
					amount = rl.Unit_Price__c * rl.Quantity_Received__c;
				}
			}else{
				///FIN-894 Changes Implementing New ItemService
				decimal stdCost = ItemService.getActiveStandardCost(itemSet, facilitySet, rl.Company__c, rl.Facility__c, rl.Receiving_Document__r.Transaction_Date__c).get(rl.item__c);
				
				if(rl.receiving_document__r.transaction_currency__c != rl.receiving_document__r.company__r.company_currency__c){
					//TODO: Check the impact of this on item cost exceptions with FX with RS
				stdCost = stdCost == null ? 0 : stdCost;
					Exchange_Rate__c rate = returnExchangeRate( rl.receiving_document__r.company__r.company_currency__c, rl.receiving_document__r.transaction_currency__c, rl.receiving_document__r.transaction_date__c, 'Daily');
					decimal exchange;
					if(rate != null){
						exchange = rate.Multiplier_Exchange_Rate__c;
					}else{
						exchange = 0;
					}
					
					stdCost = stdCost * exchange;
				}
			    /*StandardCostingService.ItemCostDefinition facilityICD = new StandardCostingService.ItemCostDefinition(rl.item__c, rl.Facility__c, rl.Company__c);
				StandardCostingService.ItemCostDefinition companyICD = new StandardCostingService.ItemCostDefinition(rl.item__c, null, rl.Company__c);
			     Item_Cost__c ic = returnItemCost(system.today(), mICDs.get(facilityICD) != null ? mICDs.get(facilityICD) : mICDs.get(companyICD)); 
				decimal stdCost = ic == null ? 0 : ic.Standard_Cost__c;*//*
				decimal qtyRcvd = rl.Quantity_Received__c;
				if(stdCost == null){
					amount = null;
				}else
				if(stdCost != null && qtyRcvd != null){
					amount = stdCost * qtyRcvd;
				}else{
					amount = 0;
				}
			}
*/					amount = rl.Purchase_Price__c ;
		}
        return returnFinalLineAmount(amount,ar);
	}	
	
	public Item_Cost__c returnItemCost(Date trxnDate, List<Item_Cost__c> itemCosts){
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
		
		return activeCost;
	}
	
}