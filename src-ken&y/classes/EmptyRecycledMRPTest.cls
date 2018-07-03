/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest

private class EmptyRecycledMRPTest {
    static testMethod void batchTest() {
        TestData data = new TestData();
        List<MRP__c> mList = new List<MRP__c>();
        MRP__c mrp = new MRP__c();
        mrp.Company__c = data.company.id;
        mList.add(mrp);
        insert mList;
        delete mList;
        
        Process_Job__c pj = new Process_Job__c();
        pj.Batch_Size__c = 200;
        insert pj;
      
        Test.startTest();
        EmptyRecycledMRP obj = new EmptyRecycledMRP();
        Id jobid = Database.executeBatch( obj );
        obj.runBatch(pj);
        obj.execute(mList);
        Test.stopTest();
        system.assert(ApexPages.hasMessages() == false, 'unexpected error'); 
    } 
}