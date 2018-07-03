@isTest
private class WorkOrderAllocationTest {
    @testSetup
    private static void setupData() {
        TestFuel fuel = new TestFuel();
        System.assert(fuel.smrsList != null);
        System.assert(fuel.stockMovementRuleList != null);
        System.assert(fuel.workOrder != null);
        System.assert(fuel.itemAttrObj2 != null);
        update new Company__c(Id = fuel.company.Id, Serial_Control__c = SkidService3.AT_RECEIPT);
        update new Component__c(Id = fuel.components[0].Id, Allocation_Required__c = true);
        WorkOrderPlanningService.release(new Set<Id>{ fuel.workOrder.Id });
    }

    public static TestFuelQuery fuel = new TestFuelQuery();

    private static void setupInventory(Boolean attributes,Boolean serials) {
        Map<Id,Lot__c> lots = new Map<Id,Lot__c>();
        List<SKID__c> skids = new List<SKID__c>();
        for (Item__c item:fuel.itemList) {
            SKID__c skid1 = new SKID__c(
                Company__c = fuel.company.Id,
                Item__c = item.Id,
                Facility2__c = fuel.facility2.Id,
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
                lots.put(item.Id,new Lot__c(Name = 'Lot1', Item__c = item.Id, Company__c = fuel.company.Id,Expiration_Date__c = System.today() + 365));

                skid1.Expiration_Date__c = System.today() + 365;

                if (serials) {
                    item.Item_Attribute__c = fuel.itemAttrObj2.Id;

                    skid1.Quantity__c = 10;
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
                skid.Lot_Number__c = lots.get(skid.Item__c).Name;

                if (serials) {
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

    private static testMethod void testAllocateNoAttributes() {
        setupInventory(false,false);

        Work_Order__c wo = fuel.workOrder;

        WorkOrderAllocationExt ext = new WorkOrderAllocationExt(new ApexPages.StandardController(wo));
        String str = ext.woJson;
        str = ext.materialConfigJson;
        str = ext.materialFieldsJson;
        str = ext.skidFieldsJson;
        str = ext.serialFieldsJson;
        str = ext.serialAttributesJson;
        Integer i = ext.gridSize;
        ext.cancel();

        JsonResult result = WorkOrderAllocationExt.getMaterialData(wo.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);
        List<LineWrapper> mData = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:mData) {
            System.assert(wrapper.serialWrappers.size() == 2,wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 0,sw);
                sw.skid.Input_Quantity__c = 2;
            }
        }

        result = WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());
        System.assert(result.success,result);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.addAllCustomFields(Material_Tracking__c.sObjectType,'Material_Tracking__r');
        skidQuery.addAllCustomFields(Work_Order__c.sObjectType,'Material_Tracking__r.Work_Order__r');
        skidQuery.setWhereClause('Material_Tracking__r.Work_Order__c = \'' + wo.Id + '\'');
        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2,skids);

        for (SKID__c skid:skids) {
            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 2,skid);
                System.assert(skid.Material_Tracking__r.Quantity_Allocated__c == 4,skid.Material_Tracking__r);
                System.assert(skid.Material_Tracking__r.Work_Order__r.Status__c == 'In Process',skid.Material_Tracking__r.Work_Order__r);
            } else {
                System.assert(false,'Unexpected skid type: ' + skid.Type__c);
            }
        }

        result = WorkOrderAllocationExt.getMaterialData(wo.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);
        mData = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:mData) {
            System.assert(wrapper.serialWrappers.size() == 2,wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 2,sw);
                sw.skid.Input_Quantity__c = 1;
            }
        }

        result = WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());
        System.assert(result.success,result);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2,skids);

        for (SKID__c skid:skids) {
            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 3,skid);
                System.assert(skid.Material_Tracking__r.Quantity_Allocated__c == 6,skid.Material_Tracking__r);
                System.assert(skid.Material_Tracking__r.Work_Order__r.Status__c == 'In Process',skid.Material_Tracking__r.Work_Order__r);
            } else {
                System.assert(false,'Unexpected skid type: ' + skid.Type__c);
            }
        }

        Test.startTest();

        result = WorkOrderAllocationExt.getMaterialData(wo.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);
        mData = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:mData) {
            System.assert(wrapper.serialWrappers.size() == 2,wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 3,sw);
                sw.skid.Input_Quantity__c = -2;
            }
        }

        result = WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());
        System.assert(result.success,result);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2,skids);

        for (SKID__c skid:skids) {
            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 1,skid);
                System.assert(skid.Material_Tracking__r.Quantity_Allocated__c == 2,skid.Material_Tracking__r);
                System.assert(skid.Material_Tracking__r.Work_Order__r.Status__c == 'In Process',skid.Material_Tracking__r.Work_Order__r);
            } else {
                System.assert(false,'Unexpected skid type: ' + skid.Type__c);
            }
        }

        result = WorkOrderAllocationExt.getMaterialData(wo.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);
        mData = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:mData) {
            System.assert(wrapper.serialWrappers.size() == 2,wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 1,sw);
                sw.skid.Input_Quantity__c = -1;
            }
        }

        result = WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());
        System.assert(result.success,result);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0,skids);

        Test.stopTest();
    }

    private static testMethod void testAllocateAttributes() {
        setupInventory(true,false);

        Work_Order__c wo = fuel.workOrder;

        JsonResult result = WorkOrderAllocationExt.getMaterialData(wo.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);
        List<LineWrapper> mData = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:mData) {
            System.assert(wrapper.serialWrappers.size() == 2,wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 0,sw);
                System.assert(sw.skid.Lot_Number__c != null,sw);
                sw.skid.Input_Quantity__c = 2;
            }
        }

        result = WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());
        System.assert(result.success,result);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.addAllCustomFields(Material_Tracking__c.sObjectType,'Material_Tracking__r');
        skidQuery.addAllCustomFields(Work_Order__c.sObjectType,'Material_Tracking__r.Work_Order__r');
        skidQuery.setWhereClause('Material_Tracking__r.Work_Order__c = \'' + wo.Id + '\'');
        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2,skids);

        for (SKID__c skid:skids) {
            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 2,skid);
                System.assert(skid.Material_Tracking__r.Quantity_Allocated__c == 4,skid.Material_Tracking__r);
                System.assert(skid.Material_Tracking__r.Work_Order__r.Status__c == 'In Process',skid.Material_Tracking__r.Work_Order__r);
            } else {
                System.assert(false,'Unexpected skid type: ' + skid.Type__c);
            }
        }

        result = WorkOrderAllocationExt.getMaterialData(wo.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);
        mData = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:mData) {
            System.assert(wrapper.serialWrappers.size() == 2,wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 2,sw);
                System.assert(sw.skid.Lot_Number__c != null,sw);
                sw.skid.Input_Quantity__c = 1;
            }
        }

        result = WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());
        System.assert(result.success,result);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2,skids);

        for (SKID__c skid:skids) {
            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 3,skid);
                System.assert(skid.Material_Tracking__r.Quantity_Allocated__c == 6,skid.Material_Tracking__r);
                System.assert(skid.Material_Tracking__r.Work_Order__r.Status__c == 'In Process',skid.Material_Tracking__r.Work_Order__r);
            } else {
                System.assert(false,'Unexpected skid type: ' + skid.Type__c);
            }
        }

        Test.startTest();

        result = WorkOrderAllocationExt.getMaterialData(wo.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);
        mData = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:mData) {
            System.assert(wrapper.serialWrappers.size() == 2,wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 3,sw);
                System.assert(sw.skid.Lot_Number__c != null,sw);
                sw.skid.Input_Quantity__c = -2;
            }
        }

        result = WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());
        System.assert(result.success,result);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2,skids);

        for (SKID__c skid:skids) {
            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 1,skid);
                System.assert(skid.Material_Tracking__r.Quantity_Allocated__c == 2,skid.Material_Tracking__r);
                System.assert(skid.Material_Tracking__r.Work_Order__r.Status__c == 'In Process',skid.Material_Tracking__r.Work_Order__r);
            } else {
                System.assert(false,'Unexpected skid type: ' + skid.Type__c);
            }
        }

        result = WorkOrderAllocationExt.getMaterialData(wo.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);
        mData = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:mData) {
            System.assert(wrapper.serialWrappers.size() == 2,wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 1,sw);
                System.assert(sw.skid.Lot_Number__c != null,sw);
                sw.skid.Input_Quantity__c = -1;
            }
        }

        result = WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());
        System.assert(result.success,result);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0,skids);

        Test.stopTest();
    }

    private static testMethod void testAllocateSerials() {
        setupInventory(true,true);

        Work_Order__c wo = fuel.workOrder;

        JsonResult result = WorkOrderAllocationExt.getMaterialData(wo.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);
        List<LineWrapper> mData = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:mData) {
            System.assert(wrapper.serialWrappers.size() == 2,wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 0,sw);
                System.assert(sw.skid.Lot_Number__c != null,sw);
                System.assert(sw.serialList.size() == 10,sw);
                sw.skid.Input_Quantity__c = 2;

                sw.serialList[0].Temporary_Value_Holder__c = 'Allocate';
                sw.serialList[1].Temporary_Value_Holder__c = 'Allocate';
            }
        }

        result = WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());
        System.assert(result.success,result);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.addAllCustomFields(Material_Tracking__c.sObjectType,'Material_Tracking__r');
        skidQuery.addAllCustomFields(Work_Order__c.sObjectType,'Material_Tracking__r.Work_Order__r');
        skidQuery.setWhereClause('Material_Tracking__r.Work_Order__c = \'' + wo.Id + '\'');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery,'Allocated_Serials__r');
        serialQuery.addAllCustomFields();
        skidQuery.addChildRelationship(serialQuery);

        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2,skids);

        for (SKID__c skid:skids) {
            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 2,skid);
                System.assert(skid.Material_Tracking__r.Quantity_Allocated__c == 4,skid.Material_Tracking__r);
                System.assert(skid.Material_Tracking__r.Work_Order__r.Status__c == 'In Process',skid.Material_Tracking__r.Work_Order__r);
                System.assert(skid.Allocated_Serials__r.size() == skid.Quantity__c,skid.Allocated_Serials__r);
            } else {
                System.assert(false,'Unexpected skid type: ' + skid.Type__c);
            }
        }

        result = WorkOrderAllocationExt.getMaterialData(wo.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);
        mData = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:mData) {
            System.assert(wrapper.serialWrappers.size() == 2,wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 2,sw);
                System.assert(sw.skid.Lot_Number__c != null,sw);
                System.assert(sw.serialList.size() == 10,sw);
                sw.skid.Input_Quantity__c = 1;

                Integer allocated = 0;
                Integer ct = 0;
                for (Serial__c serial:sw.serialList) {
                    if (serial.Allocated_SKID__c != null) {
                        serial.Temporary_Value_Holder__c = 'Allocated';
                        allocated++;
                    } else if (ct < 1) {
                        serial.Temporary_Value_Holder__c = 'Allocate';
                        ct++;
                    }
                }
                System.assert(allocated == 2);
            }
        }

        result = WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());
        System.assert(result.success,result);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2,skids);

        for (SKID__c skid:skids) {
            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 3,skid);
                System.assert(skid.Material_Tracking__r.Quantity_Allocated__c == 6,skid.Material_Tracking__r);
                System.assert(skid.Material_Tracking__r.Work_Order__r.Status__c == 'In Process',skid.Material_Tracking__r.Work_Order__r);
                System.assert(skid.Allocated_Serials__r.size() == skid.Quantity__c,skid.Allocated_Serials__r);
            } else {
                System.assert(false,'Unexpected skid type: ' + skid.Type__c);
            }
        }

        Test.startTest();

        result = WorkOrderAllocationExt.getMaterialData(wo.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);
        mData = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:mData) {
            System.assert(wrapper.serialWrappers.size() == 2,wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 3,sw);
                System.assert(sw.skid.Lot_Number__c != null,sw);
                System.assert(sw.serialList.size() == 10,sw);
                sw.skid.Input_Quantity__c = -2;

                Integer allocated = 0;
                Integer ct = 0;
                for (Serial__c serial:sw.serialList) {
                    if (serial.Allocated_SKID__c != null) {
                        allocated++;
                        if (ct < 2) {
                            serial.Temporary_Value_Holder__c = 'Unallocate';
                            ct++;
                        } else {
                            serial.Temporary_Value_Holder__c = 'Allocated';
                        }
                    }
                }
                System.assert(allocated == 3);
            }
        }

        result = WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());
        System.assert(result.success,result);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 2,skids);

        for (SKID__c skid:skids) {
            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                System.assert(skid.Quantity__c == 1,skid);
                System.assert(skid.Material_Tracking__r.Quantity_Allocated__c == 2,skid.Material_Tracking__r);
                System.assert(skid.Material_Tracking__r.Work_Order__r.Status__c == 'In Process',skid.Material_Tracking__r.Work_Order__r);
                System.assert(skid.Allocated_Serials__r.size() == skid.Quantity__c,skid.Allocated_Serials__r);
            } else {
                System.assert(false,'Unexpected skid type: ' + skid.Type__c);
            }
        }

        result = WorkOrderAllocationExt.getMaterialData(wo.Id);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result.records);
        mData = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:mData) {
            System.assert(wrapper.serialWrappers.size() == 2,wrapper.serialWrappers);
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                System.assert(sw.skid.Quantity_Allocated__c == 1,sw);
                System.assert(sw.skid.Lot_Number__c != null,sw);
                System.assert(sw.serialList.size() == 10,sw);
                sw.skid.Input_Quantity__c = -1;

                Integer allocated = 0;
                Integer ct = 0;
                for (Serial__c serial:sw.serialList) {
                    if (serial.Allocated_SKID__c != null) {
                        allocated++;
                        if (ct < 1) {
                            serial.Temporary_Value_Holder__c = 'Unallocate';
                        } else {
                            serial.Temporary_Value_Holder__c = 'Allocated';
                        }
                    }
                }
                System.assert(allocated == 1);
            }
        }

        result = WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());
        System.assert(result.success,result);

        skids = Database.query(skidQuery.getQuery());
        System.assert(skids.size() == 0,skids);

        Test.stopTest();
    }
}