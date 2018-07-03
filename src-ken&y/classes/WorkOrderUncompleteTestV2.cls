@isTest
private class WorkOrderUncompleteTestV2 {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null && f.stockMovementRuleList != null && f.workOrder != null && f.itemAttrObj2 != null);
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void testInvalidWO() {
        Test.setCurrentPage(Page.WorkOrderUncompleteV2);
        WorkOrderUncompleteExtV2 uncompleteExt = new WorkOrderUncompleteExtV2();
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR));
    }

    private static testMethod void testInvalidOp() {
        Test.setCurrentPage(Page.WorkOrderUncompleteV2);
        ApexPages.currentPage().getParameters().put('wo',fuel.workOrder.Id);
        WorkOrderUncompleteExtV2 uncompleteExt = new WorkOrderUncompleteExtV2();
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR));
    }

    private static testMethod void testNoSerials() {
        delete [SELECT Id FROM Routing__c];

        Component__c byproduct = fuel.components[0];
        byproduct.Component_Item__c = fuel.itemList[1].Id;
        byproduct.Type__c = 'By-product';
        byproduct.Component_Sequence__c = null;
        update fuel.components[0];

        fuel.setupInventory(true);

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Item__r.Stocking_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Input_Quantity__c = 1;

        List<WorkOrderWrapper> components = (List<WorkOrderWrapper>)WorkOrderCompleteExtV2.getBackflushData(wo.Id, operation.Id, true).records;
        components[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 2;
        components[0].serialWrapperList[1].skid.Quantity_to_Issue__c = 2;

        List<SkidService3.SerialWrapper> byproducts = (List<SkidService3.SerialWrapper>)WorkOrderCompleteExtV2.getByproductData(wo.Id, operation.Id, true).records;
        System.assert(byproducts[0].skid.Packaging_UOM__c == byproducts[0].skid.Material_Tracking__r.Item__r.Stocking_UOM__c, byproducts[0].skid.Packaging_UOM__r);
        System.assert(byproducts[0].skid.Container_Item__c == byproducts[0].skid.Material_Tracking__r.Item__c, byproducts[0].skid.Container_Item__r);
        System.assert(byproducts[0].skid.Location__c == fuel.location3.Id, byproducts[0].skid.Location__r);
        byproducts[0].skid.Lot_Number__c = 'bpLot1';
        byproducts[0].skid.Expiration_Date__c = System.today() + 365;
        byproducts[0].skid.Quantity__c = 1;

        Test.startTest();

        JsonResult result = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, components, byproducts, null);
        System.assert(result.success == true, result);
        
        Test.setCurrentPage(Page.WorkOrderUncompleteV2);
        ApexPages.currentPage().getParameters().put('wo',wo.Id);
        ApexPages.currentPage().getParameters().put('op',operation.Id);
        WorkOrderUncompleteExtV2 uncompleteExt = new WorkOrderUncompleteExtV2();

        Boolean last = uncompleteExt.last;
        System.assert(last,uncompleteExt);

        String str = uncompleteExt.headerFieldsJson;
        str = uncompleteExt.assemblyFieldsJson;
        str = uncompleteExt.materialFieldsJson;
        str = uncompleteExt.editableSkidFieldsJson;
        str = uncompleteExt.uneditableSkidFieldListJson;
        str = uncompleteExt.serialFieldListJson;
        Integer i = uncompleteExt.gridSize;
        uncompleteExt.cancel();

        List<SkidService3.SerialWrapper> assemblyInfo = (List<SkidService3.SerialWrapper>)WorkOrderUncompleteExtV2.getHeaderAssemblyData(uncompleteExt.woId, uncompleteExt.opId, uncompleteExt.last).records[1];
        System.assert(assemblyInfo.size() == 1,assemblyInfo);
        assemblyInfo[0].skid.Quantity_To_Return__c = 1;
        assemblyInfo[0].skid.Input_Quantity__c = 1;
        assemblyInfo[0].skid.Packaging_UOM__c = fuel.uomList[8].Id;

        result = WorkOrderUncompleteExtV2.getComponentData(wo, operation.Id, true, assemblyInfo[0]);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 1, result.records);
        components = (List<WorkOrderWrapper>)result.records;
        System.assert(components[0].serialWrapperList.size() == 1, components[0].serialWrapperList);
        System.assert(components[0].serialWrapperList[0].skid.Location__c == fuel.location3.Id, components[0].serialWrapperList[0].skid);
        System.assert(components[0].serialWrapperList[0].skid.Quantity_To_Return__c == 4, components[0].serialWrapperList[0].skid);
        components[0].serialWrapperList[0].skid.Quantity_To_Return__c = 2;

        JsonResult byproductResult =  WorkOrderUncompleteExtV2.getByproductData(wo.Id,operation.Id,last);
        System.assert(byproductResult.success,byproductResult);
        System.assert(byproductResult.records.size() == 1,byproductResult.records);
        List<WorkOrderWrapper> bpRows = (List<WorkOrderWrapper>)byproductResult.records;
        System.assert(bpRows[0].serialWrapperList.size() == 1,bpRows);
        bpRows[0].serialWrapperList[0].skid.Quantity_To_Return__c = 1;
        components.addAll(bpRows);

        JsonResult saveResult = WorkOrderUncompleteExtV2.save(wo.Id,operation.Id,assemblyInfo,components,last,null);
        System.assert(saveResult.success,saveResult);

        Test.stopTest();

        wo = WorkOrderService.getWorkOrders(new Set<Id>{wo.Id},null,null,new Set<String>{'Material_Trackings__r','Operation_Trackings__r'})[0];
		//Check Stocking UOM fields..
		system.assert(wo.Order_Quantity_Stocking_UOM__c ==10,wo.Order_Quantity_Stocking_UOM__c);
		system.assert(wo.Quantity_Complete_Stocking_UOM__c ==0,wo.Quantity_Complete_Stocking_UOM__c);
		system.assert(wo.Quantity_to_Complete_Stocking_UOM__c == 10,wo.Quantity_to_Complete_Stocking_UOM__c);
		
        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{'From_Lot__r.Name','Lot__r.Name'});
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.addAllCustomFields(Inventory_Change__c.sObjectType,'Inventory_Change__r');
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\' AND Inventory_Change__r.Type__c = \'Work Order Uncomplete\'');
        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());

        System.assert(wo.Quantity_Complete__c == 0,wo);

        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Backflush') {
                System.assert(mt.Quantity_Issued__c == 2,mt);
                System.assert(mt.Quantity_Used__c == 2,mt);
            } else if (mt.Type__c == 'By-product') {
                System.assert(mt.Quantity_Completed__c == 0,mt);
            } else {
                System.assert(false,'Unxpected material type: ' + mt.Type__c);
            }
        }

        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            System.assert(op.Hours_Consumed__c == 0,op);
        }

        //1 assembly, 2 backflush, 1 byproduct
        System.assert(itList.size() == 4, itList.size());

        Integer assemblyCt = 0, bReturnCt = 0, bWipCt = 0, bpCt = 0;

        for (Inventory_Transaction__c it:itList) {
            if (it.Item__c == fuel.itemList[5].Id) {
                if (it.Type__c == 'Work Order Assembly Uncompletion') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.Lot__r.Name == 'COMPLOT1',it);
                    System.assert(it.From_SKID__c == null,it.From_SKID__r);
                    System.assert(it.To_SKID__c == null,it);

                    assemblyCt++;
                } else {
                    System.assert(false,'Unexpected IT type for assembly: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[0].Id) {
                if (it.Type__c == 'Work Order Component Return') {
                    System.assert(it.Quantity__c == 2, it);
                    System.assert(it.From_SKID__c == null, it);
                    System.assert(it.To_SKID__c != null, it);
                    System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == fuel.location3.Id, it.To_SKID__r);
                    System.assert(it.To_SKID__r.Quantity__c == 100, it.To_SKID__r);

                    bReturnCt++;
                } else if (it.Type__c == 'Work Order Return To WIP') {
                    System.assert(it.Quantity__c == 2, it);
                    System.assert(it.From_SKID__c == null, it);
                    System.assert(it.To_SKID__c == null, it);

                    bWipCt++;
                } else {
                    System.assert(false,'Unexpected IT type for backflush: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[1].Id) {
                if (it.Type__c == 'By-product Uncompletion') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.From_Lot__r.Name == 'BPLOT1',it);
                    System.assert(it.From_SKID__c == null,it);
                    System.assert(it.To_SKID__c == null,it);

                    bpCt++;
                } else {
                    System.assert(false,'Unexpected IT type for byproduct: ' + it.Type__c);
                }
            } else {
                System.assert(false,'Unepxected item on IT');
            }
        }

        System.assert(assemblyCt == 1);
        System.assert(bReturnCt == 1);
        System.assert(bWipCt == 1);
        System.assert(bpCt == 1);
    }
    
    private static testMethod void testSerialswithNonSerialAssembly() {
        delete [SELECT Id FROM Routing__c];

        Component__c byproduct = fuel.components[0];
        byproduct.Component_Item__c = fuel.itemList[1].Id;
        byproduct.Type__c = 'By-product';
        byproduct.Component_Sequence__c = null;
        update fuel.components[0];

        fuel.setupInventory(true, true);

        Work_Order__c wo = fuel.workOrder;
        
        delete [SELECT Id FROM SKID__c WHERE Item__c = :wo.Item__c];
        delete [SELECT Id FROM Serial__c WHERE Item__c = :wo.Item__c];
        update new Item__c(Id = wo.Item__c, Item_Attribute__c = null);

        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Item__r.Stocking_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Input_Quantity__c = 1;

        List<WorkOrderWrapper> components = (List<WorkOrderWrapper>)WorkOrderCompleteExtV2.getBackflushData(wo.Id, operation.Id, true).records;
        components[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 2;
        components[0].serialWrapperList[0].serialList[0].Temporary_Value_Holder__c = 'COMPONENT ISSUE';
        components[0].serialWrapperList[0].serialList[1].Temporary_Value_Holder__c = 'COMPONENT ISSUE';
        components[0].serialWrapperList[0].serialList = new List<Serial__c>{ components[0].serialWrapperList[0].serialList[0], components[0].serialWrapperList[0].serialList[1] };
        components[0].serialWrapperList[1].skid.Quantity_to_Issue__c = 2;
        components[0].serialWrapperList[1].serialList[0].Temporary_Value_Holder__c = 'COMPONENT ISSUE';
        components[0].serialWrapperList[1].serialList[1].Temporary_Value_Holder__c = 'COMPONENT ISSUE';
        components[0].serialWrapperList[1].serialList = new List<Serial__c>{ components[0].serialWrapperList[1].serialList[0], components[0].serialWrapperList[1].serialList[1] };

        List<SkidService3.SerialWrapper> byproducts = (List<SkidService3.SerialWrapper>)WorkOrderCompleteExtV2.getByproductData(wo.Id, operation.Id, true).records;
        System.assert(byproducts[0].skid.Packaging_UOM__c == byproducts[0].skid.Material_Tracking__r.Item__r.Stocking_UOM__c, byproducts[0].skid.Packaging_UOM__r);
        System.assert(byproducts[0].skid.Container_Item__c == byproducts[0].skid.Material_Tracking__r.Item__c, byproducts[0].skid.Container_Item__r);
        System.assert(byproducts[0].skid.Location__c == fuel.location3.Id, byproducts[0].skid.Location__r);
        byproducts[0].skid.Lot_Number__c = 'bpLot1';
        byproducts[0].skid.Expiration_Date__c = System.today() + 365;
        byproducts[0].skid.Quantity__c = 1;
        byproducts[0].serialList = new List<Serial__c>{ new Serial__c(Name = 'SERIAL1') };

        Test.startTest();

        JsonResult result = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, components, byproducts, null);
        System.assert(result.success == true, result);
        
        wo = WorkOrderService.getWorkOrders(new Set<Id>{wo.Id},null,null,new Set<String>{'Material_Trackings__r','Operation_Trackings__r'})[0];

        //Check Stocking UOM fields after complete
		system.assert(wo.Order_Quantity__c ==10 ,wo);
		system.assert(wo.Order_Quantity_Stocking_UOM__c ==10 ,wo);
		system.assert(wo.Quantity_Complete_Stocking_UOM__c ==1,wo);
		system.assert(wo.Quantity_to_Complete_Stocking_UOM__c ==9,wo.Quantity_to_Complete_Stocking_UOM__c);
                
        Test.setCurrentPage(Page.WorkOrderUncompleteV2);
        ApexPages.currentPage().getParameters().put('wo',wo.Id);
        ApexPages.currentPage().getParameters().put('op',operation.Id);
        WorkOrderUncompleteExtV2 uncompleteExt = new WorkOrderUncompleteExtV2();

        Boolean last = uncompleteExt.last;
        System.assert(last,uncompleteExt);

        List<SkidService3.SerialWrapper> assemblyInfo = (List<SkidService3.SerialWrapper>)WorkOrderUncompleteExtV2.getHeaderAssemblyData(uncompleteExt.woId, uncompleteExt.opId, uncompleteExt.last).records[1];
        System.assert(assemblyInfo.size() == 1,assemblyInfo);
        System.assert(assemblyInfo[0].serialList.size() == 0,assemblyInfo);
        assemblyInfo[0].skid.Quantity_To_Return__c = 1;
        assemblyInfo[0].skid.Input_Quantity__c = 1;

        result = WorkOrderUncompleteExtV2.getComponentData(wo, operation.Id, last, assemblyInfo[0]);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 1, result.records);
        components = (List<WorkOrderWrapper>)result.records;
        System.assert(components[0].serialWrapperList.size() == 1, components[0].serialWrapperList);
        System.assert(components[0].serialWrapperList[0].skid.Location__c == fuel.location3.Id, components[0].serialWrapperList[0].skid);
        components[0].serialWrapperList[0].skid.Quantity_To_Return__c = 1;
        components[0].serialWrapperList[0].serialList[0].Allow_Reentry__c = false;
        components[0].serialWrapperList[0].serialList = new List<Serial__c>{ components[0].serialWrapperList[0].serialList[0] };

        JsonResult byproductResult =  WorkOrderUncompleteExtV2.getByproductData(wo.Id,operation.Id,last);
        System.assert(byproductResult.success,byproductResult);
        System.assert(byproductResult.records.size() == 1,byproductResult.records);
        List<WorkOrderWrapper> bpRows = (List<WorkOrderWrapper>)byproductResult.records;
        System.assert(bpRows[0].serialWrapperList.size() == 1,bpRows[0]);
        System.assert(bpRows[0].serialWrapperList[0].serialList.size() == 1,bpRows[0]);
        bpRows[0].serialWrapperList[0].skid.Quantity_To_Return__c = 1;
        for ( Serial__c sr : bpRows[0].serialWrapperList[0].serialList ) {
            sr.Allow_Reentry__c = false;
        }
        bpRows[0].serialWrapperList[0].serialList = new List<Serial__c>{bpRows[0].serialWrapperList[0].serialList[0]};
        components.addAll(bpRows);

        JsonResult saveResult = WorkOrderUncompleteExtV2.save(wo.Id,operation.Id,assemblyInfo,components,last,null);
        System.assert(saveResult.success,saveResult);

        Test.stopTest();

        wo = WorkOrderService.getWorkOrders(new Set<Id>{wo.Id},null,null,new Set<String>{'Material_Trackings__r','Operation_Trackings__r'})[0];
         //Check Stocking UOM fields after Uncomplete
		system.assert(wo.Order_Quantity__c ==10 ,wo);
		system.assert(wo.Order_Quantity_Stocking_UOM__c ==10 ,wo);
		system.assert(wo.Quantity_Complete_Stocking_UOM__c ==0,wo);
		system.assert(wo.Quantity_to_Complete_Stocking_UOM__c ==10,wo.Quantity_to_Complete_Stocking_UOM__c);
                
        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{'From_Lot__r.Name','Lot__r.Name'});
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.addAllCustomFields(Inventory_Change__c.sObjectType,'Inventory_Change__r');
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\' AND Inventory_Change__r.Type__c = \'Work Order Uncomplete\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery,'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial_Parent__r');
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());

        System.assert(wo.Quantity_Complete__c == 0,wo);

        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Backflush') {
                System.assert(mt.Quantity_Issued__c == 3,mt);
                System.assert(mt.Quantity_Used__c == 3,mt);
            } else if (mt.Type__c == 'By-product') {
                System.assert(mt.Quantity_Completed__c == 0,mt);
            } else {
                System.assert(false,'Unxpected material type: ' + mt.Type__c);
            }
        }

        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            System.assert(op.Hours_Consumed__c == 0,op);
        }

        //1 assembly, 2 backflush, 1 byprorduct
        System.assert(itList.size() == 4, itList.size());

        Integer assemblyCt = 0, bReturnCt = 0, bWipCt = 0, bpCt = 0;

        for (Inventory_Transaction__c it:itList) {
            if (it.Item__c == fuel.itemList[5].Id) {
                if (it.Type__c == 'Work Order Assembly Uncompletion') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.From_SKID__c == null,it.From_SKID__r);
                    System.assert(it.To_SKID__c == null,it);
                    
                    System.assert(it.Serial_Transactions__r.size() == 0,it.Serial_Transactions__r);
                    assemblyCt++;
                } else {
                    System.assert(false,'Unexpected IT type for assembly: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[0].Id) {
                if (it.Type__c == 'Work Order Component Return') {
                    System.assert(it.Quantity__c == 1, it);
                    System.assert(it.From_SKID__c == null, it);
                    System.assert(it.To_SKID__c != null, it);
                    System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == fuel.location3.Id, it.To_SKID__r);

                    System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'Component Return',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                    }

                    bReturnCt++;
                } else if (it.Type__c == 'Work Order Return To WIP') {
                    System.assert(it.Quantity__c == 1, it);
                    System.assert(it.From_SKID__c == null, it);
                    System.assert(it.To_SKID__c == null, it);

                    System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'WIP Untranslate',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                    }

                    bWipCt++;
                } else {
                    System.assert(false,'Unexpected IT type for backflush: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[1].Id) {
                if (it.Type__c == 'By-product Uncompletion') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.From_Lot__r.Name == 'BPLOT1',it);
                    System.assert(it.From_SKID__c == null,it);
                    System.assert(it.To_SKID__c == null,it);

                    System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'By-product Uncompletion',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.SKID__c == null);
                    }

                    bpCt++;
                } else {
                    System.assert(false,'Unexpected IT type for byproduct: ' + it.Type__c);
                }
            } else {
                System.assert(false,'Unepxected item on IT');
            }
        }

        System.assert(assemblyCt == 1);
        System.assert(bReturnCt == 1);
        System.assert(bWipCt == 1);
        System.assert(bpCt == 1);
    }

    private static testMethod void testSerials() {
        delete [SELECT Id FROM Routing__c];

        Component__c byproduct = fuel.components[0];
        byproduct.Component_Item__c = fuel.itemList[1].Id;
        byproduct.Type__c = 'By-product';
        byproduct.Component_Sequence__c = null;
        update fuel.components[0];

        fuel.setupInventory(true, true);

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Item__r.Stocking_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Input_Quantity__c = 1;
        assembly.serialList = new List<Serial__c>{ new Serial__c(Name = 'SERIAL1',Temporary_Value_Holder__c = 'Complete') };

        List<WorkOrderWrapper> components = (List<WorkOrderWrapper>)WorkOrderCompleteExtV2.getBackflushData(wo.Id, operation.Id, true).records;
        components[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 2;
        components[0].serialWrapperList[0].serialList[0].Temporary_Value_Holder__c = 'SERIAL1';
        components[0].serialWrapperList[0].serialList[1].Temporary_Value_Holder__c = 'SERIAL1';
        components[0].serialWrapperList[0].serialList = new List<Serial__c>{ components[0].serialWrapperList[0].serialList[0], components[0].serialWrapperList[0].serialList[1] };
        components[0].serialWrapperList[1].skid.Quantity_to_Issue__c = 2;
        components[0].serialWrapperList[1].serialList[0].Temporary_Value_Holder__c = 'SERIAL1';
        components[0].serialWrapperList[1].serialList[1].Temporary_Value_Holder__c = 'SERIAL1';
        components[0].serialWrapperList[1].serialList = new List<Serial__c>{ components[0].serialWrapperList[1].serialList[0], components[0].serialWrapperList[1].serialList[1] };

        List<SkidService3.SerialWrapper> byproducts = (List<SkidService3.SerialWrapper>)WorkOrderCompleteExtV2.getByproductData(wo.Id, operation.Id, true).records;
        System.assert(byproducts[0].skid.Packaging_UOM__c == byproducts[0].skid.Material_Tracking__r.Item__r.Stocking_UOM__c, byproducts[0].skid.Packaging_UOM__r);
        System.assert(byproducts[0].skid.Container_Item__c == byproducts[0].skid.Material_Tracking__r.Item__c, byproducts[0].skid.Container_Item__r);
        System.assert(byproducts[0].skid.Location__c == fuel.location3.Id, byproducts[0].skid.Location__r);
        byproducts[0].skid.Lot_Number__c = 'bpLot1';
        byproducts[0].skid.Expiration_Date__c = System.today() + 365;
        byproducts[0].skid.Quantity__c = 1;
        byproducts[0].serialList = new List<Serial__c>{ new Serial__c(Name = 'SERIAL1') };

        Test.startTest();

        JsonResult result = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, components, byproducts, null);
        System.assert(result.success == true, result);

        Test.setCurrentPage(Page.WorkOrderUncompleteV2);
        ApexPages.currentPage().getParameters().put('wo',wo.Id);
        ApexPages.currentPage().getParameters().put('op',operation.Id);
        WorkOrderUncompleteExtV2 uncompleteExt = new WorkOrderUncompleteExtV2();

        Boolean last = uncompleteExt.last;
        System.assert(last,uncompleteExt);

        List<SkidService3.SerialWrapper> assemblyInfo = (List<SkidService3.SerialWrapper>)WorkOrderUncompleteExtV2.getHeaderAssemblyData(uncompleteExt.woId, uncompleteExt.opId, uncompleteExt.last).records[1];
        System.assert(assemblyInfo.size() == 1,assemblyInfo);
        System.assert(assemblyInfo[0].serialList.size() == 1,assemblyInfo);
        assemblyInfo[0].skid.Quantity_To_Return__c = 1;
        assemblyInfo[0].skid.Input_Quantity__c = 1;
        assemblyInfo[0].serialList = new List<Serial__c>{assemblyInfo[0].serialList[0]};

        result = WorkOrderUncompleteExtV2.getComponentData(wo, operation.Id, last, assemblyInfo[0]);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 1, result.records);
        components = (List<WorkOrderWrapper>)result.records;
        System.assert(components[0].serialWrapperList.size() == 1, components[0].serialWrapperList);
        System.assert(components[0].serialWrapperList[0].skid.Location__c == fuel.location3.Id, components[0].serialWrapperList[0].skid);
        components[0].serialWrapperList[0].skid.Quantity_To_Return__c = 1;
        components[0].serialWrapperList[0].serialList[0].Allow_Reentry__c = false;
        components[0].serialWrapperList[0].serialList = new List<Serial__c>{ components[0].serialWrapperList[0].serialList[0] };

        JsonResult byproductResult =  WorkOrderUncompleteExtV2.getByproductData(wo.Id,operation.Id,last);
        System.assert(byproductResult.success,byproductResult);
        System.assert(byproductResult.records.size() == 1,byproductResult.records);
        List<WorkOrderWrapper> bpRows = (List<WorkOrderWrapper>)byproductResult.records;
        System.assert(bpRows[0].serialWrapperList.size() == 1,bpRows[0]);
        System.assert(bpRows[0].serialWrapperList[0].serialList.size() == 1,bpRows[0]);
        bpRows[0].serialWrapperList[0].skid.Quantity_To_Return__c = 1;
        for ( Serial__c sr : bpRows[0].serialWrapperList[0].serialList ) {
            sr.Allow_Reentry__c = false;
        }
        bpRows[0].serialWrapperList[0].serialList = new List<Serial__c>{bpRows[0].serialWrapperList[0].serialList[0]};
        components.addAll(bpRows);

        JsonResult saveResult = WorkOrderUncompleteExtV2.save(wo.Id,operation.Id,assemblyInfo,components,last,null);
        System.assert(saveResult.success,saveResult);

        wo = WorkOrderService.getWorkOrders(new Set<Id>{wo.Id},null,null,new Set<String>{'Material_Trackings__r','Operation_Trackings__r'})[0];

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{'From_Lot__r.Name','Lot__r.Name'});
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        itQuery.addAllCustomFields(Inventory_Change__c.sObjectType,'Inventory_Change__r');
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\' AND Inventory_Change__r.Type__c = \'Work Order Uncomplete\'');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery,'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial_Parent__r');
        itQuery.addChildRelationship(stQuery);

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());

        System.assert(wo.Quantity_Complete__c == 0,wo);

        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Backflush') {
                System.assert(mt.Quantity_Issued__c == 3,mt);
                System.assert(mt.Quantity_Used__c == 3,mt);
            } else if (mt.Type__c == 'By-product') {
                System.assert(mt.Quantity_Completed__c == 0,mt);
            } else {
                System.assert(false,'Unxpected material type: ' + mt.Type__c);
            }
        }

        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            System.assert(op.Hours_Consumed__c == 0,op);
        }

        //1 assembly, 2 backflush, 1 byprorduct
        System.assert(itList.size() == 4, itList.size());

        Integer assemblyCt = 0, bReturnCt = 0, bWipCt = 0, bpCt = 0;

        for (Inventory_Transaction__c it:itList) {
            if (it.Item__c == fuel.itemList[5].Id) {
                if (it.Type__c == 'Work Order Assembly Uncompletion') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.Lot__r.Name == 'COMPLOT1',it);
                    System.assert(it.From_SKID__c == null,it.From_SKID__r);
                    System.assert(it.To_SKID__c == null,it);
                    
                    System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'Assembly Uncompletion',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.SKID__c == it.To_SKID__c);
                    }

                    assemblyCt++;
                } else {
                    System.assert(false,'Unexpected IT type for assembly: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[0].Id) {
                if (it.Type__c == 'Work Order Component Return') {
                    System.assert(it.Quantity__c == 1, it);
                    System.assert(it.From_SKID__c == null, it);
                    System.assert(it.To_SKID__c != null, it);
                    System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION, it.To_SKID__r);
                    System.assert(it.To_SKID__r.Location__c == fuel.location3.Id, it.To_SKID__r);
                    System.assert(it.To_SKID__r.Quantity__c == 9, it.To_SKID__r);

                    System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'Component Return',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                    }

                    bReturnCt++;
                } else if (it.Type__c == 'Work Order Return To WIP') {
                    System.assert(it.Quantity__c == 1, it);
                    System.assert(it.From_SKID__c == null, it);
                    System.assert(it.To_SKID__c == null, it);

                    System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'WIP Untranslate',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c != null,st);
                    }

                    bWipCt++;
                } else {
                    System.assert(false,'Unexpected IT type for backflush: ' + it.Type__c);
                }
            } else if (it.Item__c == fuel.itemList[1].Id) {
                if (it.Type__c == 'By-product Uncompletion') {
                    System.assert(it.Quantity__c == 1,it);
                    System.assert(it.From_Lot__r.Name == 'BPLOT1',it);
                    System.assert(it.From_SKID__c == null,it);
                    System.assert(it.To_SKID__c == null,it);

                    System.assert(it.Serial_Transactions__r.size() == 1,it.Serial_Transactions__r);
                    for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                        System.assert(st.Type__c == 'By-product Uncompletion',st);
                        System.assert(st.Serial__c != null,st);
                        System.assert(st.Serial_Parent__c == null,st);
                        System.assert(st.Serial__r.SKID__c == null);
                    }

                    bpCt++;
                } else {
                    System.assert(false,'Unexpected IT type for byproduct: ' + it.Type__c);
                }
            } else {
                System.assert(false,'Unepxected item on IT');
            }
        }

        System.assert(assemblyCt == 1);
        System.assert(bReturnCt == 1);
        System.assert(bWipCt == 1);
        System.assert(bpCt == 1);

        Test.stopTest();
    }

    private static testMethod void testRoutings() {
        delete fuel.routings[2];

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[1];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, false).records[0];
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Used__c = 2;

        Test.startTest();

        JsonResult result = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, null, null, null);
        System.assert(result.success == true, result);

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        operation = wo.Operation_Trackings__r[0];

        assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        assembly.skid.Quantity_Used__c = 1;

        result = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, null, null, null);
        System.assert(result.success == true, result);

        List<SkidService3.SerialWrapper> assemblyInfo = (List<SkidService3.SerialWrapper>)WorkOrderUncompleteExtV2.getHeaderAssemblyData(wo.Id, wo.Operation_Trackings__r[0].Id, true).records[1];
        assemblyInfo[0].skid.Quantity_To_Return__c = 1;

        result = WorkOrderUncompleteExtV2.save(wo.Id, wo.Operation_Trackings__r[0].Id, assemblyInfo, new List<WorkOrderWrapper>(), true, null);
        System.assert(result.success == true, result);

        Test.stopTest();

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\' AND Inventory_Change__r.Type__c = \'Work Order Uncomplete\'');
        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1,itList);
    }

    private static testMethod void testWithAllocation() {
        delete [SELECT Id FROM Routing__c];

        update new Component__c(Id = fuel.components[0].Id, Allocation_Required__c = true);
        delete fuel.components[1];

        fuel.setupInventory(true, true);

        Work_Order__c wo = fuel.workOrder;
        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        List<LineWrapper> mData = (List<LineWrapper>)WorkOrderAllocationExt.getMaterialData(wo.Id).records;
        mData[0].serialWrappers[0].skid.Input_Quantity__c = 2;
        mData[0].serialWrappers[0].serialList[0].Temporary_Value_Holder__c = 'Allocate';
        WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        System.assert(assembly.skid.Packaging_UOM__c == wo.Item__r.Stocking_UOM__c, assembly.skid.Packaging_UOM__r);
        System.assert(assembly.skid.Container_Item__c == wo.Item__c, assembly.skid.Container_Item__r);
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Used__c = 1;
        assembly.skid.Input_Quantity__c = 1;
        assembly.skid.Item__r = wo.Item__r;
        assembly.serialList = new List<Serial__c>{ new Serial__c(Name = 'SERIAL1', Temporary_Value_Holder__c = 'Complete') };

        Test.startTest();
        
        JsonResult bfResult = WorkOrderCompleteExtV2.getBackflushData(wo.Id,operation.Id,true);
        List<WorkOrderWrapper> backflushRows = (List<WorkOrderWrapper>)bfResult.records;
        /*commented for crp1 build #JCI
        backflushRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        Serial__c serial;
        for (Serial__c ser:backflushRows[0].serialWrapperList[0].serialList) {
            if (ser.Allocated_SKID__c != null) {
                ser.Temporary_Value_Holder__c = 'SERIAL1';
                serial = ser;
            }
        }
        backflushRows[0].serialWrapperList[0].serialList = new List<Serial__c>{ serial };*

        WorkOrderCompleteExtV2.save(wo.Id,operationId,assemblyInfo,backflushRows,new List<SkidService3.SerialWrapper>(),new List<String>(),new List<String>(),last);

        Test.setCurrentPage(Page.WorkOrderUncompleteV2);
        ApexPages.currentPage().getParameters().put('wo',wo.Id);
        ApexPages.currentPage().getParameters().put('op',operationId);
        WorkOrderUncompleteExtV2 uncompleteExt = new WorkOrderUncompleteExtV2();

        last = uncompleteExt.last;
        System.assert(last,uncompleteExt);

        assemblyInfo = (List<SkidService3.SerialWrapper>)WorkOrderUncompleteExtV2.getHeaderAssemblyData(uncompleteExt.woId, uncompleteExt.opId, uncompleteExt.last).records[1];
        /*System.assert(assemblyInfo.size() == 1,assemblyInfo);
        System.assert(assemblyInfo[0].serialList.size() == 1,assemblyInfo);
        assemblyInfo[0].skid.Quantity_To_Return__c = 1;
        assemblyInfo[0].serialList = new List<Serial__c>{assemblyInfo[0].serialList[0]};

        JsonResult componentResult = WorkOrderUncompleteExtV2.getComponentData(wo,operationId,last,assemblyInfo[0]);
        /* #JCI
        System.assert(componentResult.success,componentResult);
        System.assert(componentResult.records.size() == 1,componentResult.records);
        List<WorkOrderWrapper> componentRows = (List<WorkOrderWrapper>)componentResult.records;
        System.assert(componentRows[0].serialWrapperList.size() == 1,componentRows);
        System.assert(componentRows[0].serialWrapperList[0].serialList.size() == 1,componentRows);
        componentRows[0].serialWrapperList[0].skid.Quantity_To_Return__c = 1;

        JsonResult saveResult = WorkOrderUncompleteExtV2.save(wo.Id,operationId,assemblyInfo,componentRows,last,null);
        System.assert(saveResult.success,saveResult);

        Test.stopTest();

        wo = WorkOrderService.getWorkOrders(new Set<Id>{wo.Id},null,null,new Set<String>{'Material_Trackings__r','Operation_Trackings__r'})[0];

        System.assert(wo.Status__c == 'Released',wo);
        System.assert(wo.Quantity_Complete__c == 0,wo);

        System.assert(wo.Material_Trackings__r.size() == 1,wo.Material_Trackings__r);
        System.assert(wo.Material_Trackings__r[0].Quantity_Allocated__c == 2,wo.Material_Trackings__r[0]);
        System.assert(wo.Material_Trackings__r[0].Quantity_Issued__c == 0,wo.Material_Trackings__r[0]);
        System.assert(wo.Material_Trackings__r[0].Quantity_Used__c == 0,wo.Material_Trackings__r[0]);

        System.assert(wo.Operation_Trackings__r.size() == 1,wo.Operation_Trackings__r);
        System.assert(wo.Operation_Trackings__r[0].Quantity_Completed__c == 0,wo.Operation_Trackings__r[0]);

        SOQLUtil otQuery = new SOQLUtil('Operation_Transaction__c');
        otQuery.addAllCustomFields();
        otQuery.addField('Lot__r.Name');
        otQuery.setWhereClause('Work_Order__c = \'' + wo.Id + '\' AND Quantity_Completed__c < 0');

        SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(otQuery, 'Serial_Transactions__r');
        stQuery.addAllCustomFields();
        otQuery.addChildRelationship(stQuery);

        List<Operation_Transaction__c> otList = Database.query(otQuery.getQuery());
        System.assert(otList.size() == 1,otList);
        System.assert(otList[0].Quantity_Completed__c == -1,otList[0]);
        System.assert(otList[0].Item__c == wo.Item__c,otList[0]);
        System.assert(otList[0].Location__c == wo.Complete_To_Location__c,otList[0]);
        System.assert(otList[0].Lot__r.Name == 'COMPLOT1',otList[0]);
        System.assert(otList[0].Serial_Transactions__r.size() == -otList[0].Quantity_Completed__c, otList[0].Serial_Transactions__r);

        SOQLUtil allocSkidQuery = new SOQLUtil('SKID__c');
        allocSkidQuery.addAllCustomFields();
        allocSkidQuery.setWhereClause('Material_Tracking__c = \'' + wo.Material_Trackings__r[0].Id + '\' AND Type__c = \'Allocated\'');

        SOQLUtil.ChildRelationship allocSerialQuery = new SOQLUtil.ChildRelationship(allocSkidQuery,'Allocated_Serials__r');
        allocSerialQuery.addAllCustomFields();
        allocSkidQuery.addChildRelationship(allocSerialQuery);

        List<SKID__c> allocSkids = Database.query(allocSkidQuery.getQuery());
        System.assert(allocSkids.size() == 1,allocSkids);
        System.assert(allocSkids[0].Quantity__c == 2,allocSkids[0]);
        System.assert(allocSkids[0].Allocated_Serials__r.size() == 0,allocSkids[0].Allocated_Serials__r);*/
    }

    private static testMethod void testVoidedSerial() {
        Work_Order__c wo = fuel.workOrder;

        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id,Serial_Number__c = true);

        delete [SELECT Id FROM Routing__c];

        WorkOrderPlanningService.release(new Set<Id>{wo.Id});

        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c operation = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, operation, true).records[0];
        assembly.skid.Lot_Number__c = 'compLOT1';
        assembly.skid.Expiration_Date__c = System.today() + 365;
        assembly.skid.Quantity_Used__c = 1;
        assembly.serialList = new List<Serial__c>{ new Serial__c(Name = 'SERIAL1', Temporary_Value_Holder__c = 'Complete') };

        JsonResult result = WorkOrderCompleteExtV2.save(wo.Id, operation.Id, assembly, null, null, null);
        System.assert(result.success == true, result);

        Test.setCurrentPage(Page.WorkOrderUncompleteV2);
        ApexPages.currentPage().getParameters().put('wo',wo.Id);
        ApexPages.currentPage().getParameters().put('op',operation.Id);
        WorkOrderUncompleteExtV2 uncompleteExt = new WorkOrderUncompleteExtV2();

        Boolean last = uncompleteExt.last;
        System.assert(last,uncompleteExt);

        List<SkidService3.SerialWrapper> assemblyInfo = (List<SkidService3.SerialWrapper>)WorkOrderUncompleteExtV2.getHeaderAssemblyData(uncompleteExt.woId, uncompleteExt.opId, uncompleteExt.last).records[1];
        assemblyInfo[0].skid.Quantity_To_Return__c = 1;
        assemblyInfo[0].serialList = new List<Serial__c>{assemblyInfo[0].serialList[0]};

        JsonResult saveResult = WorkOrderUncompleteExtV2.save(wo.Id,operation.Id,assemblyInfo,new List<WorkOrderWrapper>(),last,null);
        System.assert(saveResult.success,saveResult);

        Serial__c serial = [SELECT Id,Name,Status__c FROM Serial__c];
        System.assert(serial.Status__c == 'Voided', serial);

        Test.stopTest();
    }
}