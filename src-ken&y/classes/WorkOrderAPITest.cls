@isTest
private class WorkOrderAPITest {
    private static testMethod void testSuccessKitAndDeKit() {
        TestFuel fuel = new TestFuel();
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> smrs = fuel.stockMovementRuleList;
        Work_Order__c workOrder = fuel.workorder;
        update new Component__c(Id = fuel.components[0].Id,Type__c = 'Kit');
        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id,Lot_Number__c = true,Date_Received__c = true,Expiration_Date__c = true);
        Map<Id,Lot__c> lots = new Map<Id,Lot__c>();
        for (Item__c item:fuel.itemList)
            lots.put(item.Id,new Lot__c(Name = 'A',Company__c = fuel.company.Id,Expiration_Date__c = Date.today() + 365,Item__c = item.Id));
        insert lots.values();
        for (SKID__c skid:fuel.skids) {
            skid.Date_Received__c = Date.today();
            skid.Lot_Number__c = 'A';
            skid.Lot__c = lots.get(skid.Item__c).Id;
        }
        update fuel.skids;
        
        try {
            WorkOrderAPI.release(new Set<Id>{workOrder.Id});
            System.assert(true);
        } catch(Exception e) {
            System.assert(false);
        }
        
        Id materialId = [SELECT Id FROM Material_Tracking__c WHERE Work_Order__c = :workOrder.Id AND Type__c = 'Kit'][0].Id;

        Map<Id,WorkOrderAPI.WorkOrderWrapper> woMap = new Map<Id,WorkOrderAPI.WorkOrderWrapper>();
        WorkOrderAPI.WorkOrderWrapper woWrapper = new WorkOrderAPI.WorkOrderWrapper(workorder.Id);
        WorkOrderAPI.DemandSKIDWrapper demandWrapper = new WorkOrderAPI.DemandSKIDWrapper();
        WorkOrderAPI.IssuedQuantity iq1 = new WorkOrderAPI.IssuedQuantity();
        iq1.quantity = 1;
        iq1.lot = 'A';
        iq1.expirationDate = Date.today() + 365;
        iq1.dateReceived = Date.today();
        iq1.attributes.put('Date_Received__c',Date.today());
        iq1.locationId = fuel.location3.Id;
        demandWrapper.quantities.add(iq1);
        WorkOrderAPI.IssuedQuantity iq2 = new WorkOrderAPI.IssuedQuantity();
        iq2.quantity = 1;
        iq2.lot = 'B';
        iq2.expirationDate = Date.today() + 365;
        iq2.dateReceived = Date.today();
        iq2.attributes.put('Date_Received__c',Date.today());
        iq2.locationId = fuel.location3.Id;
        demandWrapper.quantities.add(iq2);
        woWrapper.demandSKIDs.put(materialId,demandWrapper);
        woMap.put(woWrapper.workOrderId,woWrapper);
        
        Test.startTest();
        Map<Id,WorkOrderAPI.WorkOrderAPIStatus> statuses = WorkOrderAPI.kit(woMap);
        Test.stopTest();
        System.assert(statuses.get(workOrder.Id).success);
        List<Inventory_Change__c> ics = [SELECT Id,(SELECT Id FROM Inventory_Transactions__r) FROM Inventory_Change__c WHERE Work_Order__c = :workOrder.Id];
        System.assert(ics.size() == 1,'Should have one IC');
        System.assert(ics[0].Inventory_Transactions__r.size() == 2,'Should have two ITs');
        //System.assert([SELECT Id,Quantity__c FROM SKID__c WHERE Item__c = :fuel.components[0].Component_Item__c AND Type__c = 'Location' AND Location__c = :fuel.location3.Id AND Lot_Number__c = 'A'][0].Quantity__c == 199,'Quantity in lot A should be 199');
        System.assert([SELECT Id,Quantity__c FROM SKID__c WHERE Item__c = :fuel.components[0].Component_Item__c AND Type__c = 'Location' AND Location__c = :fuel.location3.Id AND Lot_Number__c = 'B'][0].Quantity__c == -1,'Quantity in lot B should be -1');
        
        statuses = WorkOrderAPI.dekit(woMap);
        System.assert(statuses.get(workOrder.Id).success);
        ics = [SELECT Id,(SELECT Id FROM Inventory_Transactions__r) FROM Inventory_Change__c WHERE Work_Order__c = :workOrder.Id];
        System.assert(ics.size() == 2,'Should have two IC');
        for (Inventory_Change__c ic:ics)
            System.assert(ic.Inventory_Transactions__r.size() == 2,'Should have two ITs');
        System.assert([SELECT Id,Quantity__c FROM SKID__c WHERE Item__c = :fuel.components[0].Component_Item__c AND Type__c = 'Location' AND Location__c = :fuel.location3.Id AND Lot_Number__c = 'A'][0].Quantity__c == 200,'Quantity in lot A should be 200');
    }
    private static testMethod void testKitFail() {
        TestFuel fuel = new TestFuel();
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> smrs = fuel.stockMovementRuleList;
        Work_Order__c workOrder = fuel.workorder;
        update new Component__c(Id = fuel.components[0].Id,Type__c = 'Kit');
        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id,Lot_Number__c = true,Date_Received__c = true,Expiration_Date__c = true);
        Map<Id,Lot__c> lots = new Map<Id,Lot__c>();
        for (Item__c item:fuel.itemList)
            lots.put(item.Id,new Lot__c(Name = 'A',Company__c = fuel.company.Id,Expiration_Date__c = Date.today() + 365,Item__c = item.Id));
        insert lots.values();
        for (SKID__c skid:fuel.skids) {
            skid.Date_Received__c = Date.today();
            skid.Lot_Number__c = 'A';
            skid.Lot__c = lots.get(skid.Item__c).Id;
        }
        update fuel.skids;
        
        try {
            WorkOrderAPI.release(new Set<Id>{workOrder.Id});
            System.assert(true);
        } catch(Exception e) {
            System.assert(false);
        }
        
        Id materialId = [SELECT Id FROM Material_Tracking__c WHERE Work_Order__c = :workOrder.Id AND Type__c = 'Kit'][0].Id;

        Map<Id,WorkOrderAPI.WorkOrderWrapper> woMap = new Map<Id,WorkOrderAPI.WorkOrderWrapper>();
        WorkOrderAPI.WorkOrderWrapper woWrapper = new WorkOrderAPI.WorkOrderWrapper(workorder.Id);
        WorkOrderAPI.DemandSKIDWrapper demandWrapper = new WorkOrderAPI.DemandSKIDWrapper();
        WorkOrderAPI.IssuedQuantity iq1 = new WorkOrderAPI.IssuedQuantity();
        iq1.quantity = 1000;
        iq1.lot = 'A';
        iq1.expirationDate = Date.today() + 365;
        iq1.dateReceived = Date.today();
        iq1.attributes.put('Date_Received__c',Date.today());
        iq1.locationId = fuel.location3.Id;
        demandWrapper.quantities.add(iq1);
        woWrapper.demandSKIDs.put(materialId,demandWrapper);
        woMap.put(woWrapper.workOrderId,woWrapper);
        
        Test.startTest();
        Map<Id,WorkOrderAPI.WorkOrderAPIStatus> statuses = WorkOrderAPI.kit(woMap);
        Test.stopTest();
        System.assert(!statuses.get(workOrder.Id).success);
    }
}