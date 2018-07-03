@isTest
private class MakeToOrderTest {
    @testSetup
    private static void setupData() {
        TestFuel fuel = new TestFuel();
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
        List<Period__c> periodList = fuel.periodList;
        Item_Attribute__c itemAttr = fuel.itemAttrObj2;
        Customer__c customer = fuel.customerShipTo;
        List<Location__c> locations = new List<Location__c>{ fuel.location2, fuel.location6, fuel.location7 };

        List<SKID__c> skids = fuel.skids;
        Map<Id,Lot__c> lots = new Map<Id,Lot__c>();
        for (Item__c i:fuel.itemList) {
            lots.put(i.Id,new Lot__c(
                Company__c = fuel.company.Id,
                Item__c = i.Id,
                Name = 'COMPLOT1',
                Expiration_Date__c = System.today() + 365
            ));
        }
        insert lots.values();

        for (SKID__c skid:skids) {
            skid.Lot__c = lots.get(skid.Item__c).Id;
            skid.Lot_Number__c = 'COMPLOT1';
        }
        update skids;

        insert new Invoice_Grouping_Rule__c(
            Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),
            Rank__c = 1,
            Group_By_Customer_Hierarchy__c = 'Bill To',
            Group_By_Sales_Orders__c = true,
            Company__c = fuel.company.Id
        );
    }

    public class MakeToOrderData {
        private Boolean makeToOrder = false;
        private Boolean serials = false;

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

        public Map<String,UOM__c> uoms {
            get {
                if (uoms == null) {
                    uoms = new Map<String,UOM__c>();
                    SOQLUtil uomQuery = new SOQLUtil('UOM__c');
                    uomQuery.addAllCustomFields();
                    for (UOM__c uom:Database.query(uomQuery.getQuery())) {
                        uoms.put(uom.Name,uom);
                    }
                }
                return uoms;
            } set;
        }

        public Class__c cls {
            get {
                if (cls == null) {
                    SOQLUtil classQuery = new SOQLUtil('Class__c');
                    classQuery.addAllCustomFields();
                    cls = (Class__c)Database.query(classQuery.getQuery())[0];
                }
                return cls;
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

        public Item_Attribute__c serialItemAttr {
            get {
                if (serialItemAttr == null) {
                    SOQLUtil itemAttrQuery = new SOQLUtil('Item_Attribute__c');
                    itemAttrQuery.addAllCustomFields();
                    itemAttrQuery.setWhereClause('Serial_Number__c = true');
                    serialItemAttr = (Item_Attribute__c)Database.query(itemAttrQuery.getQuery())[0];
                }
                return serialItemAttr;
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

        public Payment_Term__c payTerm {
            get {
                if (payTerm == null) {
                    SOQLUtil ptQuery = new SOQLUtil('Payment_Term__c');
                    ptQuery.addAllCustomFields();
                    payTerm = (Payment_Term__c)Database.query(ptQuery.getQuery())[0];
                }
                return payTerm;
            } set;
        }

        public Pricebook__c pricebook {
            get {
                if (pricebook == null) {
                    SOQLUtil pricebookQuery = new SOQLUtil('Pricebook__c');
                    pricebookQuery.addAllCustomFields();
                    pricebook = (Pricebook__c)Database.query(pricebookQuery.getQuery())[0];
                }
                return pricebook;
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

        public List<SKID__c> skids {
            get {
                if (skids == null) {
                    SOQLUtil skidQuery = new SOQLUtil('SKID__c');
                    skidQuery.addAllCustomFields();
                    skidQuery.setOrderByClause('Item__c,Location__c');
                    skids = Database.query(skidQuery.getQuery());
                }
                return skids;
            } set;
        }

        public Item__c item {
            get {
                if (item == null) {
                    item = new Item__c(
                        Company__c = company.Id,
                        Name = company.Name + ' Make Item',
                        Description__c = company.Name + ' Make Item',
                        Active__c = true,
                        Stocking_UOM__c = uoms.get('EA').Id,
                        Packaging_UOM__c = JSON.serialize(new List<Id>{uoms.get('EA').Id}),
                        Class__c = cls.Id,
                        Lead_Time__c = 2,
                        ABC_Code__c = 'make-123'
                    );
                    if (makeToOrder) {
                        item.Source__c = 'Build To Order';
                    } else {
                        item.Source__c = 'Manufacturered';
                    }
                    if (serials) {
                        item.Item_Attribute__c = serialItemAttr.Id;
                    } else {
                        item.Item_Attribute__c = itemAttr.Id;
                    }
                    insert item;
                }
                return item;
            } set;
        }

        public Item_Specification__c assembly {
            get {
                if (assembly == null) {
                    assembly = new Item_Specification__c(
                        Facility__c = facility.Id,
                        Item__c = item.Id,
                        Start_Date2__c = System.now().addDays(-39),
                        Packaging_UOM__c = item.Stocking_UOM__c,
                        Revision__c = 'A',
                        Company__c = company.Id,
                        Production__c = true,
                        Costing__c = true
                    );
                    insert assembly;

                    List<Component__c> comps = components;
                }
                return assembly;
            } set;
        }

        public List<Component__c> components {
            get {
                if (components == null) {
                    components = new List<Component__c>{
                        new Component__c(
                            Component_Item__c = items.get(company.Name + ' Item-10').Id,
                            Assembly_Item_Specification__c = assembly.Id,
                            Type__c = ComponentService.TYPE_BACKFLUSH,
                            Company__c = company.Id,
                            Quantity_per_Assembly__c = 1
                        )
                    };
                    insert components;
                }
                return components;
            } set;
        }

        public Product__c product {
            get {
                if (product == null) {
                    product = new Product__c(
                        Company__c = company.Id,
                        Name = 'Make Product',
                        Item__c = item.Id,
                        Description__c = 'Make Product',
                        Selling_UOM__c = uoms.get('EA').Id,
                        Weight__c = 13,
                        Weight_UOM__c = uoms.get('OZ').Id,
                        UPC_Code__c = '1234567891234',
                        Primary_Key__c = '1234564',
                        Dimension_UOM__c = uoms.get('IN').Id,
                        Invoiceable__c = true,
                        Length__c = 1,
                        Width__c = 1,
                        Height__c = 1,
                        Pricebook_Line_Required__c = false
                    );
                    insert product;
                }
                return product;
            } set;
        }

        public Sales_Order__c salesOrder {
            get {
                if (salesOrder == null) {
                    salesOrder = new Sales_Order__c(
                        Company__c = company.Id,
                        Customer__c = customers.get('Customer Sold To 1').Id,
                        Ship_to__c = customers.get('Customer Ship To 1').Id,
                        Bill_To__c = customers.get('Customer Bill To 1').Id,
                        Payment_Term__c = payTerm.Id,
                        Pricebook__c = pricebook.Id
                    );
                    insert salesOrder;

                    List<Sales_Order_Line__c> sols = salesOrderLines;
                }
                return salesOrder;
            } set;
        }
        
        public Sales_Order__c salesOrder2 {
            get {
                if (salesOrder2 == null) {
                    salesOrder2 = new Sales_Order__c(
                        Company__c = company.Id,
                        Customer__c = customers.get('Customer Sold To 1').Id,
                        Ship_to__c = customers.get('Customer Ship To 1').Id,
                        Bill_To__c = customers.get('Customer Bill To 1').Id,
                        Payment_Term__c = payTerm.Id,
                        Pricebook__c = pricebook.Id
                    );
                    insert salesOrder2;

                    List<Sales_Order_Line__c> sols = salesOrderLines2;
                }
                return salesOrder2;
            } set;
        }

        public List<Sales_Order_Line__c> salesOrderLines {
            get {
                if (salesOrderLines == null) {
                    salesOrderLines = new List<Sales_Order_Line__c>{
                        new Sales_Order_Line__c(
                            Company__c = company.Id,
                            Sales_Order__c = salesOrder.Id,
                            Ship_From_Location__c = locations.get('Delivery/Shipping/scrap Location').Id,
                            Product__c = product.Id,
                            Pricebook__c = pricebook.Id,
                            Item_Specification__c = assembly.Id,
                            Required_Date__c = System.today() + 5,
                            Quantity_Ordered__c = 10,
                            Unit_Price__c = 80,
                            Description__c = product.Description__c,
                            Discount_Percent__c = 2,
                            Selling_UOM__c = uoms.get('EA').Id
                        )
                    };
                    if (!makeToOrder) {
                        salesOrderLines[0].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BUILD_TO_ORDER;
                    }
                    insert salesOrderLines;
                }
                return salesOrderLines;
            } set;
        }
        
        public List<Sales_Order_Line__c> salesOrderLines2 {
            get {
                if (salesOrderLines2 == null) {
                    salesOrderLines2 = new List<Sales_Order_Line__c>{
                        new Sales_Order_Line__c(
                            Company__c = company.Id,
                            Sales_Order__c = salesOrder2.Id,
                            Ship_From_Location__c = locations.get('Delivery/Shipping/scrap Location').Id,
                            Product__c = product.Id,
                            Pricebook__c = pricebook.Id,
                            Item_Specification__c = assembly.Id,
                            Required_Date__c = System.today() + 5,
                            Quantity_Ordered__c = 10,
                            Unit_Price__c = 80,
                            Description__c = product.Description__c,
                            Discount_Percent__c = 2,
                            Selling_UOM__c = uoms.get('EA').Id
                        )
                    };
                    if (!makeToOrder) {
                        salesOrderLines2[0].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BUILD_TO_ORDER;
                    }
                    insert salesOrderLines2;
                }
                return salesOrderLines2;
            } set;
        }

        public Shipment_Line__c shl {
            get {
                if (shl == null) {
                    shl = querySHL();
                }
                return shl;
            } set;
        }

        public Shipment_Line__c querySHL() {
            SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
            shlQuery.addAllCustomFields();
            shlQuery.addAllCustomFields(Shipment__c.sObjectType,'Shipment__r');
            shlQuery.addAllCustomFields(Work_Order__c.sObjectType,'Work_Order__r');
            shlQuery.addAllCustomFields(Sales_Order__c.sObjectType,'Sales_Order__r');
            shlQuery.addAllCustomFields(Sales_Order_Line__c.sObjectType,'Sales_Order_Line__r');
            shlQuery.addFields(new Set<String>{ 'Product__r.Item__c','Product__r.Item__r.Stocking_UOM__c','Item__r.Non_Shippable__c','Sales_Order_Line__r.Ship_From_Location__r.Facility__c',
                'Item__r.Source__c','Sales_Order_Line__r.Item_Specification__c' });
            shlQuery.setWhereClause('Sales_Order__c = \'' + salesOrder.Id + '\'');

            SOQLUtil.ChildRelationship skidQuery = new SOQLUtil.ChildRelationship(shlQuery,'SKIDs__r');
            skidQuery.addAllCustomFields();
            skidQuery.setWhereClause('Type__c = \'Allocated\'');
            shlQuery.addChildRelationship(skidQuery);

            List<Shipment_Line__c> shipmentLines = Database.query(shlQuery.getQuery());
            System.assert(shipmentLines.size() == 1,shipmentLines.size() + ' shipment lines');
            
            salesOrderLines[0] = shipmentLines[0].Sales_Order_Line__r;
            shl = shipmentLines[0];

            return shl;
        }
        
        public Shipment_Line__c querySHL2() {
            SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
            shlQuery.addAllCustomFields();
            shlQuery.addAllCustomFields(Shipment__c.sObjectType,'Shipment__r');
            shlQuery.addAllCustomFields(Work_Order__c.sObjectType,'Work_Order__r');
            shlQuery.addAllCustomFields(Sales_Order__c.sObjectType,'Sales_Order__r');
            shlQuery.addAllCustomFields(Sales_Order_Line__c.sObjectType,'Sales_Order_Line__r');
            shlQuery.addFields(new Set<String>{ 'Product__r.Item__c','Product__r.Item__r.Stocking_UOM__c','Item__r.Non_Shippable__c','Sales_Order_Line__r.Ship_From_Location__r.Facility__c',
                'Item__r.Source__c','Sales_Order_Line__r.Item_Specification__c' });
            shlQuery.setWhereClause('Sales_Order__c = \'' + salesOrder2.Id + '\'');

            SOQLUtil.ChildRelationship skidQuery = new SOQLUtil.ChildRelationship(shlQuery,'SKIDs__r');
            skidQuery.addAllCustomFields();
            skidQuery.setWhereClause('Type__c = \'Allocated\'');
            shlQuery.addChildRelationship(skidQuery);

            List<Shipment_Line__c> shipmentLines = Database.query(shlQuery.getQuery());
            System.assert(shipmentLines.size() == 1,shipmentLines.size() + ' shipment lines');
            
            salesOrderLines2[0] = shipmentLines[0].Sales_Order_Line__r;
            shl = shipmentLines[0];

            return shl;
        }

        public Work_Order__c wo {
            get {
                if (wo== null) {
                    wo = new Work_Order__c(
                        Company__c = company.Id,
                        Facility__c = facility.Id,
                        Assembly_Item_Specification__c = assembly.Id,
                        Item__c = item.id,
                        Need_Date2__c = System.today() + 30,
                        Start_Date2__c = System.today().addDays(30 - (Integer)item.Lead_Time__c),
                        Order_Quantity__c = 10,
                        Status__c = 'Draft',
                        Type__c = 'Regular',
                        Complete_To_Location__c = locations.get('Stock').Id,
                        Packaging_UOM__c = item.Stocking_UOM__c,
                        MRB_Location__c = locations.get('Delivery/Shipping/scrap Location').Id,
                        Default_WIP_Location__c = locations.get('WIP Location').Id,
                        Notes__c = 'workorder',
                        Currency__c=company.Default_Transaction_Currency__c
                    );
                    insert wo;
                }
                return wo;
            } set;
        }

        public Work_Order__c queryWO() {
            return WorkOrderCompleteExtV2.getWorkOrder(wo.Id);
        }

        public MakeToOrderData(Boolean makeToOrder,Boolean serials) {
            this.makeToOrder = makeToOrder;
            this.serials = serials;

            if (makeToOrder) {
                facility.Default_Work_Order_Complete_to_Location__c = locations.get('Finished Goods').Id;
            } else {
                facility.Default_Work_Order_Complete_to_Location__c = locations.get('Stock').Id;
            }
            facility.Default_Work_Order_MRB_Location__c = locations.get('Delivery/Shipping/scrap Location').Id;
            facility.Default_Work_Order_WIP_Location__c = locations.get('WIP Location').Id;
            update facility;

            Lot__c lot = new Lot__c(
                Company__c = company.Id,
                Item__c = item.Id,
                Name = 'COMPLOT1',
                Expiration_Date__c = System.today() + 365
            );
            insert lot;
            
            SKID__c newSkid = new SKID__c(
                Facility2__c = facility.Id,
                Location__c = locations.get('Stock').Id,
                Company__c = company.Id,
                Quantity__c = 200.0,
                Quantity_Stocking_UOM__c = 200.0,
                Stocking_UOM__c = item.Stocking_UOM__c,
                Packaging_UOM__c = item.Stocking_UOM__c,
                Item__c = item.Id,
                Container_Item__c = item.Id,
                Type__c = SkidService3.SKID_TYPE_LOCATION,
                Expiration_Date__c = System.today() + 365,
                Lot__c = lot.Id,
                Lot_Number__c = 'COMPLOT1'
            );
            insert newSkid;
            
            if (serials) {
                List<Serial__c> serialList = new List<Serial__c>();
                for (SKID__c skid:skids) {
                    skid.Quantity__c = 5;
                    for (Integer i=0;i<5;i++) {
                        String uniqueKey = company.Id + '-' + skid.Item__c + '-' + skid.Id + ' SERIAL' + i;
                        serialList.add(new Serial__c(
                            Company__c = company.Id,
                            Item__c = skid.Item__c,
                            SKID__c = skid.Id,
                            Name = skid.Id + ' SERIAL' + i,
                            Unique_Key2__c = company.Id + '-' + skid.Item__c + '-' + skid.Id + ' SERIAL' + i
                        ));
                    }
                }
                insert serialList;
                update skids;
            }
        }

        public void releaseSalesOrder() { releaseSalesOrder(null); }
        public void releaseSalesOrder(Map<Id,Id> soMap) {
            if (soMap == null) {
                new SalesOrderService().plan(salesOrder.Id);
            } else {
                SalesOrderService.plan(soMap);
            }
        }
        
        public void createWorkOrderForSalesOrderLines(Boolean consolidate){
            List<Sales_Order_Line__c> sols = new List<Sales_Order_Line__c> ();
            Decimal addQty = 0;
            system.assert( wo != null && wo.Id != null);
            salesOrderLines[0].Work_Order__c = wo.Id;
            addQty += salesOrderLines[0].Quantity_Ordered__c;
            sols.add(salesOrderLines[0]);
            
            List<Shipment_Line__c> shls = new List<Shipment_Line__c> {querySHL()};
            if ( consolidate ) {
                shls.add ( querySHL2() );
                addQty += salesOrderLines2[0].Quantity_Ordered__c;
                salesOrderLines2[0].Work_Order__c = wo.Id;
                sols.add(salesOrderLines2[0]);
            }
            
            for (Shipment_Line__c shl: shls ) {
                shl.Work_Order__c = wo.Id;
            }
            
            wo.Order_Quantity__c += addQty;
            wo.Last_Sync_Date__c = System.now();
            update sols;
            update shls;
            
            update wo;
        }

        public void releaseWorkOrder() {
            WorkOrderPlanningService.release(new Set<Id>{ wo.Id });
        }
        
        public void completeWorkOrder() {
            Operation_Tracking__c op = wo.Operation_Trackings__r[0];

            SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(wo, op, true).records[0];
            assembly.skid.Quantity_Used__c = wo.Order_Quantity__c - 2;
            assembly.skid.Quantity_Scrapped__c = 2;
            assembly.skid.Expiration_Date__c = System.today() + 365;
            assembly.skid.Lot_Number__c = 'COMPLOT1';
            assembly.skid.Item__r = wo.Item__r;
            if (serials == true) {
                assembly.serialList = new List<Serial__c>();
                Integer index = 1;
                for (Integer i = 0; i < assembly.skid.Quantity_Used__c; i++) assembly.serialList.add(new Serial__c(Name='SERIAL' + (index++), Temporary_Value_Holder__c = 'Complete'));
                for (Integer i = 0; i < assembly.skid.Quantity_Scrapped__c; i++) assembly.serialList.add(new Serial__c(Name='SERIAL' + (index++), Temporary_Value_Holder__c = 'Scrap'));
            }

            JsonResult backflushResult =  WorkOrderCompleteExtV2.getBackflushData(wo.Id, op.Id, true);
            System.assert(backflushResult.success, backflushResult);
            System.assert(backflushResult.records.size() >= 1, backflushResult.records);
            List<WorkOrderWrapper> backflushRows = (List<WorkOrderWrapper>)backflushResult.records;
            backflushRows[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 4;

            WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(wo, op, null, assembly, backflushRows, null, true) });
        }
        
        public void uncompleteWorkOrder() {
            Id opId = wo.Operation_Trackings__r[0].Id;

            Test.setCurrentPage(Page.WorkOrderUncompleteV2);
            ApexPages.currentPage().getParameters().put('wo',wo.Id);
            ApexPages.currentPage().getParameters().put('op',opId);

            WorkOrderUncompleteExtV2 uncompleteExt = new WorkOrderUncompleteExtV2();
            Boolean last = uncompleteExt.last;
            System.assert(last,uncompleteExt);

            List<SkidService3.SerialWrapper> assemblyInfo = (List<SkidService3.SerialWrapper>)WorkOrderUncompleteExtV2.getHeaderAssemblyData(uncompleteExt.woId, uncompleteExt.opId, uncompleteExt.last).records[1];
            assemblyInfo[0].skid.Quantity_To_Return__c = 8;
            
            List<WorkOrderWrapper> componentRows = (List<WorkOrderWrapper>)WorkOrderUncompleteExtV2.getComponentData(wo,opId,last,assemblyInfo[0]).records;

            JsonResult saveResult = WorkOrderUncompleteExtV2.save(wo.Id,opId,assemblyInfo,componentRows,last,null);
            System.assert(saveResult.success,saveResult);
        }
    }

    public static testMethod void testMakeToOrder() {
        MakeToOrderData data = new MakeToOrderData(true,false);
        data.releaseSalesOrder();
        Test.startTest();
        data.createWorkOrderForSalesOrderLines(false);
        
        Shipment_Line__c shl = data.querySHL();
        System.assert(shl.Work_Order__c != null,shl);

        Work_Order__c wo = data.wo;
        Sales_Order_Line__c sol = data.salesOrderLines[0];
        System.assert(wo.Id == shl.Work_Order__c);
        System.assert(wo.Facility__c == sol.Ship_From_Location__r.Facility__c);
        System.assert(wo.Order_Quantity__c == 10 + sol.Quantity_Ordered__c);
        System.assert(wo.Assembly_Item_Specification__c == shl.Sales_Order_Line__r.Item_Specification__c, shl.Sales_Order_Line__r);
        System.assert(wo.Company__c == sol.Company__c);
        
        data.releaseWorkOrder();
        
        wo = data.queryWO();
        System.assert(wo.Operation_Trackings__r.size() == 1,wo.Operation_Trackings__r.size() + ' operation trackings');
        data.wo = wo;
        data.completeWorkOrder();
        wo = data.queryWO();
        

        Test.stopTest();

        shl = data.querySHL();
        System.assert(shl.Quantity_Allocated__c == 10,shl);
        System.assert(shl.SKIDs__r.size() == 1,shl.SKIDs__r);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{ 'To_SKID__r.Type__c','To_SKID__r.Quantity__c','To_SKID__r.Lot__c' });
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 4,itList.size() + ' inventory transactions');

        Inventory_Transaction__c it;
        for (Inventory_Transaction__c trans:itList) {
            if (trans.Type__c == 'Work Order Assembly Completion') {
                it = trans;
                break;
            }
        }

        System.assert(it != null);
        System.assert(it.To_SKID__c != null,it);
        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,it);
        System.assert(it.To_SKID__r.Quantity__c == 200 + 8 + shl.SKIDs__r[0].Quantity__c);
        System.assert(it.To_SKID__r.Lot__c == shl.SKIDs__r[0].Lot__c);
    }

    // public static testMethod void testMakeToOrderReverse() {
    //     DML.systemTime = system.now().addHours(-2); // Going back in time to allow skipping triggers 
    //     List<Configuration__c> configList = new List<Configuration__c>();
    //     List<sObjectType> skipTriggers = new List<sObjectType>{ 
    //             Pricebook__c.sObjectType,
    //             // Sales_Order__c.sObjectType,
    //             Sales_Order_Line__c.sObjectType,
    //             Work_Order__c.sObjectType,
    //             SKID__c.sObjectType,
    //             Shipment__c.sObjectType,
    //             Shipment_Line__c.sObjectType
    //     };
        
    //     for (sObjectType s:skipTriggers) {
    //         configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
    //     }
    //     insert configList;
        
    //     MakeToOrderData data = new MakeToOrderData(false,false);
    //     data.releaseSalesOrder();
    //     data.createWorkOrderForSalesOrderLines(false);
    //     Shipment_Line__c shl = data.querySHL();
    //     data.releaseWorkOrder();
        
    //     Test.startTest();
        
    //     Work_Order__c wo = data.queryWO();
    //     data.wo = wo;
    //     data.completeWorkOrder();
    //     data.uncompleteWorkOrder();

    //     Test.stopTest();

    //     shl = data.querySHL();
    //     System.assert(shl.Quantity_Allocated__c == 2,shl);
    //     System.assert(shl.SKIDs__r.size() == 1,shl.SKIDs__r);
    //     delete configList;
    // }

    public static testMethod void testBuildToOrder() {
        MakeToOrderData data = new MakeToOrderData(false,false);
        data.releaseSalesOrder();
        Test.startTest();
        data.createWorkOrderForSalesOrderLines(false);

        Shipment_Line__c shl = data.querySHL();
        System.assert(shl.Work_Order__c != null,shl);

        Work_Order__c wo = data.wo;
        Sales_Order_Line__c sol = data.salesOrderLines[0];
        System.assert(wo.Id == shl.Work_Order__c);
        System.assert(wo.Facility__c == sol.Ship_From_Location__r.Facility__c);
        System.assert(wo.Order_Quantity__c == 10 + sol.Quantity_Ordered__c);
        System.assert(wo.Assembly_Item_Specification__c == sol.Item_Specification__c);
        System.assert(wo.Company__c == sol.Company__c);
        
        data.releaseWorkOrder();
        
        wo = data.queryWO();
        System.assert(wo.Operation_Trackings__r.size() == 1,wo.Operation_Trackings__r.size() + ' operation trackings');
        
        data.wo = wo;
        data.completeWorkOrder();
        wo = data.queryWO();
        
        Test.stopTest();

        shl = data.querySHL();
        System.assert(shl.Quantity_Allocated__c == 10,shl);
        System.assert(shl.SKIDs__r.size() == 1,shl.SKIDs__r);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{ 'To_SKID__r.Type__c','To_SKID__r.Quantity__c','To_SKID__r.Lot__c' });
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        System.assert(itList.size() == 4,itList.size() + ' inventory transactions');

        Inventory_Transaction__c it;
        for (Inventory_Transaction__c trans:itList) {
            if (trans.Type__c == 'Work Order Assembly Completion') {
                it = trans;
                break;
            }
        }

        System.assert(it != null);
        System.assert(it.To_SKID__c != null,it);
        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,it);
        System.assert(it.To_SKID__r.Quantity__c == 200 + 8 + shl.SKIDs__r[0].Quantity__c);
        System.assert(it.To_SKID__r.Lot__c == shl.SKIDs__r[0].Lot__c);
    }
    
    // public static testMethod void testBuildToOrderConsolidation () {
    //     MakeToOrderData data = new MakeToOrderData(false,false);
        
    //     data.releaseSalesOrder( new Map<Id,Id> { data.salesOrder.Id=>null,data.salesOrder2.Id=>null });
        
    //     Test.startTest();
    //     data.createWorkOrderForSalesOrderLines(true);
        
    //     Shipment_Line__c shl = data.querySHL();
    //     System.assert(shl.Work_Order__c != null,shl);
        
    //     Work_Order__c wo = data.wo;
    //     Sales_Order_Line__c sol = data.salesOrderLines[0];
    //     Sales_Order_Line__c sol2 = data.salesOrderLines2[0];
    //     System.assert(wo.Facility__c == sol.Ship_From_Location__r.Facility__c);
    //     System.assert(wo.Order_Quantity__c > sol.Quantity_Ordered__c + sol2.Quantity_Ordered__c);
    //     System.assert(wo.Company__c == sol.Company__c);
        
    //     data.releaseWorkOrder();
        
    //     wo = data.queryWO();
    //     System.assert(wo.Id == shl.Work_Order__c,shl.Work_Order__c);
    //     System.assert(wo.Operation_Trackings__r.size() == 1,wo.Operation_Trackings__r.size() + ' operation trackings');
    //     data.wo = wo;
    //     data.completeWorkOrder();

    //     shl = data.querySHL();
    //     System.assert(shl.Quantity_Allocated__c == 10,shl);
    //     System.assert(shl.SKIDs__r.size() == 1,shl.SKIDs__r);
        
    //     shl = data.querySHL2();
    //     Test.stopTest();
    //     System.assert(shl.Quantity_Allocated__c == 10,shl);
    //     System.assert(shl.SKIDs__r.size() == 1,shl.SKIDs__r);

    //     SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
    //     itQuery.addAllCustomFields();
    //     itQuery.addFields(new Set<String>{ 'To_SKID__r.Type__c','To_SKID__r.Quantity__c','To_SKID__r.Lot__c' });
    //     itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\'');

    //     List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
    //     System.assert(itList.size() == 4,itList.size() + ' inventory transactions');

    //     Inventory_Transaction__c it;
    //     for (Inventory_Transaction__c trans:itList) {
    //         if (trans.Type__c == 'Work Order Assembly Completion') {
    //             it = trans;
    //             break;
    //         }
    //     }

    //     System.assert(it != null);
    //     System.assert(it.To_SKID__c != null,it);
    //     System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,it);
    //     System.assert(it.To_SKID__r.Quantity__c == 200 + 8 + 2 * shl.SKIDs__r[0].Quantity__c );
    //     System.assert(it.To_SKID__r.Lot__c == shl.SKIDs__r[0].Lot__c);
    // }
    
    // public static testMethod void testBuildToOrderReverse() {
    //     DML.systemTime = system.now().addHours(-2); // Going back in time to allow skipping triggers 
    //     List<Configuration__c> configList = new List<Configuration__c>();
    //     List<sObjectType> skipTriggers = new List<sObjectType>{ 
    //             Pricebook__c.sObjectType,
    //             // Sales_Order__c.sObjectType,
    //             Sales_Order_Line__c.sObjectType,
    //             Work_Order__c.sObjectType,
    //             SKID__c.sObjectType,
    //             Shipment__c.sObjectType,
    //             Shipment_Line__c.sObjectType
    //     };
        
    //     for (sObjectType s:skipTriggers) {
    //         configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
    //     }
    //     insert configList;
        
    //     MakeToOrderData data = new MakeToOrderData(false,false);
    //     data.releaseSalesOrder();
    //     data.createWorkOrderForSalesOrderLines(false);
    //     Shipment_Line__c shl = data.querySHL();
    //     Test.startTest();
    //     data.releaseWorkOrder();
        
    //     Work_Order__c wo = data.queryWO();
    //     System.assert(wo.Id == shl.Work_Order__c,shl.Work_Order__c);
    //     System.assert(wo.Operation_Trackings__r.size() == 1,wo.Operation_Trackings__r.size() + ' operation trackings');
    //     data.wo = wo;
    //     data.completeWorkOrder();
    //     data.uncompleteWorkOrder();
    //     Test.stopTest();

    //     shl = data.querySHL();
    //     System.assert(shl.Quantity_Allocated__c == 2,shl);
    //     System.assert(shl.SKIDs__r.size() == 1,shl.SKIDs__r);
    //     delete configList;
    //     System.debug(LoggingLevel.INFO, '*** Limits.getQueries-1(): ' + Limits.getQueries());
    // }

    public static testMethod void testBuildToOrderWithAllocation() {
        MakeToOrderData data = new MakeToOrderData(false,true);
        
        data.releaseSalesOrder();

        Test.startTest();
        
        data.createWorkOrderForSalesOrderLines(false);
        Shipment_Line__c shl = data.querySHL();

        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shl.Shipment__c }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == data.locations.get('Stock').Id) {
                    sw.skid.Input_Quantity__c = 5;
                    sw.serialList[0].Temporary_Value_Holder__c = 'Allocate';
                    sw.serialList[1].Temporary_Value_Holder__c = 'Allocate';
                    sw.serialList[2].Temporary_Value_Holder__c = 'Allocate';
                    sw.serialList[3].Temporary_Value_Holder__c = 'Allocate';
                    sw.serialList[4].Temporary_Value_Holder__c = 'Allocate';
                } else {
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        data.releaseWorkOrder();

        Work_Order__c wo = data.queryWO();
        data.wo = wo;
        
        data.completeWorkOrder();

        

        shl = data.querySHL();
        System.assert(shl.Quantity_Allocated__c == 10,shl);
        System.assert(shl.SKIDs__r.size() == 1,shl.SKIDs__r);

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{ 'To_SKID__r.Type__c','To_SKID__r.Quantity__c','To_SKID__r.Lot__c' });
        itQuery.setWhereClause('Inventory_Change__r.Work_Order__c = \'' + wo.Id + '\'');

        List<Inventory_Transaction__c> itList = Database.query(itQuery.getQuery());
        test.stopTest();
        System.assert(itList.size() == 4,itList.size() + ' inventory transactions');
        
        Inventory_Transaction__c it;
        for (Inventory_Transaction__c trans:itList) {
            if (trans.Type__c == 'Work Order Assembly Completion') {
                it = trans;
                break;
            }
        }

        System.assert(it != null);
        System.assert(it.To_SKID__c != null,it);
        System.assert(it.To_SKID__r.Type__c == SkidService3.SKID_TYPE_LOCATION,it);
        System.assert(it.To_SKID__r.Quantity__c == 5 + 3 + 5 + shl.SKIDs__r[0].Quantity__c,it.To_SKID__r + ' - ' + shl.SKIDs__r[0].Quantity__c);
        System.assert(it.To_SKID__r.Lot__c == shl.SKIDs__r[0].Lot__c);
    }

    public static testMethod void updateStatusTest() {
        MakeToOrderData data = new MakeToOrderData(false,false);
        data.releaseSalesOrder();
        Test.startTest();
        data.createWorkOrderForSalesOrderLines(false);

        Shipment_Line__c shl = data.querySHL();
        Sales_Order_Line__c sol = data.salesOrderLines[0];

        try {
            update new Sales_Order_Line__c(Id = sol.Id, Status__c = 'Closed');
        } catch (Exception e) {
            System.assert(false,e.getMessage());
        }

        Work_Order__c wo = data.queryWO();
        System.assert(wo.Status__c == 'Draft',wo);
        System.assert(wo.Close_Date__c == null,wo);

        try {
            update new Sales_Order_Line__c(Id = sol.Id, Status__c = 'Open');
        } catch (Exception e) {
            System.assert(false,e.getMessage());
        }

        wo = data.queryWO();
        System.assert(wo.Status__c == 'In Process',wo);
        System.assert(wo.Close_Date__c == null,wo);

        try {
            update new Sales_Order_Line__c(Id = sol.Id, Status__c = 'Cancelled');
        } catch (Exception e) {
            System.assert(false,e.getMessage());
        }

        wo = data.queryWO();
        System.assert(wo.Status__c == 'In Process',wo);
    }

    public static testMethod void makeToOrderErrors() {
        MakeToOrderData data = new MakeToOrderData(false,false);
        data.releaseSalesOrder();
        Test.startTest();
        data.createWorkOrderForSalesOrderLines(false);

        Shipment_Line__c shl = data.querySHL();

        data.releaseWorkOrder();
        
        Work_Order__c  wo = data.queryWO();
        System.assert(wo.Id == shl.Work_Order__c,shl.Work_Order__c);
        System.assert(wo.Operation_Trackings__r.size() == 1,wo.Operation_Trackings__r.size() + ' operation trackings');
        data.wo = wo;
        data.completeWorkOrder();

        try {
            update new Sales_Order_Line__c(Id = data.salesOrderLines[0].Id, Status__c = 'Cancelled');
            wo = data.queryWO();
            system.assert(wo.Status__c == 'Complete' );
        } catch (Exception e) {
            System.assert(false, e.getMessage() );
        }
    }
}