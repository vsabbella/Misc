@isTest
public with sharing class ShipmentManageDeliveryTestV2 {
    @testSetup
    private static void setupData() {
        DML.systemTime = system.now().addMinutes(-2);
        List<Configuration__c> configList = new List<Configuration__c>(); 
        List<sObjectType> skipTriggers = new List<sObjectType>{Package_Class__c.sObjectType,UOM__c.sObjectType,Location__c.sObjectType,GL_Type__c.sObjectType,Lot__c.sObjectType,Serial__c.sObjectType,  
        	                                  FOB_Terms__c.sObjectType,Item_Attribute__c.sObjectType,Item_Specification__c.sObjectType,Serial_Transaction__c.sObjectType,Receipt_Line__c.sObjectType,
        	                                  Receiving_Document__c.sObjectType,Purchase_Order_Line__c.sObjectType,Company__c.sObjectType,Customer__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,
        	                                  Product__c.sObjectType,Component__c.sObjectType,LPN__c.sObjectType,Payment_Term__c.sObjectType};  

         for (sObjectType s:skipTriggers) {
             configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
         }
        insert configList; 
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.itemAttrObj2 != null);
        delete configList;
        System.assert(f.packageSalesOrder != null);
    }

    public static TestFuelQuery fuel = new TestFuelQuery();
    
    
    private static testMethod void noAttributes(){
        SalesOrderReleaseService.release(fuel.packageSalesOrder.Id);

        
        SKID__c locnSkid = new SKID__c();
        locnSkid.location__c = fuel.location3.id;
        locnSkid.Facility2__c = fuel.facility2.Id;
        locnSkid.Company__c= fuel.company.id;
        locnSkid.Quantity__c = 1;
        locnSkid.Item__c= fuel.itemList[14].Id;
        locnSkid.Type__c = SKIDService.SKID_TYPE_LOCATION;
        locnSkid.Stocking_UOM__c = fuel.itemList[14].Stocking_UOM__c;
        locnSkid.Packaging_UOM__c = fuel.itemList[14].Stocking_UOM__c;
        locnSkid.Container_Item__c = fuel.itemList[14].Id;
        locnSkid.Quantity_Stocking_UOM__c = 10;
        insert locnSkid;
        
        list<SObject> groupedUpdate = new List<SObject>();

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        shipment.Status__c = 'Staged';
        update shipment;

        List<Shipment_Line__c> shls = [SELECT Id, Name, Quantity_Allocated__c, Quantity_Picked__c, Quantity_Planned__c, Quantity_To_Pick__c FROM Shipment_Line__c];
        for(Shipment_Line__c shl: shls) {
            shl.Quantity_Picked__c = locnSkid.Quantity_Stocking_UOM__c;
            shl.Quantity_Shipped__c = 0;
            shl.Quantity_From_Stock__c = locnSkid.Quantity_Stocking_UOM__c;

            groupedUpdate.add(shl);
        }
        
        SOQLUtil solineQuery = new SOQLUtil('Sales_Order_Line__c');
        solineQuery.addFields(new Set<String>{'Id','Quantity_Planned__c','Quantity_Allocated__c'});
        Sales_Order_Line__c soline = Database.query(solineQuery.getQuery());
        
        soline.Quantity_Allocated__c = 10;
        soline.Quantity_Planned__c = 10;
        groupedUpdate.add(soline);
        
        SOQLUtil skidQuery = new SOQLUtil('Skid__c');
        skidQuery.addAllCustomFields();
        skidQuery.addAllCustomFields(Item__c.sObjectType, 'Item__r');
        skidQuery.addAllCustomFields(Item__c.sObjectType,'Item__r.Container_Item__r');
        skidQuery.addAllCustomFields(Package_Class__c.sObjectType, 'Packaging_UOM__r.Package_Class__r');
        skidQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
        skidQuery.addFields(new Set<String>{ 'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Level__c', 'Container_Item__r.Item_Attribute__c',
                'Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Item__r.Container_Item__r.Container_Package_Class__c', 'Item__r.Container_Item__r.Container_Package_Class__r.Level__c','Item__r.Container_Item__r.Container_Package_Class__r.Fractional_Quantities_Allowed__c',
                'Item__r.Container_Item__r.Item_Attribute__c', 'Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Packaging_UOM__r.Package_Class__c', 'Item__r.Container_Item__r.Packaging_UOM__c',
                'Packaging_UOM__r.Package_Class__r.Default_Container_Item__c', 'Packaging_UOM__r.Package_Class__r.Level__c', 'Location__r.Bin_Tracked__c', 'Location__r.Track_Bin_Capacity__c',
                'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Container_Item__r.Container__c', 'Shipment_Line__r.Shipment__c','Shipment_Line__c','Shipment_Line__r.Name',
                'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c', 'Location__r.Facility__c', 'Location__r.name', 'Item__r.Packaging_UOM__c', 'Facility2__r.Facility_Identifier__c'
        });
        Id shlId = shls[0].Id;
        skidQuery.setWhereClause('Shipment_Line__c = :shlId');
        List<Skid__c> skids = Database.query(skidQuery.getQuery());
        for ( Skid__c skid: skids ) {
            skid.Container_Item__c = fuel.itemList[14].Id;
            skid.Container_Item__r = fuel.itemList[14];
            skid.Type__c = 'Planned Pick';
            skid.Location__c = fuel.location3.Id;
            skid.Quantity__c = 10;
            skid.Packaging_UOM__c = fuel.itemList[14].Stocking_UOM__c;
            skid.Stocking_UOM__c = fuel.itemList[14].Stocking_UOM__c;
            skid.Quantity_Stocking_UOM__c = locnSkid.Quantity_Stocking_UOM__c;
            update skid;
            break;
        }
        update groupedUpdate;

        Map<Id, Company__c> mCompanies = InventoryChangeService.getCompanies(new Set<String>{fuel.company.Id});

        Inventory_Change__c inventoryChange = new Inventory_Change__c();
        inventoryChange.Company__c = fuel.company.Id;
        inventoryChange.Company__r = mCompanies.get(fuel.company.Id);
        inventoryChange.Transaction_Date__c = System.now();
        inventoryChange.Type__c = 'Sales Order Pick';
        insert inventoryChange;

        if ( !skids.isEmpty()){
            Skid__c skid = skids[0];

            Skid__c pickSkid = new Skid__c();
            pickSkid.Facility2__c = fuel.facility2.Id;
            pickSkid.Company__c= fuel.company.id;
            pickSkid.Item__c= fuel.itemList[14].Id;
            pickSkid.Item__r= fuel.itemList[14];
            pickSkid.Type__c = SKIDService.SKID_TYPE_LOCATION;
            pickSkid.Packaging_UOM__c = fuel.itemList[14].Stocking_UOM__c;
            pickSkid.Stocking_UOM__c = fuel.itemList[14].Stocking_UOM__c;
            pickSkid.Container_Item__c = fuel.itemList[14].Id;
            pickSkid.Location__c = fuel.location2.Id;
            pickSkid.Quantity__c = 10;
            pickSkid.Shipment_Line__c = shls[0].Id;
            pickSkid.Unique_Key__c = null;
            pickSkid.Quantity_Stocking_UOM__c = 10;
            insert pickSkid;

            Inventory_Transaction__c pickit = SkidService3.createInventoryTransaction(pickSkid.Item__r, inventoryChange, 'Sales Order Pick', locnSkid.Quantity__c, locnSkid, pickSkid, null);
            insert pickIt;

            delete new List<Skid__c> { locnSkid};
            delete skids;
        }
        
        Test.startTest();
        
        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() == Date.today(), shipment);

        String str = ext.headerFieldListJson;
        str = ext.shipmentLineConfigJson;
        str = ext.shipmentLineFieldListJson;
        str = ext.skidFieldListJson;
        str = ext.serialFieldListJson;
        Integer i = ext.gridSize;
        ext.cancel();

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);

        List<LineWrapper> wrappers = (List<LineWrapper>)result.records;
        LineWrapper wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 1, wrapper);

        SKID__c skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity__c == 10, skid);

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        try {
            update new Shipment__c(Id = shipment.Id, Date_Shipped__c = null);
            System.assert(false);
        } catch (Exception e) { }

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Container_Item__c', 'From_Facility__c', 'From_Location__c', 'From_Packaging_UOM__c',
            'From_SKID__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c', 'Sales_Order_Line__r.Quantity_Fulfilled__c', 'Sales_Order_Line__r.Quantity_Shipped__c',
            'Sales_Order_Line__r.Sales_Order__c', 'Sales_Order_Line__r.Sales_Order__r.Status__c', 'Sales_Order_Line__r.Status__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c',
            'Shipment_Line__r.Item__c', 'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_Shipped__c',
            'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Date_Shipped__c', 'Shipment_Line__r.Shipment__r.Locked__c',
            'Shipment_Line__r.Shipment__r.Status__c', 'Shipment_Line__r.Shipment__r.Transaction_Date__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c',
            'To_SKID__r.Stocking_UOM__c', 'To_SKID__r.Type__c'
        });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Sales Order Shipment\'');

        Inventory_Transaction__c it = Database.query(itQuery.getQuery());
        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Shipment_Line__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.From_Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
//        System.assert(it.To_Facility__c == null, it);
        System.assert(it.To_Location__c == null, it);
        System.assert(it.From_SKID__c == null, it);
        System.assert(it.To_SKID__c == null, it);

        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == true, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c != null, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Transaction_Date__c != null, it.Shipment_Line__r.Shipment__r);

        System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Shipped__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Fulfilled__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_CLOSED, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderService.SO_STATUS_CLOSED, it.Sales_Order_Line__r.Sales_Order__r);

        ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(!ext.shipMode,ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson,Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c != null,shipment);

        result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);

        wrappers = (List<LineWrapper>)result.records;
        wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 1, wrapper);

        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity__c == 10, skid);

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        Test.stopTest();

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Sales Order Undo Shipment\'');

        it = Database.query(itQuery.getQuery());
        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Shipment_Line__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == null, it);
        System.assert(it.From_Location__c == null, it);
        System.assert(it.From_Packaging_UOM__c == null, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
        System.assert(it.To_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.From_SKID__c == null, it);

        System.assert(it.To_SKID__c != null, it);
        SKID__c toSkid = it.To_SKID__r;
        System.assert(toSkid.Company__c == it.Company__c, toSkid);
        System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, toSkid);
        System.assert(toSkid.Quantity__c == 10, toSkid);
        System.assert(toSkid.Quantity_Stocking_UOM__c == toSkid.Quantity__c, toSkid);
        System.assert(toSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
        System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
        System.assert(toSkid.Item__c == it.Item__c, toSkid);
        System.assert(toSkid.Facility2__c == it.Shipment_Line__r.Facility__c, toSkid);
        System.assert(toSkid.Location__c == it.Shipment_Line__r.Location__c, toSkid);
        System.assert(toSkid.Container_Item__c == toSkid.Item__c, toSkid);
        System.assert(toSkid.Shipment_Line__c == it.Shipment_Line__c, toSkid);

        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == false, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c == null, it.Shipment_Line__r.Shipment__r);

        System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Shipped__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Fulfilled__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_OPEN, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderService.SO_STATUS_OPEN, it.Sales_Order_Line__r.Sales_Order__r);
        
        SOQLUtil fulfillmentQuery = new SOQLUtil('Fulfillment__c');
        fulfillmentQuery.addFields(new Set<String>{ 'Id', 'Invoice_Ready__c' });

        List<Fulfillment__c> fulfillments = Database.query(fulfillmentQuery.getQuery());
        System.assert(fulfillments.size() == 2, fulfillments);
        for (Fulfillment__c fulfillment:fulfillments) {
            System.assert(!fulfillment.Invoice_Ready__c, fulfillment);
        }
    }

    private static testMethod void attributes() {
        fuel.setupInventory(true);

        Sales_Order__c so = fuel.packageSalesOrder;
        new SalesOrderService().plan(so.Id);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        LineWrapper wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        SKID__c skid = wrapper.serialWrappers[0].skid;
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        
        
        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        skid = wrapper.serialWrappers[0].skid;
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        Test.startTest();
        ShipmentInventoryService.pick(wrappers);

        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() == Date.today(), shipment);

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);

        wrappers = (List<LineWrapper>)result.records;
        wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 1, wrapper);

        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity__c == 10, skid);

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Container_Item__c', 'From_Facility__c', 'From_Location__c', 'From_Packaging_UOM__c',
            'From_SKID__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c', 'Sales_Order_Line__r.Quantity_Fulfilled__c', 'Sales_Order_Line__r.Quantity_Shipped__c',
            'Sales_Order_Line__r.Sales_Order__c', 'Sales_Order_Line__r.Sales_Order__r.Status__c', 'Sales_Order_Line__r.Status__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c',
            'Shipment_Line__r.Item__c', 'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_Shipped__c',
            'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Date_Shipped__c', 'Shipment_Line__r.Shipment__r.Locked__c',
            'Shipment_Line__r.Shipment__r.Status__c', 'Shipment_Line__r.Shipment__r.Transaction_Date__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c',
            'To_SKID__r.Stocking_UOM__c', 'To_SKID__r.Type__c'
        });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Sales Order Shipment\'');

        Inventory_Transaction__c it = Database.query(itQuery.getQuery());
        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Shipment_Line__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.From_Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
//        System.assert(it.To_Facility__c == null, it);
        System.assert(it.To_Location__c == null, it);
        System.assert(it.From_SKID__c == null, it);
        System.assert(it.To_SKID__c == null, it);

        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == true, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c != null, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Transaction_Date__c != null, it.Shipment_Line__r.Shipment__r);

        System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Shipped__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Fulfilled__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_CLOSED, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderService.SO_STATUS_CLOSED, it.Sales_Order_Line__r.Sales_Order__r);

        ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(!ext.shipMode,ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson,Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c != null,shipment);

        result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);

        wrappers = (List<LineWrapper>)result.records;
        wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 1, wrapper);

        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity__c == 10, skid);

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Sales Order Undo Shipment\'');

        it = Database.query(itQuery.getQuery());
        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Shipment_Line__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == null, it);
        System.assert(it.From_Location__c == null, it);
        System.assert(it.From_Packaging_UOM__c == null, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
        System.assert(it.To_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.From_SKID__c == null, it);

        System.assert(it.To_SKID__c != null, it);
        SKID__c toSkid = it.To_SKID__r;
        System.assert(toSkid.Company__c == it.Company__c, toSkid);
        System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, toSkid);
        System.assert(toSkid.Quantity__c == 10, toSkid);
        System.assert(toSkid.Quantity_Stocking_UOM__c == toSkid.Quantity__c, toSkid);
        System.assert(toSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
        System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
        System.assert(toSkid.Item__c == it.Item__c, toSkid);
        System.assert(toSkid.Facility2__c == it.Shipment_Line__r.Facility__c, toSkid);
        System.assert(toSkid.Location__c == it.Shipment_Line__r.Location__c, toSkid);
        System.assert(toSkid.Container_Item__c == toSkid.Item__c, toSkid);
        System.assert(toSkid.Shipment_Line__c == it.Shipment_Line__c, toSkid);

        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == false, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c == null, it.Shipment_Line__r.Shipment__r);

        System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Shipped__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Fulfilled__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_OPEN, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderService.SO_STATUS_OPEN, it.Sales_Order_Line__r.Sales_Order__r);
        
        SOQLUtil fulfillmentQuery = new SOQLUtil('Fulfillment__c');
        fulfillmentQuery.addFields(new Set<String>{ 'Id', 'Invoice_Ready__c' });
        Test.stopTest();
        List<Fulfillment__c> fulfillments = Database.query(fulfillmentQuery.getQuery());
        System.assert(fulfillments.size() == 2, fulfillments);
        for (Fulfillment__c fulfillment:fulfillments) {
            System.assert(!fulfillment.Invoice_Ready__c, fulfillment);
        }
    }

    private static testMethod void serials() {
        fuel.setupInventory(true, true);

        Sales_Order__c so = fuel.packageSalesOrder;
        new SalesOrderService().plan(so.Id);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        LineWrapper wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        SKID__c skid = wrapper.serialWrappers[0].skid;
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
         
        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        skid = wrapper.serialWrappers[0].skid;
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        List<Serial__c> serials = wrapper.serialWrappers[0].serialList;
        for (Integer i = 0; i < serials.size(); i++) serials[i].Temporary_Value_Holder__c = 'Pick';
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        Test.startTest();
        ShipmentInventoryService.pick(wrappers);

        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() == Date.today(), shipment);

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);

        wrappers = (List<LineWrapper>)result.records;
        wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 1, wrapper);

        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity__c == 10, skid);

        serials = wrapper.serialWrappers[0].serialList;
        System.assert(serials.size() == 10, serials);

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Container_Item__c', 'From_Facility__c', 'From_Location__c', 'From_Packaging_UOM__c',
            'From_SKID__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c', 'Sales_Order_Line__r.Quantity_Fulfilled__c', 'Sales_Order_Line__r.Quantity_Shipped__c',
            'Sales_Order_Line__r.Sales_Order__c', 'Sales_Order_Line__r.Sales_Order__r.Status__c', 'Sales_Order_Line__r.Status__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c',
            'Shipment_Line__r.Item__c', 'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_Shipped__c',
            'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Date_Shipped__c', 'Shipment_Line__r.Shipment__r.Locked__c',
            'Shipment_Line__r.Shipment__r.Status__c', 'Shipment_Line__r.Shipment__r.Transaction_Date__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c',
            'To_SKID__r.Stocking_UOM__c', 'To_SKID__r.Type__c'
        });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Sales Order Shipment\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery, 'Serial_Transactions__r');
        stQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Facility__c', 'Item__c', 'Serial__c', 'Serial_Parent__c', 'Type__c',
            
            'Serial__r.Allocated_SKID__c', 'Serial__r.Allow_Reentry__c', 'Serial__r.Company__c', 'Serial__r.Item__c', 'Serial__r.SKID__c' });
        itQuery.addChildRelationship(stQuery);

        Inventory_Transaction__c it = Database.query(itQuery.getQuery());
        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Shipment_Line__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.From_Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
//        System.assert(it.To_Facility__c == null, it);
        System.assert(it.To_Location__c == null, it);
        System.assert(it.From_SKID__c == null, it);
        System.assert(it.To_SKID__c == null, it);

        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == true, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c != null, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Transaction_Date__c != null, it.Shipment_Line__r.Shipment__r);

        System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Shipped__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Fulfilled__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_CLOSED, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderService.SO_STATUS_CLOSED, it.Sales_Order_Line__r.Sales_Order__r);

        System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r.size());
        for (Serial_Transaction__c st:it.Serial_Transactions__r) {
            System.assert(st.Company__c == it.Company__c, st);
            System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
            System.assert(st.Item__c == it.Item__c, st);
            System.assert(st.Serial_Parent__c == null, st);
            System.assert(st.Type__c == 'Shipment', st);

            System.assert(st.Serial__c != null, st);
            System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
            System.assert(st.Serial__r.Allow_Reentry__c == true, st.Serial__r);
            System.assert(st.Serial__r.Company__c == st.Company__c, st.Serial__r);
            System.assert(st.Serial__r.Item__c == st.Item__c, st.Serial__r);
            System.assert(st.Serial__r.SKID__c == null, st.Serial__r);
        }

        ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(!ext.shipMode,ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson,Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c != null,shipment);

        result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);

        wrappers = (List<LineWrapper>)result.records;
        wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 1, wrapper);

        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity__c == 10, skid);

        serials = wrapper.serialWrappers[0].serialList;
        System.assert(serials.size() == 10, serials);

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        Test.stopTest();

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Sales Order Undo Shipment\'');

        it = Database.query(itQuery.getQuery());
        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Shipment_Line__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == null, it);
        System.assert(it.From_Location__c == null, it);
        System.assert(it.From_Packaging_UOM__c == null, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
        System.assert(it.To_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.From_SKID__c == null, it);

        System.assert(it.To_SKID__c != null, it);
        SKID__c toSkid = it.To_SKID__r;
        System.assert(toSkid.Company__c == it.Company__c, toSkid);
        System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, toSkid);
        System.assert(toSkid.Quantity__c == 10, toSkid);
        System.assert(toSkid.Quantity_Stocking_UOM__c == toSkid.Quantity__c, toSkid);
        System.assert(toSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
        System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
        System.assert(toSkid.Item__c == it.Item__c, toSkid);
        System.assert(toSkid.Facility2__c == it.Shipment_Line__r.Facility__c, toSkid);
        System.assert(toSkid.Location__c == it.Shipment_Line__r.Location__c, toSkid);
        System.assert(toSkid.Container_Item__c == toSkid.Item__c, toSkid);
        System.assert(toSkid.Shipment_Line__c == it.Shipment_Line__c, toSkid);

        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == false, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c == null, it.Shipment_Line__r.Shipment__r);

        System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Shipped__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Fulfilled__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_OPEN, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderService.SO_STATUS_OPEN, it.Sales_Order_Line__r.Sales_Order__r);

        System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r.size());
        for (Serial_Transaction__c st:it.Serial_Transactions__r) {
            System.assert(st.Company__c == it.Company__c, st);
            System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
            System.assert(st.Item__c == it.Item__c, st);
            System.assert(st.Serial_Parent__c == null, st);
            System.assert(st.Type__c == 'Undo Shipment', st);

            System.assert(st.Serial__c != null, st);
            System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
            System.assert(st.Serial__r.Allow_Reentry__c == false, st.Serial__r);
            System.assert(st.Serial__r.Company__c == st.Company__c, st.Serial__r);
            System.assert(st.Serial__r.Item__c == st.Item__c, st.Serial__r);
            System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
        }
        
        SOQLUtil fulfillmentQuery = new SOQLUtil('Fulfillment__c');
        fulfillmentQuery.addFields(new Set<String>{ 'Id', 'Invoice_Ready__c' });

        List<Fulfillment__c> fulfillments = Database.query(fulfillmentQuery.getQuery());
        System.assert(fulfillments.size() == 2, fulfillments);
        for (Fulfillment__c fulfillment:fulfillments) {
            System.assert(!fulfillment.Invoice_Ready__c, fulfillment);
        }
    }

    private static testMethod void serialsShipmentOnly() {
        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        update new Company__c(Id = fuel.company.Id, Serial_Control__c = SkidService3.AT_SHIPMENT);

        delete c;

        fuel.setupInventory(true);

        Sales_Order__c so = fuel.packageSalesOrder;
        new SalesOrderService().plan(so.Id);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        LineWrapper wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        SKID__c skid = wrapper.serialWrappers[0].skid;
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        Test.startTest();
        
        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        skid = wrapper.serialWrappers[0].skid;
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        ShipmentInventoryService.pick(wrappers);

        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() == Date.today(), shipment);

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);

        wrappers = (List<LineWrapper>)result.records;
        wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 1, wrapper);

        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity__c == 10, skid);

        for (Integer i = 0; i < 10; i++) wrapper.serialWrappers[0].serialList.add(new Serial__c(Name = 'SERIAL' + i));

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Container_Item__c', 'From_Facility__c', 'From_Location__c', 'From_Packaging_UOM__c',
            'From_SKID__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c', 'Sales_Order_Line__r.Quantity_Fulfilled__c', 'Sales_Order_Line__r.Quantity_Shipped__c',
            'Sales_Order_Line__r.Sales_Order__c', 'Sales_Order_Line__r.Sales_Order__r.Status__c', 'Sales_Order_Line__r.Status__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c',
            'Shipment_Line__r.Item__c', 'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_Shipped__c',
            'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Date_Shipped__c', 'Shipment_Line__r.Shipment__r.Locked__c',
            'Shipment_Line__r.Shipment__r.Status__c', 'Shipment_Line__r.Shipment__r.Transaction_Date__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c',
            'To_SKID__r.Stocking_UOM__c', 'To_SKID__r.Type__c'
        });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Sales Order Shipment\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery, 'Serial_Transactions__r');
        stQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Facility__c', 'Item__c', 'Serial__c', 'Serial_Parent__c', 'Type__c',
            
            'Serial__r.Allocated_SKID__c', 'Serial__r.Allow_Reentry__c', 'Serial__r.Company__c', 'Serial__r.Item__c', 'Serial__r.SKID__c' });
        itQuery.addChildRelationship(stQuery);

        Inventory_Transaction__c it = Database.query(itQuery.getQuery());
        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Shipment_Line__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.From_Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
//        System.assert(it.To_Facility__c == null, it);
        System.assert(it.To_Location__c == null, it);
        System.assert(it.From_SKID__c == null, it);
        System.assert(it.To_SKID__c == null, it);

        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == true, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c != null, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Transaction_Date__c != null, it.Shipment_Line__r.Shipment__r);

        System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Shipped__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Fulfilled__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_CLOSED, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderService.SO_STATUS_CLOSED, it.Sales_Order_Line__r.Sales_Order__r);

        System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r.size());
        for (Serial_Transaction__c st:it.Serial_Transactions__r) {
            System.assert(st.Company__c == it.Company__c, st);
            System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
            System.assert(st.Item__c == it.Item__c, st);
            System.assert(st.Serial_Parent__c == null, st);
            System.assert(st.Type__c == 'Shipment', st);

            System.assert(st.Serial__c != null, st);
            System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
            System.assert(st.Serial__r.Allow_Reentry__c == true, st.Serial__r);
            System.assert(st.Serial__r.Company__c == st.Company__c, st.Serial__r);
            System.assert(st.Serial__r.Item__c == st.Item__c, st.Serial__r);
            System.assert(st.Serial__r.SKID__c == null, st.Serial__r);
        }

        ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(!ext.shipMode,ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson,Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c != null,shipment);

        result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);

        wrappers = (List<LineWrapper>)result.records;
        wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 1, wrapper);

        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity__c == 10, skid);

        List<Serial__c> serials = wrapper.serialWrappers[0].serialList;
        System.assert(serials.size() == 10, serials);

        /* TO DO: HITTING LIMITS
        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        Test.stopTest();

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Sales Order Undo Shipment\'');

        it = Database.query(itQuery.getQuery());
        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Shipment_Line__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == null, it);
        System.assert(it.From_Location__c == null, it);
        System.assert(it.From_Packaging_UOM__c == null, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
        System.assert(it.To_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.From_SKID__c == null, it);

        System.assert(it.To_SKID__c != null, it);
        SKID__c toSkid = it.To_SKID__r;
        System.assert(toSkid.Company__c == it.Company__c, toSkid);
        System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, toSkid);
        System.assert(toSkid.Quantity__c == 10, toSkid);
        System.assert(toSkid.Quantity_Stocking_UOM__c == toSkid.Quantity__c, toSkid);
        System.assert(toSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
        System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
        System.assert(toSkid.Item__c == it.Item__c, toSkid);
        System.assert(toSkid.Facility2__c == it.Shipment_Line__r.Facility__c, toSkid);
        System.assert(toSkid.Location__c == it.Shipment_Line__r.Location__c, toSkid);
        System.assert(toSkid.Container_Item__c == toSkid.Item__c, toSkid);
        System.assert(toSkid.Shipment_Line__c == it.Shipment_Line__c, toSkid);

        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == false, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c == null, it.Shipment_Line__r.Shipment__r);

        System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Shipped__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Fulfilled__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_OPEN, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderService.SO_STATUS_OPEN, it.Sales_Order_Line__r.Sales_Order__r);

        System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r.size());
        for (Serial_Transaction__c st:it.Serial_Transactions__r) {
            System.assert(st.Company__c == it.Company__c, st);
            System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
            System.assert(st.Item__c == it.Item__c, st);
            System.assert(st.Serial_Parent__c == null, st);
            System.assert(st.Type__c == 'Undo Shipment', st);

            System.assert(st.Serial__c != null, st);
            System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
            System.assert(st.Serial__r.Allow_Reentry__c == true, st.Serial__r);
            System.assert(st.Serial__r.Company__c == st.Company__c, st.Serial__r);
            System.assert(st.Serial__r.Item__c == st.Item__c, st.Serial__r);
            System.assert(st.Serial__r.SKID__c == null, st.Serial__r);
        }
        
        SOQLUtil fulfillmentQuery = new SOQLUtil('Fulfillment__c');
        fulfillmentQuery.addFields(new Set<String>{ 'Id', 'Invoice_Ready__c' });

        List<Fulfillment__c> fulfillments = Database.query(fulfillmentQuery.getQuery());
        System.assert(fulfillments.size() == 2, fulfillments);
        for (Fulfillment__c fulfillment:fulfillments) {
            System.assert(!fulfillment.Invoice_Ready__c, fulfillment);
        }*/
    }

    private static testMethod void installBase() {
        fuel.setupInventory(true, true);

        Sales_Order__c so = fuel.packageSalesOrder;
        new SalesOrderService().plan(so.Id);

        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        update new Item__c(Id = so.Sales_Order_Lines__r[0].Product__r.Item__c, Track_Install_Base__c = true);

        delete c;

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        LineWrapper wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        SKID__c skid = wrapper.serialWrappers[0].skid;
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        
        
        ShipmentInventoryService.plan(wrappers);
        
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        skid = wrapper.serialWrappers[0].skid;
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        List<Serial__c> serials = wrapper.serialWrappers[0].serialList;
        for (Integer i = 0; i < serials.size(); i++) serials[i].Temporary_Value_Holder__c = 'Pick';
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        Test.startTest();
        ShipmentInventoryService.pick(wrappers);

        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() == Date.today(), shipment);

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);

        wrappers = (List<LineWrapper>)result.records;
        wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 1, wrapper);

        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity__c == 10, skid);

        serials = wrapper.serialWrappers[0].serialList;
        System.assert(serials.size() == 10, serials);

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Container_Item__c', 'From_Facility__c', 'From_Location__c', 'From_Packaging_UOM__c',
            'From_SKID__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c',

            'From_SKID__r.Company__c', 'From_SKID__r.Container_Item__c', 'From_SKID__r.Customer__c', 'From_SKID__r.Facility2__c', 'From_SKID__r.Item__c',
            'From_SKID__r.Location__c', 'From_SKID__r.Packaging_UOM__c', 'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',
            'From_SKID__r.Sales_Order_Line__c', 'From_SKID__r.Shipment_Line__c', 'From_SKID__r.Stocking_UOM__c', 'From_SKID__r.Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c', 'Sales_Order_Line__r.Quantity_Fulfilled__c', 'Sales_Order_Line__r.Quantity_Shipped__c',
            'Sales_Order_Line__r.Sales_Order__c', 'Sales_Order_Line__r.Sales_Order__r.Status__c', 'Sales_Order_Line__r.Status__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c',
            'Shipment_Line__r.Item__c', 'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_Shipped__c',
            'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Customer__c', 'Shipment_Line__r.Shipment__r.Date_Shipped__c',
            'Shipment_Line__r.Shipment__r.Locked__c', 'Shipment_Line__r.Shipment__r.Status__c', 'Shipment_Line__r.Shipment__r.Transaction_Date__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Customer__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c',
            'To_SKID__r.Location__c', 'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c','To_SKID__r.Shipment_Line__c',
            'To_SKID__r.Sales_Order_Line__c','To_SKID__r.Stocking_UOM__c', 'To_SKID__r.Type__c'
        });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Sales Order Shipment\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery, 'Serial_Transactions__r');
        stQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Facility__c', 'Item__c', 'Serial__c', 'Serial_Parent__c', 'Type__c',
            
            'Serial__r.Allocated_SKID__c', 'Serial__r.Allow_Reentry__c', 'Serial__r.Company__c', 'Serial__r.Item__c', 'Serial__r.SKID__c' });
        itQuery.addChildRelationship(stQuery);

        Inventory_Transaction__c it = Database.query(itQuery.getQuery());
        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Shipment_Line__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.From_Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
        System.assert(it.To_Facility__c == null, it);
        System.assert(it.To_Location__c == null, it);
        System.assert(it.From_SKID__c == null, it);

        System.assert(it.To_SKID__c != null, it);
        SKID__c toSkid = it.To_SKID__r;
        System.assert(toSkid.Company__c == it.Company__c, toSkid);
        System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_INSTALLBASE, toSkid);
        System.assert(toSkid.Quantity__c == 10, toSkid);
        System.assert(toSkid.Quantity_Stocking_UOM__c == toSkid.Quantity__c, toSkid);
        System.assert(toSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
        System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
        System.assert(toSkid.Item__c == it.Item__c, toSkid);
        System.assert(toSkid.Facility2__c == null, toSkid);
        System.assert(toSkid.Location__c == null, toSkid);
        System.assert(toSkid.Customer__c == it.Shipment_Line__r.Shipment__r.Customer__c, toSkid);
        System.assert(toSkid.Container_Item__c == toSkid.Item__c, toSkid);
        System.assert(toSkid.Sales_Order_Line__c == it.Sales_Order_Line__c, toSkid);

        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == true, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c != null, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Transaction_Date__c != null, it.Shipment_Line__r.Shipment__r);

        System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Shipped__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Fulfilled__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_CLOSED, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderService.SO_STATUS_CLOSED, it.Sales_Order_Line__r.Sales_Order__r);

        System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r.size());
        for (Serial_Transaction__c st:it.Serial_Transactions__r) {
            System.assert(st.Company__c == it.Company__c, st);
            System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
            System.assert(st.Item__c == it.Item__c, st);
            System.assert(st.Serial_Parent__c == null, st);
            System.assert(st.Type__c == 'Shipment', st);

            System.assert(st.Serial__c != null, st);
            System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
            System.assert(st.Serial__r.Allow_Reentry__c == true, st.Serial__r);
            System.assert(st.Serial__r.Company__c == st.Company__c, st.Serial__r);
            System.assert(st.Serial__r.Item__c == st.Item__c, st.Serial__r);
            System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
        }

        ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(!ext.shipMode,ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson,Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c != null,shipment);

        result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);

        wrappers = (List<LineWrapper>)result.records;
        wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 1, wrapper);

        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity__c == 10, skid);

        serials = wrapper.serialWrappers[0].serialList;
        System.assert(serials.size() == 10, serials);

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        Test.stopTest();

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Sales Order Undo Shipment\'');

        it = Database.query(itQuery.getQuery());
        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Shipment_Line__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == null, it);
        System.assert(it.From_Location__c == null, it);
        System.assert(it.From_Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
        System.assert(it.To_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);

        System.assert(it.From_SKID__c != null, it);
        SKID__c fromSkid = it.From_SKID__r;
        System.assert(fromSkid.Company__c == it.Company__c, fromSkid);
        System.assert(fromSkid.Type__c == SkidService3.SKID_TYPE_INSTALLBASE, fromSkid);
        System.assert(fromSkid.Quantity__c == 0, fromSkid);
        System.assert(fromSkid.Quantity_Stocking_UOM__c == fromSkid.Quantity__c, fromSkid);
        System.assert(fromSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, fromSkid);
        System.assert(fromSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, fromSkid);
        System.assert(fromSkid.Item__c == it.Item__c, fromSkid);
        System.assert(fromSkid.Facility2__c == null, fromSkid);
        System.assert(fromSkid.Location__c == null, fromSkid);
        System.assert(fromSkid.Customer__c == it.Shipment_Line__r.Shipment__r.Customer__c, fromSkid);
        System.assert(fromSkid.Container_Item__c == fromSkid.Item__c, fromSkid);
        System.assert(fromSkid.Sales_Order_Line__c == it.Sales_Order_Line__c, fromSkid);

        System.assert(it.To_SKID__c != null, it);
        toSkid = it.To_SKID__r;
        System.assert(toSkid.Company__c == it.Company__c, toSkid);
        System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, toSkid);
        System.assert(toSkid.Quantity__c == 10, toSkid);
        System.assert(toSkid.Quantity_Stocking_UOM__c == toSkid.Quantity__c, toSkid);
        System.assert(toSkid.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
        System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
        System.assert(toSkid.Item__c == it.Item__c, toSkid);
        System.assert(toSkid.Facility2__c == it.Shipment_Line__r.Facility__c, toSkid);
        System.assert(toSkid.Location__c == it.Shipment_Line__r.Location__c, toSkid);
        System.assert(toSkid.Container_Item__c == toSkid.Item__c, toSkid);
        System.assert(toSkid.Shipment_Line__c == it.Shipment_Line__c, toSkid);

        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == false, it.Shipment_Line__r.Shipment__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c == null, it.Shipment_Line__r.Shipment__r);

        System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 10, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Shipped__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Fulfilled__c == 0, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_OPEN, it.Sales_Order_Line__r);
        System.assert(it.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderService.SO_STATUS_OPEN, it.Sales_Order_Line__r.Sales_Order__r);

        System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r.size());
        for (Serial_Transaction__c st:it.Serial_Transactions__r) {
            System.assert(st.Company__c == it.Company__c, st);
            System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
            System.assert(st.Item__c == it.Item__c, st);
            System.assert(st.Serial_Parent__c == null, st);
            System.assert(st.Type__c == 'Undo Shipment', st);

            System.assert(st.Serial__c != null, st);
            System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
            System.assert(st.Serial__r.Allow_Reentry__c == false, st.Serial__r);
            System.assert(st.Serial__r.Company__c == st.Company__c, st.Serial__r);
            System.assert(st.Serial__r.Item__c == st.Item__c, st.Serial__r);
            System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
        }
        
        SOQLUtil fulfillmentQuery = new SOQLUtil('Fulfillment__c');
        fulfillmentQuery.addFields(new Set<String>{ 'Id', 'Invoice_Ready__c' });

        List<Fulfillment__c> fulfillments = Database.query(fulfillmentQuery.getQuery());
        System.assert(fulfillments.size() == 2, fulfillments);
        for (Fulfillment__c fulfillment:fulfillments) {
            System.assert(!fulfillment.Invoice_Ready__c, fulfillment);
        }
    }

    private static testMethod void nonInventory() {
        Sales_Order__c so = fuel.packageSalesOrder;
        new SalesOrderService().plan(so.Id);

        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        update new Item__c(Id = so.Sales_Order_Lines__r[0].Product__r.Item__c, Item_Attribute__c = null, Source__c = 'Miscellaneous', Non_Inventory__c = true);

        delete c;

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());

        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() == Date.today(), shipment);

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);

        List<LineWrapper> wrappers = (List<LineWrapper>)result.records;
        LineWrapper wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 1, wrapper);

        SKID__c skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity__c == 10, skid);
        skid.Quantity__c = 9;

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
        shlQuery.addFields(new Set<String>{ 'Id', 'Name', 'Quantity_Shipped__c', 'Sales_Order_Line__c', 'Shipment__c',

            'Sales_Order_Line__r.Quantity_Fulfilled__c', 'Sales_Order_Line__r.Quantity_Shipped__c', 'Sales_Order_Line__r.Sales_Order__c',
            'Sales_Order_Line__r.Sales_Order__r.Status__c', 'Sales_Order_Line__r.Status__c',

            'Shipment__r.Date_Shipped__c', 'Shipment__r.Locked__c', 'Shipment__r.Status__c', 'Shipment__r.Transaction_Date__c'
        });
        shlQuery.setWhereClause('Shipment__c = \'' + shipment.Id + '\'');

        Shipment_Line__c shl = Database.query(shlQuery.getQuery());
        System.assert(shl.Quantity_Shipped__c == 9, shl);
        System.assert(shl.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED, shl.Shipment__r);
        System.assert(shl.Shipment__r.Locked__c == true, shl.Shipment__r);
        System.assert(shl.Shipment__r.Date_Shipped__c != null, shl.Shipment__r);
        System.assert(shl.Shipment__r.Transaction_Date__c != null, shl.Shipment__r);
        System.assert(shl.Sales_Order_Line__r.Quantity_Shipped__c == 9, shl.Sales_Order_Line__r);
        System.assert(shl.Sales_Order_Line__r.Quantity_Fulfilled__c == 9, shl.Sales_Order_Line__r);
        System.assert(shl.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_OPEN, shl.Sales_Order_Line__r);
        System.assert(shl.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_OPEN, shl.Sales_Order_Line__r.Sales_Order__r);

        ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(!ext.shipMode,ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson,Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c != null,shipment);

        result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);

        wrappers = (List<LineWrapper>)result.records;
        wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 1, wrapper);

        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity__c == 9, skid);

        Test.startTest();

        FulfillmentService.processedShipmentLineIds = new Set<Id>();

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        shl = Database.query(shlQuery.getQuery());
        System.assert(shl.Quantity_Shipped__c == 0, shl);
        System.assert(shl.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, shl.Shipment__r);
        System.assert(shl.Shipment__r.Locked__c == false, shl.Shipment__r);
        System.assert(shl.Shipment__r.Date_Shipped__c == null, shl.Shipment__r);
        System.assert(shl.Sales_Order_Line__r.Quantity_Shipped__c == 0, shl.Sales_Order_Line__r);
        System.assert(shl.Sales_Order_Line__r.Quantity_Fulfilled__c == 0, shl.Sales_Order_Line__r);
        System.assert(shl.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_OPEN, shl.Sales_Order_Line__r);
        System.assert(shl.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_OPEN, shl.Sales_Order_Line__r.Sales_Order__r);
        
        SOQLUtil fulfillmentQuery = new SOQLUtil('Fulfillment__c');
        fulfillmentQuery.addFields(new Set<String>{ 'Id', 'Invoice_Ready__c' });

        List<Fulfillment__c> fulfillments = Database.query(fulfillmentQuery.getQuery());
        System.assert(fulfillments.size() == 2, fulfillments);
        for (Fulfillment__c fulfillment:fulfillments) {
            System.assert(!fulfillment.Invoice_Ready__c, fulfillment);
        }
    }

    private static testMethod void rerelease() {
        fuel.setupInventory(true, false, true);

        Sales_Order__c so = fuel.packageSalesOrder;
        new SalesOrderService().plan(so.Id);

        List<Shipment_Line__c> shipmentLines = ShipmentWorkbenchExt.getShipmentLines('AND Sales_Order__c = \'' + so.Id + '\'', 'allocate');
        Shipment_Line__c shl = shipmentLines[0];
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines);
        System.assert(wrappers.size() == 1, wrappers.size());
        wrappers[0].line = shl;
        wrappers[0].header = shl.Shipment__r;
        System.assert(wrappers[0].serialWrappers.size() == 2, wrappers[0].serialWrappers.size());
        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = shl.Item__r;
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = ShipmentWorkbenchExt.getShipmentLines('AND Sales_Order__c = \'' + so.Id + '\'', 'planpick');
        shl = shipmentLines[0];
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines);
        System.assert(wrappers.size() == 3, wrappers.size());
        wrappers[0].line = shl;
        wrappers[0].header = shl.Shipment__r;
        List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers.size());
            if (wrapper.uom == 'PT') continue;
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (wrapper.uom == 'CS') sw.skid.Quantity_to_Issue__c = 2;
                else sw.skid.Quantity_to_Issue__c = 5;
                sw.skid.Item__r = shl.Item__r;
                swList.add(sw);
            }
        }
        wrappers[0].serialWrappers = swList;
        ShipmentInventoryService.plan(new List<LineWrapper>{ wrappers[0] });
        
        shipmentLines = ShipmentWorkbenchExt.getShipmentLines('AND Sales_Order__c = \'' + so.Id + '\'', 'pick');
        shl = shipmentLines[0];
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines);
        System.assert(wrappers.size() == 3, wrappers.size());
        wrappers[0].line = shl;
        wrappers[0].header = shl.Shipment__r;
        swList = new List<SkidService3.SerialWrapper>();
        for (LineWrapper wrapper:wrappers) {
            if (wrapper.uom != 'CS') System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers.size());
            else System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers.size());
            if (wrapper.uom == 'PT') continue;
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (wrapper.uom == 'CS') sw.skid.Quantity_to_Issue__c = 1;
                else sw.skid.Quantity_to_Issue__c = 4;
                sw.skid.Item__r = shl.Item__r;
                swList.add(sw);
            }
        }
        wrappers[0].serialWrappers = swList;
        Test.startTest();
        ShipmentInventoryService.pick(new List<LineWrapper>{ wrappers[0] });

        SKID__c sk = [SELECT Id FROM SKID__c WHERE Shipment_Line__c != null AND License_Plate_Number__c != null];
        sk.Mixed_Palletized__c = true;
        update sk;

        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(new Shipment__c(Id = shl.Shipment__c)));
        Shipment__c shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        wrappers = (List<LineWrapper>)ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode).records;
        System.assert(wrappers.size() == 1, wrappers.size());
        System.assert(wrappers[0].serialWrappers.size() == 3, wrappers[0].serialWrappers.size());
        for (Integer i = 0; i < wrappers[0].serialWrappers.size(); i++) {
            SKID__c skid = wrappers[0].serialWrappers[i].skid;
            if (skid.Packaging_UOM__r.Name == 'CS') {
                System.assert(skid.Quantity__c == 1, skid.Quantity__c);
                wrappers[0].serialWrappers.remove(i--);
            } else {
                System.assert(skid.Quantity__c == 4, skid.Quantity__c);
            }
        }
        JsonResult result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success == true, result);

        result = ShipmentManageDeliveryExtV2.rerelease(shipment.Id);
        System.assert(result.success == true, result);

        Test.stopTest();

        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
        shlQuery.addFields(new Set<String>{ 'Id', 'Name', 'Quantity_Allocated__c', 'Quantity_Picked__c', 'Quantity_Shipped__c', 'Quantity_To_Pick__c',
            'Shipment__r.Status__c' });
        shlQuery.setWhereClause('Sales_Order__c = \'' + so.Id + '\'');

        SOQLUtil.ChildRelationship skidQuery = new SOQLUtil.ChildRelationship(shlQuery, 'SKIDs__r');
        skidQuery.addField('Id');
        shlQuery.addChildRelationship(skidQuery);

        SOQLUtil.ChildRelationship itQuery2 = new SOQLUtil.ChildRelationship(shlQuery, 'Inventory_Transactions__r');
        itQuery2.addField('Id');
        shlQuery.addChildRelationship(itQuery2);

        shipmentLines = Database.query(shlQuery.getQuery());
        System.assert(shipmentLines.size() == 2, shipmentLines);

        for (Shipment_Line__c shipmentLine:shipmentLines) {
            if (shipmentLine.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED) {
                System.assert(shipmentLine.Quantity_Allocated__c == 0, shipmentLine);
                System.assert(shipmentLine.Quantity_To_Pick__c == 0, shipmentLine);
                System.assert(shipmentLine.Quantity_Picked__c == 0, shipmentLine);
                System.assert(shipmentLine.Quantity_Shipped__c == 4, shipmentLine);
                System.assert(shipmentLine.SKIDs__r.size() == 0, shipmentLine.SKIDs__r.size());
            } else {
                System.assert(shipmentLine.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, shipmentLine.Shipment__r);
                System.assert(shipmentLine.Quantity_Allocated__c == 1, shipmentLine);
                System.assert(shipmentLine.Quantity_To_Pick__c == 1, shipmentLine);
                System.assert(shipmentLine.Quantity_Picked__c == 4, shipmentLine);
                System.assert(shipmentLine.Quantity_Shipped__c == 0, shipmentLine);

                System.assert(shipmentLine.SKIDs__r.size() == 3, shipmentLine.SKIDs__r.size());
                System.assert(shipmentLine.Inventory_Transactions__r.size() == 3, shipmentLine.Inventory_Transactions__r.size());
            }
        }
    }

    private static testMethod void undoShipment() {
        Sales_Order__c so = fuel.packageSalesOrder;
        fuel.setupInventory(true);
        new SalesOrderService().plan(so.Id);

        List<Shipment_Line__c> shipmentLines = ShipmentWorkbenchExt.getShipmentLines('AND Sales_Order__c = \'' + so.Id + '\'', 'allocate');
        Shipment_Line__c shl = shipmentLines[0];

        Lot__c lot = new Lot__c(
            Name = 'LOT2',
            Company__c = shl.Company__c,
            Item__c = shl.Item__c,
            Expiration_Date__c = System.today() + 365
        );
        insert lot;

        insert new SKID__c(
            Company__c = shl.Company__c,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = shl.Item__r.Stocking_UOM__c,
            Item__c = shl.Item__c,
            Facility2__c = shl.Facility__c,
            Location__c = fuel.location3.Id,
            Container_Item__c = shl.Item__c,
            Lot__c = lot.Id,
            Lot_Number__c = lot.Name,
            Expiration_Date__c = lot.Expiration_Date__c
        );

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines);
        LineWrapper wrapper = wrappers[0];
        wrapper.line = shl;
        wrapper.header = shl.Shipment__r;
        for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 5;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = shl.Item__r;
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = ShipmentWorkbenchExt.getShipmentLines('AND Sales_Order__c = \'' + so.Id + '\'', 'planpick');
        shl = shipmentLines[0];
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines);
        wrapper = wrappers[0];
        wrapper.line = shl;
        wrapper.header = shl.Shipment__r;
        for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
            if (sw.skid.Lot__c == lot.Id) sw.skid.Quantity_to_Issue__c = 4;
            else sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = sw.skid.Quantity_to_Issue__c;
            sw.skid.Item__r = shl.Item__r;
        }
        
        Test.startTest();
        
        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = ShipmentWorkbenchExt.getShipmentLines('AND Sales_Order__c = \'' + so.Id + '\'', 'pick');
        shl = shipmentLines[0];
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines);
        wrapper = wrappers[0];
        wrapper.line = shl;
        wrapper.header = shl.Shipment__r;
        for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
            if (sw.skid.Lot__c == lot.Id) sw.skid.Quantity_to_Issue__c = 3;
            else sw.skid.Quantity_to_Issue__c = 5;
            sw.skid.Input_Quantity__c = sw.skid.Quantity_to_Issue__c;
            sw.skid.Item__r = shl.Item__r;
        }
        
        ShipmentInventoryService.pick(wrappers);

        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(new Shipment__c(Id = shl.Shipment__c)));
        Shipment__c shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        wrappers = (List<LineWrapper>)ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode).records;
        wrapper = wrappers[0];
        for (Integer i = 0; i < wrapper.serialWrappers.size(); i++) {
            SKID__c skid = wrapper.serialWrappers[i].skid;
            if (skid.Lot__c == lot.Id) {
                wrapper.serialWrappers.remove(i--);
                break;
            }
        }

        ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);

        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
        ShipmentWorkbenchExt.addShlFields(shlQuery, 'pick');
        shlQuery.setWhereClause('Shipment__c = \'' + shipment.Id + '\'');

        SOQLUtil.ChildRelationship skidQuery = new SOQLUtil.ChildRelationship(shlQuery, 'SKIDs__r');
        skidQuery.addFields(SkidService3.getSkidSoql(new Map<String, String>()).getFields());
        shlQuery.addChildRelationship(skidQuery);

        shipmentLines = Database.query(shlQuery.getQuery());

        ShipmentRereleaseService.undoShipment(shipmentLines);

        Test.stopTest();

        shlQuery = new SOQLUtil('Shipment_Line__c');
        shlQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Facility__c', 'Item__c', 'Location__c', 'Quantity_Allocated__c', 'Quantity_Picked__c',
            'Quantity_Shipped__c', 'Quantity_To_Pick__c', 'Sales_Order_Line__c',

            'Item__r.Stocking_UOM__c',

            'Shipment__r.Status__c' });
        shlQuery.setWhereClause('Sales_Order__c = \'' + so.Id + '\'');

        skidQuery = new SOQLUtil.ChildRelationship(shlQuery, 'SKIDs__r');
        skidQuery.addField('Id');
        shlQuery.addChildRelationship(skidQuery);

        SOQLUtil.ChildRelationship itQuery = new SOQLUtil.ChildRelationship(shlQuery, 'Inventory_Transactions__r');
        itQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Container_Item__c', 'From_Facility__c', 'From_Location__c', 'From_Packaging_UOM__c',
            'From_SKID__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c' });
        itQuery.setWhereClause('Type__c = \'Sales Order Undo Pick\'');
        shlQuery.addChildRelationship(itQuery);

        shipmentLines = Database.query(shlQuery.getQuery());
        System.assert(shipmentLines.size() == 1, shipmentLines);

        shl = shipmentLines[0];
        System.assert(shl.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED, shl.Shipment__r);
        System.assert(shl.Quantity_Allocated__c == 0, shl);
        System.assert(shl.Quantity_To_Pick__c == 0, shl);
        System.assert(shl.Quantity_Picked__c == 0, shl);
        System.assert(shl.Quantity_Shipped__c == 5, shl);
        System.assert(shl.SKIDs__r.size() == 0, shl.SKIDs__r);

        System.assert(shl.Inventory_Transactions__r.size() == 1, shl.Inventory_Transactions__r);
        Inventory_Transaction__c it = shl.Inventory_Transactions__r[0];
        System.assert(it.Company__c == shl.Company__c, it);
        System.assert(it.Item__c == shl.Item__c, it);
        System.assert(it.Quantity__c == 3, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == shl.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == shl.Item__r.Stocking_UOM__c, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Shipment_Line__c == shl.Id, it);
        System.assert(it.Sales_Order_Line__c == shl.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == shl.Facility__c, it);
        System.assert(it.From_Location__c == shl.Location__c, it);
        System.assert(it.From_Packaging_UOM__c == shl.Item__r.Stocking_UOM__c, it);
        System.assert(it.Container_Item__c == shl.Item__c, it);
        System.assert(it.To_Facility__c == shl.Facility__c, it);
        System.assert(it.To_Location__c == shl.Location__c, it);
        System.assert(it.From_SKID__c == null, it);
        System.assert(it.To_SKID__c != null, it);
    }

    /*private static testMethod void warrantyFulfillment() {
        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        fuel.setupInventory(true);

        Sales_Order__c so = fuel.packageSalesOrder;
        Sales_Order_Line__c sol = so.Sales_Order_Lines__r[0];

        Lot__c lot = new Lot__c(
            Name = 'LOT2',
            Item__c = sol.Product__r.Item__c,
            Company__c = so.Company__c,
            Expiration_Date__c = System.today() + 365
        );
        insert lot;

        insert new SKID__c(
            Company__c = so.Company__c,
            Item__c = sol.Product__r.Item__c,
            Facility2__c = fuel.location3.Facility__c,
            Location__c = fuel.location3.Id,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Expiration_Date__c = System.today() + 365,
            Lot__c = lot.Id,
            Lot_Number__c = lot.Name,
            Packaging_UOM__c = sol.Product__r.Item__r.Stocking_UOM__c,
            Stocking_UOM__c = sol.Product__r.Item__r.Stocking_UOM__c,
            Container_Item__c = sol.Product__r.Item__c
        );

        Item__c warrantyItem = new Item__c(
            Name = 'Warranty',
            Description__c = 'Warranty',
            Source__c = 'Purchased',
            Non_Shippable__c = true,
            ABC_Code__c = 'Warr-123',
            Company__c = so.Company__c,
            Active__c = true,
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Packaging_UOM__c = JSON.serialize(new List<Id>{ fuel.itemList[0].Stocking_UOM__c })
        );
        insert warrantyItem;
        
        Product__c warrantyProduct = new Product__c(
            Company__c = so.Company__c,
            Name = 'Warranty' ,
            Item__c  = warrantyItem.Id,
            Pricebook_Line_Required__c = false,
            Product_Type__c = 'Warranty'
        );
        insert warrantyProduct;
        
        Sales_Order_Line__c warrantysol = new Sales_Order_Line__c(
            Company__c = so.Company__c,
            Discount_Percent__c = 2,
            Product__c = warrantyProduct.Id,
            Quantity_Ordered__c = 1,
            Required_Date__c = System.today() + 15,
            Sales_Order__c = so.Id,
            Ship_From_Location__c = sol.Ship_From_Location__c,
            Parent_Sales_Order_Line__c = sol.Id,
            Start_Date__c = System.today(),
            End_Date__c = System.today() + 365,
            Unit_Price__c = 12.11,
            Sales_Tax__c = 14.686403,
            Memo__c = 'warrantysoline'
        );
        insert warrantysol;

        delete c;

        new SalesOrderService().plan(so.Id);

        c.Id = null;
        insert c;

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Date_Shipped__c', 'Transaction_Date__c', 'Company__r.Serial_Control__c' });
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            if ((Id)wrapper.line.get('Sales_Order_Line__c') == sol.Id) {
                for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                    if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 5;
                    else sw.skid.Input_Quantity__c = 0;
                    sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
                }
            }
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            if ((Id)wrapper.line.get('Sales_Order_Line__c') == sol.Id) {
                for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                    if (sw.skid.Location__c == fuel.location3.Id) {
                        sw.skid.Quantity_to_Issue__c = 5;
                        sw.skid.Input_Quantity__c = 5;
                    } else {
                        sw.skid.Quantity_to_Issue__c = 0;
                        sw.skid.Input_Quantity__c = 0;
                    }
                    sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
                }
            }
        }
        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        Test.startTest();
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            if ((Id)wrapper.line.get('Sales_Order_Line__c') == sol.Id) {
                for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                    if (sw.skid.Location__c == fuel.location3.Id) {
                        sw.skid.Quantity_to_Issue__c = 5;
                        sw.skid.Input_Quantity__c = 5;
                    } else {
                        sw.skid.Quantity_to_Issue__c = 0;
                        sw.skid.Input_Quantity__c = 0;
                    }
                    sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
                }
            }
        }

        //100 Queries

        ShipmentInventoryService.pick(wrappers);

        shipment = Database.query(shipmentQuery.getQuery());
        shipment.Date_Shipped__c = System.now();
        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, true);
        System.assert(result.success, result);
        wrappers = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:wrappers) {
            wrapper.header = shipment;
            Shipment_Line__c shl = (Shipment_Line__c)wrapper.line;
            if (shl.Sales_Order_Line__c == sol.Id) {
                System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
                for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                    System.assert(sw.skid.Quantity__c == 5, sw);
                    sw.skid.Item__r = shl.Item__r;
                }
            }
        }

        delete c;

        ShipmentInventoryService.confirmShip(wrappers);
        List<Configuration__c> configList = new List<Configuration__c>();  
        List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType,bin__c.sObjectType,Lot__c.sObjectType,Serial__c.sObjectType,    
        	                                  FOB_Terms__c.sObjectType,Serial_Transaction__c.sObjectType,Receipt_Line__c.sObjectType,
        	                                  Receiving_Document__c.sObjectType,Item__c.sObjectType,Purchase_Order_Line__c.sObjectType,
        	                                  Company__c.sObjectType,Component__c.sObjectType,Customer__c.sObjectType};  

         for (sObjectType s:skipTriggers) {
             configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
         }
         insert configList;    
        
        SOQLUtil fulfillmentQuery = new SOQLUtil('Fulfillment__c');
        fulfillmentQuery.addField('Id');
        fulfillmentQuery.setWhereClause('Sales_Order__c = \'' + sol.Sales_Order__c + '\' AND Invoice_Ready__c = true');
        List<Fulfillment__c> fulfillments = Database.query(fulfillmentQuery.getQuery());
        System.assert(fulfillments.size() == 4, fulfillments);

        shipment = Database.query(shipmentQuery.getQuery());
        result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, false);
        System.assert(result.success, result);
        wrappers = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:wrappers) {
            wrapper.header = shipment;
            Shipment_Line__c shl = (Shipment_Line__c)wrapper.line;
            if (shl.Sales_Order_Line__c == sol.Id) {
                System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
                for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                    System.assert(sw.skid.Quantity__c == 5, sw);
                    sw.skid.Item__r = shl.Item__r;
                }
            }
        }

         
        ShipmentInventoryService.undoShip(wrappers);
         delete  configList;   
        
        fulfillmentQuery.setWhereClause('Sales_Order__c = \'' + sol.Sales_Order__c + '\' AND Invoice_Ready__c = false');
        fulfillments = Database.query(fulfillmentQuery.getQuery());
        System.assert(fulfillments.size() == 8, fulfillments);
        Test.stopTest();      
    }*/
    
    private static testMethod void packaging() {
        fuel.setupInventory(true, false, true);

        Sales_Order__c so = fuel.packageSalesOrder;
        new SalesOrderService().plan(so.Id);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        LineWrapper wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        LineWrapper shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper uomWrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:uomWrapper.serialWrappers) {
                SKID__c skid = sw.skid;
                if (uomWrapper.uom == 'PT') {
                    System.assert(skid.Count_Quantity__c == 6, skid);
                    System.assert(skid.Quantity_Available__c == 6, skid);
                    System.assert(skid.Quantity_Issued__c == 6, skid);   //PT-EA conversion factor

                    skid.Quantity_to_Issue__c = 1; //1 PT
                    skid.Input_Quantity__c = 6;    //6 EA
                } else if (uomWrapper.uom == 'CS') {
                    System.assert(skid.Count_Quantity__c == 202, skid);
                    System.assert(skid.Quantity_Available__c == 10, skid);
                    System.assert(skid.Quantity_Issued__c == 2, skid);   //CS-EA conversion factor

                    skid.Quantity_to_Issue__c = 1; //1 CS
                    skid.Quantity_to_Return__c = 1; //1 EA
                    skid.Input_Quantity__c = 3;    //3 EA
                } else if (uomWrapper.uom == 'EA2') {
                    System.assert(skid.Count_Quantity__c == 100, skid);
                    System.assert(skid.Quantity_Available__c == 10, skid);
                    System.assert(skid.Quantity_Issued__c == 1, skid);   //EA-EA conversion factor

                    skid.Quantity_to_Issue__c = 1; //1 EA
                    skid.Input_Quantity__c = 1;    //1 EA
                } else {
                    System.assert(false, 'Invalid UOM: ' + uomWrapper.uom);
                }

                skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                shlWrapper.serialWrappers.add(sw);
            }
        }
        
        ShipmentInventoryService.plan(new List<LineWrapper>{ shlWrapper });
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper uomWrapper:wrappers) {
            SkidService3.SerialWrapper sw = uomWrapper.serialWrappers[0];
            sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
            shlWrapper.serialWrappers.add(sw);
        }
        Test.startTest();
        ShipmentInventoryService.pick(new List<LineWrapper>{ shlWrapper });

        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson,Shipment__c.Class);

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);

        wrappers = (List<LineWrapper>)result.records;
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 3, wrapper.serialWrappers);

        for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
            if (sw.skid.Packaging_UOM__r.Name == 'PT') System.assert(sw.skid.Quantity__c == 1, sw.skid);
            else if (sw.skid.Packaging_UOM__r.Name == 'CS') System.assert(sw.skid.Quantity__c == 1, sw.skid);
            else if (sw.skid.Packaging_UOM__r.Name == 'EA2') System.assert(sw.skid.Quantity__c == 2, sw.skid);
            else System.assert(false, 'Invalid UOM: ' + sw.skid.Packaging_UOM__r.Name);
        }

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Container_Item__c', 'From_Facility__c', 'From_Location__c', 'From_Packaging_UOM__c',
            'From_SKID__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c',

            'Container_Item__r.ExtId__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c', 'Sales_Order_Line__r.Quantity_Fulfilled__c', 'Sales_Order_Line__r.Quantity_Shipped__c',
            'Sales_Order_Line__r.Sales_Order__c', 'Sales_Order_Line__r.Sales_Order__r.Status__c', 'Sales_Order_Line__r.Status__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c',
            'Shipment_Line__r.Item__c', 'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_Shipped__c',
            'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Date_Shipped__c', 'Shipment_Line__r.Shipment__r.Locked__c',
            'Shipment_Line__r.Shipment__r.Status__c', 'Shipment_Line__r.Shipment__r.Transaction_Date__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Container_Item__r.ExtId__c', 'To_SKID__r.Facility2__c',
            'To_SKID__r.Item__c', 'To_SKID__r.Location__c', 'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c',
            'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c', 'To_SKID__r.Type__c'
        });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Sales Order Shipment\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 3, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Shipment_Line__c != null, it);
            System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
//            System.assert(it.To_Facility__c == null, it);
            System.assert(it.To_Location__c == null, it);
            System.assert(it.From_SKID__c == null, it);
            System.assert(it.To_SKID__c == null, it);

            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 10, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == true, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c != null, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Transaction_Date__c != null, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 0, it.Sales_Order_Line__r);
            System.assert(it.Sales_Order_Line__r.Quantity_Shipped__c == 10, it.Sales_Order_Line__r);
            System.assert(it.Sales_Order_Line__r.Quantity_Fulfilled__c == 10, it.Sales_Order_Line__r);
            System.assert(it.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_CLOSED, it.Sales_Order_Line__r);
            System.assert(it.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderService.SO_STATUS_CLOSED, it.Sales_Order_Line__r.Sales_Order__r);

            if (it.Packaging_UOM__r.Name == 'PT') {
                System.assert(it.Quantity__c == 1, it);
                System.assert(it.Quantity_Stocking_UOM__c == 6, it);
            } else if (it.Packaging_UOM__r.Name == 'CS') {
                System.assert(it.Quantity__c == 1, it);
                System.assert(it.Quantity_Stocking_UOM__c == 2, it);
            } else if (it.Packaging_UOM__r.Name == 'EA2') {
                System.assert(it.Quantity__c == 2, it);
                System.assert(it.Quantity_Stocking_UOM__c == 2, it);
            } else {
                System.assert(false, 'Invalid UOM: ' + it.Packaging_UOM__r.Name);
            }
        }

        ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(!ext.shipMode, ext);

        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson,Shipment__c.Class);

        result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);

        wrappers = (List<LineWrapper>)result.records;
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        System.assert(wrapper.serialWrappers.size() == 3, wrapper.serialWrappers);

        for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {if (sw.skid.Packaging_UOM__r.Name == 'PT') System.assert(sw.skid.Quantity__c == 1, sw.skid);
            else if (sw.skid.Packaging_UOM__r.Name == 'CS') System.assert(sw.skid.Quantity__c == 1, sw.skid);
            else if (sw.skid.Packaging_UOM__r.Name == 'EA2') System.assert(sw.skid.Quantity__c == 2, sw.skid);
            else System.assert(false, 'Invalid UOM: ' + sw.skid.Packaging_UOM__r.Name);
        }

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\' AND Type__c = \'Sales Order Undo Shipment\'');

        Test.stopTest();

        itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 3, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Shipment_Line__c != null, it);
            System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
            System.assert(it.From_Facility__c == null, it);
            System.assert(it.From_Location__c == null, it);
            System.assert(it.From_Packaging_UOM__c == null, it);
            System.assert(it.To_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_SKID__c == null, it);

            System.assert(it.To_SKID__c != null, it);
            SKID__c toSkid = it.To_SKID__r;
            System.assert(toSkid.Company__c == it.Company__c, toSkid);
            System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, toSkid);
            System.assert(toSkid.Packaging_UOM__c == it.Packaging_UOM__c, toSkid);
            System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Item__c == it.Item__c, toSkid);
            System.assert(toSkid.Facility2__c == it.Shipment_Line__r.Facility__c, toSkid);
            System.assert(toSkid.Location__c == it.Shipment_Line__r.Location__c, toSkid);
            System.assert(toSkid.Shipment_Line__c == it.Shipment_Line__c, toSkid);

            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Shipped__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Locked__c == false, it.Shipment_Line__r.Shipment__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Date_Shipped__c == null, it.Shipment_Line__r.Shipment__r);

            System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 10, it.Sales_Order_Line__r);
            System.assert(it.Sales_Order_Line__r.Quantity_Shipped__c == 0, it.Sales_Order_Line__r);
            System.assert(it.Sales_Order_Line__r.Quantity_Fulfilled__c == 0, it.Sales_Order_Line__r);
            System.assert(it.Sales_Order_Line__r.Status__c == SalesOrderLineService.SO_LINE_STATUS_OPEN, it.Sales_Order_Line__r);
            System.assert(it.Sales_Order_Line__r.Sales_Order__r.Status__c == SalesOrderService.SO_STATUS_OPEN, it.Sales_Order_Line__r.Sales_Order__r);

            if (it.Packaging_UOM__r.Name == 'PT') {
                System.assert(it.Quantity__c == 1, it);
                System.assert(it.Quantity_Stocking_UOM__c == 6, it);

                System.assert(toSkid.Quantity__c == 1, toSkid);
                System.assert(toSkid.Quantity_Stocking_UOM__c == 6, toSkid);
            } else if (it.Packaging_UOM__r.Name == 'CS') {
                System.assert(it.Quantity__c == 1, it);
                System.assert(it.Quantity_Stocking_UOM__c == 2, it);

                System.assert(toSkid.Quantity__c == 1, toSkid);
                System.assert(toSkid.Quantity_Stocking_UOM__c == 2, toSkid);
            } else if (it.Packaging_UOM__r.Name == 'EA2') {
                System.assert(it.Quantity__c == 2, it);
                System.assert(it.Quantity_Stocking_UOM__c == 2, it);

                System.assert(toSkid.Quantity__c == 2, toSkid);
                System.assert(toSkid.Quantity_Stocking_UOM__c == 2, toSkid);
            } else {
                System.assert(false, 'Invalid UOM: ' + it.Packaging_UOM__r.Name);
            }
        }
    }
}