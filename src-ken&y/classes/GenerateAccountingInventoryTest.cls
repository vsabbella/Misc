@isTest
private class GenerateAccountingInventoryTest {
    @testSetup
    private static void setupData() {
        TestDataForFinance financeData = new TestDataForFinance();

        insert new Location__c(
            Name = 'Test To Location',
            Facility__c = financeData.facility.Id
        );

        insert new SKID__c(
            Company__c = financeData.company.Id,
            Item__c = financeData.itemList[0].Id,
            Facility2__c = financeData.facility.Id,
            Location__c = financeData.location.Id,
            Quantity__c = 200,
            Quantity_Stocking_UOM__c = 200,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Stocking_UOM__c = financeData.itemList[0].Stocking_UOM__c,
            Packaging_UOM__c = financeData.itemList[0].Stocking_UOM__c,
            Container_Item__c = financeData.itemList[0].Id
        );

        List<Reason_Code__c> reasonCodes = new List<Reason_Code__c>();
        reasonCodes.add(new Reason_Code__c(Name = 'Change', Type__c = 'Inventory Change'));
        reasonCodes.add(new Reason_Code__c(Name = 'Transfer', Type__c = 'Inventory Transfer'));
        reasonCodes.add(new Reason_Code__c(Name = 'Cycle', Type__c = 'Cycle Count'));
        insert reasonCodes;

        insert new User_Preference__c(
            OwnerId = UserInfo.getUserId(),
            Default_Company__c = financeData.company.Id,
            Default_Facility__c = financeData.facility.Id
        );
    }

    private static TestDataForFinanceQuery data = new TestDataForFinanceQuery();

    private static Location__c toLocation {
        get {
            if (toLocation == null) {
                SOQLUtil locationQuery = new SOQLUtil('Location__c');
                locationQuery.addAllCustomFields();
                locationQuery.setWhereClause('Name = \'Test To Location\'');
                toLocation = Database.query(locationQuery.getQuery());
            }
            return toLocation;
        } set;
    }

    private static Map<String,Reason_Code__c> reasonCodes {
        get {
            if (reasonCodes == null) {
                reasonCodes = new Map<String,Reason_Code__c>();
                for (Reason_Code__c rc:[SELECT Id,Name,Type__c FROM Reason_Code__c]) {
                    reasonCodes.put(rc.Name,rc);
                }
            }
            return reasonCodes;
        } set;
    }

    private static testMethod void transfer() {
        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(data.company));
        
        ext.inventoryChange.Company__c = data.company.Id;
        ext.inventoryChange.Item__c = data.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Location__c = data.location.Id;

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)InventoryTransferExtV2.getSkids(data.itemList[0].Id, data.facility.Id, new SKID__c(Location__c = data.location.Id), data.facility.Id, toLocation.Id,null,null,null,new List<String>(),new List<String>()).records;
        swList[0].skid.Input_Quantity__c = 75;
        
        Test.startTest();
        
        JsonResult result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, null, data.itemList[0].Id, data.facility.Id, new SKID__c(Location__c = data.location.Id), null, null);
        System.assert(result.success,result);

        Inventory_Change__c ic = [SELECT Id,Finalized__c,Finalized_hidden__c,(SELECT Id,Inventory_Change__c FROM Inventory_Transactions__r) FROM Inventory_Change__c WHERE Id = :result.additionalInfo];
        System.assert(ic.Finalized__c,ic);
        System.assert(ic.Finalized_hidden__c,ic);
        System.assert(ic.Inventory_Transactions__r.size() == 1,ic.Inventory_Transactions__r);

        try {
            update new Inventory_Change__c(Id = ic.Id, Finalized__c = false);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }

        InventoryChangeAccounting ica = new InventoryChangeAccounting();
        ica.execute(ic.Inventory_Transactions__r);

        Accounting_Entry__c ae = [SELECT Id,Transaction_Type__c,(SELECT Id FROM Accounting_Entry_Lines__r) FROM Accounting_Entry__c WHERE Inventory_Change__c = :ic.Id];
        System.assert(ae.Transaction_Type__c == 'Transfer',ae);
        System.assert(ae.Accounting_Entry_Lines__r.size() == 2,ae.Accounting_Entry_Lines__r);
        
        
        Test.stopTest();
    }

    private static testMethod void adjustmentDecrease() {
        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(data.company));
        
        ext.inventoryChange.Company__c = data.company.Id;
        ext.inventoryChange.Item__c = data.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = reasonCodes.get('Change').Id;
        ext.inventoryChange.Location__c = data.location.Id;

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)InventoryChangeExtV2.getSkids(data.itemList[0].Id,data.location.Id).records;
        swList[0].skid.Count_Quantity__c = -12;
        
        Test.startTest();
        
        JsonResult result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        Inventory_Change__c ic = [SELECT Id,(SELECT Id,Inventory_Change__c FROM Inventory_Transactions__r) FROM Inventory_Change__c WHERE Id = :result.additionalInfo];
        System.assert(ic.Inventory_Transactions__r.size() == 1,ic.Inventory_Transactions__r);

        InventoryChangeAccounting ica = new InventoryChangeAccounting();
        ica.execute(ic.Inventory_Transactions__r);

        Test.stopTest();

        Accounting_Entry__c ae = [SELECT Id,Transaction_Type__c,Has_Exceptions__c,(SELECT Id FROM Accounting_Entry_Lines__r) FROM Accounting_Entry__c WHERE Inventory_Change__c = :ic.Id];
        System.assert(ae.Transaction_Type__c == 'Adjustment',ae);
        System.assert(!ae.Has_Exceptions__c,ae);
        System.assert(ae.Accounting_Entry_Lines__r.size() == 2,ae.Accounting_Entry_Lines__r);
    }

    private static testMethod void adjustmentIncrease() {
        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(data.company));
        
        ext.inventoryChange.Company__c = data.company.Id;
        ext.inventoryChange.Item__c = data.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = reasonCodes.get('Change').Id;
        ext.inventoryChange.Location__c = data.location.Id;

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)InventoryChangeExtV2.getSkids(data.itemList[0].Id,data.location.Id).records;
        swList[0].skid.Count_Quantity__c = 100;
        
        Test.startTest();
        
        JsonResult result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        Inventory_Change__c ic = [SELECT Id,(SELECT Id,Inventory_Change__c FROM Inventory_Transactions__r) FROM Inventory_Change__c WHERE Id = :result.additionalInfo];
        System.assert(ic.Inventory_Transactions__r.size() == 1,ic.Inventory_Transactions__r);

        InventoryChangeAccounting ica = new InventoryChangeAccounting();
        ica.execute(ic.Inventory_Transactions__r);

        Test.stopTest();

        Accounting_Entry__c ae = [SELECT Id,Transaction_Type__c,Has_Exceptions__c,(SELECT Id FROM Accounting_Entry_Lines__r) FROM Accounting_Entry__c WHERE Inventory_Change__c = :ic.Id];
        System.assert(ae.Transaction_Type__c == 'Adjustment',ae);
        System.assert(!ae.Has_Exceptions__c,ae);
        System.assert(ae.Accounting_Entry_Lines__r.size() == 2,ae.Accounting_Entry_Lines__r);
    }
    
    private static testMethod void cycleCountIncrease() {
        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(data.company));

        ext.inventoryChange.Company__c = data.company.Id;
        ext.inventoryChange.Item__c = data.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = reasonCodes.get('Cycle').Id;

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)InventoryChangeExtV2.getSkids(data.itemList[0].Id,data.location.Id).records;
        swList[0].skid.Count_Quantity__c = 204;
        
        Test.startTest();
        
        JsonResult result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        Inventory_Change__c ic = [SELECT Id,(SELECT Id,Inventory_Change__c FROM Inventory_Transactions__r) FROM Inventory_Change__c WHERE Id = :result.additionalInfo];
        System.assert(ic.Inventory_Transactions__r.size() == 1,ic.Inventory_Transactions__r);

        InventoryChangeAccounting ica = new InventoryChangeAccounting();
        ica.execute(ic.Inventory_Transactions__r);

        Accounting_Entry__c ae = [SELECT Id,Transaction_Type__c,Has_Exceptions__c,(SELECT Id,Amount_CR__c,Amount_DR__c,GL_Account__c FROM Accounting_Entry_Lines__r) FROM Accounting_Entry__c WHERE Inventory_Change__c = :ic.Id];
        System.assert(ae.Transaction_Type__c == 'Cycle Count',ae);
        System.assert(!ae.Has_Exceptions__c,ae);
        System.assert(ae.Accounting_Entry_Lines__r.size() == 2,ae.Accounting_Entry_Lines__r);

        for (Accounting_Entry_Line__c ael:ae.Accounting_Entry_Lines__r) {
            if (ael.Amount_CR__c != 0 ) {
                System.assert(ael.GL_Account__c != null,ael);
            }
            if (ael.Amount_DR__c != 0 ) {
                System.assert(ael.GL_Account__c == data.inventoryGL.Id,ael);
            }
        }
        
        Test.stopTest();
    }
    
    private static testMethod void cycleCountDecrease() {
        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(data.company));

        ext.inventoryChange.Company__c = data.company.Id;
        ext.inventoryChange.Item__c = data.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = reasonCodes.get('Cycle').Id;

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)InventoryChangeExtV2.getSkids(data.itemList[0].Id,data.location.Id).records;
        swList[0].skid.Count_Quantity__c = 190;
        
        Test.startTest();

        JsonResult result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        Inventory_Change__c ic = [SELECT Id,(SELECT Id,Inventory_Change__c FROM Inventory_Transactions__r) FROM Inventory_Change__c WHERE Id = :result.additionalInfo];
        System.assert(ic.Inventory_Transactions__r.size() == 1,ic.Inventory_Transactions__r);

        InventoryChangeAccounting ica = new InventoryChangeAccounting();
        ica.execute(ic.Inventory_Transactions__r);

        Accounting_Entry__c ae = [SELECT Id,Transaction_Type__c,Has_Exceptions__c,(SELECT Id,Amount_CR__c,Amount_DR__c,GL_Account__c FROM Accounting_Entry_Lines__r) FROM Accounting_Entry__c WHERE Inventory_Change__c = :ic.Id];
        System.assert(ae.Transaction_Type__c == 'Cycle Count',ae);
        System.assert(!ae.Has_Exceptions__c,ae);
        System.assert(ae.Accounting_Entry_Lines__r.size() == 2,ae.Accounting_Entry_Lines__r);

        Test.stopTest();

        for (Accounting_Entry_Line__c ael:ae.Accounting_Entry_Lines__r) {
            if (ael.Amount_CR__c != 0 ) {
                System.assert(ael.GL_Account__c != null,ael);
            }
            if (ael.Amount_DR__c != 0 ) {
                System.assert(ael.GL_Account__c != null,ael);
            }
        }
    }
}