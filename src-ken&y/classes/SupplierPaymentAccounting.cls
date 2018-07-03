public with sharing class SupplierPaymentAccounting extends AccountingService {
    
    public SupplierPaymentAccounting(){
        super('Supplier_Payment__c');
    }   
    
    public override void execute(List<sObject> supplierPaymentLines){
        
        string bjId = this.batchJobId;
        
        set<Id> spIds = new set<Id>();
        for(Supplier_Payment_Line__c spl : (List<Supplier_Payment_Line__c>)supplierPaymentLines){
            spIds.add(spl.supplier_payment__c);
        }
        
        set<string> supPayFields = new set<string>{'ID', 'name', 'payment_amount__c', 'bank_account__c', 'date_paid__c', 'supplier__c', 'finalized__c', 'company__c', 'company__r.accounting_standard__c', 'void__c', 'void_date__c',
                                'Payment_Method_G__c', 'transaction_type__c','Transaction_Currency__c','currency__c', 'Currency__r.ISO_Code__c', 'finalized_date__c', 'transaction_date__c', 'total_number_of_lines__c', 'posting_date__c'};       
        
        
        set<string> supPayLineFields = new set<string>{'id', 'name', 'amount__c', 'supplier_invoice__c', 'supplier_payment__c', 'type__c', 
                                'line_type__c', 'subtransaction_type__c', 'Supplier_Invoice__r.Purchase_Order__c','Supplier_Payment__r.Company__c', 'Supplier_Payment__r.Company__r.Comp_Currency__c', 'supplier_payment__r.Currency__c', 'supplier_payment__r.transaction_date__c', 'supplier_payment__r.company__r.comp_currency__r.ISO_Code__c', 'supplier_payment__r.currency__r.ISO_Code__c'};
        supPayLineFields.addAll(segmentReferences); 
        
        Map<Id, Accounting_Entry__c> mSourceDocAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mSourceDocAELs = new Map<Id, List<Accounting_Entry_Line__c>>();
        Map<Id, Supplier_Payment__c> mSPs = new Map<Id, Supplier_Payment__c>();
        Map<Id, Supplier_Payment_Line__c> mSPLs = new Map<Id, Supplier_Payment_Line__c>();
        try{
            
            String whereClause = 'Id IN :supplierPaymentLines '
                                    + 'AND Finalized__c = true '
                                    + 'AND Historical__c = false ' 
                                    + 'AND Supplier_Payment__r.Transaction_Date__c != null '
                                    + 'AND Supplier_Payment__r.Finalized_Date__c != null '
                                    + 'AND Supplier_Payment__r.Company__c != null '
                                    + 'AND (Supplier_Payment__r.Currency__c != null or Supplier_Payment__r.Transaction_Currency__c != null) '
                                    + 'AND Supplier_Payment__c NOT IN (SELECT Supplier_Payment__c FROM Accounting_Entry__c WHERE Supplier_Payment__c IN :spIds AND related_accounting_entry__c = null  AND status__c=\'Active\' AND (Period__r.Closed__c = true OR Period__r.Permanently_Closed__c = true OR period__r.AP_Subledger_Closed__c != null) ) ' // FIN-889  AND batchjobid__c!=null and batchjobid__c!=:batchJobID
                                    + 'AND Id NOT IN (SELECT Supplier_Payment_Line__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Supplier_Payment_Line__c IN :supplierPaymentLines AND Accounting_Entry__r.BatchJobId__c = :bjId) '
                                    + 'FOR UPDATE';
        
            SOQLUtil soql = new SOQLUtil('Supplier_Payment_Line__c');
            soql.addFields(supPayLineFields);
            soql.setWhereClause(whereClause);
            
            //Grab Lines for this scope
            mSPLs = new Map<Id, Supplier_Payment_Line__c>((List<Supplier_Payment_Line__c>) Database.query(soql.getQuery()));
            
            soql = new SOQLUtil('Supplier_Payment__c');
            soql.addFields(supPayFields);
            soql.setWhereClause('Id IN :spIds');
            
            //Place the headers in a map for later reference
            mSPs = new Map<Id, Supplier_Payment__c>((List<Supplier_Payment__c>) Database.query(soql.getQuery()));
            findExistingDraftAEs(mSPs.keySet());
        }catch(Exception ex){
            throw ex;
        }
        //KNDY-9545 
        //Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
        //This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
        //This approach avoids handling all rules for the object and increases efficiency.
        loadEffRuleDetails(mSPs);
        
        system.debug(LOGGINGLEVEL.INFO,'mRuleDefs'+mRuleDefs);
                
        List<DateTime> exchangeRateDates = new List<DateTime>();
        set<Id>compIds = new set<Id>();
        set<Id> siIds = new set<Id>();
        for(Supplier_Payment_Line__c spayl : mSPLs.values()){
            siIds.add(spayl.supplier_invoice__c);
            exchangeRateDates.add(spayl.supplier_payment__r.transaction_date__c);
            compIds.add(spayl.Supplier_Payment__r.Company__c);
        }
        
        populateCompanyMap(compIds);
        
        findExchangeRates(exchangeRateDates);
            
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        
        SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', true, true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'supplier_invoice_line__r.supplier_invoice__c siId','GL_Account__c glId','GL_Account__r.FX_Type__c fxType','sum(amount_dr__c) amtDR',
            'sum(COMP_Functional_Currency_Amount_DR__c) funcDR','sum(amount_cr__c) amtCR','sum(COMP_Functional_Currency_Amount_CR__c) funcCR'
        });
        soql.setWhereClause('Supplier_Invoice_Line__r.Supplier_Invoice__c IN :siIds AND Status__c = \'Active\' AND Related_Accounting_Entry_Line__c = null '
                            +' GROUP BY supplier_invoice_line__r.supplier_invoice__c, gl_account__c, gl_account__r.fx_type__c');
        
        List<AggregateResult> arGLAggs = Database.query(soql.getQuery());
        
        Map<Id, Map<Id, AggregateResult>> mARs = new Map<Id, Map<Id, AggregateResult>>();
        for(AggregateResult ar : arGLAggs){
            if(mARs.containsKey((string)ar.get('siId'))){
                mARs.get((string)ar.get('siId')).put((string)ar.get('glId'), ar);
            }else{
                mARs.put((string)ar.get('siId'), new map<Id, AggregateResult>{(string)ar.get('glId') => ar});
            }
        }
            
        for(Supplier_Payment_Line__c spayl : mSPLs.values()){
                
            Accounting_Entry__c iAE;
            Supplier_Payment__c spay = mSPs.get(spayl.Supplier_Payment__c);
            if(mSourceDocAEs.containsKey(spayl.Supplier_Payment__c)){
                iAE = mSourceDocAes.get(spayl.Supplier_Payment__c);
            }else{
                iAE = generateAccountingEntry(spay, 'Supplier Payment');
                iAE.supplier__c = spay.Supplier__c;
                mSourceDocAEs.put(spay.Id, iAE);
            }
                
            List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
            string transType = iAE.Transaction_Type__c;
            string subTrans = (spayl.Subtransaction_Type__c != null && spayl.Subtransaction_Type__c != '') ? spayl.Subtransaction_Type__c : null;
                        
            //Create the rule definitions for this line
            AccountingRuleService.RuleDefinition iCRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, spay.Company__r.Accounting_Standard__c, 'Supplier_Payment__c', transType, subTrans, spayl.Line_Type__c);
            AccountingRuleService.RuleDefinition iDRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, spay.Company__r.Accounting_Standard__c, 'Supplier_Payment__c', transType, subTrans, spayl.Line_Type__c);
            AccountingRuleService.RuleDefinition iNARuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, spay.Company__r.Accounting_Standard__c, 'Supplier_Payment__c', transType, subTrans, spayl.Line_Type__c);
                            
            if(mRuleDefs.containsKey(iNARuleDef)){
                //system.debug(logginglevel.INFO, 'NA Rule Defs: ' + mRuleDefs.get(iNARuleDef).size() + ' - '  + mRuleDefs.get(iNARuleDef));
                //Do nothing when NA rules are identified
                for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
                    referencedRules.add(ar);
                }
                mSourceDocAELs.put(spayl.Id, new List<Accounting_Entry_Line__c>());
                continue;
            }
                
            //system.debug(logginglevel.INFO, 'iCRRuleDef: ' + iCRRuleDef);
            //system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iCRRuleDef));
            if(mRuleDefs.containsKey(iCRRuleDef)){
                Integer outDatedRuleCount =0;
                //system.debug(logginglevel.INFO, 'CR Rule Defs: ' + mRuleDefs.get(iCRRuleDef).size() + ' - '  + mRuleDefs.get(iCRRuleDef));
                for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){                 
                    //KNDY-9545
                    if((ar.Effective_End_Date__c!=null ? spay.transaction_date__c >= ar.Effective_End_Date__c:false)  || spay.transaction_date__c < ar.Effective_Start_Date__c  )
                    {
                        //ReturnLine for missing rule 
                        if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
                        {
                          iAELs.add(returnLineForMissingEffectiveRule(iAE, spayl, iCRRuleDef, spayl.Amount__c));                            
                        }
                        outDatedRuleCount++;
                        continue;
                    }                       
                    decimal iCRAmt = findLineAmount(spayl, ar);
                    if(iCRAmt == null){
                        //continue;
                    }   
                    
                    Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, spay, spayl, ar, iCRAmt);
                    iAEL.SubTransaction_Type__c = subTrans;
                    iAEL.Line_Type__c = spayl.Line_Type__c;
                    iAEL.Supplier_Payment_Line__c = spayl.Id;                           

                    SS.assignSegments(ar, spayl, iAEL);                         
                    populateLedgers(ar, iAE, iAEL);
                    
                    iAELs.add(iAEL);
                    referencedRules.add(ar);
                }   
            }else{
                iAELs.add(returnLineForMissingEffectiveRule(iAE, spayl, iCRRuleDef, spayl.Amount__c));
            }                       
                
            //system.debug(logginglevel.INFO, 'iDRRuleDef: ' + iDRRuleDef);
            //system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iDRRuleDef));
            if(mRuleDefs.containsKey(iDRRuleDef)){
                Integer outDatedRuleCount =0;
                //system.debug(logginglevel.INFO, 'DR Rule Defs: ' + mRuleDefs.get(iDRRuleDef).size() + ' - '  + mRuleDefs.get(iDRRuleDef));
                for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){
                    //KNDY-9545
                    if((ar.Effective_End_Date__c!=null ? spay.transaction_date__c >= ar.Effective_End_Date__c:false)    || spay.transaction_date__c < ar.Effective_Start_Date__c  )
                    {
                        //ReturnLine for missing rule
                        if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
                        {
                          iAELs.add(returnLineForMissingEffectiveRule(iAE, spayl, iDRRuleDef, spayl.Amount__c));                            
                        }
                        outDatedRuleCount++;
                        continue;
                    }                       
                    decimal iDRAmt = findLineAmount(spayl, ar);
                    if(iDRAmt == null){
                        //continue;
                    }           
                    
                    Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, spay, spayl, ar, iDRAmt);
                    iAEL.SubTransaction_Type__c = subTrans;
                    iAEL.Line_Type__c = spayl.Line_Type__c;                             
                    iAEL.Supplier_Payment_Line__c = spayl.Id;                       
                    
                    SS.assignSegments(ar, spayl, iAEL); 
                    populateLedgers(ar, iAE, iAEL);
                    
                    iAELs.add(iAEL);
                    referencedRules.add(ar);
                }
            }else{
                iAELs.add(returnLineForMissingRule(iAE, spayl, iDRRuleDef, spayl.Amount__c));
            }
            
               
            if(spayl.supplier_payment__r.currency__r.ISO_Code__c != spayl.supplier_payment__r.company__r.comp_currency__r.ISO_Code__c){
				//Now check deltas vs. aggregates and create percentage for clearing upstream accounts
				system.debug(logginglevel.info, 'mARs: ' + mARs);
				system.debug(logginglevel.info, 'checking supplier_invoice__c: ' + spayl.supplier_invoice__c + ' - ' + mARs.containsKey(spayl.supplier_invoice__c) + ' - ' + mARs.get(spayl.supplier_invoice__c));
				if(mARs.containsKey(spayl.supplier_invoice__c)){
					for(Id glId : mARs.get(spayl.supplier_invoice__c).keySet()){
						decimal totalDR = 0;
						decimal totalCR = 0;
						//need % sil vs sum RDs
						for(Accounting_Entry_Line__c iAEL : iAELs){
							//check map for pol, then gl for this sil and iAEL respectively
							if(mARs.containsKey(spayl.supplier_invoice__c)){
								if(mARs.get(spayl.supplier_invoice__c).containsKey(iAEL.gl_account__c)){
									AggregateResult iAgg = mARs.get(spayl.supplier_invoice__c).get(iAEL.gl_account__c);
									if(iAgg.get('fxType') != null){
										string iFXType = (string)iAgg.get('fxType');
										if(iFXType.equalsIgnoreCase('Monetary Non-cash') && iAEL.GL_Account__c == glId){
											//Now we're open to exposure
											totalDR += iAEL.amount_dr__c;
											totalCR += iAEL.amount_cr__c;
										}
									}
								}
							}
						}
						system.debug(logginglevel.info, 'totalDR: ' + totalDR + ' totalCR: ' + totalCR);
						if(totalDR != 0 || totalCR != 0){
							
							AggregateResult aggRes = mARs.get(spayl.supplier_invoice__c).get(glId);
							string iFXType = (string)aggRes.get('fxType');
							system.debug(logginglevel.info, 'aggRes: ' + aggRes);
							decimal iAggDR = decimal.valueOf(string.valueOf(aggRes.get('amtDR')));
							decimal iAggCR = decimal.valueOf(string.valueOf(aggRes.get('amtCR')));
							system.debug(logginglevel.info, 'iAggDR: ' + iAggDR + ' iAggCR: ' + iAggCR);
							decimal iAggFuncDR = decimal.valueOf(string.valueOf(aggRes.get('funcDR')));
							decimal iAggFuncCR = decimal.valueOf(string.valueOf(aggRes.get('funcCR')));
							system.debug(logginglevel.info, 'iAggFuncDR: ' + iAggFuncDR + ' iAggFuncCR: ' + iAggFuncCR);
							//normalize attainment of functional based on transaction currency
							
							decimal iPctDR = iAggDR != 0 ? 1 - (iAggDR - totalCR)/iAggDR : 0;
							decimal iPctCR = iAggCR != 0 ? 1 - (iAggCR - totalDR)/iAggCR : 0;
							
							system.debug(logginglevel.info, 'iPctDR: ' + iPctDR + ' iPctCR: ' + iPctCR);
							
							//loop back through and assign ledger amounts - back in to exchange rate
							decimal rate;
							for(Accounting_Entry_Line__c iAEL : iAELs){
								if(iFXType.equalsIgnoreCase('Monetary Non-cash') && iAEL.GL_Account__c == glId){
									if(iAEL.amount_DR__c != null && totalDR != 0){
										decimal normalizedFuncDR = iAggFuncCR * (iAEL.amount_dr__c/totalDR) * iPctCR;
										system.debug(logginglevel.info, 'normalizedFuncDR: ' + normalizedFuncDR);
										iAEL.COMP_Functional_Currency_Amount_DR__c = normalizedFuncDr;
										iAEL.COMP_Transaction_Currency__c = spayl.supplier_payment__r.currency__r.ISO_Code__c;
										iAEL.COMP_Functional_Currency__c = spayl.supplier_payment__r.company__r.comp_currency__r.ISO_Code__c;
										if(iAEL.amount_dr__c != 0){
											iAEL.COMP_Functional_Conversion_Rate__c = iAEL.COMP_Functional_Currency_Amount_DR__c/iAEL.amount_dr__c;
											rate = iAEL.COMP_Functional_Conversion_Rate__c;
										}
									}
									if(iAEL.amount_CR__c != null && totalCR != 0){
										decimal normalizedFuncCR = iAggFuncDR * (iAEL.amount_cr__c/totalCR) * iPctDR;
										system.debug(logginglevel.info, 'normalizedFuncCR: ' + normalizedFuncCR);
										iAEL.COMP_Functional_Currency_Amount_CR__c = normalizedFuncCr;
										iAEL.COMP_Transaction_Currency__c = spayl.supplier_payment__r.currency__r.ISO_Code__c;
										iAEL.COMP_Functional_Currency__c = spayl.supplier_payment__r.company__r.comp_currency__r.ISO_Code__c;
										if(iAEL.amount_cr__c != 0){
											iAEL.COMP_Functional_Conversion_Rate__c = iAEL.COMP_Functional_Currency_Amount_CR__c/iAEL.amount_cr__c;
											rate = iAEL.COMP_Functional_Conversion_Rate__c;
										}
									}
								}
							}
							
							
							
/*							decimal totalFuncDR = 0;
							decimal totalFuncCR = 0;

                            Id rfxId = returnRFX() != null ? returnRFX().Id : null;
							Accounting_Entry_Line__c rfxAEL = new Accounting_Entry_Line__c(COMP_Transaction_Currency__c = spayl.Supplier_Payment__r.Currency__r.ISO_Code__c, 
																							COMP_Functional_Currency__c = spayl.Supplier_Payment__r.Company__r.comp_currency__r.ISO_Code__c,
																							Supplier_Payment_Line__c = spayl.Id, 
																							GL_Account__c = rfxId, 
																							Source_Id__c = spayl.Id + '|RFX', 
																							Accounting_Entry__r = new Accounting_Entry__c(source_key__c = iAE.source_Key__c), 
																							COMP_Functional_Currency_Amount_CR__c = 0, 
																							COMP_Functional_Currency_Amount_DR__c = 0,
																							COMP_Transaction_Currency_Amount_CR__c = 0, 
																							COMP_Transaction_Currency_Amount_DR__c = 0,
																							Subtransaction_Type__c = 'RFX');
							for(Accounting_Entry_Line__c ael : iAELs){
								system.debug(logginglevel.info, 'ael: ' + ael);
								totalFuncDR += ael.COMP_Functional_Currency_Amount_DR__c == null ? 0 : ael.COMP_Functional_Currency_Amount_DR__c;
								totalFuncCR += ael.COMP_Functional_Currency_Amount_CR__c == null ? 0 : ael.COMP_Functional_Currency_Amount_CR__c;
							}
							
							system.debug('totalFuncDR: ' + totalFuncDR + ' - totalFuncCR: ' + totalFuncCR);
							decimal delta = totalFuncDR - totalFuncCR;
							if(delta > 0){
								rfxAEL.COMP_Functional_Currency_Amount_CR__c = math.abs(delta);
								system.debug(logginglevel.info, 'rfxAEL: ' + rfxAEL);
								iAELs.add(rfxAEL);
							}else if(delta < 0){
								rfxAEL.COMP_Functional_Currency_Amount_DR__c = math.abs(delta);
								system.debug(logginglevel.info, 'rfxAEL: ' + rfxAEL);
								iAELs.add(rfxAEL);
							}*/
				           
							
						}
						
					}
				}
			}
			system.debug(logginglevel.info, 'spaylId = > iAELs: ' + spayl.Id + ' = > ' + iAELs.size() + ' - ' + iAELs );
			 
            mSourceDocAELs.put(spayl.Id, iAELs);
        }
        
        finish((Map<Id, sObject>)mSPs, (Map<Id, sObject>)mSPLs, mSourceDocAEs, mSourceDocAELs);

    }

    
    private decimal findLineAmount(Supplier_Payment_Line__c spayl, Accounting_Rule__c ar){
        decimal amount;     
        if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
            amount = (decimal)spayl.get(ar.Amount_Reference__c);            
        }else{                                  
            if(spayl.Amount__c != null){
                amount = spayl.Amount__c;
            }   
        }
        return returnFinalLineAmount(amount,ar);
    }   
}