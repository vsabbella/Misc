public with sharing class BankReconSummaryExt extends GridRelatedListController{
     private ApexPages.StandardController controller;
     public GridRelatedListController.GridRelatedListConfig bankTransactionGridConfig {get; set;}
     public GridRelatedListController.GridRelatedListConfig matchedChildRecordGridConfig {get; set;}
    public string matchedChildRecordGridConfigJson;
  
     public GridRelatedListController.GridRelatedListConfig searchedResultGridConfig {get; set;}
     Public string company{get;set;} //:TODO to get company
     //public static list<BankTransactionMatchService.MatchingWrapper> lstmatchedReceiptSupplierPaymentJournalEntry{get;set;}
     //public static list<BankTransactionMatchService.MatchingWrapper> lstSearchedReceiptSupplierPaymentJournalEntry{get;set;}
    
    //Bank Recon Summary Page
    public string bankTranSummarySelectQry{get{
                    return getSelectQuery(BankReconciliationService.getBankTransactionsFields(),'Bank_Transaction__c'); }}
    
    
    public string bankTranSummaryQryWhereClause{get{  
                    return BankReconciliationService.getBankTransactionsWhereClause( endDateTime,  bankAccount.id,  bankAccount.Company__c,bankAccount.opening_balance_date__c);}}
    
    public string baseQuerySuppPayments{get{
                    return getSelectQuery(BankReconciliationService.getSupplierPaymentsInTransitFields(),'Supplier_Payment__c'); }}
    
    public string baseFilterSuppPayments{get{
                    return BankReconciliationService.getSupplierPaymentsInTransitWhereClause( endDateTime,  bankAccount.id,  bankAccount.Company__c, bankAccount.Opening_Balance_date__C);}}
    
    public string baseQueryJELines{get{
                    return getSelectQuery(BankReconciliationService.getJournalEntryLinesInTransitFields(),'Journal_Entry_Line__c'); }}
    
    public string baseFilterJELines{get{
                    return BankReconciliationService.getJournalEntryLinesInTransitWhereClause( endDateTime,  bankAccount.Id,  bankAccount.Company__c,bankAccount.Opening_Balance_date__C);}}
    
    //KNDY-16492
    public string baseJournalEntryLinesInTransitMap{get{
	       	Map<string,List<Map<string,string>>> mapObj = new Map<string,List<Map<string,string>>>();
			Map<string,string> mapChildObj = new Map<string,string>();
			List<Map<string,string>> lst = new List<Map<string,string>>();
			mapChildObj.put('sObjectName','Journal_Entry_Line__c');
			mapChildObj.put('whereClause',baseFilterJELines);
			List<string> getFieldsList = BankReconciliationService.getJournalEntryLinesInTransitFields();
			
			mapChildObj.put('addFields',getFieldsList != null && getFieldsList.size() >=0  ? String.join( getFieldsList,',') : '');
			lst.add(mapChildObj);
			mapObj.put('MainRelationShip',lst);
			lst = new List<Map<string,string>>();
			mapChildObj = new Map<string,string>();
			mapChildObj.put('sObjectName','Accounting_Entry_Lines__r');
			mapChildObj.put('whereClause',' Journal_Entry_Line__r.Journal_Entry__r.Auto_Reverse__c = true and Accounting_Entry__r.Status__c=\'Active\'');
			mapChildObj.put('addFields','Name,Accounting_Entry__r.Posting_Date__c,Has_Exceptions__c');
			mapChildObj.put('orderByClause','Accounting_Entry__r.Posting_Date__c ASC');
			lst.add(mapChildObj);
			mapObj.put('ChildRelationShip',lst);
			system.debug('soql='+JSON.serialize(mapObj, true)); 
			return JSON.serialize(mapObj, true);
    }}
   
       
    public string baseQueryAELines{get{
                    return getSelectQuery(BankReconciliationService.getCurrentGLBalanceFields() ,'Accounting_Entry_Line__c'); }}
    
    public string baseFilterAELines{get{
                    return BankReconciliationService.getCurrentGLBalanceWhereClause( endDateTime,  bankAccount.GL_Account__c, bankAccount.Company__c);}}
        
    public string baseQueryCustomerReceiptsInTransit{get{
                    return getSelectQuery(BankReconciliationService.getCustomerReceiptsInTransitFields() ,'Customer_Receipt__c'); }}
    
    public string baseFilterCustomerReceiptsInTransit{get{
                    return BankReconciliationService.getCustomerReceiptsInTransitWhereClause( endDateTime,  bankAccount.id,  bankAccount.Company__c,bankAccount.Opening_Balance_date__C);}}
    public string baseFilterReconciledTransactions{get{
                    return BankReconciliationService.getReconciledTransactionsWhereClause( endDateTime,  bankAccount.id,  bankAccount.Company__c,bankAccount.Opening_Balance_date__C);}}

    public string baseQueryIntecoInTransit{get{
        return getSelectQuery(BankReconciliationService.getIntercoInTransitFields() ,'Payment__c'); }}

    public string baseFilterIntecoReceiptsInTransit{get{
        return BankReconciliationService.getIntercoReceiptsInTransit( endDateTime,  bankAccount.id,  bankAccount.Company__c,bankAccount.Opening_Balance_date__C);}}

    public string baseFilterIntecoPaymentsInTransit{get{
        return BankReconciliationService.getIntercoPaymentsInTransit( endDateTime,  bankAccount.id,  bankAccount.Company__c,bankAccount.Opening_Balance_date__C);}}




    public Bank_Account__c bankAccount{get;set;}

    
        public static Bank_account__c getBankAccount(String bid){
        Bank_account__c bankAcct = [select id,GL_Account__c,Opening_Balance__c,Opening_Balance_date__c, Active__c,Company__c from bank_account__c where id= :bid];
        /*if(bankAcct!=null ){
            if( bankAcct.Opening_Balance_date__c !=null)
            bankAcct.Opening_Balance_date__c = Datetime.newInstance(bankAcct.Opening_Balance_date__c.date(),Time.newInstance(0,0,0,0));
        }*/
        return bankAcct;
        }
    
     public BankReconSummaryExt(ApexPages.StandardController c) {
       
         //c.addFields(new List<String> {'GL_Account__c'});
        controller = c;
        //bankAccount = (Bank_Account__c) controller.getRecord();
        if(controller.getRecord().id!=null){
       bankAccount = getBankAccount(controller.getRecord().id);
        }
          //endDateTime = Datetime.now();//TODO Remove this 
     String tempDate=     ApexPages.currentPage().getParameters().get('endDate');
        endDateTime= Datetime.newInstance(Date.parse(tempDate),Time.newInstance(0,0,0,0)).addDays(1);


        
     }  

    // QUERIES
    public String getSelectQuery(List<String> ListFields, String ObjName ){
        String qry='';
        for(String s:ListFields){
            if(String.isNotBlank(qry)){
                qry=','+ qry ;
            }
            qry=s+ qry;
        }
        system.debug('query Bank_Transaction: ' + qry);
        
    system.debug('glAccountId' + bankAccount.GL_Account__c);
        return 'SELECT '+ qry +' FROM '+ ObjName + ' ' ;
    }
   
        
    Public static DateTime endDateTime{get;set;}    
    
     //QUERIES END



    

}