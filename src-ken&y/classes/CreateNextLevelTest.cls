@isTest
private class CreateNextLevelTest {

    static testMethod void batchTest() {
       
       TestData data=new TestData();
       Id companyId=data.company.Id;
       
       Test.startTest();
       
       CreateNextLevel obj = new CreateNextLevel(0);
       obj.companyId=companyId;
       obj.query='select Id,Item__c from Item_Specification__c where Id in '+
                 '(select Assembly_Item_Specification__c from Component__c where Component_Item__r.Level__c= 0) and '+
                 'Company__c=:companyId';
       Id jobId=Database.executebatch(obj);
       
       Test.stopTest();
       
       system.assert(jobId!=null);

    }
}