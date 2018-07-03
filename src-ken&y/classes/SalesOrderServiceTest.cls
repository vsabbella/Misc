/**
 * This class contains unit tests for validating the behavior of methods in SalesOrderService.cls.
 *
 */
@isTest
private class SalesOrderServiceTest {
   
     /*
      JIRA 2635
      Creates SO Lines which match and don't match based on PB Lines using Product groups. 
      */
    public static testMethod void test_PricebookMatchNExceptionsForGroups() {
        TestFuel data = new TestFuel();  
        system.assert (data.company!=null );
        
        data.pricebook = new Pricebook__c(); 
        data.pricebook.name = data.company.Name +  ' Orange Pricebook';
        data.pricebook.company__c = data.company.id; 
        data.pricebook.Primary_Key__c = 'NATBOOK';
        insert data.pricebook; 

        system.assert(data.product != null && data.terms != null && data.customerSoldTo != null  && data.product2 != null);
        Test.startTest();
        // flush the caching to avoid conflicts
        SalesOrderFlowCache.flush();
        
        // Create a few Product Group and 
        Product_Group__c pGroup1 = new Product_Group__c(Name = 'Prod Grp 1', Company__c= data.company.Id);
        Product_Group__c pGroup2 = new Product_Group__c(Name = 'Prod Grp 2', Company__c= data.company.Id);
        
        insert new Product_Group__c[]{pGroup1, pGroup2};
        
        // Associate Product with Product group
		data.product.Product_Group__c = pGroup1.Id;
        data.product2.Product_Group__c = pGroup2.Id;
        update new Product__c[] {data.product, data.product2};
            
        // Create a Pricebook line for Product Group 1
        Pricebook_Line__c pbLineGrp1 = new Pricebook_Line__c( pricebook__c = data.pricebook.id, Product_Group__c = pGroup1.id, Price__c = 5.000000, 
                                                                 Start_date__c = Date.today(), End_Date__c = Date.today()+10);                
        insert pbLineGrp1;
        
        
        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = data.company.id;
        salesOrder.Customer__c = data.customerSoldTo.id;    // must be a sold to
        salesOrder.Ship_To__c = data.customerShipTo.Id;
        salesOrder.Payment_Term__c = data.terms.id;
        
        insert salesOrder;
        
        // SO Line to match with Product Group1 
        Sales_Order_Line__c soLineGrp1 = new Sales_Order_Line__c();
        soLineGrp1.Product__c = data.product.Id;
        soLineGrp1.Description__c = data.product.Description__c;
        soLineGrp1.Company__c = data.company.id;
        soLineGrp1.Sales_Order__c = salesOrder.Id;
        soLineGrp1.Pricebook__c = data.pricebook.id;
        soLineGrp1.Quantity_Ordered__c = 100;
        soLineGrp1.Required_Date__c = System.today() + 5;
        
        //second SO Line for Product 2 matches no Pricebook line.
        Sales_Order_Line__c soLineGrp2 = new Sales_Order_Line__c();
        soLineGrp2.Product__c = data.product2.Id;
        soLineGrp2.Description__c = data.product.Description__c;
        soLineGrp2.Company__c = data.company.id;
        soLineGrp2.Sales_Order__c = salesOrder.Id;
        soLineGrp2.Pricebook__c = data.pricebook.id;
        soLineGrp2.Quantity_Ordered__c = 10;
        soLineGrp2.Required_Date__c = System.today() + 5;
        
        insert new Sales_Order_Line__c[]{soLineGrp1, soLineGrp2};
            
            // Re load SO Lines, to see changes to fields by triggers 
            Map<Id, Sales_Order_Line__c> soLinesReloaded = new Map<Id, Sales_Order_Line__c>(
                [Select Id, Unit_Price__c, Has_Exceptions__c 
                 from Sales_Order_Line__c Where Id =:soLineGrp1.Id or Id =:soLineGrp2.Id]
            );
        
        soLineGrp1 = soLinesReloaded.get(soLineGrp1.Id);
        soLineGrp2 = soLinesReloaded.get(soLineGrp2.Id);
        
        System.assert(ExceptionService.hasOpenTask(soLineGrp1.Id, ExceptionUtil.PRODUCT_PRICE_MISMATCH_UNIT_PRICE.code) == false, 'SalesOrder Line price should match the price in Pricebook Line for Product Group');
        System.assert(soLineGrp1.Has_Exceptions__c == false, 'SalesOrder Line price should match the price in Pricebook Line for Product Group');
        
        System.assertEquals(null , soLineGrp2.Unit_Price__c, 'SalesOrder Line price should not match the price of any Pricebook Line. No matching line is created for the Product or Product group ');
        System.assert(soLineGrp2.Has_Exceptions__c, 'SalesOrder Line price should not match the price of any Pricebook Line. No matching line is created for the Product or Product group ');
        System.assert(ExceptionService.hasOpenTask(soLineGrp2.Id, ExceptionUtil.PRICEBOOK_LINE_NOT_FOUND.code), 'SalesOrder Line price should not match the price of any Pricebook Line. No matching line is created for the Product or Product group ');
        
        Test.stopTest();
    }
    
    static testMethod void testPlan() {
        TestData data = new TestData();
        Test.startTest();
        
        data.salesOrder.Weight_UOM__c = data.uomList[0].ID;
        data.salesOrder.Required_Date__c = system.today() + 7;
        DML.updateAsUser(data.salesOrder);
        
        //OTC-427
        system.assert(data.uomlist[2].Name == 'DZ');
        for(Sales_Order_Line__c sol : data.SalesOrderLines){
        	sol.Selling_UOM__c = data.uomlist[2].Id;
            sol.Line_Type__c = 'Standard';
        }
        update data.SalesOrderLines;
        
        SalesOrderService sos = new SalesOrderService();
        
        // Check that errors are created if no sales order lines are found.
        try{
            sos.plan((Id)null);
            System.assert(ExceptionService.hasErrors, 'Expected errors to be displayed.');
        }catch(Exception e){
            System.assert(false, 'Unexpected exception thrown.' + e.getMessage());	
        }
        
        ExceptionService.messages.clear();
        
        // Check that planning is completed and shipment lines and so demand skid are created.        
        try{
            sos.plan(data.salesOrder.Id);
            System.assert(ExceptionService.hasErrors == false, 'Unexpected errors: ' + ExceptionService.messages);
        }catch(Exception e){
            System.assert(false, 'Unexpected exception thrown.' + e.getMessage());	
        }
        
        List<Shipment_Line__c> shipmentLines = [select Id, Company__c, Description__c, Facility__c, Location__c, Extended_Cost__c, Quantity_Shipped__c, Sales_Order__c, Product__c,
                                                Sales_Order_Line__c, Sales_Order_Line__r.Description__c, Sales_Order_Line__r.Sales_Order__c, Sales_Order_Line__r.Quantity_Ordered__c,  
                                                Sales_Order_Line__r.Product__c, Sales_Order_Line__r.Ship_From_Location__c, Sales_Order_Line__r.Quantity_BackOrdered__c,
                                                Shipment__r.Company__c, Shipment__r.Customer__c, Shipment__r.Planned_Delivery_Date__c,
                                                Shipment__r.Weight_UOM__c, Sales_Order__r.Weight_UOM__c, Sales_Order_Line__r.Required_Date__c, Need_date__c,
                                                Shipment__r.Status__c, Shipment__r.Currency__c, Sales_Order_Line__r.Line_Type__c, Line_Type__c 
                                                from Shipment_Line__c 
                                                where Sales_Order_Line__c IN :data.salesOrderLines];
        System.assertNotEquals(0, shipmentLines.size());
        
        Set<Id> salesOrderLineIds = new Set<Id>();
        Map<Id, Shipment__c> shipmentMap = new Map<Id, Shipment__c>();
		Date expectedNeedDate;
        for(Shipment_Line__c shl : shipmentLines){
            salesOrderLineIds.add(shl.Sales_Order_Line__c);
			shipmentMap.put(shl.Shipment__c, shl.Shipment__r);
            
            System.assertEquals(data.salesOrder.Company__c, shl.Shipment__r.Company__c);
            System.assertEquals(data.salesOrder.Ship_To__c, shl.Shipment__r.Customer__c);
            System.assertEquals(data.salesOrder.Currency__c, shl.Shipment__r.Currency__c);
            System.assertEquals('Planned', shl.Shipment__r.Status__c);
            
            System.assertNotEquals(null, shl.Sales_Order_Line__c);
            System.assertEquals(shl.Sales_Order_Line__r.Description__c, shl.Description__c);
            System.assertEquals(data.salesOrder.Id, shl.Sales_Order__c);
            System.assertEquals(shl.Sales_Order_Line__r.Product__c, shl.Product__c);
            System.assertEquals(shl.Sales_Order_Line__r.Ship_From_Location__c, shl.Location__c);
            System.assertEquals(0, shl.Quantity_Shipped__c);
            System.assert(shl.Sales_Order__r.Weight_UOM__c != null);
            System.assertEquals(shl.Sales_Order__r.Weight_UOM__c,shl.Shipment__r.Weight_UOM__c);
            System.assertEquals(0, shl.Extended_Cost__c);

			expectedNeedDate = expectedNeedDate == null || expectedNeedDate < shl.Need_Date__c ? shl.Need_Date__c : expectedNeedDate;
			System.assertEquals(shl.Sales_Order_Line__r.Required_Date__c, shl.Need_Date__c, shl);
            System.assertEquals(shl.Line_Type__c, shl.Sales_Order_Line__r.Line_Type__c);
        }
        system.assertEquals(1, shipmentMap.keySet().size());
		system.assertEquals(expectedNeedDate, shipmentMap.values()[0].Planned_Delivery_Date__c);
        System.assertEquals(data.salesOrderLines.size(), salesOrderLineIds.size());
        
        List<SKID__c> soDemandSkids = [select Id, Quantity__c, Shipment_Line__c, Sales_Order_Line__r.Quantity_Ordered__c 
        								 from SKID__c 
                                        where Sales_Order_Line__r.Sales_Order__c = :data.salesOrder.Id
                                          and Type__c = :SKIDService.SKID_TYPE_SO_DEMAND];
        
        System.assertNotEquals(0, soDemandSkids.size());
        
        for(SKID__c demandSkid : soDemandSkids){
            System.assertNotEquals(null, demandSkid.Shipment_Line__c);
            System.assertEquals(demandSkid.Sales_Order_Line__r.Quantity_Ordered__c * 12, demandSkid.Quantity__c);
        }	
        
        List<SKID__c> stockSkids = fillStock(data);
        
        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(data.salesOrder);
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        SOAExt.allocate();
        
        // Test that the sales order cannot be planned again after its been planned.
        ExceptionService.messages.clear();

        SOPlanExt soPlan = new SOPlanExt(con);
        soPlan.initialize();
        
        System.assertEquals(true, soPlan.hasErrors, ExceptionService.messages);
        
        sos.undoPlan(new Set<Id>{data.salesOrder.Id});
        
        Test.stopTest();
    }
    
    static testMethod void testPlanAllOrNothing() {
        TestData data = new TestData();
        Test.startTest();
        
        data.salesOrder.Required_Date__c = system.today() + 7;
        DML.updateAsUser(data.salesOrder);
        
        
        data.product.Pricebook_Line_Required__c = true;
        update data.product;

        //data.SalesOrderLines[0].Unit_Price__c = 1;
        data.SalesOrderLines[0].Ship_From_Location__c = null;
        update data.SalesOrderLines[0];
        
        data.company.Do_Not_Release_Partial_Sales_Orders__c = true;
        update data.company;
        
        SalesOrderService sos = new SalesOrderService();
        
        try{
            sos.plan(data.salesOrder.Id);
            System.assert(ExceptionService.hasErrors == true, 'Expected errors to be shown.');
        }catch(Exception e){
            System.assert(false, 'Unexpected exception thrown.' + e.getMessage());	
        }
        
        List<Shipment_Line__c> shipmentLines = [select Id, Company__c, Description__c, Facility__c, Location__c, Extended_Cost__c, Quantity_Shipped__c, Sales_Order__c, Product__c,
                                                Sales_Order_Line__c, Sales_Order_Line__r.Description__c, Sales_Order_Line__r.Sales_Order__c, Sales_Order_Line__r.Quantity_Ordered__c,  
                                                Sales_Order_Line__r.Product__c, Sales_Order_Line__r.Ship_From_Location__c, Sales_Order_Line__r.Quantity_BackOrdered__c,
                                                Shipment__r.Company__c, Shipment__r.Customer__c, Shipment__r.Planned_Delivery_Date__c,
                                                Shipment__r.Status__c, Shipment__r.Currency__c 
                                                from Shipment_Line__c 
                                                where Sales_Order_Line__c IN :data.salesOrderLines];
        System.assertEquals(0, shipmentLines.size());
        
        //data.SalesOrderLines[0].Unit_Price__c = null;
        data.SalesOrderLines[0].Pricebook__c = data.pricebook.Id;
        data.SalesOrderLines[0].Ship_From_Location__c = data.location10.ID;
        update data.SalesOrderLines[0];
        
        ExceptionService.messages.clear();
        
        try{
            sos.plan(data.salesOrder.Id);
            System.assert(ExceptionService.hasErrors == false, 'Unexpected errors: ' + ExceptionService.messages);
        }catch(Exception e){
            System.assert(false, 'Unexpected exception thrown.' + e.getMessage());	
        }
        
        shipmentLines = [select Id, Company__c, Description__c, Facility__c, Location__c, Extended_Cost__c, Quantity_Shipped__c, Sales_Order__c, Product__c,
                                    Sales_Order_Line__c, Sales_Order_Line__r.Description__c, Sales_Order_Line__r.Sales_Order__c, Sales_Order_Line__r.Quantity_Ordered__c,  
                                    Sales_Order_Line__r.Product__c, Sales_Order_Line__r.Ship_From_Location__c, Sales_Order_Line__r.Quantity_BackOrdered__c,
                                    Shipment__r.Company__c, Shipment__r.Customer__c, Shipment__r.Planned_Delivery_Date__c,
                                    Shipment__r.Status__c, Shipment__r.Currency__c 
                           from Shipment_Line__c 
                          where Sales_Order_Line__c IN :data.salesOrderLines];
        
        System.assertEquals(2, shipmentLines.size());
        
        Test.stopTest();
    }
    
    public static testMethod void preventChangeOfPaymentTerms()
    {
    	TestFuel fuel = new TestFuel(); 
        List<Period__c> periodList = fuel.periodList;
        Sales_Order__c sorder = fuel.salesOrder;
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Adjustment';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Sales_Order__c = sorder.id;
        CustomerInvoice.Transaction_Date__c = Date.today();
		insert CustomerInvoice;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
		
		CustomerInvoice.Finalized__c = true;
		update CustomerInvoice;
        
        Payment_Term__c terms = new Payment_Term__c(); 
        terms.name = '2/10 Net 30 NO'; 
        terms.Description__c = '2% discount in 10 days, due 30 days';
        terms.Discount_Days__c = 20;
        terms.Discount_Percent__c = 2;
        terms.Due_Days__c = 30;
        insert terms; 
        
        sorder = [select id, (select id from Customer_INvoices__r where Status__c ='Open') from Sales_Order__c where id = :sorder.id limit 1];
        system.assert(sorder.Customer_Invoices__r.size()>0);
        sorder.Payment_Term__c = terms.id;
        try
        {
        	update sorder;
        }
        catch(Exception ex)
        {
        	system.assert(ex.getMessage().contains(Label.CannotChangePaymentTermOnSO));
        }
        sorder = [select id, payment_term__c from Sales_Order__c where id = :sorder.id limit 1];
        system.assertNotEquals(sorder.payment_term__c,terms.ID);
        
        
    }
    
    // OTC-696: For a SO with 2 SOLs where 1 SOL is complete shipped and the other line is Open unallocated, cancel the 2nd line 
    public static testMethod void cancelSOLOnPartialCompleteOrder(){
        TestFuel fuel = new TestFuel(); 
        List<Period__c> periodList = fuel.periodList;
        List<SKID__c> skids = fuel.skids;    
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
        //Transit_Route__c route = fuel.transitRoute; KNDY-10333

        Sales_Order__c sorder = fuel.salesOrder;
        Sales_Order_Line__c[] sols = fuel.salesOrderLines;

        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(sorder);
        SOPlanExt soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();
        system.debug(LoggingLevel.INFO,'Queries plan()'+Limits.getQueries() );   
        System.assertEquals(false, ExceptionService.hasErrors, ExceptionService.messages);
        System.assertEquals(false, soPlanExt.hasErrors);
        
        Test.startTest();
        
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);
        system.assertEquals(2, SOAExt.solWrapperList.size());
        
        // Allocate 1 of the sales order lines
        SOAExt.solWrapperList[0].skidList[0].Quantity_Allocated__c  = 0;

        SOAExt.allocate();

        // verify only 1 SOL has quantity allocated
        system.assertEquals(1, [select id from Sales_Order_Line__c where Quantity_Allocated__c > 0].size());
        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        socpExt.confirmPick();
		
		
        SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension(con);
        
        socsExt.confirmShip();
        // shipment is finalized even though 1 SHL has 0 shipped. This needs to happen for accounting reasons
        for (Shipment__c ship : [select id, status__c, Locked__c from Shipment__c]){
          system.assertEquals('Confirmed', ship.status__c);
          system.assertEquals(true, ship.Locked__c);
        }
        
        system.assertEquals('Open', [select id, status__c from Sales_Order__c where id =: sorder.id ].status__c);

        // re-release SO
        soPlanExt.plan();
        system.debug(LoggingLevel.INFO,'Queries plan()'+Limits.getQueries() );   
        System.assertEquals(false, ExceptionService.hasErrors, ExceptionService.messages);
        System.assertEquals(false, soPlanExt.hasErrors);
        system.assertEquals(1, [select id from Shipment__c where status__c = :ShipmentService.SHIPMENT_STATUS_PLANNED].size());
		Test.stopTest();
        // cancel open SOL line
        SalesOrderLinesAddManageExt solam = new SalesOrderLinesAddManageExt(con);
        List <SalesOrderLinesAddManageExt.SOLineWrapper>  solWrapedLines = solam.wrapLines([select id, Product__c, Quantity_Ordered__c from Sales_Order_Line__c where status__c = :SalesOrderService.SO_STATUS_OPEN]);
        System.assertEquals(1, solWrapedLines.size()); // check that we have lines
        solam.soLineList = solWrapedLines;
        // set index to select line for cancellation
        String selected_indexes = Apexpages.currentPage().getParameters().put('selected_indexes','0');
        solam.cancelLines();


        // verify that the SO is closed once SOL is cancelled
        Sales_Order_Line__c[] closedSol = [select id, Sales_Order__r.status__c from Sales_Order_Line__c where status__c = :SalesOrderService.SO_STATUS_CANCEL];
        system.assertEquals(1, closedSol.size());
        system.assertEquals(SalesOrderService.SO_STATUS_CLOSED, closedSol[0].Sales_Order__r.Status__c);
    }

    public static testMethod void testonhold(){
        TestFuel data = new TestFuel();  
        system.assert (data.company!=null && data.product != null && data.customerSoldTo != null && data.terms != null 
                    && data.product2 != null);
        test.startTest();
        ApexPages.Standardcontroller con;
        data.salesOrder.Hold__c = true;
        update data.salesOrder;
        
        con = new ApexPages.Standardcontroller(data.salesOrder);
        SOPlanExt SOPExt = new SOPlanExt(con);
        SOPExt.plan();
        system.assertEquals(true, SOPExt.hasErrors);
        system.assertequals('This sales order is on hold and cannot be released', 'This sales order is on hold and cannot be released') ;
        
        
        Test.stopTest();
    }    
    
    public static testMethod void UpdatePricingBracketAfterCICancelled() //OTC-860
    {
    	TestFuel fuel = new TestFuel(); 

        System.assert(fuel.smrsList.size() > 0);
        System.assert(fuel.stockMovementRuleList.size() > 0);
        System.assert(fuel.periodList.size() > 0);

        system.debug(Logginglevel.INFO, fuel.smrsList);
        // Implement brackets
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(fuel.company));
        
        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        System.assertEquals(5, bracketWraps.size());
        for (BracketPricingUpchargeManageExt.BracketPriceWrapper wrap : bracketWraps) {
            System.assertEquals(null, wrap.reasonCode.Id);
            System.assertEquals(BracketPricingService.TypeBracketPricingUpcharge, wrap.reasonCode.Type__c);
            System.assertEquals(fuel.company.Id, wrap.reasonCode.Company__c);
            System.assertEquals('Price__c', wrap.pricebookLineField);
            System.assert(wrap.volumeRangeBottom == null || wrap.volumeRangeBottom == 0);
            System.assert(wrap.percentUpcharge == null || wrap.percentUpcharge == 0);
        }
        
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1,brack2,brack3,brack4;
        
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 200;
        brack1.percentUpcharge = 0;
        brack1.pricebookLineField = 'Price__c';
        
        // Create bracket 2
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 150;
        brack2.percentUpcharge = 1;
        brack2.pricebookLineField = 'Price_2__c';

        // Create bracket 3
        brack3 = bracketWraps[2];
        brack3.inUse = true;
        brack3.volumeRangeBottom = 100;
        brack3.percentUpcharge = 2;
        brack3.pricebookLineField = 'Price_3__c';

        // Create bracket 4
        brack4 = bracketWraps[3];
        brack4.inUse = true;
        brack4.volumeRangeBottom = 50;
        brack4.percentUpcharge = 3;
        brack4.pricebookLineField = 'Price_4__c';

		// Create bracket 5		
		/*
        brack5 = bracketWraps[4];
        brack5.inUse = true;
        brack5.volumeRangeBottom = 0;
        brack5.percentUpcharge = 4;
        brack5.pricebookLineField = 'Price_5__c';
        */

        // Persist to DB
        ext.onSave();
        
        // Reload extension to verify
        ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(fuel.company));
        
        Pricebook__c pricebook = new Pricebook__c(); 
        pricebook.Name = fuel.company.Name +  ' Orange Pricebook2';
        pricebook.Company__c = fuel.company.Id; 
        insert pricebook; 

        Pricebook_Line__c pl = new Pricebook_Line__c();
        pl.Product__c = fuel.product.Id;
        pl.Pricebook__c = pricebook.Id;
        pl.Use_Fixed_Pricing__c = false;
        pl.Price__c = 10;
        pl.Start_date__c = System.today() + 3; 
        pl.End_Date__c = System.today() + 5;
        
        Pricebook_Line__c pl2 = new Pricebook_Line__c();
        pl2.Product__c = fuel.product.Id;
        pl2.Pricebook__c = pricebook.Id;
        pl2.Use_Fixed_Pricing__c = false;
        pl2.Price__c = 20;
        pl2.Start_date__c = System.today();
        pl2.End_Date__c = System.today() + 2;
        insert new Pricebook_Line__c[] {pl, pl2};

        

        Map<Id, Pricebook_Line__c> pbLinesById = new Map<Id, Pricebook_Line__c>([SELECT Price_2__c, Price_3__c, Price_4__c, Price_5__c 
                                                                                 FROM Pricebook_Line__c WHERE Id IN :new Set<Id>{pl.Id, pl2.Id}]);
        Pricebook_Line__c plReloaded = [Select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c Where Id =:pl.Id];
        System.debug (LoggingLevel.INFO, 'plReloaded : ' + plReloaded);
        
        //Check that our pricing is working properly
        System.assertEquals(10.1, plReloaded.Price_2__c);
        System.assertEquals(10.2, plReloaded.Price_3__c);
        System.assertEquals(10.3, plReloaded.Price_4__c);
        //System.assertEquals(10.4, plReloaded.Price_5__c);


        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;   
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        salesOrder.pricebook__c = pricebook.id;// make sure its pointing to normal pricebook
        salesOrder.Ship_From_Location__c = fuel.location2.Id;
        salesOrder.Type__c = 'Adjustment';
        salesOrder.Price_Determination_Date__c = SalesOrderService.PRICE_DET_MANUAL;
        salesOrder.Required_Date__c = System.today() + 5;
        insert salesOrder;

        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 5;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
        insert salesOrderLine;
        
        SalesOrderService.generateCustomerInvoices(new list<Sales_Order__c>{salesOrder});
        
        Customer_Invoice__c CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Invoice_Type__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c from Customer_Invoice__c where Sales_Order__c = :salesOrder.Id limit 1 ];
		CustomerInvoiceVoidCancelExt extVoidCancel = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(CustomerInvoice));
		system.debug(LoggingLevel.INFO,CustomerINvoice.Invoice_Type__c);
		
		system.assert(!extVoidCancel.getDisableCancel() == true);
		
		extVoidCancel.cancelDocs();
		CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
		system.assertEquals(CustomerInvoice.Status__c, 'Cancelled');
		
		test.StartTest();
		{
			Sales_Order__c SO = [SELECT Id, Bracket_Price_Field_In_Use__c, Pricing_Bracket__c, Total_Product_Weight__c, Pricing_Date__c,
					                (SELECT Id, Quantity_Ordered__c, Unit_Price__c, Product__c, Has_Exceptions__c FROM Sales_Order_Lines__r)
					                FROM Sales_Order__c WHERE Id = :salesOrder.Id LIMIT 1];
			SO.Pricing_Bracket__c = 'Bracket 2';
	        update SO;
	
	        SO = [SELECT Id, Bracket_Price_Field_In_Use__c, Pricing_Bracket__c, Total_Product_Weight__c, Pricing_Date__c,
	                (SELECT Id, Quantity_Ordered__c, Unit_Price__c, Product__c, Has_Exceptions__c FROM Sales_Order_Lines__r)
	               FROM Sales_Order__c WHERE Id = :salesOrder.Id LIMIT 1];
	        System.assert(SO.Bracket_Price_Field_In_Use__c.contains('Price_2__c'));
		}
		test.StopTest();
    }
    
    public static testMethod void testSalesOrderAdjustmentRelease(){
    	
    	TestFuel fuel = new TestFuel(); 
    	
    	Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;   
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Bill_To__c = fuel.customerBillTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        salesOrder.pricebook__c = fuel.pricebook.id;// make sure its pointing to normal pricebook
        salesOrder.Ship_From_Location__c = fuel.location2.Id;
        salesOrder.Type__c = 'Adjustment';
        salesOrder.Price_Determination_Date__c = SalesOrderService.PRICE_DET_MANUAL;
        salesOrder.Required_Date__c = System.today() + 5;
        insert salesOrder;

        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = -5;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
        insert salesOrderLine;
        
        salesOrderLine = [SELECT Id, Status__c, Sales_Order__r.Status__c, Quantity_Fulfilled__c, Quantity_Ordered__c 
        					FROM Sales_Order_Line__c WHERE Id = :salesOrderLine.Id LIMIT 1];
        system.assertEquals('Draft', salesOrderLine.Status__c);
        system.assertEquals('Draft', salesOrderLine.Sales_Order__r.Status__c);
        system.assertEquals(-5, salesOrderLine.Quantity_Ordered__c);
        system.assertEquals(0, salesOrderLine.Quantity_Fulfilled__c);
        
        SalesOrderService sos = new SalesOrderService();
        
        try{
            sos.plan(salesOrder.Id);
            System.assert(ExceptionService.hasErrors == false, 'Unexpected errors: ' + ExceptionService.messages);
        }catch(Exception e){
            System.assert(false, 'Unexpected exception thrown.' + e.getMessage());	
        }
        
        salesOrderLine = [SELECT Id, Status__c, Sales_Order__r.Status__c, Quantity_Fulfilled__c, Quantity_Ordered__c, 
        						 (SELECT Id FROM Fulfillments__r)
        					FROM Sales_Order_Line__c WHERE Id = :salesOrderLine.Id LIMIT 1];
        					
        system.assertEquals('Closed', salesOrderLine.Status__c);
        system.assertEquals('Closed', salesOrderLine.Sales_Order__r.Status__c);
        system.assertEquals(-5, salesOrderLine.Quantity_Ordered__c);
        system.assertEquals(-5, salesOrderLine.Quantity_Fulfilled__c);
        system.assertEquals(1, salesOrderLine.Fulfillments__r.size());
        
    }  
    
    public static List<SKID__c> fillStock(TestData testData){
        
        List<SKID__c> availableSkids = new List<SKID__c>();
        for (Item__c item : testData.itemList) {
            SKID__c skid = new SKID__c();
            skid.location__c = testData.location3.id;
            skid.Company__c= testData.company.id;
            skid.Quantity__c = 2400.0;
            skid.Item__c= item.Id;
            skid.Type__c = SKIDService.SKID_TYPE_LOCATION;
            skid.Expiration_Date__c = System.today() + 365;
            availableSkids.add(skid);
        }
        insert availableSkids;
        
        return availableSkids;
    }
}