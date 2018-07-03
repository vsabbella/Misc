public with sharing class AccountingEntryLineEditExt {
    ApexPages.StandardController controller;
    public AccountingEntryLineEditExt(ApexPages.StandardController sc) {
        controller = sc;
    }
    public Pagereference doRedirect() { 
        Pagereference p = Page.AccountingEntryLinesManage;
        Accounting_Entry_Line__c rec = (Accounting_Entry_Line__c)controller.getRecord(); 
        p.getParameters().put('id', rec.Accounting_Entry__c );
        return p;
    }
    
}