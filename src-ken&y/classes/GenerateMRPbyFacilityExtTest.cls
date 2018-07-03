/**
 * 
 */
@isTest
private class GenerateMRPbyFacilityExtTest {

    static testMethod void batchTest() {
        
      TestData data=new TestData();
      data.facility2.Use_Quantity_on_Hand_as_Supply_in_MRP__c = true;
      update data.facility2;
      
      List<Item__c> itemList=new List<Item__c>(); 

      for(integer i=1;i<200;i++){
            Item__c item = new Item__c();
            item.name='TestLevel'+i;
            item.Description__c='TestLevel'+i;
            item.Source__c=Label.Source_field_of_ItemP;
            item.company__c = data.company.Id;
            item.Use_Lot_Sizing__c=true;
            item.Ordering_Multiple__c=10;
            item.Shrinkage__c=2;
            item.EOQ__c=10;
            item.Active__c = true;
            item.Class__c=data.clsObj.Id;

            itemList.add(item);
      }
      insert itemList;
      
      MRP_Run__c mrpRun = new MRP_Run__c();
      mrpRun.Company__c = data.company.id;
      mrpRun.Facility__c = null;

      insert mrpRun;
        
      list<MRP__c> insertList=new list<MRP__c>();
      for(integer i=1;i<11;i++){
            data.itemList[i-1].use_lot_sizing__c = true;
            data.itemList[i-1].safety_stock__c = 1000;
            data.itemList[i-1].level__c = 1;
            MRP__c mrpObj=new MRP__c();
            mrpObj.Company__c=data.company.Id;
            mrpObj.Facility__c=data.facility2.Id;
            mrpObj.Item__c=data.itemList[i-1].ID;
            mrpObj.Quantity__c=50;
            mrpObj.Modified_Quantity__c=50;
            mrpObj.Required_Date__c=system.today();
            if (i < 5) mrpObj.Is_Demand__c=true;
            else mrpObj.Is_Demand__c=false;
            mrpObj.MRP_Run__c = mrpRun.ID;
            insertList.add(mrpObj);
        }
      update data.itemlist;

      Test.startTest();
      
      Apexpages.Standardcontroller stdcon = new Apexpages.Standardcontroller(data.facility2); 
      GenerateMRPbyFacilityExt utilObj2 = new GenerateMRPbyFacilityExt(stdcon);
      utilObj2.companyId=data.company.Id;
      utilObj2.facilityID=data.facility2.Id;
      utilObj2.generatePlan();
      
      Test.stopTest();
      System.assert( ApexPages.hasMessages() );
    }

}