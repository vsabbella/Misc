/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest

private class EraseMRP_RunExtTest {
    static testMethod void batchTest() {
        TestData data = new TestData();
        insert new MRP__c( company__c = data.company.id );
        MRP_Run__c mrpRun = new MRP_Run__c();
        mrpRun.Company__c = data.company.id;
        mrpRun.Facility__c = null;
        insert mrpRun;
        MRP__c mrp = new MRP__c();
        mrp.Company__c = data.company.id;
        mrp.Facility__c = null;
        mrp.MRP_Run__c = mrpRun.ID;
        insert mrp;
      
        Test.startTest();
        Apexpages.Standardcontroller stdcon = new Apexpages.Standardcontroller(mrpRun);
        EraseMRP_RunExt obj = new EraseMRP_RunExt(stdcon);
        obj.eraseMrpRun();
        Test.stopTest();
        system.assertEquals(0,[select Id from MRP__c where MRP_Run__c = : mrpRun.id].size() ); 
    } 
    
    static testMethod void errorMessagesTest() {
        TestData data = new TestData();
        insert new MRP__c( company__c = data.company.id );
        
        MRP_Run__c mrpRun = new MRP_Run__c();
        mrpRun.Company__c = data.company.id;
        mrpRun.Facility__c = null;
        mrpRun.Completion_Status__c = 'Success';
        insert mrpRun;
      
        Test.startTest();
        Apexpages.Standardcontroller stdcon = new Apexpages.Standardcontroller(mrpRun);
        EraseMRP_RunExt obj = new EraseMRP_RunExt(stdcon);
        Test.stopTest();
        
        ApexPages.Message[] pgMsgs = ApexPages.getMessages();
        system.assertEquals(pgMsgs[0].getDetail(),Label.MRP_Run_Completion_Status_Error_Message); 
    }
}