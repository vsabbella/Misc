/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest

private class GenerateMRPEraseTempTest {
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
        GenerateMRPEraseTemp obj = new GenerateMRPEraseTemp(mrpRun.ID);
        Id jobid = Database.executeBatch( obj );
        Test.stopTest();
        system.assertEquals(0,[select Id from MRP__c where MRP_Run__c = : mrpRun.id].size() ); 
    } 
}