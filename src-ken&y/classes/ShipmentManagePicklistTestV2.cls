@isTest
private class ShipmentManagePicklistTestV2 {
    @testSetup
    private static void setupData() {
    	DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType,Currency__c.sObjectType ,Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,
            Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, item_attribute__c.sObjectType,Shipment__c.sObjectType,Customer__c.sObjectType, Shipment_Line__c.sObjectType,Product__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        TestFuel f = new TestFuel();
        System.assert(f.periodList != null);
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.itemAttrObj2 != null);
        System.assert(f.supplier != null);
        System.assert(f.purchaseOrder != null);
        System.assert(f.purchaseOrderLines != null);
        delete configList;
        new SalesOrderService().plan(f.packageSalesOrder.Id);
    }

    public static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void noAttributes() {
        fuel.setupInventory();

        Sales_Order__c so = fuel.packageSalesOrder;

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
        Test.startTest();
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
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 0, skid);
        System.assert(skid.Quantity_Available__c == 10, skid);
        
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        
        JsonResult result = ShipmentWorkbenchExt.save(wrappers, 'pick');
        System.assert(result.success, result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',

            'Item__r.Stocking_UOM__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c','Shipment_Line__r.Sales_Order_Line__c',
            'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\'');

        Inventory_Transaction__c it = Database.query(itQuery.getQuery());

        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Type__c == 'Sales Order Pick', it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Finalized__c == true, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.To_Facility__c == it.From_Facility__c, it);
        System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);

        System.assert(it.From_SKID__c != null, it);
        System.assert(it.From_SKID__r.Quantity__c == 90, it.From_SKID__r);
        System.assert(it.From_SKID__r.Quantity_Stocking_UOM__c == it.From_SKID__r.Quantity__c, it.From_SKID__r);

        System.assert(it.To_SKID__c != null, it);
        System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
        System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Quantity__c == 10, it.To_SKID__r);
        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Location__c == it.Shipment_Line__r.Location__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Shipment_Line__c == it.Shipment_Line__c, it.To_SKID__r);

        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c','Sales_Order_Line__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 10, skid);
        System.assert(skid.Quantity_Available__c == 0, skid);
        
        skid.Quantity_to_Issue__c = -10;
        skid.Input_Quantity__c = -10;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');

        ShipmentInventoryService.pick(wrappers);

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Sales Order Pick\'');

        it = Database.query(itQuery.getQuery());

        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Type__c == 'Sales Order Undo Pick', it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Finalized__c == true, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.To_Facility__c == it.From_Facility__c, it);
        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
        System.assert(it.From_SKID__c == null, it);

        System.assert(it.To_SKID__c != null, it);
        System.assert(it.To_SKID__r.Quantity__c == 100, it.To_SKID__r);
        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);

        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
        
        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 1,skids);

        skid = skids[0];
        System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
        System.assert(skid.Quantity__c == 10, skid);
        System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
        System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
        System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Container_Item__c == skid.Item__c, skid);
        System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
        System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 10, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_Picked__c == 0, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
    }

    private static testMethod void attributes() {
        fuel.setupInventory(true);

        Sales_Order__c so = fuel.packageSalesOrder;

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
        
        Test.startTest();
        
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
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 0, skid);
        System.assert(skid.Quantity_Available__c == 10, skid);
        
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        ShipmentInventoryService.pick(wrappers);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',

            'Item__r.Stocking_UOM__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c','Shipment_Line__r.Sales_Order_Line__c',
            'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\'');

        Inventory_Transaction__c it = Database.query(itQuery.getQuery());

        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Type__c == 'Sales Order Pick', it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Finalized__c == true, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.To_Facility__c == it.From_Facility__c, it);
        System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);

        System.assert(it.From_SKID__c != null, it);
        System.assert(it.From_SKID__r.Quantity__c == 90, it.From_SKID__r);
        System.assert(it.From_SKID__r.Quantity_Stocking_UOM__c == it.From_SKID__r.Quantity__c, it.From_SKID__r);

        System.assert(it.To_SKID__c != null, it);
        System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
        System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Quantity__c == 10, it.To_SKID__r);
        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Location__c == it.Shipment_Line__r.Location__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Shipment_Line__c == it.Shipment_Line__c, it.To_SKID__r);

        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 10, skid);
        System.assert(skid.Quantity_Available__c == 0, skid);
        
        skid.Quantity_to_Issue__c = -10;
        skid.Input_Quantity__c = -10;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');

        ShipmentInventoryService.pick(wrappers);

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Sales Order Pick\'');

        it = Database.query(itQuery.getQuery());

        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Type__c == 'Sales Order Undo Pick', it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Finalized__c == true, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.To_Facility__c == it.From_Facility__c, it);
        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
        System.assert(it.From_SKID__c == null, it);

        System.assert(it.To_SKID__c != null, it);
        System.assert(it.To_SKID__r.Quantity__c == 100, it.To_SKID__r);
        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);

        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
        
        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 1,skids);

        skid = skids[0];
        System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
        System.assert(skid.Quantity__c == 10, skid);
        System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
        System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
        System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Container_Item__c == skid.Item__c, skid);
        System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
        System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 10, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_Picked__c == 0, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
    }

    private static testMethod void serials() {
        fuel.setupInventory(true, true);

        Sales_Order__c so = fuel.packageSalesOrder;

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
        Test.startTest();
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
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 0, skid);
        System.assert(skid.Quantity_Available__c == 10, skid);
        
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        for (Integer i = 0; i < 10; i++) wrapper.serialWrappers[0].serialList[i].Temporary_Value_Holder__c = 'Pick';
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        ShipmentInventoryService.pick(wrappers);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',

            'Item__r.Stocking_UOM__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c','Shipment_Line__r.Sales_Order_Line__c',
            'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery, 'Serial_Transactions__r');
        stQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Facility__c', 'Item__c', 'Serial__c', 'Serial_Parent__c', 'Type__c',

            'Serial__r.Allocated_SKID__c', 'Serial__r.Allow_Reentry__c', 'Serial__r.Company__c', 'Serial__r.Item__c', 'Serial__r.SKID__c' });
        itQuery.addChildRelationship(stQuery);

        Inventory_Transaction__c it = Database.query(itQuery.getQuery());

        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Type__c == 'Sales Order Pick', it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Finalized__c == true, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.To_Facility__c == it.From_Facility__c, it);
        System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
        System.assert(it.From_SKID__c == null, it);

        System.assert(it.To_SKID__c != null, it);
        System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
        System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Quantity__c == 10, it.To_SKID__r);
        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Location__c == it.Shipment_Line__r.Location__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Shipment_Line__c == it.Shipment_Line__c, it.To_SKID__r);

        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);

        System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r);
        for (Serial_Transaction__c st:it.Serial_Transactions__r) {
            System.assert(st.Company__c == it.Company__c, st);
            System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
            System.assert(st.Item__c == it.Item__c, st);
            System.assert(st.Serial__c != null, st);
            System.assert(st.Serial_Parent__c == null, st);
            System.assert(st.Type__c == 'Pick', st);
            System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
            System.assert(st.Serial__r.Allow_Reentry__c == false, st.Serial__r);
            System.assert(st.Serial__r.Company__c == it.Company__c, st.Serial__r);
            System.assert(st.Serial__r.Item__c == it.Item__c, st.Serial__r);
            System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
        }

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery, 'Allocated_Serials__r');
        serialQuery.addField('Id');
        skidQuery.addChildRelationship(serialQuery);

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 10, skid);
        System.assert(skid.Quantity_Available__c == 0, skid);
        
        skid.Quantity_to_Issue__c = -10;
        skid.Input_Quantity__c = -10;
        for (Serial__c serial:wrapper.serialWrappers[0].serialList) {
            if (serial.Temporary_Value_Holder__c == 'Picked') serial.Temporary_Value_Holder__c = 'Unpick';
        }
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');

        ShipmentInventoryService.pick(wrappers);

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Sales Order Pick\'');

        it = Database.query(itQuery.getQuery());

        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Type__c == 'Sales Order Undo Pick', it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Finalized__c == true, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.To_Facility__c == it.From_Facility__c, it);
        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
        System.assert(it.From_SKID__c == null, it);

        System.assert(it.To_SKID__c != null, it);
        System.assert(it.To_SKID__r.Quantity__c == 10, it.To_SKID__r);
        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);

        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);

        System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r);
        for (Serial_Transaction__c st:it.Serial_Transactions__r) {
            System.assert(st.Company__c == it.Company__c, st);
            System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
            System.assert(st.Item__c == it.Item__c, st);
            System.assert(st.Serial__c != null, st);
            System.assert(st.Serial_Parent__c == null, st);
            System.assert(st.Type__c == 'Undo Pick', st);
            System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
            System.assert(st.Serial__r.Allow_Reentry__c == false, st.Serial__r);
            System.assert(st.Serial__r.Company__c == it.Company__c, st.Serial__r);
            System.assert(st.Serial__r.Item__c == it.Item__c, st.Serial__r);
            System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
        }
        
        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 1,skids);

        skid = skids[0];
        System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
        System.assert(skid.Quantity__c == 10, skid);
        System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
        System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
        System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Container_Item__c == skid.Item__c, skid);
        System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
        System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 10, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_Picked__c == 0, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
    }

    private static testMethod void errors() {
        fuel.setupInventory(true, true);

        Sales_Order__c so = fuel.packageSalesOrder;

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
        Test.startTest();
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        SKID__c skid = wrapper.serialWrappers[0].skid;
        skid.Quantity_to_Issue__c = 5;
        skid.Input_Quantity__c = 5;
        for (Integer i = 0; i < 5; i++) wrapper.serialWrappers[0].serialList[i].Temporary_Value_Holder__c = 'Plan';
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        
        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 0, skid);
        System.assert(skid.Quantity_Available__c == 5, skid);
        
        skid.Quantity_to_Issue__c = 6;
        skid.Input_Quantity__c = 6;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        try {
            ShipmentInventoryService.pick(wrappers);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        
        skid.Quantity_to_Issue__c = 5;
        skid.Input_Quantity__c = 5;
        for (Serial__c serial:wrapper.serialWrappers[0].serialList) {
            if (serial.Allocated_SKID__c != null) serial.Temporary_Value_Holder__c = 'Planned';
            else serial.Temporary_Value_Holder__c = 'Pick';
        }

        try {
            ShipmentInventoryService.pick(wrappers);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }

        skid.Quantity_to_Issue__c = 4;
        skid.Input_Quantity__c = 4;

        try {
            ShipmentInventoryService.pick(wrappers);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
    }

    /*private static testMethod void packagingPlanBreak() {
        fuel.setupInventory(true, false, true);

        Sales_Order__c so = fuel.packageSalesOrder;

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        wrappers[0].line = shipmentLines.get(wrappers[0].line.Id);
        wrappers[0].header = wrappers[0].line.getSObject('Shipment__r');
        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        LineWrapper shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Packaging_UOM__r.Package_Class__c != sw.skid.Container_Item__r.Container_Package_Class__c && sw.skid.Container_Item__r.Container_Package_Class__c != null) continue;

                if (wrapper.uom == 'PT') {
                    sw.skid.Quantity_to_Issue__c = 1; //1 PT
                    sw.skid.Input_Quantity__c = 6;  //6 EA
                } else if (wrapper.uom == 'CS') {
                    sw.skid.Quantity_to_Issue__c = 1; //1 CS
                    sw.skid.Quantity_to_Return__c = 1;  //1 EA
                    sw.skid.Input_Quantity__c = 3;  //3 EA
                } else if (wrapper.uom == 'EA2') {
                    sw.skid.Quantity_to_Issue__c = 1;   //1 EA
                    sw.skid.Input_Quantity__c = 1;  //1 EA
                }
                sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                shlWrapper.serialWrappers.add(sw);
            }
        }
        
        Test.startTest();

        ShipmentInventoryService.plan(new List<LineWrapper>{ shlWrapper });
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 3, wrappers.size());

        shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            if (wrapper.uom == 'PT' || wrapper.uom == 'CS') {
                System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);

                SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
                System.assert(sw.skid.Quantity_Used__c == 0, sw.skid);
                System.assert(sw.skid.Quantity_to_Issue__c == 1, sw.skid);
                if (wrapper.uom == 'PT') {
                    System.assert(sw.skid.Quantity_Available__c == 6, sw.skid);
                    System.assert(sw.skid.Input_Quantity__c == 6, sw.skid);
                } else {
                    System.assert(sw.skid.Quantity_Available__c == 2, sw.skid);
                    System.assert(sw.skid.Input_Quantity__c == 2, sw.skid);
                }

                sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                shlWrapper.serialWrappers.add(sw);
            } else if (wrapper.uom == 'EA2') {
                System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);

                for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                    System.assert(sw.skid.Quantity_Used__c == 0, sw.skid);
                    System.assert(sw.skid.Quantity_Available__c == 1, sw.skid);
                    System.assert(sw.skid.Quantity_to_Issue__c == 1, sw.skid);
                    System.assert(sw.skid.Input_Quantity__c == 1, sw.skid);

                    sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                    shlWrapper.serialWrappers.add(sw);
                }
            } else {
                System.assert(false, 'Invalid UOM: ' + wrapper.uom);
            }
        }

        ShipmentInventoryService.pick(new List<LineWrapper>{ shlWrapper });

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'Container_Item__r.ExtId__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',

            'Item__r.Stocking_UOM__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c',

            'From_SKID__r.Company__c', 'From_SKID__r.Container_Item__c', 'From_SKID__r.Container_Item__r.ExtId__c', 'From_SKID__r.Facility2__c', 'From_SKID__r.Item__c',
            'From_SKID__r.Location__c', 'From_SKID__r.Packaging_UOM__c', 'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c', 'From_SKID__r.Shipment_Line__c',
            'From_SKID__r.Stocking_UOM__c', 'From_SKID__r.Type__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Container_Item__r.ExtId__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c',
            'To_SKID__r.Location__c', 'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c',
            'To_SKID__r.Stocking_UOM__c', 'To_SKID__r.Type__c'
        });
        itQuery.setWhereClause('Type__c IN (\'Break Package\', \'Sales Order Pick\')');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 5, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);

            SKID__c fromSkid = it.From_SKID__r;
            SKID__c toSkid = it.To_SKID__r;

            if (it.Container_Item__r.ExtId__c == 'PalletContainer') {
                System.assert(it.From_SKID__c == null, it);
            } else {
                System.assert(it.From_SKID__c != null, it);
                System.assert(fromSkid.Company__c == it.Company__c, fromSkid);
                System.assert(fromSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, fromSkid);
                System.assert(fromSkid.Item__c == it.Item__c, fromSkid);
                System.assert(fromSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, fromSkid);
                System.assert(fromSkid.Facility2__c == it.From_Facility__c, fromSkid);
                System.assert(fromSkid.Location__c == it.From_Location__c, fromSkid);
            }
            
            System.assert(it.To_SKID__c != null, it);
            System.assert(toSkid.Company__c == it.Company__c, toSkid);
            System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, toSkid);
            System.assert(toSkid.Item__c == it.Item__c, toSkid);
            System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Facility2__c == it.To_Facility__c, toSkid);
            System.assert(toSkid.Location__c == it.To_Location__c, toSkid);

            if (it.Type__c == 'Break Package') {
                System.assert(it.Quantity__c == 2, it);
                System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
                System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
                System.assert(it.Finalized__c == true, it);
                System.assert(it.To_Location__c == it.From_Location__c, it);
                System.assert(it.From_Packaging_UOM__r.Name == 'CS', it);
                System.assert(it.Container_Item__c == it.Item__c, it);
                
                System.assert(fromSkid.Quantity__c == 98, fromSkid);
                System.assert(fromSkid.Quantity_Stocking_UOM__c == 196, fromSkid);
                System.assert(fromSkid.Packaging_UOM__r.Name == 'CS', fromSkid);
                System.assert(fromSkid.Container_Item__r.ExtId__c == 'CaseContainer', fromSkid);
                
                System.assert(toSkid.Quantity__c == 5, toSkid);
                System.assert(toSkid.Quantity_Stocking_UOM__c == toSkid.Quantity__c, toSkid);
                System.assert(toSkid.Packaging_UOM__c == toSkid.Stocking_UOM__c, toSkid);
                System.assert(toSkid.Container_Item__c == toSkid.Item__c, toSkid);
            } else if (it.Type__c == 'Sales Order Pick') {
                System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
                System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
                System.assert(it.Quantity__c == 1, it);
                System.assert(it.Inventory_Change__c != null, it);
                System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
                System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
                System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
                System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
                System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
                System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
                System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);

                System.assert(toSkid.Shipment_Line__c == it.Shipment_Line__c, toSkid);

                if (it.Container_Item__r.ExtId__c == 'PalletContainer') {
                    System.assert(it.Quantity_Stocking_UOM__c == 6, it);
                    System.assert(it.Packaging_UOM__r.Name == 'PT', it);
                
                    System.assert(toSkid.Quantity__c == 1, toSkid);
                    System.assert(toSkid.Quantity_Stocking_UOM__c == 6, toSkid);
                    System.assert(toSkid.Packaging_UOM__c == it.Packaging_UOM__c, toSkid);
                    System.assert(toSkid.Container_Item__c == it.Container_Item__c, toSkid);
                } else if (it.Container_Item__r.ExtId__c == 'CaseContainer') {
                    System.assert(it.Quantity_Stocking_UOM__c == 2, it);
                    System.assert(it.Packaging_UOM__r.Name == 'CS', it);

                    System.assert(fromSkid.Quantity__c == 98, fromSkid);
                    System.assert(fromSkid.Quantity_Stocking_UOM__c == 196, fromSkid);
                    System.assert(fromSkid.Packaging_UOM__r.Name == 'CS', fromSkid);
                    System.assert(fromSkid.Container_Item__r.ExtId__c == 'CaseContainer', fromSkid);
                
                    System.assert(toSkid.Quantity__c == 1, toSkid);
                    System.assert(toSkid.Quantity_Stocking_UOM__c == 2, toSkid);
                    System.assert(toSkid.Packaging_UOM__c == fromSkid.Packaging_UOM__c, toSkid);
                    System.assert(toSkid.Container_Item__c == fromSkid.Container_Item__c, toSkid);
                } else {
                    System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
                    System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
                    System.assert(it.Container_Item__c == it.Item__c, it);

                    System.assert(fromSkid.Quantity__c == 5, fromSkid);
                    System.assert(fromSkid.Quantity_Stocking_UOM__c == 5, fromSkid);
                    System.assert(fromSkid.Packaging_UOM__c == fromSkid.Stocking_UOM__c, fromSkid);
                    System.assert(fromSkid.Container_Item__c == fromSkid.Item__c, fromSkid);
                
                    System.assert(toSkid.Quantity__c == 2, toSkid);
                    System.assert(toSkid.Quantity_Stocking_UOM__c == 2, toSkid);
                    System.assert(toSkid.Packaging_UOM__c == fromSkid.Packaging_UOM__c, toSkid);
                    System.assert(toSkid.Container_Item__c == fromSkid.Container_Item__c, toSkid);
                }
            }
        }

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 3, wrappers);

        shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (wrapper.uom == 'PT' || wrapper.uom == 'CS') {
                    System.assert(sw.skid.Quantity_Used__c == 1, sw.skid);

                    sw.skid.Quantity_to_Issue__c = -1;
                    if (wrapper.uom == 'PT') sw.skid.Input_Quantity__c = -6;
                    else sw.skid.Input_Quantity__c = -2;
                } else if (wrapper.uom == 'EA2') {
                    System.assert(sw.skid.Quantity_Used__c == 2, sw.skid);

                    sw.skid.Quantity_to_Issue__c = -2;
                    sw.skid.Input_Quantity__c = -2;
                }
                sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                shlWrapper.serialWrappers.add(sw);
            }
        }

        ShipmentInventoryService.pick(new List<LineWrapper>{ shlWrapper });

        itQuery.setWhereClause('Type__c = \'Sales Order Undo Pick\'');

        itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 3, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Finalized__c == true, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 10, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
            System.assert(it.From_SKID__c == null, it);
            System.assert(it.To_SKID__c != null, it);

            SKID__c toSkid = it.To_SKID__r;

            System.assert(toSkid.Company__c == it.Company__c, toSkid);
            System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, toSkid);
            System.assert(toSkid.Item__c == it.Item__c, toSkid);
            System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Facility2__c == it.To_Facility__c, toSkid);
            System.assert(toSkid.Location__c == it.To_Location__c, toSkid);

            if (it.Packaging_UOM__r.Name == 'PT') {
                System.assert(it.Quantity__c == 1, it);
                System.assert(it.Quantity_Stocking_UOM__c == 6, it);
                System.assert(it.Container_Item__r.ExtId__c == 'PalletContainer', it);

                System.assert(toSkid.Quantity__c == 1, toSkid);
                System.assert(toSkid.Quantity_Stocking_UOM__c == 6, toSkid);
                System.assert(toSkid.Packaging_UOM__r.Name == 'PT', toSkid);
                System.assert(toSkid.Container_Item__r.ExtId__c == 'PalletContainer', toSkid);
            } else if (it.Packaging_UOM__r.Name == 'CS') {
                System.assert(it.Quantity__c == 1, it);
                System.assert(it.Quantity_Stocking_UOM__c == 2, it);
                System.assert(it.Container_Item__r.ExtId__c == 'CaseContainer', it);

                System.assert(toSkid.Quantity__c == 99, toSkid);
                System.assert(toSkid.Quantity_Stocking_UOM__c == 198, toSkid);
                System.assert(toSkid.Packaging_UOM__r.Name == 'CS', toSkid);
                System.assert(toSkid.Container_Item__r.ExtId__c == 'CaseContainer', toSkid);
            } else if (it.Packaging_UOM__r.Name == 'EA2') {
                System.assert(it.Quantity__c == 2, it);
                System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
                System.assert(it.Container_Item__c == it.Item__c, it);

                System.assert(toSkid.Quantity__c == 7, toSkid);
                System.assert(toSkid.Quantity_Stocking_UOM__c == 7, toSkid);
                System.assert(toSkid.Packaging_UOM__c == toSkid.Stocking_UOM__c, toSkid);
                System.assert(toSkid.Container_Item__c == toSkid.Item__c, toSkid);
            } else {
                System.assert(false, 'Invalid UOM: ' + it.Packaging_UOM__r.Name);
            }
        }

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 3, skids);
    }

    private static testMethod void packagingPickBreak() {
        fuel.setupInventory(true, false, true);

        Sales_Order__c so = fuel.packageSalesOrder;

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        wrappers[0].line = shipmentLines.get(wrappers[0].line.Id);
        wrappers[0].header = wrappers[0].line.getSObject('Shipment__r');
        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        LineWrapper shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Packaging_UOM__r.Package_Class__c != sw.skid.Container_Item__r.Container_Package_Class__c && sw.skid.Container_Item__r.Container_Package_Class__c != null) continue;

                if (wrapper.uom == 'PT') {
                    sw.skid.Quantity_to_Issue__c = 1; //1 PT
                    sw.skid.Input_Quantity__c = 6;  //6 EA
                } else if (wrapper.uom == 'CS') {
                    sw.skid.Quantity_to_Issue__c = 2; //2 CS
                    sw.skid.Input_Quantity__c = 4;  //4 EA
                } else if (wrapper.uom == 'EA2') {
                    sw.skid.Quantity_to_Issue__c = 0;   //0 EA
                    sw.skid.Input_Quantity__c = 0;  //0 EA
                }
                sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                shlWrapper.serialWrappers.add(sw);
            }
        }
        
        Test.startTest();

        ShipmentInventoryService.plan(new List<LineWrapper>{ shlWrapper });
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            if (wrapper.uom == 'PT' || wrapper.uom == 'CS') {
                System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);

                SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
                System.assert(sw.skid.Quantity_Used__c == 0, sw.skid);
                
                if (wrapper.uom == 'PT') {
                    System.assert(sw.skid.Quantity_Available__c == 6, sw.skid);
                    System.assert(sw.skid.Quantity_to_Issue__c == 1, sw.skid);  //1 PT
                    System.assert(sw.skid.Input_Quantity__c == 6, sw.skid); //6 EA
                } else {
                    System.assert(sw.skid.Quantity_Available__c == 4, sw.skid);
                    System.assert(sw.skid.Quantity_to_Issue__c == 2, sw.skid);
                    System.assert(sw.skid.Input_Quantity__c == 4, sw.skid);

                    sw.skid.Quantity_to_Issue__c = 1;   //1 CS
                    sw.skid.Quantity_to_Return__c = 2;  //2 EA
                    sw.skid.Input_Quantity__c = 4;  //4 EA
                }

                sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                shlWrapper.serialWrappers.add(sw);
            } else {
                System.assert(false, 'Invalid UOM: ' + wrapper.uom);
            }
        }

        ShipmentInventoryService.pick(new List<LineWrapper>{ shlWrapper });

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'Container_Item__r.ExtId__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',

            'Item__r.Stocking_UOM__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c',

            'From_SKID__r.Company__c', 'From_SKID__r.Container_Item__c', 'From_SKID__r.Container_Item__r.ExtId__c', 'From_SKID__r.Facility2__c', 'From_SKID__r.Item__c',
            'From_SKID__r.Location__c', 'From_SKID__r.Packaging_UOM__c', 'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c', 'From_SKID__r.Shipment_Line__c',
            'From_SKID__r.Stocking_UOM__c', 'From_SKID__r.Type__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Container_Item__r.ExtId__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c',
            'To_SKID__r.Location__c', 'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c',
            'To_SKID__r.Stocking_UOM__c', 'To_SKID__r.Type__c'
        });
        itQuery.setWhereClause('Type__c IN (\'Break Package\', \'Sales Order Pick\')');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 4, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);

            SKID__c fromSkid = it.From_SKID__r;
            SKID__c toSkid = it.To_SKID__r;

            if (it.Container_Item__r.ExtId__c == 'PalletContainer') {
                System.assert(it.From_SKID__c == null, it);
            } else {
                System.assert(it.From_SKID__c != null, it);
                System.assert(fromSkid.Company__c == it.Company__c, fromSkid);
                System.assert(fromSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, fromSkid);
                System.assert(fromSkid.Item__c == it.Item__c, fromSkid);
                System.assert(fromSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, fromSkid);
                System.assert(fromSkid.Facility2__c == it.From_Facility__c, fromSkid);
                System.assert(fromSkid.Location__c == it.From_Location__c, fromSkid);
            }
            
            System.assert(it.To_SKID__c != null, it);
            System.assert(toSkid.Company__c == it.Company__c, toSkid);
            System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, toSkid);
            System.assert(toSkid.Item__c == it.Item__c, toSkid);
            System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Facility2__c == it.To_Facility__c, toSkid);
            System.assert(toSkid.Location__c == it.To_Location__c, toSkid);

            if (it.Type__c == 'Break Package') {
                System.assert(it.Quantity__c == 2, it);
                System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
                System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
                System.assert(it.Finalized__c == true, it);
                System.assert(it.To_Location__c == it.From_Location__c, it);
                System.assert(it.From_Packaging_UOM__r.Name == 'CS', it);
                System.assert(it.Container_Item__c == it.Item__c, it);
                
                System.assert(fromSkid.Quantity__c == 98, fromSkid);
                System.assert(fromSkid.Quantity_Stocking_UOM__c == 196, fromSkid);
                System.assert(fromSkid.Packaging_UOM__r.Name == 'CS', fromSkid);
                System.assert(fromSkid.Container_Item__r.ExtId__c == 'CaseContainer', fromSkid);
                
                System.assert(toSkid.Quantity__c == 5, toSkid);
                System.assert(toSkid.Quantity_Stocking_UOM__c == toSkid.Quantity__c, toSkid);
                System.assert(toSkid.Packaging_UOM__c == toSkid.Stocking_UOM__c, toSkid);
                System.assert(toSkid.Container_Item__c == toSkid.Item__c, toSkid);
            } else if (it.Type__c == 'Sales Order Pick') {
                System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
                System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
                System.assert(it.Inventory_Change__c != null, it);
                System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
                System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
                System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
                System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
                System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
                System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
                System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);

                System.assert(toSkid.Shipment_Line__c == it.Shipment_Line__c, toSkid);

                if (it.Container_Item__r.ExtId__c == 'PalletContainer') {
                    System.assert(it.Quantity__c == 1, it);
                    System.assert(it.Quantity_Stocking_UOM__c == 6, it);
                    System.assert(it.Packaging_UOM__r.Name == 'PT', it);
                
                    System.assert(toSkid.Quantity__c == 1, toSkid);
                    System.assert(toSkid.Quantity_Stocking_UOM__c == 6, toSkid);
                    System.assert(toSkid.Packaging_UOM__c == it.Packaging_UOM__c, toSkid);
                    System.assert(toSkid.Container_Item__c == it.Container_Item__c, toSkid);
                } else if (it.Container_Item__r.ExtId__c == 'CaseContainer') {
                    System.assert(it.Quantity__c == 1, it);
                    System.assert(it.Quantity_Stocking_UOM__c == 2, it);
                    System.assert(it.Packaging_UOM__r.Name == 'CS', it);

                    System.assert(fromSkid.Quantity__c == 98, fromSkid);
                    System.assert(fromSkid.Quantity_Stocking_UOM__c == 196, fromSkid);
                    System.assert(fromSkid.Packaging_UOM__r.Name == 'CS', fromSkid);
                    System.assert(fromSkid.Container_Item__r.ExtId__c == 'CaseContainer', fromSkid);
                
                    System.assert(toSkid.Quantity__c == 1, toSkid);
                    System.assert(toSkid.Quantity_Stocking_UOM__c == 2, toSkid);
                    System.assert(toSkid.Packaging_UOM__c == fromSkid.Packaging_UOM__c, toSkid);
                    System.assert(toSkid.Container_Item__c == fromSkid.Container_Item__c, toSkid);
                } else {
                    System.assert(it.Quantity__c == 2, it);
                    System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
                    System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
                    System.assert(it.Container_Item__c == it.Item__c, it);

                    System.assert(fromSkid.Quantity__c == 5, fromSkid);
                    System.assert(fromSkid.Quantity_Stocking_UOM__c == 5, fromSkid);
                    System.assert(fromSkid.Packaging_UOM__c == fromSkid.Stocking_UOM__c, fromSkid);
                    System.assert(fromSkid.Container_Item__c == fromSkid.Item__c, fromSkid);
                
                    System.assert(toSkid.Quantity__c == 2, toSkid);
                    System.assert(toSkid.Quantity_Stocking_UOM__c == 2, toSkid);
                    System.assert(toSkid.Packaging_UOM__c == fromSkid.Packaging_UOM__c, toSkid);
                    System.assert(toSkid.Container_Item__c == fromSkid.Container_Item__c, toSkid);
                }
            }
        }

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 3, wrappers);

        shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];

            if (wrapper.uom == 'PT' || wrapper.uom == 'CS') {
                System.assert(sw.skid.Quantity_Used__c == 1, sw.skid);

                sw.skid.Quantity_to_Issue__c = -1;
                if (wrapper.uom == 'PT') sw.skid.Input_Quantity__c = -6;
                else sw.skid.Input_Quantity__c = -2;
            } else if (wrapper.uom == 'EA2') {
                System.assert(sw.skid.Quantity_Used__c == 2, sw.skid);

                sw.skid.Quantity_to_Issue__c = -2;
                sw.skid.Input_Quantity__c = -2;
            } else {
                System.assert(false, 'Invalid UOM: ' + wrapper.uom);
            }

            sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
            shlWrapper.serialWrappers.add(sw);
        }

        ShipmentInventoryService.pick(new List<LineWrapper>{ shlWrapper });

        itQuery.setWhereClause('Type__c = \'Sales Order Undo Pick\'');

        itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 3, itList);

        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
            System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
            System.assert(it.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it);
            System.assert(it.Finalized__c == true, it);
            System.assert(it.Inventory_Change__c != null, it);
            System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
            System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
            System.assert(it.To_Facility__c == it.From_Facility__c, it);
            System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
            System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
            System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 10, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
            System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
            System.assert(it.From_SKID__c == null, it);
            System.assert(it.To_SKID__c != null, it);

            SKID__c toSkid = it.To_SKID__r;

            System.assert(toSkid.Company__c == it.Company__c, toSkid);
            System.assert(toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION, toSkid);
            System.assert(toSkid.Item__c == it.Item__c, toSkid);
            System.assert(toSkid.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, toSkid);
            System.assert(toSkid.Facility2__c == it.To_Facility__c, toSkid);
            System.assert(toSkid.Location__c == it.To_Location__c, toSkid);

            if (it.Packaging_UOM__r.Name == 'PT') {
                System.assert(it.Quantity__c == 1, it);
                System.assert(it.Quantity_Stocking_UOM__c == 6, it);
                System.assert(it.Container_Item__r.ExtId__c == 'PalletContainer', it);

                System.assert(toSkid.Quantity__c == 1, toSkid);
                System.assert(toSkid.Quantity_Stocking_UOM__c == 6, toSkid);
                System.assert(toSkid.Packaging_UOM__r.Name == 'PT', toSkid);
                System.assert(toSkid.Container_Item__r.ExtId__c == 'PalletContainer', toSkid);
            } else if (it.Packaging_UOM__r.Name == 'CS') {
                System.assert(it.Quantity__c == 1, it);
                System.assert(it.Quantity_Stocking_UOM__c == 2, it);
                System.assert(it.Container_Item__r.ExtId__c == 'CaseContainer', it);

                System.assert(toSkid.Quantity__c == 99, toSkid);
                System.assert(toSkid.Quantity_Stocking_UOM__c == 198, toSkid);
                System.assert(toSkid.Packaging_UOM__r.Name == 'CS', toSkid);
                System.assert(toSkid.Container_Item__r.ExtId__c == 'CaseContainer', toSkid);
            } else if (it.Packaging_UOM__r.Name == 'EA2') {
                System.assert(it.Quantity__c == 2, it);
                System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
                System.assert(it.Container_Item__c == it.Item__c, it);

                System.assert(toSkid.Quantity__c == 7, toSkid);
                System.assert(toSkid.Quantity_Stocking_UOM__c == 7, toSkid);
                System.assert(toSkid.Packaging_UOM__c == toSkid.Stocking_UOM__c, toSkid);
                System.assert(toSkid.Container_Item__c == toSkid.Item__c, toSkid);
            } else {
                System.assert(false, 'Invalid UOM: ' + it.Packaging_UOM__r.Name);
            }
        }

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 3, skids);
    }*/

    private static testMethod void unpickLocationChangeAllocation() {
        fuel.setupInventory(true);

        Sales_Order__c so = fuel.packageSalesOrder;

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
        
        Test.startTest();
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        SkidService3.SerialWrapper sw2 = wrapper.serialWrappers[0];
        sw2.skid.Quantity_to_Issue__c = 10;
        sw2.skid.Input_Quantity__c = 10;
        sw2.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        sw2 = wrapper.serialWrappers[0];
        sw2.skid.Quantity_to_Issue__c = 10;
        sw2.skid.Input_Quantity__c = 10;
        sw2.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        ShipmentInventoryService.pick(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        sw2 = wrapper.serialWrappers[0];
        sw2.temporaryValueHolder = '' + sw2.skid.Location__c + '|null|null';
        sw2.skid.Location__c = fuel.location2.Id;
        sw2.skid.Location__r = fuel.location2;
        sw2.skid.Quantity_to_Issue__c = -10;
        sw2.skid.Input_Quantity__c = -10;
        sw2.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        ShipmentInventoryService.pick(wrappers);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Quantity_Allocated__c', 'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c',
            'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Sales Order Pick\'');

        Inventory_Transaction__c it = Database.query(itQuery.getQuery());

        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Type__c == 'Sales Order Undo Pick', it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Finalized__c == true, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.To_Facility__c == it.From_Facility__c, it);
        System.assert(it.To_Location__c == fuel.location2.Id, it);
        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
        System.assert(it.From_SKID__c == null, it);

        System.assert(it.To_SKID__c != null, it);
        System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
        System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Quantity__c == 10, it.To_SKID__r);
        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Location__c == fuel.location2.Id, it.To_SKID__r);
        System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);

        System.assert(it.Shipment_Line__r.Quantity_Allocated__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 0, it.Sales_Order_Line__r);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Name' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c IN (\'' + SkidService3.SKID_TYPE_PLANNED + '\', \'' + SkidService3.SKID_TYPE_ALLOCATED + '\')');
        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
    }

    private static testMethod void unpickLocationChangeNoAllocation() {
        fuel.setupInventory(true);
        
        insert new Allocation_Profile__c(
            Company__c = fuel.company.Id,
            Date_Received__c = false,
            Expiration_Date__c = false,
            Location__c = false,
            Rental__c = false,
            Used__c = false
        );

        Sales_Order__c so = fuel.packageSalesOrder;

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
        Test.startTest();
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        SkidService3.SerialWrapper sw2 = wrapper.serialWrappers[0];
        sw2.skid.Quantity_to_Issue__c = 10;
        sw2.skid.Input_Quantity__c = 10;
        sw2.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        
        ShipmentInventoryService.plan(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        sw2 = wrapper.serialWrappers[0];
        sw2.skid.Quantity_to_Issue__c = 10;
        sw2.skid.Input_Quantity__c = 10;
        sw2.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        ShipmentInventoryService.pick(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        sw2 = wrapper.serialWrappers[0];
        sw2.temporaryValueHolder = '' + sw2.skid.Location__c + '|null|null';
        sw2.skid.Location__c = fuel.location2.Id;
        sw2.skid.Location__r = fuel.location2;
        sw2.skid.Quantity_to_Issue__c = -10;
        sw2.skid.Input_Quantity__c = -10;
        sw2.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        ShipmentInventoryService.pick(wrappers);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Quantity_Allocated__c', 'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c',
            'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Sales Order Pick\'');

        Inventory_Transaction__c it = Database.query(itQuery.getQuery());

        System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
        System.assert(it.Type__c == 'Sales Order Undo Pick', it);
        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
        System.assert(it.Quantity__c == 10, it);
        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Finalized__c == true, it);
        System.assert(it.Inventory_Change__c != null, it);
        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
        System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
        System.assert(it.To_Facility__c == it.From_Facility__c, it);
        System.assert(it.To_Location__c == fuel.location2.Id, it);
        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
        System.assert(it.Container_Item__c == it.Item__c, it);
        System.assert(it.From_SKID__c == null, it);

        System.assert(it.To_SKID__c != null, it);
        System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
        System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Quantity__c == 10, it.To_SKID__r);
        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
        System.assert(it.To_SKID__r.Location__c == fuel.location2.Id, it.To_SKID__r);
        System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);

        System.assert(it.Shipment_Line__r.Quantity_Allocated__c == 10, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
        System.assert(it.Sales_Order_Line__r.Quantity_Allocated__c == 10, it.Sales_Order_Line__r);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Name' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c IN (\'' + SkidService3.SKID_TYPE_PLANNED + '\', \'' + SkidService3.SKID_TYPE_ALLOCATED + '\')');
        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 1, skids);
    }
    private static testMethod void noAttributes_UndoPickConsignedInventory() {
        fuel.setupInventory();
        
        Sales_Order__c so = fuel.packageSalesOrder;
        List<SKID__c> skidlist = new List<SKID__c>();
        for(SKID__c sk:fuel.skids){
        	if(sk.Item__c == fuel.itemList[14].ID && sk.Type__c == 'Location'){
        		sk.Consigned_Owner__c = fuel.supplier.id;
	            sk.Purchase_Order_Line__c = fuel.purchaseOrderLines[0].Id;
	            skidlist.add(sk);
        	}
            
        }
        update skidlist;
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
        Test.startTest();
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
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 0, skid);
        System.assert(skid.Quantity_Available__c == 10, skid);
        
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        
        JsonResult result = ShipmentWorkbenchExt.save(wrappers, 'pick');
        System.assert(result.success, result);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c','Consigned_Owner__c','Purchase_Order_Line__c',

            'Item__r.Stocking_UOM__c','Sales_Order_Line__r.Ship_From_Location__r.Name',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c','Shipment_Line__r.Sales_Order_Line__c',
            'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\'');

        List<Inventory_Transaction__c> itlist = Database.query(itQuery.getQuery());
		system.assert(itlist.size()==2,itlist);
		
		for (Inventory_Transaction__c it:itList) {
			if (it.Type__c == 'Sales Order Pick') {
				System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
		        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
		        System.assert(it.Quantity__c == 10, it);
		        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
		        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
		        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Finalized__c == true, it);
		        System.assert(it.Inventory_Change__c != null, it);
		        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
		        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
		        System.assert(it.To_Facility__c == it.From_Facility__c, it);
		        System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
		        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Container_Item__c == it.Item__c, it);
		
		        System.assert(it.From_SKID__c != null, it);
		        System.assert(it.From_SKID__r.Quantity__c == 90, it.From_SKID__r);
		        System.assert(it.From_SKID__r.Quantity_Stocking_UOM__c == it.From_SKID__r.Quantity__c, it.From_SKID__r);
		
		        System.assert(it.To_SKID__c != null, it);
		        System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity__c == 10, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Location__c == it.Shipment_Line__r.Location__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Shipment_Line__c == it.Shipment_Line__c, it.To_SKID__r);
		
		        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
						
			}
			else if(it.Type__c != 'Transfer Of Ownership'){
                 System.assert(false,'Unexpected IT type: ' + it.Type__c);
            }
		}
		
        
        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 10, skid);
        System.assert(skid.Quantity_Available__c == 0, skid);
        
        skid.Quantity_to_Issue__c = -10;
        skid.Input_Quantity__c = -10;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');

        ShipmentInventoryService.pick(wrappers);

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Sales Order Pick\' AND Type__c !=\'Transfer Of Ownership\'');

        List<Inventory_Transaction__c> itUndoPicklist = Database.query(itQuery.getQuery());
		system.assert(itUndoPicklist.size()==2,itUndoPicklist);
		Boolean UndoTransferIT = false;
		for (Inventory_Transaction__c it:itUndoPicklist) {
			if (it.Type__c == 'Sales Order Undo Pick'){
				System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
		        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
		        System.assert(it.Quantity__c == 10, it);
		        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
		        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
		        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Finalized__c == true, it);
		        System.assert(it.Inventory_Change__c != null, it);
		        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
		        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
		        System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
		        System.assert(it.To_Facility__c == it.From_Facility__c, it);
		        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Container_Item__c == it.Item__c, it);
		        System.assert(it.From_SKID__c == null, it);
		
		        System.assert(it.To_SKID__c != null, it);
		        System.assert(it.To_SKID__r.Quantity__c == 100, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
		
		        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 10, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
		        
			}
			else if (it.Type__c == 'Undo Transfer Of Ownership'){
                UndoTransferIT = true;
                System.assert(it.Consigned_Owner__c ==fuel.supplier.id);
                System.assert(it.Purchase_Order_Line__c != null,it);
                System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
		        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
		        System.assert(it.Quantity__c == 10, it);
		        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
		        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
		        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Finalized__c == true, it);
		        System.assert(it.Inventory_Change__c != null, it);
		        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
		        System.assert(it.From_Location__c == fuel.location3.Id,it);
                System.assert(it.To_Location__c == fuel.location3.Id,it);
		        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
		        //System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it.Sales_Order_Line__r.Ship_From_Location__r);
		        //System.assert(it.To_Location__c == it.Sales_Order_Line__r.Ship_From_Location__c,it);
		        System.assert(it.To_Facility__c == it.From_Facility__c, it);
		        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Container_Item__c == it.Item__c, it);
		        System.assert(it.From_SKID__c == null, it);
		
		        System.assert(it.To_SKID__c != null, it);
		        System.assert(it.To_SKID__r.Quantity__c == 100, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
		
		        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 10, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
            }
            else {
                System.assert(false,'Unexpected IT type: ' +it.Type__c);
            }
				
		}
        system.assert(UndoTransferIT==true);
        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 1,skids);

        skid = skids[0];
        System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
        System.assert(skid.Quantity__c == 10, skid);
        System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
        System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
        System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Container_Item__c == skid.Item__c, skid);
        System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
        System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 10, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_Picked__c == 0, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        
    }
    
    private static testMethod void serials_Consigned() {
        fuel.setupInventory(true, true);

        Sales_Order__c so = fuel.packageSalesOrder;
		List<SKID__c> skidlist = new List<SKID__c>();
        for(SKID__c sk:fuel.skids){
        	if(sk.Item__c == fuel.itemList[14].ID && sk.Type__c == 'Location'){
        		sk.Consigned_Owner__c = fuel.supplier.id;
            	sk.Purchase_Order_Line__c = fuel.purchaseOrderLines[0].Id;
            	skidlist.add(sk);
        	}
            
        }
        update skidlist;
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
        
        Test.startTest();
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
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 0, skid);
        System.assert(skid.Quantity_Available__c == 10, skid);
        
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        for (Integer i = 0; i < 10; i++) wrapper.serialWrappers[0].serialList[i].Temporary_Value_Holder__c = 'Pick';
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        ShipmentInventoryService.pick(wrappers);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c','To_Facility__r.Name', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c','To_Location__r.Facility__c',

            'Item__r.Stocking_UOM__c','Consigned_Owner__c','Purchase_Order_Line__c','From_Facility__r.Name',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c','Shipment_Line__r.Sales_Order_Line__c',
            'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery, 'Serial_Transactions__r');
        stQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Facility__c', 'Item__c', 'Serial__c', 'Serial_Parent__c', 'Type__c',

            'Serial__r.Allocated_SKID__c', 'Serial__r.Allow_Reentry__c', 'Serial__r.Company__c', 'Serial__r.Item__c', 'Serial__r.SKID__c' });
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itlist = Database.query(itQuery.getQuery());
        system.assert(itlist.size()==2,itlist);
		for(Inventory_Transaction__c it:itlist){
			if(it.Type__c == 'Sales Order Pick'){
				System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
		        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
		        System.assert(it.Quantity__c == 10, it);
		        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
		        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
		        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Finalized__c == true, it);
		        System.assert(it.Inventory_Change__c != null, it);
		        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
		        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
		        System.assert(it.To_Facility__c == it.From_Facility__c, it);
		        System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
		        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Container_Item__c == it.Item__c, it);
		        System.assert(it.From_SKID__c == null, it);
		
		        System.assert(it.To_SKID__c != null, it);
		        System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity__c == 10, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Location__c == it.Shipment_Line__r.Location__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Shipment_Line__c == it.Shipment_Line__c, it.To_SKID__r);
		
		        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
		
		        System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r);
		        for (Serial_Transaction__c st:it.Serial_Transactions__r) {
		            System.assert(st.Company__c == it.Company__c, st);
		            System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
		            System.assert(st.Item__c == it.Item__c, st);
		            System.assert(st.Serial__c != null, st);
		            System.assert(st.Serial_Parent__c == null, st);
		            System.assert(st.Type__c == 'Pick', st);
		            System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
		            System.assert(st.Serial__r.Allow_Reentry__c == false, st.Serial__r);
		            System.assert(st.Serial__r.Company__c == it.Company__c, st.Serial__r);
		            System.assert(st.Serial__r.Item__c == it.Item__c, st.Serial__r);
		            System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
		        }
			}
			else if(it.Type__c != 'Transfer Of Ownership'){
                 System.assert(false,'Unexpected IT type: ' + it.Type__c);
            }
		}
        

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery, 'Allocated_Serials__r');
        serialQuery.addField('Id');
        skidQuery.addChildRelationship(serialQuery);

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 10, skid);
        System.assert(skid.Quantity_Available__c == 0, skid);
        
        skid.Quantity_to_Issue__c = -10;
        skid.Input_Quantity__c = -10;
        for (Serial__c serial:wrapper.serialWrappers[0].serialList) {
            if (serial.Temporary_Value_Holder__c == 'Picked') serial.Temporary_Value_Holder__c = 'Unpick';
        }
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');

        ShipmentInventoryService.pick(wrappers);

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Sales Order Pick\' AND Type__c !=\'Transfer Of Ownership\'');

        List<Inventory_Transaction__c>undoITs = Database.query(itQuery.getQuery());
        Boolean UndoTransferIT = false;
		for(Inventory_Transaction__c it:undoITs){
			if(it.Type__c == 'Sales Order Undo Pick'){
				System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
		        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
		        System.assert(it.Quantity__c == 10, it);
		        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
		        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
		        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Finalized__c == true, it);
		        System.assert(it.Inventory_Change__c != null, it);
		        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
		        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
		        System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
		        System.assert(it.To_Facility__c == it.From_Facility__c, it);
		        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Container_Item__c == it.Item__c, it);
		        System.assert(it.From_SKID__c == null, it);
		
		        System.assert(it.To_SKID__c != null, it);
		        System.assert(it.To_SKID__r.Quantity__c == 10, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
		
		        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 10, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
		
		        System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r);
		        for (Serial_Transaction__c st:it.Serial_Transactions__r) {
		            System.assert(st.Company__c == it.Company__c, st);
		            System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
		            System.assert(st.Item__c == it.Item__c, st);
		            System.assert(st.Serial__c != null, st);
		            System.assert(st.Serial_Parent__c == null, st);
		            System.assert(st.Type__c == 'Undo Pick', st);
		            System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
		            System.assert(st.Serial__r.Allow_Reentry__c == false, st.Serial__r);
		            System.assert(st.Serial__r.Company__c == it.Company__c, st.Serial__r);
		            System.assert(st.Serial__r.Item__c == it.Item__c, st.Serial__r);
		            System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
		        }
		        
			}
			else if(it.Type__c == 'Undo Transfer Of Ownership'){
				UndoTransferIT = true;
				System.assert(it.Consigned_Owner__c ==fuel.supplier.id);
                System.assert(it.Purchase_Order_Line__c != null,it);
				System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
		        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
		        System.assert(it.Quantity__c == 10, it);
		        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
		        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
		        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Finalized__c == true, it);
		        System.assert(it.Inventory_Change__c != null, it);
		        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
		        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
		        System.assert(it.From_Location__c == fuel.location3.Id,it);
                System.assert(it.To_Location__c == fuel.location3.Id,it);
                System.assert(it.From_Facility__c == it.To_Location__r.Facility__c, it.From_Facility__r+'To Facility:'+it.To_Facility__r);
		        
		        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it.To_Facility__r);
		        System.assert(it.Container_Item__c == it.Item__c, it);
		        System.assert(it.From_SKID__c == null, it);
				System.assert(it.To_SKID__c != null, it);
		        System.assert(it.To_SKID__r.Quantity__c == 10, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
		
		        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 10, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
		
		        System.assert(it.Serial_Transactions__r.size() == it.Quantity__c, it.Serial_Transactions__r);
		        for (Serial_Transaction__c st:it.Serial_Transactions__r) {
		            System.assert(st.Company__c == it.Company__c, st);
		            System.assert(st.Facility__c == it.Shipment_Line__r.Facility__c, st);
		            System.assert(st.Item__c == it.Item__c, st);
		            System.assert(st.Serial__c != null, st);
		            System.assert(st.Serial_Parent__c == null, st);
		            System.assert(st.Type__c == 'Undo Transfer of Ownership', st);
		            System.assert(st.Serial__r.Allocated_SKID__c == null, st.Serial__r);
		            System.assert(st.Serial__r.Allow_Reentry__c == false, st.Serial__r);
		            System.assert(st.Serial__r.Company__c == it.Company__c, st.Serial__r);
		            System.assert(st.Serial__r.Item__c == it.Item__c, st.Serial__r);
		            System.assert(st.Serial__r.SKID__c == it.To_SKID__c, st.Serial__r);
		        }
		        
			}
		}
		
		skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 1,skids);

        skid = skids[0];
        System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
        System.assert(skid.Quantity__c == 10, skid);
        System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
        System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
        System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Container_Item__c == skid.Item__c, skid);
        System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
        System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 10, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_Picked__c == 0, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        
    }
    
    private static testMethod void attributes_UndoPick_Consigned() {
        fuel.setupInventory(true);

        Sales_Order__c so = fuel.packageSalesOrder;
        List<SKID__c> skidlist = new List<SKID__c>();
        for(SKID__C sk:fuel.skids){
        	if(sk.Item__c == fuel.itemList[14].ID && sk.Type__c == 'Location'){
        		sk.Consigned_Owner__c = fuel.supplier.id;
	            sk.Purchase_Order_Line__c = fuel.purchaseOrderLines[0].Id;
	            skidlist.add(sk);
        	}
            
        }
        update skidlist;

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
        Test.startTest();
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 0, skid);
        System.assert(skid.Quantity_Available__c == 10, skid);
        
        skid.Quantity_to_Issue__c = 10;
        skid.Input_Quantity__c = 10;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');

        ShipmentInventoryService.pick(wrappers);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',

            'Item__r.Stocking_UOM__c','Consigned_Owner__c','Purchase_Order_Line__c','To_Location__r.Facility__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c','Shipment_Line__r.Sales_Order_Line__c',
            'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\'');

        
		List<Inventory_Transaction__c>itList = Database.query(itQuery.getQuery());
		system.assert(itlist.size()==2,itlist);
		for(Inventory_Transaction__c it:itList){
			if (it.Type__c == 'Sales Order Pick') {
				System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
		        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
		        System.assert(it.Quantity__c == 10, it);
		        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
		        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
		        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Finalized__c == true, it);
		        System.assert(it.Inventory_Change__c != null, it);
		        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
		        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
		        System.assert(it.To_Facility__c == it.From_Facility__c, it);
		        System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
		        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Container_Item__c == it.Item__c, it);
		
		        System.assert(it.From_SKID__c != null, it);
		        System.assert(it.From_SKID__r.Quantity__c == 90, it.From_SKID__r);
		        System.assert(it.From_SKID__r.Quantity_Stocking_UOM__c == it.From_SKID__r.Quantity__c, it.From_SKID__r);
		
		        System.assert(it.To_SKID__c != null, it);
		        System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity__c == 10, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Location__c == it.Shipment_Line__r.Location__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Shipment_Line__c == it.Shipment_Line__c, it.To_SKID__r);
		
		        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 0, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 10, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
			}
			else if(it.Type__c != 'Transfer Of Ownership'){
                 System.assert(false,'Unexpected IT type: ' + it.Type__c);
            }
		}
        

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Picked__c',
            'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 10, skid);
        System.assert(skid.Quantity_Available__c == 0, skid);
        
        skid.Quantity_to_Issue__c = -10;
        skid.Input_Quantity__c = -10;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');

        ShipmentInventoryService.pick(wrappers);

        itQuery.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c != \'Sales Order Pick\' AND Type__c !=\'Transfer Of Ownership\'');

        List<Inventory_Transaction__c>undoITList = Database.query(itQuery.getQuery());
		
		Boolean UndoTransferIT = false;
		for (Inventory_Transaction__c it:undoITList) {
			if (it.Type__c == 'Sales Order Undo Pick'){
				System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
		        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
		        System.assert(it.Quantity__c == 10, it);
		        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
		        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
		        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Finalized__c == true, it);
		        System.assert(it.Inventory_Change__c != null, it);
		        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
		        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
		        System.assert(it.From_Location__c == it.Shipment_Line__r.Location__c, it);
		        System.assert(it.To_Facility__c == it.From_Facility__c, it);
		        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Container_Item__c == it.Item__c, it);
		        System.assert(it.From_SKID__c == null, it);
		
		        System.assert(it.To_SKID__c != null, it);
		        System.assert(it.To_SKID__r.Quantity__c == 100, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
		
		        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 10, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
		        
		        
			}
			else if (it.Type__c == 'Undo Transfer Of Ownership'){
                UndoTransferIT = true;
                System.assert(it.Consigned_Owner__c ==fuel.supplier.id);
                System.assert(it.Purchase_Order_Line__c != null,it);
                System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
		        System.assert(it.Quantity__c == 10, it);
		        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
		        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
		        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Finalized__c == true, it);
		        System.assert(it.Inventory_Change__c != null, it);
		        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
		        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
		        System.assert(it.From_Location__c == fuel.location3.Id,it);
                System.assert(it.To_Location__c == fuel.location3.Id,it);
		        System.assert(it.To_Facility__c == it.From_Facility__c, it);
		        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Container_Item__c == it.Item__c, it);
		        System.assert(it.From_SKID__c == null, it);
		
		        System.assert(it.To_SKID__c != null, it);
		        System.assert(it.To_SKID__r.Quantity__c == 100, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
		
		        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 10, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 0, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, it.Shipment_Line__r.Shipment__r);
		        
			}
		}
        
		skids = Database.query(skidQuery.getQuery());
		System.assert(skids.size() == 1,skids);
        skid = skids[0];
        System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
        System.assert(skid.Quantity__c == 10, skid);
        System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
        System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
        System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Container_Item__c == skid.Item__c, skid);
        System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
        System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 10, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_Picked__c == 0, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        
        //Pick Again
        
        
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');
        
        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        skid = wrapper.serialWrappers[0].skid;
        System.assert(skid.Quantity_Used__c == 0, skid);
        System.assert(skid.Quantity_Available__c == 10, skid);
        
        skid.Quantity_to_Issue__c = 8;
        skid.Input_Quantity__c = 8;
        skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        ShipmentInventoryService.pick(wrappers);

        SOQLUtil itQuery1 = new SOQLUtil('Inventory_Transaction__c');
        itQuery1.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Finalized__c', 'From_Facility__c', 'From_Location__c', 'From_SKID__c',
            'From_Packaging_UOM__c', 'Inventory_Change__c', 'Item__c', 'Packaging_UOM__c', 'Quantity__c', 'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c',
            'Shipment_Line__c', 'Stocking_UOM__c', 'To_Facility__c', 'To_Location__c', 'To_SKID__c', 'Type__c',

            'From_SKID__r.Quantity__c', 'From_SKID__r.Quantity_Stocking_UOM__c',

            'Item__r.Stocking_UOM__c','Consigned_Owner__c','Purchase_Order_Line__c','To_Location__r.Facility__c',

            'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Item__c',
            'Shipment_Line__r.Quantity_Picked__c', 'Shipment_Line__r.Quantity_To_Pick__c','Shipment_Line__r.Sales_Order_Line__c',
            'Shipment_Line__r.Shipment__r.Status__c',

            'To_SKID__r.Company__c', 'To_SKID__r.Container_Item__c', 'To_SKID__r.Facility2__c', 'To_SKID__r.Item__c', 'To_SKID__r.Location__c',
            'To_SKID__r.Packaging_UOM__c', 'To_SKID__r.Quantity__c', 'To_SKID__r.Quantity_Stocking_UOM__c', 'To_SKID__r.Shipment_Line__c', 'To_SKID__r.Stocking_UOM__c',
            'To_SKID__r.Type__c' });
        itQuery1.setWhereClause('Shipment_Line__r.Shipment__c  = \'' + shipment.Id + '\' AND Type__c = \'Sales Order Pick\'');
		
        
		List<Inventory_Transaction__c>itList1 = Database.query(itQuery1.getQuery());
		system.assert(itlist.size()==2,itlist1);
		for(Inventory_Transaction__c it:itList){
			if (it.Type__c == 'Sales Order Pick' && it.Quantity__c == 8) {
				System.assert(it.Company__c == it.Shipment_Line__r.Company__c, it);
		        System.assert(it.Item__c == it.Shipment_Line__r.Item__c, it);
		        System.assert(it.Quantity__c == 8, it);
		        System.assert(it.Quantity_Stocking_UOM__c == it.Quantity__c, it);
		        System.assert(it.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it);
		        System.assert(it.Stocking_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Finalized__c == true, it);
		        System.assert(it.Inventory_Change__c != null, it);
		        System.assert(it.Sales_Order_Line__c == it.Shipment_Line__r.Sales_Order_Line__c, it);
		        System.assert(it.From_Facility__c == it.Shipment_Line__r.Facility__c, it);
		        System.assert(it.To_Facility__c == it.From_Facility__c, it);
		        System.assert(it.To_Location__c == it.Shipment_Line__r.Location__c, it);
		        System.assert(it.From_Packaging_UOM__c == it.Packaging_UOM__c, it);
		        System.assert(it.Container_Item__c == it.Item__c, it);
		
		        System.assert(it.From_SKID__c != null, it);
		        System.assert(it.From_SKID__r.Quantity__c == 92, it.From_SKID__r);
		        System.assert(it.From_SKID__r.Quantity_Stocking_UOM__c == it.From_SKID__r.Quantity__c, it.From_SKID__r);
		
		        System.assert(it.To_SKID__c != null, it);
		        System.assert(it.To_SKID__r.Company__c == it.Shipment_Line__r.Company__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Item__c == it.Shipment_Line__r.Item__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity__c == 8, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Quantity_Stocking_UOM__c == it.To_SKID__r.Quantity__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Packaging_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Stocking_UOM__c == it.Item__r.Stocking_UOM__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Facility2__c == it.Shipment_Line__r.Facility__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Location__c == it.Shipment_Line__r.Location__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Container_Item__c == it.To_SKID__r.Item__c, it.To_SKID__r);
		        System.assert(it.To_SKID__r.Shipment_Line__c == it.Shipment_Line__c, it.To_SKID__r);
		
		        System.assert(it.Shipment_Line__r.Quantity_To_Pick__c == 2, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Quantity_Picked__c == 8, it.Shipment_Line__r);
		        System.assert(it.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED, it.Shipment_Line__r.Shipment__r);
			}
		}
    }

    private static testMethod void pack() {
        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        Sales_Order_Line__c sol = fuel.packageSalesOrder.Sales_Order_Lines__r[0];

        insert new User_Preference__c(Default_Company__c = sol.Company__c, Default_Facility__c = fuel.facility2.Id, User__c = UserInfo.getUserId());

        update new Location__c(Id = sol.Ship_From_Location__c, Bin_Tracked__c = true);
        Bin__c bin = new Bin__c(Name = 'Bin', Location__c = sol.Ship_From_Location__c);
        insert bin;
        bin = BaseController.getBin(bin.Id);

        fuel.setupInventory(true, false, true);
        delete [SELECT Id FROM Item_Attribute__c WHERE License_Plate_Number__c != true];
        delete [SELECT Id FROM Lot__c];
        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Item__c = :fuel.itemList[14].Id];
        for (SKID__c skid:skids) {
            skid.Expiration_Date__c = null;
            skid.Lot_Number__c = null;
        }
        update skids;

        delete c;

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        wrappers[0].line = shipmentLines.get(wrappers[0].line.Id);
        wrappers[0].header = wrappers[0].line.getSObject('Shipment__r');
        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
        }
        AllocationService.allocate(wrappers);
        Test.startTest();
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        LineWrapper shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (wrapper.uom == 'PT') sw.skid.Quantity_to_Issue__c = 1;
                else if (wrapper.uom == 'CS') sw.skid.Quantity_to_Issue__c = 2;
                else sw.skid.Quantity_to_Issue__c = 0;
                sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                shlWrapper.serialWrappers.add(sw);
            }
        }
        
        

        ShipmentInventoryService.plan(new List<LineWrapper>{ shlWrapper });
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (wrapper.uom == 'PT' || wrapper.uom == 'CS') sw.skid.Quantity_to_Issue__c = 1;
                else sw.skid.Quantity_to_Issue__c = 0;
                sw.toskid = new SKID__c(Bin__c = bin.Id, Bin__r = bin, License_Plate_Number__r = new LPN__c(Name = 'PACKLPN'));
                sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                shlWrapper.serialWrappers.add(sw);
            }
        }
        ShipmentInventoryService.pick(new List<LineWrapper>{ shlWrapper });

        

        List<Inventory_Transaction__c> itList = [SELECT Id FROM Inventory_Transaction__c WHERE Type__c = 'Sales Order Pick'];
        System.assert(itList.size() == 3, itList.size());
        Test.stopTest();
        itList = [SELECT Id FROM Inventory_Transaction__c WHERE Type__c = 'Transfer'];
        System.assert(itList.size() == 2, itList.size());

        skids = [SELECT Id FROM SKID__c WHERE Shipment_Line__c != null];
        System.assert(skids.size() == 2, skids.size());

        skids = [SELECT Id FROM SKID__c WHERE Mixed_Palletized__c = true];
        System.assert(skids.size() == 1, skids.size());
    }
}