public with sharing class BudgetDeleteExt {
    
    Budget__c bdg;

    private ApexPages.StandardController con;
    public BudgetDeleteExt(ApexPages.StandardController controller) {
        con = controller;
        bdg = (Budget__c)con.getRecord();
    }
     
    public PageReference deletebudget() {
        
        Id budgetId = bdg.Id;  
        SOQLUtil soql    = new SOQLUtil('Budget_Line1__c', true); 
        soql.addFields(new set<string>{'Id'}); 
        soql.setWhereClause('Budget__c = :budgetId');
        List<Budget_Line1__c> deleteBL = Database.query(soql.getQuery()); 
          
        try {
            DML.deleteAsUser(deleteBL);
            DML.deleteAsUser(bdg);
        } 
        catch(Exception e) {
             ApexPages.addMessages(e);
        }
    
        return ApexPages.hasMessages() ? null : con.cancel(); 
    }

    
}