@isTest 
public with sharing class OrderForecastNewTest {
    
    public static testMethod void test_OrderForecastNew() {
        TestData data = new TestData(); 
        Test.startTest();
        OrderForecastNewExt obj = new OrderForecastNewExt(new apexpages.standardController(data.company));
        obj.newObj.Company__c = data.company.ID;
        obj.newObj.Facility__c = data.facility.ID;
        obj.newObj.Item__c = data.itemlist[0].ID;
        obj.newObj.Plan_Date__c = system.today();
        obj.newObj.Forecast_Quantity__c = 10;
        obj.save();
        system.assert( Apexpages.hasMessages() == false , Apexpages.getMessages() );
      Test.stopTest();
    }
}