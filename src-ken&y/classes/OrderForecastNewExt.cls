public with sharing class OrderForecastNewExt {

    // TODO could use the controller.getRecord() instead of creating a new object in this class... 
    
    public OrderForecastNewExt(ApexPages.StandardController controller) {
        newObj = new Order_Forecast__c();
        newObj.Company__c = CompanyService.getDefaultCompanyId();
    }
    
    public void save(){
        try {
            DML.insertAsUser( new list<sobject>{newObj } ); 
        } 
        catch ( Exception e ) {
            Apexpages.addMessages(e);
        }
        return;
    }
    
    public Order_Forecast__c newObj {get;set;}
    public String getOrderForecastId(){
        return (String)newObj.Id;
    }
   
}