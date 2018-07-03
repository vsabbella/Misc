public with sharing class PaymentAccounting extends AccountingService{
public PaymentAccounting(){
		super('Payment__c');
	}	
	
	
	public override void execute(List<sObject> Paymentlines){
		
		string bjId = this.batchJobId;
		
		set<Id> PaymentIds = new set<Id>();
		for(Payment_line__c Paymentl : (List<Payment_line__c>)Paymentlines){
			PaymentIds.add(Paymentl.Payment__c);
		}
		
		set<string> PaymentFields = new set<string>{'ID', 'name',  'finalized__c', 'Finalized_Date__c','Posting_Date__c', 
								'From_Company__c', 'From_Company__r.id' ,'From_Company__r.Accounting_Standard__c','From_City__c', 'From_State__c', 'From_Country__c', 'From_Street__c', 'From_Zip_Code__c', 
								'To_City__c', 'To_Company__c', 'To_Company__r.id' ,'To_Company__r.Accounting_Standard__c', 'To_Country__c', 'To_State__c', 'To_Street__c', 'To_Zip_Code__c', 'Type__c','Transaction_Type__c ',
								'Transaction_Currency__c', 'currency__c', 'transaction_date__c', 'total_number_of_lines__c'};		
//		set<string> PaymentSubQueryfields = new set<string>{'( id, name, period__r.InterCompany_Subledger_Closed__c,company__c from Accounting_Entries__r where status__c=\'Active\')'};
		
//		string paymentQuery = 'SELECT ' + string.join(new List<string>(PaymentFields), ', ');
//		paymentQuery += ' FROM Payment__c WHERE Id IN :PaymentIds';
		
		set<string> PaymentLineFields = new set<string>{'id', 'name', 'Amount__c',  'Payment__c', 'type__c',
								'line_type__c', 'subtransaction_type__c', 'Payment__r.from_Company__r.Comp_Currency__c', 'Payment__r.Currency__c', 'Payment__r.transaction_date__c', 'Payment__r.to_Company__r.Comp_Currency__c'};
		PaymentLineFields.addAll(segmentReferences);	
		
//		string PaymentlQuery = 'SELECT ' + string.join(new List<string>(PaymentLineFields), ', ');
		map<Accounting_entry__c,FinishWrapper> fwrapMap = new map<Accounting_entry__c,FinishWrapper>();
        Map<Id, Payment__c> mPMTs = new Map<Id, Payment__c>();
		Map<Id, Payment_line__c> mPaymentls = new Map<Id, Payment_line__c>();
        try{
			string paymentWhereClause = ' Id IN :Paymentlines '
	                            + 'AND Finalized__c = true '
	                            + 'AND Payment__r.Transaction_Date__c != null '
	                            + 'AND Payment__r.Finalized_Date__c != null '
	                            + 'AND Payment__r.From_Company__c != null '
	                            + 'AND Payment__r.To_Company__c != null '
	                            + 'AND (Payment__r.Currency__c != null or Payment__r.Transaction_Currency__c != null) '
	                            + 'AND Payment__c NOT IN (SELECT Payment__c FROM Accounting_Entry__c WHERE Payment__c IN :PaymentIds AND related_accounting_entry__c = null  AND status__c=\'Active\' AND (Period__r.Closed__c = true OR Period__r.Permanently_Closed__c = true ) ) '
	                            + 'AND Id NOT IN (SELECT Payment_line__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Payment_line__c IN :Paymentlines AND Accounting_Entry__r.BatchJobId__c = :bjId) '
	                            + 'FOR UPDATE';
			                       
		    SOQLUtil soql = new SOQLUtil('Payment_line__c');
		    soql.addFields(PaymentLineFields);
		    soql.setWhereClause(paymentWhereClause);
		
        	//Grab Lines for this scope
        	mPaymentls = new Map<Id, Payment_line__c>((List<Payment_line__c>)Database.query(soql.getQuery()));
        	//Place the headers in a map for later reference
        	soql = new SOQLUtil('Payment__c');
		    SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');            	
            childRel.addFields ( new set<string>{'Id', 'Name','Period__r.InterCompany_Subledger_Closed__c', 'company__c'});
            childRel.setWhereClause ( 'status__c=\'Active\'');
 			soql.addChildRelationship(childRel);	
		    soql.addFields(PaymentFields);
		    soql.setWhereClause('Id IN :PaymentIds');
        	mPMTs = new Map<Id, Payment__c>((List<Payment__c>)Database.Query(soql.getQuery()));
		    system.debug('In execute ****   ' + 'mPaymentls:  ' +mPaymentls + 'mHeaders: ' + mPMTs);
        	findExistingDraftAEs(mPMTs.keySet());
  			loadEffRuleDetails(mPMTs);
        }catch(Exception ex){
        	throw ex;
        }
  		//Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
  		//This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
  		//This approach avoids handling all rules for the object and increases efficiency.
  				        
        List<DateTime> exchangeRateDates = new List<DateTime>();
        for(Payment_line__c Paymentline : mPaymentls.values()){
        	exchangeRateDates.add(Paymentline.Payment__r.transaction_date__c);
        }
        
        
        findExchangeRates(exchangeRateDates);
        	 			
 		for(Payment_line__c Paymentline : mPaymentls.values()){
 			    
 			map<id,string> compids = new map<id,string>();
 			Accounting_Entry__c iAE;
        	Payment__c payment = mPMTs.get(Paymentline.Payment__c);  
        	map<Id, Id> mCompanyAccountingStandards = new map<Id, Id>{	payment.To_Company__c => payment.To_Company__r.Accounting_Standard__c, 
        																payment.From_Company__c => payment.From_Company__r.Accounting_Standard__c};     	
        	compids.put(payment.From_Company__r.id,'Payor');
        	compids.put(payment.To_Company__r.id,'Payee');
        	String PaymentType = payment.Type__c;
        	
        	for (Accounting_Entry__c ae: payment.Accounting_Entries__r ){
        		if(ae.period__r.InterCompany_Subledger_Closed__c != null){
        		compids.remove(ae.company__c);
        		}
        	}
        	for(id companyid: compids.keyset()){
        		FinishWrapper ifwrap = new FinishWrapper();
        		iAE = generateAccountingEntry(payment, PaymentType, companyid);
	 			    
	 			List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
				string transType = iAE.Transaction_Type__c;
				string subTrans = (Paymentline.Subtransaction_Type__c != null && Paymentline.Subtransaction_Type__c != '') ? Paymentline.Subtransaction_Type__c : null;
				string Role = compids.get(companyid);
							
	 			//Create the rule definitions for this line
				AccountingRuleService.RuleDefinition iCRRuleDef = 
					new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, mCompanyAccountingStandards.get(companyid), 'Payment__c', transType, subTrans, Paymentline.Line_Type__c,Role);
				AccountingRuleService.RuleDefinition iDRRuleDef = 
					new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, mCompanyAccountingStandards.get(companyid), 'Payment__c', transType, subTrans, Paymentline.Line_Type__c,Role);
				AccountingRuleService.RuleDefinition iNARuleDef = 
					new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, mCompanyAccountingStandards.get(companyid), 'Payment__c', transType, subTrans, Paymentline.Line_Type__c,Role);
								
	 			if(mRuleDefs.containsKey(iNARuleDef)){
					//Do nothing when NA rules are identified
					for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
						referencedRules.add(ar);
					}

					if(!fwrapMap.containsKey(iAE)){
						ifwrap.SourceDocAE = iAE;
						ifwrap.SourceDocAELs = new List<Accounting_Entry_Line__c>();
	        			fwrapMap.put(iAE,ifwrap);
					}
					continue;
				}
					
				AccountingRuleService.RuleDefinition tempRuleDef;
				if(mRuleDefs.containsKey(iCRRuleDef)){
					Integer outDatedRuleCount =0;
					for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){					
						//KNDY-9545
						if((ar.Effective_End_Date__c!=null ? payment.transaction_date__c >= ar.Effective_End_Date__c:false)  || payment.transaction_date__c < ar.Effective_Start_Date__c  )
						{
							//ReturnLine for missing rule 
							if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
							{
						      iAELs.add(returnLineForMissingEffectiveRule(iAE, Paymentline, iCRRuleDef, Paymentline.Amount__c));							
							}
							outDatedRuleCount++;
							continue;
						}						
						decimal iCRAmt = findLineAmount(Paymentline, ar);
						if(iCRAmt == null){
							//continue;
						}	
						
						Accounting_Entry_Line__c iAEL = generateAccountingEntryLineWithRole(iAE, payment, Paymentline, ar, iCRAmt);
						iAEL.SubTransaction_Type__c = subTrans;
						iAEL.Line_Type__c = Paymentline.Line_Type__c;
						iAEL.Payment_line__c = Paymentline.Id;							
	
						SS.assignSegments(ar, Paymentline, iAEL);							
						populateLedgers(ar, iAE, iAEL);
						
						iAELs.add(iAEL);
						referencedRules.add(ar);
						tempRuleDef = iCRRuleDef;
					}	
				}else{
					iAELs.add(returnLineForMissingEffectiveRule(iAE, Paymentline, iCRRuleDef, Paymentline.Amount__c));
					tempRuleDef = iCRRuleDef;
				}						
					
				if(mRuleDefs.containsKey(iDRRuleDef)){
					Integer outDatedRuleCount =0;
					for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){
						if((ar.Effective_End_Date__c!=null ? payment.transaction_date__c >= ar.Effective_End_Date__c:false)    || payment.transaction_date__c < ar.Effective_Start_Date__c  )
						{
							//ReturnLine for missing rule
							if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
							{
						      iAELs.add(returnLineForMissingEffectiveRule(iAE, Paymentline, iDRRuleDef, Paymentline.Amount__c));							
							}
							outDatedRuleCount++;
							continue;
						}						
						decimal iDRAmt = findLineAmount(Paymentline, ar);
						if(iDRAmt == null){
							//continue;
						}			
						

						Accounting_Entry_Line__c iAEL = generateAccountingEntryLineWithRole(iAE, payment, Paymentline, ar, iDRAmt);
						iAEL.SubTransaction_Type__c = subTrans;
						iAEL.Line_Type__c = Paymentline.Line_Type__c;								
						iAEL.Payment_line__c = Paymentline.Id;						
						
						SS.assignSegments(ar, Paymentline, iAEL);	
						populateLedgers(ar, iAE, iAEL);
						
						iAELs.add(iAEL);
						referencedRules.add(ar);
						tempRuleDef = iDRRuleDef;
					}
				}else{
					iAELs.add(returnLineForMissingRule(iAE, Paymentline, iDRRuleDef, Paymentline.Amount__c));
					tempRuleDef = iDRRuleDef;
				}
				if(fwrapMap.containsKey(iAE)){
    				FinishWrapper ifwrapold = fwrapMap.get(iAE);
					ifwrapold.SourceDocAELs.addAll(iAELs);
				}
				else{				 
					ifwrap.SourceDocAE = iAE;
					ifwrap.SourceDocAELs = iAELs;
        			fwrapMap.put(iAE,ifwrap);
				}
				
        	}
 		}
        
        finish((Map<Id, sObject>)mPMTs, (Map<Id, sObject>)mPaymentls, fwrapMap.values());

    }

	
	private decimal findLineAmount(Payment_line__c Paymentline, Accounting_Rule__c ar){
		decimal amount;		
		if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
			amount = (decimal)Paymentline.get(ar.Amount_Reference__c);			
		}else{									
			if(Paymentline.Amount__c != null){
				amount = Paymentline.Amount__c;
			}
			else{
				amount = 0.0;
			}	
		}
        return returnFinalLineAmount(amount,ar);
    }	
}