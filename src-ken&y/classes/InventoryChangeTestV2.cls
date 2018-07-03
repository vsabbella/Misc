@isTest
private class InventoryChangeTestV2 {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.periodList != null);
        System.assert(f.reasonCodes != null);
        System.assert(f.itemList != null);
        System.assert(f.location3 != null);
        System.assert(f.location5 != null);
        System.assert(f.itemAttrObj2 != null);
        System.assert(f.salesOrder != null);
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);

        insert new User_Preference__c(
            OwnerId = UserInfo.getUserId(),
            Default_Company__c = f.company.Id,
            Default_Facility__c = f.facility2.Id,
            User__c = UserInfo.getUserId()
        );
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void noAttributes() {
        fuel.setupInventory(false,false);

        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(fuel.company));
        ext.getInventoryChangeJson();
        ext.getInventoryChangeHeaderFieldList();
        ext.getSkidsConfigJson();
        InventoryChangeExtV2.getItemDetails(fuel.itemList[0].Id);
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Change').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;
        ext.inventoryChange.Transaction_Date__c = System.now();

        JsonResult result = InventoryChangeExtV2.getSkids(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        swList[0].skid.Count_Quantity__c = 1;

        result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);

        System.assert(itList[0].From_SKID__c != null,itList[0]);
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].From_SKID__c == itList[0].To_SKID__c,itList[0]);
        System.assert(itList[0].Quantity__c == 1,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 101,itList[0].From_SKID__r);
    }

    private static testMethod void attributes() {
        fuel.setupInventory(true,false);

        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Change').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;
        ext.inventoryChange.Transaction_Date__c = System.now();

        JsonResult result = InventoryChangeExtV2.getSkids(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        swList[0].skid.Count_Quantity__c = -1;

        result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);

        System.assert(itList[0].From_SKID__c != null,itList[0]);
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].From_SKID__c == itList[0].To_SKID__c,itList[0]);
        System.assert(itList[0].Quantity__c == -1,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 99,itList[0].From_SKID__r);
    }

    private static testMethod void serials() {
        fuel.setupInventory(true,true);

        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Change').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;
        ext.inventoryChange.Transaction_Date__c = System.now();

        JsonResult result = InventoryChangeExtV2.getSkids(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        swList[0].skid.Count_Quantity__c = -1;
        swList[0].serialList.remove(0);

        result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery,'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);

        System.assert(itList[0].From_SKID__c != null,itList[0]);
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].From_SKID__c == itList[0].To_SKID__c,itList[0]);
        System.assert(itList[0].Quantity__c == -1,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 9,itList[0].From_SKID__r);
        System.assert(itList[0].Serial_Transactions__r.size() == 1,itList[0].Serial_Transactions__r);
        System.assert(itList[0].Serial_Transactions__r[0].Type__c == 'Adjustment',itList[0].Serial_Transactions__r[0]);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.setWhereClause('Id = \'' + itList[0].From_SKID__c + '\'');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery,'Serials__r');
        serialQuery.addAllCustomFields();
        skidQuery.addChildRelationship(serialQuery);

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 1,skids);

        System.assert(skids[0].Quantity__c == skids[0].Serials__r.size(),skids[0].Serials__r);
        for (Serial__c serial:skids[0].Serials__r) {
            System.assert(!serial.Allow_Reentry__c,serial);
        }

        SOQLUtil serQuery = new SOQLUtil('Serial__c');
        serQuery.addAllCustomFields();
        serQuery.setWhereClause('SKID__c = null');

        List<Serial__c> serials = Database.query(serQuery.getQuery());
        System.assert(serials.size() == 1,serials);
        System.assert(serials[0].Allow_Reentry__c,serials[0]);
    }

    private static testMethod void createSkid() {
        fuel.setupInventory(true,false);

        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Change').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;
        ext.inventoryChange.Transaction_Date__c = System.now();

        SKID__c skid = new SKID__c(
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Location__c = fuel.location3.Id,
            Location__r = fuel.location3,
            Count_Quantity__c = 25,
            Expiration_Date__c = System.today() + 10,
            Lot_Number__c = 'ABC',
            Packaging_UOM__c = fuel.uomList[8].Id
        );

        JsonResult result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,new List<Serial__c>()) },new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);

        System.assert(itList[0].From_SKID__c != null,itList[0]);
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].From_SKID__c == itList[0].To_SKID__c,itList[0]);
        System.assert(itList[0].Quantity__c == 25,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 25,itList[0].From_SKID__r);
    }

    private static testMethod void deleteSkid() {
        fuel.setupInventory(true,false);

        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Change').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;
        ext.inventoryChange.Transaction_Date__c = System.now();

        JsonResult result = InventoryChangeExtV2.getSkids(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        swList[0].skid.Count_Quantity__c = 1;

        delete [SELECT Id FROM SKID__c];

        result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);

        System.assert(itList[0].From_SKID__c != null,itList[0]);
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].From_SKID__c == itList[0].To_SKID__c,itList[0]);
        System.assert(itList[0].Quantity__c == 1,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 1,itList[0].From_SKID__r);
    }

    private static testMethod void updateSkid() {
        fuel.setupInventory(true,false);

        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Change').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;
        ext.inventoryChange.Transaction_Date__c = System.now();

        JsonResult result = InventoryChangeExtV2.getSkids(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        swList[0].skid.Count_Quantity__c = 1;

        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Item__c = :fuel.itemList[0].Id];
        for (SKID__c skid:skids) {
            skid.Quantity__c = 40;
        }
        update skids;

        result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);

        System.assert(itList[0].From_SKID__c != null,itList[0]);
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].From_SKID__c == itList[0].To_SKID__c,itList[0]);
        System.assert(itList[0].Quantity__c == 1,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 41,itList[0].From_SKID__r);
    }

    private static testMethod void zeroSkid() {
        fuel.setupInventory(true,false);

        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Change').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;
        ext.inventoryChange.Transaction_Date__c = System.now();

        JsonResult result = InventoryChangeExtV2.getSkids(fuel.itemList[0].Id,fuel.location3.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        swList[0].skid.Count_Quantity__c = -100;

        result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);

        System.assert(itList[0].From_SKID__c == null,itList[0]);
        System.assert(itList[0].To_SKID__c == null,itList[0]);
        System.assert(itList[0].Quantity__c == -100,itList[0]);
    }

    private static testMethod void missingAttr() {
        fuel.setupInventory(true,false);

        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Change').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;
        ext.inventoryChange.Transaction_Date__c = System.now();

        SKID__c skid = new SKID__c(
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Location__c = fuel.location3.Id,
            Location__r = fuel.location3,
            Count_Quantity__c = 25,
            Expiration_Date__c = System.today() + 10
        );

        JsonResult result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,new List<Serial__c>()) },new List<String>());
        System.assert(!result.success,result);
    }

    private static testMethod void duplicate() {
        fuel.setupInventory(true,false);

        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Change').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;
        ext.inventoryChange.Transaction_Date__c = System.now();

        SKID__c skid = new SKID__c(
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Location__c = fuel.location3.Id,
            Location__r = fuel.location3,
            Count_Quantity__c = 25,
            Expiration_Date__c = System.today() + 10,
            Lot_Number__c = 'ABC'
        );

        JsonResult result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,new List<Serial__c>()), new SkidService3.SerialWrapper(skid.clone(false,true),new List<Serial__c>()) },new List<String>());
        System.assert(!result.success,result);
    }

    private static testMethod void existingSkid() {
        fuel.setupInventory(true,false);

        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Change').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;
        ext.inventoryChange.Transaction_Date__c = System.now();

        SKID__c skid = new SKID__c(
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Location__c = fuel.location3.Id,
            Location__r = fuel.location3,
            Count_Quantity__c = 25,
            Expiration_Date__c = System.today() + 365,
            Lot_Number__c = 'LOT1'
        );

        JsonResult result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,new List<Serial__c>()) },new List<String>());
        System.assert(!result.success,result);
    }
    
    private static testMethod void binCapacityInvChangeSucess() {
        
        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
         Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin1;
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Bin__c = bin1.id,
            Quantity__c = 1,
            Quantity_Stocking_UOM__c =1,
            Item__c = fuel.itemList[14].Id,
            Type__c = 'Location',
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[12].Id,  
            Packaging_UOM__r = fuel.uomList[12],
            Stocking_UOM__c = fuel.uomList[11].Id,  
            Stocking_UOM__r = fuel.uomList[11],
            Container_Item__c = fuel.itemList[12].Id ,//case container item  
            Container_Item__r = fuel.itemList[12]  
        );
        insert skid;

        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(fuel.company));
        ext.getInventoryChangeJson();
        ext.getInventoryChangeHeaderFieldList();
        ext.getSkidsConfigJson();
        InventoryChangeExtV2.getItemDetails(fuel.itemList[14].Id);
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[14].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Change').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;
        ext.inventoryChange.Transaction_Date__c = System.now();

        JsonResult result = InventoryChangeExtV2.getSkids(fuel.itemList[14].Id,fuel.location3.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        swList[0].skid.Count_Quantity__c = 1;

        result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[14].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);  

        System.assert(itList[0].From_SKID__c != null,itList[0]);
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].From_SKID__c == itList[0].To_SKID__c,itList[0]);
        System.assert(itList[0].Quantity__c == 1,itList[0]);
        System.assert(itList[0].Packaging_UOM__c == fuel.uomList[12].Id);
        System.assert(itList[0].Stocking_UOM__c == fuel.uomList[11].Id);
        System.assert(itList[0].Quantity_Stocking_UOM__c == 2);
        System.assert(itList[0].From_SKID__r.Quantity__c == 2,itList[0].From_SKID__r);
        System.assert(itList[0].From_SKID__r.Packaging_UOM__c == fuel.uomList[12].Id);
        System.assert(itList[0].From_SKID__r.Stocking_UOM__c == fuel.uomList[11].Id);
        System.assert(itList[0].From_SKID__r.Quantity_Stocking_UOM__c == 4);
    }
    
     private static testMethod void binCapacityInvChangeFail() {
       
        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
         Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin1;
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Bin__c = bin1.id,
            Quantity__c = 1,
            Quantity_Stocking_UOM__c =1,
            Item__c = fuel.itemList[14].Id,
            Type__c = 'Location',
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[12].Id,  
            Stocking_UOM__c = fuel.uomList[12].Id,
            Packaging_UOM__r = fuel.uomList[12],
            Container_Item__c = fuel.itemList[12].Id ,//case container item  
            Container_Item__r = fuel.itemList[12]  
        );
        insert skid;

        InventoryChangeExtV2 ext = new InventoryChangeExtV2(new ApexPages.StandardController(fuel.company));
        ext.getInventoryChangeJson();
        ext.getInventoryChangeHeaderFieldList();
        ext.getSkidsConfigJson();
        InventoryChangeExtV2.getItemDetails(fuel.itemList[14].Id);
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[14].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Change').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;
        ext.inventoryChange.Transaction_Date__c = System.now();

        JsonResult result = InventoryChangeExtV2.getSkids(fuel.itemList[14].Id,fuel.location3.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        swList[0].skid.Count_Quantity__c = 3;

        result = InventoryChangeExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success == false, result);
    }
}