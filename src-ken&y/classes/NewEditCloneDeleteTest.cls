@isTest 
public with sharing class NewEditCloneDeleteTest {
    
    public static testMethod void test1() {
        NewEditCloneDeleteExt ext = new NewEditCloneDeleteExt(new Apexpages.Standardcontroller(new Company__c() ));
        ext.errMsg();
        system.assert(ApexPages.hasMessages(), 'Has Message Error');    
     }         
}