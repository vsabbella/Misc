/**
 * Test case for KNDY-2123
 */
 @isTest
private class SalesOrderKndy2123Test {
    /*
        Tries to create an overweight sales order and asserts if Sales Order release fails because of the same.     
     */
    static testMethod void test_SO_Release_By_OverWeight() {
        TestFuel fuel = new TestFuel();
        
        Means_of_Transport__c mot = fuel.newMeansOfTransport('LTL', 'LTL');
        mot.Maximum_Cube__c = 5000;
		mot.Maximum_Weight__c = 43000;
        fuel.meansOfTransport = mot;
        insert fuel.meansOfTransport;
        
        Product__c prd1 = fuel.newProduct();
        prd1.Length__c = 1;
        prd1.Width__c = 1;
        prd1.Height__c = 1;
        prd1.Weight__c = 1000;
        prd1.Dimension_UOM__c = fuel.uomList[7].Id;
        insert prd1;
        fuel.product = prd1;

        Sales_Order__c salesOrder = fuel.newSalesOrder();
        salesOrder.Means_of_Transport__c = mot.Id;
        salesOrder.Ship_to__c = fuel.customerShipTo.Id;
        salesOrder.Bill_To__c = fuel.customerBillTo.Id;
        insert salesOrder;
                
        // Add a bad SO line whose quantity doesnt matches the product's quantity factors
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 60;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Ship_From_Location__c = fuel.location.Id;

        insert salesOrderLine;
        
        
        Test.startTest();
        
        System.assert(ExceptionService.fetchExceptionTasks(new Set<Id>{salesOrderLine.Id}).isEmpty(), 'Should have no exceptions on this line');                                
        
        Sales_Order__c soReloaded = [Select Id, Total_Order_Volume__c, Total_Weight__c,Number_of_pallets__c , Exceeds_Max_Weight__c, Dimensional_Weight__c, Maximum_Dimensional_Percent__c from Sales_Order__c Where Id =:salesOrder.Id];
        System.debug (LoggingLevel.INFO, 'soReloaded:' + soReloaded);
        System.assert(soReloaded.Exceeds_Max_Weight__c, 'SO Dimensional_Weight should exceed Means_of_Transport > Max Weight__c');                                
        
        //SOPlanExt planExt = new SOPlanExt(new ApexPages.StandardController(salesOrder));
        
        //planExt.plan();
        new SalesOrderService().plan(salesOrder.Id);
        System.assert(ExceptionService.hasErrors , 'Plan/Release should fail, as order is over weight ');
        
        System.assert(ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_OVER_WEIGHT_EXCEPTION.code), 'Release should create a exception on over weight Sales order ');                
        
        // Change Sales order line quantity to get out of exception
        salesOrderLine.Quantity_Ordered__c = 40;
        //KNDY-2551
        Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
        insert rc;
        salesOrderLine.Quantity_Change_Reason__c = rc.Id; 
        update salesOrderLine;
        soReloaded = [Select Id, Exceeds_Max_Weight__c, Dimensional_Weight__c, Maximum_Dimensional_Percent__c from Sales_Order__c Where Id =:salesOrder.Id];
        System.debug (LoggingLevel.INFO, 'soReloaded:' + soReloaded);
        System.assert(soReloaded.Exceeds_Max_Weight__c == false, 'SO Dimensional_Weight should be less then Means_of_Transport > Max Weight__c');                                       
        
        ExceptionService.messages.clear();
        
        //planExt = new SOPlanExt(new ApexPages.StandardController(salesOrder));
        //planExt.plan();
        
        new SalesOrderService().plan(salesOrder.Id);
        System.assertEquals(false, ExceptionService.hasErrors, 'Plan should be successful');
        
        System.assert(false == ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_OVER_WEIGHT_EXCEPTION.code), 'Release should not create a exception on this Sales order ');                
        
        // check if dimension weight is copied correctly to shipment
        Shipment_Line__c[] shipLines = [Select Shipment__r.Dimensional_Weight__c from Shipment_Line__c Where Sales_Order__c = :salesOrder.Id];
        System.debug (LoggingLevel.INFO, shipLines);
        System.assert(shipLines != null && !shipLines.isEmpty(), 'Ship lines should come as release of sales order was success !');
        
        //OTC-187
        System.assertEquals(soReloaded.Dimensional_Weight__c, 40000.00);
        
        Test.stopTest();
    }  	 
    
    
    
   
    //    Tries to create an over volume sales order and asserts if Sales Order release fails because of the same.     
     
    static testMethod void test_SO_Release_By_OverVolume() {
        TestFuel fuel = new TestFuel();
        
        Means_of_Transport__c mot = fuel.newMeansOfTransport('LTL', 'LTL');
        mot.Maximum_Cube__c = 5000;
		mot.Maximum_Weight__c = 43000;
        fuel.meansOfTransport = mot;
        insert fuel.meansOfTransport;
        
        Product__c prd1 = fuel.newProduct();
        prd1.Length__c = 10;
        prd1.Width__c = 10;
        prd1.Height__c = 10;
        prd1.Weight__c = 10;
        prd1.Dimension_UOM__c = fuel.uomList[7].Id;
        insert prd1;
        fuel.product = prd1;

        Sales_Order__c salesOrder = fuel.newSalesOrder();
        salesOrder.Means_of_Transport__c = mot.Id;
        salesOrder.Ship_to__c = fuel.customerShipTo.Id;
        salesOrder.Bill_To__c = fuel.customerBillTo.Id;
        insert salesOrder;
                
        // Add a bad SO line whose quantity doesnt matches the product's quantity factors
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 60;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Ship_From_Location__c = fuel.location.Id;

        insert salesOrderLine;
        
        
        Test.startTest();
        
        System.assert(ExceptionService.fetchExceptionTasks(new Set<Id>{salesOrderLine.Id}).isEmpty(), 'Should have no exceptions on this line');                                
        
        Sales_Order__c soReloaded = [Select Id, Exceeds_Max_Weight__c, Dimensional_Weight__c, Maximum_Dimensional_Percent__c from Sales_Order__c Where Id =:salesOrder.Id];
        System.debug (LoggingLevel.INFO, 'soReloaded:' + soReloaded);
        System.assert(soReloaded.Exceeds_Max_Weight__c, 'SO Dimensional_Weight should exceed Means_of_Transport > Maximum_Cube__c');                                
        
        //SOPlanExt planExt = new SOPlanExt(new ApexPages.StandardController(salesOrder));
        
        //planExt.plan();
        new SalesOrderService().plan(salesOrder.Id);
        System.assert(ExceptionService.hasErrors , 'Plan/Release should fail, as order is over volume ');
        
        System.assert(ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_OVER_WEIGHT_EXCEPTION.code), 'Release should create a exception on over weight Sales order ');                
        
        // Change Sales order line quantity to get out of exception, this should bring volume to 4000 which is below max cube 5000 on Means_of_Transport__c record
        salesOrderLine.Quantity_Ordered__c = 4; 
        //KNDY-2551
        Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
        insert rc;
        salesOrderLine.Quantity_Change_Reason__c = rc.Id;
        update salesOrderLine;
        soReloaded = [Select Id, Exceeds_Max_Weight__c, Dimensional_Weight__c, Maximum_Dimensional_Percent__c from Sales_Order__c Where Id =:salesOrder.Id];
        System.debug (LoggingLevel.INFO, 'soReloaded:' + soReloaded);
        System.assert(soReloaded.Exceeds_Max_Weight__c == false, 'SO Dimensional_Weight should be less then Means_of_Transport > Max Weight__c');                                       
        
        ExceptionService.messages.clear();
        
        //planExt = new SOPlanExt(new ApexPages.StandardController(salesOrder));
        //planExt.plan();
        new SalesOrderService().plan(salesOrder.Id);
        System.assertEquals(false, ExceptionService.hasErrors, 'Plan should be successful');
        
        System.assert(false == ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_OVER_WEIGHT_EXCEPTION.code), 'Release should not create a exception on this Sales order ');                
        
        
        Test.stopTest();
    }  



       // Tries to create a sales order with overflowing number of pallets and asserts if Sales Order release fails because of the same.     
   
    static testMethod void test_SO_Release_By_OverPallets() {
        TestFuel fuel = new TestFuel();
        
        Means_of_Transport__c mot = fuel.newMeansOfTransport('LTL', 'LTL');
        mot.Maximum_Cube__c = 5000;
		mot.Maximum_Weight__c = 43000;
		mot.Pallet_Positions_double_stacked__c = 50;
        fuel.meansOfTransport = mot;
        insert fuel.meansOfTransport;
        
        Product__c prd1 = fuel.newProduct();
        prd1.Length__c = 1;
        prd1.Width__c = 1;
        prd1.Height__c = 1;
        prd1.Weight__c = 1;
        prd1.Stackable__c = true;
        prd1.Layers_Per_Pallet__c = 1;
        prd1.Units_Per_Layer__c = 1;
        prd1.Dimension_UOM__c = fuel.uomList[7].Id;

        insert prd1;
        fuel.product = prd1;

        Sales_Order__c salesOrder = fuel.newSalesOrder();
        salesOrder.Means_of_Transport__c = mot.Id;
        salesOrder.Ship_to__c = fuel.customerShipTo.Id;
        salesOrder.Bill_To__c = fuel.customerBillTo.Id;
        insert salesOrder;
                
        // Add a bad SO line whose quantity doesnt matches the product's quantity factors
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 60;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Ship_From_Location__c = fuel.location.Id;

        insert salesOrderLine;
        
        
        Test.startTest();
        
        System.assert(ExceptionService.fetchExceptionTasks(new Set<Id>{salesOrderLine.Id}).isEmpty(), 'Should have no exceptions on this line');                                
        
        Sales_Order__c soReloaded = [Select Id, Exceeds_Max_Weight__c, Dimensional_Weight__c, Maximum_Dimensional_Percent__c from Sales_Order__c Where Id =:salesOrder.Id];
        System.debug (LoggingLevel.INFO, 'soReloaded:' + soReloaded);
        System.assert(soReloaded.Exceeds_Max_Weight__c, 'SO Number of pallets should exceed Means_of_Transport > Pallet_Positions_double_stacked__c');                                
        
        //SOPlanExt planExt = new SOPlanExt(new ApexPages.StandardController(salesOrder));
        
        //planExt.plan();
        new SalesOrderService().plan(salesOrder.Id);
        System.assert(ExceptionService.hasErrors , 'Plan/Release should fail, as order is resulting in too many stackable pallets ');
        
        System.assert(ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_OVER_WEIGHT_EXCEPTION.code), 'Release should create a exception on over weight Sales order ');                
        
        // Change Sales order line quantity to get out of exception, this should bring volume to 4000 which is below max cube 5000 on Means_of_Transport__c record
        salesOrderLine.Quantity_Ordered__c = 40; 
        //KNDY-2551
        Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
        insert rc;
        salesOrderLine.Quantity_Change_Reason__c = rc.Id;
        update salesOrderLine;
        soReloaded = [Select Id, Exceeds_Max_Weight__c, Dimensional_Weight__c, Maximum_Dimensional_Percent__c from Sales_Order__c Where Id =:salesOrder.Id];
        System.debug (LoggingLevel.INFO, 'soReloaded:' + soReloaded);
        System.assert(soReloaded.Exceeds_Max_Weight__c == false, 'SO Dimensional_Weight should be less then Means_of_Transport > Max Weight__c');                                       
        
        ExceptionService.messages.clear();
        
        //planExt = new SOPlanExt(new ApexPages.StandardController(salesOrder));
        //planExt.plan();
        new SalesOrderService().plan(salesOrder.Id);
        System.assertEquals(false, ExceptionService.hasErrors, 'Plan should be successful');
        
        System.assert(false == ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_OVER_WEIGHT_EXCEPTION.code), 'Release should not create a exception on this Sales order ');                
        
        
        Test.stopTest();
    }  

    static testMethod void test_SO_Release_UOM_Conversion() {
    	TestFuel fuel = new TestFuel();
    	List<UOM_Conversion_Details__c> uomcList = fuel.uomcList;
		Decimal convOZLB = 0.0625;
		Decimal convYDFT3 = 0.037040;		
		Decimal weight = 2*5* 0.0625;
        Decimal volume = 2*1*1*1*0.037040;
        List<Sales_Order__c> solist = new List<Sales_Order__c>();
        List<Sales_Order_Line__c> solineslist = new List<Sales_Order_Line__c>();
       
       
        Product__c prd1 = fuel.product;
        prd1.Length__c = 1;
        prd1.Width__c = 1;
        prd1.Height__c = 1;
        prd1.Weight__c = 5;
        prd1.Stackable__c = true;
        prd1.Layers_Per_Pallet__c = 1;
        prd1.Units_Per_Layer__c = 1;
        prd1.Weight_UOM__c = fuel.uomList[3].id;
        prd1.Dimension_UOM__c = fuel.uomList[5].Id;

        DML.updateAsUser(prd1); 
                   
		Test.startTest(); 
        Sales_Order__c salesOrder = fuel.newSalesOrder();    
        salesOrder.Weight_UOM__c = fuel.uomList[0].Id;        
        salesOrder.Dimension_UOM__c = fuel.uomList[9].Id;
        salesOrder.Ship_to__c = fuel.customerShipTo.Id;
        salesOrder.Bill_To__c = fuel.customerBillTo.Id;

        solist.add(salesOrder);
        DML.insertAsUser(solist);
       
       	Sales_Order_Line__c sol = new Sales_Order_Line__c();
        sol.Product__c = prd1.Id;
        sol.Description__c = prd1.Description__c;     
        sol.Company__c = fuel.company.id;
        sol.Sales_Order__c = salesOrder.Id;
        sol.Quantity_Ordered__c = 2;
        sol.Weight_UOM__c = fuel.uomList[0].Id;
        sol.Dimension_UOM__c = fuel.uomList[9].Id;        
        sol.Required_Date__c = System.today() + 5;
        sol.Ship_From_Location__c = fuel.location.Id;

         
        solineslist.add(sol);
        DML.insertAsUser(solineslist);
     
        
        sol =  [Select Weight__c, Volume__c,Product__c, Company__c, Weight_UOM__c, Weight_UOM__r.Name, Dimension_UOM__c, Quantity_Ordered__c,Product__r.Weight_UOM__c,Product__r.Weight_UOM__r.Name, Product__r.Dimension_UOM__c from Sales_Order_Line__c Where Id =:sol.Id];
       
        system.assert( sol.Weight__c == (2*5*0.0625), 'converted weight after insert does not match!'+sol.Weight__c + ','+weight + ',' + sol.Weight_UOM__c + ',' +sol.Product__r.Weight_UOM__c );
        system.assert( sol.Volume__c == (2*1*1*1*0.037040), 'converted volume after insert does not match!'+sol.Volume__c + ','+volume + ',' + sol.Dimension_UOM__c + ',' +sol.Product__r.Dimension_UOM__c );
            
        //Updating Product's Weight & Dimension UOM.
            
        prd1.Weight_UOM__c = fuel.uomList[1].Id;
        prd1.Dimension_UOM__c = fuel.uomList[10].Id;
        prd1.Weight_UOM__r = fuel.uomList[1]; 
        prd1.Weight_UOM__r.Name = fuel.uomList[1].Name; 
        
        DML.updateAsUser(prd1); 
        
        SalesOrderFlowCache.flush();              
              
        sol.Quantity_Ordered__c = 1;
		//KNDY-2551
        Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
        insert rc;
        sol.Quantity_Change_Reason__c = rc.Id;
	    DML.updateAsUser(sol); 
		
        sol =  [Select Weight__c, Volume__c,Product__c, Company__c, Weight_UOM__c, Weight_UOM__r.Name, Dimension_UOM__c, Dimension_UOM__r.Name, Quantity_Ordered__c, Product__r.Weight_UOM__c,Product__r.Weight_UOM__r.Name, Product__r.Dimension_UOM__r.Name from Sales_Order_Line__c Where Id =:sol.Id];
        weight = 5*2000.0;
        volume = 1*1*1*0.133680;
        
         system.assert( sol.Weight__c == (5*2000.0), 'converted weight after update does not match!'+sol.Weight__c + ','+weight + ',' + sol.Weight_UOM__r.Name + ',' +sol.Product__r.Weight_UOM__r.Name);
         system.assert( sol.Volume__c == (1*1*1*0.133680), 'converted volume after update does not match!'+sol.Volume__c + ','+volume + ',' + sol.Dimension_UOM__r.Name + ',' +sol.Product__r.Dimension_UOM__r.Name);
        
           //Updating Product's Weight & Dimension UOM for Release test.
            
        prd1.Weight_UOM__c = fuel.uomList[3].Id;
        prd1.Dimension_UOM__c = fuel.uomList[5].Id;
        prd1.Weight_UOM__r = fuel.uomList[3]; 
        prd1.Weight_UOM__r.Name = fuel.uomList[3].Name; 
        
     
        DML.updateAsUser(prd1); 
        
         weight = 5* 0.0625;
         volume = 1*1*1*0.037040;
                
        SOPlanExt planExt = new SOPlanExt(new ApexPages.StandardController(salesOrder));
        planExt.plan(); 
        Sales_Order_Line__c solReload = [Select Weight__c, Volume__c, Weight_UOM__c, Dimension_UOM__c, Quantity_Ordered__c from Sales_Order_Line__c Where Id =:sol.Id LIMIT 1];
        system.assert( solReload.Weight__c == (5* 0.0625), 'converted weight after release does not match!' );
        system.assert( solReload.Volume__c == (1*1*1*0.037040), 'converted Volume after release does not match!' );       
        System.assertEquals(solReload.Weight__c , prd1.Weight__c* solReload.Quantity_Ordered__c * convOZLB);
        System.assertEquals(solReload.Volume__c , prd1.Length__c*prd1.Height__c * prd1.Width__c * solReload.Quantity_Ordered__c * convYDFT3);
        
  
        Test.stopTest();
        
    }
    //KNDY 4343
    
    static testMethod void test_SO_totalweight() {
    	TestFuel fuel = new TestFuel();
    	//List<UOM_Conversion_Details__c> uomcList = fuel.uomcList;
		
        List<Sales_Order__c> solist = new List<Sales_Order__c>();
        List<Sales_Order_Line__c> solineslist = new List<Sales_Order_Line__c>();
       
       
        Product__c prd1 = fuel.product;
        prd1.Length__c = 1;
        prd1.Width__c = 1;
        prd1.Height__c = 1;
        prd1.Weight__c = 5;
        prd1.Stackable__c = true;
        prd1.Layers_Per_Pallet__c = 5;
        prd1.Units_Per_Layer__c = 4;
        prd1.Weight_UOM__c = fuel.uomList[0].id;
        prd1.Dimension_UOM__c = fuel.uomList[9].Id;
        DML.updateAsUser(prd1); 
        
        Product__c palletprod = fuel.product2;
        palletprod.Weight__c = 1;
        prd1.Weight_UOM__c = fuel.uomList[0].id;   
        
        Customer__c soShipTo = fuel.customerShipTo;
        soShipTo.Pallet_Product__c = palletprod.Id;
        update soShipTo;
                   
		Test.startTest(); 
        Sales_Order__c salesOrder = fuel.newSalesOrder();    
        salesOrder.Weight_UOM__c = fuel.uomList[0].Id;        
        salesOrder.Dimension_UOM__c = fuel.uomList[9].Id;  
        salesOrder.Ship_to__c = soShipTo.Id;
        salesOrder.Ship_to__c = fuel.customerShipTo.Id;
        salesOrder.Bill_To__c = fuel.customerBillTo.Id;

        solist.add(salesOrder);
        DML.insertAsUser(solist);
       
       	Sales_Order_Line__c sol = new Sales_Order_Line__c();
        sol.Product__c = prd1.Id;
        sol.Description__c = prd1.Description__c;     
        sol.Company__c = fuel.company.id;
        sol.Sales_Order__c = salesOrder.Id;
        sol.Quantity_Ordered__c = 2;
        sol.Weight_UOM__c = fuel.uomList[0].Id;
        sol.Dimension_UOM__c = fuel.uomList[9].Id;        
        sol.Required_Date__c = System.today() + 5;
        sol.Ship_From_Location__c = fuel.location.Id;
         
        solineslist.add(sol);
        DML.insertAsUser(solineslist);
        
        Sales_Order__c salesOrder1 = [select Id, Total_Product_Weight__c, Number_of_pallets__c, Total_Weight__c, Ship_to__r.Pallet_Product__r.Weight__c from Sales_Order__c where Id=:salesOrder.Id];
        system.assert(salesOrder1.Total_Weight__c == salesOrder1.Total_Product_Weight__c + (salesOrder1.Number_of_pallets__c.round(System.roundingmode.CEILING) *salesOrder1.Ship_to__r.Pallet_Product__r.Weight__c), 'Total_Weight__c on SO is not calculated correctly' );
        Test.stopTest();
        
    }

     //KNDY - 3918
     static testMethod void test_Repriceonconfirmship() {
        
        Testfuel data = new Testfuel();
        List<Period__c> periodList = data.periodList;
        
        Sales_Order__c salesOrder = data.salesOrder;
        salesOrder.Price_Determination_Date__c = 'Shipment Date';
        DML.updateAsUser(salesOrder);
        salesOrder = [Select Id, Pricing_Date__c, Price_Determination_Date__c from Sales_Order__c];
        
        List<SKID__c> skids = data.skids;
        List<Stock_Movement_Rule_Settings__c> smrsList = data.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = data.stockMovementRuleList;
        Sales_Order_Line__c salesOrderLine = data.salesOrderLines[0];
        
        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SOPlanExt planExt = new SOPlanExt(con);
        planExt.plan();
        
        Sales_Order_Line__c soLine = [Select Id, Unit_Price__c,Pricebook__c,Product__c,Sales_Order__c,Sales_Order__r.Pricing_Date__c from Sales_Order_Line__c Where Id = :salesOrderLine.id];
        salesOrder.Id = soLine.Sales_Order__c;
        Test.startTest();
        System.assertEquals(11.12, soLine.Unit_Price__c);
        
        con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        
        for( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ){
            system.assert( sw.skidList.size() == 1, ApexPages.getMessages()+',:SOAEXTLOcations'+SOAExt.locationsByHeader );
            sw.skidList[0].Quantity_Allocated__c  = sw.sol.Quantity_Ordered__c;
        }
        
        SOAExt.allocate();
        con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        socpExt.confirmPick();
        
        Pricebook_Line__c pbLine3 = [select id , price__c from Pricebook_Line__c 
                                     where product__c = :data.product.id];

        
        system.assert(soLine.Sales_Order__r.Pricing_Date__c != null, 'Pricing_Date__c is empty' +soLine.Sales_Order__r.Pricing_Date__c);
        con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension(con);
        socsExt.confirmShip();
        Test.stopTest();
        
        Sales_Order_Line__c soLine1 = [Select Id, Unit_Price__c,Pricebook__c,Product__c from Sales_Order_Line__c Where Id = :salesOrderLine.id];
        System.assertEquals(pbLine3.Price__c, soLine1.Unit_Price__c);
        
        Shipment_Line__c shipLine = [select Id, Unit_Price__c from Shipment_Line__c where Sales_Order_Line__c = :salesOrderLine.id limit 1];
        System.assertEquals(pbLine3.Price__c, shipLine.Unit_Price__c);
        
    }
    
    
    //End KNDY-3918

    //KNDY 4313
    
    private static testMethod void test_populateProductbyUPC() {

        TestFuel fuel = new TestFuel();
        
        product__c prod1 = fuel.product3;
        prod1.primary__c = false;
        DML.updateAsUser(prod1);
        prod1 = [select Id, Primary__c,UPC_Code__c from Product__c where Id =:prod1.Id];
         
        System.assert(prod1.Primary__c == false, 'Primary is set to true'+prod1.Primary__c);
        
        
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.UPC_Code__c = '234567891235';
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = fuel.salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 60;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Ship_From_Location__c = fuel.location.Id;
        insert salesOrderLine;
        test.starttest();
       
        Sales_Order_Line__c soLine = [Select Id, Product__c,UPC_Code__c from Sales_Order_Line__c where Id =:salesOrderLine.Id];
         
        system.assert(soLine.Product__c == null, 'Product is not empty:'+soLine.Product__c + 'soLine:'+soLine.Id);
        
        prod1.primary__c = true;
        prod1.Primary_Key__c = '234567891235';
        DML.updateAsUser(prod1);
        
        prod1 = [select Id, Primary__c,UPC_Code__c from Product__c where Id =:prod1.Id];
        
        System.assert(prod1.Primary__c == true, 'Primary is set to False'+prod1.Primary__c);
        
        Sales_Order_Line__c salesOrderLine1 = new Sales_Order_Line__c();
        salesOrderLine1.UPC_Code__c = '234567891235';
        salesOrderLine1.Company__c = fuel.company.id;
        salesOrderLine1.Sales_Order__c = fuel.salesOrder.Id;
        salesOrderLine1.Quantity_Ordered__c = 10;
        salesOrderLine1.Required_Date__c = System.today() + 5;
        salesOrderLine1.Ship_From_Location__c = fuel.location.Id;
        insert salesOrderLine1;
       
         Sales_Order_Line__c soLine1 = [Select Id, Product__c, Product__r.Primary__c, UPC_Code__c from Sales_Order_Line__c where Id =:salesOrderLine1.Id];
         system.assert(soLine1.Product__c != null, 'Product is empty:'+soLine1.Product__c + 'soLine1:'+soLine1);
         test.stoptest();
	}
	//KNDY#4776 Auto release and allocate 
	 static testMethod void testAutoAllocate() {
        Test.startTest();      
               
	   	Testfuel data = new Testfuel();	    
	    Sales_Order__c salesOrder = data.salesOrder; 
	    Product__c prd1 = data.newProduct();        
	    List<SKID__c> skids = data.skids;
	    List<Stock_Movement_Rule_Settings__c> smrsList = data.smrsList;
	    List<Stock_Movement_Rule__c> stockMovementRuleList = data.stockMovementRuleList;
              
        salesOrder = [Select Id, Status__c from Sales_Order__c];
        System.assert(salesOrder.Status__c == 'Draft', 'Sales Order is not in Draft Status');
        
        Sales_Order_Line__c salesOrderLine = data.salesOrderLines[0];
        
        //Setting up Custom Setting Data.
    	Process__c p = new Process__c();
    	p.Name = 'Sales Order Release and Allocate';
    	p.Object__c = KSE.NamespaceUU + 'Sales_Order__c';
    	p.Object_Step__c = KSE.NamespaceUU + 'Step__c';
    	p.Active__c = true;
    	p.Automated__c = true;
    	p.Auto_Update__c = false;
    	p.After__c = true;
    	p.Insert__c = true;
    	p.Update__c = true;
    	p.State__c = 'SalesOrderLineFlowHandler.SalesOrderLineState';
    	p.Sequence__c = 20;
    	insert p;
    	
    	Step__c s = new Step__c();
    	s.Name = 'SO Release and Allocate';
    	s.Process__c = p.Id;
    	s.Sequence__c = 20;
    	insert s;
    	
    	Criteria__c c = new Criteria__c();
    	c.Name = 'Order is Ready';
    	c.Process__c = p.Id;    	
    	c.field__c = 'Ready__c';
    	c.operator__c = 'equals';
    	c.value_field__c = 'Value';
    	c.reference__c = 'true';
    	//c.number__c = 1;
    	insert c;
    	
    	Criteria__c c1 = new Criteria__c();
    	c1.Name = 'Ready Flag on Order is changing';
    	c1.Step__c = s.Id;    	
    	c1.field__c = 'Ready__c';
    	c1.operator__c = 'is changing';
    	c1.value_field__c = 'Field';
    	
    	insert c1;
    	
    	Criteria__c c2 = new Criteria__c();
    	c2.Name = 'Sales Order is in Draft Status';
    	c2.Process__c = p.Id;    	
    	c2.field__c = 'Status__c';
    	c2.operator__c = 'equals';
    	c2.value_field__c = 'Value';
    	c2.reference__c = 'Draft';
    	
    	insert c2;
    	
    	
    	
    	Action__c a = new Action__c();
    	a.Name = 'ReleaseandAllocate';
    	a.Step__c = s.Id;
    	a.Action__c = 'SalesOrderLineFlowHandler.ReleaseandAllocate';
    	insert a;
    	
    	
    	//This takes advantage of the @TestVisible annotation to clear dispatches across simulated apex transactions
    	//http://www.salesforce.com/us/developer/docs/apexcode/Content/apex_testing_testvisible.htm
    	
    	ProcessHandler.dispatches.clear();
		
		//Dispatch    	
    	salesOrder.Ready__c = true;
    	update salesOrder;
        test.stopTest();
        
        salesOrder = [Select Id, Status__c from Sales_Order__c];
        System.assert(salesOrder.Status__c == 'Open', 'Sales Order is not in Open Status');       
        
        List<Shipment_Line__c> shipLine = [select Id, Unit_Price__c from Shipment_Line__c where Sales_Order__c = :salesOrder.id];
        system.assert(shipLine.size()>0, 'No Shipment line has been created');
        
        Sales_Order_Line__c soLine = [Select Id, Quantity_Allocated__c, Quantity_Ordered__c, Status__c from Sales_Order_Line__c where Id =:salesOrderLine.Id];         
        system.assert(soLine.Quantity_Ordered__c == soLine.Quantity_Allocated__c, 'SalesOrderline has not been allocated');
        system.assert(soline.Status__c == 'Open', 'The Sales Order lines are not in Open Status');
    }
    
    //KNDY#4590 Sales Order is not getting Closed via Automation 
	 static testMethod void testAutogenerateInvoice() {
        Test.startTest();      
               
	   	Testfuel data = new Testfuel();	    
	   	system.assert(data.periodList != null,'Expected to have periods'); 
	   	   
	    Sales_Order__c salesOrder = data.salesOrder; 
	    salesOrder.Type__c = 'Military';    
    	update salesOrder;
    	
	    Product__c prd1 = data.newProduct();
              
        salesOrder = [Select Id, Status__c from Sales_Order__c];
        System.assert(salesOrder.Status__c == 'Draft', 'Sales Order is not in Draft Status');
        
        Sales_Order_Line__c salesOrderLine = data.salesOrderLines[0];
        
        //Setting up Custom Setting Data.
    	Process__c p = new Process__c();
    	p.Name = 'Sales Order Release Flow';
    	p.Object__c = KSE.NamespaceUU + 'Sales_Order__c';
    	p.Object_Step__c = KSE.NamespaceUU + 'Step__c';
    	p.Active__c = true;
    	p.Automated__c = true;
    	p.Auto_Update__c = false;
    	p.After__c = true;
    	p.Insert__c = true;
    	p.Update__c = true;
    	p.State__c = 'SalesOrderLineFlowHandler.SalesOrderLineState';
    	p.Sequence__c = 10;
    	insert p;
    	
    	Step__c s = new Step__c();
    	s.Name = 'Sales Order Line Military Release';
    	s.Process__c = p.Id;
    	s.Sequence__c = 10;
    	insert s;
    	
    	Criteria__c c = new Criteria__c();
    	c.Name = 'Ready equals true';
    	c.Process__c = p.Id;    	
    	c.field__c = 'Ready__c';
    	c.operator__c = 'equals';
    	c.value_field__c = 'Value';
    	c.reference__c = 'true';
    	
    	insert c;
    	
    	Criteria__c c1 = new Criteria__c();
    	c1.Name = 'Ready is changing';
    	c1.Step__c = s.Id;    	
    	c1.field__c = 'Ready__c';
    	c1.operator__c = 'is changing';
    	c1.value_field__c = 'Field';
    	
    	insert c1;
    	
    	Criteria__c c2 = new Criteria__c();
    	c2.Name = 'Sales Order Type = Military';
    	c2.Process__c = p.Id;    	
    	c2.field__c = 'Type__c';
    	c2.operator__c = 'equals';
    	c2.value_field__c = 'Value';
    	c2.reference__c = 'Military';
    	
    	insert c2;    	
    	
    	Action__c a = new Action__c();
    	a.Name = 'Generate Customer Invoices';
    	a.Step__c = s.Id;
    	a.Action__c = 'SalesOrderLineFlowHandler.GenerateCustomerInvoices';
    	insert a;
    	
    	/*
    	This takes advantage of the @TestVisible annotation to clear dispatches across simulated apex transactions
    	http://www.salesforce.com/us/developer/docs/apexcode/Content/apex_testing_testvisible.htm
    	*/
    	ProcessHandler.dispatches.clear();
		
		//Dispatch    	
    	salesOrder.Ready__c = true;
    	update salesOrder;
        test.stopTest();
        
        salesOrder = [Select Id, Status__c from Sales_Order__c];
        System.assert(salesOrder.Status__c == 'Closed', 'Sales Order is not in Closed Status');
        
        List<Customer_Invoice__c> invoice = [select Id from Customer_Invoice__c where Sales_Order__c = :salesOrder.id];
        system.assert(invoice.size()>0, 'No Invoice has been generated');        
       
    }

}