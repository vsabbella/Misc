public with sharing class BankTransactionGroupAccounting extends AccountingService {

    public BankTransactionGroupAccounting(){
         super('Bank_Transaction_Group__c');
    }
    
    public override void execute(List<sObject> bankTransactionList){
        string bjId = this.batchJobId;
        
        set<Id> btgIds = new set<Id>();
        for(Bank_Transaction__c bt : (List<Bank_Transaction__c>)bankTransactionList){
            btgIds.add(bt.Bank_Transaction_Group__c);
        }
        

        set<string> bankTrxnGrpFields = new set<string>{'id', 'name',  'transaction_type__c','finalized_date__c', 'transaction_date__c', 
                                                                'Transaction_Currency__c', 'currency__c', 'company__c', 'company__r.accounting_standard__c', 'total_number_of_lines__c', 'posting_date__c','void__c', 'Void_Date__c', 'Status__c'};
                                
        string bankTrxnGrpQuery = 'SELECT ' + string.join(new List<string>(bankTrxnGrpFields),', ');
        bankTrxnGrpQuery += ' FROM Bank_Transaction_Group__c WHERE Id IN :btgIds';
        
        set<string> bankTrxnFields = new set<string>{'id', 'name', 'line_type__c', 'subtransaction_type__c', 'amount__c', 'Bank_Transaction_Group__c'};

        bankTrxnFields.addAll(segmentReferences);
        
        string bankTrxnQuery = 'SELECT ' + string.join(new List<string>(bankTrxnFields), ', ');

        bankTrxnQuery       += ' FROM Bank_Transaction__c '
                            + 'WHERE id in :bankTransactionList '
                            + 'AND Finalized__c = true '
                            + 'AND Historical__c = false '
                            + 'AND Bank_Transaction_Group__r.Company__c != null '
                            + 'AND Bank_Transaction_Group__r.Transaction_Date__c != null '
                            + 'AND (Bank_Transaction_Group__r.Currency__c != null or Bank_Transaction_Group__r.Transaction_Currency__c != null) '
                            + 'AND Bank_Transaction_Group__r.Finalized_Date__c != null '
                            + 'AND Bank_Transaction_Group__c NOT IN (SELECT Bank_Transaction_Group__c FROM Accounting_Entry__c WHERE Bank_Transaction_Group__c IN :btgIds AND Related_Accounting_Entry__c = null  AND status__c=\'Active\' AND (period__r.closed__c = true OR period__r.permanently_closed__c = true OR period__r.AR_Subledger_Closed__c != null))' //FIN-889 AND batchjobid__c!=null and batchjobid__c!=:batchJobID) ' 
                            + 'AND Id NOT IN (SELECT Bank_Transaction__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Bank_Transaction__c IN :bankTransactionList AND Accounting_Entry__r.BatchJobId__c = :bjId) '
                            + 'FOR UPDATE';                       
        Map<Id, Accounting_Entry__c> mSourceDocAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mSourceDocAELs = new Map<Id, List<Accounting_Entry_Line__c>>();
        Map<Id, Bank_Transaction_Group__c> mBTGs = new Map<Id, Bank_Transaction_Group__c>();
        Map<Id, Bank_Transaction__c> mBTs = new Map<Id, Bank_Transaction__c>();
        try{
            //Grab Lines for this scope
            mBTs = new Map<Id, Bank_Transaction__c>((List<Bank_Transaction__c>)Database.query(bankTrxnQuery));
            //Place the headers in a map for later reference
            mBTGs = new Map<Id, Bank_Transaction_Group__c>((List<Bank_Transaction_Group__c>)Database.Query(bankTrxnGrpQuery));
            findExistingDraftAEs(mBTs.keySet());
        }catch(Exception ex){
            throw ex;
        }
        //KNDY-9545 
        //Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
        //This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
        //This approach avoids handling all rules for the object and increases efficiency.
        loadEffRuleDetails(mBTGs);
        
        system.debug(LOGGINGLEVEL.INFO,'mRuleDefs'+mRuleDefs);
         for(Bank_Transaction__c bt : mBTs.values()){
            
            Accounting_Entry__c iAE;
            Bank_Transaction_Group__c btg = mBTGs.get(bt.Bank_Transaction_Group__c);
            if(mSourceDocAEs.containsKey(bt.Bank_Transaction_Group__c)){
                iAE = mSourceDocAes.get(bt.Bank_Transaction_Group__c);
            }else{
                iAE = generateAccountingEntry(btg, btg.transaction_type__c);
                mSourceDocAEs.put(btg.Id, iAE);
            }
           
            List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();

            string transType = iAE.Transaction_Type__c;
            string subTrans = (bt.Subtransaction_Type__c != null && bt.Subtransaction_Type__c != '') ? bt.Subtransaction_Type__c : null;
            //TODO:Check why are we not doing above null check for linetype.
                        
            //Create the rule definitions for this line
            AccountingRuleService.RuleDefinition iCRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, btg.Company__r.Accounting_Standard__c, 'Bank_Transaction_Group__c', transType, subTrans, bt.Line_Type__c);
            AccountingRuleService.RuleDefinition iDRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, btg.Company__r.Accounting_Standard__c, 'Bank_Transaction_Group__c', transType, subTrans, bt.Line_Type__c);
            AccountingRuleService.RuleDefinition iNARuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, btg.Company__r.Accounting_Standard__c, 'Bank_Transaction_Group__c', transType, subTrans, bt.Line_Type__c);
            
            if(mRuleDefs.containsKey(iNARuleDef)){
                //system.debug(logginglevel.INFO, 'NA Rule Defs: ' + mRuleDefs.get(iNARuleDef).size() + ' - '  + mRuleDefs.get(iNARuleDef));
                //Do nothing when NA rules are identified
                for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
                    referencedRules.add(ar);
                }
                mSourceDocAELs.put(bt.Id, new List<Accounting_Entry_Line__c>());
                continue;
            }
                
                
            if(mRuleDefs.containsKey(iCRRuleDef)){
                Integer outDatedRuleCount =0;
                //system.debug(logginglevel.info,'CR Rule Defs: ' + mRuleDefs.get(iCRRuleDef).size() + ' - '  + mRuleDefs.get(iCRRuleDef));
                for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){

                    //KNDY-9545
                    if((ar.Effective_End_Date__c!=null ? btg.transaction_date__c >= ar.Effective_End_Date__c:false)   || btg.transaction_date__c < ar.Effective_Start_Date__c  )
                    {
                        //ReturnLine for missing rule
                        if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
                        {
                          iAELs.add(returnLineForMissingEffectiveRule(iAE, bt, iCRRuleDef, bt.Amount__c));                          
                        }
                        outDatedRuleCount++;
                        continue;
                    }
                    
                    decimal iCRAmt = findLineAmount(bt, ar);
                    if(iCRAmt == null){
                        //continue;
                    }
                    
                    Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, btg, bt, ar, iCRAmt);
                    iAEL.subtransaction_type__c = bt.subtransaction_type__c;
                    iAEL.Bank_Transaction__c = bt.Id;
                    
                    SS.assignSegments(ar, bt, iAEL);    
                                            
                    iAELs.add(iAEL);
                    referencedRules.add(ar);
                }   
            }else{
                iAELs.add(returnLineForMissingEffectiveRule(iAE, bt, iCRRuleDef, bt.Amount__c));
            }
                
                
                
            if(mRuleDefs.containsKey(iDRRuleDef)){
                Integer outDatedRuleCount =0;
                //system.debug(logginglevel.info, 'DR Rule Defs: ' + mRuleDefs.get(iDRRuleDef).size() + ' - '  + mRuleDefs.get(iDRRuleDef));
                for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){
                    //KNDY-9545
                    if((ar.Effective_End_Date__c!=null ? btg.transaction_date__c >= ar.Effective_End_Date__c:false)    || btg.transaction_date__c < ar.Effective_Start_Date__c  )
                    {
                        //ReturnLine for missing rule
                        if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
                        {
                          iAELs.add(returnLineForMissingEffectiveRule(iAE, bt, iDRRuleDef, bt.Amount__c));                          
                        }
                        outDatedRuleCount++;
                        continue;
                    }                   
                    decimal iDRAmt = findLineAmount(bt, ar);
                    if(iDRAmt == null){
                        //continue;
                    }
                    
                    Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, btg, bt, ar, iDRAmt);
                    iAEL.subtransaction_type__c = bt.subtransaction_type__c;
                    iAEL.Bank_Transaction__c = bt.Id;
                    
                    SS.assignSegments(ar, bt, iAEL);    
                                            
                    //system.debug(logginglevel.info,'iAEL: ' + iAEL);
                    iAELs.add(iAEL);
                    referencedRules.add(ar);
                }
            }else{
                iAELs.add(returnLineForMissingEffectiveRule(iAE, bt, iDRRuleDef, bt.Amount__c));
            }

            mSourceDocAELs.put(bt.Id, iAELs);   
                            
        }
                
        finish((Map<Id, sObject>)mBTGs, (Map<Id, sObject>)mBTs, mSourceDocAEs, mSourceDocAELs);

    }
    private decimal findLineAmount(Bank_Transaction__c bt, Accounting_Rule__c ar){
        decimal amount;
        if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
            amount = (decimal)bt.get(ar.Amount_Reference__c); 
        }else{
            if(bt.Amount__c != null){
                amount = bt.Amount__c;
            }
        }
        if((amount == null)){
			amount = null;
		}else if(amount ==  null){
			amount = 0;
		}
        return amount;
    }
}