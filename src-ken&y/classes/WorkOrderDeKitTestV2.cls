@isTest
private class WorkOrderDeKitTestV2 {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null && f.stockMovementRuleList != null && f.workOrder != null && f.itemAttrObj2 != null);

        update new Component__c(Id = fuel.components[0].Id, Type__c = ComponentService.TYPE_KIT, Routing__c = null);

        WorkOrderPlanningService.release(new Set<Id>{ f.workOrder.Id });
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

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
                Quantity_Stocking_UOM__c=100,
                Type__c = SkidService3.SKID_TYPE_LOCATION,
                Packaging_UOM__c = fuel.uomList[8].Id,
                Stocking_UOM__c = fuel.uomList[8].Id
            );

            if (!attributes && !serials) {
                item.Item_Attribute__c = null;
            } else if (attributes) {
                lots.put(item.Id,new Lot__c(Name = 'Lot1', Item__c = item.Id, Company__c = fuel.company.Id));

                skid1.Expiration_Date__c = System.today() + 365;
                skid1.Lot_Number__c = 'Lot1';

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

                if (serials) {
                    for (Integer i=0;i<10;i++) {
                        serialsToInsert.add(new Serial__c(
                            Name = '' + skid.Id + i,
                            Company__c = skid.Company__c,
                            Item__c = skid.Item__c,
                            SKID__c = skid.Id,
                            Unique_Key__c = '' + skid.Company__c + '-' + skid.Item__c + '-' + skid.Id + i
                        ));
                    }
                }
            }
        }

        if (attributes) update skids;
        if (serialsToInsert.size() > 0) insert serialsToInsert;
    }

    private static void kit(Boolean serials,Boolean allocation) {
        List<WorkOrderWrapper> kitRows = (List<WorkOrderWrapper>)WorkOrderKitExtV2.getKitData(fuel.workOrder.Id).records;
        kitRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;
        if (serials) {
            if (allocation) {
                for (Serial__c serial:kitRows[0].serialWrapperList[0].serialList) {
                    if (serial.Allocated_SKID__c != null) {
                        serial.Temporary_Value_Holder__c = 'Kit';
                    }
                }
            } else {
                for (Integer i=0;i<4;i++) {
                    kitRows[0].serialWrapperList[0].serialList[i].Temporary_Value_Holder__c = 'Kit';
                }
            }
        }
        WorkOrderKitExtV2.save(kitRows,new List<String>(),new List<String>());
    }

    private static List<WorkOrderWrapper> getDekitRows() {
        JsonResult result = WorkOrderDeKitExtV2.getDeKitData(fuel.workOrder.Id);
        System.assert(result.success,'WorkOrderDeKitExtV2.getDeKitData fail: ' + result);
        System.assert(result.records.size() == 1,'Expected lines: 1 // Lines: ' + result.records.size());

        List<WorkOrderWrapper> dekitRows = (List<WorkOrderWrapper>)result.records;
        System.assert(dekitRows[0].serialWrapperList.size() == 1,'Expected serial wrappers: 1 // Serial wrappers: ' + dekitRows[0].serialWrapperList.size());
        System.assert(dekitRows[0].serialWrapperList[0].skid.Location__c != null,'Expected skid location');

        result = WorkOrderDeKitExtV2.getLocations(dekitRows[0].serialWrapperList[0].skid.Location__c,null);
        System.assert(result.success,'WorkOrderDeKitExtV2.getLocations fail: ' + result);
        System.assert(result.records.size() == 1,'Expected locations: 1 // Locations: ' + result.records.size());

        dekitRows[0].serialWrapperList[0].skid.Location__r = (Location__c)result.records[0];

        return dekitRows;
    }

    private static void dekit(List<WorkOrderWrapper> dekitRows) {
        JsonResult result = WorkOrderDeKitExtV2.save(fuel.workOrder.Id,dekitRows,new List<String>(),new List<String>());
        System.assert(result.success,'WorkOrderDeKitExtV2.save: ' + result);
    }

    private static testMethod void noAttributes() {
        setupInventory(false,false);
        kit(false,false);

        Test.startTest();

        WorkOrderDeKitExtV2 ext = new WorkOrderDeKitExtV2(new ApexPages.StandardController(fuel.workOrder));
        ext.getWorkOrderJson();
        ext.getMtFieldList();
        ext.getSkidFieldList();
        ext.getDeKitConfigJson();

        List<WorkOrderWrapper> dekitRows = getDekitRows();

        dekitRows[0].serialWrapperList[0].skid.Temporary_Value_Holder1__c = '' + fuel.workOrder.MRB_Location__c + ',null';
        dekitRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 2;
        dekitRows[0].serialWrapperList[0].skid.Quantity_to_Scrap__c = 1;

        dekit(dekitRows);

        Test.stopTest();

        SOQLUtil icQuery = new SOQLUtil('Inventory_Change__c');
        icQuery.addAllCustomFields();
        icQuery.addAllCustomFields(Work_Order__c.sObjectType,'Work_Order__r');
        icQuery.setWhereClause('Work_Order__c = \'' + fuel.workOrder.Id + '\'');

        SOQLUtil.ChildRelationship itQuery = new SOQLUtil.ChildRelationship(icQuery,'Inventory_Transactions__r');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(Material_Tracking__c.sObjectType,'Material_Tracking__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        icQuery.addChildRelationship(itQuery);

        List<Inventory_Change__c> icList = Database.query(icQuery.getQuery());
        Boolean dekitICFound = false;
        for (Inventory_Change__c ic:Database.query(icQuery.getQuery())) {
            if (ic.Type__c != 'Work Order DeKit') {
                continue;
            }

            dekitICFound = true;

            System.assert(ic.Finalized__c,'Expected a finalized inventory change');
            System.assert(ic.Work_Order__r.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS,'Expected WO status: In Process // WO status: ' + ic.Work_Order__r.Status__c);
            System.assert(ic.Inventory_Transactions__r.size() == 2,'Expected ITs: 2 // ITs: ' + ic.Inventory_Transactions__r.size());

            for (Inventory_Transaction__c it:ic.Inventory_Transactions__r) {
                if (it.Type__c == 'Work Order Component Return') {
                    System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
                    System.assert(it.Quantity__c == 2,'Expected IT quantity: 2 // IT quantity: ' + it.Quantity__c);
                    System.assert(it.Material_Tracking__r.Quantity_Issued__c == 2,'Expected material quantity issued: 2 // Material quantity issued: ' + it.Material_Tracking__r.Quantity_Issued__c);

                    System.assert(it.From_SKID__c != null,'Expected not null IT from skid');
                    System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected IT from skid type: ' + SkidService3.SKID_TYPE_WIP + ' // IT from skid type: ' + it.From_SKID__r.Type__c);
                    System.assert(it.From_SKID__r.Quantity__c == 1,'Expected IT from skid quantity: 1 // IT from skid quantity: ' + it.From_SKID__r.Quantity__c);

                    System.assert(it.To_SKID__c != null,'Expected not null IT to skid');
                    System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected IT to skid type: ' + SkidService3.SKID_TYPE_LOCATION + ' // IT to skid type: ' + it.To_SKID__r.Type__c);
                    System.assert(it.To_SKID__r.Quantity__c == 98,'Expected IT to skid quantity: 98 // IT to skid quantity: ' + it.To_SKID__r.Quantity__c);
                } else if (it.Type__c == 'Work Order Component Scrap') {
                    System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
                    System.assert(it.Quantity__c == 1,'Expected IT quantity: 1 // IT quantity: ' + it.Quantity__c);
                    System.assert(it.Material_Tracking__r.Quantity_Scrapped__c == 1,'Expected material quantity scrapped: 1 // Material quantity scrapped: ' + it.Material_Tracking__r.Quantity_Scrapped__c);

                    System.assert(it.From_SKID__c != null,'Expected not null IT from skid');
                    System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected IT from skid type: ' + SkidService3.SKID_TYPE_WIP + ' // IT from skid type: ' + it.From_SKID__r.Type__c);
                    System.assert(it.From_SKID__r.Quantity__c == 1,'Expected IT from skid quantity: 1 // IT from skid quantity: ' + it.From_SKID__r.Quantity__c);

                    System.assert(it.To_SKID__c != null,'Expected not null IT to skid');
                    System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected IT to skid type: ' + SkidService3.SKID_TYPE_LOCATION + ' // IT to skid type: ' + it.To_SKID__r.Type__c);
                    System.assert(it.To_SKID__r.Quantity__c == 1,'Expected IT to skid quantity: 1 // IT to skid quantity: ' + it.To_SKID__r.Quantity__c);
                } else {
                    System.assert(false,'Unexpected IT type: ' + it.Type__c);
                }
            }
        }

        System.assert(dekitICFound,'Dekit inventory change not found');
    }

    private static testMethod void attributes() {
        setupInventory(true,false);
        kit(false,false);

        Test.startTest();

        List<WorkOrderWrapper> dekitRows = getDekitRows();

        dekitRows[0].serialWrapperList[0].skid.Temporary_Value_Holder1__c = '' + fuel.workOrder.MRB_Location__c + ',null';
        dekitRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 2;
        dekitRows[0].serialWrapperList[0].skid.Quantity_to_Scrap__c = 1;

        dekit(dekitRows);

        Test.stopTest();

        SOQLUtil icQuery = new SOQLUtil('Inventory_Change__c');
        icQuery.addAllCustomFields();
        icQuery.addAllCustomFields(Work_Order__c.sObjectType,'Work_Order__r');
        icQuery.setWhereClause('Work_Order__c = \'' + fuel.workOrder.Id + '\'');

        SOQLUtil.ChildRelationship itQuery = new SOQLUtil.ChildRelationship(icQuery,'Inventory_Transactions__r');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(Material_Tracking__c.sObjectType,'Material_Tracking__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        icQuery.addChildRelationship(itQuery);

        List<Inventory_Change__c> icList = Database.query(icQuery.getQuery());
        Boolean dekitICFound = false;
        for (Inventory_Change__c ic:Database.query(icQuery.getQuery())) {
            if (ic.Type__c != 'Work Order DeKit') {
                continue;
            }

            dekitICFound = true;

            System.assert(ic.Finalized__c,'Expected a finalized inventory change');
            System.assert(ic.Work_Order__r.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS,'Expected WO status: In Process // WO status: ' + ic.Work_Order__r.Status__c);
            System.assert(ic.Inventory_Transactions__r.size() == 2,'Expected ITs: 2 // ITs: ' + ic.Inventory_Transactions__r.size());

            for (Inventory_Transaction__c it:ic.Inventory_Transactions__r) {
                if (it.Type__c == 'Work Order Component Return') {
                    System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
                    System.assert(it.Quantity__c == 2,'Expected IT quantity: 2 // IT quantity: ' + it.Quantity__c);
                    System.assert(it.Material_Tracking__r.Quantity_Issued__c == 2,'Expected material quantity issued: 2 // Material quantity issued: ' + it.Material_Tracking__r.Quantity_Issued__c);

                    System.assert(it.From_SKID__c != null,'Expected not null IT from skid');
                    System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected IT from skid type: ' + SkidService3.SKID_TYPE_WIP + ' // IT from skid type: ' + it.From_SKID__r.Type__c);
                    System.assert(it.From_SKID__r.Quantity__c == 1,'Expected IT from skid quantity: 1 // IT from skid quantity: ' + it.From_SKID__r.Quantity__c);

                    System.assert(it.To_SKID__c != null,'Expected not null IT to skid');
                    System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected IT to skid type: ' + SkidService3.SKID_TYPE_LOCATION + ' // IT to skid type: ' + it.To_SKID__r.Type__c);
                    System.assert(it.To_SKID__r.Quantity__c == 98,'Expected IT to skid quantity: 98 // IT to skid quantity: ' + it.To_SKID__r.Quantity__c);
                } else if (it.Type__c == 'Work Order Component Scrap') {
                    System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
                    System.assert(it.Quantity__c == 1,'Expected IT quantity: 1 // IT quantity: ' + it.Quantity__c);
                    System.assert(it.Material_Tracking__r.Quantity_Scrapped__c == 1,'Expected material quantity scrapped: 1 // Material quantity scrapped: ' + it.Material_Tracking__r.Quantity_Scrapped__c);

                    System.assert(it.From_SKID__c != null,'Expected not null IT from skid');
                    System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected IT from skid type: ' + SkidService3.SKID_TYPE_WIP + ' // IT from skid type: ' + it.From_SKID__r.Type__c);
                    System.assert(it.From_SKID__r.Quantity__c == 1,'Expected IT from skid quantity: 1 // IT from skid quantity: ' + it.From_SKID__r.Quantity__c);

                    System.assert(it.To_SKID__c != null,'Expected not null IT to skid');
                    System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected IT to skid type: ' + SkidService3.SKID_TYPE_LOCATION + ' // IT to skid type: ' + it.To_SKID__r.Type__c);
                    System.assert(it.To_SKID__r.Quantity__c == 1,'Expected IT to skid quantity: 1 // IT to skid quantity: ' + it.To_SKID__r.Quantity__c);
                } else {
                    System.assert(false,'Unexpected IT type: ' + it.Type__c);
                }
            }
        }

        System.assert(dekitICFound,'Dekit inventory change not found');
    }

    private static testMethod void serials() {
        setupInventory(true,true);
        kit(true,false);

        Test.startTest();

        List<WorkOrderWrapper> dekitRows = getDekitRows();

        dekitRows[0].serialWrapperList[0].skid.Temporary_Value_Holder1__c = '' + fuel.workOrder.MRB_Location__c + ',null';
        dekitRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 2;
        dekitRows[0].serialWrapperList[0].skid.Quantity_to_Scrap__c = 1;
        dekitRows[0].serialWrapperList[0].serialList[0].Temporary_Value_Holder__c = 'Dekit';
        dekitRows[0].serialWrapperList[0].serialList[1].Temporary_Value_Holder__c = 'Dekit';
        dekitRows[0].serialWrapperList[0].serialList[2].Temporary_Value_Holder__c = 'Scrap';

        dekit(dekitRows);

        Test.stopTest();

        SOQLUtil icQuery = new SOQLUtil('Inventory_Change__c');
        icQuery.addAllCustomFields();
        icQuery.addAllCustomFields(Work_Order__c.sObjectType,'Work_Order__r');
        icQuery.setWhereClause('Work_Order__c = \'' + fuel.workOrder.Id + '\'');

        SOQLUtil.ChildRelationship itQuery = new SOQLUtil.ChildRelationship(icQuery,'Inventory_Transactions__r');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(Material_Tracking__c.sObjectType,'Material_Tracking__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        icQuery.addChildRelationship(itQuery);

        List<Inventory_Change__c> icList = Database.query(icQuery.getQuery());
        Boolean dekitICFound = false;
        Set<Id> itIds = new Set<Id>();
        for (Inventory_Change__c ic:Database.query(icQuery.getQuery())) {
            if (ic.Type__c != 'Work Order DeKit') {
                continue;
            }

            dekitICFound = true;

            System.assert(ic.Finalized__c,'Expected a finalized inventory change');
            System.assert(ic.Work_Order__r.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS,'Expected WO status: In Process // WO status: ' + ic.Work_Order__r.Status__c);
            System.assert(ic.Inventory_Transactions__r.size() == 2,'Expected ITs: 2 // ITs: ' + ic.Inventory_Transactions__r.size());

            for (Inventory_Transaction__c it:ic.Inventory_Transactions__r) {
                itIds.add(it.Id);

                if (it.Type__c == 'Work Order Component Return') {
                    System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
                    System.assert(it.Quantity__c == 2,'Expected IT quantity: 2 // IT quantity: ' + it.Quantity__c);
                    System.assert(it.Material_Tracking__r.Quantity_Issued__c == 2,'Expected material quantity issued: 2 // Material quantity issued: ' + it.Material_Tracking__r.Quantity_Issued__c);

                    System.assert(it.From_SKID__c != null,'Expected not null IT from skid');
                    System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected IT from skid type: ' + SkidService3.SKID_TYPE_WIP + ' // IT from skid type: ' + it.From_SKID__r.Type__c);
                    System.assert(it.From_SKID__r.Quantity__c == 1,'Expected IT from skid quantity: 1 // IT from skid quantity: ' + it.From_SKID__r.Quantity__c);

                    System.assert(it.To_SKID__c != null,'Expected not null IT to skid');
                    System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected IT to skid type: ' + SkidService3.SKID_TYPE_LOCATION + ' // IT to skid type: ' + it.To_SKID__r.Type__c);
                    System.assert(it.To_SKID__r.Quantity__c == 8,'Expected IT to skid quantity: 98 // IT to skid quantity: ' + it.To_SKID__r.Quantity__c);
                } else if (it.Type__c == 'Work Order Component Scrap') {
                    System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
                    System.assert(it.Quantity__c == 1,'Expected IT quantity: 1 // IT quantity: ' + it.Quantity__c);
                    System.assert(it.Material_Tracking__r.Quantity_Scrapped__c == 1,'Expected material quantity scrapped: 1 // Material quantity scrapped: ' + it.Material_Tracking__r.Quantity_Scrapped__c);

                    System.assert(it.From_SKID__c != null,'Expected not null IT from skid');
                    System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected IT from skid type: ' + SkidService3.SKID_TYPE_WIP + ' // IT from skid type: ' + it.From_SKID__r.Type__c);
                    System.assert(it.From_SKID__r.Quantity__c == 1,'Expected IT from skid quantity: 1 // IT from skid quantity: ' + it.From_SKID__r.Quantity__c);

                    System.assert(it.To_SKID__c != null,'Expected not null IT to skid');
                    System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected IT to skid type: ' + SkidService3.SKID_TYPE_LOCATION + ' // IT to skid type: ' + it.To_SKID__r.Type__c);
                    System.assert(it.To_SKID__r.Quantity__c == 1,'Expected IT to skid quantity: 1 // IT to skid quantity: ' + it.To_SKID__r.Quantity__c);
                } else {
                    System.assert(false,'Unexpected IT type: ' + it.Type__c);
                }
            }
        }

        System.assert(dekitICFound,'Dekit inventory change not found');

        SOQLUtil stQuery = new SOQLUtil('Serial_Transaction__c');
        stQuery.addAllCustomFields();
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
        stQuery.addAllCustomFields(Inventory_Transaction__c.sObjectType,'Inventory_Transaction__r');
        stQuery.setWhereClause('Inventory_Transaction__c IN :itIds');

        List<Serial_Transaction__c> stList = Database.query(stQuery.getQuery());
        System.assert(stList.size() == 3,'Expected serial transactions: 3 // Serial transactions: ' + stList.size());
        for (Serial_Transaction__c st:stList) {
            System.assert(st.Serial__r.SKID__c == st.Inventory_Transaction__r.To_SKID__c,'Expected serial skid: ' + st.Inventory_Transaction__r.To_SKID__c + ' // Serial skid: ' + st.Serial__r.SKID__c);
            if (st.Inventory_Transaction__r.Type__c == 'Work Order Component Return') {
                System.assert(st.Type__c == 'Component Return','Expected ST type: Component Return // ST Type: ' + st.Type__c);
            } else if (st.Inventory_Transaction__r.Type__c == 'Work Order Component Scrap') {
                System.assert(st.Type__c == 'Component Scrap','Expected ST type: Component Scrap // ST Type: ' + st.Type__c);
            }
        }
    }

    private static testMethod void withAllocation() {
        setupInventory(true,true);

        Material_Tracking__c mt = [SELECT Id FROM Material_Tracking__c WHERE Type__c = :ComponentService.TYPE_KIT];
        mt.Allocation_Required__c = true;
        update mt;

        List<LineWrapper> mData = (List<LineWrapper>)WorkOrderAllocationExt.getMaterialData(fuel.workOrder.Id).records;
        mData[0].serialWrappers[0].skid.Input_Quantity__c = 6;
        mData[0].serialWrappers[0].serialList[0].Temporary_Value_Holder__c = 'Allocate';
        mData[0].serialWrappers[0].serialList[1].Temporary_Value_Holder__c = 'Allocate';
        mData[0].serialWrappers[0].serialList[2].Temporary_Value_Holder__c = 'Allocate';
        mData[0].serialWrappers[0].serialList[3].Temporary_Value_Holder__c = 'Allocate';
        WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());

        // kit(true,true);

        // Test.startTest();

        // List<WorkOrderWrapper> dekitRows = getDekitRows();

        // dekitRows[0].serialWrapperList[0].skid.Temporary_Value_Holder1__c = '' + fuel.workOrder.MRB_Location__c + ',null';
        // dekitRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 2;
        // dekitRows[0].serialWrapperList[0].skid.Quantity_to_Scrap__c = 1;
        // dekitRows[0].serialWrapperList[0].serialList[0].Temporary_Value_Holder__c = 'Dekit';
        // dekitRows[0].serialWrapperList[0].serialList[1].Temporary_Value_Holder__c = 'Dekit';
        // dekitRows[0].serialWrapperList[0].serialList[2].Temporary_Value_Holder__c = 'Scrap';

        // dekit(dekitRows);

        // Test.stopTest();

        // SOQLUtil icQuery = new SOQLUtil('Inventory_Change__c');
        // icQuery.addAllCustomFields();
        // icQuery.addAllCustomFields(Work_Order__c.sObjectType,'Work_Order__r');
        // icQuery.setWhereClause('Work_Order__c = \'' + fuel.workOrder.Id + '\'');

        // SOQLUtil.ChildRelationship itQuery = new SOQLUtil.ChildRelationship(icQuery,'Inventory_Transactions__r');
        // itQuery.addAllCustomFields();
        // itQuery.addAllCustomFields(Material_Tracking__c.sObjectType,'Material_Tracking__r');
        // itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
        // itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
        // icQuery.addChildRelationship(itQuery);

        // List<Inventory_Change__c> icList = Database.query(icQuery.getQuery());
        // Boolean dekitICFound = false;
        // Set<Id> itIds = new Set<Id>();
        // Set<Id> mIds = new Set<Id>();
        // for (Inventory_Change__c ic:Database.query(icQuery.getQuery())) {
        //     if (ic.Type__c != 'Work Order DeKit') {
        //         continue;
        //     }

        //     dekitICFound = true;

        //     System.assert(ic.Finalized__c,'Expected a finalized inventory change');
        //     System.assert(ic.Work_Order__r.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS,'Expected WO status: In Process // WO status: ' + ic.Work_Order__r.Status__c);
        //     System.assert(ic.Inventory_Transactions__r.size() == 2,'Expected ITs: 2 // ITs: ' + ic.Inventory_Transactions__r.size());

        //     for (Inventory_Transaction__c it:ic.Inventory_Transactions__r) {
        //         itIds.add(it.Id);
        //         mIds.add(it.Material_Tracking__c);

        //         if (it.Type__c == 'Work Order Component Return') {
        //             System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
        //             System.assert(it.Quantity__c == 2,'Expected IT quantity: 2 // IT quantity: ' + it.Quantity__c);
        //             System.assert(it.Material_Tracking__r.Quantity_Issued__c == 2,'Expected material quantity issued: 2 // Material quantity issued: ' + it.Material_Tracking__r.Quantity_Issued__c);
        //             System.assert(it.Material_Tracking__r.Quantity_Allocated__c == 4,'Expected material quantity allocated: 4 // Material quantity allocated: ' + it.Material_Tracking__r.Quantity_Allocated__c);

        //             System.assert(it.From_SKID__c != null,'Expected not null IT from skid');
        //             System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected IT from skid type: ' + SkidService3.SKID_TYPE_WIP + ' // IT from skid type: ' + it.From_SKID__r.Type__c);
        //             System.assert(it.From_SKID__r.Quantity__c == 1,'Expected IT from skid quantity: 1 // IT from skid quantity: ' + it.From_SKID__r.Quantity__c);

        //             System.assert(it.To_SKID__c != null,'Expected not null IT to skid');
        //             System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected IT to skid type: ' + SkidService3.SKID_TYPE_LOCATION + ' // IT to skid type: ' + it.To_SKID__r.Type__c);
        //             System.assert(it.To_SKID__r.Quantity__c == 8,'Expected IT to skid quantity: 98 // IT to skid quantity: ' + it.To_SKID__r.Quantity__c);
        //         } else if (it.Type__c == 'Work Order Component Scrap') {
        //             System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
        //             System.assert(it.Quantity__c == 1,'Expected IT quantity: 1 // IT quantity: ' + it.Quantity__c);
        //             System.assert(it.Material_Tracking__r.Quantity_Scrapped__c == 1,'Expected material quantity scrapped: 1 // Material quantity scrapped: ' + it.Material_Tracking__r.Quantity_Scrapped__c);

        //             System.assert(it.From_SKID__c != null,'Expected not null IT from skid');
        //             System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected IT from skid type: ' + SkidService3.SKID_TYPE_WIP + ' // IT from skid type: ' + it.From_SKID__r.Type__c);
        //             System.assert(it.From_SKID__r.Quantity__c == 1,'Expected IT from skid quantity: 1 // IT from skid quantity: ' + it.From_SKID__r.Quantity__c);

        //             System.assert(it.To_SKID__c != null,'Expected not null IT to skid');
        //             System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected IT to skid type: ' + SkidService3.SKID_TYPE_LOCATION + ' // IT to skid type: ' + it.To_SKID__r.Type__c);
        //             System.assert(it.To_SKID__r.Quantity__c == 1,'Expected IT to skid quantity: 1 // IT to skid quantity: ' + it.To_SKID__r.Quantity__c);
        //         } else {
        //             System.assert(false,'Unexpected IT type: ' + it.Type__c);
        //         }
        //     }
        // }

        // System.assert(dekitICFound,'Dekit inventory change not found');

        // SOQLUtil stQuery = new SOQLUtil('Serial_Transaction__c');
        // stQuery.addAllCustomFields();
        // stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
        // stQuery.addAllCustomFields(Inventory_Transaction__c.sObjectType,'Inventory_Transaction__r');
        // stQuery.setWhereClause('Inventory_Transaction__c IN :itIds');

        // List<Serial_Transaction__c> stList = Database.query(stQuery.getQuery());
        // System.assert(stList.size() == 3,'Expected serial transactions: 3 // Serial transactions: ' + stList.size());
        // for (Serial_Transaction__c st:stList) {
        //     System.assert(st.Serial__r.SKID__c == st.Inventory_Transaction__r.To_SKID__c,'Expected serial skid: ' + st.Inventory_Transaction__r.To_SKID__c + ' // Serial skid: ' + st.Serial__r.SKID__c);
        //     if (st.Inventory_Transaction__r.Type__c == 'Work Order Component Return') {
        //         System.assert(st.Type__c == 'Component Return','Expected ST type: Component Return // ST Type: ' + st.Type__c);
        //     } else if (st.Inventory_Transaction__r.Type__c == 'Work Order Component Scrap') {
        //         System.assert(st.Type__c == 'Component Scrap','Expected ST type: Component Scrap // ST Type: ' + st.Type__c);
        //     }
        // }

        // SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        // skidQuery.addAllCustomFields();
        // skidQuery.setWhereClause('Type__c = \'' + SkidService3.SKID_TYPE_ALLOCATED + '\' AND Material_Tracking__c IN :mIds');

        // List<SKID__c> skids = Database.query(skidQuery.getQuery());
        // System.assert(skids.size() == 1,'Expected allocated skids: 1 // Allocated skids: ' + skids.size());
        // System.assert(skids[0].Quantity__c == 4,'Expected allocated skid quantity: 4 // Allocated skid quantity: ' + skids[0].Quantity__c);
    }
}