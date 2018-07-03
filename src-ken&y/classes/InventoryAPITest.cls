@isTest
public class InventoryAPITest {
    public static testMethod void transfer() {
        TestFuel fuel = new TestFuel();
        insert new Configuration__c(Name = 'STACKTRACE');

        Item__c item = fuel.itemList[0];
        delete [SELECT Id FROM Item_Attribute__c];

        insert new SKID__c(
            Company__c = item.Company__c,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Item__c = item.Id,
            Packaging_UOM__c = item.Stocking_UOM__c,
            Container_Item__c = item.id,
            Stocking_UOM__c = item.Stocking_UOM__c,
            Facility2__c = fuel.location3.Facility__c,
            Location__c = fuel.location3.Id
        );

        SKID__c fromSkid = new SKID__c(
            Item__c = item.Id,
            Location__c = fuel.location3.Id,
            Input_Quantity__c = 1
        );

        SKID__c toSkid = new SKID__c(
            Location__c = fuel.location5.Id
        );

        Test.startTest();
        InventoryAPI.Transfer transfer = new InventoryAPI.Transfer();
        Action.Response resp = transfer.execute(JSON.serialize(new List<Map<String, Object>>{ new Map<String, Object>{ 'fromSkid' => fromSkid, 'toSkid' => toSkid, 'reasonCode' => fuel.reasonCodes.get('Transfer').Id }}));
        System.assert(resp.success == true, resp);
        Test.stopTest();

        Inventory_Transaction__c it = [SELECT Id, Quantity__c, From_SKID__c, From_SKID__r.Quantity__c, To_SKID__c, To_SKID__r.Quantity__c FROM Inventory_Transaction__c WHERE Type__c = 'Transfer'];
        System.assert(it.Quantity__c == 1, it);
        System.assert(it.From_SKID__r.Quantity__c == 99, it.From_SKID__r);
        System.assert(it.To_SKID__r.Quantity__c == 1, it.To_SKID__r);
    }

    public static testMethod void transferSerials() {
        TestFuel fuel = new TestFuel();
        insert new Configuration__c(Name = 'STACKTRACE');

        Item__c item = fuel.itemList[0];
        update new Item_Attribute__c(Id = item.Item_Attribute__c, Lot_Number__c = false, Expiration_Date__c = false, Serial_Number__c = true);

        SKID__c skid = new SKID__c(
            Company__c = item.Company__c,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Quantity__c = 5,
            Quantity_Stocking_UOM__c = 5,
            Item__c = item.Id,
            Packaging_UOM__c = item.Stocking_UOM__c,
            Container_Item__c = item.id,
            Stocking_UOM__c = item.Stocking_UOM__c,
            Facility2__c = fuel.location3.Facility__c,
            Location__c = fuel.location3.Id
        );
        insert skid;

        List<Serial__c> serials = new List<Serial__c>();
        for (Integer i = 0; i < skid.Quantity__c; i++) {
            serials.add(new Serial__c(
                Name = '' + skid.Id + i,
                Company__c = skid.Company__c,
                Item__c = skid.Item__c,
                SKID__c = skid.Id,
                Unique_Key2__c = '' + skid.Company__c + '-' + skid.Item__c + '-' + skid.Id + i
            ));
        }
        insert serials;
        serials = new List<Serial__c>{ serials[0] };

        SKID__c fromSkid = new SKID__c(
            Item__c = item.Id,
            Location__c = fuel.location3.Id,
            Input_Quantity__c = 1
        );

        SKID__c toSkid = new SKID__c(
            Location__c = fuel.location5.Id
        );

        Test.startTest();
        InventoryAPI.Transfer transfer = new InventoryAPI.Transfer();
        Action.Response resp = transfer.execute(JSON.serialize(new List<Map<String, Object>>{ new Map<String, Object>{ 'fromSkid' => fromSkid, 'toSkid' => toSkid, 'serials' => serials, 'reasonCode' => fuel.reasonCodes.get('Transfer').Id }}));
        System.assert(resp.success == true, resp);
        Test.stopTest();

        Inventory_Transaction__c it = [SELECT Id, Quantity__c, From_SKID__c, From_SKID__r.Quantity__c, To_SKID__c, To_SKID__r.Quantity__c FROM Inventory_Transaction__c WHERE Type__c = 'Transfer'];
        System.assert(it.Quantity__c == 1, it);
        System.assert(it.From_SKID__r.Quantity__c == 4, it.From_SKID__r);
        System.assert(it.To_SKID__r.Quantity__c == 1, it.To_SKID__r);

        Serial_Transaction__c st = [SELECT Id, Serial__c, Serial__r.Name FROM Serial_Transaction__c WHERE Inventory_Transaction__c = :it.Id];
        System.assert(st.Serial__r.Name == serials[0].Name, st);
    }

    public static testMethod void deprecated() {
        try {
            InventoryAPI.createInventoryChange(null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        try {
            InventoryAPI.transferInventory(null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        try {
            InventoryAPI.massInventoryTransfer(null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        try {
            InventoryAPI.InventoryAPIException ex = new InventoryAPI.InventoryAPIException('error');
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
    }

    
    public static testMethod void testChangeBinTracking() {
        TestData data = new TestData();
        data.location3.Bin_Tracked__c = true;
        update data.location3;

        Bin__c bin = new Bin__c();
        bin.Name = 'Location 3 Bin';
        bin.Location__c = data.location3.Id;
        insert bin;

        Item_Attribute__c itemAttr = new Item_Attribute__c(Expiration_Date__c = true,Date_Received__c = true,Lot_Number__c = true);
        insert itemAttr;
        data.itemList[0].Item_Attribute__c = itemAttr.Id;
        update data.itemList[0];
        
        Lot__c lot = new Lot__c();
        lot.Name = 'A';
        lot.Company__c = data.company.Id;
        lot.Item__c = data.itemList[0].Id;
        lot.Expiration_Date__c = System.today() + 365;
        lot.Supplier__c = data.remitToSupplier.Id;
        insert lot;
        
        SKID__c skid = new SKID__c(
            Location__c = data.location3.id,
            Quantity__c = 5.0,
            Item__c = data.itemList[0].Id,
            Item__r = data.itemList[0],
            Type__c = SKIDService.SKID_TYPE_LOCATION,
            Expiration_Date__c = System.today() + 365,
            Date_Received__c = System.today(),
            Lot__c = lot.Id,
            Lot_Number__c = 'A',
            Bin__c = bin.Id,
            Company__c = data.company.Id
        );
        insert skid;

        Map<String,InventoryAPI.InventoryData> icData = new Map<String,InventoryAPI.InventoryData>();
        InventoryAPI.InventoryData inv1 = new InventoryAPI.InventoryData();
        inv1.itemId = data.itemList[0].Id;
        inv1.reasonCodeId = [SELECT Id FROM Reason_Code__c WHERE Type__c = 'Inventory Change'][0].Id;
        inv1.locationId = data.location3.id;
        inv1.quantity = 1;
        inv1.lot = 'A';
        inv1.expirationDate = System.today() + 365;
        inv1.dateReceived = System.today();
        inv1.attributes.put('Date_Received__c',System.today());
        inv1.bin = bin.Name;
        icData.put('1',inv1);

        Test.startTest();
        InventoryAPI.createInventoryChanges(icData);
        Test.stopTest();

        List<SKID__c> skidList = [SELECT Id,Quantity__c FROM SKID__c where Type__c = :SkidService2.SKID_TYPE_LOCATION and Location__c =:data.location3.id AND Lot_Number__c = 'A' AND Bin__c = :bin.Id];
        System.assert(skidList[0].Quantity__c == 6,'Should have 6 units in stock location');
    }
    public static testMethod void testICSuccess() {
        TestData data = new TestData();
        List<Configuration__c> configList = new List<Configuration__c>();  
        List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType,Bin__c.sObjectType};  
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        data.location3.Bin_Tracked__c = false;
        update data.location3;
        delete  configList;
        Item_Attribute__c itemAttr = new Item_Attribute__c(Expiration_Date__c = true,Date_Received__c = true,Lot_Number__c = true);
        insert itemAttr;
        data.itemList[0].Item_Attribute__c = itemAttr.Id;
        update data.itemList[0];
        
        Lot__c lot = new Lot__c();
        lot.Name = 'A';
        lot.Company__c = data.company.Id;
        lot.Item__c = data.itemList[0].Id;
        lot.Expiration_Date__c = System.today() + 365;
        lot.Supplier__c = data.remitToSupplier.Id;
        insert lot;
        Lot__c lot2 = new Lot__c();
        lot2.Name = 'B';
        lot2.Company__c = data.company.Id;
        lot2.Item__c = data.itemList[0].Id;
        lot2.Expiration_Date__c = System.today() + 365;
        lot2.Supplier__c = data.remitToSupplier.Id;
        insert lot2;
        
        SKID__c skid = new SKID__c(
            Location__c = data.location3.id,
            //Company__c = data.company.id,
            Quantity__c = 5.0,
            Item__c = data.itemList[0].Id,
            Type__c = SKIDService.SKID_TYPE_LOCATION,
            Expiration_Date__c = System.today() + 365,
            Date_Received__c = System.today(),
            Lot__c = lot.Id,
            Lot_Number__c = 'A',
            Company__c = data.company.Id
        );
        insert skid;
        SKID__c skid2 = new SKID__c(
            Location__c = data.location3.id,
            //Company__c = data.company.id,
            Quantity__c = 20.0,
            Item__c = data.itemList[0].Id,
            Type__c = SKIDService.SKID_TYPE_LOCATION,
            Expiration_Date__c = System.today() + 365,
            Date_Received__c = System.today(),
            Lot__c = lot2.Id,
            Lot_Number__c = 'B',
            Company__c = data.company.Id
        );
        insert skid2;

        Map<String,InventoryAPI.InventoryData> icData = new Map<String,InventoryAPI.InventoryData>();
        InventoryAPI.InventoryData inv1 = new InventoryAPI.InventoryData();
        inv1.itemId = data.itemList[0].Id;
        inv1.reasonCodeId = [SELECT Id FROM Reason_Code__c WHERE Type__c = 'Inventory Change'][0].Id;
        inv1.locationId = data.location3.id;
        inv1.quantity = 10;
        inv1.lot = 'A';
        inv1.expirationDate = System.today() + 365;
        inv1.dateReceived = System.today();
        inv1.attributes.put('Date_Received__c',System.today());
        icData.put('1',inv1);
        InventoryAPI.InventoryData inv2 = new InventoryAPI.InventoryData();
        inv2.itemId = data.itemList[0].Id;
        inv2.reasonCodeId = [SELECT Id FROM Reason_Code__c WHERE Type__c = 'Inventory Change'][0].Id;
        inv2.locationId = data.location3.id;
        inv2.quantity = -10;
        inv2.lot = 'B';
        inv2.expirationDate = System.today() + 365;
        inv2.dateReceived = System.today();
        inv2.attributes.put('Date_Received__c',System.today());
        icData.put('2',inv2);
        InventoryAPI.InventoryData inv3 = new InventoryAPI.InventoryData();
        inv3.itemId = data.itemList[0].Id;
        inv3.reasonCodeId = [SELECT Id FROM Reason_Code__c WHERE Type__c = 'Inventory Change'][0].Id;
        inv3.locationId = data.location3.id;
        inv3.quantity = 10;
        inv3.lot = 'C';
        inv3.expirationDate = System.today() + 365;
        inv3.dateReceived = System.today();
        inv3.attributes.put('Date_Received__c',System.today());
        icData.put('3',inv3);

        Test.startTest();
        InventoryAPI.createInventoryChanges(icData);
        Test.stopTest();

        List<SKID__c> skidList = [SELECT Id,Quantity__c FROM SKID__c where Type__c = :SkidService2.SKID_TYPE_LOCATION and Location__c =:data.location3.id AND Lot_Number__c = 'A'];
        List<SKID__c> skidList2 = [SELECT Id,Quantity__c FROM SKID__c where Type__c = :SkidService2.SKID_TYPE_LOCATION and Location__c =:data.location3.id AND Lot_Number__c = 'B'];
        List<SKID__c> skidList3 = [SELECT Id,Quantity__c FROM SKID__c where Type__c = :SkidService2.SKID_TYPE_LOCATION and Location__c =:data.location3.id AND Lot_Number__c = 'C'];
        System.assert(skidList[0].Quantity__c == 15,'Should have 15 units in stock location in lot A');
        System.assert(skidList2[0].Quantity__c == 10,'Should have 10 units in stock location in lot B');
        System.assert(skidList3[0].Quantity__c == 10,'Should have 10 units in stock location in lot C');
    }

    public static testMethod void testICFailNoLotProvided() {
        TestData data = new TestData();
        List<Configuration__c> configList = new List<Configuration__c>();  
        List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType,Bin__c.sObjectType};  
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        data.location3.Bin_Tracked__c = false;
        update data.location3;
        delete  configList;
        Item_Attribute__c itemAttr = new Item_Attribute__c(Expiration_Date__c = true,Date_Received__c = true,Lot_Number__c = true);
        insert itemAttr;
        data.itemList[0].Item_Attribute__c = itemAttr.Id;
        update data.itemList[0];
        
        Lot__c lot = new Lot__c();
        lot.Name = 'A';
        lot.Company__c = data.company.Id;
        lot.Item__c = data.itemList[0].Id;
        lot.Expiration_Date__c = System.today() + 365;
        lot.Supplier__c = data.remitToSupplier.Id;
        insert lot;
        
        SKID__c skid = new SKID__c(
            Location__c = data.location3.id,
            //Company__c = data.company.id,
            Quantity__c = 5.0,
            Item__c = data.itemList[0].Id,
            Type__c = SKIDService.SKID_TYPE_LOCATION,
            Expiration_Date__c = System.today() + 365,
            Date_Received__c = System.today(),
            Lot__c = lot.Id,
            Lot_Number__c = 'A',
            Company__c = data.company.Id
        );
        insert skid;

        Map<String,InventoryAPI.InventoryData> icData = new Map<String,InventoryAPI.InventoryData>();
        InventoryAPI.InventoryData inv1 = new InventoryAPI.InventoryData();
        inv1.itemId = data.itemList[0].Id;
        inv1.reasonCodeId = [SELECT Id FROM Reason_Code__c WHERE Type__c = 'Inventory Change'][0].Id;
        inv1.locationId = data.location3.id;
        inv1.quantity = 10;
        inv1.expirationDate = System.today() + 365;
        inv1.dateReceived = System.today();
        inv1.attributes.put('Date_Received__c',System.today());
        icData.put('1',inv1);

        Test.startTest();
        InventoryAPI.createInventoryChanges(icData);
        Test.stopTest();

        List<SKID__c> skidList = [SELECT Id,Quantity__c FROM SKID__c where Type__c = :SkidService2.SKID_TYPE_LOCATION and Location__c =:data.location3.id AND Lot_Number__c = 'A'];
        System.assert(skidList[0].Quantity__c == 5,'Should have 5 units in stock location in lot A');
    }
    public static testMethod void testGetAvailableInventory() {
        TestData data = new TestData();
        List<Configuration__c> configList = new List<Configuration__c>();  
        List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType,Bin__c.sObjectType};  
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        data.location3.Bin_Tracked__c = false;
        update data.location3;
        delete  configList;
        
        Lot__c lot = new Lot__c();
        lot.Name = 'AAA';
        lot.Company__c = data.company.Id;
        lot.Item__c = data.itemList[0].Id;
        lot.Expiration_Date__c = System.today() + 365;
        lot.Supplier__c = data.remitToSupplier.Id;
        insert lot;
        
        SKID__c skid = new SKID__c(
            Location__c = data.location3.id,
            //Company__c = data.company.id,
            Quantity__c = 200.0,
            Item__c= data.itemList[0].Id,
            Type__c = SKIDService.SKID_TYPE_LOCATION,
            Expiration_Date__c = System.today() + 365,
            Lot__c = lot.Id,
            Lot_Number__c = 'AAA',
            Company__c = data.company.Id
        );
        insert skid;
        
        Test.startTest();
        Map<String,List<SKID__c>> inventoryMap = InventoryAPI.getAvailableInventory(new Set<Id>{data.itemList[0].Id},new Set<Id>{data.location3.Id});
        Test.stopTest();
        
        System.assert(inventoryMap.size() == 1,'Should have one key key-value pair');
        System.assert(inventoryMap.get(data.itemList[0].Id + ',' + data.location3.Id) != null,'The list of SKIDs should not be null');
        System.assert(inventoryMap.get(data.itemList[0].Id + ',' + data.location3.Id).size() == 1,'Should return one SKID');
        System.assert(inventoryMap.get(data.itemList[0].Id + ',' + data.location3.Id)[0].Quantity__c == 200,'The SKID returned should have qty of 200');
    }
}