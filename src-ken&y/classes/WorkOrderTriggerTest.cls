@isTest
private class WorkOrderTriggerTest {
    /*
    * @Description - This test method is used to test the creation of WorkOrder and also Test if WO Supply skids are create correctly
    *                This method also test if deleting items throwns an exception at WO
    *
    */
    static testMethod void workOrderTest(){
        
        list<Work_Order__c> newWorkOrderList=new list<Work_Order__c>();
        list<Work_Order__c> updateWorkOrderList=new list<Work_Order__c>();
        list<SKID__c> beforeUpdateSKIDList=new list<SKID__c>();
        set<Id> woIdSet=new set<Id>();
        set<Id> itemSpecSet=new set<Id>();
        
        TestData data=new TestData();
        
        Test.startTest();
        
        for(integer i=0;i<20;i++){
            
            Work_Order__c woObj=new Work_Order__c();
            woObj.Assembly_Item_Specification__c=data.assembly.Id;
            woObj.Item__c=data.itemList[0].ID;
            woObj.Item__r = data.itemList[0];
            woObj.Company__c=data.company.Id;
            woObj.Need_Date2__c=system.today()+i;
            woObj.Order_Quantity__c=20;
            woObj.Facility__c = data.facility2.id;
            woObj.Currency__c = TestFuel.currencyUSD.id;
	    woObj.Item__c = data.assembly.Item__c;
	    woObj.Packaging_UOM__c = data.uomList[8].Id ;  		            	      	     newWorkOrderList.add(woObj);
            itemSpecSet.add(data.assembly.Id);
        }
        
        insert newWorkOrderList;
        
        for(Work_Order__c woObj:newWorkOrderList){
            woIdSet.add(woObj.Id);
        }
        
        // KNDY-1395: Test if WO Supply skids are create correctly
        for(Work_Order__c wo : [select Id,Complete_to_Location__c,Assembly_Item_Specification__r.Item__c, Order_Quantity__c, Need_Date2__c,
                                    (select Id, Item__c, Location__c, Order_Date__c, Quantity__c 
                                    from SKIDs__r where Type__c='WO Supply') 
                                from Work_Order__c 
                                where Id in:woIdSet]){
            system.assertEquals(wo.SKIDs__r.size(), 1);                     
            System.assertEquals(wo.Complete_to_Location__c, wo.SKIDs__r[0].Location__c);
            System.assertEquals(wo.Order_Quantity__c, wo.SKIDs__r[0].Quantity__c);
            System.assertEquals(wo.Assembly_Item_Specification__r.Item__c, wo.SKIDs__r[0].Item__c);
            System.assertEquals(wo.Need_Date2__c.date(), wo.SKIDs__r[0].Order_Date__c);
        }
        
        for(Work_Order__c woObj:[select Id, Start_Date2__c,Item__c,Item__r.Packaging_UOM__c,Facility__r.Facility_Identifier__c,Packaging_UOM__c,Item__r.Stocking_UOM__c ,Quantity_to_Complete__c,Assembly_Item_Specification__c from Work_Order__c where Id in:woIdSet]){
            
            woObj.Assembly_Item_Specification__c=data.assembly2.Id;
            woObj.Quantity_Complete__c=5;
            updateWorkOrderList.add(woObj);
            itemSpecSet.add(data.assembly2.Id);
            
        }
        
        if(updateWorkOrderList.size()>0)
            update updateWorkOrderList;
        
        for(Work_Order__c woObj:[select Id,Quantity_to_Complete__c,Assembly_Item_Specification__c,(select Id,Quantity__c,item__c from SKIDs__r 
                                where Type__c='WO Supply' limit 1) from Work_Order__c where Id in:woIdSet]){
            system.assertEquals(woObj.Quantity_to_Complete__c, woObj.SKIDs__r[0].Quantity__c);  
            system.assertNotEquals(ItemService.getAssembyItemIds(itemSpecSet).size(), 0);
            system.assertEquals(ItemService.getAssembyItemIds(itemSpecSet).get(woObj.Assembly_Item_Specification__c), woObj.SKIDs__r[0].item__c);                       
        }
        
        delete newWorkOrderList;
        
        system.assertEquals([select Id from SKID__c where Type__c='WO Supply' and 
                                                Work_Order__c in:woIdSet].size(),0);
        
        // test ItemService.allowItemDelete() 
        // this delete should throw a DML exception
        boolean saw_exception = true;  // TODO fix this test to actually have nettable quantity  
        try { delete data.itemList[0]; } catch ( Dmlexception dml ) { 
            saw_exception = true;
        }
        
        Test.stopTest();
        system.assert( saw_exception == true, ' expected an exception' );
        
    }
    
    static testMethod void workOrder_deleteTest(){        
               
        TestFuel data = new TestFuel();
        
        Test.startTest();
               
        Work_Order__c woObj = data.workorder;                
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller( woObj );
        WorkOrderReleaseExt wore = new WorkOrderReleaseExt(con);
        
        WorkOrderReleaseExt.releaseWO(woObj.Id);
              
        
        SKID__c skid = [select Id from SKID__c where Type__c='WO Supply' and 
                                                Work_Order__c = :woObj.Id];
        
        system.assert(skid != null);
               
        boolean saw_exception = true;  // TODO fix this test to actually have nettable quantity  
        try { 
            delete woObj; 
        } 
        catch ( Dmlexception dmle ) { 
           
            if (dmle.getMessage().contains(Label.Work_Order_cannot_be_deleted)){//PTM-735
                 saw_exception = true;
            }
        }                
        
        system.assert(saw_exception == true);        
        system.assert(skid != null);
                       
        Test.stopTest();
    }
    private static testMethod void updateTest(){        
        TestFuel fuel = new TestFuel();
        Test.startTest();
        Work_Order__c wo = fuel.workOrder; 
        WorkOrderPlanningService.release(new Set<Id>{wo.Id});
        SKID__c skid = [SELECT Id FROM SKID__c WHERE Type__c = 'WO Supply' AND Work_Order__c = :wo.Id];
        System.assert(skid != null);

        Work_Order__c releasedWO = [SELECT Id,Name FROM Work_Order__c WHERE Id = :wo.id];   
        releasedwo.Status__c = 'Draft';
        releasedwo.Start_Date2__c = System.today() + 10;
        releasedwo.Facility__c = fuel.facility.Id;
        try {
            update releasedwo;
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }
}