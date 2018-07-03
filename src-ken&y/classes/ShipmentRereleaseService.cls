public without sharing class ShipmentRereleaseService {
    public static JsonResult rerelease(Set<Id> shipmentIds) {
        Savepoint sp = Database.setSavepoint();
        JsonResult result = new JsonResult();
        List<Shipment_Line__c> shipmentLines;
        try {
            SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c', false);
            ShipmentWorkbenchExt.addShlFields(shlQuery, 'pick');
            shlQuery.setWhereClause('Shipment__c IN :shipmentIds ' +
                    'AND (Sales_Order_Line__c = null OR  Sales_Order_Line__r.Status__c = \'' + SalesOrderLineService.SO_LINE_STATUS_OPEN + '\') ' +
                    'AND (Order_Line__c = null OR Order_Line__r.Status__c = \'' + OrderService.O_STATUS_OPEN + '\')');

            SOQLUtil.ChildRelationship skidQuery = new SOQLUtil.ChildRelationship(shlQuery, 'SKIDs__r');
            skidQuery.addFields(SkidService3.getSkidSoql(new Map<String, String>()).getFields());
            shlQuery.addChildRelationship(skidQuery);

            shipmentLines = Database.query(shlQuery.getQuery());
            if (shipmentLines.size() == 0) return result;

            List<String> itAttributes = SkidService3.attributesForPutaway();
            List<String> skidAttributes = itAttributes.clone();
            skidAttributes.add('Sales_Order_Line__c');
            skidAttributes.add('Order_Line__c');
            skidAttributes.add('Type__c');

            Id companyId;
            Map<Id, Item__c> items = new Map<Id, Item__c>();
            List<Shipment_Line__c> shipmentLinesToUpdate = new List<Shipment_Line__c>();
            Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
            Map<Id, Id> soToShipment = new Map<Id, Id>();
            Map<Id, Id> orderToShipment = new Map<Id, Id>();
            Set<Id> orderLineIds = new Set<Id>();
            Map<Id, List<SKID__c>> skids = new Map<Id, List<SKID__c>>();
            Set<Id> skidIds = new Set<Id>();
            for (Shipment_Line__c shl:shipmentLines) {
                if (!(shl.Quantity_Shipped__c < shl.Quantity_Planned__c)) continue;

                companyId = shl.Company__c;
                items.put(shl.Item__c, shl.Item__r);
                shipmentLinesToUpdate.add(new Shipment_Line__c(Id = shl.Id, Quantity_Planned__c = shl.Quantity_Shipped__c, Quantity_Allocated__c = 0, Quantity_To_Pick__c = 0, Quantity_Picked__c = 0));
                if (packagingUoms.containsKey(shl.Item__c) == false) packagingUoms.put(shl.Item__c, (List<Id>)JSON.deserialize(shl.Item__r.Packaging_UOM__c, List<Id>.Class));

                Id orderLineId;
                if (shl.Sales_Order_Line__c != null) {
                    orderLineId = shl.Sales_Order_Line__c;
                    soToShipment.put(shl.Sales_Order__c, null);
                    orderLineIds.add(shl.Sales_Order_Line__c);
                } else {
                    orderLineId = shl.Order_Line__c;
                    orderToShipment.put(shl.Order__c, null);
                    orderLineIds.add(shl.Order_Line__c);
                }

                for (SKID__c skid:shl.SKIDs__r) {
                    skidIds.add(skid.Id);
                    if (skids.containsKey(orderLineId) == false) skids.put(orderLineId, new List<SKID__c>{ skid });
                    else skids.get(orderLineId).add(skid);
                }
            }

            SkidService3.setAllocAttributes(companyId, items);
            
            shlQuery = new SOQLUtil('Shipment_Line__c', false);
            ShipmentWorkbenchExt.addShlFields(shlQuery, 'pick');
            shlQuery.setWhereClause('(Sales_Order_Line__c IN :orderLineIds OR Order_Line__c IN :orderLineIds) AND Shipment__r.Status__c NOT IN (\'' + ShipmentService.SHIPMENT_STATUS_CONFIRMED + '\', \'' + ShipmentService.SHIPMENT_STATUS_DELIVERED + '\')');

            for (Shipment_Line__c shl:Database.query(shlQuery.getQuery())) {
                if (shl.Sales_Order_Line__c != null) soToShipment.put(shl.Sales_Order__c, shl.Shipment__c);
                else orderToShipment.put(shl.Order__c, shl.Shipment__c);
            }

            if (soToShipment.size() > 0) SalesOrderService.plan(soToShipment);
            if (orderToShipment.size() > 0) OrderService.release(orderToShipment);
            if (ExceptionService.hasErrors == true) throw new CustomException('ERROR');
            
            Map<Id, List<Serial__c>> serialMap = new Map<Id, List<Serial__c>>();
            if (skidIds.size() > 0) {
                SOQLUtil serialQuery = new SOQLUtil('Serial__c', false);
                serialQuery.addFields(new Set<String>{ 'Id', 'Name', 'Allocated_SKID__c', 'SKID__c' });
                serialQuery.setWhereClause('Allocated_SKID__c IN :skidIds OR SKID__c IN :skidIds');
                for (Serial__c serial:Database.query(serialQuery.getQuery())) {
                    Id skidId = skidIds.contains(serial.SKID__c) == true ? serial.SKID__c : serial.Allocated_SKID__c;
                    if (serialMap.containsKey(skidId) == false) serialMap.put(skidId, new List<Serial__c>{ serial });
                    else serialMap.get(skidId).add(serial);
                }
            }

            List<SkidService3.SerialWrapper> skidsToPutaway = new List<SkidService3.SerialWrapper>();
            Map<Id, SkidService3.ParameterData> itData = new Map<Id, SkidService3.ParameterData>();
            Map<List<String>, List<Serial__c>> reservedSerials = new Map<List<String>, List<Serial__c>>();
            Map<Id, Shipment__c> shipmentsToUpdate = new Map<Id, Shipment__c>();
            for (Shipment_Line__c shl:Database.query(shlQuery.getQuery())) {
                sObject orderLine;
                if (shl.Sales_Order_Line__c != null) orderLine = shl.Sales_Order_Line__r;
                else orderLine = shl.Order_Line__r;
                if (skids.containsKey(orderLine.Id) == false) continue;

                Shipment__c shipmentToUpdate = shipmentsToUpdate.containsKey(shl.Shipment__c) == true ? shipmentsToUpdate.get(shl.Shipment__c) : new Shipment__c(Id = shl.Shipment__c, Status__c = shl.Shipment__r.Status__c);
                Shipment_Line__c shlToUpdate = new Shipment_Line__c(Id = shl.Id, Quantity_Allocated__c = shl.Quantity_Allocated__c, Quantity_To_Pick__c = shl.Quantity_To_Pick__c, Quantity_Picked__c = shl.Quantity_Picked__c, Work_Order__c = shl.Sales_Order_Line__r.Work_Order__c);
                Decimal convFactor = shl.Sales_Order_Line__c != null ? KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, shl.Sales_Order_Line__r.Selling_UOM__c, shl.Item__r.Stocking_UOM__c, packagingUoms.get(shl.Item__c)) : 1;
                List<String> allocAttrs = SkidService3.allocAttributes.get(shl.Item__c);

                for (SKID__c skid:skids.get(orderLine.Id)) {
                    SKID__c newSkid;
                    if (skid.Type__c == SkidService3.SKID_TYPE_PLANNED && shl.Company__r.Auto_Plan_Pick__c == false) {
                        newSkid = new SKID__c(
                            Company__c = shl.Company__c,
                            Type__c = SkidService3.SKID_TYPE_ALLOCATED,
                            Quantity__c = skid.Quantity_Stocking_UOM__c,
                            Quantity_Stocking_UOM__c = skid.Quantity_Stocking_UOM__c,
                            Item__c = shl.Item__c,
                            Item__r = shl.Item__r,
                            Packaging_UOM__c = shl.Item__r.Stocking_UOM__c,
                            Packaging_UOM__r = shl.Item__r.Stocking_UOM__r,
                            Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                            Facility2__c = shl.Facility__c,
                            Facility2__r = shl.Facility__r,
                            Container_Item__c = shl.Item__c,
                            Container_Item__r = shl.Item__r,
                            Order_Line__c = shl.Order_Line__c,
                            Sales_Order_Line__c = shl.Sales_Order_Line__c
                        );
                        SkidService3.copyAttributes(skid, newSkid, allocAttrs);
                    } else {
                        newSkid = skid.clone(false, true);
                    }
                    newSkid.Shipment_Line__c = shl.Id;
                    skidsToPutaway.add(new SkidService3.SerialWrapper(newSkid, skid.Type__c == SkidService3.SKID_TYPE_LOCATION && serialMap.containsKey(skid.Id) == true ? serialMap.get(skid.Id) : new List<Serial__c>()));

                    skid.Quantity__c = -skid.Quantity__c;
                    skidsToPutaway.add(new SkidService3.SerialWrapper(skid));

                    if (skid.Type__c == SkidService3.SKID_TYPE_LOCATION) {
                        shipmentToUpdate.Status__c = ShipmentService.SHIPMENT_STATUS_STAGED;
                        shlToUpdate.Quantity_Picked__c += newSkid.Quantity_Stocking_UOM__c;

                        SkidService3.ParameterData itInfo = itData.containsKey(shl.Shipment__c) ? itData.get(shl.Shipment__c) : new SkidService3.ParameterData();
                        itInfo.sourceDoc = new Shipment__c(Company__c = shl.Company__c);

                        if (skid.Mixed_Palletized__c == true) {
                            SKID__c oldPickedSkid = skid.clone(false, true);
                            oldPickedSkid.Quantity__c = 0;
                            oldPickedSkid.Mixed_Palletized__c = false;
                            oldPickedSkid.Container_Item__r = SkidService3.getContainerforItem(shl.Item__r, skid.Packaging_UOM__r);
                            oldPickedSkid.Container_Item__c = oldPickedSkid.Container_Item__r.Id;
                            if (oldPickedSkid.Container_Item__r.Item_Attribute__c == null || oldPickedSkid.Container_Item__r.Item_Attribute__r.License_Plate_Number__c != true) {
                                oldPickedSkid.License_Plate_Number__c = null;
                                oldPickedSkid.License_Plate_Number__r = null;
                            }
                            skidsToPutaway.add(new SkidService3.SerialWrapper(oldPickedSkid));

                            SKID__c newPickedSkid = oldPickedSkid.clone(false, true);
                            newPickedSkid.Shipment_Line__c = shl.Id;
                            skidsToPutaway.add(new SkidService3.SerialWrapper(newPickedSkid));

                            Inventory_Transaction__c pickIt = SkidService3.createInventoryTransaction(shl.Item__r, orderLine, shl.Sales_Order_Line__c != null ? 'Sales Order Pick Transfer' : 'Transfer Order Pick Transfer', newSkid.Quantity__c, oldPickedSkid, newPickedSkid, itAttributes);
                            pickIt.From_SKID__r = oldPickedSkid.clone(false, true);
                            pickIt.To_SKID__r = newPickedSkid.clone(false, true);
                            itInfo.itList.add(pickIt);

                            Inventory_Transaction__c packIt = SkidService3.createInventoryTransaction(shl.Item__r, shl, 'Transfer', newSkid.Quantity__c, newPickedSkid, newSkid, itAttributes);
                            packIt.From_SKID__r = newPickedSkid.clone(false, true);
                            packIt.To_SKID__r = newSkid.clone(false, true);
                            itInfo.itList.add(packIt);
                        } else {
                            Inventory_Transaction__c it = SkidService3.createInventoryTransaction(shl.Item__r, orderLine, shl.Sales_Order_Line__c != null ? 'Sales Order Pick Transfer' : 'Transfer Order Pick Transfer', newSkid.Quantity__c, skid, newSkid, itAttributes);
                            it.From_SKID__r = skid.clone(false, true);
                            it.To_SKID__r = newSkid.clone(false, true);
                            itInfo.itList.add(it);
                        }
                        
                        itData.put(shl.Shipment__c, itInfo);
                    } else if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED || skid.Type__c == SkidService3.SKID_TYPE_PLANNED) {
                        if (shipmentToUpdate.Status__c != ShipmentService.SHIPMENT_STATUS_STAGED) shipmentToUpdate.Status__c = ShipmentService.SHIPMENT_STATUS_RELEASED;

                        if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) shlToUpdate.Quantity_Allocated__c += (newSkid.Quantity_Stocking_UOM__c / convFactor); //Stocking to Selling
                        else shlToUpdate.Quantity_To_Pick__c += newSkid.Quantity_Stocking_UOM__c;

                        if (serialMap.containsKey(skid.Id) == true) {
                            List<Serial__c> serials = serialMap.get(skid.Id);
                            List<String> skidKey = SkidService3.generateKey(newSkid, skidAttributes);
                            if (reservedSerials.containsKey(skidKey) == true) reservedSerials.get(skidKey).addAll(serials);
                            else reservedSerials.put(skidKey, serials);
                        }
                    }
                }

                shipmentsToUpdate.put(shl.Shipment__c, shipmentToUpdate);
                shipmentLinesToUpdate.add(shlToUpdate);
            }

            if (skidsToPutaway.size() > 0) {
                Map<List<String>, SkidService3.SerialWrapper> putawaySkids = SkidService3.putawayService(skidsToPutaway, skidAttributes, null);

                Map<Id, SKID__c> skidsToDelete = new Map<Id, SKID__c>();
                List<Serial__c> serialsToUpdate = new List<Serial__c>();
                for (List<String> skidKey:putawaySkids.keySet()) {
                    SkidService3.SerialWrapper sw = putawaySkids.get(skidKey);
                    if (sw.skid.Quantity__c == 0) skidsToDelete.put(sw.skid.Id, sw.skid);

                    if (reservedSerials.containsKey(skidKey) == true) {
                        for (Serial__c serial:reservedSerials.get(skidKey)) {
                            serial.Allocated_SKID__c = sw.skid.Id;
                            serialsToUpdate.add(serial);
                        }
                    }
                }

                if (itData.size() > 0) {
                    for (SkidService3.ParameterData itInfo:itData.values()) {
                        for (Inventory_Transaction__c it:itInfo.itList) {
                            SKID__c fromSkid = putawaySkids.get(SkidService3.generateKey(it.From_SKID__r, skidAttributes)).skid;
                            it.From_SKID__c = fromSkid.Id;
                            it.From_SKID__r = fromSkid;
                            skidsToDelete.remove(fromSkid.Id);  //Will be deleted when ITs are created

                            putawaySkids.put(SkidService3.generateKey(it, itAttributes), putawaySkids.get(SkidService3.generateKey(it.To_SKID__r, skidAttributes)));
                        }
                    }

                    SkidService3.inventoryTransactionsForPutaway(itData, itAttributes, putawaySkids, new Map<String,String>{ 'adjustFromSkidQuantity' => 'none', 'serialTransactionType' => 'Pick Transfer' });
                }

                if (skidsToDelete.size() > 0) DML.deleteAsSystem(skidsToDelete.values());
                if (serialsToUpdate.size() > 0) DML.updateAsSystem(serialsToUpdate);
            }

            if (shipmentsToUpdate.size() > 0) DML.updateAsSystem(shipmentsToUpdate.values());
            if (shipmentLinesToUpdate.size() > 0) DML.updateAsSystem(shipmentLinesToUpdate);
        } catch (Exception e) {
            Database.rollback(sp);
            ExceptionService exServ = new ExceptionService();

            CustomException.addError(result, 'An error has occurred while attempting to rerelease. Please rerelease manually.');
            if (ExceptionService.hasErrors == true) {
                result.messages.addAll(ExceptionService.messages);
            } else {
                CustomException.addError(result, e);

                if (shipmentLines != null && shipmentLines.size() > 0) {
                    ExceptionUtil.ORDER_RERELEASE_FAIL.description = CustomException.getMessage(e);
                    setExceptions(shipmentLines, ExceptionUtil.ORDER_RERELEASE_FAIL, exServ);
                }
            }

            if (shipmentLines != null && shipmentLines.size() > 0) {
                try {
                    undoShipment(shipmentLines);
                } catch (Exception e2) {
                    Database.rollback(sp);

                    CustomException.addError(result, 'An error has occurred while attempting to undo the shipment. Please contact your administrator.');
                    CustomException.addError(result, e2);

                    ExceptionUtil.UNDO_SHIPMENT_FAIL.description = CustomException.getMessage(e2);
                    setExceptions(shipmentLines, ExceptionUtil.UNDO_SHIPMENT_FAIL, exServ);
                }
            }

            exServ.finishTasks();
        }
        return result;
    }

    private static void setExceptions(List<Shipment_Line__c> shipmentLines, TaskType ex, ExceptionService exServ) {
        Set<Id> orderIds = new Set<Id>();
        for (Shipment_Line__c shl:shipmentLines) {
            sObject order = shl.Sales_Order__c != null ? (sObject)shl.Sales_Order__r : (sObject)shl.Order__r;
            if (orderIds.contains(order.Id) == true) continue;

            exServ.setException(order, ex);
            orderIds.add(order.Id);
        }
    }

    public static void undoShipment(List<Shipment_Line__c> shipmentLines) {
        Map<Id, Shipment_Line__c> shipmentLinesToUnpick = new Map<Id, Shipment_Line__c>();
        List<sObject> recordsToUpdate = new List<sObject>();
        for (Shipment_Line__c shl:shipmentLines) {
            if (!(shl.Quantity_Shipped__c < shl.Quantity_Planned__c)) continue;

            if (shl.Quantity_Picked__c > 0) {
                shipmentLinesToUnpick.put(shl.Id, shl);
                recordsToUpdate.add(new Shipment__c(Id = shl.Shipment__c, Status__c = ShipmentService.SHIPMENT_STATUS_CONFIRMED));
            }
            recordsToUpdate.add(new Shipment_Line__c(Id = shl.Id, Quantity_Planned__c = shl.Quantity_Shipped__c, Quantity_Allocated__c = 0, Quantity_To_Pick__c = 0));
            if (shl.Sales_Order_Line__c != null) recordsToUpdate.add(new Sales_Order_Line__c(Id = shl.Sales_Order_Line__c, Quantity_Allocated__c = 0));
            else if (shl.Order_Line__c != null) recordsToUpdate.add(new Order_Line__c(Id = shl.Order_Line__c, Quantity_Allocated__c = 0));
        }

        if (shipmentLinesToUnpick.size() > 0) {
            Map<Id, LineWrapper> shlWrappers = new Map<Id, LineWrapper>();
            for (LineWrapper wrapper:ShipmentInventoryService.getInventoryForPick(shipmentLinesToUnpick.values())) {
                Shipment_Line__c shl = shipmentLinesToUnpick.get(wrapper.line.Id);
                LineWrapper shlWrapper = shlWrappers.containsKey(shl.Id) ? shlWrappers.get(shl.Id) : new LineWrapper(shl.Shipment__r, shl);
            
                for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                    if (sw.skid.Quantity_Used__c > 0) {
                        sw.skid.Location__c = shl.Location__c;
                        sw.skid.Location__r = shl.Location__r;
                        sw.skid.Quantity_to_Issue__c = -sw.skid.Quantity_Used__c;
                        sw.skid.Quantity_To_Return__c = 0;
                        sw.skid.Input_Quantity__c = sw.skid.Quantity_to_Issue__c * sw.skid.Quantity_Issued__c;

                        if (String.isBlank(sw.skid.Temporary_Value_Holder1__c) == false || String.isBlank(sw.temporaryValueHolder) == false) {
                            Bin__c shippingBin = (Bin__c)JSON.deserialize(String.isBlank(sw.skid.Temporary_Value_Holder1__c) == false ? sw.skid.Temporary_Value_Holder1__c : sw.temporaryValueHolder, Bin__c.Class);
                            sw.toskid = new SKID__c(Bin__c = shippingBin.Id, Bin__r = shippingBin);
                            sw.skid.Bin__c = shippingBin.Id;
                            sw.skid.Bin__r = shippingBin;
                            sw.temporaryValueHolder = null;
                        } else {
                            sw.skid.Bin__c = null;
                            sw.skid.Bin__r = null;
                        }

                        shlWrapper.serialWrappers.add(sw);
                    }
                }

                if (shlWrapper.serialWrappers.size() > 0) shlWrappers.put(shl.Id, shlWrapper);
            }

            if (shlWrappers.size() > 0) ShipmentInventoryService.pick(shlWrappers.values());
        }

        if (recordsToUpdate.size() > 0) {
            recordsToUpdate.sort();
            DML.updateAsSystem(recordsToUpdate);
        }

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addField('Id');
        skidQuery.setWhereClause('Shipment_Line__c IN :shipmentLines');
        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        if (skids.size() > 0) DML.deleteAsSystem(skids);
    }
}