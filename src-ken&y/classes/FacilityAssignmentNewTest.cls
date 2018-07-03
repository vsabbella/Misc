@isTest 
public with sharing class FacilityAssignmentNewTest {
    static TestData data = new TestData();
    
    static testMethod void test_FacilityAssignmentNew() {
         
        Test.startTest();
        
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller( data.facilityassignment );        
        FacilityAssignmentNewExt ext = new FacilityAssignmentNewExt(con);     
        system.assert(ext.fa.Company__c == null, 'Company Error');
        
    }
    
    
}