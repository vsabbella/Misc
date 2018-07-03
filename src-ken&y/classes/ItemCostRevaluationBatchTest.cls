@isTest
private class ItemCostRevaluationBatchTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.periodList != null);
        System.assert(f.workOrder != null);
        System.assert(f.purchaseOrder != null);
        delete [SELECT Id FROM Item_Attribute__c];
    }

    private static void updateCosts(List<Item_Cost__c> costs) {
        List<Item_Cost__c> costsToUpdate = new List<Item_Cost__c>();
        for (Item_Cost__c cost:costs) {
            if (cost.Status__c == 'Proposed') {
                cost.Start_Date__c = System.now().addMinutes(-60);
                cost.Status__c = 'Approved';
                cost.Date_Approved__c = System.now();
            }
            cost.Facility__c = null;
            costsToUpdate.add(cost);
        }
        ItemService.allowItemCostUpdate = true;
        update costsToUpdate;
        ItemService.allowItemCostUpdate = false;
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void testNoQty() {
        List<Item_Cost__c> costsToUpdate = new List<Item_Cost__c>();
        for (Item_Cost__c cost:fuel.costList) {
            if (cost.Item__c == fuel.itemList[5].Id) costsToUpdate.add(cost);
        }
        updateCosts(costsToUpdate);

        Work_Order__c wo = fuel.workOrder;
        delete [SELECT Id FROM Routing__c];
        delete [SELECT Id FROM Component__c];
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Item__r = wo.Item__r;

        Test.startTest();

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, null, assembly, null, null, true) });

        ItemCostRevaluationBatch revalBatch = new ItemCostRevaluationBatch();
        revalBatch.runBatch(new Process_Job__c(Company__c = wo.Company__c));

        Test.stopTest();

        List<Inventory_Change__c> icList = [SELECT Id FROM Inventory_Change__c WHERE Type__c = 'Activate Proposed Costs'];
        System.assert(icList.size() == 0, icList.size());
    }

    private static testMethod void testWip() {
        List<Item_Cost__c> costsToUpdate = new List<Item_Cost__c>();
        for (Item_Cost__c cost:fuel.costList) {
            if (cost.Item__c == fuel.itemList[0].Id || cost.Item__c == fuel.itemList[5].Id) costsToUpdate.add(cost);
        }
        updateCosts(costsToUpdate);

        Work_Order__c wo = fuel.workOrder;
        delete [SELECT Id FROM Routing__c];
        delete [SELECT Id FROM Component__c WHERE Component_Sequence__c = 1 AND Assembly_Item_Specification__c = :wo.Assembly_Item_Specification__c];
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });
        fuel.setupInventory();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Item__r = wo.Item__r;

        List<WorkOrderWrapper> components = (List<WorkOrderWrapper>)WorkOrderCompleteExtV2.getBackflushData(wo.Id, operation.Id, true).records;
        components[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        components[0].serialWrapperList[0].skid.Item__r = components[0].material.Item__r;
        components[0].serialWrapperList.remove(1);

        Test.startTest();

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, null, assembly, components, null, true) });

        ItemCostRevaluationBatch revalBatch = new ItemCostRevaluationBatch();
        revalBatch.runBatch(new Process_Job__c(Company__c = wo.Company__c));

        Test.stopTest();

        List<Inventory_Change__c> icList = [SELECT Id, Transaction_Date__c,
                                                (SELECT Id, From_Standard_Cost__c, To_Standard_Cost__c, Standard_Cost__c, Extended_Cost__c, Item__c,
                                                        Quantity__c, Transaction_Date__c, Type__c
                                                FROM Inventory_Transactions__r
                                                WHERE Type__c LIKE 'Activate Proposed Costs - %')
                                            FROM Inventory_Change__c
                                            WHERE Type__c = 'Activate Proposed Costs'];
        System.assert(icList.size() == 2, icList.size());

        for (Inventory_Change__c ic:icList) {
            System.assert(ic.Inventory_Transactions__r.size() == 1, ic.Inventory_Transactions__r.size());

            Inventory_Transaction__c it = ic.Inventory_Transactions__r[0];
            System.assert(it.Type__c == 'Activate Proposed Costs - Inventory', it);
            System.assert(it.Transaction_Date__c == ic.Transaction_Date__c, it);
            System.assert(it.Transaction_Date__c <= System.now().addMinutes(-60), it);
            System.assert(it.Quantity__c == 200, it);
            System.assert(it.Standard_Cost__c == it.To_Standard_Cost__c - it.From_Standard_Cost__c, it);
            System.assert(it.Extended_Cost__c == it.Standard_Cost__c * it.Quantity__c, it);

            if (it.Item__c == wo.Item__c) {
                System.assert(it.From_Standard_Cost__c == 44.55, it);
                System.assert(it.To_Standard_Cost__c == 49.5, it);
            } else {
                System.assert(it.From_Standard_Cost__c == 29.7, it);
                System.assert(it.To_Standard_Cost__c == 33, it);
            }
        }
    }

    private static testMethod void testIntransit() {
        List<Item_Cost__c> costsToUpdate = new List<Item_Cost__c>();
        for (Item_Cost__c cost:fuel.costList) {
            if (cost.Item__c == fuel.itemList[2].Id) costsToUpdate.add(cost);
        }
        updateCosts(costsToUpdate);

        fuel.setupInventory();

        FOB_Terms__c fob = new FOB_Terms__c(
            Id = fuel.fobTerm.Id,
            FOB_Point__c = 'Origin'
        );
        update fob;

        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c pol = fuel.purchaseOrderLines[0];

        ASN__c asn = new ASN__c(
            Company__c = po.Company__c,
            Currency__c = fuel.currencyUSD.Id,
            Supplier__c = po.Supplier__c,
            Facility__c = po.Delivery_Facility__c,
            FOB__c = fob.Id,
            Transaction_Type__c = 'Purchase Order ASN',
            Status__c = 'Draft',
            Transaction_Date__c = System.today()
        );

        ASNAddManageExt.ASNLineWrapper asnLine = ((List<ASNAddManageExt.ASNLineWrapper>)ASNAddManageExt.getasnLinesByPurchaseOrderId(po.Id, po.Delivery_Facility__c, 1).records)[0];
        asnLine.serialWrapperList[0].skid.Quantity__c = asnLine.asnl.Quantity_Shipped__c;
        asnLine.serialWrapperList[0].serialList = new List<Serial__c>();

        ASNAddManageExt.saveAction(asn, null, new List<ASNAddManageExt.ASNLineWrapper>(), new List<ASNAddManageExt.ASNLineWrapper>{ asnLine }, new List<ASNAddManageExt.ASNLineWrapper>(), new List<SkidService3.SerialWrapper>(), null, null);

        SOQLUtil asnQuery = new SOQLUtil('ASN__c');
        asnQuery.addAllCustomFields();
        asnQuery.setLimit(1);
        asn = Database.query(asnQuery.getQuery());

        Test.startTest();

        ASNService.confirmASN(asn);
        ASNService.undoConfirmASN(new Set<Id>{ asn.Id });

        ItemCostRevaluationBatch revalBatch = new ItemCostRevaluationBatch();
        revalBatch.runBatch(new Process_Job__c(Company__c = po.Company__c));

        Test.stopTest();

        List<Inventory_Change__c> icList = [SELECT Id, Transaction_Date__c,
                                                (SELECT Id, From_Standard_Cost__c, To_Standard_Cost__c, Standard_Cost__c, Extended_Cost__c, Item__c,
                                                        Quantity__c, Transaction_Date__c, Type__c
                                                FROM Inventory_Transactions__r
                                                WHERE Type__c LIKE 'Activate Proposed Costs - %')
                                            FROM Inventory_Change__c
                                            WHERE Type__c = 'Activate Proposed Costs'];
        System.assert(icList.size() == 1, icList.size());

        for (Inventory_Change__c ic:icList) {
            System.assert(ic.Inventory_Transactions__r.size() == 1, ic.Inventory_Transactions__r.size());

            Inventory_Transaction__c it = ic.Inventory_Transactions__r[0];
            System.assert(it.Type__c == 'Activate Proposed Costs - Inventory', it);
            System.assert(it.Transaction_Date__c == ic.Transaction_Date__c, it);
            System.assert(it.Transaction_Date__c <= System.now().addMinutes(-60), it);
            System.assert(it.Quantity__c == 200, it);
            System.assert(it.From_Standard_Cost__c == 3, it);
            System.assert(it.To_Standard_Cost__c == 2.5, it);
            System.assert(it.Standard_Cost__c == it.To_Standard_Cost__c - it.From_Standard_Cost__c, it);
            System.assert(it.Extended_Cost__c == it.Standard_Cost__c * it.Quantity__c, it);
        }
    }
}