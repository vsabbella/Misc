@isTest
public with sharing class SalesOrderKitTest {

    public static TestFuel fuel = new TestFuel();

    public static List<Period__c> periodList = fuel.periodList;
    public static List<SKID__c> skids = fuel.skids;
    public static List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
    public static List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;

    public static Product__c prod1 = fuel.product;
    public static Product__c prod2 = fuel.product2;

    public static Sales_order__c salesOrder;

    public static Sales_Order_Line__c kitSol;
    public static Item_Specification__c kitAssembly;

    // used for non exception testing
    static void createDefaultKitData(){
        /*  create kit product: create Item Spec, create Item */
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Company__c.sObjectType,Facility__c.sObjectType,Item__c.sObjectType,Item_Specification__c.sObjectType,Component__c.sObjectType,Product__c.sObjectType,Pricebook_Line__c.sObjectType,
        Location__c.sObjectType,Bin__c.sObjectType,Stock_Movement_Rule__c.sObjectType,Stock_Movement_Rule_Settings__c.sObjectType,Shipment__c.sObjectType,Shipment_Line__c.sObjectType};  
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        Item__c kitItem = new Item__c(
                name= fuel.company.Name + ' kit Item-1',
                Description__c = 'Kit Item Item-1',
                Source__c = 'Kit', // important for kitting
                Non_Shippable__c = true, // important for kitting
                Class__c = fuel.clsobj.ID,
                Lead_Time__c = 2,
                ABC_Code__c = 'Kit-123',
                company__c = fuel.company.id,
                Active__c = true,
                Stocking_UOM__c = fuel.uomList[8].Id,
                Packaging_UOM__c= JSON.serialize(new List<Id> {fuel.uomList[8].Id})
        );
        insert kitItem;   

        kitAssembly = new Item_Specification__c(
                Facility__c = fuel.facility2.id,
                Item__c  =  kitItem.id,
                Start_Date2__c = System.now().addDays(-39),
                Revision__c = 'A',
                Company__c = fuel.company.id,
                Production__c = true,
                Costing__c = true
        );
        insert kitAssembly; // important for kitting

        List<Component__c> componentList = new List<Component__c>{
            new Component__c(
                Component_Item__c = fuel.itemList[0].Id, // item in the item spec. children of item spec
                Assembly_Item_Specification__c = kitAssembly.Id, // root item
                Type__c = ComponentService.TYPE_KIT,
                Company__c = fuel.company.Id,
                Quantity_per_Assembly__c = 2
            ),
            new Component__c(
                Component_Item__c = fuel.itemList[5].Id, // item in the item spec. children of item spec
                Assembly_Item_Specification__c = kitAssembly.Id, // root item
                Type__c = ComponentService.TYPE_KIT,
                Company__c = fuel.company.Id,
                Quantity_per_Assembly__c = 3
            )
        };
        insert componentList;

        Product__c kitProd = new Product__c( // important for kitting
            company__c = fuel.company.id,
            Name = 'Kit Product' ,
            Item__c  = kitItem.id,
            Item__r = kitItem,
            Description__c = 'Kit Product',
            Selling_UOM__c = fuel.uomList[8].ID,
            Weight__c = 13,
            Weight_UOM__c = fuel.uomList[3].ID,
            UPC_Code__c = '1234567891234',
            Primary_Key__c = '1234564',
            Dimension_UOM__c = fuel.uomList[6].ID,
            Invoiceable__c = true,
            Length__c = 1,
            Width__c = 1,
            Height__c = 1
        );
        insert kitProd;

        Pricebook_Line__c kitProdPBL =new Pricebook_Line__c(
            product__c = kitProd.Id,
            pricebook__c = fuel.pricebook.id,
            price__c = 80,
            start_date__c = system.today().adddays(0),
            end_date__c = system.today().adddays(10)
        );
        insert kitProdPBL;

        //system.assertEquals(3, [select id from Pricebook_Line__c].size());
        // assign Item spec to kit product
        salesOrder = new Sales_order__c(
            Company__c = fuel.company.Id,
            Customer__c = fuel.customerSoldTo.Id,
            Ship_to__c = fuel.customerShipTo.Id,
            Bill_To__c = fuel.customerBillTo.Id,
            Payment_Term__c = fuel.terms.Id,
            Currency__c = TestFuel.currencyUSD.id,
            Pricebook__c = fuel.pricebook.Id
        );
        insert salesOrder;
        delete configlist;
        kitSol = new Sales_Order_Line__c(
            Company__c = fuel.company.Id,
            Description__c = kitProd.Description__c,
            Discount_Percent__c = 2,
            Required_Date__c = System.today()+5,
            Sales_Order__c = salesOrder.Id,
            Ship_From_Location__c = fuel.location2.Id,
            Product__c = kitProd.id, // Add Kit product to the SO
            Product__r = kitProd,
            Pricebook__c = fuel.pricebook.Id,
            Type__c = 'Kit-Child',
            //Invoiceable__c = true,
            Quantity_Ordered__c = 10,
            Unit_Price__c = 80,
            Item_Specification__c = kitAssembly.Id
        );
        insert kitSol;

        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
            Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0),
            rank__c = 1,
            Group_By_Customer_Hierarchy__c = 'Bill To',
            Group_By_Sales_Orders__c = true,
            Company__c = fuel.company.Id
        );

        insert igr;
    }

    static void pickAndShipV2(Id shipmentId) { pickAndShipV2(shipmentId, false); }
    static void pickAndShipV2(Id shipmentId, Boolean shipFail) {
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipmentId }, 'planpick'));
        List<LineWrapper> wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }
        ShipmentInventoryService.plan(wrappers);

        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipmentId }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }
        ShipmentInventoryService.pick(wrappers);

        if (c.Id != null) delete c;

        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(new Shipment__c(Id = shipmentId)));
        Shipment__c shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);
        JsonResult result = ShipmentManageDeliveryExtV2.save(shipment, ShipmentInventoryService.getLinesForShip(new Set<Id>{ shipmentId }, true), new List<String>(), new List<String>(), new List<String>(), true);
        if (shipFail) System.assert(!result.success, result);
        else System.assert(result.success, result);
    }

    static testMethod void testKittingFlowPartialQtyForConfirmShipV2() {
        createDefaultKitData();
        new SalesOrderService().plan(salesOrder.Id);

        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines('AND Sales_Order__c = \'' + salesOrder.Id + '\'', 'allocate'));
        System.assert(shipmentLines.size() == 2, shipmentLines.size());
        for (Shipment_Line__c shl:shipmentLines.values()) {
            System.assert(shl.Item__r.Non_Shippable__c == false, shl.Item__r);
            System.assert(shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c != null, shl.Sales_Order_Line__r);
        }

        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            Shipment_Line__c shl = shipmentLines.get(wrapper.line.Id);
            wrapper.line = shl;
            wrapper.header = shl.Shipment__r;
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) {
                    if (shl.Item__c == prod1.Item__c) sw.skid.Input_Quantity__c = 12;
                    else if (shl.Item__c == prod2.Item__c) sw.skid.Input_Quantity__c = 18;
                    else sw.skid.Input_Quantity__c = 0;
                } else {
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        Test.startTest();
        AllocationService.allocate(wrappers);
       

        shipmentLines = new Map<Id, Shipment_Line__c>([SELECT Id, Name, Item__c, Quantity_Allocated__c, Shipment__c FROM Shipment_Line__c WHERE Sales_Order__c = :salesOrder.Id]);
        for (Shipment_line__c shl:shipmentLines.values()) {
            if (shl.Item__c == prod1.Item__c) System.assert(shl.Quantity_Allocated__c == 12, shl);
            else System.assert(shl.Quantity_Allocated__c == 18, shl);
        }


        pickAndShipV2(shipmentLines.values()[0].Shipment__c);

        // error should be thrown. No shipments should be shipped. Invalid quantity for line.
        salesOrder = [select id, Status__c, (select id, Status__c, Quantity_Ordered__c, Item_Source__c, Quantity_Shipped__c from Sales_Order_Lines__r) from Sales_Order__c where id = :salesOrder.id];

        List<Fulfillment__c> fulfillments = [select id, Product__c, Sales_Order_Line__c, Invoice_Ready__c, Parent_Fulfillment__c, Product__r.Item__r.Source__c, Quantity__c from Fulfillment__c];
        system.assertEquals(3 ,fulfillments.size());

        for (fulfillment__c ful : fulfillments){
            if (ful.Parent_Fulfillment__c == null){
                system.assertEquals(6, ful.Quantity__c);
            } else {
                if (ful.Product__c == prod1.id){
                    System.assertEquals(12, ful.Quantity__c); // comp qty = 3. only ship 3 * 5 = 15
                }

                if (ful.Product__c == prod2.id){
                    System.assertEquals(18, ful.Quantity__c); // comp qty = 2. only ship 2 * 5 = 10
                }
            }
        }
        for (Sales_Order_Line__c sol : salesOrder.Sales_Order_Lines__r){
            system.assertEquals('Open', sol.Status__c, sol + '\n' + salesOrder.Sales_Order_Lines__r);
        }
        system.assertEquals('Open', salesOrder.Status__c);

        Test.stopTest();
    }

    static testMethod void testKittingFlowInvalidPartialEvenQtyForConfirmShipV2(){

        createDefaultKitData();

        new SalesOrderService().plan(salesOrder.id);
        Test.startTest();


        /* Allocate, pick, ship for shippable items only */

        List<Shipment_Line__c> shlList =  [select id,Name, Quantity_Planned__c,
                                            Item__c, Shipment__c, Shipment__r.Status__c, Item__r.Non_Shippable__c,
                                            Sales_Order__c, Sales_Order__r.Status__c, Sales_Order_Line__r.Quantity_Ordered__c,
                                            Sales_Order_Line__r.Quantity_Allocated__c, Sales_Order_Line__r.Quantity_Shipped__c,
                                            Sales_order_Line__r.Parent_Sales_Order_Line__c, Item__r.Source__c, Item__r.Packaging_UOM__c,
                                            Sales_order_Line__r.Product__r.Item__r.Packaging_UOM__c 
                                            from Shipment_Line__c where Sales_Order__c = :salesOrder.id];

        for (Shipment_Line__c shl : shlList){
            System.assert(shl.Item__r.Non_Shippable__c == false, shl.Item__r);
            System.assert(shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c != null);
        }
        system.assertEquals(2, shlList.size(), 'Expecting 2 lines: ' + shlList);

        Shipment__c shipment = shlList[0].Shipment__r;
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            Shipment_Line__c shl = shipmentLines.get(wrapper.line.Id);
            wrapper.line = shl;
            wrapper.header = shl.Shipment__r;
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) {
                    if (shl.Item__c == prod1.Item__c) sw.skid.Input_Quantity__c = 18;
                    else if (shl.Item__c == prod2.Item__c) sw.skid.Input_Quantity__c = 15;
                    else sw.skid.Input_Quantity__c = 0;
                } else {
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        shlList =  [select id,Name, Quantity_Planned__c, Quantity_Allocated__c, Quantity_Shipped__c,
                                            Item__c, Shipment__c, Shipment__r.Status__c, Item__r.Non_Shippable__c,
                                            Sales_Order__c, Sales_order_Line__r.Parent_Sales_Order_Line__c, Item__r.Source__c, Item__r.Packaging_UOM__c,
                                            Sales_order_Line__r.Product__r.Item__r.Packaging_UOM__c 
                                            from Shipment_Line__c where Sales_Order__c = :salesOrder.id];

        for (Shipment_line__c shpLine : shlList){
            if (shpLine.Item__c == prod1.Item__c){
                System.assertEquals(18, shpLine.Quantity_Allocated__c);
            }

            if (shpLine.Item__c == prod2.Item__c){
                System.assertEquals(15, shpLine.Quantity_Allocated__c);
            }
        }

        pickAndShipV2(shipment.Id,true);

        //System.assert(result.success == true, result);
        
        /* assert for correctness */
        // error should be thrown. No shipments should be shipped. Invalid quantity for line.
        salesOrder = [select id, Status__c, (select id, Status__c, Quantity_Ordered__c, Item_Source__c, Quantity_Shipped__c from Sales_Order_Lines__r) from Sales_Order__c where id = :salesOrder.id];

        for (Sales_order_Line__c sol : salesOrder.Sales_Order_Lines__r){
            System.assertEquals(0, sol.Quantity_Shipped__c, sol);
        }

        List<Fulfillment__c> fulfillmets = [select id, Sales_Order_Line__c, Invoice_Ready__c, Parent_Fulfillment__c, Product__r.Item__r.Source__c, Quantity__c from Fulfillment__c];
        system.assertEquals(0 ,fulfillmets.size());


        for (Sales_Order_Line__c sol : salesOrder.Sales_Order_Lines__r){
            system.assertEquals('Open', sol.Status__c, sol + '\n' + salesOrder.Sales_Order_Lines__r);
        }
        system.assertEquals('Open', salesOrder.Status__c);
    }

    static testMethod void testKittingFlowInvalidQtyForConfirmShipV2() {

        createDefaultKitData();

        new SalesOrderService().plan(salesOrder.id);
        Test.startTest();


        /* Allocate, pick, ship for shippable items only */

        List<Shipment_Line__c> shlList =  [select id,Name, Quantity_Planned__c,
                                            Item__c, Shipment__c, Shipment__r.Status__c, Item__r.Non_Shippable__c,
                                            Sales_Order__c, Sales_Order__r.Status__c, Sales_Order_Line__r.Quantity_Ordered__c,
                                            Sales_Order_Line__r.Quantity_Allocated__c, Sales_Order_Line__r.Quantity_Shipped__c,
                                            Sales_order_Line__r.Parent_Sales_Order_Line__c, Item__r.Source__c, Item__r.Packaging_UOM__c,
                                            Sales_order_Line__r.Product__r.Item__r.Packaging_UOM__c 
                                            from Shipment_Line__c where Sales_Order__c = :salesOrder.id];

        for (Shipment_Line__c shl : shlList){
            System.assert(shl.Item__r.Non_Shippable__c == false, shl.Item__r);
            System.assert(shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c != null);
        }
        system.assertEquals(2, shlList.size(), 'Expecting 2 lines: ' + shlList);

        Shipment__c shipment = shlList[0].Shipment__r;
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            Shipment_Line__c shl = shipmentLines.get(wrapper.line.Id);
            wrapper.line = shl;
            wrapper.header = shl.Shipment__r;
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) {
                    if (shl.Item__c == prod1.Item__c) sw.skid.Input_Quantity__c = 15;
                    else if (shl.Item__c == prod2.Item__c) sw.skid.Input_Quantity__c = 25;
                    else sw.skid.Input_Quantity__c = 0;
                } else {
                    sw.skid.Input_Quantity__c = 0;
                }
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        shlList =  [select id,Name, Quantity_Planned__c, Quantity_Allocated__c, Quantity_Shipped__c,
                                            Item__c, Shipment__c, Shipment__r.Status__c, Item__r.Non_Shippable__c,
                                            Sales_Order__c, Sales_order_Line__r.Parent_Sales_Order_Line__c, Item__r.Source__c
                                            from Shipment_Line__c where Sales_Order__c = :salesOrder.id];

        for (Shipment_line__c shpLine : shlList){
            if (shpLine.Item__c == prod1.Item__c){
                System.assertEquals(15, shpLine.Quantity_Allocated__c);
            }

            if (shpLine.Item__c == prod2.Item__c){
                System.assertEquals(25, shpLine.Quantity_Allocated__c);
            }
        }

        pickAndShipV2(shipment.Id,true);

        //System.assert(result.success == true, result);
        
        /* assert for correctness */
        // error should be thrown. No shipments should be shipped. Invalid quantity for line.
        salesOrder = [select id, Status__c, (select id, Status__c, Quantity_Ordered__c, Item_Source__c, Quantity_Shipped__c from Sales_Order_Lines__r) from Sales_Order__c where id = :salesOrder.id];

        for (Sales_order_Line__c sol : salesOrder.Sales_Order_Lines__r){
            System.assertEquals(0, sol.Quantity_Shipped__c, sol);
        }

        List<Fulfillment__c> fulfillmets = [select id, Sales_Order_Line__c, Invoice_Ready__c, Parent_Fulfillment__c, Product__r.Item__r.Source__c, Quantity__c from Fulfillment__c];
        system.assertEquals(0 ,fulfillmets.size());


        for (Sales_Order_Line__c sol : salesOrder.Sales_Order_Lines__r){
            system.assertEquals('Open', sol.Status__c, sol + '\n' + salesOrder.Sales_Order_Lines__r);
        }
        system.assertEquals('Open', salesOrder.Status__c);
    }

    private static Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
    private static testMethod void testKittingFlowReleaseShipInvoiceV2() {
        createDefaultKitData();

        new SalesOrderService().plan(salesOrder.Id);


        
        salesOrder = [SELECT Id, Has_Exceptions__c, (SELECT Id, Has_Exceptions__c FROM Sales_Order_Lines__r) FROM Sales_Order__c WHERE Id = :salesOrder.Id];
        for (Sales_Order_Line__c sol:salesOrder.Sales_Order_Lines__r) {
            System.assertEquals(false, sol.Has_Exceptions__c, 'Not expecting any exceptions: ' + ExceptionService.fetchExceptionTasks(new Set<Id>{ sol.Id }));
        }
        System.assertEquals(false, salesOrder.Has_Exceptions__c, 'Not expecting any exceptions: ' + ExceptionService.fetchExceptionTasks(new Set<Id>{ salesOrder.Id }));
        System.assertEquals(3, salesOrder.Sales_Order_Lines__r.size(), salesOrder.Sales_Order_Lines__r);
        Test.startTest();   

        insert c;

        List<Shipment_Line__c> shlList = [SELECT Id, Name, Item__r.Non_Shippable__c, Sales_Order__r.Has_Exceptions__c, Sales_Order__r.Line_Exceptions__c, Sales_Order__r.Open_Sales_Order_Lines__c, Sales_Order_Line__r.Parent_Sales_Order_Line__c, Shipment__r.Id FROM Shipment_Line__c WHERE Sales_Order__c = :salesOrder.Id];
        System.assert(shlList.size() == 2, shlList.size());

        for (Shipment_Line__c shl:shlList) {
            System.assert(shl.Item__r.Non_Shippable__c == false, shl.Item__r);
            System.assert(shl.Sales_Order__r.Open_Sales_Order_Lines__c == 3, shl.Sales_Order__r);
            System.assert(shl.Sales_Order__r.Has_Exceptions__c == false, shl.Sales_Order__r);
            System.assert(shl.Sales_Order__r.Line_Exceptions__c == 0, shl.Sales_Order__r);
            System.assert(shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c != null, shl.Sales_Order_Line__r);
        }

        Shipment__c shipment = shlList[0].Shipment__r;

        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            Shipment_Line__c shl = shipmentLines.get(wrapper.line.Id);
            wrapper.line = shl;
            wrapper.header = shl.Shipment__r;
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = shl.Quantity_Planned__c;
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);

        pickAndShipV2(shipment.Id);

        
        salesOrder = [SELECT Id, Status__c, (SELECT Id, Status__c, Item_Source__c, Quantity_Ordered__c, Quantity_Shipped__c FROM Sales_Order_Lines__r) FROM Sales_Order__c WHERE Id = :salesOrder.Id];
        for (Sales_Order_Line__c sol:salesOrder.Sales_Order_Lines__r) {
            System.assertEquals('Closed', sol.Status__c, sol);
            if (sol.Item_Source__c != 'Kit'){
                System.assertEquals(sol.Quantity_Ordered__c, sol.Quantity_Shipped__c, sol);
            }
        }
        System.assertEquals(3, salesOrder.Sales_Order_Lines__r.size());
        System.assertEquals('Closed', salesOrder.Status__c);

       

        List<Fulfillment__c> fulfillments = [SELECT Id, Name, Invoice_Ready__c, Parent_Fulfillment__c, Sales_Order_Line__c, Product__r.Item__r.Source__c, Sales_Order__r.Status__c, Sales_Order_Line__r.Quantity_Ordered__c, Sales_Order_Line__r.Quantity_Shipped__c, Sales_Order_Line__r.Status__c FROM Fulfillment__c];
        System.assert(fulfillments.size() == 3, fulfillments.size());
        Set<Id> solIds = new Set<Id>();
        for (Fulfillment__c fulfillment:fulfillments) {
            solIds.add(fulfillment.Sales_Order_Line__c);
            
            System.assert(fulfillment.Sales_Order__r.Status__c == 'Closed', fulfillment.Sales_Order__r);
            System.assert(fulfillment.Sales_Order_Line__r.Status__c == 'Closed', fulfillment.Sales_Order_Line__r);

            if (fulfillment.Product__r.Item__r.Source__c != 'Kit') {
                System.assert(fulfillment.Invoice_Ready__c == false, fulfillment);
                System.assert(fulfillment.Parent_Fulfillment__c != null, fulfillment);
                System.assert(fulfillment.Sales_Order_Line__r.Quantity_Ordered__c == fulfillment.Sales_Order_Line__r.Quantity_Shipped__c, fulfillment.Sales_Order_Line__r);

            } else {
                System.assert(fulfillment.Invoice_Ready__c == true, fulfillment);
                System.assert(fulfillment.Parent_Fulfillment__c == null, fulfillment);
            }
        }
        System.assert(solIds.size() == 3, solIds.size());

        Database.executebatch(new CustomerInvoiceBatch(new Set<Id>{ fuel.company.Id }), 10);


        Test.stopTest();
        List<Customer_Invoice_Line__c> cils = [SELECT Id FROM Customer_Invoice_Line__c];
        System.assertEquals(1, cils.size(), cils);
    }
    
    static testMethod void testKittingFlowUndoShipV2() {
        createDefaultKitData();
        new SalesOrderService().plan(salesOrder.Id);

        List<Shipment_Line__c> shlList = [SELECT Id, Name, Item__c, Item__r.Non_Shippable__c, Sales_Order__c, Sales_Order__r.Has_Exceptions__c, Sales_Order_Line__c, Sales_Order_Line__r.Has_Exceptions__c, Sales_Order_Line__r.Parent_Sales_Order_Line__c, Shipment__c, Shipment__r.Id FROM Shipment_Line__c WHERE Sales_Order__c = :salesOrder.Id];
        System.assert(shlList.size() == 2, shlList.size());

        Shipment_Line__c shipline;
        Shipment_Line__c shipline1;
        Sales_Order_Line__c soline;
        Sales_Order_Line__c soline1;
        for (Shipment_Line__c shl:shlList) {
            System.assert(shl.Item__r.Non_Shippable__c == false, shl.Item__r);
            System.assert(shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c != null, shl.Sales_Order_Line__r);
            System.assert(shl.Sales_Order__r.Has_Exceptions__c == false, shl.Sales_Order__r);
            System.assert(shl.Sales_Order_Line__r.Has_Exceptions__c == false, shl.Sales_Order_Line__r);
            if (shl.Item__c == fuel.itemList[0].Id) {
                shipline = shl;
                soline = shl.Sales_Order_Line__r;
            } else {
                shipline1 = shl;
                soline1 = shl.Sales_Order_Line__r;
            }
        }
        
        Shipment__c shipment = shlList[0].Shipment__r;
        
        Inventory_Change__c ichange = new Inventory_Change__c();
        
        ichange.Type__c = 'Sales Order Shipment';
        ichange.Transaction_Date__c = system.today();
        
        insert ichange;
        
        List<Inventory_Transaction__c> itlist = new List<Inventory_Transaction__c>();
        insert c;
        Inventory_Transaction__c it = new Inventory_Transaction__c();
        
        it.Type__c = 'Sales Order Shipment';
        it.Subtransaction_Type__c = 'Sales Order Shipment';
        it.Sales_Order_Line__c = soline.Id;
        it.Shipment_Line__c = shipLine.Id;
        it.Finalized__c = true;
        it.Inventory_Change__c = ichange.Id;
        it.Quantity__c = 5;
        it.Quantity_Stocking_UOM__c = 5;
        it.Transaction_Date__c = system.now();
        it.From_Facility__c = fuel.facility2.id;
        it.From_Location__c = fuel.location3.id;
        it.Item__c = fuel.itemList[0].Id;
        it.Item__r = fuel.itemList[0];
        it.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
        it.Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c;
        it.Company__c = fuel.company.Id;
        itlist.add(it);
        
        Inventory_Transaction__c it1 = new Inventory_Transaction__c();
        
        it1.Type__c = 'Sales Order Shipment';
        it1.Subtransaction_Type__c = 'Sales Order Shipment';
        it1.Sales_Order_Line__c = soline1.Id;
        it1.Shipment_Line__c = shipLine1.Id;
        it1.Finalized__c = true;
        it1.Inventory_Change__c = ichange.Id;
        it1.Transaction_Date__c = system.now();
        it1.Quantity__c = 5;
        it1.Quantity_Stocking_UOM__c = 5;
        it1.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
        it1.Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c;
        it1.From_Facility__c = fuel.facility2.id;
        it1.From_Location__c = fuel.location3.id;
        it1.Item__c =fuel.itemList[5].Id;
        it1.Item__r =fuel.itemList[5];
        it1.Company__c = fuel.company.Id;
        itlist.add(it1);
		
         
        insert itlist;
       
        Fulfillment__c fulfillKit = new Fulfillment__c();
        
        fulfillKit.Quantity__c = 5;
        fulfillKit.Type__c = 'Kit';
        fulfillKit.Sales_Order_Line__c = kitSol.Id;
        fulfillKit.Invoice_ready__c = true;
        
        insert fulfillKit;
        
        Fulfillment__c fulfillInv = new Fulfillment__c();
        
        fulfillInv.Quantity__c = 5;
        fulfillInv.Type__c = 'Sales Order Shipment';
        fulfillInv.Inventory_Transaction__c = it.Id;
        fulfillInv.Sales_Order_Line__c = soline.Id;
        fulfillInv.Shipment_Line__c = shipLine.Id;
        fulfillInv.Parent_Fulfillment__c = fulfillKit.Id;
        fulfillInv.Invoice_ready__c = true;
        
        insert fulfillInv;
        
        
        Fulfillment__c fulfillInv1 = new Fulfillment__c();
        
        fulfillInv1.Quantity__c = 5;
        fulfillInv1.Type__c = 'Sales Order Shipment';
        fulfillInv1.Inventory_Transaction__c = it1.Id;
        fulfillInv1.Sales_Order_Line__c = soline1.Id;
        fulfillInv1.Shipment_Line__c = shipLine1.Id;
        fulfillInv1.Parent_Fulfillment__c = fulfillKit.Id;
        fulfillInv1.Invoice_ready__c = true;
        
        insert fulfillInv1;
        
        shipLine.Quantity_Shipped__c = 5;
        shipLine.Quantity_Planned__c = 5;
        shipLine.Quantity_Allocated__c = 0;
        
        update shipLine;
        
        shipLine1.Quantity_Shipped__c = 5;
        shipLine1.Quantity_Planned__c = 5;
        shipLine1.Quantity_Allocated__c = 0;
        
        update shipLine1;
        
        
        shipment.Finalized__c = true;
        shipment.Date_Shipped__c = system.now();
        shipment.Transaction_Date__c = system.now();
        shipment.Currency__c = Testfuel.currencyUSD.id;

        shipment.Status__c ='Confirmed';
        update shipment;
		
		delete c;
		
		Test.startTest();
        //Undo Ship
        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipment));
        System.assert(!ext.shipMode, ext);
        shipment = (Shipment__c)JSON.deserialize(ext.shipmentJson, Shipment__c.Class);

        JsonResult result = ShipmentManageDeliveryExtV2.getShipmentLineData(shipment.Id,ext.shipMode);
        System.assert(result.success, result);
        System.assert(result.records.size() == 2, result.records);

        List<LineWrapper> wrappers = (List<LineWrapper>)result.records;
        for (LineWrapper wrapper:wrappers) {
            System.assert(wrapper.serialWrappers.size() == 1, wrapper.serialWrappers);
            System.assert(wrapper.serialWrappers[0].skid.Quantity__c == 5, wrapper.serialWrappers[0].skid);
        }

        result = ShipmentManageDeliveryExtV2.save(shipment, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);
        
        List<Fulfillment__c> fulfillrecs = [Select Id,Name,Invoice_Ready__c,Type__c, Parent_Fulfillment__r.Name,Parent_Fulfillment__c from Fulfillment__c where Type__c IN('Kit','Reverse Kit')];
        
        system.assert(fulfillrecs.size() == 2, fulfillrecs);
        for(Fulfillment__c ful:fulfillrecs){
            system.assert(ful.Invoice_Ready__c == false,ful);
        }

        Test.stopTest();
    }
    
    static testMethod void testKittingFlowReleaseUnrelease(){

        createDefaultKitData();

        /* Relase */
        new SalesOrderService().plan(salesOrder.id);
        Test.startTest();

        salesOrder = [select id, Has_Exceptions__c, (select id, Quantity_Ordered__c, Product__c, Has_Exceptions__c, Status__c, Parent_Sales_Order_Line__c from Sales_Order_Lines__r) from Sales_order__c where id =: salesOrder.id LIMIT 1];

        // map for testing the qty update. If parent line qty is change, child lines should reflect. Handled in SalesOrderLineService trigger
        Map <Id, Decimal> solItemToQuantityMap = new Map <Id, Decimal>();

        // check for exceptions
        for (Sales_order_Line__c sol : salesOrder.Sales_Order_lines__r){
            System.assertEquals(false, sol.Has_Exceptions__c, 'Not expecting any exceptions: ' + ExceptionService.fetchExceptionTasks(new set<Id>{sol.id}));
            System.assertEquals('Open', sol.Status__c);
            solItemToQuantityMap.put(sol.Product__c, sol.Quantity_Ordered__c);
        }
        // check for header exceptions
        System.assertEquals(false, salesOrder.Has_Exceptions__c, 'Not expecting any exceptions: ' + ExceptionService.fetchExceptionTasks(new set<Id>{salesOrder.id}));

        System.assertEquals(3, salesOrder.Sales_order_lines__r.size(), salesOrder.Sales_Order_Lines__r);

        List<Shipment_Line__c> shlList = [select id from Shipment_Line__c];
        system.assertEquals(2, shlList.size(), shlList);

        /* qty change */
        Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
        insert rc;
        kitSol.Quantity_Ordered__c = 20; // double the qty
        kitSol.Quantity_Change_Reason__c = rc.id;
        update kitSol;

        salesOrder = [select id, Has_Exceptions__c, (select id, Item_Source__c, Quantity_Ordered__c, Product__c, Has_Exceptions__c, Status__c, Parent_Sales_Order_Line__c from Sales_Order_Lines__r) from Sales_order__c where id =: salesOrder.id LIMIT 1];

        for (Sales_order_Line__c sol : salesOrder.Sales_order_Lines__r){
            System.assertEquals(solItemToQuantityMap.get(sol.Product__c)*2, sol.Quantity_Ordered__c, solItemToQuantityMap + ' ' + salesOrder.Sales_order_Lines__r); // qty should be doubled on the child lines
        }

        /* undo plan */
        new SalesOrderService().undoPlan(new Set<Id>{salesOrder.id});

        salesOrder = [select id, Has_Exceptions__c, (select id, Quantity_Fulfilled__c, Has_Exceptions__c, Status__c, Parent_Sales_Order_Line__c from Sales_Order_Lines__r) from Sales_order__c where id =: salesOrder.id LIMIT 1];

        // check for Line exceptions
        for (Sales_order_Line__c sol : salesOrder.Sales_Order_lines__r){
            System.assertEquals(false, sol.Has_Exceptions__c, 'Not expecting any exceptions: ' + ExceptionService.fetchExceptionTasks(new set<Id>{sol.id}));
        }

        shlList = [select id from Shipment_Line__c];
        system.assertEquals(0, shlList.size(), shlList);

        // check for header exceptions
        System.assertEquals(false, salesOrder.Has_Exceptions__c, 'Not expecting any exceptions: ' + ExceptionService.fetchExceptionTasks(new set<Id>{salesOrder.id}));

        System.assertEquals(1, salesOrder.Sales_order_lines__r.size(), salesOrder.Sales_Order_Lines__r);

        Test.stopTest();
    }

    /* SOL Kit-child created by Item Source Kit parent SOL should be fine with $0 unit price. Exception should not be thrown.*/
    static testMethod void testKittingFlowReleaseOnChildLinesWithoutPBL(){

        /*  create kit product: create Item Spec, create Item */
        Item__c kitItem = new Item__c(
                name= fuel.company.Name + ' kit Item-1',
                Description__c = 'Kit Item Item-1',
                Source__c = 'Kit', // important for kitting
                Non_Shippable__c = true, // important for kitting
                Class__c = fuel.clsobj.ID,
                Lead_Time__c = 2,
                ABC_Code__c = 'Kit-123',
                company__c = fuel.company.id,
                Active__c = true,
                Stocking_UOM__c = fuel.uomList[8].Id,
                Packaging_UOM__c = JSON.serialize(new List<Id> {fuel.uomList[8].Id})
        );
        insert kitItem;

        kitAssembly = new Item_Specification__c(
                Facility__c = fuel.facility2.id,
                Item__c  =  kitItem.id,
                Start_Date2__c = System.now().addDays(-39),
                Revision__c = 'A',
                Company__c = fuel.company.id,
                Production__c = true,
                Costing__c = true,
                Packaging_UOM__c = fuel.uomList[8].Id
        );
        insert kitAssembly; // important for kitting

        List<Component__c> componentList = new List<Component__c>{
            new Component__c(
                Component_Item__c = fuel.itemList[1].Id, // item in the item spec. children of item spec
                Assembly_Item_Specification__c = kitAssembly.Id, // root item
                Type__c = ComponentService.TYPE_KIT,
                Company__c = fuel.company.Id,
                Quantity_per_Assembly__c = 2
            ),
            new Component__c(
                Component_Item__c = fuel.itemList[5].Id, // item in the item spec. children of item spec
                Assembly_Item_Specification__c = kitAssembly.Id, // root item
                Type__c = ComponentService.TYPE_KIT,
                Company__c = fuel.company.Id,
                Quantity_per_Assembly__c = 3
            )
        };
        insert componentList;

        // Created product with no PBL for exception. Belongs to Item kit's component
        Product__c badProduct = new Product__c();
        badProduct.company__c = fuel.company.id;
        badProduct.Name = 'Kit Product' ;
        badProduct.Item__c  = fuel.itemList[1].Id;
        badProduct.Description__c = 'Bad Product';
        badProduct.Selling_UOM__c = fuel.uomList[8].ID;
        badProduct.Weight__c = 13;
        badProduct.Weight_UOM__c = fuel.uomList[3].ID;
        badProduct.UPC_Code__c = '12345678912345';
        badProduct.Primary_Key__c = '12345641';
        badProduct.Dimension_UOM__c = fuel.uomList[6].ID;
        badProduct.Length__c = 1;
        badProduct.Width__c = 1;
        badProduct.Height__c = 1;
        insert badProduct;

        Product__c kitProd = new Product__c( // important for kitting
            company__c = fuel.company.id,
            Name = 'Kit Product' ,
            Item__c  = kitItem.id,
            Item__r = kitItem,
            Description__c = 'Kit Product',
            Selling_UOM__c = fuel.uomList[8].ID,
            Weight__c = 13,
            Weight_UOM__c = fuel.uomList[3].ID,
            UPC_Code__c = '1234567891234',
            Primary_Key__c = '1234564',
            Dimension_UOM__c = fuel.uomList[6].ID,
            Length__c = 1,
            Width__c = 1,
            Height__c = 1
        );
        insert kitProd;

        Pricebook_Line__c kitProdPBL =new Pricebook_Line__c(
            product__c = kitProd.Id,
            pricebook__c = fuel.pricebook.id,
            price__c = 80,
            start_date__c = system.today().adddays(0),
            end_date__c = system.today().adddays(10)
        );
        insert kitProdPBL;

        //system.assertEquals(3, [select id from Pricebook_Line__c].size());
        // assign Item spec to kit product
        salesOrder = new Sales_order__c(
            Company__c = fuel.company.Id,
            Customer__c = fuel.customerSoldTo.Id,
            Ship_to__c = fuel.customerShipTo.Id,
            Bill_To__c = fuel.customerBillTo.Id,
            Payment_Term__c = fuel.terms.Id,
            Currency__c = TestFuel.currencyUSD.id,
            Pricebook__c = fuel.pricebook.Id
        );
        insert salesOrder;

        kitSol = new Sales_Order_Line__c(
            Company__c = fuel.company.Id,
            Description__c = kitProd.Description__c,
            Discount_Percent__c = 2,
            Required_Date__c = System.today()+5,
            Sales_Order__c = salesOrder.Id,
            Ship_From_Location__c = fuel.location2.Id,
            Product__c = kitProd.id, // Add Kit product to the SO
            Product__r = kitProd,
            Pricebook__c = fuel.pricebook.Id,
            //Invoiceable__c = true,
            Quantity_Ordered__c = 10,
            Unit_Price__c = 80,
            Item_Specification__c = kitAssembly.Id
        );
        insert kitSol;

        Test.startTest();

        /* test child Item Exception should not be raised */

        SalesOrderService sos = new SalesOrderService();
        sos.plan(salesOrder.id);

        Test.stopTest();

        /* Use below for debugging test failures on release other it's a waste of a query */
        salesOrder = [select id, Has_Exceptions__c, (select id, Status__c, Item_Source__c, Has_Exceptions__c, Parent_Sales_Order_Line__c from Sales_Order_Lines__r) from Sales_order__c where id =: salesOrder.id LIMIT 1];

        System.assertEquals(3, salesOrder.Sales_order_lines__r.size(), salesOrder.Sales_Order_Lines__r);

        for (Sales_Order_Line__c sol : salesOrder.Sales_Order_Lines__r){
            System.assertEquals('Open',sol.Status__c, sol);
        }
    }

    static testMethod void testKittingFlowReleaseOnParentException(){
        
        createDefaultKitData();
        
        // create validation error by not having an item spec
        kitSol.Item_Specification__c = null;
        update kitSol;

        Test.startTest();
        /* test Item Specification Exception */
        new SalesOrderService().plan(salesOrder.id);


        /* Use below for debugging test failures on release other it's a waste of a query */
        salesOrder = [select id, Has_Exceptions__c, (select id, Has_Exceptions__c, Parent_Sales_Order_Line__c from Sales_Order_Lines__r) from Sales_order__c where id =: salesOrder.id LIMIT 1];

        // check for Line exceptions
        for (Sales_order_Line__c sol : salesOrder.Sales_Order_lines__r){
            System.assertEquals(true, sol.Has_Exceptions__c, 'Not expecting any exceptions: ' + ExceptionService.fetchExceptionTasks(new set<Id>{sol.id}));
        }

        // check for header exceptions
        System.assertEquals(true, salesOrder.Has_Exceptions__c, 'Not expecting any exceptions: ' + ExceptionService.fetchExceptionTasks(new set<Id>{salesOrder.id}));


        System.assertEquals(1, salesOrder.Sales_order_lines__r.size(), salesOrder.Sales_Order_Lines__r + ' - Exception 1 SOL since exception was raised on the SOL');

        /* Fix EXCEPTION */
        kitSol.Item_Specification__c = kitAssembly.Id;
        update kitSol;

        new SalesOrderService().plan(salesOrder.id);

        Test.stopTest();

        /* Use below for debugging test failures on release other it's a waste of a query */
        salesOrder = [select id, Has_Exceptions__c, (select id, Has_Exceptions__c, Parent_Sales_Order_Line__c from Sales_Order_Lines__r) from Sales_order__c where id =: salesOrder.id LIMIT 1];

        // check for Line exceptions
        for (Sales_order_Line__c sol : salesOrder.Sales_Order_lines__r){
            System.assertEquals(false, sol.Has_Exceptions__c, 'Not expecting any exceptions: ' + ExceptionService.fetchExceptionTasks(new set<Id>{sol.id}));
        }

        // check for header exceptions
        System.assertEquals(false, salesOrder.Has_Exceptions__c, 'Not expecting any exceptions: ' + ExceptionService.fetchExceptionTasks(new set<Id>{salesOrder.id}));

        System.assertEquals(3, salesOrder.Sales_order_lines__r.size(), salesOrder.Sales_Order_Lines__r);


        /* Allocate, pick, ship for shippable items only */

        List<Shipment_Line__c> shlList =  [select id,Name, Quantity_Planned__c,
                                            Item__c, Shipment__c, Shipment__r.Status__c, Item__r.Non_Shippable__c,
                                            Sales_Order__c, Sales_Order__r.Status__c, Sales_Order_Line__r.Quantity_Ordered__c,
                                            Sales_Order_Line__r.Quantity_Allocated__c, Sales_Order_Line__r.Quantity_Shipped__c,
                                            Sales_order_Line__r.Parent_Sales_Order_Line__c, Item__r.Source__c
                                            from Shipment_Line__c where Sales_Order__c = :salesOrder.id];

        for (Shipment_Line__c shl : shlList){
            System.assert(shl.Item__r.Non_Shippable__c == false, shl.Item__r);
            System.assert(shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c != null);
        }
        system.assertEquals(2, shlList.size(), 'Expecting 2 lines: ' + shlList);

        Shipment__c shipment = shlList[0].Shipment__r;
    }
    
    static testMethod void testReleaseKitwithWarranty(){
        
        createDefaultKitData();
        Test.startTest();
        
        Item__c warrantyItem = new Item__c(
                name= fuel.company.Name + ' warranty Item-1',
                Description__c = 'Kit Item Item-1',
                Source__c = 'Purchased', // important for kitting
                Non_Shippable__c = true,
                ABC_Code__c = 'Warr-123',
                company__c = fuel.company.id,
                Active__c = true,
                Stocking_UOM__c = fuel.uomList[8].Id,
                Packaging_UOM__c = JSON.serialize(new List<Id>{fuel.uomList[8].Id})
        );
        insert warrantyItem;
        
        Product__c warrantyProduct = new Product__c(
                company__c = fuel.company.id,
                Name = 'Warranty' ,
                Item__c  = warrantyItem.ID,
                Item__r = warrantyItem,
                Pricebook_Line_Required__c = false,
                Product_Type__c = 'Warranty'
        );
        insert warrantyProduct;
        
        
        Sales_Order_Line__c warrantysol = new Sales_Order_Line__c();
        warrantysol.Company__c = fuel.company.id;
        warrantysol.Discount_Percent__c = 2;
        warrantysol.Product__c = warrantyProduct.Id;
        warrantysol.Product__r = warrantyProduct;
        warrantysol.Quantity_Ordered__c = 1;
        warrantysol.Required_Date__c = System.today()+15;
        warrantysol.Sales_Order__c = salesOrder.Id;
        warrantysol.Ship_From_Location__c = fuel.location2.Id;
        warrantysol.Parent_Sales_Order_Line__c = kitSol.Id;
        warrantysol.Start_Date__c = system.today();
        warrantysol.End_Date__c = system.today().addDays(365);
        warrantysol.Unit_Price__c = 12.11;
        warrantysol.Sales_Tax__c = 14.686403;
        warrantysol.Memo__c = 'warrantysoline';
        
        insert warrantysol;
        
        Sales_Order__c sorder = [Select Id, Name, Exceptions_Count__c, Has_Exceptions__c from Sales_Order__c where Id =:salesOrder.Id limit 1];
      
        List<Sales_Order_Line__c> solinelist = [Select Id,Name, Product__c, Has_Exceptions__c, Exceptions_Count__c, Product__r.Name, Product__r.Product_Type__c, Product__r.Item__r.Source__c from Sales_Order_Line__c where Sales_Order__c = :sorder.Id];
        system.assert(solinelist.size() == 2,solinelist);
        Set<Id> solineIds = new Set<Id>();
        for(Sales_Order_Line__c soline:solinelist){
            solineIds.add(soline.Id);
        }
        
        List<Task> tasklist = [SELECT Id, whatId, subject, status, description FROM Task WHERE isClosed = false AND WhatId IN :solineIds];
        system.assert(tasklist.size() == 0,tasklist);
        new SalesOrderService().plan(sorder.id);
       
        List<Sales_Order_Line__c> solist = [Select Id,Name, Product__c, Product__r.Product_Type__c from Sales_Order_Line__c where Sales_Order__c = :sorder.Id];
        
        system.assert(solist.size() == 4, solist);
        List<Shipment_Line__c> shlList =  [select id,Name, Quantity_Planned__c,
                                            Item__c, Shipment__c, Shipment__r.Status__c, Item__r.Non_Shippable__c,
                                            Sales_Order__c, Sales_Order__r.Status__c, Sales_Order_Line__r.Quantity_Ordered__c,
                                            Sales_Order_Line__r.Quantity_Allocated__c, Sales_Order_Line__r.Quantity_Shipped__c,
                                            Sales_order_Line__r.Parent_Sales_Order_Line__c, Item__r.Source__c
                                            from Shipment_Line__c where Sales_Order__c = :sorder.id];
        
        
        for (Shipment_Line__c shl : shlList){
            System.assert(shl.Item__r.Non_Shippable__c == false, shl.Item__r);
            System.assert(shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c != null);
        }
        system.assertEquals(2, shlList.size(), 'Expecting 2 lines: ' + shlList);
        
        
        Test.stopTest();
        
    }
}