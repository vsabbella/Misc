@isTest
private class GenerateTempLevelsTest {

    static testMethod void batchTest() {
       
       TestData data=new TestData();
       Id companyId=data.company.Id;
       
       Test.startTest();
       
       GenerateTempLevels obj = new GenerateTempLevels();
       obj.companyId=companyId;
       obj.query='select Id from Item__c where active__c=true and Company__c=:companyId limit 200';
       
       Id jobId=Database.executebatch(obj);
       
       Test.stopTest();
       
       system.assert(jobId!=null);

    }
}