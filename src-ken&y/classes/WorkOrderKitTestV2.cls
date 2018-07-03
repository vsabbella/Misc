@isTest
private class WorkOrderKitTestV2 {
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
                            Unique_Key2__c = '' + skid.Company__c + '-' + skid.Item__c + '-' + skid.Id + i
                        ));
                    }
                }
            }
        }

        if (attributes) update skids;
        if (serialsToInsert.size() > 0) insert serialsToInsert;
    }

    private static List<WorkOrderWrapper> getKitRows() {
        JsonResult result = WorkOrderKitExtV2.getKitData(fuel.workOrder.Id);
        System.assert(result.success,'WorkOrderKitExtV2.getKitData fail: ' + result);
        System.assert(result.records.size() == 1,'Expected lines: 1 // Lines: ' + result.records.size());
        return (List<WorkOrderWrapper>)result.records;
    }

    private static void kit(List<WorkOrderWrapper> kitRows) {
        JsonResult result = WorkOrderKitExtV2.save(kitRows,new List<String>(),new List<String>());
        System.assert(result.success,'WorkOrderKitExtV2.save: ' + result);
    }

    private static testMethod void noAttributes() {
        setupInventory(false,false);

        WorkOrderKitExtV2 ext = new WorkOrderKitExtV2(new ApexPages.StandardController(fuel.workOrder));
        ext.getWorkOrderJson();
        ext.getKitConfigJson();
        ext.getMtFieldList();
        ext.getSkidFieldList();

        Test.startTest();

        List<WorkOrderWrapper> kitRows = getKitRows();

        kitRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;

        kit(kitRows);

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

        Inventory_Change__c ic = Database.query(icQuery.getQuery());
        System.assert(ic.Type__c == 'Work Order Kit','Expected IC type: Work Order Kit // IC type: ' + ic.Type__c);
        System.assert(ic.Finalized__c,'Expected Finalized IC');
        System.assert(ic.Work_Order__r.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS,'Expected WO status: In Process // WO status: ' + ic.Work_Order__r.Status__c);
        System.assert(ic.Inventory_Transactions__r.size() == 1,'Expected ITs: 1 // ITs: ' + ic.Inventory_Transactions__r.size());

        Inventory_Transaction__c it = ic.Inventory_Transactions__r[0];
        System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
        System.assert(it.Quantity__c == 4,'Expected IT quantity: 4 // IT quantity: ' + it.Quantity__c);
        System.assert(it.Type__c == 'Work Order Component Issue','Expected IT type: Work Order Component Issue // IT type: ' + it.Type__c);
        System.assert(it.To_Location__c == ic.Work_Order__r.Default_WIP_Location__c,'Expected IT to location: ' + ic.Work_Order__r.Default_WIP_Location__c + ' // IT to location: ' + it.To_Location__c);
        System.assert(it.Material_Tracking__r.Quantity_Issued__c == 4,'Expected quantity issued: 4 // Quantity issued: ' + it.Material_Tracking__r.Quantity_Issued__c);

        System.assert(it.From_SKID__c != null,'From skid not found');
        System.assert(it.From_SKID__r.Quantity__c == 96,'Expected from skid quantity: 96 or 6 or -4 // From skid quantity: ' + it.From_SKID__r.Quantity__c);
        System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected from skid type: Location // From skid type: ' + it.From_SKID__r.Type__c);

        System.assert(it.To_SKID__c != null,'To skid not found');
        System.assert(it.To_SKID__r.Quantity__c == 4,'Expected to skid quantity: 4 // To skid quantity: ' + it.To_SKID__r.Quantity__c);
        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected to skid type: WIP // To skid type: ' + it.From_SKID__r.Type__c);

        Test.stopTest();
    }

    private static testMethod void attributes() {
        setupInventory(true,false);

        Test.startTest();

        List<WorkOrderWrapper> kitRows = getKitRows();

        kitRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;

        kit(kitRows);

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

        Inventory_Change__c ic = Database.query(icQuery.getQuery());
        System.assert(ic.Type__c == 'Work Order Kit','Expected IC type: Work Order Kit // IC type: ' + ic.Type__c);
        System.assert(ic.Finalized__c,'Expected Finalized IC');
        System.assert(ic.Work_Order__r.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS,'Expected WO status: In Process // WO status: ' + ic.Work_Order__r.Status__c);
        System.assert(ic.Inventory_Transactions__r.size() == 1,'Expected ITs: 1 // ITs: ' + ic.Inventory_Transactions__r.size());

        Inventory_Transaction__c it = ic.Inventory_Transactions__r[0];
        System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
        System.assert(it.Quantity__c == 4,'Expected IT quantity: 4 // IT quantity: ' + it.Quantity__c);
        System.assert(it.Type__c == 'Work Order Component Issue','Expected IT type: Work Order Component Issue // IT type: ' + it.Type__c);
        System.assert(it.To_Location__c == ic.Work_Order__r.Default_WIP_Location__c,'Expected IT to location: ' + ic.Work_Order__r.Default_WIP_Location__c + ' // IT to location: ' + it.To_Location__c);
        System.assert(it.Material_Tracking__r.Quantity_Issued__c == 4,'Expected quantity issued: 4 // Quantity issued: ' + it.Material_Tracking__r.Quantity_Issued__c);

        System.assert(it.From_SKID__c != null,'From skid not found');
        System.assert(it.From_SKID__r.Quantity__c == 96,'Expected from skid quantity: 96 or 6 or -4 // From skid quantity: ' + it.From_SKID__r.Quantity__c);
        System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected from skid type: Location // From skid type: ' + it.From_SKID__r.Type__c);

        System.assert(it.To_SKID__c != null,'To skid not found');
        System.assert(it.To_SKID__r.Quantity__c == 4,'Expected to skid quantity: 4 // To skid quantity: ' + it.To_SKID__r.Quantity__c);
        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected to skid type: WIP // To skid type: ' + it.From_SKID__r.Type__c);

        Test.stopTest();
    }

    private static testMethod void serials() {
        setupInventory(true,true);

        Test.startTest();

        List<WorkOrderWrapper> kitRows = getKitRows();

        kitRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;
        for (Integer i=0;i<4;i++) {
            kitRows[0].serialWrapperList[0].serialList[i].Temporary_Value_Holder__c = 'Kit';
        }

        kit(kitRows);

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

        Inventory_Change__c ic = Database.query(icQuery.getQuery());
        System.assert(ic.Type__c == 'Work Order Kit','Expected IC type: Work Order Kit // IC type: ' + ic.Type__c);
        System.assert(ic.Finalized__c,'Expected Finalized IC');
        System.assert(ic.Work_Order__r.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS,'Expected WO status: In Process // WO status: ' + ic.Work_Order__r.Status__c);
        System.assert(ic.Inventory_Transactions__r.size() == 1,'Expected ITs: 1 // ITs: ' + ic.Inventory_Transactions__r.size());

        Inventory_Transaction__c it = ic.Inventory_Transactions__r[0];
        System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
        System.assert(it.Quantity__c == 4,'Expected IT quantity: 4 // IT quantity: ' + it.Quantity__c);
        System.assert(it.Type__c == 'Work Order Component Issue','Expected IT type: Work Order Component Issue // IT type: ' + it.Type__c);
        System.assert(it.To_Location__c == ic.Work_Order__r.Default_WIP_Location__c,'Expected IT to location: ' + ic.Work_Order__r.Default_WIP_Location__c + ' // IT to location: ' + it.To_Location__c);
        System.assert(it.Material_Tracking__r.Quantity_Issued__c == 4,'Expected quantity issued: 4 // Quantity issued: ' + it.Material_Tracking__r.Quantity_Issued__c);

        System.assert(it.From_SKID__c != null,'From skid not found');
        System.assert(it.From_SKID__r.Quantity__c == 6,'Expected from skid quantity: 96 or 6 or -4 // From skid quantity: ' + it.From_SKID__r.Quantity__c);
        System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected from skid type: Location // From skid type: ' + it.From_SKID__r.Type__c);

        System.assert(it.To_SKID__c != null,'To skid not found');
        System.assert(it.To_SKID__r.Quantity__c == 4,'Expected to skid quantity: 4 // To skid quantity: ' + it.To_SKID__r.Quantity__c);
        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected to skid type: WIP // To skid type: ' + it.From_SKID__r.Type__c);

        SOQLUtil stQuery = new SOQLUtil('Serial_Transaction__c');
        stQuery.addAllCustomFields();
        stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
        stQuery.setWhereClause('Inventory_Transaction__c = \'' + it.Id + '\'');

        List<Serial_Transaction__c> stList = Database.query(stQuery.getQuery());
        System.assert(stList.size() == 4,'Expected serial transactions: 4 // Serial transactions: ' + stList.size());
        for (Serial_Transaction__c st:it.Serial_Transactions__r) {
            System.assert(st.Type__c == 'Component Issue','Expected serial transaction type: Component Issue // Serial transaction type: ' + st.Type__c);
            System.assert(st.Serial_Parent__c == null,'Expected null serial parent');
            System.assert(st.Serial__r.SKID__c == it.To_SKID__c,'Expected skid on serial: ' + it.To_SKID__c + ' // Skid on serial: ' + st.Serial__r.SKID__c);
        }

        SOQLUtil serialQuery = new SOQLUtil('Serial__c');
        serialQuery.addAllCustomFields();
        serialQuery.setWhereClause('SKID__c = \'' + it.From_SKID__c + '\'');

        List<Serial__c> serialList = Database.query(serialQuery.getQuery());
        System.assert(serialList.size() == 6,'Expected from skid serials: 6 // From skid serials: ' + serialList.size());

        Test.stopTest();
    }

    private static testMethod void negativeInventory() {
        setupInventory(true,false);

        Test.startTest();

        List<WorkOrderWrapper> kitRows = getKitRows();

        JsonResult result = WorkOrderKitExtV2.addLine(kitRows[0].material);
        System.assert(result.success,'WorkOrderKitExtV2.addLine failed: ' + result);
        System.assert(result.records.size() == 1,'Expected lines: 1 // Lines: ' + result.records.size());

        SkidService3.SerialWrapper sw = (SkidService3.SerialWrapper)result.records[0];
        sw.skid.Packaging_UOM__c = sw.skid.Item__r.Stocking_UOM__c;
        sw.skid.Stocking_UOM__c = sw.skid.Item__r.Stocking_UOM__c;
        sw.skid.Location__c = fuel.location3.Id;
        sw.skid.Location__r = (Location__c)WorkOrderKitExtV2.getLocation(fuel.location3.Id).records[0];
        sw.skid.Expiration_Date__c = System.today() + 365;
        sw.skid.Lot_Number__c = 'CUSTLOT1';
        sw.skid.Quantity_to_Issue__c = 4;
        kitRows[0].serialWrapperList = new List<SkidService3.SerialWrapper>{ sw };

        kit(kitRows);

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

        Inventory_Change__c ic = Database.query(icQuery.getQuery());
        System.assert(ic.Type__c == 'Work Order Kit','Expected IC type: Work Order Kit // IC type: ' + ic.Type__c);
        System.assert(ic.Finalized__c,'Expected Finalized IC');
        System.assert(ic.Work_Order__r.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS,'Expected WO status: In Process // WO status: ' + ic.Work_Order__r.Status__c);
        System.assert(ic.Inventory_Transactions__r.size() == 1,'Expected ITs: 1 // ITs: ' + ic.Inventory_Transactions__r.size());

        Inventory_Transaction__c it = ic.Inventory_Transactions__r[0];
        System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
        System.assert(it.Quantity__c == 4,'Expected IT quantity: 4 // IT quantity: ' + it.Quantity__c);
        System.assert(it.Type__c == 'Work Order Component Issue','Expected IT type: Work Order Component Issue // IT type: ' + it.Type__c);
        System.assert(it.To_Location__c == ic.Work_Order__r.Default_WIP_Location__c,'Expected IT to location: ' + ic.Work_Order__r.Default_WIP_Location__c + ' // IT to location: ' + it.To_Location__c);
        System.assert(it.Material_Tracking__r.Quantity_Issued__c == 4,'Expected quantity issued: 4 // Quantity issued: ' + it.Material_Tracking__r.Quantity_Issued__c);

        System.assert(it.From_SKID__c != null,'From skid not found');
        System.assert(it.From_SKID__r.Quantity__c == -4,'Expected from skid quantity: 96 or 6 or -4 // From skid quantity: ' + it.From_SKID__r.Quantity__c);
        System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected from skid type: Location // From skid type: ' + it.From_SKID__r.Type__c);

        System.assert(it.To_SKID__c != null,'To skid not found');
        System.assert(it.To_SKID__r.Quantity__c == 4,'Expected to skid quantity: 4 // To skid quantity: ' + it.To_SKID__r.Quantity__c);
        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected to skid type: WIP // To skid type: ' + it.From_SKID__r.Type__c);

        Test.stopTest();
    }

    private static testMethod void withAllocation() {
        Material_Tracking__c mt = [SELECT Id FROM Material_Tracking__c WHERE Type__c = :ComponentService.TYPE_KIT];
        mt.Allocation_Required__c = true;
        update mt;

        setupInventory(true,true);

        Test.startTest();

        List<LineWrapper> mData = (List<LineWrapper>)WorkOrderAllocationExt.getMaterialData(fuel.workOrder.Id).records;
        mData[0].serialWrappers[0].skid.Input_Quantity__c = 6;
        mData[0].serialWrappers[0].serialList[0].Temporary_Value_Holder__c = 'Allocate';
        mData[0].serialWrappers[0].serialList[1].Temporary_Value_Holder__c = 'Allocate';
        mData[0].serialWrappers[0].serialList[2].Temporary_Value_Holder__c = 'Allocate';
        mData[0].serialWrappers[0].serialList[3].Temporary_Value_Holder__c = 'Allocate';
        WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());

        List<WorkOrderWrapper> kitRows = getKitRows();

        // kitRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;
        // List<Serial__c> serials = new List<Serial__c>();
        // for (Serial__c ser:kitRows[0].serialWrapperList[0].serialList) {
        //     if (ser.Allocated_SKID__c != null) {
        //         ser.Temporary_Value_Holder__c = 'Kit';
        //         serials.add(ser);
        //     }
        // }
        // kitRows[0].serialWrapperList[0].serialList = serials;

        // kit(kitRows);

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

        // Inventory_Change__c ic = Database.query(icQuery.getQuery());
        // System.assert(ic.Type__c == 'Work Order Kit','Expected IC type: Work Order Kit // IC type: ' + ic.Type__c);
        // System.assert(ic.Finalized__c,'Expected Finalized IC');
        // System.assert(ic.Work_Order__r.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS,'Expected WO status: In Process // WO status: ' + ic.Work_Order__r.Status__c);
        // System.assert(ic.Inventory_Transactions__r.size() == 1,'Expected ITs: 1 // ITs: ' + ic.Inventory_Transactions__r.size());

        // Inventory_Transaction__c it = ic.Inventory_Transactions__r[0];
        // System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
        // System.assert(it.Quantity__c == 4,'Expected IT quantity: 4 // IT quantity: ' + it.Quantity__c);
        // System.assert(it.Type__c == 'Work Order Component Issue','Expected IT type: Work Order Component Issue // IT type: ' + it.Type__c);
        // System.assert(it.To_Location__c == ic.Work_Order__r.Default_WIP_Location__c,'Expected IT to location: ' + ic.Work_Order__r.Default_WIP_Location__c + ' // IT to location: ' + it.To_Location__c);
        // System.assert(it.Material_Tracking__r.Quantity_Issued__c == 4,'Expected quantity issued: 4 // Quantity issued: ' + it.Material_Tracking__r.Quantity_Issued__c);

        // System.assert(it.From_SKID__c != null,'From skid not found');
        // System.assert(it.From_SKID__r.Quantity__c == 6,'Expected from skid quantity: 96 or 6 or -4 // From skid quantity: ' + it.From_SKID__r.Quantity__c);
        // System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected from skid type: Location // From skid type: ' + it.From_SKID__r.Type__c);

        // System.assert(it.To_SKID__c != null,'To skid not found');
        // System.assert(it.To_SKID__r.Quantity__c == 4,'Expected to skid quantity: 4 // To skid quantity: ' + it.To_SKID__r.Quantity__c);
        // System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected to skid type: WIP // To skid type: ' + it.From_SKID__r.Type__c);

        // SOQLUtil stQuery = new SOQLUtil('Serial_Transaction__c');
        // stQuery.addAllCustomFields();
        // stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
        // stQuery.setWhereClause('Inventory_Transaction__c = \'' + it.Id + '\'');

        // List<Serial_Transaction__c> stList = Database.query(stQuery.getQuery());
        // System.assert(stList.size() == 4,'Expected serial transactions: 4 // Serial transactions: ' + stList.size());
        // for (Serial_Transaction__c st:it.Serial_Transactions__r) {
        //     System.assert(st.Type__c == 'Component Issue','Expected serial transaction type: Component Issue // Serial transaction type: ' + st.Type__c);
        //     System.assert(st.Serial_Parent__c == null,'Expected null serial parent');
        //     System.assert(st.Serial__r.SKID__c == it.To_SKID__c,'Expected skid on serial: ' + it.To_SKID__c + ' // Skid on serial: ' + st.Serial__r.SKID__c);
        // }

        // SOQLUtil serialQuery = new SOQLUtil('Serial__c');
        // serialQuery.addAllCustomFields();
        // serialQuery.setWhereClause('SKID__c = \'' + it.From_SKID__c + '\'');

        // List<Serial__c> serialList = Database.query(serialQuery.getQuery());
        // System.assert(serialList.size() == 6,'Expected from skid serials: 6 // From skid serials: ' + serialList.size());

        // SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        // skidQuery.addAllCustomFields();
        // skidQuery.setWhereClause('Material_Tracking__c = \'' + it.Material_Tracking__c + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_ALLOCATED + '\'');

        // SOQLUtil.ChildRelationship serialSubquery = new SOQLUtil.ChildRelationship(skidQuery,'Allocated_Serials__r');
        // serialSubquery.addAllCustomFields();
        // skidQuery.addChildRelationship(serialSubquery);

        // SKID__c skid = Database.query(skidQuery.getQuery());
        // System.assert(skid.Quantity__c == 2,'Expected allocated skid quantity: 2 // Allocated skid quantity: ' + skid.Quantity__c);
        // System.assert(skid.Allocated_Serials__r.size() == 0,'Expected allocated serials: 0 // Allocated serials: ' + skid.Allocated_Serials__r.size());

        Test.stopTest();
    }

    private static testMethod void withProfile() {
        Material_Tracking__c mt = [SELECT Id FROM Material_Tracking__c WHERE Type__c = :ComponentService.TYPE_KIT];
        mt.Allocation_Required__c = true;
        update mt;

        insert new Allocation_Profile__c(
            Company__c = fuel.company.Id,
            Date_Received__c = false,
            Expiration_Date__c = false,
            Location__c = false,
            Rental__c = false,
            Used__c = false
        );

        setupInventory(true,true);

        Test.startTest();

        List<LineWrapper> mData = (List<LineWrapper>)WorkOrderAllocationExt.getMaterialData(fuel.workOrder.Id).records;
        System.assert(mData.size() == 1,mData);
        System.assert(mData[0].serialWrappers.size() == 1,mData[0].serialWrappers);
        // System.assert(mData[0].serialWrappers[0].skid.Quantity__c == 20,mData[0].serialWrappers[0].skid);
        mData[0].serialWrappers[0].skid.Input_Quantity__c = 6;
        WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());

        List<WorkOrderWrapper> kitRows = getKitRows();
        System.assert(kitRows.size() == 1,kitRows);
        // System.assert(kitRows[0].serialWrapperList.size() == 2,kitRows[0].serialWrapperList);
        for (SkidService3.SerialWrapper sw:kitRows[0].serialWrapperList) {
            System.assert(sw.skid.Quantity_Available__c == 6,sw.skid);
            if (sw.skid.Location__c == fuel.location3.Id) {
                sw.skid.Quantity_to_Issue__c = 4;
                List<Serial__c> serials = new List<Serial__c>();
                for (Integer i=0;i<4;i++) {
                    sw.serialList[i].Temporary_Value_Holder__c = 'Kit';
                    serials.add(sw.serialList[i]);
                }
                sw.serialList = serials;
            }
        }

        // kit(kitRows);

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

        // Inventory_Change__c ic = Database.query(icQuery.getQuery());
        // System.assert(ic.Type__c == 'Work Order Kit','Expected IC type: Work Order Kit // IC type: ' + ic.Type__c);
        // System.assert(ic.Finalized__c,'Expected Finalized IC');
        // System.assert(ic.Work_Order__r.Status__c == WorkOrderService.WO_STATUS_IN_PROCESS,'Expected WO status: In Process // WO status: ' + ic.Work_Order__r.Status__c);
        // System.assert(ic.Inventory_Transactions__r.size() == 1,'Expected ITs: 2 // ITs: ' + ic.Inventory_Transactions__r.size());

        // Inventory_Transaction__c it = ic.Inventory_Transactions__r[0];
        // System.assert(it.Item__c == fuel.components[0].Component_Item__c,'Expected IT item: ' + fuel.components[0].Component_Item__c + ' // IT item: ' + it.Item__c);
        // System.assert(it.Quantity__c == 4,'Expected IT quantity: 4 // IT quantity: ' + it.Quantity__c);
        // System.assert(it.Type__c == 'Work Order Component Issue','Expected IT type: Work Order Component Issue // IT type: ' + it.Type__c);
        // System.assert(it.To_Location__c == ic.Work_Order__r.Default_WIP_Location__c,'Expected IT to location: ' + ic.Work_Order__r.Default_WIP_Location__c + ' // IT to location: ' + it.To_Location__c);
        // System.assert(it.Material_Tracking__r.Quantity_Issued__c == 4,'Expected quantity issued: 4 // Quantity issued: ' + it.Material_Tracking__r.Quantity_Issued__c);

        // System.assert(it.From_SKID__c != null,'From skid not found');
        // System.assert(it.From_SKID__r.Quantity__c == 6,'Expected from skid quantity: 96 or 6 or -4 // From skid quantity: ' + it.From_SKID__r.Quantity__c);
        // System.assert(it.From_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,'Expected from skid type: Location // From skid type: ' + it.From_SKID__r.Type__c);

        // System.assert(it.To_SKID__c != null,'To skid not found');
        // System.assert(it.To_SKID__r.Quantity__c == 4,'Expected to skid quantity: 4 // To skid quantity: ' + it.To_SKID__r.Quantity__c);
        // System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_WIP,'Expected to skid type: WIP // To skid type: ' + it.From_SKID__r.Type__c);

        // SOQLUtil stQuery = new SOQLUtil('Serial_Transaction__c');
        // stQuery.addAllCustomFields();
        // stQuery.addAllCustomFields(Serial__c.sObjectType,'Serial__r');
        // stQuery.setWhereClause('Inventory_Transaction__c = \'' + it.Id + '\'');

        // List<Serial_Transaction__c> stList = Database.query(stQuery.getQuery());
        // System.assert(stList.size() == 4,'Expected serial transactions: 4 // Serial transactions: ' + stList.size());
        // for (Serial_Transaction__c st:it.Serial_Transactions__r) {
        //     System.assert(st.Type__c == 'Component Issue','Expected serial transaction type: Component Issue // Serial transaction type: ' + st.Type__c);
        //     System.assert(st.Serial_Parent__c == null,'Expected null serial parent');
        //     System.assert(st.Serial__r.SKID__c == it.To_SKID__c,'Expected skid on serial: ' + it.To_SKID__c + ' // Skid on serial: ' + st.Serial__r.SKID__c);
        // }

        // SOQLUtil serialQuery = new SOQLUtil('Serial__c');
        // serialQuery.addAllCustomFields();
        // serialQuery.setWhereClause('SKID__c = \'' + it.From_SKID__c + '\'');

        // List<Serial__c> serialList = Database.query(serialQuery.getQuery());
        // System.assert(serialList.size() == 6,'Expected from skid serials: 6 // From skid serials: ' + serialList.size());

        // SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        // skidQuery.addAllCustomFields();
        // skidQuery.setWhereClause('Material_Tracking__c = \'' + it.Material_Tracking__c + '\' AND Type__c = \'' + SkidService3.SKID_TYPE_ALLOCATED + '\'');

        // SOQLUtil.ChildRelationship serialSubquery = new SOQLUtil.ChildRelationship(skidQuery,'Allocated_Serials__r');
        // serialSubquery.addAllCustomFields();
        // skidQuery.addChildRelationship(serialSubquery);

        // SKID__c skid = Database.query(skidQuery.getQuery());
        // System.assert(skid.Quantity__c == 2,'Expected allocated skid quantity: 2 // Allocated skid quantity: ' + skid.Quantity__c);
        // System.assert(skid.Allocated_Serials__r.size() == 0,'Expected allocated serials: 0 // Allocated serials: ' + skid.Allocated_Serials__r.size());

        Test.stopTest();
    }
}