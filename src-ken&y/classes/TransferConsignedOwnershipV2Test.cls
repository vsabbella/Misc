@isTest
private class TransferConsignedOwnershipV2Test {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.periodList != null);
        System.assert(f.itemList != null);
        System.assert(f.location3 != null);
        System.assert(f.location5 != null);
        System.assert(f.itemAttrObj2 != null);
        System.assert(f.purchaseOrder != null);

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

        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        insert new SKID__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[0].Id,
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Packaging_UOM__c = fuel.uomList[8].id,
            Stocking_UOM__c = fuel.uomList[8].id,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Consigned_Owner__c = fuel.supplier.Id,
            Purchase_Order_Line__c = poLine.Id,
            Container_Item__c = fuel.itemList[0].Id
        );

        TransferConsignedOwnershipExtV2 ext = new TransferConsignedOwnershipExtV2(new ApexPages.StandardController(fuel.company));
        TransferConsignedOwnershipExtV2.transferOfOwner.Company__c = fuel.company.Id;
        TransferConsignedOwnershipExtV2.transferOfOwner.Facility__c = fuel.facility2.Id;
        TransferConsignedOwnershipExtV2.transferOfOwner.Location__c = fuel.location3.Id;
        TransferConsignedOwnershipExtV2.transferOfOwner.Item__c = fuel.itemList[0].Id;

        ext.getTransferOfOwnerJson();
        ext.getTransferConsignedOwnershipHeaderFieldList();
        ext.getSkidsConfigJson();
        System.assert(ext.skidsFieldList != null);
        TransferConsignedOwnershipExtV2.getItemRecord(fuel.itemList[0].Id);

        JsonResult result = TransferConsignedOwnershipExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id,null,null,0);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        swList[0].skid.Input_Quantity__c = 20;

        result = TransferConsignedOwnershipExtV2.saveAction(TransferConsignedOwnershipExtV2.transferOfOwner,swList,new List<String>());
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
        System.assert(itList[0].Quantity__c == 20,itList[0]);
        System.assert(itList[0].Consigned_Owner__c == null,itList[0]);
        System.assert(itList[0].Purchase_Order_Line__c == poLine.Id,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 80,itList[0].From_SKID__r);
        System.assert(itList[0].To_SKID__r.Quantity__c == 120,itList[0].To_SKID__r);
    }

    private static testMethod void attributes() {
        fuel.setupInventory(true,false);

        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        insert new SKID__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[0].Id,
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Packaging_UOM__c = fuel.uomList[8].id,
            Stocking_UOM__c = fuel.uomList[8].id,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Consigned_Owner__c = fuel.supplier.Id,
            Purchase_Order_Line__c = poLine.Id,
            Expiration_Date__c = System.today() + 365,
            Lot_Number__c = 'LOT1',
            Lot__c = [SELECT Id FROM Lot__c WHERE Item__c = :fuel.itemList[0].Id][0].Id,
            Container_Item__c = fuel.itemList[0].Id
        );

        TransferConsignedOwnershipExtV2 ext = new TransferConsignedOwnershipExtV2(new ApexPages.StandardController(fuel.company));
        TransferConsignedOwnershipExtV2.transferOfOwner.Company__c = fuel.company.Id;
        TransferConsignedOwnershipExtV2.transferOfOwner.Facility__c = fuel.facility2.Id;
        TransferConsignedOwnershipExtV2.transferOfOwner.Location__c = fuel.location3.Id;
        TransferConsignedOwnershipExtV2.transferOfOwner.Item__c = fuel.itemList[0].Id;

        JsonResult result = TransferConsignedOwnershipExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id,null,null,0);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        swList[0].skid.Input_Quantity__c = 20;

        result = TransferConsignedOwnershipExtV2.saveAction(TransferConsignedOwnershipExtV2.transferOfOwner,swList,new List<String>());
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
        System.assert(itList[0].Quantity__c == 20,itList[0]);
        System.assert(itList[0].Consigned_Owner__c == null,itList[0]);
        System.assert(itList[0].Purchase_Order_Line__c == poLine.Id,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 80,itList[0].From_SKID__r);
        System.assert(itList[0].To_SKID__r.Quantity__c == 120,itList[0].To_SKID__r);
    }

    private static testMethod void serials() {
        fuel.setupInventory(true,true);

        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        SKID__c skid = new SKID__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[0].Id,
            Facility2__c = fuel.facility2.Id,
            Location__c = fuel.location3.Id,
            Quantity__c = 10,
            Quantity_Stocking_UOM__c = 10,
            Packaging_UOM__c = fuel.uomList[8].id,
            Stocking_UOM__c = fuel.uomList[8].id,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Consigned_Owner__c = fuel.supplier.Id,
            Purchase_Order_Line__c = poLine.Id,
            Expiration_Date__c = System.today() + 365,
            Lot_Number__c = 'LOT1',
            Lot__c = [SELECT Id FROM Lot__c WHERE Item__c = :fuel.itemList[0].Id][0].Id,
            Container_Item__c = fuel.itemList[0].Id
        );
        insert skid;

        List<Serial__c> serials = new List<Serial__c>();
        for (Integer i=0;i<10;i++) {
            serials.add(new Serial__c(
                Name = '' + skid.Id + i,
                Company__c = skid.Company__c,
                Item__c = skid.Item__c,
                SKID__c = skid.Id,
                Unique_Key2__c = '' + skid.Company__c + '-' + skid.Item__c + '-' + skid.Id + i
            ));
        }
        insert serials;

        TransferConsignedOwnershipExtV2 ext = new TransferConsignedOwnershipExtV2(new ApexPages.StandardController(fuel.company));
        TransferConsignedOwnershipExtV2.transferOfOwner.Company__c = fuel.company.Id;
        TransferConsignedOwnershipExtV2.transferOfOwner.Facility__c = fuel.facility2.Id;
        TransferConsignedOwnershipExtV2.transferOfOwner.Location__c = fuel.location3.Id;
        TransferConsignedOwnershipExtV2.transferOfOwner.Item__c = fuel.itemList[0].Id;

        JsonResult result = TransferConsignedOwnershipExtV2.getSkids(fuel.itemList[0].Id,fuel.facility2.Id,null,null,0);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);

        List<SkidService3.SerialWrapper> swList = (List<SkidService3.SerialWrapper>)result.records;
        swList[0].skid.Input_Quantity__c = 4;
        swList[0].serialList = new List<Serial__c>{ swList[0].serialList[0],swList[0].serialList[1],swList[0].serialList[2],swList[0].serialList[3] };

        result = TransferConsignedOwnershipExtV2.saveAction(TransferConsignedOwnershipExtV2.transferOfOwner,swList,new List<String>());
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
        System.assert(itList[0].Quantity__c == 4,itList[0]);
        System.assert(itList[0].Consigned_Owner__c == null,itList[0]);
        System.assert(itList[0].Purchase_Order_Line__c == poLine.Id,itList[0]);
        System.assert(itList[0].From_SKID__r.Quantity__c == 6,itList[0].From_SKID__r);
        System.assert(itList[0].To_SKID__r.Quantity__c == 14,itList[0].To_SKID__r);
        System.assert(itList[0].Serial_Transactions__r.size() == 4,itList[0].Serial_Transactions__r);

        for (Serial_Transaction__c st:itList[0].Serial_Transactions__r) {
            System.assert(st.Type__c == 'Transfer Of Ownership',st);
        }

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.setWhereClause('Id IN (\'' + itList[0].From_SKID__c + '\',\'' + itList[0].To_SKID__c + '\')');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery,'Serials__r');
        serialQuery.addAllCustomFields();
        skidQuery.addChildRelationship(serialQuery);

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2,skids);

        for (SKID__c skid1:skids) {
            System.assert(skid1.Quantity__c == skid1.Serials__r.size(),skid1.Serials__r);
            for (Serial__c serial:skid1.Serials__r) {
                System.assert(!serial.Allow_Reentry__c,serial);
            }
        }
    }
}