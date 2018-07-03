public with sharing class CustomerReceiptAccounting extends AccountingService {
    
    public CustomerReceiptAccounting(){
        super('Customer_Receipt__c');
    }   
    
    public override void execute(List<sObject> customerReceiptLineList){
		
		string bjId = this.batchJobId;

        set<Id> crIDs = new set<Id>();
        for(Customer_Receipt_Line__c crl : (List<Customer_Receipt_Line__c>)customerReceiptLineList){
            crIDs.add(crl.Customer_Receipt__c);
        }
		set<string> custRecFields = new set<string>{'id', 'name', 'amount_received__c', 'amount_unapplied__c',  'customer__c', 'finalized__c', 'void__c', 'Company__r.Comp_Currency__r.ISO_Code__c',
                                'company__c', 'company__r.accounting_standard__c', 'type__c','Transaction_Currency__c', 'currency__c', 'Currency__r.ISO_Code__c','date_received__c', 'finalized_date__c', 'transaction_date__c', 'posting_date__c', 'transaction_type__c', 'total_number_of_lines__c','Company__r.comp_currency__c','Company__r.consol_currency__c','Company__r.Stat_Currency__c', 'Company__r.Subs_Currency__c'};      
		
        set<string> custRecLineFields = new set<string>{'id', 'name', 'amount__c', 'customer_invoice__c', 'customer_receipt__c', 'customer_receipt__r.amount_received__c',
                                'customer_receipt__r.amount_unapplied__c','type__c', 'line_type__c', 'subtransaction_type__c', 'Customer_Invoice__r.Transaction_Date__c'};
        custRecLineFields.addAll(segmentReferences);    
        
        String crlWhereClause = 'id in :customerReceiptLineList '
                            + 'AND Finalized__c = true '
                            + 'AND Historical__c = false '
                            + 'AND Customer_Receipt__r.Company__c != null '
                            + 'AND Customer_Receipt__r.Transaction_Date__c != null '
                            + 'AND (Customer_Receipt__r.Currency__c != null or Customer_Receipt__r.Transaction_Currency__c != null) '
                            + 'AND Customer_Receipt__r.Finalized_Date__c != null '
                            + 'AND Customer_Receipt__c NOT IN (SELECT Customer_Receipt__c FROM Accounting_Entry__c WHERE Customer_Receipt__c IN :crIDs AND Related_Accounting_Entry__c = null   AND status__c=\'Active\' AND (period__r.closed__c = true OR period__r.permanently_closed__c = true OR period__r.AR_Subledger_Closed__c != null))'//FIN-889 AND batchjobid__c!=null and batchjobid__c!=:batchJobID) ' 
                            + 'AND Id NOT IN (SELECT Customer_Receipt_Line__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Customer_Receipt_Line__c IN :customerReceiptLineList AND Accounting_Entry__r.BatchJobId__c = :bjId) '
                            + 'FOR UPDATE';

        SOQLUtil customerReceiptQuery = new SOQLUtil('Customer_Receipt__c', TRUE);
        customerReceiptQuery.addFields(custRecFields);
        customerReceiptQuery.setWhereClause('Id IN :crIDs');

        SOQLUtil customerReceiptLineQuery = new SOQLUtil('Customer_Receipt_Line__c', TRUE);
        customerReceiptLineQuery.addFields(custRecLineFields);
        customerReceiptLineQuery.setWhereClause(crlWhereClause);

        Map<Id, Accounting_Entry__c> mSourceDocAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mSourceDocAELs = new Map<Id, List<Accounting_Entry_Line__c>>();
        Map<Id, Customer_Receipt__c> mCRs = new Map<Id, Customer_Receipt__c>();
        Map<Id, Customer_Receipt_Line__c> mCRLs = new Map<Id, Customer_Receipt_Line__c>();
        try{
            //Grab Lines for this scope
            mCRLs = new Map<Id, Customer_Receipt_Line__c>((List<Customer_Receipt_Line__c>)Database.query(customerReceiptLineQuery.getQuery()));
            //Place the headers in a map for later reference
            mCRs = new Map<Id, Customer_Receipt__c>((List<Customer_Receipt__c>)Database.Query(customerReceiptQuery.getQuery()));

            List<Datetime>transDates = new List<Datetime>();
            Set<Id>compIds = new Set<Id>();
            for(Customer_Receipt__c c : mCRs.values()){
            	transDates.add(c.Transaction_Date__c);
            	compIds.add(c.Company__c);
            }
            for(Customer_Receipt_Line__c c : mCRLs.values()){
            	transDates.add(c.Customer_Invoice__r.Transaction_Date__c);
            }

            populateCompanyMap(compIds);

        	findExchangeRates(transDates);

            findExistingDraftAEs(mCRs.keySet());
        }catch(Exception ex){
            throw ex;
        }
        
  		//KNDY-9545 
  		//Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
  		//This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
  		//This approach avoids handling all rules for the object and increases efficiency.
  		loadEffRuleDetails(mCRs);
  		
		system.debug(LOGGINGLEVEL.INFO,'mRuleDefs'+mRuleDefs);
        
        for(Customer_Receipt_Line__c crl : mCRLs.values()){
            
		    Accounting_Entry__c iAE;
            Customer_Receipt__c cr = mCRs.get(crl.Customer_Receipt__c);
            if(mSourceDocAEs.containsKey(crl.Customer_Receipt__c)){
                iAE = mSourceDocAes.get(crl.Customer_Receipt__c);
            }else{
            	string transactionType;
          		if(cr.transaction_type__c != null && cr.transaction_type__c != '')
          			transactionType = cr.transaction_type__c;
          		else
          			transactionType = cr.type__c;
              	
                iAE = generateAccountingEntry(cr,  transactionType);
                iAE.Customer__c = cr.Customer__c;
                mSourceDocAEs.put(cr.Id, iAE);
            }

		    List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
		    
			string transType = iAE.Transaction_Type__c;
			string subTrans = (crl.Subtransaction_Type__c != null && crl.Subtransaction_Type__c != '') ? crl.Subtransaction_Type__c : null;
			
			//Create the rule definitions for this line
			AccountingRuleService.RuleDefinition iCRRuleDef = 
				new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, cr.Company__r.Accounting_Standard__c, 'Customer_Receipt__c', transType, subTrans, crl.Line_Type__c);
			AccountingRuleService.RuleDefinition iDRRuleDef = 
				new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, cr.Company__r.Accounting_Standard__c, 'Customer_Receipt__c', transType, subTrans, crl.Line_Type__c);
			AccountingRuleService.RuleDefinition iNARuleDef = 
				new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, cr.Company__r.Accounting_Standard__c, 'Customer_Receipt__c', transType, subTrans, crl.Line_Type__c);
			
			
			if(mRuleDefs.containsKey(iNARuleDef)){
				//system.debug(logginglevel.INFO, 'NA Rule Defs: ' + mRuleDefs.get(iNARuleDef).size() + ' - '  + mRuleDefs.get(iNARuleDef));
				//Do nothing when NA rules are identified
				for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
					referencedRules.add(ar);
				}
				mSourceDocAELs.put(crl.Id, new List<Accounting_Entry_Line__c>());
				continue;
			}
			
			if(mRuleDefs.containsKey(iCRRuleDef)){
			     Integer outDatedRuleCount =0;				
				//system.debug(logginglevel.INFO, 'CR Rule Defs: ' + mRuleDefs.get(iCRRuleDef).size() + ' - '  + mRuleDefs.get(iCRRuleDef));
				for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){
					//KNDY-9545
					if((ar.Effective_End_Date__c!=null ? cr.transaction_date__c >= ar.Effective_End_Date__c:false)  || cr.transaction_date__c < ar.Effective_Start_Date__c  )
					{
						//ReturnLine for missing rule
						if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
						{
					      iAELs.add(returnLineForMissingEffectiveRule(iAE, crl, iCRRuleDef, crl.Amount__c));							
						}
						outDatedRuleCount++;
						continue;
					}					
					decimal iCRAmt = findLineAmount(crl, ar);
					if(iCRAmt == null){
						//continue;
					}			
					
					Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, cr, crl, ar, iCRAmt);
					iAEL.SubTransaction_Type__c = subTrans;
					iAEL.Line_Type__c = crl.Line_Type__c;
					iAEL.Customer_Receipt_Line__c = crl.Id;					

					SS.assignSegments(ar, crl, iAEL);							
					populateLedgers(ar, iAE, iAEL);	

					if(iAEL.COMP_Transaction_Currency__c != iAEL.COMP_Functional_Currency__c){
						Exchange_Rate__c er = returnExchangeRate(iAEL.COMP_Transaction_Currency__c, iAEL.COMP_Functional_Currency__c, null, null, crl.Customer_Invoice__r.Transaction_Date__c, 'Daily');
						
						if(er != null){
							iAEL.COMP_Functional_Conversion_Rate__c = er.Multiplier_Exchange_Rate__c;
							iAEL.COMP_Functional_Currency_Amount_CR__c = iAEL.COMP_Functional_Conversion_Rate__c * iAEL.COMP_Transaction_Currency_Amount_CR__c;
						}
					}					
					
					iAELs.add(iAEL);
					referencedRules.add(ar);
				}	
			}else{
				iAELs.add(returnLineForMissingEffectiveRule(iAE, crl, iCRRuleDef, crl.Amount__c));
			}							
			
			//system.debug(logginglevel.INFO, 'iDRRuleDef: ' + iDRRuleDef);
			//system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iDRRuleDef));
			
			if(mRuleDefs.containsKey(iDRRuleDef)){
				//system.debug(logginglevel.INFO, 'DR Rule Defs: ' + mRuleDefs.get(iDRRuleDef).size() + ' - '  + mRuleDefs.get(iDRRuleDef));
				Integer outDatedRuleCount =0;								
				for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){
					if((ar.Effective_End_Date__c!=null ? cr.transaction_date__c >= ar.Effective_End_Date__c:false)   || cr.transaction_date__c < ar.Effective_Start_Date__c  )
					{
						//ReturnLine for missing rule
						if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
						{
					      iAELs.add(returnLineForMissingEffectiveRule(iAE, crl, iDRRuleDef, crl.Amount__c));							
						}
						outDatedRuleCount++;
						continue;
					}					
					decimal iDRAmt = findLineAmount(crl, ar);
					if(iDRAmt == null){
						//continue;
					}	
					
					Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, cr, crl, ar, iDRAmt);
					iAEL.SubTransaction_Type__c = subTrans;
					iAEL.Line_Type__c = crl.Line_Type__c;								
					iAEL.Customer_Receipt_Line__c = crl.Id;								
					
					SS.assignSegments(ar, crl, iAEL);							
					populateLedgers(ar, iAE, iAEL);
					
					iAELs.add(iAEL);
					referencedRules.add(ar);
				}
			}else{
				iAELs.add(returnLineForMissingEffectiveRule(iAE, crl, iDRRuleDef, crl.Amount__c));
			}

/*			if(cr.Currency__c != cr.Company__r.Comp_Currency__c){

				Id rfxId = returnRFX() != null ? returnRFX().Id : null;
				
				Decimal functDr = 0;
				Decimal functCr = 0;

				for(Accounting_Entry_Line__c a : iAELs){
					functCr += a.COMP_Functional_Currency_Amount_CR__c == null ? 0 : a.COMP_Functional_Currency_Amount_CR__c;
					functDr += a.COMP_Functional_Currency_Amount_DR__c == null ? 0 : a.COMP_Functional_Currency_Amount_DR__c;
				}

				Decimal rfx = functCr - functDr;

				Accounting_Entry_Line__c rfxAEL = new Accounting_Entry_Line__c(COMP_Transaction_Currency__c = cr.Currency__r.ISO_Code__c, 
																				COMP_Functional_Currency__c = cr.Company__r.Comp_Currency__r.ISO_Code__c,
																				Customer_Receipt_Line__c = crl.Id, 
																				GL_Account__c = rfxId, 
																				Source_Id__c = crl.Id + '|RFX', 
																				Accounting_Entry__r = new Accounting_Entry__c(source_key__c = iAE.source_Key__c), 
																				COMP_Functional_Currency_Amount_CR__c = 0, 
																				COMP_Functional_Currency_Amount_DR__c = 0,
																				COMP_Transaction_Currency_Amount_CR__c = 0, 
																				COMP_Transaction_Currency_Amount_DR__c = 0,
																				Subtransaction_Type__c = 'RFX');
				if(rfx <= 0){
					rfxAEL.COMP_Functional_Currency_Amount_CR__c = math.abs(rfx);
					iAELs.add(rfxAEL);
				}else if(rfx > 0){
					rfxAEL.COMP_Functional_Currency_Amount_DR__c = math.abs(rfx);
					iAELs.add(rfxAEL);
				}
			}*/

            mSourceDocAELs.put(crl.Id, iAELs);  
		}
		finish((Map<Id, sObject>)mCRs, (Map<Id, sObject>)mCRLs, mSourceDocAEs, mSourceDocAELs);

	}	
	
	
	private decimal findLineAmount(Customer_Receipt_Line__c crl, Accounting_Rule__c ar){
		decimal amount;		
		if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
			amount = (decimal)crl.get(ar.Amount_Reference__c);			
		}else{									
			if(crl.Amount__c != null){
				amount = crl.Amount__c;
			}	
		}
        return returnFinalLineAmount(amount,ar);
	}	
	
}