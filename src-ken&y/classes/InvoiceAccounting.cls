public with sharing class InvoiceAccounting extends AccountingService{
public InvoiceAccounting(){
		super('Invoice__c');
	}	
	
	
	public override void execute(List<sObject> InvoiceLines){
		
		string bjId = this.batchJobId;
		
		set<Id> InvIds = new set<Id>();
		for(Invoice_line__c invl : (List<Invoice_line__c>)InvoiceLines){
			InvIds.add(invl.Invoice__c);
		}
		
		set<string> InvoiceFields = new set<string>{'ID', 'name', 'Amount_Paid__c', 'Balance__c',  'finalized__c', 'Finalized_Date__c','Posting_Date__c',
								'From_Company__c', 'From_Company__r.id' ,'From_Company__r.Accounting_Standard__c','From_City__c', 'From_State__c', 'From_Country__c', 'From_Street__c', 'From_Zip_Code__c', 
								'To_City__c', 'To_Company__c', 'To_Company__r.id' , 'To_Company__r.Accounting_Standard__c','To_Country__c', 'To_State__c', 'To_Street__c', 'To_Zip_Code__c', 'Type__c','Transaction_Type__c ',
								'Total_Line_Amount__c','Transaction_Currency__c','currency__c', 'transaction_date__c', 'total_number_of_lines__c'};		
		
		
	//	string invQuery = 'SELECT ' + string.join(new List<string>(InvoiceFields), ', ');
	//	invQuery += ' FROM Invoice__c WHERE Id IN :InvIds';
		
		set<string> InvoiceLineFields = new set<string>{'id', 'name', 'Extended_Amount__c', 'Invoice__c', 'type__c', 
								'line_type__c', 'subtransaction_type__c', 'Invoice__r.from_Company__r.Comp_Currency__c', 'Invoice__r.Currency__c', 'Invoice__r.transaction_date__c', 'Invoice__r.to_Company__r.Comp_Currency__c'};
		InvoiceLineFields.addAll(segmentReferences);	
        Map<Id, Invoice__c> mINVs = new Map<Id, Invoice__c>();
		Map<Id, Invoice_line__c> mINVLs = new Map<Id, Invoice_line__c>();
		map<Accounting_entry__c,FinishWrapper> fwrapMap = new map<Accounting_entry__c,FinishWrapper>();
		
//		string InvlQuery = 'SELECT ' + string.join(new List<string>(InvoiceLineFields), ', ');
        try{
			String invWhereClause = 'Id IN :InvoiceLines '
	                            + 'AND Finalized__c = true '
	                            + 'AND Invoice__r.Transaction_Date__c != null '
	                            + 'AND Invoice__r.Finalized_Date__c != null '
	                            + 'AND Invoice__r.From_Company__c != null '
	                            + 'AND Invoice__r.To_Company__c != null '
	                            + 'AND (Invoice__r.Currency__c != null or Invoice__r.Transaction_Currency__c != null) '
	                            + 'AND Invoice__c NOT IN (SELECT Invoice__c FROM Accounting_Entry__c WHERE Invoice__c IN :InvIds AND related_accounting_entry__c = null  AND status__c=\'Active\''
	                            + 'AND (Period__r.Closed__c = true OR Period__r.Permanently_Closed__c = true)) '
	                            + 'AND Id NOT IN (SELECT Invoice_line__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Invoice_line__c IN :InvoiceLines AND Accounting_Entry__r.BatchJobId__c = :bjId) '
	                            + 'FOR UPDATE';
			                       
		    SOQLUtil soql = new SOQLUtil('Invoice_Line__c');
		    soql.addFields(InvoiceLineFields);
		    soql.setWhereClause(invWhereClause);
		
        	//Grab Lines for this scope
        	mINVLs = new Map<Id, Invoice_line__c>((List<Invoice_line__c>)Database.query(soql.getQuery()));
        	//Place the headers in a map for later reference
        	soql = new SOQLUtil('Invoice__c');
		    SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');            	
            childRel.addFields ( new set<string>{'Id', 'Name','Period__r.InterCompany_Subledger_Closed__c', 'company__c'});
            childRel.setWhereClause ( 'status__c=\'Active\'');
 			soql.addChildRelationship(childRel);	
		    soql.addFields(InvoiceFields);
		    soql.setWhereClause('Id IN :InvIds');
        	mINVs = new Map<Id, Invoice__c>((List<Invoice__c>)Database.Query(soql.getQuery()));
		    system.debug('In execute ****   ' + 'mINVLs:  ' +mINVLs + 'mHeaders: ' + mINVs);
        	findExistingDraftAEs(mINVs.keySet());
  			loadEffRuleDetails(mINVs);
        }catch(Exception ex){
        	throw ex;
        }
  		//Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
  		//This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
  		//This approach avoids handling all rules for the object and increases efficiency.
  				        
        List<DateTime> exchangeRateDates = new List<DateTime>();
        for(Invoice_line__c InvLine : mINVLs.values()){
        	exchangeRateDates.add(InvLine.Invoice__r.transaction_date__c);
        }
        
        
        findExchangeRates(exchangeRateDates);
        	 			
 		for(Invoice_line__c InvLine : mINVLs.values()){
 			    
 			map<id,string> compids = new map<id,string>();
 			Accounting_Entry__c iAE;
        	Invoice__c inv = mINVs.get(InvLine.Invoice__c);  
        	map<Id, Id> mCompanyAccountingStandards = new map<Id, Id>{	inv.To_Company__c => inv.To_Company__r.Accounting_Standard__c, 
        																inv.From_Company__c => inv.From_Company__r.Accounting_Standard__c};  
        	if(inv.Transaction_Type__c == 'Intercompany Investment'){     	
	        	compids.put(inv.From_Company__r.id,'Investee');
	        	compids.put(inv.To_Company__r.id,'Investor');
        	}else if(inv.Transaction_Type__c == 'Intercompany Cross Charge'){     	
	        	compids.put(inv.From_Company__r.id,'Payee');
	        	compids.put(inv.To_Company__r.id,'Payor');
        	}
        	for (Accounting_Entry__c ae: inv.Accounting_Entries__r ){
        		if(ae.period__r.InterCompany_Subledger_Closed__c != null){
        		compids.remove(ae.company__c);
        		}
        	}
        	
        	String invoiceType = inv.Type__c;
        	
        	for(id companyid: compids.keyset()){
        		FinishWrapper ifwrap = new FinishWrapper();
        		iAE = generateAccountingEntry(inv, invoiceType, companyid);
	 			    
	 			List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
				string transType = iAE.Transaction_Type__c;
				string subTrans = (InvLine.Subtransaction_Type__c != null && InvLine.Subtransaction_Type__c != '') ? InvLine.Subtransaction_Type__c : null;
				string Role = compids.get(companyid);
	 			//Create the rule definitions for this line
				AccountingRuleService.RuleDefinition iCRRuleDef = 
					new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, mCompanyAccountingStandards.get(companyid), 'Invoice__c', transType, subTrans, InvLine.Line_Type__c,Role);
				AccountingRuleService.RuleDefinition iDRRuleDef = 
					new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, mCompanyAccountingStandards.get(companyid), 'Invoice__c', transType, subTrans, InvLine.Line_Type__c,Role);
				AccountingRuleService.RuleDefinition iNARuleDef = 
					new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, mCompanyAccountingStandards.get(companyid), 'Invoice__c', transType, subTrans, InvLine.Line_Type__c,Role);
								
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
						if((ar.Effective_End_Date__c!=null ? inv.transaction_date__c >= ar.Effective_End_Date__c:false)  || inv.transaction_date__c < ar.Effective_Start_Date__c  )
						{
							//ReturnLine for missing rule 
							if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
							{
						      iAELs.add(returnLineForMissingEffectiveRule(iAE, InvLine, iCRRuleDef, InvLine.Extended_Amount__c));							
							}
							outDatedRuleCount++;
							continue;
						}						
						decimal iCRAmt = findLineAmount(InvLine, ar);
						if(iCRAmt == null){
							//continue;
						}	
						
						Accounting_Entry_Line__c iAEL = generateAccountingEntryLineWithRole(iAE, inv, InvLine, ar, iCRAmt);
						iAEL.SubTransaction_Type__c = subTrans;
						iAEL.Line_Type__c = InvLine.Line_Type__c;
						iAEL.Invoice_line__c = InvLine.Id;							
	
						SS.assignSegments(ar, InvLine, iAEL);							
						populateLedgers(ar, iAE, iAEL);
						
						iAELs.add(iAEL);
						referencedRules.add(ar);
						tempRuleDef = iCRRuleDef;
					}	
				}else{
					iAELs.add(returnLineForMissingEffectiveRule(iAE, InvLine, iCRRuleDef, InvLine.Extended_Amount__c));
					tempRuleDef = iDRRuleDef;
				}						
					
				if(mRuleDefs.containsKey(iDRRuleDef)){
					Integer outDatedRuleCount =0;
					for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){
						if((ar.Effective_End_Date__c!=null ? inv.transaction_date__c >= ar.Effective_End_Date__c:false)    || inv.transaction_date__c < ar.Effective_Start_Date__c  )
						{
							//ReturnLine for missing rule
							if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
							{
						      iAELs.add(returnLineForMissingEffectiveRule(iAE, InvLine, iDRRuleDef, InvLine.Extended_Amount__c));							
							}
							outDatedRuleCount++;
							continue;
						}						
						decimal iDRAmt = findLineAmount(InvLine, ar);
						if(iDRAmt == null){
							//continue;
						}			
						

						Accounting_Entry_Line__c iAEL = generateAccountingEntryLineWithRole(iAE, inv, InvLine, ar, iDRAmt);
						iAEL.SubTransaction_Type__c = subTrans;
						iAEL.Line_Type__c = InvLine.Line_Type__c;								
						iAEL.Invoice_line__c = InvLine.Id;						
						
						SS.assignSegments(ar, InvLine, iAEL);	
						populateLedgers(ar, iAE, iAEL);
						
						iAELs.add(iAEL);
						referencedRules.add(ar);
						tempRuleDef = iCRRuleDef;
					}
				}else{
					iAELs.add(returnLineForMissingRule(iAE, InvLine, iDRRuleDef, InvLine.Extended_Amount__c));
					tempRuleDef = iDRRuleDef;
				}
				if(fwrapMap.containsKey(iAE)){
    				FinishWrapper ifwrapold = fwrapMap.get(iAE);
					fwrapMap.get(iAE).SourceDocAELs.addAll(iAELs);
				}
				else{				 
					ifwrap.SourceDocAE = iAE;
					ifwrap.SourceDocAELs = iAELs;
        			fwrapMap.put(iAE,ifwrap);
				}
				
        	}
 		}
        
        finish((Map<Id, sObject>)mINVs, (Map<Id, sObject>)mINVLs, fwrapMap.values());

    }

	
	private decimal findLineAmount(Invoice_line__c InvLine, Accounting_Rule__c ar){
		decimal amount;		
		if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
			amount = (decimal)InvLine.get(ar.Amount_Reference__c);			
		}else{									
			if(InvLine.Extended_Amount__c != null){
				amount = InvLine.Extended_Amount__c;
			}	
			else{
				amount = 0.0;
			}	
		}
        return returnFinalLineAmount(amount,ar);
    }	
}