@isTest
private class RepairTest {
    @testSetup
    private static void setupData() {
        TestFuel fuel = new TestFuel();
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
        List<Period__c> periodList = fuel.periodList;
        Customer__c customer = fuel.customerShipTo;
        List<Location__c> locations = new List<Location__c>{ fuel.location2, fuel.location6, fuel.location7 };
        List<Item__c> items = fuel.itemList;
        System.assert(fuel.reasonCodes != null);
    }

    public class RepairData {
        public Company__c company {
            get {
                if (company == null) {
                    SOQLUtil companyQuery = new SOQLUtil('Company__c');
                    companyQuery.addAllCustomFields();
                    company = (Company__c)Database.query(companyQuery.getQuery())[0];
                }
                return company;
            } set;
        }
        
        public Facility__c facility {
            get {
                if (facility == null) {
                    SOQLUtil facilityQuery = new SOQLUtil('Facility__c');
                    facilityQuery.addAllCustomFields();
                    facilityQuery.setWhereClause('Name = \'' + company.Name + ' Facility-2\'');
                    facility = (Facility__c)Database.query(facilityQuery.getQuery())[0];
                }
                return facility;
            } set;
        }

        public Map<String,Location__c> locations {
            get {
                if (locations == null) {
                    locations = new Map<String,Location__c>();
                    SOQLUtil locationQuery = new SOQLUtil('Location__c');
                    locationQuery.addAllCustomFields();
                    locationQuery.setWhereClause('Facility__c = \'' + facility.Id + '\'');
                    for (Location__c location:Database.query(locationQuery.getQuery())) {
                        locations.put(location.Name,location);
                    }
                }
                return locations;
            } set;
        }

        public Map<String,Item__c> items {
            get {
                if (items == null) {
                    items = new Map<String,Item__c>();
                    SOQLUtil itemQuery = new SOQLUtil('Item__c');
                    itemQuery.addAllCustomFields();
                    for (Item__c item:Database.query(itemQuery.getQuery())) {
                        items.put(item.Name,item);
                    }
                }
                return items;
            } set;
        }

        public Map<String,Product__c> products {
            get {
                if (products == null) {
                    products = new Map<String,Product__c>();
                    SOQLUtil productQuery = new SOQLUtil('Product__c');
                    productQuery.addAllCustomFields();
                    for (Product__c product:Database.query(productQuery.getQuery())) {
                        products.put(product.Name,product);
                    }
                }
                return products;
            } set;
        }

        public Map<String,Customer__c> customers {
            get {
                if (customers == null) {
                    customers = new Map<String,Customer__c>();
                    SOQLUtil customerQuery = new SOQLUtil('Customer__c');
                    customerQuery.addAllCustomFields();
                    for (Customer__c customer:Database.query(customerQuery.getQuery())) {
                        customers.put(customer.Name,customer);
                    }
                }
                return customers;
            } set;
        }

        public Payment_Term__c terms {
            get {
                if (terms == null) {
                    SOQLUtil ptQuery = new SOQLUtil('Payment_Term__c');
                    ptQuery.addAllCustomFields();
                    terms = (Payment_Term__c)Database.query(ptQuery.getQuery())[0];
                }
                return terms;
            } set;
        }

        public Item_Attribute__c itemAttr {
            get {
                if (itemAttr == null) {
                    SOQLUtil itemAttrQuery = new SOQLUtil('Item_Attribute__c');
                    itemAttrQuery.addAllCustomFields();
                    itemAttrQuery.setWhereClause('Serial_Number__c = false');
                    itemAttr = (Item_Attribute__c)Database.query(itemAttrQuery.getQuery())[0];
                }
                return itemAttr;
            } set;
        }

        public Reason_Code__c reasonCode {
            get {
                if (reasonCode == null) {
                    SOQLUtil rcQuery = new SOQLUtil('Reason_Code__c');
                    rcQuery.addAllCustomFields();
                    rcQuery.setWhereClause('Type__c = \'Work Order\'');
                    reasonCode = Database.query(rcQuery.getQuery());
                }
                return reasonCode;
            } set;
        }

        public Work_Order__c repairWO {
            get {
                if (repairWO == null) {
                    repairWO = new Work_Order__c(
                        Type__c = WorkOrderService.WO_TYPE_REPAIR,
                        Company__c = company.Id,
                        Facility__c = facility.Id,
                        Order_Quantity__c = 1,
                        Need_Date2__c = DateTime.newInstance(Date.today() + 30,Time.newInstance(0,0,0,0)),
                        Start_Date2__c = DateTime.newInstance(Date.today() + 25,Time.newInstance(0,0,0,0)),
                        Item__c = items.get(company.Name + ' Item-15').Id,
                        Packaging_UOM__c = items.get(company.Name + ' Item-15').Stocking_UOM__c,
                        Complete_To_Location__c = locations.get('Stock').Id,
                        MRB_Location__c = locations.get('Delivery/Shipping/scrap Location').Id,
                        Default_WIP_Location__c = locations.get('WIP Location').Id,
                        Last_Sync_Date__c = System.now(),
                        Currency__c = company.Default_Transaction_Currency__c,
                        Reason_Code__c = reasonCode.Id
                    );
                }
                return repairWO;
            } set;
        }
        
        public Sales_Order__c rmaRepairSO {
            get {
                if (rmaRepairSO == null) {
                    rmaRepairSO = new Sales_Order__c(
                        Type__c = SalesOrderService.SO_TYPE_RMA_REPAIR,
                        Status__c = SalesOrderService.SO_STATUS_OPEN,
                        Company__c = company.Id,
                        Customer__c = customers.get('Customer Sold To 1').Id,
                        Ship_to__c = customers.get('Customer Ship To 1').Id,
                        Bill_To__c = customers.get('Customer Bill To 1').Id,
                        Payment_Term__c = terms.Id,
                        Ship_From_Location__c = locations.get('Delivery/Shipping/scrap Location').Id,
                        Required_Date__c = Date.today() + 30
                    );
                    insert rmaRepairSO;
                }
                return rmaRepairSO;
            } set;
        }
            
        public Sales_Order_Line__c rmaRepairSOL {
            get {
                if (rmaRepairSOL == null) {
                    rmaRepairSOL = new Sales_Order_Line__c(
                        Company__c = company.Id,
                        Status__c = 'Open',
                        Required_Date__c = Date.today() + 30,
                        Sales_Order__c = rmaRepairSO.Id,
                        Line__c = 1,
                        Product__c = products.get('Product-15').Id,
                        Fulfillment_Source__c = 'Inventory',
                        Quantity_Ordered__c = -1,
                        Quantity_Backordered__c = 1,
                        Ship_From_Location__c = locations.get('Delivery/Shipping/scrap Location').Id,
                        Unit_Price__c = 12.11
                    );
                }
                return rmaRepairSOL;
            } set;
        }
                
        public Sales_Order__c repairSO {
            get {
                if (repairSO == null) {
                    repairSO = new Sales_Order__c(
                        Type__c = SalesOrderService.SO_TYPE_REPAIR,
                        Status__c = SalesOrderService.SO_STATUS_OPEN,
                        Company__c = company.Id,
                        Customer__c = customers.get('Customer Sold To 1').Id,
                        Ship_to__c = customers.get('Customer Ship To 1').Id,
                        Bill_To__c = customers.get('Customer Bill To 1').Id,
                        Payment_Term__c = terms.Id,
                        Ship_From_Location__c = locations.get('Delivery/Shipping/scrap Location').Id,
                        Required_Date__c = Date.today() + 30
                    );
                    insert repairSO;
                }
                return repairSO;
            } set;
        }
            
        public Sales_Order_Line__c repairSOL {
            get {
                if (repairSOL == null) {
                    repairSOL = new Sales_Order_Line__c(
                        Company__c = company.Id,
                        Status__c = 'Open',
                        Required_Date__c = Date.today() + 30,
                        Sales_Order__c = repairSO.Id,
                        Line__c = 1,
                        Product__c = products.get('Product-15').Id,
                        Fulfillment_Source__c = 'Inventory',
                        Quantity_Ordered__c = 1,
                        Quantity_Backordered__c = 1,
                        Ship_From_Location__c = locations.get('Delivery/Shipping/scrap Location').Id,
                        Unit_Price__c = 12.11
                    );
                }
                return repairSOL;
            } set;
        }

        public RepairData(Boolean reship,Boolean manual) {
            createRepairData(reship,manual);
        }
        
        public RepairData(Boolean reship) {
            createRepairData(reship,false);   
        }

        public void createRepairData(Boolean reship, Boolean manual) {
            DML.systemTime = system.now().addHours(-2);
            List<sObjectType> skipTriggers = new List<sObjectType>{ Work_Order__c.sObjectType,Receiving_Document__c.sObjectType,Receipt_Line__c.sObjectType,Inventory_Transaction__c.sObjectType,SKID__c.sObjectType,
                Item_Attribute__c.sObjectType,Lot__c.sObjectType,Shipment__c.sObjectType,Shipment_Line__c.sObjectType };
            List<Configuration__c> configList = new List<Configuration__c>();
            for (sObjectType s:skipTriggers) {
                configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserId()));  
            }
            insert configList;
            
            update new Item_Attribute__c(Id = itemAttr.Id, Expiration_Date__c = false);
                
            Lot__c lot = new Lot__c(Name = 'ABC', Company__c = company.Id, Item__c = items.get(company.Name + ' Item-15').Id);
            Lot__c lot1 = new Lot__c(Name = 'ABCD', Company__c = company.Id, Item__c = items.get(company.Name + ' Item-15').Id);
            insert new List<Lot__c>{ lot, lot1 };
            
            if (reship) {
                Receiving_Document__c rmaRD = new Receiving_Document__c(Type__c = 'RMA Receipt');
                insert rmaRD;
                
                Receipt_Line__c rmaRL = new Receipt_Line__c(Receiving_Document__c = rmaRd.Id);
                rmaRL.Sales_Order_Line__c = rmaRepairSOL.Id;
                insert rmaRL;
                
                insert rmaRepairSOL;
                repairSOL.Receipt_Line__c = rmaRL.Id;
                insert repairSOL;
                
                SKID__c skid = new SKID__c(Facility2__c = facility.Id, Company__c = company.Id, Sales_Order_Line__c = rmaRepairSOL.Id,Location__c = locations.get('Stock').Id, Quantity__c = 10, Item__c = items.get(company.Name + ' Item-15').Id, Quantity_Stocking_UOM__c = 10, Packaging_UOM__c = items.get(company.Name + ' Item-15').Stocking_UOM__c,Stocking_UOM__c = items.get(company.Name + ' Item-15').Stocking_UOM__c, Container_Item__c = items.get(company.Name + ' Item-15').Id,  Type__c = SkidService3.SKID_TYPE_LOCATION, Lot_Number__c = lot.Name, Lot__c = lot.Id);
                insert skid;
                
                
                
                Shipment__c shipment = new Shipment__c(
                    Company__c = company.Id,
                    Customer__c = customers.get('Customer Ship To 1').Id,
                    Ship_From_Facility__c = facility.Id,
                    Ship_From_Location__c = locations.get('Delivery/Shipping/scrap Location').Id,
                    Status__c = 'Planned',
                    Type__c = ShipmentService.SHIPMENT_TYPE_SALES_ORDER,
                    Transaction_Type__c = ShipmentService.SHIPMENT_TRANSACTION_TYPE_SALES_ORDER_SHIPMENT
                );
                insert shipment;
                    
                Shipment_Line__c shl = new Shipment_Line__c(
                    Shipment__c = shipment.Id, 
                    Sales_Order_Line__c = repairSOL.Id,
                    Sales_Order_Line__r = repairSOL,
                    Company__c = company.Id,
                    Facility__c = facility.Id,
                    Location__c = locations.get('Delivery/Shipping/scrap Location').Id,
                    Product__c = products.get('Product-15').Id,
                    Item__c = items.get(company.Name + ' Item-15').Id,
                    Quantity_Planned__c = 1,
                    Quantity_Allocated__c = 0,
                    Quantity_Shipped__c = 0,
                    Sales_Order__c = repairSO.Id,
                    Unit_Price__c = 12.11
                );
                insert shl;
                    
                repairWO.Shipment_Line__c = shl.Id;
                insert repairWO;
                
                shl.Work_Order__c = repairWO.Id;
                shl.Sales_Order_Line__r.Related_Sales_Order_Line__c = rmaRepairSOL.Id;
                shl.Sales_Order_Line__r.Related_Sales_Order_Line__r = rmaRepairSOL;
                
                update new Sales_Order_Line__c(Id = repairSOL.Id, Work_Order__c = repairWO.Id,Related_Sales_Order_Line__c = rmaRepairSOL.Id);
                update shl;
            } else if (manual) {
                SKID__c skid = new SKID__c(Facility2__c = facility.Id, Company__c = company.Id, Location__c = locations.get('Stock').Id, Quantity__c = 10, Item__c = items.get(company.Name + ' Item-15').Id, Quantity_Stocking_UOM__c = 10, Packaging_UOM__c = items.get(company.Name + ' Item-15').Stocking_UOM__c,Stocking_UOM__c = items.get(company.Name + ' Item-15').Stocking_UOM__c, Container_Item__c = items.get(company.Name + ' Item-15').Id,  Type__c = SkidService3.SKID_TYPE_LOCATION, Lot_Number__c = lot.Name, Lot__c = lot.Id);
                SKID__c skid1 = new SKID__c(Facility2__c = facility.Id, Company__c = company.Id, Location__c = locations.get('Stock').Id, Quantity__c = 15, Item__c = items.get(company.Name + ' Item-15').Id, Quantity_Stocking_UOM__c = 15, Packaging_UOM__c = items.get(company.Name + ' Item-15').Stocking_UOM__c,Stocking_UOM__c = items.get(company.Name + ' Item-15').Stocking_UOM__c, Container_Item__c = items.get(company.Name + ' Item-15').Id,  Type__c = SkidService3.SKID_TYPE_LOCATION, Lot_Number__c = lot1.Name, Lot__c = lot1.Id);
                insert new List<SKID__c>{ skid, skid1 };
                
                insert repairWO;
            } else {     
                SKID__c skid = new SKID__c(Company__c = company.Id, Customer__c = customers.get('Customer Ship To 1').Id, Quantity__c = 10, Item__c = items.get(company.Name + ' Item-15').Id, Quantity_Stocking_UOM__c = 10, Packaging_UOM__c = items.get(company.Name + ' Item-15').Stocking_UOM__c,Stocking_UOM__c = items.get(company.Name + ' Item-15').Stocking_UOM__c, Container_Item__c = items.get(company.Name + ' Item-15').Id,  Type__c = SkidService3.SKID_TYPE_INSTALLBASE, Lot_Number__c = lot.Name, Lot__c = lot.Id);
                insert skid;
                
                repairSOL.SKID__c = skid.Id;
                repairWO.Field_Service__c = true;
                insert repairWO;
                
                repairSOL.Work_Order__c = repairWO.Id;
                insert repairSOL;
            }
                
            delete configList;
        }
    }

    private static testMethod void testReshipRepair() {
        RepairData testData = new RepairData(true);
        Work_Order__c wo = testData.repairWO;
        
        WorkOrderPlanningService.release(new Set<Id>{wo.Id});
        
        List<Material_Tracking__c> mtList = [SELECT Id,Type__c,Work_Order__r.Shipment_Line__r.Sales_Order_Line__r.Related_Sales_Order_Line__c FROM Material_Tracking__c WHERE Work_Order__c = :wo.Id];
        System.assert(mtList.size() == 1);
        System.assert(mtList[0].Type__c == 'Repair');

        List<Operation_Tracking__c> opList = [SELECT Id FROM Operation_Tracking__c WHERE Work_Order__c = :wo.Id];
        System.assert(opList.size() == 1);

        Id opId = opList[0].Id;
        
        JsonResult kitResult = WorkOrderKitExtV2.getKitData(wo.Id);
        System.assert(kitResult.success);
        System.assert(kitResult.records.size() == 1);
        
        List<WorkOrderWrapper> wowList = (List<WorkOrderWrapper>)kitResult.records;
        System.assert(wowList[0].serialWrapperList.size() == 1);
        System.assert(wowList[0].serialWrapperList[0].skid.Type__c == 'Location');
        
        wowList[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        Test.startTest();
        JsonResult result = WorkOrderKitExtV2.save(wowList,new List<String>(),new List<String>());
        System.assert(result.success);
        
        List<Inventory_Transaction__c> itList = [SELECT Id,To_SKID__c,To_SKID__r.Type__c,Type__c FROM Inventory_Transaction__c WHERE Inventory_Change__r.Type__c = 'Work Order Kit' AND Inventory_Change__r.Work_Order__c = :wo.Id];
        System.assert(itList.size() == 1);
        System.assert(itList[0].To_SKID__c != null);
        System.assert(itList[0].To_SKID__r.Type__c == 'WIP');
        System.assert(itList[0].Type__c == 'Work Order Repair Component Issue');


        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c op = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, op, true).records[0];
        assembly.skid.Quantity_Used__c = 1;

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, op, null, assembly, null, null, true) });
        
        itList = [SELECT Id,To_SKID__c,To_SKID__r.Type__c,Type__c FROM Inventory_Transaction__c WHERE Inventory_Change__r.Type__c = 'Work Order Complete' AND Inventory_Change__r.Work_Order__c = :wo.Id];
        System.assert(itList.size() == 2);
        for (Inventory_Transaction__c it:itList) {
            if (it.Type__c == 'Work Order Repair Assembly Completion') {
                System.assert(it.To_SKID__c != null);
                System.assert(it.To_SKID__r.Type__c == 'Location');
            } else if (it.Type__c == 'Work Order Repair Issue From WIP') {
                System.assert(it.To_SKID__c == null);
            } else {
                System.assert(false,'Unexpected IT type: ' + it.Type__c);
            }
        }
        Test.stopTest();
        List<SKID__c> allocatedSkids = [SELECT Id,Sales_Order_Line__r.Quantity_Allocated__c FROM SKID__c WHERE Type__c = 'Allocated' AND Sales_Order_Line__c = :testData.repairSOL.Id];
        System.assert(allocatedSkids.size() == 1);
        System.assert(allocatedSkids[0].Sales_Order_Line__r.Quantity_Allocated__c == 1);
    }

    private static testMethod void testReshipRepairDekit() {
        RepairData data = new RepairData(true);

        Work_Order__c wo = data.repairWO;

        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        List<WorkOrderWrapper> wowList = (List<WorkOrderWrapper>)WorkOrderKitExtV2.getKitData(wo.Id).records;
        wowList[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        Test.startTest();
        WorkOrderKitExtV2.save(wowList, new List<String>(), new List<String>());

        
        JsonResult result = WorkOrderDeKitExtV2.getDeKitData(wo.Id);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);
        wowList = (List<WorkOrderWrapper>)result.records;
        System.assert(wowList[0].serialWrapperList.size() == 1, wowList[0].serialWrapperList);
        wowList[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        result = WorkOrderDeKitExtV2.save(wo.Id, wowList, new List<String>(), new List<String>());
        System.assert(result.success, result);

        Test.stopTest();

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addAllCustomFields(SKID__c.sObjectType, 'From_SKID__r');
        itQuery.addAllCustomFields(SKID__c.sObjectType, 'To_SKID__r');
        itQuery.setWhereClause('Inventory_Change__r.Type__c = \'Work Order DeKit\' AND Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\'');
        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 1, itList);
        System.assert(itList[0].Receipt_Line__c != null, itList[0]);
        System.assert(itList[0].Type__c == 'Work Order Repair Component Return');
        System.assert(itList[0].From_SKID__c == null, itList[0]);
        System.assert(itList[0].To_SKID__c != null, itList[0]);
        System.assert(itList[0].To_SKID__r.Receipt_Line__c != null, itList[0].To_SKID__r);
        System.assert(itList[0].To_SKID__r.Type__c == 'Location', itList[0].To_SKID__r);
    }

    private static testMethod void testReshipRepairManuallyAllocate() {
        RepairData data = new RepairData(true);

        Work_Order__c wo = data.repairWO;

        WorkOrderPlanningService.release(new Set<Id>{ wo.Id });

        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
        shlQuery.addAllCustomFields();
        shlQuery.addAllCustomFields(Shipment__c.sObjectType, 'Shipment__r');
        shlQuery.setWhereClause('Sales_Order_Line__c = \'' + data.repairSOL.Id + '\'');

        Shipment_Line__c shl = Database.query(shlQuery.getQuery());
        Shipment__c shipment = shl.Shipment__r;

        Id itemId = data.items.get(data.company.Name + ' Item-15').Id;
        Item__c item = data.items.get(data.company.Name + ' Item-15');

        Lot__c lot = [SELECT Id, Name FROM Lot__c WHERE Item__c = :itemId][0];

        insert new SKID__c(Company__c = data.company.Id, Facility2__c = data.locations.get('Stock').Facility__c, Location__c = data.locations.get('Stock').Id, Quantity__c = 10,Quantity_Stocking_UOM__c = 10,  Item__c = itemId,Stocking_UOM__c = item.Stocking_UOM__c, Packaging_UOM__c = item.Stocking_UOM__c, Type__c = SkidService3.SKID_TYPE_LOCATION, Lot_Number__c = lot.Name, Lot__c = lot.Id);

        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shl.Shipment__c }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                sw.skid.Input_Quantity__c = 1;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        Test.startTest();
        AllocationService.allocate(wrappers);

        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shl.Shipment__c }, 'planpick'));
       
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                sw.skid.Input_Quantity__c = 1;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }

        
        
        ShipmentInventoryService.plan(wrappers);

        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shl.Shipment__c }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                sw.skid.Input_Quantity__c = 1;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        ShipmentInventoryService.pick(wrappers);

        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(ext.shipMode, ext);
        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        System.assert(shipment.Date_Shipped__c.date() == Date.today(), shipment);    //comparing datetime will lead to failure because datetime is measured in milliseconds

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id, ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 1, result.records);
        List<LineWrapper> shlData = (List<LineWrapper>)result.records;
        System.assert(shlData[0].serialWrappers.size() == 1, shlData[0].serialWrappers);
        System.assert(shlData[0].serialWrappers[0].skid.Quantity__c == 1, shlData[0].serialWrappers[0].skid);
        result = ShipmentManageDeliveryExtV2.save(shipment, shlData, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);

        shipment = [SELECT Id, Status__c FROM Shipment__c WHERE Id = :shipment.Id];
        System.assert(shipment.Status__c == 'Confirmed', shipment);

        wo = [SELECT Id, Status__c FROM Work_Order__c WHERE Id = :wo.Id];
        System.assert(wo.Status__c == WorkOrderService.WO_STATUS_RELEASED, wo);
        Test.stopTest();
    }

    private static testMethod void testReshipRepairReleaseSkids() {
        RepairData data = new RepairData(true);

        Id woId = data.repairWO.Id;

        WorkOrderPlanningService.release(new Set<Id>{ woId });

        WorkOrderService.validateForClose(new Set<Id>{ woId });
        WorkOrderService.closeCancel(new Set<Id>{ woId }, WorkOrderService.WO_STATUS_CLOSED);

        List<SKID__c> skids = [SELECT Id, Receipt_Line__c FROM SKID__c WHERE Receipt_Line__c != null];
        System.assert(skids.size() == 0, skids);
    }

    private static testMethod void testFieldRepair() {
        RepairData testData = new RepairData(false);
        Work_Order__c wo = testData.repairWO;
        
        WorkOrderPlanningService.release(new Set<Id>{wo.Id});
        
        List<Material_Tracking__c> mtList = [SELECT Id,Type__c FROM Material_Tracking__c WHERE Work_Order__c = :wo.Id];
        System.assert(mtList.size() == 1);
        System.assert(mtList[0].Type__c == 'Repair');

        List<Operation_Tracking__c> opList = [SELECT Id FROM Operation_Tracking__c WHERE Work_Order__c = :wo.Id];
        System.assert(opList.size() == 1);

        Id opId = opList[0].Id;
        
        JsonResult kitResult = WorkOrderKitExtV2.getKitData(wo.Id);
        System.assert(kitResult.success);
        System.assert(kitResult.records.size() == 1);
        
        List<WorkOrderWrapper> wowList = (List<WorkOrderWrapper>)kitResult.records;
        System.assert(wowList[0].serialWrapperList.size() == 1);
        System.assert(wowList[0].serialWrapperList[0].skid.Type__c == 'Install Base');
        
        wowList[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        
        JsonResult result = WorkOrderKitExtV2.save(wowList,new List<String>(),new List<String>());
        System.assert(result.success);
        
        List<Inventory_Transaction__c> itList = [SELECT Id,To_SKID__c,To_SKID__r.Type__c,Type__c,Customer__c FROM Inventory_Transaction__c WHERE Inventory_Change__r.Type__c = 'Work Order Kit' AND Inventory_Change__r.Work_Order__c = :wo.Id];
        System.assert(itList.size() == 1);
        System.assert(itList[0].To_SKID__c != null);
        System.assert(itList[0].To_SKID__r.Type__c == 'WIP');
        System.assert(itList[0].Type__c == 'Work Order Repair Component Issue');
        System.assert(itList[0].Customer__c != null);
        
        Test.startTest();

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c op = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, op, true).records[0];
        assembly.skid.Quantity_Used__c = 1;

        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, op, null, assembly, null, null, true) });

        itList = [SELECT Id,To_SKID__c,To_SKID__r.Type__c,Type__c FROM Inventory_Transaction__c WHERE Inventory_Change__r.Type__c = 'Work Order Complete' AND Inventory_Change__r.Work_Order__c = :wo.Id];
        System.assert(itList.size() == 2);
        for (Inventory_Transaction__c it:itList) {
            if (it.Type__c == 'Work Order Repair Assembly Completion') {
                System.assert(it.To_SKID__c != null);
                System.assert(it.To_SKID__r.Type__c == 'Install Base');
            } else if (it.Type__c == 'Work Order Repair Issue From WIP') {
                System.assert(it.To_SKID__c == null);
            } else {
                System.assert(false,'Unexpected IT type: ' + it.Type__c);
            }
        }
        
        List<Fulfillment__c> fulfillments = [SELECT Id,SKID__c,SKID__r.Type__c FROM Fulfillment__c WHERE Sales_Order_Line__c = :testData.repairSOL.Id];
        System.assert(fulfillments.size() == 1);
        System.assert(fulfillments[0].SKID__c != null);
        System.assert(fulfillments[0].SKID__r.Type__c == 'Install Base');
    }
    
    private static testMethod void testManualRepair() {
        RepairData testData = new RepairData(false, true);
        Work_Order__c wo = testData.repairWO;
        
        WorkOrderPlanningService.release(new Set<Id>{wo.Id});
        
        List<Material_Tracking__c> mtList = [SELECT Id,Type__c FROM Material_Tracking__c WHERE Work_Order__c = :wo.Id];
        System.assert(mtList.size() == 1);
        System.assert(mtList[0].Type__c == 'Repair');

        List<Operation_Tracking__c> opList = [SELECT Id FROM Operation_Tracking__c WHERE Work_Order__c = :wo.Id];
        System.assert(opList.size() == 1);

        Id opId = opList[0].Id;
        
        JsonResult kitResult = WorkOrderKitExtV2.getKitData(wo.Id);
        System.assert(kitResult.success);
        System.assert(kitResult.records.size() == 1);
        
        List<WorkOrderWrapper> wowList = (List<WorkOrderWrapper>)kitResult.records;
        System.assert(wowList[0].serialWrapperList.size() == 2);
        System.assert(wowList[0].serialWrapperList[0].skid.Type__c == 'Location');
        
        wowList[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        
        JsonResult result = WorkOrderKitExtV2.save(wowList,new List<String>(),new List<String>());
        System.assert(result.success);
        
        List<Inventory_Transaction__c> itList = [SELECT Id,To_SKID__c,To_SKID__r.Type__c,Type__c,Customer__c FROM Inventory_Transaction__c WHERE Inventory_Change__r.Type__c = 'Work Order Kit' AND Inventory_Change__r.Work_Order__c = :wo.Id];
        System.assert(itList.size() == 1);
        System.assert(itList[0].To_SKID__c != null);
        System.assert(itList[0].To_SKID__r.Type__c == 'WIP');
        System.assert(itList[0].Type__c == 'Work Order Repair Component Issue');
        System.assert(itList[0].Customer__c == null);

        Test.setCurrentPage(Page.WorkOrderCompleteV2);
        ApexPages.currentPage().getParameters().put('wo',wo.Id);
        ApexPages.currentPage().getParameters().put('op',opId);

        wo = WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        Operation_Tracking__c op = wo.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, op, true).records[0];
        assembly.skid.Quantity_Used__c = 1;

        Test.startTest();
        
        WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, op, null, assembly, null, null, true) });
        
        Test.stopTest();
        itList = [SELECT Id,To_SKID__c,To_SKID__r.Type__c,Type__c FROM Inventory_Transaction__c WHERE Inventory_Change__r.Type__c = 'Work Order Complete' AND Inventory_Change__r.Work_Order__c = :wo.Id];
        System.assert(itList.size() == 2);
        for (Inventory_Transaction__c it:itList) {
            if (it.Type__c == 'Work Order Repair Assembly Completion') {
                System.assert(it.To_SKID__c != null);
                System.assert(it.To_SKID__r.Type__c == 'Location');
            } else if (it.Type__c == 'Work Order Repair Issue From WIP') {
                System.assert(it.To_SKID__c == null);
            } else {
                System.assert(false,'Unexpected IT type: ' + it.Type__c);
            }
        }
    }
}