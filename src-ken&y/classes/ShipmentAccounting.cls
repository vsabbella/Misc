public with sharing class ShipmentAccounting{ //extends AccountingService {
/*	set<Id> itemSet = new set<Id>();
    set<Id> facilitySet = new set <Id>();
    List<Datetime> itemCostDates = new List<Datetime>();
	
	public ShipmentAccounting(){
		super('Shipment__c');
	}
	
	public override void execute(List<sObject> shipmentLineList){
		
		string bjId = this.batchJobId;

		set<Id> sIds = new set<Id>();
		for(Shipment_Line__c sl : (List<Shipment_Line__c>)shipmentLineList){
			sIds.add(sl.Shipment__c);
		}

		set<string> shipmentFields = new set<string>{'id', 'name', 'date_shipped__c', 'finalized__c','Transaction_Currency__c', 'currency__c','Currency__r.ISO_Code__c', 'company__c', 'company__r.accounting_standard__c',
								 'finalized_date__c', 'transaction_date__c','type__c', 'transaction_type__c','posting_date__c', 'total_number_of_lines__c','Company__r.comp_currency__c','Company__r.consol_currency__c','Company__r.Stat_Currency__c', 'Company__r.Subs_Currency__c'};		
		
		//string shipmentQuery = 'SELECT ' + string.join(new List<string>(shipmentFields),', ');
		//shipmentQuery += ' FROM Shipment__c WHERE Id IN :sIds';
		
		String shWhereClause = 'Id IN :sIds';
        
	    SOQLUtil shSoql = new SOQLUtil('Shipment__c');
	    shSoql.addFields(shipmentFields);
	    shSoql.setWhereClause(shWhereClause);
	    
		List<Accounting_Entry__c> aes = new List<Accounting_Entry__c>();
		List<Accounting_Entry_Line__c> aeLines = new List<Accounting_Entry_Line__c>();

		set<string> shipmentLineFields = new set<string>{'id', 'name', 'extended_cost__c', 'extended_price__c', 'quantity_shipped__c', 'sales_order_line__r.id', 
								'sales_order_line__r.name', 'sales_order_line__r.sales_order__c', 'product__r.item__c', 'sales_order_line__r.sales_order__r.type__c', 
								'sales_order_line__r.line_type__c', 'unit_price__c', 'sales_order_line__r.currency__c', 'product__r.item__r.class__r.type__c', 
								'subtransaction_type__c', 'Shipment__c','line_type__c', 'Shipment__r.transaction_date__c' , 'facility__c', 'Company__c', 'item__c'};
		shipmentLineFields.addAll(segmentReferences);
		
		//string shipmentLineQuery = 'SELECT ' + string.join(new List<string>(shipmentLineFields), ', ');
		//shipmentLineQuery += ' FROM Shipment_Line__c '
		//					+ 'WHERE id in :shipmentLineList '
        //                    + 'AND Finalized__c = true '
        //                    + 'AND Shipment__r.Company__c != null '
        //                    + 'AND Shipment__r.Transaction_Currency__c != null '
        //                    + 'AND Historical__c = false ' 
        //                    + 'AND Shipment__c NOT IN (SELECT Shipment__c FROM Accounting_Entry__c WHERE Shipment__c IN :sIds AND Related_Accounting_Entry__c = null  AND status__c=\'Active\' AND (period__r.closed__c = true OR period__r.permanently_closed__c = true OR period__r.Shipment_Subledger_Closed__c != null))' //FIN-889 AND batchjobid__c!=null and batchjobid__c!=:batchJobID) ' 
	    //                    + 'AND Id NOT IN (SELECT Shipment_Line__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Shipment_Line__c IN :shipmentLineList AND Accounting_Entry__r.BatchJobId__c = :bjId) '
	    //                    + 'FOR UPDATE'; 
        //system.debug('shipmentLineQuery: ' + shipmentLineQuery);
        
        
		String shLineWhereClause = 'id in :shipmentLineList '
                            + ' AND Finalized__c = true '
                            + ' AND Shipment__r.Company__c != null '
                            + ' AND (Shipment__r.Currency__c != null or Shipment__r.Transaction_Currency__c != null) '
                            + ' AND Historical__c = false ' 
                            + ' AND Shipment__c NOT IN ' 
                            	+ ' (SELECT Shipment__c FROM Accounting_Entry__c WHERE Shipment__c IN :sIds AND Related_Accounting_Entry__c = null ' 
                            		+ ' AND status__c=\'Active\' AND (period__r.closed__c = true OR period__r.permanently_closed__c = true OR period__r.Shipment_Subledger_Closed__c != null))' 
	                        + ' AND Id NOT IN '+
	                        + ' (SELECT Shipment_Line__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' '
	                        + ' AND Shipment_Line__c IN :shipmentLineList AND Accounting_Entry__r.BatchJobId__c = :bjId) '
	                        + 'FOR UPDATE';
        
	    SOQLUtil shLineSoql = new SOQLUtil('Shipment_Line__c');
	    shLineSoql.addFields(shipmentLineFields);
	    shLineSoql.setWhereClause(shLineWhereClause);
	    
        Map<Id, Accounting_Entry__c> mSourceDocAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mSourceDocAELs = new Map<Id, List<Accounting_Entry_Line__c>>();
        Map<Id, Shipment__c> mSs = new Map<Id, Shipment__c>();
		Map<Id, Shipment_Line__c> mSLs = new Map<Id, Shipment_Line__c>();

		try{
        	//Grab Lines for this scope
        	mSLs = new Map<Id, Shipment_Line__c>((List<Shipment_Line__c>)Database.query(shLineSoql.getQuery()));
        	
        	//Place the headers in a map for later reference
        	mSs = new Map<Id, Shipment__c>((List<Shipment__c>)Database.query(shSoql.getQuery()));
        	
        	findExistingDraftAEs(mSs.keySet());
        }catch(Exception ex){
        	throw ex;
        }
        
  		//KNDY-9545 
  		//Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
  		//This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
  		//This approach avoids handling all rules for the object and increases efficiency.
  		loadEffRuleDetails(mSs);
  		
		system.debug(LOGGINGLEVEL.INFO,'mRuleDefs'+mRuleDefs);
		
        //for(Shipment__c s : finalShipments){
        	
        	//string shipTransType;
        	//if (s.Type__c != null)
            //	shipTransType = s.type__c;			
            //else
            //	shipTransType = 'Shipment';
            //	
            //Accounting_Entry__c iAE = generateAccountingEntry(s, shipTransType);
 			//aes.add(iAE);
 			
 			for(Shipment_Line__c sl : mSLs.values()){
 				if(sl.product__c == null && sl.item__c != null){
 					itemSet.add(sl.item__c);
 				}else{
	    		itemSet.add(sl.product__r.item__c);
 				}
	    		itemCostDates.add(sl.Shipment__r.transaction_date__c);
				facilitySet.add(sl.Facility__c);
    		}
    	

			// first call to itemservice to cache data => tmp cost
			ItemService.preCacheCostRecords(itemCostDates, itemSet, facilitySet);
			//if(itemCostDates != null && itemCostDates.size() > 0){
			//	Datetime latestDatetime = itemCostDates[itemCostDates.size()-1];
			//	if(latestDatetime != null){
			//		Map <Id,Double> mTmpCost = ItemService.getActiveStandardCost(itemSet, facilitySet, facilityCompanyId, facilityId, latestDatetime);
			//}	
			//}	
 			
 			
 			for(Shipment_Line__c sl : mSLs.values()){

 				Accounting_Entry__c iAE;
	        	Shipment__c s = mSs.get(sl.Shipment__c);
	        	string shipTransType;
	        	if (s.Type__c != null)
	            	shipTransType = s.type__c;			
	            else
	            	shipTransType = 'Shipment';
            	
	        	if(mSourceDocAEs.containsKey(sl.Shipment__c)){
	        		iAE = mSourceDocAes.get(sl.Shipment__c);
	        	}else{
	        		iAE = generateAccountingEntry(s, shipTransType);
	        		mSourceDocAEs.put(s.Id, iAE);
	        	}
 			    
 			    
 			    List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
 			    
 			    string transType = iAE.Transaction_Type__c;
				string subTrans = (sl.Subtransaction_Type__c != null && sl.Subtransaction_Type__c != '') ? sl.Subtransaction_Type__c : null;
				
				//Create the rule definitions for this line
				AccountingRuleService.RuleDefinition iCRRuleDef = 
					new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, s.Company__r.Accounting_Standard__c, 'Shipment__c', transType, subTrans, sl.Line_Type__c);
				AccountingRuleService.RuleDefinition iDRRuleDef = 
					new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, s.Company__r.Accounting_Standard__c, 'Shipment__c', transType, subTrans, sl.Line_Type__c);
				AccountingRuleService.RuleDefinition iNARuleDef = 
					new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, s.Company__r.Accounting_Standard__c, 'Shipment__c', transType, subTrans, sl.Line_Type__c);
				
				if(mRuleDefs.containsKey(iNARuleDef)){
    				//system.debug(logginglevel.INFO, 'NA Rule Defs: ' + mRuleDefs.get(iNARuleDef).size() + ' - '  + mRuleDefs.get(iNARuleDef));
    				//Do nothing when NA rules are identified
    				for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
    					referencedRules.add(ar);
    				}
    				mSourceDocAELs.put(sl.Id, new List<Accounting_Entry_Line__c>());
    				continue;
    			}
    			
				//system.debug(logginglevel.INFO, 'iCRRuleDef: ' + iCRRuleDef);
				//system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iCRRuleDef));
				boolean nullFlag = false;
    			if(mRuleDefs.containsKey(iCRRuleDef)){
					   //system.debug(logginglevel.INFO, 'CR Rule Defs: ' + mRuleDefs.get(iCRRuleDef).size() + ' - '  + mRuleDefs.get(iCRRuleDef));
                       Integer outDatedRuleCount =0; 										
					   for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){	
						//KNDY-9545
						if((ar.Effective_End_Date__c!=null ? s.transaction_date__c >= ar.Effective_End_Date__c:false)    || s.transaction_date__c < ar.Effective_Start_Date__c  )
						{
							//ReturnLine for missing rule
							if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
							{
								decimal amount;
								decimal stdCost = ItemService.getActiveStandardCost(itemSet, facilitySet, sl.Company__c, sl.Facility__c, sl.Shipment__r.Transaction_Date__c).get(sl.product__r.item__c);
								decimal qtyShipped = sl.Quantity_Shipped__c;
								if(stdCost == null){
									nullFlag = true;
								}else if(stdCost != null && qtyShipped != null){
									amount = stdCost * qtyShipped;
								}else{
									amount = 0;
							    }	
				 			 iAELs.add(returnLineForMissingEffectiveRule(iAE, sl, iCRRuleDef, amount, nullFlag));							
							}
							outDatedRuleCount++;
							continue;
						}																	
						decimal iCRAmt = findLineAmount(sl, ar);
						system.debug(logginglevel.info,'iCRAmt:'+iCRAmt);
						//if(iCRAmt == null){
						//	continue;
						//}	
						
						if(iCRAmt == null){
							system.debug(logginglevel.info,'iCRAmt is null:'+iCRAmt);
							iCRAmt = 0;
							nullFlag = true;
						}	
						
						Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, s, sl,ar, iCRAmt);
						iAEL.SubTransaction_Type__c = subTrans;
						iAEL.Line_Type__c = sl.Line_Type__c;
						iAEL.Shipment_Line__c = sl.Id;							
						if(nullFlag == true){
							iAEL.item_cost_missing__c = true;
						}else{
							iAEL.item_cost_missing__c = false;
						}

						SS.assignSegments(ar, sl, iAEL);							
						
						iAELs.add(iAEL);
						referencedRules.add(ar);
					}	
				}else{
					decimal amount, stdCost;
					if(sl.product__c != null){
						stdCost = ItemService.getActiveStandardCost(itemSet, facilitySet, sl.Company__c, sl.Facility__c, sl.Shipment__r.Transaction_Date__c).get(sl.product__r.item__c);
					}else if(sl.item__c != null){
						stdCost = ItemService.getActiveStandardCost(itemSet, facilitySet, sl.Company__c, sl.Facility__c, sl.Shipment__r.Transaction_Date__c).get(sl.item__c);
					}
					
					decimal qtyShipped = sl.Quantity_Shipped__c;
					if(stdCost == null){
						nullFlag = true;
					}else if(stdCost != null && qtyShipped != null){
						amount = stdCost * qtyShipped;
					}else{
						amount = 0;
				    }
					iAELs.add(returnLineForMissingEffectiveRule(iAE, sl, iCRRuleDef, amount, nullFlag));
					//iAELs.add(returnLineForMissingRule(iAE, sl, iCRRuleDef, sl.Extended_Cost__c));
				}
				
				//system.debug(logginglevel.INFO, 'iDRRuleDef: ' + iDRRuleDef);
				//system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iDRRuleDef));
				if(mRuleDefs.containsKey(iDRRuleDef)){
					//system.debug(logginglevel.INFO, 'DR Rule Defs: ' + mRuleDefs.get(iDRRuleDef).size() + ' - '  + mRuleDefs.get(iDRRuleDef));
                    Integer outDatedRuleCount =0; 					
					for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){
						if((ar.Effective_End_Date__c!=null ? s.transaction_date__c >= ar.Effective_End_Date__c:false)   || s.transaction_date__c < ar.Effective_Start_Date__c  )
						{
							//ReturnLine for missing rule
							if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
							{
								decimal amount;
								decimal stdCost = ItemService.getActiveStandardCost(itemSet, facilitySet, sl.Company__c, sl.Facility__c, sl.Shipment__r.Transaction_Date__c).get(sl.product__r.item__c);
								decimal qtyShipped = sl.Quantity_Shipped__c;
								if(stdCost == null){
									nullFlag = true;
								}else if(stdCost != null && qtyShipped != null){
									amount = stdCost * qtyShipped;
								}else{
									amount = 0;
							    }	
				 			 iAELs.add(returnLineForMissingEffectiveRule(iAE, sl, iDRRuleDef, amount, nullFlag));							
							}
							outDatedRuleCount++;
							continue;
						}					
						decimal iDRAmt = findLineAmount(sl, ar);
						system.debug(logginglevel.info,'iDRAmt:'+iDRAmt);
						//if(iDRAmt == null){
						//	continue;
						//}
						
						if(iDRAmt == null){
							system.debug(logginglevel.info,'iDRAmt is null:'+iDRAmt);
							iDRAmt = 0;
							nullFlag = true;
						}
						
						Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, s, sl,ar, iDRAmt);
						iAEL.SubTransaction_Type__c = subTrans;
						iAEL.Line_Type__c = sl.Line_Type__c;								
						iAEL.Shipment_Line__c = sl.Id;									
						if(nullFlag == true){
							iAEL.item_cost_missing__c = true;
                            nullFlag = false;

						}else{
							iAEL.item_cost_missing__c = false;
						}
						SS.assignSegments(ar, sl, iAEL);							
						
						iAELs.add(iAEL);
						referencedRules.add(ar);
					}
				}else{
					decimal amount, stdCost;
					if(sl.product__c != null){
						stdCost = ItemService.getActiveStandardCost(itemSet, facilitySet, sl.Company__c, sl.Facility__c, sl.Shipment__r.Transaction_Date__c).get(sl.product__r.item__c);
					}else if(sl.item__c != null){
						stdCost = ItemService.getActiveStandardCost(itemSet, facilitySet, sl.Company__c, sl.Facility__c, sl.Shipment__r.Transaction_Date__c).get(sl.item__c);
					}
					
					decimal qtyShipped = sl.Quantity_Shipped__c;
					if(stdCost == null){
						nullFlag = true;
					}else if(stdCost != null && qtyShipped != null){
						amount = stdCost * qtyShipped;
					}else{
						amount = 0;
					}
					iAELs.add(returnLineForMissingEffectiveRule(iAE, sl, iDRRuleDef, amount, nullFlag));
					//iAELs.add(returnLineForMissingRule(iAE, sl, iDRRuleDef, sl.Extended_Cost__c));
				}	
				mSourceDocAELs.put(sl.Id, iAELs);
 			    //aeLines.addAll(iAELs);
 			}
		//}
		finish((Map<Id, sObject>)mSs, (Map<Id, sObject>)mSLs, mSourceDocAEs, mSourceDocAELs);

		//finish(finalShipments, aes, aeLines);
	}

	
	private decimal findLineAmount(Shipment_Line__c sl, Accounting_Rule__c ar){
		decimal amount, stdCost;		
		if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
			amount = (decimal)sl.get(ar.Amount_Reference__c) == null ? 0 : (decimal)sl.get(ar.Amount_Reference__c);			
		}else{									
			//if(sl.Extended_Cost__c != null){
			//	amount = sl.Extended_Cost__c;
			//}
			if(sl.product__c != null){
				stdCost = ItemService.getActiveStandardCost(itemSet, facilitySet, sl.Company__c, sl.Facility__c, sl.Shipment__r.Transaction_Date__c).get(sl.product__r.item__c);
			}else if(sl.item__c != null){
				stdCost = ItemService.getActiveStandardCost(itemSet, facilitySet, sl.Company__c, sl.Facility__c, sl.Shipment__r.Transaction_Date__c).get(sl.item__c);
			}
			decimal qtyShipped = sl.Quantity_Shipped__c;
			if(stdCost == null){
				amount = null;
			}else if(stdCost != null && qtyShipped != null){
				amount = stdCost * qtyShipped;
			}else{
				amount = 0;
			}		
		}
		return amount;		
	}	
	*/
}