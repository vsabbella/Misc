@isTest
private class ActivateProposedCostsTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.periodList != null);
        System.assert(f.reasonCodes != null);
        System.assert(f.itemList != null);
        System.assert(f.location != null);
        System.assert(f.location3 != null);
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);

        delete [SELECT Id FROM Item_Attribute__c];
        delete [SELECT Id FROM Item_Cost__c WHERE Status__c = 'Proposed'];
    }

    public static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void companyNonRetro() {
        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[1].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        SKID__c skid = new SKID__c(
            Item__c = fuel.itemList[1].Id,
            Item__r = fuel.itemList[1],
            Container_Item__c = fuel.itemList[1].Id,
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Location__r = fuel.location3,
            Count_Quantity__c = 1,
            Stocking_UOM__c = fuel.itemList[1].Stocking_UOM__c,
            Packaging_UOM__c = fuel.itemList[1].Stocking_UOM__c
        );

        CycleCountExtV2.saveAction(ext.inventoryChange, new List<String>(), new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid, new List<Serial__c>()) }, new List<String>());

        Inventory_Transaction__c it = [SELECT Id, Transaction_Date__c FROM Inventory_Transaction__c];

        Item_Cost__c newCost = new Item_Cost__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[1].Id,
            Start_Date__c = System.now().addDays(-2),
            Status__c = 'Proposed'
        );
        insert newCost;

        Test.startTest();
        ActivateProposedCostsBatch activateBatch = new ActivateProposedCostsBatch();
        activateBatch.runBatch(new Process_Job__c(Company__c = fuel.company.Id));
        Test.stopTest();

        List<Item_Cost__c> costs = [SELECT Id, Change_Reason__c, Date_Approved__c, Invalid_Flag__c, Start_Date__c, Status__c FROM Item_Cost__c WHERE Item__c = :fuel.itemList[1].Id];
        System.assert(costs.size() == 2, costs);
        for (Integer i = 0; i < costs.size(); i++) {
            Item_Cost__c cost = costs[i];
            if (cost.Id == newCost.Id) {
                System.assert(cost.Change_Reason__c == Label.Non_Retro_Item_Cost_start_date_change_message, cost);
                System.assert(cost.Date_Approved__c != null, cost);
                System.assert(cost.Start_Date__c == it.Transaction_Date__c, cost);
                System.assert(cost.Status__c == 'Approved', cost);
            }
        }
    }

    private static testMethod void facilityRetro() {
        update new Company__c(Id = fuel.company.Id, Allow_Retro_Active_Standard_Cost__c = true);

        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility.Id;

        SKID__c skid = new SKID__c(
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Container_Item__c = fuel.itemList[0].Id,
            Facility2__c = fuel.facility.Id,
            Location__c = fuel.location.Id,
            Location__r = fuel.location,
            Count_Quantity__c = 1,
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c
        );

        CycleCountExtV2.saveAction(ext.inventoryChange, new List<String>(), new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid, new List<Serial__c>()) }, new List<String>());

        Item_Cost__c newCost = new Item_Cost__c(
            Company__c = fuel.company.Id,
            Facility__c = fuel.facility.Id,
            Item__c = fuel.itemList[0].Id,
            Start_Date__c = System.now().addDays(-2),
            Status__c = 'Proposed'
        );
        insert newCost;

        Test.startTest();
        ActivateProposedCostsBatch activateBatch = new ActivateProposedCostsBatch();
        activateBatch.runBatch(new Process_Job__c(Company__c = fuel.company.Id, Facility__c = fuel.facility.Id));
        Test.stopTest();

        List<Item_Cost__c> costs = [SELECT Id, Change_Reason__c, Date_Approved__c, Invalid_Flag__c, Start_Date__c, Status__c FROM Item_Cost__c WHERE Item__c = :fuel.itemList[0].Id];
        System.assert(costs.size() == 2, costs);
        for (Integer i = 0; i < costs.size(); i++) {
            Item_Cost__c cost = costs[i];
            if (cost.Id == newCost.Id) {
                System.assert(cost.Change_Reason__c == Label.Retro_Item_Cost_start_date_change_message, cost);
                System.assert(cost.Date_Approved__c != null, cost);
                System.assert(cost.Start_Date__c == costs[i == 0 ? 1 : 0].Start_Date__c, cost);
                System.assert(cost.Status__c == 'Approved', cost);
            } else {
                System.assert(cost.Invalid_Flag__c == true, cost);
            }
        }
    }

    private static testMethod void itemNoIt() {
        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        delete [SELECT Id FROM Item_Cost__c];

        delete c;

        Item_Cost__c newCost = new Item_Cost__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[1].Id,
            Start_Date__c = System.now().addDays(2),
            Status__c = 'Proposed'
        );
        insert newCost;

        Test.startTest();
        ActivateProposedCostsExt ext = new ActivateProposedCostsExt(new ApexPages.StandardController(newCost));
        ext.activate();
        Test.stopTest();

        List<Item_Cost__c> costs = [SELECT Id, Change_Reason__c, Date_Approved__c, Invalid_Flag__c, Start_Date__c, Status__c FROM Item_Cost__c WHERE Item__c = :fuel.itemList[1].Id];
        System.assert(costs.size() == 1, costs);
        System.assert(costs[0].Change_Reason__c != null, costs[0]);
        System.assert(costs[0].Date_Approved__c != null, costs[0]);
        System.assert(costs[0].Start_Date__c == costs[0].Date_Approved__c, costs[0]);
        System.assert(costs[0].Status__c == 'Approved', costs[0]);
    }

    private static testMethod void itemIt() {
        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        delete [SELECT Id FROM Item_Cost__c];

        delete c;

        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[1].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        SKID__c skid = new SKID__c(
            Item__c = fuel.itemList[1].Id,
            Item__r = fuel.itemList[1],
            Container_Item__c = fuel.itemList[1].Id,
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Location__r = fuel.location3,
            Count_Quantity__c = 1,
            Stocking_UOM__c = fuel.itemList[1].Stocking_UOM__c,
            Packaging_UOM__c = fuel.itemList[1].Stocking_UOM__c
        );

        CycleCountExtV2.saveAction(ext.inventoryChange, new List<String>(), new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid, new List<Serial__c>()) }, new List<String>());

        Inventory_Transaction__c it = [SELECT Id, Transaction_Date__c FROM Inventory_Transaction__c];

        Item_Cost__c newCost = new Item_Cost__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[1].Id,
            Start_Date__c = System.now().addDays(2),
            Status__c = 'Proposed'
        );
        insert newCost;

        Test.startTest();
        ActivateProposedCostsBatch activateBatch = new ActivateProposedCostsBatch();
        activateBatch.companyId = fuel.company.Id;
        activateBatch.itemId = fuel.itemList[1].Id;
        activateBatch.scopeRange = 'SINGLE';
        Database.executeBatch(activateBatch);
        Test.stopTest();

        List<Item_Cost__c> costs = [SELECT Id, Change_Reason__c, Date_Approved__c, Invalid_Flag__c, Start_Date__c, Status__c FROM Item_Cost__c WHERE Item__c = :fuel.itemList[1].Id];
        System.assert(costs.size() == 1, costs);
        System.assert(costs[0].Change_Reason__c != null, costs[0]);
        System.assert(costs[0].Date_Approved__c != null, costs[0]);
        System.assert(costs[0].Start_Date__c == it.Transaction_Date__c, costs[0]);
        System.assert(costs[0].Status__c == 'Approved', costs[0]);
    }
}