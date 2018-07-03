public with sharing class AccountingProcessFixedAssetAdjustments extends AccountingService{
    
    public AccountingProcessFixedAssetAdjustments(){
        super('Fixed_Asset_Adjustment__c');
    }
     
    public override void execute(List<sObject> sObjRecs){
        
        List<Accounting_Entry__c> aes = new List<Accounting_Entry__c>();
        List<Accounting_Entry_Line__c> aeLines = new List<Accounting_Entry_Line__c>();
        
        set<string> adjustmentFields = new set<string>{'id', 'name', 'finalized__c', 'company__c', 'company__r.accounting_standard__c', 'type__c', 'transaction_type__c','subtransaction_type__c',
                                                            'amount__c', 'fixed_asset__c', 'transaction_currency__c', 'currency__c', 'Currency__r.ISO_Code__c' ,'adjustment_date__c' ,'finalized_date__c', 'transaction_date__c', 'posting_date__c','Company__r.comp_currency__c','Company__r.comp_currency__r.ISO_Code__c','Company__r.consol_currency__c','Company__r.consol_currency__r.ISO_Code__c','Company__r.Stat_Currency__c','Company__r.Stat_Currency__r.ISO_Code__c', 'Company__r.Subs_Currency__c','Company__r.Subs_Currency__r.ISO_Code__c'};
        adjustmentFields.addAll(segmentReferences);

        SOQLUtil soql = new SOQLUtil('Fixed_Asset_Adjustment__c', TRUE);
        soql.addFields(adjustmentFields);
        soql.setWhereClause('Id IN :sObjRecs '
                            + 'AND finalized__c = true ' 
                            + 'AND Company__c != null '
                            + 'AND Transaction_Date__c != null '
                            + 'AND (Currency__c != null or transaction_currency__c != null) '
                            + 'AND Historical__c = false ' 
                            + 'AND Id NOT IN (SELECT Fixed_Asset_Adjustment__c FROM Accounting_Entry__c WHERE related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\'  AND (Period__r.Closed__c = true OR Period__r.Permanently_Closed__c = true OR Subledger_Closed__c = true)  )'
                            + 'AND fixed_asset__r.fixed_asset_type__c = \'Accounting\' '
                            + 'FOR UPDATE');
        /*                       
        List<Fixed_Asset_Adjustment__c> finalAdjustments = new List<Fixed_Asset_Adjustment__c>();
        try{
            finalAdjustments = Database.query (adjustmentQuery);
        }catch(Exception ex){
            throw ex;
        }
        */
        Map<Id, Accounting_Entry__c> mSourceDocAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mSourceDocAELs = new Map<Id, List<Accounting_Entry_Line__c>>();
        Map<Id, Fixed_Asset_Adjustment__c> mFAAs = new Map<Id, Fixed_Asset_Adjustment__c>();
        //Map<Id, Bank_File_Line__c> mBFLs = new Map<Id, Bank_File_Line__c>();
        try{
            //Place the headers in a map for later reference
            mFAAs = new Map<Id, Fixed_Asset_Adjustment__c>((List<Fixed_Asset_Adjustment__c>)Database.Query(soql.getQuery()));
            findExistingDraftAEs(mFAAs.keySet());
        }catch(Exception ex){
            throw ex;
        }
        //KNDY-9545 
        //Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
        //This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
        //This approach avoids handling all rules for the object and increases efficiency.
        loadEffRuleDetails(mFAAs);
        
        system.debug(LOGGINGLEVEL.INFO,'mRuleDefs'+mRuleDefs);
        
        for(Fixed_Asset_Adjustment__c faa : mFAAs.values()){

            Accounting_Entry__c iAE;
            //Fixed_Asset_Adjustment__c faa = mFAAs.get(mFAAs.Id);
            if(mSourceDocAEs.containsKey(faa.Id)){
                iAE = mSourceDocAes.get(faa.Id);
            }else{
                iAE = generateAccountingEntry(faa, 'Fixed Asset Adjustment');
                mSourceDocAEs.put(faa.Id, iAE);
            }

        
            //Process iff this fixed asset depreciation is finalized and has not already been accounted
            //Accounting_Entry__c iAE = generateAccountingEntry(faa, 'Fixed Asset Adjustment');
            //aes.add(iAE);
            
            List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
            string transType = iAE.Transaction_Type__c;
            string subtrans = faa.subtransaction_type__c;
            
            //Create the rule definitions for this line
            AccountingRuleService.RuleDefinition iCRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, faa.Company__r.Accounting_Standard__c, 'Fixed_Asset_Adjustment__c', transType, subTrans, null);
            AccountingRuleService.RuleDefinition iDRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, faa.Company__r.Accounting_Standard__c, 'Fixed_Asset_Adjustment__c', transType, subTrans, null);
            AccountingRuleService.RuleDefinition iNARuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, faa.Company__r.Accounting_Standard__c, 'Fixed_Asset_Adjustment__c', transType, subTrans, null);
            
            
            if(mRuleDefs.containsKey(iNARuleDef)){
                //Do nothing when NA rules are identified
                for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
                    referencedRules.add(ar);
                }
                mSourceDocAELs.put(faa.Id, new List<Accounting_Entry_Line__c>());
                continue;
            }
            
            //system.debug(logginglevel.INFO, 'iCRRuleDef: ' + iCRRuleDef);
            //system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iCRRuleDef));
            if(mRuleDefs.containsKey(iCRRuleDef)){
                Integer outDatedRuleCount =0;               
                //system.debug(logginglevel.INFO, 'CR Rule Defs: ' + mRuleDefs.get(iCRRuleDef).size() + ' - '  + mRuleDefs.get(iCRRuleDef));
                for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){
                    
                    //KNDY-9545
                    if((ar.Effective_End_Date__c!=null ? faa.transaction_date__c >= ar.Effective_End_Date__c:false)    || faa.transaction_date__c < ar.Effective_Start_Date__c  )
                    {
                        //ReturnLine for missing rule
                        if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
                        {
                          iAELs.add(returnLineForMissingEffectiveRule(iAE, faa, iCRRuleDef, faa.Amount__c));                            
                        }
                        outDatedRuleCount++;
                        continue;
                    }                   
                    decimal iCRAmt = findLineAmount(faa, ar);
                    if(iCRAmt == null){
                        //continue;
                    }
                    
                    Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, faa, faa, ar, iCRAmt);
                    iAEL.Subtransaction_Type__c = subtrans;
                    
                    SS.assignSegments(ar, faa, iAEL);                           
                    
                    iAELs.add(iAEL);
                    referencedRules.add(ar);
                }   
            }else{
                iAELs.add(returnLineForMissingEffectiveRule(iAE, faa, iCRRuleDef, faa.Amount__c));
            }
            
            
            //system.debug(logginglevel.INFO, 'iDRRuleDef: ' + iDRRuleDef);
            //system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iDRRuleDef));
            if(mRuleDefs.containsKey(iDRRuleDef)){
                //system.debug(logginglevel.INFO, 'DR Rule Defs: ' + mRuleDefs.get(iDRRuleDef).size() + ' - '  + mRuleDefs.get(iDRRuleDef));
                Integer outDatedRuleCount =0;
                for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){
                    //KNDY-9545
                    if((ar.Effective_End_Date__c!=null ? faa.transaction_date__c >= ar.Effective_End_Date__c:false)   || faa.transaction_date__c < ar.Effective_Start_Date__c  )
                    {
                        //ReturnLine for missing rule
                        if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
                        {
                          iAELs.add(returnLineForMissingEffectiveRule(iAE, faa, iDRRuleDef, faa.Amount__c));                            
                        }
                        outDatedRuleCount++;
                        continue;
                    }                       
                    decimal iDRAmt = findLineAmount(faa, ar);
                    if(iDRAmt == null){
                        //continue;
                    }
                    
                    Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, faa, faa, ar, iDRAmt);
                    iAEL.Subtransaction_Type__c = subtrans;
                    
                    SS.assignSegments(ar, faa, iAEL);                           
                    
                    iAELs.add(iAEL);
                    referencedRules.add(ar);
                }
            }else{
                iAELs.add(returnLineForMissingEffectiveRule(iAE, faa, iDRRuleDef, faa.Amount__c));
            }
            mSourceDocAELs.put(faa.Id, iAELs);  
            //aeLines.addAll(iAELs);
        }
        system.debug('aes: ' + aes);
        system.debug('aeLines: ' + aeLines);
        //finish(finalAdjustments, aes, aeLines);
        finish((Map<Id, sObject>)mFAAs, (Map<Id, sObject>)mFAAs, mSourceDocAEs, mSourceDocAELs);

    }
    
    private decimal findLineAmount(Fixed_Asset_Adjustment__c faa, Accounting_Rule__c ar){
        decimal amount;
        if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
            amount = getAmtFromReference(faa,ar);
        }else{
            if(faa.Amount__c != null){
                amount = faa.Amount__c;
            }
        }
        return returnFinalLineAmount(amount,ar);
    }
    
    private decimal getAmtFromReference(Fixed_Asset_Adjustment__c faa, Accounting_Rule__c ar){
        try{
            Decimal amount;
            Integer referenceCount = ar.Amount_Reference__c.split('\\.').size();
            List<String> referenceList = ar.Amount_Reference__c.split('\\.');
            if(referenceCount == 1)
                amount = (decimal)faa.get(ar.Amount_Reference__c); 
            else if(referenceCount == 2)
                amount = (decimal)faa.getSObject(referenceList[0]).get(referenceList[1]); 
            else if(referenceCount == 3)
                amount = (decimal)faa.getSObject(referenceList[0]).getSObject(referenceList[1]).get(referenceList[2]); 
            else if(referenceCount == 4)
                amount = (decimal)faa.getSObject(referenceList[0]).getSObject(referenceList[1]).getSObject(referenceList[2]).get(referenceList[3]); 
            else if(referenceCount == 5)
                amount = (decimal)faa.getSObject(referenceList[0]).getSObject(referenceList[1]).getSObject(referenceList[2]).getSObject(referenceList[3]).get(referenceList[4]); 
            else{
                amount = (decimal)faa.get(ar.Amount_Reference__c); 
            }
            return amount;
        }catch(Exception ex){
            return (decimal)faa.get(ar.Amount_Reference__c); 
        }

    }

    public override Accounting_Entry_Line__c generateAccountingEntryLine(Accounting_Entry__c acctEntry, sObject faah, sObject faal, Accounting_Rule__c ar, decimal amount){
        
        Fixed_Asset_Adjustment__c faa = (Fixed_Asset_Adjustment__c)faah;
        
        Accounting_Entry_Line__c ael = new Accounting_Entry_Line__c();
        ael.Transaction_Date__c = faa.Transaction_Date__c.date();
        ael.SubTransaction_Type__c = faa.subtransaction_type__c;
        ael.Line_Type__c = null;
        ael.Accounting_Entry__r = new Accounting_Entry__c(source_key__c = acctEntry.source_key__c);
        ael.Company__c = acctEntry.Company__c;
        ael.Source_ID__c = faa.Id;
        ael.Source_Name__c = faa.name;
        ael.Accounting_Rule__c = ar.Id;
        
        TransactionDateList.add(ael.Transaction_Date__c);
        
        decimal absAmount;
        if((amount == null) )
         	{absAmount = null;}
        else if(amount != null){
        	absAmount = math.abs(amount);}
        else{
        	absAmount = 0;}
        
        //FIN-368
        if(ar.Expected_Sign__c == 'Positive' || ar.Expected_Sign__c == null){
            if(amount >= 0){
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
            if(amount <= 0){
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
        
        ael.FX_Flow__c = ar.FX_Flow__c;
        if(ar.FX_Date_Path__c != null && ar.FX_Date_Path__c != ''){
            DateTime iFXDt = getLocalDateTime(datetime.valueOf(AccountingRuleService.getValue(ar.FX_Date_Path__c, faa)));
            ael.FX_Date__c = iFXDt;
            //TODO: Refactor so the explicit call for currencies does not need to be made from worker class - this super method can collect the trxn and fx dates incrementally
            // The exchange dates may not be known ahead of time, consider reselecting based on FX dates found here
            TransactionDateList.add(ael.FX_Date__c);
            TransactionDateList.add(iFXDt);
        }else{
            ael.FX_Date__c = acctEntry.Transaction_Date__c;
        }
        
        return ael;
    }
    
}