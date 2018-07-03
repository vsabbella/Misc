/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class CustomerInvoiceAccounting extends AccountingService {
	
	public CustomerInvoiceAccounting(){
		super('Customer_Invoice__c');
	}
	
	private set<Id> headerAllowancesCalculated = new set<Id>();
	
	public override void execute(List<sObject> customerInvoiceLines){
		
		string bjId = this.batchJobId;
		//Note: This requires the source doc header field is specified in the input lines, is there a way to avoid this requirement?
		
		set<Id> ciIds = new set<Id>();
		for(Customer_Invoice_Line__c cil : (List<Customer_Invoice_Line__c>)customerInvoiceLines){
			ciIds.add(cil.customer_invoice__c);
		}
		
		set<string> custInvFields = new set<string>{'id', 'name', 'date_invoiced__c', 'company__c', 'company__r.accounting_standard__c', 'finalized__c', 'total_sales_tax__c', 'currency__c', 'Currency__r.ISO_Code__c', 'void__c', 'Transaction_Currency__c',
        						'apply_to_invoice__c',  'invoice_type__c','transaction_type__c', 'bill_to_customer__c', 'finalized_date__c','transaction_date__c', 'total_number_of_lines__c', 'posting_date__c','Company__r.comp_currency__c','Company__r.comp_currency__r.ISO_Code__c','Company__r.consol_currency__c','Company__r.consol_currency__r.ISO_Code__c','Company__r.Stat_Currency__c', 'Company__r.Stat_Currency__r.ISO_Code__c','Company__r.Subs_Currency__c','Company__r.Subs_Currency__r.ISO_Code__c'};
		
		set<string> custInvLineFields = new set<string>{'id', 'name', 'discount_percent__c', 'extended_price__c', 'line_type__c', 'subtransaction_type__c',
                                'product__r.item__c', 'quantity_shipped__c', 'product__r.item__r.class__r.type__c',
                                'unit_price__c', 'shipment_line__r.sales_order_line__r.sales_order__r.id',
                                'customer_invoice__r.total_sales_tax__c', 'shipment_line__r.sales_order__r.type__c', 'shipment_line__c','Sales_Tax__c',
                                'shipment_line__r.sales_order__r.company__c', 'customer_invoice__r.date_invoiced__c', 'customer_invoice__r.Company__r.comp_currency__c','customer_invoice__r.Company__r.comp_currency__r.ISO_Code__c','customer_invoice__r.finalized__c', 'customer_invoice__r.sales_order__r.type__c'};
		custInvLineFields.addAll(segmentReferences);
		
		string whereClause = 'id in :customerInvoiceLines '
                            + 'AND Finalized__c = true '
                            + 'AND Historical__c = false '
                            + 'AND Customer_Invoice__r.Company__c != null '
                            + 'AND Customer_Invoice__r.Transaction_Date__c != null '
                            + 'AND (Customer_Invoice__r.Currency__c != null or Customer_Invoice__r.Transaction_Currency__c != null ) '
                            + 'AND Customer_Invoice__r.Finalized_Date__c != null '
                            + 'AND Customer_Invoice__r.Transaction_Date__c != null '
                            + 'AND Customer_Invoice__c NOT IN (SELECT Customer_Invoice__c FROM Accounting_Entry__c WHERE Customer_Invoice__c IN :ciIds AND Related_Accounting_Entry__c = null AND status__c=\'Active\' AND (period__r.closed__c = true OR period__r.permanently_closed__c = true OR period__r.AR_Subledger_Closed__c != null))' //FIN-889 AND batchjobid__c!=null and batchjobid__c!=:batchJobID) ' 
            				+ 'AND Id NOT IN (SELECT Customer_Invoice_Line__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Customer_Invoice_Line__c IN :customerInvoiceLines AND Accounting_Entry__r.BatchJobId__c = :bjId) '
            				+ 'FOR UPDATE';
        SOQLUtil ciQuery = new SOQLUtil('Customer_Invoice__c', false);
        ciQuery.addFields(custInvFields);
        ciQuery.setWhereClause('Id IN :ciIds');

        SOQLUtil cilQuery = new SOQLUtil('Customer_Invoice_Line__c', false);
        cilQuery.addFields(custInvLineFields);
        cilQuery.setWhereClause(whereClause);
         Map<Id, Accounting_Entry__c> mSourceDocAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mSourceDocAELs = new Map<Id, List<Accounting_Entry_Line__c>>();
        Map<Id, Customer_Invoice__c> mCIs = new Map<Id, Customer_Invoice__c>();
		Map<Id, Customer_Invoice_Line__c> mCILs = new Map<Id, Customer_Invoice_Line__c>();
		
        try{
        	//Grab Lines for this scope
        	mCILs = new Map<Id, Customer_Invoice_Line__c>((List<Customer_Invoice_Line__c>)Database.query(cilQuery.getQuery()));
        	//Place the headers in a map for later reference
        	mCIs = new Map<Id, Customer_Invoice__c>((List<Customer_Invoice__c>)Database.Query(ciQuery.getQuery()));
        	findExistingDraftAEs(mCIs.keySet());
        	
	  		//KNDY-9545 
	  		//Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
	  		//This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
	  		//This approach avoids handling all rules for the object and increases efficiency.
	  		loadEffRuleDetails(mCIs);
	  		
			system.debug(LOGGINGLEVEL.INFO,'mRuleDefs'+mRuleDefs);	
			
        	updateDistroDefs(mCIs.values(), mCILs.values());
        	
        }catch(Exception ex){
        	throw ex;
        }

		        
        for(Customer_Invoice_Line__c cil : mCILs.values()){
            	
        	Accounting_Entry__c iAE;
        	Customer_Invoice__c ci = mCIs.get(cil.customer_invoice__c);
        	
        	String invoiceType = ci.Invoice_Type__c;
/*			if(invoiceType.toLowerCase() == 'manual'){
				invoiceType = 'Customer Invoice';
			}
			
*/        	if(mSourceDocAEs.containsKey(cil.customer_invoice__c)){
        		iAE = mSourceDocAes.get(cil.customer_invoice__c);
        	}else{
        		iAE = generateAccountingEntry(ci, invoiceType);
        		iAE.Customer__c = ci.Bill_To_Customer__c;
        		mSourceDocAEs.put(ci.Id, iAE);
        	}
        	
        	List<Accounting_Entry_Line__c> iHeaderAELs = new List<Accounting_Entry_Line__c>();
        	List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
        	
			if(!headerAllowancesCalculated.contains(ci.Id)){
				headerAllowancesCalculated.add(ci.Id);
	        	//Create Header DD, loop through and assign on rules
	            if(mAllowances.containsKey(ci.Id)){
	            	for(Allowance_Applied__c aa : mAllowances.get(ci.Id)){
	            		
	            		string transType = iAE.Transaction_Type__c;
/*		    			if(transType.equalsIgnoreCase('Ship Invoice') || transType.equalsIgnoreCase('Manual')){
		    				transType = 'Customer Invoice';
		    			}
	            		
*/	            		AccountingRuleService.RuleDefinition iNAAllowRuleDef = new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, ci.Company__r.Accounting_Standard__c, 'Customer_Invoice__c', transType, null, null);
	            		AccountingRuleService.DistributionDefinition iNADD = new AccountingRuleService.DistributionDefinition(iNAAllowRuleDef, AccountingRuleService.DistributionType.HEADER, aa.Allowance_Class__c);
	            		
	            		AccountingRuleService.RuleDefinition iCRAllowRuleDef = new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, ci.Company__r.Accounting_Standard__c, 'Customer_Invoice__c', transType, null, null);
	            		AccountingRuleService.DistributionDefinition iCRDD = new AccountingRuleService.DistributionDefinition(iCRAllowRuleDef, AccountingRuleService.DistributionType.HEADER, aa.Allowance_Class__c);
	            		AccountingRuleService.RuleDefinition iDRAllowRuleDef = new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, ci.Company__r.Accounting_Standard__c, 'Customer_Invoice__c', transType, null, null);
	            		AccountingRuleService.DistributionDefinition iDRDD = new AccountingRuleService.DistributionDefinition(iDRAllowRuleDef, AccountingRuleService.DistributionType.HEADER, aa.Allowance_Class__c);
	            		
	            		if(mDistroDefs.containsKey(iNADD)){
	            			for(Accounting_Rule__c ar : mDistroDefs.get(iNADD)){
								referencedRules.add(ar);
							}
	            			continue;
	            		}
	            		
						if(mDistroDefs.containsKey(iCRDD)){
							Integer outDatedRuleCount =0;
														
	            			for(Accounting_Rule__c ar : mDistroDefs.get(iCRDD)){
								//KNDY-9545
								if((ar.Effective_End_Date__c!=null ? ci.transaction_date__c >= ar.Effective_End_Date__c:false)    || ci.transaction_date__c < ar.Effective_Start_Date__c  )
								{
									//ReturnLine for missing rule
									if(outDatedRuleCount ==mDistroDefs.get(iCRDD).size()-1)
									{
								      iHeaderAELs.add(returnLineForMissingEffectiveDistroDefRule(iAE, ci, iCRDD, aa));							
									}
									outDatedRuleCount++;
									continue;
								}	            				
	            				decimal iCRAmt;
	            				if(ar.amount_reference__c != null && ar.amount_reference__c != ''){
	            					iCRAmt = decimal.valueOf(AccountingRuleService.getValue(ar.amount_reference__c, aa));
	            				}else{
	            					iCRAmt = aa.Allowance_Amount__c;
	            				}
	            				
		    					if(iCRAmt == null){
		    						//continue;
		    					}
		    					
		    					Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, ci, null, ar, iCRAmt);
								iAEL.allocation_id__c = aa.Id;
		    					SS.assignSegments(ar, aa, iAEL);
		    					iHeaderAELs.add(iAEL);	
	            			}	
	            		}else{//KNDY-10073 Associate missing effective rule to headerAELs.
							iHeaderAELs.add(returnLineForMissingEffectiveDistroDefRule(iAE, ci, iCRDD, aa));
	            		}
	            		
	
	            		if(mDistroDefs.containsKey(iDRDD)){
							Integer outDatedRuleCount =0;								            			
            			
	            			for(Accounting_Rule__c ar : mDistroDefs.get(iDRDD)){
							    //KNDY-9545
								if((ar.Effective_End_Date__c!=null ? ci.transaction_date__c >= ar.Effective_End_Date__c:false)   || ci.transaction_date__c < ar.Effective_Start_Date__c  )
								{
									//ReturnLine for missing rule
									if(outDatedRuleCount ==mDistroDefs.get(iDRDD).size()-1)
									{
								      iHeaderAELs.add(returnLineForMissingEffectiveDistroDefRule(iAE, ci, iDRDD, aa));							
									}
									outDatedRuleCount++;
									continue;
								}	
	            				decimal iDRAmt;
	            				if(ar.amount_reference__c != null && ar.amount_reference__c != ''){
	            					iDRAmt = decimal.valueOf(AccountingRuleService.getValue(ar.amount_reference__c, aa));
	            				}else{
	            					iDRAmt = aa.Allowance_Amount__c;
	            				}
		    					
		    					if(iDRAmt == null){
		    						//continue;
		    					}
	
		    					
								Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, ci, null, ar, iDRAmt);					    					
								iAEL.allocation_id__c = aa.Id;
		    					SS.assignSegments(ar, aa, iAEL);
		    					iHeaderAELs.add(iAEL);		
	            			}	
	            		}else{//KNDY-10073 Associate missing effective rule to headerAELS.
							iHeaderAELs.add(returnLineForMissingEffectiveDistroDefRule(iAE, ci, iDRDD, aa));
	            		}
	            	}
	
	            }
			}
    			
    			
    			
			string transType = iAE.Transaction_Type__c;
/*			if(transType.equalsIgnoreCase('Ship Invoice') || transType.equalsIgnoreCase('Manual')){
				transType = 'Customer Invoice';
			}
			
*/			string subTrans = (cil.Subtransaction_Type__c != null && cil.Subtransaction_Type__c != '') ? cil.Subtransaction_Type__c : null;
			
			//Create the rule definitions for this line
			AccountingRuleService.RuleDefinition iCRRuleDef = 
				new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, ci.Company__r.Accounting_Standard__c, 'Customer_Invoice__c', transType, subTrans, cil.Line_Type__c);
			AccountingRuleService.RuleDefinition iDRRuleDef = 
				new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, ci.Company__r.Accounting_Standard__c,'Customer_Invoice__c', transType, subTrans, cil.Line_Type__c);
			AccountingRuleService.RuleDefinition iNARuleDef = 
				new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, ci.Company__r.Accounting_Standard__c,'Customer_Invoice__c', transType, subTrans, cil.Line_Type__c);
			
			//system.debug('iCRRuleDef: ' + iCRRuleDef);
			//system.debug('mRuleDefs contains: ' + mRuleDefs.containsKey(iCRRuleDef));
    			
			if(mRuleDefs.containsKey(iNARuleDef)){
				//system.debug(logginglevel.INFO, 'NA Rule Defs: ' + mRuleDefs.get(iNARuleDef).size() + ' - '  + mRuleDefs.get(iNARuleDef));
				//Do nothing when NA rules are identified
				for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
					referencedRules.add(ar);
				}
				mSourceDocAELs.put(cil.Id, new List<Accounting_Entry_Line__c>());
				continue;
			}
			
			if(mRuleDefs.containsKey(iCRRuleDef)){
				//system.debug(logginglevel.info,'CR Rule Defs: ' + mRuleDefs.get(iCRRuleDef).size() + ' - '  + mRuleDefs.get(iCRRuleDef));
				Integer outDatedRuleCount =0;			
				for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){
					//KNDY-9545
					if((ar.Effective_End_Date__c!=null ? ci.transaction_date__c >= ar.Effective_End_Date__c:false)   || ci.transaction_date__c < ar.Effective_Start_Date__c  )
					{
						//ReturnLine for missing rule
						if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
						{
					      iAELs.add(returnLineForMissingEffectiveRule(iAE, cil, iCRRuleDef, cil.Extended_Price__c));							
						}
						outDatedRuleCount++;
						continue;
					}
										
					decimal iCRAmt = findLineAmount(cil, ar);
					if(iCRAmt == null){
						//continue;
					}
					
					Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, ci, cil, ar, iCRAmt);
					iAEL.SubTransaction_Type__c = subTrans;
					iAEL.Line_Type__c = cil.Line_Type__c;
					iAEL.Customer_Invoice_Line__c = cil.Id;
					
					SS.assignSegments(ar, cil, iAEL);	
					//system.debug(logginglevel.info,'iAEL: ' + iAEL);
					iAELs.add(iAEL);
					referencedRules.add(ar);
					
					//Create line DD, loop through and assign on rules
				}	
			}else{
				iAELs.add(returnLineForMissingEffectiveRule(iAE, cil, iCRRuleDef, cil.Extended_Price__c));
			}
			
			
			//system.debug('iDRRuleDef: ' + iDRRuleDef);
			//system.debug('mRuleDefs contains: ' + mRuleDefs.containsKey(iDRRuleDef));
			
			if(mRuleDefs.containsKey(iDRRuleDef)){
				
				Integer outDatedRuleCount =0;							
				for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){

					//KNDY-9545
					if((ar.Effective_End_Date__c!=null ? ci.transaction_date__c >= ar.Effective_End_Date__c:false)   || ci.transaction_date__c < ar.Effective_Start_Date__c  )
					{
						//ReturnLine for missing rule
						
						if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
						{
					      iAELs.add(returnLineForMissingEffectiveRule(iAE, cil, iDRRuleDef, cil.Extended_Price__c));							
						}
						outDatedRuleCount++;
						continue;
					}					
					decimal iDRAmt = findLineAmount(cil, ar);
					if(iDRAmt == null){
						//continue;
					}
					
					Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, ci, cil, ar, iDRAmt);
					iAEL.SubTransaction_Type__c = subTrans;
					iAEL.Line_Type__c = cil.Line_Type__c;
					iAEL.Customer_Invoice_Line__c = cil.Id;
					
					SS.assignSegments(ar, cil, iAEL);	
					//system.debug(logginglevel.info,'iAEL: ' + iAEL);
					iAELs.add(iAEL);
					referencedRules.add(ar);
				}
			}else{
				iAELs.add(returnLineForMissingEffectiveRule(iAE, cil, iDRRuleDef, cil.Extended_Price__c));
			}
			
			mSourceDocAELs.put(ci.Id, iHeaderAELs);    
			    
		    if(mAllowances.containsKey(cil.Id)){
            	for(Allowance_Applied__c aa : mAllowances.get(cil.Id)){
            		
            		AccountingRuleService.DistributionDefinition iNADD = new AccountingRuleService.DistributionDefinition(iNARuleDef, AccountingRuleService.DistributionType.LINE, aa.Allowance_Class__c);
            		AccountingRuleService.DistributionDefinition iCRDD = new AccountingRuleService.DistributionDefinition(iCRRuleDef, AccountingRuleService.DistributionType.LINE, aa.Allowance_Class__c);
            		AccountingRuleService.DistributionDefinition iDRDD = new AccountingRuleService.DistributionDefinition(iDRRuleDef, AccountingRuleService.DistributionType.LINE, aa.Allowance_Class__c);
            		
            		if(mDistroDefs.containsKey(iNADD)){
            			for(Accounting_Rule__c ar : mDistroDefs.get(iNADD)){
							referencedRules.add(ar);
						}
            			continue;
            		}
            		
					if(mDistroDefs.containsKey(iCRDD)){
						Integer outDatedRuleCount=0;
            			for(Accounting_Rule__c ar : mDistroDefs.get(iCRDD)){
		  					//KNDY-9545
							if((ar.Effective_End_Date__c!=null ? ci.transaction_date__c >= ar.Effective_End_Date__c:false)   || ci.transaction_date__c < ar.Effective_Start_Date__c  )
							{
								//ReturnLine for missing rule
								if(outDatedRuleCount ==mDistroDefs.get(iCRDD).size()-1)
								{
							      iAELs.add(returnLineForMissingEffectiveDistroDefRule(iAE, cil, iCRDD, aa));							
								}
								outDatedRuleCount++;
								continue;
							}	            				
            				decimal iCRAmt;
            				if(ar.amount_reference__c != null && ar.amount_reference__c != ''){
            					iCRAmt = decimal.valueOf(AccountingRuleService.getValue(ar.amount_reference__c, aa));
            				}else{
            					iCRAmt = aa.Allowance_Amount__c;
            				}
            				
	    					if(iCRAmt == null){
	    						//continue;
	    					}
	    					
	    					Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, ci, cil, ar, iCRAmt);
	    					iAEL.allocation_id__c = aa.Id;
	    					iAEL.customer_invoice_line__c = cil.id;
	    					SS.assignSegments(ar, aa, iAEL);
	    					iAELs.add(iAEL);	
            			}	
            		}else{
						iAELs.add(returnLineForMissingEffectiveDistroDefRule(iAE, cil, iCRDD, aa));
            		}
	            		

            		if(mDistroDefs.containsKey(iDRDD)){
            			Integer outDatedRuleCount = 0;
            			for(Accounting_Rule__c ar : mDistroDefs.get(iDRDD)){
		  					//KNDY-9545
							if((ar.Effective_End_Date__c!=null ? ci.transaction_date__c >= ar.Effective_End_Date__c:false)  || ci.transaction_date__c < ar.Effective_Start_Date__c  )
							{
								//ReturnLine for missing rule
								if(outDatedRuleCount ==mDistroDefs.get(iDRDD).size()-1)
								{
							      iAELs.add(returnLineForMissingEffectiveDistroDefRule(iAE, cil, iDRDD, aa));							
								}
								outDatedRuleCount++;
								continue;
							}	          				
            				decimal iDRAmt;
            				if(ar.amount_reference__c != null && ar.amount_reference__c != ''){
            					iDRAmt = decimal.valueOf(AccountingRuleService.getValue(ar.amount_reference__c, aa));
            				}else{
            					iDRAmt = aa.Allowance_Amount__c;
            				}
	    					
	    					if(iDRAmt == null){
	    						//continue;
	    					}
	    					
	    					Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, ci, cil, ar, iDRAmt);
	    					iAEL.allocation_id__c = aa.Id;
	    					iAEL.customer_invoice_line__c = cil.id;
	    					SS.assignSegments(ar, aa, iAEL);
	    					iAELs.add(iAEL);		
            			}	
            		}else{
						iAELs.add(returnLineForMissingEffectiveDistroDefRule(iAE, cil, iDRDD, aa));
            		}
            	}
            }
			    
		    mSourceDocAELs.put(cil.Id, iAELs);
			    
		}
		
        finish((Map<Id, sObject>)mCIs, (Map<Id, sObject>)mCILs, mSourceDocAEs, mSourceDocAELs);
           
	}
	
	private decimal findLineAmount(Customer_Invoice_Line__c cil, Accounting_Rule__c ar){
		decimal amount;
		if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
			amount = (decimal)cil.get(ar.Amount_Reference__c); 
		}else{
			if(cil.Extended_Price__c != null){
				amount = cil.Extended_Price__c;
			}
		}
        return returnFinalLineAmount(amount,ar);
	}
	
	/*public enum DistributionType {HEADER, LINE}
	public class DistributionDefinition{
		
		public AccountingRuleService.RuleDefinition ruleDef;
		public string distro;
		public DistributionType distroType;
		
		public DistributionDefinition(AccountingRuleService.RuleDefinition ruleDef, Accounting_Rule__c ar){
			this.ruleDef = ruleDef;
			this.distro = ar.Allocation__c;
			if(ar.Allocation_Type__c == 'Header'){
				this.distroType = DistributionType.HEADER;
			}else if(ar.Allocation_Type__c == 'Line'){
				this.distroType = DistributionType.LINE;
			} 
		}
		
		public DistributionDefinition(AccountingRuleService.RuleDefinition ruleDef, DistributionType distroType, string distro){
			this.ruleDef = ruleDef;
			this.distro = distro;
			this.distroType = distroType;
		}
		
		
		public boolean equals(object compareTo){
			DistributionDefinition compare = (DistributionDefinition)compareTo;
			if(this.ruleDef.equals(compare.ruleDef)
					&& this.distro == compare.distro
					&& this.distroType == compare.distroType){
				return true;	
			}else{
				return false;
			}
		}
		
		public integer hashCode(){
			return HashCodeGenerator.getHashCode(this);  
		}
	}*/
	
	map<Id, List<Allowance_Applied__c>> mAllowances = new Map<Id, List<Allowance_Applied__c>>();
	map<AccountingRuleService.DistributionDefinition, List<Accounting_Rule__c>> mDistroDefs = new Map<AccountingRuleService.DistributionDefinition, List<Accounting_Rule__c>>();
	void updateDistroDefs(List<sObject> customerInvoices, List<Customer_Invoice_Line__c> customerInvoiceLines){
		
		set<string> queryFields = new set<string>{'id','name',  'rule_type__c', 'transaction__c', 'subtransaction_type__c', 'line_type__c', 'object_name__c', 'Allocation__c', 'Allocation_Type__c', 'Expected_Sign__c',
														'accounting_standard__c', 'amount_reference__c','company_ledger__c','consolidation_ledger__c','statutory_ledger__c','subsidiary_ledger__c','Role__c',
														'Effective_Start_Date__c','Effective_End_Date__c', 'FX_Date_Path__c', 'FX_Flow__c','Suppress_Zero_Amount_Lines__c','Raise_Exceptions_for_Blank_Amounts__c'};
			queryFields.addAll(AccountingRuleService.getSegmentFields());
			string whereClause = 'Object_Name__c = \'Customer_Invoice__c\'';
			whereClause += ' AND (Allocation__c != null AND Allocation__c != \'\')';
			whereClause += ' AND Allocation_Type__c != null';

			DateTime startTxnDate = getStartTxnDate(SDTransactionDateList);
			DateTime endTxnDate   = getEndTxnDate(SDTransactionDateList);		
			if(endTxnDate!=null)
			{
				whereClause += ' AND Effective_Start_Date__c <=:endTxnDate ';
			}	

			if(startTxnDate!=null)
			{
				whereClause += ' AND (Effective_End_Date__c >=:startTxnDate OR Effective_End_Date__c=NULL )';
			}

			SOQLUtil soql = new SOQLUtil('Accounting_Rule__c', false);
			soql.addFields(queryFields);
			soql.setWhereClause(whereClause);

		List<Accounting_Rule__c> ciRules = Database.Query(soql.getQuery());
		//Set the rule up in the super as well
		mRules.putAll(ciRules);
		
		set<string> allowanceQueryFields = new set<string>{'id', 'Allowance_Class__c', 'name', 'allowance_rule2__r.name', 'customer_invoice2__c', 
																'customer_invoice_line__c', 'allowance_amount__c'};
		for(Accounting_Rule__c ar : ciRules){
			for(Segment_Definition__c sd : Segment_Definition__c.getAll().values()){
				if(sd.Accounting_Rule_Reference_Value__c != null && sd.Accounting_Rule_Reference_Value__c != ''){
					string segmentPath = (string)ar.get(sd.Accounting_Rule_Reference_Value__c);
					if(segmentPath != null && segmentPath != ''){
						allowanceQueryFields.add(segmentPath.toLowerCase());
					}
				}
			}
			if(ar.amount_reference__c != null && ar.amount_reference__c != ''){
				allowanceQueryFields.add(ar.amount_reference__c.toLowerCase());
			}
		}
		
		List<Customer_Invoice__c> refInvoices = customerInvoices;
		List<Customer_Invoice_Line__c> refInvoiceLines = customerInvoiceLines;
		string allowanceWhereClause = 'Customer_Invoice2__c IN :refInvoices';
		allowanceWhereClause += ' OR Customer_Invoice_Line__c IN :refInvoiceLines';

		SOQLUtil allowanceQuery = new SOQLUtil('Allowance_Applied__c', false);
		allowanceQuery.addFields(allowanceQueryFields);
		allowanceQuery.setWhereClause(allowanceWhereClause);
		List<Allowance_Applied__c> allowanceApplieds = Database.query(allowanceQuery.getQuery());

		for(Allowance_Applied__c aa : allowanceApplieds){
			Id refId;
			if(aa.customer_invoice_line__c != null){
				refId = aa.customer_invoice_line__c;
			}else if(aa.Customer_Invoice2__c != null){
				refId = aa.Customer_Invoice2__c;
			}
			
			if(refId != null){
				if(mAllowances.containsKey(refId)){
					mAllowances.get(refId).add(aa);
				}else{
					mAllowances.put(refId, new List<Allowance_Applied__c>{aa});
				}
			}
			
		}
		system.debug('mAllowances: ' + mAllowances);
		
		for(Accounting_Rule__c ar : ciRules){
			AccountingRuleService.RuleDefinition iRD = new AccountingRuleService.RuleDefinition(ar);
			AccountingRuleService.DistributionDefinition iDD = new AccountingRuleService.DistributionDefinition(iRD, ar);
			if(mDistroDefs.containsKey(iDD)){
				mDistroDefs.get(iDD).add(ar);
			}else{
				mDistroDefs.put(iDD, new List<Accounting_Rule__c>{ar});
			}
		}
		
	}
	
}