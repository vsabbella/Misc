/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public abstract without sharing class AccountingService { // implements AccountingInterface
    
    public class FinishWrapper{
        
        public AccountingRuleService.RuleDefinition ruleDef;
        public Accounting_Entry__c SourceDocAE;
        public list<Accounting_Entry_Line__c> SourceDocAELs;
        
    }
    
        
    public class AccountingException extends Exception{}
    public list<string> logs = new list<string>();
    
    /*
        This super class is to be extended by all worker classes that are used to generate accounting
    */
    private string sObjectName;
    SchemaUtil util = SchemaUtil.getInstance();
    public Map<Id, Accounting_Rule__c> mRules;
    //Referenced rules can be used to collect rules used during the accounting entry line generation process
    public set<Accounting_Rule__c> referencedRules = new set<Accounting_Rule__c>();
    public Map<AccountingRuleService.RuleDefinition, List<Accounting_Rule__c>> mRuleDefs;
    public set<string> segmentReferences;
	public map<Id,Company__c> mCompanies = new Map<Id,Company__c>();
    public AccountingRuleService ARS = new AccountingRuleService();    
    public SegmentService SS = new SegmentService();
    public List<Segment_Definition__c> segments = SS.segments;
    public List<DateTime> TransactionDateList = new List<DateTime>();
    public List<DateTime> SDTransactionDateList = new List<DateTime>();
    public static Map<Id, Currency__c>mCurrencies = new Map<Id, Currency__c>();

    
    public boolean isValidation = false;
    
    public boolean isPreview = false;
    //FIN-749 Large Data Accounting
    public string batchJobID;
    //KNDY-10268 - deprecating bank file and bank file line objects - commented references
    public static final map<string, string> mAccountingWorkers = new map<string, string>{
        'Journal_Entry__c'          =>  'JournalEntryAccounting',
        'Customer_Invoice__c'       =>  'CustomerInvoiceAccounting',
        'Customer_Receipt__c'       =>  'CustomerReceiptAccounting',
        //'Bank_File__c'              =>  'BankFileAccounting',
        'Bank_Transaction_Group__c' =>  'BankTransactionGroupAccounting',
        'Supplier_Invoice__c'       =>  'SupplierInvoiceAccounting',
        'Supplier_Payment__c'       =>  'SupplierPaymentAccounting',
///     'Purchase_Order__c'         =>  'PurchaseOrderAccounting',
//        'Work_Order__c'             =>  'WorkOrderAccounting',
        'Inventory_Change__c'       =>  'InventoryChangeAccounting',
//        'Shipment__c'               =>  'ShipmentAccounting',
        'Receiving_Document__c'     =>  'ReceivingDocumentAccounting',
        'Fixed_Asset_Adjustment__c' =>  'AccountingProcessFixedAssetAdjustments',
        'Fixed_Asset_Depreciation__c'=> 'AccountingProcessFixedAssetDepreciation',
        'Invoice__c'                =>  'InvoiceAccounting',
        'Payment__c'                =>  'PaymentAccounting'
    }; 
    //KNDY-10268 - deprecating bank file and bank file line objects - commented references
    public static final map<string, set<string>> mLinesToHeader = new map<string, set<string>>{
        'Journal_Entry_Line__c'      =>  new set<string>{'Journal_Entry__c'},
        'Customer_Invoice_Line__c'      =>  new set<string>{'Customer_Invoice__c'},
        'Customer_Receipt_Line__c'      =>  new set<string>{'Customer_Receipt__c'},
        //'Bank_File_Line__c'             =>  new set<string>{'Bank_File__c'},
        'Bank_Transaction__c'           =>  new set<string>{'Bank_Transaction_Group__c'},       
        'Supplier_Invoice_Line__c'       =>  new set<string>{'Supplier_Invoice__c'},
        'Supplier_Payment_Line__c'      =>  new set<string>{'Supplier_Payment__c'},
        'Purchase_Order_Line__c'        =>  new set<string>{'Purchase_Order__c'},
        'Inventory_Transaction__c'      =>  new set<string>{'Work_Order__c', 'Inventory_Change__c'},
        'Shipment_Line__c'              =>  new set<string>{'Shipment__c'},
        'Receipt_Line__c'               =>  new set<string>{'Receiving_Document__c'},
        'Invoice_Line__c'               =>  new set<string>{'Invoice__c'},
        'Payment_Line__c'               =>  new set<string>{'Payment__c'},
        'Fixed_Asset_Adjustment__c'     =>  new set<string>{null},
        'Fixed_Asset_Depreciation__c'   =>  new set<string>{null}
    }; 
    
    //KNDY-10268 - deprecating bank file and bank file line objects - commented references
    public static final map<string, string> mHeaderToLines = new map<string, string>{
        'Journal_Entry__c'          =>  'Journal_Entry_Line__c',
        'Customer_Invoice__c'       =>  'Customer_Invoice_Line__c',
        'Customer_Receipt__c'       =>  'Customer_Receipt_Line__c',
        //'Bank_File__c'              =>  'Bank_File_Line__c',
        'Bank_Transaction_Group__c' =>  'Bank_Transaction__c',      
        'Supplier_Invoice__c'       =>  'Supplier_Invoice_Line__c',
        'Supplier_Payment__c'       =>  'Supplier_Payment_Line__c',
        'Purchase_Order__c'         =>  'Purchase_Order_Line__c',
        'Work_Order__c'             =>  'Inventory_Transaction__c',
        'Inventory_Change__c'       =>  'Inventory_Transaction__c',
        'Shipment__c'               =>  'Shipment_Line__c',
        'Receiving_Document__c'     =>  'Receipt_Line__c',
        'Invoice__c'                =>  'Invoice_Line__c',
        'Payment__c'                =>  'Payment_Line__c',
        'Fixed_Asset_Adjustment__c' =>  null,
        'Fixed_Asset_Depreciation__c'=> null
    };
    //TODO:Replaced by internal map is SourceDocumentAccountingCon
    //KNDY-10268 - deprecating bank file and bank file line objects - commented references
    public static final map<string, string> mSourceDocToType = new map<string, string>{
        'Journal_Entry__c'          =>  'Type__c',
        'Customer_Invoice__c'       =>  'Invoice_Type__c',
        'Customer_Receipt__c'       =>  'Customer Receipt',
        //'Bank_File__c'              =>  'Type__c',
        'Supplier_Invoice__c'       =>  'Invoice_Type__c',
        'Supplier_Payment__c'       =>  'Supplier Payment',
//        'Purchase_Order__c'         =>  'Type__c',
        'Work_Order__c'             =>  'Work Order',
        'Inventory_Change__c'       =>  'Type__c',
        'Shipment__c'               =>  'Shipment',
        'Receiving_Document__c'     =>  'Type__c',
        'Invoice__c'                =>  'Type__c',
        'Payment__c'                =>  'Type__c',
        'Fixed_Asset_Adjustment__c' =>  'Fixed Asset Adjustment',
        'Fixed_Asset_Depreciation__c'=> 'Fixed Asset Depreciation'
    };  
    
    //TODO:This map not used anywhere.
    //KNDY-10268 - deprecating bank file and bank file line objects - removed references
    private map<string, string> mLineRelationships = new map<string, string>{
        //'Bank_File_Line__c' => 'Bank_File_Line__c',
        'Customer_Invoice_Line__c' => 'Customer_Invoice_Line__c',
        'Customer_Receipt_Line__c' => 'Customer_Receipt_Line__c',
        'Inventory_Transaction__c' => 'Inventory_Transaction__c',
        'Invoice_Line__c'          => 'Invoice_Line__c',
        'Fixed_Asset_Depreciation__c' => null,
        'Fixed_Asset_Adjustment__c' => null,
        'Receipt_Line__c' => 'Receipt_Line__c',
        'Shipment_Line__c' => 'Shipment_Line__c',
        'Supplier_Invoice_Line__c' => 'Supplier_Invoice_Line__c',
        'Supplier_Payment_Line__c' => 'Supplier_Payment_Line__c',
        'Purchase_Order_Line__c' => 'Purchase_Order_Line__c'
    };
 
    public AccountingService(string sObjectName){
        this.sObjectName = sObjectName;
        //mRules = new Map<Id, Accounting_Rule__c>(AccountingRuleService.getAccountingRulesByObject(this.sObjectName));
        //mRuleDefs = AccountingRuleService.getRuleDefsForObject(this.sObjectName);
        //system.debug('super con mRuleDefs: ' + mRuleDefs);
        segmentReferences = AccountingRuleService.getSegmentReferenceFields(this.sObjectName);
        //system.debug('super con segmentReferences: ' + segmentReferences);
    }

    private String getCurrency(Accounting_Entry__c ae){
        if(ae.Currency__r != null){
            //most accounting will use this
            return ae.Currency__r.ISO_Code__c;
        }else if(ae.Currency__c != null){
            //some accounting calls populateLegdger before finish.  In that case there is a chance the Currency__r wasn't queried
        if(mCurrencies == null || mCurrencies.size() == 0){
            SOQLUtil soql = new SOQLUtil('Currency__c');
        soql.addFields(new set<String>{'Id','ISO_Code__c'});
        soql.setWhereClause('iso_code__c != null');
            mCurrencies = new Map<Id, Currency__c>((List<Currency__c>)Database.query(soql.getQuery()));
        }
            return mCurrencies.get(ae.Currency__c).ISO_Code__c;
        }else{
            //Fallback for backwards compatability
            return ae.Transaction_Currency__c;
        }
    }

	public void populateCompanyMap(set<Id> companyIds){
        if(mCompanies == null || mCompanies.size() == 0){
		set<Id> cIds = companyIds;
		SOQLUtil soql = new SOQLUtil('Company__c');
		soql.addAllFields();
		soql.addFields(new set<string>{'comp_currency__r.iso_code__c', 'consol_currency__r.iso_code__c','stat_currency__r.iso_code__c', 'subs_currency__r.iso_code__c'});
		soql.setWhereClause('Id IN :cIds');
		string query = soql.getQuery();
		mCompanies = new Map<Id, Company__c>((List<Company__c>)Database.query(query));
    }
    }
    
    /*
        Description: This abstract is overridden in each worker class to generate the appropriate accounting entries
    */
    public abstract void execute(List<sObject> sObjRecs);
    
    private map<Id, Accounting_Entry__c> mGeneratedAEs = new Map<Id, Accounting_Entry__c>();
    
    public void findExistingDraftAEs(set<Id> sourceDocIds){
        set<Id> sdIds = sourceDocIds;
        string bjId = this.batchJobId;
        Set<String> queryFields = new Set<String>{ 'Id', 'Name', 'Finalized_Date__c', 'Transaction_Date__c', 'Posting_Date__c', 'Company__c', 'Currency__c','currency__r.ISO_Code__c' ,'Company__r.comp_currency__c','Company__r.comp_currency__r.ISO_Code__c','Company__r.consol_currency__c','Company__r.consol_currency__r.ISO_Code__c','Company__r.Stat_Currency__c','Company__r.Stat_Currency__r.ISO_Code__c', 'Company__r.Subs_Currency__c','Company__r.Subs_Currency__r.ISO_Code__c','Transaction_Type__c',
                                        'Source_Document_Object_Name__c', 'Status__c', 'Source_Key__c', 'BatchJobid__c', 'Source_Lines_Processed__c', 'Related_Accounting_Entry__c'};
        queryFields.add(AccountingEntryService.SourceDocPathMap.get(sObjectName));
        SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', TRUE);
        soql.addFields(queryFields);
        soql.setWhereClause('Status__c = \'Draft\''
                        + ' AND ' + AccountingEntryService.SourceDocPathMap.get(sObjectName) + ' IN : sdIds'
                        + ' AND batchjobId__c = :bjId');
        List<Accounting_Entry__c> aes = Database.query(soql.getQuery());
        for(Accounting_Entry__c ae : aes){
            mGeneratedAEs.put((Id)ae.get(AccountingEntryService.SourceDocPathMap.get(sObjectName)), ae);
        }   
        
        system.debug('mGeneratedAEs: ' + mGeneratedAEs);
    }   
    
    public  list<string> getLogs()
    {
        return logs;
    }
    
    public void loadEffRuleDetails(map<id,sobject> mSDs)
    {
        if(mSDs.size()>0)
        {
            populateTransactionDateList(mSDs);
            mRules= new map<id,Accounting_Rule__c>(AccountingRuleService.getEffectiveAccountingRulesByObject(this.sObjectName,SDTransactionDateList));
            mRuleDefs = new map<AccountingRuleService.RuleDefinition, List<Accounting_Rule__c>>(AccountingRuleService.getEffectiveRuleDefs(mRules));        
        }

    }
    //KNDY-9545  Get the TDs in scope to be used to get the Effective Rules.
    public void populateTransactionDateList(map<id,sobject> mSDs){      
 
        set<datetime> TDSetForSDs = new set<datetime>();
        for(Id SDid:mSDs.keyset()){
          Datetime TD = (DateTime)mSDs.get(SDid).get('Transaction_Date__c');
          if(TD!=null){
            TDSetForSDs.add(TD);                        
          }
        }
        SDTransactionDateList = new list<datetime>(TDsetForSDs);
        SDTransactionDateList.sort();
        system.debug(LOGGINGLEVEL.INFO,'Transaction Dates '+SDTransactionDateList);
        
    }       
    public static datetime getStartTxnDate(list<datetime> TDList)
    {
        Datetime startTxnDate;
        if(TDList!= null)
        {
             if(TDList.size()>0)
            {
                startTxnDate=TDList[0];                     
            }
                    
        }
        return startTxnDate; 

    }
    public static datetime getEndTxnDate(list<datetime> TDList)
    {
        Datetime endTxnDate;
        if(TDList!= null)
        {
             if(TDList.size()>0)
            {
                endTxnDate=TDList[TDList.size()-1];                     
            }
                    
        }
        return endTxnDate;  
    }
    
    private map<String, Id> mCompanyCurrencies = null;
    private Id getFallbackCurrency(String iso){
        if(mCompanyCurrencies == null){
            mCompanyCurrencies = new map<String, Id>();
            SOQLUtil soql = new SOQLUtil('Currency__c', true);
            soql.addFields(new set<String>{'Id', 'ISO_Code__c'});
            soql.setWhereClause('ISO_Code__c != null');
            List<Currency__c> curr = (List<Currency__c>)Database.query(soql.getQuery());

            for(Currency__c c : curr){
                mCompanyCurrencies.put(c.ISO_Code__c, c.Id);
            }
        }
        return mCompanyCurrencies.get(iso);
    }
    
    /*
        Description: This method is used to generate the Accounting Entry header
    */
    //TODO:Exclude the transactionType parameter once all sourceDocs are populating new field Transaction_Type__c in the source doc.Change in all accounting workers.
    public virtual Accounting_Entry__c generateAccountingEntry(sObject sourceDoc, string transactionType){
        
        Accounting_Entry__c ae;
        if(mGeneratedAEs.containsKey(sourceDoc.Id)){
            ae = mGeneratedAEs.get(sourceDoc.Id);
            system.debug('found ae: ' + ae);
        }
        
        //if(ae == null){// || (ae.batchjobId__c != this.batchJobId || string.isEmpty(ae.batchJobId__c))){
        else{
            system.debug('resetting ae: ' + ae);
            ae = new Accounting_Entry__c();
            
            string objectName = sourceDoc.getSObjectType().getDescribe().getLocalName();
            
            ae.Finalized_Date__c = (DateTime)sourceDoc.get('Finalized_Date__c');
            ae.Transaction_Date__c = (DateTime)sourceDoc.get('Transaction_Date__c');
            ae.Posting_Date__c = (DateTime)sourceDoc.get('Posting_Date__c');
            ae.Posting_Date__c = ae.Posting_Date__c == null ? ae.Finalized_Date__c : ae.Posting_Date__c;
            if(objectName.equalsIgnoreCase('Journal_Entry__c') && (sourceDoc.get('Type__c') == 'Year End' || sourceDoc.get('Type__c') == 'Year End Adjustment')){
                ae.GL_Date_Time__c = (Datetime) sourceDoc.get('GL_Date_Time__c');
                ae.Period__c = (Id) sourceDoc.get('Period__c');
            }
            ae.Company__c = (Id)sourceDoc.get('Company__c');
            ae.Currency__c = sourceDoc.get('Currency__c') != null ? (Id)sourceDoc.get('Currency__c') : getFallbackCurrency((String)sourceDoc.get('Transaction_Currency__c')) ;
            
            //FIN-954 Adding new field Transaction_Type__c field to all source docs.
            String transactionTypeFromSD = (String)sourceDoc.get('Transaction_Type__c');
            //TODO:Comment the below line after all source docs start populating the new field Transaction_Type__c field            
            transactionTypeFromSD=(transactionTypeFromSD==null || transactionTypeFromSD=='')?transactionType:transactionTypeFromSD;
            ae.Transaction_Type__c = transactionTypeFromSD;
            
            ae.put(objectName, sourceDoc.Id);
            ae.source_document_object_name__c = objectName;
            ae.status__c = 'Draft';
            ae.source_key__c = sourceDoc.Id + '|' + ae.status__c + '|' + this.batchJobId;
            ae.BatchJobid__c =this.batchJobID;
            ae.source_lines_processed__c = null;
        }
        
        system.debug('returning: ' + ae);
        return ae;
    }

    public virtual Accounting_Entry__c generateAccountingEntry(sObject sourceDoc, string transactionType, id companyID){
        
        Accounting_Entry__c ae;
        if(mGeneratedAEs.containsKey(sourceDoc.Id)){
            ae = mGeneratedAEs.get(sourceDoc.Id);
            system.debug('found ae: ' + ae);
        }
        
        //if(ae == null){// || (ae.batchjobId__c != this.batchJobId || string.isEmpty(ae.batchJobId__c))){
        else{
            system.debug('resetting ae: ' + ae);
            ae = new Accounting_Entry__c();
            
            string objectName = sourceDoc.getSObjectType().getDescribe().getLocalName();
            
            ae.Finalized_Date__c = (DateTime)sourceDoc.get('Finalized_Date__c');
            ae.Transaction_Date__c = (DateTime)sourceDoc.get('Transaction_Date__c');
            ae.Posting_Date__c = (DateTime)sourceDoc.get('Posting_Date__c');
            ae.Posting_Date__c = ae.Posting_Date__c == null ? ae.Finalized_Date__c : ae.Posting_Date__c;
            if(objectName.equalsIgnoreCase('Journal_Entry__c') && (sourceDoc.get('Type__c') == 'Year End' || sourceDoc.get('Type__c') == 'Year End Adjustment')){
                ae.GL_Date_Time__c = (Datetime) sourceDoc.get('GL_Date_Time__c');
                ae.Period__c = (Id) sourceDoc.get('Period__c');
            }
            ae.Company__c = companyID;
            ae.Currency__c = (Id)sourceDoc.get('Currency__c');
            
            //FIN-954 Adding new field Transaction_Type__c field to all source docs.
            String transactionTypeFromSD = (String)sourceDoc.get('Transaction_Type__c');
            //TODO:Comment the below line after all source docs start populating the new field Transaction_Type__c field            
            transactionTypeFromSD=(transactionTypeFromSD==null || transactionTypeFromSD=='')?transactionType:transactionTypeFromSD;
            ae.Transaction_Type__c = transactionTypeFromSD;
            
            ae.put(objectName, sourceDoc.Id);
            ae.source_document_object_name__c = objectName;
            ae.status__c = 'Draft';
            ae.source_key__c = sourceDoc.Id + '|' + ae.status__c + '|' + this.batchJobId;
            if(ae.source_document_object_name__c ==  'Invoice__c' || ae.source_document_object_name__c == 'Payment__c'){
                 ae.source_key__c = ae.source_key__c + '|' + ae.company__c;
            }           
            ae.BatchJobid__c =this.batchJobID;
            ae.source_lines_processed__c = null;
        }
        
        system.debug('returning: ' + ae);
        return ae;
    }
    /*
        Description: This method is used to generate the basis for each accounting entry line in each worker class
    */
    public virtual Accounting_Entry_Line__c generateAccountingEntryLine(Accounting_Entry__c acctEntry, sObject headerObj, sObject lineObj, Accounting_Rule__c ar, decimal amount){
        
        Accounting_Entry_Line__c ael = new Accounting_Entry_Line__c();
        ael.Transaction_Date__c = acctEntry.Transaction_Date__c.date();
        if(lineObj != null){
            ael.SubTransaction_Type__c = String.valueOf(lineObj.get('Subtransaction_Type__c'));
            ael.Line_Type__c = String.valueOf(lineObj.get('Line_Type__c'));
            ael.Source_ID__c = String.valueOf(lineObj.get('Id'));
            ael.Source_Name__c = String.valueOf(lineObj.get('Name'));
        }else{
            ael.Source_ID__c = String.valueOf(headerObj.get('Id'));
            ael.Source_Name__c = String.valueOf(headerObj.get('Name'));
        }
        //ael.Accounting_Entry__c = acctEntry.id;
        ael.Company__c = acctEntry.Company__c;
        ael.Accounting_Rule__c = ar.Id;
        ael.Accounting_Entry__r = new Accounting_Entry__c(source_key__c = acctEntry.source_key__c);
        TransactionDateList.add(ael.Transaction_Date__c);
        decimal absAmount;
        if((amount == null) )
         	{absAmount = null;}
        else if(amount != null){
        	absAmount = math.abs(amount);}
        else{
        	//absAmount = 0;
        	}
         
        //FIN-368
        if(ar.Expected_Sign__c == 'Positive' || ar.Expected_Sign__c == null){
            if(amount == null){
                if(ar.Rule_Type__c == 'CR'){
                    ael.amount_CR__c = absAmount;
                    ael.amount_DR__c = 0;
                }else if(ar.Rule_Type__c == 'DR'){
                    ael.amount_CR__c = 0;
                    ael.amount_DR__c = absAmount;
                }
            }else if(amount >= 0){
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
             if(amount == null){
                if(ar.Rule_Type__c == 'CR'){
                    ael.amount_CR__c = 0;
                    ael.amount_DR__c = absAmount;
                }else if(ar.Rule_Type__c == 'DR'){
                    ael.amount_CR__c = absAmount;
                    ael.amount_DR__c = 0;
                }
            }else if(amount <= 0){
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
            string strDt = AccountingRuleService.getValue(ar.FX_Date_Path__c, lineObj);
            if(strDt != null){
                DateTime iFXDt = getLocalDateTime(datetime.valueOf(strDt));
                ael.FX_Date__c = iFXDt;
                //TODO: Refactor so the explicit call for currencies does not need to be made from worker class - this super method can collect the trxn and fx dates incrementally
                // The exchange dates may not be known ahead of time, consider reselecting based on FX dates found here
                TransactionDateList.add(ael.FX_Date__c);
                TransactionDateList.add(iFXDt);
                //ael.FX_Date__c = datetime.valueOf(AccountingRuleService.getValue(ar.FX_Date_Path__c, lineObj));
                //system.debug('assigning FX Date: ' + ar.FX_Date_Path__c + ' - ' + ael.FX_Date__c + ' - ' + ael.FX_Flow__c + ' - ' + getLocalDateTime(datetime.valueOf(AccountingRuleService.getValue(ar.FX_Date_Path__c, lineObj))));
            }
        }else{
            ael.FX_Date__c = acctEntry.Transaction_Date__c;
        }
        
        /*
        //This assignment was pushed to the worker classes
        string sObjectName = util.getLocalNameFromObject(lineObj);
        string sourceDocLineField = mLineRelationships.get(sObjectName);
        if(sourceDocLineField != null){
            ael.put(sourceDocLineField, lineObj.Id);
        }
        */
        return ael;
    }

    public virtual boolean checkForActivateProposedCosts(Accounting_Entry__c acctEntry, sObject lineObj){
        return String.isNotBlank(acctEntry.Transaction_Type__c) 
                && acctEntry.Transaction_Type__c == 'Activate Proposed Costs'
                && lineObj != NULL                                                     
                && lineObj.getSObjectType() == Inventory_Transaction__c.getSObjectType()
                && lineObj.get('Standard_Cost__c') != NULL
                && (Decimal)(lineObj.get('Standard_Cost__c')) < 0;
    } 
    
    public virtual Accounting_Entry_Line__c generateAccountingEntryLineWithRole(Accounting_Entry__c acctEntry, sObject headerObj, sObject lineObj, Accounting_Rule__c ar, decimal amount){
        
        Accounting_Entry_Line__c ael = new Accounting_Entry_Line__c();
        ael.Transaction_Date__c = acctEntry.Transaction_Date__c.date();
        if(lineObj != null){
            ael.SubTransaction_Type__c = String.valueOf(lineObj.get('Subtransaction_Type__c'));
            ael.Line_Type__c = String.valueOf(lineObj.get('Line_Type__c'));
            ael.Source_ID__c = String.valueOf(lineObj.get('Id'));
            ael.Source_Name__c = String.valueOf(lineObj.get('Name'));
            ael.Role__c = String.valueOf(ar.get('Role__c'));
        }else{
            ael.Source_ID__c = String.valueOf(headerObj.get('Id'));
            ael.Source_Name__c = String.valueOf(headerObj.get('Name'));
        }
        //ael.Accounting_Entry__c = acctEntry.id;
        ael.Company__c = acctEntry.Company__c;
        ael.Accounting_Rule__c = ar.Id;
        ael.Accounting_Entry__r = new Accounting_Entry__c(source_key__c = acctEntry.source_key__c);
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
            string strDt = AccountingRuleService.getValue(ar.FX_Date_Path__c, lineObj);
            if(strDt != null){
                DateTime iFXDt = getLocalDateTime(datetime.valueOf(strDt));
                ael.FX_Date__c = iFXDt;
                //TODO: Refactor so the explicit call for currencies does not need to be made from worker class - this super method can collect the trxn and fx dates incrementally
                // The exchange dates may not be known ahead of time, consider reselecting based on FX dates found here
                TransactionDateList.add(ael.FX_Date__c);
                TransactionDateList.add(iFXDt);
                //ael.FX_Date__c = datetime.valueOf(AccountingRuleService.getValue(ar.FX_Date_Path__c, lineObj));
                //system.debug('assigning FX Date: ' + ar.FX_Date_Path__c + ' - ' + ael.FX_Date__c + ' - ' + ael.FX_Flow__c + ' - ' + getLocalDateTime(datetime.valueOf(AccountingRuleService.getValue(ar.FX_Date_Path__c, lineObj))));
            }
        }else{
            ael.FX_Date__c = acctEntry.Transaction_Date__c;
        }
        
        /*
        //This assignment was pushed to the worker classes
        string sObjectName = util.getLocalNameFromObject(lineObj);
        string sourceDocLineField = mLineRelationships.get(sObjectName);
        if(sourceDocLineField != null){
            ael.put(sourceDocLineField, lineObj.Id);
        }
        */
        return ael;
    }
    /*
        Description: This method is to be used when a distribution definition is not match between any effective accounting rule and the source doc
                        It returns a line with the proper CR/DR and Amount with no segments assigned
    */
    public Accounting_Entry_Line__c returnLineForMissingEffectiveDistroDefRule(Accounting_Entry__c ae, sObject rec, AccountingRuleService.DistributionDefinition distroDef, Allowance_Applied__c aa){
        Accounting_Entry_Line__c ael = new Accounting_Entry_Line__c();
        //ael.Accounting_Entry__c = ae.Id;
        ael.Accounting_Entry__r = new Accounting_Entry__c(source_key__c = ae.source_key__c);
        ael.SubTransaction_Type__c = distroDef.ruleDef.subTransType;
        ael.Line_Type__c = distroDef.ruleDef.lineType;
        ael.Source_ID__c = (string)rec.Id;// + '|' + ruleDef.rt;
        ael.Source_Name__c = (string)rec.get('name');
        ael.allocation_id__c = aa.id;
        if(distroDef.ruleDef.rt == AccountingRuleService.RuleType.CR){
            ael.Amount_CR__c = aa.Allowance_Amount__c;
            ael.Amount_DR__c = 0;
        }else if(distroDef.ruleDef.rt == AccountingRuleService.RuleType.DR){
            ael.Amount_CR__c = 0;
            ael.Amount_DR__c = aa.Allowance_Amount__c;
        }
        ael.Error_Message__c = 'Missing accounting rule. Make sure transaction date '+ String.valueof((datetime)ae.get('Transaction_Date__c'))+' meets the effective date requirement.';
        
        string sObjectName = rec.getSObjectType().getDescribe().getName();
        if(schemautil.getInstance().fieldExists('Accounting_Entry_Line__c', sObjectName)){
            ael.put(sObjectName, rec.Id);
        }
        return ael;
    }   
    
    /*
        Description: This method is to be used when a distribution definition is not match between the accounting rules and the source doc
                        It returns a line with the proper CR/DR and Amount with no segments assigned
    */
    public Accounting_Entry_Line__c returnLineForMissingDistroDefRule(Accounting_Entry__c ae, sObject rec, AccountingRuleService.DistributionDefinition distroDef, Allowance_Applied__c aa){
        Accounting_Entry_Line__c ael = new Accounting_Entry_Line__c();
        //ael.Accounting_Entry__c = ae.Id;
        ael.Accounting_Entry__r = new Accounting_Entry__c(source_key__c = ae.source_key__c);
        ael.SubTransaction_Type__c = distroDef.ruleDef.subTransType;
        ael.Line_Type__c = distroDef.ruleDef.lineType;
        ael.Source_ID__c = (string)rec.Id;// + '|' + ruleDef.rt;
        ael.Source_Name__c = (string)rec.get('name');
        ael.allocation_id__c = aa.id;
        if(distroDef.ruleDef.rt == AccountingRuleService.RuleType.CR){
            ael.Amount_CR__c = aa.Allowance_Amount__c;
            ael.Amount_DR__c = 0;
        }else if(distroDef.ruleDef.rt == AccountingRuleService.RuleType.DR){
            ael.Amount_CR__c = 0;
            ael.Amount_DR__c = aa.Allowance_Amount__c;
        }
        ael.Error_Message__c = Label.AccountingRule_could_not_be_found;
        
        string sObjectName = rec.getSObjectType().getDescribe().getName();
        if(schemautil.getInstance().fieldExists('Accounting_Entry_Line__c', sObjectName)){
            ael.put(sObjectName, rec.Id);
        }
        return ael;
    }   
    /*
        Description: This method is to be used when a rule definition from source doc corresponds to accounting rules which are not effective 
                        It returns a line with the proper CR/DR and Amount with no segments assigned
    */  
    public Accounting_Entry_Line__c returnLineForMissingEffectiveRule(Accounting_Entry__c ae, sObject rec, AccountingRuleService.RuleDefinition ruleDef, Decimal amount){
        return returnLineForMissingEffectiveRule(ae, rec, ruleDef, amount, false);
    }       

    public Accounting_Entry_Line__c returnLineForMissingEffectiveRule(Accounting_Entry__c ae, sObject rec, AccountingRuleService.RuleDefinition ruleDef, Decimal amount, Boolean nullFlag){
        Accounting_Entry_Line__c ael = new Accounting_Entry_Line__c();
        //ael.Accounting_Entry__c = ae.Id;
        ael.Accounting_Entry__r = new Accounting_Entry__c(source_key__c = ae.source_key__c);
        ael.SubTransaction_Type__c = ruleDef.subTransType;
        ael.Line_Type__c = ruleDef.lineType;
        ael.Source_ID__c = (string)rec.Id;// + '|' + ruleDef.rt;
        ael.Source_Name__c = (string)rec.get('name');
        if(nullFlag == true){
            ael.item_cost_missing__c = true;
        }else{
            ael.item_cost_missing__c = false;
        }
        if(ruleDef.rt == AccountingRuleService.RuleType.CR){
            ael.Amount_CR__c = amount;
            ael.Amount_DR__c = 0;
        }else if(ruleDef.rt == AccountingRuleService.RuleType.DR){
            ael.Amount_CR__c = 0;
            ael.Amount_DR__c = amount;
        }
        ael.Error_Message__c = 'Missing accounting rule. Make sure transaction date '+ String.valueof((datetime)ae.get('Transaction_Date__c'))+' meets the effective date requirement.';
        
        string sObjectName = rec.getSObjectType().getDescribe().getName();
        if(schemautil.getInstance().fieldExists('Accounting_Entry_Line__c', sObjectName)){
            ael.put(sObjectName, rec.Id);
        }
        system.debug('*** inside Line for missing effective rule'+ael);
        return ael;
    }   
    
    /*
        Description: This method is to be used when a rule definition is not match between the accounting rules and the source doc
                        It returns a line with the proper CR/DR and Amount with no segments assigned
    */
    public Accounting_Entry_Line__c returnLineForMissingRule(Accounting_Entry__c ae, sObject rec, AccountingRuleService.RuleDefinition ruleDef, Decimal amount){
        return returnLineForMissingRule(ae, rec, ruleDef, amount, false);
    }
    
    
    public Accounting_Entry_Line__c returnLineForMissingRule(Accounting_Entry__c ae, sObject rec, AccountingRuleService.RuleDefinition ruleDef, Decimal amount, Boolean nullFlag){
        Accounting_Entry_Line__c ael = new Accounting_Entry_Line__c();
        //ael.Accounting_Entry__c = ae.Id;
        ael.Accounting_Entry__r = new Accounting_Entry__c(source_key__c = ae.source_key__c);
        ael.SubTransaction_Type__c = ruleDef.subTransType;
        ael.Line_Type__c = ruleDef.lineType;
        ael.Source_ID__c = (string)rec.Id;// + '|' + ruleDef.rt;
        ael.Source_Name__c = (string)rec.get('name');
        if(nullFlag == true){
            ael.item_cost_missing__c = true;
            nullFlag = false;
        }else{
            ael.item_cost_missing__c = false;
        }
        if(ruleDef.rt == AccountingRuleService.RuleType.CR){
            ael.Amount_CR__c = amount;
            ael.Amount_DR__c = 0;
        }else if(ruleDef.rt == AccountingRuleService.RuleType.DR){
            ael.Amount_CR__c = 0;
            ael.Amount_DR__c = amount;
        }
        ael.Error_Message__c = Label.AccountingRule_could_not_be_found;
        
        string sObjectName = rec.getSObjectType().getDescribe().getName();
        if(schemautil.getInstance().fieldExists('Accounting_Entry_Line__c', sObjectName)){
            ael.put(sObjectName, rec.Id);
        }
        system.debug('*** inside Line for missing rule'+ael);
        return ael;
    }   
    public Boolean isMiscOrExpense(SObject sObj){
        String str = AccountingRuleService.getValue('Item__r.Source__c',sObj);
        if(str == null){
            return false;
        }else{
            return (str.ToLowerCase() == 'miscellaneous' || str.toLowerCase() == 'expense');
        }
    }   
    
    public set<String> sourceDocsSet{
        get{
            Schemautil util = schemautil.getInstance();
            Set<String> SDset = new Set<String>();
            if(SDset.size() < 1){
                for(String str: util.getFieldsFromFieldSetString(Journal_Entry__c.sObjectType , 'Source_documents')){
                    SDset.add(str);
                }
            }
            return SDset;
        }
        set;
    }
   
    
    private List<Accounting_Entry__c> finishedAccountingEntries = new List<Accounting_Entry__c>();
    public list<Accounting_Entry__c> getFinishedAccountingEntries(){
        return finishedAccountingEntries;
    }
    
    // collectexchangerates ==> using AE list
    public List<Exchange_Rate__c> exchangeRates = new List<Exchange_Rate__c>();
    public void clearExchangeRates(){
        exchangeRates = new List<Exchange_Rate__c>();
    }
    public void findExchangeRates(List<DateTime> exchangeRateDates){
        if(exchangeRateDates == null || exchangeRateDates.isEmpty()){
            //throw new AccountingException('No transaction dates were provided.');
            return;
        }
        exchangeRateDates.sort();
        Datetime beginDateTime = exchangeRateDates[0];//getLocalDateTime(exchangeRateDates[0]);
        Datetime endDateTime = exchangeRateDates[exchangeRateDates.size()-1];//getLocalDateTime(exchangeRateDates[exchangeRateDates.size()-1]);
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Exchange_Rate__c', false); //enforceFLS=false, running in system mode
        soql.addFields(new set<string>{
            'id','Name','Rate_Start_DateTime__c','Rate_End_DateTime__c','From_Currency__c','From_Currency__r.ISO_code__c','To_Currency__c','To_Currency__r.ISO_code__c','Daily_Monthly__c','Multiplier_Exchange_Rate__c', 'Currency_To__c', 'Currency_From__c'
        });
        soql.setWhereClause('Rate_End_DateTime__c >= :beginDateTime or Rate_Start_DateTime__c <= :endDateTime');
        soql.setOrderByClause('Rate_Start_DateTime__c');
        exchangeRates = Database.query(soql.getQuery());
    }
    
    
    // returnexchangerate == > based on the specific curr and date
    public Exchange_Rate__c returnExchangeRate(string FromCurrency, string ToCurrency, ID FromCurrencyID, ID ToCurrencyID, DateTime TransactionDate, String dailymonthly){
        string descr = 'from: ' + FromCurrencyID + ' To: ' + ToCurrencyID + ' TD: ' + TransactionDate + ' DM: ' + dailyMonthly;
        system.debug(logginglevel.info, descr);
        Exchange_Rate__c myRate;
        if(FromCurrency == ToCurrency){
                myRate = new Exchange_Rate__c(Multiplier_Exchange_Rate__c = 1, From_Currency__c = FromCurrencyID, To_Currency__c = ToCurrencyID, Currency_To__c = ToCurrency, Currency_From__c = FromCurrency, daily_monthly__c = dailymonthly);
        }
        else if(exchangeRates != null){
            for(Exchange_Rate__c thisRate: exchangeRates){
                system.debug('thisRate: ' + thisRate);
                if(TransactionDate >= thisRate.Rate_Start_DateTime__c &&
                        (thisRate.Rate_End_DateTime__c == null || TransactionDate < thisRate.Rate_End_DateTime__c ) &&
                        thisRate.From_Currency__r.ISO_code__c.equalsIgnoreCase(FromCurrency) &&
                        ThisRate.To_Currency__r.ISO_code__c.equalsIgnoreCase(ToCurrency) &&
                        thisRate.Daily_Monthly__c.equalsIgnoreCase(dailymonthly))
                {
                    myRate = thisRate;
                    system.debug(logginglevel.info,'myRate: '+myRate);
                    break;
                }
            }
        }
        if(myRate == null){
            //throw new AccountingException('No exchange rate found: ' +  descr + ' - ' + exchangeRates);
        }
        return myRate;
    }
    
    /*
    public Task returnMissingExchangeException(String FromCurrency, String ToCurrency, DateTime TransactionDate, String dailymonthly){
        Task currExcTask = new Task();
        currExcTask.subject = 'Missing ' + dailyMonthly + ' Currency Exchange';
        currExcTask.status = 'Open';
        currExcTask.priority = 'Normal';
        currExcTask.Description = 'Missing ' + dailyMonthly + 'Currency Exchange from ' + FromCurrency + ' to ' + ToCurrency + ' on ' + TransactionDate.format();
        currExcTask.Type = 'Exception';
        return currExcTask;
    }
    */
    
    

    //This is a short term solution for capturing FX - need to optimize asap
    public Map<Id, GL_Account__c> mMonetaryNonCashGLAccounts {
        get {
            if (mMonetaryNonCashGLAccounts == null) {
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                SOQLUtil soql = new SOQLUtil('GL_Account__c', false); //enforceFLS=false, running in system mode
                soql.addFields(new set<string>{
                    'Id','name','FX_Type__c'
                });
                soql.setWhereClause('FX_Type__c = \'Monetary Non-cash\' or FX_Type__c = \'P/L Non-monetary\'');
                mMonetaryNonCashGLAccounts = new Map<Id, GL_Account__c>((List<GL_Account__c>)Database.query(soql.getQuery()));
            }
            return mMonetaryNonCashGLAccounts;
        }
        set;
    }

    public Map<Id, GL_Account__c> mMonetaryCashGLAccounts {
        get {
            if (mMonetaryCashGLAccounts == null) {
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                SOQLUtil soql = new SOQLUtil('GL_Account__c', false); //enforceFLS=false, running in system mode
                soql.addFields(new set<string>{
                    'Id','name','FX_Type__c'
                });
                soql.setWhereClause('FX_Type__c = \'Monetary Cash\' or FX_Type__c = \'P/L Monetary\'');
                mMonetaryCashGLAccounts = new Map<Id, GL_Account__c>((List<GL_Account__c>)Database.query(soql.getQuery()));
            }
            return mMonetaryCashGLAccounts;
        }
        set;
    }

    //RS: 2014-5-16 I'm concerned about this function with regard to daylight savings time - although it seems to work fine right now
    public Datetime getLocalDateTime(Datetime gmtDt){
        //Date currDate = gmtDt.date();
        //Time currTime = gmtDt.time();
        //return Datetime.newInstance(currDate, currTime);
        TimeZone tz = UserInfo.getTimeZone();
        integer seconds = tz.getOffset(gmtDt)/1000;
        return gmtDt.addSeconds(seconds);
    }
    
    private GL_Account__c rfxGL;
    private GL_Type__c rfxGLType;
    public GL_Account__c returnRFX(){
        if(rfxGL == null){
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            SOQLUtil soql = new SOQLUtil('GL_Account__c', false); //enforceFLS=false, running in system mode
            soql.addFields(new set<string>{
                'Id'
            });
            soql.setWhereClause('FX_Type__c = \'RFX\'');
            soql.setLimit(1);
            List<GL_Account__c> rfxGLs = Database.query(soql.getQuery());

            if(rfxGLs.size() > 0){
                rfxGL = rfxGLs[0];
            }/*else{
                rfxGLType = new GL_Type__c(name = 'RFX GL Type', Normal_Balance__c  = 'Credit',
                Accounting_Type__c  = 'Other Comprehensive Income',
                Statement_Type__c  = 'Income Statement',
                Account_Range_From__c = '870000',
                Account_Range_To__c ='879999' );
                DML.insertAsSystem(rfxGLType);
                rfxGL = new GL_Account__c(name = 'RFX', GL_Account_Number__c = '870000', GL_Account_Name__c = 'RFX',FX_Type__c = 'RFX', active__c = true, normal_balance__c = 'Debit', GL_Type__c = rfxGLType.id) ;
                DML.insertAsSystem(rfxGL);
            }*/
        }
        return rfxGL;
    }
    
    
    //This map is used to manage which source doc lines have been seen in the accounting entry generation process
    //private Map<Id, integer> mSourceDocLineAccounting  = new Map<Id, integer>();
    
    public void finish(Map<Id, sObject> mHeaders, Map<Id, sObject> mLines, list<FinishWrapper> fwrapList){
        //Reset the exchange rates from anything the workers might have needed
            system.debug('In finish ****   ' + 'fwrapList:  ' +fwrapList + 'mHeaders: ' + mHeaders + 'mLines: ' + mLines);
        if(mRules==null)
        {
            if(mHeaders.size()>0)
            {
               throw new AccountingException('Please call loadEffRuleDetails() method to load mRules map in the accounting worker.');                   
            }
            else
            {
                //Do nothing as empty sobject list has been passed for accounting generation.
            }
        }
        else
        {
            List<DateTime> exchangeDateTimes = new List<DateTime>();
            List<Accounting_Entry_Line__c> aels = new List<Accounting_Entry_Line__c>();
            list<Accounting_Entry__c> AEs = new list<Accounting_Entry__c> ();
            map<id,Accounting_Entry__c> mAEs = new map<id,Accounting_Entry__c> ();
			set<Id> companyIds = new set<Id>();
            for(FinishWrapper fw : fwrapList){
                exchangeDateTimes.add(fw.SourceDocAE.Transaction_Date__c);
                exchangeDateTimes.add(fw.SourceDocAE.Finalized_Date__c);
		    	companyIds.add(fw.SourceDocAE.Company__c);
                for(Accounting_Entry_Line__c ael : fw.SourceDocAEls){
                    exchangeDateTimes.add(ael.FX_Date__c);
                }
                AEs.add(fw.SourceDocAE);
            }
            
		    populateCompanyMap(companyIds);
		    
            findExchangeRates(exchangeDateTimes);
            
            AccountingEntryService.getInstance().assignSourceKey(AEs);
            
            upsert AEs source_key__c;
            for(Accounting_Entry__c ae: AEs){
                mAEs.put(ae.id, ae);
            }
            
            list<sObject> refAEs = mAEs.values();
            
            //now requery for the line count and other interesting fields
            set<string> aeFields = new set<string>();
            string aeRefQuery = 'SELECT ';
            for(Schema.FieldSetMember fsm : util.getFieldsFromFieldSet(Accounting_Entry__c.getSObjectType(), 'Validate')){
                aeFields.add(fsm.getFieldPath());
            }
            aeFields.addAll(new List<string>{'Source_Lines_Processed__c', 'Related_Accounting_Entry__c', 'CreatedDate', 'Source_Reference__c', 'Status__c', 'Total_Lines__c', 'Total_Amount_CR__c', 'Total_Amount_DR__c', 'Currency__r.ISO_Code__c' ,'Company__r.comp_currency__c','Company__r.comp_currency__r.ISO_Code__c','Company__r.consol_currency__c','Company__r.consol_currency__r.ISO_Code__c','Company__r.Stat_Currency__c','Company__r.Stat_Currency__r.ISO_Code__c', 'Company__r.Subs_Currency__c','Company__r.Subs_Currency__r.ISO_Code__c', 'Currency__c'});
            aeFields = SchemaUtil.getInstance().removeNSfromSetString(aeFields);
            
            aeRefQuery += string.join(new list<string>(aeFields), ', ');    
            
            aeRefQuery += ' FROM Accounting_Entry__c ';
            aeRefQuery += ' WHERE Id IN :refAEs';
            system.debug('aeRefQuery: ' + aeRefQuery);
            for(Accounting_Entry__c ae : Database.query(aeRefQuery)){
                mAEs.put(ae.id, ae);
            }  
            
            for(FinishWrapper fw : fwrapList){
                
                sObject source;
                Id sourceDocId;
                sObject sourceDoc;
                Accounting_Entry__c ae = fw.SourceDocAE;
                system.debug('ae: ' + ae);

                for(Accounting_Entry_Line__c ael :fw.SourceDocAELs){
                    Id sourceId = id.valueof(ael.Source_ID__c);
                    if(mLines.containsKey(sourceId)){
                        source = mLines.get(sourceId);
                        //Find the source document header Id
                        string sourceDocLineName = schemaUtil.getInstance().getLocalNameFromObject(source);
                        for(string s : mLinesToHeader.get(sourceDocLineName)){
                            if(s != null){
                                if((Id)source.get(s) != null){
                                    sourceDocId = (Id)source.get(s);
                                }
                            }else{
                                sourceDocId = (Id)source.get('Id');
                            }
                        }
                        
                        
                        //Increment the AE Source Lines Processed count
                        ae.Source_Lines_Processed__c = ae.Source_Lines_Processed__c == null ? 0 : ae.Source_Lines_Processed__c;
                        ae.Source_Lines_Processed__c += 1;
                        mAEs.put(ae.id, ae);
                        
                    }else if(mHeaders.containsKey(sourceId)){
                        source = mHeaders.get(sourceId);
                        sourceDoc = mHeaders.get(sourceId);
                        sourceDocId = sourceId;
                    }else{
                        //Can't find the source doc/line
                        continue;
                    }
                }
                    
                //If we skipped accounting for this source doc line - move on to the next record
                if(fw.SourceDocAELs.size() == 0) {continue;}
                
                
                //Grab the Accounting Entry header for this source doc
		    	Company__c iCompany = mCompanies.get(ae.company__c); 
                
                decimal totalFuncDR = 0;
                decimal totalFuncCR = 0;

                decimal totalTransDR = 0;
                decimal totalTransCR = 0;
                
                for(Accounting_Entry_Line__c ael :fw.SourceDocAELs){
                    
                    //FIN-753 Omit 0/CR 0/DR lines
                     Accounting_Rule__c iAR = mRules.get(ael.accounting_rule__c);
                    system.debug(logginglevel.Info,'iAR:========*********========'+iAR);
                    // Set the amounts = 0 if the raise exception for blank amount is not true to avoid having nulls in the amount fields.
                    if(iAR != null && iAR.Raise_Exceptions_for_Blank_Amounts__c == false && ael.amount_cr__c == null){
                    	ael.amount_cr__c = 0;
                    }
                    if(iAR != null && iAR.Raise_Exceptions_for_Blank_Amounts__c == false && ael.amount_dr__c == null){
                    	ael.amount_dr__c = 0;
                    }
                    system.debug(logginglevel.info,'ael.amount_dr__c:'+ael.amount_dr__c+'*********===========*********ael.amount_cr__c:'+ael.amount_cr__c);
                    if((ael.amount_cr__c == 0 ) 
                            && (ael.amount_dr__c == 0 ) 
                            && ael.item_cost_missing__c == false
                            && ael.subtransaction_type__c != 'RFX'
                            && ael.subtransaction_type__c != 'UFX'
                            && ael.subtransaction_type__c != 'PL RFX'
 	                       	&& ael.Error_Message__c==null   && iAR.Suppress_Zero_Amount_Lines__c){
                        	system.debug(logginglevel.info,'skipping ael DR/CR 0/0: ' + ael);
                        continue;
                    }
                    
                    boolean isMonetaryNonCash = mMonetaryNonCashGLAccounts.containsKey(ael.gl_account__c);
                    
                    //Assign the ledger values and conversion rates
                    populateLedgers(iAR, ae, ael);
    		system.debug('Error_Message__c ======== ' + ael.Error_Message__c);
                    
	            	if(iAR != null && ael.Error_Message__c == null && iAR.Raise_Exceptions_for_Blank_Amounts__c && (ael.amount_cr__c == null || ael.amount_dr__c == null)){
	            		ael.Error_Message__c = 'Raise Exception';
	            	}
                    aels.add(ael);

                    if(ae.Currency__c != ae.Company__r.Comp_Currency__c){
                        System.debug(LoggingLevel.ERROR, 'Using diff currency');
                        totalFuncCR += ael.COMP_Functional_Currency_Amount_CR__c == null ? 0 : ael.COMP_Functional_Currency_Amount_CR__c;
                        totalFuncDR += ael.COMP_Functional_Currency_Amount_DR__c == null ? 0 : ael.COMP_Functional_Currency_Amount_DR__c;
                        totalTransCR += ael.COMP_Transaction_Currency_Amount_CR__c == null ? 0 : ael.COMP_Transaction_Currency_Amount_CR__c;
                        totalTransDR += ael.COMP_Transaction_Currency_Amount_DR__c == null ? 0 : ael.COMP_Transaction_Currency_Amount_DR__c;

                        system.debug(LoggingLevel.ERROR, 'Total Func DR: ' + totalFuncDR + '\tTotal Func CR: ' + totalFuncCR + '\tTot Tran DR: ' + totalTransDR + '\tTotal Tran CR: ' + totalTransCR);
                    }
                }
                
                Decimal delta = totalFuncDR - totalFuncCR;
                Decimal tranDelta = totalTransDR - totalTransCR;

                System.debug(LoggingLevel.ERROR, 'Delta: ' + delta + '\tTrans Delta: ' + tranDelta);
                if(totalTransDR > 0 && totalTransDR == totalTransCR && delta != 0){
                    //RFX exists.  Create RFX entry
                    Id rfxId = returnRFX() != null ? returnRFX().Id : null;
                    Accounting_Entry_Line__c rfxAEL = new Accounting_Entry_Line__c( GL_Account__c = rfxId, 
                                                                                    Source_Id__c = ae.Source_Reference__c + '|RFX', 
                                                                                    Accounting_Entry__r = ae, 
                                                                                    COMP_Functional_Currency_Amount_CR__c = 0, 
                                                                                    COMP_Functional_Currency_Amount_DR__c = 0,
                                                                                    COMP_Transaction_Currency_Amount_CR__c = 0, 
                                                                                    COMP_Transaction_Currency_Amount_DR__c = 0,
                                                                                    Subtransaction_Type__c = 'RFX');

                    rfxAEL.COMP_Functional_Currency_Amount_CR__c = delta > 0 ? math.abs(delta) : 0;
                    rfxAEL.COMP_Functional_Currency_Amount_DR__c = delta < 0 ? math.abs(delta) : 0;

                    aels.add(rfxAEL);
                }
            }
            
            
            //Create the Accounting Entry Lines
            system.debug('aels: ' +aels.size() + ' - ' + aels);
            AccountingCodeService.generateSCOACode(aels);
            insert aels;
            
            //Update the Source Lines Processed on the headers          
            update mAEs.values();
            
            //Replay validation - build fields for query and comparison
            List<Schema.FieldSetMember> aelFieldSet = util.getFieldsFromFieldSet(Accounting_Entry_Line__c.getSObjectType(), 'Validate');
            set<string> aelFields = new set<string>();
            Map<string, Accounting_Entry_Line__c> mOldAEL = new Map<String, Accounting_Entry_Line__c>();
            map<string, Task> mTasks = new map<string, Task>();
            set<Id> sdlIds = new set<Id>(mLines.keySet());
            
            string query = 'SELECT ';
            for(Schema.FieldSetMember fsm : aelFieldSet){
                aelFields.add(fsm.getFieldPath());
            }
            aelFields.addAll(new List<string>{'Source_Reference__c', 'GL_Account__r.FX_Type__c', 'Allocation_ID__c', 'Accounting_Entry__r.Status__c', 'Accounting_Entry__r.Source_Reference__c', 'Accounting_Entry__c'}); 
            aelFields = SchemaUtil.getInstance().removeNSfromSetString(aelFields);
            
            query += string.join(new list<string>(aelFields), ', ') + ' ';
            
            query += 'FROM Accounting_Entry_Line__c ';
            if(sObjectName == 'Fixed_Asset_Adjustment__c'){
                query += 'WHERE Accounting_Entry__r.Fixed_Asset_Adjustment__c IN :sdlIds';
            }else if(sObjectName == 'Fixed_Asset_Depreciation__c'){
                query += 'WHERE Accounting_Entry__r.Fixed_Asset_Depreciation__c IN :sdlIds';
            }else{
                query += 'WHERE ' + mHeaderToLines.get(sObjectName) + ' IN :sdlIds';
            }
            
            system.debug(logginglevel.info, 'query: ' + query);
            
            //Query for the Accounting Entry Lines considered in the validation     
            List<Accounting_Entry_Line__c> refAELs = Database.Query(query + ' AND Accounting_Entry__r.Status__c != \'Obsolete\'');
            
            system.debug('refAELs**** '  +refAELs);
            //Remove fields we do NOT want to consider during the validation process, but were still potentially used in the query 
            aelFields.removeAll(new List<string>{'Id', 'Autonumber__c', 'CreatedDate', 'LastModifiedDate', 'CreatedById', 'LastModifiedById', 'Name', 'GL_Account__r.FX_Type__c', 'Source_Key__c', 'Source_Reference__c', 'Allocation_ID__c', 'Accounting_Entry__r.Source_Reference__c', 'Accounting_Entry__r.Status__c', 'Accounting_Entry__c'});
            
            map<string, Accounting_Entry_Line__c> mDraftAELs = new map<string, Accounting_Entry_Line__c>();
            map<string, Accounting_Entry_Line__c> mActiveAELs = new map<string, Accounting_Entry_Line__c>();
            
            //Loop through the accounting and organize by draft and active 
            for(Accounting_Entry_Line__c ael : refAELs){
                if(ael.Accounting_Entry__r.Status__c == 'Active' || ael.Accounting_Entry__r.Status__c == null){
                    mActiveAELs.put(ael.source_reference__c, ael);
                }else if(ael.Accounting_Entry__r.Status__c == 'Draft'){
                    mDraftAELs.put(ael.source_reference__c, ael);
                }
            }
            
            //Extend this query to pull manual ledger roll up fields?
            List<Task> aeRefTasks = [SELECT Id, subject, whatId, description
                                        FROM Task
                                    WHERE subject = 'Accounting Entry Validation'
                                    AND whatId IN :mAEs.values()
                                    ORDER BY lastmodifieddate];
            
            for(Task t : aeRefTasks){
                mTasks.put(t.whatId, t);
            }                                       
            
            set<Id> matchIds = new set<Id>();
            
            //Now scrub the fields on the Accounting Entry Lines using the Validate fieldset
            for(string draftAELRef : mDraftAELs.keySet()){
                
                Accounting_Entry_Line__c iDraftAEL = mDraftAELs.get(draftAELRef);
                
                boolean isMatch = true;
                Task iTask;
                if(mTasks.containsKey(iDraftAEL.Accounting_Entry__c)){
                    iTask = mTasks.get(iDraftAEL.Accounting_Entry__c);
                }else{
                    iTask = new Task(Status = 'Open', Priority='Normal', Subject='Accounting Entry Validation', Description='', whatId = iDraftAEL.Accounting_Entry__c);
                }
                                
                if(mActiveAELs.containsKey(iDraftAEL.source_reference__c)){
                    
                    //If the draft Accounting Entry Line has no source reference, that means that there is no rule or something else wrong with the record
                    if(iDraftAEL.source_reference__c == null){
                        if(iDraftAEL.GL_Account__r.FX_Type__c == 'RFX'){
                            //TODO: Enhance RFX checks, currently reliant on other fields validate which would ultimately drive the RFX value
                            continue;
                        }else{
                            //TODO: Further checks for relationship to lines?
                            isMatch = false;
                            iTask.Description += iDraftAEL.Name + ' is missing an Accounting Rule' +' \n';
                        }
                    }
                    
                    Accounting_Entry_Line__c iActiveAEL = mActiveAELs.get(iDraftAEL.source_reference__c);
    
                    if(iActiveAEL == null){
                        //Treat this as a net new Accounting Entry Line
                        iTask.Description += iDraftAEL.Name + Label.Has_no_prior_records_for_comparison +' \n';
                        isMatch = false;
                    }else{
                        //Compare the old and the New Accounting Entry Line records
                        for(string aelFieldPath : aelFields){
                            if(AccountingRuleService.getValue(aelFieldPath, iDraftAEL) != AccountingRuleService.getValue(aelFieldPath, iActiveAEL)){
                                isMatch = false;
                                iTask.Description += iDraftAEL.Name + ' - ' + aelFieldPath + ' - ' + Label.Changed_from + ' ' + AccountingRuleService.getValue(aelFieldPath, iActiveAEL) + ' '+ Label.to + ' ' + AccountingRuleService.getValue(aelFieldPath, iDraftAEL) + '\n';
                                system.debug('MISMATCH: ' + aelFieldPath + ' - ' + AccountingRuleService.getValue(aelFieldPath, iActiveAEL) + ' - ' + AccountingRuleService.getValue(aelFieldPath, iDraftAEL));
                            }
                        }
                    }
                }else{
                    //No prior value could be found for this Accounting Entry Line
                    iTask.Description += iDraftAEL.name + ' ' + Label.Has_no_prior_entry_for_comparison + '\n';
                    isMatch = false;
                }
                
                if(isMatch){
                    matchIds.add(iDraftAEL.Id);
                }else{
                    mTasks.put(iDraftAEL.Accounting_Entry__c, iTask);
                }
            }
            
            //Commit only the tasks with changes logged
            list<task> tasks = new list<task>();
            for(Task t : mTasks.values()){
    
                if(t.description.length() > 0){
                    if(t.description.length() > 31500){
                        t.description = t.description.left(31500) + '...';
                    }
                    tasks.add(t);
                }
            }
            
                upsert tasks;   
            
            map<Id,sObject> mCompletedSourceDocAccountingIds = new map<Id,sObject>();
            for(Id headerId : mHeaders.keySet()){
                
                integer totalNumberOfLines = 0;
                sObject header = mHeaders.get(headerId);
                if(schemaUtil.getInstance().fieldExists(sObjectName, 'total_number_of_lines__c')){
                    totalNumberOfLines = integer.valueOf(header.get('total_number_of_lines__c'));
                }
            system.debug('totalNumberOfLines **** ' + totalNumberOfLines);
                boolean addHeader = false;
                for(Accounting_Entry__c iAE : mAEs.values()){
            system.debug('inside if iAE.Source_Document_Object_Name__c **** ' + iAE.Source_Document_Object_Name__c);
            system.debug('inside if SchemaUtil.getinstance().removeNSfromString(headerId.getSObjectType().getDescribe().getName()) **** ' + SchemaUtil.getinstance().removeNSfromString(headerId.getSObjectType().getDescribe().getName()));
                    if(iAE.Source_Document_Object_Name__c == SchemaUtil.getinstance().removeNSfromString(headerId.getSObjectType().getDescribe().getName())){
                        iAE.Source_Lines_Processed__c = iAE.Source_Lines_Processed__c == null ? 0 : iAE.Source_Lines_Processed__c;
                        if(iAE.Source_Lines_Processed__c >= totalNumberOfLines){
                            addHeader = true;
                        }
                        else{
                            addHeader = false;
                        }
                    }
                    else{continue;}
                
                }
                if(addHeader == true){
                    mCompletedSourceDocAccountingIds.put(header.Id, header);
                }
            }
            system.debug('mCompletedSourceDocAccountingIds: ' + mCompletedSourceDocAccountingIds);
            
            if(mCompletedSourceDocAccountingIds.keySet().size() > 0){
                validateCompletedAccounting((map<Id, sObject>)mCompletedSourceDocAccountingIds);
            }   
        }       

    }   
    
    public void finish(Map<Id, sObject> mHeaders, Map<Id, sObject> mLines, Map<Id, Accounting_Entry__c> mAEs, Map<Id, List<Accounting_Entry_Line__c>> mAELs){
        
        //Reset the exchange rates from anything the workers might have needed
        //clearExchangeRates();
        if(mRules==null)
        {
            if(mHeaders.size()>0)
            {
               throw new AccountingException('Please call loadEffRuleDetails() method to load mRules map in the accounting worker.');                   
            }
            else
            {
                //Do nothing as empty sobject list has been passed for accounting generation.
            }
        }
        else
        {
            List<DateTime> exchangeDateTimes = new List<DateTime>();
            List<Accounting_Entry_Line__c> aels = new List<Accounting_Entry_Line__c>();
	        set<Id> companyIds = new set<Id>();
            //TODO: Collect this in the super generate template methods?
            //Collect the transaction dates from the accounting entries to identify exchange rates
            for(Accounting_Entry__c ae : mAEs.values()){
                exchangeDateTimes.add(ae.Transaction_Date__c);
                exchangeDateTimes.add(ae.Finalized_Date__c);
		        companyIds.add(ae.Company__c);
            }
            
            for(List<Accounting_Entry_Line__c> aelines : mAELs.values()){
                for(Accounting_Entry_Line__c ael : aelines){
                    exchangeDateTimes.add(ael.FX_Date__c);
                }
            }
            
		    populateCompanyMap(companyIds);
		    
            system.debug(logginglevel.info, 'exchangeDateTimes: ' + exchangeDateTimes);
            findExchangeRates(exchangeDateTimes);
            
            AccountingEntryService.getInstance().assignSourceKey(mAEs.values());
            
            system.debug('mAEs.values(): '+ mAEs.values());
            DML.upsertAsSystem(); upsert mAEs.values() source_key__c;
            list<sObject> refAEs = mAEs.values();
            
            //now requery for the line count and other interesting fields
            set<string> aeFields = new set<string>();
            for(Schema.FieldSetMember fsm : util.getFieldsFromFieldSet(Accounting_Entry__c.getSObjectType(), 'Validate')){
                aeFields.add(fsm.getFieldPath());
            }
            aeFields.addAll(new List<string>{'Source_Lines_Processed__c', 'Related_Accounting_Entry__c', 'CreatedDate', 'Source_Reference__c', 'Status__c', 'Total_Lines__c', 'Total_Amount_CR__c', 'Total_Amount_DR__c', 'Currency__c', 'Currency__r.ISO_Code__c' ,'Company__r.comp_currency__c','Company__r.comp_currency__r.ISO_Code__c','Company__r.consol_currency__c','Company__r.consol_currency__r.ISO_Code__c','Company__r.Stat_Currency__c','Company__r.Stat_Currency__r.ISO_Code__c', 'Company__r.Subs_Currency__c','Company__r.Subs_Currency__r.ISO_Code__c','Supplier_Invoice_Transaction_Date__c','Fixed_Asset_Depreciation__r.Depreciation_Type__c', 'Fixed_Asset_Depreciation__r.Fixed_Asset__r.Supplier_Invoice__r.Transaction_Date__c'});
            aeFields = SchemaUtil.getInstance().removeNSfromSetString(aeFields);

            SOQLUtil aeQuery = new SOQLUtil('Accounting_Entry__c', TRUE);
            aeQuery.addFields(aeFields);
            aeQuery.setWhereClause('Id IN :refAEs');
            system.debug('aeRefQuery: ' + aeQuery.getQuery());
            for(Accounting_Entry__c ae : Database.query(aeQuery.getQuery())){
                mAEs.put((Id)ae.get(AccountingEntryService.SourceDocPathMap.get(sObjectName)), ae);
            }  
            
            //for(sObject sdl : mLines.values()){
            for(Id sourceId : mAELs.keySet()){
                
                sObject source;
                Id sourceDocId;
                sObject sourceDoc;
                
                if(mLines.containsKey(sourceId)){
                    source = mLines.get(sourceId);
                    //Find the source document header Id
                    string sourceDocLineName = schemaUtil.getInstance().getLocalNameFromObject(source);
                    for(string s : mLinesToHeader.get(sourceDocLineName)){
                        if(s != null){
                            if((Id)source.get(s) != null){
                                sourceDocId = (Id)source.get(s);
                            }
                        }else{
                            sourceDocId = (Id)source.get('Id');
                        }
                    }
                    
                    /*
                    //Grab the Source Document and manage the map of the line counts
                    sourceDoc = mHeaders.get(sourceDocId);
                    if(!mSourceDocLineAccounting.containsKey(sourceDoc.Id)){
                        if(SchemaUtil.getInstance().fieldExists(schemaUtil.getInstance().getLocalNameFromObject(sourceDoc), 'Total_Number_of_Lines__c')){
                            mSourceDocLineAccounting.put(sourceDoc.Id, integer.valueOf(sourceDoc.get('Total_Number_of_Lines__c')));
                        }else{
                            mSourceDocLineAccounting.put(sourceDoc.Id, 0); //or 2?
                        }
                    }
                    //Decrement the line counts in the map
                    mSourceDocLineAccounting.put(sourceDoc.Id, mSourceDocLineAccounting.get(sourceDoc.Id) - 1);
                    */
                    
                    //Increment the AE Source Lines Processed count
                    Accounting_Entry__c ae = mAEs.get(sourceDocId);
                    system.debug('ae: ' + ae);
                    ae.Source_Lines_Processed__c = ae.Source_Lines_Processed__c == null ? 0 : ae.Source_Lines_Processed__c;
                    ae.Source_Lines_Processed__c += 1;
                    mAEs.put((Id)ae.get(AccountingEntryService.SourceDocPathMap.get(sObjectName)), ae);
                    
                }else if(mHeaders.containsKey(sourceId)){
                    source = mHeaders.get(sourceId);
                    sourceDoc = mHeaders.get(sourceId);
                    sourceDocId = sourceId;
                }else{
                    //Can't find the source doc/line
                    continue;
                }
                    
                //If we skipped accounting for this source doc line - move on to the next record
                if(mAELs.get(source.Id).size() == 0) {continue;}
                
                system.debug('sourceDocId: ' + sourceDocId + ' ' + mAEs);
                
                //Grab the Accounting Entry header for this source doc
                Accounting_Entry__c ae = mAEs.get(sourceDocId);
		    	Company__c iCompany = mCompanies.get(ae.company__c); 
                
                decimal totalFuncDR = 0;
                decimal totalFuncCR = 0;

                decimal totalTransDR = 0;
                decimal totalTransCR = 0;
                
                for(Accounting_Entry_Line__c ael : mAELs.get(source.Id)){
                    
                     Accounting_Rule__c iAR = mRules.get(ael.accounting_rule__c);
                    //FIN-753 Omit 0/CR 0/DR lines
                    
                    if(iAR != null && iAR.Raise_Exceptions_for_Blank_Amounts__c == false && ael.amount_cr__c == null){
                    	ael.amount_cr__c = 0;
                    }
                    if(iAR != null && iAR.Raise_Exceptions_for_Blank_Amounts__c == false && ael.amount_dr__c == null){
                    	ael.amount_dr__c = 0;
                    }
                    system.debug(logginglevel.info,'ael.amount_dr__c:'+ael.amount_dr__c+'*********===========*********ael.amount_cr__c:'+ael.amount_cr__c);
                    
                    
                    if((ael.amount_cr__c == 0 ) 
                            && (ael.amount_dr__c == 0) 
                            && ael.item_cost_missing__c == false
                            && ael.subtransaction_type__c != 'RFX'
                          	&& ael.subtransaction_type__c != 'UFX'
                            && ael.subtransaction_type__c != 'PL RFX'
                        	&& ael.Error_Message__c==null  &&  iAR.Suppress_Zero_Amount_Lines__c ){
                        system.debug(logginglevel.info,'skipping ael DR/CR 0/0: ' + ael);
                        continue;
                    }
                    
                    boolean isMonetaryNonCash = mMonetaryNonCashGLAccounts.containsKey(ael.gl_account__c);
                    
                    //Assign the ledger values and conversion rates
                    populateLedgers(iAR, ae, ael);
                    
	            	if(iAR != null && ael.Error_Message__c == null && iAR.Raise_Exceptions_for_Blank_Amounts__c && (ael.amount_cr__c == null || ael.amount_dr__c == null)){
	            		ael.Error_Message__c = 'Raise Exception';
	            	}
                    aels.add(ael);


                    if(ae.Currency__c != ae.Company__r.Comp_Currency__c){
                        totalFuncCR += ael.COMP_Functional_Currency_Amount_CR__c == null ? 0 : ael.COMP_Functional_Currency_Amount_CR__c;
                        totalFuncDR += ael.COMP_Functional_Currency_Amount_DR__c == null ? 0 : ael.COMP_Functional_Currency_Amount_DR__c;
                        totalTransCR += ael.COMP_Transaction_Currency_Amount_CR__c == null ? 0 : ael.COMP_Transaction_Currency_Amount_CR__c;
                        totalTransDR += ael.COMP_Transaction_Currency_Amount_DR__c == null ? 0 : ael.COMP_Transaction_Currency_Amount_DR__c;
                    }
                }

                Decimal delta = totalFuncDR - totalFuncCR;
                Decimal tranDelta = totalTransDR - totalTransCR;

                if(totalTransDR > 0 && totalTransDR == totalTransCR && delta != 0){
                    //RFX exists.  Create RFX entry
                    Id rfxId = returnRFX() != null ? returnRFX().Id : null;
                    Accounting_Entry_Line__c rfxAEL = new Accounting_Entry_Line__c( GL_Account__c = rfxId, 
                                                                                    Source_Id__c = source.Id + '|RFX', 
                                                                                    Accounting_Entry__c = ae.Id,
                                                                                    COMP_Functional_Currency_Amount_CR__c = 0, 
                                                                                    COMP_Functional_Currency_Amount_DR__c = 0,
                                                                                    COMP_Transaction_Currency_Amount_CR__c = 0, 
                                                                                    COMP_Transaction_Currency_Amount_DR__c = 0,
                                                                                    Subtransaction_Type__c = 'RFX');

                    string sObjectName = source.getSObjectType().getDescribe().getName();
                    if(schemautil.getInstance().fieldExists('Accounting_Entry_Line__c', sObjectName)){
                        rfxAEL.put(sObjectName, source.Id);
                }
                    rfxAEL.COMP_Functional_Currency_Amount_CR__c = delta > 0 ? math.abs(delta) : 0;
                    rfxAEL.COMP_Functional_Currency_Amount_DR__c = delta < 0 ? math.abs(delta) : 0;

                    aels.add(rfxAEL);
            }
            
            }
            
            //Create the Accounting Entry Lines
            system.debug('aels: ' +aels.size() + ' - ' + aels);
            AccountingCodeService.generateSCOACode(aels);
            DML.insertAsSystem(aels);
            
            //Update the Source Lines Processed on the headers          
            DML.updateAsSystem(mAEs.values());
            
            //Replay validation - build fields for query and comparison
            List<Schema.FieldSetMember> aelFieldSet = util.getFieldsFromFieldSet(Accounting_Entry_Line__c.getSObjectType(), 'Validate');
            set<string> aelFields = new set<string>();
            Map<string, Accounting_Entry_Line__c> mOldAEL = new Map<String, Accounting_Entry_Line__c>();
            map<string, Task> mTasks = new map<string, Task>();
            set<Id> sdlIds = new set<Id>(mLines.keySet());
            
            for(Schema.FieldSetMember fsm : aelFieldSet){
                aelFields.add(fsm.getFieldPath());
            }
            aelFields.addAll(new List<string>{'Source_Reference__c', 'GL_Account__r.FX_Type__c', 'Allocation_ID__c', 'Accounting_Entry__r.Status__c', 'Accounting_Entry__r.Source_Reference__c', 'Accounting_Entry__c'}); 
            aelFields = SchemaUtil.getInstance().removeNSfromSetString(aelFields);
            
            String whereClause = '';
            if(sObjectName == 'Fixed_Asset_Adjustment__c'){
                whereClause += 'Accounting_Entry__r.Fixed_Asset_Adjustment__c IN :sdlIds';
            }else if(sObjectName == 'Fixed_Asset_Depreciation__c'){
                whereClause += 'Accounting_Entry__r.Fixed_Asset_Depreciation__c IN :sdlIds';
            }else{
                whereClause += mHeaderToLines.get(sObjectName) + ' IN :sdlIds';
            }

            whereClause += ' AND Accounting_Entry__r.Status__c != \'Obsolete\'';

            SOQLUtil aelQuery = new SOQLUtil('Accounting_Entry_Line__c', TRUE);
            aelQuery.addFields(aelFields);
            aelQuery.setWhereClause(whereClause);
            system.debug(logginglevel.info, 'query: ' + aelQuery.getQuery());// + ' AND Accounting_Entry__r.Status__c = \'Active\'');

            //Query for the Accounting Entry Lines considered in the validation
            List<Accounting_Entry_Line__c> refAELs = Database.Query(aelQuery.getQuery());// + ' AND Accounting_Entry__r.Status__c = \'Active\'');
            
            //Remove fields we do NOT want to consider during the validation process, but were still potentially used in the query 
            aelFields.removeAll(new List<string>{'Id', 'Autonumber__c', 'CreatedDate', 'LastModifiedDate', 'CreatedById', 'LastModifiedById', 'Name', 'GL_Account__r.FX_Type__c', 'Source_Key__c', 'Source_Reference__c', 'Allocation_ID__c', 'Accounting_Entry__r.Source_Reference__c', 'Accounting_Entry__r.Status__c', 'Accounting_Entry__c'});
            
            map<string, Accounting_Entry_Line__c> mDraftAELs = new map<string, Accounting_Entry_Line__c>();
            map<string, Accounting_Entry_Line__c> mActiveAELs = new map<string, Accounting_Entry_Line__c>();
            
            //Loop through the accounting and organize by draft and active 
            for(Accounting_Entry_Line__c ael : refAELs){
                if(ael.Accounting_Entry__r.Status__c == 'Active' || ael.Accounting_Entry__r.Status__c == null){
                    mActiveAELs.put(ael.source_reference__c, ael);
                }else if(ael.Accounting_Entry__r.Status__c == 'Draft'){
                    mDraftAELs.put(ael.source_reference__c, ael);
                }
            }
            
            //Extend this query to pull manual ledger roll up fields?
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            SOQLUtil soql = new SOQLUtil('Task', false); //enforceFLS=false, running in system mode
            soql.addFields(new set<string>{
                'Id','subject','whatId','description'
            });
            List<Accounting_Entry__c> aeList = mAEs.values();
            soql.setWhereClause('subject = \'Accounting Entry Validation\' AND whatId IN :aeList');
            soql.setOrderByClause('lastmodifieddate');
            List<Task> aeRefTasks = Database.query(soql.getQuery());

            for(Task t : aeRefTasks){
                mTasks.put(t.whatId, t);
            }                                       
            
            set<Id> matchIds = new set<Id>();
            
            //Now scrub the fields on the Accounting Entry Lines using the Validate fieldset
            for(string draftAELRef : mDraftAELs.keySet()){
                
                Accounting_Entry_Line__c iDraftAEL = mDraftAELs.get(draftAELRef);
                
                boolean isMatch = true;
                Task iTask;
                if(mTasks.containsKey(iDraftAEL.Accounting_Entry__c)){
                    iTask = mTasks.get(iDraftAEL.Accounting_Entry__c);
                }else{
                    iTask = new Task(Status = 'Open', Priority='Normal', Subject='Accounting Entry Validation', Description='', whatId = iDraftAEL.Accounting_Entry__c);
                }
                
                //system.debug('ael source: ' + iDraftAEL.source_reference__c);
                
                if(mActiveAELs.containsKey(iDraftAEL.source_reference__c)){
                    
                    //If the draft Accounting Entry Line has no source reference, that means that there is no rule or something else wrong with the record
                    if(iDraftAEL.source_reference__c == null){
                        if(iDraftAEL.GL_Account__r.FX_Type__c == 'RFX'){
                            //TODO: Enhance RFX checks, currently reliant on other fields validate which would ultimately drive the RFX value
                            continue;
                        }else{
                            //TODO: Further checks for relationship to lines?
                            isMatch = false;
                            iTask.Description += iDraftAEL.Name + ' is missing an Accounting Rule' +' \n';
                        }
                    }
                    
                    Accounting_Entry_Line__c iActiveAEL = mActiveAELs.get(iDraftAEL.source_reference__c);
    
                    if(iActiveAEL == null){
                        //Treat this as a net new Accounting Entry Line
                        iTask.Description += iDraftAEL.Name + Label.Has_no_prior_records_for_comparison +' \n';
                        isMatch = false;
                    }else{
                        //Compare the old and the New Accounting Entry Line records
                        for(string aelFieldPath : aelFields){
                            if(AccountingRuleService.getValue(aelFieldPath, iDraftAEL) != AccountingRuleService.getValue(aelFieldPath, iActiveAEL)){
                                isMatch = false;
                                iTask.Description += iDraftAEL.Name + ' - ' + aelFieldPath + ' - ' + Label.Changed_from + ' ' + AccountingRuleService.getValue(aelFieldPath, iActiveAEL) + ' '+ Label.to + ' ' + AccountingRuleService.getValue(aelFieldPath, iDraftAEL) + '\n';
                                system.debug('MISMATCH: ' + aelFieldPath + ' - ' + AccountingRuleService.getValue(aelFieldPath, iActiveAEL) + ' - ' + AccountingRuleService.getValue(aelFieldPath, iDraftAEL));
                            }
                        }
                    }
                }else{
                    //No prior value could be found for this Accounting Entry Line
                    iTask.Description += iDraftAEL.name + ' ' + Label.Has_no_prior_entry_for_comparison + '\n';
                    isMatch = false;
                }
                
                if(isMatch){
                    matchIds.add(iDraftAEL.Id);
                }else{
                    mTasks.put(iDraftAEL.Accounting_Entry__c, iTask);
                }
            }
            
            //Commit only the tasks with changes logged
            list<task> tasks = new list<task>();
            for(Task t : mTasks.values()){
    
                if(t.description.length() > 0){
                    if(t.description.length() > 31500){
                        t.description = t.description.left(31500) + '...';
                    }
                    tasks.add(t);
                }
            }
            
            //system.debug('tasks: ' + tasks);
            DML.upsertAsSystem(); upsert tasks;
            
            //system.debug('mSourceDocLineAccounting: ' + mSourceDocLineAccounting);
            //Post commit - check if there are any lines that are unaccounted for here...
            map<Id,sObject> mCompletedSourceDocAccountingIds = new map<Id,sObject>();
            for(Id headerId : mHeaders.keySet()){
                
                integer totalNumberOfLines = 0;
                sObject header = mHeaders.get(headerId);
                if(schemaUtil.getInstance().fieldExists(sObjectName, 'total_number_of_lines__c')){
                    totalNumberOfLines = integer.valueOf(header.get('total_number_of_lines__c'));
                }
                
                Accounting_Entry__c iAE = mAEs.get(headerId);
                if(iAE == null){
                    continue;
                }
                iAE.Source_Lines_Processed__c = iAE.Source_Lines_Processed__c == null ? 0 : iAE.Source_Lines_Processed__c;
                if(iAE.Source_Lines_Processed__c >= totalNumberOfLines){
                    mCompletedSourceDocAccountingIds.put(header.Id, header);
                }
                /*
                if(mSourceDocLineAccounting.get(headerId) <= 0){
                    mCompletedSourceDocAccountingIds.put(headerId, mHeaders.get(headerId));
                    mSourceDocLineAccounting.remove(headerId);
                }
                */
            }
            
            system.debug('mCompletedSourceDocAccountingIds: ' + mCompletedSourceDocAccountingIds);
            
            if(mCompletedSourceDocAccountingIds.keySet().size() > 0){
                validateCompletedAccounting((map<Id, sObject>)mCompletedSourceDocAccountingIds);
            }   
        }       

    }
    
    //Tracks all AEs that need to be deleted upon completion of building accounting
    public set<Id> deleteAEIds = new set<Id>();
    //Tracks all AEs that need to be voided upon completion of building accounting
    public set<Id> voidAEIds = new set<Id>();
    

    private void validateCompletedAccounting(map<Id, sObject> mHeaders){
        
        set<Id> headerIds = mHeaders.keySet();      

        //Round
        roundFromHeader(headerIds);
        
        //Gather fields for validations based on the Validate fieldsets on Accounting Entry/Lines
        List<Schema.FieldSetMember> aeFieldSet = util.getFieldsFromFieldSet(Accounting_Entry__c.getSObjectType(), 'Validate');
        set<string> aeFields = new set<string>();
        List<Task> tasks = new List<Task>();
        
        string bjId = this.batchJobId;
        for(Schema.FieldSetMember fsm : aeFieldSet){
            aeFields.add(fsm.getFieldPath());
        }
        aeFields.addAll(new List<string>{'Related_Accounting_Entry__c', 'CreatedDate', 'Source_Reference__c', 'Status__c', 'Total_Lines__c', 'Total_Amount_CR__c', 'Total_Amount_DR__c', 'Currency__r.ISO_Code__c', 'Currency__c', 'Company__r.comp_currency__c','Company__r.comp_currency__r.ISO_Code__c','Company__r.consol_currency__c','Company__r.consol_currency__r.ISO_Code__c','Company__r.Stat_Currency__c','Company__r.Stat_Currency__r.ISO_Code__c', 'Company__r.Subs_Currency__c','Company__r.Subs_Currency__r.ISO_Code__c'});
        aeFields = SchemaUtil.getInstance().removeNSfromSetString(aeFields);
        
        string whereClause = AccountingEntryService.SourceDocPathMap.get(sObjectName) + ' IN :headerIds AND (Status__c = \'Active\' OR (Status__c = \'Draft\' AND batchJobId__c = :bjId)) AND Related_Accounting_Entry__c = null AND Period__r.Closed__c = false AND Period__r.Permanently_Closed__c = false' ;// ORDER BY CreatedDate asc   // AND void__c = false';
        
        SOQLUtil soqlAE = new SOQLUtil('Accounting_Entry__c', TRUE);
        soqlAE.addFields(aeFields);
        soqlAE.setWhereClause(whereClause);

        system.debug('query: ' + soqlAE.getQuery());
        List<Accounting_Entry__c> refAEs = Database.query(soqlAE.getQuery());
        
        //Remove any additional fields that will NEVER be the same, IE createddate, lastmodifieddate or shouldn't be reconsidered in validation
        aeFields.removeAll(new List<string>{'Id', 'Autonumber__c', 'CreatedDate', 'LastModifiedDate', 'CreatedById', 'LastModifiedById', 'Name', 'Related_Accounting_Entry__c', 'Source_Key__c', 'Source_Reference__c', 'Status__c'});
        
        Map<string, Accounting_Entry__c> mDraftAEs = new Map<string, Accounting_Entry__c>();
        Map<string, Accounting_Entry__c> mActiveAEs = new Map<string, Accounting_Entry__c>();
        set<Id> matchIds = new set<Id>();
        List<Accounting_Entry_Line__c> updateLines = new List<Accounting_Entry_Line__c>();
        
        for(Accounting_Entry__c ae : refAEs){
            if(ae.status__c == 'Active'){
                mActiveAEs.put(ae.source_reference__c, ae); 
            }else if(ae.status__c == 'Draft'){
                mDraftAEs.put(ae.source_reference__c, ae);
            }
        }
        
        //Querying OpenActivities fails in unit tests, this will have to do the work
        map<Id, Task> mTasks = new map<Id, Task>();
       //FIN-904 Drafts not getting swapped to Active

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Task', false); //enforceFLS=false, running in system mode
        soql.addFields(new set<string>{
            'Id','whatId','subject','status','description'
        });
        soql.setWhereClause('isClosed = false AND WhatId IN :refAEs and Subject=\'Accounting Entry Validation\'');
        soql.setOrderByClause('lastmodifieddate desc');
        for(Task t : Database.query(soql.getQuery())) { 
            mTasks.put(t.whatId, t);
        }
            
        for(string aeRef : mDraftAEs.keySet()){
            
            Accounting_Entry__c iDraftAE = mDraftAEs.get(aeRef);
            
            boolean isMatch = true;
            Task iTask;
            if(mTasks.containsKey(iDraftAE.Id)){
                iTask = mTasks.get(iDraftAE.Id);
            }else{
                iTask = new Task(Status = 'Open', Priority='Normal', Subject='Accounting Entry Validation', Description = '', whatId = iDraftAE.Id);
            }
            
            system.debug('ae source: ' + iDraftAE.source_reference__c);
            
            if(mActiveAEs.containsKey(iDraftAE.source_reference__c)){
                
                Accounting_Entry__c iActiveAE = mActiveAEs.get(iDraftAE.source_reference__c);
                    
                if(iActiveAE == null){
                    //Treat this as a net new Accounting Entry
                    iTask.Description +=  '\n' + Label.This_AccountingEntry_has_no_prior_records_for_comparison;
                    isMatch = false;
                }else{
                    //Compare the old and the new Accounting Entry records
                    for(string aeFieldPath : aeFields){
                        if(AccountingRuleService.getValue(aeFieldPath, iDraftAE) != AccountingRuleService.getValue(aeFieldPath, iActiveAE)){
                            isMatch = false;
                            iTask.Description += iDraftAE.Name + ' - ' + aeFieldPath + ' - ' + Label.Changed_from + ' ' +  AccountingRuleService.getValue(aeFieldPath, iActiveAE) + ' '+ Label.to +' ' + AccountingRuleService.getValue(aeFieldPath, iDraftAE) + '\n';
                            system.debug('MISMATCH: ' + aeFieldPath + ' - ' + AccountingRuleService.getValue(aeFieldPath, iActiveAE) + ' - ' + AccountingRuleService.getValue(aeFieldPath, iDraftAE));
                        }
                    }
                }
            }else{
                //Treat this as a net new Accounting Entry
                iTask.Description = Label.This_AccountingEntry_has_no_prior_records_for_comparison;
                isMatch = false;
            }
            
            if(isMatch){
                matchIds.add(iDraftAE.Id);
            }else{
                tasks.add(iTask);
            }
            
        }
        
        //Commit only the tasks with changes logged
        list<task> validationTasks = new list<task>();
        for(Task t : tasks){
            //system.debug('task:  ' + t);
            if(t.description.length() > 0){
                if(t.description.length() > 31500){
                    t.description = t.description.left(31500) + '...';
                }
                validationTasks.add(t);
            }
        }
        
        //system.debug('validationTasks: ' + validationTasks);
        DML.upsertAsSystem(); upsert validationTasks;
        
        //Now query for at least one task tied to this accounting entry/lines to determine if it is different than the prior entry
        //If found - make the respective AE active and any prior entry Obsolete
        refAEs = database.query(soqlAE.getQuery());

        mDraftAEs = new Map<string, Accounting_Entry__c>();
        mActiveAEs = new Map<string, Accounting_Entry__c>();
        set<Id> obsoleteIds = new set<Id>();
        
        for(Accounting_Entry__c ae : refAEs){
            if(ae.status__c == 'Active'){
                mActiveAEs.put(ae.source_reference__c, ae); 
            }else if(ae.status__c == 'Draft'){
                mDraftAEs.put(ae.source_reference__c, ae);
            }
        }
        
        List<Accounting_Entry__c> finalAEs = new List<Accounting_Entry__c>();
        List<Accounting_Entry__c> deleteAEs = new List<Accounting_Entry__c>();
        list<Id> deleteTasks = new List<Id>();
        
        //Querying OpenActivities fails in unit tests, this will have to do the work
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        soql = new SOQLUtil('Task', false); //enforceFLS=false, running in system mode
        soql.addFields(new set<string>{
            'Id','whatId','subject','status','description'
        });
        soql.setWhereClause('isClosed = false AND WhatId IN :refAEs AND Subject = \'Accounting Entry Validation\'');
        soql.setOrderByClause('lastmodifieddate desc');
        for(Task t : Database.query(soql.getQuery())) {
            mTasks.put(t.whatId, t);    
        }        
         
         
        for(string aeRef : mDraftAEs.keySet()){
            
            boolean hasChanges = false;
            boolean isValidated = false;
            Accounting_Entry__c iDraftAE = mDraftAEs.get(aeRef);
            if(mTasks.containsKey(iDraftAE.Id)){
                //We found a task - means we have been logging differences between no/prior AE and this Draft
                iDraftAE.status__c = 'Active';
                iDraftAE.last_validated__c = system.now();
                iDraftAE.source_key__c = null;
                string headerPath = AccountingEntryService.sourceDocPathMap.get(iDraftAE.source_document_object_name__c);
                sObject header = mHeaders.get((Id)iDraftAE.get(headerPath));

                //KNDY-7410
                //boolean hasVoid = header.getSobjectType().getDescribe().fields.getMap().containsKey('void__c');
                SchemaUtil util = SchemaUtil.getInstance();
                Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(header.getSobjectType().getDescribe().fields.getMap());
                boolean hasVoid = fieldsMap.containsKey('void__c');                 
                
                if(hasVoid){
                    if((Boolean)header.get('void__c')){
                        voidAEIds.add(iDraftAE.Id);
                    }
                }
                finalAEs.add(iDraftAE);
                hasChanges = true;
            }else{
                isValidated = true;
                deleteAEs.add(iDraftAE);
                deleteAEIds.add(iDraftAE.Id);
            }   
            
            system.debug('isValidated: ' + isValidated);
            system.debug('hasChanges: ' + hasChanges);
            
            if(mActiveAEs.containsKey(iDraftAE.source_reference__c)){
                
                Accounting_Entry__c iActiveAE = mActiveAEs.get(iDraftAE.source_reference__c);
                
                if(isValidated){

                    string headerPath = AccountingEntryService.sourceDocPathMap.get(iActiveAE.source_document_object_name__c);
                    sObject header = mHeaders.get((Id)iActiveAE.get(headerPath));
                    
                    //KNDY-7410
                    //boolean hasVoid = header.getSobjectType().getDescribe().fields.getMap().containsKey('void__c');
                    SchemaUtil util = SchemaUtil.getInstance();
                    Map<String, sObjectField> fieldsMap = util.addNoNSfieldsToMap(header.getSobjectType().getDescribe().fields.getMap());
                    boolean hasVoid = fieldsMap.containsKey('void__c');                         
                    
                    if(hasVoid){
                        if((Boolean)header.get('void__c')){
                            voidAEIds.add(iActiveAE.Id);
                        }
                    }
                    
                    //Update this last validated flag to show the time this was validated against a newly generated AE
                    iActiveAE.last_validated__c = system.now();
                    finalAEs.add(iActiveAE);

                    if(mTasks.containsKey(iActiveAE.Id)){
                        deleteTasks.add(mTasks.get(iActiveAE.Id).Id);
                    }
                }else{
                    iActiveAE.status__c = 'Obsolete';
                    iActiveAE.source_key__c = null;
                    obsoleteIds.add(iActiveAE.Id);
                    finalAEs.add(iActiveAE);
                }
                
            }
            
        }
        
        //Leaving Tasks in the system now as an audit of changes from one record to the next - now check last validated flag for validation signals
        system.debug('deleteAEs: ' + deleteAEs);
        //Deferring this to the calling process... there has to be a better way...
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        soql = new SOQLUtil('Accounting_Entry__c', false); //enforceFLS=false, running in system mode
        soql.addFields(new set<string>{
            'Id','Status__c'
        });
        soql.setWhereClause('Related_Accounting_Entry__c IN :obsoleteIds');
        List<Accounting_Entry__c> relatedObsoleteEntries = Database.query(soql.getQuery());     

        for(Accounting_Entry__c ae : relatedObsoleteEntries){
            ae.Status__c = 'Obsolete';
            finalAEs.add(ae);
        }
        system.debug('finalAEs: ' + finalAEs);
        DML.updateAsSystem(finalAEs);
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        soql = new SOQLUtil('Accounting_Entry__c', false); //enforceFLS=false, running in system mode
        soql.addFields(new set<string>{
            'id','Name'
        });
        soql.setWhereClause('id in :voidAEIds and status__c = \'Active\' and has_exceptions__c = false and total_lines__c = 0');
        list<Accounting_Entry__c> aeList = Database.query(soql.getQuery());     
        
        if(aeList.size() > 0){
            AccountingEntryService.getInstance().AccountingEntryReversal(AccountingEntryService.AEReverseType.AEVoid, aeList);
        }
        
    }

    
    
    private void roundFromHeader(set<Id> headerIds){
        
        system.debug(logginglevel.info,'rounding: ' + headerIds);
        
        List<Accounting_Entry_Line__c> roundingLines = new List<Accounting_Entry_Line__c>();
        string bjId = this.batchJobId;
        Set<String> queryFields = new Set<String>{'Id', 'Total_Lines__c', 'Total_Amount_CR__c', 'Total_Amount_DR__c', 'COMP_Total_Credit__c', 'COMP_Total_Debit__c', 'Source_Document_Object_Name__c', 'Company__c', 'Transaction_Type__c','COMP_Functional_Total_CR__c', 'COMP_Functional_Total_DR__c', 'Source_Key__c',
                                        'Currency__c', 'currency__r.ISO_Code__c','Company__r.comp_currency__c','Company__r.comp_currency__r.ISO_Code__c','Company__r.comp_currency__r.ISO_Code__c','Company__r.consol_currency__c','Company__r.consol_currency__r.ISO_Code__c','Company__r.consol_currency__r.ISO_Code__c','Company__r.Stat_Currency__c','Company__r.Stat_Currency__r.ISO_Code__c', 'Company__r.Subs_Currency__c','Company__r.Subs_Currency__r.ISO_Code__c','Transaction_Date__c','company__r.Accounting_Standard__c'};
        queryFields.add(AccountingEntryService.SourceDocPathMap.get(sObjectName));
        queryFields.add(AccountingEntryService.SourceDocPathMap.get(sObjectName).replace('__c', '__r.name'));
        SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', TRUE);
        soql.addFields(queryFields);
        soql.setWhereClause(AccountingEntryService.SourceDocPathMap.get(sObjectName) + ' IN :headerIds '
                        + ' AND Period__r.Closed__c = false AND Period__r.Permanently_Closed__c = false '
                        + ' AND Status__c = \'Draft\' AND batchJobId__c = :bjId');
        List<Accounting_Entry__c> draftAEs = Database.query(soql.getQuery());
        
        for(Accounting_Entry__c ae : draftAEs){

            if((ae.total_amount_cr__c != ae.total_amount_dr__c) || (ae.COMP_Total_Credit__c != ae.COMP_Total_Debit__c)){
                system.debug(logginglevel.info,'Inside  header CR / DR not matching');
                //Grab the rounding threshold for this source document
                Rounding_Configuration__c rounding = Rounding_Configuration__c.getAll().get(ae.source_document_object_name__c);

                if(rounding != null ){
                    //system.debug(logginglevel.info,'Inside rounding not null');
                    rounding.value__c = rounding.value__c == null ? 0 : rounding.value__c;
                    decimal iDiff_BASE = math.abs(ae.total_amount_cr__c - ae.total_amount_dr__c);
                    decimal iDiff_COMP = math.abs(ae.COMP_Total_Credit__c - ae.COMP_Total_Debit__c);
                    system.debug(logginglevel.info,'rounding.value__c: ' + rounding.value__c+'iDiff_BASE:'+iDiff_BASE+' --- iDiff_COMP:'+iDiff_COMP);
                    if((iDiff_BASE > 0 && iDiff_BASE <= rounding.value__c) || (iDiff_COMP > 0 && iDiff_COMP <= rounding.value__c)){
                        
                        //Generate rounding AEL
                        Accounting_Entry_Line__c iRound = new Accounting_Entry_Line__c(accounting_entry__c = ae.Id, subtransaction_type__c = 'Rounding', line_type__c = null, transaction_date__c = ae.transaction_date__c.date(),
                                                                                            source_id__c = (string)ae.get(AccountingEntryService.SourceDocPathMap.get(sObjectName)), 
                                                                                            source_name__c = (string)ae.getSObject(AccountingEntryService.SourceDocPathMap.get(sObjectName).replace('__c', '__r')).get('name'));
                        
                        //Create the rule definitions for this line
                        AccountingRuleService.RuleDefinition iCRRuleDef = 
                            new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.CR, ae.company__r.accounting_standard__c, ae.source_document_object_name__c, ae.Transaction_Type__c, iRound.Subtransaction_Type__c, iRound.Line_Type__c);
                        AccountingRuleService.RuleDefinition iDRRuleDef = 
                            new AccountingRuleService.RuleDefinition(AccountingRuleService.RuleType.DR, ae.company__r.accounting_standard__c, ae.source_document_object_name__c, ae.Transaction_Type__c, iRound.Subtransaction_Type__c, iRound.Line_Type__c);
                        
                        //SK: Assumption here is to have same rule added twice as we do not expect the CR as well as DR of the rounding ? Hence safe to user RuleforLedger[0] to pass the accounting rule
                        List<Accounting_Rule__c> RuleforLedger = new List<Accounting_Rule__c>();
                        iRound.amount_dr__c = 0;
                            iRound.amount_cr__c = 0;
                            iRound.COMP_Transaction_Currency_Amount_DR__c = 0;
                            iRound.COMP_Transaction_Currency_Amount_CR__c = 0;
                        if(ae.total_amount_cr__c > ae.total_amount_dr__c){
                            iRound.amount_dr__c = iDiff_BASE;
                            //iRound.amount_cr__c = 0;
                            //iRound.COMP_Transaction_Currency_Amount_DR__c = 0;
                            //iRound.COMP_Transaction_Currency_Amount_CR__c = 0;
                            if(mRuleDefs.containsKey(iDRRuleDef)){
                                RuleforLedger.add(mRuleDefs.get(iDRRuleDef)[0]);
                                //SS.assignSegments(mRuleDefs.get(iDRRuleDef)[0], null, iRound); 
                                //populateLedgers(mRuleDefs.get(iDRRuleDef)[0], ae, iRound);
                                iRound.Accounting_Rule__c = mRuleDefs.get(iDRRuleDef)[0].Id;
                            }
                        }else if(ae.total_amount_cr__c < ae.total_amount_dr__c){
                            //iRound.amount_dr__c = 0;
                            iRound.amount_cr__c = iDiff_BASE;
                            //iRound.COMP_Transaction_Currency_Amount_DR__c = 0;
                            //iRound.COMP_Transaction_Currency_Amount_CR__c = 0;
                            if(mRuleDefs.containsKey(iCRRuleDef)){
                                RuleforLedger.add(mRuleDefs.get(iCRRuleDef)[0]);
                                //SS.assignSegments(mRuleDefs.get(iCRRuleDef)[0], null, iRound);
                                //populateLedgers(mRuleDefs.get(iCRRuleDef)[0], ae, iRound);
                                iRound.Accounting_Rule__c = mRuleDefs.get(iCRRuleDef)[0].Id;
                            }
                        }
                
                        if(ae.COMP_Total_Credit__c > ae.COMP_Total_Debit__c){
                            //iRound.amount_dr__c = 0;
                            //iRound.amount_cr__c = 0;
                            iRound.COMP_Transaction_Currency_Amount_DR__c = iDiff_COMP;
                            //iRound.COMP_Transaction_Currency_Amount_CR__c = 0;
                            if(mRuleDefs.containsKey(iDRRuleDef)){
                                RuleforLedger.add(mRuleDefs.get(iDRRuleDef)[0]);
                                //SS.assignSegments(mRuleDefs.get(iDRRuleDef)[0], null, iRound); 
                                //populateLedgers(mRuleDefs.get(iDRRuleDef)[0], ae, iRound);
                                iRound.Accounting_Rule__c = mRuleDefs.get(iDRRuleDef)[0].Id;
                            }
                        }else if(ae.COMP_Total_Credit__c < ae.COMP_Total_Debit__c){
                            //iRound.amount_dr__c = 0;
                            //iRound.amount_cr__c = 0;
                            //`iRound.COMP_Transaction_Currency_Amount_DR__c = 0;
                            iRound.COMP_Transaction_Currency_Amount_CR__c = iDiff_COMP;
                            if(mRuleDefs.containsKey(iCRRuleDef)){
                                RuleforLedger.add(mRuleDefs.get(iCRRuleDef)[0]);
                                //SS.assignSegments(mRuleDefs.get(iCRRuleDef)[0], null, iRound);
                                //populateLedgers(mRuleDefs.get(iCRRuleDef)[0], ae, iRound);
                                iRound.Accounting_Rule__c = mRuleDefs.get(iCRRuleDef)[0].Id;
                            }
                        }
                        
						if(RuleforLedger != null && RuleforLedger.size() > 0 ){
							SS.assignSegments(RuleforLedger[0], null, iRound);
							populateLedgers(RuleforLedger[0], ae, iRound);
						}
                        system.debug(logginglevel.info,'iRound:'+iRound);
                        roundingLines.add(iRound);
                        system.debug(logginglevel.info,'roundingLines:'+roundingLines);
                        
                        
                        /*if(ae.total_amount_cr__c > ae.total_amount_dr__c || ae.COMP_Total_Credit__c > ae.COMP_Total_Debit__c){
                            system.debug(logginglevel.info,'iDiff_BASE:'+iDiff_BASE+' --- iDiff_COMP:'+iDiff_COMP);
                            iRound.amount_dr__c = iDiff_BASE;
                            iRound.amount_cr__c = 0;
                            iRound.COMP_Transaction_Currency_Amount_DR__c = iDiff_COMP;
                            iRound.COMP_Transaction_Currency_Amount_CR__c = 0;
                            if(mRuleDefs.containsKey(iDRRuleDef)){
                                SS.assignSegments(mRuleDefs.get(iDRRuleDef)[0], null, iRound); 
                                populateLedgers(mRuleDefs.get(iDRRuleDef)[0], ae, iRound);
                                iRound.Accounting_Rule__c = mRuleDefs.get(iDRRuleDef)[0].Id;
                            }
                            roundingLines.add(iRound);
                        }else if(ae.total_amount_cr__c < ae.total_amount_dr__c || ae.COMP_Total_Credit__c < ae.COMP_Total_Debit__c){
                            iRound.amount_dr__c = 0;
                            iRound.amount_cr__c = iDiff_BASE;
                            iRound.COMP_Transaction_Currency_Amount_DR__c = 0;
                            iRound.COMP_Transaction_Currency_Amount_CR__c = iDiff_COMP;
                            if(mRuleDefs.containsKey(iCRRuleDef)){
                                SS.assignSegments(mRuleDefs.get(iCRRuleDef)[0], null, iRound);
                                populateLedgers(mRuleDefs.get(iCRRuleDef)[0], ae, iRound);
                                iRound.Accounting_Rule__c = mRuleDefs.get(iCRRuleDef)[0].Id;
                        }
                            roundingLines.add(iRound);
                        }*/
                    }
                    
                }
            }

			system.debug('rounding lines: ' + roundingLines);

			//KNDY-15198 - Journal Entry Rounding.  For now we will only be doing this journal entries.  For all other source docs RFX remains at the Source Line level.
			if(sObjectName.equalsIgnoreCase('Journal_Entry__c') && ae.Company__r.comp_currency__c != ae.Currency__c && ae.total_amount_cr__c == ae.total_amount_dr__c && ae.COMP_Functional_Total_CR__c != ae.COMP_Functional_Total_DR__c){
				system.debug(LoggingLevel.ERROR, 'Create RFX'); 
				Id rfxId = returnRFX() != null ? returnRFX().Id : null;

				Decimal delta = ae.COMP_Functional_Total_DR__c - ae.COMP_Functional_Total_CR__c;

				Accounting_Entry_Line__c rfxAEL = new Accounting_Entry_Line__c( GL_Account__c = rfxId, 
																				Source_Id__c = ae.Source_Key__c + '|RFX',
																				Accounting_Entry__c = ae.Id,
																				COMP_Functional_Currency_Amount_CR__c = 0, 
																				COMP_Functional_Currency_Amount_DR__c = 0,
																				COMP_Transaction_Currency_Amount_CR__c = 0, 
																				COMP_Transaction_Currency_Amount_DR__c = 0,
																				Subtransaction_Type__c = 'RFX');

				System.debug(LoggingLevel.ERROR, 'Source Key: ' + rfxAEL.Source_Id__c);

				rfxAEL.COMP_Functional_Currency_Amount_CR__c = delta > 0 ? math.abs(delta) : 0;
				rfxAEL.COMP_Functional_Currency_Amount_DR__c = delta < 0 ? math.abs(delta) : 0;

				roundingLines.add(rfxAEL);
			}
        }   
        
        if(roundingLines.size() > 0){
            AccountingCodeService.generateSCOACode(roundingLines);
            DML.insertAsSystem(roundingLines);
        }
    }
    
    public void populateLedgers(Accounting_Rule__c ar, Accounting_Entry__c ae, Accounting_Entry_Line__c ael){
        system.debug(logginglevel.info, 'populating ledgers: ' + ael);
        if(ar == null){
            return;
        }
        
        boolean isMonetaryNonCash = mMonetaryNonCashGLAccounts.containsKey(ael.gl_account__c);
        boolean isMonetaryCash = mMonetaryCashGLAccounts.containsKey(ael.gl_account__c);

		Company__c tmpCompany = mCompanies.get(ae.Company__c);
		if(tmpCompany == null) return;

        //Assign the company ledger fields and conversions
        if( ar.Company_Ledger__c && ael.COMP_Functional_Conversion_Rate__c == null){
                
            ael.COMP_Transaction_Currency__c = getCurrency(ae);
            ael.COMP_Functional_Currency__c = tmpCompany.comp_currency__r.ISO_Code__c;
            
            if((ael.COMP_Transaction_Currency__c != null || ael.COMP_Transaction_Currency__c != '') 
                    || (ael.COMP_Functional_Currency__c!= null || ael.COMP_Functional_Currency__c != '')){
                    Exchange_Rate__c funcExchangeRate;
                    Boolean isCapitalizingFAD = false;
                    DateTime transactionDate = ae.Transaction_Date__c;
                    Boolean isFADEntry = String.isNotBlank(ae.Transaction_Type__c) && ae.Transaction_Type__c.contains('Fixed Asset Depreciation');
                    if(isFADEntry){
                        isCapitalizingFAD = ae.Fixed_Asset_Depreciation__c != NULL && String.isNotBlank(ae.Fixed_Asset_Depreciation__r.Depreciation_Type__c) && ae.Fixed_Asset_Depreciation__r.Depreciation_Type__c == 'Capitalize';
                        transactionDate = isCapitalizingFAD && String.isNotBlank(String.valueOf(ae.Fixed_Asset_Depreciation__r.Fixed_Asset__r.Supplier_Invoice__r.Transaction_Date__c)) ? ae.Fixed_Asset_Depreciation__r.Fixed_Asset__r.Supplier_Invoice__r.Transaction_Date__c : ae.Transaction_Date__c;
                    }
                    if(ael.FX_Flow__c == 'Out' && isMonetaryNonCash){
                    funcExchangeRate = returnExchangeRate(ael.COMP_Transaction_Currency__c, ael.COMP_Functional_Currency__c, ae.currency__c,tmpCompany.comp_currency__c ,ael.FX_Date__c, 'Daily');
                }else{
                    funcExchangeRate = returnExchangeRate(ael.COMP_Transaction_Currency__c, ael.COMP_Functional_Currency__c,ae.currency__c,tmpCompany.comp_currency__c , ae.Transaction_Date__c, 'Daily');
                }
                system.debug('funcExchangeRate: '+ funcExchangeRate);
                ael.COMP_Functional_Conversion_Rate__c = funcExchangeRate == null ? null : funcExchangeRate.Multiplier_Exchange_Rate__c ;
                
                ael.COMP_Transaction_Currency_Amount_CR__c = ael.COMP_Transaction_Currency_Amount_CR__c != null ? ael.COMP_Transaction_Currency_Amount_CR__c : (ael.Amount_CR__c == null ? 0 : ael.Amount_CR__c).setScale(2,System.Roundingmode.HALF_EVEN) ;
                ael.COMP_Transaction_Currency_Amount_DR__c = ael.COMP_Transaction_Currency_Amount_DR__c != null ? ael.COMP_Transaction_Currency_Amount_DR__c : (ael.Amount_DR__c == null ? 0 : ael.Amount_DR__c).setScale(2,System.Roundingmode.HALF_EVEN) ;
                //system.debug(logginglevel.info,'ael.COMP_Transaction_Currency_Amount_CR__c'+ael.COMP_Transaction_Currency_Amount_CR__c);
                //system.debug(logginglevel.info,'ael.COMP_Transaction_Currency_Amount_DR__c'+ael.COMP_Transaction_Currency_Amount_DR__c);
                ael.COMP_Functional_Currency_Amount_CR__c = (ael.COMP_Transaction_Currency_Amount_CR__c * (ael.COMP_Functional_Conversion_Rate__c == null ? 0: ael.COMP_Functional_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                ael.COMP_Functional_Currency_Amount_DR__c = (ael.COMP_Transaction_Currency_Amount_DR__c * (ael.COMP_Functional_Conversion_Rate__c == null ? 0 : ael.COMP_Functional_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                
            }
        }
        
        //Assign the consolidation ledger fields and conversions
        if( ar.Consolidation_Ledger__c && ael.CONSOL_Functional_Conversion_Rate__c == null){
            
            ael.CONSOL_Transaction_Currency__c = ae.currency__r.ISO_Code__c;
            ael.CONSOL_Functional_Currency__c = tmpCompany.comp_currency__r.ISO_Code__c;
            ael.CONSOL_Reporting_Currency__c = tmpCompany.consol_currency__r.ISO_Code__c;
            
            if((ael.CONSOL_Transaction_Currency__c != null || ael.CONSOL_Transaction_Currency__c != '') 
                    || (ael.CONSOL_Functional_Currency__c != null || ael.CONSOL_Functional_Currency__c != '') 
                    || (ael.CONSOL_Reporting_Currency__c != null || ael.CONSOL_Reporting_Currency__c != '')){
                        
                Exchange_Rate__c funcExchangeRate;
                if(ael.FX_Flow__c == 'Out' && isMonetaryNonCash){
                    funcExchangeRate = returnExchangeRate(ael.CONSOL_Transaction_Currency__c, ael.CONSOL_Functional_Currency__c, ae.currency__c, tmpCompany.comp_currency__c , ael.FX_Date__c, 'Daily');
                }else{
                    funcExchangeRate = returnExchangeRate(ael.CONSOL_Transaction_Currency__c, ael.CONSOL_Functional_Currency__c, ae.currency__c, tmpCompany.comp_currency__c , ae.Transaction_Date__c, 'Daily');
                }
                
                ael.CONSOL_Functional_Conversion_Rate__c = funcExchangeRate == null ? null : funcExchangeRate.Multiplier_Exchange_Rate__c ;
                
                Exchange_Rate__c repExchangeRate = returnExchangeRate(ael.CONSOL_Functional_Currency__c, ael.CONSOL_Reporting_Currency__c,tmpCompany.comp_currency__c, tmpCompany.consol_currency__c , ae.Transaction_Date__c, 'Daily');
                ael.CONSOL_Reporting_Conversion_Rate__c = repExchangeRate == null ? null : repExchangeRate.Multiplier_Exchange_Rate__c ;
                
                ael.CONSOL_Transaction_Currency_Amount_CR__c = (ael.Amount_CR__c == null ? 0 : ael.Amount_CR__c).setScale(2,System.Roundingmode.HALF_EVEN) ;
                ael.CONSOL_Transaction_Currency_Amount_DR__c = (ael.Amount_DR__c == null ? 0 : ael.Amount_DR__c).setScale(2,System.Roundingmode.HALF_EVEN) ;
                
                ael.CONSOL_Functional_Currency_Amount_CR__c = (ael.CONSOL_Transaction_Currency_Amount_CR__c * (ael.CONSOL_Functional_Conversion_Rate__c == null ? 0 : ael.CONSOL_Functional_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                ael.CONSOL_Functional_Currency_Amount_DR__c = (ael.CONSOL_Transaction_Currency_Amount_DR__c * (ael.CONSOL_Functional_Conversion_Rate__c == null ? 0 : ael.CONSOL_Functional_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                
                ael.CONSOL_Reporting_Currency_Amount_CR__c = (ael.CONSOL_Functional_Currency_Amount_CR__c * (ael.CONSOL_Reporting_Conversion_Rate__c == null ? 0 :ael.CONSOL_Reporting_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                ael.CONSOL_Reporting_Currency_Amount_DR__c = (ael.CONSOL_Functional_Currency_Amount_DR__c * (ael.CONSOL_Reporting_Conversion_Rate__c == null ? 0 : ael.CONSOL_Reporting_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                
            }
        }
        
        //Assign the statutory ledger fields and conversions
        if(ar.Statutory_Ledger__c && ael.STAT_Functional_Conversion_Rate__c == null){
            
            ael.STAT_Transaction_Currency__c = ae.currency__r.ISO_Code__c;
            ael.STAT_Functional_Currency__c = tmpCompany.comp_currency__r.ISO_Code__c;
            ael.STAT_Reporting_Currency__c = tmpCompany.Stat_Currency__r.ISO_Code__c;
            
            if((ael.STAT_Transaction_Currency__c != null || ael.STAT_Transaction_Currency__c != '')
                    || (ael.STAT_Functional_Currency__c != null || ael.STAT_Functional_Currency__c != '')
                    || (ael.STAT_Reporting_Currency__c != null || ael.STAT_Reporting_Currency__c != '')){
                
                Exchange_Rate__c funcExchangeRate;
                if(ael.FX_Flow__c == 'Out' && isMonetaryNonCash){
                    funcExchangeRate = returnExchangeRate(ael.STAT_Transaction_Currency__c, ael.STAT_Functional_Currency__c,ae.currency__c,tmpCompany.comp_currency__c , ael.FX_Date__c, 'Daily');
                }else{
                    funcExchangeRate = returnExchangeRate(ael.STAT_Transaction_Currency__c, ael.STAT_Functional_Currency__c,ae.currency__c,tmpCompany.comp_currency__c , ae.Transaction_Date__c, 'Daily');
                }
                
                ael.STAT_Functional_Conversion_Rate__c = funcExchangeRate == null ? null : funcExchangeRate.Multiplier_Exchange_Rate__c ;
                
                Exchange_Rate__c repExchangeRate = returnExchangeRate(ael.STAT_Functional_Currency__c, ael.STAT_Reporting_Currency__c, tmpCompany.comp_currency__c, tmpCompany.stat_currency__c , ae.Transaction_Date__c, 'Daily');
                ael.STAT_Reporting_Conversion_Rate__c = repExchangeRate == null ? null : repExchangeRate.Multiplier_Exchange_Rate__c ;
                
                ael.STAT_Transaction_Currency_Amount_CR__c = (ael.Amount_CR__c == null ? 0 : ael.Amount_CR__c).setScale(2,System.Roundingmode.HALF_EVEN) ;
                ael.STAT_Transaction_Currency_Amount_DR__c = (ael.Amount_DR__c == null ? 0 : ael.Amount_DR__c).setScale(2,System.Roundingmode.HALF_EVEN) ;
                
                ael.STAT_Functional_Currency_Amount_CR__c = (ael.STAT_Transaction_Currency_Amount_CR__c * (ael.STAT_Functional_Conversion_Rate__c == null ? 0 : ael.STAT_Functional_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                ael.STAT_Functional_Currency_Amount_DR__c = (ael.STAT_Transaction_Currency_Amount_DR__c * (ael.STAT_Functional_Conversion_Rate__c == null ? 0 : ael.STAT_Functional_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                
                ael.STAT_Reporting_Currency_Amount_CR__c = (ael.STAT_Functional_Currency_Amount_CR__c * (ael.STAT_Reporting_Conversion_Rate__c == null ? 0 : ael.STAT_Reporting_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                ael.STAT_Reporting_Currency_Amount_DR__c = (ael.STAT_Functional_Currency_Amount_DR__c * (ael.STAT_Reporting_Conversion_Rate__c == null ? 0 : ael.STAT_Reporting_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                
            }
        }
        
        //Assign the subsidiary ledger fields and conversions
        if(ar.Subsidiary_Ledger__c && ael.SUB_Functional_Conversion_Rate__c == null){
            
            ael.SUB_Transaction_Currency__c = ae.currency__r.ISO_Code__c;
            ael.SUB_Functional_Currency__c = tmpCompany.comp_currency__r.ISO_Code__c;
            ael.SUB_Reporting_Currency__c = tmpCompany.Subs_Currency__r.ISO_Code__c;
            
            if((ael.SUB_Transaction_Currency__c != null || ael.SUB_Transaction_Currency__c != '')
                    || (ael.SUB_Functional_Currency__c != null || ael.SUB_Functional_Currency__c != '')
                    || (ael.SUB_Reporting_Currency__c != null || ael.SUB_Reporting_Currency__c != '')){
                        
                Exchange_Rate__c funcExchangeRate;
                if(ael.FX_Flow__c == 'Out' && isMonetaryNonCash){
                    funcExchangeRate = returnExchangeRate(ael.SUB_Transaction_Currency__c, ael.SUB_Functional_Currency__c,ae.currency__c,tmpCompany.comp_currency__c , ael.FX_Date__c, 'Daily');
                }
                else{
                    funcExchangeRate = returnExchangeRate(ael.SUB_Transaction_Currency__c, ael.SUB_Functional_Currency__c,ae.currency__c,tmpCompany.comp_currency__c , ae.Transaction_Date__c, 'Daily');
                }
                
                ael.SUB_Functional_Conversion_Rate__c = funcExchangeRate == null ? null : funcExchangeRate.Multiplier_Exchange_Rate__c ;
                
                Exchange_Rate__c repExchangeRate = returnExchangeRate(ael.SUB_Functional_Currency__c, ael.SUB_Reporting_Currency__c,tmpCompany.comp_currency__c,tmpCompany.subs_currency__c , ae.Transaction_Date__c, 'Daily');
                ael.SUB_Reporting_Conversion_Rate__c = repExchangeRate == null ? null : repExchangeRate.Multiplier_Exchange_Rate__c ;
                
                ael.SUB_Transaction_Currency_Amount_CR__c = (ael.Amount_CR__c == null ? 0 : ael.Amount_CR__c).setScale(2,System.Roundingmode.HALF_EVEN) ;
                ael.SUB_Transaction_Currency_Amount_DR__c = (ael.Amount_DR__c == null ? 0 : ael.Amount_DR__c).setScale(2,System.Roundingmode.HALF_EVEN) ;
                
                ael.SUB_Functional_Currency_Amount_CR__c = (ael.SUB_Transaction_Currency_Amount_CR__c * (ael.SUB_Functional_Conversion_Rate__c == null ? 0 : ael.SUB_Functional_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                ael.SUB_Functional_Currency_Amount_DR__c = (ael.SUB_Transaction_Currency_Amount_DR__c * (ael.SUB_Functional_Conversion_Rate__c == null ? 0 : ael.SUB_Functional_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                
                ael.SUB_Reporting_Currency_Amount_CR__c = (ael.SUB_Functional_Currency_Amount_CR__c * (ael.SUB_Reporting_Conversion_Rate__c == null ? 0 : ael.SUB_Reporting_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                ael.SUB_Reporting_Currency_Amount_DR__c = (ael.SUB_Functional_Currency_Amount_DR__c * (ael.SUB_Reporting_Conversion_Rate__c == null ? 0 : ael.SUB_Reporting_Conversion_Rate__c)).setScale(2,System.Roundingmode.HALF_EVEN);
                
            }
        }
        system.debug(logginglevel.info, 'populated ledgers: ' + ael);
    }
    
	public decimal returnFinalLineAmount(decimal amount,accounting_rule__c ar){
		
        /*if((ar.Raise_Exceptions_for_Blank_Amounts__c && amount == null)){
			amount = null;
		}else if(amount ==  null){
			amount = 0;
		}*/
		
		return amount;
	
	}    

}