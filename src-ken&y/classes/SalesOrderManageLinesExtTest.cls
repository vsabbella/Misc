/** 
 *  File Name: SalesOrderManageLinesExtTest.cls
 *  
 *  @Description: SalesOrderManageLinesExtTest contains all the unit test methods
 *          for SalesOrderManageLinesExt.cls class
 *  @Copyright : Kenandy, Inc. 2015
 *  @author : Jerome Israel
 *  @Date : 05/11/2015
 *
 **/
@isTest
public with sharing class SalesOrderManageLinesExtTest {

    public static testMethod void getSalesOrderTest(){

        TestFuel testData = new TestFuel();
        Sales_Order__c salesOrder = testData.salesOrder;
        List<Sales_Order_Line__c> sols = testData.salesOrderLines;

        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderManageLinesExt soManageLines = new SalesOrderManageLinesExt(con);

        Test.startTest();

        String KNDO_SO_MANAGE_LINES_DUPLICATE_LINE_NUMBERS_ERROR = SalesOrderManageLinesExt.KNDO_SO_MANAGE_LINES_DUPLICATE_LINE_NUMBERS_ERROR;
        system.assertNotEquals(KNDO_SO_MANAGE_LINES_DUPLICATE_LINE_NUMBERS_ERROR, '');

        String KNDO_SO_PRODUCT_ITEM_KIT_NON_INVENTORY_FULFILLMENT_SOURCE_ERROR = SalesOrderManageLinesExt.KNDO_SO_PRODUCT_ITEM_KIT_NON_INVENTORY_FULFILLMENT_SOURCE_ERROR;
        system.assertNotEquals(KNDO_SO_PRODUCT_ITEM_KIT_NON_INVENTORY_FULFILLMENT_SOURCE_ERROR, '');

        //get Sales Order Lines field list
        soManageLines.getsalesorderheaderJson();
        soManageLines.getReturnUrl();
        SalesOrderManageLinesExt.getSalesOrderTypeRepair();
        String soHeaderFieldList = soManageLines.getSalesOrderHeaderFieldList();
        system.assertNotEquals('', soHeaderFieldList);

        String soAddlHeaderFieldList = soManageLines.getSalesOrderAddlHeaderFieldList();
        system.assertNotEquals('', soAddlHeaderFieldList);

        JsonResult result = SalesOrderManageLinesExt.getSalesOrderDetails(salesOrder.id, null);
        system.assertEquals(result.records.size(), 1);

        result = SalesOrderManageLinesExt.getSalesOrderDetails(salesOrder.id, '1');
        system.assertEquals(result.records.size(), 1);

        result = SalesOrderManageLinesExt.cancelsalesorder(salesOrder.id);
        system.assertEquals(result.success, true);

        result = SalesOrderManageLinesExt.getCustomerDefaults(salesOrder.Customer__c);
        system.assertNotEquals(result.records.size(), 0);

        String soLineFieldList = soManageLines.getSalesOrderLinesFieldList();
        system.assertNotEquals('', soLineFieldList);

        //get Segment Line field list
        GridRelatedListController.GridRelatedListConfig segmentLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        segmentLinesConfig.uniqueId = 'SegmentLinesGrid';
        segmentLinesConfig.objectName = 'Accounting_Default__c';
        String segmentFieldList = KSE.getSegmentLinesFieldList(soLineFieldList, segmentLinesConfig);
        system.assertNotEquals('', segmentFieldList);

        result = SalesOrderManageLinesExt.getSalesOrderLines(soManageLines.salesOrderLinesConfig, soManageLines.theSalesOrder.id,(List<String>) JSON.deserialize(soManageLines.getAllFields(), List<String>.class),'1');
        List<SalesOrderManageLinesExt.SOLineWrapper> soLineWrappers = (List<SalesOrderManageLinesExt.SOLineWrapper>)result.records;

        Test.stopTest();
    }

	/**
	 *	getSalesOrderLinesTest method is primarily to test the getSalesOrderLines and fetchAvailableInventory methods under 
	 *	SalesOrderManageLinesExt class
	 **/
	public static testMethod void getSalesOrderLinesTest(){

		TestFuel testData = new TestFuel();
		Sales_Order__c salesOrder = testData.salesOrder;
		List<Sales_Order_Line__c> sols = testData.salesOrderLines;

		ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderManageLinesExt soManageLines = new SalesOrderManageLinesExt(con);

        Test.startTest();
        //get Sales Order Lines field list
        String soLineFieldList = soManageLines.getSalesOrderLinesFieldList();
        system.assertNotEquals('', soLineFieldList);

        String soLineConfig = soManageLines.getSalesOrderLinesConfigJson();
        system.assertNotEquals('', soLineConfig);

        String KNDO_PAGE_HEADER_EXCEPTION_MSG = SalesOrderManageLinesExt.KNDO_PAGE_HEADER_EXCEPTION_MSG;
        system.assertNotEquals('', KNDO_PAGE_HEADER_EXCEPTION_MSG);

        String KNDO_PAGE_HEADER_ERROR_MSG = SalesOrderManageLinesExt.KNDO_PAGE_HEADER_ERROR_MSG;
        system.assertNotEquals('', KNDO_PAGE_HEADER_ERROR_MSG);

        String KNDO_PAGE_HEADER_SO_STATUS_WARNING_MSG = SalesOrderManageLinesExt.KNDO_PAGE_HEADER_SO_STATUS_WARNING_MSG;
        system.assertNotEquals('', KNDO_PAGE_HEADER_SO_STATUS_WARNING_MSG);

        String KNDO_PAGE_HEADER_GENERAL_EXCEPTION_MSG = SalesOrderManageLinesExt.KNDO_PAGE_HEADER_GENERAL_EXCEPTION_MSG;
        system.assertNotEquals('', KNDO_PAGE_HEADER_GENERAL_EXCEPTION_MSG);

        //get Segment Line field list
        GridRelatedListController.GridRelatedListConfig segmentLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        segmentLinesConfig.uniqueId = 'SegmentLinesGrid';
        segmentLinesConfig.objectName = 'Accounting_Default__c';
        String segmentFieldList = KSE.getSegmentLinesFieldList(soLineFieldList, segmentLinesConfig);
        system.assertNotEquals('', segmentFieldList);

        JsonResult result = SalesOrderManageLinesExt.getSalesOrderLines(soManageLines.salesOrderLinesConfig, soManageLines.theSalesOrder.id,(List<String>) JSON.deserialize(soManageLines.getAllFields(), List<String>.class),'2');
        List<SalesOrderManageLinesExt.SOLineWrapper> soLineWrappers = (List<SalesOrderManageLinesExt.SOLineWrapper>)result.records;

        system.assertEquals(soLineWrappers.size(), sols.size());

        List<String> dateFields = new List<String>();
        dateFields.add('Required_Date__c');

        //Test fetchAvailableInventory
        result = SalesOrderManageLinesExt.fetchAvailableInventory(soLineWrappers, dateFields);

        soLineWrappers = (List<SalesOrderManageLinesExt.SOLineWrapper>)result.records;

        system.assertEquals(null, soLineWrappers[0].soLine.Available_Inventory__c);


        Test.stopTest();

	}

	/**
	 *	testGetSalesOrderLineDetails method tests the getSalesOrderLineDetailsFromUPC and getSalesOrderLineDetailsFromProduct methods 
	 *  under SalesOrderManageLinesExt class
	 */
	public static testmethod void testGetSalesOrderLineDetails() {

		TestFuel testData = new TestFuel();
		Sales_Order__c salesOrder = testData.salesOrder;
		ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
		SalesOrderManageLinesExt soManageLines = new SalesOrderManageLinesExt(con);

		Test.startTest();

		List<Sales_Order_Line__c> sols = testData.salesOrderLines;

		JsonResult result = SalesOrderManageLinesExt.getSalesOrderLineDetailsFromUPC(testData.product.UPC_Code__c,
																					 sols[0],
                                                                                     null, 
																					 salesOrder.id, null);
		system.assertEquals(true, result.success);

		JsonResult productResult = SalesOrderManageLinesExt.getSalesOrderLineDetailsFromProduct( testData.product.id, 
                                                                                                 sols[0],
                                                                                                 null,
																							     salesOrder.id, null);
		system.assertEquals(true, productResult.success);
        JsonResult productRefresult = SalesOrderManageLinesExt.getSalesOrderLineDetailsFromProductCrossRef(testData.crossRef.Id, 
                                                                                     sols[0],
                                                                                     null, 
                                                                                     salesOrder.id, null);
        system.assertEquals(true, result.success);

		//Update product to have UPC code and primary flag checked
		salesOrder.Customer__c = testData.customerSoldTo.Id;
        
        update testData.salesOrder;
		testData.product.Primary__c = true;
		testData.product.Pricebook_Line_Required__c = true;

		update testData.product;

		//Query updated Sales Order
		Sales_Order__c updatedSO = [Select id, Pricebook__c, customer__c, Customer__r.Pricebook__c from Sales_Order__c where id = :testData.salesOrder.Id];

		JsonResult upcresult = SalesOrderManageLinesExt.getSalesOrderLineDetailsFromUPC(testData.product.UPC_Code__c, 
                                                                                        sols[0],
																						null, 
																						updatedSO.id, null);

		system.assertEquals(true, upcresult.success);
		
		JsonResult productResultPostUpdate = SalesOrderManageLinesExt.getSalesOrderLineDetailsFromProduct(testData.product.id, 
            sols[0],
																							              null, 
																							              updatedSO.id, null);
		system.assertEquals(true, productResultPostUpdate.success);

        JsonResult productRefResultPostUpdate = SalesOrderManageLinesExt.getSalesOrderLineDetailsFromProductCrossRef(testData.crossRef.id, 
            sols[0],
                                                                                                          null, 
                                                                                                          updatedSO.id, null);
        system.assertEquals(true, productRefResultPostUpdate.success);

		//Quantity Order factor while fetching Lines details from UPC coce
		testData.customerSoldTo.Order_Quantity_Factor_At__c = 'Layer';

		update testData.customerSoldTo;
		testData.product.Units_per_Layer__c = 10;
		testData.product.Layers_per_Pallet__c = 10;

		JsonResult upcresultQtyFactorLayer = SalesOrderManageLinesExt.getSalesOrderLineDetailsFromUPC(testData.product.UPC_Code__c, 
            sols[0],
            																						 null, 
            																						 updatedSO.id, null);

		system.assertEquals(true, upcresultQtyFactorLayer.success);

		//Quantity Order factor while fetching Lines details from UPC coce
		testData.customerSoldTo.Order_Quantity_Factor_At__c = 'Pallet';

		update testData.customerSoldTo;
		testData.product.Units_per_Layer__c = 10;
		testData.product.Layers_per_Pallet__c = 10;

		JsonResult upcresultQtyFactorPallet = SalesOrderManageLinesExt.getSalesOrderLineDetailsFromUPC(testData.product.UPC_Code__c, 
            sols[0],
                																					   null, 
                																					   updatedSO.id, null);

		system.assertEquals(true, upcresultQtyFactorPallet.success);

		Test.stopTest();

	}

	/**
	 *	testAddModifySoLine method tests the saveSalesOrderLines by creating new lines, editing, 
	 *  cancelling and deleting existing lines
	 *
	 */
	public static testmethod void testAddModifySoLine() {

		TestFuel testData = new TestFuel();
		Sales_Order__c salesOrder = testData.salesOrder;
		List<Sales_Order_Line__c> sols = testData.salesOrderLines;
		salesOrder.Company__r = testData.company;
		update salesOrder;
		ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderManageLinesExt soManageLines = new SalesOrderManageLinesExt(con);

        List<String> dateFields = new List<String>();
        dateFields.add('Required_Date__c');

        List<SalesOrderManageLinesExt.SOLineWrapper> newSoLineWrappers = new List<SalesOrderManageLinesExt.SOLineWrapper>();
        List<SalesOrderManageLinesExt.SOLineWrapper> editSoLineWrappers = new List<SalesOrderManageLinesExt.SOLineWrapper>();
        List<SalesOrderManageLinesExt.SOLineWrapper> deleteSoLineWrappers = new List<SalesOrderManageLinesExt.SOLineWrapper>();
        List<SalesOrderManageLinesExt.SOLineWrapper> cancelSoLineWrappers = new List<SalesOrderManageLinesExt.SOLineWrapper>();

        //** Insert Line error case Start **//
        SalesOrderManageLinesExt.SOLineWrapper newSoLineWrapper1 = new SalesOrderManageLinesExt.SOLineWrapper();

        newSoLineWrapper1.soLine.Product__c = testData.product.Id;
        newSoLineWrapper1.soLine.Line__c = 4;
        newSoLineWrapper1.rowGUID = '1';

        newSoLineWrappers.add(newSoLineWrapper1);

        JsonResult singleInsertResultError = SalesOrderManageLinesExt.saveSalesOrderLines(salesOrder, dateFields, editSoLineWrappers, newSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));
               
        system.assertEquals(false, singleInsertResultError.success);

        //Clear all the elements from the new line
        newSoLineWrappers.clear();
        //** Insert Line error case End **//

        //** Insert Exception case Start **//
        testData.customerSoldTo.Order_Quantity_Factor_At__c = 'Layer';
		testData.product.Units_per_Layer__c = 10;
        testData.product.Layers_per_Pallet__c = 10;

        //Update customer and product to prepare data for SO Line exception
		update testData.customerSoldTo;
        update testData.product;

        SalesOrderManageLinesExt.SOLineWrapper newSoLineWrapperQtyException = new SalesOrderManageLinesExt.SOLineWrapper();
        newSoLineWrapperQtyException.soLine.Line__c = 5;
        newSoLineWrapperQtyException.rowGUID = '100';
        newSoLineWrapperQtyException.soLine.Product__c = testData.product.Id;
        newSoLineWrapperQtyException.soLine.Quantity_Ordered__c = 129.00;
		newSoLineWrapperQtyException.soLine.Unit_Price__c = 10.00;

        newSoLineWrappers.add(newSoLineWrapperQtyException);

        Test.startTest();

        JsonResult singleInsertResultException = SalesOrderManageLinesExt.saveSalesOrderLines(salesOrder, dateFields, editSoLineWrappers, newSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));
               
        system.assertEquals(true, singleInsertResultException.success);

        JsonResult soLineWrappersAfterInsertException = SalesOrderManageLinesExt.getSalesOrderLines(soManageLines.salesOrderLinesConfig, soManageLines.theSalesOrder.id,(List<String>) JSON.deserialize(soManageLines.getAllFields(), List<String>.class),'2');
        List<SalesOrderManageLinesExt.SOLineWrapper> soLineWrappers = (List<SalesOrderManageLinesExt.SOLineWrapper>)soLineWrappersAfterInsertException.records;
        
        system.assertEquals(soLineWrappers.size(), sols.size() + 1);

        //delete inserted row
        for(SalesOrderManageLinesExt.SOLineWrapper soLineWrapper: soLineWrappers) {
        	if(soLineWrapper.soLine.Quantity_Ordered__c ==  129.000000){
        		deleteSoLineWrappers.add(soLineWrapper);
           		break;

        	}
           		
        }

	   	system.assertEquals(1, deleteSoLineWrappers.size());

	   	JsonResult deleteResultSuccess = SalesOrderManageLinesExt.deleteSalesOrderLines(deleteSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));

	   	//Clear List
	   	deleteSoLineWrappers.clear();
        system.assertEquals(true, deleteResultSuccess.success);

        //Clear all the elements from the new line
        newSoLineWrappers.clear();
        //** Insert Exception case End **//

        //** Insert Line success case Start **//
        //Correct all errors and recreate the line
        SalesOrderManageLinesExt.SOLineWrapper newSoLineWrapper2 = new SalesOrderManageLinesExt.SOLineWrapper();
        newSoLineWrapper2.rowGUID = '1';
        newSoLineWrapper2.soLine.Line__c = 8;
        newSoLineWrapper2.soLine.Product__c = testData.product.Id;
        newSoLineWrapper2.soLine.Quantity_Ordered__c = 10;
		newSoLineWrapper2.soLine.Unit_Price__c = 10.00;

        newSoLineWrappers.add(newSoLineWrapper2);

        //Save lines
        JsonResult singleInsertResultSuccess = SalesOrderManageLinesExt.saveSalesOrderLines(salesOrder, dateFields, editSoLineWrappers, newSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));
               
        system.assertEquals(true, singleInsertResultSuccess.success);

        JsonResult result = SalesOrderManageLinesExt.getSalesOrderLines(soManageLines.salesOrderLinesConfig, soManageLines.theSalesOrder.id,(List<String>) JSON.deserialize(soManageLines.getAllFields(), List<String>.class),'2');
        List<SalesOrderManageLinesExt.SOLineWrapper> soLineWrappers1 = (List<SalesOrderManageLinesExt.SOLineWrapper>)result.records;


        system.assertEquals(soLineWrappers1.size(), sols.size() + 1);

        newSoLineWrappers.clear();
        //** Insert Line success case End **//

        //** Edit Line success case Start **//
        //Edit So Lines
		for(SalesOrderManageLinesExt.SOLineWrapper soLineWrapper: soLineWrappers1) {
           soLineWrapper.soLine.Quantity_Ordered__c = 200;
        }

        JsonResult singleEditResultSuccess = SalesOrderManageLinesExt.saveSalesOrderLines(salesOrder, dateFields, soLineWrappers1, newSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));

        JsonResult resultAfterUpdateSuccess = SalesOrderManageLinesExt.getSalesOrderLines(soManageLines.salesOrderLinesConfig, soManageLines.theSalesOrder.id,(List<String>) JSON.deserialize(soManageLines.getAllFields(), List<String>.class),'2');
        List<SalesOrderManageLinesExt.SOLineWrapper> soLineWrappersAfterUpdateSuccess = (List<SalesOrderManageLinesExt.SOLineWrapper>)resultAfterUpdateSuccess.records;

        system.assertEquals(true, singleEditResultSuccess.success);

        newSoLineWrappers.clear();

        //** Edit Line success case End **//

        //** Edit Line error case Start **//
        //Edit So Lines
		for(SalesOrderManageLinesExt.SOLineWrapper soLineWrapper: soLineWrappers) {
           soLineWrapper.soLine.Unit_Price__c = null;
        }

        JsonResult singleEditResultError = SalesOrderManageLinesExt.saveSalesOrderLines(salesOrder, dateFields, soLineWrappers, newSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));

        JsonResult resultAfterUpdateError = SalesOrderManageLinesExt.getSalesOrderLines(soManageLines.salesOrderLinesConfig, soManageLines.theSalesOrder.id,(List<String>) JSON.deserialize(soManageLines.getAllFields(), List<String>.class),'2');
        List<SalesOrderManageLinesExt.SOLineWrapper> soLineWrappersAfterUpdateError = (List<SalesOrderManageLinesExt.SOLineWrapper>)resultAfterUpdateError.records;

        system.assertEquals(false, singleEditResultError.success);

        //** Edit Line error case End **//

        //** Delete Line success case Start **//
        //Delete SO Line
        for(SalesOrderManageLinesExt.SOLineWrapper soLineWrapper: soLineWrappersAfterUpdateError) {
           deleteSoLineWrappers.add(soLineWrapper);
           break;
        }
	   	
	   	JsonResult singleDeleteResultSuccess = SalesOrderManageLinesExt.deleteSalesOrderLines(deleteSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));

        system.assertEquals(true, singleDeleteResultSuccess.success);

        JsonResult resultAfterDeleteSuccess = SalesOrderManageLinesExt.getSalesOrderLines(soManageLines.salesOrderLinesConfig, soManageLines.theSalesOrder.id,(List<String>) JSON.deserialize(soManageLines.getAllFields(), List<String>.class),'2');
        List<SalesOrderManageLinesExt.SOLineWrapper> soLineWrappersAfterDeleteSuccess = (List<SalesOrderManageLinesExt.SOLineWrapper>)resultAfterDeleteSuccess.records;

        system.assertEquals(soLineWrappersAfterDeleteSuccess.size(), sols.size());
        deleteSoLineWrappers.clear();
        //** Delete Line success case End **//

        //** Cancel Line success case Start **//
        //Cancel SO Line
        for(SalesOrderManageLinesExt.SOLineWrapper soLineWrapper: soLineWrappersAfterDeleteSuccess) {
           cancelSoLineWrappers.add(soLineWrapper);
           break;
        }

        JsonResult singleCancelResultSuccess = SalesOrderManageLinesExt.cancelSalesOrderLines(cancelSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));

        system.assertEquals(true, singleCancelResultSuccess.success);

        JsonResult resultAfterCancelSuccess = SalesOrderManageLinesExt.getSalesOrderLines(soManageLines.salesOrderLinesConfig, soManageLines.theSalesOrder.id,(List<String>) JSON.deserialize(soManageLines.getAllFields(), List<String>.class),'2');
        List<SalesOrderManageLinesExt.SOLineWrapper> soLineWrappersAfterCancelSuccess = (List<SalesOrderManageLinesExt.SOLineWrapper>)resultAfterCancelSuccess.records;

		//** Delete Line error case Start **//
        for(SalesOrderManageLinesExt.SOLineWrapper soLineWrapper: soLineWrappersAfterCancelSuccess) {
        	if(soLineWrapper.soLine.Status__c == 'Cancelled'){
        		deleteSoLineWrappers.add(soLineWrapper);
       			break;
        	}
           
        }

        //One cancelled line should be there
        system.assertEquals(deleteSoLineWrappers.size(), 1);

        JsonResult singleDeleteResultError = SalesOrderManageLinesExt.deleteSalesOrderLines(deleteSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));

        system.assertEquals(false, singleDeleteResultError.success);

        //** Delete Line error case End **//

        //** Cancel Line error case Start **//
        JsonResult singleCancelResultError = SalesOrderManageLinesExt.cancelSalesOrderLines(deleteSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));

        system.assertEquals(false, singleCancelResultError.success);

        JsonResult resultAfterCancelError = SalesOrderManageLinesExt.getSalesOrderLines(soManageLines.salesOrderLinesConfig, soManageLines.theSalesOrder.id,(List<String>) JSON.deserialize(soManageLines.getAllFields(), List<String>.class),'2');
        List<SalesOrderManageLinesExt.SOLineWrapper> soLineWrappersAfterCancelError = (List<SalesOrderManageLinesExt.SOLineWrapper>)resultAfterCancelError.records;

        //** Cancel Line error case End **//

        editSoLineWrappers.clear();
        newSoLineWrappers.clear();
        
        //** Insert Line with Segments case Start **//
        for(SalesOrderManageLinesExt.SOLineWrapper soLineWrapper: soLineWrappersAfterCancelError) {
        	if(soLineWrapper.soLine.Status__c != 'Cancelled'){
        		Accounting_Default__c ad = new Accounting_Default__c();
        		ad.Company__c = testData.company.Id;
        		ad.GL_Account__c = testData.cashGL.Id;
        		soLineWrapper.segments = ad;
        		editSoLineWrappers.add(soLineWrapper);
       			break;
        	}
           
        }

        //Test segments
        JsonResult singleEditSegmentResultSuccess = SalesOrderManageLinesExt.saveSalesOrderLines(salesOrder, dateFields, editSoLineWrappers, newSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));

        system.assertEquals(true, singleEditSegmentResultSuccess.success);

        JsonResult resultAfterEditSegmentResultSuccess = SalesOrderManageLinesExt.getSalesOrderLines(soManageLines.salesOrderLinesConfig, soManageLines.theSalesOrder.id,(List<String>) JSON.deserialize(soManageLines.getAllFields(), List<String>.class),'2');
        List<SalesOrderManageLinesExt.SOLineWrapper> soLineWrappersAfterEditSegmentResultSuccess = (List<SalesOrderManageLinesExt.SOLineWrapper>)resultAfterEditSegmentResultSuccess.records;

        //** Insert Line with Segments case End **//

        //** SO error case start **//

        cancelSoLineWrappers.clear();

        for(SalesOrderManageLinesExt.SOLineWrapper soLineWrapper: soLineWrappersAfterEditSegmentResultSuccess) {
        	if(soLineWrapper.soLine.Status__c != 'Cancelled' && soLineWrapper.soLine.Status__c != 'Closed'){
        		cancelSoLineWrappers.add(soLineWrapper);
        	}
		}
        
		//Cancel all lines which will cancel the SO
		JsonResult cancelAllLinesResult = SalesOrderManageLinesExt.cancelSalesOrderLines(cancelSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));
        
        system.assertEquals(true, cancelAllLinesResult.success);

        Test.StopTest();
        Sales_Order__c cancelledSalesOrder = [Select Id, name, Status__c from Sales_Order__c where id = :salesOrder.Id];
        //system.assertEquals('Cancelled', cancelledSalesOrder.Status__c);
        //Try to edit a line
        JsonResult editCancelledSO = SalesOrderManageLinesExt.saveSalesOrderLines(salesOrder, dateFields, editSoLineWrappers, newSoLineWrappers, dateFields, JSON.serialize(cancelledSalesOrder));

        system.assertEquals(false, editCancelledSO.success);

        //** SO error case End **//

	}
	/**
	 *	testValidateProductReference method validates the inactive / invalid Product Reference on the sol on save
	 *
	 */
	public static testMethod void testValidateProductReference() {
        TestFuel testData = new TestFuel();
        Sales_Order__c salesOrder = testData.salesOrder;
        // update the crosReference to test the sol exception with inactive product reference value
        Cross_Reference__c cr = new Cross_Reference__c();
        cr.Name = 'CR00';
        cr.Cross_Reference_Type__c = 'Customer';
        cr.Reference_Object__c = 'Product';
        cr.Active__c = false;
        cr.Customer__c = testData.customerParent.Id;
        cr.Product__c = testData.product.Id; 
        insert cr;
        
        List<Sales_Order_Line__c>sols = testData.salesOrderLines;

        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderManageLinesExt soManageLines = new SalesOrderManageLinesExt(con);
        
        test.StartTest();
        List<String> dateFields = new List<String>();
        dateFields.add('Required_Date__c');

        List<SalesOrderManageLinesExt.SOLineWrapper> newSoLineWrappers = new List<SalesOrderManageLinesExt.SOLineWrapper>();
        List<SalesOrderManageLinesExt.SOLineWrapper> editSoLineWrappers = new List<SalesOrderManageLinesExt.SOLineWrapper>();

        SalesOrderManageLinesExt.SOLineWrapper newSoLineWrapper1 = new SalesOrderManageLinesExt.SOLineWrapper();
        newSoLineWrapper1.soLine.Line__c = 10;
        newSoLineWrapper1.rowGUID = '199';
        newSoLineWrapper1.soLine.Product__c = testData.product.Id;
        newSoLineWrapper1.soLine.Product_Reference__c = cr.id;
        newSoLineWrapper1.soLine.Quantity_Ordered__c = 12.00;
        newSoLineWrapper1.soLine.Unit_Price__c = 10.00;

        newSoLineWrappers.add(newSoLineWrapper1);

        JsonResult resultLineException = SalesOrderManageLinesExt.saveSalesOrderLines(salesOrder, dateFields, editSoLineWrappers, newSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));
        
        system.assert(resultLineException.success == false, '<<<LineException>>>>' + resultLineException);
    
    }

    /**
     *  testSoLineAllowamceMethods method tests the Sales Order lines allowances related methods
     *
     */
    public static testmethod void testSoLineAllowamceMethods() {

        TestFuel testData = new TestFuel();
        Sales_Order__c salesOrder = testData.salesOrder;
        List<Sales_Order_Line__c> sols = testData.salesOrderLines;
		for (Sales_Order_Line__c sol: sols){
			sol.Sales_Order__r = salesOrder;
		}

        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderManageLinesExt soManageLines = new SalesOrderManageLinesExt(con);

        String soLineAllowancesHeaderFields = soManageLines.getSOLineHeaderFieldList();

        System.assertNotEquals(null, soLineAllowancesHeaderFields, 'So Line Allowances Header fields cannot be null');

        //Insert allowances
        Allowance_Type__c autoAllowance = new Allowance_Type__c(Name = '10 $ Flat off',
                                                                Basis__c = AllowanceRuleService.BASIS_FLAT_AMOUNT, // 'Flat Amount',
                                                                Amount__c = 10.00,
                                                                Apply_At_Header__c = false,
                                                                Type__c = AllowanceRuleService.TYPE_CHARGE,
                                                                Manual__c = true,
                                                                Currency__c = TestFuel.currencyUSD.ID);

       
        insert autoAllowance;

        System.assert(true, 'Allowance Type created successfully');
      
        //Insert Allowance Rule
        Allowance_Rule__c ar = new Allowance_Rule__c(Name = '10$ off on header ', 
                                 Allowance_Type__c = autoAllowance.Id,
                                 Start_Date__c = System.today(),
                                 End_Date__c = system.today() + 4);     
        
        insert ar;
        System.assert(true, 'Allowance Rule created successfully');

        AllowanceService.validateAndApplyAllowances(
            new Map<Id, Sales_Order__c>{salesOrder.id => salesOrder},
            new Map<Id, List<Sales_Order_Line__c>>{salesOrder.id => sols},
            null, null
        );

        Sales_Order__c sOrder = [Select Id, Name, Allowances__c, Pricing_Date__c, Order_Total__c
                                   from Sales_Order__c
                                  where Id = :salesOrder.Id];

        
        Sales_Order_Line__c soLine = [Select Id, Name, Product__c , Allowances__c, Unit_Price__c, Pricebook__c, Pricebook_Line__c
                                               from Sales_Order_Line__c
                                              where Sales_Order__c = :salesOrder.Id
                                              Limit 1];

		system.assert(soLine.Pricebook__c != null,soLine);
		system.assert(soLine.Pricebook_Line__c != null, soLine);

        //Fetch the list of Allowance Rules Id
        //List<SelectListItem> selectListItems = SalesOrderManageLinesExt.fetchAllowanceTypes(sols[0].Id);
        Allowance_Rule__c allowanceRule = (Allowance_Rule__c) SalesOrderManageLinesExt.fetchAllowanceRuleTypes(sols[0].Id).records[0];

        //System.assertNotEquals(0, allowanceTypes.records.size(), 'Selected List Items should return manual allowance : ' + allowanceTypes.records);

        JSONResult allowanceData = SalesOrderManageLinesExt.fetchAllowance(  allowanceRule.Id, soLine.Id, null);

        List<Allowance_Applied__c> aa = (List<Allowance_Applied__c>) allowanceData.records;
        System.assertEquals(10, Integer.valueOf(aa[0].Allowance_Amount__c), 'Allowance amount mis match: ' + aa[0].Allowance_Amount__c);

        JSONResult soLineHeader = SalesOrderManageLinesExt.getSOLineHeaderDetails(sols[0].Id);

        System.assertNotEquals(null, soLineHeader, 'Header details ' + soLineHeader);
    }
    public static testmethod void testReqLPOLCancelwithSOLCancel() {
    	
    	TestFuel testData = new TestFuel();
    	Sales_Order__c salesOrder = testData.salesOrder;
    	
        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderManageLinesExt soManageLines = new SalesOrderManageLinesExt(con);
        
        Test.startTest();
        
        List<String> dateFields = new List<String>();
        dateFields.add('Required_Date__c');
        
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();{
	    	salesOrderLine.Company__c = testData.company.Id;
	    	salesOrderLine.Description__c = testData.product3.Description__c;
	    	salesOrderLine.Discount_Percent__c = 2;
	    	salesOrderLine.Product__c = testData.product.Id;
	    	salesOrderLine.Quantity_Ordered__c = 100;
	    	salesOrderLine.Required_Date__c = System.today()+5;
	    	salesOrderLine.Sales_Order__c = testData.salesOrder.Id;
	    	salesOrderLine.Ship_From_Location__c = testData.location2.Id;
	    	salesOrderLine.Unit_Price__c = 11.12;
	    	salesOrderLine.Memo__c = 'salesOrderLine';
        }     
        List<Sales_Order_Line__c> soLineList = new List<Sales_Order_Line__c>();{
            soLineList.add(salesOrderLine);
            insert soLineList;
        } 
	    Requisition__c req = new Requisition__c();{
        	req.Company__c = testData.company.id;
        	req.Source__c = 'Drop Ship';
        	req.Type__c = 'Purchase Requisition';
        	req.Status__c = 'Open';
        	req.Approval_Status__c = 'Approved';
            req.Currency__c = TestFuel.currencyUSD.id;
        }
        List<Requisition__c> reqList = new List<Requisition__c>();{
        	reqList.add(req);
        	insert reqList;
        }
        Requisition_Line__c reqLine = new Requisition_Line__c();{
        	reqLine.Item__c = testData.itemList[5].id;
        	reqLine.Purchasing_UOM__c = testData.uomList[8].Id; 
        	reqLine.Facility__c = testData.facility.id;
        	reqLine.Quantity_Ordered__c = 100;
        	reqLine.Unit_Price__c = 1;
        	reqLine.Need_Date__c = system.today();
        	reqLine.Quantity_Released__c = 100;
        	reqLine.Requisition__c = req.id;
        	reqLine.Sales_Order_Line__c = salesOrderLine.id;
        	reqLine.Status__c = 'Closed';	
        }
        List<Requisition_Line__c> reqLineList = new List<Requisition_Line__c>();{
        	reqLineList.add(reqLine);
        	insert reqLineList;
        }
        Purchase_Order__c po = new Purchase_Order__c();{
        	po.Supplier__c = testData.supplier.id; 
        	po.Company__c = testData.company.id;
        	po.Payment_Term__c = testData.terms.id;
    		po.Delivery_Facility__c = testData.facility2.id;
    		po.Delivery_Location__c = testData.location2.ID;
    		po.Remit_To_Supplier__c = testData.remitToSupplier.id;								        
    		po.Approval_Status__c = 'Approved';
    		po.Type__c = 'Drop Ship';								        
    		po.fob_term__c = testData.fobTerm.id;								        
    		po.Status__c = 'Open';								        
    		po.Memo__c = 'purchaseOrder';	
    		po.Currency__c = TestFuel.currencyUSD.id;							        
        }
        List<Purchase_Order__c> poList = new List<Purchase_Order__c>();{
        	poList.add(po);
        	insert poList;
        }
        Purchase_Order_Line__c pol = new Purchase_Order_Line__c();{
            pol.Purchase_Order__c = po.Id;
            pol.Order_Quantity__c = 10;     
            pol.Unit_Price__c = 12;
            pol.Status__c = 'Open';
            pol.Item__c = testData.itemList[5].Id;
            pol.Description__c = testData.itemList[5].Description__c;
            pol.Purchase_UOM__c = testData.itemList[5].Purchasing_UOM__c;
            pol.Company__c = testData.company.id;
            pol.Need_Date__c = system.today() + 7;
            pol.Delivery_Facility__c = testData.facility2.id;
            pol.Delivery_Location__c = testData.location2.ID;
            pol.Supplier__c = testData.supplier.Id;
            pol.Line__c = 1;
            pol.Quantity_Matched__c = 0;
            pol.Amount_Matched__c = 0;
        }
        List<Purchase_Order_Line__c>polList = new List<Purchase_Order_Line__c>();{
        	polList.add(pol);
        	insert polList;
        }
        Requisition_Cross_Reference__c rcf = new Requisition_Cross_Reference__c();{
        	rcf.Purchase_Order_Line__c  = pol.id;
        	rcf.Requisition_Line__c  = reqLine.id; 
        }
        List<Requisition_Cross_Reference__c>rcfList = new List<Requisition_Cross_Reference__c>();{
        	rcfList.add(rcf);
        	insert rcfList;
        }
        List<SalesOrderManageLinesExt.SOLineWrapper> cancelSoLineWrappers = new List<SalesOrderManageLinesExt.SOLineWrapper>();
        
        JsonResult resultAfterCancelSuccess = SalesOrderManageLinesExt.getSalesOrderLines(soManageLines.salesOrderLinesConfig, soManageLines.theSalesOrder.id,(List<String>) JSON.deserialize(soManageLines.getAllFields(), List<String>.class),'2');
        List<SalesOrderManageLinesExt.SOLineWrapper> soLineWrappersAfterCancelSuccess = (List<SalesOrderManageLinesExt.SOLineWrapper>)resultAfterCancelSuccess.records;
        
        for(SalesOrderManageLinesExt.SOLineWrapper soLineWrapper : soLineWrappersAfterCancelSuccess){
        	cancelSoLineWrappers.add(soLineWrapper);    
        }

        JsonResult cancelLineResult = SalesOrderManageLinesExt.cancelSalesOrderLines(cancelSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));
    	system.assertEquals(true, cancelLineResult.success );
        
        Sales_Order__c cancelledSalesOrder = [Select Id, name, Status__c from Sales_Order__c where id = :salesOrder.Id];
        system.assertEquals('Cancelled', cancelledSalesOrder.Status__c);
    	
        Requisition_Line__c	closedReqLine = [Select Id, name, Status__c from Requisition_Line__c where id =:reqLine.Id ];
        system.assertEquals('Closed', closedReqLine.Status__c);
    	
        Purchase_Order_Line__c cancelledPoLine = [Select Id, name, Status__c from Purchase_Order_Line__c where id = :pol.Id]; 
    	system.assertEquals('Cancelled', cancelledPoLine.Status__c);								
        test.stopTest();
    }
    public static testMethod void testdropShipSolShortClose(){
        TestFuel testData = new TestFuel();
        testData.product.Pricebook_Line_Required__c = true;
        update testData.product;

        Sales_Order__c so = new Sales_Order__c();
        so.Ship_to__c = testData.customerShipTo.Id;
        so.Bill_To__c = testData.customerBillTo.Id;
        so.Customer__c = testData.customerSoldTo.Id;
        so.Currency__c = TestFuel.currencyUSD.id;
        so.Payment_Term__c = testData.terms.id;
        so.company__c = testData.company.id;
        so.Status__c = 'Open';
        insert so;

        ApexPages.StandardController con = new ApexPages.StandardController(so);
        SalesOrderManageLinesExt manageLinesExt = new SalesOrderManageLinesExt(con);
       
        List<String> dateFields = new List<String>();
        dateFields.add('Required_Date__c');
        List<SalesOrderManageLinesExt.SOLineWrapper> newSoLineWrappers = new List<SalesOrderManageLinesExt.SOLineWrapper>();
        List<SalesOrderManageLinesExt.SOLineWrapper> editSoLineWrappers = new List<SalesOrderManageLinesExt.SOLineWrapper>();

        SalesOrderManageLinesExt.SOLineWrapper newSoLineWrapper = new SalesOrderManageLinesExt.SOLineWrapper();
        newSoLineWrapper.soLine.Product__c = testData.product.Id;
        newSoLineWrapper.soLine.Line__c = 10;
        newSoLineWrapper.soLine.Quantity_Ordered__c = 155;
        newSoLineWrapper.rowGUID = '12232323';
        newSoLineWrapper.soLine.Status__c = 'Open';
        newSoLineWrapper.soLine.Fulfillment_Source__c = 'Drop Ship';
        newSoLineWrapper.soLine.Selling_UOM__c = testData.uomList[8].id;
        newSoLineWrapper.soLine.Unit_Price__c = 11.12;

        newSoLineWrappers.add(newSoLineWrapper);
        JsonResult InsertResult = SalesOrderManageLinesExt.saveSalesOrderLines(so, dateFields,editSoLineWrappers, newSoLineWrappers, dateFields, JSON.serialize(manageLinesExt.theSalesOrder));
        system.assert(InsertResult.success == true, InsertResult);
        Sales_Order_Line__c sol = [select id, Quantity_Ordered__c, Sales_Order__c, Sales_Order__r.id, Sales_Order__r.Status__c, Sales_Order__r.Weight_UOM__c, Quantity_Shipped__c, Status__c, Sales_Order__r.Type__c from Sales_Order_Line__c where Sales_Order__c =:so.id];
    
        Requisition__c req = new Requisition__c();{
            req.Company__c = testData.company.id;
            req.Source__c = 'Drop Ship';
            req.Type__c = 'Purchase Requisition';
            req.Status__c = 'Open';
            req.Approval_Status__c = 'Approved';
            req.Currency__c = TestFuel.currencyUSD.id;
        }
        List<Requisition__c> reqList = new List<Requisition__c>();{
            reqList.add(req);
            insert reqList;
        }
        Requisition_Line__c reqLine = new Requisition_Line__c();{
            reqLine.Item__c = testData.itemList[5].id;
            reqLine.Purchasing_UOM__c = testData.uomList[8].Id; 
            reqLine.Facility__c = testData.facility.id;
            reqLine.Quantity_Ordered__c = 15;
            reqLine.Unit_Price__c = 1;
            reqLine.Need_Date__c = system.today();
            reqLine.Quantity_Released__c = 100;
            reqLine.Requisition__c = req.id;
            reqLine.Sales_Order_Line__c = sol.id;
            reqLine.Status__c = 'Closed';   
        }
        List<Requisition_Line__c> reqLineList = new List<Requisition_Line__c>();{
            reqLineList.add(reqLine);
            insert reqLineList;
        }
        Purchase_Order__c po = new Purchase_Order__c();{
            po.Supplier__c = testData.supplier.id; 
            po.Company__c = testData.company.id;
            po.Payment_Term__c = testData.terms.id;
            po.Delivery_Facility__c = testData.facility2.id;
            po.Delivery_Location__c = testData.location2.ID;
            po.Remit_To_Supplier__c = testData.remitToSupplier.id;                                     
            po.Approval_Status__c = 'Approved';
            po.Type__c = 'Drop Ship';                                       
            po.fob_term__c = testData.fobTerm.id;                                       
            po.Status__c = 'Open';                                      
            po.Memo__c = 'purchaseOrder';   
            po.Currency__c = TestFuel.currencyUSD.id;                                   
        }
        List<Purchase_Order__c> poList = new List<Purchase_Order__c>();{
            poList.add(po);
            insert poList;
        }
        Purchase_Order_Line__c pol = new Purchase_Order_Line__c();{
            pol.Purchase_Order__c = po.Id;
            pol.Order_Quantity__c = 15;     
            pol.Unit_Price__c = 12;
            pol.Status__c = 'Open';
            pol.Item__c = testData.itemList[5].Id;
            pol.Description__c = testData.itemList[5].Description__c;
            pol.Purchase_UOM__c = testData.itemList[5].Purchasing_UOM__c;
            pol.Company__c = testData.company.id;
            pol.Need_Date__c = system.today() + 7;
            pol.Delivery_Facility__c = testData.facility2.id;
            pol.Delivery_Location__c = testData.location2.ID;
            pol.Supplier__c = testData.supplier.Id;
            pol.Line__c = 1;
            pol.Quantity_Matched__c = 0;
            pol.Amount_Matched__c = 0;
        }
        List<Purchase_Order_Line__c>polList = new List<Purchase_Order_Line__c>();{
            polList.add(pol);
            insert polList;
        }
        Requisition_Cross_Reference__c rcf = new Requisition_Cross_Reference__c();{
            rcf.Purchase_Order_Line__c  = pol.id;
            rcf.Requisition_Line__c  = reqLine.id; 
        }
        List<Requisition_Cross_Reference__c>rcfList = new List<Requisition_Cross_Reference__c>();{
            rcfList.add(rcf);
            insert rcfList;
        }
        ASN__c asn = new ASN__c();{
            asn.Company__c = testData.company.id;
            asn.Supplier__c = testData.supplier.id;
            asn.Facility__c = testData.facility2.id;
            asn.FOB__c = testData.fobTerm.id;
            asn.Status__c = 'Confirmed';
            asn.Transaction_Date__c = system.today();
            asn.Currency__c = TestFuel.currencyUSD.id;
            asn.Transaction_Type__c = 'Purchase Order ASN';
            insert asn;
        }

        ASN_Line__c asnLine = new ASN_Line__c();{
            asnLine.Purchase_Order__c = po.id;
            asnLine.Purchase_Order_Line__c = pol.id;
            asnLine.Item__c = testData.itemList[5].Id;
            asnLine.Item__r = testData.itemList[5];
            asnLine.Quantity_Shipped__c = 10;
            asnLine.Quantity_Received__c = 10;
            asnLine.Unit_Price__c = 12;
            asnLine.Status__c = 'Closed';
            asnLine.ASN__c = asn.id;
            asnLine.ASN__r = asn;
            asnLine.Company__c = testData.company.id;
            asnLine.Supplier__c = testData.supplier.id;
            asnLine.Is_Changed__c = true;
            insert asnLine;

        }
       
        ASN__c newASN = new ASN__c();{
            newASN.Company__c = testData.company.id;
            newASN.Supplier__c = testData.supplier.id;
            newASN.Facility__c = testData.facility2.id;
            newASN.FOB__c = testData.fobTerm.id;
            newASN.Status__c = 'Draft';
            newASN.Transaction_Date__c = system.today();
            newASN.Currency__c = TestFuel.currencyUSD.id;
            newASN.Transaction_Type__c = 'Purchase Order ASN';
            insert newASN;
        }

        ASN_Line__c newAsnLine = new ASN_Line__c();{
            newAsnLine.Purchase_Order__c = po.id;
            newAsnLine.Purchase_Order_Line__c = pol.id;
            newAsnLine.Item__c = testData.itemList[5].Id;
            newAsnLine.Item__r = testData.itemList[5];
            newAsnLine.Quantity_Shipped__c = 5;
            newAsnLine.Quantity_Received__c = 0;
            newAsnLine.Unit_Price__c = 11.12;
            newAsnLine.Status__c = 'New';
            newAsnLine.ASN__c = newASN.id;
            newAsnLine.ASN__r = newASN;
            newAsnLine.Company__c = testData.company.id;
            newAsnLine.Supplier__c = testData.supplier.id;
            newAsnLine.Is_Changed__c = true;
            insert newAsnLine;

        }
        test.StartTest();
        sol.Quantity_Shipped__c = 10;
        update sol;
        polList[0].Quantity_Received__c = 10;
        update polList[0];
        
        ApexPages.Standardcontroller con1 = new ApexPages.Standardcontroller(sol.Sales_Order__r);
        SalesOrderManageLinesExt soManageLines = new SalesOrderManageLinesExt(con1);

        List<SalesOrderManageLinesExt.SOLineWrapper> newSoLineWrappers1 = new List<SalesOrderManageLinesExt.SOLineWrapper>();
        JsonResult result = SalesOrderManageLinesExt.getSalesOrderLines(manageLinesExt.salesOrderLinesConfig, manageLinesExt.theSalesOrder.id,(List<String>) JSON.deserialize(manageLinesExt.getAllFields(), List<String>.class),'2');

        List<SalesOrderManageLInesExt.SOLineWrapper> soLineWrappers1 = (List<SalesOrderManageLinesExt.soLineWrapper>)result.records;
        for(SalesOrderManageLinesExt.soLineWrapper soLineWrapper : soLineWrappers1){
            soLineWrapper.soLine.Quantity_Ordered__c = 10;
            soLineWrapper.soLine.Quantity_Change_Reason__c = testData.reasonCodes.get('Change').id;
        }
       
        JsonResult updateResult = SalesOrderManageLinesExt.saveSalesOrderLines(sol.Sales_Order__r, datefields,soLineWrappers1, newSoLineWrappers1, dateFields, JSON.serialize(soManageLines.theSalesOrder));
        system.assert(updateResult.success == true, '<<<result>>>>' + updateResult);
        Sales_Order_Line__c sol1 = [select id, Quantity_Shipped__c, Status__c, Quantity_Ordered__c from Sales_Order_Line__c where Sales_Order__c = :so.id];
        system.assertEquals(sol1.Status__c, 'Closed'); 
        Purchase_Order_Line__c pol1 = [select id, Status__c from Purchase_Order_Line__c where Purchase_Order__c =:po.id];
        system.assert(pol1.Status__c == 'Closed');
        test.StopTest();

    }

    public static testMethod void testCustomerHierarchyPricing(){

        TestFuel testData = new TestFuel();

        //Customer group
        Customer_Group__c custGroup = new Customer_Group__c();
        custGroup.Company__c = testData.company.Id;
        custGroup.Name = 'Test Customer group 1';
        insert custGroup;

        testData.customerSoldTo.Customer_Group__c = custGroup.Id;
        testData.customerSoldTo.Pricebook__c = null;
        update testData.customerSoldTo;

        //Price book
        Pricebook__c chPB = new Pricebook__c();
        chPb.Company__c = testData.company.Id;
        chPb.Currency__c = TestFuel.currencyUSD.Id;
        chPb.Name = 'Customer Hier PB';
        insert chPB;

        Pricebook_Line__c chPBL = new Pricebook_Line__c();
        chPBL.Start_Date__c = System.today();
        chPBL.End_Date__c = System.today() + 10;
        chPBL.Product__c = testData.product.Id;
        chPbl.Price__c = 9000;
        chPbl.Use_Fixed_Pricing__c = true;
        chPBL.Pricebook__c = chPB.Id;
        insert chPBL;

        //Customer hierarchy
        Hierarchy__c custHier = new Hierarchy__c();
        custHier.Name = '';
        custHier.Code__c = String.valueOf(custGroup.Id).substring(0, 15);
        custHier.Top_Parent_Code__c = String.valueOf(custGroup.Id).substring(0, 15);
        custHier.Pricebook__c = chPB.Id;
        custHier.Type__c = 'Customer Hierarchy';

        insert custHier;

        //Update Sales Order
        Sales_Order__c salesOrder = testData.SalesOrder;
        salesOrder.Customer__c = testData.customerSoldTo.Id;
        salesOrder.Currency__c = TestFuel.currencyUSD.Id;
        salesOrder.Price_Determination_Date__c = SalesOrderService.PRICE_DET_ORDER;
        salesOrder.Pricebook__c = null;
        update salesOrder;

        Id soId = salesOrder.Id;
        Id prodId = testData.product.Id;
        //Query Sales Order
        Sales_Order__c theSalesOrder = new Sales_Order__c();
        SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
                'Id','Company__c','Company__r.Use_Warranty_Repairs__c','Customer__r.Pricebook__c','Customer__r.Order_Quantity_Factor_At__c', 'Customer__r.Customer_Group__c','Date_Time_Ordered__c','Dimension_UOM__c',
                'Dimension_UOM__r.Name','Name','Pricebook__c','Pricebook__r.Name','Pricing_Date__c','Price_Determination_Date__c','Required_Date__c',
                'Status__c','Subtotal__c','Ship_From_Location__c','Ship_From_Location__r.Id','Ship_From_Location__r.Name','Type__c','Currency__c',
                'Weight_UOM__c','Weight_UOM__r.Name'
        });
        soql.setWhereClause('Id = :soId');

        theSalesOrder = Database.query(soql.getQuery());

        //Fetch Product information
        Set<String> productQueryFields = new Set<String>{'Id',
                'Name',
                'Description__c',
                'Item__c',
                'Item__r.Name',
                'Item__r.Fulfillment_Source__c',
                'Item_Specification__c',
                'Item_Specification__r.Name',
                'Pricebook_Line_Required__c',
                'Product_Group__c',
                'Selling_UOM__r.Name',
                'Units_per_Layer__c',
                'Units_per_Pallet__c',
                'UPC_Code__c',
                'Invoiceable__c',
                'Item__r.Source__c'};

        SOQLUtil prodSoql = new SOQLUtil('Product__c');
        prodSoql.addFields(productQueryFields);
        prodSoql.setWhereClause('id = :prodId ');


        Product__c productRef = Database.query( prodSoql.getQuery() );

        Sales_Order_Line__c soLine = new Sales_Order_Line__c();
        soLine.Sales_Order__c = soId;
        soLine.Sales_Order__r = theSalesOrder;
        soLine.Line__c = 6;
        soLine.Product__c = testData.product.Id;
        soLine.Product__r = productRef;
        soLine.Ordered_Date_Time__c = System.now();

        Map<String, Pricebook_Line__c> soLinesPrices = PricingService.fetchSOLinesPriceBookInfo(new List<Sales_Order_Line__c>{ soLine });

        System.assert(soLinesPrices.get(soId + '-' + soLine.Line__c).Pricebook__c == chPB.Id, 'Customer hierarchy Pricebook should be picked!');

    }

    public static testMethod void testSOLCancelWithExceptions(){

        TestFuel testData = new TestFuel();
        Sales_Order__c salesOrder = testData.salesOrder;
        List<Sales_Order_Line__c> sols = testData.salesOrderLines;

        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderManageLinesExt soManageLines = new SalesOrderManageLinesExt(con);

        testData.product.Pricebook_line_Required__c = true;
        update testData.product;

        Test.startTest();

        JsonResult result = SalesOrderManageLinesExt.getSalesOrderLines(soManageLines.salesOrderLinesConfig, soManageLines.theSalesOrder.id,(List<String>) JSON.deserialize(soManageLines.getAllFields(), List<String>.class),'2');
        List<SalesOrderManageLinesExt.SOLineWrapper> soLineWrappers = (List<SalesOrderManageLinesExt.SOLineWrapper>)result.records;

        system.assertNotEquals(soLineWrappers.size(), 0); //check if sales order lines exist

        List<String> dateFields = new List<String>();
        dateFields.add('Required_Date__c');

        List<SalesOrderManageLinesExt.SOLineWrapper> editSoLineWrappers = new List<SalesOrderManageLinesExt.SOLineWrapper>();
        List<SalesOrderManageLinesExt.SOLineWrapper> newSoLineWrappers = new List<SalesOrderManageLinesExt.SOLineWrapper>();

        for (SalesOrderManageLinesExt.SOLineWrapper solWrapper : soLineWrappers){
            solWrapper.soLine.Quantity_Ordered__c = 25;
            solWrapper.soLine.Unit_Price__c = 5.25; //change the unit price to make sure there is an error
            editSoLineWrappers.add(solWrapper);
        }

        JsonResult singleInsertResultSuccess = SalesOrderManageLinesExt.saveSalesOrderLines(salesOrder, dateFields, editSoLineWrappers, newSoLineWrappers, dateFields, JSON.serialize(soManageLines.theSalesOrder));

        sols = [select id, name, product__c, product__r.Pricebook_Line_Required__c, Has_Exceptions__c from Sales_Order_Line__c where Sales_Order__c = :salesOrder.id];

        for (Sales_Order_Line__c sol : sols){
            system.assertEquals(sol.Has_Exceptions__c, true); //all lines should have an exception
        }

        //now cancel the lines and check if the exceptions are cleared
        result = SalesOrderManageLinesExt.getSalesOrderLines(soManageLines.salesOrderLinesConfig, soManageLines.theSalesOrder.id,(List<String>) JSON.deserialize(soManageLines.getAllFields(), List<String>.class),'2');
        soLineWrappers = (List<SalesOrderManageLinesExt.SOLineWrapper>)result.records;

        result = SalesOrderManageLinesExt.cancelSalesOrderLines(soLineWrappers,dateFields,JSON.serialize(soManageLines.theSalesOrder));

        sols = [select id, name, product__c, product__r.Pricebook_Line_Required__c, Has_Exceptions__c, Status__c from Sales_Order_Line__c where Sales_Order__c = :salesOrder.id];

        for (Sales_Order_Line__c sol : sols){
            system.assertEquals(sol.Status__c, 'Cancelled');
            system.assertEquals(sol.Has_Exceptions__c, false); //all lines should not have an exception as the lines will be cancelled
        }

        Test.stopTest();
    }
}