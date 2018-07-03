@isTest
public with sharing class ShipmentAPITest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.itemAttrObj2 != null);
        insert new Configuration__c(Name = 'STACKTRACE');
        new SalesOrderService().plan(f.packageSalesOrder.Id);
    }

    public static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void shipment() {
        fuel.setupInventory(true, true);

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        SKID__c skid = wrappers[0].serialWrappers[0].skid;
        skid.Input_Quantity__c = 10;
        Serial__c serial = wrappers[0].serialWrappers[0].serialList[0];
        serial.Temporary_Value_Holder__c = 'Allocate';

        Map<Id, List<SkidWrapperV2>> inputData = new Map<Id, List<SkidWrapperV2>>{ wrappers[0].line.Id => new List<SkidWrapperV2>{ new SkidWrapperV2(skid, new List<Serial__c>{ serial }) }};
        ShipmentAPI.Allocate allocate = new ShipmentAPI.Allocate();
        Action.Response resp = allocate.execute(JSON.serialize(inputData));
        System.assert(resp.success == true, resp);

        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));

        Test.startTest();
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        skid = wrappers[0].serialWrappers[0].skid;
        skid.Packaging_UOM__c = null;
        skid.Input_Quantity__c = 10;
        serial = wrappers[0].serialWrappers[0].serialList[0];
        serial.Temporary_Value_Holder__c = 'Plan';

        inputData = new Map<Id, List<SkidWrapperV2>>{ wrappers[0].line.Id => new List<SkidWrapperV2>{ new SkidWrapperV2(skid, new List<Serial__c>{ serial }) }};
        ShipmentAPI.PlanPick plan = new ShipmentAPI.PlanPick();
        resp = plan.execute(JSON.serialize(inputData));
        System.assert(resp.success == true, resp);

        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        skid = wrappers[0].serialWrappers[0].skid;
        skid.Input_Quantity__c = 10;
        serial = wrappers[0].serialWrappers[0].serialList[0];
        for (Serial__c ser:wrappers[0].serialWrappers[0].serialList) ser.Temporary_Value_Holder__c = 'Pick';

        inputData = new Map<Id, List<SkidWrapperV2>>{ wrappers[0].line.Id => new List<SkidWrapperV2>{ new SkidWrapperV2(skid, wrappers[0].serialWrappers[0].serialList) }};
        ShipmentAPI.Pick pick = new ShipmentAPI.Pick();
        resp = pick.execute(JSON.serialize(inputData));
        System.assert(resp.success == true, resp);

        ShipmentAPI.ship ship = new ShipmentAPI.Ship();
        resp = ship.execute(JSON.serialize(new Set<Id>{ shipmentLines.values()[0].Shipment__c }));
        System.assert(resp.success == true, resp);
    }
}