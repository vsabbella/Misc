public with sharing class BudgetLineNewExt {

    public BudgetLineNewExt(ApexPages.StandardController controller) {

        newObj = (Budget_Line1__c)controller.getRecord(); 
         
                       
        Id newObjId = newobj.Budget__c; 
         
        SOQLUtil soql    = new SOQLUtil('Budget__c', true); 
         
        soql.addFields(new set<string>{'Id','Company__c'}); 
        soql.setWhereClause('ID = :newObjId');
        
        Budget__c b = Database.query(soql.getQuery());
        
        newObj.Company__c = b.Company__c; 
        
    }
    
    public pageReference save(){
        try {
            DML.insertAsUser( new list<sobject>{newObj } ); 
        } 
        catch ( Exception e ) {
            Apexpages.addMessages(e);
        }
        PageReference ISPage = new PageReference('/'+newObj.Id);
        ISPage.setRedirect(true);
        return (ApexPages.hasMessages() ? null : ISPage );
    }
    
    public Budget_Line1__c newObj {get;set;}
   
}