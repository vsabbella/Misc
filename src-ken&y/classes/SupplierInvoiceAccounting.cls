public with sharing class SupplierInvoiceAccounting extends AccountingService {
    
    public SupplierInvoiceAccounting(){
        super('Supplier_Invoice__c');
    }
    
    public override void execute(List<sObject> supplierInvoiceLines){
        
        string bjId = this.batchJobId;
        //Note: This requires the source doc header field is specified in the input lines, is there a way to avoid this requirement?
        
        set<Id> siIds = new set<Id>();
        for(Supplier_Invoice_Line__c sil : (List<Supplier_Invoice_Line__c>)supplierInvoiceLines){
            siIds.add(sil.supplier_invoice__c);
        }
        

        set<string> suppInvFields = new set<string>{'id', 'name', 'finalized__c', 'date_invoiced__c', 'void__c', 'void_date__c', 'company__c', 'company__r.accounting_standard__c','Transaction_Currency__c', 'currency__c', 'Currency__r.ISO_Code__c', 'Company__r.comp_currency__c','company__r.comp_currency__r.ISO_Code__c','Company__r.consol_currency__c','Company__r.Stat_Currency__c', 'Company__r.Subs_Currency__c', 'amount_due__c',
                                'invoice_type__c', 'transaction_type__c', 'credit_memo_amount__c', 'supplier__c', 'finalized_date__c', 'transaction_date__c', 'total_number_of_lines__c', 'posting_date__c'};
        
        set<string> suppInvLineFields = new set<string>{'id', 'name',  'purchase_order_line__c', 'unit_price__c', 'miscellaneous__c', 'item__r.class__r.type__c',
                                'currency__c', 'extended_cost__c', 'purchase_order__c', 'purchase_order_line__r.company__c', 'supplier_invoice__c', 'supplier_invoice__r.company__c',
                                'quantity_received__c', 'quantity_returned_to_supplier__c', 'quantity_returned_to_supplier_for_credit__c',
                                'invoice_quantity__c', 'invoice_quantity_to_stock__c', 'subtransaction_type__c',
                                'purchase_order_line__r.unit_price__c', 'item__r.source__c', 'line_type__c', 'purchase_order_line__r.delivery_facility__c', 'Supplier_Invoice__r.transaction_date__c',
                                'supplier_invoice__r.currency__c', 'supplier_invoice__r.company__r.comp_currency__c', 'supplier_invoice__r.company__r.comp_currency__r.ISO_Code__c', 'supplier_invoice__r.currency__r.ISO_code__c'};
        suppInvLineFields.addAll(segmentReferences);
        
        Map<Id, Accounting_Entry__c> mSourceDocAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mSourceDocAELs = new Map<Id, List<Accounting_Entry_Line__c>>();
        Map<Id, Supplier_Invoice__c> mSIs = new Map<Id, Supplier_Invoice__c>();
        Map<Id, Supplier_Invoice_Line__c> mSILs = new Map<Id, Supplier_Invoice_Line__c>();
        
        try{
            String silWhereClause = 'Id in :supplierInvoiceLines '
                                + 'AND Finalized__c = true '
                                + 'AND Historical__c = false ' 
                                + 'AND Supplier_Invoice__r.Company__c != null '
                                + 'AND Supplier_Invoice__r.Transaction_Date__c != null ' 
                                + 'AND Supplier_Invoice__r.Finalized_Date__c != null '
                                + 'AND (Supplier_Invoice__r.Currency__c != null or Supplier_Invoice__r.Transaction_Currency__c != null) '
                                + 'AND Supplier_Invoice__c NOT IN (SELECT Supplier_Invoice__c FROM Accounting_Entry__c WHERE Supplier_Invoice__c IN :siIds AND related_accounting_entry__c = null  AND status__c=\'Active\' AND (Period__r.Closed__c = true OR Period__r.Permanently_Closed__c = true OR Subledger_Closed__c = true) ) ' //FIN-889  AND batchjobid__c!=null and batchjobid__c!=:batchJobID
                                + 'AND Id NOT IN (SELECT Supplier_Invoice_Line__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Supplier_Invoice_Line__c IN :supplierInvoiceLines AND Accounting_Entry__r.BatchJobId__c = :bjId) '
                                + 'FOR UPDATE';
        
            SOQLUtil soql = new SOQLUtil('Supplier_Invoice_Line__c');
            soql.addFields(suppInvLineFields);
            soql.setWhereClause(silWhereClause);
            
            //Grab Lines for this scope
            mSILs = new Map<Id, Supplier_Invoice_Line__c>((List<Supplier_Invoice_Line__c>)Database.query(soql.getQuery()));
            
            soql = new SOQLUtil('Supplier_Invoice__c');
            soql.addFields(suppInvFields);
            soql.setWhereClause('Id IN :siIds');
        
            //Place the headers in a map for later reference
            mSIs = new Map<Id, Supplier_Invoice__c>((List<Supplier_Invoice__c>)Database.query(soql.getQuery()));
            
            findExistingDraftAEs(mSIs.keySet());
        }catch(Exception ex){
            throw ex;
        }
        
        //KNDY-9545 
        //Call method in super to populate mRules,mRuleDefs and SDTransactionDateList
        //This method gets the Txn Date Boundaries to be used in eff date filter in query and gets the subset of rules to load mRules and mRuleDefs.
        //This approach avoids handling all rules for the object and increases efficiency.
        loadEffRuleDetails(mSIs);
        
        set<Id> polIds = new set<Id>();
        
        for(Supplier_Invoice_Line__c sil : mSILs.values()){
            if(sil.purchase_order_line__c!=null)
            {
            polIds.add(sil.purchase_order_line__c);
                
            }
        }
        
        //need to aggregate GL by po line
        List<AggregateResult> arGLAggs  = new List<AggregateResult>();
        if(polIds.size()>0)
        {
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            
            SOQLUtil soql = new SOQLUtil('Accounting_Entry_Line__c', true, true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'receipt_line__r.purchase_order_line__c polId','GL_Account__c glId','GL_Account__r.FX_Type__c fxType','sum(amount_dr__c) amtDR',
                'sum(COMP_Functional_Currency_Amount_DR__c) funcDR','sum(amount_cr__c) amtCR','sum(COMP_Functional_Currency_Amount_CR__c) funcCR'
            });
            soql.setWhereClause('Receipt_Line__r.Purchase_Order_Line__c IN :polIds AND Status__c = \'Active\' AND Related_Accounting_Entry_Line__c = null '
                                +' GROUP BY receipt_line__r.purchase_order_line__c, gl_account__c, gl_account__r.fx_type__c');
            
            arGLAggs = Database.query(soql.getQuery());
        }
        
        map<Id, map<Id, AggregateResult>> mARs = new map<Id, map<Id, AggregateResult>>();
        
        //Now organize aggregates by pol Id
        for(AggregateResult ar : arGLAggs){
            if(mARs.containsKey((string)ar.get('polId'))){
                mARs.get((string)ar.get('polId')).put((string)ar.get('glId'), ar);
            }else{
                mARs.put((string)ar.get('polId'), new map<Id, AggregateResult>{(string)ar.get('glId') => ar});
            }
        }
        
        for(Supplier_Invoice_Line__c sil : mSILs.values()){
            
            Accounting_Entry__c iAE;
            Supplier_Invoice__c si = mSIs.get(sil.Supplier_Invoice__c);
            
            string transType;
            if(si.Invoice_Type__c.equalsIgnoreCase('Credit Memo')){
                transType = 'Credit Memo';
            }else{
                transType = 'Supplier Invoice';
            }
            
            if(mSourceDocAEs.containsKey(sil.Supplier_Invoice__c)){
                iAE = mSourceDocAes.get(sil.Supplier_Invoice__c);
            }else{
            	string transactionType;
         		if(si.transaction_type__c != null && si.transaction_type__c != '')
         			transactionType = si.transaction_type__c;
         		else
         			transactionType = si.Invoice_type__c;
             	
                iAE = generateAccountingEntry(si,  transactionType);
                iAE.Supplier__c = si.Supplier__c;
                mSourceDocAEs.put(si.Id, iAE);
            }
            
            List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
            
            string subTrans = (sil.Subtransaction_Type__c != null && sil.Subtransaction_Type__c != '') ? sil.Subtransaction_Type__c : null;
            
            //Create the rule definitions for this line
            AccountingRuleService.RuleDefinition iCRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, si.Company__r.Accounting_Standard__c, 'Supplier_Invoice__c', iAE.Transaction_Type__c, subTrans, sil.Line_Type__c);
            AccountingRuleService.RuleDefinition iDRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, si.Company__r.Accounting_Standard__c, 'Supplier_Invoice__c', iAE.Transaction_Type__c, subTrans, sil.Line_Type__c);
            AccountingRuleService.RuleDefinition iNARuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, si.Company__r.Accounting_Standard__c, 'Supplier_Invoice__c', iAE.Transaction_Type__c, subTrans, sil.Line_Type__c);
            
            if(mRuleDefs.containsKey(iNARuleDef)){
                //Do nothing when NA rules are identified
                for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
                    referencedRules.add(ar);
                }
                mSourceDocAELs.put(sil.Id, new List<Accounting_Entry_Line__c>());
                continue;
            }
            
            if(mRuleDefs.containsKey(iCRRuleDef)){
                Integer outDatedRuleCount =0;               
            
                for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){
                    //KNDY-9545             
                    if((ar.Effective_End_Date__c!=null ? si.transaction_date__c >= ar.Effective_End_Date__c:false)  || si.transaction_date__c < ar.Effective_Start_Date__c  )
                    {
                        //ReturnLine for missing rule
                        if(outDatedRuleCount ==mRuleDefs.get(iCRRuleDef).size()-1)
                        {
                          decimal amount = sil.Unit_Price__c * sil.Invoice_Quantity__c;//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price. 
                          iAELs.add(returnLineForMissingEffectiveRule(iAE, sil, iCRRuleDef, amount));                           
                        }
                        outDatedRuleCount++;
                        continue;
                    }                   
                    decimal iCRAmt = findLineAmount(sil, ar);
                    if(iCRAmt == null){
                        //continue;
                    }
                    
                    Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, si, sil, ar, iCRAmt);
                    iAEL.SubTransaction_Type__c = subTrans;
                    iAEL.Line_Type__c = sil.Line_Type__c;
                    iAEL.Supplier_Invoice_Line__c = sil.Id;
                    
                    SS.assignSegments(ar, sil, iAEL);                           
                    
                    iAELs.add(iAEL);
                    referencedRules.add(ar);
                }   
            }else{
                //FIN-894 changes to implement the new Itemservice
                Decimal amount;
                amount = sil.Unit_Price__c * sil.Invoice_Quantity__c;//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price.
                iAELs.add(returnLineForMissingEffectiveRule(iAE, sil, iCRRuleDef, amount));
            }
            
            
            if(mRuleDefs.containsKey(iDRRuleDef)){
                Integer outDatedRuleCount =0;               
                for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){
                    //KNDY-9545             
                    if((ar.Effective_End_Date__c!=null ? si.transaction_date__c >= ar.Effective_End_Date__c:false)  || si.transaction_date__c < ar.Effective_Start_Date__c  )
                    {
                        //ReturnLine for missing rule
                        if(outDatedRuleCount ==mRuleDefs.get(iDRRuleDef).size()-1)
                        {
                          decimal amount = sil.Unit_Price__c * sil.Invoice_Quantity__c;//KNDY-14371 
                          iAELs.add(returnLineForMissingEffectiveRule(iAE, sil, iDRRuleDef, amount));                           
                        }
                        outDatedRuleCount++;
                        continue;
                    }                   
                    decimal iDRAmt = findLineAmount(sil, ar);
                    if(iDRAmt == null){
                        //continue;
                    }
                    
                    Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, si, sil, ar, iDRAmt);
                    iAEL.SubTransaction_Type__c = subTrans;
                    iAEL.Line_Type__c = sil.Line_Type__c;
                    iAEL.Supplier_Invoice_Line__c = sil.Id;
                    
                    SS.assignSegments(ar, sil, iAEL);                           
                    
                    iAELs.add(iAEL);
                    referencedRules.add(ar);
                }
            }else{
                //FIN-894 changes to implement the new Itemservice
                Decimal amount;
                amount = sil.Unit_Price__c * sil.Invoice_Quantity__c;//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price.
                iAELs.add(returnLineForMissingEffectiveRule(iAE, sil, iDRRuleDef, amount));
            }
            
            if(sil.supplier_invoice__r.currency__c != sil.supplier_invoice__r.company__r.comp_currency__c){
                //Now check deltas vs. aggregates and create percentage for clearing upstream accounts
                if(mARs.containsKey(sil.purchase_order_line__c)){
                    for(Id glId : mARs.get(sil.purchase_order_line__c).keySet()){
                        decimal totalDR = 0;
                        decimal totalCR = 0;
                        //need % sil vs sum RDs
                        for(Accounting_Entry_Line__c iAEL : iAELs){
                            //check map for pol, then gl for this sil and iAEL respectively
                            if(mARs.containsKey(sil.purchase_order_line__c)){
                                if(mARs.get(sil.purchase_order_line__c).containsKey(iAEL.gl_account__c)){
                                    AggregateResult iAgg = mARs.get(sil.purchase_order_line__c).get(iAEL.gl_account__c);
                                    string iFXType = (string)iAgg.get('fxType');
                                    if(iFXType != null && iFXType.equalsIgnoreCase('Monetary Non-cash') && iAEL.GL_Account__c == glId){
                                        //Now we're open to exposure
                                        totalDR += iAEL.amount_dr__c;
                                        totalCR += iAEL.amount_cr__c;
                                    }
                                }
                            }
                        }
                        
                        if(totalDR != 0 || totalCR != 0){
                            
                            AggregateResult aggRes = mARs.get(sil.Purchase_Order_Line__c).get(glId);
                            string iFXType = (string)aggRes.get('fxType');
                            
                            decimal iAggDR = decimal.valueOf(string.valueOf(aggRes.get('amtDR')));
                            decimal iAggCR = decimal.valueOf(string.valueOf(aggRes.get('amtCR')));
                            decimal iAggFuncDR = decimal.valueOf(string.valueOf(aggRes.get('funcDR')));
                            decimal iAggFuncCR = decimal.valueOf(string.valueOf(aggRes.get('funcCR')));
                            //normalize attainment of functional based on transaction currency
                            
                            decimal iPctDR = iAggDR != 0 ? 1 - (iAggDR - totalCR)/iAggDR : 0;
                            decimal iPctCR = iAggCR != 0 ? 1 - (iAggCR - totalDR)/iAggCR : 0;
                            
                            //loop back through and assign ledger amounts - back in to exchange rate
                            decimal rate;
                            for(Accounting_Entry_Line__c iAEL : iAELs){
                                if(iFXType.equalsIgnoreCase('Monetary Non-cash') && iAEL.GL_Account__c == glId){
                                    if(iAEL.amount_DR__c != null && totalDR != 0){
                                        decimal normalizedFuncDR = iAggFuncCR * (iAEL.amount_dr__c/totalDR) * iPctCR;
                                        system.debug(logginglevel.info, 'normalizedFuncDR: ' + normalizedFuncDR);
                                        iAEL.COMP_Functional_Currency_Amount_DR__c = normalizedFuncDr;
                                        iAEL.COMP_Functional_Currency_Amount_CR__c = 0;
                                        iAEL.COMP_Functional_Currency__c = sil.supplier_invoice__r.company__r.comp_currency__r.ISO_code__c;
                                        iAEL.COMP_Transaction_Currency__c = sil.supplier_invoice__r.currency__r.ISO_code__c;
                                        iAEL.COMP_Transaction_Currency_Amount_DR__c = iAEL.amount_dr__c;
                                        iAEL.COMP_Transaction_Currency_Amount_CR__c = 0;
                                        if(iAEL.amount_dr__c != 0){
                                            iAEL.COMP_Functional_Conversion_Rate__c = iAEL.COMP_Functional_Currency_Amount_DR__c/iAEL.amount_dr__c;
                                            rate = iAEL.COMP_Functional_Conversion_Rate__c;
                                        }
                                    }
                                    if(iAEL.amount_CR__c != null && totalCR != 0){
                                        decimal normalizedFuncCR = iAggFuncDR * (iAEL.amount_cr__c/totalCR) * iPctDR;
                                        
                                        iAEL.COMP_Functional_Currency_Amount_DR__c = 0;
                                        iAEL.COMP_Functional_Currency_Amount_CR__c = normalizedFuncCr;
                                        iAEL.COMP_Functional_Currency__c = sil.supplier_invoice__r.company__r.comp_currency__r.ISO_code__c;
                                        iAEL.COMP_Transaction_Currency__c = sil.supplier_invoice__r.currency__r.ISO_code__c;
                                        iAEL.COMP_Transaction_Currency_Amount_DR__c = 0;
                                        iAEL.COMP_Transaction_Currency_Amount_CR__c = iAEL.amount_cr__c;
                                        if(iAEL.amount_cr__c != 0){
                                            iAEL.COMP_Functional_Conversion_Rate__c = iAEL.COMP_Functional_Currency_Amount_CR__c/iAEL.amount_cr__c;
                                            rate = iAEL.COMP_Functional_Conversion_Rate__c;
                                        }
                                    }
                                }
                            }
                            
                            //We found the rate, now apply to the other lines...
                            for(Accounting_Entry_Line__c iAEL : iAELs){
                                if(iAEL.COMP_Functional_Conversion_Rate__c == null){
                                    iAEL.COMP_Functional_Conversion_Rate__c = rate;
                                    iAEL.COMP_Functional_Currency_Amount_CR__c = iAEL.amount_cr__c * rate;
                                    iAEL.COMP_Functional_Currency_Amount_DR__c = iAEL.amount_dr__c * rate;
                                    iAEL.COMP_Functional_Currency__c = sil.supplier_invoice__r.company__r.comp_currency__r.ISO_code__c;
                                    iAEL.COMP_Transaction_Currency__c = sil.supplier_invoice__r.currency__r.ISO_code__c;
                                    iAEL.COMP_Transaction_Currency_Amount_CR__c = iAEL.amount_cr__c;
                                    iAEL.COMP_Transaction_Currency_Amount_DR__c = iAEL.amount_dr__c;
                                }
                            } 
                        }
                        
                    }
                }
            }
            
            mSourceDocAELs.put(sil.Id, iAELs);
        }
        
        
        finish((Map<Id, sObject>)mSIs, (Map<Id, sObject>)mSILs, mSourceDocAEs, mSourceDocAELs);
    }
    
    private decimal findLineAmount(Supplier_Invoice_Line__c sil, Accounting_Rule__c ar){
        //TODO: Drive consistency in all of these various permutations at the supplier invoice line level
        //Misc or expense lines are pulling from the po line, why can't this be pulled from the supplier invoice directly, or via amount overrides
        //NOTE: We are expecting PPV and IPV to use amount overrides
        decimal amount;
        if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
            amount = (decimal)sil.get(ar.Amount_Reference__c); 
        }else if(ar.transaction__c.equalsIgnoreCase('Supplier Credit Memo')){ // Credit memo will always have invoice unit price * invoice quantity regardless of item source on the line
            amount = sil.Unit_Price__c * sil.Invoice_Quantity__c;//KNDY-14371
        }else if(isMiscOrExpense(sil)){
            if(sil.Purchase_Order_Line__r != null){
                if((sil.Purchase_Order_Line__r.Unit_Price__c != null && sil.Purchase_Order_Line__r.Unit_Price__c > 0) && (sil.Invoice_Quantity__c != null && sil.Invoice_Quantity__c > 0)){
                    amount = sil.Purchase_Order_Line__r.Unit_Price__c * sil.Invoice_Quantity__c;
                }
            }else{
                amount = sil.Unit_Price__c * sil.Invoice_Quantity__c;//KNDY-14371
            }
        }else{
            amount = sil.Unit_Price__c * sil.Invoice_Quantity__c;//KNDY-14371  
        }
    
 		system.debug('returnFinalLineAmount(amount,ar) ======== ' + returnFinalLineAmount(amount,ar));
        if(amount == null){
            return amount;
        }
        else{  
            return returnFinalLineAmount(amount,ar);}
    }
    
    public Item_Cost__c returnItemCost(Date trxnDate, List<Item_Cost__c> itemCosts){
        Item_Cost__c activeCost;
        if(itemCosts == null){
            return null;
        }else{
            for(Item_Cost__c ic : itemCosts){
                if(trxnDate >= ic.Date_Activated__c){
                    activeCost = ic;
                    break;
                }
            }
        }
        
        return activeCost;
    }
}