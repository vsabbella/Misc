@isTest
private class SubcontractTest {
    @testSetup
    private static void setupData() {
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType,Currency__c.sObjectType ,Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,
            Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, item_attribute__c.sObjectType,Shipment__c.sObjectType,Customer__c.sObjectType, Shipment_Line__c.sObjectType,Product__c.sObjectType,Item__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null && f.stockMovementRuleList != null && f.periodList != null);

        f.facility2.Default_Purchasing_Delivery_Location__c = f.location2.Id;
        update f.facility2;

		f.components[0].Supplier__c = f.supplier.Id;
		f.components[1].Supplier__c = f.supplier.Id;
        Item__c ospItem = f.itemList[2];
        ospItem.Source__c = ItemService.ITEM_SOURCE_OSP;
        ospItem.Non_Inventory__c = true;
        ospItem.Item_Attribute__c = null;
        ospItem.Supplier__c = f.supplier.Id;
        ospItem.Stocking_UOM__c = f.itemList[2].Stocking_UOM__c;
        ospItem.Packaging_UOM__c = JSON.serialize(new List<Id>{ f.itemList[2].Stocking_UOM__c });
        update ospItem;

        f.components[0].Supplier__c = f.supplier.Id;
        f.components[1].Routing__c = f.routings[0].Id;

        Component__c component = f.components[0].clone(true,true);
        component.Type__c = WorkOrderService.MATERIAL_TYPE_BYPRODUCT;
        component.Component_Sequence__c = null;
        try {
            update component;
            System.assert(false,'OSP component type was set to byproduct');
        } catch (Exception e) {
            System.assert(true);
        }

        component = f.components[0].clone(true,true);
        component.Routing__c = null;
        try {
            update component;
            System.assert(false,'OSP component\'s routing was set to null');
        } catch (Exception e) {
            System.assert(true);
        }

        Item__c ospItem2 = f.itemList[0].clone(true,true);
        ospItem2.Source__c = ItemService.ITEM_SOURCE_OSP;
        ospItem2.Non_Inventory__c = true;
        ospItem2.Item_Attribute__c = null;
        update ospItem2;
		
		f.components[0].Supplier__c = f.supplier.Id;
		update f.components[0];
		
        component = f.components[1].clone(true,true);
        component.Supplier__c = f.supplier.Id;
        
        try {
            update component;
            System.assert(false,'You can’t choose same supplier on a outside processing component associated to same routing/operation.');
        } catch (Exception e) {
            System.assert(true);
        }

        update f.itemList[0];

        component.Type__c = WorkOrderService.MATERIAL_TYPE_BYPRODUCT;
        component.Component_Sequence__c = null;
        try {
            update component;
            System.assert(false,'An OSP component and byproduct component are tied to the same routing');
        } catch (Exception e) {
            System.assert(true);
        }

        f.itemList[0].Item_Attribute__c = f.itemAttrObj2.Id;
        update f.itemList[0];

        component = f.components[1].clone(true,true);
        try {
            update component;
            System.assert(false,'An OSP component and serialized component are tied to the same routing');
        } catch (Exception e) {
            System.assert(true);
        }

        f.itemList[0].Item_Attribute__c = f.itemAttrObj.Id;
        update f.itemList[0];
        update f.components;
        
        delete configList;
        WorkOrderPlanningService.release(new Set<Id>{ f.workOrder.Id });

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{ f.workOrder.Id },null,null,new Set<String>{ 'Material_Trackings__r','Operation_Trackings__r' })[0];

        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_RELEASED,'Expected WO status: ' + WorkOrderService.WO_STATUS_RELEASED + ' // WO status: ' + wo.Status__c);
        System.assert(wo.Material_Trackings__r.size() == 2,'Expected materials: 2 // Materials: ' + wo.Material_Trackings__r.size());
        System.assert(wo.Operation_Trackings__r.size() == 3,'Expected operations: 3 // Operations: ' + wo.Operation_Trackings__r.size());

        Id subcontractOpId;
        for (Material_Tracking__c m:wo.Material_Trackings__r) {
            if (m.Item__c == ospItem.Id) {
                subcontractOpId = m.Operation_Tracking__c;
                break;
            }
        }

        System.assert(subcontractOpId != null,'Subcontract operation Id is null');

        Operation_Tracking__c subcontractOperation;
        for (Operation_Tracking__c op:wo.Operation_Trackings__r) {
            if (subcontractOpId == op.Id) {
                subcontractOperation = op;
                break;
            }
        }

        System.assert(subcontractOperation != null,'Subcontract operation is null');

        Operation_Tracking__c operationClone = subcontractOperation.clone(true,true);
        operationClone.Sequence__c = 100;
        try {
            update operationClone;
            System.assert(false,'An operation with an OSP was changed to the last operation');
        } catch (Exception e) {
            System.assert(true);
        }

        try {
            delete operationClone;
            System.assert(false,'An operation with an OSP item was deleted');
        } catch (Exception e) {
            System.assert(true);
        }

        SOQLUtil polQuery = new SOQLUtil('Purchase_Order_Line__c');
        polQuery.addAllCustomFields();
        polQuery.addAllCustomFields(Purchase_Order__c.sObjectType,'Purchase_Order__r');
        polQuery.setWhereClause('Operation_Tracking__c = :subContractOpId');
        List<Purchase_Order_Line__c> poLines = Database.query(polQuery.getQuery());

        System.assert(poLines.size() == 1,'Expected PO lines: 1 // PO lines: ' + poLines.size());

        Purchase_Order_Line__c pol = poLines[0];
        System.assert(pol.Item_Specification__c == wo.Assembly_Item_Specification__c,'Expected POL spec: ' + wo.Assembly_Item_Specification__c + ' // POL spec: ' + pol.Item_Specification__c);
        System.assert(pol.Order_Quantity__c == wo.Order_Quantity__c,'Expected POL quantity: ' + wo.Order_Quantity__c + ' // POL quantity: ' + pol.Order_Quantity__c);

        Purchase_Order__c po = pol.Purchase_Order__r;
        System.assert(po.Supplier__c == ospItem.Supplier__c,'Expected PO supplier: ' + ospItem.Supplier__c + ' // PO supplier: ' + po.Supplier__c);
        System.assert(po.Need_Date__c == subcontractOperation.Start_Date__c.date(),'Expected PO need date: ' + subcontractOperation.Start_Date__c.date() + ' // PO need date: ' + po.Need_Date__c);
        System.assert(po.Delivery_Facility__c == wo.Facility__c,'Expected PO delivery facility: ' + wo.Facility__c + ' // PO delivery facility: ' + po.Delivery_Facility__c);
        System.assert(po.Delivery_Location__c == fuel.location2.Id,'Expected PO delivery location: ' + fuel.location2.Id + ' // PO delivery location: ' + po.Delivery_Location__c);

        po.Approval_Status__c = PurchaseOrderService.PO_APPROVAL_STATUS_APPROVED;
        update po;
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static void setupInventory(Boolean attributes,Boolean serials) {
        Map<Id,Lot__c> lots = new Map<Id,Lot__c>();
        List<SKID__c> skids = new List<SKID__c>();
        for (Item__c item:fuel.itemList) {
            if (item.Non_Inventory__c) {
                continue;
            }

            SKID__c skid1 = new SKID__c(
                Facility2__c = fuel.facility2.Id,
                Company__c = fuel.company.Id,
                Item__c = item.Id,
                Location__c = fuel.location3.Id,
                Quantity__c = 100,
                Quantity_Stocking_UOM__c = 100,
                Stocking_UOM__c = item.Stocking_UOM__c,
        	    Packaging_UOM__c = item.Stocking_UOM__c,
                Type__c = SkidService3.SKID_TYPE_LOCATION
            );

            if (!attributes && !serials) {
                item.Item_Attribute__c = null;
            } else if (attributes) {
                lots.put(item.Id,new Lot__c(Name = 'Lot1', Item__c = item.Id, Company__c = fuel.company.Id));

                skid1.Expiration_Date__c = System.today() + 365;
                skid1.Lot_Number__c = 'Lot1';

                if (serials && item.Id != fuel.components[1].Component_Item__c) {
                    item.Item_Attribute__c = fuel.itemAttrObj2.Id;

                    skid1.Quantity__c = 10;
                    skid1.Quantity_Stocking_UOM__c = 10;
                }
            }

            SKID__c skid2 = skid1.clone(false,true);
            skid2.Location__c = fuel.location5.Id;

            skids.add(skid1);
            skids.add(skid2);
        }
        update fuel.itemList;
        if (lots.size() > 0) insert lots.values();
        insert skids;

        List<Serial__c> serialsToInsert = new List<Serial__c>();
        for (SKID__c skid:skids) {
            if (attributes) {
                skid.Lot__c = lots.get(skid.Item__c).Id;

                if (serials && skid.Item__c != fuel.components[1].Component_Item__c) {
                    for (Integer i=0;i<10;i++) {
                        serialsToInsert.add(new Serial__c(
                            Name = '' + skid.Id + i,
                            Company__c = skid.Company__c,
                            Item__c = skid.Item__c,
                            SKID__c = skid.Id,
                            Unique_Key2__c = '' + skid.Company__c + '-' + skid.Item__c + '-' + skid.Id + i
                        ));
                    }
                }
            }
        }

        if (attributes) update skids;
        if (serialsToInsert.size() > 0) insert serialsToInsert;
    }

    private static Set<Id> getPOLIds() {
        JsonResult result = ReceivingWorkBenchExt.getLinesToReceive(ReceivingWorkBenchExt.getGridConfig('Purchase Order').get('config'),fuel.workOrder.Facility__c,null,null,null,null,null,null,null,null);
        System.assert(result.success,'ReceivingWorkBenchExt.getLinesToReceive fail: ' + result);
        System.assert(result.records.size() == 1,'Expected PO lines: 1 // PO lines: ' + result.records.size());

        Set<Id> polIds = new Set<Id>();
        for (Purchase_Order_Line__c pol:(List<Purchase_Order_Line__c>)result.records) {
            pol.Packaging_UOM__c = pol.Item__r.Stocking_UOM__c;
            polIds.add(pol.Id);
        }

        return polIds;
    }

    private static List<ReceivingWrapper> getReceivingWrappers(Set<Id> polIds) {
        JsonResult result = ReceivingWorkBenchExt.getList(new List<Id>(polIds),'Purchase Order');
        System.assert(result.success,'ReceivingWorkBenchExt.getList fail: ' + result);
        System.assert(result.records.size() == 1,'Expected PO lines: 1 // PO lines: ' + result.records.size());

        return (List<ReceivingWrapper>)result.records;
    }

    private static Receiving_Document__c getRD(Set<Id> polIds) {
        JsonResult result = ReceivingWorkBenchExt.getrdDetails(new List<Id>(polIds),'Purchase Order',fuel.workOrder.Currency__c);
        System.assert(result.success,'ReceivingWorkBenchExt.getrdDetails fail: ' + result);
        System.assert(result.records.size() == 1,'Expected RDs: 1 // RDs: ' + result.records.size());

        return (Receiving_Document__c)result.records[0];
    }

    private static void receive(List<ReceivingWrapper> rWrappers,Receiving_Document__c rd) {
        JsonResult result = ReceivingWorkBenchExt.receive(rWrappers,new List<String>(),new List<String>(),rd,new List<String>());
        System.assert(result.success,'ReceivingWorkBenchExt.receive fail: ' + result);
    }

    private static void validate(Set<Id> polIds) {
        SOQLUtil polQuery = new SOQLUtil('Purchase_Order_Line__c');
        polQuery.addAllCustomFields();
        polQuery.setWhereClause('Id IN :polIds');
        List<Purchase_Order_Line__c> poLines = Database.query(polQuery.getQuery());

        System.assert(poLines.size() == 1,'Expected PO lines: 1 // PO lines: ' + poLines.size());
        System.assert(poLines[0].Quantity_Received__c == 5,'Expected quantity received: 5 // Quantity received: ' + poLines[0].Quantity_Received__c);

        SOQLUtil icQuery = new SOQLUtil('Inventory_Change__c');
        icQuery.addAllCustomFields();
        icQuery.setWhereClause('Work_Order__c = \'' + fuel.workOrder.Id + '\'');

        SOQLUtil.ChildRelationship itQuery = new SOQLUtil.ChildRelationship(icQuery,'Inventory_Transactions__r');
        itQuery.addAllCustomFields();
        icQuery.addChildRelationship(itQuery);

        List<Inventory_Change__c> icList = Database.query(icQuery.getQuery());
        System.assert(icList.size() == 1,icList);
        Inventory_Change__c ic = icList[0];
        System.assert(ic.Type__c == 'Work Order Complete','Expected IC type: Work Order Complete // IC type: ' + ic.Type__c);
        System.assert(ic.Finalized__c,'Expected Finalized IC');

        List<Inventory_Transaction__c> itList = ic.Inventory_Transactions__r;
        System.assert(itList.size() == 2,'Expected ITs: 2 // ITs: ' + itList.size());   //1 for assembly, 1 for bf component
        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Quantity__c == 5,'Expected IT quantity: 5 // IT quantity: ' + it.Quantity__c);
        }
    }

    private static testMethod void testNoAttributes() {
        setupInventory(false,false);

        Set<Id> polIds = getPOLIds();
        List<ReceivingWrapper> rWrappers = getReceivingWrappers(polIds);
        Receiving_Document__c rd = getRD(polIds);

        for (ReceivingWrapper rw:rWrappers) {
            System.assert(rw.serialWrapperList.size() == 1,'Expected serial wrappers: 1 // Serial wrappers: ' + rw.serialWrapperList.size());
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 5;
                sw.skid.Packaging_UOM__c = fuel.uomObj.Id;
                sw.skid.Packaging_UOM__r = fuel.uomObj;
                sw.skid.Packaging_UOM__r.Package_Class__r = null;
            }
        }

        Test.startTest();

        receive(rWrappers,rd);
        validate(polIds);

        Test.stopTest();
    }

    private static testMethod void testAttributes() {
        setupInventory(true,false);

        Set<Id> polIds = getPOLIds();
        List<ReceivingWrapper> rWrappers = getReceivingWrappers(polIds);
        Receiving_Document__c rd = getRD(polIds);

        for (ReceivingWrapper rw:rWrappers) {
            System.assert(rw.serialWrapperList.size() == 1,'Expected serial wrappers: 1 // Serial wrappers: ' + rw.serialWrapperList.size());
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 5;
                sw.skid.Expiration_Date__c = System.today() + 30;
                sw.skid.Lot_Number__c = 'Lot2';
                sw.skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                sw.skid.Packaging_UOM__r = fuel.uomObj;
                sw.skid.Packaging_UOM__r.Package_Class__r = null;
            }
        }

        Test.startTest();

        receive(rWrappers,rd);
        validate(polIds);

        Test.stopTest();
    }

    private static testMethod void testSerials() {
        setupInventory(true,false);

        Set<Id> polIds = getPOLIds();
        List<ReceivingWrapper> rWrappers = getReceivingWrappers(polIds);
        Receiving_Document__c rd = getRD(polIds);

        for (ReceivingWrapper rw:rWrappers) {
            System.assert(rw.serialWrapperList.size() == 1,'Expected serial wrappers: 1 // Serial wrappers: ' + rw.serialWrapperList.size());
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 5;
                sw.skid.Expiration_Date__c = System.today() + 30;
                sw.skid.Lot_Number__c = 'Lot2';
                sw.skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                sw.skid.Packaging_UOM__r = fuel.uomObj;
                sw.skid.Packaging_UOM__r.Package_Class__r = null;

                sw.serialList = new List<Serial__c>{
                    new Serial__c(Name='SERIAL1'),
                    new Serial__c(Name='SERIAL2'),
                    new Serial__c(Name='SERIAL3'),
                    new Serial__c(Name='SERIAL4'),
                    new Serial__c(Name='SERIAL5')
                };
            }
        }

        Test.startTest();

        receive(rWrappers,rd);
        validate(polIds);

        Test.stopTest();
    }

    private static testMethod void testASN() {
        setupInventory(true,false);

        Set<Id> polIds = getPOLIds();

        SOQLUtil polQuery = new SOQLUtil('Purchase_Order_Line__c');
        polQuery.addAllCustomFields();
        polQuery.addAllCustomFields(Item__c.sObjectType,'Item__r');
        polQuery.addAllCustomFields(Item__c.sObjectType,'Item_Specification__r.Item__r');
        polQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Item__r.Item_Attribute__r');
        polQuery.setWhereClause('Id IN :polIds');

        List<Purchase_Order_Line__c> pols = Database.query(polQuery.getQuery());
        for (Purchase_Order_Line__c pol:pols) {
            pol.Approved__c = false;
            pol.Purchase_UOM__c = pol.Item__r.Stocking_UOM__c;
        }
        update pols;

        FOB_Terms__c fob = new FOB_Terms__c(
            Name = 'Origin',
            FOB_Point__c = 'Origin'
        );
        insert fob;
        
        update new Purchase_Order__c(Id = pols[0].Purchase_Order__c, FOB_Term__c = fob.Id);
		Test.startTest();
        update new Purchase_Order__c(Id = pols[0].Purchase_Order__c, Approval_Status__c = PurchaseOrderService.PO_APPROVAL_STATUS_APPROVED);

        ASN__c asn = new ASN__c(
            Company__c = fuel.workOrder.Company__c,
            Supplier__c = fuel.components[0].Supplier__c,
            Facility__c = fuel.workOrder.Facility__c,
            FOB__c = fob.Id,
            Status__c = 'Draft',
            Transaction_Date__c = System.today(),
            Currency__c = fuel.workOrder.Currency__c,
            Transaction_Type__c = 'Purchase Order ASN'
        );
        insert asn;
        
        ASN_Line__c asnLine = new ASN_Line__c(
            Purchase_Order__c = pols[0].Purchase_Order__c,
            Purchase_Order_Line__c = pols[0].Id,
            Item__c = pols[0].Item__c,
            Item__r = pols[0].Item__r,
            Quantity_Shipped__c = 5,
            Quantity_Received__c = 0,
            Unit_Price__c = 0,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = fuel.workOrder.Company__c,
            Supplier__c = fuel.components[0].Supplier__c,
            Facility__c = fuel.workOrder.Facility__c,
            Location__c = pols[0].Delivery_Location__c
        );
        insert asnLine;
		
		Lot__c lot2 = new Lot__c(Company__c = asn.company__c, Item__c = asnLine.Item__c, Expiration_Date__c = system.today()+30, Name='lot2' );
        insert lot2;
        SKID__c skid = new SKID__c(
            ASN_Line__c = asnLine.Id,
            Facility2__c = asnLine.Facility__c,
            Location__c = asnLine.Location__c,
            Type__c = SkidService3.SKID_TYPE_INTRANSIT,
            Item__c = asnLine.Item__c,
            Item__r = asnLine.Item__r,
            Company__c = asn.Company__c,
            Quantity__c = 5,
            Lot_Number__c = lot2.Name,
            Lot__c = lot2.Id,
            Expiration_Date__c = System.today() + 30,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );
        insert skid;

        JsonResult result = ASNService.ConfirmASN(asn);
        System.assert(result.success,'ASNService.ConfirmASN failed: ' + result);

        result = ReceivingWorkBenchExt.getList(new List<Id>{ asnLine.Id },'ASN');
        System.assert(result.success,'ReceivingWorkBenchExt.getList fail: ' + result);
        System.assert(result.records.size() == 1,'Expected ASN lines: 1 // ASN lines: ' + result.records.size());
        List<ReceivingWrapper> rWrappers = (List<ReceivingWrapper>)result.records;

        for (ReceivingWrapper rw:rWrappers) {
            System.assert(rw.serialWrapperList.size() == 1,'Expected serial wrappers: 1 // Serial wrappers: ' + rw.serialWrapperList.size());
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 5;
                sw.skid.Expiration_Date__c = System.today() + 30;
                sw.skid.Lot_Number__c = lot2.Name;
                sw.skid.Lot__c = lot2.Id;
                sw.skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                sw.skid.Packaging_UOM__r = fuel.uomObj;
                sw.skid.Packaging_UOM__r.Package_Class__r = null;
            }
        }

        result = ReceivingWorkBenchExt.getrdDetails(new List<Id>{ asnLine.Id },'ASN',fuel.workOrder.Currency__c);
        System.assert(result.success,'ReceivingWorkBenchExt.getrdDetails fail: ' + result);
        System.assert(result.records.size() == 1,'Expected RDs: 1 // RDs: ' + result.records.size());
        Receiving_Document__c rd = (Receiving_Document__c)result.records[0];

        result = ReceivingWorkBenchExt.receive(rWrappers,new List<String>(),new List<String>(),rd,new List<String>());
        System.assert(result.success,'ReceivingWorkBenchExt.receive fail: ' + result);

        validate(polIds);
        Test.stopTest();
    }
}