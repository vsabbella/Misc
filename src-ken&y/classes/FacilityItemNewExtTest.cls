@isTest
public with sharing class FacilityItemNewExtTest {

    static TestData data = new TestData();
    
    static testMethod void test_FacilityItemNew() {
         
        Test.startTest();
        
        Facility_Item__c fi = new Facility_Item__c();
        fi.Company__c = data.company.ID;
        fi.Facility__c = data.facility2.ID;
        fi.Item__c = data.itemList[0].ID;
        
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller( fi );        
        FacilityItemNewExt ext = new FacilityItemNewExt(con);
        ext.SaveFI();
        system.assert(Apexpages.hasMessages() == false, Apexpages.getMessages());        
    }
 
  
}