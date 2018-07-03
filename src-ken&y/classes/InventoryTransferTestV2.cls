@isTest
private class InventoryTransferTestV2 {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.periodList != null);
        System.assert(f.reasonCodes != null);
        System.assert(f.itemList != null);
        System.assert(f.location != null);
        System.assert(f.location3 != null);
        System.assert(f.location5 != null);
        System.assert(f.itemAttrObj2 != null);
        System.assert(f.salesOrder != null);
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.bin != null);

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

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        ext.getInventoryChangeJson();
        ext.getSkidObjJson();
        ext.getInventoryChangeHeaderFieldList();
        ext.getSkidsConfigJson();
        InventoryTransferExtV2.getItemDetails(new SKID__c(Item__c = fuel.itemList[0].Id),new List<String>(),new List<String>());
        InventoryTransferExtV2.getInvAdditionalFields(fuel.itemList[0].Id);
        InventoryTransferExtV2.getAttrOptions(fuel.itemList[0].Id);
        InventoryTransferExtV2.getLocationRecord(fuel.location3.Id);
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Input_Quantity__c = 3;
                sw.toskid.Location__c = fuel.location5.Id;
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, null, fuel.itemList[0].Id, fuel.facility2.Id, new SKID__c(), null, null);
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
        System.assert(itList[0].Quantity__c == 3,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 97,itList[0].From_SKID__r);
        System.assert(itList[0].To_SKID__r.Quantity__c == 103,itList[0].To_SKID__r);
    }
    private static testMethod void roundTripSuccess() {
        List<Location__c> Locations = new List<Location__c>{ new Location__c(Bin_Tracked__c=true
                                                                             //Mixed_Bins_Allowed__c=true
                                                                             ),
                                                             new Location__c(Bin_Tracked__c=true
                                                              //Mixed_Bins_Allowed__c=true
                                                             ) };
        Locations[0].Id = fuel.location3.Id;
        Locations[1].Id = fuel.location5.Id;

        update Locations;

        Bin__c Bin_Location5 = fuel.bin.clone(false);
        Bin_Location5.Location__c =  fuel.location5.Id;
        //Bin_Location5.Id = fuel.bin.Id;
        Insert Bin_Location5;

        fuel.setupInventory(false, false);

        for(skid__c sk:fuel.skids){
            if(sk.Location__c == fuel.location3.Id && sk.Item__c ==fuel.itemList[0].Id){
              sk.bin__c = fuel.bin.Id; 
            }

            if(sk.Location__c == fuel.location5.Id && sk.Item__c == fuel.itemList[0].Id){
                sk.bin__c = Bin_Location5.Id;
            }

        }  
        update fuel.skids;
        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        ext.getInventoryChangeJson();
        ext.getSkidObjJson();
        ext.getInventoryChangeHeaderFieldList();
        ext.getSkidsConfigJson();
        InventoryTransferExtV2.getItemDetails(new SKID__c(Item__c = fuel.itemList[0].Id),new List<String>(),new List<String>());
        InventoryTransferExtV2.getInvAdditionalFields(fuel.itemList[0].Id);
        InventoryTransferExtV2.getAttrOptions(fuel.itemList[0].Id);
        InventoryTransferExtV2.getLocationRecord(fuel.location3.Id);
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;

        system.debug(LoggingLevel.ERROR, JSON.serialize(swList));

        //to skid and from skid have qty 100.


        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Input_Quantity__c = 3;
                sw.toskid.Location__c = fuel.location5.Id;
                sw.toskid.bin__c = Bin_Location5.id;
            }
            if (sw.skid.Location__c == fuel.location5.Id) {
                sw.skid.Input_Quantity__c = 1;
                sw.toskid.Location__c = fuel.location3.Id;
                sw.toskid.bin__c = fuel.bin.Id;
            }
        }
        Test.startTest();
        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, null, fuel.itemList[0].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(result.success,result);

        

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[0].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2,itList);

        System.assert(itList[0].From_SKID__c != null,itList[0]);
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].Quantity__c == 3,itList[0]);
        System.assert(itList[1].Quantity__c == 1,itList[1]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 98,itList[0].From_SKID__r);  
        System.assert(itList[0].To_SKID__r.Quantity__c == 102,itList[0].To_SKID__r);
        Test.stopTest();
       
    }
    private static testMethod void attributesWithLotCorrection() {
        fuel.setupInventory(true,false);

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>{ 'Lot_Number__c' },new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Input_Quantity__c = 3;
                sw.toskid.bin__c = fuel.bin.id;
                sw.toskid.Lot_Number__c = 'LOT2';
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, new List<String>{ 'Lot_Number__c' }, fuel.itemList[0].Id, fuel.facility2.Id, new SKID__c(), null, null);
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
        System.assert(itList[0].Quantity__c == 3,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 97,itList[0].From_SKID__r);
        System.assert(itList[0].To_SKID__r.Quantity__c == 3,itList[0].To_SKID__r);
        System.assert(itList[0].To_SKID__r.Lot_Number__c == 'LOT2',itList[0].To_SKID__r);
    }

    private static testMethod void serials() {
        fuel.setupInventory(true,true);

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Input_Quantity__c = 3;
                sw.toskid.Location__c = fuel.location5.Id;
                sw.serialList = new List<Serial__c>{ sw.serialList[0], sw.serialList[1], sw.serialList[2] };
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, null, fuel.itemList[0].Id, fuel.facility2.Id, new SKID__c(), null, null);
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
        System.assert(itList[0].Quantity__c == 3,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 7,itList[0].From_SKID__r);
        System.assert(itList[0].To_SKID__r.Quantity__c == 13,itList[0].To_SKID__r);
        System.assert(itList[0].Serial_Transactions__r.size() == 3,itList[0].Serial_Transactions__r);

        for (Serial_Transaction__c st:itList[0].Serial_Transactions__r) {
            System.assert(st.Type__c == 'Transfer',st);
        }

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.setWhereClause('Id IN (\'' + itList[0].From_SKID__c + '\',\'' + itList[0].To_SKID__c + '\')');

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
    }

    private static testMethod void facilityTransfer() {
        fuel.setupInventory(true,true);

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        Test.startTest();
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Input_Quantity__c = 1;
                sw.toskid.Location__c = fuel.location.Id;
                sw.serialList = new List<Serial__c>{ sw.serialList[0] };
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, null, fuel.itemList[0].Id, fuel.facility2.Id, new SKID__c(), null, null);
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
        Integer shipmentCount = 0, receiptCount = 0;
        for (Inventory_Transaction__c it:itList) {
            if (it.Type__c == 'Transfer Shipment') {
                System.assert(it.From_SKID__c != null,it);
                System.assert(it.To_SKID__c == null,it);
                System.assert(it.From_SKID__r.Quantity__c == 9,it.From_SKID__r);
                System.assert(it.From_Facility__c != it.To_Facility__c,it);
                skidIds.add(it.From_SKID__c);
                shipmentCount++;
            } else if (it.Type__c == 'Transfer Receipt') {
                System.assert(it.From_SKID__c == null,it);
                System.assert(it.To_SKID__c != null,it);
                System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                skidIds.add(it.To_SKID__c);
                receiptCount++;
            }
            System.assert(it.Quantity__c == 1,it);
            System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
            System.assert(it.Serial_Transactions__r[0].Type__c == it.Type__c,it.Serial_Transactions__r[0]);
        }
        System.assert(shipmentCount == 1,shipmentCount);
        System.assert(receiptCount == 1,receiptCount);
        
        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.setWhereClause('Id IN :skidIds');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery,'Serials__r');
        serialQuery.addAllCustomFields();
        skidQuery.addChildRelationship(serialQuery);

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2,skids);
        Test.stopTest();
        for (SKID__c skid:skids) {
            System.assert(skid.Quantity__c == skid.Serials__r.size(),skid.Serials__r);
            for (Serial__c serial:skid.Serials__r) {
                System.assert(!serial.Allow_Reentry__c,serial);
            }
        }
    }

    /**
     * Transferring between facilities: facility from has higher conversion
     */
    private static testMethod void facilityTransferSuccess_FacilityUOMConv() {
        // setup uom conversion
        insert new UOM_Conversion_Details__c(
                Name = ((String)fuel.uomList[12].Id).substring(3, 15) + ((String)fuel.uomList[13].Id).substring(3, 15) + fuel.facility2.Facility_Identifier__c,
                UOM_1__c = fuel.uomList[12].Id,
                UOM_1_Quantity__c = 2,
                UOM_2__c = fuel.uomList[13].Id,
                UOM_2_Quantity__c = 1,
                Key_1__c = '' + fuel.uomList[12].Id + fuel.uomList[13].Id,
                Key_2__c = '' + fuel.uomList[13].Id + fuel.uomList[12].Id,
                facility_identifier__c=fuel.facility2.Facility_Identifier__c
        );

        fuel.setupInventory(true,false,true);

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[14].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[14].Id,fuel.facility2.Id,new SKID__c(),fuel.facility.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() >= 2,result.records.size());

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Packaging_UOM__c == fuel.uomList[13].Id) {
                sw.skid.Input_Quantity__c = 1;
                system.assert(sw.toskid.Facility2__c == fuel.facility.Id);
                sw.toskid.Location__c = fuel.location.Id;
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, null, fuel.itemList[14].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[14].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2,itList);

        Set<Id> skidIds = new Set<Id>();
        Integer shipmentCount = 0, receiptCount = 0;
        for (Inventory_Transaction__c it:itList) {
            if (it.Type__c == 'Transfer Shipment') {
                System.assert(it.From_Facility__c != it.To_Facility__c,it);
                system.assert(it.Packaging_UOM__c == fuel.uomList[12].Id, it.Packaging_UOM__c + ' - ' + fuel.uomList[12].Id + ' - ' + fuel.uomList[13].Id );
                shipmentCount++;
            } else if (it.Type__c == 'Transfer Receipt') {
                System.assert(it.To_SKID__c != null,it);
                System.assert(it.To_SKID__r.Quantity__c == 2,it.To_SKID__r);
                System.assert(it.To_SKID__r.Packaging_UOM__c == fuel.uomList[12].Id,it.To_SKID__r);
                skidIds.add(it.To_SKID__c);
                receiptCount++;
            }
            System.assert(it.Quantity__c == 2,it);
        }
        System.assert(shipmentCount == 1,shipmentCount);
        System.assert(receiptCount == 1,receiptCount);
    }

    private static testMethod void facilityTransfer2Failure_FacilityUOMConv() {
        // setup uom conversion
        insert new UOM_Conversion_Details__c(
                Name = ((String)fuel.uomList[12].Id).substring(3, 15) + ((String)fuel.uomList[13].Id).substring(3, 15) + fuel.facility.Facility_Identifier__c,
                UOM_1__c = fuel.uomList[12].Id,
                UOM_1_Quantity__c = 2,
                UOM_2__c = fuel.uomList[13].Id,
                UOM_2_Quantity__c = 1,
                Key_1__c = '' + fuel.uomList[12].Id + fuel.uomList[13].Id,
                Key_2__c = '' + fuel.uomList[13].Id + fuel.uomList[12].Id,
                facility_identifier__c=fuel.facility.Facility_Identifier__c
        );

        fuel.setupInventory(true,false,true);

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[14].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[14].Id,fuel.facility2.Id,new SKID__c(),fuel.facility.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() >= 2,result.records.size());

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Packaging_UOM__c == fuel.uomList[13].Id) {
                sw.skid.Input_Quantity__c = 1;
                system.assert(sw.toskid.Facility2__c == fuel.facility.Id);
                sw.toskid.Location__c = fuel.location.Id;
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, null, fuel.itemList[14].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(!result.success,result);
        System.assert(result.messages[0].get('message') == 'You can\'t transfer item from facility with higher uom conversion to a facility with lower uom conversion.', result.messages[0].get('message'));
    }

    private static testMethod void negativeQuantity() {
        fuel.setupInventory(true,false);

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>{ 'Lot_Number__c' },new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Input_Quantity__c = -3;
                sw.toskid.Lot_Number__c = 'LOT2';
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, new List<String>{ 'Lot_Number__c' }, fuel.itemList[0].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(!result.success,result);
    }

    private static testMethod void sameLocation() {
        fuel.setupInventory(true,false);

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Input_Quantity__c = 3;
                sw.toskid.Location__c = sw.skid.Location__c;
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, null, fuel.itemList[0].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(!result.success,result);
    }

    private static testMethod void binToBin() {
        fuel.setupInventory(true,false);

        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Mixed_Bins_Allowed__c = true);

        Bin__c bin = new Bin__c(Name = 'StockBin', Description__c = 'StockBin', Location__c = fuel.location3.Id);
        Bin__c bin2 = new Bin__c(Name = 'StockBin2', Description__c = 'StockBin2', Location__c = fuel.location3.Id);
        insert new List<Bin__c>{ bin, bin2 };
        
        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Location__c = :fuel.location3.Id];
        for (SKID__c skid:skids) {
            skid.Bin__c = bin.Id;
        }
        update skids;

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Input_Quantity__c = 3;
                sw.toskid.Location__c = fuel.location3.Id;
                sw.toskid.Bin__c = bin2.Id;
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, null, fuel.itemList[0].Id, fuel.facility2.Id, new SKID__c(), null, null);
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
        System.assert(itList[0].Quantity__c == 3,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 97,itList[0].From_SKID__r);
        System.assert(itList[0].To_SKID__r.Quantity__c == 3,itList[0].To_SKID__r);
    }

    private static testMethod void missingBin() {
        fuel.setupInventory(true,false);

        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true);

        Bin__c bin = new Bin__c(Name = 'StockBin', Description__c = 'StockBin', Location__c = fuel.location3.Id);
        insert new List<Bin__c>{ bin };
        
        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Location__c = :fuel.location3.Id];
        for (SKID__c skid:skids) {
            skid.Bin__c = bin.Id;
        }
        update skids;

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[0].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Input_Quantity__c = 3;
                sw.toskid.Location__c = fuel.location3.Id;
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, null, fuel.itemList[0].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(!result.success,result);
    }
    
    private static testMethod void testInvTransferBinCapacitySuccess() {
      
        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
          update new Location__c(Id = fuel.location5.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
         Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin1;
        
         Bin__c bin2 = new Bin__c(
            Name = 'Location 5 Bin1',
            Location__c = fuel.location5.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin2;
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 2,
            Quantity_Stocking_UOM__c = 2,
            Item__c = fuel.itemList[14].Id,
            Item__r = fuel.itemList[14],
            Type__c = 'Location',
            bin__c = bin1.id,
            Company__c = fuel.company.Id,
            Packaging_UOM__c = fuel.uomList[12].Id,
            Packaging_UOM__r = fuel.uomList[12],
            Container_Item__c = fuel.itemList[12].Id ,//case container item  
            Container_Item__r = fuel.itemList[12]  
        );
        insert skid;
        Test.startTest();
        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        ext.getInventoryChangeJson();
        ext.getSkidObjJson();
        ext.getInventoryChangeHeaderFieldList();
        ext.getSkidsConfigJson();
        InventoryTransferExtV2.getItemDetails(new SKID__c(Item__c = fuel.itemList[14].Id),new List<String>(),new List<String>());
        InventoryTransferExtV2.getInvAdditionalFields(fuel.itemList[14].Id);
        InventoryTransferExtV2.getAttrOptions(fuel.itemList[14].Id);
        InventoryTransferExtV2.getLocationRecord(fuel.location3.Id);
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[14].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[14].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Input_Quantity__c = 1;
                sw.toskid.Location__c = fuel.location5.Id;
                 sw.toskid.Bin__c = bin2.Id;
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, null, fuel.itemList[14].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(result.success,result);
        Test.stopTest();
        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[14].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);

        System.assert(itList[0].From_SKID__c != null,itList[0]);
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].Quantity__c == 1,itList[0]);
        System.assert(itList[0].Packaging_UOM__c == fuel.uomList[12].Id);
        System.assert(itList[0].Stocking_UOM__c == fuel.uomList[11].Id);
        System.assert(itList[0].Quantity_Stocking_UOM__c == 2);
        System.assert(itList[0].From_SKID__r.Quantity__c == 1,itList[0].From_SKID__r);
        System.assert(itList[0].To_SKID__r.Quantity__c == 1,itList[0].To_SKID__r);
        System.assert(itList[0].To_SKID__r.Packaging_UOM__c == fuel.uomList[12].Id,itList[0].To_SKID__r);
        System.assert(itList[0].To_SKID__r.Stocking_UOM__c == fuel.uomList[11].Id,itList[0].To_SKID__r);
        System.assert(itList[0].To_SKID__r.Quantity_Stocking_UOM__c == 2,itList[0].To_SKID__r);
        
    }
    private static testMethod void testInvTransferBinCapacityFail() {
       
        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
          update new Location__c(Id = fuel.location5.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
         Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin1;
        
         Bin__c bin2 = new Bin__c(
            Name = 'Location 5 Bin1',
            Location__c = fuel.location5.Id,
            Max_Capacity__c = 1,
            Packaging_UOM__c = fuel.uomList[12].Id
        );
        insert bin2;
        
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 2,
            Quantity_Stocking_UOM__c = 4,
            Item__c = fuel.itemList[14].Id,
            Item__r = fuel.itemList[14],
            Type__c = 'Location',
            bin__c = bin1.id,
            Company__c = fuel.company.Id,
            Stocking_UOM__c = fuel.uomList[11].Id,
            Packaging_UOM__c = fuel.uomList[12].Id,
            Packaging_UOM__r = fuel.uomList[12],
            Container_Item__c = fuel.itemList[12].Id ,//case container item  
            Container_Item__r = fuel.itemList[12]  
        );
        insert skid;
        
        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        ext.getInventoryChangeJson();
        ext.getSkidObjJson();
        ext.getInventoryChangeHeaderFieldList();
        ext.getSkidsConfigJson();
        InventoryTransferExtV2.getItemDetails(new SKID__c(Item__c = fuel.itemList[14].Id),new List<String>(),new List<String>());
        InventoryTransferExtV2.getInvAdditionalFields(fuel.itemList[14].Id);
        InventoryTransferExtV2.getAttrOptions(fuel.itemList[14].Id);
        InventoryTransferExtV2.getLocationRecord(fuel.location3.Id);
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[14].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[14].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Input_Quantity__c = 2;
                sw.toskid.Location__c = fuel.location5.Id;
                 sw.toskid.Bin__c = bin2.Id;
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, null, fuel.itemList[14].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(result.success == false, result);
   }
   
    private static testMethod void testInvTransferBinCapacityLPNMatchingPartPallet() {
      
        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
        update new Location__c(Id = fuel.location5.Id, Bin_Tracked__c = true,Track_Bin_Capacity__c = true);
        //cs-2 each,pt-3 cases,pt-eaches -6 cases = 12,PT -13,EA2 - 11
         Bin__c bin1 = new Bin__c(
            Name = 'Location 3 Bin1',
            Location__c = fuel.location3.Id,
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[13].Id//2PT capacity   
        );
        insert bin1;
        
         Bin__c bin2 = new Bin__c(    
            Name = 'Location 5 bin2',
            Location__c = fuel.location5.Id,  
            Max_Capacity__c = 2,
            Packaging_UOM__c = fuel.uomList[13].Id//2PT capacity
        );
        insert bin2;
        LPN__c LPN1 = new LPN__c(
            Name = 'LPN-1'
        );
        insert LPN1;
        LPN__c LPN2 = new LPN__c(
            Name = 'LPN-2'
        );
        insert LPN2;
        //part pallet skid
        SKID__c skid = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 1,
            Quantity_Stocking_UOM__c = 2,
            Item__c = fuel.itemList[14].Id,
            Item__r = fuel.itemList[14],
            Type__c = 'Location',
            Bin__c = bin1.id,
            Company__c = fuel.company.Id,
            Stocking_UOM__c = fuel.uomList[11].Id,
            Stocking_UOM__r = fuel.uomList[11],
            Packaging_UOM__c = fuel.uomList[12].Id,
            Packaging_UOM__r = fuel.uomList[12],
            License_Plate_Number__c = LPN1.id,
            Container_Item__c = fuel.itemList[13].Id ,
            Container_Item__r = fuel.itemList[13]                        
        );
        insert skid;
        //pallet skid
        SKID__c skid2 = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 1,
            Quantity_Stocking_UOM__c =6,
            Item__c = fuel.itemList[14].Id,
            Item__r = fuel.itemList[14],
            Type__c = 'Location',   
            Bin__c = bin1.id,
            Company__c = fuel.company.Id,
            Stocking_UOM__c  = fuel.uomList[11].Id,
            Packaging_UOM__c = fuel.uomList[13].Id,
            Packaging_UOM__r = fuel.uomList[13],
            License_Plate_Number__c = LPN2.id,
            Container_Item__c = fuel.itemList[13].Id ,
            Container_Item__r = fuel.itemList[13]                        
        );
        insert skid2;
        //case skid
        SKID__c skid3 = new SKID__c(
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location5.Id,
            Quantity__c = 1,
            Quantity_Stocking_UOM__c = 2,
            Item__r = fuel.itemList[14],
            Item__c = fuel.itemList[14].Id,
            Type__c = 'Location',
            bin__c = bin2.id,
            Company__c = fuel.company.Id,
            Stocking_UOM__c = fuel.uomList[11].Id,
            Packaging_UOM__c = fuel.uomList[12].Id,
            Packaging_UOM__r = fuel.uomList[12],
            Container_Item__c = fuel.itemList[12].Id ,//case container item  
            Container_Item__r = fuel.itemList[12]  
        );
        insert skid3;
        
        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        ext.getInventoryChangeJson();
        ext.getSkidObjJson();
        ext.getInventoryChangeHeaderFieldList();
        ext.getSkidsConfigJson();
        InventoryTransferExtV2.getItemDetails(new SKID__c(Item__c = fuel.itemList[14].Id),new List<String>(),new List<String>());
        InventoryTransferExtV2.getInvAdditionalFields(fuel.itemList[14].Id);
        InventoryTransferExtV2.getAttrOptions(fuel.itemList[14].Id);
        InventoryTransferExtV2.getLocationRecord(fuel.location3.Id);

        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[14].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location5.Id;
        Test.startTest();
        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[14].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        
        System.assert(result.success,result);
        

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location5.Id) {
                sw.skid.Input_Quantity__c = 1;
                sw.toskid.Location__c = fuel.location3.Id;
                sw.toskid.Bin__c = bin1.Id;
                sw.toskid.Packaging_UOM__c = fuel.uomList[13].Id;
                sw.toskid.License_Plate_Number__c = LPN1.id;
                
            }
        }
        system.debug(logginglevel.info,swList);
        
        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, new List<String>{ 'Packaging_UOM__c' }, fuel.itemList[14].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('Item__c = \'' + fuel.itemList[14].Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);

        Test.stopTest();
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].Quantity__c == 1,itList[0]);
        System.assert(itList[0].Packaging_UOM__c == fuel.uomList[12].Id);
        System.assert(itList[0].Stocking_UOM__c == fuel.uomList[11].Id);
        System.assert(itList[0].Quantity_Stocking_UOM__c == 2);  
        System.assert(itList[0].To_SKID__r.Quantity__c == 2,itList[0].To_SKID__r);
        System.assert(itList[0].To_SKID__r.Packaging_UOM__c == fuel.uomList[12].Id,itList[0].To_SKID__r);
        System.assert(itList[0].To_SKID__r.Stocking_UOM__c == fuel.uomList[11].Id,itList[0].To_SKID__r);
        System.assert(itList[0].To_SKID__r.Quantity_Stocking_UOM__c == 4,itList[0].To_SKID__r);  
        
    }

    private static testMethod void rentalExchange() {
        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id, Rental__c = true, Used__c = true, Lot_Number__c = true, Expiration_Date__c = true);

        Sales_Order__c so = fuel.salesOrder;
        List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>{ fuel.salesOrderLine, fuel.salesOrderLine2 };
        Sales_Order_Line__c soline = soLines[0];

        Lot__c lot = new Lot__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[0].Id,
            Name = 'lot 1',
            Expiration_Date__c = System.today() + 2
        );
        Lot__c lot2 = new Lot__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[0].Id,
            Name = 'lot 2',
            Expiration_Date__c = System.today() + 4
        );
        insert new List<Lot__c>{ lot, lot2 };

        SKID__c installSkid = new SKID__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Type__c = SkidService3.SKID_TYPE_INSTALLBASE,
            Quantity__c = 2,
            Quantity_Stocking_UOM__c = 2,
            Sales_Order_Line__c = soLine.Id,
            Customer__c = fuel.customerShipTo.Id,
            Lot__c = lot2.Id,
            Lot_Number__c = lot2.Name,
            Rental__c = true,
            Expiration_Date__c = System.today() + 4,
            Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Container_Item__c = fuel.itemList[0].Id
        );
        SKID__c locSkid = new SKID__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Quantity__c = 5,
            Quantity_Stocking_UOM__c = 5,
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            bin__c = fuel.bin.Id,
            Lot__c = lot.Id,
            Lot_Number__c = lot.Name,
            Rental__c = true,
            Expiration_Date__c = System.today() + 365,
            Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Container_Item__c = fuel.itemList[0].Id
        );
        insert new List<SKID__c>{ installSkid, locSkid };

        List<Serial__c> serials = new List<Serial__c>();
        for (Integer i=0;i<2;i++) {
            serials.add(new Serial__c(
                Company__c = fuel.company.Id,
                Item__c = installSkid.Item__c,
                SKID__c = installSkid.Id,
                Name = 'IB Serial ' + i,
                Unique_Key__c = fuel.company.Id + '-' + installSkid.Item__c + '- IB SERIAL ' + i
            ));
        }
        for (Integer i=0;i<5;i++) {
            serials.add(new Serial__c(
                Company__c = fuel.company.Id,
                Item__c = locSkid.Item__c,
                SKID__c = locSkid.Id,
                Name = locSkid.Id + ' SERIAL' + i,
                Unique_Key__c = fuel.company.Id + '-' + locSkid.Item__c + '-' + locSkid.Id + ' SERIAL' + i
            ));
        }
        insert serials;

        installSkid.Type__c = locSkid.Type__c;
        installSkid.Quantity__c = 1;
        installSkid.Facility2__c = locSkid.Facility2__c;
        installSkid.Location__c = locSkid.Location__c;
        installSkid.bin__c = locSkid.bin__c;
        installSkid.Lot__c = locSkid.Lot__c;
        installSkid.Lot_Number__c = locSkid.Lot_Number__c;
        installSkid.Expiration_Date__c = locSkid.Expiration_Date__c;

        locSkid.Type__c = SkidService3.SKID_TYPE_INSTALLBASE;
        locSkid.Quantity__c = 1;
        locSkid.Sales_Order_Line__c = installSkid.Sales_Order_Line__c;
        locSkid.Customer__c = installSkid.Customer__c;
        locSkid.Lot__c = lot2.Id;
        locSkid.Lot_Number__c = 'lot 2';
        locSkid.Expiration_Date__c = System.today() + 4;

        installSkid.Sales_Order_Line__c = null;
        installSkid.Customer__c = null;
        locSkid.Facility2__c = null;
        locSkid.Location__c = null;
        locSkid.bin__c = null;

        SkidService3.SerialWrapper sw1 = new SkidService3.SerialWrapper(installSkid,new List<Serial__c>{ serials[0] });
        sw1.itType = 'Rental Exchange In';
        for(serial__c serial : sw1.serialList){
           serial.allow_reentry__c = false ;  
        }
        SkidService3.SerialWrapper sw2 = new SkidService3.SerialWrapper(locSkid,new list<Serial__c>{ serials[6] });
        sw2.itType = 'Rental Exchange Out';

        Test.startTest();

        InventoryChangeService.transfer(new List<SkidService3.SerialWrapper>{ sw1, sw2 },null,new Map<String,String>{ 'ICType' => 'Rental Exchange' });

        Test.stopTest();

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.setWhereClause('Sales_Order_Line__c = \'' + soLine.Id + '\' AND Type__c = \'Rental Exchange Out\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery,'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList.size());

        itQuery.setWhereClause('Inventory_Change__c = \'' + itList[0].Inventory_Change__c + '\' AND Id NOT IN :itList');

        itList.addAll((List<Inventory_Transaction__c>)Database.query(itQuery.getQuery()));
        System.assert(itList.size() == 2,itList.size());

        Boolean foundRentalExchangeIn = false;
        Boolean foundRentalExchangeOut = false;
        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Quantity__c == 1,it.Quantity__c);
            
            if (it.Type__c == 'Rental Exchange Out') {
                System.assert(it.From_SKID__c == locSkid.Id,it);
                System.assert(it.To_SKID__c == installSkid.Id,it);
                System.assert(it.From_Lot__r.Name == lot.Name,it);
                System.assert(it.Lot__r.Name == lot2.Name,it);
                foundRentalExchangeOut = true;
            } else if (it.Type__c == 'Rental Exchange In') {
                System.assert(it.From_SKID__c == installSkid.Id,it);
                System.assert(it.To_SKID__c == locSkid.Id,it);
                System.assert(it.From_Lot__r.Name == lot2.Name,it);
                System.assert(it.Lot__r.Name == lot.Name,it);
                foundRentalExchangeIn = true;
            }

            System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
            
            for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                if (it.Type__c == 'Rental Exchange In') {
                    System.assert(st.Type__c == it.Type__c,st);
                    System.assert(st.Serial__c == serials[0].Id,st);
                } else if (it.Type__c == 'Rental Exchange Out') {
                    System.assert(st.Type__c == it.Type__c,st);
                    System.assert(st.Serial__c == serials[6].Id,st);
                }
            }
        }
        System.assert(foundRentalExchangeOut && foundRentalExchangeIn);

        Set<Id> serialIds = new Set<Id>();
        for (SKID__c skid:[SELECT Id,Quantity__c,(SELECT Id FROM Serials__r) FROM SKID__c WHERE Id = :installSkid.Id OR Id = :locSkid.Id]) {
            if (skid.Id == installSkid.Id) {
                System.assert(skid.Quantity__c == 2,skid);
                System.assert(skid.Serials__r.size() == 2,skid.Serials__r);
            } else if (skid.Id == locSkid.Id) {
                System.assert(skid.Quantity__c == 5,skid);
                System.assert(skid.Serials__r.size() == 5,skid.Serials__r);
            }

            for (Serial__c serial:skid.Serials__r) {
                serialIds.add(serial.Id);
            }
        }

        for (Serial__c serial:serials) {
            System.assert(serialIds.contains(serial.Id));
        }
    }

    private static testMethod void rentalExchangeSameAttributes() {
        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id, Rental__c = true, Used__c = true, Lot_Number__c = true, Expiration_Date__c = true);

        Sales_Order__c so = fuel.salesOrder;
        List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>{ fuel.salesOrderLine, fuel.salesOrderLine2 };
        Sales_Order_Line__c soline = soLines[0];

        Lot__c lot = new Lot__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[0].Id,
            Name = 'lot 1',
            Expiration_Date__c = System.today() + 2
        );
        insert lot;

        SKID__c installSkid = new SKID__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Type__c = SkidService3.SKID_TYPE_INSTALLBASE,
            Quantity__c = 2,
            Quantity_Stocking_UOM__c = 2,
            Sales_Order_Line__c = soLine.Id,
            Customer__c = fuel.customerShipTo.Id,
            Lot__c = lot.Id,
            Lot_Number__c = lot.Name,
            Rental__c = true,
            Expiration_Date__c = System.today() + 4,
            Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Container_Item__c = fuel.itemList[0].Id
        );
        SKID__c locSkid = new SKID__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[0].Id,
            Item__r = fuel.itemList[0],
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Quantity__c = 5,
            Quantity_Stocking_UOM__c = 5,
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            bin__c = fuel.bin.Id,  
            Lot__c = lot.Id,
            Lot_Number__c = lot.Name,
            Rental__c = true,
            Expiration_Date__c = System.today() + 4,
            Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Container_Item__c = fuel.itemList[0].Id
        );
        insert new List<SKID__c>{ installSkid, locSkid };

        List<Serial__c> serials = new List<Serial__c>();
        for (Integer i=0;i<2;i++) {
            serials.add(new Serial__c(
                Company__c = fuel.company.Id,
                Item__c = installSkid.Item__c,
                SKID__c = installSkid.Id,
                Name = 'IB Serial ' + i,
                Unique_Key__c = fuel.company.Id + '-' + installSkid.Item__c + '- IB SERIAL ' + i
            ));
        }
        for (Integer i=0;i<5;i++) {
            serials.add(new Serial__c(
                Company__c = fuel.company.Id,
                Item__c = locSkid.Item__c,
                SKID__c = locSkid.Id,
                Name = locSkid.Id + ' SERIAL' + i,
                Unique_Key__c = fuel.company.Id + '-' + locSkid.Item__c + '-' + locSkid.Id + ' SERIAL' + i
            ));
        }
        insert serials;

        installSkid.Type__c = locSkid.Type__c;
        installSkid.Quantity__c = 1;
        installSkid.Facility2__c = locSkid.Facility2__c;
        installSkid.Location__c = locSkid.Location__c;
        installSkid.bin__c = locSkid.bin__c;

        locSkid.Type__c = SkidService3.SKID_TYPE_INSTALLBASE;
        locSkid.Quantity__c = 1;
        locSkid.Sales_Order_Line__c = installSkid.Sales_Order_Line__c;
        locSkid.Customer__c = installSkid.Customer__c;

        installSkid.Sales_Order_Line__c = null;
        installSkid.Customer__c = null;
        locSkid.Facility2__c = null;
        locSkid.Location__c = null;
        locSkid.bin__c = null;

        SkidService3.SerialWrapper sw1 = new SkidService3.SerialWrapper(installSkid,new List<Serial__c>{ serials[0] });
        sw1.itType = 'Rental Exchange In';

        SkidService3.SerialWrapper sw2 = new SkidService3.SerialWrapper(locSkid,new list<Serial__c>{ serials[6] });
        sw2.itType = 'Rental Exchange Out';

        Test.startTest();

        InventoryChangeService.transfer(new List<SkidService3.SerialWrapper>{ sw1, sw2 },null,new Map<String,String>{ 'ICType' => 'Rental Exchange' });

        Test.stopTest();

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.setWhereClause('Sales_Order_Line__c = \'' + soLine.Id + '\' AND Type__c = \'Rental Exchange Out\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery,'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList.size());

        itQuery.setWhereClause('Inventory_Change__c = \'' + itList[0].Inventory_Change__c + '\' AND Id NOT IN :itList');

        itList.addAll((List<Inventory_Transaction__c>)Database.query(itQuery.getQuery()));
        System.assert(itList.size() == 2,itList.size());

        Boolean foundRentalExchangeIn = false;
        Boolean foundRentalExchangeOut = false;
        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Quantity__c == 1,it.Quantity__c);
            
            if (it.Type__c == 'Rental Exchange Out') {
                System.assert(it.From_SKID__c == locSkid.Id,it);
                System.assert(it.To_SKID__c == installSkid.Id,it);
                foundRentalExchangeOut = true;
            } else if (it.Type__c == 'Rental Exchange In') {
                System.assert(it.From_SKID__c == installSkid.Id,it);
                System.assert(it.To_SKID__c == locSkid.Id,it);
                foundRentalExchangeIn = true;
            }

            System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
            
            for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                if (it.Type__c == 'Rental Exchange In') {
                    System.assert(st.Type__c == it.Type__c,st);
                    System.assert(st.Serial__c == serials[0].Id,st);
                } else if (it.Type__c == 'Rental Exchange Out') {
                    System.assert(st.Type__c == it.Type__c,st);
                    System.assert(st.Serial__c == serials[6].Id,st);
                }
            }
        }
        System.assert(foundRentalExchangeOut && foundRentalExchangeIn);

        Set<Id> serialIds = new Set<Id>();
        for (SKID__c skid:[SELECT Id,Quantity__c,(SELECT Id FROM Serials__r) FROM SKID__c WHERE Id = :installSkid.Id OR Id = :locSkid.Id]) {
            if (skid.Id == installSkid.Id) {
                System.assert(skid.Quantity__c == 2,skid);
                System.assert(skid.Serials__r.size() == 2,skid.Serials__r);
            } else if (skid.Id == locSkid.Id) {
                System.assert(skid.Quantity__c == 5,skid);
                System.assert(skid.Serials__r.size() == 5,skid.Serials__r);
            }

            for (Serial__c serial:skid.Serials__r) {
                serialIds.add(serial.Id);
            }
        }

        for (Serial__c serial:serials) {
            System.assert(serialIds.contains(serial.Id));
        }
    }  
    
    private static testMethod void testPartPalletize() {
        fuel.setupInventory(true,false,true);

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[14].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[14].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 5,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id && sw.skid.Container_Item__c == fuel.itemList[12].Id) { //Case skid
                sw.skid.Input_Quantity__c = 2;
                sw.toSkid.Location__c = sw.skid.Location__c;
                 sw.toSkid.bin__c = fuel.bin.Id;
                sw.toskid.Packaging_UOM__c = fuel.uomList[13].Id;
                sw.toSkid.Temporary_LPN_Holder__c = 'new_part_LPN';
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, new List<String>{ 'Packaging_UOM__c' }, fuel.itemList[14].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addField('License_Plate_Number__r.Name');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.setWhereClause('License_Plate_Number__c != null');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);

        System.assert(itList[0].From_SKID__c != null,itList[0]);
        System.assert(itList[0].To_SKID__c != null,itList[0]);
        System.assert(itList[0].Quantity__c == 2,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 98,itList[0].From_SKID__r);
        System.assert(itList[0].To_SKID__r.Quantity__c == 2,itList[0].To_SKID__r);
        System.assert(itList[0].From_SKID__r.Container_Item__c == fuel.itemList[12].Id,itList[0].From_SKID__r);//cas container
        System.assert(itList[0].To_SKID__r.Container_Item__c == fuel.itemList[13].Id,itList[0].From_SKID__r);//pallet containwr
    }
    
    
    private static testMethod void testPalletize() {
        fuel.setupInventory(true,false,true);
        for(skid__c sk:fuel.skids){
            if(sk.Location__c == fuel.location3.Id){
              sk.bin__c = fuel.bin.Id; 
            }

        }  
        update fuel.skids;
        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[14].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[14].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 5,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id && sw.skid.Container_Item__c == fuel.itemList[12].Id) { //Case skid
                sw.skid.Input_Quantity__c = 2;
                sw.toSkid.Location__c = sw.skid.Location__c;
                sw.toSkid.bin__c = fuel.bin.Id;
                sw.toskid.Packaging_UOM__c = fuel.uomList[13].Id;
                sw.toSkid.Temporary_LPN_Holder__c = 'Part LPN' + fuel.itemList[14].Name;//adding 2 cases to a part pallet and making it a full pallet
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, new List<String>{ 'Packaging_UOM__c' }, fuel.itemList[14].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addField('License_Plate_Number__r.Name');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2,itList);

        for( Inventory_Transaction__c it : itList ){
            
            if(it.Type__c == 'Transfer'){
                System.assert(it.From_SKID__c != null,it);
                System.assert(it.To_SKID__c != null,it);
                System.assert(it.Quantity__c == 2,it);
                System.assert(it.Packaging_UOM__c == fuel.uomList[12].Id,it);
                System.assert(it.From_SKID__r.Quantity__c == 98,it.From_SKID__r);
                System.assert(it.From_SKID__r.Container_Item__c == fuel.itemList[12].Id,it.From_SKID__r);//case container
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
    
    private static testMethod void testdePalletize() {
        fuel.setupInventory(true,false,true);

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[14].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[14].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 5,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id && sw.skid.Packaging_UOM__c == fuel.uomList[12].Id && sw.skid.Container_Item__c == fuel.itemList[13].Id) { //Part Pallet skid
                sw.skid.Input_Quantity__c = 1;
                sw.toSkid.Location__c = sw.skid.Location__c;
                sw.toSkid.bin__c = fuel.bin.Id;
                sw.toskid.Packaging_UOM__c = fuel.uomList[12].Id;
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, new List<String>{ 'Packaging_UOM__c' }, fuel.itemList[14].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addField('License_Plate_Number__r.Name');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);

        for( Inventory_Transaction__c it : itList ){
            
            if(it.Type__c == 'Transfer'){
                System.assert(it.From_SKID__c == null,it);
                System.assert(it.To_SKID__c != null,it);
                System.assert(it.Quantity__c == 1,it);
                System.assert(it.Packaging_UOM__c == fuel.uomList[12].Id,it);
                System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                System.assert(it.To_SKID__r.Packaging_UOM__c == fuel.uomList[12].Id,it.To_SKID__r);
                System.assert(it.To_SKID__r.Container_Item__c == fuel.itemList[12].Id,it.To_SKID__r);//case containwr
            }
            else{
                system.assert(false); // should not enter here
            }
        }
    }
   
    private static testMethod void testReplenish() {
        fuel.setupInventory(true,false,true);

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[14].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[14].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 5,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id && sw.skid.Packaging_UOM__c == fuel.uomList[13].Id) { //Pallet skid
                sw.skid.Input_Quantity__c = 2;
                sw.toSkid.Location__c = fuel.location5.Id;
                sw.toskid.Packaging_UOM__c = fuel.uomList[12].Id;
                sw.toskid.Quantity_Available__c = 3;
            }
        }

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, new List<String>{ 'Packaging_UOM__c' }, fuel.itemList[14].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(result.success,result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addField('License_Plate_Number__r.Name');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 2,itList);

        for( Inventory_Transaction__c it : itList ){
            
            if(it.Type__c == 'Transfer'){
                System.assert(it.From_SKID__c != null,it);
                System.assert(it.To_SKID__c != null,it);
                System.assert(it.Quantity__c == 2,it);
                System.assert(it.Packaging_UOM__c == fuel.uomList[12].Id,it);
                System.assert(it.From_SKID__r.Quantity__c == 1,it.From_SKID__r);
                System.assert(it.From_SKID__r.Packaging_UOM__c == fuel.uomList[12].Id ,it.From_SKID__r);//part pallet
                System.assert(it.From_SKID__r.Container_Item__c == fuel.itemList[13].Id,it.From_SKID__r);//pallet container
                System.assert(it.To_SKID__r.Quantity__c == 2,it.To_SKID__r);
                System.assert(it.To_SKID__r.Packaging_UOM__c == fuel.uomList[12].Id ,it.To_SKID__r);//cases
                System.assert(it.To_SKID__r.Container_Item__c == fuel.itemList[12].Id,it.To_SKID__r);//case containwr
            }
            else if(it.Type__c == 'Break Package'){
                System.assert(it.From_SKID__c == null,it);
                System.assert(it.To_SKID__c != null,it);
                System.assert(it.Quantity__c == 3,it);
                System.assert(it.Packaging_UOM__c == fuel.uomList[12].Id,it);
                System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                System.assert(it.To_SKID__r.Packaging_UOM__c == fuel.uomList[12].Id ,it.To_SKID__r);//part pallet
                System.assert(it.To_SKID__r.Container_Item__c == fuel.itemList[13].Id,it.To_SKID__r);//pallet containwr
            }
            else{
                system.assert(false); // should not enter here
            }
        }
    }
    
    private static testMethod void testErrors() {
        fuel.setupInventory(true,false,true);

        InventoryTransferExtV2 ext = new InventoryTransferExtV2(new ApexPages.StandardController(fuel.company));
        
        ext.inventoryChange.Company__c = fuel.company.Id;
        ext.inventoryChange.Item__c = fuel.itemList[14].Id;
        ext.inventoryChange.Reason_Code__c = fuel.reasonCodes.get('Transfer').Id;
        ext.inventoryChange.Facility__c = fuel.facility2.Id;
        ext.inventoryChange.Location__c = fuel.location3.Id;

        JsonResult result = InventoryTransferExtV2.getSkids(fuel.itemList[14].Id,fuel.facility2.Id,new SKID__c(),fuel.facility2.Id,null,null,null,null,new List<String>(),new List<String>());
        System.assert(result.success,result);
        System.assert(result.records.size() == 5,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id && sw.skid.Packaging_UOM__c == fuel.uomList[13].Id) { //Pallet skid
                sw.skid.Input_Quantity__c = 2;
                sw.toSkid.Location__c = fuel.location5.Id;
                sw.toskid.Packaging_UOM__c = fuel.uomList[13].Id;
            }
        }
        
        Test.startTest();

        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, new List<String>{ 'Packaging_UOM__c' }, fuel.itemList[14].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(!result.success,result);
        system.assert(result.messages[0].values()[0].contains('From and To Packaging UOM cannot be the same'));
        
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id && sw.skid.Packaging_UOM__c == fuel.uomList[13].Id) { //Pallet skid
                sw.skid.Input_Quantity__c = 1;
                sw.toSkid.Location__c = null;
                sw.toskid.Packaging_UOM__c = null;
            }
        }
        
        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, new List<String>{ 'Packaging_UOM__c' }, fuel.itemList[14].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(!result.success,result);
        system.assert(result.messages[0].values()[0].contains('To location is not valid'),result.messages[0].values()[0]);
        
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id && sw.skid.Packaging_UOM__c == fuel.uomList[13].Id) { //Pallet skid
                sw.skid.Input_Quantity__c = 1;
                sw.toSkid.Location__c = sw.skid.Location__c;
                sw.toSkid.Bin__c = fuel.bin.Id;
                sw.toskid.Packaging_UOM__c = null;
            }
        }
        
        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, new List<String>{ 'Packaging_UOM__c' }, fuel.itemList[14].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(!result.success,result);
        //system.assert(result.messages[0].values()[0].contains('To bin has been specified for a non bin-tracked location'),result.messages[0].values()[0]);
        
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid.Location__c == fuel.location3.Id && sw.skid.Packaging_UOM__c == fuel.uomList[13].Id) { //Pallet skid
                sw.skid.Input_Quantity__c = 1;
                sw.toSkid.Location__c = sw.skid.Location__c;
                sw.toSkid.Bin__c = fuel.bin.Id;
                sw.toskid.Packaging_UOM__c = fuel.uomList[11].Id;
            }
        }
        
        result = InventoryTransferExtV2.saveAction(ext.inventoryChange, swList, new List<String>{ 'Packaging_UOM__c' }, fuel.itemList[14].Id, fuel.facility2.Id, new SKID__c(), null, null);
        System.assert(!result.success,result);
        system.assert(result.messages[0].values()[0].contains('Cannot transfer across multiple levels of packaging UOM'),result.messages[0].values()[0]);
        
        Test.stopTest();
    }
}