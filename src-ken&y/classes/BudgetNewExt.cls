public with sharing class BudgetNewExt {

    public BudgetNewExt(ApexPages.StandardController controller) {

        newObj = new Budget__c();
        newObj.Company__c = CompanyService.getDefaultCompanyId();
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
    
    public Budget__c newObj {get;set;}
   
}