@isTest
private class ShipmentPlanPickTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.itemAttrObj2 != null);

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
        for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);
        
        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);

        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Used__c == 0, wrapper.serialWrappers[0]);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Available__c == 10, wrapper.serialWrappers[0]);
        
        wrapper.serialWrappers[0].skid.Quantity_to_Issue__c = 10;
        wrapper.serialWrappers[0].skid.Input_Quantity__c = 10;
        
        Test.startTest();
        
        JsonResult result = ShipmentWorkbenchExt.save(wrappers, 'planpick');
        System.assert(result.success, result);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Allocated__c',
            'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c',
            'Shipment_Line__r.Shipment__c','Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\'');

        SKID__c skid = Database.query(skidQuery.getQuery());

        System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
        System.assert(skid.Type__c == SkidService3.SKID_TYPE_PLANNED, skid);
        System.assert(skid.Quantity__c == 10, skid);
        System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
        System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
        System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Container_Item__c == skid.Item__c, skid);
        System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
        System.assert(skid.Shipment_Line__r.Shipment__c == shipment.Id, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 0, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 10, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());

        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');

        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Used__c == 10, wrapper.serialWrappers[0]);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Available__c == 0, wrapper.serialWrappers[0]);

        wrapper.serialWrappers[0].skid.Quantity_to_Issue__c = -10;
        wrapper.serialWrappers[0].skid.Input_Quantity__c = -10;
        wrapper.serialWrappers[0].skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');

        ShipmentInventoryService.plan(wrappers);

        skid = Database.query(skidQuery.getQuery());

        System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
        System.assert(skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED, skid);
        System.assert(skid.Quantity__c == 10, skid);
        System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
        System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
        System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Container_Item__c == skid.Item__c, skid);
        System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
        System.assert(skid.Shipment_Line__r.Shipment__c == shipment.Id, skid.Shipment_Line__r);
        System.assert(skid.Sales_Order_Line__c == skid.Shipment_Line__r.Sales_Order_Line__c, skid);
        System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 10, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 0, skid.Shipment_Line__r);
        System.assert(skid.Sales_Order_Line__r.Quantity_Allocated__c == 10, skid.Sales_Order_Line__r);
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
        for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');

        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Used__c == 0, wrapper.serialWrappers[0]);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Available__c == 10, wrapper.serialWrappers[0]);

        wrapper.serialWrappers[0].skid.Quantity_to_Issue__c = 10;
        wrapper.serialWrappers[0].skid.Input_Quantity__c = 10;
        wrapper.serialWrappers[0].skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        Test.startTest();
        
        ShipmentInventoryService.plan(wrappers);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Allocated__c',
            'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c',
            'Shipment_Line__r.Shipment__c','Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\'');

        SKID__c skid = Database.query(skidQuery.getQuery());

        System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
        System.assert(skid.Type__c == SkidService3.SKID_TYPE_PLANNED, skid);
        System.assert(skid.Quantity__c == 10, skid);
        System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
        System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
        System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Container_Item__c == skid.Item__c, skid);
        System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
        System.assert(skid.Shipment_Line__r.Shipment__c == shipment.Id, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 0, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 10, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());

        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');

        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Used__c == 10, wrapper.serialWrappers[0]);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Available__c == 0, wrapper.serialWrappers[0]);

        wrapper.serialWrappers[0].skid.Quantity_to_Issue__c = -10;
        wrapper.serialWrappers[0].skid.Input_Quantity__c = -10;
        wrapper.serialWrappers[0].skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');

        ShipmentInventoryService.plan(wrappers);

        skid = Database.query(skidQuery.getQuery());

        System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
        System.assert(skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED, skid);
        System.assert(skid.Quantity__c == 10, skid);
        System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
        System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
        System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Container_Item__c == skid.Item__c, skid);
        System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
        System.assert(skid.Shipment_Line__r.Shipment__c == shipment.Id, skid.Shipment_Line__r);
        System.assert(skid.Sales_Order_Line__c == skid.Shipment_Line__r.Sales_Order_Line__c, skid);
        System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 10, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 0, skid.Shipment_Line__r);
        System.assert(skid.Sales_Order_Line__r.Quantity_Allocated__c == 10, skid.Sales_Order_Line__r);
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
        for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');

        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Used__c == 0, wrapper.serialWrappers[0]);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Available__c == 10, wrapper.serialWrappers[0]);

        wrapper.serialWrappers[0].skid.Quantity_to_Issue__c = 10;
        wrapper.serialWrappers[0].skid.Input_Quantity__c = 10;
        wrapper.serialWrappers[0].serialList[0].Temporary_Value_Holder__c = 'Plan';
        wrapper.serialWrappers[0].skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        Test.startTest();
        
        ShipmentInventoryService.plan(wrappers);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Allocated__c',
            'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c',
            'Shipment_Line__r.Shipment__c','Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\'');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery, 'Allocated_Serials__r');
        serialQuery.addFields(new Set<String>{ 'Id', 'Allow_Reentry__c', 'Company__c', 'Item__c', 'SKID__c' });
        skidQuery.addChildRelationship(serialQuery);

        SKID__c skid = Database.query(skidQuery.getQuery());

        System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
        System.assert(skid.Type__c == SkidService3.SKID_TYPE_PLANNED, skid);
        System.assert(skid.Quantity__c == 10, skid);
        System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
        System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
        System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Container_Item__c == skid.Item__c, skid);
        System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
        System.assert(skid.Shipment_Line__r.Shipment__c == shipment.Id, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 0, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 10, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);
        System.assert(skid.Allocated_Serials__r.size() == 1, skid.Allocated_Serials__r);
        System.assert(skid.Allocated_Serials__r[0].Allow_Reentry__c == false, skid.Allocated_Serials__r[0]);
        System.assert(skid.Allocated_Serials__r[0].Company__c == skid.Shipment_Line__r.Company__c, skid.Allocated_Serials__r[0]);
        System.assert(skid.Allocated_Serials__r[0].Item__c == skid.Item__c, skid.Allocated_Serials__r[0]);
        System.assert(skid.Allocated_Serials__r[0].SKID__c != null, skid.Allocated_Serials__r[0]);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());

        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');

        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Used__c == 10, wrapper.serialWrappers[0]);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Available__c == 0, wrapper.serialWrappers[0]);

        wrapper.serialWrappers[0].skid.Quantity_to_Issue__c = -10;
        wrapper.serialWrappers[0].skid.Input_Quantity__c = -10;
        wrapper.serialWrappers[0].serialList[0].Temporary_Value_Holder__c = 'Unplan';
        wrapper.serialWrappers[0].skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');

        ShipmentInventoryService.plan(wrappers);

        skid = Database.query(skidQuery.getQuery());

        System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
        System.assert(skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED, skid);
        System.assert(skid.Quantity__c == 10, skid);
        System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
        System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
        System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
        System.assert(skid.Container_Item__c == skid.Item__c, skid);
        System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
        System.assert(skid.Shipment_Line__r.Shipment__c == shipment.Id, skid.Shipment_Line__r);
        System.assert(skid.Sales_Order_Line__c == skid.Shipment_Line__r.Sales_Order_Line__c, skid);
        System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 10, skid.Shipment_Line__r);
        System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 0, skid.Shipment_Line__r);
        System.assert(skid.Sales_Order_Line__r.Quantity_Allocated__c == 10, skid.Sales_Order_Line__r);
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
        for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Input_Quantity__c = 5;
                for (Integer i = 0; i < 5; i++) sw.serialList[i].Temporary_Value_Holder__c = 'Allocate';
            } else {
                sw.skid.Input_Quantity__c = 0;
            }
            sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');

        System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Used__c == 0, wrapper.serialWrappers[0]);
        System.assert(wrapper.serialWrappers[0].skid.Quantity_Available__c == 5, wrapper.serialWrappers[0]);

        wrapper.serialWrappers[0].skid.Quantity_to_Issue__c = 10;
        wrapper.serialWrappers[0].skid.Input_Quantity__c = 10;
        wrapper.serialWrappers[0].skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        
        Test.startTest();

        try {
            ShipmentInventoryService.plan(wrappers);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }

        wrapper.serialWrappers[0].skid.Quantity_to_Issue__c = 5;
        wrapper.serialWrappers[0].skid.Input_Quantity__c = 5;
        for (Serial__c serial:wrapper.serialWrappers[0].serialList) {
            if (serial.Allocated_SKID__c != null) serial.Temporary_Value_Holder__c = 'Allocated';
            else serial.Temporary_Value_Holder__c = 'Plan';
        }

        try {
            ShipmentInventoryService.plan(wrappers);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }

        wrapper.serialWrappers[0].skid.Quantity_to_Issue__c = 4;
        wrapper.serialWrappers[0].skid.Input_Quantity__c = 4;

        try {
            ShipmentInventoryService.plan(wrappers);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
    }

    private static testMethod void packaging() {
        fuel.setupInventory(true, false, true);

        Sales_Order__c so = fuel.packageSalesOrder;

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);
        
        wrappers[0].line = shipmentLines.get(wrappers[0].line.Id);
        wrappers[0].header = wrappers[0].line.getSObject('Shipment__r');
        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 10;
            else sw.skid.Input_Quantity__c = 0;
            sw.skid.Item__r = (Item__c)wrappers[0].line.getSObject('Item__r');
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 3, wrappers);
        
        LineWrapper shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                SKID__c skid = sw.skid;
                if (wrapper.uom == 'PT') {
                    System.assert(skid.Count_Quantity__c == 6, skid);
                    System.assert(skid.Quantity_Available__c == 6, skid);
                    System.assert(skid.Quantity_Issued__c == 6, skid);   //PT-EA conversion factor

                    skid.Quantity_to_Issue__c = 1; //1 PT
                    skid.Input_Quantity__c = 6;    //6 EA
                } else if (wrapper.uom == 'CS') {
                    System.assert(skid.Count_Quantity__c == 202, skid);
                    System.assert(skid.Quantity_Available__c == 10, skid);
                    System.assert(skid.Quantity_Issued__c == 2, skid);   //CS-EA conversion factor

                    skid.Quantity_to_Issue__c = 1; //1 CS
                    skid.Quantity_to_Return__c = 1; //1 EA
                    skid.Input_Quantity__c = 3;    //3 EA
                } else if (wrapper.uom == 'EA2') {
                    System.assert(skid.Count_Quantity__c == 100, skid);
                    System.assert(skid.Quantity_Available__c == 10, skid);
                    System.assert(skid.Quantity_Issued__c == 1, skid);   //EA-EA conversion factor

                    skid.Quantity_to_Issue__c = 1; //1 EA
                    skid.Input_Quantity__c = 1;    //1 EA
                } else {
                    System.assert(false, 'Invalid UOM: ' + wrapper.uom);
                }

                skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                shlWrapper.serialWrappers.add(sw);
            }
        }
        
        Test.startTest();

        ShipmentInventoryService.plan(new List<LineWrapper>{ shlWrapper });

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Container_Item__r.ExtId__c', 

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Allocated__c',
            'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Quantity_To_Pick__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c',
            'Shipment_Line__r.Shipment__c','Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 3, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Type__c == SkidService3.SKID_TYPE_PLANNED, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Shipment_Line__r.Shipment__c == shipment.Id, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Quantity_To_Pick__c == 10, skid.Shipment_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);

            if (skid.Packaging_UOM__r.Name == 'PT') {
                System.assert(skid.Quantity__c == 1, skid);
                System.assert(skid.Quantity_Stocking_UOM__c == 6, skid);
            } else if (skid.Packaging_UOM__r.Name == 'CS') {
                System.assert(skid.Quantity__c == 1, skid);
                System.assert(skid.Quantity_Stocking_UOM__c == 2, skid);
            } else if (skid.Packaging_UOM__r.Name == 'EA2') {
                System.assert(skid.Quantity__c == 2, skid);
                System.assert(skid.Quantity_Stocking_UOM__c == 2, skid);
            } else {
                System.assert(false, 'Invalid UOM: ' + skid.Packaging_UOM__r.Name);
            }
        }
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        System.assert(wrappers.size() == 3, wrappers);
        
        shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            SkidService3.SerialWrapper sw = wrapper.serialWrappers[0];
            sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
            if (wrapper.uom == 'PT' || wrapper.uom == 'CS') {
                System.assert(sw.skid.Quantity_Used__c == 1, sw.skid);
                if (wrapper.uom == 'PT') {
                    sw.skid.Quantity_to_Issue__c = -1; //-1 PT
                    sw.skid.Input_Quantity__c = -6;    //-6 EA
                } else if (wrapper.uom == 'CS') {
                    sw.skid.Quantity_to_Issue__c = -1; //-1 CS
                    sw.skid.Input_Quantity__c = -2;    //-2 EA
                }
                shlWrapper.serialWrappers.add(sw);
            } else if (wrapper.uom == 'EA2') {
                System.assert(sw.skid.Quantity_Used__c == 2, sw.skid);
                sw.skid.Quantity_to_Issue__c = -2; //-1 EA
                sw.skid.Input_Quantity__c = -2;    //-1 EA
                shlWrapper.serialWrappers.add(sw);
            } else {
                System.assert(false, 'Invalid UOM: ' + wrapper.uom);
            }
        }

        ShipmentInventoryService.plan(new List<LineWrapper>{ shlWrapper });

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 1, skids);

        System.assert(skids[0].Company__c == skids[0].Shipment_Line__r.Company__c, skids[0]);
        System.assert(skids[0].Type__c == SkidService3.SKID_TYPE_ALLOCATED, skids[0]);
        System.assert(skids[0].Quantity__c == 10, skids[0]);
        System.assert(skids[0].Quantity_Stocking_UOM__c == skids[0].Quantity__c, skids[0]);
        System.assert(skids[0].Item__c == skids[0].Shipment_Line__r.Item__c, skids[0]);
        System.assert(skids[0].Packaging_UOM__c == skids[0].Item__r.Stocking_UOM__c, skids[0]);
        System.assert(skids[0].Stocking_UOM__c == skids[0].Item__r.Stocking_UOM__c, skids[0]);
        System.assert(skids[0].Container_Item__c == skids[0].Item__c, skids[0]);
        System.assert(skids[0].Facility2__c == skids[0].Shipment_Line__r.Facility__c, skids[0]);
        System.assert(skids[0].Shipment_Line__r.Shipment__c == shipment.Id, skids[0].Shipment_Line__r);
        System.assert(skids[0].Sales_Order_Line__c == skids[0].Shipment_Line__r.Sales_Order_Line__c, skids[0]);
        System.assert(skids[0].Shipment_Line__r.Quantity_Allocated__c == 10, skids[0].Shipment_Line__r);
        System.assert(skids[0].Shipment_Line__r.Quantity_To_Pick__c == 0, skids[0].Shipment_Line__r);
        System.assert(skids[0].Sales_Order_Line__r.Quantity_Allocated__c == 10, skids[0].Sales_Order_Line__r);
        System.assert(skids[0].Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skids[0].Shipment_Line__r.Shipment__r);
    }
    
    private static testMethod void optimizedPlan1() {
        delete [SELECT Id FROM Item_Attribute__c];
        
        Item__c item = fuel.itemList[14];
        List<SKID__c> skids = new List<SKID__c>();
        SKID__c skid = new SKID__c(
            Company__c = item.Company__c,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Stocking_UOM__c = item.Stocking_UOM__c,
            Item__c = item.Id,
            Facility2__c = fuel.location3.Facility__c,
            Location__c = fuel.location3.Id
        );
        
        SKID__c pallet = skid.clone(false, true);
        pallet.Quantity__c = 1;
        pallet.Quantity_Stocking_UOM__c = 6;
        pallet.Packaging_UOM__c = fuel.uomList[13].Id;
        pallet.Container_Item__c = fuel.itemList[13].Id;
        skids.add(pallet);
        
        SKID__c partPallet = skid.clone(false, true);
        partPallet.Quantity__c = 1;
        partPallet.Quantity_Stocking_UOM__c = 2;
        partPallet.Packaging_UOM__c = fuel.uomList[12].Id;
        partPallet.Container_Item__c = fuel.itemList[13].Id;
        skids.add(partPallet);
        
        SKID__c cs = skid.clone(false, true);
        cs.Quantity__c = 1;
        cs.Quantity_Stocking_UOM__c = 2;
        cs.Packaging_UOM__c = fuel.uomList[12].Id;
        cs.Container_Item__c = fuel.itemList[12].Id;
        skids.add(cs);
        
        insert skids;

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        wrappers[0].line = shipmentLines.get(wrappers[0].line.Id);
        wrappers[0].header = wrappers[0].line.getSObject('Shipment__r');
        AllocationService.allocate(wrappers);
        
        Test.setCurrentPage(Page.ShipmentPlanPickMass);
        ShipmentPlanPick plan = new ShipmentPlanPick(new ApexPages.StandardSetController(new List<Shipment__c>{ shipment }));
        plan.massRedirect();
        
        Test.startTest();
        Test.setCurrentPage(Page.ShipmentPlanPick);
        ApexPages.currentPage().getParameters().put('recs', shipment.Id);
        plan = new ShipmentPlanPick();
        plan.executeBatch();
        Test.stopTest();
        
        skids = [SELECT Id FROM SKID__c WHERE Type__c = :SkidService3.SKID_TYPE_PLANNED];
        System.assert(skids.size() == 2, skids.size());
    }
    
    private static testMethod void optimizedPlan2() {
        delete [SELECT Id FROM Item_Attribute__c];
        
        Item__c item = fuel.itemList[14];
        insert new SKID__c(
            Company__c = item.Company__c,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Stocking_UOM__c = item.Stocking_UOM__c,
            Item__c = item.Id,
            Facility2__c = fuel.location3.Facility__c,
            Location__c = fuel.location3.Id,
            Quantity__c = 10,
            Quantity_Stocking_UOM__c = 10,
            Packaging_UOM__c = item.Stocking_UOM__c,
            Container_Item__c = item.Id
        );

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        wrappers[0].line = shipmentLines.get(wrappers[0].line.Id);
        wrappers[0].header = wrappers[0].line.getSObject('Shipment__r');
        AllocationService.allocate(wrappers);
        
        Test.startTest();
        Test.setCurrentPage(Page.ShipmentPlanPick);
        ApexPages.currentPage().getParameters().put('recs', shipment.Id);
        ShipmentPlanPick plan = new ShipmentPlanPick();
        plan.executeBatch();
        Test.stopTest();
        
        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Type__c = :SkidService3.SKID_TYPE_PLANNED];
        System.assert(skids.size() == 1, skids.size());
    }
    
    private static testMethod void optimizedPlan3() {
        delete [SELECT Id FROM Item_Attribute__c];
        
        UOM_Conversion_Details__c conv = UOM_Conversion_Details__c.getInstance(((String)fuel.uomList[11].Id).substring(3, 15) + ((String)fuel.uomList[12].Id).substring(3, 15));
        conv.UOM_1_Quantity__c = 12;
        update conv;
        
        Item__c item = fuel.itemList[14];
        insert new SKID__c(
            Company__c = item.Company__c,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Stocking_UOM__c = item.Stocking_UOM__c,
            Item__c = item.Id,
            Facility2__c = fuel.location3.Facility__c,
            Location__c = fuel.location3.Id,
            Quantity__c = 1,
            Quantity_Stocking_UOM__c = 12,
            Packaging_UOM__c = fuel.uomList[12].Id,
            Container_Item__c = fuel.itemList[12].Id
        );

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        wrappers[0].line = shipmentLines.get(wrappers[0].line.Id);
        wrappers[0].header = wrappers[0].line.getSObject('Shipment__r');
        AllocationService.allocate(wrappers);
        
        Test.startTest();
        Test.setCurrentPage(Page.ShipmentPlanPick);
        ApexPages.currentPage().getParameters().put('recs', shipment.Id);
        ShipmentPlanPick plan = new ShipmentPlanPick();
        plan.executeBatch();
        Test.stopTest();
        
        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Type__c = :SkidService3.SKID_TYPE_PLANNED];
        System.assert(skids.size() == 1, skids.size());
    }
    
    private static testMethod void optimizedPlan4() {
        delete [SELECT Id FROM Item_Attribute__c];
        
        UOM_Conversion_Details__c conv = UOM_Conversion_Details__c.getInstance(((String)fuel.uomList[11].Id).substring(3, 15) + ((String)fuel.uomList[12].Id).substring(3, 15));
        conv.UOM_1_Quantity__c = 6;
        update conv;
        
        Item__c item = fuel.itemList[14];
        insert new SKID__c(
            Company__c = item.Company__c,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Stocking_UOM__c = item.Stocking_UOM__c,
            Item__c = item.Id,
            Facility2__c = fuel.location3.Facility__c,
            Location__c = fuel.location3.Id,
            Quantity__c = 2,
            Quantity_Stocking_UOM__c = 12,
            Packaging_UOM__c = fuel.uomList[12].Id,
            Container_Item__c = fuel.itemList[13].Id
        );

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        wrappers[0].line = shipmentLines.get(wrappers[0].line.Id);
        wrappers[0].header = wrappers[0].line.getSObject('Shipment__r');
        AllocationService.allocate(wrappers);
        
        Test.startTest();
        Test.setCurrentPage(Page.ShipmentPlanPick);
        ApexPages.currentPage().getParameters().put('recs', shipment.Id);
        ShipmentPlanPick plan = new ShipmentPlanPick();
        plan.executeBatch();
        Test.stopTest();
        
        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Type__c = :SkidService3.SKID_TYPE_PLANNED];
        System.assert(skids.size() == 1, skids.size());
    }
    
    private static testMethod void optimizedPlan6() {
        delete [SELECT Id FROM Item_Attribute__c];
        
        UOM_Conversion_Details__c conv = UOM_Conversion_Details__c.getInstance(((String)fuel.uomList[11].Id).substring(3, 15) + ((String)fuel.uomList[12].Id).substring(3, 15));
        conv.UOM_1_Quantity__c = 6;
        update conv;
        
        Item__c item = fuel.itemList[14];
        insert new SKID__c(
            Company__c = item.Company__c,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Stocking_UOM__c = item.Stocking_UOM__c,
            Item__c = item.Id,
            Facility2__c = fuel.location3.Facility__c,
            Location__c = fuel.location3.Id,
            Quantity__c = 1,
            Quantity_Stocking_UOM__c = 18,
            Packaging_UOM__c = fuel.uomList[13].Id,
            Container_Item__c = fuel.itemList[13].Id
        );

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        wrappers[0].line = shipmentLines.get(wrappers[0].line.Id);
        wrappers[0].header = wrappers[0].line.getSObject('Shipment__r');
        AllocationService.allocate(wrappers);
        
        Test.startTest();
        Test.setCurrentPage(Page.ShipmentPlanPick);
        ApexPages.currentPage().getParameters().put('recs', shipment.Id);
        ShipmentPlanPick plan = new ShipmentPlanPick();
        plan.executeBatch();
        Test.stopTest();
        
        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Type__c = :SkidService3.SKID_TYPE_PLANNED];
        System.assert(skids.size() == 1, skids.size());
    }
}