/*
*   Test methods for BaseController
*/
@isTest
public with sharing class BaseControllerTest {
    static TestData globalTestData = new TestData();
    
    static testMethod void testLookupSearch(){
        Test.startTest();
        
        String searchTerm = 'Kenandy';
        String objectName = 'Account';
        
        List<SelectListItem> result = BaseController.lookupSearch(searchTerm, objectName);
        
        System.assertNotEquals(0, result.size());
        
        Test.stopTest();
    }
    
    static testMethod void testLookupSearchFilter(){
        Test.startTest();
        
        String searchTerm = 'Kenandy';
        String objectName = 'Account';
        
        List<SelectListItem> result = BaseController.lookupSearchFilter(searchTerm, objectName, '');
        
        System.assertNotEquals(0, result.size());
        
        result = BaseController.lookupSearchFilter(searchTerm, objectName, 'Name = \'Kenandy\'');
        
        System.assertEquals(1, result.size());
        
        Test.stopTest();
    }
    
    static testMethod void testGetPicklistValues() {
    	Test.startTest();
    	
    	String objectName = 'Account';
    	String fieldName = 'Type';
    	
    	List<SelectListItem> result = BaseController.getPicklistValues(objectName, fieldName);
        
        System.assertNotEquals(0, result.size());
        
        Test.stopTest();
    }
}