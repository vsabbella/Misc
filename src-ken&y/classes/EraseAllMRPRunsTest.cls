/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest

private class EraseAllMRPRunsTest {
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
        Process_Job__c pj = new Process_Job__c();
        pj.Batch_Size__c = 2000;
        pj.company__c = data.company.id;
        insert pj;
      
        Test.startTest();
        EraseAllMRPRuns obj = new EraseAllMRPRuns(data.company.id);
        obj.CompanyID = data.company.id;
        obj.recBin = true;
        Id jobid = Database.executeBatch( obj );
        try {
        obj.runBatch(pj);
        }catch(exception e){
           system.assert(e.getMessage().contains('MRP is currently running'));
        }
        
        List <MRP__c> tempList = [select ID, MRP_Run__c
                                  from MRP__c
                                  where Company__c =: data.company.id];
        obj.execute(tempList);
        Test.stopTest();
        system.assertEquals(0,[select Id from MRP__c where MRP_Run__c = : mrpRun.id].size() ); 
    } 
}