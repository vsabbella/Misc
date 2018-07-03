public with sharing class AllocationService {
    private static Map<Id, List<String>> skidAttributes;

    public static void validate(List<sObject> records) {
        if (records == null || records.size() == 0) return;
        
        Map<Id, Shipment__c> shipments = new Map<Id, Shipment__c>();
        Set<Id> soShipments = new Set<Id>();
        for (sObject record:records) {
            if (record.getSObjectType() == Shipment_Line__c.sObjectType) {
                Shipment_Line__c shl = (Shipment_Line__c)record;
                shipments.put(shl.Shipment__c, shl.Shipment__r);

                if (shl.Sales_Order_Line__c != null) {
                    Sales_Order__c so = shl.Sales_Order__r;
                    Sales_Order_Line__c sol = shl.Sales_Order_Line__r;

                    soShipments.add(shl.Shipment__c);

                    if (sol.Has_Exceptions__c) {
                        throw new CustomException(shl.Name + ': ' + Label.Sales_order_or_sales_order_line_has_exceptions);
                    } else if (!so.Override_Credit_Hold__c) {
                        if (so.Credit_Hold__c) {
                            throw new CustomException(shl.Name + ': ' + Label.Sales_Order_on_Credit_Hold);
                        } else {
                            OTC__c otc = getOtc(shl);
                            if (otc != null && otc.Customer_Credit_Hold_Check_At_Allocate__c && so.Customer__r.Top_Parent_Customer__r.Credit_Hold__c) {
                                throw new CustomException(shl.Name + ': ' + Label.Top_Parent_Customer_on_Credit_Hold);
                            }
                        }
                    } else if (so.Hold__c) {
                        throw new CustomException(shl.Name + ': ' + Label.SH_SO_On_Hold_At_Ship);
                    } else if (so.Released_to_3PL__c) {
                        throw new CustomException(shl.Name + ': ' + Label.SH_SO_released_to_3PL);
                    }
                }
            } else {
                Work_Order__c wo = (Work_Order__c)record;

                if (wo.Status__c == WorkOrderService.WO_STATUS_DRAFT) {
                    throw new CustomException(wo.Name + ': ' + Label.WorkOrder_not_released);
                } else if (wo.Status__c == WorkOrderService.WO_STATUS_CLOSED) {
                    throw new CustomException(wo.Name + ': ' + Label.WorkOrder_already_closed);
                } else if (wo.Status__c == WorkOrderService.WO_STATUS_CANCELLED) {
                    throw new CustomException(wo.Name + ': ' + Label.WorkOrder_accounted_or_cancelled);
                }
            }
        }

        for (Shipment__c shipment:shipments.values()) {
            if (shipment.Has_Exceptions__c) {
                throw new CustomException(shipment.Name + ': ' + Label.Shipment_has_exceptions);
            } else if (shipment.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED) {
                throw new CustomException(shipment.Name + ': Shipment has already been confirmed');
            } else if (soShipments.contains(shipment.Id) && shipment.Customer__r.Top_Parent_Customer__r.Status__c != 'Approved') {
                throw new CustomException(shipment.Name + ': ' + Label.Top_Parent_Customer_not_status_Approved);
            }
        }
    }

    public static List<LineWrapper> getInventory(List<sObject> lines) {
        List<LineWrapper> wrappers = new List<LineWrapper>();
        if (lines == null || lines.size() == 0) return wrappers;

        Boolean isShipment = lines[0].getSObjectType() == Shipment_Line__c.sObjectType;

        Map<Id, Item__c> items = new Map<Id, Item__c>();
        Company__c company;
        Set<Id> facilityIds = new Set<Id>();
        Set<String> lineTypes = new Set<String>();
        Map<Id, sObject> linesForLocation = new Map<Id, sObject>();
        for (sObject line:lines) {
            items.put((Id)line.get('Item__c'), (Item__c)line.getSObject('Item__r'));

            if (isShipment == true) {
                Shipment_Line__c shl = (Shipment_Line__c)line;
                company = shl.Company__r;
                facilityIds.add(shl.Facility__c);

                if (shl.Sales_Order_Line__c != null) {
                    lineTypes.add('sales_order_line__c');
                    linesForLocation.put(shl.Id, shl.Sales_Order_Line__r);
                } else {
                    lineTypes.add('order_line__c');
                    linesForLocation.put(shl.Id, shl.Order_Line__r);
                }
            } else {
                Material_Tracking__c material = (Material_Tracking__c)line;
                company = material.Work_Order__r.Company__r;
                facilityIds.add(material.Work_Order__r.Facility__c);
                lineTypes.add('material_tracking__c');
                linesForLocation.put(material.Id, material);
            }
        }

        Map<Id, List<String>> allocAttributes = getSkidAttributes(company.Id, items);
        List<String> attributes = SkidService3.attributesForPutaway();

        Set<Id> locationIds = new Set<Id>();
        Map<String, List<Location__c>> locMap = SkidService3.locationsFromStockMovementRules(linesForLocation.values(), 'Pick', lineTypes, null, locationIds);

        Set<Id> itemIds = items.keySet();
        Set<Id> lineIds = linesForLocation.keySet();
        List<String> sortCriteria = SkidService3.populateSortCriteria(null, company.Id);

        String whereClause = 'Item__c IN :itemIds ' +
                             'AND Facility2__c IN :facilityIds ' +
                             'AND (Location__c IN :locationIds OR Location__c = null) ' +
                             'AND Receipt_Line__c = null ' +
                             'AND (Type__c IN (\'' + SkidService3.SKID_TYPE_ALLOCATED + '\', \'' + SkidService3.SKID_TYPE_PLANNED + '\') ' +
                             'OR (Type__c = \'' + SkidService3.SKID_TYPE_LOCATION + '\' ' +
                             'AND Shipment_Line__c = null))';

        Map<Id, Map<List<String>, SKID__c>> allocatedSkids = new Map<Id, Map<List<String>, SKID__c>>();
        Map<List<String>, Decimal> allocQtys = new Map<List<String>, Decimal>();
        Map<Id, SKID__c> skidMap = new Map<Id, SKID__c>();
        Map<List<String>, List<SKID__c>> sortedSkids = new Map<List<String>, List<SKID__c>>();
        for (SKID__c skid:Database.query(SkidService3.getSkidQuery(new Map<String, String>{ 'WHERE' => whereClause, 'ORDER' => (sortCriteria.size() > 0 ? String.join(sortCriteria, ',') : null) }))) {
            List<String> allocAttrs = allocAttributes.get(skid.Item__c);

            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED || skid.Type__c == SkidService3.SKID_TYPE_PLANNED) {
                Id lineId = skid.Shipment_Line__c != null ? skid.Shipment_Line__c : skid.Material_Tracking__c;
                skid.Shipment_Line__c = null;
                skid.Material_Tracking__c = null;
                List<String> allocKey = SkidService3.generateKey(skid, allocAttrs);

                if (lineIds.contains(lineId) == true) {
                    if (allocatedSkids.containsKey(lineId) == false) allocatedSkids.put(lineId, new Map<List<String>, SKID__c>{ allocKey => skid });
                    else allocatedSkids.get(lineId).put(allocKey, skid);
                }

                allocQtys.put(allocKey, KSE.addQuantityToField(allocQtys.get(allocKey), skid.Quantity_Stocking_UOM__c));
            } else {
                skidMap.put(skid.Id, skid);

                List<String> key = (new Set<String>(allocAttrs)).contains('Location__c') == true ? new List<String>{ skid.Item__c, skid.Location__c } : new List<String>{ skid.Item__c };
                if (sortedSkids.containsKey(key) == false) sortedSkids.put(key, new List<SKID__c>{ skid });
                else sortedSkids.get(key).add(skid);
            }
        }

        Map<Id, List<Serial__c>> allocSerials = new Map<Id, List<Serial__c>>();
        Map<List<String>, List<Serial__c>> serialMap = new Map<List<String>, List<Serial__c>>();
        if (skidMap.size() > 0) {
            Set<Id> skidIds = skidMap.keySet();
            SOQLUtil serialQuery = new SOQLUtil('Serial__c');
            serialQuery.addFields(new Set<String>{ 'Id', 'Name', 'Allocated_SKID__c', 'Item__c', 'SKID__c', 'Status__c', 'Temporary_Value_Holder__c',
                'Allocated_SKID__r.Shipment_Line__c', 'Allocated_SKID__r.Material_Tracking__c' });
            serialQuery.addFields(new Set<String>(SkidService3.serialAttributes));
            serialQuery.addFields('Serial');
            serialQuery.setWhereClause('SKID__c IN :skidIds AND ' +
                                       '(Allocated_SKID__c = null ' +
                                       'OR (Allocated_SKID__r.Type__c = \'' + SkidService3.SKID_TYPE_ALLOCATED + '\' ' +
                                       'AND (Allocated_SKID__r.Shipment_Line__c IN :lineIds ' +
                                       'OR Allocated_SKID__r.Material_Tracking__c IN :lineIds)))');
            serialQuery.setOrderByClause('Name ASC');

            for (Serial__c serial:Database.query(serialQuery.getQuery())) {
                if (serial.Allocated_SKID__c != null) {
                    if (allocSerials.containsKey(serial.Allocated_SKID__c) == false) allocSerials.put(serial.Allocated_SKID__c, new List<Serial__c>{ serial });
                    else allocSerials.get(serial.Allocated_SKID__c).add(serial);
                } else {
                    List<String> allocKey = SkidService3.generateKey(skidMap.get(serial.SKID__c), allocAttributes.get(serial.Item__c));
                    if (serialMap.containsKey(allocKey) == false) serialMap.put(allocKey, new List<Serial__c>{ serial });
                    else serialMap.get(allocKey).add(serial);
                }
            }
        }

        Map<List<String>, Decimal> qtyAvailableMap = new Map<List<String>, Decimal>();
        for (sObject line:lines) {
            sObject lineForLocation = linesForLocation.get(line.Id);
            if (!locMap.containsKey(lineForLocation.Id)) throw new CustomException(line.get('Name') + ': ' + Label.Matching_stock_movement_rule_not_found);
            Set<Id> locIds = (new Map<Id, Location__c>(locMap.get(lineForLocation.Id))).keySet();

            LineWrapper wrapper = new LineWrapper(line, new List<SkidService3.SerialWrapper>());
            Id itemId = (Id)line.get('Item__c');
            List<String> allocAttrs = allocAttributes.get(itemId);
            Boolean hasBin = ((new Set<String>(allocAttrs)).contains('Bin__c'));
            Map<List<String>, SKID__c> allocSkids = allocatedSkids.containsKey(line.Id) == true ? allocatedSkids.get(line.Id) : new Map<List<String>, SKID__c>();
            
            Decimal qtyToAllocate;
            if (isShipment) {
                Shipment_Line__c shl = (Shipment_Line__c)line;
                qtyToAllocate = shl.Quantity_Planned__c - shl.Quantity_Allocated__c - shl.Quantity_To_Pick__c - shl.Quantity_Picked__c - shl.Quantity_Shipped__c;
                
                if (shl.Sales_Order_Line__c != null) wrapper.uom = shl.Sales_Order_Line__r.Selling_UOM__r.Name;
                else wrapper.uom = shl.Item__r.Stocking_UOM__r.Name;
            } else {
                Material_Tracking__c material = (Material_Tracking__c)line;
                qtyToAllocate = material.Quantity_Required__c - material.Quantity_Allocated__c - material.Quantity_Issued__c;
                wrapper.uom = material.Item__r.Stocking_UOM__r.Name;
            }

            wrapper.skidFields = getSkidFIList(allocAttrs.clone(),company);
            for (Integer i = 0; i < wrapper.skidFields.size(); i++) {
                FieldInfo skidField = wrapper.skidFields[i];
                if (skidField.field == 'Item__c' || skidField.field == 'Material_Tracking__c' || skidField.field == 'Shipment_Line__c' || skidField.field == 'Receipt_Line__c' || skidField.field == 'Purchase_Order_Line__c' || skidField.field == 'Purchase_Order_Line__c' || (skidField.field == 'Customer__c' && lineForLocation.getSObjectType() != Sales_Order_Line__c.sObjectType) || (!isShipment && skidField.field == 'Sales_Order_Line__c')) {
                    wrapper.skidFields.remove(i--);
                    continue;
                } else if (skidField.field == 'Input_Quantity__c') {
                    skidField.title = 'Quantity to Allocate (' + wrapper.uom + ')';
                } else {
                    skidField.editable = false;
                    if (skidField.field == 'Quantity_Allocated__c' || skidField.field == 'Quantity_Available__c') skidField.title = skidField.title + ' (' + wrapper.uom + ')';
                }

                skidField.field = 'skid.' + skidField.field;
            }

            List<SKID__c> skids = new List<SKID__c>();
            if ((new Set<String>(allocAttrs)).contains('Location__c') == true) {
                for (Id locId:locIds) {
                    List<String> itemLocKey = new List<String>{ itemId, locId };
                    if (sortedSkids.containsKey(itemLocKey) == true) skids.addAll(sortedSkids.get(itemLocKey));
                }
            } else {
                List<String> itemKey = new List<String>{ itemId };
                if (sortedSkids.containsKey(itemKey) == true) skids.addAll(sortedSkids.get(itemKey));
            }

            /*
             * Quantity Fields
             * Quantity Allocated = Quantity allocated for this line (Selling UOM)
             * Quantity Available = Quantity from stock - quantity allocated for all lines (Selling UOM)
             * Input Quantity = Quantity to allocate (Selling UOM)
             */
            Map<List<String>, SkidService3.SerialWrapper> swMap = new Map<List<String>, SkidService3.SerialWrapper>();
            Set<List<String>> keysUsed = new Set<List<String>>();
            for (SKID__c skid:skids) {
                List<String> allocKey = SkidService3.generateKey(skid, allocAttrs);
                if (locIds.contains(skid.Location__c) == false || SkidService3.isValidSkid(skid, lineForLocation, attributes) == false ||
                (skid.Customer__c != null && lineForLocation.getSObjectType() != Sales_Order_Line__c.sObjectType) ||
                (skid.Sales_Order_Line__c != null && (lineForLocation.getSObjectType() != Sales_Order_Line__c.sObjectType || (String)lineForLocation.get('Type__c') != 'Repair' || skid.Sales_Order_Line__c != lineForLocation.Id)) ||
                (skid.Sales_Order_Line__c == null && lineForLocation.getSObjectType() == Sales_Order_Line__c.sObjectType && (String)lineForLocation.get('Type__c') == 'Repair')) continue;
                
                skid = skid.clone(true, true);
                if (skid.Lot__c != null && skid.Lot__r.Lot_Hold__c == true) skid.Quantity_Stocking_UOM__c = 0;
                else skid.Quantity_Stocking_UOM__c /= wrapper.convFactor;

                if (swMap.containsKey(allocKey) == true) {
                    SkidService3.SerialWrapper sw = swMap.get(allocKey);
                    sw.skid.Quantity_Available__c += skid.Quantity_Stocking_UOM__c;
                } else {
                    if (hasBin == false) {
                        skid.Bin__c = null;
                        skid.Bin__r = null;
                    }

                    List<Serial__c> serials = new List<Serial__c>();

                    if (allocSkids.containsKey(allocKey) == true) {
                        SKID__c allocSkid = allocSkids.get(allocKey);
                        skid.Quantity_Allocated__c = allocSkid.Quantity_Stocking_UOM__c / wrapper.convFactor;

                        if (allocSerials.containsKey(allocSkid.Id) == true) serials.addAll(allocSerials.get(allocSkid.Id));

                        keysUsed.add(allocKey);
                    } else {
                        skid.Quantity_Allocated__c = 0;
                    }

                    skid.Quantity_Available__c = skid.Quantity_Stocking_UOM__c;
                    if (allocQtys.containsKey(allocKey) == true) skid.Quantity_Available__c -= (allocQtys.get(allocKey) / wrapper.convFactor);
                    skid.Input_Quantity__c = 0;
                    skid.Lot_Number__c = skid.Lot__r.Name;

                    if (serialMap.containsKey(allocKey) == true) serials.addAll(serialMap.get(allocKey));

                    SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(skid, serials);
                    swMap.put(allocKey, sw);
                    wrapper.serialWrappers.add(sw);
                }
            }

            if (keysUsed.size() != allocSkids.size()) {
                for (List<String> allocKey:allocSkids.keySet()) {
                    if (keysUsed.contains(allocKey) == true) continue;
                    
                    SKID__c skid = allocSkids.get(allocKey).clone(true, true);
                    skid.Quantity_Allocated__c = skid.Quantity_Stocking_UOM__c / wrapper.convFactor;
                    skid.Quantity_Available__c = 0;
                    skid.Input_Quantity__c = 0;
                    skid.Lot_Number__c = skid.Lot__r.Name;
                    wrapper.serialWrappers.add(new SkidService3.SerialWrapper(skid, allocSerials.containsKey(skid.Id) == true ? allocSerials.get(skid.Id) : new List<Serial__c>()));
                }
            }

            for (Integer i = 0; i < wrapper.serialWrappers.size(); i++) {
                SkidService3.SerialWrapper sw = wrapper.serialWrappers[i];
                if (sw.skid.Quantity_Available__c < 0) sw.skid.Quantity_Available__c = 0;

                if (sw.skid.Quantity_Available__c == 0 && sw.skid.Quantity_Allocated__c == 0) {
                    wrapper.serialWrappers.remove(i--);
                    continue;
                }

                List<String> allocKey = SkidService3.generateKey(sw.skid, allocAttrs);
                Decimal qtyAvailable = qtyAvailableMap.containsKey(allocKey) == true ? Math.min(qtyAvailableMap.get(allocKey), sw.skid.Quantity_Available__c) : sw.skid.Quantity_Available__c;

                sw.skid.Input_Quantity__c = Math.min(qtyAvailable, qtyToAllocate);
                qtyToAllocate -= sw.skid.Input_Quantity__c;
                qtyAvailableMap.put(allocKey, qtyAvailable - sw.skid.Input_Quantity__c);
            }

            if (isShipment) wrapper.line = new Shipment_Line__c();
            else wrapper.line = new Material_Tracking__c();
            wrapper.line.Id = line.Id;
            wrapper.logical = null;
            wrappers.add(wrapper);
        }

        return wrappers;
    }

    public static List<LineWrapper> getLines(Set<Id> woIds) {
        List<LineWrapper> wrappers = new List<LineWrapper>();
        
        if (woIds == null || woIds.size() == 0) {
            return wrappers;
        }

        Map<Id, Material_Tracking__c> materials = new Map<Id, Material_Tracking__c>(WorkOrderService.getMaterials(woIds, null, new Set<String>{ WorkOrderService.MATERIAL_TYPE_BACKFLUSH, WorkOrderService.MATERIAL_TYPE_KIT }, new Set<String>{ 'Allocate' }, null, ' AND Allocation_Required__c = true AND Item__r.Non_Inventory__c = false '));
        if (materials.size() == 0) return wrappers;

        for (LineWrapper wrapper:getInventory(materials.values())) {
            Material_Tracking__c material = materials.get(wrapper.line.Id);
            wrapper.header = material.Work_Order__r;
            wrapper.line = material;
            wrappers.add(wrapper);
        }

        return wrappers;
    }

    private static void checkErrors(List<LineWrapper> wrappers) {
        if (wrappers == null || wrappers.size() == 0) return;

        Boolean isShipment = wrappers[0].line.getSObjectType() == Shipment_Line__c.sObjectType;

        Set<String> serialKeys = new Set<String>();
        Map<List<String>, Decimal> qtyAvailableMap = new Map<List<String>, Decimal>();
        for (LineWrapper wrapper:wrappers) {
            sObject line = wrapper.line;
            String lineName = (String)line.get('Name');
            Id itemId = (Id)line.get('Item__c');
            
            Decimal totalToAllocate = 0;
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Input_Quantity__c != null) totalToAllocate += sw.skid.Input_Quantity__c;

                if (sw.skid.Input_Quantity__c < 0) {
                    if (-sw.skid.Input_Quantity__c > sw.skid.Quantity_Allocated__c) {
                        throw new CustomException(lineName + ': Cannot unallocate more quantity (' + (-sw.skid.Input_Quantity__c) + ') than allocated (' + sw.skid.Quantity_Allocated__c + ')');
                    }
                } else if (sw.skid.Input_Quantity__c > 0) {
                    SKID__c skidClone = sw.skid.clone(false, true);
                    skidClone.Shipment_Line__c = null;
                    skidClone.Material_Tracking__c = null;

                    List<String> skidKey = SkidService3.generateKey(skidClone, skidAttributes.get(itemId));
                    Decimal qtyAvailable = qtyAvailableMap.containsKey(skidKey) ? Math.min(qtyAvailableMap.get(skidKey), sw.skid.Quantity_Available__c * wrapper.convFactor) / wrapper.convFactor : sw.skid.Quantity_Available__c;

                    if (sw.skid.Input_Quantity__c > qtyAvailable) {
                        throw new CustomException(lineName + ': Cannot allocate more quantity (' + sw.skid.Input_Quantity__c + ') than available (' + qtyAvailable + ')');
                    }

                    qtyAvailableMap.put(skidKey, (qtyAvailable * wrapper.convFactor) - sw.skid.Input_Quantity__c);
                }

                if (sw.serialList.size() > 0) {
                    Decimal serialsToAllocate = 0;
                    Decimal serialsToUnallocate = 0;
                    Decimal serialsAllocated = 0;
                    for (Serial__c serial:sw.serialList) {
                        if (serial.Temporary_Value_Holder__c == 'Allocate' || serial.Temporary_Value_Holder__c == 'Allocated') {
                            String uniqueKey = (String)wrapper.header.get('Company__c') + '-' + itemId + '-' + serial.Name;
                            if (!serialKeys.contains(uniqueKey)) serialKeys.add(uniqueKey);
                            else throw new CustomException(lineName + ': Serial ' + serial.Name + ' has been specified more than once');
                            
                            if (serial.Temporary_Value_Holder__c == 'Allocate') serialsToAllocate++;
                            else serialsAllocated++;
                        } else if (serial.Temporary_Value_Holder__c == 'Unallocate') {
                            serialsToUnallocate++;
                        }
                    }
                    
                    Decimal totalSerials = serialsToAllocate - serialsToUnallocate + serialsAllocated;
                    Decimal totalAllocated = (sw.skid.Quantity_Allocated__c + sw.skid.Input_Quantity__c) * wrapper.convFactor;  //Selling To Stocking
                    if (totalSerials > totalAllocated) {
                        throw new CustomException(lineName + ': ' + Label.Number_of_serials + ' (' + totalSerials + ') cannot be greater than quantity allocated (' + totalAllocated + ')');
                    }
                }
            }

            if (isShipment && totalToAllocate > 0) {
                Shipment_Line__c shl = (Shipment_Line__c)line;
                Decimal qtyForAllocation = shl.Quantity_Planned__c - shl.Quantity_Allocated__c - shl.Quantity_To_Pick__c - shl.Quantity_Picked__c - shl.Quantity_Shipped__c;
                totalToAllocate = totalToAllocate.setScale(6, System.RoundingMode.HALF_UP);
                if (totalToAllocate > qtyForAllocation) {
                    throw new CustomException(shl.Name + ': Cannot allocate more quantity (' + totalToAllocate + ') than required (' + qtyForAllocation + ')');
                }
            }
        }
    }

    public static void allocate(List<LineWrapper> wrappers) {
        if (wrappers == null || wrappers.size() == 0) return;

        Boolean isShipment = wrappers[0].line.getSObjectType() == Shipment_Line__c.sObjectType;

        if (skidAttributes == null) {
            Id companyId;
            Map<Id, Item__c> items = new Map<Id, Item__c>();
            for (LineWrapper wrapper:wrappers) {
                companyId = (Id)(isShipment ? wrapper.line.get('Company__c') : wrapper.line.getSObject('Work_Order__r').get('Company__c'));
                items.put((Id)wrapper.line.get('Item__c'), (Item__c)wrapper.line.getSObject('Item__r'));
            }
            skidAttributes = getSkidAttributes(companyId, items);
        }


        List<String> attributes = SkidService3.attributesForPutaway();
        attributes.add('Material_Tracking__c');
        attributes.add('Type__c');
        
        checkErrors(wrappers);
        
        Map<Id, sObject> recsToUpdateMap = new Map<Id, sObject>();
        List<sObject> recsToUpdate = new List<sObject>();
        List<SkidService3.SerialWrapper> skidsToPutaway = new List<SkidService3.SerialWrapper>();
        Map<Id, Serial__c> serialsToUpdate = new Map<Id, Serial__c>();
        Map<List<String>, List<Serial__c>> serialMap = new Map<List<String>, List<Serial__c>>();
        Map<Id, List<Id>> itemPackagingUOMIds = new Map<Id, List<Id>>();
        Set<Id> headerIds = new Set<Id>();
        Set<Id> lineIds = new Set<Id>();
        for (LineWrapper wrapper:wrappers) {
            sObject header = wrapper.header;
            sObject line = wrapper.line;

            sObject lineToUpdate;
            sObject orderLineToUpdate;
            SKID__c demandSkid;

            List<String> attrs = skidAttributes.get((Id)line.get('Item__c'));

            if (isShipment) {
                Shipment_Line__c shl = (Shipment_Line__c)line;

                lineToUpdate = new Shipment_Line__c();
                lineToUpdate.put('Quantity_To_Pick__c', shl.Quantity_To_Pick__c * wrapper.convFactor);

                demandSkid = new SKID__c(
                    Company__c = shl.Company__c,
                    Item__c = shl.Item__c,
                    Item__r = shl.Item__r,
                    Container_Item__c = shl.Item__c,
                    Quantity__c = 0,
                    Stocking_UOM__c = shl.Item__r.Stocking_UOM__c,
                    Packaging_UOM__c = shl.Item__r.Stocking_UOM__c,
                    Facility2__c = shl.Facility__c,
                    Facility2__r = shl.Facility__r,
                    Location__c = shl.Location__c,
                    Sales_Order_Line__c = shl.Sales_Order_Line__c,
                    Order_Line__c = shl.Order_Line__c,
                    Shipment_Line__c = shl.Id
                );

                sObject orderLine;
                if (shl.Sales_Order_Line__c != null) {
                    orderLine = shl.Sales_Order_Line__r;
                    orderLineToUpdate = new Sales_Order_Line__c();
                    demandSkid.Type__c = SkidService3.SKID_TYPE_SO_DEMAND;
                } else {
                    orderLine = shl.Order_Line__r;
                    orderLineToUpdate = new Order_Line__c(Packaging_UOM__c = (Id)orderLine.get('Packaging_UOM__c'));
                    orderLineToUpdate.put('Ship_From_Facility__c' , (Id)orderLine.get('Ship_From_Facility__c'));
                    orderLineToUpdate.putSObject('Ship_From_Facility__r', orderLine.getSObject('Ship_From_Facility__r'));
                    demandSkid.Type__c = SkidService3.SKID_TYPE_TO_DEMAND;
                }
                
                if (recsToUpdateMap.containsKey(orderLine.Id)) {
                    orderLineToUpdate = recsToUpdateMap.get(orderLine.Id);
                } else {
                    orderLineToUpdate.Id = orderLine.Id;
                    orderLineToUpdate.put('Quantity_Allocated__c', orderLine.get('Quantity_Allocated__c'));
                    recsToUpdateMap.put(orderLine.Id, orderLineToUpdate);
                }
            } else {
                lineToUpdate = new Material_Tracking__c();
            }

            lineIds.add(line.Id);
            lineToUpdate.Id = line.Id;
            lineToUpdate.put('Quantity_Allocated__c', line.get('Quantity_Allocated__c'));

            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                SKID__c allocatedSkid = new SKID__c(
                    Company__c = (Id)header.get('Company__c'),
                    Type__c = isShipment && (Boolean)line.getSObject('Company__r').get('Auto_Plan_Pick__c') == true ? SkidService3.SKID_TYPE_PLANNED : SkidService3.SKID_TYPE_ALLOCATED,
                    Container_Item__c = sw.skid.Item__c,
                    Quantity__c = sw.skid.Input_Quantity__c != null ? sw.skid.Input_Quantity__c * wrapper.convFactor : 0,   //Selling To Stocking
                    Stocking_UOM__c = sw.skid.Item__r.Stocking_UOM__c,
                    Packaging_UOM__c = sw.skid.Item__r.Stocking_UOM__c
                );
                for (String attr:attrs) {
                    if (attr != 'Shipment_Line__c' && attr != 'Material_Tracking__c') { 
                        if (attr == 'Lot__c') allocatedSkid.Lot_Number__c = sw.skid.Lot_Number__c;
                        allocatedSkid.put(attr, sw.skid.get(attr));
                    }
                }
                allocatedSkid.Item__r = sw.skid.Item__r;
                
                if (demandSkid != null) {
                    if (allocatedSkid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                        allocatedSkid.Sales_Order_Line__c = demandSkid.Sales_Order_Line__c;
                        allocatedSkid.Order_Line__c = demandSkid.Order_Line__c;
                    }
                    allocatedSkid.Shipment_Line__c = line.Id;

                    demandSkid.Quantity__c -= allocatedSkid.Quantity__c;

                    if ( !itemPackagingUOMIds.containsKey( sw.skid.Item__c))
                        itemPackagingUOMIds.put( sw.skid.Item__c, (List<Id>) JSON.deserialize(sw.skid.Item__r.Packaging_UOM__c, LisT<Id>.class));

                    if (sw.skid.Input_Quantity__c != null) { //Selling UOM
                        orderLineToUpdate.put('Quantity_Allocated__c', KSE.addQuantityToField((Decimal) orderLineToUpdate.get('Quantity_Allocated__c'), sw.skid.Input_Quantity__c));
                    }
                } else {
                    allocatedSkid.Material_Tracking__c = line.Id;
                }

                Boolean serialsToAllocate = false;
                for (Serial__c serial:sw.serialList) {
                    if (serial.Temporary_Value_Holder__c == 'Unallocate') {
                        serialsToUpdate.put(serial.Id, new Serial__c(Id = serial.Id, Allocated_SKID__c = null));
                    } else if (serial.Temporary_Value_Holder__c == 'Allocate') {
                        serialsToAllocate = true;
                        List<String> skidKey = SkidService3.generateKey(allocatedSkid, attributes);
                        Serial__c ser = new Serial__c(Id = serial.Id);
                        if (!serialMap.containsKey(skidKey)) serialMap.put(skidKey, new List<Serial__c>{ ser });
                        else serialMap.get(skidKey).add(ser);
                    }
                }

                if (serialsToAllocate || (sw.skid.Input_Quantity__c != null && sw.skid.Input_Quantity__c != 0)) {
                    if (sw.skid.Input_Quantity__c != null) {
                        if (allocatedSkid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) lineToUpdate.put('Quantity_Allocated__c', (Decimal)lineToUpdate.get('Quantity_Allocated__c') + sw.skid.Input_Quantity__c);  //Selling UOM
                        else lineToUpdate.put('Quantity_To_Pick__c', (Decimal)lineToUpdate.get('Quantity_To_Pick__c') + (sw.skid.Input_Quantity__c * wrapper.convFactor)); //Stocking UOM
                    }
                    skidsToPutaway.add(new SkidService3.SerialWrapper(allocatedSkid, new List<Serial__c>()));
                }
            }

            if (demandSkid != null) {
                if (demandSkid.Quantity__c != 0) skidsToPutaway.add(new SkidService3.SerialWrapper(demandSkid, new List<Serial__c>()));

                Shipment__c shipment = (Shipment__c)header;
                Shipment_Line__c shl = (Shipment_Line__c)line;
                Shipment_Line__c shlToUpdate = (Shipment_Line__c)lineToUpdate;

                if (shipment.Status__c != ShipmentService.SHIPMENT_STATUS_STAGED) {
                    if (shlToUpdate.Quantity_Allocated__c > 0 || shlToUpdate.Quantity_To_Pick__c > 0) {
                        recsToUpdateMap.put(shipment.Id, new Shipment__c(Id = shipment.Id, Status__c = ShipmentService.SHIPMENT_STATUS_RELEASED));
                        headerIds.remove(shipment.Id);
                    } else if (!recsToUpdateMap.containsKey(shipment.Id) && shipment.Status__c == ShipmentService.SHIPMENT_STATUS_RELEASED) {
                        headerIds.add(shipment.Id);
                    }
                }
            } else {
                Work_Order__c wo = (Work_Order__c)header;
                Material_Tracking__c material = (Material_Tracking__c)line;
                Material_Tracking__c materialToUpdate = (Material_Tracking__c)lineToUpdate;

                if (wo.Status__c != WorkOrderService.WO_STATUS_COMPLETE) {
                    if (materialToUpdate.Quantity_Allocated__c > 0 || material.Quantity_Issued__c > 0) {
                        recsToUpdateMap.put(wo.Id, new Work_Order__c(Id = wo.Id, Status__c = WorkOrderService.WO_STATUS_IN_PROCESS));
                        headerIds.remove(wo.Id);
                    } else if (!recsToUpdateMap.containsKey(wo.Id) && wo.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS) {
                        headerIds.add(wo.Id);
                    }
                }
            }

            recsToUpdate.add(lineToUpdate);
        }

        Map<List<String>, SkidService3.SerialWrapper> toSkids = skidsToPutaway.size() > 0 ? SkidService3.putAwayService(skidsToPutaway, attributes, new Map<String,Boolean>{ SkidService3.DELETE_SKIDS => true }) : new Map<List<String>, SkidService3.SerialWrapper>();
        
        for (List<String> skidKey:serialMap.keySet()) {
            for (Serial__c serial:serialMap.get(skidKey)) {
                serial.Allocated_SKID__c = toSkids.get(skidKey).skid.Id;
                serialsToUpdate.put(serial.Id, serial);
            }
        }
        if (serialsToUpdate.size() > 0) DML.updateAsSystem(serialsToUpdate.values());

        if (headerIds.size() > 0) {
            SOQLUtil headerQuery = new SOQLUtil(isShipment ? 'Shipment__c' : 'Work_Order__c');
            headerQuery.addField('Id');
            headerQuery.setWhereClause('Id IN :headerIds');

            SOQLUtil.ChildRelationship lineQuery = new SOQLUtil.ChildRelationship(headerQuery, isShipment ? 'Shipment_Lines__r' : 'Material_Trackings__r');
            lineQuery.addField('Id');
            lineQuery.addFields(isShipment ? new Set<String>{ 'Quantity_Allocated__c', 'Quantity_To_Pick__c' } : new Set<String>{ 'Quantity_Allocated__c', 'Quantity_Issued__c', 'Quantity_Completed__c' });
            lineQuery.setWhereClause('Id NOT IN :lineIds');
            headerQuery.addChildRelationship(lineQuery);

            for (sObject header:Database.query(headerQuery.getQuery())) {
                Boolean hasQty = false;
                for (sObject line:header.getSObjects(isShipment ? 'Shipment_Lines__r' : 'Material_Trackings__r')) {
                    if ((Decimal)line.get('Quantity_Allocated__c') > 0 || (isShipment && (Decimal)line.get('Quantity_To_Pick__c') > 0) || (!isShipment && ((Decimal)line.get('Quantity_Issued__c') > 0 || (Decimal)line.get('Quantity_Completed__c') > 0))) {
                        hasQty = true;
                        break;
                    }
                }
                if (!hasQty) {
                    sObject rec = isShipment ? Shipment__c.sObjectType.newSObject(header.Id) : Work_Order__c.sObjectType.newSObject(header.Id);
                    rec.put('Status__c', isShipment ? ShipmentService.SHIPMENT_STATUS_PLANNED : WorkOrderService.WO_STATUS_RELEASED);
                    recsToUpdate.add(rec);
                }
            }
        }

        if (recsToUpdateMap.size() > 0) recsToUpdate.addAll(recsToUpdateMap.values());
        if (recsToUpdate.size() > 0) {
            recsToUpdate.sort();
            WorkOrderService.allowWorkOrderUpdate = true;
            DML.updateAsUser(recsToUpdate);
            WorkOrderService.allowWorkOrderUpdate = false;
        }
    }

    public static void autoAllocate(Map<Id,Map<Id,List<SkidService3.SerialWrapper>>> skidsToAllocate) {
        if (skidsToAllocate == null || skidsToAllocate.size() == 0) return;

        Set<Id> headerIds = skidsToAllocate.keySet();
        Set<Id> lineIds = new Set<Id>();
        for (Map<Id,List<SkidService3.SerialWrapper>> linesToAllocate:skidsToAllocate.values()) {
            lineIds.addAll(linesToAllocate.keySet());
        }

        Boolean isShipment = new List<Id>(headerIds)[0].getSObjectType() == Shipment__c.sObjectType;

        List<sObject> records = isShipment ? (List<sObject>)ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Id' => '(\'' + String.join(new List<Id>(lineIds), '\',\'') + '\')' }, 'allocate') : (List<sObject>)WorkOrderService.getWorkOrders(headerIds, null, null, new Set<String>{ 'Material_Trackings__r' });

        validate(records);

        Id companyId;
        Map<Id, sObject> lineMap = new Map<Id, sObject>();
        Map<Id, Item__c> items = new Map<Id, Item__c>();
        for (sObject record:records) {
            if (isShipment) {
                lineMap.put(record.Id, record);
                companyId = (Id)record.get('Company__c');
                items.put((Id)record.get('Item__c'), (Item__c)record.getSObject('Item__r'));
            } else {
                companyId = (Id)record.get('Company__c');
                for (Material_Tracking__c material:(List<Material_Tracking__c>)record.getSObjects('Material_Trackings__r')) {
                    lineMap.put(material.Id, material);
                }
            }
        }

        Map<Id, LineWrapper> wrappers = new Map<Id, LineWrapper>();
        for (LineWrapper wrapper:isShipment ? getInventory(records) : getLines(headerIds)) {
            wrappers.put(wrapper.line.Id, wrapper);

            if (!isShipment) items.put((Id)wrapper.line.get('Item__c'), (Item__c)wrapper.line.getSObject('Item__r'));
        }

        Map<Id,List<String>> attributes = getSkidAttributes(companyId,items);

        List<LineWrapper> wrappersToAllocate = new List<LineWrapper>();
        Map<List<String>,SkidService3.SerialWrapper> swMap1 = new Map<List<String>,SkidService3.SerialWrapper>();
        
        for (Map<Id,List<SkidService3.SerialWrapper>> linesToAllocate:skidsToAllocate.values()) {
            for (Id lineId:linesToAllocate.keySet()) {
                if (!wrappers.containsKey(lineId)) {
                    throw new AllocationException((String)lineMap.get(lineId).get('Name') + ' is not available for allocation');
                }

                LineWrapper wrapper = wrappers.get(lineId);
                List<SkidService3.SerialWrapper> swList = linesToAllocate.get(lineId);
                List<String> attrs = attributes.get(swList[0].skid.Item__c);
                Map<List<String>,SkidService3.SerialWrapper> swMap = new Map<List<String>,SkidService3.SerialWrapper>();

                if (isShipment) {
                    wrapper.line = lineMap.get(lineId);
                    wrapper.header = wrapper.line.getSObject('Shipment__r');
                }

                for (SkidService3.SerialWrapper sw:swList) {
                    List<String> key = SkidService3.generateKey(sw.skid,attrs);

                    sw.skid.Quantity_Allocated__c = 0;
                    sw.skid.Input_Quantity__c = sw.skid.Input_Quantity__c / wrapper.convFactor;
                    sw.skid.Quantity_Available__c = sw.skid.Input_Quantity__c;

                    for (Serial__c serial:sw.serialList) {
                        serial.Temporary_Value_Holder__c = 'Allocate';
                    }

                    if (swMap.containsKey(key)) {
                        SkidService3.SerialWrapper existingSW = swMap.get(key);
                        existingSW.skid.Input_Quantity__c += sw.skid.Input_Quantity__c;
                        existingSW.serialList.addAll(sw.serialList);
                    } else {
                        sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
                        swMap.put(key,sw);
                    }

                    if (swMap1.containsKey(key)) {
                        SkidService3.SerialWrapper existingSW = swMap1.get(key);
                        existingSW.skid.Quantity_Available__c += sw.skid.Quantity_Available__c;
                    } else {
                        swMap1.put(key, sw);
                    }
                }

                if (swMap.size() > 0) {
                    wrapper.serialWrappers = swMap.values();
                    wrappersToAllocate.add(wrapper);
                }
            }
        }

        if (wrappersToAllocate.size() > 0) allocate(wrappersToAllocate);
    }

    public static void autoUnallocate(Map<Id,Map<Id,List<SkidService3.SerialWrapper>>> skidsToUnallocate) {
        if (skidsToUnallocate == null || skidsToUnallocate.size() == 0) return;

        Set<Id> headerIds = skidsToUnallocate.keySet();
        Set<Id> lineIds = new Set<Id>();
        for (Map<Id,List<SkidService3.SerialWrapper>> linesToUnallocate:skidsToUnallocate.values()) {
            lineIds.addAll(linesToUnallocate.keySet());
        }

        Boolean isShipment = new List<Id>(headerIds)[0].getSObjectType() == Shipment__c.sObjectType;

        List<sObject> records = isShipment ? (List<sObject>)ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Id' => '(\'' + String.join(new List<Id>(lineIds), '\',\'') + '\')' }, 'allocate') : (List<sObject>)WorkOrderService.getWorkOrders(headerIds, null, null, new Set<String>{ 'Material_Trackings__r' });

        validate(records);

        Id companyId;
        Map<Id, sObject> lineMap = new Map<Id, sObject>();
        Map<Id, Item__c> items = new Map<Id, Item__c>();
        for (sObject record:records) {
            if (isShipment) {
                lineMap.put(record.Id, record);
                companyId = (Id)record.get('Company__c');
                items.put((Id)record.get('Item__c'), (Item__c)record.getSObject('Item__r'));
            } else {
                companyId = (Id)record.get('Company__c');
                for (Material_Tracking__c material:(List<Material_Tracking__c>)record.getSObjects('Material_Trackings__r')) {
                    lineMap.put(material.Id, material);
                }
            }
        }

        Map<Id, LineWrapper> wrappers = new Map<Id, LineWrapper>();
        for (LineWrapper wrapper:isShipment ? getInventory(records) : getLines(headerIds)) {
            wrappers.put(wrapper.line.Id, wrapper);

            if (!isShipment) items.put((Id)wrapper.line.get('Item__c'), (Item__c)wrapper.line.getSObject('Item__r'));
        }

        Map<Id,List<String>> attributes = getSkidAttributes(companyId,items);

        List<LineWrapper> wrappersToUnallocate = new List<LineWrapper>();
        for (Map<Id,List<SkidService3.SerialWrapper>> linesToUnallocate:skidsToUnallocate.values()) {
            for (Id lineId:linesToUnallocate.keySet()) {
                if (!wrappers.containsKey(lineId)) {
                    throw new AllocationException((String)lineMap.get(lineId).get('Name') + ' is not available for unallocation');
                }

                LineWrapper wrapper = wrappers.get(lineId);
                List<SkidService3.SerialWrapper> swList = linesToUnallocate.get(lineId);
                List<String> attrs = attributes.get(swList[0].skid.Item__c);

                if (isShipment) {
                    wrapper.line = lineMap.get(lineId);
                    wrapper.header = wrapper.line.getSObject('Shipment__r');
                }

                Map<List<String>,SkidService3.SerialWrapper> swMap = new Map<List<String>,SkidService3.SerialWrapper>();
                for (SkidService3.SerialWrapper sw:swList) {
                    List<String> key = SkidService3.generateKey(sw.skid,attrs);

                    sw.skid.Input_Quantity__c = sw.skid.Input_Quantity__c / wrapper.convFactor;
                    for (Serial__c serial:sw.serialList) {
                        serial.Temporary_Value_Holder__c = 'Unallocate';
                    }

                    if (swMap.containsKey(key)) {
                        SkidService3.SerialWrapper existingSW = swMap.get(key);
                        existingSW.skid.Input_Quantity__c += sw.skid.Input_Quantity__c;
                        existingSW.serialList.addAll(sw.serialList);
                    } else {
                        swMap.put(key,sw);
                    }
                }

                List<SkidService3.SerialWrapper> swsToUnallocate = new List<SkidService3.SerialWrapper>();
                for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                    SKID__c skidClone = sw.skid.clone(false, true);
                    skidClone.Shipment_Line__c = null;
                    skidClone.Material_Tracking__c = null;
                    List<String> key = SkidService3.generateKey(skidClone, attrs);
                    
                    if (swMap.containsKey(key)) {
                        SkidService3.SerialWrapper swToUnallocate = swMap.get(key);
                        if (swToUnallocate.serialList.size() > 0) {
                            Map<Id,Serial__c> serials = new Map<Id,Serial__c>(sw.serialList);
                            List<Serial__c> serialsToUnallocate = new List<Serial__c>();
                            for (Serial__c serial:swToUnallocate.serialList) {
                                if (serials.containsKey(serial.Id) && serial.Allocated_SKID__c != null) {
                                    serialsToUnallocate.add(serial);
                                }
                            }
                            
                            if(serialsToUnallocate.size()>0){
                                sw.skid.Input_Quantity__c = (-serialsToUnallocate.size());
                            }
                            else{
                                sw.skid.Input_Quantity__c = -Math.min(sw.skid.Quantity_Allocated__c,swToUnallocate.skid.Input_Quantity__c);
                            }
                            
                            sw.serialList = serialsToUnallocate;
                        } else {
                            sw.skid.Input_Quantity__c = -Math.min(sw.skid.Quantity_Allocated__c,swToUnallocate.skid.Input_Quantity__c);
                        }

                        if (sw.skid.Input_Quantity__c < 0) {
                            sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
                            swsToUnallocate.add(sw);
                        }
                    }
                }

                if (swsToUnallocate.size() > 0) {
                    wrapper.serialWrappers = swsToUnallocate;
                    wrappersToUnallocate.add(wrapper);
                }
            }
        }

        if (wrappersToUnallocate.size() > 0) allocate(wrappersToUnallocate);
    }

    public static Map<Id,List<String>> getSkidAttributes(Id companyId, Map<Id,Item__c> items) { return getSkidAttributes(companyId, items, false); }
    public static Map<Id,List<String>> getSkidAttributes(Id companyId, Map<Id,Item__c> items, Boolean fromApi) {
        Map<String,Schema.SObjectField> profileFields = SchemaUtil.getInstance().getFieldsMap('Allocation_Profile__c');
        Company__c companyObj;
        Set<Id> itemIds = new Set<Id>();
        SOQLUtil profileQuery = new SOQLUtil('Allocation_Profile__c');
        profileQuery.addAllCustomFields();
        profileQuery.addFields(new set<string>{'company__r.Auto_Plan_Pick__c', 'company__r.Name'});
        profileQuery.setWhereClause('Company__c = :companyId OR Item__c IN :itemIds');
        
        Map<Id, Allocation_Profile__c> profiles = new Map<Id, Allocation_Profile__c>();
        Allocation_Profile__c companyProfile;
        for (Allocation_Profile__c profile:Database.query(profileQuery.getQuery())) {
            if (profile.Item__c != null) profiles.put(profile.Item__c, profile);
            else companyProfile = profile;
            
            if(companyObj ==null){
                companyObj = profile.Company__r;
            }
        }
        if (companyProfile == null) {
            companyProfile = new Allocation_Profile__c(Location__c = true);
            for (String attr:SkidService3.attributeFields) {
                if (profileFields.containsKey(attr)) companyProfile.put(attr, true);
            }
        }
        
        if(companyObj ==null){
            
            SOQLUtil soql = new SOQLUtil('Company__c');
    		soql.addFields(new set<string>{'Id','Name','Auto_Plan_Pick__c'});
    		soql.setWhereClause('Id = :companyId');
    		string query = soql.getQuery();
    		
    		companyObj = Database.query(query);
        }
        
        for (Id itemId:items.keySet()) {
            if (!profiles.containsKey(itemId)) profiles.put(itemId,companyProfile);
        }
        
        Map<Id,List<String>> skAttributes = new Map<Id,List<String>>();
        for (Item__c item:items.values()) {
            Item_Attribute__c itemAttr = item.Item_Attribute__r;
            Allocation_Profile__c profile = profiles.get(item.Id);

            Set<String> attrsToExclude = new Set<String>();
            if (!profile.Location__c) attrsToExclude.add('location__c');
            for (String attr:SkidService3.attributeFields) {
                if (itemAttr == null || (Boolean)itemAttr.get(attr) == false || (profileFields.containsKey(attr) && (Boolean)profile.get(attr) == false)) {
                    attrsToExclude.add(attr.toLowerCase());
                }
            }

            skAttributes.put(item.Id, getSkidFieldList(attrsToExclude, fromApi,companyObj));
        }
        return skAttributes;
    }

    public static List<String> getSkidFieldList(Set<String> attrsToExclude,Company__c company) { return getSkidFieldList(attrsToExclude, false,company); }
    public static List<String> getSkidFieldList(Set<String> attrsToExclude, Boolean fromApi,Company__c company) {
        if (attrsToExclude == null) attrsToExclude = new Set<String>();
        
        List<String> skidFieldList = new List<String>{ 'Item__c', 'Facility2__c' };

        if (!attrsToExclude.contains('location__c')) {
            skidFieldList.add('Location__c');
            skidFieldList.add('Bin__c');
        }

        skidFieldList.addAll(new List<String>{ 'Customer__c', 'Consigned_Owner__c' });

        for (String attr:SkidService3.attributeFields) {
            if (!SkidService3.attributesToExclude.contains(attr.toLowerCase()) && !attrsToExclude.contains(attr.toLowerCase())) {
                if (attr == 'Lot_Number__c' && fromApi == false) skidFieldList.add('Lot__c');
                else skidFieldList.add(attr);
            }
        }

        skidFieldList.addAll(new List<String>{ 'Shipment_Line__c', 'Purchase_Order_Line__c', 'Receipt_Line__c', 'Material_Tracking__c' });
		if(company !=null && company.Auto_Plan_Pick__c){
        	skidFieldList.add('Sales_Order_Line__c');
        }
        return skidFieldList;
    }

	public static List<FieldInfo> getSkidFIList(List<String> skidFieldList,Company__c company) {
        if (skidFieldList == null) skidFieldList = getSkidFieldList(null,company);
        skidFieldList.addAll(new List<String>{ 'Quantity_Allocated__c', 'Quantity_Available__c', 'Input_Quantity__c' });
        return FieldInfo.fetchJsonFieldInfos('SKID__c', skidFieldList);
    }

    public static String getSkidQueryFromAllocatedSkids(List<SKID__c> allocatedSkids,Map<Id,List<String>> skAttributes,Map<String,List<Location__c>> locationMap) {
        Map<String,Schema.SObjectField> skidFields = SchemaUtil.getInstance().getFieldsMap('SKID__c');
        
        Map<Id,Map<String,Set<Object>>> queryFilters = new Map<Id,Map<String,Set<Object>>>();
        for (SKID__c skid:allocatedSkids) {
            Id lineId, lineForLocations;
            if (skid.Shipment_Line__c != null) {
                lineId = skid.Shipment_Line__c;
                lineForLocations = skid.Shipment_Line__r.Sales_Order_Line__c != null ? skid.Shipment_Line__r.Sales_Order_Line__c : skid.Shipment_Line__r.Order_Line__c;
            } else if (skid.Material_Tracking__c != null) {
                lineId = skid.Material_Tracking__c;
                lineForLocations = skid.Material_Tracking__c;
            }
            
            List<String> attrs = skAttributes.get(skid.Item__c);
            Map<String,Set<Object>> attrMap = queryFilters.containsKey(lineId) ? queryFilters.get(lineId) : new Map<String,Set<Object>>();
            for (String attr:attrs) {
                Set<Object> attrSet = attrMap.containsKey(attr) ? attrMap.get(attr) : new Set<Object>();
                attrSet.add(skid.get(attr));
                attrMap.put(attr,attrSet);
            }

            if (!attrMap.containsKey('Location__c') && locationMap != null && locationMap.containsKey(lineForLocations)) {
                Set<Object> locationIds = new Set<Object>();
                for (Location__c loc:locationMap.get(lineForLocations)) {
                    locationIds.add(loc.Id);
                }
                attrMap.put('Location__c',locationIds);
            }

            queryFilters.put(lineId,attrMap);
        }
        
        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.addField('Lot__r.Lot_Hold__c');
        skidQuery.addAllCustomFields(Location__c.sObjectType,'Location__r');
        
        String whereClause = '(';
        for (Map<String,Set<Object>> attrMap:queryFilters.values()) {
            if (whereClause != '(') {
                whereClause += ' OR ';
            }
            whereClause += '(';
            List<String> attrList = new List<String>(attrMap.keySet());
            for (Integer i=0;i<attrList.size();i++) {
                String attr = attrList[i];
                Schema.DisplayType attrType = skidFields.get(attr).getDescribe().getType();
                Set<Object> valSet = attrMap.get(attr);

                Boolean hasNull = valSet.contains(null);
                valSet.remove(null);

                if (i != 0) {
                    whereClause += ' AND ';
                }
                whereClause += attr + ' IN (';
                if (attrType == Schema.DisplayType.Boolean || attrType == Schema.DisplayType.Integer || attrType == Schema.DisplayType.Double || attrType == Schema.DisplayType.Percent || attrType == Schema.DisplayType.Currency) {
                    whereClause += String.join(new List<Object>(valSet),',');
                } else if (attrType == Schema.DisplayType.Date || attrType == Schema.DisplayType.DateTime) {
                    List<Object> valList = new List<Object>(valSet);
                    for (Integer j=0;j<valList.size();j++) {
                        Object val = valList[j];

                        Integer year;
                        Integer month;
                        Integer day;
                        Integer hour;
                        Integer minute;
                        Integer second;

                        if (attrType == Schema.DisplayType.Date) {
                            Date d = (Date)val;
                            year = d.year();
                            month = d.month();
                            day = d.day();
                        } else if (attrType == Schema.DisplayType.DateTime) {
                            DateTime dt = (DateTime)val;
                            year = dt.yearGmt();
                            month = dt.monthGmt();
                            day = dt.dayGmt();
                            hour = dt.hourGmt();
                            minute = dt.minuteGmt();
                            second = dt.secondGmt();
                        }

                        if (j != 0) {
                            whereClause += ',';
                        }
                        whereClause += year + '-' + (month < 10 ? '0' : '') + month + '-' + (day < 10 ? '0' : '') + day + (attrType == Schema.DisplayType.DateTime ? ('T' + (hour < 10 ? '0' : '') + hour + ':' + (minute < 10 ? '0' : '') + minute + ':' + (second < 10 ? '0' : '') + second + 'Z') : '');
                    }
                } else {
                    whereClause += valSet.size() > 0 ? '\'' + String.join(new List<Object>(valSet),'\',\'') + '\'' : '';
                }
                whereClause += (hasNull ? (valSet.size() > 0 ? ',null' : 'null') : '') + ')';
            }
            whereClause += ')';
        }
        whereClause += ') AND Type__c = \'' + SkidService3.SKID_TYPE_LOCATION + '\' AND Shipment_Line__c = null';
        skidQuery.setWhereClause(whereClause);
        
        return skidQuery.getQuery();
    }

    public static OTC__c getOtc(Shipment_Line__c shl) {
        String otcCompany = shl.Company__c;
        otcCompany = 'CompanyId=' + otcCompany.substring(0, otcCompany.length() - 3);
        return OTC__c.getInstance(otcCompany);
    }

    private static GridRelatedListController.GridRelatedListConfig lineConfig { get; set; }
    public static GridRelatedListController.GridRelatedListConfig getLineConfig(sObjectType objType) {
        if (lineConfig == null) {
            lineConfig = new GridRelatedListController.GridRelatedListConfig();
            lineConfig.buttons = 'Expand All,Collapse All';
            if (objType == Material_Tracking__c.sObjectType) {
                lineConfig.buttons += ',Populate Quantities';
            }
            lineConfig.buttons += ',Unallocate All';
        }
        return lineConfig;
    }

    private static List<FieldInfo> lineFields { get; set; }
    public static List<FieldInfo> getLineFields(String objName) {
        if (lineFields == null) {
            lineFields = FieldInfo.fetchJsonFieldInfos(objName,'Allocate');
            lineFields.remove(0);
            for (FieldInfo fi:lineFields) {
                fi.field = 'line.' + fi.field;
                fi.editable = false;
            }
        }
        return lineFields;
    }

    public static List<FieldInfo> skidFields {
        get {
            if (skidFields == null) skidFields = getSkidFIList(null,null);
            return skidFields;
        } set;
    }

    public static List<FieldInfo> serialFields {
        get {
            if (serialFields == null) {
                serialFields = new List<FieldInfo>{ new FieldInfo('', '', 'integer') };
                serialFields.addAll(FieldInfo.fetchJsonFieldInfos('Serial__c', 'Serial', SkidService3.serialAttributes.size() > 0 ? String.join(SkidService3.serialAttributes, ',') : null, true));
            }
            return serialFields;
        } set;
    }

    public static Integer gridSize {
        get {
            if (gridSize == null) gridSize = serialFields.size() * 150;
            return gridSize;
        } set;
    }

    public class AllocationException extends Exception { }
}