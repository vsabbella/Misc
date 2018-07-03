public with sharing class ShipmentInventoryService {
    private static SchemaUtil util = SchemaUtil.getInstance();
    private static final List<String> inputFields = new List<String>{ 'Quantity_to_Issue__c', 'Quantity_To_Return__c', 'Quantity_to_Scrap__c' };
    private static final Map<String, Schema.sObjectField> skidFieldMap = util.getFieldsMap('SKID__c');

    public static void validateForPlanAndPick(List<Shipment_Line__c> shipmentLines) {
        if (shipmentLines == null || shipmentLines.size() == 0) return;

        for (Shipment_Line__c shl:shipmentLines) {
            if (shl.Sales_Order_Line__c != null) {
                Sales_Order__c so = shl.Sales_Order__r;

                if (so.Hold__c) {
                    throw new CustomException(shl.Name + ': ' + Label.SH_SO_On_Hold_At_Ship);
                }
            }
        }
    }

    public static List<LineWrapper> getInventoryForPlan(List<Shipment_Line__c> shipmentLines) {
        List<LineWrapper> wrappers = new List<LineWrapper>();
        if (shipmentLines == null || shipmentLines.size() == 0) return wrappers;

        Id companyId;
        Id facilityId;
        Map<Id, Item__c> items = new Map<Id, Item__c>();
        Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
        Set<Id> uomIds = new Set<Id>();
        Set<String> lineTypes = new Set<String>();
        Map<Id, sObject> linesForLocation = new Map<Id, sObject>();
        for (Shipment_Line__c shl:shipmentLines) {
            companyId = shl.Company__c;
            facilityId = shl.Facility__c;

            if (items.containsKey(shl.Item__c) == false) {
                items.put(shl.Item__c, shl.Item__r);
                List<Id> uomList = getUomIds(shl);
                packagingUoms.put(shl.Item__c, uomList);
                uomIds.addAll(uomList);
            }

            if (shl.Sales_Order_Line__c != null) {
                lineTypes.add('sales_order_line__c');
                linesForLocation.put(shl.Id, shl.Sales_Order_Line__r);
            } else {
                lineTypes.add('order_line__c');
                linesForLocation.put(shl.Id, shl.Order_Line__r);
            }
        }

        SkidService3.setAllocAttributes(companyId, items);
        Map<Id, List<UOM__c>> uoms = getUomList(uomIds, packagingUoms);

        Set<Id> locationIds = new Set<Id>();
        Map<String, List<Location__c>> locMap = SkidService3.locationsFromStockMovementRules(linesForLocation.values(), 'Pick', lineTypes, null, locationIds);

        Set<Id> itemIds = items.keySet();
        Set<Id> shlIds = linesForLocation.keySet();

        String whereClause = 'Item__c IN :itemIds ' +
                             'AND Facility2__c = :facilityId ' +
                             'AND Receipt_Line__c = null ' +
                             'AND ((((Type__c = \'' + SkidService3.SKID_TYPE_ALLOCATED + '\' AND Shipment_Line__c IN :shlIds) ' +
                             'OR (Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\' AND Shipment_Line__c NOT IN :shlIds AND Location__c IN :locationIds) ' +
                             'OR (Type__c = \'' + SkidService3.SKID_TYPE_LOCATION + '\' AND Shipment_Line__c = null AND Location__c IN :locationIds)) ' +
                             'AND (Lot__c = null OR Lot__r.Lot_Hold__c != true)) ' +
                             'OR (Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\' AND Shipment_Line__c IN :shlIds))';

        List<String> sortCriteria = SkidService3.populateSortCriteria(null, companyId);
        sortCriteria.add('Packaging_UOM__r.Package_Class__r.Level__c ASC');

        Map<Id, Map<List<String>, SKID__c>> allocSkidMap = new Map<Id, Map<List<String>, SKID__c>>();
        Map<Id, Map<List<String>, SKID__c>> planSkidMap = new Map<Id, Map<List<String>, SKID__c>>();
        Map<List<String>, Decimal> plannedQtys = new Map<List<String>, Decimal>();
        Map<Id, SKID__c> skidMap = new Map<Id, SKID__c>();
        Map<List<String>, List<SKID__c>> sortedSkids = new Map<List<String>, List<SKID__c>>();
        Map<List<String>, SKID__c> aggregatedSkids = new Map<List<String>, SKID__c>();
        for (SKID__c skid:Database.query(SkidService3.getSkidQuery(new Map<String, String>{ 'WHERE' => whereClause, 'ORDER' => String.join(sortCriteria, ',') }))) {
            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED || skid.Type__c == SkidService3.SKID_TYPE_PLANNED) {
                Id shlId = skid.Shipment_Line__c;
                skid.Shipment_Line__c = null;

                List<String> key;
                Map<Id, Map<List<String>, SKID__c>> skMap;
                if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                    key = SkidService3.generateKey(skid, SkidService3.allocAttributes.get(skid.Item__c));
                    skMap = allocSkidMap;
                } else {
                    key = SkidService3.generateKey(skid, SkidService3.planAttributes);
                    if (shlIds.contains(shlId) == true) {
                        skid.Quantity_Allocated__c = skid.Quantity__c;
                        skMap = planSkidMap;
                    } else {
                        plannedQtys.put(key, KSE.addQuantityToField(plannedQtys.get(key), skid.Quantity_Stocking_UOM__c));
                    }
                }

                if (skMap != null) {
                    if (skMap.containsKey(shlId) == false) skMap.put(shlId, new Map<List<String>, SKID__c>{ key => skid });
                    else skMap.get(shlId).put(key, skid);
                }
            } else {
                skidMap.put(skid.Id, skid.clone(true, true));

                List<String> itemLocKey = new List<String>{ skid.Item__c, skid.Location__c };
                List<String> planKey = SkidService3.generateKey(skid, SkidService3.planAttributes);
                if (sortedSkids.containsKey(itemLocKey) == false) {
                    sortedSkids.put(itemLocKey, new List<SKID__c>{ skid });
                    aggregatedSkids.put(planKey, skid);
                } else if (aggregatedSkids.containsKey(planKey) == false) {
                    sortedSkids.get(itemLocKey).add(skid);
                    aggregatedSkids.put(planKey, skid);
                } else {
                    SKID__c sk = aggregatedSkids.get(planKey);
                    sk.Quantity__c += skid.Quantity__c;
                    sk.Quantity_Stocking_UOM__c += skid.Quantity_Stocking_UOM__c;
                }
            }
        }

        Set<Id> skidIds = skidMap.keySet();
        whereClause = '(Allocated_SKID__c != null AND Allocated_SKID__r.Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\' AND Allocated_SKID__r.Shipment_Line__c IN :shlIds) OR (SKID__c IN :skidIds AND (Allocated_SKID__c = null OR Allocated_SKID__r.Shipment_Line__c IN :shlIds))';

        Map<Id, List<Serial__c>> planSerials = new Map<Id, List<Serial__c>>();
        Map<Id, Map<List<String>, List<Serial__c>>> allocSerialMap = new Map<Id, Map<List<String>, List<Serial__c>>>();
        Map<List<String>, List<Serial__c>> availableSerials = new Map<List<String>, List<Serial__c>>();
        for (Serial__c serial:Database.query(SkidService3.getSerialQuery(new Map<String, String>{ 'WHERE' => whereClause, 'ORDER' => 'Name ASC' }))) {
            if (serial.Allocated_SKID__c != null && serial.Allocated_SKID__r.Type__c == SkidService3.SKID_TYPE_PLANNED) {
                serial.Temporary_Value_Holder__c = 'Planned';
                if (planSerials.containsKey(serial.Allocated_SKID__c) == false) planSerials.put(serial.Allocated_SKID__c, new List<Serial__c>{ serial });
                else planSerials.get(serial.Allocated_SKID__c).add(serial);
            } else {
                List<String> key = SkidService3.generateKey(skidMap.get(serial.SKID__c), SkidService3.planAttributes);
                if (serial.Allocated_SKID__c != null) {
                    Id shlId = serial.Allocated_SKID__r.Shipment_Line__c;
                    if (allocSerialMap.containsKey(shlId) == false) allocSerialMap.put(shlId, new Map<List<String>, List<Serial__c>>{ key => new List<Serial__c>{ serial }});
                    else if (allocSerialMap.get(shlId).containsKey(key) == false) allocSerialMap.get(shlId).put(key, new List<Serial__c>{ serial });
                    else allocSerialMap.get(shlId).get(key).add(serial);
                } else {
                    if (availableSerials.containsKey(key) == false) availableSerials.put(key, new List<Serial__c>{ serial });
                    else availableSerials.get(key).add(serial);
                }
            }
        }

        Map<List<String>, SKID__c> skids = new Map<List<String>, SKID__c>();
        Map<Id, Map<Id, List<SkidService3.SerialWrapper>>> swByUom = new Map<Id, Map<Id, List<SkidService3.SerialWrapper>>>();
        for (Shipment_Line__c shl:shipmentLines) {
            sObject lineForLocation = linesForLocation.get(shl.Id);
            if (locMap.containsKey(lineForLocation.Id) == false) throw new CustomException(shl.Name + ': ' + Label.Matching_stock_movement_rule_not_found);

            Map<List<String>, SKID__c> allocSkids = allocSkidMap.containsKey(shl.Id) == true ? allocSkidMap.get(shl.Id) : new Map<List<String>, SKID__c>();
            Map<List<String>, SKID__c> planSkids = planSkidMap.containsKey(shl.Id) == true ? planSkidMap.get(shl.Id) : new Map<List<String>, SKID__c>();
            if (allocSkids.size() == 0 && planSkids.size() == 0) continue;

            Map<List<String>, List<Serial__c>> allocSerials = allocSerialMap.containsKey(shl.Id) == true ? allocSerialMap.get(shl.Id) : new Map<List<String>, List<Serial__c>>();

            List<String> allocAttributes = SkidService3.allocAttributes.get(shl.Item__c);
            List<UOM__c> uomList = uoms.get(shl.Item__c);
            List<Id> pkgUoms = packagingUoms.get(shl.Item__c);

            Map<Id, List<SkidService3.SerialWrapper>> swList = new Map<Id, List<SkidService3.SerialWrapper>>();
            Map<List<String>, SkidService3.SerialWrapper> swMap = new  Map<List<String>, SkidService3.SerialWrapper>();
            for (Location__c loc:locMap.get(lineForLocation.Id)) {
                List<String> itemLocKey = new List<String>{ shl.Item__c, loc.Id };
                if (sortedSkids.containsKey(itemLocKey) == false) continue;

                /*
                 * Quantity Used = Quantity planned (Packaging UOM)
                 * Count Quantity = Quantity available in stock (Stocking UOM)
                 * Total Material = Quantity available for break (Packaging UOM)
                 * Quantity Allocated = Quantity allocated (Stocking UOM)
                 * Quantity Available = Quantity available to plan (Stocking UOM)
                 * Quantity to Issue = Input quantity for packaging UOM
                 * Quantity To Return = Input quantity for packaging UOM level - 1 (if applicable)
                 * Input Quantity = Quantity to plan (Stocking UOM)
                 * Quantity Issued = Conversion factor for packaging UOM (to stocking)
                 * Quantity Required = Conversion factor for packaging UOM level - 1 (to stocking)
                 */
                for (SKID__c skid:sortedSkids.get(itemLocKey)) {
                    if (skid.Quantity__c <= 0 || (shl.Sales_Order_Line__r.Type__c =='Repair' && shl.Sales_Order_Line__c != skid.Sales_Order_Line__c)) continue;//match skid soline with shipment line

                    List<String> skidKey = SkidService3.generateKey(skid, SkidService3.planAttributes);
                    SKID__c allocSkid = allocSkids.get(SkidService3.generateKey(skid, allocAttributes));

                    SKID__c skidToBreak;
                    Decimal skidToBreakConvFactor;
                    for (Integer i = 0; i < uomList.size(); i++) {
                        UOM__c uom = uomList[i];

                        if (uom.Package_Class__c != null) {
                            if (uom.Package_Class__r.Level__c > skid.Packaging_UOM__r.Package_Class__r.Level__c) continue;
                            if (uom.Package_Class__r.Level__c < skid.Packaging_UOM__r.Package_Class__r.Level__c - 1) break;
                        }

                        SKID__c skidClone = skid.clone(false, true);
                        skidClone.Packaging_UOM__c = uom.Id;
                        skidClone.Packaging_UOM__r = uom;

                        List<String> planKey = SkidService3.generateKey(skidClone, SkidService3.planAttributes);
                        SKID__c planSkid = planSkids.get(planKey);
                        SKID__c sk = skids.containsKey(planKey) == true ? skids.get(planKey) : null;
                        Decimal convFactor = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, skidClone.Packaging_UOM__c, shl.Item__r.Stocking_UOM__c, pkgUoms);

                        if (uom.Id == skid.Packaging_UOM__c) {
                            skidClone.Quantity_Used__c = planSkid != null ? Math.min(planSkid.Quantity_Allocated__c, sk != null ? (sk.Count_Quantity__c / convFactor) : skid.Quantity__c) : 0;
                            skidClone.Count_Quantity__c = (sk != null ? sk.Count_Quantity__c : skid.Quantity_Stocking_UOM__c) - (skidClone.Quantity_Used__c * convFactor);
                            skidClone.Total_Material__c = (sk != null ? sk.Total_Material__c : skid.Quantity__c) - skidClone.Quantity_Used__c;

                            if (skidClone.Total_Material__c >= 1) {
                                skidToBreak = skidClone;
                                skidToBreakConvFactor = convFactor;
                            }
                        } else {
                            if (planSkid == null && sk == null) continue;

                            skidClone.Quantity_Used__c = planSkid != null && sk != null ? Math.min(planSkid.Quantity_Allocated__c, sk.Count_Quantity__c / convFactor) : 0;
                            skidClone.Count_Quantity__c = sk != null ? (sk.Count_Quantity__c - (skidClone.Quantity_Used__c * convFactor)) : 0;
                            skidClone.Total_Material__c = sk != null ? (sk.Total_Material__c - skidClone.Quantity_Used__c) : 0;
                            
                            if (planSkid != null && skidToBreak != null) {
                                Decimal qtyLeft = planSkid.Quantity_Allocated__c - skidClone.Quantity_Used__c;
                                if (qtyLeft > 0) {
                                    Decimal qtyAvailable = skidToBreak.Total_Material__c.intValue();
                                    Decimal breakConvFactor = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, skidToBreak.Packaging_UOM__c, skidClone.Packaging_UOM__c, pkgUoms);
                                    Decimal qtyToBreak = (qtyLeft / breakConvFactor).round(System.RoundingMode.CEILING);

                                    if (qtyAvailable < qtyToBreak) {
                                        skidClone.Quantity_Used__c += (qtyAvailable * breakConvFactor);

                                        skidToBreak.Count_Quantity__c -= (qtyAvailable * skidToBreakConvFactor);
                                        skidToBreak.Total_Material__c -= qtyAvailable;
                                    } else {
                                        Decimal qtyBroken = qtyToBreak * skidToBreakConvFactor;

                                        skidClone.Quantity_Used__c += qtyLeft;
                                        skidClone.Count_Quantity__c += (qtyBroken - (qtyLeft * convFactor));

                                        skidToBreak.Count_Quantity__c -= qtyBroken;
                                        skidToBreak.Total_Material__c -= (qtyBroken / skidToBreakConvFactor);
                                    }
                                }
                            }
                        }

                        if (planSkid != null) {
                            planSkid.Quantity_Allocated__c -= skidClone.Quantity_Used__c;
                            if (planSkid.Quantity_Allocated__c == 0) planSkids.remove(planKey);
                        }

                        skidClone.Quantity_Allocated__c = allocSkid != null ? allocSkid.Quantity_Stocking_UOM__c : 0;

                        if (swMap.containsKey(planKey) == false) {
                            skidClone.Quantity_to_Issue__c = 0;
                            skidClone.Quantity_To_Return__c = 0;
                            skidClone.Input_Quantity__c = 0;
                            skidClone.Quantity_Issued__c = convFactor;
                            skidClone.Quantity_Required__c = uomList.size() > i + 1 ? KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, uomList[i + 1].Id, shl.Item__r.Stocking_UOM__c, pkgUoms) : 1;
                        
                            List<Serial__c> serials = planSkid != null && planSerials.containsKey(planSkid.Id) == true ? planSerials.get(planSkid.Id) : new List<Serial__c>();
                            if (allocSerials.containsKey(skidKey) == true) serials.addAll(allocSerials.get(skidKey));
                            if (availableSerials.containsKey(skidKey) == true) serials.addAll(availableSerials.get(skidKey));

                            SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(skidClone, serials);
                            if (swList.containsKey(uom.Id) == false) swList.put(uom.Id, new List<SkidService3.SerialWrapper>{ sw });
                            else swList.get(uom.Id).add(sw);

                            swMap.put(planKey, sw);
                        } else {
                            SkidService3.SerialWrapper sw = swMap.get(planKey);
                            sw.skid.Quantity_Used__c += skidClone.Quantity_Used__c;

                            if (allocSerials.containsKey(skidKey) == true) {
                                List<Serial__c> serials = new List<Serial__c>();
                                List<Serial__c> serials2 = new List<Serial__c>();
                                for (Serial__c serial:sw.serialList) {
                                    if (serial.Allocated_SKID__c != null) serials.add(serial);
                                    else serials2.add(serial);
                                }

                                serials.addAll(allocSerials.get(skidKey));
                                serials.addAll(serials2);
                                if (availableSerials.containsKey(skidKey) == true) serials.addAll(availableSerials.get(skidKey));

                                sw.serialList = serials;
                            } else if (availableSerials.containsKey(skidKey) == true) {
                                sw.serialList.addAll(availableSerials.get(skidKey));
                            }
                        }
                        
                        skids.put(planKey, skidClone);
                    }
                }
            }

            for (List<String> key:planSkids.keySet()) {
                SKID__c skid = planSkids.get(key);
                if (swMap.containsKey(key) == true) {
                    swMap.get(key).skid.Quantity_Used__c += skid.Quantity_Allocated__c;
                } else {
                    skid.Quantity_Used__c = skid.Quantity_Allocated__c;
                    skid.Count_Quantity__c = 0;
                    skid.Total_Material__c = 0;
                    skid.Quantity_Allocated__c = 0;
                    skid.Quantity_Available__c = 0;
                    skid.Quantity_to_Issue__c = 0;
                    skid.Quantity_To_Return__c = 0;
                    skid.Input_Quantity__c = 0;
                    skid.Quantity_Issued__c = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, skid.Packaging_UOM__c, shl.Item__r.Stocking_UOM__c, pkgUoms);
                    for (Integer i = 0; i < uomList.size(); i++) {
                        UOM__c uom = uomList[i];
                        if (uom.Id == skid.Packaging_UOM__c) {
                            skid.Quantity_Required__c = uomList.size() > i + 1 ? KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, uomList[i + 1].Id, shl.Item__r.Stocking_UOM__c, pkgUoms) : 1;
                            break;
                        }
                    }

                    SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(skid, planSerials.containsKey(skid.Id) == true ? planSerials.get(skid.Id) : new List<Serial__c>());
                    if (swList.containsKey(skid.Packaging_UOM__c) == false) swList.put(skid.Packaging_UOM__c, new List<SkidService3.SerialWrapper>{ sw });
                    else swList.get(skid.Packaging_UOM__c).add(sw);
                }
            }

            if (swList.size() > 0) swByUom.put(shl.Id, swList);
        }

        Map<List<String>, Decimal> qtyAvailableMap = new Map<List<String>, Decimal>();
        for (Shipment_Line__c shl:shipmentLines) {
            if (swByUom.containsKey(shl.Id) == false) continue;

            List<String> allocAttributes = SkidService3.allocAttributes.get(shl.Item__c);
            List<UOM__c> uomList = uoms.get(shl.Item__c);
            List<Id> pkgUoms = packagingUoms.get(shl.Item__c);

            List<String> skidFields = new List<String>{ 'Location__c', 'Bin__c', 'Customer__c', 'Consigned_Owner__c' };
            for (String attr:SkidService3.attributeFields) {
                if (attr != 'License_Plate_Number__c' && shl.Item__r.Item_Attribute__c != null && (Boolean)shl.Item__r.Item_Attribute__r.get(attr) == true) {
                    if (attr == 'Lot_Number__c') skidFields.add('Lot__c');
                    else skidFields.add(attr);
                }
            }
            skidFields.addAll(util.getFieldsFromFieldSetString(SKID__c.sObjectType, 'ShipmentPlanPick'));
            skidFields.addAll(new List<String>{ 'Quantity_Used__c', 'Quantity_Available__c', 'Quantity_to_Issue__c' });

            Map<List<String>, Decimal> plannedQuantities = plannedQtys.clone();
            for (Integer i = uomList.size() - 1; i >= 0; i--) {
                UOM__c uom = uomList[i];
                if (swByUom.get(shl.Id).containsKey(uom.Id) == false) continue;
                for (SkidService3.SerialWrapper sw:swByUom.get(shl.Id).get(uom.Id)) {
                    for (Integer j = 0; j < uomList.size(); j++) {
                        UOM__c uom2 = uomList[j];
                        if (uom2.Package_Class__c != null) {
                            if (uom2.Package_Class__r.Level__c > uom.Package_Class__r.Level__c) continue;
                            if (uom2.Package_Class__r.Level__c < uom.Package_Class__r.Level__c - 1) break;
                        }

                        SKID__c skidClone = sw.skid.clone(false, true);
                        skidClone.Packaging_UOM__c = uom2.Id;
                        List<String> planKey = SkidService3.generateKey(skidClone, SkidService3.planAttributes);
                        if (uom2.Id == uom.Id && skids.containsKey(planKey) == true) {
                            SKID__c skid = skids.get(planKey);
                            sw.skid.Count_Quantity__c = skid.Count_Quantity__c;
                            sw.skid.Total_Material__c = skid.Total_Material__c;
                        }
                        if (plannedQuantities.containsKey(planKey) == true) {
                            Decimal qtyPlanned = Math.min(sw.skid.Count_Quantity__c, plannedQuantities.get(planKey));
                            sw.skid.Count_Quantity__c -= qtyPlanned;
                            sw.skid.Total_Material__c -= Math.min(sw.skid.Total_Material__c, plannedQuantities.get(planKey) / sw.skid.Quantity_Issued__c).intValue();
                            plannedQuantities.put(planKey, plannedQuantities.get(planKey) - qtyPlanned);
                            if (plannedQuantities.get(planKey) == 0) plannedQuantities.remove(planKey);
                        }
                        sw.skid.Quantity_Available__c = Math.min(sw.skid.Count_Quantity__c, sw.skid.Quantity_Allocated__c);
                    }
                }
            }

            Decimal qtyToPlan = shl.Quantity_Allocated__c;
            Map<List<String>, Decimal> allocQtyAvailableMap = new Map<List<String>, Decimal>();
            for (Integer i = 0; i < uomList.size(); i++) {
                UOM__c uom = uomList[i];
                if (swByUom.get(shl.Id).containsKey(uom.Id) == false) continue;

                LineWrapper wrapper = generateWrapper(shl, uom);
                for (SkidService3.SerialWrapper sw:swByUom.get(shl.Id).get(uom.Id)) {
                    List<String> planKey = SkidService3.generateKey(sw.skid, SkidService3.planAttributes);

                    if (sw.skid.Quantity_Used__c > 0 || sw.skid.Quantity_Available__c > 0) {
                        if (qtyToPlan > 0 && sw.skid.Quantity_Available__c > 0 && (sw.skid.Bin__c == null || sw.skid.Bin__r.Blocked__c != true)) {
                            List<String> allocKey = SkidService3.generateKey(sw.skid, allocAttributes);
                            Decimal qty = qtyAvailableMap.containsKey(planKey) == true ? qtyAvailableMap.get(planKey) : sw.skid.Count_Quantity__c;
                            Decimal allocQty = allocQtyAvailableMap.containsKey(allocKey) == true ? allocQtyAvailableMap.get(allocKey) : sw.skid.Quantity_Allocated__c;
                            Decimal qtyAvailable = Math.min(qty, allocQty);

                            if (qtyAvailable > 0) {
                                sw.skid.Quantity_to_Issue__c = Math.min(qtyAvailable, qtyToPlan) / sw.skid.Quantity_Issued__c;
                                if (sw.skid.Packaging_UOM__r.Package_Class__c != null && sw.skid.Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c != true) sw.skid.Quantity_to_Issue__c = sw.skid.Quantity_to_Issue__c.intValue();
                                sw.skid.Input_Quantity__c = sw.skid.Quantity_to_Issue__c * sw.skid.Quantity_Issued__c;
                                qtyToPlan -= sw.skid.Input_Quantity__c;

                                qtyAvailableMap.put(planKey, qty - sw.skid.Input_Quantity__c);
                                allocQtyAvailableMap.put(allocKey, allocQty - sw.skid.Input_Quantity__c);
                            }
                        }

                        wrapper.serialWrappers.add(sw);
                    }
                }

                if (wrapper.serialWrappers.size() > 0) {
                    UOM__c lowerUom = uomList.size() > i + 1 ? uomList[i + 1] : null;

                    List<String> skFields = skidFields.clone();
                    if (lowerUom != null) skFields.add('Quantity_To_Return__c');
                    skFields.add('Input_Quantity__c');

                    wrapper.skidFields = FieldInfo.fetchJsonFieldInfos('SKID__c', skFields, true);
                    for (FieldInfo fi:wrapper.skidFields) {
                        if (fi.field == 'Quantity__c') {
                            fi.title = 'Quantity in Stock (' + uom.Name + ')';
                        } else if (fi.field == 'Quantity_Used__c') {
                            fi.title = 'Quantity Plan Picked (' + uom.Name + ')';
                        } else if (fi.field == 'Quantity_Available__c') {
                            fi.title = fi.title + ' (' + shl.Item__r.Stocking_UOM__r.Name + ')';
                        } else if (fi.field == 'Quantity_to_Issue__c' || fi.field == 'Quantity_To_Return__c') {
                            fi.editable = true;
                            if (fi.field == 'Quantity_to_Issue__c') fi.title = uom.Name + (uom.Id != shl.Item__r.Stocking_UOM__c ? ' (' + KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, uom.Id, shl.Item__r.Stocking_UOM__c, pkgUoms) + ' ' + shl.Item__r.Stocking_UOM__r.Name + ')' : '');
                            else fi.title = lowerUom.Name + (lowerUom.Id != shl.Item__r.Stocking_UOM__c ? ' (' + KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, lowerUom.Id, shl.Item__r.Stocking_UOM__c, pkgUoms) + ' ' + shl.Item__r.Stocking_UOM__r.Name + ')' : '');
                        } else if (fi.field == 'Input_Quantity__c') {
                            fi.title = 'Quantity To Plan (' + shl.Item__r.Stocking_UOM__r.Name + ')';
                        }
                        fi.field = 'skid.' + fi.field;
                    }

                    wrappers.add(wrapper);
                }
            }
        }

        return wrappers;
    }

    public static void checkPlanErrors(List<LineWrapper> shlWrappers) {
        if (shlWrappers == null || shlWrappers.size() == 0) return;

        Id companyId;
        Map<Id, Item__c> items = new Map<Id, Item__c>();
        Set<Id> uomIds = new Set<Id>();
        Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
        for (LineWrapper shlWrapper:shlWrappers) {
            Shipment_Line__c shl = (Shipment_Line__c)shlWrapper.line;
            companyId = shl.Company__c;
            if (items.containsKey(shl.Item__c) == false) {
                items.put(shl.Item__c, shl.Item__r);
                List<Id> pkgUoms = getUomIds(shl);
                uomIds.addAll(pkgUoms);
                packagingUoms.put(shl.Item__c, pkgUoms);
            }
        }

        SkidService3.setAllocAttributes(companyId, items);
        Map<Id, List<UOM__c>> uoms = getUomList(uomIds, packagingUoms);

        Map<List<String>, SKID__c> skids = new Map<List<String>, SKID__c>();
        Set<String> serialKeys = new Set<String>();
        for (LineWrapper shlWrapper:shlWrappers) {
            Shipment_Line__c shl = (Shipment_Line__c)shlWrapper.line;
            List<Id> pkgUoms = packagingUoms.get(shl.Item__c);
            List<UOM__c> uomList = uoms.get(shl.Item__c);

            Map<List<String>, Decimal> allocQtyAvailableMap = new Map<List<String>, Decimal>();
            Map<List<String>, Decimal> serialsLeft = new Map<List<String>, Decimal>();
            Map<List<String>, Set<String>> allocSerials = new Map<List<String>, Set<String>>();
            for (SkidService3.SerialWrapper sw:shlWrapper.serialWrappers) {
                sw.skid.Input_Quantity__c = (KSE.addQuantityToField(sw.skid.Quantity_to_Issue__c, 0) * sw.skid.Quantity_Issued__c) + (KSE.addQuantityToField(sw.skid.Quantity_To_Return__c, 0) * sw.skid.Quantity_Required__c);

                if (sw.skid.Quantity_To_Return__c < 0) throw new CustomException(shl.Name + ': You can\'t unplan partial packages.');

                List<String> allocKey = SkidService3.generateKey(sw.skid, SkidService3.allocAttributes.get(shl.Item__c));
                if (allocQtyAvailableMap.containsKey(allocKey) == false) allocQtyAvailableMap.put(allocKey, sw.skid.Quantity_Allocated__c);
                List<String> planKey = SkidService3.generateKey(sw.skid, SkidService3.planAttributes);
                SKID__c skid = skids.containsKey(planKey) == true ? skids.get(planKey) : new SKID__c(Count_Quantity__c = sw.skid.Count_Quantity__c, Total_Material__c = sw.skid.Total_Material__c);

                if (sw.skid.Quantity_To_Issue__c < 0) {
                    Decimal qtyToUnplan = -sw.skid.Quantity_To_Issue__c;
                    if (qtyToUnplan > sw.skid.Quantity_Used__c) throw new CustomException(shl.Name + ': You can\'t unplan more quantity (' + qtyToUnplan + ') than planned (' + sw.skid.Quantity_Used__c + ').');

                    qtyToUnplan *= sw.skid.Quantity_Issued__c;
                    allocQtyAvailableMap.put(allocKey, allocQtyAvailableMap.get(allocKey) + qtyToUnplan);
                    skid.Count_Quantity__c += qtyToUnplan;
                    skid.Total_Material__c -= sw.skid.Quantity_To_Issue__c;
                }

                if (sw.skid.Quantity_To_Issue__c > 0 || sw.skid.Quantity_To_Return__c > 0) {
                    Decimal inputQty = KSE.addQuantityToField(sw.skid.Quantity_To_Return__c, 0) * sw.skid.Quantity_Required__c;

                    if (sw.skid.Quantity_To_Issue__c > 0) {
                        inputQty += (sw.skid.Quantity_To_Issue__c * sw.skid.Quantity_Issued__c);
                        skid.Total_Material__c -= sw.skid.Quantity_To_Issue__c;

                        if (shl.Order_Line__c != null && pkgUoms.size() > 1 && pkgUoms[pkgUoms.size() - 1] == sw.skid.Packaging_UOM__c) {
                            Decimal shipConvFactor = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, pkgUoms[pkgUoms.size() - 2], pkgUoms);
                            Decimal receiveConvFactor = KSE.getConversionFactor(shl.Item__c, shl.Order_Line__r.Deliver_To_Facility__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, pkgUoms[pkgUoms.size() - 2], pkgUoms);
                            if (shipConvFactor > receiveConvFactor) throw new CustomException(shl.Name + ': You can\'t ship an item from a facility with a higher UOM conversion to a facility with a lower UOM conversion.');
                        }
                    }

                    Decimal qtyAvailable = Math.min(skid.Count_Quantity__c, allocQtyAvailableMap.get(allocKey));
                    if (inputQty > qtyAvailable) throw new CustomException(shl.Name + ': You can\'t plan more quantity (' + inputQty + ') than available (' + qtyAvailable + ').');

                    allocQtyAvailableMap.put(allocKey, allocQtyAvailableMap.get(allocKey) - inputQty);
                    skid.Count_Quantity__c -= inputQty;

                    if (sw.skid.Quantity_To_Return__c > 0) {
                        UOM__c lowerUom;
                        for (Integer i = 0; i < uomList.size(); i++) {
                            if (sw.skid.Packaging_UOM__c == uomList[i].Id) {
                                lowerUom = uomList[i + 1];
                                break;
                            }
                        }

                        SKID__c lowerSkid = sw.skid.clone(false, true);
                        lowerSkid.Packaging_UOM__c = lowerUom.Id;
                        lowerSkid.Packaging_UOM__r = lowerUom;
                        List<String> lowerSkidKey = SkidService3.generateKey(lowerSkid, SkidService3.planAttributes);

                        Decimal qtyLeft = sw.skid.Quantity_To_Return__c;
                        if (skids.containsKey(lowerSkidKey) == true) {
                            lowerSkid = skids.get(lowerSkidKey);

                            Decimal qtyToPlan = Math.min(qtyLeft, (lowerSkid.Count_Quantity__c / sw.skid.Quantity_Required__c));
                            qtyLeft -= qtyToPlan;
                            lowerSkid.Count_Quantity__c -= (qtyToPlan * sw.skid.Quantity_Required__c);
                        } else {
                            lowerSkid = new SKID__c(Count_Quantity__c = 0, Total_Material__c = 0);
                        }

                        if (qtyLeft > 0) {
                            Decimal convFactor = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, lowerUom.Id, pkgUoms);
                            Decimal qtyToBreak = (qtyLeft / convFactor).round(System.RoundingMode.CEILING);
                            Decimal pkgsAvailable = skid.Total_Material__c.intValue();
                            if (qtyToBreak > pkgsAvailable) throw new CustomException(shl.Name + ': You can\'t break more packages (' + qtyToBreak + ') than available (' + pkgsAvailable + ').');

                            skid.Total_Material__c -= qtyToBreak;

                            lowerSkid.Count_Quantity__c += ((qtyToBreak * sw.skid.Quantity_Issued__c) - (qtyLeft * sw.skid.Quantity_Required__c));
                            skids.put(lowerSkidKey, lowerSkid);
                        }
                    }
                }

                skids.put(planKey, skid);

                if (shl.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT && shl.Item__r.Item_Attribute__c != null && shl.Item__r.Item_Attribute__r.Serial_Number__c == true) {
                    if (sw.skid.Quantity_To_Return__c > 0) throw new CustomException(shl.Name + ': You can\'t break packages for serial tracked items.');

                    Integer serialsToPlan = 0;
                    Integer serialsToUnplan = 0;
                    Integer serialsPlanned = 0;
                    for (Serial__c serial:sw.serialList) {
                        if (serial.Temporary_Value_Holder__c == 'Plan' || serial.Temporary_Value_Holder__c == 'Planned') {
                            String uniqueKey = shl.Company__c + '-' + shl.Item__c + '-' + serial.Name;
                            if (serialKeys.contains(uniqueKey) == false) serialKeys.add(uniqueKey);
                            else throw new CustomException(shl.Item__r.Name + ': Serial ' + serial.Name + ' has been specified more than once.');

                            if (serial.Temporary_Value_Holder__c == 'Plan') serialsPlanned++;
                            else serialsPlanned++;
                        } else if (serial.Temporary_Value_Holder__c == 'Unplan') {
                            serialsPlanned--;
                        } else if (serial.Temporary_Value_Holder__c == 'Allocated') {
                            serialsLeft.put(allocKey, KSE.addQuantityToField(serialsLeft.get(allocKey), 1));
                        }

                        if (serial.Allocated_SKID__c != null && serial.Temporary_Value_Holder__c != 'Planned' && serial.Temporary_Value_Holder__c != 'Unplan') {
                            if (allocSerials.containsKey(allocKey) == false) allocSerials.put(allocKey, new Set<String>{ serial.Name });
                            else allocSerials.get(allocKey).add(serial.Name);
                        }
                    }

                    Decimal totalSerials = serialsToPlan - serialsToUnplan + serialsPlanned;
                    Decimal totalPlanned = (sw.skid.Quantity_Used__c * sw.skid.Quantity_Issued__c) + sw.skid.Input_Quantity__c;
                    if (totalSerials > totalPlanned) {
                        throw new CustomException(shl.Name + ': ' + Label.Number_of_serials + ' (' + totalSerials + ') cannot be greater than quantity planned (' + totalPlanned + ')');
                    }
                }
            }

            if (serialsLeft.size() > 0) {
                for (List<String> allocKey:serialsLeft.keySet()) {
                    Decimal qtyLeft = allocQtyAvailableMap.get(allocKey);
                    Decimal serLeft = serialsLeft.get(allocKey);
                    Set<String> allocatedSerials = allocSerials.get(allocKey);

                    if (serLeft > qtyLeft) {
                        Decimal serialsRequired = serLeft - qtyLeft;
                        
                        String errMsg = shl.Name + ': You must plan ';
                        if (serialsRequired != serLeft) errMsg += 'at least ' + serialsRequired;
                        else errMsg += 'all';
                        errMsg += ' allocated serials';
                        if (allocatedSerials.size() <= 20) errMsg += ': ' + String.join(new List<String>(allocatedSerials),', ');
                            
                        throw new CustomException(errMsg);
                    }
                }
            }
        }
    }

    public static void plan(List<LineWrapper> shlWrappers) {
        if (shlWrappers == null || shlWrappers.size() == 0) return;
        
        checkPlanErrors(shlWrappers);

        Set<Id> uomIds = new Set<Id>();
        Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
        for (LineWrapper shlWrapper:shlWrappers) {
            Shipment_Line__c shl = (Shipment_Line__c)shlWrapper.line;
            if (packagingUoms.containsKey(shl.Item__c) == false) {
                List<Id> pkgUoms = getUomIds(shl);
                uomIds.addAll(pkgUoms);
                packagingUoms.put(shl.Item__c, pkgUoms);
            }
        }

        Map<Id, List<UOM__c>> uoms = getUomList(uomIds, packagingUoms);
        
        List<Shipment_Line__c> shlsToUpdate = new List<Shipment_Line__c>();
        List<SkidService3.SerialWrapper> skidsToPutaway = new List<SkidService3.SerialWrapper>();
        Map<Id, Serial__c> serialsToUpdate = new Map<Id, Serial__c>();
        Map<List<String>, List<Serial__c>> serialMap = new Map<List<String>, List<Serial__c>>();
        for (LineWrapper shlWrapper:shlWrappers) {
            Shipment_Line__c shl = (Shipment_Line__c)shlWrapper.line;
            List<Id> pkgUoms = packagingUoms.get(shl.Item__c);
            Decimal convFactor = shl.Sales_Order_Line__c != null ? KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, shl.Sales_Order_Line__r.Selling_UOM__c, shl.Item__r.Stocking_UOM__c, pkgUoms) : 1;
            Shipment_Line__c shlToUpdate = new Shipment_Line__c(Id = shl.Id, Quantity_Allocated__c = shl.Quantity_Allocated__c / convFactor, Quantity_To_Pick__c = shl.Quantity_To_Pick__c);
            List<String> allocAttributes = SkidService3.allocAttributes.get(shl.Item__c);

            for (SkidService3.SerialWrapper sw:shlWrapper.serialWrappers) {
                if (sw.skid.Input_Quantity__c != null && sw.skid.Input_Quantity__c != 0) {
                    SKID__c allocSkid = new SKID__c(
                        Type__c = SkidService3.SKID_TYPE_ALLOCATED,
                        Company__c = shl.Company__c,
                        Item__c = shl.Item__c,
                        Item__r = shl.Item__r,
                        Quantity__c = -sw.skid.Input_Quantity__c,
                        Quantity_Stocking_UOM__c = -sw.skid.Input_Quantity__c,
                        Packaging_UOM__c = shl.Item__r.Stocking_UOM__c,
                        Packaging_UOM__r = shl.Item__r.Stocking_UOM__r,
                        Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                        Facility2__c = shl.Facility__c,
                        Facility2__r = shl.Facility__r,
                        Container_Item__c = shl.Item__c,
                        Container_Item__r = shl.Item__r,
                        Shipment_Line__c = shl.Id,
                        Shipment_Line__r = shl,
                        Sales_Order_Line__c = shl.Sales_Order_Line__c,
                        Order_Line__c = shl.Order_Line__c
                    );
                    for (String attr:allocAttributes) {
                        if (allocSkid.get(attr) == null && sw.skid.get(attr) != null) {
                            allocSkid.put(attr, sw.skid.get(attr));
                            if (attr == 'Lot__c') allocSkid.Lot_Number__c = sw.skid.Lot_Number__c;
                            if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference) {
                                String refField = attr.replace('__c', '__r');
                                allocSkid.putSObject(refField, sw.skid.getSObject(refField));
                            }
                        }
                    }
                    skidsToPutaway.add(new SkidService3.SerialWrapper(allocSkid));

                    shlToUpdate.Quantity_Allocated__c += (allocSkid.Quantity__c / convFactor);
                    shlToUpdate.Quantity_To_Pick__c -= allocSkid.Quantity__c;
                }

                List<Serial__c> serialsToPlan = new List<Serial__c>();
                for (Serial__c serial:sw.serialList) {
                    if (serial.Temporary_Value_Holder__c == 'Unplan') serialsToUpdate.put(serial.Id, new Serial__c(Id = serial.Id, Allocated_SKID__c = null));
                    else if (serial.Temporary_Value_Holder__c == 'Plan') serialsToPlan.add(new Serial__c(Id = serial.Id));
                }

                if (serialsToPlan.size() > 0 || (sw.skid.Quantity_to_Issue__c != null && sw.skid.Quantity_to_Issue__c != 0) || sw.skid.Quantity_To_Return__c > 0) {
                    SKID__c planSkidTemplate = new SKID__c(
                        Type__c = SkidService3.SKID_TYPE_PLANNED,
                        Company__c = shl.Company__c,
                        Item__c = shl.Item__c,
                        Item__r = shl.Item__r,
                        Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                        Facility2__c = shl.Facility__c,
                        Facility2__r = shl.Facility__r,
                        Container_Item__c = shl.Item__c,
                        Container_Item__r = shl.Item__r,
                        Shipment_Line__c = shl.Id,
                        Shipment_Line__r = shl,
                        Lot_Number__c = sw.skid.Lot_Number__c
                    );
                    for (String attr:SkidService3.planAttributes) {
                        if (planSkidTemplate.get(attr) == null && sw.skid.get(attr) != null) {
                            planSkidTemplate.put(attr, sw.skid.get(attr));
                            if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference) {
                                String refField = attr.replace('__c', '__r');
                                planSkidTemplate.putSObject(refField, sw.skid.getSObject(refField));
                            }
                        }
                    }

                    if (serialsToPlan.size() > 0 || (sw.skid.Quantity_to_Issue__c != null && sw.skid.Quantity_to_Issue__c != 0)) {
                        SKID__c planSkid = planSkidTemplate.clone(false, true);
                        planSkid.Quantity__c = KSE.addQuantityToField(sw.skid.Quantity_to_Issue__c, 0);
                        planSkid.Quantity_Stocking_UOM__c = planSkid.Quantity__c * KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, planSkid.Packaging_UOM__c, shl.Item__r.Stocking_UOM__c, pkgUoms);
                        skidsToPutaway.add(new SkidService3.SerialWrapper(planSkid));

                        if (serialsToPlan.size() > 0) serialMap.put(SkidService3.generateKey(planSkid, SkidService3.attributesForUniqueKey), serialsToPlan);
                    }

                    if (sw.skid.Quantity_To_Return__c > 0) {
                        List<UOM__c> uomList = uoms.get(shl.Item__c);
                        for (Integer i = 0; i < uomList.size(); i++) {
                            if (uomList[i].Id == sw.skid.Packaging_UOM__c) {
                                SKID__c planSkid = planSkidTemplate.clone(false, true);
                                planSkid.Packaging_UOM__r = uomList[i + 1];
                                planSkid.Packaging_UOM__c = planSkid.Packaging_UOM__r.Id;
                                planSkid.Quantity__c = sw.skid.Quantity_To_Return__c;
                                planSkid.Quantity_Stocking_UOM__c = planSkid.Quantity__c * KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, planSkid.Packaging_UOM__c, shl.Item__r.Stocking_UOM__c, pkgUoms);
                                skidsToPutaway.add(new SkidService3.SerialWrapper(planSkid));
                                break;
                            }
                        }
                    }
                }
            }

            shlsToUpdate.add(shlToUpdate);
        }

        Map<List<String>, SkidService3.SerialWrapper> putawaySkids = skidsToPutaway.size() > 0 ? SkidService3.putAwayService(skidsToPutaway, SkidService3.attributesForUniqueKey, new Map<String,Boolean>{ SkidService3.DELETE_SKIDS => true }) : new Map<List<String>, SkidService3.SerialWrapper>();
        for (List<String> skidKey:serialMap.keySet()) {
            for (Serial__c serial:serialMap.get(skidKey)) {
                serial.Allocated_SKID__c = putawaySkids.get(skidKey).skid.Id;
                serialsToUpdate.put(serial.Id, serial);
            }
        }
        if (serialsToUpdate.size() > 0) DML.updateAsSystem(serialsToUpdate.values());

        if (shlsToUpdate.size() > 0) DML.updateAsUser(shlsToUpdate);
    }

    public static List<LineWrapper> getInventoryForPick(List<Shipment_Line__c> shipmentLines) {
        List<LineWrapper> wrappers = new List<LineWrapper>();
        if (shipmentLines == null || shipmentLines.size() == 0) return wrappers;

        Id companyId;
        Boolean isPicked = false;
        Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
        Set<Id> uomIds = new Set<Id>();
        Set<String> lineTypes = new Set<String>();
        Map<Id, sObject> linesForLocation = new Map<Id, sObject>();
        for (Shipment_Line__c shl:shipmentLines) {
            companyId = shl.Company__c;
            if (shl.Quantity_Picked__c > 0) isPicked = true;

            if (packagingUoms.containsKey(shl.Item__c) == false) {
                List<Id> uomList = getUomIds(shl);
                packagingUoms.put(shl.Item__c, uomList);
                uomIds.addAll(uomList);
            }

            if (shl.Sales_Order_Line__c != null) {
                lineTypes.add('sales_order_line__c');
                linesForLocation.put(shl.Id, shl.Sales_Order_Line__r);
            } else {
                lineTypes.add('order_line__c');
                linesForLocation.put(shl.Id, shl.Order_Line__r);
            }
        }

        Set<Id> shlIds = linesForLocation.keySet();
        Set<Id> locationIds = new Set<Id>();
        Map<String, List<Location__c>> locMap = SkidService3.locationsFromStockMovementRules(linesForLocation.values(), 'Pick', lineTypes, null, locationIds);
        Set<Id> itemIds = packagingUoms.keySet();
        Map<Id, UOM__c> uoms = getUoms(uomIds);

        Map<List<String>, Map<List<String>, SkidService3.SerialWrapper>> pickedSkids = new Map<List<String>, Map<List<String>, SkidService3.SerialWrapper>>();
        if (isPicked == true) {
            List<String> consignedAttributes = SkidService3.attributes.clone();
            consignedAttributes.add('Quantity__c');
            consignedAttributes.add('Transaction_Date__c');

            Map<List<String>, Inventory_Transaction__c> consignedIts = new Map<List<String>, Inventory_Transaction__c>();
            String whereClause = 'Type__c = \'Transfer of Ownership\' AND Shipment_Line__c IN :shlIds';
            for (Inventory_Transaction__c it:Database.query(SkidService3.getItQuery(new Map<String, String>{ 'WHERE' => whereClause, 'ORDER' => 'CreatedDate ASC' }))) {
                Inventory_Transaction__c itClone = it.clone(false, true);
                itClone.Purchase_Order_Line__c = null;
                consignedIts.put(SkidService3.generateKey(itClone, consignedAttributes), it);
            }
            
            whereClause = 'Type__c IN (\'Sales Order Pick\', \'Sales Order Pick Transfer\', \'Sales Order Undo Pick\', \'Transfer Order Pick\', \'Transfer Order Pick Transfer\', \'Transfer Order Undo Pick\') AND Shipment_Line__c IN :shlIds';
            for (Inventory_Transaction__c it:Database.query(SkidService3.getItQuery(new Map<String, String>{ 'WHERE' => whereClause, 'ORDER' => 'CreatedDate ASC', 'SERIALS' => 'true' }))) {
                String pickDir = it.Type__c == 'Sales Order Pick' || it.Type__c == 'Sales Order Pick Transfer' || it.Type__c == 'Transfer Order Pick' || it.Type__c == 'Transfer Order Pick Transfer' ? 'To' : 'From';
                String stockDir = pickDir == 'From' ? 'To' : 'From';

                SKID__c pickedSkid = new SKID__c();
                SKID__c stockSkid = new SKID__c();
                stockSkid.Quantity__c = it.Type__c == 'Sales Order Undo Pick' || it.Type__c == 'Transfer Order Undo Pick' ? -it.Quantity__c : it.Quantity__c;
                stockSkid.Quantity_Stocking_UOM__c = it.Type__c == 'Sales Order Undo Pick' || it.Type__c == 'Transfer Order Undo Pick' ? -it.Quantity_Stocking_UOM__c : it.Quantity_Stocking_UOM__c;

                for (String attr:SkidService3.attributes) {
                    String pickField;
                    String stockField;
                    Boolean isLookup = skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference;

                    if (attr == 'Facility2__c') {
                        pickField = pickDir + '_Facility__c';
                        stockField = stockDir + '_Facility__c';
                    } else if (attr == 'Location__c') {
                        pickField = pickDir + '_Location__c';
                        stockField = stockDir + '_Location__c';
                    } else if (attr == 'Bin__c') {
                        if (pickDir == 'From') pickField = 'From_Bin__c';
                        else pickField = 'Bin__c';

                        if (stockDir == 'From') stockField = 'From_Bin__c';
                        else stockField = 'Bin__c';
                    } else if (attr == 'Packaging_UOM__c') {
                        if (pickDir == 'From') pickField = 'From_Packaging_UOM__c';
                        else pickField = 'Packaging_UOM__c';

                        if (stockDir == 'From') stockField = 'From_Packaging_UOM__c';
                        else stockField = 'Packaging_UOM__c';
                    } else if (attr == 'Lot__c') {
                        if (pickDir == 'From') pickField = 'From_Lot__c';
                        else pickField = 'Lot__c';

                        if (stockDir == 'From') stockField = 'From_Lot__c';
                        else stockField = 'Lot__c';
                    } else {
                        pickField = attr;
                        stockField = attr;
                    }
                    pickedSkid.put(attr, it.get(pickField));
                    
                    
                        
                    
                    //Remove SOLine
                    if (isLookup == true) pickedSkid.putSObject(attr.replace('__c', '__r'), it.getSObject(pickField.replace('__c', '__r')));

                    if ((it.Type__c == 'Sales Order Pick Transfer' || it.Type__c == 'Transfer Order Pick Transfer') && attr == 'Location__c') {
                        Id lineId = linesForLocation.get(it.Shipment_Line__c).Id;
                        if (locMap.containsKey(lineId) == false) throw new CustomException(it.Shipment_Line__r.Name + ': ' + Label.Matching_stock_movement_rule_not_found);
                        Location__c loc = locMap.get(lineId)[0];
                        stockSkid.Location__c = loc.Id;
                        stockSkid.Location__r = loc.clone(true, true);
                    } else if ((it.Type__c != 'Sales Order Pick Transfer' && it.Type__c != 'Transfer Order Pick Transfer') || attr != 'Bin__c') {
                        stockSkid.put(attr, it.get(stockField));
                        if (isLookup == true) stockSkid.putSObject(attr.replace('__c', '__r'), it.getSObject(stockField.replace('__c', '__r')));
                    }
                }
                pickedSkid.Sales_Order_Line__c = null;
                if(it.Sales_Order_Line__r.Sales_Order__r.Type__c != SalesOrderService.SO_TYPE_RMA_REPAIR && it.Sales_Order_Line__r.Sales_Order__r.Type__c != SalesOrderService.SO_TYPE_REPAIR){
                    stockSkid.Sales_Order_Line__c = null;
                }
                if (it.Shipment_Line__r.Sales_Order_Line__c != null && it.Shipment_Line__r.Sales_Order_Line__r.Price_Type__c != 'Recurring') {
                    if (it.Type__c == 'Sales Order Pick') {
                        Inventory_Transaction__c itClone = it.clone(false, true);
                        itClone.To_Location__c = itClone.From_Location__c;
                        itClone.Bin__c = itClone.From_Bin__c;

                        Inventory_Transaction__c consignedIt = consignedIts.get(SkidService3.generateKey(itClone, consignedAttributes));
                        if (consignedIt != null) {
                            stockSkid.Consigned_Owner__c = consignedIt.Purchase_Order_Line__r.Supplier__c;
                            stockSkid.Consigned_Owner__r = consignedIt.Purchase_Order_Line__r.Supplier__r;
                            stockSkid.Purchase_Order_Line__c = consignedIt.Purchase_Order_Line__c;
                        }
                    } else if (it.Type__c == 'Sales Order Undo Pick') {
                        pickedSkid.Consigned_Owner__c = null;
                        pickedSkid.Purchase_Order_Line__c = null;
                    }
                }

                SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(stockSkid);
                for (Serial_Transaction__c st:it.Serial_Transactions__r) sw.serialList.add(new Serial__c(Id = st.Serial__c));

                List<String> pickedKey = SkidService3.generateKey(pickedSkid, SkidService3.attributes);
                List<String> stockKey = SkidService3.generateKey(stockSkid, SkidService3.attributes);
                if (pickedSkids.containsKey(pickedKey) == false) {
                    pickedSkids.put(pickedKey, new Map<List<String>, SkidService3.SerialWrapper>{ stockKey => sw });
                } else if (sw.skid.Quantity__c > 0) {
                    if (pickedSkids.get(pickedKey).containsKey(stockKey) == false) {
                        pickedSkids.get(pickedKey).put(stockKey, sw);
                    } else {
                        SkidService3.SerialWrapper sw2 = pickedSkids.get(pickedKey).get(stockKey);
                        sw2.skid.Quantity__c += stockSkid.Quantity__c;
                        sw2.skid.Quantity_Stocking_UOM__c += stockSkid.Quantity_Stocking_UOM__c;
                        sw2.serialList.addAll(sw.serialList);
                    }
                } else {
                    Decimal convFactor = KSE.getConversionFactor(it.Item__c, it.To_Facility__r.Facility_Identifier__c, it.Packaging_UOM__c, it.Item__r.Stocking_UOM__c, packagingUoms.get(it.Item__c));

                    if (pickedSkids.get(pickedKey).containsKey(stockKey) == true && sw.serialList.size() == 0) {
                        SkidService3.SerialWrapper sw2 = pickedSkids.get(pickedKey).get(stockKey);
                        Decimal qtyUnpicked = Math.min(sw2.skid.Quantity__c, -sw.skid.Quantity__c);
                        sw2.skid.Quantity__c -= qtyUnpicked;
                        sw2.skid.Quantity_Stocking_UOM__c = sw2.skid.Quantity__c * convFactor;
                        sw.skid.Quantity__c += qtyUnpicked;
                        sw.skid.Quantity_Stocking_UOM__c = sw.skid.Quantity__c * convFactor;
                    }

                    Set<Id> unpickedSerials = new Set<Id>((new Map<Id, Serial__c>(sw.serialList)).keySet());
                    for (SkidService3.SerialWrapper sw2:pickedSkids.get(pickedKey).values()) {
                        if (sw.skid.Quantity_Stocking_UOM__c == 0) break;

                        if (sw.serialList.size() > 0) {
                            for (Integer i = 0; i < sw2.serialList.size(); i++) {
                                Serial__c serial = sw2.serialList[i];
                                if (unpickedSerials.contains(serial.Id)) {
                                    sw2.serialList.remove(i--);
                                    sw2.skid.Quantity_Stocking_UOM__c--;
                                    sw.skid.Quantity_Stocking_UOM__c++;
                                    unpickedSerials.remove(serial.Id);
                                }
                            }
                            
                            sw2.skid.Quantity__c = sw2.skid.Quantity_Stocking_UOM__c / convFactor;
                            sw.skid.Quantity__c = sw.skid.Quantity_Stocking_UOM__c / convFactor;
                        } else {
                            Decimal qtyUnpicked = Math.min(sw2.skid.Quantity__c, -sw.skid.Quantity__c);
                            sw2.skid.Quantity__c -= qtyUnpicked;
                            sw2.skid.Quantity_Stocking_UOM__c = sw2.skid.Quantity__c * convFactor;
                            sw.skid.Quantity__c += qtyUnpicked;
                            sw.skid.Quantity_Stocking_UOM__c = sw.skid.Quantity__c * convFactor;
                        }
                    }
                }
            }
        }

        List<String> sortCriteria = SkidService3.populateSortCriteria(null, companyId);
        sortCriteria.add('Shipment_Line__c ASC NULLS LAST');

        String whereClause = 'Item__c IN :itemIds ' +
                             'AND Receipt_Line__c = null ' +
                             'AND ((Type__c IN (\'' + SkidService3.SKID_TYPE_PLANNED + '\', \'' + SkidService3.SKID_TYPE_LOCATION + '\') ' +
                             'AND Shipment_Line__c IN :shlIds '+
                             'AND Mixed_Palletized__c = false) ' +
                             'OR (Type__c = \'' + SkidService3.SKID_TYPE_LOCATION + '\' ' +
                             'AND Location__c IN :locationIds ' +
                             'AND Quantity_Stocking_UOM__c > 0 ' +
                             'AND (Lot__c = null OR Lot__r.Lot_Hold__c = false) ' +
                             'AND Shipment_Line__c = null))';

        Map<Id, Map<List<String>, SkidService3.SerialWrapper>> planSkidMap = new Map<Id, Map<List<String>, SkidService3.SerialWrapper>>();
        Map<Id, SKID__c> skidMap = new Map<Id, SKID__c>();
        Map<List<String>, List<SkidService3.SerialWrapper>> sortedSkids = new Map<List<String>, List<SkidService3.SerialWrapper>>();
        Map<List<String>, SkidService3.SerialWrapper> stockSkids = new Map<List<String>, SkidService3.SerialWrapper>();
        for (SKID__c skid:Database.query(SkidService3.getSkidQuery(new Map<String, String>{ 'WHERE' => whereClause, 'ORDER' => String.join(sortCriteria, ',') }))) {
            SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(skid, new List<Serial__c>());
            if (sw.skid.Type__c == SkidService3.SKID_TYPE_PLANNED) {
                Id shlId = sw.skid.Shipment_Line__c;
                sw.skid.Shipment_Line__c = null;

                List<String> planKey = SkidService3.generateKey(sw.skid, SkidService3.planAttributes);
                if (planSkidMap.containsKey(shlId) == false) planSkidMap.put(shlId, new Map<List<String>, SkidService3.SerialWrapper>{ planKey => sw });
                else planSkidMap.get(shlId).put(planKey, sw);
            } else {
                skidMap.put(sw.skid.Id, sw.skid);

                List<String> key = SkidService3.generateKey(sw.skid, SkidService3.attributes);
                if (sw.skid.Shipment_Line__c != null) {
                    for (List<String> skidKey:pickedSkids.get(key).keySet()) {
                        SkidService3.SerialWrapper sw2 = pickedSkids.get(key).get(skidKey);
                        if (sw2.skid.Quantity_Stocking_UOM__c == 0) continue;

                        sw2.skid.Temporary_Value_Holder__c = sw.skid.Id;
                        sw2.skid.Total_Material__c = sw.skid.Quantity__c;
                        if (sw.skid.Bin__c != null) sw2.skid.Temporary_Value_Holder1__c = JSON.serialize(sw.skid.Bin__r);

                        List<String> itemLocKey = new List<String>{ sw2.skid.Item__c, sw2.skid.Location__c };
                        if (sortedSkids.containsKey(itemLocKey) == false) sortedSkids.put(itemLocKey, new List<SkidService3.SerialWrapper>{ sw2 });
                        else sortedSkids.get(itemLocKey).add(sw2);
                    }
                } else {
                    List<String> itemLocKey = new List<String>{ sw.skid.Item__c, sw.skid.Location__c };
                    if (sortedSkids.containsKey(itemLocKey) == false) sortedSkids.put(itemLocKey, new List<SkidService3.SerialWrapper>{ sw });
                    else sortedSkids.get(itemLocKey).add(sw);

                    stockSkids.put(key, sw);
                }
            }
        }

        Map<Id, Serial__c> serialMap = new Map<Id, Serial__c>();
        if (skidMap.size() > 0) {
            Set<Id> skidIds = skidMap.keySet();
            whereClause = 'SKID__c IN :skidIds AND (Allocated_SKID__c = null OR (Allocated_SKID__r.Shipment_Line__c IN :shlIds AND Allocated_SKID__r.Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\'))';
            for (Serial__c serial:Database.query(SkidService3.getSerialQuery(new Map<String, String>{ 'WHERE' => whereClause, 'ORDER' => 'Allocated_SKID__c ASC NULLS LAST, Name ASC' }))) {
                List<String> skidKey = SkidService3.generateKey(skidMap.get(serial.SKID__c), SkidService3.attributes);
                if (stockSkids.containsKey(skidKey) == true) {
                    stockSkids.get(skidKey).serialList.add(serial);
                } else {
                    serial.Temporary_Value_Holder__c = 'Picked';
                    serialMap.put(serial.Id, serial);
                }
            }
        }

        Map<List<String>, Decimal> qtyAvailableMap = new Map<List<String>, Decimal>();
        for (Shipment_Line__c shl:shipmentLines) {
            sObject lineForLocation = linesForLocation.get(shl.Id);
            if (locMap.containsKey(lineForLocation.Id) == false) throw new CustomException(shl.Name + ': ' + Label.Matching_stock_movement_rule_not_found);

            Map<List<String>, SkidService3.SerialWrapper> planSkids = planSkidMap.containsKey(shl.Id) ? planSkidMap.get(shl.Id) : new Map<List<String>, SkidService3.SerialWrapper>();
            List<Id> pkgUoms = packagingUoms.get(shl.Item__c);

            List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('SKID__c', new List<String>{ 'Location__c', 'Bin__c' });
            if (shl.Location__r.Bin_Tracked__c == true) {
                FieldInfo binField = new FieldInfo('To_Bin__c','Shipping Bin','reference');
                binField.referenceTo = 'Bin__c';
                binField.editable = true;
                fiList.add(binField);
            }
            fiList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', new List<String>{ 'Customer__c', 'Consigned_Owner__c', 'Container_Item__c' }, true));
            
            List<FieldInfo> lpnFields = FieldInfo.fetchJsonFieldInfos('SKID__c', new List<String>{ 'License_Plate_Number__c' }, true);
            lpnFields[0].title = 'From LPN';

            lpnFields.add(new FieldInfo('To_LPN__c', 'To LPN', 'reference'));
            lpnFields[lpnFields.size() - 1].referenceTo = 'LPN__c';
            lpnFields[lpnFields.size() - 1].editable = true;

            if (shl.Item__r.Container_Item__c != null && shl.Item__r.Container_Item__r.Item_Attribute__c != null && shl.Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c == true) {
                fiList.addAll(lpnFields);
            } else {
                for (Id uomId:pkgUoms) {
                    Item__c container = SkidService3.getContainerforItem(shl.Item__r, uoms.get(uomId));
                    if (container.Item_Attribute__c != null && container.Item_Attribute__r.License_Plate_Number__c == true) {
                        fiList.addAll(lpnFields);
                        break;
                    }
                }
            }
            
            List<String> skidFields = new List<String>();
            for (String attr:SkidService3.attributeFields) {
                if (attr != 'License_Plate_Number__c' && shl.Item__r.Item_Attribute__c != null && (Boolean)shl.Item__r.Item_Attribute__r.get(attr) == true) {
                    if (attr == 'Lot_Number__c') skidFields.add('Lot__c');
                    else skidFields.add(attr);
                }
            }
            skidFields.addAll(util.getFieldsFromFieldSetString(SKID__c.sObjectType, 'ShipmentPickRO'));
            skidFields.addAll(new List<String>{ 'Quantity_Used__c', 'Quantity_Available__c' });
            fiList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', skidFields, true));
            fiList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', new List<String>{ 'Quantity_to_Issue__c' }));

            Map<Id, LineWrapper> swMap = new Map<Id, LineWrapper>();
            Decimal qtyToPick = shl.Quantity_To_Pick__c;
            Map<List<String>, Decimal> planQtyAvailableMap = new Map<List<String>, Decimal>();
            for (Location__c loc:locMap.get(lineForLocation.Id)) {
                List<String> itemLocKey = new List<String>{ shl.Item__c, loc.Id };
                if (sortedSkids.containsKey(itemLocKey) == false) continue;

                /*
                 * Quantity Used = Quantity picked (Packaging UOM)
                 * Total Material = Total quantity picked at shipping dock/not mixed palletized (Packaging UOM)
                 * Quantity Allocated = Quantity planned for packaging UOM (Stocking UOM)
                 * Quantity Short = Quantity planned for packaging UOM level - 1 (Stocking UOM)
                 * Count Quantity = Quantity available in stock (Stocking UOM)
                 * Quantity Available = Quantity available to pick (Stocking UOM)
                 * Quantity to Issue = Input quantity for packaging UOM
                 * Quantity To Return = Input quantity for packaging UOM level - 1
                 * Input Quantity = Quantity to pick (Stocking UOM)
                 * Quantity Issued = Conversion factor for packaging UOM (to stocking)
                 * Quantity Required = Conversion factor for packaging UOM level - 1 (to stocking)
                 */
                Set<List<String>> keysUsed = new Set<List<String>>();
                for (SkidService3.SerialWrapper sw:sortedSkids.get(itemLocKey)) {
                    SKID__c skidClone = sw.skid.clone(false, true);
                    skidClone.Shipment_Line__c = null;

                    List<String> skidKey = SkidService3.generateKey(skidClone, SkidService3.attributes);
                    List<String> planKey = SkidService3.generateKey(skidClone, SkidService3.planAttributes);

                    UOM__c lowerUom;
                    List<String> lowerUomKey;
                    for (Integer i = 0; i < pkgUoms.size(); i++) {
                        if (sw.skid.Packaging_UOM__c == pkgUoms[i]) {
                            if (i > 0) {
                                lowerUom = uoms.get(pkgUoms[i - 1]);
                                SKID__c lowerUomSkid = skidClone.clone(false, true);
                                lowerUomSkid.Packaging_UOM__c = lowerUom.Id;
                                lowerUomKey = SkidService3.generateKey(lowerUomSkid, SkidService3.planAttributes);
                            }
                            break;
                        }
                    }

                    if ((sw.skid.Shipment_Line__c != null && sw.skid.Shipment_Line__c != shl.Id) || (sw.skid.Shipment_Line__c == null && (keysUsed.contains(skidKey) == true || (planSkids.containsKey(planKey) == false && planSkids.containsKey(lowerUomKey) == false)))) continue;

                    SkidService3.SerialWrapper stockSw = sw.skid.Shipment_Line__c == null ? sw : stockSkids.get(skidKey);
                    if (stockSw != null) keysUsed.add(skidKey);

                    skidClone.Quantity_Used__c = sw.skid.Shipment_Line__c != null ? Math.min(sw.skid.Quantity__c, sw.skid.Total_Material__c) : 0;
                    skidClone.Total_Material__c = sw.skid.Shipment_Line__c != null ? sw.skid.Total_Material__c : 0;
                    skidClone.Quantity_Allocated__c = planSkids.containsKey(planKey) == true ? planSkids.get(planKey).skid.Quantity_Stocking_UOM__c : 0;
                    skidClone.Quantity_Short__c = planSkids.containsKey(lowerUomKey) == true ? planSkids.get(lowerUomKey).skid.Quantity_Stocking_UOM__c : 0;
                    skidClone.Count_Quantity__c = stockSw != null ? stockSw.skid.Quantity_Stocking_UOM__c : 0;
                    skidClone.Quantity_to_Issue__c = 0;
                    skidClone.Quantity_To_Return__c = 0;
                    skidClone.Input_Quantity__c = 0;
                    skidClone.Quantity_Issued__c = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, skidClone.Packaging_UOM__c, shl.Item__r.Stocking_UOM__c, pkgUoms);
                    skidClone.Quantity_Required__c = lowerUom != null ? KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, lowerUom.Id, shl.Item__r.Stocking_UOM__c, pkgUoms) : 0;
                    skidClone.Quantity_Available__c = Math.min(skidClone.Quantity_Allocated__c + skidClone.Quantity_Short__c, skidClone.Count_Quantity__c);
                    if (skidClone.Lot__c != null) skidClone.Lot_Number__c = skidClone.Lot__r.Name;
                    if (skidClone.License_Plate_Number__c != null) skidClone.Temporary_LPN_Holder__c = skidClone.License_Plate_Number__r.Name;

                    if (skidClone.Quantity_Available__c > 0 || skidClone.Quantity_Used__c > 0) {
                        SkidService3.SerialWrapper sw2 = new SkidService3.SerialWrapper(skidClone);
                        if (shl.Shipment__r.Ship_From_Bin__c != null) sw2.temporaryValueHolder = JSON.serialize(shl.Shipment__r.Ship_From_Bin__r);

                        if (sw.skid.Shipment_Line__c != null) {
                            for (Serial__c serial:sw.serialList) sw2.serialList.add(serialMap.get(serial.Id));
                        }
                        if (stockSw != null) {
                            for (Serial__c serial:stockSw.serialList) {
                                if (serial.Allocated_SKID__c == null || serial.Allocated_SKID__r.Shipment_Line__c == shl.Id) sw2.serialList.add(serial);
                            }
                        }

                        Decimal qty = qtyAvailableMap.containsKey(skidKey) == true ? qtyAvailableMap.get(skidKey) : sw2.skid.Count_Quantity__c;
                        Decimal planQty = planQtyAvailableMap.containsKey(planKey) ? planQtyAvailableMap.get(planKey) : sw2.skid.Quantity_Allocated__c;
                        Decimal qtyAvailable = Math.min(qty, planQty);

                        sw2.skid.Quantity_to_Issue__c = Math.min(qtyAvailable, qtyToPick) / sw2.skid.Quantity_Issued__c;
                        if (sw2.skid.Packaging_UOM__r.Package_Class__c != null && sw2.skid.Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c != true) sw2.skid.Quantity_to_Issue__c = sw2.skid.Quantity_to_Issue__c.intValue();
                        sw2.skid.Input_Quantity__c = sw2.skid.Quantity_to_Issue__c * sw2.skid.Quantity_Issued__c;

                        qtyToPick -= sw2.skid.Input_Quantity__c;
                        qtyAvailableMap.put(skidKey, qty - sw2.skid.Input_Quantity__c);
                        planQtyAvailableMap.put(planKey, planQty - sw2.skid.Input_Quantity__c);

                        if (swMap.containsKey(sw2.skid.Packaging_UOM__c) == false) {
                            LineWrapper wrapper = generateWrapper(shl, sw2.skid.Packaging_UOM__r);

                            wrapper.skidFields = (List<FieldInfo>)JSON.deserialize(JSON.serialize(fiList), List<FieldInfo>.Class);
                            if (lowerUom != null) {
                                FieldInfo fi = FieldInfo.fetchJsonFieldInfos('SKID__c', new List<String>{ 'Quantity_To_Return__c' })[0];
                                fi.title = lowerUom.Name + (lowerUom.Id != shl.Item__r.Stocking_UOM__c ? ' (' + sw2.skid.Quantity_Required__c + ' ' + shl.Item__r.Stocking_UOM__r.Name + ')' : '');
                                fi.editable = true;
                                wrapper.skidFields.add(fi);
                            }
                            wrapper.skidFields.add(FieldInfo.fetchJsonFieldInfos('SKID__c', new List<String>{ 'Input_Quantity__c' }, true)[0]);
                            for (FieldInfo fi:wrapper.skidFields) {
                                if (fi.field == 'Location__c') fi.title = 'Stock Location';
                                else if (fi.field == 'Bin__c') fi.title = 'Stock Bin';
                                else if (fi.field == 'Quantity_Used__c') fi.title = 'Quantity Picked (' + wrapper.uom + ')';
                                else if (fi.field == 'Quantity_Available__c') fi.title = fi.title + ' (' + shl.Item__r.Stocking_UOM__r.Name + ')';
                                else if (fi.field == 'Quantity_to_Issue__c') fi.title = wrapper.uom + (sw2.skid.Packaging_UOM__c != shl.Item__r.Stocking_UOM__c ? ' (' + sw2.skid.Quantity_Issued__c + ' ' + shl.Item__r.Stocking_UOM__r.Name + ')' : '');
                                else if (fi.field == 'Input_Quantity__c') fi.title = 'Quantity To Pick (' + shl.Item__r.Stocking_UOM__r.Name + ')';
                                else if (fi.field == 'Quantity__c') fi.title = 'Quantity in Stock (' + wrapper.uom + ')';

                                fi.field = 'skid.' + fi.field;
                            }

                            swMap.put(sw2.skid.Packaging_UOM__c, wrapper);
                        }

                        swMap.get(sw2.skid.Packaging_UOM__c).serialWrappers.add(sw2);
                    }
                }
            }

            for (Integer i = pkgUoms.size() - 1; i >= 0; i--) {
                if (swMap.containsKey(pkgUoms[i]) == true) wrappers.add(swMap.get(pkgUoms[i]));
            }
        }

        return wrappers;
    }

    public static void checkPickErrors(List<LineWrapper> shlWrappers) {
        if (shlWrappers == null || shlWrappers.size() == 0) return;

        Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
        Set<Id> uomIds = new Set<Id>();
        for (LineWrapper shlWrapper:shlWrappers) {
            Shipment_Line__c shl = (Shipment_Line__c)shlWrapper.line;
            if (packagingUoms.containsKey(shl.Item__c) == false) {
                List<Id> uomList = getUomIds(shl);
                packagingUoms.put(shl.Item__c, uomList);
                uomIds.addAll(uomList);
            }
        }

        Map<Id, UOM__c> uoms = getUoms(uomIds);
        
        Set<String> serialKeys = new Set<String>();
        Map<List<String>, SKID__c> skids = new Map<List<String>, SKID__c>();
        Map<String, Set<Id>> lpnMap = new Map<String, Set<Id>>();
        for (LineWrapper shlWrapper:shlWrappers) {
            Shipment_Line__c shl = (Shipment_Line__c)shlWrapper.line;
            List<Id> pkgUoms = packagingUoms.get(shl.Item__c);

            Map<List<String>, Decimal> serialsLeft = new Map<List<String>, Decimal>();
            Map<List<String>, Set<String>> plannedSerials = new Map<List<String>, Set<String>>();
            Map<List<String>, SKID__c> pickedSkids = new Map<List<String>, SKID__c>();
            Map<List<String>, Decimal> planQtyAvailableMap = new Map<List<String>, Decimal>();
            for (SkidService3.SerialWrapper sw:shlWrapper.serialWrappers) {
                List<String> planKey = SkidService3.generateKey(sw.skid, SkidService3.planAttributes);
                sw.skid.Input_Quantity__c = (KSE.addQuantityToField(sw.skid.Quantity_to_Issue__c, 0) * sw.skid.Quantity_Issued__c) + (KSE.addQuantityToField(sw.skid.Quantity_To_Return__c, 0) * sw.skid.Quantity_Required__c);
                if (planQtyAvailableMap.containsKey(planKey) == false) planQtyAvailableMap.put(planKey, sw.skid.Quantity_Allocated__c);

                Integer serialsToPick = 0;
                Integer serialsToUnpick = 0;
                if (shl.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT && shl.Item__r.Item_Attribute__c != null && shl.Item__r.Item_Attribute__r.Serial_Number__c == true) {
                    if (sw.skid.Quantity_To_Return__c > 0) throw new CustomException(shl.Name + ': You can\'t break packages for items that are serial tracked.');

                    for (Serial__c serial:sw.serialList) {
                        if (serial.Temporary_Value_Holder__c == 'Pick' || serial.Temporary_Value_Holder__c == 'Picked') {
                            String uniqueKey = shl.Company__c + '-' + shl.Item__c + '-' + serial.Name;
                            if (serialKeys.contains(uniqueKey) == false) serialKeys.add(uniqueKey);
                            else throw new CustomException(shl.Item__r.Name + ': Serial ' + serial.Name + ' has been specified more than once.');

                            if (serial.Temporary_Value_Holder__c == 'Pick') serialsToPick++;
                        } else if (serial.Temporary_Value_Holder__c == 'Unpick') {
                            serialsToUnpick++;
                        } else if (serial.Temporary_Value_Holder__c == 'Planned') {
                            serialsLeft.put(planKey, KSE.addQuantityToField(serialsLeft.get(planKey), 1));
                        }

                        if (serial.Allocated_SKID__c != null) {
                            if (plannedSerials.containsKey(planKey) == false) plannedSerials.put(planKey, new Set<String>{ serial.Name });
                            else plannedSerials.get(planKey).add(serial.Name);
                        }
                    }

                    Integer serialCount = serialsToPick - serialsToUnpick;
                    if (serialCount != sw.skid.Input_Quantity__c) throw new CustomException(shl.Name + ': You can\'t pick a different number of serials (' + serialCount + ') than quantity (' + sw.skid.Input_Quantity__c + ').');
                }

                if (sw.skid.Quantity_To_Return__c < 0) throw new CustomException(shl.Name + ': You can\'t unpick partial packages.');

                if ((sw.skid.Quantity_to_Issue__c != null && sw.skid.Quantity_to_Issue__c != 0) || sw.skid.Quantity_To_Return__c > 0 || serialsToPick > 0 || serialsToUnpick > 0) {
                    if (sw.skid.Location__c == null) throw new CustomException(shl.Name + ': You must enter a stock location.');
                    if (sw.skid.Location__r.Bin_Tracked__c == true && sw.skid.Bin__c == null) throw new CustomException(shl.Name + ': You must enter a stock bin.');
                    if (shl.Location__r.Bin_Tracked__c == true && (sw.toskid == null || sw.toskid.Bin__c == null)) throw new CustomException(shl.Name + ': You must enter a shipping bin.');

                    if (String.isBlank(sw.temporaryValueHolder) == false) {
                        List<String> originalAttrs = sw.temporaryValueHolder.split('\\|');
                        Id originalLoc = (Id)originalAttrs[0];
                        Id originalBin = originalAttrs[1] != 'null' ? (Id)originalAttrs[1] : null;
                        Id originalToBin = originalAttrs[2] != 'null' ? (Id)originalAttrs[2] : null;

                        if ((sw.skid.Quantity_to_Issue__c > 0 || sw.skid.Quantity_To_Return__c > 0 || serialsToPick > 0) && (sw.skid.Location__c != originalLoc || sw.skid.Bin__c != originalBin)) {
                            throw new CustomException(shl.Name + ': You can\'t change the stock location or bin while picking.');
                        }

                        if ((sw.skid.Quantity_to_Issue__c < 0 || serialsToUnpick > 0) && shl.Location__r.Bin_Tracked__c == true && sw.toskid.Bin__c != originalToBin) {
                            throw new CustomException(shl.Name + ': You can\'t change the shipping bin while unpicking.');
                        }
                    }

                    if (sw.toskid != null && sw.toskid.License_Plate_Number__r != null && String.isNotBlank(sw.toskid.License_Plate_Number__r.Name) && (sw.skid.Quantity_to_Issue__c > 0 || sw.skid.Quantity_To_Return__c > 0)) {
                        String lpn = sw.toskid.License_Plate_Number__r.Name;
                        if (lpnMap.containsKey(lpn) == true) lpnMap.get(lpn).add(shl.Shipment__c);
                        else lpnMap.put(lpn, new Set<Id>{ shl.Shipment__c });
                    }

                    List<String> skidKey = SkidService3.generateKey(sw.skid, SkidService3.attributes);
                    SKID__c skid = skids.containsKey(skidKey) == true ? skids.get(skidKey) : new SKID__c(Count_Quantity__c = sw.skid.Count_Quantity__c);

                    if (sw.skid.Quantity_to_Issue__c < 0) {
                        SKID__c pickedSkid = sw.skid.clone(false, true);
                        pickedSkid.Location__c = shl.Location__c;
                        pickedSkid.Bin__c = sw.toskid != null ? sw.toskid.Bin__c : null;
                        List<String> pickedKey = SkidService3.generateKey(pickedSkid, SkidService3.attributes);
                        pickedSkid = pickedSkids.containsKey(pickedKey) == true ? pickedSkids.get(pickedKey) : new SKID__c(Total_Material__c = sw.skid.Total_Material__c);
                        
                        Decimal qtyToUnpick = -sw.skid.Quantity_to_Issue__c;
                        Decimal qtyAvailableUndo = Math.min(sw.skid.Quantity_Used__c, pickedSkid.Total_Material__c);
                        if (qtyToUnpick > qtyAvailableUndo) throw new CustomException(shl.Name + ': You can\'t unpick more quantity (' + qtyToUnpick + ') than picked (' + qtyAvailableUndo + ').');

                        pickedSkid.Total_Material__c -= qtyToUnpick;
                        pickedSkids.put(pickedKey, pickedSkid);
                    
                        qtyToUnpick *= sw.skid.Quantity_Issued__c;
                        planQtyAvailableMap.put(planKey, planQtyAvailableMap.get(planKey) + qtyToUnpick);
                        skid.Count_Quantity__c += qtyToUnpick;
                    } else {
                        Decimal qtyToPick = sw.skid.Quantity_to_Issue__c;
                        Decimal qtyAvailable = Math.min(skid.Count_Quantity__c, planQtyAvailableMap.get(planKey)) / sw.skid.Quantity_Issued__c;
                        if (qtyToPick > qtyAvailable) throw new CustomException(shl.Name + ': You can\'t pick more ' + sw.skid.Packaging_UOM__r.Name + ' (' + qtyToPick + ') than available (' + qtyAvailable + ').');

                        qtyToPick *= sw.skid.Quantity_Issued__c;
                        planQtyAvailableMap.put(planKey, planQtyAvailableMap.get(planKey) - qtyToPick);
                        skid.Count_Quantity__c -= qtyToPick;
                    }

                    if (sw.skid.Quantity_To_Return__c > 0) {
                        if (sw.skid.Container_Item__r.Container_Package_Class__c != sw.skid.Packaging_UOM__r.Package_Class__c) throw new CustomException(shl.Name + ': You can\'t break partial packages.');

                        SKID__c lowerUomSkid;
                        List<String> lowerUomPlanKey;
                        for (Integer i = 0; i < pkgUoms.size(); i++) {
                            if (pkgUoms[i] == sw.skid.Packaging_UOM__c) {
                                UOM__c lowerUom = uoms.get(pkgUoms[i - 1]);
                                lowerUomSkid = sw.skid.clone(false, true);
                                lowerUomSkid.Packaging_UOM__c = lowerUom.Id;
                                lowerUomSkid.Packaging_UOM__r = lowerUom;
                                lowerUomPlanKey = SkidService3.generateKey(lowerUomSkid, SkidService3.planAttributes);
                                break;
                            }
                        }

                        if (planQtyAvailableMap.containsKey(lowerUomPlanKey) == false) planQtyAvailableMap.put(lowerUomPlanKey, sw.skid.Quantity_Short__c);

                        Decimal qtyToPick = sw.skid.Quantity_To_Return__c;
                        Decimal qtyAvailable = Math.min(skid.Count_Quantity__c, planQtyAvailableMap.get(lowerUomPlanKey)) / sw.skid.Quantity_Required__c;
                        if (qtyToPick > qtyAvailable) throw new CustomException(shl.Name + ': You can\'t pick more ' + lowerUomSkid.Packaging_UOM__r.Name + ' (' + qtyToPick + ') than available (' + qtyAvailable + ').');

                        qtyToPick *= sw.skid.Quantity_Required__c;
                        planQtyAvailableMap.put(lowerUomPlanKey, planQtyAvailableMap.get(lowerUomPlanKey) - qtyToPick);
                        skid.Count_Quantity__c -= qtyToPick;
                    }
                }
            }

            if (serialsLeft.size() > 0) {
                for (List<String> planKey:serialsLeft.keySet()) {
                    Decimal qtyLeft = planQtyAvailableMap.get(planKey);
                    Decimal serLeft = serialsLeft.get(planKey);
                    Set<String> planSerials = plannedSerials.get(planKey);

                    if (serLeft > qtyLeft) {
                        Decimal serialsRequired = serLeft - qtyLeft;
                        String errMsg = shl.Name + ': Must pick ';
                        if (serialsRequired != serLeft) {
                            errMsg += 'at least ' + serialsRequired;
                        } else {
                            errMsg += 'all';
                        }
                        errMsg += ' planned serials';
                        if (planSerials.size() <= 20) errMsg += ': ' + String.join(new List<String>(planSerials), ', ');
                            
                        throw new CustomException(errMsg);
                    }
                }
            }
        }

        String lpnError = '';
        for (String lpn:lpnMap.keySet()) {
            if (lpnMap.get(lpn).size() > 1) {
                if (lpnError != '') lpnError += ', ';
                lpnError += lpn;
            }
        }
        if (lpnError != '') throw new CustomException('You can\'t choose the same To LPN across shipments. Please check the following LPNs: ' + lpnError);
    }

    public static void pick(List<LineWrapper> shlWrappers) {
        if (shlWrappers == null || shlWrappers.size() == 0) return;

        checkPickErrors(shlWrappers);

        Id companyId;
        Map<Id, Item__c> items = new Map<Id, Item__c>();
        Set<Id> uomIds = new Set<Id>();
        Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
        for (LineWrapper shlWrapper:shlWrappers) {
            Shipment_Line__c shl = (Shipment_Line__c)shlWrapper.line;
            companyId = shl.Company__c;
            if (items.containsKey(shl.Item__c) == false) {
                items.put(shl.Item__c, shl.Item__r);
                List<Id> pkgUoms = getUomIds(shl);
                uomIds.addAll(pkgUoms);
                packagingUoms.put(shl.Item__c, pkgUoms);
            }
        }

        SkidService3.setAllocAttributes(companyId, items);
        Map<Id, UOM__c> uoms = getUoms(uomIds);

        List<String> attributesForPutaway = SkidService3.attributes.clone();
        attributesForPutaway.add('Sales_Order_Line__c');
        attributesForPutaway.add('Order_Line__c');
        attributesForPutaway.add('Type__c');

        List<SkidService3.SerialWrapper> skidsToPutaway = new List<SkidService3.SerialWrapper>();
        Map<Id, SkidService3.ParameterData> itData = new Map<Id, SkidService3.ParameterData>();
        Map<String, Map<String, List<Map<String, Object>>>> packMap = new Map<String, Map<String, List<Map<String, Object>>>>();
        Map<List<String>, Decimal> brokenQtys = new Map<List<String>, Decimal>();
        List<Shipment_Line__c> shlsToUpdate = new List<Shipment_Line__c>();
        Map<Id, Shipment__c> shipmentsToUpdate = new Map<Id, Shipment__c>();
        Map<Id, sObject> orderLinesToUpdate = new Map<Id, sObject>();
        Set<Id> shipmentIds = new Set<Id>();
        Set<Id> shlIds = new Set<Id>();
        for (LineWrapper wrapper:shlWrappers) {
            Shipment__c shipment = (Shipment__c)wrapper.header;
            Shipment__c shipmentToUpdate = shipmentsToUpdate.containsKey(shipment.Id) ? shipmentsToUpdate.get(shipment.Id) : new Shipment__c(Id = shipment.Id, Ship_From_Bin__c = shipment.Ship_From_Bin__c, Status__c = shipment.Status__c);
            Shipment_Line__c shl = (Shipment_Line__c)wrapper.line;
            List<Id> pkgUoms = packagingUoms.get(shl.Item__c);
            Decimal sellingConvFactor = shl.Sales_Order_Line__c != null ? KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, shl.Sales_Order_Line__r.Selling_UOM__c, shl.Item__r.Stocking_UOM__c, pkgUoms) : 1;
            Shipment_Line__c shlToUpdate = new Shipment_Line__c(Id = shl.Id, Quantity_Allocated__c = shl.Quantity_Allocated__c / sellingConvFactor, Quantity_To_Pick__c = shl.Quantity_To_Pick__c, Quantity_Picked__c = shl.Quantity_Picked__c);
            List<String> allocAttrs = SkidService3.allocAttributes.get(shl.Item__c);

            SkidService3.ParameterData itInfo = itData.get(shl.Shipment__c);
            if (itInfo == null) {
                itInfo = new SkidService3.ParameterData();
                itInfo.sourceDoc = new Shipment__c(Company__c = shl.Company__c);
            }

            sObject orderLine;
            String pickItType;
            String undoPickItType;
            if (shl.Sales_Order_Line__c != null) {
                orderLine = orderLinesToUpdate.containsKey(shl.Sales_Order_Line__c) ? orderLinesToUpdate.get(shl.Sales_Order_Line__c) : shl.Sales_Order_Line__r;
                pickItType = 'Sales Order Pick';
                undoPickItType = 'Sales Order Undo Pick';
            } else {
                orderLine = orderLinesToUpdate.containsKey(shl.Order_Line__c) ? orderLinesToUpdate.get(shl.Order_Line__c) : shl.Order_Line__r;
                pickItType = 'Transfer Order Pick';
                undoPickItType = 'Transfer Order Undo Pick';
            }

            shlIds.add(shl.Id);

            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.toskid != null && shipmentToUpdate.Ship_From_Bin__c == null) shipmentToUpdate.Ship_From_Bin__c = sw.toskid.Bin__c;

                List<Serial__c> serialsToPick = new List<Serial__c>();
                List<Serial__c> serialsToUnpick = new List<Serial__c>();
                for (Serial__c serial:sw.serialList) {
                    serial.Allocated_SKID__c = null;
                    serial.Allow_Reentry__c = false;

                    if (serial.Temporary_Value_Holder__c == 'Pick') serialsToPick.add(serial);
                    else if (serial.Temporary_Value_Holder__c == 'Unpick') serialsToUnpick.add(serial);
                }

                SKID__c stockSkidTemplate = new SKID__c(
                    Company__c = shl.Company__c,
                    Type__c = SkidService3.SKID_TYPE_LOCATION,
                    Item__c = shl.Item__c,
                    Item__r = shl.Item__r,
                    Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                    Facility2__c = shl.Facility__c,
                    Facility2__r = shl.Facility__r
                );
                for (String attr:SkidService3.attributes) {
                    if (stockSkidTemplate.get(attr) == null) {
                        if (attr == 'Lot__c') stockSkidTemplate.Lot_Number__c = sw.skid.Lot__r.Name;
                        stockSkidTemplate.put(attr, sw.skid.get(attr));
                        if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference) {
                            attr = attr.replace('__c', '__r');
                            stockSkidTemplate.putSObject(attr, sw.skid.getSObject(attr));
                        }
                    }
                }
				
                SKID__c pickSkidTemplate = stockSkidTemplate.clone(false, true);
                pickSkidTemplate.Location__c = shl.Location__c;
                pickSkidTemplate.Location__r = shl.Location__r;
                if (sw.toskid != null) {
                    pickSkidTemplate.Bin__c = sw.toskid.Bin__c;
                    pickSkidTemplate.Bin__r = sw.toskid.Bin__r;
                } else {
                    pickSkidTemplate.Bin__c = null;
                    pickSkidTemplate.Bin__r = null;
                }
                pickSkidTemplate.Shipment_Line__c = shl.Id;
                pickSkidTemplate.Shipment_Line__r = shl;
                if (shl.Order_Line__c == null && shl.Sales_Order_Line__r.Price_Type__c != 'Recurring') {
                    pickSkidTemplate.Consigned_Owner__c = null;
                    pickSkidTemplate.Purchase_Order_Line__c = null;
                }
                pickSkidTemplate.Sales_Order_Line__c = null;
                
                SKID__c planSkidTemplate = stockSkidTemplate.clone(false, true);
                planSkidTemplate.Type__c = SkidService3.SKID_TYPE_PLANNED;
                planSkidTemplate.Container_Item__c = shl.Item__c;
                planSkidTemplate.Container_Item__r = shl.Item__r;
                planSkidTemplate.License_Plate_Number__c = null;
                planSkidTemplate.License_Plate_Number__r = null;
                planSkidTemplate.Shipment_Line__c = shl.Id;
                planSkidTemplate.Shipment_Line__r = shl;
                

                List<Map<String, Object>> packLines = sw.toskid != null && sw.toskid.License_Plate_Number__r != null && String.isNotBlank(sw.toskid.License_Plate_Number__r.Name) == true && pickSkidTemplate.Bin__c != null ? new List<Map<String, Object>>() : null;

                if (serialsToPick.size() > 0 || serialsToUnpick.size() > 0 || (sw.skid.Quantity_to_Issue__c != null && sw.skid.Quantity_to_Issue__c != 0)) {
                    SKID__c stockSkid = stockSkidTemplate.clone(false, true);
                    
                    stockSkid.Quantity__c = -KSE.addQuantityToField(sw.skid.Quantity_to_Issue__c, 0);
                    if (stockSkid.License_Plate_Number__c != null && sw.skid.Input_Quantity__c < 0 && stockSkid.Quantity__c != sw.skid.Total_Material__c) {
                        stockSkid.License_Plate_Number__c = null;
                        stockSkid.License_Plate_Number__r = null;
                        if (stockSkid.Packaging_UOM__r.Package_Class__c != stockSkid.Container_Item__r.Container_Package_Class__c) {
                            stockSkid.Container_Item__r = SkidService3.getContainerforItem(shl.Item__r, stockSkid.Packaging_UOM__r);
                            stockSkid.Container_Item__c = stockSkid.Container_Item__r.Id;
                        }
                    }
                    skidsToPutaway.add(new SkidService3.SerialWrapper(stockSkid, serialsToUnpick));

                    SKID__c pickSkid = pickSkidTemplate.clone(false, true);
                    pickSkid.Quantity__c = -stockSkid.Quantity__c;
                    if (pickSkid.License_Plate_Number__c != null && sw.skid.Input_Quantity__c > 0 && sw.skid.Input_Quantity__c != sw.skid.Count_Quantity__c) {
                        pickSkid.License_Plate_Number__c = null;
                        pickSkid.License_Plate_Number__r = null;
                        if (pickSkid.Packaging_UOM__r.Package_Class__c != pickSkid.Container_Item__r.Container_Package_Class__c) {
                            pickSkid.Container_Item__r = SkidService3.getContainerforItem(shl.Item__r, pickSkid.Packaging_UOM__r);
                            pickSkid.Container_Item__c = pickSkid.Container_Item__r.Id;
                        }
                    }
                    skidsToPutaway.add(new SkidService3.SerialWrapper(pickSkid, serialsToPick));

                    if (serialsToPick.size() > 0 || sw.skid.Quantity_to_Issue__c > 0) {
                        Inventory_Transaction__c it = SkidService3.createInventoryTransaction(shl.Item__r, orderLine, pickItType, serialsToPick.size() > 0 ? serialsToPick.size() / sw.skid.Quantity_Issued__c : sw.skid.Quantity_to_Issue__c, stockSkid, pickSkid, SkidService3.attributes);
                        it.Purchase_Order_Line__c = pickSkid.Purchase_Order_Line__c;
                        it.To_SKID__r = pickSkid;
                        itInfo.itList.add(it);

                        if (packLines != null && (pkgUoms.size() == 1 || pickSkid.Packaging_UOM__c != pkgUoms[pkgUoms.size() - 1])) {
                            for (Integer i = 0; i < (pickSkid.Packaging_UOM__c != pkgUoms[0] ? it.Quantity__c.intValue() : 1); i++) {
                                Map<String, Object> packLine = new Map<String, Object>{ 'itemId' => shl.Item__c, 'Shipment_Line__c' => shl.Id, 'quantity' => pickSkid.Packaging_UOM__c != pkgUoms[0] ? sw.skid.Quantity_Issued__c : it.Quantity__c };
                                if (pickSkid.License_Plate_Number__c != null) packLine.put('fromLPN', pickSkid.License_Plate_Number__r.Name);
                                packLines.add(packLine);
                            }
                        }
                    }

                    if (serialsToUnpick.size() > 0 || sw.skid.Quantity_to_Issue__c < 0) {
                        Inventory_Transaction__c it = SkidService3.createInventoryTransaction(shl.Item__r, orderLine, undoPickItType, serialsToUnpick.size() > 0 ? serialsToUnpick.size() / sw.skid.Quantity_Issued__c : -sw.skid.Quantity_to_Issue__c, pickSkid, stockSkid, SkidService3.attributes);
                        it.Shipment_Line__c = shl.Id;
                        it.Purchase_Order_Line__c = stockSkid.Purchase_Order_Line__c;
                        it.To_SKID__r = stockSkid;
                        itInfo.itList.add(it);
                    }

                    if (sw.skid.Quantity_to_Issue__c != null && sw.skid.Quantity_to_Issue__c != 0) {
                        Id originalLoc = sw.temporaryValueHolder != null ? (Id)sw.temporaryValueHolder.split('\\|')[0] : sw.skid.Location__c;
                        Decimal qtyPicked = pickSkid.Quantity__c * sw.skid.Quantity_Issued__c;

                        shlToUpdate.Quantity_Picked__c += qtyPicked;

                        if (stockSkid.Location__c == originalLoc) {
                            SKID__c planSkid = planSkidTemplate.clone(false, true);
                            planSkid.Quantity__c = stockSkid.Quantity__c;
                            skidsToPutaway.add(new SkidService3.SerialWrapper(planSkid));

                            shlToUpdate.Quantity_To_Pick__c -= qtyPicked;
                        } else if ((new Set<String>(allocAttrs)).contains('Location__c') == false && shl.Company__r.Auto_Plan_Pick__c == false) {
                            SKID__c allocSkid = new SKID__c(
                                Company__c = shl.Company__c,
                                Type__c = SkidService3.SKID_TYPE_ALLOCATED,
                                Quantity__c = -qtyPicked,
                                Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                                Item__c = shl.Item__c,
                                Item__r = shl.Item__r,
                                Container_Item__c = shl.Item__c,
                                Container_Item__r = shl.Item__r,
                                Facility2__c = shl.Facility__c,
                                Facility2__r = shl.Facility__r,
                                Packaging_UOM__c = shl.Item__r.Stocking_UOM__c,
                                Packaging_UOM__r = shl.Item__r.Stocking_UOM__r,
                                Sales_Order_Line__c = shl.Sales_Order_Line__c,
                                Order_Line__c = shl.Order_Line__c,
                                Shipment_Line__c = shl.Id,
                                Shipment_Line__r = shl
                            );
                            for (String attr:allocAttrs) {
                                if (allocSkid.get(attr) == null) {
                                    if (attr == 'Lot__c') allocSkid.Lot_Number__c = stockSkid.Lot_Number__c;
                                    allocSkid.put(attr, stockSkid.get(attr));
                                    if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference) {
                                        attr = attr.replace('__c', '__r');
                                        allocSkid.putSObject(attr, stockSkid.getSObject(attr));
                                    }
                                }
                            }
                            skidsToPutaway.add(new SkidService3.SerialWrapper(allocSkid));

                            shlToUpdate.Quantity_Allocated__c += (allocSkid.Quantity__c / sellingConvFactor);
                        } else {
                            SKID__c demandSkid = new SKID__c(
                                Company__c = shl.Company__c,
                                Type__c = shl.Sales_Order_Line__c != null ? SkidService3.SKID_TYPE_SO_DEMAND : SkidService3.SKID_TYPE_TO_DEMAND,
                                Quantity__c = -qtyPicked,
                                Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                                Item__c = shl.Item__c,
                                Item__r = shl.Item__r,
                                Container_Item__c = shl.Item__c,
                                Container_Item__r = shl.Item__r,
                                Facility2__c = shl.Facility__c,
                                Facility2__r = shl.Facility__r,
                                Location__c = shl.Location__c,
                                Location__r = shl.Location__r,
                                Packaging_UOM__c = shl.Item__r.Stocking_UOM__c,
                                Packaging_UOM__r = shl.Item__r.Stocking_UOM__r,
                                Sales_Order_Line__c = shl.Sales_Order_Line__c,
                                Order_Line__c = shl.Order_Line__c,
                                Shipment_Line__c = shl.Id,
                                Shipment_Line__r = shl
                            );
                            skidsToPutaway.add(new SkidService3.SerialWrapper(demandSkid));

                            orderLine.put('Quantity_Allocated__c', (Decimal)orderLine.get('Quantity_Allocated__c') - (demandSkid.Quantity__c / sellingConvFactor));
                            orderLinesToUpdate.put(orderLine.Id, orderLine);
                        }
                    }
                }

                if (sw.skid.Quantity_To_Return__c > 0) {
                    UOM__c lowerUom;
                    for (Integer i = 0; i < pkgUoms.size(); i++) {
                        if (pkgUoms[i] == sw.skid.Packaging_UOM__c) {
                            lowerUom = uoms.get(pkgUoms[i - 1]);
                            break;
                        }
                    }

                    SKID__c lowerUomSkid = stockSkidTemplate.clone(false, true);
                    lowerUomSkid.Packaging_UOM__c = lowerUom.Id;
                    lowerUomSkid.Packaging_UOM__r = lowerUom;
                    if (lowerUomSkid.License_Plate_Number__c == null) {
                        lowerUomSkid.Container_Item__r = SkidService3.getContainerforItem(shl.Item__r, lowerUom);
                        lowerUomSkid.Container_Item__c = lowerUomSkid.Container_Item__r.Id;
                    }

                    List<String> lowerUomKey = SkidService3.generateKey(lowerUomSkid, SkidService3.attributes);
                    if (brokenQtys.containsKey(lowerUomKey) == false || sw.skid.Quantity_To_Return__c > brokenQtys.get(lowerUomKey)) {
                        Decimal breakConvFactor = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, lowerUom.Id, pkgUoms);
                        Decimal qtyToBreak = (KSE.subtractDecimals(sw.skid.Quantity_To_Return__c, brokenQtys.get(lowerUomKey)) / breakConvFactor).round(System.RoundingMode.CEILING);

                        SKID__c skidToBreak = stockSkidTemplate.clone(false, true);
                        skidToBreak.Quantity__c = -qtyToBreak;
                        skidsToPutaway.add(new SkidService3.SerialWrapper(skidToBreak));

                        SKID__c brokenSkid = lowerUomSkid.clone(false, true);
                        brokenSkid.Quantity__c = qtyToBreak * breakConvFactor;
                        skidsToPutaway.add(new SkidService3.SerialWrapper(brokenSkid));

                        Inventory_Transaction__c breakIt = SkidService3.createInventoryTransaction(shl.Item__r, shl, 'Break Package', brokenSkid.Quantity__c, skidToBreak, brokenSkid, SkidService3.attributes);
                        breakIt.Shipment_Line__c = null;
                        breakIt.To_SKID__r = brokenSkid;
                        itInfo.itList.add(breakIt);

                        brokenQtys.put(lowerUomKey, KSE.addQuantityToField(brokenQtys.get(lowerUomKey), brokenSkid.Quantity__c));
                    }

                    lowerUomSkid.Quantity__c = -sw.skid.Quantity_To_Return__c;
                    skidsToPutaway.add(new SkidService3.SerialWrapper(lowerUomSkid));

                    SKID__c pickSkid = pickSkidTemplate.clone(false, true);
                    pickSkid.Quantity__c = sw.skid.Quantity_To_Return__c;
                    pickSkid.Packaging_UOM__c = lowerUom.Id;
                    pickSkid.Packaging_UOM__r = lowerUom;
                    pickSkid.License_Plate_Number__c = null;
                    pickSkid.License_Plate_Number__r = null;
                    pickSkid.Container_Item__r = SkidService3.getContainerforItem(shl.Item__r, lowerUom);
                    pickSkid.Container_Item__c = pickSkid.Container_Item__r.Id;
                    skidsToPutaway.add(new SkidService3.SerialWrapper(pickSkid));

                    SKID__c planSkid = planSkidTemplate.clone(false, true);
                    planSkid.Quantity__c = -sw.skid.Quantity_To_Return__c;
                    planSkid.Packaging_UOM__c = lowerUom.Id;
                    planSkid.Packaging_UOM__r = lowerUom;
                    skidsToPutaway.add(new SkidService3.SerialWrapper(planSkid));

                    Inventory_Transaction__c it = SkidService3.createInventoryTransaction(shl.Item__r, orderLine, pickItType, pickSkid.Quantity__c, lowerUomSkid, pickSkid, SkidService3.attributes);
                    it.To_SKID__r = pickSkid;
                    itInfo.itList.add(it);

                    if (packLines != null) {
                        for (Integer i = 0; i < (pickSkid.Packaging_UOM__c != pkgUoms[0] ? it.Quantity__c.intValue() : 1); i++) {
                            Map<String, Object> packLine = new Map<String, Object>{ 'itemId' => shl.Item__c, 'Shipment_Line__c' => shl.Id, 'quantity' => pickSkid.Packaging_UOM__c != pkgUoms[0] ? sw.skid.Quantity_Required__c : it.Quantity__c };
                            if (pickSkid.License_Plate_Number__c != null) packLine.put('fromLPN', pickSkid.License_Plate_Number__r.Name);
                            packLines.add(packLine);
                        }
                    }

                    Decimal qtyPicked = pickSkid.Quantity__c * sw.skid.Quantity_Required__c;
                    shlToUpdate.Quantity_To_Pick__c -= qtyPicked;
                    shlToUpdate.Quantity_Picked__c += qtyPicked;

                    brokenQtys.put(lowerUomKey, brokenQtys.get(lowerUomKey) - sw.skid.Quantity_To_Return__c);
                }

                if (packLines != null && packLines.size() > 0) {
                    if (packMap.containsKey(sw.toskid.License_Plate_Number__r.Name) == false) packMap.put(sw.toskid.License_Plate_Number__r.Name, new Map<String, List<Map<String, Object>>>{ pickSkidTemplate.Bin__r.Name => packLines });
                    else if (packMap.get(sw.toskid.License_Plate_Number__r.Name).containsKey(pickSkidTemplate.Bin__r.Name) == false) packMap.get(sw.toskid.License_Plate_Number__r.Name).put(pickSkidTemplate.Bin__r.Name, packLines);
                    else packMap.get(sw.toskid.License_Plate_Number__r.Name).get(pickSkidTemplate.Bin__r.Name).addAll(packLines);
                }
            }

            if (itInfo.itList.size() > 0) itData.put(shl.Shipment__c, itInfo);

            if (shlToUpdate.Quantity_Picked__c != shl.Quantity_Picked__c) {
                shlsToUpdate.add(shlToUpdate);
                
                if (shlToUpdate.Quantity_Picked__c > 0 || shl.Quantity_Shipped__c > 0) {
                    shipmentToUpdate.Status__c = ShipmentService.SHIPMENT_STATUS_STAGED;
                    shipmentsToUpdate.put(shipment.Id, shipmentToUpdate);
                    shipmentIds.remove(shipment.Id);
                } else if (shipmentsToUpdate.containsKey(shipment.Id) == false && shipment.Status__c == ShipmentService.SHIPMENT_STATUS_STAGED) {
                    shipmentIds.add(shipment.Id);
                }
            }
        }

        Map<List<String>, SkidService3.SerialWrapper> putawaySkids = skidsToPutaway.size() > 0 ? SkidService3.putAwayService(skidsToPutaway, attributesForPutaway, null) : new Map<List<String>, SkidService3.SerialWrapper>();

        if (itData.size() > 0) {
            for (SkidService3.ParameterData itInfo:itData.values()) {
                for (Inventory_Transaction__c it:itInfo.itList) {
                    SKID__c fromSkid = putawaySkids.get(SkidService3.generateKey(it.From_SKID__r, attributesForPutaway)).skid;
                    it.From_SKID__c = fromSkid.Id;
                    it.From_SKID__r = fromSkid;

                    putawaySkids.put(SkidService3.generateKey(it, SkidService3.attributes), putawaySkids.get(SkidService3.generateKey(it.To_SKID__r, attributesForPutaway)));
                }
            }

            SkidService3.inventoryTransactionsForPutaway(itData, SkidService3.attributes, putawaySkids, new Map<String,String>{ 'transferofowner' => 'true', 'Undo transferofowner' => 'true', 'adjustFromSkidQuantity' => 'none' });
        }

        List<SKID__c> skidsToDelete = new List<SKID__c>();
        for (SkidService3.SerialWrapper sw:putawaySkids.values()) {
            if (sw.skid.Type__c == SkidService3.SKID_TYPE_PLANNED && sw.skid.Quantity__c == 0) skidsToDelete.add(sw.skid);
        }
        if (skidsToDelete.size() > 0) DML.deleteAsSystem(skidsToDelete);

        if (shlsToUpdate.size() > 0) DML.updateAsUser(shlsToUpdate);
        if (orderLinesToUpdate.size() > 0) DML.updateAsUser(orderLinesToUpdate.values());

        if (shipmentIds.size() > 0) {
            SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
            shipmentQuery.addField('Id');
            shipmentQuery.setWhereClause('Id IN :shipmentIds');

            SOQLUtil.ChildRelationship shlQuery = new SOQLUtil.ChildRelationship(shipmentQuery, 'Shipment_Lines__r');
            shlQuery.addFields(new Set<String>{ 'Id', 'Quantity_Picked__c', 'Quantity_Shipped__c' });
            shlQuery.setWhereClause('Id NOT IN :shlIds');
            shipmentQuery.addChildRelationship(shlQuery);

            for (Shipment__c shipment:Database.query(shipmentQuery.getQuery())) {
                Boolean hasQty = false;
                for (Shipment_Line__c shl:shipment.Shipment_Lines__r) {
                    if (shl.Quantity_Picked__c > 0 || shl.Quantity_Shipped__c > 0) {
                        hasQty = true;
                        break;
                    }
                }

                if (hasQty == false) {
                    shipment.Status__c = ShipmentService.SHIPMENT_STATUS_RELEASED;
                    shipmentsToUpdate.put(shipment.Id, shipment);
                }
            }
        }
        
        if (shipmentsToUpdate.size() > 0) DML.updateAsUser(shipmentsToUpdate.values());

        if (packMap.size() > 0) {
            for (String lpn:packMap.keySet()) {
                Map<String, List<Map<String, Object>>> packLine = packMap.get(lpn);
                for (String bin:packLine.keySet()) pack(lpn, bin, JSON.serialize(packLine.get(bin)));
            }
        }
    }

    public static void autoPick(List<Id> shlIds) {
        if (shlIds == null || shlIds.size() == 0) return;

        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Id' => '(\'' + String.join(shlIds, '\',\'') + '\')' }, 'pick'));
        Map<Id, LineWrapper> shlWrappers = new Map<Id, LineWrapper>();
        for (LineWrapper wrapper:getInventoryForPick(shipmentLines.values())) {
            Shipment_Line__c shl = shipmentLines.get(wrapper.line.Id);

            List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Input_Quantity__c > 0) {
                    sw.skid.Item__r = shl.Item__r;
                    swList.add(sw);
                }
            }

            if (swList.size() > 0) {
                if (shlWrappers.containsKey(shl.Id) == false) shlWrappers.put(shl.Id, new LineWrapper(shl.Shipment__r, shl, swList));
                else shlWrappers.get(shl.Id).serialWrappers.addAll(swList);
            }
        }

        if (shlWrappers.size() > 0) pick(shlWrappers.values());
    }


    /*
     * PACK SECTION
     */
    @future
    public static void pack(String toLPN, String bin, String packLines) {
    	ScannerService.packShipment pack = new ScannerService.packShipment();
        Action.Response resp = pack.execute(JSON.serialize(new Map<String, Object>{ 'toLPN' => toLPN, 'fromBin' => bin, 'inventory' => (List<Object>)JSON.deserializeUntyped(packLines) }));
        if (resp.success == false) throw new CustomException(resp.error.get('message'));
    }


    /*
     * SHIP SECTION
     */
    public static Map<Id, String> validateForShip(List<Shipment__c> shipments, Boolean shipMode) {
        Set<Id> shlWithCI = new Set<Id>();
        if (shipMode == false) {
            Set<Id> shlIds = new Set<Id>();
            for (Shipment__c shipment:shipments) {
                for (Shipment_Line__c shl:shipment.Shipment_Lines__r) shlIds.add(shl.Id);
            }

            SOQLUtil ciQuery = new SOQLUtil('Customer_Invoice_Sub_Line__c');
            ciQuery.addFields(new Set<String>{ 'Id', 'Fulfillment__r.Shipment_Line__c' });
            ciQuery.setWhereClause('Fulfillment__r.Shipment_Line__c in :shlIds and Customer_Invoice_Line__r.Customer_Invoice__r.Status__c != \'Cancelled\' and Customer_Invoice_Line__r.Customer_Invoice__r.Void__c = false');
            for (Customer_Invoice_Sub_Line__c ci:Database.query(ciQuery.getQuery())) shlWithCI.add(ci.Fulfillment__r.Shipment_Line__c);
        }
        
        Map<Id, String> errors = new Map<Id, String>();
        Map<Id, List<Id>> itemPackagingUOMCache = new Map<Id, List<Id>> ();
        for (Shipment__c shipment:shipments) {
            Boolean soShipment = false;
            for (Shipment_Line__c shl:shipment.Shipment_Lines__r) {
                
                if (shl.Sales_Order__c != null) {
                    soShipment = true;
                    if ( !itemPackagingUOMCache.containsKey(shl.Item__c)) {
                        List<Id> lstPkgUOM = (List<Id>) JSON.deserialize(shl.Item__r.Packaging_UOM__c, List<Id>.class);
                        itemPackagingUOMCache.put(shl.Item__c, lstPkgUOM);
                    }

                    Decimal convFactor = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c,shl.Sales_Order_Line__r.Selling_UOM__c, shl.Item__r.Stocking_UOM__c, itemPackagingUOMCache.get(shl.Item__c ) );

                    if (shl.Sales_Order__r.Hold__c == true) {
                        errors.put(shipment.Id, shl.Name + ': ' + Label.SH_SO_On_Hold_At_Ship);
                    } else if (shl.Sales_Order__r.Released_to_3PL__c == true) {
                        errors.put(shipment.Id, shl.Name + ': ' + Label.SH_SO_On_Hold_At_Ship);
                    } else if (shipMode == true && shl.Item__r.Non_Inventory__c == false && shl.Sales_Order__r.Ship_Complete__c == true && (shl.Sales_Order_Line__r.Quantity_Ordered__c * convFactor).setScale(6,System.RoundingMode.HALF_UP) != shl.Quantity_Picked__c) {
                        errors.put(shipment.Id, shl.Name + ': ' + Label.Partial_shipment_not_allowed_on_ship_complete);
                    } else if (shlWithCI.contains(shl.Id)) {
                        errors.put(shipment.Id, shl.Name + ': ' + Label.Unable_to_undo_ship_an_invoiced_line);
                    }
                }
            }

            if (soShipment) {
                if (shipment.Customer__r.Top_Parent_Customer__r.Status__c != 'Approved') {
                    errors.put(shipment.Id, shipment.Name + ': ' + Label.Top_Parent_Customer_not_status_Approved);
                }
            }
        }
        
        return errors;
    }

    public static List<LineWrapper> getLinesForShip(Set<Id> shipmentIds, Boolean shipMode) {
        List<String> attributes = SkidService3.attributesForPutaway();
		
        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
        shlQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Extended_Cost__c', 'Facility__c', 'Item__c', 'Location__c', 'Order__c', 'Order_Line__c',
            'Quantity_Allocated__c', 'Quantity_From_Stock__c', 'Quantity_Picked__c', 'Quantity_Planned__c', 'Quantity_Shipped__c', 'Quantity_To_Pick__c',
            'Sales_Order__c', 'Sales_Order_Line__c', 'Shipment__c', 'Shipment__r.Date_Shipped__c','Shipment__r.Company__c','Shipment__r.Company__r.Serial_Control__c',
                'Shipment__r.Status__c', 'Shipment__r.Transaction_Date__c','Shipment__r.Customer__r.Top_Parent_Customer__r.Status__c',    

            'Location__r.Bin_Tracked__c',
            'Facility__r.Facility_Identifier__c',

            'Product__r.Item__c', 'Product__r.Item__r.Item_Attribute__c', 'Product__r.Item__r.Non_Inventory__c', 'Product__r.Item__r.Stocking_UOM__c',
            'Product__r.Item__r.Track_Install_Base__c', 'Product__r.Item__r.Packaging_UOM__c', 'Item__r.Packaging_UOM__c','Item__r.Container__c',
            'Item__c', 'Item__r.Item_Attribute__c', 'Item__r.Non_Inventory__c', 'Item__r.Stocking_UOM__c', 'Item__r.Track_Install_Base__c',

            'Order_Line__r.Deliver_To_Facility__c', 'Order_Line__r.Deliver_To_Location__c', 'Order_Line__r.Quantity_Allocated__c', 'Order_Line__r.Quantity_Shipped__c',
            'Order_Line__r.Receiving_Company__c', 'Order_Line__r.Receiving_Item__c',  'Order_Line__r.Receiving_Item__r.Packaging_UOM__c',  'Order_Line__r.Receiving_Item__r.Stocking_UOM__c',
            'Order_Line__r.Deliver_To_Facility__r.Facility_Identifier__c','Order_Line__r.Ship_From_Facility__r.Facility_Identifier__c',

            'Sales_Order_Line__r.Parent_Sales_Order_Line__c', 'Sales_Order_Line__r.Quantity_Allocated__c', 'Sales_Order_Line__r.Quantity_Shipped__c', 'Sales_Order_Line__r.Quantity_Planned__c', 'Sales_Order_Line__r.Selling_UOM__c',

            'Sales_Order_Line__r.Customer_Site__c', 'Sales_Order__r.Ship_To__c', 'Sales_Order__r.Ship_To__r.Track_Install_Base__c'
        });
        shlQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
        shlQuery.addFields('ConfirmShip');

        String whereClause = 'Shipment__c IN :shipmentIds ';
        if (shipMode) whereClause += 'AND ((Item__r.Non_Inventory__c = false AND Quantity_Picked__c > 0) OR Item__r.Non_Inventory__c = true) ';
        else whereClause += 'AND Quantity_Shipped__c > 0 ';
        shlQuery.setWhereClause(whereClause);

        List<Shipment_Line__c> shipmentLines = Database.query(shlQuery.getQuery());

        Map<Id, Map<List<String>, SKID__c>> skidMap = new Map<Id, Map<List<String>, SKID__c>>();
        Map<List<String>, List<Inventory_Transaction__c>> itMap = new Map<List<String>, List<Inventory_Transaction__c>>();
        Map<List<String>, Map<Id, Serial__c>> serialMap = new Map<List<String>, Map<Id, Serial__c>>();
        if (shipMode) {
            Map<Id, SKID__c> skids = new Map<Id, SKID__c>((List<SKID__c>)Database.query(SkidService3.getSkidQuery(new Map<String, String>{ 'WHERE' => 'Shipment_Line__c IN :shipmentLines AND Type__c = \'' + SkidService3.SKID_TYPE_LOCATION + '\'' })));
            Map<Id, List<String>> skidKeys = new Map<Id, List<String>>();
            for (SKID__c skid:skids.values()) {
                List<String> skidKey = SkidService3.generateKey(skid, attributes);
                if (!skidMap.containsKey(skid.Shipment_Line__c)) skidMap.put(skid.Shipment_Line__c, new Map<List<String>, SKID__c>{ skidKey => skid });
                else skidMap.get(skid.Shipment_Line__c).put(skidKey, skid);
                
                skidKeys.put(skid.Id, skidKey);
            }

            if (skids != null && skids.size() > 0) {
                SOQLUtil serialQuery = new SOQLUtil('Serial__c');
                serialQuery.addFields(new Set<String>{ 'Id', 'Name', 'SKID__c' });
                serialQuery.addFields(new Set<String>(SkidService3.serialAttributes));
                serialQuery.addFields('Serial');
                serialQuery.setWhereClause('SKID__c IN (\'' + String.join(new List<Id>(skids.keySet()), '\',\'') + '\')');

                for (Serial__c serial:Database.query(serialQuery.getQuery())) {
                    List<String> skidKey = skidKeys.get(serial.SKID__c);
                    if (!serialMap.containsKey(skidKey)) serialMap.put(skidKey, new Map<Id, Serial__c>{ serial.Id => serial });
                    else serialMap.get(skidKey).put(serial.Id, serial);
                }
            }
        } else {
            Map<List<String>, Decimal> InTransitQuantityByKey = getInTransitQtyByKey(shipmentLines,attributes);

            Map<Boolean,Set<String>> shipmentLinesByUndoValidity = new Map<Boolean,Set<String>>{false => new Set<String>{}};// stores shipmentlines that fails qty validation.

            Set<String> exceptionSet = new Set<String>();
            Set<String> itTypes = new Set<String>{ 'Sales Order Shipment', 'Sales Order Undo Shipment', 'RMA Repair Shipment', 'RMA Repair Undo Shipment', 'Transfer Order Shipment', 'Transfer Order Undo Shipment' };
            for (Inventory_Transaction__c it:Database.query(SkidService3.getItQuery(new Map<String, String>{ 'WHERE' => 'Shipment_Line__c IN :shipmentLines AND Type__c IN :itTypes', 'ORDER' => 'CreatedDate ASC', 'SERIALS' => 'true' }))) {
                String dir = it.Type__c == 'Sales Order Shipment' || it.Type__c == 'RMA Repair Shipment' || it.Type__c == 'Transfer Order Shipment' ? 'From' : 'To';

                SKID__c skid = new SKID__c(
                    Company__c = it.Company__c,
                    Type__c = SkidService3.SKID_TYPE_LOCATION,
                    Quantity__c = it.Type__c == 'Sales Order Shipment' || it.Type__c == 'RMA Repair Shipment' || it.Type__c == 'Transfer Order Shipment' ? it.Quantity__c : -it.Quantity__c,
                    Quantity_Stocking_UOM__c = it.Type__c == 'Sales Order Shipment' || it.Type__c == 'RMA Repair Shipment' || it.Type__c == 'Transfer Order Shipment' ? it.Quantity_Stocking_UOM__c : -it.Quantity_Stocking_UOM__c,
                    Stocking_UOM__c = it.Stocking_UOM__c,
                    Mixed_Palletized__c = it.Mixed_Palletized__c
                );
                if (it.Lot__c != null) skid.Lot_Number__c = it.Lot__r.Name;

                for (String attr:attributes) {
                    if ((attr == 'Customer__c'  && it.Type__c == 'Sales Order Shipment') || attr == 'Sales_Order_Line__c') continue;
                    
                    Boolean isLookup = skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference;

                    String itAttr = attr;
                    if (attr == 'Facility2__c') itAttr = dir + '_Facility__c';
                    else if (attr == 'Location__c') itAttr = dir + '_Location__c';
                    else if (attr == 'Bin__c' && dir == 'From') itAttr = 'From_Bin__c';
                    else if (attr == 'Packaging_UOM__c' && dir == 'From') itAttr = 'From_Packaging_UOM__c';
                    else if (attr == 'Lot__c' && dir == 'From') itAttr = 'From_Lot__c';

                    skid.put(attr, it.get(itAttr));
                    if (isLookup) {
                        attr = attr.replace('__c', '__r');
                        itAttr = itAttr.replace('__c', '__r');
                        skid.putSObject(attr, it.getSObject(itAttr));
                    }
                }

                if (it.Type__c == 'Transfer Order Shipment'
                            && it.From_Packaging_UOM__r.Package_Class__r.Level__c > it.Packaging_UOM__r.Package_Class__r.Level__c ) {
                    skid.Packaging_UOM__c = it.Packaging_UOM__c;
                    skid.Packaging_UOM__r = it.Packaging_UOM__r;
                } else if (it.Type__c == 'Transfer Order Undo Shipment'
                        && it.From_Packaging_UOM__r.Package_Class__r.Level__c < it.Packaging_UOM__r.Package_Class__r.Level__c ) {
                    List<Id> pkgUoms = (List<Id>) JSON.deserialize(it.Item__r.Packaging_UOM__c, List<Id>.class);
                    Decimal toConvFactor = KSE.getConversionFactor(it.Item__c, it.To_Facility__r.Facility_Identifier__c, it.Packaging_UOM__c, it.From_Packaging_UOM__c, pkgUoms);
                    skid.Quantity__c = skid.Quantity__c * toConvFactor;
                    skid.Packaging_UOM__c = it.From_Packaging_UOM__c;
                    skid.Packaging_UOM__r = it.From_Packaging_UOM__r;
                }

                List<String> skidKey = SkidService3.generateKey(skid, attributes);

                if (!skidMap.containsKey(it.Shipment_Line__c)) {
                    skidMap.put(it.Shipment_Line__c, new Map<List<String>, SKID__c>{ skidKey => skid });
                } else if (!skidMap.get(it.Shipment_Line__c).containsKey(skidKey)) {
                    skidMap.get(it.Shipment_Line__c).put(skidKey, skid);
                } else {
                    SKID__c sk = skidMap.get(it.Shipment_Line__c).get(skidKey);
                    sk.Quantity__c += skid.Quantity__c;
                    sk.Quantity_Stocking_UOM__c += skid.Quantity_Stocking_UOM__c;
                }
                
                if ((it.Type__c == 'Sales Order Shipment' || it.Type__c == 'RMA Repair Shipment' || it.Type__c == 'Transfer Order Shipment') && it.Reversed__c == false)  {   //Kit-To-Order flow only generates invoice ready fulfillments for parent SOL
                    Inventory_Transaction__c itClone = new Inventory_Transaction__c(Id = it.Id, Transaction_Date__c = it.Transaction_Date__c, Quantity__c = it.Quantity__c, Receipt_Line__c = it.Receipt_Line__c, Packaging_UOM__c=it.Packaging_UOM__c, From_Packaging_UOM__c=it.From_Packaging_UOM__c);
                    if (!itMap.containsKey(skidKey)) itMap.put(skidKey, new List<Inventory_Transaction__c>{ itClone });
                    else itMap.get(skidKey).add(itClone);
                }

                for (Serial_Transaction__c st:it.Serial_Transactions__r) {
                    if (serialMap.containsKey(skidKey)) {
                        if (it.Type__c == 'Sales Order Shipment' || it.Type__c == 'RMA Repair Shipment' || it.Type__c == 'Transfer Order Shipment') serialMap.get(skidKey).put(st.Serial__c, st.Serial__r);
                        else serialMap.get(skidKey).remove(st.Serial__c);
                    } else if (it.Type__c == 'Sales Order Shipment' || it.Type__c == 'RMA Repair Shipment' || it.Type__c == 'Transfer Order Shipment') {
                        serialMap.put(skidKey, new Map<Id, Serial__c>{ st.Serial__c => st.Serial__r });
                    }
                }

                SKID__c skidForValidation = skid.clone(true,true);
                skidForValidation.put('Order_Line__c', it.get('Order_Line__c'));
                List<String> customAttributes  = getCustomAttributesForUndoShipmentValidation(attributes);
                List<String> skidKey_customAttributes = SkidService3.generateKey(skidForValidation, customAttributes);
                if(it.Type__c == 'Transfer Order Shipment'){
                    //At this moment, In shipment delivery UI,  qty field is uneditable. Qty can only be shipped and undone in its entirety.
                    if(InTransitQuantityByKey.containsKey(skidKey_customAttributes)){
                        Decimal InTransitQty = InTransitQuantityByKey.get(skidKey_customAttributes);
                        if(InTransitQty<it.Quantity__c){
                            shipmentLinesByUndoValidity.get(false).add(it.Shipment_Line__r.Name);
                        }
                    }
                    else {
                        shipmentLinesByUndoValidity.get(false).add(it.Shipment_Line__r.Name);
                    }
                }
                else if (it.Type__c == 'Transfer Order Undo Shipment'){
                    //Undoe shipment Delivery.
                    shipmentLinesByUndoValidity.get( false ).remove(it.Shipment_Line__r.Name);

                }
            }
            if(shipmentLinesByUndoValidity.get(false).size()>0){
                // limit the error message to 10 shipment lines
                Integer numOfShlsToAccrueForError = 10;
                String ShipmentLineString = String.join(new List<String>(shipmentLinesByUndoValidity.get(false)),',');
                ShipmentLineString+=' : ';
                if(shipmentLinesByUndoValidity.get(false).size()>numOfShlsToAccrueForError){
                     ShipmentLineString='';
                }
                ShipmentLineString+= ' There is not enough in-transit inventory to undo ship.';
                Throw new CustomException(ShipmentLineString);
            }

         }

        List<LineWrapper> shlWrappers = new List<LineWrapper>();
        Map<Id, List<Id>> itemPackagingUOMCache = new Map<Id, List<Id>>();
        for (Shipment_Line__c shl:shipmentLines) {
            if ( !itemPackagingUOMCache.containsKey(shl.Item__c)) {
                List<Id> lstPkgUOM = (List<Id>) JSON.deserialize(shl.Item__r.Packaging_UOM__c, List<Id>.class);
                itemPackagingUOMCache.put(shl.Item__c, lstPkgUOM);
            }
            Decimal convFactor = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c,shl.Sales_Order_Line__r.Selling_UOM__c, shl.Item__r.Stocking_UOM__c, itemPackagingUOMCache.get(shl.Item__c) );

            shl.Quantity_Planned__c *= convFactor;
            shl.Quantity_Allocated__c *= convFactor;
            shl.Quantity_Shipped__c *= convFactor;

            LineWrapper shlWrapper = new LineWrapper(shl.Shipment__r, shl, new List<SkidService3.SerialWrapper>());

            List<String> skidFields;
            if (shl.Item__r.Non_Inventory__c == true) {
                skidFields = new List<String>{ 'Quantity__c' };

                //Quantity Stocking UOM = 0 will ignore non inventory items when calculating quantity picked vs picked skid quantity
                shlWrapper.serialWrappers.add(new SkidService3.SerialWrapper(new SKID__c(Quantity__c = shipMode ? shl.Quantity_Planned__c - shl.Quantity_Shipped__c : shl.Quantity_Shipped__c, Quantity_Stocking_UOM__c = 0), new List<Serial__c>()));
            } else {
                skidFields = new List<String>{ 'Location__c' };
                if (shl.Location__r.Bin_Tracked__c == true) skidFields.add('Bin__c');
                skidFields.addAll(new List<String>{ 'Customer__c', 'Container_Item__c', 'Packaging_UOM__c', 'License_Plate_Number__c' });
                for (String attr:SkidService3.attributeFields) {
                    if (attr != 'License_Plate_Number__c' && shl.Item__r.Item_Attribute__c != null && (Boolean)shl.Item__r.Item_Attribute__r.get(attr) == true) {
                        if (attr == 'Lot_Number__c') skidFields.add('Lot__c');
                        else skidFields.add(attr);
                    }
                }
                skidFields.addAll(new List<String>{ 'Quantity__c', 'Quantity_Stocking_UOM__c' });

                if (skidMap.containsKey(shl.Id)) {
                    Map<List<String>, SKID__c> skids = skidMap.get(shl.Id);
                    for (List<String> skidKey:skids.keySet()) {
                        SKID__c skid = skids.get(skidKey);
                        if (skid.Quantity__c == 0) continue;

                        SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(skid, serialMap.containsKey(skidKey) ? serialMap.get(skidKey).values() : new List<Serial__c>());
                        if (itMap.containsKey(skidKey)) sw.temporaryValueHolder = JSON.serialize(itMap.get(skidKey));
                        shlWrapper.serialWrappers.add(sw);
                    }
                }
            }

            shlWrapper.skidFields = FieldInfo.fetchJsonFieldInfos('SKID__c', skidFields, true);
            for (FieldInfo fi:shlWrapper.skidFields) {
                if (fi.field == 'Quantity__c') {
                    if (shipMode) {
                        fi.title = 'Quantity To Ship';
                        if (shl.Item__r.Non_Inventory__c == true) fi.editable = true;
                    } else {
                        fi.title = 'Quantity Shipped';
                    }
                } else if (fi.field == 'Quantity_Stocking_UOM__c') {
                    if (shipMode) fi.title = 'Quantity To Ship (' + shl.Item__r.Stocking_UOM__r.Name + ')';
                    else fi.title = 'Quantity Shipped (' + shl.Item__r.Stocking_UOM__r.Name + ')';
                }
                fi.field = 'skid.' + fi.field;
            }

            if (shlWrapper.serialWrappers.size() > 0) shlWrappers.add(shlWrapper);
        }

        return shlWrappers;
    }

    public static Map<List<String>, Decimal> getInTransitQtyByKey(List<Shipment_Line__c> ShipmentLines, List<String> attributes){
        String Query = SkidService3.getSkidQuery(new Map<String, String>{'WHERE'=>' Order_Line__c In ( select Order_Line__c from Shipment_Line__c where Id  IN :ShipmentLines) and Type__c In (\''+SkidService3.SKID_TYPE_INTRANSIT+'\')'});
        List<String> customAttributes = getCustomAttributesForUndoShipmentValidation(attributes);

        // validate if the intransit inventory matches what has been shipped.
        Map<List<String>, Decimal> InTransitQuantityByKey = new Map<List<String>,Decimal>();
        for(SKID__c In_TransSkid :(List<SKID__c>)Database.query(Query))
        {
            Decimal totalIntransitMatchingQty =0;
            SKID__c skidclone = In_TransSkid.clone(true,true);
            List<String> skidKey1 = SkidService3.generateKey(skidclone, customAttributes);
            totalIntransitMatchingQty = skidclone.Quantity__c;
            if(InTransitQuantityByKey.containsKey(skidKey1)){
                totalIntransitMatchingQty+=InTransitQuantityByKey.get(skidKey1);
                InTransitQuantityByKey.put(skidKey1,totalIntransitMatchingQty);
            }
            else{
                InTransitQuantityByKey.put(skidKey1,totalIntransitMatchingQty);
            }
        }

        return InTransitQuantityByKey;
    }
    public static List<String> getCustomAttributesForUndoShipmentValidation(List<String> attributes){
        List<String> customAttributes = attributes.clone();
        Set<String> customAttributesSet = new Set<String>(customAttributes);
        customAttributesSet.removeAll(new Set<String>{'Facility2__c','Location__c','Bin__c','Shipment_Line__c'});
        customAttributes = new List<String>(customAttributesSet);

        // donot match inventory from different transfer orders.
        customAttributes.add('Order_Line__c');

        return customAttributes;
    }
    public static void checkShipErrors(List<LineWrapper> shlWrappers, Boolean shipMode) {
        Set<String> serialKeys = new Set<String>();
        Boolean recordSerialsAtConfirmShipment = false;
        for (LineWrapper shlWrapper:shlWrappers) {
            Shipment__c shipment = (Shipment__c)shlWrapper.header;
            Shipment_Line__c shl = (Shipment_Line__c)shlWrapper.line;
            
            if (shipMode == true && shipment.Date_Shipped__c == null) throw new CustomException(shipment.Name + ': ' + Label.Missing_Shipment_Date);
			if ((String)shipment.getSObject('Company__r').get('Serial_Control__c') == 'At shipment only')
				recordSerialsAtConfirmShipment = true;
            for (SkidService3.SerialWrapper sw:shlWrapper.serialWrappers) {
                if (shipMode == true) {
                    if (shl.Item__r.Item_Attribute__c != null && shl.Item__r.Item_Attribute__r.Expiration_Date__c == true && sw.skid.Expiration_Date__c < shipment.Date_Shipped__c.date()) {
                        throw new CustomException(shl.Name + ': ' + Label.Cant_ship_expired_item);
                    }
                }
				if(sw.skid.Item__r.Item_Attribute__c != null && sw.skid.Item__r.Item_Attribute__r.Serial_Number__c == true && recordSerialsAtConfirmShipment && sw.serialList.size() == 0){
					throw new CustomException(shl.Name + ':'+Label.Number_Of_Serials_Not_Matching_Shipped_Quantity);
				}
                if (sw.serialList.size() > 0) {
                    for (Serial__c serial:sw.serialList) {
                        String uniqueKey = shipment.Company__c + '-' + shl.Item__c + '-' + serial.Name;
                        if (!serialKeys.contains(uniqueKey)) serialKeys.add(uniqueKey);
                        else throw new CustomException(serial.Name + ': ' + Label.Serial_Number_Specified_More_than_Once);
                    }

                    if (sw.skid.Quantity__c != sw.serialList.size()) throw new CustomException(shl.Name + ': Number of serials (' + sw.serialList.size() + ') does not match quantity (' + sw.skid.Quantity__c + ')');
                }
            }
        }
    }
	public static map<Id,Shipment__c> confirmShipMap = new map<Id,Shipment__c>();
    public static void confirmShip(List<LineWrapper> shlWrappers) {
        if (shlWrappers == null || shlWrappers.size() == 0) return;

        checkShipErrors(shlWrappers, true);

        List<String> attributes = SkidService3.attributesForPutaway();
        attributes.add('Sales_Order_Line__c');
        attributes.add('Customer__c');
        attributes.add('Order_Line__c');

        List<String> attributesForPutaway = attributes.clone();
        attributesForPutaway.add('Type__c');

        Boolean mixedSerials = false;
        Set<Id> facilityIds = new Set<Id>();
        Set<Id> itemIds = new Set<Id>();
        Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();
        Set<Id> uomIds = new Set<Id>();
        for (LineWrapper shlWrapper:shlWrappers) {
            Shipment__c shipment = (Shipment__c)shlWrapper.header;
            Shipment_Line__c shl = (Shipment_Line__c)shlWrapper.line;

            if (shipment.Company__r.Serial_Control__c == SkidService3.AT_SHIPMENT) mixedSerials = true;
            facilityIds.add(shl.Facility__c);

            if (itemIds.contains(shl.Item__c) == false) {
                itemIds.add(shl.Item__c);
                List<Id> uomList = (List<Id>)JSON.deserialize(shl.Item__r.Packaging_UOM__c, List<Id>.Class);
                packagingUoms.put(shl.Item__c, uomList);
                uomIds.addAll(uomList);
            }
        }

        Map<Id, UOM__c> uoms = getUoms(uomIds);

        Map<Id, Shipment__c> shipmentsToUpdate = new Map<Id, Shipment__c>();
        List<Shipment_Line__c> shlsToUpdate = new List<Shipment_Line__c>();
        Map<Id, sObject> orderLinesToUpdate = new Map<Id, sObject>();
        Set<Id> parentSoLines = new Set<Id>();
        Map<Id, Shipment_Line__c> solShlMap = new Map<Id, Shipment_Line__c>();
        Map<Id, SkidService3.ParameterData> itData = new Map<Id, SkidService3.ParameterData>();
        List<SkidService3.SerialWrapper> skidsToPutaway = new List<SkidService3.SerialWrapper>();
        Map<List<String>, SkidService3.SerialWrapper> putawaySkids = new Map<List<String>, SkidService3.SerialWrapper>();
        for (LineWrapper wrapper:shlWrappers) {
            Shipment__c shipment = (Shipment__c)wrapper.header;
            Shipment_Line__c shl = (Shipment_Line__c)wrapper.line;
            List<Id> pkgUoms = packagingUoms.get(shl.Item__c);

            if (!shipmentsToUpdate.containsKey(shipment.Id)) {
                shipment.Status__c = ShipmentService.SHIPMENT_STATUS_CONFIRMED;
                shipment.Locked__c = true;
                shipment.Transaction_Date__c = shipment.Transaction_Date__c == null ? System.now() : shipment.Transaction_Date__c;
                shipmentsToUpdate.put(shipment.Id,shipment);
            }
			if(!confirmShipMap.containskey(shipment.Id)){
				confirmShipMap.put(shipment.Id,shipment);
			}
            Shipment_Line__c shlToUpdate = new Shipment_Line__c(Id = shl.Id, Quantity_From_Stock__c = shl.Quantity_From_Stock__c, Quantity_Picked__c = shl.Quantity_Picked__c, Quantity_Shipped__c = shl.Quantity_Shipped__c / wrapper.convFactor);
            
            Id orderLineId = shl.Sales_Order_Line__c != null ? shl.Sales_Order_Line__c : shl.Order_Line__c;
            sObject orderLineToUpdate;
            if (orderLinesToUpdate.containsKey(orderLineId)) {
                orderLineToUpdate = orderLinesToUpdate.get(orderLineId);
            } else {
                if (shl.Sales_Order_Line__c != null) orderLineToUpdate = new Sales_Order_Line__c(Id = orderLineId, Quantity_Allocated__c = shl.Sales_Order_Line__r.Quantity_Allocated__c, Quantity_Shipped__c = shl.Sales_Order_Line__r.Quantity_Shipped__c);
                else orderLineToUpdate = new Order_Line__c(Id = orderLineId, Quantity_Allocated__c = shl.Order_Line__r.Quantity_Allocated__c, Quantity_Shipped__c = shl.Order_Line__r.Quantity_Shipped__c);
                
                orderLinesToUpdate.put(orderLineId, orderLineToUpdate);
            }

            if (shl.Sales_Order_Line__c != null && shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c != null) {
                parentSoLines.add(shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c);
                solShlMap.put(shl.Sales_Order_Line__c, shl);
            }

            SkidService3.ParameterData itInfo = itData.get(shipment.Id);
            if (itInfo == null) {
                itInfo = new SkidService3.ParameterData();
                itInfo.sourceDoc = new Shipment__c(Company__c = shipment.Company__c);
                itData.put(shipment.Id, itInfo);
            }

            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (shl.Item__r.Non_Inventory__c == false) {
                    Decimal pkgToStock = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, shl.Item__r.Stocking_UOM__c, pkgUoms);
                    Decimal pkgToSell = pkgToStock / wrapper.convFactor;

                    SKID__c pickedSkid = new SKID__c(
                        Company__c = shipment.Company__c,
                        Type__c = SkidService3.SKID_TYPE_LOCATION,
                        Quantity__c = -sw.skid.Quantity__c,
                        Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                        Mixed_Palletized__c = sw.skid.Mixed_Palletized__c
                    );
                    for (String attr:attributes) {
                        if (attr == 'Lot__c') pickedSkid.Lot_Number__c = sw.skid.Lot_Number__c;
                        pickedSkid.put(attr, sw.skid.get(attr));
                        if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference) {
                            String refAttr = attr.replace('__c', '__r');
                            pickedSkid.putSObject(refAttr, sw.skid.getSObject(refAttr));
                        }
                    }
                    skidsToPutaway.add(new SkidService3.SerialWrapper(pickedSkid, new List<Serial__c>()));

                    Decimal itQuantity;
                    SKID__c toSkid;
                    if (shl.Order_Line__c != null) {
                        toSkid = new SKID__c(
                            Company__c = shl.Order_Line__r.Receiving_Company__c,
                            Type__c = SkidService3.SKID_TYPE_INTRANSIT,
                            Quantity__c = sw.skid.Quantity__c,
                            Stocking_UOM__c = shl.Order_Line__r.Receiving_Item__r.Stocking_UOM__c,
                            Item__c = shl.Order_Line__r.Receiving_Item__c,
                            Item__r = shl.Order_Line__r.Receiving_Item__r,
                            Facility2__c = shl.Order_Line__r.Deliver_To_Facility__c,
                            Facility2__r = shl.Order_Line__r.Deliver_To_Facility__r,
                            Location__c = shl.Order_Line__r.Deliver_To_Location__c,
                            Location__r = shl.Order_Line__r.Deliver_To_Location__r,
                            Mixed_Palletized__c = sw.skid.Mixed_Palletized__c,
                            Order_Line__c = shl.Order_Line__c,
                            Order_Line__r = shl.Order_Line__r
                        );
                        for (String attr:attributes) {
                            if (attr != 'Item__c' && attr != 'Facility2__c' && attr != 'Location__c' && attr != 'Bin__c' && attr != 'Shipment_Line__c' && attr != 'Order_Line__c') {
                                if (attr == 'Lot__c') toSkid.Lot_Number__c = sw.skid.Lot_Number__c;
                                toSkid.put(attr, sw.skid.get(attr));
                                if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference) {
                                    String refAttr = attr.replace('__c', '__r');
                                    toSkid.putSObject(refAttr, sw.skid.getSObject(refAttr));
                                }
                            }
                        }

                        if (pkgUoms.size() > 1 && pkgUoms[pkgUoms.size() - 1] == sw.skid.Packaging_UOM__c) {
                            Id lowerUom = pkgUoms[pkgUoms.size() - 2];
                            Decimal convFactorShip = KSE.getConversionFactor(shl.Item__c, shl.Order_Line__r.Ship_From_Facility__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, lowerUom, pkgUoms);
                            Decimal convFactorReceive = KSE.getConversionFactor(shl.Order_Line__r.Receiving_Item__c, shl.Order_Line__r.Deliver_To_Facility__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, lowerUom, pkgUoms);

                            if (convFactorShip < convFactorReceive) {
                                toSkid.Quantity__c = sw.skid.Quantity__c * convFactorShip;
                                toSkid.Packaging_UOM__c = lowerUom;
                                toSkid.Packaging_UOM__r = uoms.get(lowerUom);
                            }
                        }

                        itQuantity = toSkid.Quantity__c;
                        if (sw.skid.Container_Item__c == sw.skid.Item__c) toSkid.Container_Item__c = toSkid.Item__c;
                        skidsToPutaway.add(new SkidService3.SerialWrapper(toSkid, sw.serialList));

                        skidsToPutaway.add(new SkidService3.SerialWrapper(new SKID__c(
                            Company__c = shl.Order_Line__r.Receiving_Company__c,
                            Type__c = SkidService3.SKID_TYPE_TO_SUPPLY,
                            Quantity__c = -sw.skid.Quantity__c * KSE.getConversionFactor(shl.Order_Line__r.Receiving_Item__c, shl.Order_Line__r.Deliver_To_Facility__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, shl.Order_Line__r.Receiving_Item__r.Stocking_UOM__c, pkgUoms),
                            Stocking_UOM__c = shl.Order_Line__r.Receiving_Item__r.Stocking_UOM__c,
                            Item__c = shl.Order_Line__r.Receiving_Item__c,
                            Item__r = shl.Order_Line__r.Receiving_Item__r,
                            Packaging_UOM__c = shl.Order_Line__r.Receiving_Item__r.Stocking_UOM__c,
                            Packaging_UOM__r = uoms.get(shl.Order_Line__r.Receiving_Item__r.Stocking_UOM__c),
                            Facility2__c = shl.Order_Line__r.Deliver_To_Facility__c,
                            Facility2__r = shl.Order_Line__r.Deliver_To_Facility__r,
                            Location__c = shl.Order_Line__r.Deliver_To_Location__c,
                            Location__r = shl.Order_Line__r.Deliver_To_Location__r,
                            Container_Item__c = shl.Order_Line__r.Receiving_Item__c,
                            Container_Item__r = shl.Order_Line__r.Receiving_Item__r,
                            Order_Line__c = shl.Order_Line__c
                        )));
                    } else if (shl.Item__r.Track_Install_Base__c == true && shl.Sales_Order__r.Ship_To__r.Track_Install_Base__c == true) {
                        itQuantity = sw.skid.Quantity__c;
                        toSkid = new SKID__c(
                            Company__c = shipment.Company__c,
                            Type__c = SkidService3.SKID_TYPE_INSTALLBASE,
                            Quantity__c = sw.skid.Quantity__c,
                            Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                            Customer__c = shl.Sales_Order_Line__r.Customer_Site__c != null ? shl.Sales_Order_Line__r.Customer_Site__c : shl.Sales_Order__r.Ship_To__c,
                            Sales_Order_Line__c = shl.Sales_Order_Line__c
                        );
                        for (String attr:attributes) {
                            if (attr != 'Facility2__c' && attr != 'Location__c' && attr != 'Bin__c' && attr != 'Shipment_Line__c' && attr != 'Customer__c' && attr != 'Sales_Order_Line__c') {
                                if (attr == 'Lot__c') toSkid.Lot_Number__c = sw.skid.Lot_Number__c;
                                toSkid.put(attr, sw.skid.get(attr));
                                if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference) {
                                    String refAttr = attr.replace('__c', '__r');
                                    toSkid.putSObject(refAttr, sw.skid.getSObject(refAttr));
                                }
                            }
                        }
                        skidsToPutaway.add(new SkidService3.SerialWrapper(toSkid, sw.serialList));
                    } else {
                        itQuantity = sw.skid.Quantity__c;
                        toSkid = new SKID__c(Sales_Order_Line__c = shl.Sales_Order_Line__c);
                        toSkid.Facility2__c = shl.Facility__c;
                        toSkid.Facility2__r =shl.Facility__r;
                        for (String attr:attributes) {
                            if (attr != 'Facility2__c' && attr != 'Location__c' && attr != 'Bin__c' && attr != 'Sales_Order_Line__c') {
                                if (attr == 'Lot__c') toSkid.Lot_Number__c = sw.skid.Lot_Number__c;
                                toSkid.put(attr, sw.skid.get(attr));
                            }
                        }
                    }

                    Inventory_Transaction__c it = SkidService3.createInventoryTransaction(shl.Item__r, shl, pickedSkid.Customer__c != null ? 'RMA Repair Shipment' : (shl.Sales_Order_Line__c != null ? 'Sales Order Shipment' : 'Transfer Order Shipment'), itQuantity, pickedSkid, toSkid, attributes);
                    it.Purchase_Order_Line__c = toSkid.Purchase_Order_Line__c;
                    it.To_SKID__r = toSkid;
                    it.Mixed_Palletized__c = sw.skid.Mixed_Palletized__c;
                    it.Transaction_Date__c = shipment.Date_Shipped__c;
                    itInfo.itList.add(it);

                    if (toSkid.Type__c == null && sw.serialList.size() > 0) {
                        SkidService3.SerialWrapper sw2 = new SkidService3.SerialWrapper(it, sw.serialList);
                        skidsToPutaway.add(sw2);
                        putawaySkids.put(SkidService3.generateKey(it, attributes), sw2);
                    }

                    shlToUpdate.Quantity_Picked__c -= (sw.skid.Quantity__c * pkgToStock);   //Packaging to Stocking
                    shlToUpdate.Quantity_Shipped__c += (sw.skid.Quantity__c * pkgToSell);   //Packaging to Selling

                    orderLineToUpdate.put('Quantity_Allocated__c', (Decimal)orderLineToUpdate.get('Quantity_Allocated__c') - (sw.skid.Quantity__c * pkgToSell));   //Packaging to Selling
                    orderLineToUpdate.put('Quantity_Shipped__c', (Decimal)orderLineToUpdate.get('Quantity_Shipped__c') + (sw.skid.Quantity__c * pkgToSell)); //Packaging to Selling
                } else {
                    shlToUpdate.Quantity_Shipped__c += (sw.skid.Quantity__c / wrapper.convFactor);  //Stocking to Selling
                    orderLineToUpdate.put('Quantity_Shipped__c', (Decimal)orderLineToUpdate.get('Quantity_Shipped__c') + (sw.skid.Quantity__c / wrapper.convFactor));  //Stocking to Selling
                }
            }

            Double stdCost = ItemService.getActiveStandardCostDecimal(itemIds, facilityIds, shipment.Company__c, shl.Facility__c, System.now(), shl.Item__c);
            if (stdCost != null) {
                shlToUpdate.Extended_Cost__c = stdCost * shlToUpdate.Quantity_Shipped__c * wrapper.convFactor;  //Selling to Stocking
                if (shl.Item__r.Non_Inventory__c == false) shlToUpdate.Quantity_From_Stock__c = shlToUpdate.Quantity_Shipped__c * wrapper.convFactor;    //Selling to Stocking 
            } else {
                shlToUpdate.Extended_Cost__c = 0;
            }

            shlsToUpdate.add(shlToUpdate);

            shl.Quantity_Picked__c = shlToUpdate.Quantity_Picked__c;
            shl.Quantity_Shipped__c = shlToUpdate.Quantity_Shipped__c;
            shl.Quantity_From_Stock__c = shlToUpdate.Quantity_From_Stock__c;
            shl.Extended_Cost__c = shlToUpdate.Extended_Cost__c;
        }

        if (parentSoLines.size() > 0) SalesOrderLineService.createFulfillmentForParentSOLs(parentSoLines, solShlMap.values());

        putawaySkids.putAll(SkidService3.putAwayService(skidsToPutaway, attributesForPutaway, new Map<String,Boolean>{ SkidService3.MIXED_SERIAL => mixedSerials }));

        for (SkidService3.ParameterData itInfo:itData.values()) {
            for (Inventory_Transaction__c it:itInfo.itList) {
                SKID__c fromSkid = putawaySkids.get(SkidService3.generateKey(it.From_SKID__r, attributesForPutaway)).skid;
                it.From_SKID__c = fromSkid.Id;

                if (it.To_SKID__r.Type__c != null) putawaySkids.put(SkidService3.generateKey(it, attributes), putawaySkids.get(SkidService3.generateKey(it.To_SKID__r, attributesForPutaway)));
            }
        }

        SkidService3.inventoryTransactionsForPutAway(itData, attributes, putawaySkids, new Map<String,String>{ 'adjustFromSkidQuantity' => null, 'deleteToSkids' => 'false' });
        SkidService3.deleteSkids(putawaySkids.values());

        if (orderLinesToUpdate.size() > 0) {
            List<sObject> linesToUpdate = orderLinesToUpdate.values();
            linesToUpdate.sort();
            DML.updateAsUser(linesToUpdate);
        }

        if (shlsToUpdate.size() > 0) DML.updateAsUser(shlsToUpdate);
        if (shipmentsToUpdate.size() > 0) DML.updateAsUser(shipmentsToUpdate.values());
    }
    
    public static void undoShip(List<LineWrapper> shlWrappers) {
        if (shlWrappers == null || shlWrappers.size() == 0) return;

        checkShipErrors(shlWrappers, false);

        List<String> attributes = SkidService3.attributesForPutaway();
        attributes.add('Sales_Order_Line__c');
        attributes.add('Customer__c');
        attributes.add('Order_Line__c');
        attributes.add('Type__c');

        Boolean undoSerials = false;
        Set<Id> itemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();
        for (LineWrapper shlWrapper:shlWrappers) {
            Shipment__c shipment = (Shipment__c)shlWrapper.header;
            Shipment_Line__c shl = (Shipment_Line__c)shlWrapper.line;

            if (shipment.Company__r.Serial_Control__c == SkidService3.AT_SHIPMENT) undoSerials = true;
            itemIds.add(shl.Item__c);
            facilityIds.add(shl.Facility__c);
        }

        Map<Id, Shipment__c> shipmentsToUpdate = new Map<Id, Shipment__c>();
        List<Shipment_Line__c> shlsToUpdate = new List<Shipment_Line__c>();
        Map<Id, sObject> orderLinesToUpdate = new Map<Id, sObject>();
        Map<Id, SkidService3.ParameterData> itData = new Map<Id, SkidService3.ParameterData>();
        List<SkidService3.SerialWrapper> skidsToPutaway = new List<SkidService3.SerialWrapper>();
        Map<Id, Inventory_Transaction__c> itMap = new Map<Id, Inventory_Transaction__c>();
        Map<Id, List<Id>> itemPackagingUOMCache = new Map<Id, List<Id>>();
        for (LineWrapper wrapper:shlWrappers) {
            Shipment__c shipment = (Shipment__c)wrapper.header;
            Shipment_Line__c shl = (Shipment_Line__c)wrapper.line;
            if ( !itemPackagingUOMCache.containsKey(shl.Item__c)) {
                List<Id> lstPkgUOM = (List<Id>) JSON.deserialize(shl.Item__r.Packaging_UOM__c, List<Id>.class);
                itemPackagingUOMCache.put(shl.Item__c, lstPkgUOM);
            }

            if (!shipmentsToUpdate.containsKey(shipment.Id)) {
                shipmentsToUpdate.put(shipment.Id, new Shipment__c(
                    Id = shipment.Id,
                    Locked__c = false,
                    Finalized__c = false,
                    Finalized_Hidden__c = false,
                    Date_Shipped__c = null,
                    Status__c = wrapper.logical == true ? 'Planned' : 'Staged'
                ));
            }

            Shipment_Line__c shlToUpdate = new Shipment_Line__c(Id = shl.Id, Quantity_Picked__c = shl.Quantity_Picked__c, Quantity_Shipped__c = shl.Quantity_Shipped__c / wrapper.convFactor, Quantity_From_Stock__c = shl.Quantity_From_Stock__c);

            Id orderLineId = shl.Sales_Order_Line__c != null ? shl.Sales_Order_Line__c : shl.Order_Line__c;
            sObject orderLineToUpdate;
            if (orderLinesToUpdate.containsKey(orderLineId)) {
                orderLineToUpdate = orderLinesToUpdate.get(orderLineId);
            } else {
                if (shl.Sales_Order_Line__c != null){
                    orderLineToUpdate = new Sales_Order_Line__c(Id = orderLineId, Quantity_Allocated__c = shl.Sales_Order_Line__r.Quantity_Allocated__c, Quantity_Shipped__c = shl.Sales_Order_Line__r.Quantity_Shipped__c, Quantity_Planned__c = shl.Sales_Order_Line__r.Quantity_Planned__c);
                } 
                else orderLineToUpdate = new Order_Line__c(Id = orderLineId, Quantity_Allocated__c = shl.Order_Line__r.Quantity_Allocated__c, Quantity_Shipped__c = shl.Order_Line__r.Quantity_Shipped__c);
                
                orderLinesToUpdate.put(orderLineId, orderLineToUpdate);
            }
            
            SkidService3.ParameterData itInfo = itData.get(shipment.Id);
            if (itInfo == null) {
                itInfo = new SkidService3.ParameterData();
                itInfo.sourceDoc = new Shipment__c(Company__c = shipment.Company__c);
                if (wrapper.logical == true) itInfo.icType = 'Logical Sales Order Undo Shipment';
                itData.put(shipment.Id, itInfo);
            }

            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (shl.Item__r.Non_Inventory__c == false) {
                    SKID__c pickedSkid = new SKID__c(
                        Company__c = shipment.Company__c,
                        Type__c = SkidService3.SKID_TYPE_LOCATION,
                        Quantity__c = sw.skid.Quantity__c,
                        Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                        Item__r = shl.Item__r,
                        Mixed_Palletized__c = sw.skid.Mixed_Palletized__c
                    );
                    for (String attr:attributes) {
                        if (attr == 'Lot__c') pickedSkid.Lot_Number__c = sw.skid.Lot_Number__c;
                        pickedSkid.put(attr, sw.skid.get(attr));
                        if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference) {
                            String refAttr = attr.replace('__c', '__r');
                            pickedSkid.putSObject(refAttr, sw.skid.getSObject(refAttr));
                        }
                    }
                    pickedSkid.Sales_Order_Line__c = null;
                        
                    for (Serial__c serial:sw.serialList) serial.Allow_Reentry__c = false;
                    
                    skidsToPutaway.add(new SkidService3.SerialWrapper(pickedSkid, sw.serialList));

                    SKID__c fromSkid;
                    if (shl.Order_Line__c != null) {
                        fromSkid = new SKID__c(
                            Company__c = shl.Order_Line__r.Receiving_Company__c,
                            Quantity__c = -sw.skid.Quantity__c,
                            Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                            Item__c = shl.Order_Line__r.Receiving_Item__c,
                            Facility2__c = shl.Order_Line__r.Deliver_To_Facility__c,
                            Facility2__r = shl.Order_Line__r.Deliver_To_Facility__r,
                            Location__c = shl.Order_Line__r.Deliver_To_Location__c,
                            Order_Line__c = shl.Order_Line__c,
                            Order_Line__r = shl.Order_Line__r
                        );
                        fromSkid.Item__r = shl.Item__r;
                        for (String attr:attributes) {
                            if (attr != 'Item__c' && attr != 'Facility2__c' && attr != 'Location__c' && attr != 'Bin__c' && attr != 'Shipment_Line__c' && attr != 'Order_Line__c') {
                                if (attr == 'Lot__c') fromSkid.Lot_Number__c = sw.skid.Lot_Number__c;
                                fromSkid.put(attr, sw.skid.get(attr));
                                if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference) {
                                    String refAttr = attr.replace('__c', '__r');
                                    fromSkid.putSObject(refAttr, sw.skid.getSObject(refAttr));
                                }
                            }
                        }
                        
                        fromSkid.Type__c = SkidService3.SKID_TYPE_INTRANSIT;
                        skidsToPutaway.add(new SkidService3.SerialWrapper(fromSkid, new List<Serial__c>()));
                        
                        skidsToPutaway.add(new SkidService3.SerialWrapper(new SKID__c(
                            Company__c = shl.Order_Line__r.Receiving_Company__c,
                            Type__c = SkidService3.SKID_TYPE_TO_SUPPLY,
                            Quantity__c = sw.skid.Quantity__c * KSE.getConversionFactor(shl.Order_Line__r.Receiving_Item__c, shl.Order_Line__r.Deliver_To_Facility__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, shl.Order_Line__r.Receiving_Item__r.Stocking_UOM__c, itemPackagingUOMCache.get(shl.Item__c)),
                            Stocking_UOM__c = shl.Order_Line__r.Receiving_Item__r.Stocking_UOM__c,
                            Item__c = shl.Order_Line__r.Receiving_Item__c,
                            Item__r = shl.Order_Line__r.Receiving_Item__r,
                            Packaging_UOM__c = shl.Order_Line__r.Receiving_Item__r.Stocking_UOM__c,
                            Facility2__c = shl.Order_Line__r.Deliver_To_Facility__c,
                            Facility2__r = shl.Order_Line__r.Deliver_To_Facility__r,
                            Location__c = shl.Order_Line__r.Deliver_To_Location__c,
                            Location__r = shl.Order_Line__r.Deliver_To_Location__r,
                            Container_Item__c = shl.Order_Line__r.Receiving_Item__c,
                            Container_Item__r = shl.Order_Line__r.Receiving_Item__r,
                            Order_Line__c = shl.Order_Line__c
                        )));
                        
                        
                    } else if (shl.Item__r.Track_Install_Base__c == true && shl.Sales_Order__r.Ship_To__r.Track_Install_Base__c == true) {
                        fromSkid = new SKID__c(
                            Company__c = shipment.Company__c,
                            Quantity__c = -sw.skid.Quantity__c,
                            Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                            Customer__c = shl.Sales_Order_Line__r.Customer_Site__c != null ? shl.Sales_Order_Line__r.Customer_Site__c : shl.Sales_Order__r.Ship_To__c,
                            Sales_Order_Line__c = shl.Sales_Order_Line__c
                        );
                        fromSkid.Item__r = shl.Item__r;
                        for (String attr:attributes) {
                            if (attr != 'Facility2__c' && attr != 'Location__c' && attr != 'Bin__c' && attr != 'Shipment_Line__c' && attr != 'Customer__c' && attr != 'Sales_Order_Line__c') {
                                if (attr == 'Lot__c') fromSkid.Lot_Number__c = sw.skid.Lot_Number__c;
                                fromSkid.put(attr, sw.skid.get(attr));
                                if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference) {
                                    String refAttr = attr.replace('__c', '__r');
                                    fromSkid.putSObject(refAttr, sw.skid.getSObject(refAttr));
                                }
                            }
                        }
                        fromSkid.Type__c = SkidService3.SKID_TYPE_INSTALLBASE;
                        skidsToPutaway.add(new SkidService3.SerialWrapper(fromSkid, new List<Serial__c>()));
                    }
                    List<Id> pkgUOMIds = (List<Id>)JSON.deserialize(sw.skid.Item__r.Packaging_UOM__c,List<Id>.class);
                    Decimal convFactor = 1;
                    // while undoing the ship, the item needs to go back in the packaging uom for which it was issued
                    // TODO container flag check for Eaches scenario instead of checking if item == container item
                    if (sw.skid.Item__c != sw.skid.Container_Item__c &&  sw.skid.Packaging_UOM__r.Package_Class__c != sw.skid.Container_Item__r.Container_Package_Class__c && sw.skid.Mixed_Palletized__c == false) {
                        Id pkgUom = SkidService3.getNextLevelUomId(sw.skid, sw.skid.Item__r);
                        convFactor = KSE.getConversionFactor(sw.skid.Item__c, sw.skid.Facility2__r.Facility_Identifier__c, pkgUom, sw.skid.Packaging_UOM__c,pkgUOMIds);
                        if ( Math.round(pickedSkid.Quantity__c / convFactor) == (pickedSkid.Quantity__c / convFactor) ) {
                            pickedSkid.Packaging_UOM__c = pkgUom;
                            pickedSkid.Quantity__c = pickedSkid.Quantity__c / convFactor;
                        } else {
                            convFactor = 1;
                        }
                    }

                    Decimal pkgToStock = KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c,pickedSkid.Packaging_UOM__c, shl.Item__r.Stocking_UOM__c, itemPackagingUOMCache.get(shl.Item__c) );
                    Decimal pkgToSell = pkgToStock / wrapper.convFactor;

                    for (Inventory_Transaction__c it:(List<Inventory_Transaction__c>)JSON.deserialize(sw.temporaryValueHolder, List<Inventory_Transaction__c>.Class)) {

                        Inventory_Transaction__c undoIt = SkidService3.createInventoryTransaction(shl.Item__r, shl, pickedSkid.Customer__c != null ? 'RMA Repair Undo Shipment' : (shl.Sales_Order_Line__c != null ? 'Sales Order Undo Shipment' : 'Transfer Order Undo Shipment'), it.Quantity__c/convFactor, fromSkid, pickedSkid, attributes);
                        undoIt.Purchase_Order_Line__c = pickedSkid.Purchase_Order_Line__c;
                        undoIt.To_SKID__r = pickedSkid;
                        undoIt.Mixed_Palletized__c = sw.skid.Mixed_Palletized__c;
                        undoIt.Sales_Order_Line__c = shl.Sales_Order_Line__c;
                        undoIt.Order_Line__c = shl.Order_Line__c;
                        undoIt.Transaction_Date__c = it.Transaction_Date__c;

                        if (wrapper.logical) {
                            undoIt.Type__c = 'Logical ' + undoIt.Type__c;
                            undoIt.Purchase_Order_Line__c = shl.Purchase_Order_Line__c;
                            undoIt.Receipt_Line__c = it.Receipt_Line__c;
                        }

                        itInfo.itList.add(undoIt);
                        itMap.put(it.Id, new Inventory_Transaction__c(Id = it.Id, Reversed__c = true));
                    }

                    if (wrapper.logical != true) {
                        shlToUpdate.Quantity_Picked__c += (pickedSkid.Quantity__c * pkgToStock); //Packaging to Stocking
                        orderLineToUpdate.put('Quantity_Allocated__c', (Decimal)orderLineToUpdate.get('Quantity_Allocated__c') + (pickedSkid.Quantity__c * pkgToSell));  //Packaging to Selling
                    }

                    shlToUpdate.Quantity_Shipped__c -= (pickedSkid.Quantity__c * pkgToSell); //Packaging to Selling
                    if (shl.Sales_Order_Line__c != null){
                        orderLineToUpdate.put('Quantity_Planned__c', (Decimal)orderLineToUpdate.get('Quantity_Planned__c') + (pickedSkid.Quantity__c * pkgToSell));
                    }
                    
                    orderLineToUpdate.put('Quantity_Shipped__c', (Decimal)orderLineToUpdate.get('Quantity_Shipped__c') - (pickedSkid.Quantity__c * pkgToSell));  //Packaging to Selling
                } else {
                    shlToUpdate.Quantity_Shipped__c -= (sw.skid.Quantity__c / wrapper.convFactor); //Stocking to Selling
                    orderLineToUpdate.put('Quantity_Shipped__c', (Decimal)orderLineToUpdate.get('Quantity_Shipped__c') - (sw.skid.Quantity__c / wrapper.convFactor));    //Stocking to Selling
                    
                    SKID__c demandSkid = new SKID__c(
                        Company__c = shipment.Company__c,
                        Type__c = shl.Sales_Order_Line__c != null ? SkidService3.SKID_TYPE_SO_DEMAND : SkidService3.SKID_TYPE_TO_DEMAND,
                        Quantity__c = sw.skid.Quantity__c,
                        Quantity_Stocking_UOM__c = sw.skid.Quantity__c,
                        Packaging_UOM__c = shl.Item__r.Stocking_UOM__c,
                        Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                        Item__c = shl.Item__c,
                        Facility2__c = shl.Facility__c,
                        Facility2__r = shl.Facility__r,
                        Location__c = shl.Location__c,
                        Container_Item__c = shl.Item__c,
                        Shipment_Line__c = shl.Id,
                        Sales_Order_Line__c = shl.Sales_Order_Line__c,
                        Order_Line__c = shl.Order_Line__c
                    );
                    demandSkid.Item__r =shl.Item__r;
                    
                    skidsToPutaway.add(new SkidService3.SerialWrapper(demandSkid, new List<Serial__c>()));
                }
            }

            Double stdCost = ItemService.getActiveStandardCostDecimal(itemIds, facilityIds, shipment.Company__c, shl.Facility__c, System.now(), shl.Item__c);
            if (stdCost != null) {
                shlToUpdate.Extended_Cost__c = stdCost * shlToUpdate.Quantity_Shipped__c * wrapper.convFactor;  //Selling to Stocking
                if (shl.Item__r.Non_Inventory__c == false) shlToUpdate.Quantity_From_Stock__c = shlToUpdate.Quantity_Shipped__c * wrapper.convFactor;    //Selling to Stocking 
            } else {
                shlToUpdate.Extended_Cost__c = 0;
            }

            shlsToUpdate.add(shlToUpdate);
        }

        if (itMap.size() > 0) {
            Set<Id> itIds = itMap.keySet();
            SOQLUtil fulfillmentQuery = new SOQLUtil('Fulfillment__c');
            fulfillmentQuery.addField('Id');
            fulfillmentQuery.setWhereClause('(Inventory_Transaction__c IN :itIds AND Type__c NOT IN (\'RMA Receipt For Repair\')) AND Invoice_Ready__c = true');

            List<Fulfillment__c> fulfillments = Database.query(fulfillmentQuery.getQuery());
            for (Fulfillment__c fulfillment:fulfillments) fulfillment.Invoice_Ready__c = false;

            if (fulfillments.size() > 0) DML.updateAsUser(fulfillments);
            DML.updateAsSystem(itMap.values());
        }

        Map<List<String>, SkidService3.SerialWrapper> putawaySkids = SkidService3.putAwayService(skidsToPutaway, attributes, new Map<String,Boolean>{ SkidService3.UNDO_SERIAL => undoSerials });

        for (SkidService3.ParameterData itInfo:itData.values()) {
            for (Inventory_Transaction__c it:itInfo.itList) {
                if (it.From_SKID__r != null) {
                    SKID__c fromSkid = putawaySkids.get(SkidService3.generateKey(it.From_SKID__r, attributes)).skid;
                    it.From_SKID__c = fromSkid.Id;
                    it.From_SKID__r = fromSkid;
                }

                putawaySkids.put(SkidService3.generateKey(it, attributes), putawaySkids.get(SkidService3.generateKey(it.To_SKID__r, attributes)));
            }
        }

        SkidService3.inventoryTransactionsForPutAway(itData, attributes, putawaySkids, new Map<String,String>{ 'adjustFromSkidQuantity' => 'none' });

        if (orderLinesToUpdate.size() > 0) {
            List<sObject> linesToUpdate = orderLinesToUpdate.values();
            linesToUpdate.sort();
            DML.updateAsUser(linesToUpdate);
        }
        if (shipmentsToUpdate.size() > 0) DML.updateAsUser(shipmentsToUpdate.values());
        if (shlsToUpdate.size() > 0) DML.updateAsUser(shlsToUpdate);
    }


    private static List<Id> getUomIds(Shipment_Line__c shl) { return (List<Id>)JSON.deserialize(shl.Item__r.Packaging_UOM__c, List<Id>.Class); }

    private static Map<Id, UOM__c> getUoms(Set<Id> uomIds) {
        SOQLUtil uomQuery = new SOQLUtil('UOM__c');
        uomQuery.addFields(new Set<String>{ 'Id', 'Name', 'Package_Class__c',

            'Package_Class__r.Default_Container_Item__c', 'Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            'Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c', 'Package_Class__r.Default_Container_Item__r.Item_Attribute__c',
            'Package_Class__r.Fractional_Quantities_Allowed__c', 'Package_Class__r.Level__c' });
        uomQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Package_Class__r.Default_Container_Item__r.Item_Attribute__r');
        uomQuery.setWhereClause('Id IN :uomIds');
        return new Map<Id, UOM__c>((List<UOM__c>)Database.query(uomQuery.getQuery()));
    }

    private static Map<Id, List<UOM__c>> getUomList(Set<Id> uomIds, Map<Id, List<Id>> packagingUoms) {
        Map<Id, UOM__c> uomMap = getUoms(uomIds);
        Map<Id, List<UOM__c>> uoms = new Map<Id, List<UOM__c>>();
        for (Id itemId:packagingUoms.keySet()) {
            uoms.put(itemId, new List<UOM__c>());
            for (Integer i = packagingUoms.get(itemId).size() - 1; i >= 0; i--) uoms.get(itemId).add(uomMap.get(packagingUoms.get(itemId)[i]));
        }
        return uoms;
    }

    private static List<String> getSkidFields(Shipment_Line__c shl, List<String> addlFields) {
        List<String> skidFields = addlFields.clone();
        for (String attr:SkidService3.attributeFields) {
            if (attr != 'License_Plate_Number__c' && shl.Item__r.Item_Attribute__c != null && (Boolean)shl.Item__r.Item_Attribute__r.get(attr) == true) {
                if (attr == 'Lot_Number__c') skidFields.add('Lot__c');
                else skidFields.add(attr);
            }
        }
        skidFields.addAll(new List<String>{ 'Consigned_Owner__c', 'Quantity_Used__c', 'Quantity_Available__c', 'Quantity_to_Issue__c' });
        return skidFields;
    }

    private static LineWrapper generateWrapper(Shipment_Line__c shl, UOM__c uom) {
        LineWrapper wrapper = new LineWrapper(new Shipment_Line__c(Id = shl.Id));
        wrapper.convFactor = null;
        wrapper.logical = null;
        wrapper.uom = uom.Name;
        return wrapper;
    }
}