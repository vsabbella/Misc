public class PurchaseOrderAccounting  {
//DEPRECATED CLASS FIN-1046    


/*    public PurchaseOrderAccounting(){

// without sharing is intentional.  accounting needs to be run in system mode.

public without sharing class PurchaseOrderAccounting extends AccountingService {
    
    public PurchaseOrderAccounting(){
        super('Purchase_Order__c');
    }
    
    public override void execute(List<sObject> purchaseOrderLines){
        
        string bjId = this.batchJobId;
        
        set<Id> poIds = new set<Id>();
        for(Purchase_Order_Line__c pol : (List<Purchase_Order_Line__c>)purchaseOrderLines){
            poIds.add(pol.purchase_order__c);
        }
        
        set<string> purchaseOrderFields = new set<string>{'id', 'name', 'company__c', 'supplier__c', 'finalized__c', 'finalized_date__c', 'transaction_currency__c', 'transaction_date__c','transaction_type__c','type__c', 'void__c', 'void_date__c','posting_date__c', 'total_number_of_lines__c'};
        
        string poQuery = 'SELECT ' + string.join(new List<string>(purchaseOrderFields),', ');
        poQuery += ' FROM Purchase_Order__c WHERE Id IN :poIds';

        set<string> purchaseOrderLineFields = new set<string>{ 'id', 'name', 'subtransaction_type__c', 'line_type__c', 'line_value__c','quantity_shipped__c','unit_price__c', 'purchase_order__c'};
        purchaseOrderLineFields.addAll(segmentReferences);
        
        string purchaseOrderLineQuery = 'SELECT ' + string.join(new List<string>(purchaseOrderLineFields), ', ');
        purchaseOrderLineQuery += ' FROM Purchase_Order_Line__c '
                            + 'WHERE Id IN :purchaseOrderLines '
                            + 'AND Finalized__c = true '
                            + 'AND Historical__c = false ' 
                            + 'AND Purchase_Order__r.Company__c != null '
                            + 'AND Purchase_Order__r.Transaction_Date__c != null '
                            + 'AND Purchase_Order__r.Finalized_Date__c != null '
                            + 'AND Purchase_Order__r.Transaction_Currency__c != null '
                            + 'AND Purchase_Order__c NOT IN (SELECT Purchase_Order__c FROM Accounting_Entry__c WHERE Purchase_Order__c IN :poIds AND related_accounting_entry__c = null AND (Period__r.Closed__c = true OR Period__r.Permanently_Closed__c = true) ) ' //FIN-889 AND batchjobid__c!=null and batchjobid__c!=:batchJobID
                            + 'AND Id NOT IN (SELECT Purchase_Order_Line__c FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Purchase_Order_Line__c IN :purchaseOrderLines AND Accounting_Entry__r.BatchJobId__c = :bjId) '
                            + 'FOR UPDATE';
                            
                            
        Map<Id, Accounting_Entry__c> mSourceDocAEs = new Map<Id, Accounting_Entry__c>();
        Map<Id, List<Accounting_Entry_Line__c>> mSourceDocAELs = new Map<Id, List<Accounting_Entry_Line__c>>();
        Map<Id, Purchase_Order__c> mPOs = new Map<Id, Purchase_Order__c>();
        Map<Id, Purchase_Order_Line__c> mPOLs = new Map<Id, Purchase_Order_Line__c>();
        try{
           //Grab Lines for this scope
            mPOLs = new Map<Id, Purchase_Order_Line__c>((List<Purchase_Order_Line__c>)Database.query(purchaseOrderLineQuery));
            //Place the headers in a map for later reference
            mPOs = new Map<Id, Purchase_Order__c>((List<Purchase_Order__c>)Database.Query(poQuery));
            findExistingDraftAEs(mPOs.keySet());
        }catch(Exception ex){
            throw ex;
        }
        
        for(Purchase_Order_Line__c pol : mPOLs.values()){
            
            Accounting_Entry__c iAE;
            Purchase_Order__c po = mPOs.get(pol.Purchase_Order__c);
            if(mSourceDocAEs.containsKey(pol.Purchase_Order__c)){
                iAE = mSourceDocAes.get(pol.Purchase_Order__c);
            }else{
                iAE = generateAccountingEntry(po, po.Type__c);
                iAE.Supplier__c = po.Supplier__c;
                mSourceDocAEs.put(po.Id, iAE);
            }
            
            List<Accounting_Entry_Line__c> iAELs = new List<Accounting_Entry_Line__c>();
            
            string transType = iAE.Transaction_Type__c;
            string subTrans = (pol.Subtransaction_Type__c != null && pol.Subtransaction_Type__c != '') ? pol.Subtransaction_Type__c : null;
            
            //Create the rule definitions for this line
            AccountingRuleService.RuleDefinition iCRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, po.Company__c, 'Purchase_Order__c', transType, subTrans, pol.Line_Type__c);
            AccountingRuleService.RuleDefinition iDRRuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, po.Company__c,'Purchase_Order__c', transType, subTrans, pol.Line_Type__c);
            AccountingRuleService.RuleDefinition iNARuleDef = 
                new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.NA, po.Company__c,'Purchase_Order__c', transType, subTrans, pol.Line_Type__c);
            
            if(mRuleDefs.containsKey(iNARuleDef)){
                //system.debug(logginglevel.INFO, 'NA Rule Defs: ' + mRuleDefs.get(iNARuleDef).size() + ' - '  + mRuleDefs.get(iNARuleDef));
                //Do nothing when NA rules are identified
                for(Accounting_Rule__c ar : mRuleDefs.get(iNARuleDef)){
                    referencedRules.add(ar);
                }
                mSourceDocAELs.put(pol.Id, new List<Accounting_Entry_Line__c>());
                continue;
            }           
            
            //system.debug('iCRRuleDef: ' + iCRRuleDef);
            //system.debug('mRuleDefs contains: ' + mRuleDefs.containsKey(iCRRuleDef));
            if(mRuleDefs.containsKey(iCRRuleDef)){
                //system.debug(logginglevel.info,'CR Rule Defs: ' + mRuleDefs.get(iCRRuleDef).size() + ' - '  + mRuleDefs.get(iCRRuleDef));
                for(Accounting_Rule__c ar : mRuleDefs.get(iCRRuleDef)){
                    
                    decimal iCRAmt = findLineAmount(pol, ar);
                    if(iCRAmt == null){
                        continue;
                    }
                    
                    Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, po, pol, ar, iCRAmt);
                    iAEL.SubTransaction_Type__c = subTrans;
                    iAEL.Line_Type__c = pol.Line_Type__c;
                    iAEL.Purchase_Order_Line__c = pol.Id;
                    
                    SS.assignSegments(ar, pol, iAEL);   
                    //system.debug(logginglevel.info,'iAEL: ' + iAEL);
                    iAELs.add(iAEL);
                    referencedRules.add(ar);
                }   
            }else{
                iAELs.add(returnLineForMissingRule(iAE, pol, iCRRuleDef, pol.Line_Value__c));
            }
            
            
            //system.debug('iDRRuleDef: ' + iDRRuleDef);
            //system.debug('mRuleDefs contains: ' + mRuleDefs.containsKey(iDRRuleDef));
            if(mRuleDefs.containsKey(iDRRuleDef)){
                //system.debug(logginglevel.info, 'DR Rule Defs: ' + mRuleDefs.get(iDRRuleDef).size() + ' - '  + mRuleDefs.get(iDRRuleDef));
                for(Accounting_Rule__c ar : mRuleDefs.get(iDRRuleDef)){
                    
                    decimal iDRAmt = findLineAmount(pol, ar);
                    if(iDRAmt == null){
                        continue;
                    }
                    
                    Accounting_Entry_Line__c iAEL = generateAccountingEntryLine(iAE, po, pol, ar, iDRAmt);
                    iAEL.SubTransaction_Type__c = subTrans;
                    iAEL.Line_Type__c = pol.Line_Type__c;
                    iAEL.Purchase_Order_Line__c = pol.Id;
                    
                    SS.assignSegments(ar, pol, iAEL);   
                    //system.debug(logginglevel.info,'iAEL: ' + iAEL);
                    iAELs.add(iAEL);
                    referencedRules.add(ar);
                }
            }else{
                iAELs.add(returnLineForMissingRule(iAE, pol, iDRRuleDef, pol.Line_Value__c));
            }
            
            mSourceDocAELs.put(pol.Id, iAELs);
        }
        
        finish((Map<Id, sObject>)mPOs, (Map<Id, sObject>)mPOLs, mSourceDocAEs, mSourceDocAELs);
    }
    
    public decimal findLineAmount(Purchase_Order_Line__c pol, Accounting_Rule__c ar){
        decimal amount;
        if(ar.Amount_Reference__c != null && ar.Amount_Reference__c != ''){
            amount = (decimal)pol.get(ar.Amount_Reference__c); 
        }
        //FIN-566 fix ASN Accounting
        else{
            amount = (pol.Quantity_Shipped__c == null ? 0 : pol.Quantity_Shipped__c)*(pol.Unit_Price__c  == null ? 0 : pol.Unit_Price__c );
        }
        return amount;
    }
*/}