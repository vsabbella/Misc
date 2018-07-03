@isTest 
public with sharing class FacilityAssignmentManageTest {
    static TestData data = new TestData();
    
    static testMethod void test_FacilityAssignmentCreate() {
         
        Test.startTest();
        
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller( data.facilityassignment );
        FacilityAssignmentManageExt ext = new FacilityAssignmentManageExt(con);
        
        ext.fa.Company__c = data.company.id;
        ext.FASearch();
        system.assert(ext.faList.size() != 0, 'No Records Error');
        
        ext.FACreate();
        system.assert(Apexpages.hasMessages() == true , 'No Records Selected' );
        
        Apexpages.currentPage().getParameters().put('selected_indexes','0');
        ext.FACreate();
        system.assert(Apexpages.hasMessages() == true , 'No Values Set' );
        
        ext.fa.Create_Replace_Start_Date__c = system.today() + 100;
        ext.FACreate();
        system.assert(ext.createList.size() != 0, 'No Records Created');
    }
    
    static testMethod void test_FacilityAssignmentReplace() {
         
        Test.startTest();
        
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller( data.facilityassignment );
        FacilityAssignmentManageExt ext = new FacilityAssignmentManageExt(con);
        
        ext.fa.Company__c = data.company.id;
        ext.FASearch();
        system.assert(ext.faList.size() != 0, 'No Records Error');
        
        ext.FAReplace();
        system.assert(Apexpages.hasMessages() == true , 'No Records Selected' );
        
        Apexpages.currentPage().getParameters().put('selected_indexes','0');
        ext.FAReplace();
        system.assert(Apexpages.hasMessages() == true , 'No Values Set' );
        
        ext.fa.Create_Replace_Start_Date__c = system.today() + 100;
        ext.FAReplace();
        system.assert(ext.updateList.size() != 0, 'No Records Replaced');
    }
    
    static testMethod void test_FacilityAssignmentDelete() {
         
        Test.startTest();
        
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller( data.facilityassignment );
        FacilityAssignmentManageExt ext = new FacilityAssignmentManageExt(con);
        
        ext.fa.Company__c = data.company.id;
        ext.FASearch();
        system.assert(ext.faList.size() != 0, 'No Records Error');
        
        Apexpages.currentPage().getParameters().put('selected_indexes','0');
        ext.FADelete();
        system.assert(ext.deleteList.size() != 0, 'No Records Deleted');
    }
    
}