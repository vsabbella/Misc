@isTest
private class CycleCountTestV2 {
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

        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));
        ext.getInventoryChangeJson();
        ext.getInventoryChangeHeaderFieldList();
        ext.getSkidsConfigJson();
        CycleCountExtV2.getItemDetails(fuel.itemList[0].Id);

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        JsonResult result = CycleCountExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Count_Quantity__c = 101;
            } else if (sw.skid.Location__c == fuel.location5.Id) {
                sw.skid.Count_Quantity__c = 99;
            }
        }

        result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2,itList);
        
        for (Inventory_Transaction__c it:itList) {
            System.assert(it.From_SKID__c != null,it);
            System.assert(it.To_SKID__c != null,it);
            System.assert(it.From_SKID__c == it.To_SKID__c,it);

            if (it.To_Location__c == fuel.location3.Id) {
                System.assert(it.Quantity__c == 1,it);
                System.assert(it.From_SKID__r.Quantity__c == 101,it.From_SKID__r);
            } else if (it.To_Location__c == fuel.location5.Id) {
                System.assert(it.Quantity__c == -1,it);
                System.assert(it.From_SKID__r.Quantity__c == 99,it.From_SKID__r);
            }
        }
    }

    private static testMethod void attributes() {
        fuel.setupInventory(true,false);

        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        JsonResult result = CycleCountExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Count_Quantity__c = 101;
            } else if (sw.skid.Location__c == fuel.location5.Id) {
                sw.skid.Count_Quantity__c = 99;
            }
        }

        result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2,itList);
        
        for (Inventory_Transaction__c it:itList) {
            System.assert(it.From_SKID__c != null,it);
            System.assert(it.To_SKID__c != null,it);
            System.assert(it.From_SKID__c == it.To_SKID__c,it);

            if (it.To_Location__c == fuel.location3.Id) {
                System.assert(it.Quantity__c == 1,it);
                System.assert(it.From_SKID__r.Quantity__c == 101,it.From_SKID__r);
            } else if (it.To_Location__c == fuel.location5.Id) {
                System.assert(it.Quantity__c == -1,it);
                System.assert(it.From_SKID__r.Quantity__c == 99,it.From_SKID__r);
            }
        }
    }

    private static testMethod void serials() {
        fuel.setupInventory(true,true);

        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        JsonResult result = CycleCountExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Count_Quantity__c = 11;

                sw.serialList.add(new Serial__c(Name = 'NEWSERIAL'));
            } else if (sw.skid.Location__c == fuel.location5.Id) {
                sw.skid.Count_Quantity__c = 9;

                sw.serialList.remove(0);
            }
        }

        result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
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
        System.assert(itList.size() == 2,itList);
        
        Set<Id> skidIds = new Set<Id>();
        for (Inventory_Transaction__c it:itList) {
            System.assert(it.From_SKID__c != null,it);
            System.assert(it.To_SKID__c != null,it);
            System.assert(it.From_SKID__c == it.To_SKID__c,it);
            System.assert(it.Serial_Transactions__r.size() == 1);
            System.assert(it.Serial_Transactions__r[0].Type__c == it.Type__c,it.Serial_Transactions__r[0]);
            skidIds.add(it.From_SKID__c);

            if (it.To_Location__c == fuel.location3.Id) {
                System.assert(it.Quantity__c == 1,it);
                System.assert(it.From_SKID__r.Quantity__c == 11,it.From_SKID__r);
            } else if (it.To_Location__c == fuel.location5.Id) {
                System.assert(it.Quantity__c == -1,it);
                System.assert(it.From_SKID__r.Quantity__c == 9,it.From_SKID__r);
            }
        }

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.setWhereClause('Id IN :skidIds');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery,'Serials__r');
        serialQuery.addAllCustomFields();
        skidQuery.addChildRelationship(serialQuery);

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2,skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Quantity__c == skid.Serials__r.size(),skid.Serials__r);
            for (Serial__c serial:skid.Serials__r) {
                System.assert(!serial.Allow_Reentry__c,serial);
            }
        }

        SOQLUtil serQuery = new SOQLUtil('Serial__c');
        serQuery.addAllCustomFields();
        serQuery.setWhereClause('SKID__c = null');

        List<Serial__c> serials = Database.query(serQuery.getQuery());
        System.assert(serials.size() == 1,serials);
        System.assert(serials[0].Allow_Reentry__c,serials[0]);
    }

    private static testMethod void createSkid() {
        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        SKID__c skid = new SKID__c(
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Location__c = fuel.location3.Id,
            Location__r = fuel.location3,
            Count_Quantity__c = 25,
            Expiration_Date__c = System.today() + 10,
            Lot_Number__c = 'ABC',
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Container_Item__c = fuel.itemList[0].id
        );

        JsonResult result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,new List<Serial__c>()) },new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);

        Inventory_Transaction__c it = itList[0];
        System.assert(it.From_SKID__c != null,it);
        System.assert(it.To_SKID__c != null,it);
        System.assert(it.From_SKID__c == it.To_SKID__c,it);
        System.assert(it.Quantity__c == 25,it);
        System.assert(it.From_SKID__r.Quantity__c == 25,it.From_SKID__r);
        System.assert(it.From_SKID__r.Company__c != null,it.From_SKID__r);
        System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,it.From_SKID__r);
        System.assert(it.From_SKID__r.Lot__c != null,it.From_SKID__r);
        System.assert(it.From_SKID__r.Facility2__c != null,it.From_SKID__r);
    }

    public static testMethod void skidDeleted() {
        fuel.setupInventory(true,false);

        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        JsonResult result = CycleCountExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Count_Quantity__c = 41;
            } else if (sw.skid.Location__c == fuel.location5.Id) {
                sw.skid.Count_Quantity__c = 39;
            }
        }

        delete [SELECT Id FROM SKID__c];

        result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2,itList);
        
        for (Inventory_Transaction__c it:itList) {
            System.assert(it.From_SKID__c != null,it);
            System.assert(it.To_SKID__c != null,it);
            System.assert(it.From_SKID__c == it.To_SKID__c,it);

            if (it.To_Location__c == fuel.location3.Id) {
                System.assert(it.Quantity__c == 41,it);
                System.assert(it.From_SKID__r.Quantity__c == 41,it.From_SKID__r);
            } else if (it.To_Location__c == fuel.location5.Id) {
                System.assert(it.Quantity__c == 39,it);
                System.assert(it.From_SKID__r.Quantity__c == 39,it.From_SKID__r);
            }
        }
    }

    public static testMethod void skidUpdated() {
        fuel.setupInventory(true,false);

        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        JsonResult result = CycleCountExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Count_Quantity__c = 41;
            } else if (sw.skid.Location__c == fuel.location5.Id) {
                sw.skid.Count_Quantity__c = 39;
            }
        }

        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Item__c = :fuel.itemList[0].Id];
        for (SKID__c skid:skids) {
            skid.Quantity__c = 40;
        }
        update skids;

        result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2,itList);
        
        for (Inventory_Transaction__c it:itList) {
            System.assert(it.From_SKID__c != null,it);
            System.assert(it.To_SKID__c != null,it);
            System.assert(it.From_SKID__c == it.To_SKID__c,it);

            if (it.To_Location__c == fuel.location3.Id) {
                System.assert(it.Quantity__c == 1,it);
                System.assert(it.From_SKID__r.Quantity__c == 41,it.From_SKID__r);
            } else if (it.To_Location__c == fuel.location5.Id) {
                System.assert(it.Quantity__c == -1,it);
                System.assert(it.From_SKID__r.Quantity__c == 39,it.From_SKID__r);
            }
        }
    }

    public static testMethod void zeroSkid() {
        fuel.setupInventory(true,false);

        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        JsonResult result = CycleCountExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Count_Quantity__c = 0;
            } else if (sw.skid.Location__c == fuel.location5.Id) {
                sw.skid.Count_Quantity__c = 101;
            }
        }

        result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2,itList);
        
        for (Inventory_Transaction__c it:itList) {
            if (it.To_Location__c == fuel.location3.Id) {
                System.assert(it.From_SKID__c == null,it);
                System.assert(it.To_SKID__c == null,it);
                System.assert(it.Quantity__c == -100,it);
            } else if (it.To_Location__c == fuel.location5.Id) {  
                System.assert(it.From_SKID__c != null,it);
                System.assert(it.To_SKID__c != null,it);
                System.assert(it.From_SKID__c == it.To_SKID__c,it);
                System.assert(it.Quantity__c == 1,it);
                System.assert(it.From_SKID__r.Quantity__c == 101,it.From_SKID__r);
            }
        }

        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Item__c = :fuel.itemList[0].Id AND Location__c = :fuel.location3.Id];
        System.assert(skids.size() == 0,skids);
    }

    public static testMethod void companyFacilityMismatch() {
        fuel.setupInventory(true,false);

        Company__c newCompany = fuel.company.clone(false,true);
        newCompany.Name = 'TestCycleCountCompany';
        newCompany.Company_Identifier__c = 'TEST1';
        insert newCompany;

        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = newCompany.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        SKID__c skid = new SKID__c(
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Location__c = fuel.location3.Id,
            Location__r = fuel.location3,
            Count_Quantity__c = 25,
            Lot_Number__c = 'ABC',
            Expiration_Date__c = System.today() + 10
        );

        JsonResult result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,new List<Serial__c>()) },new List<String>());
        System.assert(!result.success,result);
    }

    public static testMethod void negativeQty() {
        fuel.setupInventory(true,false);

        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        JsonResult result = CycleCountExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Count_Quantity__c = -1;
            } else if (sw.skid.Location__c == fuel.location5.Id) {
                sw.skid.Count_Quantity__c = 99;
            }
        }

        result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(!result.success,result);
    }

    public static testMethod void missingAttr() {
        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        SKID__c skid = new SKID__c(
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Location__c = fuel.location3.Id,
            Location__r = fuel.location3,
            Count_Quantity__c = 25,
            Expiration_Date__c = System.today() + 10
        );

        JsonResult result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,new List<Serial__c>()) },new List<String>());
        System.assert(!result.success,result);
    }

    public static testMethod void duplicate() {
        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        SKID__c skid = new SKID__c(
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Location__c = fuel.location3.Id,
            Location__r = fuel.location3,
            Count_Quantity__c = 25,
            Expiration_Date__c = System.today() + 10,
            Lot_Number__c = 'ABC'
        );

        JsonResult result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,new List<Serial__c>()), new SkidService3.SerialWrapper(skid.clone(false,true),new List<Serial__c>()) },new List<String>());
        System.assert(!result.success,result);
    }

    public static testMethod void existingSkid() {
        fuel.setupInventory(true,false);

        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        SKID__c skid = new SKID__c(
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Location__c = fuel.location3.Id,
            Location__r = fuel.location3,
            Count_Quantity__c = 25,
            Expiration_Date__c = System.today() + 365,
            Lot_Number__c = 'LOT1'
        );

        JsonResult result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,new List<Serial__c>()) },new List<String>());
        System.assert(!result.success,result);
    }

    public static testMethod void cycleCountDates() {
        fuel.setupInventory(true,false);

        Facility_Item__c fi = new Facility_Item__c(
            Company__c = fuel.company.Id,
            Facility__c = fuel.facility2.Id,
            Item__c = fuel.itemList[0].Id
        );

        FacilityItemNewExt fiExt = new FacilityItemNewExt(new ApexPages.StandardController(fi));
        fiExt.SaveFI();
        System.assert(!ApexPages.hasMessages(),ApexPages.getMessages());

        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        JsonResult result = CycleCountExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Count_Quantity__c = 101;
            }
        }

        result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        fi = [SELECT Id,Name,ABC_Code__c,Last_Cycle_Count__c,Next_Cycle_Count_Date__c FROM Facility_Item__c WHERE Facility__c = :fuel.facility2.Id AND Item__c = :fuel.itemList[0].Id AND Active__c = true];
        System.assert(fi.ABC_Code__c == 'C',fi);
        system.assert(fi.Last_Cycle_Count__c == System.today(),fi);            
        system.assert(fi.Next_Cycle_Count_Date__c == (fi.Last_Cycle_Count__c + Integer.valueof(fuel.company.C_Days__c)),fi);
    }
    
    public static testMethod void testPalletize() {
        fuel.setupInventory(true,false,true);

        CycleCountExtV2 ext = new CycleCountExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[14].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Cycle').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;

        JsonResult result = CycleCountExtV2.getSkids(fuel.itemList[14].Id,fuel.facility2.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 5,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id && sw.skid.Packaging_UOM__c == fuel.uomList[12].Id && sw.skid.Container_Item__c == fuel.itemList[13].Id) { //Part Pallet skid
                sw.skid.Count_Quantity__c = 3; //changing from 1 to 3 cases making it a full pallet
            }
        }

        result = CycleCountExtV2.saveAction(ext.inventoryChange,new List<String>(),swList,new List<String>());
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addField('License_Plate_Number__r.Name');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2,itList);

        for( Inventory_Transaction__c it : itList ){
            
            if(it.Type__c == 'Cycle Count'){
                System.assert(it.Quantity__c == 2,it);
                System.assert(it.Packaging_UOM__c == fuel.uomList[12].Id,it);
                System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                System.assert(it.To_SKID__r.Container_Item__c == fuel.itemList[13].Id,it.To_SKID__r);//pallet containwr
            }
            else if(it.Type__c == 'Palletize'){
                System.assert(it.From_SKID__c == it.To_SKID__c,it);
                System.assert(it.Quantity__c == 1,it);
                System.assert(it.Packaging_UOM__c == fuel.uomList[13].Id,it);
                System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                System.assert(it.To_SKID__r.Container_Item__c == fuel.itemList[13].Id,it.To_SKID__r);//pallet containwr
            }
            else{
                system.assert(false); // should not enter here
            }
        }
    }
}