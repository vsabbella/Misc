/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest
private class GenerateMRPTempTest {

    static testMethod void batchTest() {
        ID calID;
        
        TestData data=new TestData();
        
        calID = [select Id from BusinessHours where isDefault = true limit 1].Id;
        
        Date dateFilter=date.newInstance(2011, 1, 1);
        Id companyId=data.company.Id;
        
        MRP_Run__c mrpRun = new MRP_Run__c();
        mrpRun.Company__c = data.company.id;
        mrpRun.Facility__c = null;
        insert mrpRun;
        
        test.startTest();
        
        GenerateMRPTempData obj=new GenerateMRPTempData(mrpRun.ID, calID, calID);
        Id jobId=Database.executeBatch(obj);
        
        test.stopTest();
        
        system.assertNotEquals([select Id from MRP__c where Planned__c=false].size(),0 );
    
    }
}