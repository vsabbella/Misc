public with sharing class AccountingProcessFixedAssetDepreciation extends AccountingService{
    
    public AccountingProcessFixedAssetDepreciation(){
        super('Fixed_Asset_Depreciation__c');
    }
    
    public override void execute(List<sObject> sObjRecs){
        
        List<Accounting_Entry__c> aes = new List<Accounting_Entry__c>();
        List<Accounting_Entry_Line__c> aeLines = new List<Accounting_Entry_Line__c>();
        
        set<string> depreciationFields = new set<string>{'id', 'name', 'finalized__c', 'company__c', 'company__r.accounting_standard__c', 'value_upon_depreciation__c','transaction_type__c', 'subtransaction_type__c',
                                'depreciation_amount__c', 'depreciation_date__c', 'depreciation_key__c', 'depreciation_type__c', 'fixed_asset__c',
                                'Transaction_Currency__c', 'Currency__c','currency__r.ISO_Code__c' ,'Company__r.comp_currency__c','Company__r.comp_currency__r.ISO_Code__c','Company__r.consol_currency__c','Company__r.consol_currency__r.ISO_Code__c','Company__r.Stat_Currency__c','Company__r.Stat_Currency__r.ISO_Code__c', 'Company__r.Subs_Currency__c','Company__r.Subs_Currency__r.ISO_Code__c', 'finalized_date__c', 'transaction_date__c', 'posting_date__c'};
        depreciationFields.addAll(segmentReferences);

        SOQLUtil soql = new SOQLUtil('Fixed_Asset_Depreciation__c', TRUE);
        soql.addFields(depreciationFields);
        soql.setWhereClause('Id IN :sObjRecs '
                            + 'AND finalized__c = true '
                            + 'AND Company__c != null '
                            + 'AND Transaction_Date__c != null '
                            + 'AND (Currency__c != null or Transaction_Currency__c != null)'
                            + 'AND Historical__c = false ' 
                            + 'AND fixed_asset__r.fixed_asset_type__c = \'Accounting\' '
                            + 'AND Id NOT IN (SELECT Fixed_Asset_Depreciation__c FROM Accounting_Entry__c WHERE related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\'  AND (Period__r.Closed__c = true OR Period__r.Permanently_Closed__c = true OR Subledger_Closed__c = true)  )'
                            + 'FOR UPDATE');
        /*                       
        List<Fixed_Asset_Depreciation__c> finalDepreciations = new List<Fixed_Asset_Depreciation__c>();
        try{
            finalDepreciations = Database.query (depreciationQuery);
        }catch(Exception ex){
            throw ex;
        }
        */


        Map<Id, Accounting_Entry__c> mSourceDocAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mSourceDocAELs = new Map<Id, List<Accounting_Entry_Line__c>>();
        Map<Id, Fixed_Asset_Depreciation__c> mFADs = new Map<Id, Fixed_Asset_Depreciation__c>();

        try{
            //Place the headers in a map for later reference
            mFADs = new Map<Id, Fixed_Asset_Depreciation__c>((List<Fixed_Asset_Depreciation__c>)Database.Query(soql.getQuery()));
            findExistingDraftAEs(mFADs.keySet());
        }catch(Exception ex){
            throw ex;
        }

        //KNDY-9545 
        //Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
        //This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
        //This approach avoids handling all rules for the object and increases efficiency.
        loadEffRuleDetails(mFADs);
        
        system.debug(LOGGINGLEVEL.INFO,'mRuleDefs'+mRuleDefs);
        
        
        
               
        for(Fixed_Asset_Depreciation__c fad : mFADs.values()){ 
            //Process iff this fixed asset depreciation is finalized and has not already been accounted
            //Accounting_Entry__c iAE = generateAccountingEntry(fad, 'Fixed Asset Depreciation');
            //aes.add(iAE);

            Accounting_Entry__c iAE;
            //Fixed_Asset_Adjustment__c faa = mFAAs.get(mFAAs.Id);
            if(mSourceDocAEs.containsKey(fad.Id)){
                iAE = mSourceDocAes.get(fad.Id);
            }else{
                iAE = generateAccountingEntry(fad, 'Fixed Asset Depreciation');
                mSourceDocAEs.put(fad.Id, iAE);
            }


            
            List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
            string transType = iAE.Transaction_Type__c;
            string subtrans = fad.subtransaction_type__c;
                        
            //Create the rule definitions for this line
            AccountingRuleService.RuleDefinition iCRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, fad.Company__r.Accounting_Standard__c, 'Fixed_Asset_Depreciation__c', transType, subTrans, null);
            AccountingRuleService.RuleDefinition iDRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, fad.Company__r.Accounting_Standard__c, 'Fixed_Asset_Depreciation__c', transType, subTrans, null);
            AccountingRuleService.RuleDefinition iNARuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, fad.Company__r.Accounting_Standard__c, 'Fixed_Asset_Depreciation__c', transType, subTrans, null);
            
            
            if(mRuleDefs.containsKey(iNARuleDef)){
                //Do nothing when NA rules are identified
                for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
                    referencedRules.add(ar);
                }
                mSourceDocAELs.put(fad.Id, new List<Accounting_Entry_Line__c>());
                continue;
            }
            
            //system.debug(logginglevel.INFO, 'iCRRuleDef: ' + iCRRuleDef);
            //system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iCRRuleDef));
            if(mRuleDefs.containsKey(iCRRuleDef)){
                //system.debug(logginglevel.INFO, 'CR Rule Defs: ' + mRuleDefs.get(iCRRuleDef).size() + ' - '  + mRuleDefs.get(iCRRuleDef));
                Integer outDatedRuleCount =0;               
                for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){
                    //KNDY-9545
                    if((ar.Effective_End_Date__c!=null ? fad.transaction_date__c >= ar.Effective_End_Date__c:false)   || fad.transaction_date__c < ar.Effective_Start_Date__c  )
                    {
                        //ReturnLine for missing rule
                        if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
                        {
                          iAELs.add(returnLineForMissingEffectiveRule(iAE, fad, iCRRuleDef, fad.depreciation_amount__c));                           
                        }
                        outDatedRuleCount++;
                        continue;
                    }                   
                    decimal iCRAmt = findLineAmount(fad, ar);
                    if(iCRAmt == null){
                        //continue;
                    }
                    
                    Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, fad, fad, ar, iCRAmt);
                    //FIN-960 Fixed Asset AEs not getting generated with lines bug fix.
                    //iAEL.Amount_CR__c = 0;
                    //iAEL.Amount_DR__c = 0;
                    iAEL.SubTransaction_Type__c = subtrans;
                    
                    SS.assignSegments(ar, fad, iAEL);                           
                    
                    iAELs.add(iAEL);
                    referencedRules.add(ar);
                }   
            }else{
                iAELs.add(returnLineForMissingEffectiveRule(iAE, fad, iCRRuleDef, fad.depreciation_amount__c));
            }
                    
            //system.debug(logginglevel.INFO, 'iDRRuleDef: ' + iDRRuleDef);
            //system.debug(logginglevel.INFO, 'mRuleDefs contains: ' + mRuleDefs.containsKey(iDRRuleDef));
            if(mRuleDefs.containsKey(iDRRuleDef)){
                //system.debug(logginglevel.INFO, 'DR Rule Defs: ' + mRuleDefs.get(iDRRuleDef).size() + ' - '  + mRuleDefs.get(iDRRuleDef));
                Integer outDatedRuleCount =0;                               
                for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){
                    //KNDY-9545
                    if((ar.Effective_End_Date__c!=null ? fad.transaction_date__c >= ar.Effective_End_Date__c:false)    || fad.transaction_date__c < ar.Effective_Start_Date__c  )
                    {
                        //ReturnLine for missing rule
                        if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
                        {
                          iAELs.add(returnLineForMissingEffectiveRule(iAE, fad, iDRRuleDef, fad.depreciation_amount__c));                           
                        }
                        outDatedRuleCount++;
                        continue;
                    }                   
                    decimal iDRAmt = findLineAmount(fad, ar);
                    if(iDRAmt == null){
                        //continue;
                    }
                    
                    Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, fad, fad, ar, iDRAmt);
                    //FIN-960 Fixed Asset AEs not getting generated with lines bug fix.
                    //iAEL.Amount_CR__c = 0;
                    //iAEL.Amount_DR__c = 0;
                    iAEL.SubTransaction_Type__c = subtrans;
                    
                    SS.assignSegments(ar, fad, iAEL);                           
                    
                    iAELs.add(iAEL);
                    referencedRules.add(ar);
                }
            }else{
                iAELs.add(returnLineForMissingEffectiveRule(iAE, fad, iDRRuleDef, fad.depreciation_amount__c));
            }
            mSourceDocAELs.put(fad.Id, iAELs);    
            //aeLines.addAll(iAELs); 
            
        }
        finish((Map<Id, sObject>)mFADs, (Map<Id, sObject>)mFADs, mSourceDocAEs, mSourceDocAELs);
        
        //finish(finalDepreciations, aes, aeLines);
    }
    
    private decimal findLineAmount(Fixed_Asset_Depreciation__c fad, Accounting_Rule__c ar){
        decimal amount;
        if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
           amount = getAmtFromReference(fad,ar);
        }else{
            if(fad.depreciation_amount__c != null){
                amount = fad.depreciation_amount__c;
            }
        }
        return returnFinalLineAmount(amount,ar);
    }

    private decimal getAmtFromReference(Fixed_Asset_Depreciation__c fad, Accounting_Rule__c ar){
        try{
            Decimal amount;
            Integer referenceCount = ar.Amount_Reference__c.split('\\.').size();
            List<String> referenceList = ar.Amount_Reference__c.split('\\.');
            if(referenceCount == 1)
                amount = (decimal)fad.get(ar.Amount_Reference__c); 
            else if(referenceCount == 2)
                amount = (decimal)fad.getSObject(referenceList[0]).get(referenceList[1]); 
            else if(referenceCount == 3)
                amount = (decimal)fad.getSObject(referenceList[0]).getSObject(referenceList[1]).get(referenceList[2]); 
            else if(referenceCount == 4)
                amount = (decimal)fad.getSObject(referenceList[0]).getSObject(referenceList[1]).getSObject(referenceList[2]).get(referenceList[3]); 
            else if(referenceCount == 5)
                amount = (decimal)fad.getSObject(referenceList[0]).getSObject(referenceList[1]).getSObject(referenceList[2]).getSObject(referenceList[3]).get(referenceList[4]); 
            else{
                amount = (decimal)fad.get(ar.Amount_Reference__c); 
            }
            return amount;
        }catch(Exception ex){
            return (decimal)fad.get(ar.Amount_Reference__c); 
        }

    }
    
    public override Accounting_Entry_Line__c generateAccountingEntryLine(Accounting_Entry__c acctEntry, sObject fadh, sObject fadl, Accounting_Rule__c ar, decimal amount){
        
        Fixed_Asset_Depreciation__c fad = (Fixed_Asset_Depreciation__c)fadh;
        
        Accounting_Entry_Line__c ael = new Accounting_Entry_Line__c();
        ael.Transaction_Date__c = fad.Transaction_Date__c.date();
        ael.SubTransaction_Type__c = fad.subtransaction_type__c;
        ael.Line_Type__c = null;
        ael.Accounting_Entry__r = new Accounting_Entry__c(source_key__c = acctEntry.source_key__c);
        ael.Company__c = acctEntry.Company__c;
        ael.Source_ID__c = fad.Id;
        ael.Source_Name__c = fad.name;
        ael.Accounting_Rule__c = ar.Id;
        
        TransactionDateList.add(ael.Transaction_Date__c);
        
        decimal absAmount;
        if((amount == null))
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
            DateTime iFXDt = getLocalDateTime(datetime.valueOf(AccountingRuleService.getValue(ar.FX_Date_Path__c, fad)));
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