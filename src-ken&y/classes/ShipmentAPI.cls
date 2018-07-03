global with sharing class ShipmentAPI {
    private static Action.Response processLines(Object obj, String mode) {
        String modeMsg = mode == 'allocate' ? 'allocation' : (mode == 'planpick' ? 'plan pick' : 'picking');
        Savepoint sp = Database.setSavepoint();
        Action.Response resp = new Action.Response();
        resp.success = true;

        try {
            Map<Id, List<SkidWrapperV2>> lines = (Map<Id, List<SkidWrapperV2>>)JSON.deserialize(String.valueOf(obj), Map<Id, List<SkidWrapperV2>>.Class);
            if (lines.size() == 0) return resp;

            Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines('AND Id IN (\'' + String.join(new List<Id>(lines.keySet()), '\',\'') + '\')', mode));

            Id companyId;
            Map<Id, Item__c> items = new Map<Id, Item__c>();
            Set<Id> uomIds = new Set<Id>();
            for (Shipment_Line__c shl:shipmentLines.values()) {
                if (mode == 'allocate') {
                    companyId = shl.Company__c;
                    items.put(shl.Item__c, shl.Item__r);
                } else {
                    uomIds.addAll((List<Id>)JSON.deserialize(shl.Item__r.Packaging_UOM__c, List<Id>.Class));
                }
            }

            Map<Id, List<String>> allocAttrs;
            List<String> attributes;
            Map<Id, UOM__c> uoms;
            if (mode == 'allocate') {
                allocAttrs = AllocationService.getSkidAttributes(companyId, items, true);
            } else {
                attributes = SkidService3.attributesForPutaway(null, mode == 'planpick' ? new Set<String>{ 'license_plate_number__c' } : null, true);

                SOQLUtil uomQuery = new SOQLUtil('UOM__c');
                uomQuery.addFields(new Set<String>{ 'Id', 'Name', 'Package_Class__c',

                    'Package_Class__r.Default_Container_Item__c', 'Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
                    'Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c', 'Package_Class__r.Default_Container_Item__r.Item_Attribute__c',
                    'Package_Class__r.Fractional_Quantities_Allowed__c', 'Package_Class__r.Level__c' });
                uomQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Package_Class__r.Default_Container_Item__r.Item_Attribute__r');
                uomQuery.setWhereClause('Id IN :uomIds');
                uoms = new Map<Id, UOM__c>((List<UOM__c>)Database.query(uomQuery.getQuery()));
            }

            Map<Id, List<LineWrapper>> inventory = ShipmentWorkbenchExt.getInventory(shipmentLines.values(), mode);

            List<LineWrapper> shlWrappers = new List<LineWrapper>();
            for (Id shlId:lines.keySet()) {
                if (shipmentLines.containsKey(shlId) == false) throw new CustomException('Shipment line (' + shlId + ') is not available for ' + modeMsg + '.');

                Shipment_Line__c shl = shipmentLines.get(shlId);
                List<String> attrs = mode == 'allocate' ? allocAttrs.get(shl.Item__c) : attributes;
                List<SkidWrapperV2> swList = lines.get(shlId);
                LineWrapper shlWrapper = new LineWrapper(shl.Shipment__r, shl, null);

                if (inventory.containsKey(shl.Id) == false) throw new CustomException(shl.Name + ': No inventory available for ' + modeMsg + '.');

                Map<List<String>, SkidService3.SerialWrapper> skidMap = new Map<List<String>, SkidService3.SerialWrapper>();
                for (LineWrapper uomWrapper:inventory.get(shl.Id)) {
                    for (SkidService3.SerialWrapper sw:uomWrapper.serialWrappers) {
                        skidMap.put(SkidService3.generateKey(sw.skid, attrs), sw);
                    }
                }

                for (SkidWrapperV2 sw:swList) {
                    if (KSE.addQuantityToField(sw.skid.Input_Quantity__c, 0) == 0) continue;

                    if (mode == 'allocate') {
                        sw.skid.Container_Item__c = shl.Item__c;
                    } else {
                        if (sw.skid.Packaging_UOM__c == null) {
                            sw.skid.Packaging_UOM__c = shl.Item__r.Stocking_UOM__c;
                            sw.skid.Packaging_UOM__r = shl.Item__r.Stocking_UOM__r;
                        } else {
                            sw.skid.Packaging_UOM__r = uoms.get(sw.skid.Packaging_UOM__c);
                        }

                        sw.skid.Container_Item__r = SkidService3.getContainerForItem(shl.Item__r, sw.skid.Packaging_UOM__r);
                        sw.skid.Container_Item__c = sw.skid.Container_Item__r.Id;
                    }

                    List<String> skidKey = SkidService3.generateKey(sw.skid, attrs);
                    if (skidMap.containsKey(skidKey) == false) throw new CustomException(shl.Name + ': Specified inventory is not available for ' + modeMsg + '.');
                
                    SkidService3.SerialWrapper sw2 = skidMap.get(skidKey);
                    sw2.skid.Item__r = shl.Item__r;
                    if (mode == 'allocate') {
                        sw2.skid.Input_Quantity__c = sw.skid.Input_Quantity__c;
                    } else {
                        //DOES NOT SUPPORT BREAKING
                        sw2.skid.Quantity_to_Issue__c = sw.skid.Input_Quantity__c;
                        sw2.skid.Quantity_To_Return__c = 0;
                        sw2.skid.Quantity_to_Scrap__c = 0;
                        sw2.skid.Input_Quantity__c = sw2.skid.Quantity_to_Issue__c * sw2.skid.Quantity_Issued__c;
                    }

                    Map<String, Serial__c> serialMap = new Map<String, Serial__c>();
                    for (Serial__c serial:sw2.serialList) serialMap.put(serial.Name, serial);
                    sw2.serialList = new List<Serial__c>();

                    for (Serial__c serial:sw.serials) {
                        if (String.isBlank(serial.Name) == true || String.isBlank(serial.Temporary_Value_Holder__c) == true) continue;
                        if (serialMap.containsKey(serial.Name) == false) throw new CustomException(shl.Name + ': Serial ' + serial.Name + ' is not available for ' + modeMsg + '.');

                        if (mode != 'pick') {
                            Serial__c serial2 = serialMap.get(serial.Name);
                            serial2.Temporary_Value_Holder__c = serial.Temporary_Value_Holder__c;
                            sw2.serialList.add(serial2);
                        } else {
                            sw2.serialList.add(serial);
                        }
                    }

                    shlWrapper.serialWrappers.add(sw2);
                }

                if (shlWrapper.serialWrappers.size() > 0) shlWrappers.add(shlWrapper);
            }

            if (shlWrappers.size() > 0) {
                if (mode == 'allocate') AllocationService.allocate(shlWrappers);
                else if (mode == 'planpick') ShipmentInventoryService.plan(shlWrappers);
                else ShipmentInventoryService.pick(shlWrappers);
            }
        } catch (Exception e) {
            Database.rollback(sp);
            resp.success = false;
            resp.error.put('error', CustomException.getMessage(e));
            resp.error.put('message', CustomException.getMessage(e));
        }

        return resp;
    }

    public class Allocate implements Action.Target {
        public Action.Response execute(Object obj) { return processLines(obj, 'allocate'); }
    }

    public class PlanPick implements Action.Target {
        public Action.Response execute(Object obj) { return processLines(obj, 'planpick'); }
    }
    
    public class Pick implements Action.Target {
        public Action.Response execute(Object obj) { return processLines(obj, 'pick'); }
    }

    public class Ship implements Action.Target {
        public Action.Response execute(Object obj) {
            Savepoint sp = Database.setSavepoint();
            Action.Response resp = new Action.Response();
            resp.success = true;

            try {
                Set<Id> shipmentIds = (Set<Id>)JSON.deserialize(String.valueOf(obj), Set<Id>.Class);
                if (shipmentIds.size() == 0) return resp;

                Map<Id, Shipment__c> shipments = new Map<Id, Shipment__c>((List<Shipment__c>)Database.query(ShipmentManageDeliveryExtV2.getShipmentQuery('Id IN :shipmentIds')));

                Map<Id, String> errors = ShipmentInventoryService.validateForShip(shipments.values(), true);
                if (errors.size() > 0) throw new CustomException(errors.values()[0]);

                List<LineWrapper> shlWrappers = ShipmentInventoryservice.getLinesForShip(shipmentIds, true);
                if (shlWrappers.size() == 0) return resp;

                for (LineWrapper shlWrapper:shlWrappers) {
                    Shipment_Line__c shl = (Shipment_Line__c)shlWrapper.line;
                    Shipment__c shipment = shipments.get(shl.Shipment__c);
                    if (shipment.Date_Shipped__c == null) shipment.Date_Shipped__c = System.now();

                    shlWrapper.header = shipment.clone(true, true);
                    for (SkidService3.SerialWrapper sw:shlWrapper.serialWrappers) sw.skid.Item__r = shl.Item__r;
                }

                ShipmentInventoryService.confirmShip(shlWrappers);

                JsonResult result = ShipmentRereleaseService.rerelease(shipmentIds);
                if (result.success == false) throw new CustomException(result.messages[0].get('message'));
            } catch (Exception e) {
                Database.rollback(sp);
                resp.success = false;
                resp.error.put('error', CustomException.getMessage(e));
                resp.error.put('message', CustomException.getMessage(e));
            }

            return resp;
        }
    }
}