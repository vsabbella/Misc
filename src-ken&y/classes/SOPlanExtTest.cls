/**
 * This class contains unit tests for validating the behavior of methods in SOPlanExt.cls
 * and triggers.
 */
@isTest
private class SOPlanExtTest {

    @testSetup // 3 mins to run
    private static void setupfuel() {
        TestFuel dataInit = new TestFuel();
        // initialize necessary data to be queried by TestDataQuery
        system.assert(dataInit.salesOrder != null &&
                dataInit.product3 != null &&
                dataInit.location != null &&
                dataInit.location3 != null &&
                dataInit.pricebook != null &&
                dataInit.uomcList != null &&
                dataInit.uomList != null &&
                dataInit.itemList != null &&
                dataInit.reasonCodes != null &&
                dataInit.itemSpec != null &&
                dataInit.smrsList != null &&
                dataInit.stockMovementRuleList != null 
        );
    }

    static TestFuelQuery fuelQuery = new TestFuelQuery();

    static testMethod void testSOPlanExt() {
        //TestData globalTestData = new TestData();

        ApexPages.StandardController con;
        SOPlanExt planExt;
        
        Test.startTest();
        
        con = new ApexPages.StandardController(new Sales_Order__c());
        planExt = new SOPlanExt(con);            
        planExt.plan();
        System.assertEquals(true, planExt.hasErrors);

        fuelQuery.salesOrder.Status__c = 'Closed';
        update fuelQuery.salesOrder;
        
        con = new ApexPages.StandardController(fuelQuery.salesOrder);
        planExt = new SOPlanExt(con);
        planExt.plan();
        
        System.assertEquals(true, planExt.hasErrors);

        fuelQuery.salesOrder.Status__c = 'Open';
        update fuelQuery.salesOrder;
        
        // Backordered quantity will become zero.
        fuelQuery.salesOrderLine.Quantity_Shipped__c = fuelQuery.salesOrderLine.Quantity_Ordered__c;
        fuelQuery.salesOrderLine2.Quantity_Shipped__c = fuelQuery.salesOrderLine2.Quantity_Ordered__c;

        List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>{fuelQuery.salesOrderLine, fuelQuery.salesOrderLine2};
        update soLines;
        
        con = new ApexPages.StandardController(fuelQuery.salesOrder);
        planExt = new SOPlanExt(con);
        planExt.plan();
        
        System.assertEquals(true, planExt.hasErrors);
        
    }
        
    static testMethod void testPlan(){
        //TestData globalTestData = new TestData();
        ApexPages.StandardController con;
        SOPlanExt planExt;

        List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>{fuelQuery.salesOrderLine, fuelQuery.salesOrderLine2};

        for (Sales_Order_Line__c sol : soLines) {
            sol.Required_Date__c = system.today() - 2;
        }
        update soLines;
        
        con = new ApexPages.StandardController(fuelQuery.salesOrder);
        planExt = new SOPlanExt(con);
        planExt.plan();
        

        List<Shipment_Line__c> shlLines = [select Id from Shipment_Line__c where Sales_Order_Line__r.Sales_Order__c = :fuelQuery.salesOrder.Id ];
        system.assertEquals(0, shlLines.size(), 'Shipment Lines should not have been created.');
        
        SalesOrderAllocateExt soaExt = new SalesOrderAllocateExt(con);
        soaExt.undoRelease();

        List<SKID__c> demandSkids = [Select Id from SKID__c 
                                    where Type__c = :SKIDService.SKID_TYPE_SO_DEMAND 
                                    and Sales_Order_Line__c IN :soLines];
                                    
        System.assertEquals(0, demandSkids.size());

        fuelQuery.salesOrder.Required_Date__c = null;
        update fuelQuery.salesOrder;

        for (Sales_Order_Line__c sol : soLines) {
				sol.Required_Date__c = null;
        }
        update soLines;

        Test.startTest();
        ExceptionService.messages.clear();
        
        con = new ApexPages.StandardController(fuelQuery.salesOrder);
        planExt = new SOPlanExt(con);
        planExt.plan();
        
        System.assertEquals(false, planExt.hasErrors);
        
        
        
        Sales_Order__c salesOrder = [select Id, Status__c from Sales_Order__c where id = :fuelQuery.salesOrder.Id];
        System.assertEquals(false, planExt.hasErrors);
        
        System.assertEquals('Open', salesOrder.Status__c);
        
        demandSkids = [Select Id from SKID__c 
                        where Type__c = :SKIDService.SKID_TYPE_SO_DEMAND 
                          and Sales_Order_Line__c IN :soLines];
                            
        System.assertNotEquals(0, demandSkids.size());
        System.assertEquals(soLines.size(), demandSkids.size());
        soLines[0].Quantity_Ordered__c = 25;
        soLines[0].Quantity_Change_Reason__c = fuelQuery.reasonCodes.get('Change').Id;
        update soLines[0];
         
        con = new ApexPages.StandardController(fuelQuery.salesOrder);
        planExt = new SOPlanExt(con);
        planExt.initialize();
        planExt.plan();                                 

		/* KNDY-18993: temp comment till fixed in null orgs
        System.assertEquals(false, planExt.hasErrors, ExceptionService.messages); // OTC-18
                                    
        system.assertEquals(25, [Select Id, Quantity__c from SKID__c 
                                  where Type__c = :SKIDService.SKID_TYPE_SO_DEMAND 
                                    and Sales_Order_Line__c = :soLines[0].Id].Quantity__c,
                                    'Demand skid quantity must be equal to sales order line quantity ordered.');
        Test.stopTest();
        */
    }
    
	static testMethod void testLeadTimeException(){
        //TestData globalTestData = new TestData();
        ApexPages.StandardController con;
        SOPlanExt planExt;
        
        Test.startTest();
        List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>{fuelQuery.salesOrderLine, fuelQuery.salesOrderLine2};
		for (Sales_Order_Line__c sol : soLines) {
			sol.Required_Date__c = system.today() - 2;
		}
        update soLines;
		System.debug( logginglevel.error, '~*~ salesOrder Required_Date__c :' + fuelQuery.salesOrder.Required_Date__c );
        con = new ApexPages.StandardController(fuelQuery.salesOrder);
        planExt = new SOPlanExt(con);
        planExt.plan();

        List<Shipment_Line__c> shlLines = [select Id from Shipment_Line__c where Sales_Order_Line__r.Sales_Order__c = :fuelQuery.salesOrder.Id ];
        system.assertEquals(0, shlLines.size(), 'Shipment Lines should not have been created.');
        
        List<SKID__c> demandSkids = [Select Id from SKID__c 
                                    where Type__c = :SKIDService.SKID_TYPE_SO_DEMAND 
                                    and Sales_Order_Line__c IN :soLines];
                                    
        System.assertEquals(0, demandSkids.size());
        
        system.assert(ExceptionService.hasErrors, 'Expected lead time validation exception.');
        
        Task overrideTask = new Task();
		overrideTask.WhatId = fuelQuery.salesOrderLine.Id;
    	overrideTask.Exception_Code__c = ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP.code;
	    overrideTask.Status = 'Overridden';
	    overrideTask.Subject = ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP.label;
	    overrideTask.Type = ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP.typeName;
	    overrideTask.Primary_Key__c = '' + overrideTask.WhatId + overrideTask.Exception_Code__c;

		Task overrideTask2 = new Task();
		overrideTask2.WhatId = fuelQuery.salesOrderLine2.Id;
		overrideTask2.Exception_Code__c = ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP.code;
		overrideTask2.Status = 'Overridden';
		overrideTask2.Subject = ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP.label;
		overrideTask2.Type = ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP.typeName;
		overrideTask2.Primary_Key__c = '' + overrideTask2.WhatId + overrideTask2.Exception_Code__c;


	    upsert new List<Task>{overrideTask, overrideTask2} Primary_Key__c;
	    
	    ExceptionService.messages.clear();
		System.assertEquals(false, ExceptionService.hasErrors, ExceptionService.messages);

		ExceptionService.hasErrors = false;
		planExt.hasErrors = false;


	    planExt.plan();
        

        
        Sales_Order__c salesOrder = [select Id, Status__c from Sales_Order__c where id = :fuelQuery.salesOrder.Id];
        /* KNDY-18993: temp comment till fixed in null orgs
		System.assertEquals(false, planExt.hasErrors);
        
        System.assertEquals('Open', salesOrder.Status__c);
        
		System.assertEquals(false, planExt.hasErrors, ExceptionService.messages);


        demandSkids = [Select Id from SKID__c
                        where Type__c = :SKIDService.SKID_TYPE_SO_DEMAND 
                          and Sales_Order_Line__c IN :soLines];
                            
        System.assertNotEquals(0, demandSkids.size());
        System.assertEquals(soLines.size(), demandSkids.size());

        Test.stopTest();
        */

    }
    
    static testMethod void testShipmentLinesCreation(){

        ApexPages.StandardController con;
        SOPlanExt soPlanExt;
        
        Test.startTest();
        final decimal OZ_LB = .0625;

        System.debug(loggingLevel.Error, ' ***** fuelQuery.uomList :' + fuelQuery.uomList);
        fuelQuery.product.Weight_UOM__c = fuelQuery.uomList[3].Id; //oz
        System.debug(loggingLevel.Error, ' ***** fuelQuery.product :' + fuelQuery.product);
        System.debug(loggingLevel.Error, ' ***** fuelQuery.product.Units_per_Pallet__c :' + fuelQuery.product.Units_per_Pallet__c);
        fuelQuery.product.units_per_layer__c = 1;
        fuelQuery.product.layers_per_pallet__c = 1;

        fuelQuery.product2.units_per_layer__c = 1;
        fuelQuery.product2.layers_per_pallet__c = 1;
        List<Product__c> productsToUpdate = new List<Product__c>{fuelQuery.product, fuelQuery.product2};
        update productsToUpdate;

        fuelQuery.salesOrder.Weight_UOM__c = fuelQuery.uomList[0].Id;
        fuelQuery.salesOrder.Dimension_UOM__c = fuelQuery.uomList[6].Id;
        fuelQuery.salesOrder.Currency__c = fuelQuery.currencyUSD.Id;

        update fuelQuery.salesOrder;
        
        Sales_Order__c salesOrder = [SELECT Id, Weight_UOM__r.Name, Dimension_UOM__r.Name FROM Sales_Order__c WHERE Id = :fuelQuery.salesOrder.Id];
        System.debug(LoggingLevel.INFO, 'fuelQuery.product.: ' + fuelQuery.product.Weight__c);

        con = new ApexPages.StandardController(fuelQuery.salesOrder);
        soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();

        List<Sales_Order_Line__c> soLinesQ = new List<Sales_Order_Line__c>{fuelQuery.salesOrderLine, fuelQuery.salesOrderLine2};
        List<Sales_Order_Line__c> soLines = [SELECT Id, Weight__c, Quantity_Ordered__c, Weight_UOM__r.Name, Dimension_UOM__r.Name 
                                             FROM Sales_Order_Line__c WHERE Id IN :soLinesQ AND Product__c = :fuelQuery.product.Id];
        
        System.debug(LoggingLevel.INFO, 'soLines: ' + soLines);
        System.debug(LoggingLevel.INFO, 'global test sol weight: ' + soLines[0].Weight__c);
        System.assertEquals(fuelQuery.product.Weight__c * OZ_LB * soLines[0].Quantity_Ordered__c, soLines[0].Weight__c, 'Weight Conversion Failed.');

        for (Sales_Order_Line__c SOL : soLines){
            System.assertEquals(salesOrder.Weight_UOM__c, SOL.Weight_UOM__c);
            System.assertEquals(salesOrder.Weight_UOM__r.Name, SOL.Weight_UOM__r.Name);
            System.assertEquals(salesOrder.Dimension_UOM__c, SOL.Dimension_UOM__c);
            System.assertEquals(salesOrder.Dimension_UOM__r.Name, SOL.Dimension_UOM__r.Name);
        }

        List<Shipment_Line__c> shipmentLines = [select Id, Company__c, Description__c, Facility__c, Location__c, Quantity_Shipped__c, Sales_Order__c, Product__c, Number_of_Pallets_Planned__c,
                                                Sales_Order_Line__c, Sales_Order_Line__r.Description__c, Sales_Order_Line__r.Sales_Order__c, Sales_Order_Line__r.Quantity_Ordered__c,  
                                                Sales_Order_Line__r.Product__c, Sales_Order_Line__r.Ship_From_Location__c, Sales_Order_Line__r.Quantity_BackOrdered__c,
                                                Shipment__r.Company__c, Shipment__r.Customer__c, Shipment__r.Status__c, Shipment__r.Currency__c, Planned_Weight__c, Sales_Order_Line__r.Weight__c,
                                                Shipment__r.Number_of_Pallets_Planned__c, Shipment__r.Total_Product_Weight__c, Shipment__r.Total_Pallet_Weight_Planned__c, Shipment__r.Total_Weight_Planned__c
                                                from Shipment_Line__c 
                                                where Sales_Order_Line__c IN :soLinesQ];

        System.debug(loggingLevel.Error, ' ***** shipmentLines :' + shipmentLines);
        System.debug(loggingLevel.Error, ' ***** shipmentLines.size() :' + shipmentLines.size());
        System.assertNotEquals(0, shipmentLines.size());
        
        Set<Id> salesOrderLineIds = new Set<Id>();
        System.debug(loggingLevel.Error, ' ***** shipmentLines[0].Shipment__r :' + shipmentLines[0].Shipment__r);
        system.assertEquals(115, shipmentLines[0].Shipment__r.Number_of_Pallets_Planned__c);
        system.assertEquals(156.25, shipmentLines[0].Shipment__r.Total_Product_Weight__c);
        system.assertEquals(156.25, shipmentLines[0].Shipment__r.Total_Weight_Planned__c); 

        for(Shipment_Line__c shl : shipmentLines){
            salesOrderLineIds.add(shl.Sales_Order_Line__c);
            
            System.assertEquals(shl.Sales_Order_Line__r.Weight__c, shl.Planned_Weight__c);
            System.assertEquals(fuelQuery.salesOrder.Company__c, shl.Shipment__r.Company__c);

            System.assertEquals(fuelQuery.salesOrder.Company__c, shl.Shipment__r.Company__c);
            System.assertEquals(fuelQuery.salesOrder.Ship_To__c, shl.Shipment__r.Customer__c);
            System.assertEquals(fuelQuery.salesOrder.Currency__c, shl.Shipment__r.Currency__c);
            System.assertEquals('Planned', shl.Shipment__r.Status__c);
        
            System.assertNotEquals(null, shl.Sales_Order_Line__c);
            System.assertEquals(shl.Sales_Order_Line__r.Description__c, shl.Description__c);
            System.assertEquals(fuelQuery.salesOrder.Id, shl.Sales_Order__c);
            System.assertEquals(shl.Sales_Order_Line__r.Product__c, shl.Product__c);
            System.assertEquals(shl.Sales_Order_Line__r.Ship_From_Location__c, shl.Location__c);
            System.assertEquals(0, shl.Quantity_Shipped__c);
            
        }
        
        System.assertEquals(soLinesQ.size(), salesOrderLineIds.size());
        
        List<SKID__c> soDemandSkids = [select Id, Shipment_Line__c, Sales_Order_Line__c from SKID__c 
                                            where Sales_Order_Line__r.Sales_Order__c = :fuelQuery.salesOrder.Id
                                            and Type__c = :SKIDService.SKID_TYPE_SO_DEMAND];
        System.assertNotEquals(0, soDemandSkids.size());                                    
        for(SKID__c demandSkid : soDemandSkids){
            System.assertNotEquals(null, demandSkid.Shipment_Line__c);
        }    
    }
    static testMethod void testOverrideHoldDropShip() {

        Test.startTest();

        //TestFuel fuel = new TestFuel();
        Product__c product = fuelQuery.product;
        Product__c product2 = fuelQuery.product2;
        // KNDY-10903 Change the product`s item to item that has a uom
        //product.Item__c = fuelQuery.itemList[2].Id;
        //product2.Item__c = fuelQuery.itemList[3].Id;
        List<Product__c> products = new List<Product__c> { product, product2};
        update products;

        ApexPages.StandardController con;
        SOPlanExt planExt;
        
        Customer__c top = fuelQuery.customerParent;
        top.Risk_Class__c = 'R';
        top.Credit_Limit__c = 1;        
        update top;
        
        Credit_Profile_Rules__c cp = new Credit_Profile_Rules__c(); 
        cp.name='R'; cp.Percent_Over_Credit__c = 0;
        insert cp;
                

        Sales_Order__c salesOrder = fuelQuery.salesOrder;

        List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>{ fuelQuery.salesOrderLine, fuelQuery.salesOrderLine2};

        soLines[0].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP;
        soLines[1].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP;
        // KNDY-10903 Change the uom on sales order line to match that of product
        soLines[0].Selling_UOM__c = fuelQuery.uomList[8].ID;
        soLines[1].Selling_UOM__c = fuelQuery.uomList[8].ID;
        update soLines;

        Test.stopTest();

        con = new ApexPages.StandardController(fuelQuery.salesOrder);
        planExt = new SOPlanExt(con);            
        planExt.plan();

        // System.assertEquals(true, planExt.hasErrors, 'Expected errors to be shown.');
        ExceptionService.messages.clear();


        fuelQuery.salesOrder.Override_Credit_Hold__c = true;
        update fuelQuery.salesOrder;

        con = new ApexPages.StandardController(fuelQuery.salesOrder);
        planExt = new SOPlanExt(con);            
        planExt.plan();

        System.assertEquals(false, planExt.hasErrors, 'No expected errors to be shown.');
    }

    static testMethod void testOverrideHold() {
        //TestFuel fuel = new TestFuel();
                
        List<SKID__c> skids = fuelQuery.skids;

        ApexPages.StandardController con;
        SOPlanExt planExt;
        
        Customer__c top = fuelQuery.customerParent;
        top.Risk_Class__c = 'R';
        top.Credit_Limit__c = 1;        
        update top;
        
        Sales_Order__c salesOrder = fuelQuery.salesOrder;

        List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>{ fuelQuery.salesOrderLine, fuelQuery.salesOrderLine2};
        soLines[0].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY;
        soLines[1].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY;
        update soLines;

        Credit_Profile_Rules__c cp = new Credit_Profile_Rules__c(); 
        cp.name='R'; 
        cp.Percent_Over_Credit__c = 0;
        insert cp;
                
        Test.startTest();

        con = new ApexPages.StandardController(fuelQuery.salesOrder);
        planExt = new SOPlanExt(con);            
        planExt.plan();
        System.assertEquals(true, planExt.hasErrors, 'Lead Time Exception expected.');
          
    }

    static testMethod void testSalesOrderPlanBatch(){
        //TestFuel fuel = new TestFuel();
        
        Sales_Order__c salesOrder = fuelQuery.salesOrder;
        salesOrder.Ready__c = true;
        update salesOrder;
        
        Test.startTest();
        
        SalesOrderPlanBatch batchInstance = new SalesOrderPlanBatch();
        batchInstance.runBatch(new Process_Job__c( Company__c = fuelQuery.company.Id) );
        
        Test.stopTest();
        
        salesOrder = [select Id, Has_Exceptions__c from Sales_Order__c where Id = :salesOrder.Id limit 1];
        system.assertEquals(false, salesOrder.Has_Exceptions__c);
        
        List<Shipment_Line__c> shipmentLines = [select Id, Sales_Order_Line__c 
        										  from Shipment_Line__c 
        										 where Sales_Order_Line__r.Sales_Order__c = :salesOrder.Id];
        										      
        system.assertEquals(2, shipmentLines.size());										  
	    
    }
    
    static testMethod void testMixedOrders(){
        
        // Test drop ship and inventory line planned in the same order
        //TestFuel fuel = new TestFuel();
        
        Product__c product = fuelQuery.product;
        Product__c product2 = fuelQuery.product2;
        // KNDY-10903 Change the product`s item to item that has a uom
        //product.Item__c = fuelQuery.itemList[2].Id;
        //product2.Item__c = fuelQuery.itemList[3].Id;
        List<Product__c> products = new List<Product__c> { product, product2};
        update products;

        Sales_Order__c salesOrder = fuelQuery.salesOrder;
        List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>{ fuelQuery.salesOrderLine, fuelQuery.salesOrderLine2};
        soLines[0].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP;
        soLines[1].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY;
        // KNDY-10903 Change the uom on sales order line to match that of product
        soLines[0].Selling_UOM__c = fuelQuery.uomList[8].ID;
        soLines[1].Selling_UOM__c = fuelQuery.uomList[8].ID;
        update soLines;

        ApexPages.StandardController con = new ApexPages.StandardController(fuelQuery.salesOrder);
        SOPlanExt planExt = new SOPlanExt(con);
        planExt.plan();

        salesOrder = [SELECT Id, Has_Exceptions__c FROM Sales_Order__c WHERE Id = :salesOrder.Id LIMIT 1];
        System.assertEquals(false, salesOrder.Has_Exceptions__c);

        //fuel.salesOrderLines[0].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY;
        //update fuel.salesOrderLines[0];

        //con = new ApexPages.StandardController(fuel.salesOrder);
        //planExt = new SOPlanExt(con);
        //planExt.plan();
        List<Sales_Order_Line__c> salesOrderLines = [SELECT Id, Product__r.Item__c, Ship_From_Location__r.Facility__c,
                                                            Quantity_Ordered__c, Purchase_From_Supplier__c, Ship_From_Location__c,
                                                            Selling_UOM__c, Status__c, Sales_Order__r.Status__c, Company__c,
                                                            (SELECT Id FROM Requisition_Lines__r),
                                                            (SELECT Id, Shipment__r.Id FROM Shipment_Lines__r)
                                                       FROM Sales_Order_Line__c];
        salesOrder = [SELECT Id, Has_Exceptions__c FROM Sales_Order__c WHERE Id = :salesOrder.Id LIMIT 1];
        System.assertEquals(false, salesOrder.Has_Exceptions__c);

        System.assertEquals(false, planExt.hasErrors, 'Unexpected errors: ' + ApexPages.getMessages());
        for (Sales_Order_Line__c SOL : salesOrderLines){
            if (SOL.Id == soLines[0].Id){
                System.assertEquals(1, SOL.Requisition_Lines__r.size());
            }
            if (SOL.Id == soLines[1].Id){
                System.assertEquals(1, SOL.Shipment_Lines__r.size());
            }
        }


    }

    static testMethod void testCreateRequisitions(){

        Test.startTest();
        //TestFuel fuel = new TestFuel();
        //String reqKey = (String) SOL.Sales_Order__c + SOL.Ship_From_Location__r.Facility__c + SOL.Sales_Order__r.Ship_To__c;
        
        Product__c product = fuelQuery.product;
        Product__c product2 = fuelQuery.product2;
        // KNDY-10903 Change the product`s item to item that has a uom
        //product.Item__c = fuelQuery.itemList[2].Id;
        //product2.Item__c = fuelQuery.itemList[3].Id;
        List<Product__c> products = new List<Product__c> { product, product2};
        update products;
        Sales_Order__c salesOrder = fuelQuery.salesOrder;
        List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>{ fuelQuery.salesOrderLine, fuelQuery.salesOrderLine2};
        // test mix order
        soLines[0].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP;
        soLines[1].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP;
        // KNDY-10903 Change the uom on sales order line to match that of product
        soLines[0].Selling_UOM__c = fuelQuery.uomList[8].ID;
        soLines[1].Selling_UOM__c = fuelQuery.uomList[8].ID;
        update new List<Sales_Order_Line__c>{soLines[0], soLines[1]};


                        //exService.setException(salesOrder, ExceptionUtil.SO_ALL_LINES_SAME_FULFILLMENT_SOURCE);
        //update new List<Sales_Order_Line__c>{ fuel.salesOrderLines[0], fuel.salesOrderLines[1]};

        //fuel.salesOrderLines[0].Need_Date__c = System.today();
        ApexPages.StandardController con = new ApexPages.StandardController(fuelQuery.salesOrder);
        SOPlanExt planExt = new SOPlanExt(con);
        planExt.plan();

        salesOrder = [SELECT Id, Has_Exceptions__c FROM Sales_Order__c WHERE Id = :salesOrder.Id LIMIT 1];
        system.assertEquals(false, salesOrder.Has_Exceptions__c);

        List<Sales_Order_Line__c> salesOrderLines = [SELECT Id, Product__r.Item__c, Ship_From_Location__r.Facility__c,
                                                            Quantity_Ordered__c, Quantity_Planned__c, Purchase_From_Supplier__c, Ship_From_Location__c,
                                                            Selling_UOM__c, Status__c, Sales_Order__r.Status__c, Company__c,
                                                        (SELECT Id, Approved__c, Item__c, Facility__c, Quantity_Ordered__c,
                                                                Supplier__c, Sales_Order_Line__c, Status__c, Delivery_Location__c,
                                                                Purchasing_UOM__c,
                                                                Requisition__r.Id, Requisition__r.Company__c, Requisition__r.Ship_To_Customer__c,
                                                                Requisition__r.Sales_Order__c, Requisition__r.Transaction_Date__c, Requisition__r.Delivery_Facility__c,
                                                                Requisition__r.Source__c, Requisition__r.Status__c, Requisition__r.Type__c
                                                          FROM Requisition_Lines__r)
                                                       FROM Sales_Order_Line__c];

        System.assertEquals(2, salesOrderLines.size());

        for(Sales_Order_Line__c SOL: salesOrderLines) {
            for(Requisition_Line__c RQL: SOL.Requisition_Lines__r) {
                System.assertEquals(true, RQL.Approved__c);
                System.assertEquals(SOL.Product__r.Item__c, RQL.Item__c);
                System.assertEquals(SOL.Quantity_Ordered__c, RQL.Quantity_Ordered__c);
                System.assertEquals(SOL.Purchase_From_Supplier__c, RQL.Supplier__c);
                System.assertEquals(SOL.Id, RQL.Sales_Order_Line__c);
                System.assertEquals(SOL.Ship_From_Location__c, RQL.Delivery_Location__c);
                System.assertEquals(SOL.Selling_UOM__c, RQL.Purchasing_UOM__c);
                System.assertEquals(SOL.Quantity_Planned__c, SOL.Quantity_Ordered__c);

                System.assertEquals(SOL.Company__c, RQL.Requisition__r.Company__c);
                System.assertEquals(SOL.Ship_From_Location__r.Facility__c, RQL.Requisition__r.Delivery_Facility__c);
                System.assertEquals(SOL.Sales_Order__c, RQL.Requisition__r.Sales_Order__c);
                System.assertEquals(RequisitionService.RQ_SOURCE_DROPSHIP, RQL.Requisition__r.Source__c);
                System.assertEquals(RequisitionService.RQ_STATUS_OPEN, RQL.Requisition__r.Status__c);
                System.assertEquals(System.today(), RQL.Requisition__r.Transaction_Date__c);
                System.assertEquals(RequisitionService.RQ_TYPE_PURCHASE_REQUISITION, RQL.Requisition__r.Type__c);

                System.assertEquals(SOL.Status__c, 'Open');            
                System.assertEquals(SOL.Sales_Order__r.Status__c, 'Open');            
            }
        }  

        List<Requisition__c> requisitionList = [SELECT Id, Approval_Status__c, Company__c, Delivery_Facility__c, Requester__c, Sales_Order__c,
                                                       Ship_To_Customer__c, Source__c, Status__c, Transaction_Date__c, Type__c
                                                  FROM Requisition__c];

        System.assertEquals(1, requisitionList.size());
        Requisition__c RQ = requisitionList[0];
        System.assertEquals(RequisitionService.RQ_APPROVAL_STATUS_APPROVED, RQ.Approval_Status__c);
        //updating the quantity ordered on SOL also updates the Quantity Ordered on Requisition line on SO Rerelease 
        salesOrderLines[0].Quantity_Ordered__c = 105;
        salesOrderLines[0].Quantity_Change_Reason__c = fuelQuery.reasonCodes.get('Change').Id;
        salesOrderLines[1].Quantity_Ordered__c = 20;
        salesOrderLines[1].Quantity_Change_Reason__c = fuelQuery.reasonCodes.get('Change').Id;
        update new List<Sales_Order_Line__c>{salesOrderLines[0], salesOrderLines[1]};
        ApexPages.StandardController con1 = new ApexPages.StandardController(salesOrderLines[0].Sales_Order__r);
        SOPlanExt planExt1 = new SOPlanExt(con1);
        planExt1.plan();
        List<Sales_Order_Line__c> updatedsalesOrderLines = [SELECT Id, Product__r.Item__c, Ship_From_Location__r.Facility__c,
                                                            Quantity_Ordered__c, Purchase_From_Supplier__c, Ship_From_Location__c,
                                                            Selling_UOM__c, Status__c, Sales_Order__r.Status__c, Company__c,
                                                        (SELECT Id, Approved__c, Item__c, Facility__c, Quantity_Ordered__c,
                                                                Supplier__c, Sales_Order_Line__c, Status__c, Delivery_Location__c,
                                                                Purchasing_UOM__c,
                                                                Requisition__r.Id, Requisition__r.Company__c, Requisition__r.Ship_To_Customer__c,
                                                                Requisition__r.Sales_Order__c, Requisition__r.Transaction_Date__c, Requisition__r.Delivery_Facility__c,
                                                                Requisition__r.Source__c, Requisition__r.Status__c, Requisition__r.Type__c
                                                          FROM Requisition_Lines__r)
                                                       FROM Sales_Order_Line__c];
           List<Requisition_Line__c> requisitionLineList = [SELECT Id, Status__c, Quantity_Ordered__c, Sales_Order_Line__c, Sales_Order_Line__r.Quantity_Ordered__c FROM Requisition_Line__c];
      
       system.assertEquals(requisitionLineList[0].Quantity_Ordered__c, 105);
        Test.stopTest();


    }
    
    
//    public class RepairTestData {
//        TestFuel tf = new TestFuel();
//
    public static Sales_Order__c repairSO {
        get {
            if (repairSO == null) {
                repairSO = new Sales_Order__c(
                    Type__c = SalesOrderService.SO_TYPE_REPAIR,
                    Status__c = SalesOrderService.SO_STATUS_DRAFT,
                    Company__c = fuelQuery.company.Id,
                    Customer__c = fuelQuery.customerSoldTo.Id,
                    Bill_To__c = fuelQuery.customerBillTo.Id,
                    Ship_To__c = fuelQuery.customerShipTo.Id,
                    Payment_Term__c = fuelQuery.terms.Id,
                    Ship_From_Location__c = fuelQuery.location2.Id,
                    Required_Date__c = Date.today() + 30,
                    Currency__c=fuelQuery.currencyUSD.id
                );
                insert repairSO;
            }
            return repairSO;
        } set;
    }

    public static Sales_Order_Line__c repairSOL {
        get {
            if (repairSOL == null) {
                repairSOL = new Sales_Order_Line__c(
                    Company__c = fuelQuery.company.Id,
                    Status__c = 'Draft',
                    Required_Date__c = Date.today() + 30,
                    Sales_Order__c = repairSO.Id,
                    Line__c = 1,
                    Product__c = fuelQuery.product2.Id,
                    Fulfillment_Source__c = 'Inventory',
                    Quantity_Ordered__c = 1,
                    Quantity_Backordered__c = 1,
                    Ship_From_Location__c = fuelQuery.location2.Id,
                    Unit_Price__c = 0,
                    Type__c = 'Repair'
                );
            }
            return repairSOL;
        } set;
    }
        
    public static void RepairTestData(Boolean reship,Boolean itemSpec) {
        DML.systemTime = system.now().addHours(-2);
        List<sObjectType> skipTriggers = new List<sObjectType>{ Sales_Order__c.sObjectType, Sales_Order_Line__c.sObjectType };
        List<Configuration__c> configList = new List<Configuration__c>();
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserId()));
        }
        insert configList;
        Pricebook__c pb = fuelQuery.pricebook;
        Sales_Order_Line__c sol = repairSOL;
        sol.Pricebook__c = pb.id;
        if (reship)
            sol.Non_Shippable__c = false;
        else
            sol.Non_Shippable__c = true;
        if (itemSpec) {
            update new Item_Specification__c(Id = fuelQuery.itemSpec.Id, Type__c = 'Repair');
            sol.Item_Specification__c = fuelQuery.itemSpec.Id;
        }
        insert sol;

        delete configList;


        SalesOrderService.plan(new Map<Id,Id>{repairSO.Id => null});
    }


    private static testMethod void testReshipRepairItemSpec() {

        
        Test.startTest();

        RepairTestData(true,true);
        Test.stopTest();
        
        List<Work_Order__c> woList = [SELECT Id,Assembly_Item_Specification__c,Item__c,Shipment_Line__c FROM Work_Order__c WHERE Type__c = 'Repair'];
        
        System.assert(woList.size() == 1,ExceptionService.messages);
        System.assert(woList[0].Shipment_Line__c != null,ExceptionService.messages);
        System.assert(woList[0].Assembly_Item_Specification__c != null,ExceptionService.messages);
        System.assert(woList[0].Item__c != null,ExceptionService.messages);
    }
    private static testMethod void testReshipRepairNoItemSpec() {
        
        Test.startTest();
        RepairTestData(true,false);
        Test.stopTest();
        
        List<Work_Order__c> woList = [SELECT Id,Assembly_Item_Specification__c,Item__c,Shipment_Line__c FROM Work_Order__c WHERE Type__c = 'Repair'];
        
        System.assert(woList.size() == 1,ExceptionService.messages);
        System.assert(woList[0].Shipment_Line__c != null,ExceptionService.messages);
        System.assert(woList[0].Assembly_Item_Specification__c == null,ExceptionService.messages);
        System.assert(woList[0].Item__c != null,ExceptionService.messages);
    }
    private static testMethod void testFieldRepairItemSpec() {

        
        Test.startTest();

        RepairTestData(false,true);
        Test.stopTest();
        
        List<Work_Order__c> woList = [SELECT Id,Assembly_Item_Specification__c,Item__c,Shipment_Line__c FROM Work_Order__c WHERE Type__c = 'Repair'];
        
        System.assert(woList.size() == 1,ExceptionService.messages);
        //System.assert(woList[0].Shipment_Line__c == null,ExceptionService.messages);
        System.assert(woList[0].Assembly_Item_Specification__c != null,ExceptionService.messages);
        System.assert(woList[0].Item__c != null,ExceptionService.messages);
    }
    private static testMethod void testFieldRepairNoItemSpec() {
        
        Test.startTest();
        RepairTestData(false,false);
        Test.stopTest();
        
        List<Work_Order__c> woList = [SELECT Id,Assembly_Item_Specification__c,Item__c,Shipment_Line__c FROM Work_Order__c WHERE Type__c = 'Repair'];
        
        System.assert(woList.size() == 1,ExceptionService.messages);
        //System.assert(woList[0].Shipment_Line__c == null,ExceptionService.messages);
        System.assert(woList[0].Assembly_Item_Specification__c == null,ExceptionService.messages);
        System.assert(woList[0].Item__c != null,ExceptionService.messages);
    }
    
    static testMethod void testSOAutomation(){
       
        fuelQuery.setupInventory(false, false);
        
        Sales_Order__c salesOrder = fuelQuery.salesOrder;
        salesOrder.Ready__c = true;
        update salesOrder;
        
        ApexPages.StandardController con = new ApexPages.StandardController(salesOrder);
        SalesOrderAutomationExt autoExt = new SalesOrderAutomationExt(con);
        
        Test.startTest();
        autoExt.processSO();
        Test.stopTest();

        List<Shipment_Line__c> shlLines = [select Id, Quantity_Allocated__c from Shipment_Line__c where Sales_Order_Line__r.Sales_Order__c = :fuelQuery.salesOrder.Id ];
        system.assertEquals(2, shlLines.size(), ApexPages.getMessages()); //Released successfully
        system.assert(shlLines[0].Quantity_Allocated__c > 0); //allocated successfully
        
    }
}
