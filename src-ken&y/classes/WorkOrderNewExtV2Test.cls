@isTest
public with sharing class WorkOrderNewExtV2Test {
   @testSetup
    private static void setupData() {
        TestFuel fuel = new TestFuel();
        System.assert(fuel.itemList != null);
        System.assert(fuel.itemSpec != null);
        System.assert(fuel.location3 != null);
        System.assert(fuel.location5 != null);
        System.assert(fuel.itemAttrObj2 != null);
        System.assert(fuel.smrsList != null);
        System.assert(fuel.location2 != null);
        System.assert(fuel.location6 != null);
        System.assert(fuel.location7 != null);
        System.assert(fuel.stockMovementRuleList != null);

        insert new User_Preference__c(
            OwnerId = UserInfo.getUserId(),
            Default_Company__c = fuel.company.Id,
            Default_Facility__c = fuel.facility2.Id,
            User__c = UserInfo.getUserId()
        );
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    
    public static testMethod void testWorkOrderNewMissingField() {
      
        Work_Order__c wo = new Work_Order__c();
        List<String> headerDateFields = new List<String>();
        Apexpages.StandardController sc = new Apexpages.Standardcontroller(wo);
        WorkOrderNewExtV2 ext = new WorkOrderNewExtV2(sc);
        JsonResult result = WorkOrderNewExtV2.save(wo, headerDateFields); 
        system.assertEquals(false, result.success);
        
    }
    public static testMethod void testWorkOrderNewWrongIS() {
        
        update new Item_Specification__c(Id = fuel.itemSpec.Id,Facility__c = fuel.facility.Id);
        Item_Specification__c itemSpec = new Item_Specification__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[5].Id,
            Revision__c = 'R9',
            Start_Date2__c = System.now().addDays(-1),
            Costing__c = false,
            Production__c = true
        );
        insert itemSpec;
        Work_Order__c wo = new Work_Order__c();
        List<String> headerDateFields = new List<String>();
        Apexpages.StandardController sc = new Apexpages.Standardcontroller(wo);
        WorkOrderNewExtV2 ext = new WorkOrderNewExtV2(sc);
        wo.Assembly_Item_Specification__c = itemSpec.Id;
        wo.Start_Date2__c = System.today() + 30;
        wo.Need_Date2__c =  System.today() + 60 ;  
        headerDateFields  = new List<String>{'wo.Start_Date2__c','wo.Need_Date2__c'};
        JsonResult result = WorkOrderNewExtV2.save(wo, headerDateFields); 
        system.assertEquals(false, result.success);
        
    }
    public static testMethod void testWorkOrderNewWrongISRepair() {
 
        update new Item_Specification__c(Id = fuel.itemSpec.Id,Facility__c = fuel.facility.Id);
        Item_Specification__c itemSpec = new Item_Specification__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[5].Id,
            Revision__c = 'R9',
            Start_Date2__c = System.now().addDays(-1),
            Costing__c = false,
            Production__c = true,
            type__c = 'Repair'
        );
        insert itemSpec;
        Work_Order__c wo = new Work_Order__c();
        List<String> headerDateFields = new List<String>();
        Apexpages.StandardController sc = new Apexpages.Standardcontroller(wo);
        WorkOrderNewExtV2 ext = new WorkOrderNewExtV2(sc);
        wo.Assembly_Item_Specification__c = itemSpec.Id;
        wo.Start_Date2__c = System.today() + 30;
        wo.Need_Date2__c =  System.today() + 60 ;
        //wo.Order_Quantity__c =  -1 ;
        headerDateFields  = new List<String>{'wo.Start_Date2__c','wo.Need_Date2__c'};
        JsonResult result = WorkOrderNewExtV2.save(wo, headerDateFields); 
        system.assertEquals(false, result.success);
        
    }
        public static testMethod void testWorkOrderNegQty() {
        
        update new Item_Specification__c(Id = fuel.itemSpec.Id,Facility__c = fuel.facility2.Id);
        
        Work_Order__c wo = new Work_Order__c();
        List<String> headerDateFields = new List<String>();
        Apexpages.StandardController sc = new Apexpages.Standardcontroller(wo);
        WorkOrderNewExtV2 ext = new WorkOrderNewExtV2(sc);
        wo.Assembly_Item_Specification__c = fuel.itemSpec.Id;
        wo.Order_Quantity__c = -10;
        wo.Status__c = 'Draft';
        wo.Type__c = 'Regular';
        wo.Complete_To_Location__c = fuel.location6.Id;
        wo.MRB_Location__c = fuel.location2.Id;
        wo.Default_WIP_Location__c = fuel.location7.Id;
        wo.Packaging_UOM__c = fuel.uomList[8].Id;
        wo.Need_Date2__c = System.today() + 30;
        wo.Start_Date2__c = System.today() + 30;
        headerDateFields  = new List<String>{'wo.Start_Date2__c','wo.Need_Date2__c'};
        
        Test.startTest();
        JsonResult result = WorkOrderNewExtV2.save(wo, headerDateFields); 
        system.assertEquals(false, result.success);
        
        Test.stopTest();
    }
    public static testMethod void testWorkOrderNewSuccess() {
        
        update new Item_Specification__c(Id = fuel.itemSpec.Id,Facility__c = fuel.facility2.Id);
        
        Work_Order__c wo = new Work_Order__c();
        List<String> headerDateFields = new List<String>();
        Apexpages.StandardController sc = new Apexpages.Standardcontroller(wo);
        WorkOrderNewExtV2 ext = new WorkOrderNewExtV2(sc);
        wo.Assembly_Item_Specification__c = fuel.itemSpec.Id;
        wo.Order_Quantity__c = 10;
        wo.Status__c = 'Draft';
        wo.Type__c = 'Regular';
        wo.Complete_To_Location__c = fuel.location6.Id;
        wo.MRB_Location__c = fuel.location2.Id;
        wo.Default_WIP_Location__c = fuel.location7.Id;
        wo.Packaging_UOM__c = fuel.uomList[8].Id;
        
        wo.Need_Date2__c = System.today() + 30;
        wo.Start_Date2__c = System.today() + 30;
        headerDateFields  = new List<String>{'wo.Start_Date2__c','wo.Need_Date2__c'};
        
        Test.startTest();
        JsonResult result = WorkOrderNewExtV2.save(wo, headerDateFields); 
        system.assertEquals(true, result.success);
        List<Work_Order__c> wOrder = [Select Id from Work_Order__c
                                     where Id = :wo.Id];
        system.assertEquals( 1,wOrder.size());
        Test.stopTest();
    }
    public static testMethod void testWorkOrderSuccessNeedDate() {
        
        update new Item_Specification__c(Id = fuel.itemSpec.Id,Facility__c = fuel.facility2.Id);
        
        Work_Order__c wo = new Work_Order__c();
        List<String> headerDateFields = new List<String>();
        Apexpages.StandardController sc = new Apexpages.Standardcontroller(wo);
        WorkOrderNewExtV2 ext = new WorkOrderNewExtV2(sc);
        wo.Assembly_Item_Specification__c = fuel.itemSpec.Id;
        wo.Order_Quantity__c = 10;
        wo.Status__c = 'Draft';
        wo.Type__c = 'Regular';
        wo.Complete_To_Location__c = fuel.location6.Id;
        wo.MRB_Location__c = fuel.location2.Id;
        wo.Default_WIP_Location__c = fuel.location7.Id;
        wo.Packaging_UOM__c = fuel.uomList[8].Id;
        integer leadTime =  WorkOrderNewExtV2.calculateDates(fuel.itemSpec.Id);
        system.assertNotEquals(null, leadTime);
        wo.Start_Date2__c = System.now() + 2 ;
        wo.Need_Date2__c = System.now() + leadTime + 2;
        
        headerDateFields  = new List<String>{'wo.Start_Date2__c','wo.Need_Date2__c'};
        ext.getReturnUrl();
        ext.getWorkOrderHeaderFieldList();
        Test.startTest();
        JsonResult result = WorkOrderNewExtV2.save(wo, headerDateFields); 
        system.assertEquals(true, result.success);
        List<Work_Order__c> wOrder = [Select Id from Work_Order__c
                                     where Id = :wo.Id];
        system.assertEquals( 1,wOrder.size());
        Test.stopTest();
    }
}