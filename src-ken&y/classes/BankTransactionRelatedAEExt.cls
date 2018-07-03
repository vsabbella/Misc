public class BankTransactionRelatedAEExt{
    public Apexpages.Standardcontroller con {get;set;}
    public string namespace {get;set;}
        
    public Bank_Transaction__c bt {get;set;}
    public list<Accounting_Entry__c> accountingEntries {get;set;}
    public Bank_Transaction_Group__c btg {get;set;}
    public String helpURl {get;set;}
    public String imageIcon {get;set;}
    
    public BankTransactionRelatedAEExt(Apexpages.Standardcontroller controller){
        this.con = controller;
        this.namespace = KSE.NamespaceUU;    
        HelpURL= URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+'HelpAccountingEntries';
        getmyimageurl();
        accountingEntries = new list<Accounting_Entry__c>();
        btg = new Bank_Transaction_Group__c();
        bt = [Select Id,Name,Finalized__c,Transaction_Date__c, Bank_Transaction_Group__c,
              Bank_Transaction_Group__r.Finalized_Date__c,Bank_Transaction_Group__r.Posting_Date__c,
              Historical__c 
              from Bank_Transaction__c where id =: con.getId()];
        btg = [Select Id, Company__c, Exceptions_Count__c, Finalized__c, Finalized_Date__c, Transaction_Date__c , Posting_Date__c, Void__c, Void_Date__c, Status__c, Historical__c, Name
                                           From Bank_Transaction_Group__c where id =: bt.Bank_Transaction_Group__c];
        accountingEntries = [SELECT ID, Name ,Company__c, Transaction_Type__c, Period__c, COMP_Total_Debit__c, COMP_Total_Credit__c, Has_Exceptions__c, Status__c
                            FROM Accounting_Entry__c WHERE Bank_Transaction_Group__c = : btg.id ORDER BY Name];
    }

    public void getmyimageurl() {  
    document doc = [SELECT ID, Name FROM Document WHERE NAME = 'Accounting Entries' limit 1];
    if(doc != NULL){
    system.debug('Doc Name!' +doc.name);
    string imageid = doc.id; 
    imageid = imageid.substring(0,15);
    imageIcon = '/servlet/servlet.FileDownload?file=' + imageid;
    }
}

}