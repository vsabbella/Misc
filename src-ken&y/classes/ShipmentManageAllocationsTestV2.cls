@isTest
private class ShipmentManageAllocationsTestV2 {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.salesOrder != null);
        System.assert(f.itemAttrObj2 != null);
    }

    public static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void noAttributes() {
        fuel.setupInventory(false, false);

        Sales_Order__c so = fuel.salesOrder;
        new SalesOrderService().plan(so.Id);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());

        Test.setCurrentPage(Page.ShipmentWorkbench);
        ApexPages.currentPage().getParameters().put('shipment', shipment.Id);
        ApexPages.currentPage().getParameters().put('mode', 'allocate');
        ShipmentWorkbenchExt ext = new ShipmentWorkbenchExt();
        String s = ext.filterFieldsJson;
        s = ext.serialFieldsJson;
        s = ext.serialAttributesJson;
        Integer i = ext.gridSize;

        JsonResult result = ShipmentWorkbenchExt.getShipmentLinesAndFields(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate', true,false);
        System.assert(result.success, result);
        System.assert(result.records.size() == 2, result.records);
        System.assert(result.additionalInfo != null, result.additionalInfo);

        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>((List<Shipment_Line__c>)result.records);
        result = ShipmentWorkbenchExt.getInventoryAndFields(shipmentLines.values(), 'allocate');
        System.assert(result.success, result);
        System.assert(result.records.size() == 2, result.records);

        List<List<LineWrapper>> shlWrappers = (List<List<LineWrapper>>)result.records;
        List<LineWrapper> wrappers = new List<LineWrapper>();
        for (List<LineWrapper> uomWrappers:shlWrappers) {
            System.assert(uomWrappers.size() == 1, shlWrappers);
            LineWrapper wrapper = uomWrappers[0];
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                System.assert(sw.skid.Quantity_Available__c == 100, sw);
                if (sw.skid.Location__c == fuel.location3.Id) {
                    sw.skid.Input_Quantity__c = 5;
                } else {
                    sw.skid.Input_Quantity__c = 0;
                }
            }
            
            wrappers.add(wrapper);
        }
        Test.startTest();
        result = ShipmentWorkbenchExt.save(wrappers, 'allocate');
        System.assert(result.success, result);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Allocated__c',
            'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 4, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Sales_Order_Line__c == skid.Shipment_Line__r.Sales_Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Sales_Order_Line__r.Quantity_Allocated__c == 5, skid.Sales_Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);

            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 5, skid);
            } else if (skid.Type__c == SkidService3.SKID_TYPE_SO_DEMAND) {
                System.assert(skid.Quantity__c == (skid.Shipment_Line__r.Quantity_Planned__c - 5), skid);
                System.assert(skid.Location__c == skid.Shipment_Line__r.Location__c, skid);
            } else {
                System.assert(false, 'Unexpected skid type: ' + skid.Type__c);
            }
        }

        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);
        
        wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) {
                    System.assert(sw.skid.Quantity_Allocated__c == 5, sw);
                    System.assert(sw.skid.Quantity_Available__c == 95, sw);
                    sw.skid.Input_Quantity__c = -5;
                } else {
                    System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                    System.assert(sw.skid.Quantity_Available__c == 100, sw);
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Type__c == SkidService3.SKID_TYPE_SO_DEMAND);
            System.assert(skid.Quantity__c == skid.Shipment_Line__r.Quantity_Planned__c, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Location__c == skid.Shipment_Line__r.Location__c, skid);
            System.assert(skid.Sales_Order_Line__c == skid.Shipment_Line__r.Sales_Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Sales_Order_Line__r.Quantity_Allocated__c == 0, skid.Sales_Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_PLANNED, skid.Shipment_Line__r.Shipment__r);
        }
    }

    private static testMethod void attributes() {
        fuel.setupInventory(true, false);

        Sales_Order__c so = fuel.salesOrder;
        new SalesOrderService().plan(so.Id);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                System.assert(sw.skid.Quantity_Available__c == 100, sw);
                if (sw.skid.Location__c == fuel.location3.Id) {
                    sw.skid.Input_Quantity__c = 5;
                } else {
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Allocated__c',
            'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 4, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Sales_Order_Line__c == skid.Shipment_Line__r.Sales_Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Sales_Order_Line__r.Quantity_Allocated__c == 5, skid.Sales_Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);

            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 5, skid);
            } else if (skid.Type__c == SkidService3.SKID_TYPE_SO_DEMAND) {
                System.assert(skid.Quantity__c == (skid.Shipment_Line__r.Quantity_Planned__c - 5), skid);
                System.assert(skid.Location__c == skid.Shipment_Line__r.Location__c, skid);
            } else {
                System.assert(false, 'Unexpected skid type: ' + skid.Type__c);
            }
        }

        Test.startTest();
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) {
                    System.assert(sw.skid.Quantity_Allocated__c == 5, sw);
                    System.assert(sw.skid.Quantity_Available__c == 95, sw);
                    sw.skid.Input_Quantity__c = -5;
                } else {
                    System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                    System.assert(sw.skid.Quantity_Available__c == 100, sw);
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Type__c == SkidService3.SKID_TYPE_SO_DEMAND);
            System.assert(skid.Quantity__c == skid.Shipment_Line__r.Quantity_Planned__c, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Location__c == skid.Shipment_Line__r.Location__c, skid);
            System.assert(skid.Sales_Order_Line__c == skid.Shipment_Line__r.Sales_Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Sales_Order_Line__r.Quantity_Allocated__c == 0, skid.Sales_Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_PLANNED, skid.Shipment_Line__r.Shipment__r);
        }
    }

    private static testMethod void serials() {
        fuel.setupInventory(true, true);

        Sales_Order__c so = fuel.salesOrder;
        new SalesOrderService().plan(so.Id);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                System.assert(sw.skid.Quantity_Available__c == 10, sw);
                if (sw.skid.Location__c == fuel.location3.Id) {
                    sw.skid.Input_Quantity__c = 5;
                    sw.serialList[0].Temporary_Value_Holder__c = 'Allocate';
                } else {
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Packaging_UOM__c', 'Quantity__c',
            'Quantity_Stocking_UOM__c', 'Sales_Order_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Item__r.Stocking_UOM__c',

            'Sales_Order_Line__r.Quantity_Allocated__c',

            'Shipment_Line__c', 'Shipment_Line__r.Company__c', 'Shipment_Line__r.Facility__c', 'Shipment_Line__r.Location__c', 'Shipment_Line__r.Quantity_Allocated__c',
            'Shipment_Line__r.Quantity_Planned__c', 'Shipment_Line__r.Item__c', 'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Status__c' });
        skidQuery.setWhereClause('Shipment_Line__r.Shipment__c = \'' + shipment.Id + '\'');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery, 'Allocated_Serials__r');
        serialQuery.addFields(new Set<String>{ 'Id', 'Allow_Reentry__c', 'Company__c', 'Item__c', 'SKID__c' });
        skidQuery.addChildRelationship(serialQuery);

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 4, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Sales_Order_Line__c == skid.Shipment_Line__r.Sales_Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 5, skid.Shipment_Line__r);
            System.assert(skid.Sales_Order_Line__r.Quantity_Allocated__c == 5, skid.Sales_Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED, skid.Shipment_Line__r.Shipment__r);

            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 5, skid);
                System.assert(skid.Allocated_Serials__r.size() == 1, skid.Allocated_Serials__r);
                System.assert(skid.Allocated_Serials__r[0].Allow_Reentry__c == false, skid.Allocated_Serials__r[0]);
                System.assert(skid.Allocated_Serials__r[0].Company__c == skid.Shipment_Line__r.Company__c, skid.Allocated_Serials__r[0]);
                System.assert(skid.Allocated_Serials__r[0].Item__c == skid.Item__c, skid.Allocated_Serials__r[0]);
                System.assert(skid.Allocated_Serials__r[0].SKID__c != null, skid.Allocated_Serials__r[0]);
            } else if (skid.Type__c == SkidService3.SKID_TYPE_SO_DEMAND) {
                System.assert(skid.Quantity__c == (skid.Shipment_Line__r.Quantity_Planned__c - 5), skid);
                System.assert(skid.Location__c == skid.Shipment_Line__r.Location__c, skid);
            } else {
                System.assert(false, 'Unexpected skid type: ' + skid.Type__c);
            }
        }

        Test.startTest();
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) {
                    System.assert(sw.skid.Quantity_Allocated__c == 5, sw);
                    System.assert(sw.skid.Quantity_Available__c == 5, sw);
                    sw.skid.Input_Quantity__c = -5;
                    sw.serialList[0].Temporary_Value_Holder__c = 'Unallocate';
                } else {
                    System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                    System.assert(sw.skid.Quantity_Available__c == 10, sw);
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Company__c == skid.Shipment_Line__r.Company__c, skid);
            System.assert(skid.Type__c == SkidService3.SKID_TYPE_SO_DEMAND);
            System.assert(skid.Quantity__c == skid.Shipment_Line__r.Quantity_Planned__c, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Quantity__c, skid);
            System.assert(skid.Item__c == skid.Shipment_Line__r.Item__c, skid);
            System.assert(skid.Packaging_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Stocking_UOM__c == skid.Item__r.Stocking_UOM__c, skid);
            System.assert(skid.Container_Item__c == skid.Item__c, skid);
            System.assert(skid.Facility2__c == skid.Shipment_Line__r.Facility__c, skid);
            System.assert(skid.Location__c == skid.Shipment_Line__r.Location__c, skid);
            System.assert(skid.Sales_Order_Line__c == skid.Shipment_Line__r.Sales_Order_Line__c, skid);
            System.assert(skid.Shipment_Line__r.Quantity_Allocated__c == 0, skid.Shipment_Line__r);
            System.assert(skid.Sales_Order_Line__r.Quantity_Allocated__c == 0, skid.Sales_Order_Line__r);
            System.assert(skid.Shipment_Line__r.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_PLANNED, skid.Shipment_Line__r.Shipment__r);
        }
    }

    private static testMethod void errors() {
        fuel.setupInventory(true, true);

        Sales_Order__c so = fuel.salesOrder;
        new SalesOrderService().plan(so.Id);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                System.assert(sw.skid.Quantity_Available__c == 10, sw);
                if (sw.skid.Location__c == fuel.location3.Id) {
                    sw.skid.Input_Quantity__c = 20;
                } else {
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }

        try {
            AllocationService.allocate(wrappers);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }

        for (LineWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) {
                    sw.skid.Input_Quantity__c = 1;
                    sw.serialList[0].Temporary_Value_Holder__c = 'Allocate';
                    sw.serialList[1].Temporary_Value_Holder__c = 'Allocate';
                }
            }
        }

        try {
            AllocationService.allocate(wrappers);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
    }

    private static testMethod void filtering() {
        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id, Rental__c = true, Used__c = true, Lot_Number__c = false, Expiration_Date__c = false);

        List<SKID__c> skids = new List<SKID__c>();
        for (Item__c item:fuel.itemList) {
            SKID__c skid = new SKID__c(
                Company__c = fuel.company.Id,
                Type__c = SkidService3.SKID_TYPE_LOCATION,
                Item__c = item.Id,
                Container_Item__c = item.Id,
                Quantity__c = 100,
                Quantity_Stocking_UOM__c = 100,
                Packaging_UOM__c = item.Stocking_UOM__c,
                Stocking_UOM__c = item.Stocking_UOM__c,
                Facility2__c = fuel.location3.Facility__c,
                Location__c = fuel.location3.Id
            );
            skids.add(skid);

            SKID__c skid1 = skid.clone(false, true);
            skid1.Location__c = fuel.location5.Id;
            skids.add(skid1);

            SKID__c skid2 = skid.clone(false, true);
            SKID__c skid3 = skid1.clone(false, true);
            skid2.Rental__c = true;
            skid3.Rental__c = true;
            skids.add(skid2);
            skids.add(skid3);

            SKID__c skid4 = skid.clone(false, true);
            SKID__c skid5 = skid1.clone(false, true);
            skid4.Used__c = true;
            skid5.Used__c = true;
            skids.add(skid4);
            skids.add(skid5);

            SKID__c skid6 = skid.clone(false, true);
            SKID__c skid7 = skid1.clone(false, true);
            skid6.Rental__c = true;
            skid7.Rental__c = true;
            skid6.Used__c = true;
            skid7.Used__c = true;
            skids.add(skid6);
            skids.add(skid7);
        }
        insert skids;

        Sales_Order__c so = fuel.salesOrder;
        delete fuel.salesOrderLine;

        new SalesOrderService().plan(so.Id);

        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
        shlQuery.addFields(new Set<String>{ 'Id', 'Sales_Order_Line__c', 'Shipment__c' });
        Shipment_Line__c shl = Database.query(shlQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shl.Shipment__c }, 'allocate'));
        System.assert(shipmentLines.size() == 1, shipmentLines);

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            System.assert(sw.skid.Rental__c == false, sw.skid);
            System.assert(sw.skid.Used__c == false, sw.skid);
        }

        update new Sales_Order_Line__c(Id = shl.Sales_Order_Line__c, Rental__c = true);

        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shl.Shipment__c }, 'allocate'));
        System.assert(shipmentLines.size() == 1, shipmentLines);

        Test.startTest();

        wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            System.assert(sw.skid.Rental__c == true, sw.skid);
            System.assert(sw.skid.Used__c == false, sw.skid);
        }

        update new Sales_Order_Line__c(Id = shl.Sales_Order_Line__c, Used__c = true);

        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shl.Shipment__c }, 'allocate'));
        System.assert(shipmentLines.size() == 1, shipmentLines);

        wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            System.assert(sw.skid.Rental__c == true, sw.skid);
            System.assert(sw.skid.Used__c == true, sw.skid);
        }

        update new Sales_Order_Line__c(Id = shl.Sales_Order_Line__c, Rental__c = false);

        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shl.Shipment__c }, 'allocate'));
        System.assert(shipmentLines.size() == 1, shipmentLines);

        wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 1, wrappers);

        for (SkidService3.SerialWrapper sw:wrappers[0].serialWrappers) {
            System.assert(sw.skid.Rental__c == false, sw.skid);
            System.assert(sw.skid.Used__c == true, sw.skid);
        }
    }
    
    private static testMethod void profileOff() {
        fuel.setupInventory(true, false);

        insert new Allocation_Profile__c(
            Company__c = fuel.company.Id,
            Date_Received__c = false,
            Expiration_Date__c = false,
            Location__c = false,
            Rental__c = false,
            Used__c = false
        );

        Sales_Order__c so = fuel.salesOrder;
        new SalesOrderService().plan(so.Id);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            System.assert(wrapper.serialWrappers[0].skid.Quantity_Available__c == 200, wrapper.serialWrappers[0].skid);
        }
    }
    
    private static testMethod void profileLocation() {
        fuel.setupInventory(true, false);

        insert new Allocation_Profile__c(
            Company__c = fuel.company.Id,
            Date_Received__c = false,
            Expiration_Date__c = false,
            Location__c = true,
            Rental__c = false,
            Used__c = false
        );

        Sales_Order__c so = fuel.salesOrder;
        new SalesOrderService().plan(so.Id);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            System.assert(wrapper.serialWrappers[0].skid.Quantity_Available__c == 100, wrapper.serialWrappers[0].skid);
            System.assert(wrapper.serialWrappers[1].skid.Quantity_Available__c == 100, wrapper.serialWrappers[0].skid);
        }
    }

    private static testMethod void requeryShipmentLineError() {
        fuel.setupInventory(true, false);

        Sales_Order__c so = fuel.salesOrder;
        new SalesOrderService().plan(so.Id);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                System.assert(sw.skid.Quantity_Available__c == 100, sw);
                if (sw.skid.Location__c == fuel.location3.Id) {
                    sw.skid.Input_Quantity__c = 5;
                } else {
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }

        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;
        delete [SELECT Id FROM Shipment_Line__c];
        delete c;

        JsonResult result = ShipmentWorkbenchExt.save(wrappers, 'allocate');
        System.assert(!result.success, result);
    }

    private static testMethod void requerySkidError() {
        fuel.setupInventory(true, false);

        Sales_Order__c so = fuel.salesOrder;
        new SalesOrderService().plan(so.Id);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                System.assert(sw.skid.Quantity_Available__c == 100, sw);
                if (sw.skid.Location__c == fuel.location3.Id) {
                    sw.skid.Input_Quantity__c = 5;
                } else {
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }

        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;
        delete [SELECT Id FROM SKID__c];
        delete c;

        JsonResult result = ShipmentWorkbenchExt.save(wrappers, 'allocate');
        System.assert(!result.success, result);
    }

    private static testMethod void requerySerialError() {
        fuel.setupInventory(true, true);

        Sales_Order__c so = fuel.salesOrder;
        new SalesOrderService().plan(so.Id);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        System.assert(wrappers.size() == 2, wrappers);

        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            
            System.assert(wrapper.serialWrappers.size() == 2, wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 0, sw);
                System.assert(sw.skid.Quantity_Available__c == 10, sw);
                if (sw.skid.Location__c == fuel.location3.Id) {
                    sw.skid.Input_Quantity__c = 5;
                    sw.serialList[0].Temporary_Value_Holder__c = 'Allocate';
                } else {
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }

        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;
        delete [SELECT Id FROM Serial__c];
        delete c;

        JsonResult result = ShipmentWorkbenchExt.save(wrappers, 'allocate');
        System.assert(!result.success, result);
    }
}