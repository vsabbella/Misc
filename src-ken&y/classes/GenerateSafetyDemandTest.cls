@isTest
private with sharing class GenerateSafetyDemandTest {

    static testMethod void batchTest() {
        ID calID;
        TestData data=new TestData();
        
        calID = [select Id from BusinessHours where isDefault = true limit 1].Id;
        Date todaysDate=KSE.calculateStartDate(Date.today(),0,calID);
   
        for(integer i=1;i<11;i++){
            data.itemList[i-1].use_lot_sizing__c = true;
            data.itemList[i-1].safety_stock__c = 1000;   
            
        }
        update data.itemList;
        
        MRP_Run__c mrpRun = new MRP_Run__c();
        mrpRun.Company__c = data.company.id;
        mrpRun.Facility__c = null;
        insert mrpRun;
        
        // add some inventory so the nettable.getNettable returns something for one item anyway
        SKID__c skid = new SKID__c(
            location__c = data.location.id, 
            Quantity__c = 10.0,
            Item__c = data.itemList[0].id,
            Type__c = 'Location',
            Company__c = data.company.Id);
        insert skid;
        SKID__c skid1 = new SKID__c(
            location__c = data.location.id, 
            Quantity__c = -10.0,
            Item__c = data.itemList[1].id,
            Type__c = 'Location',
            Company__c = data.company.Id);
        insert skid1;
        
        test.startTest();
        
        GenerateSafetyDemand obj = new GenerateSafetyDemand(mrpRun.id, calID, calID);
        
        Id jobId=Database.executeBatch(obj, 200);
        
        test.stopTest();
        
        system.assert(jobId!=null);
        // we should have mrp temp entries for our items, since they all have safe stock and no inventory
        List<MRP__c> tmp = [select id,quantity__c from MRP__c where is_demand__c = true and MRP_Run__c =: mrpRun.id];
        system.assert(tmp.size() > 1);
        for ( MRP__c m : tmp ) {
            system.assertEquals(1000, m.Quantity__c);
        }
    }
}