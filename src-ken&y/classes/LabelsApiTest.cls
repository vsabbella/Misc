@isTest
public with sharing class LabelsApiTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.itemAttrObj2 != null);
        System.assert(f.periodList != null);
        System.assert(f.purchaseOrder != null);
        System.assert(f.purchaseOrderLines != null);
        System.assert(f.supplier != null);
        System.assert(f.transferOrder != null);
        System.assert(f.transferOrderLines!=null);
        system.assert(f.salesOrder != null &&
                f.product3 != null &&
                f.location != null &&
                f.location3 != null &&
                f.pricebook != null &&
                f.uomcList != null &&
                f.uomList != null &&
                f.itemList != null &&
                f.reasonCodes != null &&
                f.itemSpec != null &&
                f.smrsList != null
        );
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void transferOrderShipmentLabels() {
        OrderService.release(new Map<Id, Id>{ fuel.transferOrder.Id => null });

        fuel.setupInventory();

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<Label__c> labels = LabelsApi.generateLabels(new List<SObject>{shipment});
        System.assert(labels.size() > 0);

        Shipment_Line__c shl = shipmentLines.values().get(0);

        LabelWrapper lw = new LabelWrapper();
        lw.quantity = 1;
        lw.caseIndex = 1;
        lw.record = shl;
        lw.packagingUom = fuel.uomList[8];

        labels = LabelsApi.generateSingleLabels(new Map<Id, List<LabelWrapper>>{shl.Id => new List<LabelWrapper>{
                lw
        }});
        System.assert(labels.size() > 0);
    }

    private static testMethod void salesOrderShipmentLabels() {

        ApexPages.StandardController con;
        SOPlanExt soPlanExt;

        Test.startTest();
        final decimal OZ_LB = .0625;

        System.debug(loggingLevel.Error, ' ***** fuel.uomList :' + fuel.uomList);
        fuel.product.Weight_UOM__c = fuel.uomList[3].Id; //oz
        System.debug(loggingLevel.Error, ' ***** fuel.product :' + fuel.product);
        System.debug(loggingLevel.Error, ' ***** fuel.product.Units_per_Pallet__c :' + fuel.product.Units_per_Pallet__c);
        fuel.product.units_per_layer__c = 1;
        fuel.product.layers_per_pallet__c = 1;

        fuel.product2.units_per_layer__c = 1;
        fuel.product2.layers_per_pallet__c = 1;
        List<Product__c> productsToUpdate = new List<Product__c>{fuel.product, fuel.product2};
        update productsToUpdate;

        fuel.salesOrder.Weight_UOM__c = fuel.uomList[0].Id;
        fuel.salesOrder.Dimension_UOM__c = fuel.uomList[6].Id;
        fuel.salesOrder.Currency__c = fuel.currencyUSD.Id;

        update fuel.salesOrder;

        Sales_Order__c salesOrder = [SELECT Id, Weight_UOM__r.Name, Dimension_UOM__r.Name FROM Sales_Order__c WHERE Id = :fuel.salesOrder.Id];
        System.debug(LoggingLevel.INFO, 'fuel.product.: ' + fuel.product.Weight__c);

        con = new ApexPages.StandardController(fuel.salesOrder);
        soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<Label__c> labels = LabelsApi.generateLabels(new List<SObject>{shipment});
        System.assert(labels.size() > 0);

        Shipment_Line__c shl = shipmentLines.values().get(0);

        LabelWrapper lw = new LabelWrapper();
        lw.quantity = 1;
        lw.caseIndex = 1;
        lw.record = shl;
        lw.packagingUom = fuel.uomList[8];

        labels = LabelsApi.generateSingleLabels(new Map<Id, List<LabelWrapper>>{shl.Id => new List<LabelWrapper>{
                lw
        }});
        System.assert(labels.size() > 0);

        Test.stopTest();
    }

    private static testMethod void testHeterogeneousLabelsSuccess() {

        ApexPages.StandardController con;
        SOPlanExt soPlanExt;

        Test.startTest();
        final decimal OZ_LB = .0625;

        System.debug(loggingLevel.Error, ' ***** fuel.uomList :' + fuel.uomList);
        fuel.product.Weight_UOM__c = fuel.uomList[3].Id; //oz
        System.debug(loggingLevel.Error, ' ***** fuel.product :' + fuel.product);
        System.debug(loggingLevel.Error, ' ***** fuel.product.Units_per_Pallet__c :' + fuel.product.Units_per_Pallet__c);
        fuel.product.units_per_layer__c = 1;
        fuel.product.layers_per_pallet__c = 1;

        fuel.product2.units_per_layer__c = 1;
        fuel.product2.layers_per_pallet__c = 1;
        List<Product__c> productsToUpdate = new List<Product__c>{fuel.product, fuel.product2};
        update productsToUpdate;

        fuel.salesOrder.Weight_UOM__c = fuel.uomList[0].Id;
        fuel.salesOrder.Dimension_UOM__c = fuel.uomList[6].Id;
        fuel.salesOrder.Currency__c = fuel.currencyUSD.Id;

        update fuel.salesOrder;

        Sales_Order__c salesOrder = [SELECT Id, Weight_UOM__r.Name, Dimension_UOM__r.Name FROM Sales_Order__c WHERE Id = :fuel.salesOrder.Id];
        System.debug(LoggingLevel.INFO, 'fuel.product.: ' + fuel.product.Weight__c);

        con = new ApexPages.StandardController(fuel.salesOrder);
        soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<Label__c> labels = LabelsApi.generateLabels(new List<SObject>{shipment});
        System.assert(labels.size() > 0);

        Shipment_Line__c shl = shipmentLines.values().get(0);

        LabelWrapper lw = new LabelWrapper();
        lw.quantity = 1;
        lw.caseIndex = 1;
        lw.record = shl;
        lw.packagingUom = fuel.uomList[8];
        lw.fromType = 'Item__c';

        LabelWrapper lw1 = new LabelWrapper();
        lw1.quantity = 1;
        lw1.caseIndex = 2;
        lw1.record = fuel.salesOrderLine;
        lw1.packagingUom = fuel.uomList[8];
        lw1.fromType = 'Item__c';

        labels = LabelsApi.generateHeterogeneousLabels(new Map<Id, List<LabelWrapper>>{
                shl.Id => new List<LabelWrapper>{
                        lw
                }, fuel.salesOrderLine.Id => new List<LabelWrapper>{
                        lw1
                }
        });
        System.assert(labels.size() > 0);

        Test.stopTest();
    }

    private static testMethod void testHeterogeneousLabelsFailure() {

        ApexPages.StandardController con;
        SOPlanExt soPlanExt;

        Test.startTest();
        final decimal OZ_LB = .0625;

        System.debug(loggingLevel.Error, ' ***** fuel.uomList :' + fuel.uomList);
        fuel.product.Weight_UOM__c = fuel.uomList[3].Id; //oz
        System.debug(loggingLevel.Error, ' ***** fuel.product :' + fuel.product);
        System.debug(loggingLevel.Error, ' ***** fuel.product.Units_per_Pallet__c :' + fuel.product.Units_per_Pallet__c);
        fuel.product.units_per_layer__c = 1;
        fuel.product.layers_per_pallet__c = 1;

        fuel.product2.units_per_layer__c = 1;
        fuel.product2.layers_per_pallet__c = 1;
        List<Product__c> productsToUpdate = new List<Product__c>{fuel.product, fuel.product2};
        update productsToUpdate;

        fuel.salesOrder.Weight_UOM__c = fuel.uomList[0].Id;
        fuel.salesOrder.Dimension_UOM__c = fuel.uomList[6].Id;
        fuel.salesOrder.Currency__c = fuel.currencyUSD.Id;

        update fuel.salesOrder;

        Sales_Order__c salesOrder = [SELECT Id, Weight_UOM__r.Name, Dimension_UOM__r.Name FROM Sales_Order__c WHERE Id = :fuel.salesOrder.Id];
        System.debug(LoggingLevel.INFO, 'fuel.product.: ' + fuel.product.Weight__c);

        con = new ApexPages.StandardController(fuel.salesOrder);
        soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines);

        List<Label__c> labels = LabelsApi.generateLabels(new List<SObject>{shipment});
        System.assert(labels.size() > 0);

        Shipment_Line__c shl = shipmentLines.values().get(0);

        LabelWrapper lw = new LabelWrapper();
        lw.quantity = 1;
        lw.caseIndex = 1;
        lw.record = shl;
        lw.packagingUom = fuel.uomList[8];
        lw.fromType = 'Item__c';

        LabelWrapper lw1 = new LabelWrapper();
        lw1.quantity = 1;
        lw1.caseIndex = 2;
        lw1.record = salesOrder;
        lw1.packagingUom = fuel.uomList[8];
        lw1.fromType = 'Item__c';
        lw1.item = fuel.itemList[8];

        try {
            labels = LabelsApi.generateHeterogeneousLabels(new Map<Id, List<LabelWrapper>>{
                    shl.Id => new List<LabelWrapper>{
                            lw
                    }, salesOrder.Id => new List<LabelWrapper>{
                            lw1
                    }
            });
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, e.getMessage() );
        }
        Test.stopTest();
    }


}