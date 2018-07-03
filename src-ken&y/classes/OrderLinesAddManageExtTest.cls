@isTest
private class OrderLinesAddManageExtTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.periodList != null);
        System.assert(f.transferOrder != null);
    }

    private static TestFuelQuery fuel = new TestFuelQuery();
      
    private static testMethod void addManage() {
        Order__c to = new Order__c(
            Shipping_Company__c = fuel.company.Id,
            Ship_From_Facility__c = fuel.facility2.Id,
            Ship_From_Location__c = fuel.location2.Id,
            Receiving_Company__c = fuel.company.Id,
            Deliver_To_Facility__c = fuel.facility.Id,
            Deliver_To_Location__c = fuel.location.Id,
            Currency__c = fuel.currencyUSD.Id,
            Status__c = OrderService.O_STATUS_DRAFT
        );
        insert to;

        OrderLinesAddManageExt ext = new OrderLinesAddManageExt(new ApexPages.StandardController(to));
        JsonResult result = OrderLinesAddManageExt.getLinesForAddManage(to.Id);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 0, result.records);

        List<OrderService.OrderWrapper> orderLines = new List<OrderService.OrderWrapper>{
            new OrderService.OrderWrapper(new Order_Line__c(
                Order__c = to.Id,
                Shipping_Company__c = fuel.company.Id,
                Ship_From_Facility__c = fuel.facility2.Id,
                Shipping_Item__c = fuel.itemList[0].Id,
                Receiving_Company__c = fuel.company.Id,
                Deliver_To_Facility__c = fuel.facility.Id,
                Deliver_To_Location__c = fuel.location.Id,
                Receiving_Item__c = fuel.itemList[0].Id,
                Description__c = fuel.itemList[0].Description__c,
                Quantity_Ordered__c = 10,
                Required_Date__c = System.today() + 7
            ), null, null, null),

            new OrderService.OrderWrapper(new Order_Line__c(
                Order__c = to.Id,
                Shipping_Company__c = fuel.company.Id,
                Ship_From_Facility__c = fuel.facility2.Id,
                Ship_From_Location__c = fuel.location2.Id,
                Shipping_Item__c = fuel.itemList[5].Id,
                Receiving_Company__c = fuel.company.Id,
                Deliver_To_Facility__c = fuel.facility.Id,
                Deliver_To_Location__c = fuel.location.Id,
                Receiving_Item__c = fuel.itemList[5].Id,
                Description__c = fuel.itemList[5].Description__c,
                Quantity_Ordered__c = 10,
                Required_Date__c = System.today() + 7
            ), null, null, null)
        };

        result = OrderLinesAddManageExt.saveList(to.Id, new List<OrderService.OrderWrapper>(), orderLines, new List<OrderService.OrderWrapper>(), new List<String>());
        System.assert(result.success == false, result);

        ExceptionService.messages.clear();
        orderLines[0].order.put('Ship_From_Location__c', fuel.location2.Id);

        result = OrderLinesAddManageExt.saveList(to.Id, new List<OrderService.OrderWrapper>(), orderLines, new List<OrderService.OrderWrapper>(), new List<String>());
        System.assert(result.success == true, result);

        result = OrderLinesAddManageExt.getExceptionLines(to.Id);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 0, result.records);

        result = OrderLinesAddManageExt.getLinesForAddManage(to.Id);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 2, result.records);

        orderLines = (List<OrderService.OrderWrapper>)result.records;
        List<OrderService.OrderWrapper> updatedList = new List<OrderService.OrderWrapper>{ orderLines[0] };
        updatedList[0].order.put('Quantity_Ordered__c', 1000);
        List<OrderService.OrderWrapper> deletedList = new List<OrderService.OrderWrapper>{ orderLines[1] };

        result = OrderLinesAddManageExt.saveList(to.Id, updatedList, new List<OrderService.OrderWrapper>(), deletedList, new List<String>());
        System.assert(result.success == true, result);

        result = OrderLinesAddManageExt.getLinesForAddManage(to.Id);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 1, result.records);
    }

    private static testMethod void releaseWithFacilityItem () {


        Facility_Item__c fi = new Facility_Item__c();
        fi.Company__c = fuel.company.ID;
        fi.Facility__c = fuel.facility.ID;
        fi.Item__c = fuel.itemList[0].ID;
        fi.Lead_Time__c = fuel.itemList[0].Lead_Time__c + 5;

        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller( fi );
        FacilityItemNewExt ext1 = new FacilityItemNewExt(con);
        ext1.SaveFI();
        system.assert(Apexpages.hasMessages() == false, Apexpages.getMessages());

        Facility_Item__c fi2 = new Facility_Item__c();
        fi2.Company__c = fuel.company.ID;
        fi2.Facility__c = fuel.facility.ID;
        fi2.Item__c = fuel.itemList[5].ID;
        fi2.Lead_Time__c = fuel.itemList[5].Lead_Time__c + 5;

        con = new Apexpages.Standardcontroller( fi2 );
        ext1 = new FacilityItemNewExt(con);
        ext1.SaveFI();
        system.assert(Apexpages.hasMessages() == false, Apexpages.getMessages());
        Map<Id, Facility_Item__c> mapFacilityItems = new Map<Id, Facility_Item__c>{
                fi.Item__c => fi,
                fi2.Item__c => fi2
        };

        Order__c to = fuel.transferOrder;

        JsonResult result = OrderLinesAddManageExt.getLinesForAddManage(to.id);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 2, result.records);

        result = OrderLinesAddManageExt.releaseList(to.Id);
        System.assert(result.success == true, result);

        OrderLinesAddManageExt ext = new OrderLinesAddManageExt(new ApexPages.StandardController(to));

        result = OrderLinesAddManageExt.getLinesForAddManage(to.Id);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 2, result.records);

        List<OrderService.OrderWrapper> orderLines = (List<OrderService.OrderWrapper>)result.records;
        system.assert(OrderLinesAddManageExt.ShipmentExist(orderLines) == true);

        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
        shlQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Facility__c', 'Item__c', 'Location__c', 'Order__c', 'Order_Line__c', 'Shipment__c', 'Item__r.Lead_Time__c',

                'Order__r.Status__c', 'Estimated_Ship_Date__c', 'Need_Date__c', 'Facility__r.Shipping_Calendar__c',

                'Order_Line__r.Order__c', 'Order_Line__r.Shipping_Item__c', 'Order_Line__r.Status__c', 'Order_Line__r.Required_Date__c',

                'Shipment__r.Currency__c', 'Shipment__r.Ship_From_Facility__c', 'Shipment__r.Ship_From_Location__c', 'Shipment__r.Status__c', 'Shipment__r.Type__c'
        });
        shlQuery.setWhereClause('Order__c = \'' + to.Id + '\'');

        List<Shipment_Line__c> shipmentLines = Database.query(shlQuery.getQuery());
        System.assert(shipmentLines.size() == 2, shipmentLines);

        for (Shipment_Line__c shl:shipmentLines) {
            System.assert(shl.Company__c == to.Shipping_Company__c, shl);
            System.assert(shl.Facility__c == to.Ship_From_Facility__c, shl);
            System.assert(shl.Location__c == to.Ship_From_Location__c, shl);
            System.assert(shl.Item__c == shl.Order_Line__r.Shipping_Item__c, shl);
            System.assert(shl.Order__c == to.Id, shl);
            System.assert(shl.Order__r.Status__c == OrderService.O_STATUS_OPEN, shl.Order__r);
            System.assert(shl.Order_Line__r.Order__c == to.Id, shl);
            System.assert(shl.Order_Line__r.Status__c == OrderService.O_STATUS_OPEN, shl.Order_Line__r);
            System.assert(shl.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_PLANNED, shl.Shipment__r);
            System.assert(shl.Shipment__r.Currency__c == to.Currency__c, shl.Shipment__r);
            System.assert(shl.Shipment__r.Ship_From_Facility__c == to.Ship_From_Facility__c, shl.Shipment__r);
            System.assert(shl.Shipment__r.Ship_From_Location__c == to.Ship_From_Location__c, shl.Shipment__r);
            System.assert(shl.Shipment__r.Type__c == ShipmentService.SHIPMENT_TYPE_TRANSFER_ORDER, shl.Shipment__r);
            System.assert(shl.Need_Date__c ==  shl.Order_Line__r.Required_Date__c );
            Integer leadTime = (Integer)mapFacilityItems.get(shl.Item__c).Lead_Time__c;
            System.assert(shl.Estimated_Ship_Date__c == KSE.calculateEndDate(system.today(), leadTime, shl.Facility__r.Shipping_Calendar__c) );
        }
    }

    private static testMethod void plan() {
        Order__c to = fuel.transferOrder;

        JsonResult result = OrderLinesAddManageExt.getLinesForAddManage(to.id);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 2, result.records);

        result = OrderLinesAddManageExt.releaseList(to.Id);
        System.assert(result.success == true, result);

        OrderLinesAddManageExt ext = new OrderLinesAddManageExt(new ApexPages.StandardController(to));

        result = OrderLinesAddManageExt.getLinesForAddManage(to.Id);
        System.assert(result.success == true, result);
        System.assert(result.records.size() == 2, result.records);

        List<OrderService.OrderWrapper> orderLines = (List<OrderService.OrderWrapper>)result.records;
        system.assert(OrderLinesAddManageExt.ShipmentExist(orderLines) == true);

        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
        shlQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Facility__c', 'Item__c', 'Location__c', 'Order__c', 'Order_Line__c', 'Shipment__c', 'Item__r.Lead_Time__c',
            
            'Order__r.Status__c', 'Estimated_Ship_Date__c', 'Need_Date__c', 'Facility__r.Shipping_Calendar__c',

            'Order_Line__r.Order__c', 'Order_Line__r.Shipping_Item__c', 'Order_Line__r.Status__c', 'Order_Line__r.Required_Date__c',

            'Shipment__r.Currency__c', 'Shipment__r.Ship_From_Facility__c', 'Shipment__r.Ship_From_Location__c', 'Shipment__r.Status__c', 'Shipment__r.Type__c'
        });
        shlQuery.setWhereClause('Order__c = \'' + to.Id + '\'');

        List<Shipment_Line__c> shipmentLines = Database.query(shlQuery.getQuery());
        System.assert(shipmentLines.size() == 2, shipmentLines);

        for (Shipment_Line__c shl:shipmentLines) {
            System.assert(shl.Company__c == to.Shipping_Company__c, shl);
            System.assert(shl.Facility__c == to.Ship_From_Facility__c, shl);
            System.assert(shl.Location__c == to.Ship_From_Location__c, shl);
            System.assert(shl.Item__c == shl.Order_Line__r.Shipping_Item__c, shl);
            System.assert(shl.Order__c == to.Id, shl);
            System.assert(shl.Order__r.Status__c == OrderService.O_STATUS_OPEN, shl.Order__r);
            System.assert(shl.Order_Line__r.Order__c == to.Id, shl);
            System.assert(shl.Order_Line__r.Status__c == OrderService.O_STATUS_OPEN, shl.Order_Line__r);
            System.assert(shl.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_PLANNED, shl.Shipment__r);
            System.assert(shl.Shipment__r.Currency__c == to.Currency__c, shl.Shipment__r);
            System.assert(shl.Shipment__r.Ship_From_Facility__c == to.Ship_From_Facility__c, shl.Shipment__r);
            System.assert(shl.Shipment__r.Ship_From_Location__c == to.Ship_From_Location__c, shl.Shipment__r);
            System.assert(shl.Shipment__r.Type__c == ShipmentService.SHIPMENT_TYPE_TRANSFER_ORDER, shl.Shipment__r);
            System.assert(shl.Need_Date__c ==  shl.Order_Line__r.Required_Date__c );
            Integer leadTime = (Integer)shl.Item__r.Lead_Time__c;
            System.assert(shl.Estimated_Ship_Date__c == KSE.calculateEndDate(system.today(), leadTime, shl.Facility__r.Shipping_Calendar__c) );
        }

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Container_Item__c', 'Facility2__c', 'Item__c', 'Location__c', 'Order_Line__c',
            'Quantity__c', 'Quantity_Stocking_UOM__c', 'Packaging_UOM__c', 'Shipment_Line__c', 'Stocking_UOM__c', 'Type__c',

            'Order_Line__r.Order__c', 'Order_Line__r.Quantity_Ordered__c', 'Order_Line__r.Receiving_Item__c', 'Order_Line__r.Receiving_Item__r.Stocking_UOM__c',
            'Order_Line__r.Shipping_Item__c', 'Order_Line__r.Shipping_Item__r.Stocking_UOM__c',

            'Shipment_Line__r.Order__c'
        });
        skidQuery.setWhereClause('Order_Line__r.Order__c = \'' + to.Id + '\'');

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 4, skids);

        for (SKID__c skid:skids) {
            System.assert(skid.Quantity__c == skid.Order_Line__r.Quantity_Ordered__c, skid);
            System.assert(skid.Quantity_Stocking_UOM__c == skid.Order_Line__r.Quantity_Ordered__c, skid);
            System.assert(skid.Order_Line__r.Order__c == to.Id, skid);

            if (skid.Type__c == SkidService3.SKID_TYPE_TO_DEMAND) {
                System.assert(skid.Company__c == to.Shipping_Company__c, skid);
                System.assert(skid.Packaging_UOM__c == skid.Order_Line__r.Shipping_Item__r.Stocking_UOM__c, skid);
                System.assert(skid.Stocking_UOM__c == skid.Order_Line__r.Shipping_Item__r.Stocking_UOM__c, skid);
                System.assert(skid.Item__c == skid.Order_Line__r.Shipping_Item__c, skid);
                System.assert(skid.Container_Item__c == skid.Order_Line__r.Shipping_Item__c, skid);
                System.assert(skid.Facility2__c == to.Ship_From_Facility__c, skid);
                System.assert(skid.Location__c == to.Ship_From_Location__c, skid);
                System.assert(skid.Shipment_Line__r.Order__c == to.Id, skid);
            } else if (skid.Type__c == SkidService3.SKID_TYPE_TO_SUPPLY) {
                System.assert(skid.Company__c == to.Receiving_Company__c, skid);
                System.assert(skid.Packaging_UOM__c == skid.Order_Line__r.Receiving_Item__r.Stocking_UOM__c, skid);
                System.assert(skid.Stocking_UOM__c == skid.Order_Line__r.Receiving_Item__r.Stocking_UOM__c, skid);
                System.assert(skid.Item__c == skid.Order_Line__r.Receiving_Item__c, skid);
                System.assert(skid.Container_Item__c == skid.Order_Line__r.Receiving_Item__c, skid);
                System.assert(skid.Facility2__c == to.Deliver_To_Facility__c, skid);
                System.assert(skid.Location__c == to.Deliver_To_Location__c, skid);
            } else {
                System.assert(false, 'Invalid skid type: ' + skid.Type__c);
            }
        }

        ext.selectedShipment = shipmentLines[0].Shipment__c;
        ext.orderId = to.Id;
        ext.release();

        result = OrderLinesAddManageExt.undoRelease(orderLines, new List<String>(), new List<String>());
        System.assert(result.success == true, result);

        shipmentLines = Database.query(shlQuery.getQuery());
        System.assert(shipmentLines.size() == 0, shipmentLines);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0, skids);
    }

    private static testMethod void cancelLines() {
        Order__c to = fuel.transferOrder;
        OrderService.release(new Map<Id, Id>{ to.Id => null });
        List<OrderService.OrderWrapper> orderLines = (List<OrderService.OrderWrapper>)OrderLinesAddManageExt.getLinesForAddManage(to.Id).records;

        JsonResult result = OrderLinesAddManageExt.cancelLines(orderLines, new List<String>());
        System.assert(result.success == true, result);

        OrderLinesAddManageExt.undoRelease(orderLines, new List<String>(), new List<String>());
        orderLines = (List<OrderService.OrderWrapper>)OrderLinesAddManageExt.getLinesForAddManage(to.Id).records;

        ExceptionService.messages.clear();
        result = OrderLinesAddManageExt.cancelLines(orderLines, new List<String>());
        System.assert(result.success == true, result);
    }

    private static testMethod void cancelOrder() {
        fuel.setupInventory();

        Order__c to = fuel.transferOrder;
        OrderService.release(new Map<Id, Id>{ to.Id => null });

        SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 5;
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        TransferOrderCancelExt ext = new TransferOrderCancelExt(new Apexpages.StandardController(to));
        ext.cancel();

        SOQLUtil toQuery = new SOQLUtil('Order__c');
        toQuery.addFields(new Set<String>{ 'Id', 'Status__c' });
        toQuery.setWhereClause('Id = \'' + to.Id + '\'');
        
        to = Database.query(toQuery.getQuery());
        System.assert(to.Status__c == OrderService.O_STATUS_OPEN, to);

        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = -5;
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        ext.cancel();

        to = Database.query(toQuery.getQuery());
        System.assert(to.Status__c == OrderService.O_STATUS_CANCEL, to);
    }

    private static testMethod void deleteOrder() {
        Order__c to = fuel.transferOrder;
        OrderService.release(new Map<Id, Id>{ to.Id => null });

        try {
            delete to;
            System.assert(false, 'Delete should fail');
        } catch (Exception e) { }

        List<OrderService.OrderWrapper> orderLines = (List<OrderService.OrderWrapper>)OrderLinesAddManageExt.getLinesForAddManage(to.Id).records;
        OrderLinesAddManageExt.undoRelease(orderLines, new List<String>(), new List<String>());

        try {
            delete to;
        } catch (Exception e) {
            System.assert(false, 'Delete should succeed');
        }
    }

    private static testMethod void clone() {
        Order__c to = fuel.TransferOrder;
        OrderService.release(new Map<Id, Id>{ to.Id => null });

        to = [SELECT Id, Shipping_Company__c, Receiving_Company__c, Ship_From_Location__c, Deliver_To_Location__c, Ship_From_Facility__c, Deliver_To_Facility__c, Order_Date__c, Need_Date__c, Status__c FROM Order__c WHERE Id = :to.id];
        to.Order_Date__c = Date.Today();
        to.Need_Date__c = Date.Today();

        TransferOrderCloneExt ext = new TransferOrderCloneExt(new ApexPages.StandardController(to));
        ext.Save();
        System.assert(ext.redirectToRecordId!=null, ApexPages.getMessages());

        to = [SELECT Id, Status__c FROM Order__c WHERE Id != :to.Id];
        System.assert(to.Status__c == OrderService.O_STATUS_DRAFT, to);

        List<Order_Line__c> orderLines = [SELECT Id, Status__c FROM Order_Line__c WHERE Order__c = :to.Id];
        System.assert(orderLines.size() == 2, orderLines); 
        for (Order_line__c ol:orderLines) System.assert(ol.Status__c == OrderService.O_STATUS_DRAFT, ol);
    }
}