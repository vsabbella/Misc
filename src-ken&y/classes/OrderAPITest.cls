@isTest
public class OrderAPITest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.itemAttrObj2 != null);
        System.assert(f.periodList != null);
        System.assert(f.transferOrder != null);
        insert new Configuration__c(Name = 'STACKTRACE');
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static void ship() {
        fuel.setupInventory(true);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        SKID__c skid = wrappers[0].serialWrappers[0].skid;
        skid.Input_Quantity__c = 2;

        Map<Id, List<SkidWrapperV2>> inputData = new Map<Id, List<SkidWrapperV2>>{ wrappers[0].line.Id => new List<SkidWrapperV2>{ new SkidWrapperV2(skid) }};
        ShipmentAPI.Allocate allocate = new ShipmentAPI.Allocate();
        Action.Response resp = allocate.execute(JSON.serialize(inputData));
        System.assert(resp.success == true, resp);

        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        skid = wrappers[0].serialWrappers[0].skid;
        skid.Packaging_UOM__c = null;
        skid.Input_Quantity__c = 2;

        inputData = new Map<Id, List<SkidWrapperV2>>{ wrappers[0].line.Id => new List<SkidWrapperV2>{ new SkidWrapperV2(skid) }};
        ShipmentAPI.PlanPick plan = new ShipmentAPI.PlanPick();
        resp = plan.execute(JSON.serialize(inputData));
        System.assert(resp.success == true, resp);

        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        skid = wrappers[0].serialWrappers[0].skid;
        skid.Input_Quantity__c = 2;

        Test.startTest();

        inputData = new Map<Id, List<SkidWrapperV2>>{ wrappers[0].line.Id => new List<SkidWrapperV2>{ new SkidWrapperV2(skid) }};
        ShipmentAPI.Pick pick = new ShipmentAPI.Pick();
        resp = pick.execute(JSON.serialize(inputData));
        System.assert(resp.success == true, resp);

        ShipmentAPI.ship ship = new ShipmentAPI.Ship();
        resp = ship.execute(JSON.serialize(new Set<Id>{ shipmentLines.values()[0].Shipment__c }));
        System.assert(resp.success == true, resp);
    }

    private static testMethod void testReceiveExceptions() {
        Order__c order = fuel.transferOrder;

        OrderService.release(new Map<Id, Id>{ order.Id => null });
        ship();

        Order_Line__c orderLine = [SELECT Id FROM Order_Line__c WHERE Order__c = :order.Id AND Quantity_Shipped__c > 0];

        OrderAPI.OrderWrapper orderWrapper = new OrderAPI.OrderWrapper(order.Id);
        OrderAPI.OrderLineWrapper orderLineWrapper = new OrderAPI.OrderLineWrapper();
        OrderAPI.Quantity qtyReceiving = new OrderAPI.Quantity();
        qtyReceiving.quantity = 1;
        qtyReceiving.lot = 'A';
        qtyReceiving.expirationDate = System.today() + 365;
        qtyReceiving.attributes.put('Expiration_Date__c', System.today() + 365);
        orderLineWrapper.quantities.add(qtyReceiving);
        orderWrapper.lines.put(orderLine.Id, orderLineWrapper);

        Map<Id, OrderAPI.OrderAPIStatus> statuses = OrderAPI.receive(new Map<Id, OrderAPI.OrderWrapper>{ order.Id => orderWrapper });

        for (OrderAPI.OrderAPIStatus status:statuses.values()) System.assert(status.success == true, status);

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :orderLine.Id AND (Exception_Code__c = 'TO-LOTMI900001' OR Exception_Code__c = 'TO-QTYEX900001')];
        System.assert(tasks.size() == 2, tasks);
    }

    private static testMethod void testCloseSuccess() {
        Order__c order = fuel.transferOrder;

        OrderService.release(new Map<Id, Id>{ order.Id => null });

        Map<Id,OrderAPI.OrderAPIStatus> statuses = OrderAPI.close(new Map<Id, OrderAPI.OrderWrapper>{ order.Id => new OrderAPI.OrderWrapper(order.Id) });

        for (OrderAPI.OrderAPIStatus status:statuses.values()) System.assert(status.success == true, status);

        order = [SELECT Id, Status__c FROM Order__c WHERE Id = :order.Id];
        System.assert(order.Status__c == 'Closed', order);
    }

    private static testMethod void testCloseFailOrderInDraft() {
        Order__c order = fuel.transferOrder;

        Map<Id,OrderAPI.OrderAPIStatus> statuses = OrderAPI.close(new Map<Id, OrderAPI.OrderWrapper>{ order.Id => new OrderAPI.OrderWrapper(order.Id) });

        for (OrderAPI.OrderAPIStatus status:statuses.values()) System.assert(status.success == false, status);

        order = [SELECT Id, Status__c FROM Order__c WHERE Id = :order.Id];
        System.assert(order.Status__c == 'Draft', order);
    }

    private static testMethod void testReleaseSuccess() {
        Order__c order = fuel.transferOrder;

        Map<Id, OrderAPI.OrderAPIStatus> statuses = OrderAPI.release(new Map<Id, OrderAPI.OrderWrapper>{ order.Id => new OrderAPI.OrderWrapper(order.Id) });

        for (OrderAPI.OrderAPIStatus status:statuses.values()) System.assert(status.success == true, status);

        List<SKID__c> skids = [SELECT Id FROM SKID__c WHERE Type__c = 'TO Demand' AND Order_Line__r.Order__c = :order.Id];
        System.assert(skids.size() == 2, skids);

        order = [SELECT Id, Status__c FROM Order__c WHERE Id = :order.Id];
        System.assert(order.Status__c == 'Open', order);
    }

    private static testMethod void testReceiveSuccessDifferentLots() {
        Order__c order = fuel.transferOrder;

        OrderService.release(new Map<Id, Id>{ order.Id => null });
        ship();

        Order_Line__c orderLine = [SELECT Id FROM Order_Line__c WHERE Order__c = :order.Id AND Quantity_Shipped__c > 0];

        OrderAPI.OrderWrapper orderWrapper = new OrderAPI.OrderWrapper(order.Id);
        OrderAPI.OrderLineWrapper orderLineWrapper = new OrderAPI.OrderLineWrapper();
        OrderAPI.Quantity qtyReceiving = new OrderAPI.Quantity();
        qtyReceiving.quantity = 1;
        qtyReceiving.lot = 'A';
        qtyReceiving.expirationDate = System.today() + 365;
        qtyReceiving.attributes.put('Expiration_Date__c', System.today() + 365);
        orderLineWrapper.quantities.add(qtyReceiving);
        qtyReceiving = new OrderAPI.Quantity();
        qtyReceiving.quantity = 1;
        qtyReceiving.lot = 'B';
        qtyReceiving.expirationDate = System.today() + 365;
        qtyReceiving.attributes.put('Expiration_Date__c', System.today() + 365);
        orderLineWrapper.quantities.add(qtyReceiving);
        orderWrapper.lines.put(orderLine.Id, orderLineWrapper);

        Map<Id, OrderAPI.OrderAPIStatus> statuses = OrderAPI.receive(new Map<Id, OrderAPI.OrderWrapper>{ order.Id => orderWrapper });

        for (OrderAPI.OrderAPIStatus status:statuses.values()) System.assert(status.success == true, status);

        List<Inventory_Transaction__c> itList = [SELECT Id FROM Inventory_Transaction__c WHERE Type__c = 'Transfer Order Receipt' AND Order_Line__c = :orderLine.Id];
        System.assert(itList.size() == 2, itList);
    }

    private static testMethod void testReceiveFail() {
        Order__c order = fuel.transferOrder;

        OrderService.release(new Map<Id, Id>{ order.Id => null });
        ship();

        Order_Line__c orderLine = [SELECT Id FROM Order_Line__c WHERE Order__c = :order.Id AND Quantity_Shipped__c > 0];

        OrderAPI.OrderWrapper orderWrapper = new OrderAPI.OrderWrapper(order.Id);
        OrderAPI.OrderLineWrapper orderLineWrapper = new OrderAPI.OrderLineWrapper();
        OrderAPI.Quantity qtyReceiving = new OrderAPI.Quantity();
        qtyReceiving.quantity = 1;
        qtyReceiving.expirationDate = System.today() + 365;
        qtyReceiving.attributes.put('Expiration_Date__c', System.today() + 365);
        orderLineWrapper.quantities.add(qtyReceiving);
        orderWrapper.lines.put(orderLine.Id, orderLineWrapper);

        Map<Id, OrderAPI.OrderAPIStatus> statuses = OrderAPI.receive(new Map<Id, OrderAPI.OrderWrapper>{ order.Id => orderWrapper });

        for (OrderAPI.OrderAPIStatus status:statuses.values()) System.assert(status.success == false, status);

        List<Inventory_Transaction__c> itList = [SELECT Id FROM Inventory_Transaction__c WHERE Type__c = 'Transfer Order Receipt' AND Order_Line__c = :orderLine.Id];
        System.assert(itList.size() == 0, itList);
    }
}