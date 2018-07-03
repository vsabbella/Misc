/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest
private class LotUpdateStatusBatchTest {

    static testMethod void batchTest() {
        TestData data = new TestData();
        
        data.clsObj.Status_1_Offset_Days__c = 10;
        data.clsObj.Status_3_Offset_Days__c = 35;
        update data.clsObj;
        
        Lot__c lot = new Lot__c( Name = '1234' , Item__c = data.itemList[0].id ,Company__c =  data.company.id, Expiration_Date__c = system.today()+30 );
        insert lot;
        
        test.startTest();
        
        LotUpdateStatusBatch obj = new LotUpdateStatusBatch();
        obj.CompanyID = data.company.ID;
        obj.runBatch(data.company.id);
        
        test.stopTest();
        
        lot = [ select id, lot_hold__c from lot__c where id=:lot.id];
        system.assertEquals(lot.lot_hold__c,true);
    }
}