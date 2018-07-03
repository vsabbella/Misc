@isTest 
public with sharing class WOCompleteExtTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null && f.stockMovementRuleList != null && f.workOrder != null && f.itemAttrObj2 != null);
        System.assert(f.location6 != null);
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void testInvalidWO() {
        Test.setCurrentPage(Page.WorkOrderCompleteV2);
        WorkOrderCompleteExtV2 completeExt = new WorkOrderCompleteExtV2();
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR));
    }

    private static testMethod void testInvalidOp() {
        Test.setCurrentPage(Page.WorkOrderCompleteV2);
        ApexPages.currentPage().getParameters().put('wo',fuel.workOrder.Id);
        WorkOrderCompleteExtV2 completeExt = new WorkOrderCompleteExtV2();
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR));
    }

    private static testMethod void testNoRoutingsNoSerials() {
        delete [SELECT Id FROM Routing__c];

        fuel.components[0].Type__c = 'Kit';
        Component__c byproduct = fuel.components[0].clone(false,true);
        byproduct.Component_Item__c = fuel.itemList[1].Id;
        byproduct.Type__c = 'By-product';
        byproduct.Component_Sequence__c = null;
        fuel.components.add(byproduct);
        upsert fuel.components;

        fuel.setupInventory(true);

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        SOQLUtil mtQuery = new SOQLUtil('Material_Tracking__c');
        mtQuery.addFields(new Set<String>{ 'Id', 'Name', 'Item__c', 'Item__r.Stocking_UOM__c' });
        mtQuery.setWhereClause('Work_Order__c = \'' + wo.Id + '\' AND Type__c = \'' + WorkOrderService.MATERIAL_TYPE_KIT + '\'');
        Material_Tracking__c kitMaterial = Database.query(mtQuery.getQuery());

        Lot__c lot = new Lot__c(Company__c = wo.Company__c, Item__c = kitMaterial.Item__c, Name = 'LOT1', Expiration_Date__c = System.today() + 365);
        insert lot;
        insert new SKID__c(
            Company__c = wo.Company__c,
            Type__c = SkidService3.SKID_TYPE_WIP,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Stocking_UOM__c = kitMaterial.Item__r.Stocking_UOM__c,
            Item__c = kitMaterial.Item__c,
            Container_Item__c = kitMaterial.Item__c,
            Packaging_UOM__c = kitMaterial.Item__r.Stocking_UOM__c,
            Facility2__c = wo.Facility__c,
            Location__c = wo.Default_WIP_Location__c,
            Lot__c = lot.Id,
            Lot_Number__c = lot.Name,
            Expiration_Date__c = lot.Expiration_Date__c,
            Material_Tracking__c = kitMaterial.Id
        );

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        Test.setCurrentPage(Page.WorkOrderCompleteV2);
        ApexPages.currentPage().getParameters().put('wo', wo.Id);
        ApexPages.currentPage().getParameters().put('op', operation.Id);
        WorkOrderCompleteExtV2 completeExt = new WorkOrderCompleteExtV2();

        Boolean last = completeExt.last;
        System.assert(last == true, completeExt);

        JsonResult result = WorkOrderCompleteExtV2.getConversionFactor(wo, wo.Packaging_UOM__c);
        String str = completeExt.headerFieldsJson;
        str = completeExt.assemblyFieldsJson;
        str = completeExt.transactionFieldsJson;
        str = completeExt.materialFieldsJson;
        str = completeExt.byproductFieldsJson;
        str = completeExt.repairEditableFieldsJson;
        str = completeExt.serialFieldsJson;
        str = completeExt.serialAttributesJson;
        Integer inte = completeExt.gridSize;
        inte = completeExt.assemblyGridSize;
        completeExt.cancel();
        str = completeExt.namespaceUU;
        str = completeExt.serialAttributes;
        str = completeExt.serialFieldList;
        str = completeExt.woId;
        str = completeExt.opId;
        completeExt.getAssemblyFieldListWithAllAttributes();
        completeExt.getBackflushDetailFieldList();
        completeExt.getIssueFromWipDetailFieldList();
        WorkOrderCompleteExtV2.refreshTrackedAttr(null, null);
        completeExt.getByproductsFieldList();

        result = WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 1, result.records);

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)result.records[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Item__r.Stocking_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Used__c = 2;
        assembly.skid.Quantity_Scrapped__c = 2;
        assembly.skid.Input_Quantity__c = 1;

        result = WorkOrderCompleteExtV2.getBackflushData(wo.Id, operation.Id, true);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 1, result.records);

        List<WorkOrderWrapper> components = (List<WorkOrderWrapper>)result.records;
        System.assert(components[0].serialWrapperList.size() == 2, components[0].serialWrapperList);
        components[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        components[0].serialWrapperList[0].skid.Quantity_to_Scrap__c = 1;
        components[0].serialWrapperList.remove(1);

        result = WorkOrderCompleteExtV2.getByproductData(wo.Id, operation.Id, true);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 1, result.records);

        List<SkidService3.SerialWrapper> byproducts = (List<SkidService3.SerialWrapper>)result.records;
        System.assert(byproducts[0].skid.Packaging_UOM__c == byproducts[0].skid.Material_Tracking__r.Item__r.Stocking_UOM__c, byproducts[0].skid.Packaging_UOM__r);
        System.assert(byproducts[0].skid.Container_Item__c == byproducts[0].skid.Material_Tracking__r.Item__c, byproducts[0].skid.Container_Item__r);
        System.assert(byproducts[0].skid.Location__c == fuel.location3.Id, byproducts[0].skid.Location__r);
        byproducts[0].skid.Lot_Number__c = 'bpLot1';
        byproducts[0].skid.Expiration_Date__c = System.today() + 365;
        byproducts[0].skid.Quantity__c = 1;

        result = WorkOrderCompleteExtV2.getIssueFromWIPData(wo.Id, true);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 1, result.records);

        List<WorkOrderWrapper> wipComponents = (List<WorkOrderWrapper>)result.records;
        System.assert(wipComponents[0].serialWrapperList.size() == 1, wipComponents[0].serialWrapperList);
        wipComponents[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        components.addAll(wipComponents);

        result = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, components, byproducts, null);
        System.assert(result.success == true, result);

        Test.stopTest();
        
        wo = WorkOrderService.getWorkOrders(new Set<Id>{wo.Id},null,null,new Set<String>{'Material_Trackings__r','Operation_Trackings__r'})[0];

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{'From_Lot__r.Name','Lot__r.Name'});
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.addAllCustomFields(Inventory_Change__c.sObjectType,'Inventory_Change__r');
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\'');
        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());

        SOQLUtil otQuery = new SOQLUtil('Operation_Transaction__c');
        otQuery.addAllCustomFields();
        otQuery.addField('Lot__r.Name');
        otQuery.setWhereClause('Work_Order__c = \'' + wo.Id + '\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(otQuery, 'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        otQuery.addChildRelationship(stQuery);
        
        List<Operation_Transaction__c> otList = Database.query(otQuery.getQuery());

        System.assert(wo.Status__c == 'In Process',wo);
        System.assert(wo.Quantity_Complete__c == 2,wo);
        System.assert(wo.Quantity_Scrapped__c == 2,wo);
        System.assert(wo.Material_Trackings__r.size() == 3,wo.Material_Trackings__r);
        System.assert(wo.Operation_Trackings__r.size() == 1,wo.Operation_Trackings__r);
        System.assert(otList.size() == 1,otList);

        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Backflush') {
                System.assert(mt.Quantity_Issued__c == 2,mt);
                System.assert(mt.Quantity_Used__c == 1,mt);
                System.assert(mt.Quantity_Scrapped__c == 1,mt);
            } else if (mt.Type__c == 'By-product') {
                System.assert(mt.Quantity_Completed__c == 1,mt);
            } else if (mt.Type__c == 'Kit') {
                System.assert(mt.Quantity_Issued__c == 0,mt);   //did not actually kit
                System.assert(mt.Quantity_Used__c == 1,mt);
                System.assert(mt.Quantity_Scrapped__c == 0,mt);
            } else {
                System.assert(false,'Unxpected material type: ' + mt.Type__c);
            }
        }

        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            System.assert(op.Quantity_Completed__c == 2,op);
            System.assert(op.Quantity_Scrapped__c == 2,op);
            System.assert(op.Hours_Consumed__c == 1,op);
        }

        for (Operation_Transaction__c ot:otList) {
            if (ot.Operation_Tracking__c == operation.Id) {
                System.assert(ot.Quantity_Completed__c == 2,ot);
                System.assert(ot.Quantity_Scrapped__c == 2,ot);
                System.assert(ot.Hours_Consumed__c == 1,ot);
                System.assert(ot.Item__c == wo.Item__c,ot);
                System.assert(ot.Location__c == wo.Complete_to_Location__c,ot);
                System.assert(ot.Lot__r.Name == 'COMPLOT1',ot);
                System.assert(ot.Serial_Transactions__r.size() == 0, ot.Serial_Transactions__r);
            } else {
                System.assert(false,'Unxpected operation transaction');
            }
        }

        //1 assembly complete, 1 assembly scrap, 1 byproduct, 3 backflush, 1 for kit
        System.assert(itList.size() == 7,itList);

        Integer completeCt = 0,scrapCt = 0,bIssueCt = 0,bWipCt = 0,bScrapCt = 0,bpCt = 0,wipCt = 0;

        for (Inventory_Transaction__c it:itList) {
            if (it.Item__c == fuel.itemList[5].Id) {
                if (it.Type__c == 'Work Order Assembly Completion') {
                    System.assert(it.Quantity__c == 2,it);
                    System.assert(it.Lot__r.Name == 'COMPLOT1',it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 2,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'Location',it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == wo.Complete_To_Location__c,it.To_SKID__r);

                    completeCt++;
                } else if (it.Type__c == 'Work Order Assembly Scrap') {
                    System.assert(it.Quantity__c == 2,it);
                    System.assert(it.Lot__r.Name == 'COMPLOT1',it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 2,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'Location',it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == wo.MRB_Location__c,it.To_SKID__r);

                    scrapCt++;
                } else {
                    System.assert(false,'Unexpected IT type for assembly: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[0].Id) {
                if (it.Type__c == 'Work Order Component Issue') {
                    System.assert(it.Quantity__c == 2,it);
                    System.assert(it.To_SKID__c == null,it);

                    System.assert(it.From_SKID__c != null,it);
                    System.assert(it.From_SKID__r.Quantity__c == 98,it.From_SKID__r);

                    bIssueCt++;
                } else if (it.Type__c == 'Work Order Issue From WIP') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.From_SKID__c == null,it);
                    System.assert(it.To_SKID__c == null,it);

                    bWipCt++;
                } else if (it.Type__c == 'Work Order Component Scrap') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'Location',it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == wo.MRB_Location__c,it.To_SKID__r);

                    bScrapCt++;
                } else {
                    System.assert(false,'Unexpected IT type for backflush: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[1].Id) {
                if (it.Type__c == 'By-product') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.Lot__r.Name == 'BPLOT1',it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'Location',it.To_SKID__r);

                    bpCt++;
                } else {
                    System.assert(false,'Unexpected IT type for byproduct: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[2].Id) {
                if (it.Type__c == 'Work Order Issue From WIP') {
                    System.assert(it.Quantity__c == 1,it);

                    System.assert(it.From_SKID__c != null,it);
                    System.assert(it.From_SKID__r.Quantity__c == 99,it.From_SKID__r);
                    System.assert(it.From_SKID__r.Type__c == 'WIP',it.From_SKID__r);
                    System.assert(it.From_SKID__r.Location__c == wo.Default_WIP_Location__c,it.From_SKID__r);
                    System.assert(it.To_SKID__c == null,it);

                    wipCt++;
                } else {
                    System.assert(false,'Unexpected IT type for kit: ' + it.Type__c);
                }
            } else {
                System.assert(false,'Unepxected item on IT');
            }
        }

        System.assert(completeCt == 1);
        System.assert(scrapCt == 1);
        System.assert(bIssueCt == 1);
        System.assert(bWipCt == 1);
        System.assert(bScrapCt == 1);
        System.assert(bpCt == 1);
        System.assert(wipCt == 1);
    }

    private static testMethod void testNoRoutingsSerials() {
        delete [SELECT Id FROM Routing__c];

        fuel.components[0].Type__c = 'Kit';
        Component__c byproduct = fuel.components[0].clone(false,true);
        byproduct.Component_Item__c = fuel.itemList[1].Id;
        byproduct.Type__c = 'By-product';
        byproduct.Component_Sequence__c = null;
        fuel.components.add(byproduct);
        upsert fuel.components;

        fuel.setupInventory(true, true);

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        SOQLUtil mtQuery = new SOQLUtil('Material_Tracking__c');
        mtQuery.addFields(new Set<String>{ 'Id', 'Name', 'Item__c', 'Item__r.Stocking_UOM__c' });
        mtQuery.setWhereClause('Work_Order__c = \'' + wo.Id + '\' AND Type__c = \'' + WorkOrderService.MATERIAL_TYPE_KIT + '\'');
        Material_Tracking__c kitMaterial = Database.query(mtQuery.getQuery());

        Lot__c lot = new Lot__c(Company__c = wo.Company__c, Item__c = kitMaterial.Item__c, Name = 'LOT1', Expiration_Date__c = System.today() + 365);
        insert lot;
        SKID__c wipSkid = new SKID__c(
            Company__c = wo.Company__c,
            Type__c = SkidService3.SKID_TYPE_WIP,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Stocking_UOM__c = kitMaterial.Item__r.Stocking_UOM__c,
            Item__c = kitMaterial.Item__c,
            Container_Item__c = kitMaterial.Item__c,
            Packaging_UOM__c = kitMaterial.Item__r.Stocking_UOM__c,
            Facility2__c = wo.Facility__c,
            Location__c = wo.Default_WIP_Location__c,
            Lot__c = lot.Id,
            Lot_Number__c = lot.Name,
            Expiration_Date__c = lot.Expiration_Date__c,
            Material_Tracking__c = kitMaterial.Id
        );
        insert wipSkid;

        List<Serial__c> serials = new List<Serial__c>();
        for (Integer i = 0; i < 100; i++) {
            serials.add(new Serial__c(
                Name = 'SERIAL' + i,
                Company__c = wo.Company__c,
                Item__c = kitMaterial.Item__c,
                SKID__c = wipSkid.Id,
                Unique_Key2__c = wo.Company__c + '-' + kitMaterial.Item__c + '-' + 'SERIAL' + i
            ));
        }
        insert serials;

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Item__r.Stocking_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Used__c = 2;
        assembly.skid.Quantity_Scrapped__c = 2;
        assembly.skid.Input_Quantity__c = 1;
        assembly.serialList = new List<Serial__c>{
            new Serial__c(Name = 'SERIAL1', Temporary_Value_Holder__c = 'Complete'),
            new Serial__c(Name = 'SERIAL2', Temporary_Value_Holder__c = 'Complete'),
            new Serial__c(Name = 'SERIAL3', Temporary_Value_Holder__c = 'Scrap'),
            new Serial__c(Name = 'SERIAL4', Temporary_Value_Holder__c = 'Scrap')
        };

        List<WorkOrderWrapper> components = (List<WorkOrderWrapper>)WorkOrderCompleteExtV2.getBackflushData(wo.Id, operation.Id, true).records;
        components[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;
        components[0].serialWrapperList[0].skid.Quantity_to_Scrap__c = 1;
        System.assert(components[0].serialWrapperList[0].serialList.size() > 0, components[0].serialWrapperList[0].serialList);
        components[0].serialWrapperList[0].serialList[0].Temporary_Value_Holder__c = 'SERIAL1';
        components[0].serialWrapperList[0].serialList[1].Temporary_Value_Holder__c = 'SERIAL2';
        components[0].serialWrapperList[0].serialList[2].Temporary_Value_Holder__c = 'SERIAL3';
        components[0].serialWrapperList[0].serialList[3].Temporary_Value_Holder__c = 'SERIAL4';
        components[0].serialWrapperList[0].serialList[4].Temporary_Value_Holder__c = 'COMPONENT SCRAP';
        components[0].serialWrapperList[0].serialList = new List<Serial__c>{
            components[0].serialWrapperList[0].serialList[0],
            components[0].serialWrapperList[0].serialList[1],
            components[0].serialWrapperList[0].serialList[2],
            components[0].serialWrapperList[0].serialList[3],
            components[0].serialWrapperList[0].serialList[4]
        };
        components[0].serialWrapperList.remove(1);

        List<SkidService3.SerialWrapper> byproducts = (List<SkidService3.SerialWrapper>)WorkOrderCompleteExtV2.getByproductData(wo.Id, operation.Id, true).records;
        System.assert(byproducts[0].skid.Packaging_UOM__c == byproducts[0].skid.Material_Tracking__r.Item__r.Stocking_UOM__c, byproducts[0].skid.Packaging_UOM__r);
        System.assert(byproducts[0].skid.Container_Item__c == byproducts[0].skid.Material_Tracking__r.Item__c, byproducts[0].skid.Container_Item__r);
        System.assert(byproducts[0].skid.Location__c == fuel.location3.Id, byproducts[0].skid.Location__r);
        byproducts[0].skid.Lot_Number__c = 'bpLot1';
        byproducts[0].skid.Expiration_Date__c = System.today() + 365;
        byproducts[0].skid.Quantity__c = 1;
        byproducts[0].serialList = new List<Serial__c>{ new Serial__c(Name = 'SERIAL1') };

        List<WorkOrderWrapper> wipComponents = (List<WorkOrderWrapper>)WorkOrderCompleteExtV2.getIssueFromWIPData(wo.Id, true).records;
        wipComponents[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;
        System.assert(wipComponents[0].serialWrapperList[0].serialList.size() > 0, wipComponents[0].serialWrapperList[0].serialList);
        wipComponents[0].serialWrapperList[0].serialList[0].Temporary_Value_Holder__c = 'SERIAL1';
        wipComponents[0].serialWrapperList[0].serialList[1].Temporary_Value_Holder__c = 'SERIAL2';
        wipComponents[0].serialWrapperList[0].serialList[2].Temporary_Value_Holder__c = 'SERIAL3';
        wipComponents[0].serialWrapperList[0].serialList[3].Temporary_Value_Holder__c = 'SERIAL4';
        wipComponents[0].serialWrapperList[0].serialList = new List<Serial__c>{
            wipComponents[0].serialWrapperList[0].serialList[0],
            wipComponents[0].serialWrapperList[0].serialList[1],
            wipComponents[0].serialWrapperList[0].serialList[2],
            wipComponents[0].serialWrapperList[0].serialList[3]
        };
        components.addAll(wipComponents);

        JsonResult result = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, components, byproducts, null);
        System.assert(result.success == true, result);

        Test.stopTest();

        wo = WorkOrderService.getWorkOrders(new Set<Id>{wo.Id},null,null,new Set<String>{'Material_Trackings__r','Operation_Trackings__r'})[0];

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{'From_Lot__r.Name','Lot__r.Name'});
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.addAllCustomFields(Inventory_Change__c.sObjectType,'Inventory_Change__r');
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery,'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial_Parent__r');
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());

        SOQLUtil otQuery = new SOQLUtil('Operation_Transaction__c');
        otQuery.addAllCustomFields();
        otQuery.addField('Lot__r.Name');
        otQuery.setWhereClause('Work_Order__c = \'' + wo.Id + '\'');

        SOQLUtil.ChildRelationship stQuery2 = new SOQLUtil.ChildRelationship(otQuery, 'Serial_Transactions__r');
        stQuery2.addAllCustomFields();
        otQuery.addChildRelationship(stQuery2);
        
        List<Operation_Transaction__c> otList = Database.query(otQuery.getQuery());

        System.assert(wo.Status__c == 'In Process',wo);
        System.assert(wo.Quantity_Complete__c == 2,wo);
        System.assert(wo.Quantity_Scrapped__c == 2,wo);
        System.assert(wo.Material_Trackings__r.size() == 3,wo.Material_Trackings__r);
        System.assert(wo.Operation_Trackings__r.size() == 1,wo.Operation_Trackings__r);

        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Backflush') {
                System.assert(mt.Quantity_Issued__c == 5,mt);
                System.assert(mt.Quantity_Used__c == 4,mt);
                System.assert(mt.Quantity_Scrapped__c == 1,mt);
            } else if (mt.Type__c == 'By-product') {
                System.assert(mt.Quantity_Completed__c == 1,mt);
            } else if (mt.Type__c == 'Kit') {
                System.assert(mt.Quantity_Issued__c == 0,mt);   //did not actually kit
                System.assert(mt.Quantity_Used__c == 4,mt);
                System.assert(mt.Quantity_Scrapped__c == 0,mt);
            } else {
                System.assert(false,'Unxpected material type: ' + mt.Type__c);
            }
        }

        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            System.assert(op.Quantity_Completed__c == 2,op);
            System.assert(op.Quantity_Scrapped__c == 2,op);
            System.assert(op.Hours_Consumed__c == 1,op);
        }

        for (Operation_Transaction__c ot:otList) {
            if (ot.Operation_Tracking__c == operation.Id) {
                System.assert(ot.Quantity_Completed__c == 2,ot);
                System.assert(ot.Quantity_Scrapped__c == 2,ot);
                System.assert(ot.Hours_Consumed__c == 1,ot);
                System.assert(ot.Item__c == wo.Item__c,ot);
                System.assert(ot.Location__c == wo.Complete_to_Location__c,ot);
                System.assert(ot.Lot__r.Name == 'COMPLOT1',ot);
                System.assert(ot.Serial_Transactions__r.size() == ot.Quantity_Completed__c + ot.Quantity_Scrapped__c, ot.Serial_Transactions__r);
            } else {
                System.assert(false,'Unxpected operation transaction');
            }
        }

        //1 assembly complete, 1 assembly scrap, 1 byproduct, 3 backflush, 1 for kit
        System.assert(itList.size() == 7,itList);

        Integer completeCt = 0,scrapCt = 0,bIssueCt = 0,bWipCt = 0,bScrapCt = 0,bpCt = 0,wipCt = 0;

        for (Inventory_Transaction__c it:itList) {
            if (it.Item__c == fuel.itemList[5].Id) {
                if (it.Type__c == 'Work Order Assembly Completion') {
                    System.assert(it.Quantity__c == 2,it);
                    System.assert(it.Lot__r.Name == 'COMPLOT1',it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 2,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'Location',it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == wo.Complete_To_Location__c,it.To_SKID__r);

                    System.assert(it.Serial_Transactions__r.size() == 2,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'Assembly Completion',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.SKID__c == it.To_SKID__c);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    completeCt++;
                } else if (it.Type__c == 'Work Order Assembly Scrap') {
                    System.assert(it.Quantity__c == 2,it);
                    System.assert(it.Lot__r.Name == 'COMPLOT1',it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 2,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'Location',it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == wo.MRB_Location__c,it.To_SKID__r);

                    System.assert(it.Serial_Transactions__r.size() == 2,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'Assembly Scrap',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.SKID__c == it.To_SKID__c);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    scrapCt++;
                } else {
                    System.assert(false,'Unexpected IT type for assembly: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[0].Id) {
                if (it.Type__c == 'Work Order Component Issue') {
                    System.assert(it.Quantity__c == 5,it);
                    System.assert(it.To_SKID__c == null,it);

                    System.assert(it.From_SKID__c != null,it);
                    System.assert(it.From_SKID__r.Quantity__c == 5,it.From_SKID__r);

                    // System.assert(it.Serial_Transactions__r.size() == 5,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'Component Issue',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    bIssueCt++;
                } else if (it.Type__c == 'Work Order Issue From WIP') {
                    System.assert(it.Quantity__c == 4,it);
                    System.assert(it.From_SKID__c == null,it);
                    System.assert(it.To_SKID__c == null,it);

                    System.assert(it.Serial_Transactions__r.size() == 4,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'WIP Translate',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c != null,st);
                        System.assert(st.Serial__r.SKID__c == null,st.Serial__r);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    bWipCt++;
                } else if (it.Type__c == 'Work Order Component Scrap') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'Location',it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == wo.MRB_Location__c,it.To_SKID__r);

                    System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'Component Scrap',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.SKID__c == it.To_SKID__c);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    bScrapCt++;
                } else {
                    System.assert(false,'Unexpected IT type for backflush: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[1].Id) {
                if (it.Type__c == 'By-product') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.Lot__r.Name == 'BPLOT1',it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'Location',it.To_SKID__r);

                    System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'By-product Completion',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.SKID__c == it.To_SKID__c);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    bpCt++;
                } else {
                    System.assert(false,'Unexpected IT type for byproduct: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[2].Id) {
                if (it.Type__c == 'Work Order Issue From WIP') {
                    System.assert(it.Quantity__c == 4,it);

                    System.assert(it.From_SKID__c != null,it);
                    System.assert(it.From_SKID__r.Quantity__c == 96,it.From_SKID__r);
                    System.assert(it.From_SKID__r.Type__c == 'WIP',it.From_SKID__r);
                    System.assert(it.From_SKID__r.Location__c == wo.Default_WIP_Location__c,it.From_SKID__r);
                    System.assert(it.To_SKID__c == null,it);

                    System.assert(it.Serial_Transactions__r.size() == 4,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'WIP Translate',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c != null,st);
                        System.assert(st.Serial__r.SKID__c == null,st.Serial__r);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    wipCt++;
                } else {
                    System.assert(false,'Unexpected IT type for kit: ' + it.Type__c);
                }
            } else {
                System.assert(false,'Unepxected item on IT');
            }
        }

        System.assert(completeCt == 1);
        System.assert(scrapCt == 1);
        System.assert(bIssueCt == 1);
        System.assert(bWipCt == 1);
        System.assert(bScrapCt == 1);
        System.assert(bpCt == 1);
        System.assert(wipCt == 1);
    }

    private static testMethod void testRoutingsNoSerials() {
        fuel.components[0].Type__c = 'Kit';
        fuel.components[1].Routing__c = fuel.routings[1].Id;
        Component__c byproduct = fuel.components[0].clone(false,true);
        byproduct.Component_Item__c = fuel.itemList[1].Id;
        byproduct.Type__c = 'By-product';
        byproduct.Component_Sequence__c = null;
        byproduct.Routing__c = null;
        fuel.components.add(byproduct);
        upsert fuel.components;

        //kit = operation[0], backflush = operation[1], byproduct = no operation

        fuel.setupInventory(true);

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[2];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, false).records[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Item__r.Stocking_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Quantity_Scrapped__c = 1;
        assembly.skid.Input_Quantity__c = 1;

        List<WorkOrderWrapper> components = (List<WorkOrderWrapper>)WorkOrderCompleteExtV2.getBackflushData(wo.Id, operation.Id, false).records;
        System.assert(components[0].material.Type__c == WorkOrderService.MATERIAL_TYPE_KIT, components[0].material);
        components[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        components[0].serialWrapperList.remove(1);

        List<SkidService3.SerialWrapper> byproducts = (List<SkidService3.SerialWrapper>)WorkOrderCompleteExtV2.getByproductData(wo.Id, operation.Id, false).records;
        System.assert(byproducts.size() == 0, byproducts);

        List<WorkOrderWrapper> wipComponents = (List<WorkOrderWrapper>)WorkOrderCompleteExtV2.getIssueFromWIPData(wo.Id, false).records;
        System.assert(wipComponents.size() == 0, wipComponents);

        JsonResult result = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, components, null, null);
        System.assert(result.success == true, result);

        Test.stopTest();

        wo = WorkOrderService.getWorkOrders(new Set<Id>{wo.Id},null,null,new Set<String>{'Material_Trackings__r','Operation_Trackings__r'})[0];

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{'From_Lot__r.Name','Lot__r.Name'});
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.addAllCustomFields(Inventory_Change__c.sObjectType,'Inventory_Change__r');
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\'');
        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());

        SOQLUtil otQuery = new SOQLUtil('Operation_Transaction__c');
        otQuery.addAllCustomFields();
        otQuery.addField('Lot__r.Name');
        otQuery.setWhereClause('Work_Order__c = \'' + wo.Id + '\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(otQuery, 'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        otQuery.addChildRelationship(stQuery);
        
        List<Operation_Transaction__c> otList = Database.query(otQuery.getQuery());

        System.assert(wo.Status__c == 'In Process',wo);
        System.assert(wo.Quantity_Complete__c == 0 || wo.Quantity_Complete__c == null,wo);
        System.assert(wo.Quantity_Scrapped__c == 1,wo);
        System.assert(wo.Material_Trackings__r.size() == 3,wo.Material_Trackings__r);
        System.assert(wo.Operation_Trackings__r.size() == 3,wo.Operation_Trackings__r);

        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Backflush') {
                System.assert(mt.Quantity_Issued__c == 0,mt);
                System.assert(mt.Quantity_Used__c == 0,mt);
                System.assert(mt.Quantity_Scrapped__c == 0,mt);
            } else if (mt.Type__c == 'By-product') {
                System.assert(mt.Quantity_Completed__c == 0,mt);
            } else if (mt.Type__c == 'Kit') {
                System.assert(mt.Quantity_Issued__c == 1,mt);
                System.assert(mt.Quantity_Used__c == 1,mt);
                System.assert(mt.Quantity_Scrapped__c == 0,mt);
            } else {
                System.assert(false,'Unxpected material type: ' + mt.Type__c);
            }
        }

        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            if ( op.Id ==  operation.Id) {
                System.assert(op.Quantity_Scrapped__c == 1,op);
            } else {
                System.assert(op.Quantity_Scrapped__c == 0,op);
            }
            System.assert(op.Serial_List__c == null,op);
            if (op.Quantity_Completed__c == 0) {
                System.assert(op.Hours_Consumed__c == 0,op);
            } else if (op.Quantity_Completed__c == 1) {
                System.assert(op.Hours_Consumed__c == 1,op);
            } else {
                System.assert(false,'Unexpected operation: ' + op);
            }
        }

        for (Operation_Transaction__c ot:otList) {
            if (ot.Operation_Tracking__c == operation.Id) {
                System.assert(ot.Quantity_Completed__c == 1,ot);
                System.assert(ot.Quantity_Scrapped__c == 1,ot);
                System.assert(ot.Hours_Consumed__c == 1,ot);
                System.assert(ot.Item__c == wo.Item__c,ot);
                System.assert(ot.Location__c == wo.Default_WIP_Location__c,ot);
                System.assert(ot.Lot__r.Name == 'COMPLOT1',ot);
                System.assert(ot.Serial_Transactions__r.size() == 0, ot.Serial_Transactions__r);
            } else {
                System.assert(false,'Unxpected operation transaction');
            }
        }

        //2 for kit, 1 for Scrap
        System.assert(itList.size() == 3,itList);

        Integer wipIssueCt = 0,wipWipCt = 0;

        for (Inventory_Transaction__c it:itList) {
            if (it.Item__c == fuel.itemList[2].Id) {
                if (it.Type__c == 'Work Order Component Issue') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.To_SKID__c == null,it);

                    System.assert(it.From_SKID__c != null,it);
                    System.assert(it.From_SKID__r.Quantity__c == 99,it.From_SKID__r);

                    wipIssueCt++;
                } else if (it.Type__c == 'Work Order Issue From WIP') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'WIP',it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == wo.Default_WIP_Location__c,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Item__c == wo.Item__c,it.To_SKID__r);

                    wipWipCt++;
                } else {
                    System.assert(false,'Unexpected IT type for kit: ' + it.Type__c);
                }
            } else if ( it.Type__c != 'Work Order Assembly Scrap' ) {
                System.assert(false,'Unepxected item on IT');
            }
        }

        System.assert(wipIssueCt == 1);
        System.assert(wipWipCt == 1);
    }
    
    // tests wo completion in a different packaging uom
    private static testMethod void testRoutingsNoSerialsMultiUom() {
        List<Id> lstPkgUoms = new List<Id> { fuel.uomList[11].Id, fuel.uomList[12].Id};
        List<Item__c> itemsToUpdate = new List<Item__c>();
        
        fuel.itemList[5].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[5].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[5]);
        fuel.itemList[2].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[2].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[2]);
        fuel.itemList[0].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[0].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[0]);
        update itemsToUpdate;
        
        fuel.itemSpec.Packaging_UOM__c = fuel.uomList[12].Id;
        update fuel.itemSpec;
        
        fuel.workOrder.Packaging_UOM__c = fuel.uomList[12].Id;
        update fuel.workOrder;
        
        delete fuel.components[1];
        
        Lot__c lot = new Lot__c(Item__c=fuel.itemList[2].Id,Name='LOT-1234',Company__c=fuel.company.Id);
        insert lot;

        WorkOrderPlanningService.release(new Set<Id>{fuel.workOrder.Id});
        
        Skid__c sk1 = new SKID__c( Facility2__c=fuel.facility2.Id,
                            Location__c=fuel.location3.Id,
                            Company__c=fuel.company.Id,
                            Quantity__c=100,
                            Quantity_Stocking_UOM__c =100,
                            Item__c=fuel.itemList[2].Id,
                            Type__c='Location',
                            Lot__c=lot.Id,
                            Packaging_UOM__c = fuel.uomList[11].Id,
                            Stocking_UOM__c =fuel.uomList[11].Id,
                            Expiration_Date__c=System.today()+365);
        
        // this skid should not show up in the mtl tracking locn skids...              
        Skid__c sk2 = new SKID__c( Facility2__c=fuel.facility2.Id,
                            Location__c=fuel.location3.Id,
                            Company__c=fuel.company.Id,
                            Quantity__c=100,
                            Quantity_Stocking_UOM__c =100,
                            Item__c=fuel.itemList[2].Id,
                            Type__c='Location',
                            Lot__c=lot.Id,
                            Packaging_UOM__c = fuel.uomList[12].Id,
                            Stocking_UOM__c =fuel.uomList[11].Id,
                            Expiration_Date__c=System.today()+365);                    
        
        insert new List<Skid__c>{sk1,sk2};

        Test.startTest();

        Work_Order__c wo = WorkOrderCompleteExtV2.getWorkOrder(fuel.workorder.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[2];
        
        Decimal convFactor = KSE.getConversionFactor(fuel.itemList[5].Id, null, fuel.uomList[12].Id, fuel.uomList[11].Id, lstPkgUoms );
        Decimal qtyCompleted = 1 * convFactor;
        System.assert(qtyCompleted == 2, qtyCompleted);
        
        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, false).records[0];
        assembly.skid.Quantity_Used__c = qtyCompleted;
        assembly.skid.Quantity_Scrapped__c = qtyCompleted; // scrapping the same qty as completed
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Lot_Number__c = 'compLot1';
        assembly.skid.Input_Quantity__c = 1;
        assembly.skid.Packaging_UOM__c = fuel.uomList[11].Id;

        List<Object> uomData = WorkOrderCompleteExtV2.uomChange(wo.Item__r, wo.Facility__r.Facility_Identifier__c, assembly.skid.Packaging_UOM__c,wo.Packaging_UOM__c).records;
        assembly.skid.Packaging_UOM__r = (UOM__c)uomData[0];
        assembly.skid.Container_Item__r = (Item__c)uomData[1];
        assembly.skid.Container_Item__c = assembly.skid.Container_Item__r.Id;
        assembly.conversionFactor = (Decimal)uomData[2];

        JsonResult backflushResult =  WorkOrderCompleteExtV2.getBackflushData(wo.Id,operation.Id,false);
        System.assert(backflushResult.success == true,backflushResult);
        System.assert(backflushResult.records.size() == 1,backflushResult.records);
        List<WorkOrderWrapper> backflushRows = (List<WorkOrderWrapper>)backflushResult.records;
        System.assert(backflushRows[0].material.Type__c == 'Backflush',backflushRows[0].material);
        System.assert(backflushRows[0].serialWrapperList.size() == 1,backflushRows);
        System.assert ( backflushRows[0].serialWrapperList[0].skid.Packaging_UOM__c == fuel.uomList[11].Id );
        backflushRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = qtyCompleted;

        JsonResult byproductResult =  WorkOrderCompleteExtV2.getByproductData(wo.Id,operation.Id,false);
        System.assert(byproductResult.success == true,byproductResult);
        System.assert(byproductResult.records.size() == 0,byproductResult.records);

        JsonResult wipResult =  WorkOrderCompleteExtV2.getIssueFromWIPData(wo.Id, false);
        System.assert(wipResult.success == true,wipResult);
        System.assert(wipResult.records.size() == 0,wipResult.records);

        JsonResult saveResult = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, backflushRows, null, null);
        System.assert(saveResult.success == true,saveResult);

        Test.stopTest();

        wo = WorkOrderService.getWorkOrders(new Set<Id>{wo.Id},null,null,new Set<String>{'Material_Trackings__r','Operation_Trackings__r'})[0];
		//Check Stocking UOM fields..
		system.assert(wo.Order_Quantity_Stocking_UOM__c ==20 ,wo);
		system.assert(wo.Quantity_to_Complete__c ==9,wo);
		system.assert(wo.Quantity_to_Complete_Stocking_UOM__c ==18,wo.Quantity_to_Complete_Stocking_UOM__c);
		system.assert(wo.Quantity_Scrapped__c ==1,wo);
		system.assert(wo.Quantity_Scrapped_Stocking_UOM__c ==2,wo.Quantity_Scrapped_Stocking_UOM__c);
        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{'From_Lot__r.Name','Lot__r.Name', 'Packaging_UOM__r.Name' });
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.addAllCustomFields(Inventory_Change__c.sObjectType,'Inventory_Change__r');
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\'');
        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());

        SOQLUtil otQuery = new SOQLUtil('Operation_Transaction__c');
        otQuery.addAllCustomFields();
        otQuery.addField('Lot__r.Name');
        otQuery.setWhereClause('Work_Order__c = \'' + wo.Id + '\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(otQuery, 'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        otQuery.addChildRelationship(stQuery);
        
        List<Operation_Transaction__c> otList = Database.query(otQuery.getQuery());

        System.assert(wo.Status__c == 'In Process',wo);
        System.assert(wo.Quantity_Complete__c == 0 || wo.Quantity_Complete__c == null,wo);
        System.assert(wo.Quantity_Scrapped__c == 1,wo);
        System.assert(wo.Material_Trackings__r.size() == 1,wo.Material_Trackings__r);
        System.assert(wo.Operation_Trackings__r.size() == 3,wo.Operation_Trackings__r);

        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Backflush') {
                System.assert(mt.Quantity_Issued__c == 2,mt);
                System.assert(mt.Quantity_Used__c == 2,mt);
                System.assert(mt.Quantity_Scrapped__c == 0,mt);
            } else {
                System.assert(false,'Unxpected material type: ' + mt.Type__c);
            }
        }

        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            if ( op.Id ==  operation.Id) {
                System.assert(op.Quantity_Scrapped__c == ( qtyCompleted/ convFactor),op);
            } else {
                System.assert(op.Quantity_Scrapped__c == 0,op);
            }
            System.assert(op.Serial_List__c == null,op);
            if (op.Quantity_Completed__c == 0) {
                System.assert(op.Hours_Consumed__c == 0,op);
            } else if (op.Quantity_Completed__c == 1) {
                System.assert(op.Hours_Consumed__c == 1,op);
            } else {
                System.assert(false,'Unexpected operation: ' + op);
            }
        }

        for (Operation_Transaction__c ot:otList) {
            if (ot.Operation_Tracking__c == operation.Id) {
                System.assert(ot.Quantity_Completed__c == 1 * convFactor,ot);
                System.assert(ot.Quantity_Scrapped__c == 1 * convFactor,ot);
                System.assert(ot.Hours_Consumed__c == 1,ot);
                System.assert(ot.Item__c == wo.Item__c,ot);
                System.assert(ot.Location__c == wo.Default_WIP_Location__c,ot);
                System.assert(ot.Lot__r.Name == 'COMPLOT1',ot);
                System.assert(ot.Serial_Transactions__r.size() == 0, ot.Serial_Transactions__r);
            } else {
                System.assert(false,'Unxpected operation transaction');
            }
        }

        System.assert(itList.size() == 3,itList.size()  );

        Integer wipIssueCt = 0,wipWipCt = 0;

        for (Inventory_Transaction__c it:itList) {
            if (it.Item__c == fuel.itemList[2].Id) {
                if (it.Type__c == 'Work Order Component Issue') {
                    System.assert(it.Quantity__c == qtyCompleted,it);
                    System.assert(it.Packaging_UOM__c == fuel.uomList[11].id );
                    System.assert(it.Lot__c == lot.Id,it);
                    System.assert(it.To_SKID__c == null,it);

                    System.assert(it.From_SKID__c != null,it);
                    System.assert(it.From_SKID__r.Quantity__c == 98,it.From_SKID__r); // ??

                    wipIssueCt++;
                } else if (it.Type__c == 'Work Order Issue From WIP') {
                    System.assert(it.Quantity__c == qtyCompleted,it);
                    System.assert(it.Packaging_UOM__c == fuel.uomList[11].id);
                    System.assert(it.From_Lot__c == lot.Id,it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == qtyCompleted,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'WIP',it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == wo.Default_WIP_Location__c,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Item__c == wo.Item__c,it.To_SKID__r);

                    wipWipCt++;
                } else {
                    System.assert(false,'Unexpected IT type for backflush: ' + it.Type__c);
                }
            } else if ( it.Type__c != 'Work Order Assembly Scrap' ) {
                System.assert(false,'Unepxected item on IT');
            }
        }

        System.assert(wipIssueCt == 1);
        System.assert(wipWipCt == 1);
    }

    private static testMethod void testRoutingWithSerialsMultiUom () {
        delete [SELECT Id FROM Routing__c];

        fuel.components[0].Type__c = 'Kit';
        Component__c byproduct = fuel.components[0].clone(false,true);
        byproduct.Component_Item__c = fuel.itemList[1].Id;
        byproduct.Type__c = 'By-product';
        byproduct.Component_Sequence__c = null;
        fuel.components.add(byproduct);
        upsert fuel.components;
        
        List<Id> lstPkgUoms = new List<Id> { fuel.uomList[11].Id, fuel.uomList[12].Id};
        
        fuel.itemList[5].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[5].Stocking_UOM__c = fuel.uomList[11].Id;
        
        fuel.itemList[2].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[2].Stocking_UOM__c = fuel.uomList[11].Id;
        
        fuel.itemList[0].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[0].Stocking_UOM__c = fuel.uomList[11].Id;
        
        fuel.itemList[1].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[1].Stocking_UOM__c = fuel.uomList[11].Id;
        update fuel.itemList;
        
        fuel.itemSpec.Packaging_UOM__c = fuel.uomList[12].Id;
        update fuel.itemSpec;
        
        fuel.workOrder.Packaging_UOM__c = fuel.uomList[12].Id;
        update fuel.workOrder;
        
        List<Lot__c> lots = new List<Lot__c>{
            new Lot__c(Item__c=fuel.itemList[0].Id,Name='LOT-1234',Company__c=fuel.company.Id),
            new Lot__c(Item__c=fuel.itemList[2].Id,Name='LOT-123',Company__c=fuel.company.Id)
        };
        insert lots;

        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id,Serial_Number__c = true);

        WorkOrderPlanningService.release(new Set<Id>{fuel.workOrder.Id});

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{fuel.workOrder.Id},null,null,new Set<String>{ 'Operation_Trackings__r', 'Material_Trackings__r' })[0];

        Id kitMaterial;
        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Kit') {
                kitMaterial = mt.Id;
                break;
            }
        }

        Id operationId = wo.Operation_Trackings__r[0].Id;

        List<SKID__c> skids = new List<SKID__c>{
            new SKID__c(Facility2__c=fuel.facility2.Id,Location__c=fuel.location3.Id,Company__c=fuel.company.Id,Quantity__c=100,Quantity_Stocking_UOM__c = 100,Item__c=fuel.itemList[0].Id,Type__c='Location',Lot__c=lots[0].Id,Expiration_Date__c=System.today()+365, Packaging_UOM__c=fuel.uomList[11].Id, Stocking_UOM__c=fuel.uomList[11].Id),
            new SKID__c(Facility2__c=fuel.facility2.Id,Location__c=fuel.location7.Id,Company__c=fuel.company.Id,Quantity__c = 100,Quantity_Stocking_UOM__c = 100,Item__c=fuel.itemList[2].Id,Type__c='WIP',Lot__c=lots[1].Id,Expiration_Date__c=System.today()+365,Material_Tracking__c=kitMaterial, Packaging_UOM__c=fuel.uomList[11].Id, Stocking_UOM__c=fuel.uomList[11].Id)
        };
        insert skids;

        List<Serial__c> bfSerials = new List<Serial__c>();
        List<Serial__c> wipSerials = new List<Serial__c>();
        for (Integer i=0;i<100;i++) {
            bfSerials.add(new Serial__c(Name='SERIAL'+i,Item__c=fuel.itemList[0].Id,Company__c=fuel.company.Id,SKID__c=skids[0].Id,Unique_Key2__c=fuel.company.Id+'-'+fuel.itemList[0].Id+'-'+'SERIAL'+i));
            wipSerials.add(new Serial__c(Name='SERIAL'+i,Item__c=fuel.itemList[2].Id,Company__c=fuel.company.Id,SKID__c=skids[1].Id,Unique_Key2__c=fuel.company.Id+'-'+fuel.itemList[2].Id+'-'+'SERIAL'+i));
        }
        insert bfSerials;
        insert wipSerials;

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(fuel.workorder.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        assembly.skid.Quantity_Used__c = 2;
        assembly.skid.Quantity_Scrapped__c = 2;
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Lot_Number__c = 'compLot1';
        assembly.skid.Input_Quantity__c = 1;
        assembly.skid.Packaging_UOM__c = fuel.uomList[11].Id;

        List<Object> uomData = WorkOrderCompleteExtV2.uomChange(wo.Item__r, wo.Facility__r.Facility_Identifier__c, assembly.skid.Packaging_UOM__c,wo.Packaging_UOM__c).records;
        assembly.skid.Packaging_UOM__r = (UOM__c)uomData[0];
        assembly.skid.Container_Item__r = (Item__c)uomData[1];
        assembly.skid.Container_Item__c = assembly.skid.Container_Item__r.Id;
        assembly.conversionFactor = (Decimal)uomData[2];

        assembly.serialList = new List<Serial__c>{
            new Serial__c(Name='SERIAL1',Temporary_Value_Holder__c='Complete'),
            new Serial__c(Name='SERIAL2',Temporary_Value_Holder__c='Complete'),
            new Serial__c(Name='SERIAL3',Temporary_Value_Holder__c='Scrap'),
            new Serial__c(Name='SERIAL4',Temporary_Value_Holder__c='Scrap')
        };

        JsonResult backflushResult =  WorkOrderCompleteExtV2.getBackflushData(wo.Id,operationId,true);
        System.assert(backflushResult.success == true,backflushResult);
        System.assert(backflushResult.records.size() == 1,backflushResult.records);
        List<WorkOrderWrapper> backflushRows = (List<WorkOrderWrapper>)backflushResult.records;
        System.assert(backflushRows[0].serialWrapperList.size() == 1,backflushRows);
        backflushRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;
        backflushRows[0].serialWrapperList[0].skid.Quantity_to_Scrap__c = 1;
        backflushRows[0].serialWrapperList[0].skid.Packaging_UOM__c = fuel.uomList[11].Id;
        bfSerials[0].Temporary_Value_Holder__c = 'SERIAL1';
        bfSerials[1].Temporary_Value_Holder__c = 'SERIAL2';
        bfSerials[2].Temporary_Value_Holder__c = 'SERIAL3';
        bfSerials[3].Temporary_Value_Holder__c = 'SERIAL4';
        bfSerials[4].Temporary_Value_Holder__c = 'COMPONENT SCRAP';
        backflushRows[0].serialWrapperList[0].serialList = new List<Serial__c>{bfSerials[0],bfSerials[1],bfSerials[2],bfSerials[3],bfSerials[4]};

        JsonResult byproductResult =  WorkOrderCompleteExtV2.getByproductData(wo.Id,operationId,true);
        System.assert(byproductResult.success == true,byproductResult);
        System.assert(byproductResult.records.size() == 1,byproductResult.records);
        List<SkidService3.SerialWrapper> byproductRows = (List<SkidService3.SerialWrapper>)byproductResult.records;
        byproductRows[0].skid.Facility2__c = fuel.facility2.Id;
        byproductRows[0].skid.Facility2__r = fuel.facility2;
        byproductRows[0].skid.Location__c = fuel.location3.Id;
        byproductRows[0].skid.Quantity__c = 1;
        byproductRows[0].skid.Expiration_Date__c = System.today() + 365;
        byproductRows[0].skid.Lot_Number__c = 'bpLot1';
        byproductRows[0].skid.Packaging_UOM__c = fuel.uomList[11].Id;
        byproductRows[0].serialList = new List<Serial__c>{
            new Serial__c(Name='SERIAL1')
        };

        JsonResult wipResult =  WorkOrderCompleteExtV2.getIssueFromWIPData(wo.Id, true);
        System.assert(wipResult.success == true,wipResult);
        System.assert(wipResult.records.size() == 1,wipResult.records);
        List<WorkOrderWrapper> wipRows = (List<WorkOrderWrapper>)wipResult.records;
        System.assert(wipRows[0].serialWrapperList.size() == 1,wipRows);
        wipRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;
        wipRows[0].serialWrapperList[0].skid.Packaging_UOM__c = fuel.uomList[11].Id;
        wipSerials[0].Temporary_Value_Holder__c = 'SERIAL1';
        wipSerials[1].Temporary_Value_Holder__c = 'SERIAL2';
        wipSerials[2].Temporary_Value_Holder__c = 'SERIAL3';
        wipSerials[3].Temporary_Value_Holder__c = 'SERIAL4';
        wipRows[0].serialWrapperList[0].serialList = new List<Serial__c>{wipSerials[0],wipSerials[1],wipSerials[2],wipSerials[3]};

        backflushRows.addAll(wipRows);

        JsonResult saveResult = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, backflushRows, byproductRows,null);
        System.assert(saveResult.success == true,saveResult);

        Test.stopTest();

        wo = WorkOrderService.getWorkOrders(new Set<Id>{wo.Id},null,null,new Set<String>{'Material_Trackings__r','Operation_Trackings__r'})[0];

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{'From_Lot__r.Name','Lot__r.Name'});
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.addAllCustomFields(Inventory_Change__c.sObjectType,'Inventory_Change__r');
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery,'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial_Parent__r');
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());

        SOQLUtil otQuery = new SOQLUtil('Operation_Transaction__c');
        otQuery.addAllCustomFields();
        otQuery.addField('Lot__r.Name');
        otQuery.setWhereClause('Work_Order__c = \'' + wo.Id + '\'');

        SOQLUtil.ChildRelationship stQuery2 = new SOQLUtil.ChildRelationship(otQuery, 'Serial_Transactions__r');
        stQuery2.addAllCustomFields();
        otQuery.addChildRelationship(stQuery2);
        
        List<Operation_Transaction__c> otList = Database.query(otQuery.getQuery());

        System.assert(wo.Status__c == 'In Process',wo);
        System.assert(wo.Quantity_Complete__c == 1,wo);
        System.assert(wo.Quantity_Scrapped__c == 1,wo);
        System.assert(wo.Material_Trackings__r.size() == 3,wo.Material_Trackings__r);
        System.assert(wo.Operation_Trackings__r.size() == 1,wo.Operation_Trackings__r);

        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Backflush') {
                System.assert(mt.Quantity_Issued__c == 5,mt);
                System.assert(mt.Quantity_Used__c == 4,mt);
                System.assert(mt.Quantity_Scrapped__c == 1,mt);
            } else if (mt.Type__c == 'By-product') {
                System.assert(mt.Quantity_Completed__c == 1,mt);
            } else if (mt.Type__c == 'Kit') {
                System.assert(mt.Quantity_Issued__c == 0,mt);   //did not actually kit
                System.assert(mt.Quantity_Used__c == 4,mt);
                System.assert(mt.Quantity_Scrapped__c == 0,mt);
            } else {
                System.assert(false,'Unxpected material type: ' + mt.Type__c);
            }
        }

        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            System.assert(op.Quantity_Completed__c == 1,op);
            System.assert(op.Quantity_Scrapped__c == 1,op);
            System.assert(op.Hours_Consumed__c == 1,op);
        }

        for (Operation_Transaction__c ot:otList) {
            if (ot.Operation_Tracking__c == operationId) {
                System.assert(ot.Quantity_Completed__c == 2,ot);
                System.assert(ot.Quantity_Scrapped__c == 2,ot);
                System.assert(ot.Hours_Consumed__c == 1,ot);
                System.assert(ot.Item__c == wo.Item__c,ot);
                System.assert(ot.Location__c == wo.Complete_to_Location__c,ot);
                System.assert(ot.Lot__r.Name == 'COMPLOT1',ot);
                System.assert(ot.Serial_Transactions__r.size() == 4, ot.Serial_Transactions__r);
            } else {
                System.assert(false,'Unxpected operation transaction');
            }
        }

        //1 assembly complete, 1 assembly scrap, 1 byproduct, 3 backflush, 1 for kit
        System.assert(itList.size() == 7,itList);

        Integer completeCt = 0,scrapCt = 0,bIssueCt = 0,bWipCt = 0,bScrapCt = 0,bpCt = 0,wipCt = 0;

        for (Inventory_Transaction__c it:itList) {
            if (it.Item__c == fuel.itemList[5].Id) {
                if (it.Type__c == 'Work Order Assembly Completion') {
                    System.assert(it.Quantity__c == 2,it);
                    System.assert(it.Lot__r.Name == 'COMPLOT1',it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 2,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'Location',it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == wo.Complete_To_Location__c,it.To_SKID__r);

                    System.assert(it.Serial_Transactions__r.size() == 2,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'Assembly Completion',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.SKID__c == it.To_SKID__c);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    completeCt++;
                } else if (it.Type__c == 'Work Order Assembly Scrap') {
                    System.assert(it.Quantity__c == 2,it);
                    System.assert(it.Lot__r.Name == 'COMPLOT1',it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 2,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'Location',it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == wo.MRB_Location__c,it.To_SKID__r);

                    System.assert(it.Serial_Transactions__r.size() == 2,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'Assembly Scrap',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.SKID__c == it.To_SKID__c);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    scrapCt++;
                } else {
                    System.assert(false,'Unexpected IT type for assembly: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[0].Id) {
                if (it.Type__c == 'Work Order Component Issue') {
                    System.assert(it.Quantity__c == 5,it);
                    System.assert(it.Lot__c == lots[0].Id,it);
                    System.assert(it.To_SKID__c == null,it);

                    System.assert(it.From_SKID__c != null,it);
                    System.assert(it.From_SKID__r.Quantity__c == 95,it.From_SKID__r);

                    // System.assert(it.Serial_Transactions__r.size() == 5,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'Component Issue',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    bIssueCt++;
                } else if (it.Type__c == 'Work Order Issue From WIP') {
                    System.assert(it.Quantity__c == 4,it);
                    System.assert(it.From_Lot__c == lots[0].Id,it);
                    System.assert(it.From_SKID__c == null,it);
                    System.assert(it.To_SKID__c == null,it);

                    System.assert(it.Serial_Transactions__r.size() == 4,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'WIP Translate',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c != null,st);
                        System.assert(st.Serial__r.SKID__c == null,st.Serial__r);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    bWipCt++;
                } else if (it.Type__c == 'Work Order Component Scrap') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.Lot__c == lots[0].Id,it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'Location',it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == wo.MRB_Location__c,it.To_SKID__r);

                    System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'Component Scrap',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.SKID__c == it.To_SKID__c);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    bScrapCt++;
                } else {
                    System.assert(false,'Unexpected IT type for backflush: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[1].Id) {
                if (it.Type__c == 'By-product') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.Lot__r.Name == 'BPLOT1',it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'Location',it.To_SKID__r);

                    System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'By-product Completion',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.SKID__c == it.To_SKID__c);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    bpCt++;
                } else {
                    System.assert(false,'Unexpected IT type for byproduct: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[2].Id) {
                if (it.Type__c == 'Work Order Issue From WIP') {
                    System.assert(it.Quantity__c == 4,it);
                    System.assert(it.From_Lot__c == lots[1].Id,it);

                    System.assert(it.From_SKID__c != null,it);
                    System.assert(it.From_SKID__r.Quantity__c == 96,it.From_SKID__r);
                    System.assert(it.From_SKID__r.Type__c == 'WIP',it.From_SKID__r);
                    System.assert(it.From_SKID__r.Location__c == wo.Default_WIP_Location__c,it.From_SKID__r);
                    System.assert(it.To_SKID__c == null,it);

                    System.assert(it.Serial_Transactions__r.size() == 4,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'WIP Translate',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c != null,st);
                        System.assert(st.Serial__r.SKID__c == null,st.Serial__r);
                        System.assert(st.Serial__r.Temporary_Value_Holder__c == null,st.Serial__r);
                    }

                    wipCt++;
                } else {
                    System.assert(false,'Unexpected IT type for kit: ' + it.Type__c);
                }
            } else {
                System.assert(false,'Unepxected item on IT');
            }
        }

        System.assert(completeCt == 1);
        System.assert(scrapCt == 1);
        System.assert(bIssueCt == 1);
        System.assert(bWipCt == 1);
        System.assert(bScrapCt == 1);
        System.assert(bpCt == 1);
        System.assert(wipCt == 1);
    }
    
    private static testMethod void testRoutingMultiUomFail () {
        delete [SELECT Id FROM Routing__c];

        fuel.components[0].Type__c = 'Kit';
        Component__c byproduct = fuel.components[0].clone(false,true);
        byproduct.Component_Item__c = fuel.itemList[1].Id;
        byproduct.Type__c = 'By-product';
        byproduct.Component_Sequence__c = null;
        fuel.components.add(byproduct);
        upsert fuel.components;
        
        List<Id> lstPkgUoms = new List<Id> { fuel.uomList[11].Id, fuel.uomList[12].Id};
        List<Item__c> itemsToUpdate = new List<Item__c>();
        
        fuel.itemList[5].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[5].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[5]);
        fuel.itemList[2].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[2].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[2]);
        fuel.itemList[0].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[0].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[0]);
        update itemsToUpdate;
        
        fuel.itemSpec.Packaging_UOM__c = fuel.uomList[12].Id;
        update fuel.itemSpec;
        
        fuel.workOrder.Packaging_UOM__c = fuel.uomList[12].Id;
        update fuel.workOrder;
        
        List<Lot__c> lots = new List<Lot__c>{
            new Lot__c(Item__c=fuel.itemList[0].Id,Name='LOT-1234',Company__c=fuel.company.Id),
            new Lot__c(Item__c=fuel.itemList[2].Id,Name='LOT-123',Company__c=fuel.company.Id)
        };
        insert lots;

        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id,Serial_Number__c = true);

        WorkOrderPlanningService.release(new Set<Id>{fuel.workOrder.Id});

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{fuel.workOrder.Id},null,null,new Set<String>{ 'Operation_Trackings__r', 'Material_Trackings__r' })[0];

        Id kitMaterial;
        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Kit') {
                kitMaterial = mt.Id;
                break;
            }
        }

        Id operationId = wo.Operation_Trackings__r[0].Id;

        List<SKID__c> skids = new List<SKID__c>{
            new SKID__c(Facility2__c=fuel.facility2.Id,Location__c=fuel.location3.Id,Company__c=fuel.company.Id,Quantity__c=100,Quantity_Stocking_UOM__c = 100,Item__c=fuel.itemList[0].Id,Type__c='Location',Lot__c=lots[0].Id,Expiration_Date__c=System.today()+365, Packaging_UOM__c=fuel.uomList[11].Id, Stocking_UOM__c=fuel.uomList[11].Id),
            new SKID__c(Facility2__c=fuel.facility2.Id,Location__c=fuel.location7.Id,Company__c=fuel.company.Id,Quantity__c = 100,Quantity_Stocking_UOM__c = 100,Item__c=fuel.itemList[2].Id,Type__c='WIP',Lot__c=lots[1].Id,Expiration_Date__c=System.today()+365,Material_Tracking__c=kitMaterial, Packaging_UOM__c=fuel.uomList[11].Id, Stocking_UOM__c=fuel.uomList[11].Id)
        };
        insert skids;

        List<Serial__c> bfSerials = new List<Serial__c>();
        List<Serial__c> wipSerials = new List<Serial__c>();
        for (Integer i=0;i<100;i++) {
            bfSerials.add(new Serial__c(Name='SERIAL'+i,Item__c=fuel.itemList[0].Id,Company__c=fuel.company.Id,SKID__c=skids[0].Id,Unique_Key2__c=fuel.company.Id+'-'+fuel.itemList[0].Id+'-'+'SERIAL'+i));
            wipSerials.add(new Serial__c(Name='SERIAL'+i,Item__c=fuel.itemList[2].Id,Company__c=fuel.company.Id,SKID__c=skids[1].Id,Unique_Key2__c=fuel.company.Id+'-'+fuel.itemList[2].Id+'-'+'SERIAL'+i));
        }
        insert bfSerials;
        insert wipSerials;

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(fuel.workorder.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        assembly.skid.Quantity_Used__c = 2;
        assembly.skid.Quantity_Scrapped__c = 2;
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Lot_Number__c = 'compLot1';
        assembly.skid.Input_Quantity__c = 1;
        assembly.skid.Packaging_UOM__c = fuel.uomList[11].Id;

        List<Object> uomData = WorkOrderCompleteExtV2.uomChange(wo.Item__r, wo.Facility__r.Facility_Identifier__c, assembly.skid.Packaging_UOM__c,wo.Packaging_UOM__c).records;
        assembly.skid.Packaging_UOM__r = (UOM__c)uomData[0];
        assembly.skid.Container_Item__r = (Item__c)uomData[1];
        assembly.skid.Container_Item__c = assembly.skid.Container_Item__r.Id;
        assembly.conversionFactor = (Decimal)uomData[2];

        assembly.serialList = new List<Serial__c>{
            new Serial__c(Name='SERIAL1',Temporary_Value_Holder__c='Complete'),
            new Serial__c(Name='SERIAL2',Temporary_Value_Holder__c='Complete'),
            new Serial__c(Name='SERIAL3',Temporary_Value_Holder__c='Scrap'),
            new Serial__c(Name='SERIAL4',Temporary_Value_Holder__c='Scrap')
        };

        JsonResult backflushResult =  WorkOrderCompleteExtV2.getBackflushData(wo.Id,operationId,true);
        System.assert(backflushResult.success == true,backflushResult);
        System.assert(backflushResult.records.size() == 1,backflushResult.records);
        List<WorkOrderWrapper> backflushRows = (List<WorkOrderWrapper>)backflushResult.records;
        System.assert(backflushRows[0].serialWrapperList.size() == 1,backflushRows);
        backflushRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;
        backflushRows[0].serialWrapperList[0].skid.Quantity_to_Scrap__c = 1;
        backflushRows[0].serialWrapperList[0].skid.Packaging_UOM__c = fuel.uomList[8].Id;
        bfSerials[0].Temporary_Value_Holder__c = 'SERIAL1';
        bfSerials[1].Temporary_Value_Holder__c = 'SERIAL2';
        bfSerials[2].Temporary_Value_Holder__c = 'SERIAL3';
        bfSerials[3].Temporary_Value_Holder__c = 'SERIAL4';
        bfSerials[4].Temporary_Value_Holder__c = 'COMPONENT SCRAP';
        backflushRows[0].serialWrapperList[0].serialList = new List<Serial__c>{bfSerials[0],bfSerials[1],bfSerials[2],bfSerials[3],bfSerials[4]};

        JsonResult byproductResult =  WorkOrderCompleteExtV2.getByproductData(wo.Id,operationId,true);
        System.assert(byproductResult.success == true,byproductResult);
        System.assert(byproductResult.records.size() == 1,byproductResult.records);
        List<SkidService3.SerialWrapper> byproductRows = (List<SkidService3.SerialWrapper>)byproductResult.records;
        byproductRows[0].skid.Facility2__c = fuel.facility2.Id;
        byproductRows[0].skid.Location__c = fuel.location3.Id;
        byproductRows[0].skid.Quantity__c = 1;
        byproductRows[0].skid.Expiration_Date__c = System.today() + 365;
        byproductRows[0].skid.Lot_Number__c = 'bpLot1';
        byproductRows[0].skid.Packaging_UOM__c = fuel.uomList[8].Id;
        byproductRows[0].serialList = new List<Serial__c>{
            new Serial__c(Name='SERIAL1')
        };

        JsonResult wipResult =  WorkOrderCompleteExtV2.getIssueFromWIPData(wo.Id, true);
        System.assert(wipResult.success == true,wipResult);
        System.assert(wipResult.records.size() == 1,wipResult.records);
        List<WorkOrderWrapper> wipRows = (List<WorkOrderWrapper>)wipResult.records;
        System.assert(wipRows[0].serialWrapperList.size() == 1,wipRows);
        wipRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;
        wipRows[0].serialWrapperList[0].skid.Packaging_UOM__c = fuel.uomList[8].Id;
        wipSerials[0].Temporary_Value_Holder__c = 'SERIAL1';
        wipSerials[1].Temporary_Value_Holder__c = 'SERIAL2';
        wipSerials[2].Temporary_Value_Holder__c = 'SERIAL3';
        wipSerials[3].Temporary_Value_Holder__c = 'SERIAL4';
        wipRows[0].serialWrapperList[0].serialList = new List<Serial__c>{wipSerials[0],wipSerials[1],wipSerials[2],wipSerials[3]};

        backflushRows.addAll(wipRows);

        JsonResult saveResult = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, backflushRows, byproductRows,null);
        System.assert(saveResult.success == false,saveResult);

        Test.stopTest();
        
        Boolean isUOMError = false;
        for ( Map<String,String> msgObj : saveResult.messages ) {
            if ( msgObj.get('message').contains('Invalid from or to UOM for Item Packaging UOM')) {
                isUOMError = true;
            }
        }
        system.assert( isUOMError );
    }
    
    // Tests the case when an invalid packaging UOM is added
    // ex: When the uom is of level higher than the work order packaging uom
    private static testMethod void testRoutingMultiUomFail2 () {
        delete [SELECT Id FROM Routing__c];

        fuel.components[0].Type__c = 'Kit';
        Component__c byproduct = fuel.components[0].clone(false,true);
        byproduct.Component_Item__c = fuel.itemList[1].Id;
        byproduct.Type__c = 'By-product';
        byproduct.Component_Sequence__c = null;
        fuel.components.add(byproduct);
        upsert fuel.components;
        
        List<Id> lstPkgUoms = new List<Id> { fuel.uomList[11].Id, fuel.uomList[12].Id, fuel.uomList[13].Id };
        List<Item__c> itemsToUpdate = new List<Item__c>();
        
        fuel.itemList[5].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[5].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[5]);
        fuel.itemList[2].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[2].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[2]);
        fuel.itemList[0].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[0].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[0]);
        update itemsToUpdate;
        
        fuel.itemSpec.Packaging_UOM__c = fuel.uomList[12].Id;
        update fuel.itemSpec;
        
        fuel.workOrder.Packaging_UOM__c = fuel.uomList[12].Id;
        update fuel.workOrder;
        
        List<Lot__c> lots = new List<Lot__c>{
            new Lot__c(Item__c=fuel.itemList[0].Id,Name='LOT-1234',Company__c=fuel.company.Id),
            new Lot__c(Item__c=fuel.itemList[2].Id,Name='LOT-123',Company__c=fuel.company.Id)
        };
        insert lots;

        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id,Serial_Number__c = true);

        WorkOrderPlanningService.release(new Set<Id>{fuel.workOrder.Id});

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{fuel.workOrder.Id},null,null,new Set<String>{ 'Operation_Trackings__r', 'Material_Trackings__r' })[0];

        Id kitMaterial;
        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Kit') {
                kitMaterial = mt.Id;
                break;
            }
        }

        Id operationId = wo.Operation_Trackings__r[0].Id;

        List<SKID__c> skids = new List<SKID__c>{
            new SKID__c(Facility2__c=fuel.facility2.Id,Location__c=fuel.location3.Id,Company__c=fuel.company.Id,Quantity__c=100,Quantity_Stocking_UOM__c = 100,Item__c=fuel.itemList[0].Id,Type__c='Location',Lot__c=lots[0].Id,Expiration_Date__c=System.today()+365, Packaging_UOM__c=fuel.uomList[11].Id, Stocking_UOM__c=fuel.uomList[11].Id),
            new SKID__c(Facility2__c=fuel.facility2.Id,Location__c=fuel.location7.Id,Company__c=fuel.company.Id,Quantity__c = 100,Quantity_Stocking_UOM__c = 100,Item__c=fuel.itemList[2].Id,Type__c='WIP',Lot__c=lots[1].Id,Expiration_Date__c=System.today()+365,Material_Tracking__c=kitMaterial, Packaging_UOM__c=fuel.uomList[11].Id, Stocking_UOM__c=fuel.uomList[11].Id)
        };
        insert skids;

        List<Serial__c> bfSerials = new List<Serial__c>();
        List<Serial__c> wipSerials = new List<Serial__c>();
        for (Integer i=0;i<100;i++) {
            bfSerials.add(new Serial__c(Name='SERIAL'+i,Item__c=fuel.itemList[0].Id,Company__c=fuel.company.Id,SKID__c=skids[0].Id,Unique_Key2__c=fuel.company.Id+'-'+fuel.itemList[0].Id+'-'+'SERIAL'+i));
            wipSerials.add(new Serial__c(Name='SERIAL'+i,Item__c=fuel.itemList[2].Id,Company__c=fuel.company.Id,SKID__c=skids[1].Id,Unique_Key2__c=fuel.company.Id+'-'+fuel.itemList[2].Id+'-'+'SERIAL'+i));
        }
        insert bfSerials;
        insert wipSerials;

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(fuel.workorder.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        assembly.skid.Quantity_Used__c = 2;
        assembly.skid.Quantity_Scrapped__c = 2;
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Lot_Number__c = 'compLot1';
        assembly.skid.Input_Quantity__c = 1;
        assembly.skid.Packaging_UOM__c = fuel.uomList[13].Id;

        List<Object> uomData = WorkOrderCompleteExtV2.uomChange(wo.Item__r, wo.Facility__r.Facility_Identifier__c, assembly.skid.Packaging_UOM__c,wo.Packaging_UOM__c).records;
        assembly.skid.Packaging_UOM__r = (UOM__c)uomData[0];
        assembly.skid.Container_Item__r = (Item__c)uomData[1];
        assembly.skid.Container_Item__c = assembly.skid.Container_Item__r.Id;
        assembly.conversionFactor = (Decimal)uomData[2];

        assembly.serialList = new List<Serial__c>{
            new Serial__c(Name='SERIAL1',Temporary_Value_Holder__c='Complete'),
            new Serial__c(Name='SERIAL2',Temporary_Value_Holder__c='Complete'),
            new Serial__c(Name='SERIAL3',Temporary_Value_Holder__c='Scrap'),
            new Serial__c(Name='SERIAL4',Temporary_Value_Holder__c='Scrap')
        };

        JsonResult backflushResult =  WorkOrderCompleteExtV2.getBackflushData(wo.Id,operationId,true);
        System.assert(backflushResult.success == true,backflushResult);
        System.assert(backflushResult.records.size() == 1,backflushResult.records);
        List<WorkOrderWrapper> backflushRows = (List<WorkOrderWrapper>)backflushResult.records;
        System.assert(backflushRows[0].serialWrapperList.size() == 1,backflushRows);
        backflushRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;
        backflushRows[0].serialWrapperList[0].skid.Quantity_to_Scrap__c = 1;
        backflushRows[0].serialWrapperList[0].skid.Packaging_UOM__c = fuel.uomList[8].Id;
        bfSerials[0].Temporary_Value_Holder__c = 'SERIAL1';
        bfSerials[1].Temporary_Value_Holder__c = 'SERIAL2';
        bfSerials[2].Temporary_Value_Holder__c = 'SERIAL3';
        bfSerials[3].Temporary_Value_Holder__c = 'SERIAL4';
        bfSerials[4].Temporary_Value_Holder__c = 'COMPONENT SCRAP';
        backflushRows[0].serialWrapperList[0].serialList = new List<Serial__c>{bfSerials[0],bfSerials[1],bfSerials[2],bfSerials[3],bfSerials[4]};

        JsonResult byproductResult =  WorkOrderCompleteExtV2.getByproductData(wo.Id,operationId,true);
        System.assert(byproductResult.success == true,byproductResult);
        System.assert(byproductResult.records.size() == 1,byproductResult.records);
        List<SkidService3.SerialWrapper> byproductRows = (List<SkidService3.SerialWrapper>)byproductResult.records;
        byproductRows[0].skid.Facility2__c = fuel.facility2.Id;
        byproductRows[0].skid.Location__c = fuel.location3.Id;
        byproductRows[0].skid.Quantity__c = 1;
        byproductRows[0].skid.Expiration_Date__c = System.today() + 365;
        byproductRows[0].skid.Lot_Number__c = 'bpLot1';
        byproductRows[0].skid.Packaging_UOM__c = fuel.uomList[8].Id;
        byproductRows[0].serialList = new List<Serial__c>{
            new Serial__c(Name='SERIAL1')
        };

        JsonResult wipResult =  WorkOrderCompleteExtV2.getIssueFromWIPData(wo.Id, true);
        System.assert(wipResult.success == true,wipResult);
        System.assert(wipResult.records.size() == 1,wipResult.records);
        List<WorkOrderWrapper> wipRows = (List<WorkOrderWrapper>)wipResult.records;
        System.assert(wipRows[0].serialWrapperList.size() == 1,wipRows);
        wipRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;
        wipRows[0].serialWrapperList[0].skid.Packaging_UOM__c = fuel.uomList[8].Id;
        wipSerials[0].Temporary_Value_Holder__c = 'SERIAL1';
        wipSerials[1].Temporary_Value_Holder__c = 'SERIAL2';
        wipSerials[2].Temporary_Value_Holder__c = 'SERIAL3';
        wipSerials[3].Temporary_Value_Holder__c = 'SERIAL4';
        wipRows[0].serialWrapperList[0].serialList = new List<Serial__c>{wipSerials[0],wipSerials[1],wipSerials[2],wipSerials[3]};

        backflushRows.addAll(wipRows);

        JsonResult saveResult = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, backflushRows, byproductRows,null);
        System.assert(saveResult.success == false,saveResult);

        Test.stopTest();
    }

    private static testMethod void testPalletCompletion ( ) {
        delete [SELECT Id FROM Routing__c];

        fuel.components[0].Type__c = 'Kit';
        Component__c byproduct = fuel.components[0].clone(false,true);
        byproduct.Component_Item__c = fuel.itemList[1].Id;
        byproduct.Type__c = 'By-product';
        byproduct.Component_Sequence__c = null;
        fuel.components.add(byproduct);
        upsert fuel.components;

        List<Id> lstPkgUoms = new List<Id> { fuel.uomList[11].Id, fuel.uomList[12].Id, fuel.uomList[13].Id};
        List<Item__c> itemsToUpdate = new List<Item__c>();

        fuel.itemList[5].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[5].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[5]);
        fuel.itemList[2].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[2].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[2]);
        fuel.itemList[0].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[0].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[0]);
        update itemsToUpdate;

        fuel.itemSpec.Packaging_UOM__c = fuel.uomList[12].Id;
        update fuel.itemSpec;

        fuel.workOrder.Packaging_UOM__c = fuel.uomList[13].Id;
        update fuel.workOrder;

        List<Lot__c> lots = new List<Lot__c>{
                new Lot__c(Item__c=fuel.itemList[0].Id,Name='LOT-1234',Company__c=fuel.company.Id),
                new Lot__c(Item__c=fuel.itemList[2].Id,Name='LOT-123',Company__c=fuel.company.Id)
        };
        insert lots;

        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id,Serial_Number__c = true);

        WorkOrderPlanningService.release(new Set<Id>{fuel.workOrder.Id});

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{fuel.workOrder.Id},null,null,new Set<String>{ 'Operation_Trackings__r', 'Material_Trackings__r' })[0];

        Id kitMaterial;
        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Kit') {
                kitMaterial = mt.Id;
                break;
            }
        }

        Id operationId = wo.Operation_Trackings__r[0].Id;

        List<SKID__c> skids = new List<SKID__c>{
                new SKID__c(Facility2__c=fuel.facility2.Id,Location__c=fuel.location3.Id,Company__c=fuel.company.Id,Quantity__c=100,Quantity_Stocking_UOM__c = 100,Item__c=fuel.itemList[0].Id,Type__c='Location',Lot__c=lots[0].Id,Expiration_Date__c=System.today()+365, Packaging_UOM__c=fuel.uomList[11].Id, Stocking_UOM__c=fuel.uomList[11].Id),
                new SKID__c(Facility2__c=fuel.facility2.Id,Location__c=fuel.location7.Id,Company__c=fuel.company.Id,Quantity__c = 100,Quantity_Stocking_UOM__c = 100,Item__c=fuel.itemList[2].Id,Type__c='WIP',Lot__c=lots[1].Id,Expiration_Date__c=System.today()+365,Material_Tracking__c=kitMaterial, Packaging_UOM__c=fuel.uomList[11].Id, Stocking_UOM__c=fuel.uomList[11].Id)
        };
        insert skids;

        List<Serial__c> bfSerials = new List<Serial__c>();
        List<Serial__c> wipSerials = new List<Serial__c>();

        Decimal convFactor = KSE.getConversionFactor (fuel.itemList[5].Id, null, fuel.uomList[13].Id,fuel.uomList[11].Id, lstPkgUoms);

        for (Integer i=1;i<=convFactor * 3;i++) {
            bfSerials.add(new Serial__c(Name='SERIAL'+i,Item__c=fuel.itemList[0].Id,Company__c=fuel.company.Id,SKID__c=skids[0].Id,Unique_Key2__c=fuel.company.Id+'-'+fuel.itemList[0].Id+'-'+'SERIAL'+i));
            wipSerials.add(new Serial__c(Name='SERIAL'+i,Item__c=fuel.itemList[2].Id,Company__c=fuel.company.Id,SKID__c=skids[1].Id,Unique_Key2__c=fuel.company.Id+'-'+fuel.itemList[2].Id+'-'+'SERIAL'+i));
        }
        insert bfSerials;
        insert wipSerials;

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(fuel.workorder.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Lot_Number__c = 'compLot1';
        assembly.skid.Input_Quantity__c = 1;
        assembly.skid.Temporary_LPN_Holder__c = 'LPN1';
        assembly.skid.Packaging_UOM__c = fuel.uomList[13].Id;

        List<Object> uomData = WorkOrderCompleteExtV2.uomChange(wo.Item__r, wo.Facility__r.Facility_Identifier__c, assembly.skid.Packaging_UOM__c,wo.Packaging_UOM__c).records;
        assembly.skid.Packaging_UOM__r = (UOM__c)uomData[0];
        assembly.skid.Container_Item__r = (Item__c)uomData[1];
        assembly.skid.Container_Item__c = assembly.skid.Container_Item__r.Id;
        assembly.conversionFactor = (Decimal)uomData[2];

        assembly.serialList = new List<Serial__c>();
        for ( Integer i=1; i <= convFactor; i ++ ) {
            assembly.serialList.add(new Serial__c(Name='SERIAL' + (i),Temporary_Value_Holder__c='Complete'));
        }

        JsonResult backflushResult =  WorkOrderCompleteExtV2.getBackflushData(wo.Id,operationId,true);
        System.assert(backflushResult.success == true,backflushResult);
        System.assert(backflushResult.records.size() == 1,backflushResult.records);
        List<WorkOrderWrapper> backflushRows = (List<WorkOrderWrapper>)backflushResult.records;
        System.assert(backflushRows[0].serialWrapperList.size() == 1,backflushRows);
        backflushRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = convFactor;
        backflushRows[0].serialWrapperList[0].skid.Packaging_UOM__c = fuel.uomList[11].Id;

        List<Serial__c> backflushSerials = new List<Serial__c> ();
        for ( Integer i=0; i < convFactor; i ++ ) {
            bfSerials[i].Temporary_Value_Holder__c = 'SERIAL'+(i+1);
            backflushSerials.add ( bfSerials[i]);
        }
        backflushRows[0].serialWrapperList[0].serialList = backflushSerials;

        List<SkidService3.SerialWrapper> byproductRows = new List<SkidService3.SerialWrapper>();

        JsonResult wipResult =  WorkOrderCompleteExtV2.getIssueFromWIPData(wo.Id, true);
        System.assert(wipResult.success == true,wipResult);
        System.assert(wipResult.records.size() == 1,wipResult.records);
        List<WorkOrderWrapper> wipRows = (List<WorkOrderWrapper>)wipResult.records;
        System.assert(wipRows[0].serialWrapperList.size() == 1,wipRows);
        wipRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = convFactor;
        wipRows[0].serialWrapperList[0].skid.Packaging_UOM__c = fuel.uomList[11].Id;
        List<Serial__c> wipSerials2 = new List<Serial__c> ();
        for ( Integer i=0; i < convFactor; i ++ ) {
            wipSerials[i].Temporary_Value_Holder__c = 'SERIAL'+(i+1);
            wipSerials2.add(wipSerials[i]);
        }
        wipRows[0].serialWrapperList[0].serialList = wipSerials2;

        backflushRows.addAll(wipRows);

        JsonResult saveResult = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, backflushRows, byproductRows,null);
        System.assert(saveResult.success == true,saveResult);

        Test.stopTest();
    }

    private static testMethod void testRoutingsSerials() {
        delete fuel.routings[1];

        fuel.components[0].Type__c = WorkOrderService.MATERIAL_TYPE_KIT;
        fuel.components[1].Routing__c = null;
        Component__c byproduct = fuel.components[0].clone(false, true);
        byproduct.Component_Item__c = fuel.itemList[1].Id;
        byproduct.Type__c = WorkOrderService.MATERIAL_TYPE_BYPRODUCT;
        byproduct.Component_Sequence__c = null;
        byproduct.Routing__c = null;
        fuel.components.add(byproduct);
        upsert fuel.components;

        //kit = operation[0], backflush = no operation, byproduct = no operation

        fuel.setupInventory(true, true);

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[1];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, false).records[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Item__r.Stocking_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Quantity_Scrapped__c = 1;
        assembly.skid.Input_Quantity__c = 1;
        assembly.serialList = new List<Serial__c>{
            new Serial__c(Name = 'SERIAL1', Temporary_Value_Holder__c = 'Complete'),
            new Serial__c(Name = 'SERIAL2', Temporary_Value_Holder__c = 'Scrap')
        };

        List<WorkOrderWrapper> components = (List<WorkOrderWrapper>)WorkOrderCompleteExtV2.getBackflushData(wo.Id, operation.Id, false).records;
        components[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        components[0].serialWrapperList[0].serialList[0].Temporary_Value_Holder__c = 'SERIAL1';
        components[0].serialWrapperList[0].serialList = new List<Serial__c>{ components[0].serialWrapperList[0].serialList[0] };
        components[0].serialWrapperList.remove(1);

        JsonResult result = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, components, null, null);
        System.assert(result.success == true, result);

        wo = WorkOrderService.getWorkOrders(new Set<Id>{wo.Id},null,null,new Set<String>{'Material_Trackings__r','Operation_Trackings__r'})[0];

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{'From_Lot__r.Name','Lot__r.Name'});
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.addAllCustomFields(Inventory_Change__c.sObjectType,'Inventory_Change__r');
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery,'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial_Parent__r');
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());

        SOQLUtil otQuery = new SOQLUtil('Operation_Transaction__c');
        otQuery.addAllCustomFields();
        otQuery.addField('Lot__r.Name');
        otQuery.setWhereClause('Work_Order__c = \'' + wo.Id + '\'');

        SOQLUtil.ChildRelationship stQuery2 = new SOQLUtil.ChildRelationship(otQuery, 'Serial_Transactions__r');
        stQuery2.addAllCustomFields();
        otQuery.addChildRelationship(stQuery2);
        
        List<Operation_Transaction__c> otList = Database.query(otQuery.getQuery());

        System.assert(wo.Status__c == 'In Process',wo);
        System.assert(wo.Quantity_Complete__c == 0 || wo.Quantity_Complete__c == null,wo);
        System.assert(wo.Quantity_Scrapped__c == 1,wo); // KNDY-15369 : If scrapped, quantity will be updated 
        System.assert(wo.Material_Trackings__r.size() == 3,wo.Material_Trackings__r);
        System.assert(wo.Operation_Trackings__r.size() == 2,wo.Operation_Trackings__r);

        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Backflush') {
                System.assert(mt.Quantity_Issued__c == 0,mt);
                System.assert(mt.Quantity_Used__c == 0,mt);
                System.assert(mt.Quantity_Scrapped__c == 0,mt);
            } else if (mt.Type__c == 'By-product') {
                System.assert(mt.Quantity_Completed__c == 0,mt);
            } else if (mt.Type__c == 'Kit') {
                System.assert(mt.Quantity_Issued__c == 1,mt);
                System.assert(mt.Quantity_Used__c == 1,mt);
                System.assert(mt.Quantity_Scrapped__c == 0,mt);
            } else {
                System.assert(false,'Unxpected material type: ' + mt.Type__c);
            }
        }

        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            if ( op.Id == operation.Id) {
                System.assert(op.Quantity_Scrapped__c == 1,op);
            } else {
                System.assert(op.Quantity_Scrapped__c == 0,op);
            }
            if (op.Quantity_Completed__c == 0) {
                System.assert(op.Hours_Consumed__c == 0,op);
            } else if (op.Quantity_Completed__c == 1) {
                System.assert(op.Hours_Consumed__c == 1,op);
            } else {
                System.assert(false,'Unexpected operation: ' + op);
            }
        }

        for (Operation_Transaction__c ot:otList) {
            if (ot.Operation_Tracking__c == operation.Id) {
                System.assert(ot.Quantity_Completed__c == 1,ot);
                System.assert(ot.Quantity_Scrapped__c == 1,ot);
                System.assert(ot.Hours_Consumed__c == 1,ot);
                System.assert(ot.Item__c == wo.Item__c,ot);
                System.assert(ot.Location__c == wo.Default_WIP_Location__c,ot);
                System.assert(ot.Lot__r.Name == 'COMPLOT1',ot);
                System.assert(ot.Serial_Transactions__r.size() == ot.Quantity_Completed__c + ot.Quantity_Scrapped__c, ot.Serial_Transactions__r);
            } else {
                System.assert(false,'Unxpected operation transaction');
            }
        }

        //2 for kit and 1 scrap from previous operation
        System.assert(itList.size() == 3,itList);

        Integer wipIssueCt = 0,wipWipCt = 0;

        Id skidId;

        for (Inventory_Transaction__c it:itList) {
            if (it.Item__c == fuel.itemList[2].Id) {
                if (it.Type__c == 'Work Order Component Issue') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.To_SKID__c == null,it);

                    System.assert(it.From_SKID__c != null,it);
                    System.assert(it.From_SKID__r.Quantity__c == 9,it.From_SKID__r);

                    // System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r.size() );
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'Component Issue',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.SKID__c == null,st.Serial__r);
                    }

                    wipIssueCt++;
                } else if (it.Type__c == 'Work Order Issue From WIP') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.From_SKID__c == null,it);

                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'WIP',it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == wo.Default_WIP_Location__c,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Item__c == wo.Item__c,it.To_SKID__r);

                    skidId = it.To_SKID__c;

                    // System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'WIP Translate',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c != null,st);
                        System.assert(st.Serial__r.SKID__c == null,st.Serial__r);
                    }

                    wipWipCt++;
                } else {
                    System.assert(false,'Unexpected IT type for kit: ' + it.Type__c);
                }
            } else if (it.Type__c != 'Work Order Assembly Scrap' ) {
                System.assert(false,'Unepxected item on IT');
            }
        }

        System.assert(wipIssueCt == 1);
        System.assert(wipWipCt == 1);

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        operation = wo.Operation_Trackings__r[0];

        assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        System.assert(assembly.skid.Quantity_Issued__c > 0, assembly.skid.Packaging_UOM__r);
        assembly.skid.Quantity_Used__c = 1;
        assembly.serialList[0].Temporary_Value_Holder__c = 'Complete';
        assembly.serialList = new List<Serial__c>{ assembly.serialList[0] };

        result = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, null, null, null);
        System.assert(result.success == true, result);
    }

    private static testMethod void testNoRoutingsNoAssemblySerial() {
        delete [SELECT Id FROM Routing__c];
        delete fuel.components[0];

        fuel.setupInventory(true, true);

        Work_Order__c wo = fuel.workOrder;

        delete [SELECT Id FROM SKID__c WHERE Item__c = :wo.Item__c];
        update new Item__c(Id = wo.Item__c, Item_Attribute__c = null);

        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Item__r.Stocking_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Input_Quantity__c = 1;
        assembly.skid.Item__r = wo.Item__r;

        List<WorkOrderWrapper> components = (List<WorkOrderWrapper>)WorkOrderCompleteExtV2.getBackflushData(wo.Id, operation.Id, true).records;
        components[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        components[0].serialWrapperList[0].skid.Item__r = components[0].material.Item__r;
        components[0].serialWrapperList[0].serialList[0].Temporary_Value_Holder__c = 'COMPONENT ISSUE';
        components[0].serialWrapperList[0].serialList = new List<Serial__c>{ components[0].serialWrapperList[0].serialList[0] };
        components[0].serialWrapperList.remove(1);

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, null, assembly, components, null, true) });

        Test.stopTest();
        wo = WorkOrderService.getWorkOrders(new Set<Id>{wo.Id},null,null,new Set<String>{'Material_Trackings__r','Operation_Trackings__r'})[0];
        
        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{'From_Lot__r.Name','Lot__r.Name'});
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.addAllCustomFields(Inventory_Change__c.sObjectType,'Inventory_Change__r');
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\'');
        
        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery,'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial_Parent__r');
        itQuery.addChildRelationship(stQuery);
        
        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        
        SOQLUtil otQuery = new SOQLUtil('Operation_Transaction__c');
        otQuery.addAllCustomFields();
        otQuery.addField('Lot__r.Name');
        otQuery.setWhereClause('Work_Order__c = \'' + wo.Id + '\'');
        List<Operation_Transaction__c> otList = Database.query(otQuery.getQuery());
        
        System.assert(wo.Status__c == 'In Process',wo);
        System.assert(wo.Quantity_Complete__c == 1,wo);
        System.assert(wo.Quantity_Scrapped__c == 0 || wo.Quantity_Scrapped__c == null,wo);
        System.assert(wo.Material_Trackings__r.size() == 1,wo.Material_Trackings__r);
        System.assert(wo.Operation_Trackings__r.size() == 1,wo.Operation_Trackings__r);
        
        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Backflush') {
                System.assert(mt.Quantity_Issued__c == 1,mt);
                System.assert(mt.Quantity_Used__c == 1,mt);
                System.assert(mt.Quantity_Scrapped__c == 0,mt);
            } else {
                System.assert(false,'Unxpected material type: ' + mt.Type__c);
            }
        }
        
        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            System.assert(op.Quantity_Scrapped__c == 0,op);
            if (op.Quantity_Completed__c == 1) {
                System.assert(op.Hours_Consumed__c == 1,op);
            } else {
                System.assert(false,'Unexpected operation: ' + op);
            }
        }

        for (Operation_Transaction__c ot:otList) {
            if (ot.Operation_Tracking__c == operation.Id) {
                System.assert(ot.Quantity_Completed__c == 1,ot);
                System.assert(ot.Quantity_Scrapped__c == 0,ot);
                System.assert(ot.Hours_Consumed__c == 1,ot);
                System.assert(ot.Item__c == wo.Item__c,ot);
                System.assert(ot.Location__c == wo.Complete_to_Location__c,ot);
            } else {
                System.assert(false,'Unxpected operation transaction');
            }
        }
        //1 for completion, 2 for backflush
        System.assert(itList.size() == 3,itList);
        Integer completeCt = 0,bIssueCt = 0,bWipCt = 0;
        for (Inventory_Transaction__c it:itList) {
            if (it.Item__c == fuel.itemList[5].Id) {
                if (it.Type__c == 'Work Order Assembly Completion') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.From_SKID__c == null,it);
                    System.assert(it.To_SKID__c != null,it);
                    System.assert(it.To_SKID__r.Quantity__c == 1,it.To_SKID__r);
                    System.assert(it.To_SKID__r.Type__c == 'Location',it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == wo.Complete_To_Location__c,it.To_SKID__r);
                    System.assert(it.Serial_Transactions__r.size() == 0,it.Serial_Transactions__r);
                    completeCt++;
                } else {
                    System.assert(false,'Unexpected IT type for assembly: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[0].Id) {
                if (it.Type__c == 'Work Order Component Issue') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.To_SKID__c == null,it);
                    System.assert(it.From_SKID__c != null,it);
                    System.assert(it.From_SKID__r.Quantity__c == 9,it.From_SKID__r);
                    // System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r.size());
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'Component Issue',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.SKID__c == null,st.Serial__r);
                    }
                    bIssueCt++;
                } else if (it.Type__c == 'Work Order Issue From WIP') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.From_SKID__c == null,it);
                    System.assert(it.To_SKID__c == null,it);
                    System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
                    bWipCt++;
                } else {
                    System.assert(false,'Unexpected IT type for backflush: ' + it.Type__c);
                }
            } else {
                System.assert(false,'Unepxected item on IT');
            }
        }
        System.assert(completeCt == 1);
        System.assert(bIssueCt == 1);
        System.assert(bWipCt == 1);
    }

    private static testMethod void testErrors() {
        delete [SELECT Id FROM Routing__c];
        delete fuel.components[1];

        fuel.setupInventory(true, true);

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Item__r.Stocking_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Quantity_Scrapped__c = 1;
        assembly.skid.Input_Quantity__c = 1;
        assembly.skid.Item__r = wo.Item__r;
        assembly.serialList = new List<Serial__c>();

        try {
            WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, null, assembly, null, null, true) });
            System.assert(false);
        } catch (Exception e) { }

        assembly.serialList = new List<Serial__c>{
            new Serial__c(Name = 'SERIAL1', Temporary_Value_Holder__c = 'Complete'),
            new Serial__c(Name = 'SERIAL1', Temporary_Value_Holder__c = 'Scrap')
        };
        try {
            WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, null, assembly, null, null, true) });
            System.assert(false);
        } catch (Exception e) { }

        assembly.serialList[1].Name = 'SERIAL2';

        List<WorkOrderWrapper> components = (List<WorkOrderWrapper>)WorkOrderCompleteExtV2.getBackflushData(wo.Id, operation.Id, true).records;
        components[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 2;
        components[0].serialWrapperList[0].skid.Quantity_to_Scrap__c = 1;
        components[0].serialWrapperList[0].skid.Item__r = components[0].material.Item__r;
        components[0].serialWrapperList[0].serialList[0].Temporary_Value_Holder__c = 'SERIAL1';
        components[0].serialWrapperList[0].serialList[1].Temporary_Value_Holder__c = 'SERIAL2';
        components[0].serialWrapperList[0].serialList = new List<Serial__c>{
            components[0].serialWrapperList[0].serialList[0],
            components[0].serialWrapperList[0].serialList[1]
        };
        components[0].serialWrapperList.remove(1);
        
        try {
            WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, null, assembly, components, null, true) });
            System.assert(false);
        } catch (Exception e) { }
    }

    private static testMethod void testAllocation() {
        delete [SELECT Id FROM Routing__c];
        update new Component__c(Id = fuel.components[0].Id, Allocation_Required__c = true);
        delete new Component__c(Id = fuel.components[1].Id);

        insert new Allocation_Profile__c(
            Company__c = fuel.company.Id,
            Date_Received__c = false,
            Expiration_Date__c = false,
            Location__c = false,
            Rental__c = false,
            Used__c = false
        );

        fuel.setupInventory(true, true);

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        List<LineWrapper> mData = (List<LineWrapper>)WorkOrderAllocationExt.getMaterialData(wo.Id).records;
        mData[0].serialWrappers[0].skid.Input_Quantity__c = 2;
        mData[0].serialWrappers[0].skid.Item__r = (Item__c)mData[0].line.getSObject('Item__r');
        mData[0].serialWrappers[0].serialList[0].Temporary_Value_Holder__c = 'Allocate';
        mData[0].serialWrappers[0].serialList = new List<Serial__c>{ mData[0].serialWrappers[0].serialList[0] };
        AllocationService.allocate(mData);

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Packaging_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Item__r = wo.Item__r;
        assembly.serialList = new List<Serial__c>{ new Serial__c(Name = 'SERIAL1', Temporary_Value_Holder__c = 'Complete') };

        List<WorkOrderWrapper> components = (List<WorkOrderWrapper>)WorkOrderCompleteExtV2.getBackflushData(wo.Id, operation.Id, true).records;
        components[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        components[0].serialWrapperList[0].skid.Item__r = components[0].material.Item__r;
        System.assert(components[0].serialWrapperList[0].serialList.size() > 0, components[0].serialWrapperList[0].serialList);
        for (Serial__c serial:components[0].serialWrapperList[0].serialList) {
            if (serial.Allocated_SKID__c != null) {
                serial.Temporary_Value_Holder__c = 'SERIAL1';
                components[0].serialWrapperList[0].serialList = new List<Serial__c>{ serial };
                break;
            }
        }
        components[0].serialWrapperList.remove(1);

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, null, assembly, components, null, true) });

        Test.stopTest();

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Name', 'Expiration_Date__c', 'Location__c', 'Lot__c', 'Quantity__c' });
        skidQuery.setWhereClause('Type__c = \'' + SkidService3.SKID_TYPE_ALLOCATED + '\'');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery, 'Allocated_Serials__r');
        serialQuery.addField('Id');
        skidQuery.addChildRelationship(serialQuery);

        SKID__c skid = Database.query(skidQuery.getQuery());
        System.assert(skid.Expiration_Date__c == null, skid);
        System.assert(skid.Location__c == null, skid);
        System.assert(skid.Lot__c != null, skid);
        System.assert(skid.Quantity__c == 1, skid);
        System.assert(skid.Allocated_Serials__r.size() == 0, skid.Allocated_Serials__r);
    }

    private static testMethod void testVoidedSerial() {
        delete [SELECT Id FROM Routing__c];
        delete [SELECT Id FROM Component__c];
        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id, Serial_Number__c = true);

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        Serial__c serial = new Serial__c(
            Company__c = wo.Company__c,
            Item__c = wo.Item__c,
            Name = 'SERIAL1',
            Unique_Key2__c = wo.Company__c + '-' + wo.Item__c + '-SERIAL1',
            Allow_Reentry__c = true
        );
        insert serial;

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Packaging_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Item__r = wo.Item__r;
        assembly.serialList = new List<Serial__c>{ new Serial__c(Name = 'SERIAL1', Temporary_Value_Holder__c = 'Complete') };

        try {
            WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, null, assembly, null, null, true) });
            System.assert(false);
        } catch (Exception e) { }

        serial.Status__c = 'Voided';
        update serial;

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, null, assembly, null, null, true) });

        Test.stopTest();

        serial = [SELECT Id,Status__c FROM Serial__c WHERE Id = :serial.Id];
        System.assert(serial.Status__c == null, serial);
    }

    private static testMethod void testOverScrap() {
        delete [SELECT Id FROM Routing__c];
        delete [SELECT Id FROM Component__c];

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        List<SkidService3.SerialWrapper> assemblies = (List<SkidService3.SerialWrapper>)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records;
        System.assert(assemblies.size() == 1, assemblies);
        SkidService3.SerialWrapper assembly = assemblies[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Packaging_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Scrapped__c = 2;
        assembly.skid.Item__r = wo.Item__r;

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, null, assembly, null, null, true) });
        
        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        operation = wo.Operation_Trackings__r[0];

        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_COMPLETE, wo);
        System.assert(wo.Quantity_Complete__c == 10, wo);
        System.assert(wo.Quantity_Scrapped__c == 2, wo);

        assemblies = (List<SkidService3.SerialWrapper>)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records;
        System.assert(assemblies.size() == 2, assemblies);
        assembly = assemblies[0];
        System.assert(assembly.skid.Quantity_Short__c > 0 && assembly.skid.Quantity_Required__c > 0, assembly.skid);
        assembly.skid.Quantity_Used__c = 10;
        assembly.skid.Quantity_Scrapped__c = 2;
        assembly.skid.Item__r = wo.Item__r;

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, null, assembly, null, null, true) });

        Test.stopTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_COMPLETE, wo);
        System.assert(wo.Quantity_Complete__c == 20, wo);
        System.assert(wo.Quantity_Scrapped__c == 4, wo);
    }
    
    private static testMethod void testOverComplete() {
        delete [SELECT Id FROM Routing__c];
        delete [SELECT Id FROM Component__c];

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        List<SkidService3.SerialWrapper> assemblies = (List<SkidService3.SerialWrapper>)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records;
        System.assert(assemblies.size() == 1, assemblies);
        SkidService3.SerialWrapper assembly = assemblies[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Packaging_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Item__r = wo.Item__r;

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, null, assembly, null, null, true) });

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        operation = wo.Operation_Trackings__r[0];

        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_COMPLETE, wo);
        System.assert(wo.Quantity_Complete__c == 10, wo);

        assemblies = (List<SkidService3.SerialWrapper>)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records;
        System.assert(assemblies.size() == 2, assemblies);
        assembly = assemblies[0];
        System.assert(assembly.skid.Quantity_Short__c > 0 && assembly.skid.Quantity_Required__c > 0, assembly.skid);
        assembly.skid.Quantity_Used__c = 10;
        assembly.skid.Item__r = wo.Item__r;

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, null, assembly, null, null, true) });

        Test.stopTest();
        
        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_COMPLETE, wo);
        System.assert(wo.Quantity_Complete__c == 20, wo);
    }
    
    private static testMethod void testScrapOnly() {
        delete [SELECT Id FROM Component__c];
        
        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[2]; //first operation
        Operation_Tracking__c nextOp = wo.Operation_Trackings__r[1]; //second operation

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, false).records[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Packaging_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Used__c = 0;
        assembly.skid.Quantity_Scrapped__c = 1;
        assembly.skid.Input_Quantity__c = 0;
        assembly.skid.Item__r = wo.Item__r;

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, operation, nextOp, assembly, null, null, false) });

        Test.stopTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS, wo);
        System.assert(wo.Quantity_Complete__c == 0 || wo.Quantity_Complete__c == null, wo);
        System.assert(wo.Quantity_Scrapped__c == 1, wo);
        System.assert(wo.Quantity_to_Complete__c == wo.Order_Quantity__c - wo.Quantity_Scrapped__c, wo);

        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            if (op.Id == operation.Id) {
                System.assert(op.Quantity_Available__c == wo.Quantity_to_Complete__c, op);
                System.assert(op.Quantity_Completed__c == 0, op);
                System.assert(op.Quantity_Scrapped__c == 1, op);
            } else if (op.Id == nextOp.Id) {
                System.assert(op.Quantity_Available__c == 0, op);
            }
        }
    }
    
    private static testMethod void testShowSerialTopBar() {
        WorkOrderCompleteExtV2 ext = new WorkOrderCompleteExtV2();
        System.assert(ext.serialShowTopBar == false);
        
        Configuration__c config = new Configuration__c(Name = 'SerialShowTopBar', Value__c = 'true');
        insert config;
        
        ext = new WorkOrderCompleteExtV2();
        System.assert(ext.serialShowTopBar == true);
        
        config.Value__c = 'false';
        update config;
        
        ext = new WorkOrderCompleteExtV2();
        System.assert(ext.serialShowTopBar == false);
        
        config.Value__c = null;
        update config;
        
        ext = new WorkOrderCompleteExtV2();
        System.assert(ext.serialShowTopBar == false);
    }
    // tests wo completion in a different packaging uom
    /*private static testMethod void testWOQtyUpdatedinStockingUOM() {
        delete [SELECT Id FROM Routing__c];
        List<Id> lstPkgUoms = new List<Id> { fuel.uomList[11].Id, fuel.uomList[12].Id};
        List<Item__c> itemsToUpdate = new List<Item__c>();
        
        fuel.itemList[5].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[5].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[5]);
        fuel.itemList[2].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[2].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[2]);
        fuel.itemList[0].Packaging_UOM__c = JSON.serialize(lstPkgUoms);
        fuel.itemList[0].Stocking_UOM__c = fuel.uomList[11].Id;
        itemsToUpdate.add(fuel.itemList[0]);
        update itemsToUpdate;
        
        fuel.itemSpec.Packaging_UOM__c = fuel.uomList[12].Id;
        update fuel.itemSpec;
        
        fuel.workOrder.Packaging_UOM__c = fuel.uomList[12].Id;
        update fuel.workOrder;
        
        
        delete fuel.components[1];
        
        Lot__c lot = new Lot__c(Item__c=fuel.itemList[2].Id,Name='LOT-1234',Company__c=fuel.company.Id);
        insert lot;

        WorkOrderPlanningService.release(new Set<Id>{fuel.workOrder.Id});

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{fuel.workOrder.Id},null,null,new Set<String>{ 'Operation_Trackings__r', 'Material_Trackings__r' })[0];

        Operation_Tracking__c operation;
        system.assert(wo.Operation_Trackings__r.size() ==1,wo.Operation_Trackings__r);
        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            if (operation == null || (operation.Sequence__c > op.Sequence__c)) {
                operation = op;
            }
        }
		
		Skid__c sk1 = new SKID__c( Facility2__c=fuel.facility2.Id,
                            Location__c=fuel.location3.Id,
                            Company__c=fuel.company.Id,
                            Quantity__c=100,
                            Quantity_Stocking_UOM__c =100,
                            Item__c=fuel.itemList[2].Id,
                            Type__c='Location',
                            Lot__c=lot.Id,
                            Packaging_UOM__c = fuel.uomList[11].Id,
                            Stocking_UOM__c =fuel.uomList[11].Id,
                            Expiration_Date__c=System.today()+365);
        
        // this skid should not show up in the mtl tracking locn skids...              
        Skid__c sk2 = new SKID__c( Facility2__c=fuel.facility2.Id,
                            Location__c=fuel.location3.Id,
                            Company__c=fuel.company.Id,
                            Quantity__c=100,
                            Quantity_Stocking_UOM__c =100,
                            Item__c=fuel.itemList[2].Id,
                            Type__c='Location',
                            Lot__c=lot.Id,
                            Packaging_UOM__c = fuel.uomList[12].Id,
                            Stocking_UOM__c =fuel.uomList[11].Id,
                            Expiration_Date__c=System.today()+365);                    
		
        insert new List<Skid__c>{sk1,sk2};

        Test.startTest();

        Test.setCurrentPage(Page.WorkOrderCompleteV2);
        ApexPages.currentPage().getParameters().put('wo',wo.Id);
        ApexPages.currentPage().getParameters().put('op',operation.Id);
        WorkOrderCompleteExtV2 completeExt = new WorkOrderCompleteExtV2();

        Boolean last = completeExt.last;
        System.assert(last,completeExt);
        
        Decimal convFactor = KSE.getConversionFactor(fuel.itemList[5].Id, null, fuel.uomList[12].Id, fuel.uomList[11].Id, lstPkgUoms );
        Decimal qtyCompleted = 1 * convFactor;
        
        List<SkidService3.SerialWrapper> assemblyInfo = (List<SkidService3.SerialWrapper>)WorkOrderCompleteExtV2.getHeaderAssemblyData(completeExt.woId, completeExt.opId, completeExt.last, completeExt.serialTracked).records[1];
        System.assert(assemblyInfo.size() == 1,assemblyInfo);
        assemblyInfo[0].skid.Quantity_Used__c = qtyCompleted;
        assemblyInfo[0].skid.Quantity_Scrapped__c = qtyCompleted; // scrapping the same qty as completed
        assemblyInfo[0].skid.Expiration_Date__c = System.today() + 365;
        assemblyInfo[0].skid.Lot_Number__c = 'compLot1';
        assemblyInfo[0].skid.Input_Quantity__c = 1;
        

        JsonResult backflushResult =  WorkOrderCompleteExtV2.getBackflushData(wo.Id,operation.Id,last);
        System.assert(backflushResult.success == true,backflushResult);
        System.assert(backflushResult.records.size() == 1,backflushResult.records);
        List<WorkOrderWrapper> backflushRows = (List<WorkOrderWrapper>)backflushResult.records;
        System.assert(backflushRows[0].material.Type__c == 'Backflush',backflushRows[0].material);
        System.assert(backflushRows[0].serialWrapperList.size() == 1,backflushRows);
        System.assert ( backflushRows[0].serialWrapperList[0].skid.Packaging_UOM__c == fuel.uomList[11].Id );
        backflushRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = qtyCompleted;

        JsonResult byproductResult =  WorkOrderCompleteExtV2.getByproductData(wo.Id,operation.Id,last);
        System.assert(byproductResult.success == true,byproductResult);
        System.assert(byproductResult.records.size() == 0,byproductResult.records);

        JsonResult wipResult =  WorkOrderCompleteExtV2.getIssueFromWIPData(wo.Id, last);
        System.assert(wipResult.success == true,wipResult);
        System.assert(wipResult.records.size() == 0,wipResult.records);

        JsonResult saveResult = WorkOrderCompleteExtV2.save(wo.Id,operation.Id,assemblyInfo,backflushRows,new List<SkidService3.SerialWrapper>(),null,null,last);
        System.assert(saveResult.success == true,saveResult);

        Test.stopTest();

        wo = WorkOrderService.getWorkOrders(new Set<Id>{wo.Id},null,null,new Set<String>{'Material_Trackings__r','Operation_Trackings__r'})[0];
		//Check Stocking UOM fields..
		system.assert(wo.Order_Quantity__c ==10 ,wo);
		system.assert(wo.Order_Quantity_Stocking_UOM__c ==20 ,wo);
		system.assert(wo.Quantity_Complete__c ==2,wo);
		system.assert(wo.Quantity_Complete_Stocking_UOM__c ==4,wo);
		system.assert(wo.Quantity_to_Complete__c ==6,wo.Quantity_to_Complete__c);
		system.assert(wo.Quantity_to_Complete_Stocking_UOM__c ==12,wo.Quantity_to_Complete_Stocking_UOM__c);
		system.assert(wo.Quantity_Scrapped_Stocking_UOM__c ==4,wo.Quantity_Scrapped_Stocking_UOM__c);
		system.assert(wo.Quantity_Scrapped__c ==2,wo.Quantity_Scrapped__c);
        
    }*/
}