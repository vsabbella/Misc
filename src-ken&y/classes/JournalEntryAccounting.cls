public with sharing class JournalEntryAccounting extends AccountingService {
	
	public JournalEntryAccounting(){
		super('Journal_Entry__c');
	}
	
	public override void execute(List<sObject> journalEntryLines){
		
		string bjId = this.batchJobId;
		//Note: This requires the source doc header field is specified in the input lines, is there a way to avoid this requirement?
		
		set<Id> jeIds = new set<Id>();
		for(Journal_Entry_Line__c jel : (List<Journal_Entry_Line__c>)journalEntryLines){
			jeIds.add(jel.journal_entry__c);
		}

		set<string> jeFields = new set<string>{'ID', 'Name', 'GL_Date_time__c', 'Company__c',  'Company__r.Accounting_Standard__c','Transaction_Currency__c', 'Currency__c', 'Currency__r.ISO_Code__c','Transaction_Type__c', 'Supplier__c', 'Customer__c', 'Transaction_Date__c', 'Finalized_Date__c', 'Auto_Reverse__c' ,	
												'Transaction_Date__c', 'Finalized_Date__c', 'Auto_Reverse__c', 'Total_Number_of_Lines__c','Description__c',
								'Period__c' , 'Period__r.Period_Start__c', 'Period__r.Period_End__c' , 'Type__c', 'Void__c', 'Void_Date__c', 'Posting_Date__c','Company__r.comp_currency__c','Company__r.comp_currency__r.ISO_Code__c','Company__r.consol_currency__c','Company__r.Stat_Currency__c', 'Company__r.Subs_Currency__c'};
								
						
		set<string> jeLineFields = new set<string>{'id', 'name', 'journal_entry__c', 'amount_cr__c', 'amount_dr__c', 'subtransaction_type__c', 'line_type__c', 'Description__c'};
		jeLineFields.addAll(segmentReferences);		
		
        Map<Id, Accounting_Entry__c> mSourceDocAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mSourceDocAELs = new Map<Id, List<Accounting_Entry_Line__c>>();
        Map<Id, Journal_Entry__c> mJEs = new Map<Id, Journal_Entry__c>();
		Map<Id, Journal_Entry_Line__c> mJELs = new Map<Id, Journal_Entry_Line__c>();
        try{
        	//Grab Lines for this scope
        	String whereClause = 'id in :journalEntryLines '
	                            + 'AND Finalized__c = true '
	                            + 'AND Journal_Entry__r.Company__c != null '
	                            + 'AND Journal_Entry__r.GL_Date_Time__c != null '
	                            + 'AND (Journal_Entry__r.Currency__c != null or Journal_Entry__r.Transaction_Currency__c != null) '
	                            + 'AND Journal_Entry__c NOT IN (SELECT Journal_Entry__c FROM Accounting_Entry__c WHERE Journal_Entry__c IN :jeIds AND related_accounting_entry__c = null  AND status__c=\'Active\' AND (Period__r.Closed__c = true OR Period__r.Permanently_Closed__c = true OR period__r.GL_Close__c != null))' //FIN-889 AND batchjobid__c!=null and batchjobid__c!=:batchJobID) '
	            				+ 'AND Id NOT IN (SELECT Journal_Entry_Line__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Journal_Entry_Line__c IN :journalEntryLines AND Accounting_Entry__r.BatchJobId__c = :bjId) '
	            				+ 'FOR UPDATE';
        
		    SOQLUtil soql = new SOQLUtil('Journal_Entry_Line__c');
		    soql.addFields(jeLineFields);
		    soql.setWhereClause(whereClause);
	    
        	mJELs = new Map<Id, Journal_Entry_Line__c>((List<Journal_Entry_Line__c>)Database.query(soql.getQuery()));
        	
        	//Place the headers in a map for later reference
        	whereClause = 'Id IN :jeIds';
        
		    soql = new SOQLUtil('Journal_Entry__c');
		    soql.addFields(jeFields);
		    soql.setWhereClause(whereClause);
		    
        	mJEs = new Map<Id, Journal_Entry__c>((List<Journal_Entry__c>)Database.query(soql.getQuery()));
        	
        	findExistingDraftAEs(mJEs.keySet());
        }catch(Exception ex){
        	throw ex;
        }   
        
        set<Id>compIds = new set<Id>();

        for(Journal_Entry__c j : mJEs.values()){
        	compIds.add(j.Company__c);
        }

        populateCompanyMap(compIds);
        
  		//KNDY-9545 
  		//Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
  		//This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
  		//This approach avoids handling all rules for the object and increases efficiency.
  		loadEffRuleDetails(mJEs);
  		
		system.debug(LOGGINGLEVEL.INFO,'mRuleDefs'+mRuleDefs); 
		     
        set<Id> autoReverseJELs = new set<Id>();

        for(Journal_Entry_Line__c jel : mJELs.values()){
        	
        	Accounting_Entry__c iAE;
        	Journal_Entry__c je = mJEs.get(jel.journal_entry__c);
        	if(mSourceDocAEs.containsKey(jel.journal_entry__c)){
        		iAE = mSourceDocAes.get(jel.journal_entry__c);
        	}else{
        		iAE = generateAccountingEntry(je, je.Transaction_Type__c);
        		mSourceDocAEs.put(je.Id, iAE);
        	}
        	
        	if(je.Auto_Reverse__c){
        		autoReverseJELs.add(jel.Id);
        	}
        	
        	List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
    			
			string transType = iAE.Transaction_Type__c;
            string fxTransType = '';
			
            if(transType.equalsIgnoreCase('PL RFX') || transType.equalsIgnoreCase('UFX')){
                fxTransType = transType.toUpperCase();
            }else if(transType.equalsIgnoreCase('Accrual - Manual') &&  je.Description__c != null && je.Description__c.equals('UFX')){
                fxTransType = 'UFX';
            }
			
			String subtrans = null;
	        subtrans = jel.SubTransaction_Type__c;
			
			//Create the rule definitions for this line
			AccountingRuleService.RuleDefinition iCRRuleDef = 
				new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, je.Company__r.Accounting_Standard__c, 'Journal_Entry__c', transType, subTrans, jel.Line_Type__c);
			AccountingRuleService.RuleDefinition iDRRuleDef = 
				new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, je.Company__r.Accounting_Standard__c,'Journal_Entry__c', transType, subTrans, jel.Line_Type__c);
			AccountingRuleService.RuleDefinition iNARuleDef = 
				new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, je.Company__r.Accounting_Standard__c,'Journal_Entry__c', transType, subTrans, jel.Line_Type__c);
			
			if(mRuleDefs.containsKey(iNARuleDef)){
				//Do nothing when NA rules are identified
				for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
					referencedRules.add(ar);
				}
				mSourceDocAELs.put(jel.Id, new List<Accounting_Entry_Line__c>());
				continue;
			}
			
			if(jel.Amount_CR__c != null && jel.Amount_CR__c != 0){
    			if(mRuleDefs.containsKey(iCRRuleDef)){
  				   Integer outDatedRuleCount =0;    				
    				for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){
	   					//KNDY-9545
						if((ar.Effective_End_Date__c!=null ? je.transaction_date__c >= ar.Effective_End_Date__c:false)   || je.transaction_date__c < ar.Effective_Start_Date__c  )
						{
							//ReturnLine for missing rule
							if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
							{
						      iAELs.add(returnLineForMissingEffectiveRule(iAE, jel, iCRRuleDef, jel.Amount_CR__c));							
							}
							outDatedRuleCount++;
							continue;
						} 					
	    				decimal iCRAmt = findLineAmount(jel, ar);
	    					//system.debug(logginglevel.info,'iCRAmt:'+iCRAmt);
    					if(iCRAmt == null){
    						continue;
    					}
    					
    					Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, je, jel, ar, iCRAmt);
    					iAEL.SubTransaction_Type__c = subTrans;
    					iAEL.Line_Type__c = jel.Line_Type__c;
    					iAEL.Journal_Entry_Line__c = jel.Id;
                        iAEL.Description__c = jel.Description__c;
                        
    					SS.assignSegments(ar, jel, iAEL);	

    					populateLedgers(ar, iAE, iAEL);

                        if(String.isNotBlank(fxTransType)){
                            //is fx journal entry
                            iAEL.COMP_Transaction_Currency__c = je.Currency__r.ISO_Code__c;
                            iAEL.COMP_Functional_Currency__c =  je.Company__r.comp_currency__r.ISO_Code__c;
                            iAEL.SubTransaction_Type__c = fxTransType;
                        	iAEL.COMP_Transaction_Currency_Amount_CR__c = 0;
                        	iAEL.COMP_Transaction_Currency_Amount_DR__c = 0;

                            iAEL.Amount_DR__c = 0;
                            iAEL.Amount_CR__c = 0;
                        }

    					iAELs.add(iAEL);
    					referencedRules.add(ar);
    				}	
    			}else{
    				
					  iAELs.add(returnLineForMissingEffectiveRule(iAE, jel, iCRRuleDef, jel.Amount_CR__c));								    			
   				
    			}
        	}
        	
        	if(jel.Amount_DR__c != null && jel.Amount_DR__c != 0){
    			if(mRuleDefs.containsKey(iDRRuleDef)){
  				   Integer outDatedRuleCount =0;    				    				
    				for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){   
    	   			    //KNDY-9545
						if((ar.Effective_End_Date__c!=null ? je.transaction_date__c >= ar.Effective_End_Date__c:false)   || je.transaction_date__c < ar.Effective_Start_Date__c  )
						{
							//ReturnLine for missing rule
							if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
							{
						      iAELs.add(returnLineForMissingEffectiveRule(iAE, jel, iDRRuleDef, jel.Amount_DR__c));							
							}
							outDatedRuleCount++;
							continue;
						} 					
    					decimal iDRAmt = findLineAmount(jel, ar);
    					if(iDRAmt == null){
    						continue;
    					}
    					
    					Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, je, jel, ar, iDRAmt);
    					iAEL.SubTransaction_Type__c = subTrans;
    					iAEL.Line_Type__c = jel.Line_Type__c;
    					iAEL.Journal_Entry_Line__c = jel.Id;
    					iAEL.Description__c = jel.Description__c;

    					SS.assignSegments(ar, jel, iAEL);	

    					populateLedgers(ar, iAE, iAEL);

                        if(String.isNotBlank(fxTransType)){
                            //is fx journal entry
                            iAEL.SubTransaction_Type__c = fxTransType;
                            iAEL.COMP_Transaction_Currency__c = je.Currency__r.ISO_Code__c;
                            iAEL.COMP_Functional_Currency__c =  je.Company__r.comp_currency__r.ISO_Code__c;
                        	iAEL.COMP_Transaction_Currency_Amount_CR__c = 0;
                        	iAEL.COMP_Transaction_Currency_Amount_DR__c = 0;

                            iAEL.Amount_DR__c = 0;
                            iAEL.Amount_CR__c = 0;
                        }

    					iAELs.add(iAEL);
    					referencedRules.add(ar);
					}
    			}else{

					  iAELs.add(returnLineForMissingEffectiveRule(iAE, jel, iDRRuleDef, jel.Amount_DR__c));								    			

    			}
        	}
			
			
        	mSourceDocAELs.put(jel.Id, iAELs);
        }
        
        finish((Map<Id, sObject>)mJEs, (Map<Id, sObject>)mJELs, mSourceDocAEs, mSourceDocAELs);

        
        system.debug('autoReverseJELs: ' + autoReverseJELs.size() + ' - '  + autoReverseJELs);
        if(autoReverseJELs.size() > 0){
        	
            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Accounting_Entry__c'
            });
            soql.setWhereClause('Journal_Entry_Line__c IN :autoReverseJELs AND Related_Accounting_Entry_Line__c = null');
            List<Accounting_Entry_Line__c> aels = Database.query(soql.getQuery());



        	for(Accounting_Entry_Line__c ael : aels){
        		voidAEIds.add(ael.accounting_entry__c);
        	}
        }
                          
	}
	
	private decimal findLineAmount(Journal_Entry_Line__c jel, Accounting_Rule__c ar){
		decimal amount;
		if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
			amount = (decimal)jel.get(ar.Amount_Reference__c); 
		}else if(ar.rule_type__c.equalsIgnoreCase('CR')){
			amount = jel.amount_CR__c;
		}else if (ar.rule_type__c.equalsIgnoreCase('DR')){
			amount = jel.amount_DR__c;
		}else {
			amount = 0;
		}
		return amount;
	}
	
}