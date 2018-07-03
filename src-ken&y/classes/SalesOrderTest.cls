/**
 * @description test methods for SalesOrder, including LinesAddManageExt
 */
@isTest
public with sharing class SalesOrderTest {


    @testSetup // 3 mins to run
    private static void setupfuel() {
        TestFuel dataInit = new TestFuel();
        // initialize necessary data to be queried by TestDataQuery
        system.assert(dataInit.salesOrder != null &&
                      dataInit.product3 != null &&
                      dataInit.periodList != null &&
                      dataInit.smrsList != null &&
                      dataInit.stockMovementRuleList != null &&
                      dataInit.CashGL != null &&
                      dataInit.GLTypeTestData != null &&
                      dataInit.GLAccountTestData != null &&
                      dataInit.clsobj != null &&
                      dataInit.location != null &&
                      dataInit.pricebook != null &&
                      dataInit.uomcList != null
                      //dataInit.skids != null // Manually create skids others some tests will fails
                     );
    }

    static TestFuelQuery fuel = new TestFuelQuery();

    private static sales_Order__c fetchSO( id soid )  {
        return [ Select s.Total_Quantity_Shipped__c, s.Total_Quantity_Ordered__c,
                 s.SystemModstamp, s.Subtotal__c, s.Status__c, s.Ship_Complete__c, s.Quote__c, s.Primary_Contact__c, s.Payment_Term__c,
                 s.OwnerId, s.Order_Total__c, s.Open_Sales_Order_Lines__c, s.Name, s.Required_Date__c,
                 s.Id,  s.Date_Time_Ordered__c, s.Ship_From_Location__c, s.Customer__r.Top_Parent_Customer__c,
                 s.Customer__c, s.Customer_Purchase_Order__c, s.CreatedDate, s.CreatedById, s.Company__c, s.Backorder_Value__c,
                 (Select Id, IsDeleted, Name, Sales_Order__c, Backorder_Value__c, Company__c, Description__c, Discount_Percent__c,
                  Extended_Price__c, Product__c, Line__c, Quantity_Backordered__c, Quantity_Ordered__c, Quantity_Shipped__c,
                  Required_Date__c, Status__c, Unit_Price__c, Accounting_Segment__c, Accounting_Segment__r.GL_Account__c, Ship_From_Location__r.Facility__r.Facility_Identifier__c
                  From Sales_Order_Lines__r)
                 From Sales_Order__c s
                 where s.id = :soid limit 1];
    }

    public static List<SKID__c> fillStock() {

        List<SKID__c> availableSkids = new List<SKID__c>();
        for (Item__c item : fuel.itemList) {
            SKID__c skid = new SKID__c();
            skid.location__c = fuel.location3.id;
            skid.facility2__c = fuel.location3.Facility__c;
            skid.facility2__r = fuel.location3.Facility__r;
            skid.Company__c = fuel.company.id;
            skid.Quantity__c = 200.0;
            skid.Item__c = item.Id;
            skid.Type__c = SKIDService.SKID_TYPE_LOCATION;
            skid.Expiration_Date__c = System.today() + 365;
            availableSkids.add(skid);

            SKID__c skid1 = skid.clone(false, false);
            skid1.location__c = fuel.location5.id;

        }
        insert availableSkids;

        return availableSkids;
    }

    public static Sales_Order__c resaleOrder { 
        get {
            if ( resaleOrder == null  ) {
                resaleOrder = new Sales_Order__c();
                resaleOrder.Company__c = fuel.company.id;
                resaleOrder.Customer__c = fuel.customerSoldTo.id;
                resaleOrder.Ship_To__c = fuel.customerShipTo.Id;
                resaleOrder.Payment_Term__c = fuel.terms.id;
                resaleOrder.Currency__c = fuel.company.Default_Transaction_Currency__c;
                resaleOrder.Ship_to__c = fuel.customerShipTo.Id;
                resaleOrder.Bill_To__c = fuel.customerBillTo.Id;
                resaleOrder.Currency__c = fuel.currencyUSD.Id;
                resaleOrder.Original_Sales_Order__c = 'so124'; 
                resaleOrder.Type__c = SalesOrderService.SO_TYPE_RESALE;
                insert resaleOrder;
                insert resaleOrderLines;
            }
            return resaleOrder;
        }
        set; 
    }
    
    public static List<Sales_Order_Line__c> resaleOrderLines {
        get{
            if(resaleOrderLines == null){
                resaleOrderLines = new List<Sales_Order_Line__c>();
                
                Sales_Order_Line__c resaleOrderLine1 = new Sales_Order_Line__c();
                resaleOrderLine1.Company__c = fuel.company.Id;
                resaleOrderLine1.Description__c = fuel.product.Description__c;
                resaleOrderLine1.Discount_Percent__c = 2;
                resaleOrderLine1.Product__c = fuel.product.Id;
                resaleOrderLine1.Quantity_Ordered__c = 100;
                resaleOrderLine1.Required_Date__c = System.today()+5;
                resaleOrderLine1.Sales_Order__c = resaleOrder.Id;
                resaleOrderLine1.Ship_From_Location__c = fuel.location2.Id;
//                resaleOrderLine1.Ship_From_Facility__c = fuel.location2.Facility__c;
//                resaleOrderLine1.Ship_From_Facility__r = fuel.location2.Facility__r;
                resaleOrderLine1.Unit_Price__c = 11.12;
                resaleOrderLine1.Memo__c = 'Resale Order Line 1';
                resaleOrderLine1.Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_RESALE;
                resaleOrderLine1.End_Customer__c = fuel.customerBillTo.Id;
                resaleOrderLines.add(resaleOrderLine1);
                
                Sales_Order_Line__c resaleOrderLine2 = new Sales_Order_Line__c();
                resaleOrderLine2.Company__c = fuel.company.Id;
                resaleOrderLine2.Description__c = fuel.product2.Description__c;
                resaleOrderLine2.Discount_Percent__c = 2;
                resaleOrderLine2.Product__c = fuel.product2.Id;
                resaleOrderLine2.Quantity_Ordered__c = 15;
                resaleOrderLine2.Required_Date__c = System.today()+15;
                resaleOrderLine2.Sales_Order__c = resaleOrder.Id;
                resaleOrderLine2.Ship_From_Location__c = fuel.location2.Id;
//                resaleOrderLine1.Ship_From_Facility__c = fuel.location2.Facility__c;
//                resaleOrderLine1.Ship_From_Facility__r = fuel.location2.Facility__r;
                resaleOrderLine2.Unit_Price__c = 12.11;
                resaleOrderLine2.Sales_Tax__c = 14.686403;
                resaleOrderLine2.Memo__c = 'Resale Order Line 2';
                resaleOrderLine2.Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_RESALE;
                resaleOrderLine2.End_Customer_Reference__c = 'Ref Customer';
                resaleOrderLines.add(resaleOrderLine2);
            }
            return resaleOrderLines;
        }
        set;
    }

    /*******************************************************************************************************************************************************************************************************
    *   Created From SalesORderTest -  TESTS
    *******************************************************************************************************************************************************************************************************/



    /* set Custome to no approved. Create SO w/ customer. Release, verify exception, Approve customer, release without exceptions. */
    static testMethod void SalesOrderTest_testCustomerNotApproved() {

        Sales_order__c so = fuel.salesOrder;
        Sales_order__c salesOrder = [SELECT Id, Customer__r.Top_Parent_Customer__r.Status__c, Customer__r.Status__c, Bill_to__r.Status__c, Ship_to__r.Status__c
                                     FROM Sales_Order__c WHERE Id = : so.Id];
        system.assertEquals('Approved', salesOrder.Customer__r.Top_Parent_Customer__r.Status__c);

        Customer__c parentCust = fuel.customerParent;
        parentCust.Status__c = null;

        Customer__c shipToCust = fuel.customerShipTo;
        shipToCust.Status__c = null;

        Customer__c soldToCust = fuel.customerSoldTo;
        soldToCust.Status__c = null;

        Customer__c billToCust = fuel.customerBillTo;
        billToCust.Status__c = null;

        update new List<Customer__c> {parentCust, shipToCust, soldToCust, billToCust};
        salesOrder = [SELECT Id, Customer__r.Top_Parent_Customer__r.Status__c, Customer__r.Status__c, Bill_to__r.Status__c, Ship_to__r.Status__c
                      FROM Sales_Order__c WHERE Id = : so.Id];
        system.assertEquals(null, salesOrder.Customer__r.Top_Parent_Customer__r.Status__c);

        Test.startTest();

        new SalesOrderService().plan(salesOrder.Id);

        system.assert(ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_CUSTOMER_NOT_APPROVED.code), 'Expects sales order have an exception');
        system.assert(ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_SOLD_TO_CUSTOMER_NOT_APPROVED.code), 'Expect sold to customer error');
        system.assert(ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_BILL_TO_CUSTOMER_NOT_APPROVED.code), 'Expects bill to customer error');
        system.assert(ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_SHIP_TO_CUSTOMER_NOT_APPROVED.code), 'Expects ship to customer error');

        parentCust.Status__c = 'Approved';
        shipToCust.Status__c = 'Approved';
        soldToCust.Status__c = 'Approved';
        billToCust.Status__c = 'Approved';
        update new List<Customer__c> {parentCust, shipToCust, soldToCust, billToCust};

        new SalesOrderService().plan(salesOrder.Id);

        system.assert(!ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_CUSTOMER_NOT_APPROVED.code), 'Expects sales order have no exception');
        system.assert(!ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_SOLD_TO_CUSTOMER_NOT_APPROVED.code), 'Expect no sold to customer error');
        system.assert(!ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_BILL_TO_CUSTOMER_NOT_APPROVED.code), 'Expects no bill to customer error');
        system.assert(!ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_SHIP_TO_CUSTOMER_NOT_APPROVED.code), 'Expects no ship to customer error');

        Test.stopTest();
    }

    /*
     * assemble the minimum sales order record, this must not fail or we may break integrations that
     * load into the sales order object ( which have possibably missing or bad data )
     */
    public static testMethod void SalesOrderTest_SimpleOrderInsert_test() {

        Sales_Order__c so = new Sales_order__c();
        insert so;
        system.assert( so.id != null, ' expected to insert an order');
        so = [ select id, status__c from Sales_Order__c where id = :so.id limit 1];
        system.assertEquals('Draft', so.Status__c, ' expected new order to be Draft');
    }

    /*
    *   Create a SO and few SO Lines, see if Customer pricebook is picked in case product is not available on SO Pricebook
    */
    static testMethod void SalesOrderTest_test_CustomerPricebook_Match_At_So_Line_Level() {
        // accessing it before Test.startTest() to make sure limits are not consumed later
        Customer__c custShipTo = fuel.customerShipTo;

        // Create national pricebook
        Pricebook__c soPB = new Pricebook__c();
        soPB.name = fuel.company.Name +  ' SO Pricebook';
        soPB.company__c = fuel.company.id;
        insert soPB;

        Pricebook_Line__c pl = new Pricebook_Line__c();
        pl.product__c = fuel.product3.id;
        pl.pricebook__c = soPB.id;
        pl.price__c = 14;
        pl.Start_date__c = system.today();
        insert pl;

        Test.startTest();

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        salesOrder.pricebook__c = soPB.id;// make sure its pointing to specific so pricebook
        insert salesOrder;


        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 5;
        salesOrderLine.Required_Date__c = System.today() + 5;

        Sales_Order_Line__c salesOrderLineP3 = new Sales_Order_Line__c();
        salesOrderLineP3.Product__c = fuel.product3.Id; // this is product 3, which should come from national pricebook
        salesOrderLineP3.Description__c = fuel.product.Description__c;
        salesOrderLineP3.Company__c = fuel.company.id;
        salesOrderLineP3.Sales_Order__c = salesOrder.Id;
        salesOrderLineP3.Quantity_Ordered__c = 10;
        salesOrderLineP3.Required_Date__c = System.today() + 5;

        List<Sales_Order_Line__c> soLines = new Sales_Order_Line__c[] {salesOrderLine, salesOrderLineP3};
        insert soLines;

        for (Sales_Order_Line__c soLine : [Select Pricebook__c from Sales_Order_Line__c Where ID IN :soLines]) {
            if (soLine.Id == salesOrderLine.Id) {
                System.assertEquals(fuel.pricebook.Id, soLine.Pricebook__c, 'This product matches with "Sold To Customer" pricebook, so should be using the same at line level');
            }
            if (soLine.Id == salesOrderLineP3.Id) {
                System.assertEquals(soPB.Id, soLine.Pricebook__c, 'This product doesnt matches with "Sold to customer" pricebook, so should be coming from the SO pricebook for the same at line level');
            }
        }

        Test.stopTest();
    }

    /*
     KNDY-3195
     Create a SO and few SO Lines, see if National pricebook (Default__c = true) is picked in case product is not available on SO Pricebook
     */
    static testMethod void SalesOrderTest_test_National_Pricebook_Matching_When_Not_Present_On_SO_Pricebook() {
        // accessing it before Test.startTest() to make sure limits are not consumed later
        Customer__c custShipTo = fuel.customerShipTo;

        // Create national pricebook
        Pricebook__c nationalPB = new Pricebook__c();
        nationalPB.name = fuel.company.Name +  ' National Pricebook';
        nationalPB.company__c = fuel.company.id;
        nationalPB.default__c = true;// important : its company wide default
        insert nationalPB;

        Pricebook_Line__c pl = new Pricebook_Line__c();
        pl.product__c = fuel.product3.id;
        pl.pricebook__c = nationalPB.id;
        pl.price__c = 14;
        pl.Start_date__c = system.today();
        insert pl;

        Test.startTest();

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        salesOrder.pricebook__c = fuel.pricebook.id;// make sure its pointing to normal pricebook
        insert salesOrder;


        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 5;
        salesOrderLine.Required_Date__c = System.today() + 5;

        Sales_Order_Line__c salesOrderLineP3 = new Sales_Order_Line__c();
        salesOrderLineP3.Product__c = fuel.product3.Id; // this is product 3, which should come from national pricebook
        salesOrderLineP3.Description__c = fuel.product.Description__c;
        salesOrderLineP3.Company__c = fuel.company.id;
        salesOrderLineP3.Sales_Order__c = salesOrder.Id;
        salesOrderLineP3.Quantity_Ordered__c = 10;
        salesOrderLineP3.Required_Date__c = System.today() + 5;

        List<Sales_Order_Line__c> soLines = new Sales_Order_Line__c[] {salesOrderLine, salesOrderLineP3};
        insert soLines;

        for (Sales_Order_Line__c soLine : [Select Pricebook__c from Sales_Order_Line__c Where ID IN :soLines]) {
            if (soLine.Id == salesOrderLine.Id) {
                System.assertEquals(fuel.pricebook.Id, soLine.Pricebook__c, 'This product matches with SO pricebook, so should be using the same at line level');
            }
            if (soLine.Id == salesOrderLineP3.Id) {
                System.assertEquals(nationalPB.Id, soLine.Pricebook__c, 'This product doesnt matches with SO pricebook, so should be coming from the national pricebook for the same at line level');
            }
        }

        Test.stopTest();
    }

    public static testMethod void SalesOrderTest_test_SalesOrderLinesAddManageExt() {
        //TestData data = new TestData();
        //TestData.Accounting acctData = new TestData.Accounting(fuel.company.id);
        Sales_Order__c salesOrder = fuel.salesOrder;

        Process_Configuration__c pc1 = new Process_Configuration__c();
        pc1.name = 'SOLineGoods';
        pc1.Object_Name__c = 'Sales_Order_Line__c';
        pc1.Field_Value__c = 'Goods' ;
        pc1.Active__c = true;
        insert pc1;

        Test.startTest();
        system.assertEquals(true, ProcessConfigService.configResult('Sales_Order_Line__c', 'Goods', true));

        SalesOrderLinesAddManageExt soc = new SalesOrderLinesAddManageExt(new apexpages.standardController(salesOrder));
        Apexpages.currentPage().getParameters().put('selected_indexes', '0');

        soc.addNewRow();
        Accounting_Default__c testSegments = new Accounting_Default__c(Company__c = soc.soLineList[2].soLine.Company__c,
                GL_Account__c = fuel.CashGL.id );
        soc.soLineList[2].soLine.Quantity_Ordered__c = 1;
        //soc.soLineList[2].soLine.Unit_Price__c = 1;
        soc.soLineList[2].soLine.Required_Date__c = system.today();
        soc.soLineList[2].soLine.Product__c = fuel.product.id;
        soc.rowNum = 2;
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Error) == false, ApexPages.getMessages() );
        system.assertEquals(1, soc.displaySave_Return );
        soc.addSegments();
        soc.VFnewOverride = testSegments;
        soc.saveSegmentsForWrapper();
        //soc.addSegments();
        soc.closePopup();
        system.assert(soc.displayPopup == false );
        system.assertEquals(0, soc.displaySave_Return );
        system.assert(soc.save_lines() == null, ' expected null');
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Error) == false, ApexPages.getMessages() );

        soc.soLineList[2].soLine.Line_Type__c = 'Standard';
        system.assertEquals(1, soc.displaySave_Return );
        system.assert(soc.save_lines() == null, ' expected null');

        salesOrder = fetchSO( fuel.salesOrder.id );
        list<Sales_Order_Line__c> soLines = [SELECT id, Accounting_Segment__c, Accounting_Segment__r.GL_Account__c
                                             FROM Sales_Order_Line__c
                                             WHERE Sales_Order__c = :salesOrder.id ];
        system.assert(soLines.size()  == soc.soLineList.size(), 'Expect to see the same number of sales order lines from query as in wrapper list');
        object o;
        for (sales_order_line__c sol : soLines) {
            if (sol.Accounting_Segment__c != null) {
                o = sol.Accounting_Segment__c;
            }
        }
        system.assert( o != null, 'expected at least one accounting_segment');
        test.stopTest();
    }

    /**
    ****Test if the sales order lines are properly cloned with the updated field values  ***/

    public static testMethod void SalesOrderTest_test_clonesoline() {
        //TestData data = new TestData();
        ApexPages.Standardcontroller con;
        Test.startTest();
        Pagereference pageref = page.SalesOrderLinesAddManage;
        Test.setCurrentPage(pageref);
        list<Sales_Order_Line__c> salesOrderLineList = new list<Sales_Order_Line__c>(); //=fuel.SalesOrderLines;

        //create sales order lines
        Sales_Order_Line__c SalesOrderLine = new Sales_Order_Line__c();
        SalesOrderLine.Product__c = fuel.product.id;
        SalesOrderLine.Company__c = fuel.company.Id;
        SalesOrderLine.Sales_Order__c = fuel.salesOrder.Id;
        SalesOrderLine.Quantity_Ordered__c = 100;
        SalesOrderLine.Required_Date__c = System.today() + 5;
        SalesOrderLine.Status__c = 'Draft';
        insert SalesOrderLine;
        con = new ApexPages.Standardcontroller(fuel.salesOrder);
        SalesOrderLinesAddManageExt solAddManage = new SalesOrderLinesAddManageExt(con);
        Apexpages.currentPage().getParameters().put('selected_indexes', '1');
        solAddManage.clonesoline();
        System.assert(solAddManage.saveAndReturn() != null, ' expected record id');

        Test.stopTest();
        List<Sales_Order_Line__c> sol = [Select Id, Quantity_Ordered__c from Sales_Order_Line__c where Sales_Order__c = :fuel.SalesOrder.Id];
        System.assert(sol.size() == 4, ApexPages.getMessages()); //testdata already has 2 sales order lines
    }

    public static testMethod void SalesOrderTest_test_SalesOrderLinesAddManageExt3_Negative() {
        //TestData data = new TestData();
        Test.StartTest();
        // flush the caching to avoid conflicts
        SalesOrderFlowCache.flush();
        SalesOrderLinesAddManageExt soc = new SalesOrderLinesAddManageExt(new apexpages.standardController(fuel.salesOrder));
        Apexpages.currentPage().getParameters().put('selected_indexes', '0');
        soc.addNewRow();
        soc.soLineList[2].soLine.Quantity_Ordered__c = -10;
        soc.soLineList[2].soLine.Unit_Price__c = 1;
        soc.soLineList[2].soLine.Discount_Percent__c = 1;
        soc.soLineList[2].soLine.Product__c = fuel.product.id;
        soc.soLineList[2].soLine.Product__r = fuel.product;
        soc.soLineList[2].soLine.Product__r.Item__c = fuel.itemList[0].Id;
        soc.soLineList[2].soLine.Product__r.Item__r = fuel.itemList[0];
        system.assert(soc.save_lines() == null, 'You cannot have a negative amount on a Sales Order, please ensure the total for all lines is a postive number.');
        test.stopTest();
        // test for the new line was created
    }

    public static testMethod void SalesOrderTest_test_SalesOrderLinesAddManageExt3_Positive() {
        //TestData data = new TestData();
        Test.StartTest();
        // flush the caching to avoid conflicts
        SalesOrderFlowCache.flush();
        SalesOrderLinesAddManageExt soc = new SalesOrderLinesAddManageExt(new apexpages.standardController(fuel.salesOrder));
        Apexpages.currentPage().getParameters().put('selected_indexes', '0');
        soc.addNewRow();
        soc.soLineList[2].soLine.Quantity_Ordered__c = 10;
        //soc.soLineList[2].soLine.Unit_Price__c = 1;
        soc.soLineList[2].soLine.Discount_Percent__c = 1;
        soc.soLineList[2].soLine.Product__c = fuel.product.id;
        soc.soLineList[2].soLine.Product__r = fuel.product;
        soc.soLineList[2].soLine.Product__r.Item__c = fuel.itemList[0].Id;
        soc.soLineList[2].soLine.Product__r.Item__r = fuel.itemList[0];
        //system.assert(soc.save_lines()==null);
        system.assert(soc.saveAndReturn() != null, ' expected record id' + ApexPages.getMessages());
        system.assert(ApexPages.getMessages().size() == 0);
        test.stopTest();
        // test for the new line was created
    }

    // KNDY-1489: Test that sales order lines are closed too when the status of the sales order is changed to Closed.
    static testMethod void SalesOrderTest_testSalesOrderManualClose() {
        //TestData data = new TestData();
        fuel.salesOrder.Status__c = 'Open';
        update fuel.salesOrder;
        test.startTest();
        for ( Sales_Order_Line__c sol : fuel.salesOrder.Sales_Order_Lines__r ) {
            sol.Status__c = 'Open';
        }

        update fuel.salesOrder.Sales_Order_Lines__r;

        fuel.salesOrder = fetchSO( fuel.salesOrder.id );

        fuel.salesOrder.Status__c = 'Closed';
        update fuel.salesOrder;

        fuel.salesOrder = fetchSO( fuel.salesOrder.id );

        for (Sales_Order_Line__c sol : fuel.salesOrder.Sales_Order_Lines__r) {
            System.assertEquals('Closed', sol.Status__c);
        }
        test.StopTest();
    }

    public static String periodName() {
        Datetime myDT = Datetime.now();
        String myDate = myDT.format('MMM-yyyy');
        system.assert( myDate != null );
        return myDate.toUpperCase();
    }

    static testMethod void SalesOrderTest_test_salesshipment2() {
        //TestData data = new TestData();

        Shipment__c shipment = new Shipment__c();
        shipment.Customer__c = fuel.customerShipTo.id;
        shipment.Company__c = fuel.company.id;
        insert shipment;

        Shipment_Line__c SOSObj = new Shipment_Line__c();
        SOSObj.Quantity_Planned__c = 12;
        SOSObj.Quantity_Allocated__c = 0;
        SOSObj.Quantity_To_Pick__c = 0;
        SOSObj.Quantity_Picked__c = 0;
        SOSObj.Quantity_Shipped__c = 12;
        SOSObj.Sales_Order__c = fuel.salesOrder.id;
        SOSObj.Sales_Order_Line__c = fuel.salesOrder.Sales_Order_Lines__r[0].id;
        SOSObj.Unit_Price__c = 22.9;
        SOSObj.Item__c = fuel.product.Item__c;
        SOSObj.Product__c = fuel.product.Id;
        SOSObj.Shipment__c = shipment.id;

        insert SOSObj;
        List<Shipment_Line__c> soslist = new List<Shipment_Line__c> { SOSObj };

        Apexpages.standardSetController tmp = new Apexpages.standardSetController(soslist);
        system.assert( tmp != null, 'expected valid standard set controller');
    }

    public static testMethod void SalesOrderTest_SalesOrderNewExt_test() {
        //TestData data = new TestData();

        Test.startTest();
        SalesOrderNewExt ext = new SalesOrderNewExt (new Apexpages.Standardcontroller( new Sales_Order__c() ));
        ext.newObj.Company__c = fuel.company.ID;
        ext.newObj.Customer__c = fuel.customerSoldTo.ID;
        //ext.newObj.Ship_to__c = fuel.customerShipTo.ID;  test that the code fills in exactly one ship to
        // ext.newObj.Bill_to__c = fuel.customerBillTo.ID;  this also defaults
        fuel.customerSoldTo.Payment_Term__c = null;
        update fuel.customerSoldTo;
        //system.assert( ext.save() == null, ' expected an error message, save returns null ');
        system.assert( ext.save() != null, ' expected a view page save not null ' + ApexPages.getMessages());

        fuel.customerSoldTo.Payment_Term__c = fuel.terms.ID;
        update fuel.customerSoldTo;
        ext.newObj.Customer__c = fuel.customerSoldTo.ID;
        system.assert( ext.save() != null, ' expected a view page save not null ' + ApexPages.getMessages());

        update fuel.customerShipTo;

        SalesOrderNewExt ext1 = new SalesOrderNewExt (new Apexpages.Standardcontroller( new Sales_Order__c() ));
        ext1.newObj.Company__c = fuel.company.ID;
        ext1.newObj.Customer__c = fuel.customerSoldTo.ID;
        ext1.save();

        //KNDY-1149
        Payment_Term__c newTerms = new Payment_Term__c();
        newTerms.Name =  '2/10 Net 45';
        newTerms.Description__c = '2% discount in 10 days, due 45 days';
        newTerms.Discount_Days__c = 10;
        newTerms.Discount_Percent__c = 2.0;
        newTerms.Due_Days__c = 45;
        insert newTerms;

        fuel.customerBillTo.Payment_Term__c = newTerms.Id;
        update fuel.customerBillTo;

        // Requeries all the customers.
        SalesOrderService.customersMap.clear();

        SalesOrderNewExt ext2 = new SalesOrderNewExt (new Apexpages.Standardcontroller( new Sales_Order__c() ));
        ext2.newObj.Company__c = fuel.company.ID;
        ext2.newObj.Customer__c = fuel.customerSoldTo.ID;
        ext2.save();

        Payment_Term__c savedTerms = [select id, name from Payment_Term__c where id = :ext2.newObj.Payment_Term__c];
        system.assertEquals( savedTerms.Name, '2/10 Net 45');
        system.assert(savedTerms.Name != '2/10 Net 30', 'payment terms not pulled from customer bill to');

        Sales_Order__c mySO = new Sales_Order__c();
        mySO.Company__c = fuel.company.ID;
        mySO.Customer__c = fuel.customerSoldTo.ID;
        insert mySO;

        Sales_Order__c mySO1 = [SELECT Id, Name, Payment_Term__c, Payment_Term__r.Name, Currency__c, Company__r.Default_Transaction_Currency__c
                                FROM Sales_Order__c WHERE Id = :mySO.Id LIMIT 1];
        System.assertEquals( mySO1.Payment_Term__r.Name, '2/10 Net 45');
        System.assert(mySO1.Payment_Term__r.Name != '2/10 Net 30', 'payment terms not pulled from customer bill to');
        System.assertEquals(mySO1.Currency__c, mySO1.Company__r.Default_Transaction_Currency__c);
        Test.stopTest();
    }

    public static testMethod void salesOrderNewExtCustomerDefaultTest(){
        Test.startTest();
        SalesOrderNewExt ext = new SalesOrderNewExt (new Apexpages.Standardcontroller( new Sales_Order__c() ));
        ext.newObj.Company__c = fuel.company.ID;

        Sales_Order__c so = SalesOrderNewExt.updateCustomerDefaults(fuel.customerSoldTo.Id);
        System.assertEquals( so.Currency__c, fuel.customerSoldTo.Currency__c);
    }

    public static testMethod void SalesOrderTest_emptyUnitPriceError() {

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Bill_to__c = fuel.customerBillTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        salesOrder.Ship_From_Location__c = fuel.location2.Id;
        salesOrder.Price_Determination_Date__c = SalesOrderService.PRICE_DET_ORDER;
        salesOrder.Required_Date__c = System.today() + 5;
        insert salesOrder;

        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 5;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
        salesOrderLine.Product__c = null;
        salesOrderLine.Unit_Price__c = null;
        insert salesOrderLine;

        ApexPages.Standardcontroller con;
        con = new ApexPages.Standardcontroller(salesOrder);

        Test.startTest();

        new SalesOrderService().plan(salesOrder.id);

        salesOrderLine = [SELECT Id, Has_Exceptions__c, Unit_Price__c FROM Sales_Order_Line__c WHERE Id = :salesOrderLine.Id];
        System.assertEquals(null, salesOrderLine.Unit_Price__c);
        System.assertEquals(true, salesOrderLine.Has_Exceptions__c, 'Sales Order Line should have an exception.');
        system.assert(ExceptionService.hasOpenTask(salesOrderLine.Id, ExceptionUtil.SOL_MISSING_PRICE.code), 'Expects sales order line to have an exception');

        Test.stopTest();
    }

    public static testMethod void SalesOrderTest_testSalesOrderStatus() {

        Sales_Order__c salesOrder = fuel.salesOrder;

        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Company__c = fuel.company.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Discount_Percent__c = 2;
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Quantity_Ordered__c = 100;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Sales_Order__c = fuel.salesOrder.Id;
        salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
        salesOrderLine.Unit_Price__c = 11.12;
        salesOrderLine.Memo__c = 'salesOrderLine3';
        insert SalesOrderLine;

        Test.startTest();

        salesOrder = [select Id, Status__c, (Select id, Status__c from Sales_Order_Lines__r) from Sales_Order__c where Id = : salesOrder.Id];

        List<Sales_Order_Line__c> soList = salesOrder.Sales_Order_Lines__r;

        System.assertEquals(soList.size() , 3);

        System.assertEquals(soList[0].Status__c, 'Draft');
        System.assertEquals(soList[1].Status__c, 'Draft');
        System.assertEquals(soList[2].Status__c, 'Draft');
        System.assertEquals('Draft', salesOrder.Status__c);

        /* Open SO by opening 1 line */
        soList[0].Status__c = 'Open';
        soList[1].Status__c = 'Draft';
        soList[2].Status__c = 'Draft';
        update soList;
        salesOrder = [select Id, Status__c, (Select id, Status__c from Sales_Order_Lines__r) from Sales_Order__c where Id = : salesOrder.Id];
        System.assertEquals('Open', salesOrder.Status__c);

        soList[0].Status__c = 'Closed';
        soList[1].Status__c = 'Draft';
        soList[2].Status__c = 'Draft';
        update soList;
        salesOrder = [select Id, Status__c, (Select id, Status__c from Sales_Order_Lines__r) from Sales_Order__c where Id = : salesOrder.Id];
        System.assertEquals('Open', salesOrder.Status__c);

        soList[0].Status__c = 'Closed';
        soList[1].Status__c = 'Cancelled';
        soList[2].Status__c = 'Cancelled';
        update soList;
        salesOrder = [select Id, Status__c, (Select id, Status__c from Sales_Order_Lines__r) from Sales_Order__c where Id = : salesOrder.Id];
        System.assertEquals('Closed', salesOrder.Status__c);

        soList[0].Status__c = 'Closed';
        soList[1].Status__c = 'Draft';
        soList[2].Status__c = 'Cancelled';
        update soList;
        salesOrder = [select Id, Status__c, (Select id, Status__c from Sales_Order_Lines__r) from Sales_Order__c where Id = : salesOrder.Id];
        System.assertEquals('Open', salesOrder.Status__c);

        soList[0].Status__c = 'Closed';
        soList[1].Status__c = 'Open';
        soList[2].Status__c = 'Cancelled';
        update soList;
        salesOrder = [select Id, Status__c, (Select id, Status__c from Sales_Order_Lines__r) from Sales_Order__c where Id = : salesOrder.Id];
        System.assertEquals('Open', salesOrder.Status__c);

        soList[0].Status__c = 'Draft';
        soList[1].Status__c = 'Draft';
        soList[2].Status__c = 'Cancelled';
        update soList;
        salesOrder = [select Id, Status__c, (Select id, Status__c from Sales_Order_Lines__r) from Sales_Order__c where Id = : salesOrder.Id];
        System.assertEquals('Draft', salesOrder.Status__c);

        soList[0].Status__c = 'Open';
        soList[1].Status__c = 'Draft';
        soList[2].Status__c = 'Cancelled';
        update soList;
        salesOrder = [select Id, Status__c, (Select id, Status__c from Sales_Order_Lines__r) from Sales_Order__c where Id = : salesOrder.Id];
        System.assertEquals('Open', salesOrder.Status__c);

        soList[0].Status__c = 'Cancelled';
        soList[1].Status__c = 'Cancelled';
        soList[2].Status__c = 'Cancelled';
        update soList;
        salesOrder = [select Id, Status__c, (Select id, Status__c from Sales_Order_Lines__r) from Sales_Order__c where Id = : salesOrder.Id];
        System.assertEquals('Cancelled', salesOrder.Status__c);

        Test.StopTest();
    }

    public static testMethod void SalesOrderTest_validateChangingCustomerBillTo() {
        // OTC-927 - We don't want to allow users to change any of the customer fields if an SO is not in Draft

        List<Period__c> periodList = fuel.periodList;

        Sales_Order__c salesOrder = fuel.salesOrder;

        Customer__c customerBillTo2 = fuel.customerBillTo.clone(false, false);
        customerBillTo2.Customer_Identifier__c = 'Customer Bill To 2';
        customerBillTo2.Name = 'Customer Bill To 2';
        insert customerBillTo2;

        List<SKID__c> skids = fillStock();
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;

        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SOPlanExt soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();

        Sales_Order__c SO = [SELECT Id, Status__c, Customer__c, Ship_To__c, Bill_to__c FROM Sales_Order__c LIMIT 1];
        System.assertEquals('Open', SO.Status__c);
        System.assertEquals(SO.Customer__c, fuel.customerSoldTo.Id);
        System.assertEquals(SO.Ship_To__c, fuel.customerShipTo.Id);
        System.assertEquals(SO.Bill_to__c, fuel.customerBillTo.Id);

        String msg;
        Boolean matched = false;

        // Update Bill-To
        try {
            SO.Bill_to__c = customerBillTo2.Id;
            update SO;
        } catch (exception e) {
            msg = e.getMessage();
            if (msg.contains(Label.Cannot_update_bill_to_customer_if_Sales_Order_is_not_in_Draft)) {
                matched = true;
            }
        }

        msg = (msg != null) ? msg : '';
        System.assertEquals(true, matched, msg);
    }

    public static testMethod void SalesOrderTest_validateChangingCustomerSoldTo() {
        // OTC-927 - We don't want to allow users to change any of the customer fields if an SO is not in Draft

        List<Period__c> periodList = fuel.periodList;

        Sales_Order__c salesOrder = fuel.salesOrder;

        Customer__c customerBillTo2 = fuel.customerBillTo.clone(false, false);
        customerBillTo2.Customer_Identifier__c = 'Customer Bill To 2';
        customerBillTo2.Name = 'Customer Bill To 2';
        insert customerBillTo2;

        Customer__c customerSoldTo2 = fuel.customerSoldTo.clone(false, false);
        customerSoldTo2.Customer_Identifier__c = 'Customer Sold To 2';
        customerSoldTo2.Name = 'Customer Sold To 2';
        customerSoldTo2.Parent_Customer__c = customerBillTo2.Id;
        insert customerSoldTo2;

        List<SKID__c> skids = fillStock();
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;

        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SOPlanExt soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();

        Sales_Order__c SO = [SELECT Id, Status__c, Customer__c, Ship_To__c, Bill_to__c FROM Sales_Order__c where Id = :salesOrder.id];
        System.assertEquals('Open', SO.Status__c);
        System.assertEquals(SO.Customer__c, fuel.customerSoldTo.Id);
        System.assertEquals(SO.Ship_To__c, fuel.customerShipTo.Id);
        System.assertEquals(SO.Bill_to__c, fuel.customerBillTo.Id);

        String msg;
        Boolean matched = false;

        // Update Bill-To
        try {
            SO.Bill_to__c = customerBillTo2.Id;
            SO.Customer__c = customerSoldTo2.Id;
            update SO;
        } catch (exception e) {
            msg = e.getMessage();
            if (msg.contains(Label.Cannot_update_customer_if_Sales_Order_is_not_in_Draft)) {
                matched = true;
            }
        }

        msg = (msg != null) ? msg : '';
        System.assertEquals(true, matched, msg);
    }

    public static testMethod void SalesOrderTest_validateChangingCustomerShipTo() {
        // OTC-927 - We don't want to allow users to change any of the customer fields if an SO is not in Draft

        List<Period__c> periodList = fuel.periodList;

        Sales_Order__c salesOrder = fuel.salesOrder;

        Customer__c customerBillTo2 = fuel.customerBillTo.clone(false, false);
        customerBillTo2.Customer_Identifier__c = 'Customer Bill To 2';
        customerBillTo2.Name = 'Customer Bill To 2';
        insert customerBillTo2;

        Customer__c customerSoldTo2 = fuel.customerSoldTo.clone(false, false);
        customerSoldTo2.Customer_Identifier__c = 'Customer Sold To 2';
        customerSoldTo2.Name = 'Customer Sold To 2';
        customerSoldTo2.Parent_Customer__c = customerBillTo2.Id;
        insert customerSoldTo2;

        Customer__c customerShipTo2 = fuel.customerShipTo.clone(false, false);
        customerShipTo2.Customer_Identifier__c = 'Customer Ship To 2';
        customerShipTo2.Name = 'Customer Ship To 2';
        customerShipTo2.Parent_Customer__c = customerSoldTo2.Id;
        insert customerShipTo2;

        List<SKID__c> skids = fillStock();
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;

        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SOPlanExt soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();

        Sales_Order__c SO = [SELECT Id, Status__c, Customer__c, Ship_To__c, Bill_to__c FROM Sales_Order__c LIMIT 1];
        System.assertEquals('Open', SO.Status__c);
        System.assertEquals(SO.Customer__c, fuel.customerSoldTo.Id);
        System.assertEquals(SO.Ship_To__c, fuel.customerShipTo.Id);
        System.assertEquals(SO.Bill_to__c, fuel.customerBillTo.Id);

        String msg;
        Boolean matched = false;

        // Update Bill-To
        try {
            SO.Bill_to__c = customerBillTo2.Id;
            SO.Customer__c = customerSoldTo2.Id;
            SO.Ship_to__c = customerShipTo2.Id;
            update SO;
        } catch (exception e) {
            msg = e.getMessage();
            if (msg.contains(Label.Cannot_update_ship_to_customer_if_Sales_Order_is_not_in_Draft)) {
                matched = true;
            }
        }

        msg = (msg != null) ? msg : '';
        System.assertEquals(true, matched, msg);
    }
    //test undo fulfillment
    public static testMethod void partialUndoFulfillInstallBaseNonShippableSalesOrderLines(){ 
        

        Item_Attribute__c itemAttrObj = new Item_Attribute__c();
        itemAttrObj.Name = 'Attribute-1';
        itemAttrObj.Serial_Number__c = true;
        insert itemAttrObj;

        Item__c item = fuel.product.Item__r;
        item.Non_Shippable__c = true;               // for creating fulfillments
        item.Track_Install_Base__c = true;          // for serial tracking
        item.Item_Attribute__c = itemAttrObj.id;    // for serial tracking

        update item;

        fuel.customerShipTo.Track_Install_Base__c = true;
        update fuel.customerShipTo;

        Sales_Order__c salesOrder = fuel.salesOrder;
        
        Sales_Order_Line__c sol = [select Id, product__r.Item__r.Class__r.Type__c, Quantity_Ordered__c, Status__c,Packaging_UOM__c,
                                    product__r.Item__r.Non_Shippable__c, Sales_Order__r.Status__c, Has_Exceptions__c, product__r.Item__r.Packaging_UOM__c,
                                    product__r.Item__c, product__r.Item__r.Non_Inventory__c, product__r.Item__r.Source__c,
                    (Select id from Shipment_Lines__r), (Select id from Fulfillments__r) 
                from Sales_Order_Line__c 
                where Sales_Order__c = :salesOrder.id and product__r.Item__c = :fuel.product.Item__c Limit 1];
        sol.Non_Shippable__c = true;
        update sol;
        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
        JsonResult soJS = SalesOrderFulfillmentExt.getSOLines((String) salesOrder.id);

        system.assert(soJS.records != null, soJS);

         //verify the json obj was created correctly
        Boolean hasSerialList = false; 

        for (SalesOrderFulfillmentExt.SOLWrapper jsRec : (List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records){
            System.assertEquals(100, jsRec.soLine.Quantity_Ordered__c, 'Expecting 100 qty ordered.');
           // System.assertEquals(100, jsRec.qtyToFulfill);
            jsRec.qtyToFulfill = 10;
            solList.add( jsRec.soLine);

            if (jsRec.soLine.product__r.Item__r.Item_Attribute__c!= null && jsRec.soLine.product__r.Item__r.Item_Attribute__r.Serial_Number__c){
                List<Serial__c> cusSerialList = new List<Serial__c>();
                for (Integer i = 0; i < jsRec.qtyToFulfill; i++){ // create ALL EXCEPT ONE serial to throw exception
                    cusSerialList.add(new Serial__c(name='Serial-'+i)); 
                }
            
                for (skidService3.SerialWrapper sw : jsRec.serialWrapperList){
                    sw.skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                    sw.skid.Packaging_UOM__r = fuel.uomObj;
                    sw.skid.Packaging_UOM__r.Package_Class__r = null;
                    if (sw.serialList.size() == 1) hasSerialList = true;
                    System.assert(sw.serialList.size() == 1, jsRec);
                    sw.serialList = cusSerialList;
                }
            }
        }

        System.assert(hasSerialList, 'Expecting a serialWrapper list');

        soJS = SalesOrderFulfillmentExt.createFulfillments((List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records, new List<String>());
        sol = [select Id, Status__c,  Quantity_Ordered__c, Quantity_Fulfilled__c, 
                    (SELECT Id, Quantity__c, Sales_Order_Line__c FROM Fulfillments__r) 
                from Sales_Order_Line__c where id =: sol.id];

        System.assert(soJS.success == true, soJS);
        System.assert(soJS.records.size() > 0, soJS);

        System.assert(sol != null, 'SOL should not be null: ' + sol);
        System.assert(sol.Fulfillments__r.size() == 1, 'Expecting fulfillments: ' + sol.Fulfillments__r);
        System.assertEquals(10, sol.Quantity_Fulfilled__c, sol.Fulfillments__r);

        // verify skid qty and serial count
        List<Skid__c> skids = [select id, Customer__c, Item__c, Quantity__c, Type__c, Sales_Order_Line__r.Quantity_Ordered__c, (select id from Serials__r) 
                        from Skid__c 
                        where Sales_Order_Line__c = :sol.id];
        System.assert(skids.size() == 1, 'Expecting 1 skid in list: ' + skids);
        System.assert(skids[0].Serials__r.size() > 0);
        System.assert(skids[0].Quantity__c == 10);
        System.assertEquals( 10, skids[0].Serials__r.size());

        List<Serial__c> serials = [select id, (select id, Type__c from Serial_Transactions__r) from Serial__c];
        for (serial__c serial : serials){
            System.assertEquals(1, serial.Serial_Transactions__r.size());    
            System.assert(serial.Serial_Transactions__r[0].Type__c == 'Install Base');
        }
        
        // verify sol stuff
        sol = [select Id, Status__c, Quantity_Ordered__c, Quantity_Fulfilled__c, 
                    (SELECT Id, Quantity__c, SKID__c, SKID__r.Quantity__c, SKID__r.Type__c, Sales_Order_Line__c FROM Fulfillments__r) 
                from Sales_Order_Line__c where id =: sol.id];

        System.assert(sol != null, 'SOL should not be null: ' + sol);
        System.assertEquals(10, sol.Quantity_Fulfilled__c,  'Incorrect Quantity Fulfilled should equal 10');
        System.assert(sol.Fulfillments__r.size() == 1, 'Expecting fulfillments: ' + sol.Fulfillments__r);
        System.assertEquals(sol.Status__c, 'Open');
        system.assert(sol.Fulfillments__r[0].SKID__c != null);
        
        
        list<id > flist = new list<id>();
        
        JsonResult fJS = SalesOrderFulfillmentExt.getFulfillments((String) sol.id);
        
        system.assert(fJS.records != null, fJS);
        for (SalesOrderFulfillmentExt.SOLWrapper jsRec : (List<SalesOrderFulfillmentExt.SOLWrapper>) fJS.records){
            
            flist.add( jsRec.fulfillment.id);
        }
        
        JsonResult result = SalesOrderFulfillmentExt.cancelFulfillments(flist);        
        
        sol = [select Id, Status__c,  Quantity_Ordered__c, Quantity_Fulfilled__c, 
                    (SELECT Id, Quantity__c, Sales_Order_Line__c FROM Fulfillments__r) 
                from Sales_Order_Line__c where id =: sol.id];
        System.assert(sol != null, 'SOL should not be null: ' + sol);
        System.assert(sol.Fulfillments__r.size() == 1, 'Expecting 1 fulfillments: ' + sol.Fulfillments__r);
        
        list<Fulfillment__c> fullist = [select Id, Status__c FROM Fulfillment__c 
                 where id  in: flist];
        System.assertEquals('Cancelled', fullist[0].Status__c);
        
         skids = [select id, Customer__c, Item__c, Quantity__c, Type__c, Sales_Order_Line__r.Quantity_Ordered__c, (select id from Serials__r) 
                        from Skid__c 
                        where Sales_Order_Line__c = :sol.id];
        System.assert(skids.size() == 1, 'Expecting 1 skid in list: ' + skids);
        
        System.assert(skids[0].Quantity__c == 0);
        System.assertEquals( 0, skids[0].Serials__r.size());
        list<Serial_Transaction__c> serialTransactions = [select id, Type__c from Serial_Transaction__c where fulfillment__c in :flist];
        System.assertEquals(20, serialTransactions.size());  
        
    }

    public static testMethod void SalesOrderTest_partialFulfillNonShippableSalesOrderLines() {

        Sales_Order__c salesOrder = fuel.salesOrder;

        fuel.product.Item__r.Non_Shippable__c = true;
        update fuel.product.Item__r;

        Sales_Order_Line__c sol = [select Id, product__r.Item__r.Class__r.Type__c, Quantity_Ordered__c, Status__c,
                                   product__r.Item__r.Non_Shippable__c, Sales_Order__r.Status__c, Has_Exceptions__c,
                                   product__r.Item__c, product__r.Item__r.Non_Inventory__c, product__r.Item__r.Source__c,
                                   (Select id from Shipment_Lines__r), (Select id from Fulfillments__r)
                                   from Sales_Order_Line__c
                                   where Sales_Order__c = :salesOrder.id and Product__c = :fuel.product.id Limit 1];

        sol.Non_Shippable__c = true;
        update sol;


        system.assert(sol.product__r.Item__r.Non_Shippable__c);
        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();

        JsonResult soJS = SalesOrderFulfillmentExt.getSOLines((String) salesOrder.id);

        system.assert(soJS.records != null, soJS);

        for (SalesOrderFulfillmentExt.SOLWrapper jsRec : (List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records) {
            System.assertEquals(100, jsRec.soLine.Quantity_Ordered__c, 'Expecting 100 qty ordered.');
           // System.assertEquals(100, jsRec.qtyToFulfill);
            jsRec.qtyToFulfill = 10;
            solList.add( jsRec.soLine);
        }

        SalesOrderFulfillmentExt.createFulfillments((List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records, new List<String>());
        sol = [select Id, Status__c,  Quantity_Ordered__c, Quantity_Fulfilled__c,
               (SELECT Id, Quantity__c, Sales_Order_Line__c FROM Fulfillments__r)
               from Sales_Order_Line__c where id = : sol.id];

        System.assert(sol != null, 'SOL should not be null: ' + sol);
        System.assert(sol.Fulfillments__r.size() == 1, 'Expecting fulfillments: ' + sol.Fulfillments__r);
        System.assertEquals(10, sol.Quantity_Fulfilled__c, sol.Fulfillments__r);



        // do another fulfillment for the same line
        soJS = SalesOrderFulfillmentExt.getSOLines((String) salesOrder.id);

        system.assert(soJS.records != null, soJS);

        for (SalesOrderFulfillmentExt.SOLWrapper jsRec : (List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records){
            jsRec.qtyToFulfill = 90;

            System.assertEquals(90, jsRec.qtyToFulfill, 'Expecting 10 qty remaining to be fulfilled.');
            solList.add( jsRec.soLine);
        }

        SalesOrderFulfillmentExt.createFulfillments((List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records, new List<String>());
        sol = [select Id, Status__c,  Quantity_Ordered__c, Quantity_Fulfilled__c,
               (SELECT Id, Quantity__c, Sales_Order_Line__c FROM Fulfillments__r)
               from Sales_Order_Line__c where id = : sol.id];

        System.assert(sol != null, 'SOL should not be null: ' + sol);
        System.assertEquals(100, sol.Quantity_Fulfilled__c);
        System.assert(sol.Fulfillments__r.size() == 2, 'Expecting 2 fulfillments: ' + sol.Fulfillments__r);
    }

    /* partial Fulfill on Install Base NonShippable SalesOrderLines (TO-DO: rename title /smiley_face )
    */
    public static testMethod void SalesOrderTest_partialFulfillInstallBaseNonShippableSalesOrderLines() {

        Item_Attribute__c itemAttrObj = new Item_Attribute__c();
        itemAttrObj.Name = 'Attribute-1';
        itemAttrObj.Serial_Number__c = true;
        insert itemAttrObj;

        Item__c item = fuel.product.Item__r;
        item.Non_Shippable__c = true;               // for creating fulfillments
        item.Track_Install_Base__c = true;          // for serial tracking
        item.Item_Attribute__c = itemAttrObj.id;    // for serial tracking

        update item;

        fuel.customerShipTo.Track_Install_Base__c = true;
        update fuel.customerShipTo;

        Sales_Order__c salesOrder = fuel.salesOrder;

        Sales_Order_Line__c sol = [select Id, product__r.Item__r.Class__r.Type__c, Quantity_Ordered__c, Status__c,
                                   product__r.Item__r.Non_Shippable__c, Sales_Order__r.Status__c, Has_Exceptions__c,
                                   product__r.Item__c, product__r.Item__r.Non_Inventory__c, product__r.Item__r.Source__c,
                                   (Select id from Shipment_Lines__r), (Select id from Fulfillments__r)
                                   from Sales_Order_Line__c
                                   where Sales_Order__c = :salesOrder.id and product__r.Item__c = :item.id Limit 1];

        sol.Non_Shippable__c = true;
        update sol;
        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
        JsonResult soJS = SalesOrderFulfillmentExt.getSOLines((String) salesOrder.id);

        system.assert(soJS.records != null, soJS);

        //verify the json obj was created correctly
        Boolean hasSerialList = false;

        for (SalesOrderFulfillmentExt.SOLWrapper jsRec : (List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records) {
            System.assertEquals(100, jsRec.soLine.Quantity_Ordered__c, 'Expecting 100 qty ordered.');
            //System.assertEquals(100, jsRec.qtyToFulfill);
            jsRec.qtyToFulfill = 10;
            solList.add( jsRec.soLine);

            if (jsRec.soLine.product__r.Item__r.Item_Attribute__c != null && jsRec.soLine.product__r.Item__r.Item_Attribute__r.Serial_Number__c) {
                List<Serial__c> cusSerialList = new List<Serial__c>();
                for (Integer i = 0; i < jsRec.qtyToFulfill; i++) { // create ALL EXCEPT ONE serial to throw exception
                    cusSerialList.add(new Serial__c(name = 'Serial-' + i));
                }

                for (skidService3.SerialWrapper sw : jsRec.serialWrapperList) {
                    if (sw.serialList.size() == 1) hasSerialList = true;
                    System.assert(sw.serialList.size() == 1, jsRec);
                    sw.serialList = cusSerialList;
                }
            }
        }

        System.assert(hasSerialList, 'Expecting a serialWrapper list');

        soJS = SalesOrderFulfillmentExt.createFulfillments((List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records, new List<String>());
        sol = [select Id, Status__c,  Quantity_Ordered__c, Quantity_Fulfilled__c,
               (SELECT Id, Quantity__c, Sales_Order_Line__c FROM Fulfillments__r)
               from Sales_Order_Line__c where id = : sol.id];

        System.assert(soJS.success == true, soJS);
        System.assert(soJS.records.size() > 0, soJS);

        System.assert(sol != null, 'SOL should not be null: ' + sol);
        System.assert(sol.Fulfillments__r.size() == 1, 'Expecting fulfillments: ' + sol.Fulfillments__r);
        System.assertEquals(10, sol.Quantity_Fulfilled__c, sol.Fulfillments__r);



        // do another fulfillment for the same line
        soJS = SalesOrderFulfillmentExt.getSOLines((String) salesOrder.id);

        system.assert(soJS.records != null, soJS);

        for (SalesOrderFulfillmentExt.SOLWrapper jsRec : (List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records){
            jsRec.qtyToFulfill = 90;

            System.assertEquals(90, jsRec.qtyToFulfill, 'Expecting 10 qty remaining to be fulfilled.');
            solList.add( jsRec.soLine);
        }

        SalesOrderFulfillmentExt.createFulfillments((List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records, new List<String>());
        sol = [select Id, Status__c,  Quantity_Ordered__c, Quantity_Fulfilled__c,
               (SELECT Id, Quantity__c, Sales_Order_Line__c FROM Fulfillments__r)
               from Sales_Order_Line__c where id = : sol.id];

        System.assert(sol != null, 'SOL should not be null: ' + sol);
        System.assertEquals(10, sol.Quantity_Fulfilled__c);
        System.assert(sol.Fulfillments__r.size() == 1, 'Expecting 2 fulfillments: ' + sol.Fulfillments__r);

        // verify skid qty and serial count
        List<Skid__c> skids = [select id, Customer__c, Item__c, Quantity__c, Type__c, Sales_Order_Line__r.Quantity_Ordered__c, (select id from Serials__r)
                               from Skid__c
                               where Sales_Order_Line__c = :sol.id];
        System.assert(skids.size() == 1, 'Expecting 1 skid in list: ' + skids);
        System.assert(skids[0].Serials__r.size() > 0);
        System.assert(skids[0].Quantity__c == 10);
        System.assertEquals( 10, skids[0].Serials__r.size());

        List<Serial__c> serials = [select id, (select id, Type__c from Serial_Transactions__r) from Serial__c];
        for (serial__c serial : serials) {
            System.assertEquals(1, serial.Serial_Transactions__r.size());
            System.assert(serial.Serial_Transactions__r[0].Type__c == 'Install Base');
        }

        // verify sol stuff
        sol = [select Id, Status__c, Quantity_Ordered__c, Quantity_Fulfilled__c,
               (SELECT Id, Quantity__c, SKID__c, SKID__r.Quantity__c, SKID__r.Type__c, Sales_Order_Line__c FROM Fulfillments__r)
               from Sales_Order_Line__c where id = : sol.id];

        System.assert(sol != null, 'SOL should not be null: ' + sol);
        System.assertEquals(10, sol.Quantity_Fulfilled__c,  'Incorrect Quantity Fulfilled should equal 10');
        System.assert(sol.Fulfillments__r.size() == 1, 'Expecting fulfillments: ' + sol.Fulfillments__r);
        System.assertEquals(sol.Status__c, 'Open');
        system.assert(sol.Fulfillments__r[0].SKID__c != null);
    }

    // Release SO with Non-shippable line and shippable line. Expect one SHL to be created. Fufullment should create one fulfillment record for the non-shippable line
    public static testMethod void SalesOrderTest_fulfillNonShippableSalesOrderLines() {


        Item_Attribute__c itemAttrObj = new Item_Attribute__c();
        itemAttrObj.Name = 'Attribute-1';
        itemAttrObj.Serial_Number__c = true;
        insert itemAttrObj;

        Item__c item = fuel.product.Item__r;
        item.Non_Shippable__c = true;               // for creating fulfillments
        item.Track_Install_Base__c = true;          // for serial tracking
        item.Item_Attribute__c = itemAttrObj.id;    // for serial tracking

        update item;


        fuel.customerShipTo.Track_Install_Base__c = true;
        update fuel.customerShipTo;

        Sales_Order__c salesOrder = fuel.salesOrder;

        Sales_Order_Line__c sol = [select Id, product__r.Item__r.Class__r.Type__c, Quantity_Ordered__c, Status__c,
                                   Sales_Order__r.Ship_To__r.Track_Install_Base__c, Product__r.Item__r.Track_Install_Base__c,
                                   product__r.Item__r.Non_Shippable__c, Sales_Order__r.Status__c, Has_Exceptions__c,
                                   product__r.Item__c, product__r.Item__r.Non_Inventory__c, product__r.Item__r.Source__c,
                                   (Select id from Shipment_Lines__r), (Select id from Fulfillments__r)
                                   from Sales_Order_Line__c
                                   where Sales_Order__c = :salesOrder.id and product__r.Item__c = :fuel.itemList[0].id Limit 1];

        sol.Non_Shippable__c = true;
        update sol;

        Sales_Order_Line__c sol2 = [select Id, product__r.Item__r.Class__r.Type__c, Quantity_Ordered__c, Status__c,
                                    product__r.Item__r.Non_Shippable__c, Sales_Order__r.Status__c, Has_Exceptions__c,
                                    product__r.Item__c, product__r.Item__r.Non_Inventory__c, product__r.Item__r.Source__c,
                                    (Select id from Shipment_Lines__r), (Select id from Fulfillments__r)
                                    from Sales_Order_Line__c
                                    where Sales_Order__c = :salesOrder.id and product__r.Item__c = :fuel.itemList[5].id Limit 1];


        // verify line values
        System.assert(sol != null, 'Expecting there to be a SOL');
        System.assert(sol.product__r.Item__r.Non_Shippable__c, 'Expecting item to not be shippable: ' + sol.Product__r.Item__r);
        System.assert(sol.Quantity_Ordered__c == 100, sol.Quantity_Ordered__c);
        System.assert(sol.Sales_Order__r.Ship_To__r.Track_Install_Base__c = true);
        System.assert(sol.Product__r.Item__r.Track_Install_Base__c);
        System.assertEquals(sol.Status__c, 'Draft');
        System.assert(sol.Has_Exceptions__c == false);

        System.assert(sol2 != null, 'Expecting there to be a SOL');
        System.assert(!sol2.product__r.Item__r.Non_Shippable__c, 'Expecting item to not be shippable: ' + sol.Product__r.Item__r);
        System.assert(sol2.Quantity_Ordered__c == 15, sol.Quantity_Ordered__c);
        System.assertEquals(sol2.Status__c, 'Draft');
        System.assert(sol2.Sales_Order__r.Status__c != 'Confirmed');
        System.assert(sol2.Has_Exceptions__c == false);


        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();

        JsonResult soJS = SalesOrderFulfillmentExt.getSOLines((String) salesOrder.id);

        system.assert(soJS.records != null, soJS);

        //verify the json obj was created correctly
        Boolean hasSerialList = false;

        for (SalesOrderFulfillmentExt.SOLWrapper jsRec : (List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records){
            jsRec.qtyToFulfill = jsRec.soLine.Quantity_Ordered__c;

            // initial fulfillment and serialWrapper is empty
            System.assert(jsRec.serialWrapperList.size() == 1);
            System.assert(jsRec.fulfillment != null);

            System.assert(jsRec.soLine != null);
            System.assert(jsRec.qtyToFulfill != null);
            solList.add(jsRec.soLine);

            // if condition for creating serials on the Skid
            if (jsRec.soLine.product__r.Item__r.Item_Attribute__c != null && jsRec.soLine.product__r.Item__r.Item_Attribute__r.Serial_Number__c) {
                List<Serial__c> cusSerialList = new List<Serial__c>();
                for (Integer i = 0; i < jsRec.qtyToFulfill; i++) { // create ALL EXCEPT ONE serial to throw exception
                    cusSerialList.add(new Serial__c());
                }

                for (skidService3.SerialWrapper sw : jsRec.serialWrapperList) {
                    if (sw.serialList.size() == 1) hasSerialList = true;
                    System.assert(sw.serialList.size() == 1, jsRec);
                    sw.serialList = cusSerialList;
                }
            }
        }
        System.assert(hasSerialList, 'Expecting a serialWrapper list');


        // verify some data
        system.assertEquals(1, solList.size());
        system.assertEquals(sol.id, solList[0].id, 'Picked up the wrong SOL.');

        soJS = SalesOrderFulfillmentExt.createFulfillments((List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records, new List<String>());
        System.assert(soJS.success == false, 'Fulfillment should have failed.');
        System.assert(soJS.messages.size() == 1);
        System.assert(soJS.messages[0].values()[0].contains('Number of serials specified does not match the quantity to fulfill'), soJS.messages);

        // retrieve Lines in wrapper and update json with the correct amt of serials for creating fulfillment
        soJS = SalesOrderFulfillmentExt.getSOLines((String) salesOrder.id);

        /* Test error message for Mismastch quantity */
        for (SalesOrderFulfillmentExt.SOLWrapper jsRec : (List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records) {

            // initial fulfillment and serialWrapper is empty
            System.assert(jsRec.serialWrapperList.size() == 1);
            System.assert(jsRec.fulfillment != null);
            jsRec.qtyToFulfill = jsRec.soLine.Quantity_Ordered__c;
            System.assert(jsRec.soLine != null);
            System.assert(jsRec.qtyToFulfill != null);
            solList.add(jsRec.soLine);

            // if condition for creating serials on the Skid
            if (jsRec.soLine.product__r.Item__r.Item_Attribute__c != null && jsRec.soLine.product__r.Item__r.Item_Attribute__r.Serial_Number__c) {
                List<Serial__c> cusSerialList = new List<Serial__c>();
                for (Integer i = 0; i < jsRec.qtyToFulfill; i++) { // create ALL EXCEPT ONE serial to throw exception
                    cusSerialList.add(new Serial__c(name = 'Serial-' + i));
                }
                cusSerialList.add(new Serial__c(name = 'Serial-COPY-'));

                for (skidService3.SerialWrapper sw : jsRec.serialWrapperList) {
                    if (sw.serialList.size() == 1) hasSerialList = true;
                    System.assert(sw.serialList.size() == 1, jsRec);
                    sw.serialList = cusSerialList;
                }
            }
        }
        System.assert(hasSerialList, 'Expecting a serialWrapper list');

        soJS = SalesOrderFulfillmentExt.createFulfillments((List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records, new List<String>());
        System.assert(soJS.success == false, 'Fulfillment should have failed.');
        System.assert(soJS.messages.size() == 1);
        System.debug(loggingLevel.Error, '*** soJS.messages[0].values()[0]: ' + soJS.messages[0].values()[0]);
        System.debug(loggingLevel.Error, '*** label.Number_Of_Serials_Not_Matching_Quantity: ' + label.Number_Of_Serials_Not_Matching_Quantity);
        System.assert(soJS.messages[0].values()[0].contains(Label.Number_Of_Serials_Not_Matching_Quantity), soJS.messages);

        // retrieve Lines in wrapper and update json with the correct amt of serials for creating fulfillment
        soJS = SalesOrderFulfillmentExt.getSOLines((String) salesOrder.id);

        // create serials for all qty on skid

        for (SalesOrderFulfillmentExt.SOLWrapper jsRec : (List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records){
            jsRec.qtyToFulfill = jsRec.soLine.Quantity_Ordered__c;
            if (jsRec.soLine.product__r.Item__r.Item_Attribute__c!= null && jsRec.soLine.product__r.Item__r.Item_Attribute__r.Serial_Number__c){

                List<Serial__c> cusSerialList = new List<Serial__c>();
                for (Integer i = 0; i < jsRec.qtyToFulfill; i++) {
                    cusSerialList.add(new Serial__c(name = 'Serial-' + i));
                }

                for (skidService3.SerialWrapper sw : jsRec.serialWrapperList) {
                    if (sw.serialList.size() == 1) hasSerialList = true;
                    System.assert(sw.serialList.size() == 1, jsRec);
                    sw.serialList = cusSerialList; // set serialList with serials with names
                }
            }
        }
        Test.startTest();
        // this should be successful
        soJS = SalesOrderFulfillmentExt.createFulfillments((List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records, new List<String>());

        System.assert(soJS.success == true, soJS);
        System.assert(soJS.records.size() > 0, soJS);


        for (SalesOrderFulfillmentExt.SOLWrapper jsRec : (List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records) {
            System.assertNotEquals(jsRec.fulfillment.Quantity__c, null);
            System.assertNotEquals(jsRec.fulfillment.Type__c, null);

            for (skidService3.SerialWrapper sw : jsRec.serialWrapperList) {
                System.assert(sw.Skid != null);

            }
        }

        // verify skid qty and serial count
        List<Skid__c> skids = [select id, Customer__c, Item__c, Quantity__c, Type__c, Sales_Order_Line__r.Quantity_Ordered__c, (select id from Serials__r)
                               from Skid__c
                               where Sales_Order_Line__c = :sol.id];
        System.assert(skids.size() == 1, 'Expecting 1 skid in list: ' + skids);
        System.assert(skids[0].Serials__r.size() > 0);
        System.assert(skids[0].Quantity__c == skids[0].Sales_Order_Line__r.Quantity_Ordered__c);
        System.assertEquals( skids[0].Sales_Order_Line__r.Quantity_Ordered__c, skids[0].Serials__r.size());

        List<Serial__c> serials = [select id, (select id, Type__c from Serial_Transactions__r) from Serial__c];
        for (serial__c serial : serials) {
            System.assertEquals(1, serial.Serial_Transactions__r.size());
            System.assert(serial.Serial_Transactions__r[0].Type__c == 'Install Base');
        }

        // verify sol stuff
        sol = [select Id, Status__c, Quantity_Ordered__c, Quantity_Fulfilled__c,
               (SELECT Id, Quantity__c, SKID__c, SKID__r.Quantity__c, SKID__r.Type__c, Sales_Order_Line__c FROM Fulfillments__r)
               from Sales_Order_Line__c where id = : sol.id];

        System.assert(sol != null, 'SOL should not be null: ' + sol);
        System.assert(sol.Quantity_Ordered__c == sol.Quantity_Fulfilled__c, sol.Quantity_Ordered__c + ' should equal ' +  sol.Quantity_Fulfilled__c);
        System.assert(sol.Fulfillments__r.size() == 1, 'Expecting fulfillments: ' + sol.Fulfillments__r);
        System.assertEquals(sol.Status__c, 'Closed');
        system.assert(sol.Fulfillments__r[0].SKID__c != null);



        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SOPlanExt soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();

        sol = [select Id, product__r.Item__r.Class__r.Type__c, Quantity_Ordered__c, Status__c,
               product__r.Item__r.Non_Shippable__c, Sales_Order__r.Status__c, Has_Exceptions__c,
               product__r.Item__c, product__r.Item__r.Non_Inventory__c, product__r.Item__r.Source__c,
               (Select id from Shipment_Lines__r), (Select id from Fulfillments__r)
               from Sales_Order_Line__c
               where Sales_Order__c = :salesOrder.id and product__r.Item__c = :fuel.itemList[0].id Limit 1];

        sol2 = [select Id, product__r.Item__r.Class__r.Type__c, Quantity_Ordered__c, Status__c,
                product__r.Item__r.Non_Shippable__c, Sales_Order__r.Status__c, Has_Exceptions__c,
                product__r.Item__c, product__r.Item__r.Non_Inventory__c, product__r.Item__r.Source__c,
                (Select id from Shipment_Lines__r), (Select id from Fulfillments__r)
                from Sales_Order_Line__c
                where Sales_Order__c = :salesOrder.id and product__r.Item__c = :fuel.itemList[5].id Limit 1];

        System.assertEquals(sol2.Status__c, 'Open');
        System.assert(sol.Shipment_Lines__r.size() == 0, 'Expecting no SHL to be created for this SOL');
        System.assert(sol2.Shipment_Lines__r.size() == 1, 'Expecting no SHL to be created for this SOL');
    }

    public static testMethod void SalesOrderTest_CreateSalesOrderRMAFlowTest() {
        /* test fuel setup */

        List<Period__c> periodList = fuel.periodList;
        List<SKID__c> skids = fillStock();
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;

        Sales_Order__c so = fuel.salesOrder;

        Sales_Order_Line__c soline = fuel.salesOrder.Sales_Order_Lines__r[0];
        Sales_Order_Line__c soline1 = fuel.salesOrder.Sales_Order_Lines__r[1];
        Shipment__c shipmentforRMA;
        List<Shipment_Line__c> shlListforRMA;

        so.Type__c = 'Standard';
        so.Status__c = 'Open';
        update so;

        soline.Status__c = 'Open';
        soline.Fulfillment_Source__c = 'Inventory';
        soline.Quantity_Fulfilled__c = 15;
        soline1.Status__c = 'Open';
        soline1.Fulfillment_Source__c = 'Inventory';
        soline.Quantity_Fulfilled__c = 10;
        update soline;
        update soline1;
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 92  queries or less. Actual: ' + Limits.getQueries());



        Test.startTest();

        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Sales_Order__c> {so});
        setCon.setSelected(new List<Sales_Order__c> {so});
        SalesOrderRMAExt soRMAExt = new SalesOrderRMAExt(setCon);
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        List<ApexPages.Message> msgList1 = ApexPages.getMessages();
        System.assert(msgList.size() == 0, msgList);

        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();

        JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines(so.id);

        for (SalesOrderRMAExt.SalesOrderLineWrapper obj : (List<SalesOrderRMAExt.SalesOrderLineWrapper>) rmaLinesResult.records) {
            System.assert(obj.soLine.Related_Sales_Order_Line__c != null, obj.soLine);
            if (obj.soLine.Product__c == fuel.product.Id) {
                obj.soLine.Quantity_Ordered__c = -10;
                obj.soLine.Returned_To_Vendor__c = false;
                obj.soLine.Fulfillment_Source__c = 'Inventory';
                solList.add( obj.soLine);
            } else
                obj.soLine.Quantity_Ordered__c = 0;
        }
        System.assertEquals(1, solList.size());
        Sales_order__c header = (Sales_Order__c) SalesOrderRMAExt.getSODetails(so.id).records[0];
        header.Type__c = SalesOrderService.SO_TYPE_RMA;

        system.assert(header != null, 'Expecting RMA Header to not be null');

        JsonResult rma = SalesOrderRMAExt.createRMA(solList, header, new List<String>());

        Sales_Order_Line__c[] rmaLines = [select Id, Sales_Order__r.Type__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                          from Sales_Order_Line__c
                                          where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA];

        system.assertEquals(1, rmaLines.size());

        for (Sales_order_Line__c sol : rmaLines) {
            system.assert(sol.Related_Sales_Order_Line__c != null);
            System.assertEquals('Draft', sol.Status__c);
            System.assert(sol.Quantity_Ordered__c < 0, sol.Quantity_Ordered__c + 'Expecting negative qty');
        }

        Sales_order__c soRMA = rmaLines[0].Sales_Order__r;
        System.assertEquals('Draft', soRMA.Status__c);
        System.assert(soRMA.Related_Sales_Order__c != null);


        new SalesOrderService().plan(soRMA.id);
        rmaLines = [select Id, Has_Exceptions__c, Quantity_Fulfilled__c, Sales_Order__r.Has_Exceptions__c, Sales_Order__r.Type__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                    from Sales_Order_Line__c
                    where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA];

        for (Sales_order_Line__c sol : rmaLines) {
            System.assertEquals('Open', sol.Status__c, sol);
            system.assertEquals(false, sol.Has_Exceptions__c, ExceptionService.fetchExceptionTasks(new set<Id> {sol.id}));
        }
        Test.stopTest();
    }

    // Release SO with Non-shippable line and shippable line. Expect one SHL to be created. Fufullment should create one fulfillment record for the non-shippable line
    public static testMethod void SalesOrderTest_fulfillNonShippableIBSParentChildSalesOrderLines() {
        // parent SOL will be track install base and the children will not be. Expecting skids everywhere.

        Item_Attribute__c itemAttrObj = new Item_Attribute__c();
        itemAttrObj.Name = 'Attribute-1';
        itemAttrObj.Serial_Number__c = true;
        insert itemAttrObj;

        List<Item__c> itemList = new List<Item__c>();

        Item__c item1 = new Item__c();
        item1.Name = 'Server';
        item1.Description__c = 'Server';
        item1.Source__c = 'Manufactured';
        item1.Company__c = fuel.company.id;
        item1.Active__c = true;
        item1.Stocking_UOM__c = fuel.uomList[8].Id;
        item1.Packaging_UOM__c = JSON.serialize(new List<Id>{ fuel.uomList[8].Id });
        item1.Item_attribute__c = itemAttrObj.ID;
        item1.Track_Install_Base__c = true;
        item1.Non_Shippable__c = true;
        itemList.add(item1);

        Item__c item2 = new Item__c();
        item2.Name = 'Processor';
        item2.Description__c = 'Server';
        item2.Source__c = 'Manufactured';
        item2.Company__c = fuel.company.id;
        item2.Active__c = true;
        item2.Stocking_UOM__c = fuel.uomList[8].Id;
        item2.Packaging_UOM__c = JSON.serialize(new List<Id>{ fuel.uomList[8].Id });
        //item2.Item_attribute__c = itemAttrObj.ID;
        item2.Track_Install_Base__c = false;
        item2.Non_Shippable__c = true;
        itemList.add(item2);

        Item__c item3 = new Item__c();
        item3.Name = 'Motherboard';
        item3.Description__c = 'Server';
        item3.Source__c = 'Manufactured';
        item3.Company__c = fuel.company.id;
        item3.Active__c = true;
        item3.Stocking_UOM__c = fuel.uomList[8].Id;
        item3.Packaging_UOM__c = JSON.serialize(new List<Id>{ fuel.uomList[8].Id });
        //item3.Item_attribute__c = itemAttrObj.ID;
        item3.Track_Install_Base__c = false;
        item3.Non_Shippable__c = true;
        itemList.add(item3);

        insert itemList;

        fuel.customerShipTo.Track_Install_Base__c = true;
        update fuel.customerShipTo;

        Product__c parentProd = new Product__c(
            company__c = fuel.company.id,
            Name = item1.name,
            Item__c  = item1.id,
            Description__c = 'Product-10',
            Selling_UOM__c = fuel.uomList[8].ID,
            Weight__c = 13,
            Weight_UOM__c = fuel.uomList[3].ID,
            UPC_Code__c = '12345',
            Primary_Key__c = '123456' + item1.name,
            Dimension_UOM__c = fuel.uomList[6].ID,
            Length__c = 1,
            Width__c = 1,
            Height__c = 1,
            Pricebook_Line_Required__c = false
        );
        parentProd.Item__r = item1;
        insert parentProd;

        List<Product__c> prodList = new List<Product__c>();
        for (Item__c item : itemList) {
            if (item == item1) continue;
            Product__c p = new Product__c(
                company__c = fuel.company.id,
                Name = item.name,
                Item__c  = item.id,
                Description__c = 'Product-10',
                Selling_UOM__c = fuel.uomList[8].ID,
                Weight__c = 13,
                Weight_UOM__c = fuel.uomList[3].ID,
                UPC_Code__c = '12345',
                Primary_Key__c = '123456' + item.name,
                Dimension_UOM__c = fuel.uomList[6].ID,
                Length__c = 1,
                Width__c = 1,
                Height__c = 1,
                Pricebook_Line_Required__c = false
            );
            p.Item__r = item;
            prodList.add(p);
        }
        insert prodList;

        Sales_Order__c salesOrder = new Sales_Order__c(
            Company__c = fuel.company.id,
            Customer__c = fuel.customerSoldTo.id,
            Ship_To__c = fuel.customerShipTo.Id,
            Payment_Term__c = fuel.terms.id,
            Currency__c = fuel.company.Default_Transaction_Currency__c
        );
        //fuel.newSalesOrder();
        salesOrder.Ship_to__c = fuel.customerShipTo.Id;
        salesOrder.Bill_To__c = fuel.customerBillTo.Id;
        salesOrder.Currency__c = fuel.currencyUSD.id;
        salesOrder.Original_Sales_Order__c = 'so1234';
        insert salesOrder;

        Sales_Order_Line__c parentSOL = new Sales_Order_Line__c();
        parentSOL.Company__c = fuel.company.Id;
        parentSOL.Description__c = parentProd.Description__c;
        parentSOL.Discount_Percent__c = 2;
        parentSOL.Product__c = parentProd.Id;
        parentSOL.Product__r = parentProd;
        parentSOL.Quantity_Ordered__c = 1;
        parentSOL.Required_Date__c = System.today() + 5;
        parentSOL.Sales_Order__c = salesOrder.Id;
        parentSOL.Ship_From_Location__c = fuel.location2.Id;
        parentSOL.Unit_Price__c = 11.12;
        parentSOL.Memo__c = 'salesOrderLine';
        insert parentSOL;

        Set<Id> prodIds = KSE.grepIdSetFromList(prodList);
        List<Sales_Order_Line__c> salesOrderLines = new List<Sales_Order_Line__c>();
        for (Product__c prod : [select id, Description__c from Product__c where id IN: prodIds]) {
            Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
            salesOrderLine.Company__c = fuel.company.Id;
            salesOrderLine.Description__c = prod.Description__c;
            salesOrderLine.Discount_Percent__c = 2;
            salesOrderLine.Product__c = prod.Id;
            salesOrderLine.Product__r = prod;
            salesOrderLine.Parent_Sales_Order_Line__c = parentSOL.id;
            salesOrderLine.Quantity_Ordered__c = 1;
            salesOrderLine.Required_Date__c = System.today() + 5;
            salesOrderLine.Sales_Order__c = salesOrder.Id;
            salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
            salesOrderLine.Unit_Price__c = 11.12;
            salesOrderLine.Memo__c = 'salesOrderLine';
            salesOrderLines.add(salesOrderLine);
        }
        insert salesOrderLines;
        //Set<id> childLines = KSE.grepIdSetFromList(salesOrderLines);


        //salesOrderLines = [select id, Has_Exceptions__c from Sales_order_line__c where Sales_Order__c = ]

        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();

        JsonResult soJS = SalesOrderFulfillmentExt.getSOLines((String) salesOrder.id);

        system.assert(soJS.records != null, soJS);

        // create serials for all qty on skid
        for (SalesOrderFulfillmentExt.SOLWrapper jsRec : (List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records) {
            jsRec.qtyToFulfill = jsRec.soLine.Quantity_Ordered__c;
            if (jsRec.soLine.product__r.Item__r.Item_Attribute__c != null && jsRec.soLine.product__r.Item__r.Item_Attribute__r.Serial_Number__c) {
                List<Serial__c> cusSerialList = new List<Serial__c>();

               
                for (Integer i = 0; i < jsRec.qtyToFulfill; i++){
                    cusSerialList.add(new Serial__c(name= jsRec.soLine.Name + '-Serial-'+i));
                }
                //cusSerialList.add(new Serial__c());
                for (skidService3.SerialWrapper sw : jsRec.serialWrapperList) {
                    sw.serialList = cusSerialList; // set serialList with serials with names

                    System.assert(sw.serialList.size() == 1, sw.serialList);
                }
            }
        }
        Test.startTest();

        soJS = SalesOrderFulfillmentExt.createFulfillments((List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records, new List<String>());
        System.assert(soJS.success == true, soJS);
        System.assert(soJS.records.size() > 0, soJS);

        // verify skid qty and serial count
        List<Skid__c> skids = [select id, Sales_Order_Line__c, Customer__c, Item__c, Quantity__c, Type__c, Sales_Order_Line__r.Quantity_Ordered__c, (select id, name from Serials__r) from Skid__c ];
        for (skid__c skid : skids) {
            system.assert(skid.Serials__r.size() > 0);
        }

        List<Fulfillment__c> fuls = [select id, Type__c, Sales_Order_Line__c, Sales_Order_Line__r.Product__r.Item__r.Track_Install_Base__c, Sales_Order_Line__r.Sales_Order__r.Ship_To__r.Track_Install_Base__c, Skid__c from Fulfillment__c];
        system.assertEquals(3, fuls.size());


        for (fulfillment__c ful : fuls) {
            //system.assert(ful.Sales_Order_Line__r.Sales_Order__r.Ship_To__r.Track_Install_Base__c);
            //system.assert(ful.Sales_Order_Line__r.Product__r.Item__r.Track_Install_Base__c);
            system.assert(ful.Skid__c != null, ful);
        }

        solList = [select id from Sales_order_line__c where Sales_Order__c = :salesOrder.id];

        system.assertEquals(1, skids.size(), skids.size());

    }

    public static testMethod void SalesOrderTest_fulfillNonShippableNIBSParentChildSalesOrderLines() {
        // parent SOL will be track install base and the children will not be. Expecting skids everywhere.

        Item_Attribute__c itemAttrObj = new Item_Attribute__c();
        itemAttrObj.Name = 'Attribute-1';
        itemAttrObj.Serial_Number__c = true;
        insert itemAttrObj;

        List<Item__c> itemList = new List<Item__c>();

        Item__c item1 = new Item__c();
        item1.Name = 'Server';
        item1.Description__c = 'Server';
        item1.Source__c = 'Manufactured';
        item1.Company__c = fuel.company.id;
        item1.Active__c = true;
        item1.Stocking_UOM__c = fuel.uomList[8].Id;
        item1.Packaging_UOM__c = JSON.serialize(new List<Id>{ fuel.uomList[8].Id });
        //item1.Item_attribute__c = itemAttrObj.ID;
        item1.Track_Install_Base__c = false;
        item1.Non_Shippable__c = true;
        itemList.add(item1);

        Item__c item2 = new Item__c();
        item2.Name = 'Processor';
        item2.Description__c = 'Server';
        item2.Source__c = 'Manufactured';
        item2.Company__c = fuel.company.id;
        item2.Active__c = true;
        item2.Stocking_UOM__c = fuel.uomList[8].Id;
        item2.Packaging_UOM__c = JSON.serialize(new List<Id>{ fuel.uomList[8].Id });
        item2.Item_attribute__c = itemAttrObj.ID;
        item2.Track_Install_Base__c = true;
        item2.Non_Shippable__c = true;
        itemList.add(item2);

        Item__c item3 = new Item__c();
        item3.Name = 'Motherboard';
        item3.Description__c = 'Server';
        item3.Source__c = 'Manufactured';
        item3.Company__c = fuel.company.id;
        item3.Active__c = true;
        item3.Stocking_UOM__c = fuel.uomList[8].Id;
        item3.Packaging_UOM__c = JSON.serialize(new List<Id>{ fuel.uomList[8].Id });
        item3.Item_attribute__c = itemAttrObj.ID;
        item3.Track_Install_Base__c = true;
        item3.Non_Shippable__c = true;
        itemList.add(item3);

        insert itemList;

        fuel.customerShipTo.Track_Install_Base__c = true;
        update fuel.customerShipTo;

        Product__c parentProd = new Product__c(
            company__c = fuel.company.id,
            Name = item1.name,
            Item__c  = item1.id,
            Description__c = 'Product-10',
            Selling_UOM__c = fuel.uomList[8].ID,
            Weight__c = 13,
            Weight_UOM__c = fuel.uomList[3].ID,
            UPC_Code__c = '12345',
            Primary_Key__c = '123456' + item1.name,
            Dimension_UOM__c = fuel.uomList[6].ID,
            Length__c = 1,
            Width__c = 1,
            Height__c = 1,
            Pricebook_Line_Required__c = false
        );
        parentProd.Item__r = item1;
        insert parentProd;

        List<Product__c> prodList = new List<Product__c>();
        for (Item__c item : itemList) {
            if (item == item1) continue;
            Product__c p = new Product__c(
                company__c = fuel.company.id,
                Name = item.name,
                Item__c  = item.id,
                Description__c = 'Product-10',
                Selling_UOM__c = fuel.uomList[8].ID,
                Weight__c = 13,
                Weight_UOM__c = fuel.uomList[3].ID,
                UPC_Code__c = '12345',
                Primary_Key__c = '123456' + item.name,
                Dimension_UOM__c = fuel.uomList[6].ID,
                Length__c = 1,
                Width__c = 1,
                Height__c = 1,
                Pricebook_Line_Required__c = false
            );
            p.Item__r = item;
            prodList.add(p);
        }
        insert prodList;

        Sales_Order__c salesOrder = new Sales_Order__c(
            Company__c = fuel.company.id,
            Customer__c = fuel.customerSoldTo.id,
            Ship_To__c = fuel.customerShipTo.Id,
            Payment_Term__c = fuel.terms.id,
            Currency__c = fuel.company.Default_Transaction_Currency__c
        );
        //fuel.newSalesOrder();
        salesOrder.Ship_to__c = fuel.customerShipTo.Id;
        salesOrder.Bill_To__c = fuel.customerBillTo.Id;
        salesOrder.Currency__c = fuel.currencyUSD.id;
        salesOrder.Original_Sales_Order__c = 'so1234';
        insert salesOrder;

        Sales_Order_Line__c parentSOL = new Sales_Order_Line__c();
        parentSOL.Company__c = fuel.company.Id;
        parentSOL.Description__c = parentProd.Description__c;
        parentSOL.Discount_Percent__c = 2;
        parentSOL.Product__c = parentProd.Id;
        parentSOL.Product__r = parentProd;
        parentSOL.Quantity_Ordered__c = 1;
        parentSOL.Required_Date__c = System.today() + 5;
        parentSOL.Sales_Order__c = salesOrder.Id;
        parentSOL.Ship_From_Location__c = fuel.location2.Id;
        parentSOL.Unit_Price__c = 11.12;
        parentSOL.Memo__c = 'salesOrderLine';
        insert parentSOL;

        Set<Id> prodIds = KSE.grepIdSetFromList(prodList);
        List<Sales_Order_Line__c> salesOrderLines = new List<Sales_Order_Line__c>();
        for (Product__c prod : [select id, Description__c from Product__c where id IN: prodIds]) {
            Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
            salesOrderLine.Company__c = fuel.company.Id;
            salesOrderLine.Description__c = prod.Description__c;
            salesOrderLine.Discount_Percent__c = 2;
            salesOrderLine.Product__c = prod.Id;
            salesOrderLine.Product__r = prod;
            salesOrderLine.Parent_Sales_Order_Line__c = parentSOL.id;
            salesOrderLine.Quantity_Ordered__c = 1;
            salesOrderLine.Required_Date__c = System.today() + 5;
            salesOrderLine.Sales_Order__c = salesOrder.Id;
            salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
            salesOrderLine.Unit_Price__c = 11.12;
            salesOrderLine.Memo__c = 'salesOrderLine';
            salesOrderLines.add(salesOrderLine);
        }
        insert salesOrderLines;
        //Set<id> childLines = KSE.grepIdSetFromList(salesOrderLines);


        //salesOrderLines = [select id, Has_Exceptions__c from Sales_order_line__c where Sales_Order__c = ]

        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();

        JsonResult soJS = SalesOrderFulfillmentExt.getSOLines((String) salesOrder.id);

        system.assert(soJS.records != null, soJS);

        //verify the json obj was created correctly
        Boolean hasSerialList = false;

        // create serials for all qty on skid
        for (SalesOrderFulfillmentExt.SOLWrapper jsRec : (List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records) {
            jsRec.qtyToFulfill = jsRec.soLine.Quantity_Ordered__c;
            if (jsRec.soLine.product__r.Item__r.Item_Attribute__c != null && jsRec.soLine.product__r.Item__r.Item_Attribute__r.Serial_Number__c) {
                List<Serial__c> cusSerialList = new List<Serial__c>();

               
                 for (Integer i = 0; i < jsRec.qtyToFulfill; i++){
                    cusSerialList.add(new Serial__c(name= jsRec.soLine.Name + '-Serial-'+i));
                }
                //cusSerialList.add(new Serial__c());
                for (skidService3.SerialWrapper sw : jsRec.serialWrapperList) {
                    sw.serialList = cusSerialList; // set serialList with serials with names

                    System.assert(sw.serialList.size() == 1, sw.serialList);
                }
            } 
        }

        Test.startTest();
        // this should be successful


        soJS = SalesOrderFulfillmentExt.createFulfillments((List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records, new List<String>());
        System.assert(soJS.success == true, soJS);
        System.assert(soJS.records.size() > 0, soJS);

        // verify skid qty and serial count


        List<Fulfillment__c> fuls = [select id, Type__c, Sales_Order_Line__c, Sales_Order_Line__r.Product__r.Item__r.Track_Install_Base__c, Sales_Order_Line__r.Sales_Order__r.Ship_To__r.Track_Install_Base__c, Skid__c,
                                     Sales_Order_Line__r.Parent_Sales_Order_Line__c
                                     from Fulfillment__c];
        system.assertEquals(3, fuls.size());


        for (fulfillment__c ful : fuls) {
            // expecting only child lines to have skids
            if (ful.Sales_Order_Line__r.Parent_Sales_Order_Line__c != null) {
                system.assert(ful.skid__c != null, ful);
            } else {
                system.assert(ful.skid__c == null, ful);
            }
        }

        solList = [select id from Sales_order_line__c where Sales_Order__c = :salesOrder.id];


        List<Skid__c> skids = [select id, Sales_Order_Line__c, Customer__c, Item__c, Quantity__c, Type__c, Sales_Order_Line__r.Quantity_Ordered__c, (select id, name from Serials__r) from Skid__c ];

        for (skid__c skid : skids) {
            system.assert(skid.Serials__r.size() > 0);

        }
        system.assertEquals(2, skids.size());
    }

    //KNDY 3621 UOM Conversion
    /*
     * User shouldn't change UOM after it has been released.
     */
    public static testMethod void SalesOrderTest_UOMValidationonReleaseOrder() {

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customersoldTo.id;    // must be a sold to
        salesOrder.Payment_Term__c = fuel.terms.id;
        salesOrder.Status__c = 'Open';

        insert salesOrder;
        salesOrder.Weight_UOM__c = fuel.uomList[1].ID;
        Test.startTest();
        boolean matched = false;
        try {
            upsert salesOrder;
        } catch (Exception e) {
            String msg = e.getMessage();
            if (msg.contains('Unit of Measure cannot be changed after the Sales Order has been released.')) {
                matched = true;
            }
        }
        system.assertEquals(true, matched);
        Test.stopTest();
    }

    static testMethod void SalesOrderTest_test_SalesOrderLines_click_onclosed() {
        //TestData data = new TestData();
        Test.startTest();
        fuel.salesOrder.Status__c = 'Open';
        update fuel.salesOrder;

        for ( Sales_Order_Line__c sol : fuel.salesOrder.Sales_Order_Lines__r ) {
            sol.Status__c = 'Open';
            sol.Quantity_Backordered__c = 0.0;
            sol.Quantity_Fulfilled__c = sol.Quantity_Ordered__c;
        }
        update fuel.salesOrder.Sales_Order_Lines__r;
        fuel.salesOrder = fetchSO( fuel.salesOrder.id );

        for (Sales_Order_Line__c sol : fuel.salesOrder.Sales_Order_Lines__r) {
            System.assertEquals('Closed', sol.Status__c);
        }

        //system.debug(LoggingLevel.INFO, fuel.salesOrder );
        system.assert( fuel.salesOrder.Status__c == 'Closed' );

        SalesOrderLinesAddManageExt soc = new SalesOrderLinesAddManageExt(new apexpages.standardController(fuel.salesOrder));
        system.assert( soc != null );
        system.assert( soc.getHasNext() == false , ' expected has next is false ');
        Test.stopTest();
    }

    /*
     * test that the pricebook is created on a sales order even if it's not found on the customer
     */
    static testMethod void SalesOrderTest_test_companypricebook() {

        Customer__c customerSoldTo = new Customer__c();
        Customer__c customerShipTo = new Customer__c();

        // make a new sold to and ship to , with no price book
        customerSoldTo.name = 'Customer Sold To 2';
        customerSoldTo.recordTypeId =  fuel.CustomerRecordTypes.get('Sold_To');
        customerSoldTo.Company__c = fuel.company.id;
        customerSoldTo.Payment_Term__c = fuel.terms.ID;
        //customerSoldTo.Address__c = fuel.account.ID;
        customerSoldTo.Credit_Limit__c = 100000.0;
        customerSoldTo.Parent_Customer__c =  fuel.customerBillTo.id;
        customerSoldTo.Customer_Identifier__c = 'SDTEST1234';
        //     customerSoldTo.pricebook__c = pricebook.id;
        insert customerSoldTo;

        customerShipTo.name = 'Customer Ship To 2';
        customerShipTo.recordTypeId =  fuel.CustomerRecordTypes.get('Ship_To');
        customerShipTo.Company__c =  fuel.company.id;
        customerShipTo.Payment_Term__c =  fuel.terms.ID;
        //customerShipTo.Address__c =  fuel.account.ID;
        customerShipTo.Credit_Limit__c = 100000.0;
        customerShipTo.Parent_Customer__c = customerSoldTo.id;
        customerShipTo.Customer_Identifier__c = 'SHTEST1234';
        insert customerShipTo;

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;    // must be a sold to
        salesOrder.Payment_Term__c = fuel.terms.id;

        insert salesOrder;

        salesOrder = [ select Pricebook__c from Sales_Order__c where id = :salesOrder.id];
        system.assert ( salesOrder.Pricebook__c != null,
                        'epxected a price book' );
        system.assert ( salesOrder.Pricebook__c == fuel.pricebook.id,
                        'epxected a matching price book ' + fuel.pricebook );
    }

    static testmethod void SalesOrderTest_validationcheck() {

        Map<String, String> CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');
        boolean matched = false;

        // inserting a corporate parent
        customer__c  customerParent = new customer__c();
        system.assert( CustomerRecordTypes.get('Corporate_Parent') != null, 'expected valid id for corp to record type on customer');
        customerParent.name = fuel.company.Name + ' Customer Corp Parent 2';
        customerParent.recordTypeId = CustomerRecordTypes.get('Corporate_Parent');
        customerParent.Company__c = fuel.company.id;
        customerParent.Payment_Term__c = fuel.terms.ID;
        //customerParent.Address__c =testVC.account.ID;
        customerParent.Credit_Limit__c = 100000.0;
        customerParent.Customer_Identifier__c = 'CPTES45890';
        insert customerParent;

        // Inserting a new corporate parent
        customer__c  customerParent1 = new customer__c();
        system.assert( CustomerRecordTypes.get('Corporate_Parent') != null, 'expected valid id for corp to record type on customer');
        customerParent.name = fuel.company.Name + ' Customer Corp Parent 3';
        customerParent.recordTypeId = CustomerRecordTypes.get('Corporate_Parent');
        customerParent.Company__c = fuel.company.id;
        customerParent.Payment_Term__c = fuel.terms.ID;
        //customerParent.Address__c =testVC.account.ID;
        customerParent.Credit_Limit__c = 10000.0;
        customerParent.Customer_Identifier__c = 'DPTES45890';
        insert customerParent1;

        customer__c  customerBillTo = new customer__c();
        system.assert( CustomerRecordTypes.get('Bill_To') != null, 'expected valid id for bill to record type on customer');
        customerBillTo.name = 'Customer Bill To 1';
        customerBillTo.recordTypeId = CustomerRecordTypes.get('Bill_To');
        customerBillTo.Company__c = fuel.company.id;
        customerBillTo.Payment_Term__c = fuel.terms.ID;
        //customerBillTo.Address__c = fuel.account.ID;
        customerBillTo.Credit_Limit__c = 100000.0;
        customerBillTo.Parent_Customer__c = customerParent.id;
        //customerBillTo.Top_Parent_Customer__c = customerParent.Id;
        customerBillTo.Customer_Identifier__c = 'BDTEST1238';
        insert customerBillTo;

        customer__c  customerBillTo1 = new customer__c();
        system.assert( CustomerRecordTypes.get('Bill_To') != null, 'expected valid id for bill to record type on customer');
        customerBillTo1.name = 'Customer Bill To 2';
        customerBillTo1.recordTypeId = CustomerRecordTypes.get('Bill_To');
        customerBillTo1.Company__c = fuel.company.id;
        customerBillTo1.Payment_Term__c = fuel.terms.ID;
        //customerBillTo1.Address__c = fuel.account.ID;
        customerBillTo1.Credit_Limit__c = 100000.0;
        customerBillTo1.Parent_Customer__c = fuel.customerParent.id;
        //customerBillTo.Top_Parent_Customer__c = customerParent.Id;
        customerBillTo1.Customer_Identifier__c = 'BDTEST1234';
        insert customerBillTo1;

        customer__c  customerSoldTo1 = new customer__c();
        system.assert( CustomerRecordTypes.get('Sold_To') != null, 'expected valid id for sold to record type on customer');
        customerSoldTo1.name = 'Customer Sold To 2';
        customerSoldTo1.recordTypeId = CustomerRecordTypes.get('Sold_To');
        customerSoldTo1.Company__c = fuel.company.id;
        customerSoldTo1.Payment_Term__c = fuel.terms.ID;
        //customerSoldTo1.Address__c = fuel.account.ID;
        customerSoldTo1.Credit_Limit__c = 100000.0;
        customerSoldTo1.Parent_Customer__c = fuel.customerBillTo.id;
        customerSoldTo1.Customer_Identifier__c = 'SDTEST9081';
        //customerSoldTo.Top_Parent_Customer__c = customerParent.Id;
        insert customerSoldTo1;

        // updated the parent of soldto to be customerBillTo1 and making sure that the validation is properly enforced
        customer__c soldtoCust = fuel.customerSoldTo ;
        soldtoCust.Parent_customer__c = customerBillTo1.id;
        update soldtoCust;

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Bill_To__c = fuel.customerBillTo.Id;
        salesOrder.Customer__c = soldtoCust.id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        try {
            insert salesOrder;
        } catch (exception e) {
            String msg = e.getMessage();
            if (msg.contains('Please make sure the Sold To\'s parent is a bill-to within its hierarchy.')) {
                matched = true;
            }
        }
        system.assertEquals(true, matched);

        // updated the parent of shipto to be customersoldTo1 and making sure that the validation is properly enforced
        customer__c shiptoCust = fuel.customerShipTo ;
        shiptoCust.Parent_customer__c = customerSoldTo1.id;
        update shiptoCust;

        Sales_Order__c salesOrder1 = new Sales_Order__c();
        salesOrder1.Company__c = fuel.company.id;
        salesOrder1.Bill_To__c = fuel.customerBillTo.Id;
        salesOrder1.Customer__c = fuel.customerSoldTo.Id;
        salesOrder1.Ship_To__c = shiptoCust.Id;
        salesOrder1.Payment_Term__c = fuel.terms.id;
        try {
            insert salesOrder1;
        } catch (exception e) {
            String msg = e.getMessage();
            if (msg.contains('The customers on the Sales Order are not within the same hierarchy.  Please make sure the Ship-To is part of the Sold-To\'s hierarchy AND the top parents for both match.')) {
                matched = true;
            }
        }
        system.assertEquals(true, matched);

        // updating the top parent of shipto to be customerParent1, top parent of soldto to be customerparent and making sure that the validation is properly enforced
        customer__c shiptoTop = fuel.customerShipTo ;
        shiptoTop.Top_Parent_Customer__c = customerParent1.id;
        update shiptoTop;
        customer__c soldtoTop = fuel.customersoldTo ;
        soldtoTop.Top_Parent_Customer__c = customerParent.id;
        update soldtoTop;

        Sales_Order__c salesOrder11 = new Sales_Order__c();
        salesOrder11.Company__c = fuel.company.id;
        salesOrder11.Bill_To__c = fuel.customerBillTo.Id;
        salesOrder11.Customer__c = fuel.customerSoldTo.Id;
        salesOrder11.Ship_To__c = fuel.customerShipTo.Id;   // shiptoCust.Id;
        salesOrder11.Payment_Term__c = fuel.terms.id;

        try {
            insert salesOrder11;
        } catch (exception e) {
            String msg = e.getMessage();
            if (msg.contains('The customers on the Sales Order are not within the same hierarchy.  Please make sure the Ship-To is part of the Sold-To\'s hierarchy AND the top parents for both match.')) {
                matched = true;
            }
        }
        system.assertEquals(true, matched);

        // updated the top parent of billto to be customerparent1 and checking that the validation for the top parent of billto and soldto is properly enforced
        customer__c billtoTop = fuel.customerBillTo;
        billtoTop.Top_Parent_customer__c = customerparent1.id;
        update billtoTop ;

        sales_Order__c salesOrder2 = new sales_Order__c();
        salesOrder2.Company__c = fuel.company.id;
        salesOrder2.Bill_To__c = billtoTop.Id;
        salesOrder2.Customer__c = soldtoTop.Id;
        salesOrder2.Ship_To__c = shiptoCust.Id;
        salesOrder2.Payment_Term__c = fuel.terms.id;

        try {
            insert salesOrder2;
        } catch (exception e) {
            String msg = e.getMessage();
            if (msg.contains('The Bill-To and Sold-To are not part of the same customer hierarchy. Please pick a Sold-To that exists under the Bill-To')) {
                matched = true;
            }
        }
        system.assertEquals(true, matched);
    }

    /*******************************************************************************************************************************************************************************************************
    *   SalesOrderLineTest -  TESTS
    *******************************************************************************************************************************************************************************************************/

    static testMethod void SalesOrderLineTest_testStandardCostAndMargin() {

        List<Item_Cost__c> itemCosts = [SELECT Id FROM Item_Cost__c WHERE Item__c IN (:fuel.itemList[0].Id, :fuel.itemList[5].Id)];

        system.assertNotEquals(0, itemCosts.size());

        system.assert(fuel.salesOrder.Id != null);

        for (Sales_Order_Line__c sol : fuel.salesOrder.Sales_Order_Lines__r) {
            sol.Ship_From_Location__c = fuel.location.Id;
        }

        update fuel.salesOrder.Sales_Order_Lines__r;

        List<Sales_Order_Line__c> sols = [SELECT Id, Extended_Price__c, Standard_Cost__c, Margin__c, Quantity_Ordered__c
                                          FROM Sales_Order_Line__c
                                          WHERE Sales_Order__c = :fuel.salesOrder.Id];

        system.assertNotEquals(0, sols.size());

        for (Sales_Order_Line__c sol : sols) {
            system.assertNotEquals(0, sol.Extended_Price__c);
            system.assertNotEquals(0, sol.Standard_Cost__c);
            system.assertEquals((sol.Extended_Price__c - (sol.Quantity_Ordered__c * sol.Standard_Cost__c).setScale(2, System.RoundingMode.HALF_UP)), (sol.Margin__c).setScale(2, System.RoundingMode.HALF_UP));
        }
    }

    //KNDY-3688: Tests addition of pallet weight to sales order line
    static testMethod void SalesOrderLineTest_test_Pallet_Weight_Addition_To_SO_Weight() {

        Product__c prod2 = new Product__c(
            company__c = fuel.company.id,
            Name = 'Product-15a',
            Item__c  = fuel.itemList[5].ID,
            Description__c = 'Product-15',
            Selling_UOM__c = fuel.uomList[8].ID,
            Weight__c = 5,
            Weight_UOM__c = fuel.uomList[0].ID,
            Dimension_UOM__c = fuel.uomList[6].ID,
            Length__c = 1,
            Width__c = 1,
            Height__c = 1
        );
        prod2.Units_per_layer__c = 10;
        prod2.Layers_per_pallet__c = 1;
        //fuel.product2 = prod2; // BA: Remove?

        Product__c palletProduct = new Product__c(
            company__c = fuel.company.id,
            Name = 'Product 1c',
            Item__c  = fuel.itemList[0].ID,
            Description__c = 'Product-10',
            Selling_UOM__c = fuel.uomList[8].ID,
            Weight__c = 13,
            Weight_UOM__c = fuel.uomList[3].ID,
            Dimension_UOM__c = fuel.uomList[6].ID,
            Length__c = 1,
            Width__c = 1,
            Height__c = 1
        );
        palletProduct.Units_per_layer__c = 10;
        palletProduct.Layers_per_pallet__c = 1;
        //fuel.product = palletProduct; // BA: Remove?

        insert new Product__c[] { palletProduct, prod2 };

        List<Pricebook_Line__c> pbls = new List<Pricebook_Line__c>();
        Pricebook_Line__c iPL1 = new Pricebook_Line__c();
        iPL1.product__c = palletProduct.Id;
        iPL1.pricebook__c = fuel.pricebook.id;
        iPL1.price__c = 45;
        iPL1.start_date__c = system.today().adddays(0);
        iPL1.end_date__c = system.today().adddays(10);
        pbls.add(iPL1);

        Pricebook_Line__c iPL2 = new Pricebook_Line__c();
        iPL2.product__c = prod2.Id;
        iPL2.pricebook__c = fuel.pricebook.id;
        iPL2.price__c = 25;
        iPL2.start_date__c = system.today().adddays(0);
        iPL2.end_date__c = system.today().adddays(10);
        pbls.add(iPL2);
        insert pbls;
        // Accessing it like this to make sure records are created for conversions
        Object conversions = fuel.uomcList;

        // Associate a Pallet product
        fuel.customerShipTo.Pallet_Product__c = palletProduct.Id;
        update fuel.customerShipTo;

        // Add a bad SO line whose quantity doesnt matches the product's quantity factors
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = prod2.Id;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        salesOrderLine.Description__c = prod2.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = fuel.salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 60;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Ship_From_Location__c = fuel.location.Id;
        salesOrderLine.Weight_UOM__c = prod2.Weight_UOM__c;
        insert salesOrderLine;


        Test.startTest();

        System.assert(ExceptionService.fetchExceptionTasks(new Set<Id> {salesOrderLine.Id}).isEmpty(), 'Should have no exceptions on this line' + ExceptionService.fetchExceptionTasks(new Set<Id> {salesOrderLine.Id}));


        Sales_Order_Line__c sol = [Select Weight__c, Number_of_pallets__c from Sales_Order_Line__c Where Id = :salesOrderLine.Id];

        Decimal expectedWeightWithoutPallets = salesOrderLine.Quantity_Ordered__c * prod2.Weight__c; // UOM is same, so no conversion

        system.assert(sol.Number_of_pallets__c != null);
        system.assert(palletProduct.Weight__c != null);
        Decimal expectedWeightWithPallets = expectedWeightWithoutPallets + (sol.Number_of_pallets__c * palletProduct.Weight__c * 0.0625);

        System.assertEquals(expectedWeightWithPallets, sol.Weight__c);

        Test.stopTest();
    }

    // OTC-698: Release an SO, change qty on a sol to 0 causing the line to be closed, and then release causing the Shipment qty to update to 0.
    //static testMethod void SalesOrderLineTest_zeroQuantitySolUpdateShipment() {

    //    test.startTest();

    //    ApexPages.StandardController con;
    //    SOPlanExt planExt;

    //    Sales_Order__c salesOrder = fuel.SalesOrder;

    //    for (Sales_order_Line__c sol : SalesOrder.Sales_Order_Lines__r) {
    //        system.assert(sol.Status__c == 'Draft', sol);
    //    }

    //    con = new ApexPages.StandardController(salesOrder);
    //    planExt = new SOPlanExt(con);
    //    planExt.plan();
    //    System.assertEquals(false, ExceptionService.hasErrors, ExceptionService.messages);
    //    System.assertEquals(false, planExt.hasErrors);

    //    Sales_Order_Line__c[] sols = [select id, Status__c, Quantity_Ordered__c, Has_Exceptions__c
    //                                  from Sales_Order_Line__c];

    //    for (Sales_order_Line__c sol : sols) {
    //        system.assert(sol.Status__c == 'Open', sol);
    //    }

    //    sols[0].Quantity_Ordered__c = 0;
    //    Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
    //    insert rc;
    //    sols[0].Quantity_Change_Reason__c = rc.Id;
    //    update sols[0];

    //    sols = [select id, status__c, Quantity_Ordered__c,
    //            (select id, Quantity_planned__c, shipment__c from Shipment_Lines__r)
    //            from Sales_Order_Line__c];

    //    system.assert(sols.size() == 2);
    //    for (Sales_Order_Line__c sol : sols) {
    //        if (sol.id == fuel.salesOrder.Sales_Order_Lines__r[0].id) {
    //            system.assertEquals(0, sol.Quantity_Ordered__c);
    //            system.assertNotEquals(0, sol.Shipment_Lines__r[0].Quantity_planned__c);
    //            system.assertEquals('Closed', sol.Status__c, sol.Status__c + ' ' + sols);
    //        } else {
    //            system.assertNotEquals(0, sol.Quantity_Ordered__c);
    //            system.assertNotEquals(0, sol.Shipment_Lines__r[0].Quantity_planned__c);
    //            system.assertEquals('Open', sol.Status__c, sol.Status__c + ' ' + sols);
    //        }
    //    }

    //    planExt.plan();
    //    System.assertEquals(false, planExt.hasErrors);

    //    sols = [select id, status__c, Quantity_Ordered__c,
    //            (select id, Quantity_planned__c, shipment__c from Shipment_Lines__r)
    //            from Sales_Order_Line__c];
    //    system.assert(sols.size() == 2);
    //    for (Sales_Order_Line__c sol : sols) {
    //        if (sol.id == fuel.salesOrder.Sales_Order_Lines__r[0].id) {
    //            system.assertEquals(0, sol.Shipment_Lines__r[0].Quantity_planned__c);
    //        }
    //    }
    //}

    // KNDY-3939
    // Steps:
    //  Step 1: Create product where price book entry required = false (i.e. this is not checked). By choosing either expense or miscellaneous.
    //  Step 2: Add this product to your price book at $0.
    //  Step 2 a: Make this either use fixed price (true or false). Neither iterations works.
    //  Step 3: Create SO
    //  Step 4: Create SO line, selecting your product and entering a price value (say $100)
    //  Step 5: Hit save and return
    //  Problem:
    //  When hitting save and return, user get sales order line exception: product price does not match sales order unit price.
    //  Expected Behavior:
    //  No sales order line exception is created.
    static testMethod void SalesOrderLineTest_testKndy3939() {

        String itemName = 'Freight';
        Item__c item = new Item__c();
        item.name = fuel.company.Name + itemName;
        item.Description__c = 'Item-' + itemName;
        item.Source__c = 'Miscellaneous';
        item.Non_Inventory__c = true;
        item.Class__c = fuel.clsobj.ID;
        item.ABC_Code__c = 'C';
        item.company__c = fuel.company.id;
        item.Active__c = true;
        item.Stocking_UOM__c = fuel.uomObj.ID;
        item.Packaging_UOM__c = JSON.serialize(new List<Id>{ fuel.uomObj.Id });
        insert item;

        List <product__c> prodList = new List <product__c>();
        Product__c product = new Product__c(
            company__c = fuel.company.id,
            Name = itemName + '1',
            Item__c  = item.ID,
            Description__c = itemname,
            Selling_UOM__c = fuel.uomObj.ID,
            Weight__c = 13,
            Weight_UOM__c = fuel.uomList[3].ID,
            Dimension_UOM__c = fuel.uomInch.ID,
            Length__c = 1,
            Width__c = 1,
            Height__c = 1,
            Pricebook_Line_Required__c = false
        );
        prodList.add(product);

        Product__c product2 = new Product__c(
            company__c = fuel.company.id,
            Name = itemName + '2',
            Item__c  = item.ID,
            Description__c = itemname,
            Selling_UOM__c = fuel.uomObj.ID,
            Weight__c = 13,
            Weight_UOM__c = fuel.uomList[3].ID,
            Dimension_UOM__c = fuel.uomInch.ID,
            Length__c = 1,
            Width__c = 1,
            Height__c = 1,
            Pricebook_Line_Required__c = true
        );
        prodList.add(product2);

        insert prodList;

        Pricebook__c pricebook = fuel.pricebook;

        List <Pricebook_Line__c> pblist = new List <Pricebook_Line__c>();
        Pricebook_Line__c pl = new Pricebook_Line__c();
        pl.product__c = product.id;
        pl.pricebook__c = pricebook.id;
        pl.price__c = 0;
        pl.Use_Fixed_Pricing__c = true;
        pl.Start_date__c = system.today();
        pblist.add(pl);

        Pricebook_Line__c pl2 = new Pricebook_Line__c();
        pl2.product__c = product2.id;
        pl2.pricebook__c = pricebook.id;
        pl2.price__c = 0;
        pl2.Use_Fixed_Pricing__c = true;
        pl2.Start_date__c = system.today();
        pblist.add(pl2);

        insert pblist;

        // accessing it before Test.startTest() to make sure limits are not consumed later
        Customer__c custShipTo = fuel.customerShipTo;

        Test.startTest();

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Bill_To__c = fuel.customerBillTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        insert salesOrder;

        List <Sales_Order_Line__c> soList = new List <Sales_Order_Line__c> ();

        // Add a bad SO line whose quantity doesnt matches the product's quantity factors
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = product.Id;
        salesOrderLine.Product__r = product;
        salesOrderLine.Product__r.Item__c = item.Id;
        salesOrderLine.Product__r.Item__r = item;
        salesOrderLine.Description__c = product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 5;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Unit_Price__c = 5;
        salesOrderLine.Ship_From_Location__c = fuel.location.Id;
        soList.add(salesOrderLine);

        Sales_Order_Line__c salesOrderLine2 = new Sales_Order_Line__c();
        salesOrderLine2.Product__c = product2.Id;
        salesOrderLine2.Product__r = product;
        salesOrderLine2.Product__r.Item__c = item.Id;
        salesOrderLine2.Product__r.Item__r = item;
        salesOrderLine2.Description__c = product.Description__c;
        salesOrderLine2.Company__c = fuel.company.id;
        salesOrderLine2.Sales_Order__c = salesOrder.Id;
        salesOrderLine2.Quantity_Ordered__c = 5;
        salesOrderLine2.Required_Date__c = System.today() + 5;
        //salesOrderLine2.Unit_Price__c = 5;
        salesOrderLine2.Ship_From_Location__c = fuel.location.Id;
        soList.add(salesOrderLine2);
        try{
            insert soList;
        }
        catch(Exception e){
            system.assert(false,e.getMessage()+'::'+e.getStackTraceString());
        }
        system.debug(LoggingLevel.info, 'solist: ' + soList);


        //KNDY-2551
        salesOrderLine.Quantity_Ordered__c = 4;
        Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
        insert rc;
        salesOrderLine.Quantity_Change_Reason__c = rc.Id;
        update salesOrderLine;

        System.assertEquals(false, ExceptionService.hasOpenTask(salesOrderLine.Id, ExceptionUtil.PRODUCT_PRICE_MISMATCH_UNIT_PRICE.code), 'Price should be fine, as product doesnot needs pricebook entry');

        system.debug(LoggingLevel.info, salesOrderLine);
        system.assertNotEquals(salesOrderLine.unit_price__c, 0);

        new SalesOrderService().plan(salesOrder.id);
        System.assertEquals(false, ExceptionService.hasErrors, ExceptionService.messages );

        system.debug(LoggingLevel.info, 'SOL after release');
        soList = [select id, product__c, status__c, product__r.Pricebook_Line_Required__c, unit_price__c from Sales_Order_Line__c where id = : salesOrderLine.id or id = :salesOrderLine2.id];
        //for (sales_Order_Line__c sol : soList){
        //    system.debug(LoggingLevel.info, sol.status__c + ' ' + sol.Product__c + '( ' + sol.product__r.Pricebook_Line_Required__c + ' )' + ': ' + sol.Unit_Price__c);
        //}
        system.assertNotEquals(soList[0].unit_price__c, soList[1].unit_price__c, 'SOLs should have different prices');
        system.assertNotEquals(salesOrderLine.unit_price__c, 0);

        Test.stopTest();
    }


    //KNDY-3835:
    //Tries to create an overweight sales order and asserts if Sales Order release fails because of the same.
    //Then overrides the exception task created because of overweight, and checks if release succeeds
    static testMethod void SalesOrderLineTest_test_SO_Release_By_OverWeight_Override_Exception_Task() {

        Means_of_Transport__c mot = new Means_of_Transport__c();
        mot.Code__c = 'LTL';
        mot.Mode_of_Transport__c = 'LTL';
        // Set max to a high value to avoid exceptions in other test cases
        mot.Maximum_Cube__c = 1000000;
        mot.Maximum_Weight__c = 1000000;
        mot.Maximum_Cube__c = 5000;
        mot.Maximum_Weight__c = 43000;
        fuel.meansOfTransport = mot;
        insert fuel.meansOfTransport;

        Product__c prd1 = fuel.product;
        prd1.Length__c = 1;
        prd1.Width__c = 1;
        prd1.Height__c = 1;
        prd1.Weight__c = 1000;
        prd1.Dimension_UOM__c = fuel.uomList[7].Id;
        update prd1;

        //Pricebook_Line__c iPL1 = new Pricebook_Line__c();
        //iPL1.product__c = prd1.Id;
        //iPL1.pricebook__c = fuel.pricebook.id;
        //iPL1.price__c = 45;
        //iPL1.start_date__c = system.today().adddays(0);
        //iPL1.end_date__c = system.today().adddays(10);
        //insert iPL1;

        Sales_Order__c salesOrder = new Sales_Order__c(
            Company__c = fuel.company.id,
            Customer__c = fuel.customerSoldTo.id,
            Ship_To__c = fuel.customerShipTo.Id,
            Payment_Term__c = fuel.terms.id,
            Currency__c = fuel.company.Default_Transaction_Currency__c
        );
        salesOrder.pricebook__c = fuel.pricebook.id;
        salesOrder.Means_of_Transport__c = mot.Id;
        salesOrder.Bill_To__c = fuel.customerBillTo.Id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        insert salesOrder;

        // Add a bad SO line whose quantity doesnt matches the product's quantity factors
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 60;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Ship_From_Location__c = fuel.location.Id;
        salesOrderLine.pricebook__c = fuel.pricebook.id;

        insert salesOrderLine;


        Test.startTest();

        System.assert(ExceptionService.fetchExceptionTasks(new Set<Id> {salesOrderLine.Id}).isEmpty(), 'Should have no exceptions on this line' + ExceptionService.fetchExceptionTasks(new Set<Id> {salesOrderLine.Id}));

        Sales_Order__c soReloaded = [Select Id, Total_Order_Volume__c, Total_Weight__c, Number_of_pallets__c , Exceeds_Max_Weight__c, Dimensional_Weight__c, Maximum_Dimensional_Percent__c from Sales_Order__c Where Id = :salesOrder.Id];
        System.debug (LoggingLevel.INFO, 'soReloaded:' + soReloaded);
        System.assert(soReloaded.Exceeds_Max_Weight__c, 'SO Dimensional_Weight should exceed Means_of_Transport > Max Weight__c');

        //SOPlanExt planExt = new SOPlanExt(new ApexPages.StandardController(salesOrder));
        //planExt.plan();

        new SalesOrderService().plan(salesOrder.Id);
        System.assert(ExceptionService.hasErrors , 'Plan/Release should fail, as order is over weight ');

        Task[] openTasks = ExceptionService.fetchTasks(new Set<Id> {salesOrder.Id}, ExceptionUtil.SO_OVER_WEIGHT_EXCEPTION.code , TaskType.EXCEPTION_STATUS_OPEN);

        System.assertEquals(1, openTasks.size(), 'One open exception task should be created for Over weight SO');
        Task overweightTask = openTasks[0];
        // override exception and let use release it
        overweightTask.Status = TaskType.EXCEPTION_STATUS_OVERRIDDEN;
        update overweightTask;

        //planExt = new SOPlanExt(new ApexPages.StandardController(salesOrder));
        //planExt.plan();
        ExceptionService.messages.clear();
        new SalesOrderService().plan(salesOrder.Id);
        System.assertEquals(false, ExceptionService.hasErrors, 'Plan should be successful.  pageMsgs: ' + ExceptionService.messages); //KNDY-4989

        // check if dimension weight is copied correctly to shipment
        Shipment_Line__c[] shipLines = [Select Shipment__r.Dimensional_Weight__c from Shipment_Line__c Where Sales_Order__c = :salesOrder.Id];
        System.debug (LoggingLevel.INFO, shipLines);
        System.assert(shipLines != null && !shipLines.isEmpty(), 'Ship lines should come as release of sales order was success !');
        //Shipment Lines are not copied from the Sales order
        //OTC-189
        System.assertEquals(soReloaded.Dimensional_Weight__c, 60000.00);



        Test.stopTest();
    }

    //KNDY-3804:     Tries to create an under weight sales order and asserts if Sales Order release fails because of the same.
    static testMethod void SalesOrderLineTest_test_SO_Release_For_UnderWeight() {

        Means_of_Transport__c mot = new Means_of_Transport__c();
        mot.Code__c = 'LTL';
        mot.Mode_of_Transport__c = 'LTL';
        // Set max to a high value to avoid exceptions in other test cases
        mot.Maximum_Cube__c = 5000;
        mot.Maximum_Weight__c = 43000;
        mot.Minimum_Cube__c = 40;
        mot.Minimum_Weight__c = 40000;
        insert mot;


        fuel.product.Length__c = 1;
        fuel.product.Width__c = 1;
        fuel.product.Height__c = 1;
        fuel.product.Weight__c = 1000;
        fuel.product.Dimension_UOM__c = fuel.uomList[7].Id;
        update fuel.product;

        Sales_Order__c salesOrder = new Sales_Order__c(
            Company__c = fuel.company.id,
            Customer__c = fuel.customerSoldTo.id,
            Ship_To__c = fuel.customerShipTo.id,
            Payment_Term__c = fuel.terms.id,
            Currency__c = fuel.company.Default_Transaction_Currency__c
        );
        salesOrder.Means_of_Transport__c = mot.Id;
        salesOrder.Bill_To__c = fuel.customerBillTo.Id;
        insert salesOrder;

        // Add a bad SO line whose quantity doesnt matches the product's quantity factors
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        salesOrderLine.Quantity_Ordered__c = 10;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Ship_From_Location__c = fuel.location.Id;

        insert salesOrderLine;


        Test.startTest();

        System.assert(ExceptionService.fetchExceptionTasks(new Set<Id> {salesOrderLine.Id}).isEmpty(), 'Should have no exceptions on this line' + ExceptionService.fetchExceptionTasks(new Set<Id> {salesOrderLine.Id}));

        //SOPlanExt planExt = new SOPlanExt(new ApexPages.StandardController(salesOrder));
        //planExt.plan();

        //new SalesOrderService().plan(salesOrder.Id);

        //OTC-197 (Removing the Under weight exception during SO release)
        /*
        System.assert(ExceptionService.hasErrors, 'Plan/Release should fail, as order is under weight ');

        System.assert(ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_UNDER_WEIGHT_EXCEPTION.code), 'Release should create an exception on under weight Sales order ');
        */
        //KNDY-2551
        Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
        insert rc;
        salesOrderLine.Quantity_Change_Reason__c = rc.Id;

        // Change Sales order line quantity to get out of exception
        salesOrderLine.Quantity_Ordered__c = 40;
        update salesOrderLine;

        ExceptionService.messages.clear();

        //planExt = new SOPlanExt(new ApexPages.StandardController(salesOrder));
        //planExt.plan();
        new SalesOrderService().plan(salesOrder.Id);
        System.assertEquals(false, ExceptionService.hasErrors, 'Unexpected Errors: ' + ExceptionService.messages);

        System.assert(false == ExceptionService.hasOpenTask(salesOrder.Id, ExceptionUtil.SO_UNDER_WEIGHT_EXCEPTION.code), 'Release should not create a exception on this Sales order ');

        // check if dimension weight is copied correctly to shipment
        Shipment_Line__c[] shipLines = [Select Shipment__r.Dimensional_Weight__c from Shipment_Line__c Where Sales_Order__c = :salesOrder.Id];
        System.debug (LoggingLevel.INFO, shipLines);
        System.assert(shipLines != null && !shipLines.isEmpty(), 'Ship lines should come as release of sales order was success !');


        Sales_Order__c soReloaded = [Select Id, Total_Order_Volume__c, Total_Weight__c, Number_of_pallets__c , Exceeds_Max_Weight__c, Dimensional_Weight__c, Maximum_Dimensional_Percent__c from Sales_Order__c Where Id = :salesOrder.Id];

        //System.debug (LoggingLevel.INFO, 'soReloaded:' + soReloaded);

        //OTC-189
        System.assertEquals(soReloaded.Dimensional_Weight__c, 40000.00);


        Test.stopTest();
    }

    //JIRA - 2891
    //This test case setups circumstances so that a order quantity exception will be generated i.e.
    //- SoldTo Customer on SO has "Order_Quantity_Factor_At__c"  = 'Pallet'
    //- SOLine->Product has Units/Layer and Layers/Pallet mentioned.
    //- SOLine->Order Qty is not even with Products' calculated one i.e. Units_per_Pallet__c
    //This test also tests if the Qty exception is cleared once the Order Quantity is even with product.
    public static testMethod void SalesOrderLineTest_test_SOLinesEvenLayers_For_QtyException() {

        Test.startTest();
        // flush the caching to avoid conflicts
        SalesOrderFlowCache.flush();
        // Setting this on SOLD TO company makes the even layer calc fire on triggers
        fuel.customerSoldTo.Order_Quantity_Factor_At__c = 'Pallet';
        update fuel.customerSoldTo;

        // Products having this information helps decide min quatity multiples
        fuel.product.Units_per_Layer__c = 4;
        fuel.product.Layers_per_Pallet__c = 5;
        update fuel.product;

        // reload SO for sake of controller
        fuel.salesOrder = fetchSO( fuel.salesOrder.id );

        // Leaving this intact
        Process_Configuration__c pc1 = new Process_Configuration__c();
        pc1.name = 'SOLineGoods';
        pc1.Object_Name__c = 'Sales_Order_Line__c';
        pc1.Field_Value__c = 'Goods' ;
        pc1.Active__c = true;
        insert pc1;


        system.assertEquals(true, ProcessConfigService.configResult('Sales_Order_Line__c', 'Goods', true));

        SalesOrderLinesAddManageExt soc = new SalesOrderLinesAddManageExt(new apexpages.standardController(fuel.salesOrder));
        Apexpages.currentPage().getParameters().put('selected_indexes', '0');

        soc.addNewRow();

        soc.soLineList[2].soLine.Quantity_Ordered__c = 1;
        soc.soLineList[2].soLine.Unit_Price__c = 1;
        soc.soLineList[2].soLine.Required_Date__c = system.today();
        soc.soLineList[2].soLine.Product__c = fuel.product.id;
        soc.soLineList[2].soLine.Product__r = fuel.product;
        soc.soLineList[2].soLine.Product__r.Item__c = fuel.itemList[0].Id;
        soc.soLineList[2].soLine.Product__r.Item__r = fuel.itemList[0];
        soc.rowNum = 2;

        system.assert(soc.save_lines() == null, ' expected null');


        list<Sales_Order_Line__c> soLines = [SELECT id FROM Sales_Order_Line__c WHERE Sales_Order__c = :fuel.salesOrder.id ];


        System.assertEquals(true, ExceptionService.hasOpenTask(soLines[2].Id, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.code),
                            'Min_Order_Qty_Exception should happen because of even layer mismatch');


        // Lets fix the SO Line order quantity and see if the exception gets cleared now
        soc.soLineList[2].soLine.Quantity_Ordered__c = 20;

        //KNDY-2551
        Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
        insert rc;
        soc.soLineList[2].soLine.Quantity_Change_Reason__c = rc.Id;

        system.assert(soc.save_lines() == null, ' expected null');


        soLines = [SELECT id FROM Sales_Order_Line__c WHERE Sales_Order__c = :fuel.salesOrder.id ];


        System.assertEquals(false, ExceptionService.hasOpenTask(soLines[2].Id, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.code),
                            'Min_Order_Qty_Exception  should not happen because of quantities are even');

        test.stopTest();
    }

    //JIRA - 2891
    //Minimum quantity exceptions shouldn't be calculated for SO's where the SOLDTO customer is having "Require_Order_Quantity_factor__c" set to FALSE
    public static testMethod void SalesOrderLineTest_test_SOLinesEvenLayers_Customer_Doesnt_Requires_Qty_Factors() {

        // Products having this information helps decide min quatity multiples
        fuel.product.Units_per_Layer__c = 4;
        fuel.product.Layers_per_Pallet__c = 5;
        update fuel.product;

        // reload SO for sake of controller
        fuel.salesOrder = fetchSO( fuel.salesOrder.id );

        // Leaving this intact
        Process_Configuration__c pc1 = new Process_Configuration__c();
        pc1.name = 'SOLineGoods';
        pc1.Object_Name__c = 'Sales_Order_Line__c';
        pc1.Field_Value__c = 'Goods' ;
        pc1.Active__c = true;
        insert pc1;

        Test.startTest();
        system.assertEquals(true, ProcessConfigService.configResult('Sales_Order_Line__c', 'Goods', true));

        SalesOrderLinesAddManageExt soc = new SalesOrderLinesAddManageExt(new apexpages.standardController(fuel.salesOrder));
        Apexpages.currentPage().getParameters().put('selected_indexes', '0');

        soc.addNewRow();

        soc.soLineList[2].soLine.Quantity_Ordered__c = 1;
        soc.soLineList[2].soLine.Unit_Price__c = 1;
        soc.soLineList[2].soLine.Required_Date__c = system.today();
        soc.soLineList[2].soLine.Product__c = fuel.product.id;
        soc.soLineList[2].soLine.Product__r = fuel.product;
        soc.soLineList[2].soLine.Product__r.Item__c = fuel.itemList[0].Id;
        soc.soLineList[2].soLine.Product__r.Item__r = fuel.itemList[0];
        soc.rowNum = 2;

        system.assert(soc.save_lines() == null, ' expected null');


        list<Sales_Order_Line__c> soLines = [SELECT id FROM Sales_Order_Line__c
                                             WHERE Sales_Order__c = :fuel.salesOrder.id ];

        // No qty exception should be generated as the SOLDTO Customer doesn't enabled it
        System.assertEquals(false, ExceptionService.hasOpenTask(soLines[2].Id, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.code),
                            'Min_Order_Qty_Exception field should not happen because of even layer mismatch');

        test.stopTest();
    }

    //KNDY-3220
    //Different Sold to customers can have diff values for Order Factor i.e. one with Pallet, other with Layer and might be nothing (disabled).
    //This test tries to switch customers sold to field on SO, and checks if SO Lines are revalidated for Quantity exceptions.
    static testMethod void SalesOrderLineTest_SOLineMinOrderQtyExceptionOnSOCustomerChange() {
        // accessing it before Test.startTest() to make sure limits are not consumed later
        Customer__c custShipTo = fuel.customerShipTo;

        Customer__c customerSoldToPallet = fuel.customerSoldTo.clone();
        customerSoldToPallet.Name = 'Customer Sold to Pallet';
        customerSoldToPallet.Order_Quantity_Factor_At__c = 'Pallet';
        customerSoldToPallet.Customer_Identifier__c = 'SDTEST124';
        insert customerSoldToPallet;

        Customer__c customerShipToPallet = fuel.customerShipTo.clone();
        customerShipToPallet.name = 'Customer Ship To Pallet';
        customerShipToPallet.Parent_Customer__c = customerSoldToPallet.id;
        customerShipToPallet.Customer_Identifier__c = 'SHTEST124';
        insert customerShipToPallet;

        Test.startTest();
        // KNDY-3218 Supporting both Layer and Pallet
        fuel.customerSoldTo.Order_Quantity_Factor_At__c = 'Layer';
        update fuel.customerSoldTo;

        // Products having this information helps decide min quatity multiples
        fuel.product.Units_per_Layer__c = 1;
        fuel.product.Layers_per_Pallet__c = 3;
        // Makes the factor : 1 X 3 = 3
        update fuel.product;

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        insert salesOrder;


        // Add a bad SO line whose quantity doesnt matches the product's quantity factors
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 5;
        salesOrderLine.Required_Date__c = System.today() + 5;

        insert salesOrderLine;

        System.assertEquals(false, ExceptionService.hasOpenTask(salesOrderLine.Id, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.code), 'Unit per layer 1 is even with any quantity');

        salesOrder.customer__c = customerSoldToPallet.Id;
        salesOrder.Ship_To__c = customerShipToPallet.Id;
        update salesOrder;

        System.assertEquals(true, ExceptionService.hasOpenTask(salesOrderLine.Id, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.code), 'Units per pallet : 3  is not even with order quantity 5');


        Test.stopTest();
    }

    //KNDY-3220   Checks if SO Lines are revalidated when Sold To Customer's Order_Quantity_Factor_At__c field changes its state.

    // Test Order Factor Exception when updating Sold-to customers order quantity factor
    static testMethod void SalesOrderLineTest_SOLineMinOrderQtyExceptionOnCustomerUpdate() {
        // accessing it before Test.startTest() to make sure limits are not consumed later
        Customer__c custShipTo = fuel.customerShipTo;

        Test.startTest();

        // Make it work on layer first
        fuel.customerSoldTo.Order_Quantity_Factor_At__c = 'Layer';
        update fuel.customerSoldTo;

        // Products having this information helps decide min quatity multiples
        fuel.product.Units_per_Layer__c = 1;
        fuel.product.Layers_per_Pallet__c = 3;
        // Makes the factor : 1 X 3 = 3
        update fuel.product;

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        insert salesOrder;


        // Add a bad SO line whose quantity doesnt matches the product's quantity factors
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 5;
        salesOrderLine.Required_Date__c = System.today() + 5;

        insert salesOrderLine;

        System.assertEquals(false, ExceptionService.hasOpenTask(salesOrderLine.Id, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.code), 'Unit per layer 1 is even with any quantity');

        // Make it work on Pallet level now
        fuel.customerSoldTo.Order_Quantity_Factor_At__c = 'Pallet';
        update fuel.customerSoldTo;

        // Revalidation should raise exception on the so line
        System.assertEquals(true, ExceptionService.hasOpenTask(salesOrderLine.Id, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.code),
                            'Units per pallet : 3  is not even with order quantity 5');


        Test.stopTest();
    }

    //KNDY-3229   Checks if SO Lines are revalidated when Sold To Customer's Make_Order_Quantity_Even_With_Factor__c field changes its state.

    static testMethod void SalesOrderLineTest_test_Order_Factor_Exceptions_On_Change_In_Sold_To_Customers_Make_Order_Quantity_Even_With_Factor_Field() {
        // accessing it before Test.startTest() to make sure limits are not consumed later
        Customer__c custShipTo = fuel.customerShipTo;

        Test.startTest();

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        insert salesOrder;

        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 5;
        salesOrderLine.Required_Date__c = System.today() + 5;

        Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
        insert rc;
        salesOrderLine.Quantity_Change_Reason__c = rc.Id;

        insert salesOrderLine;

        Sales_Order_Line__c soLineReload = [Select Quantity_Ordered__c from Sales_Order_Line__c Where Id = :salesOrderLine.Id];

        System.assertEquals(salesOrderLine.Quantity_Ordered__c,
                            soLineReload.Quantity_Ordered__c, 'Quantity shouldnt round as its not enabled on sold to customer');

        System.assertEquals(false, ExceptionService.hasOpenTask(soLineReload.Id, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.code), 'No exception should be there, as its not enabled on customer');

        // Enable rounding on even quantity at sold to customer level
        fuel.customerSoldTo.Make_Order_Quantity_Even_With_Factor__c = true;
        update fuel.customerSoldTo;

        // Above customer update shouldnt work as Customer->Order_Quantity_Factor_At__c is not set to anything
        // Recheck SO lines if anything is changed
        soLineReload = [Select Quantity_Ordered__c from Sales_Order_Line__c Where Id = :salesOrderLine.Id];
        System.assertEquals(salesOrderLine.Quantity_Ordered__c,
                            soLineReload.Quantity_Ordered__c, 'Quantity shouldnt round as its not enabled on sold to customer');
        System.assertEquals(false, ExceptionService.hasOpenTask(soLineReload.Id, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.code), 'No exception should be there, as its not enabled on customer');

        // Change product to make it ready for rounding
        fuel.product.Units_per_Layer__c = 1;
        fuel.product.Layers_per_Pallet__c = 3;
        // Makes the factor : 1 X 3 = 3
        update fuel.product;

        // Make it work on Pallet level now
        fuel.customerSoldTo.Order_Quantity_Factor_At__c = 'Pallet';
        update fuel.customerSoldTo;

        soLineReload = [Select Quantity_Ordered__c from Sales_Order_Line__c Where Id = :salesOrderLine.Id];
        System.assertEquals(6, soLineReload.Quantity_Ordered__c, 'Quantity shouldnt round up from 5 to 6');
        System.assertEquals(false, ExceptionService.hasOpenTask(soLineReload.Id, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.code), 'No exception should be there, as its not enabled on customer');

        Test.stopTest();
    }

    // KNDY-3229          Check rounding down of order quantity on Pallet level
    static testMethod void SalesOrderLineTest_test_Order_Factor_via_Sold_To_Customers_Make_Order_Quantity_Even_With_Factor_Field() {
        // accessing it before Test.startTest() to make sure limits are not consumed later
        Customer__c custShipTo = fuel.customerShipTo;

        // Change product to make it ready for rounding
        fuel.product.Units_per_Layer__c = 1;
        fuel.product.Layers_per_Pallet__c = 3;
        // Makes the factor : 1 X 3 = 3
        update fuel.product;

        // Enable rounding on even quantity at sold to customer level
        fuel.customerSoldTo.Make_Order_Quantity_Even_With_Factor__c = true;
        // Make it work on Pallet level
        fuel.customerSoldTo.Order_Quantity_Factor_At__c = 'Pallet';
        update fuel.customerSoldTo;

        Test.startTest();

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        salesOrder.Currency__c = fuel.currencyUSD.Id;
        insert salesOrder;

        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 4;
        salesOrderLine.Required_Date__c = System.today() + 5;

        insert salesOrderLine;

        Sales_Order_Line__c soLineReload = [Select Quantity_Ordered__c from Sales_Order_Line__c Where Id = :salesOrderLine.Id];

        System.assertEquals(3, soLineReload.Quantity_Ordered__c, 'Quantity ordered should be rounded down to 3');

        System.assertEquals(false, ExceptionService.hasOpenTask(soLineReload.Id, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.code), 'No exception should be there, as its not enabled on customer');


        Test.stopTest();
    }

    //JIRA - 2891      Plan should be blocked in case some Min Order quantity exceptions exist on none of the SO Lines
    static testMethod void SalesOrderLineTest_test_Plan_Should_Pass_For_No_Order_Factor_Exceptions_Using_Pallet() {

        Test.startTest();
        // Setting it false explicitly to avoid any situations, where this is defaulted to TRUE by trigger/object config
        // KNDY-3218 Supporting both Layer and Pallet
        fuel.customerSoldTo.Order_Quantity_Factor_At__c = 'Pallet';
        update fuel.customerSoldTo;

        // Products having this information helps decide min quatity multiples
        fuel.product.Units_per_Layer__c = 4;
        fuel.product.Layers_per_Pallet__c = 5;
        // Makes the factor = 4 X 6 = 24
        update fuel.product;

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;    // must be a sold to
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        insert salesOrder;

        // Add a good SO line whose quantity doesnt matches the product's quantity factors
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 0;
        salesOrderLine.Required_Date__c = System.today() + 5;

        insert salesOrderLine;

        System.assertEquals(true, ExceptionService.hasOpenTask(salesOrderLine.Id, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.code), 'Quantity zero is not even factor, so should be an exception case');
        delete salesOrderLine;

        // Add a good SO line whose quantity doesnt matches the product's quantity factors
        salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 100;
        salesOrderLine.Required_Date__c = System.today() + 5;

        insert salesOrderLine;


        SalesOrderService sos = new SalesOrderService();
        sos.plan(salesOrder.Id);
        System.assert(ExceptionService.hasErrors, 'Product quantites are even with quantity ordered in SalesOrder line, so this should NOT fail here.' + ExceptionService.messages);

        Test.stopTest();
    }

    // JIRA - 2891      Plan should be blocked in case some Min Order quantity exceptions exist on none of the SO Lines
    static testMethod void SalesOrderLineTest_test_Plan_Should_Pass_For_No_Order_Factor_Exceptions_Using_Layer() {

        Test.startTest();
        // Setting it false explicitly to avoid any situations, where this is defaulted to TRUE by trigger/object config
        // KNDY-3218 Supporting both Layer and Pallet
        fuel.customerSoldTo.Order_Quantity_Factor_At__c = 'Layer';
        update fuel.customerSoldTo;

        // Products having this information helps decide min quatity multiples
        fuel.product.Units_per_Layer__c = 4;
        fuel.product.Layers_per_Pallet__c = 5;
        // Makes the factor = 4 X 6 = 24
        update fuel.product;

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;    // must be a sold to
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        insert salesOrder;


        // Add a bad SO line whose quantity doesnt matches the product's quantity factors
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 0;
        salesOrderLine.Required_Date__c = System.today() + 5;

        insert salesOrderLine;

        System.assertEquals(true, ExceptionService.hasOpenTask(salesOrderLine.Id, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.code), 'Quantity zero is not even factor, so should be an exception case');
        delete salesOrderLine;
        // Add a good SO line whose quantity doesnt matches the product's quantity factors
        salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 100;
        salesOrderLine.Required_Date__c = System.today() + 5;

        insert salesOrderLine;


        SalesOrderService sos = new SalesOrderService();
        sos.plan(salesOrder.Id);
        System.assert(ExceptionService.hasErrors, 'Product quantites are even with quantity ordered in SalesOrder line, so this should NOT fail here.' + ExceptionService.messages);

        Test.stopTest();
    }

    //JIRA - 2891      Plan should be blocked in case some Min Order quantity exceptions exist on all the SO Lines
    public static testMethod void SalesOrderLineTest_test_Plan_Should_Fail_For_Even_Layer_Exceptions() {
        // Setting it false explicitly to avoid any situations, where this is defaulted to TRUE by trigger/object config
        fuel.customerSoldTo.Order_Quantity_Factor_At__c = 'Layer';

        update fuel.customerSoldTo;

        // Products having this information helps decide min quatity multiples
        fuel.product.Units_per_Layer__c = 4;
        fuel.product.Layers_per_Pallet__c = 6;
        // Makes the factor = 4 X 6 = 24
        update fuel.product;

        // Creating SO again here, as the existing one has 2 SO Lines, which doesn't suits my testing
        // to figure out rows not coming out for planning because of Min Order Quantity Exception

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;    // must be a sold to
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        insert salesOrder;

        // Add a bad SO line whose quantity doesnt matches the product's quantity factors
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 101;
        salesOrderLine.Required_Date__c = System.today() + 5;

        insert salesOrderLine;


        Test.startTest();
        SalesOrderService sos = new SalesOrderService();
        sos.plan(salesOrder.Id);
        System.assertEquals(true, ExceptionService.hasErrors, 'Product quantites are not even with quantity ordered in SalesOrder line, so this should fail here.');

        Test.stopTest();
    }

    //KNDY-3331
    //Reprodcuces bug in following steps
    //1. Creates Substituion rule
    //2. Create SO Line whose product will get substituted from the rule.
    //3. SO Line has Pricebook and Price mentioned upfront, so that its same as of UI (Add Manage SO Lines)
    //4. Asserts if on product substitution price gets updated in SO Line
    testMethod static void SalesOrderLineTest_testKndy3331() {

        Pricebook__c pricebook = new Pricebook__c();
        pricebook.name = fuel.company.Name +  ' Orange Pricebook-CPY';
        pricebook.company__c = fuel.company.id;
        pricebook.default__c = true;
        insert pricebook;

        Pricebook_Line__c pl = new Pricebook_Line__c();
        pl.product__c = fuel.product.id;
        pl.pricebook__c = pricebook.id;
        pl.price__c = 11.12;
        pl.Use_Fixed_Pricing__c = true;
        pl.Start_date__c = system.today();

        Pricebook_Line__c pl2 = new Pricebook_Line__c();
        pl2.product__c = fuel.product2.id;
        pl2.pricebook__c = pricebook.id;
        pl2.price__c = 12.11;
        pl2.Use_Fixed_Pricing__c = true;
        pl2.Start_date__c = system.today();

        //// note product3 is not in any pricebook
        insert new List<Pricebook_Line__c> {pl, pl2};

        fuel.product2.UPC_Code__c = fuel.product.UPC_Code__c;
        update fuel.product2;

        Substitution__c sub2 = new Substitution__c();
        sub2.Name = 'Secondary Product Sub';
        sub2.Current_Product__c = fuel.product.Id;
        sub2.Substitute_Product__c = fuel.product2.Id;
        sub2.Start_Date__c = system.today() - 1;
        sub2.End_Date__c = system.today() + 720;
        insert sub2;

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        insert salesOrder;

        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 4;
        salesOrderLine.Required_Date__c = System.today() + 5;
        // behave like SO UI and set the pricebook and price upfront
        salesOrderLine.Unit_Price__c = pl.Price__c;
        salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
        insert salesOrderLine;

        Test.startTest();

        Sales_Order_Line__c soLine = [Select Id, Product__c, Product__r.Name, Unit_Price__c from Sales_Order_Line__c Where Id = :salesOrderLine.id];

        System.assertEquals(pl2.Price__c, soLine.Unit_Price__c);

        Test.stopTest();
    }

    // KNDY-407     If there is no active price for a product on a price book, users cannot order
    public static testMethod void SalesOrderLineTest_SalesOrderLineTest() {

        Test.startTest();

        Sales_Order_Line__c salesOrderLine = fuel.salesOrder.Sales_Order_Lines__r[0];
        system.assert( salesOrderLine.id != null , ' expected valid sales order lines');

        // Assert that pricebook exists
        Pricebook__c pb = [ select id from Pricebook__c where company__c = :fuel.company.id limit 1];
        system.assert( pb.id != null, 'Expected a pricebook');

        // get the correct sales order line that has product 1
        salesOrderLine = null;
        for ( Sales_Order_Line__c s : fuel.salesOrder.Sales_Order_Lines__r ) {
            if ( s.Product__c == fuel.product.id )
                salesOrderLine = s;
        }
        system.assert( salesOrderLine != null );

        Pricebook_Line__c[] pl = [ select price__c, id, Use_Fixed_Pricing__c
                                   from Pricebook_Line__c
                                   where product__c = :fuel.product.id ];
        system.assert( pl.size() == 1 , 'Expected valid pricebook line for product 1 ');

        // assert that sales order lines were created
        system.assert( salesOrderLine.id != null, 'Expected valid sales orders lines ' + Apexpages.getMessages());
        system.assert( Apexpages.hasMessages() == false, 'Expected no messages ' + Apexpages.getMessages());

        // verify these prices are the same
        system.assert( salesOrderLine.Unit_price__c  == pl[0].price__c ,
                       'expected the unit price to match pricebook '   +
                       salesOrderLine.Unit_price__c   + '  ' +  pl[0].price__c );

        salesOrderLine = [ select id, Has_Exceptions__c, unit_price__c, product__c from Sales_Order_Line__c where id = :salesOrderLine.id limit 1];
        system.assert(salesOrderLine.Has_Exceptions__c == false,     ' should have no exceptions on this line ');

        // insert a line with empty price, see that it is defaulted from price book.
        salesOrderLine = new Sales_Order_Line__c();
        SalesOrderLine.Product__c = fuel.product.Id;
        SalesOrderLine.Description__c = fuel.product3.Description__c;
        SalesOrderLine.Company__c = fuel.company.id;
        SalesOrderLine.Sales_Order__c = fuel.salesOrder.Id;
        SalesOrderLine.Quantity_Ordered__c = 15;
        SalesOrderLine.Required_Date__c = System.today() + 15;
        insert salesOrderLine;

        salesOrderLine = [ select id, unit_price__c from Sales_Order_Line__c where id = :salesorderLine.id limit 1];
        system.assert( SalesOrderLine.unit_Price__c == pl[0].price__c,          'Expected default from price book');

        Test.stopTest();
    }

    public static testMethod void SalesOrderLineTest_SalesOrderLineTest2() {

        Test.startTest();

        Pricebook_Line__c[] pl = [ select price__c, id, Use_Fixed_Pricing__c
                                   from Pricebook_Line__c
                                   where product__c = :fuel.product.id ];

        // insert a record with an incorrect price, expect an exception
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        SalesOrderLine.Product__c = fuel.product.Id;
        SalesOrderLine.Description__c = fuel.product3.Description__c;
        SalesOrderLine.Company__c = fuel.company.id;
        SalesOrderLine.Sales_Order__c = fuel.salesOrder.Id;
        SalesOrderLine.Quantity_Ordered__c = 15;
        SalesOrderLine.Required_Date__c = System.today() + 15;
        SalesOrderLine.Unit_Price__c = 9.1;
        SalesOrderLine.Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY;

        SalesOrderFlowCache.flush();

        // Insert a sales order line with a different fulfillment source
        Sales_Order_Line__c salesOrderLine2 = new Sales_Order_Line__c();
        salesOrderLine2.Product__c = fuel.product2.Id;
        salesOrderLine2.Description__c = fuel.product2.Description__c;
        salesOrderLine2.Company__c = fuel.company.id;
        salesOrderLine2.Sales_Order__c = fuel.salesOrder.Id;
        salesOrderLine2.Quantity_Ordered__c = 10;
        salesOrderLine2.Required_Date__c = System.today() + 15;
        salesOrderLine2.Unit_Price__c = 10;
        salesOrderLine2.Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP;
        salesOrderLine2.Selling_UOM__c = fuel.uomList[8].Id;
        insert new List<Sales_Order_Line__c> {salesOrderLine, salesOrderLine2};

        system.assertNotEquals(null, SalesOrderLine.Id, 'Expected the sales order line to be created.');
        system.assertNotEquals(null, salesOrderLine2.Id, 'Expected the sales order line to be created.');

        salesOrderLine = [ select id, unit_price__c, Has_Exceptions__c
                           from Sales_Order_Line__c
                           where id = :salesorderLine.id limit 1];
        system.assert( SalesOrderLine.Has_Exceptions__c == true,     'Expected an exception on this line ' );

        // if a line is updated with the correct price, the exception should clear !
        // also tests update trigger
        salesOrderLine.Unit_Price__c = pl[0].price__c;
        update salesOrderLine;

        salesOrderLine = [ select id, unit_price__c, Has_Exceptions__c
                           from Sales_Order_Line__c where id = :salesorderLine.id limit 1];

        system.assert( SalesOrderLine.Has_Exceptions__c != true, 'Expected no exception on this line: ex:' + ExceptionService.fetchExceptionTasks(new set<Id> {SalesOrderLine.Id}) + '***sol: ' + salesorderLine); //KNDY-4989


        Test.stopTest();
    }

    public static testMethod void SalesOrderLineTest_SalesOrderLineTest3() {

        //Pricebook__c pricebook = new Pricebook__c();
        //pricebook.name = fuel.company.Name +  ' Orange Pricebook-CPY';
        //pricebook.company__c = fuel.company.id;
        //pricebook.default__c = true;
        //insert pricebook;

        //Pricebook_Line__c pl = new Pricebook_Line__c();
        //pl.product__c = fuel.product.id;
        //pl.pricebook__c = pricebook.id;
        //pl.price__c = 11.12;
        //pl.Use_Fixed_Pricing__c = true;
        //pl.Start_date__c = system.today();

        //Pricebook_Line__c pl2 = new Pricebook_Line__c();
        //pl2.product__c = fuel.product2.id;
        //pl2.pricebook__c = pricebook.id;
        //pl2.price__c = 12.11;
        //pl2.Use_Fixed_Pricing__c = true;
        //pl2.Start_date__c = system.today();

        // note product3 is not in any pricebook
        //insert new List<Pricebook_Line__c> {pl, pl2};

        fuel.product2.UPC_Code__c = fuel.product.UPC_Code__c;
        update fuel.product2;

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        salesOrder.Pricebook__c = fuel.pricebook.id;
        insert salesOrder;

        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product3.Id;
        salesOrderLine.Description__c = fuel.product3.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 4;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        // behave like SO UI and set the pricebook and price upfront
        //salesOrderLine.Unit_Price__c = pl.Price__c;
        insert salesOrderLine;

        Test.startTest();

        salesOrderLine = [ SELECT Id, Unit_Price__c, Has_Exceptions__c
                           FROM Sales_Order_Line__c
                           WHERE Id = :salesOrderLine.Id limit 1];

        system.assert( salesOrderLine.Has_Exceptions__c == true,     'Expected an exception on this line ' );
        system.assert( ExceptionService.hasOpenTask(SalesOrderLine.Id, ExceptionUtil.PRICEBOOK_LINE_NOT_FOUND.code),
                       'Expected a price exception on this line : ' + ExceptionService.fetchExceptionTasks(new Set<Id> {SalesOrderLine.Id}));

        Test.stopTest();
    }

    public static testMethod void SalesOrderLineTest_SalesOrderLineTest4() {

        Test.startTest();

        // validate that an expired price will throw an exception
        Pricebook_Line__c[] lines = [ select id , Start_date__c from Pricebook_Line__c ];
        for ( pricebook_line__c pp : lines ) {
            pp.Start_date__c = system.today().addDays(1);
            pp.End_date__c = system.today().addDays(30);
        }
        update lines;

        Product__c product = new Product__c(
            company__c = fuel.company.id,
            Name = 'Product 1z',
            Item__c  = fuel.itemList[0].ID,
            Description__c = 'Product-10',
            Selling_UOM__c = fuel.uomList[8].ID,
            Weight__c = 13,
            Weight_UOM__c = fuel.uomList[3].ID,
            Dimension_UOM__c = fuel.uomList[6].ID,
            Length__c = 1,
            Width__c = 1,
            Height__c = 1
        );
        product.Weight_UOM__c = fuel.uomList[0].ID;
        product.Dimension_UOM__c = fuel.uomList[0].ID;
        insert product;

        Sales_Order_Line__c SalesOrderLine = new Sales_Order_Line__c();
        SalesOrderLine.Product__c = product.Id;
        SalesOrderLine.Description__c = fuel.product.Description__c;
        SalesOrderLine.Company__c = fuel.company.id;
        SalesOrderLine.Sales_Order__c = fuel.salesOrder.Id;
        SalesOrderLine.Quantity_Ordered__c = 15;
        SalesOrderLine.Required_Date__c = System.today() + 15;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        insert SalesOrderLine;

        salesOrderLine = [ select id, unit_price__c, Has_Exceptions__c
                           from Sales_Order_Line__c where id = :salesorderLine.id limit 1];
        system.assert( SalesOrderLine.Has_Exceptions__c == true, 'Expected an exception on this line' );
        system.assert( ExceptionService.hasOpenTask(SalesOrderLine.Id, ExceptionUtil.PRICEBOOK_LINE_NOT_FOUND.code), 'Expected a price exception on this line' + ExceptionService.fetchExceptionTasks(new Set<Id> {SalesOrderLine.Id}) );

        Test.stopTest();
    }

    public static testMethod void SalesOrderLineTest_SalesOrderLineTest5() {
        // OTC-365: Test for Pricebook_Line_Required__c = false.. Shouldn't throw an error

        Pricebook__c pricebook = new Pricebook__c();
        pricebook.name = fuel.company.Name +  ' Orange Pricebook-CPY';
        pricebook.company__c = fuel.company.id;
        pricebook.default__c = true;
        insert pricebook;

        Pricebook_Line__c pl = new Pricebook_Line__c();
        pl.product__c = fuel.product.id;
        pl.pricebook__c = pricebook.id;
        pl.price__c = 11.12;
        pl.Use_Fixed_Pricing__c = true;
        pl.Start_date__c = system.today();

        Pricebook_Line__c pl2 = new Pricebook_Line__c();
        pl2.product__c = fuel.product2.id;
        pl2.pricebook__c = pricebook.id;
        pl2.price__c = 12.11;
        pl2.Use_Fixed_Pricing__c = true;
        pl2.Start_date__c = system.today();

        // note product3 is not in any pricebook
        insert new List<Pricebook_Line__c> {pl, pl2};

        fuel.product2.UPC_Code__c = fuel.product.UPC_Code__c;
        fuel.product3.Pricebook_Line_Required__c = false;
        update new List<Product__c> {fuel.product2, fuel.product3};

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        insert salesOrder;

        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product3.Id;
        salesOrderLine.Description__c = fuel.product3.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 4;
        salesOrderLine.Required_Date__c = System.today() + 5;
        // behave like SO UI and set the pricebook and price upfront
        salesOrderLine.Unit_Price__c = pl.Price__c;
        insert salesOrderLine;

        Test.startTest();

        salesOrderLine = [ SELECT Id, Unit_Price__c, Has_Exceptions__c
                           FROM Sales_Order_Line__c
                           WHERE Id = :salesOrderLine.Id limit 1];

        system.assert( salesOrderLine.Has_Exceptions__c == false,     'No expected exception on this line ' );

        Test.stopTest();
    }

    // KNDY-2125 Brackets, this test tries to create brackets.
    // Then tests Pricebook line update trigger to apply bracket pricing on not null fields.
    testMethod static void SalesOrderLineTest_testBracketCalculationsAndPricebookUpdate() {
        // stop unnecessary creation of SO data


        Test.startTest();

        Pricebook__c pricebook = new Pricebook__c();
        pricebook.name = fuel.company.Name +  ' Orange Pricebook-CPY';
        pricebook.company__c = fuel.company.id;
        pricebook.Primary_Key__c = 'NATBOOK-CPY';
        insert pricebook;

        Pricebook_Line__c pl = new Pricebook_Line__c();
        pl.product__c = fuel.product.id;
        pl.pricebook__c = pricebook.id;
        pl.price__c = 11.12;
        pl.Start_date__c = system.today().addDays(1);
        pl.End_Date__c = System.today().addDays(20);
        insert pl;





        //
        // Create Brackets
        //
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(fuel.company));

        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1, brack2, brack3, brack4, brack5;
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 0;
        brack1.percentUpcharge = 0;
        brack1.pricebookLineField = 'Price__c';

        // Create bracket 2
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 100;
        brack2.percentUpcharge = 1;
        brack2.pricebookLineField = 'Price_2__c';

        // Create bracket 3
        brack3 = bracketWraps[2];
        brack3.inUse = true;
        brack3.volumeRangeBottom = 1000;
        brack3.percentUpcharge = 2;
        brack3.pricebookLineField = 'Price_3__c';

        // Create bracket 4
        brack4 = bracketWraps[3];
        brack4.inUse = true;
        brack4.volumeRangeBottom = 2000;
        brack4.percentUpcharge = 3;
        brack4.pricebookLineField = 'Price_4__c';

        // Create bracket 5
        brack5 = bracketWraps[4];
        brack5.inUse = true;
        brack5.volumeRangeBottom = 3000;
        brack5.percentUpcharge = 4;
        brack5.pricebookLineField = 'Price_5__c';

        // Persist to DB
        ext.onSave();

        //
        Pricebook_Line__c pbLineProd1 = [
                                            select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c
                                            from Pricebook_Line__c
                                            where Product__c = :fuel.product.Id AND Pricebook__c = :pricebook.Id
                                        ];
        // update the pricebook line as brackets are configured now, so it should pick up the prices
        pbLineProd1.Price__c = 100;
        // KNDY-3608: This should get overridden as manual changes are not entertained
        pbLineProd1.Price_2__c = 200;
        pbLineProd1.Use_Fixed_Pricing__c = false; // turn it off to use brackets
        update pbLineProd1;

        pbLineProd1 = [select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c where Id = :pbLineProd1.Id];
        // should be overridden
        System.assertEquals(pbLineProd1.Price__c + brack2.percentUpcharge / 100 * pbLineProd1.Price__c, pbLineProd1.Price_2__c);
        // Test if upcharge is correctly applied
        System.assertEquals(pbLineProd1.Price__c + brack3.percentUpcharge / 100 * pbLineProd1.Price__c, pbLineProd1.Price_3__c);
        System.assertEquals(pbLineProd1.Price__c + brack4.percentUpcharge / 100 * pbLineProd1.Price__c, pbLineProd1.Price_4__c);
        System.assertEquals(pbLineProd1.Price__c + brack5.percentUpcharge / 100 * pbLineProd1.Price__c, pbLineProd1.Price_5__c);

        Test.stopTest();
    }

    //  KNDY-2125 Brackets, this test tries to create brackets and matches SO lines against sub pricebook fields
    testMethod static void SalesOrderLineTest_testBracketCalculationsWithSOLineMatching() {
        // stop unnecessary creation of SO data
        List<UOM_Conversion_Details__c> uomcList = fuel.uomcList;

        Pricebook__c pricebook = new Pricebook__c();
        pricebook.name = fuel.company.Name +  ' Orange Pricebook-CPY';
        pricebook.company__c = fuel.company.id;
        pricebook.Primary_Key__c = 'NATBOOK-CPY';
        insert pricebook;

        Product__c product = new Product__c(
            company__c = fuel.company.id,
            Name = 'Product 1z',
            Item__c  = fuel.itemList[0].ID,
            Description__c = 'Product-10',
            Selling_UOM__c = fuel.uomList[8].ID,
            Weight__c = 13,
            Weight_UOM__c = fuel.uomList[3].ID,
            Dimension_UOM__c = fuel.uomList[6].ID,
            Length__c = 1,
            Width__c = 1,
            Height__c = 1
        );
        product.Weight_UOM__c = fuel.uomList[0].ID;
        product.Dimension_UOM__c = fuel.uomList[0].ID;

        Product__c product2 = new Product__c(
            company__c = fuel.company.id,
            Name = 'Product-15',
            Item__c  = fuel.itemList[5].ID,
            Description__c = 'Product-15',
            Selling_UOM__c = fuel.uomList[8].ID,
            Weight__c = 5,
            Weight_UOM__c = fuel.uomList[0].ID,
            Dimension_UOM__c = fuel.uomList[6].ID,
            Length__c = 1,
            Width__c = 1,
            Height__c = 1
        );
        product2.Weight_UOM__c = fuel.uomList[0].ID;
        product2.Dimension_UOM__c = fuel.uomList[0].ID;


        Test.startTest();

        //
        // Create Brackets
        //
        BracketPricingUpchargeManageExt ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(fuel.company));

        List<BracketPricingUpchargeManageExt.BracketPriceWrapper> bracketWraps = ext.bracketWraps;
        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1, brack2, brack3, brack4, brack5;
        // Create bracket 1
        brack1 = bracketWraps[0];
        brack1.inUse = true;
        brack1.volumeRangeBottom = 0;
        brack1.percentUpcharge = 0;
        brack1.pricebookLineField = 'Price__c';

        // Create bracket 2
        brack2 = bracketWraps[1];
        brack2.inUse = true;
        brack2.volumeRangeBottom = 100;
        brack2.percentUpcharge = 1;
        brack2.pricebookLineField = 'Price_2__c';

        // Create bracket 3
        brack3 = bracketWraps[2];
        brack3.inUse = true;
        brack3.volumeRangeBottom = 1000;
        brack3.percentUpcharge = 2;
        brack3.pricebookLineField = 'Price_3__c';

        // Create bracket 4
        brack4 = bracketWraps[3];
        brack4.inUse = true;
        brack4.volumeRangeBottom = 2000;
        brack4.percentUpcharge = 3;
        brack4.pricebookLineField = 'Price_4__c';

        // Create bracket 5
        brack5 = bracketWraps[4];
        brack5.inUse = true;
        brack5.volumeRangeBottom = 3000;
        brack5.percentUpcharge = 4;
        brack5.pricebookLineField = 'Price_5__c';

        // Persist to DB
        ext.onSave();

        //Moved the price list lines after Bracket creation due to class failure.


        Pricebook_Line__c pl = new Pricebook_Line__c();
        pl.product__c = fuel.product.id;
        pl.pricebook__c = pricebook.id;
        pl.price__c = 100;
        pl.Use_Fixed_Pricing__c = false;
        pl.Start_date__c = system.today();
        pl.End_Date__c = System.today().addDays(20);
        insert pl;

        //

        Pricebook_Line__c pbLineProd1 = [select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c where Id = :pl.Id];

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;    // must be a sold to
        salesOrder.Payment_Term__c = fuel.terms.id;
        salesOrder.Pricebook__c = pricebook.Id;
        product.Weight_UOM__c = fuel.uomList[0].ID;
        product.Dimension_UOM__c = fuel.uomList[0].ID;

        insert salesOrder;

        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Pricebook__c = fuel.pricebook.id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Company__c = fuel.company.id;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 100; // product weight is 13 for Prod1
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Pricebook__c = pricebook.id;
        // salesOrderLine.Unit_Price__c = leave it empty to come from Brackets
        salesOrderLine.Discount_Percent__c = 2;
        insert salesOrderLine;

        salesOrderLine = [Select Unit_Price__c, Quantity_Ordered__c, Pricebook__c from Sales_Order_Line__c Where Id = :salesOrderLine.Id];
        // Should match Price 3 as per brackets calcualtion total weight is 1300 = 13 X 100
        System.assertEquals(pbLineProd1.Price_3__c , salesOrderLine.Unit_Price__c);
        System.assertEquals(pricebook.Id , salesOrderLine.Pricebook__c);

        // Should change the price brackets, as quantity is raised
        salesOrderLine.Quantity_Ordered__c = 200;

        //KNDY-2551
        Reason_Code__c rc = new Reason_Code__c(Reason_Code_Unique__c = 'reason code test', Type__c = 'test type');
        insert rc;
        salesOrderLine.Quantity_Change_Reason__c = rc.Id;

        update salesOrderLine;
        salesOrderLine = [Select Unit_Price__c from Sales_Order_Line__c Where Id = :salesOrderLine.Id];
        System.assertEquals(pbLineProd1.Price_4__c , salesOrderLine.Unit_Price__c);


        Test.stopTest();
    }
	// Commenting out TPM related test case
    ////   KNDY-4509 test to make sure the National List Price for Trade Promotion gets populated
    //testMethod static void SalesOrderLineTest_testListPrice() {

    //    Product__c product = new Product__c(
    //        company__c = fuel.company.id,
    //        Name = 'Product 1a',
    //        Item__c  = fuel.itemList[0].ID,
    //        Description__c = 'Product-10',
    //        Selling_UOM__c = fuel.uomList[8].ID,
    //        Weight__c = 13,
    //        Weight_UOM__c = fuel.uomList[3].ID,
    //        Dimension_UOM__c = fuel.uomList[6].ID,
    //        Length__c = 1,
    //        Width__c = 1,
    //        Height__c = 1
    //    );
    //    Product__c product2 = new Product__c(
    //        company__c = fuel.company.id,
    //        Name = 'Product 1b',
    //        Item__c  = fuel.itemList[0].ID,
    //        Description__c = 'Product-10',
    //        Selling_UOM__c = fuel.uomList[8].ID,
    //        Weight__c = 13,
    //        Weight_UOM__c = fuel.uomList[3].ID,
    //        Dimension_UOM__c = fuel.uomList[6].ID,
    //        Length__c = 1,
    //        Width__c = 1,
    //        Height__c = 1
    //    );

    //    Pricebook__c pricebook = new Pricebook__c();
    //    pricebook.name = fuel.company.Name +  ' Orange Pricebook-CPY';
    //    pricebook.company__c = fuel.company.id;
    //    pricebook.Primary_Key__c = 'NATBOOK-TRADE';
    //    pricebook.Trade_Promotion__c = true;
    //    insert pricebook;

    //    Pricebook_Line__c pl = new Pricebook_Line__c();
    //    pl.product__c = fuel.product.id;
    //    pl.pricebook__c = pricebook.id;
    //    pl.price__c = 109.99;
    //    pl.Start_date__c = system.today();
    //    pl.End_Date__c = System.today().addDays(20);
    //    insert pl;

    //    Test.startTest();

    //    Sales_Order__c salesOrder = new Sales_Order__c();
    //    salesOrder.Company__c = fuel.company.id;
    //    salesOrder.Customer__c = fuel.customerSoldTo.id;    // must be a sold to
    //    salesOrder.Payment_Term__c = fuel.terms.id;
    //    salesOrder.Pricebook__c = pricebook.id;

    //    insert salesOrder;

    //    Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
    //    salesOrderLine.Product__c = fuel.product.Id;
    //    salesOrderLine.Pricebook__c = pricebook.id;
    //    salesOrderLine.Description__c = fuel.product.Description__c;
    //    salesOrderLine.Company__c = fuel.company.id;
    //    salesOrderLine.Sales_Order__c = salesOrder.Id;
    //    salesOrderLine.Quantity_Ordered__c = 100;
    //    salesOrderLine.Required_Date__c = System.today() + 5;
    //    salesOrderLine.Discount_Percent__c = 2;
    //    insert salesOrderLine;

    //    salesOrderLine = [Select Id, Product__c, List_Price__c from Sales_Order_Line__c Where Id = :salesOrderLine.Id LIMIT 1];
    //    system.assertNotEquals(null, salesOrderLine);

    //    system.assertEquals(109.99, salesOrderLine.List_Price__c, 'Expected List Price to be set from the Trade Promotion Pricebook');


    //    //now update to another product and make sure the List Price gets removed
    //    salesOrderLine.Product__c = product2.Id;
    //    update salesOrderLine;

    //    salesOrderLine = [Select Id, Product__c, List_Price__c from Sales_Order_Line__c Where Id = :salesOrderLine.Id LIMIT 1];
    //    system.assertEquals(null, salesOrderLine.List_Price__c, 'Expected List Price to be null');


    //    Test.stopTest();
    //}

    // OTC-175
    public static testMethod void SalesOrderLineTest_test_HistoricalData() {

        //SalesOrderTestData data = new SalesOrderTestData(false );
        system.debug(LoggingLevel.INFO, 'test_HistoricalData Queries ' + Limits.getQueries() );

        // create a closed order header,
        // start the test
        // then insert 100 lines
        Sales_Order__c closedSalesOrder = new Sales_Order__c();
        closedSalesOrder.Company__c = fuel.company.id;
        closedSalesOrder.Bill_To__c = fuel.customerBillTo.Id;
        closedSalesOrder.Customer__c = fuel.customerSoldTo.id;
        closedSalesOrder.Ship_To__c = fuel.customerShipTo.Id;
        closedSalesOrder.Payment_Term__c = fuel.terms.id;
        closedSalesOrder.Weight_UOM__c = fuel.product2.weight_UOM__c;
        closedSalesOrder.Dimension_UOM__c = fuel.product2.Dimension_UOM__c;
        closedSalesOrder.status__c  =  SalesOrderService.SO_STATUS_CLOSED;        // create order in closed status
        closedSalesOrder.Date_Time_Ordered__c = System.today().addDays(-365);
        insert closedSalesOrder;

        system.assert( [select status__c From Sales_Order__c s
                        where id = :closedSalesOrder.id limit 1].Status__c == SalesOrderService.SO_STATUS_CLOSED,
                       'expected order to be closed');

        Test.startTest();


        list<Sales_Order_Line__c> manyLines = new List<Sales_Order_Line__c>();
        Integer imported_line_number = 9000;
        for ( Integer ii = 0; ii < 60; ii++ ) {

            Sales_Order_Line__c SalesOrderLine = new Sales_Order_Line__c();
            if ( ii == 0 ) {
                // test we can assign a line number when inserting
                SalesOrderLine.Line__c = imported_line_number;
            }
            SalesOrderLine.Product__c = fuel.product2.Id;
            SalesOrderLine.Description__c = fuel.product2.Description__c;// random products ?
            SalesOrderLine.Company__c = fuel.company.id;
            SalesOrderLine.Sales_Order__c = closedSalesOrder.Id;
            SalesOrderLine.Quantity_Ordered__c = 15;
            SalesOrderLine.Required_Date__c = System.today() + 15;
            SalesOrderLine.Unit_Price__c = 12.11;
            SalesOrderLine.Weight_UOM__c = fuel.product2.Weight_UOM__c;
            SalesOrderLine.Dimension_UOM__c = fuel.product2.Dimension_UOM__c;
            SalesOrderLine.Ship_From_Location__c = fuel.location2.ID;
            SalesOrderLine.Status__c =  SalesOrderService.SO_STATUS_CLOSED;

            manyLines.add(SalesOrderLine);
        }

        insert manyLines;

        manyLines[0] = [ select id, Line__c from Sales_Order_Line__c where id = :manyLines[0].id limit 1];
        system.assertEquals(imported_line_number, manyLines[0].Line__c, 'expected to be able to set a line # at insert time');


        system.debug(LoggingLevel.INFO, 'test_HistoricalData Queries ' + Limits.getQueries() ); // 25 queries

        fuel.salesOrder = [Select s.Status__c, s.Customer__c, s.Company__c,
                           (Select Id, Sales_Order__c,
                            Backorder_Value__c, Company__c, Description__c, Discount_Percent__c,
                            Extended_Price__c, Product__r.Item__c, Line__c, Quantity_Backordered__c,
                            Quantity_Ordered__c, Quantity_Shipped__c, Required_Date__c, Status__c, Product__r.Item__r.Class__c,
                            Unit_Price__c From Sales_Order_Lines__r order by Line__c asc)
                           From Sales_Order__c s where id = :closedSalesOrder.id limit 1];

        // OTC-175 allow historical data loads
        system.assert( closedSalesOrder.status__c == SalesOrderService.SO_STATUS_CLOSED, 'expected a closed order');
        system.assertEquals( fuel.salesOrder.Sales_Order_Lines__r.size(), 60 , ' expected 60 lines, got ' + fuel.salesOrder.Sales_Order_Lines__r.size());
    }

    static testMethod void SalesOrderLineTest_test_InvalidUOM() {
        // invalid UOM conversions should be caught by the trigger
        // and become field validation exceptions ie: SOL.addError()
        // so that they don't send email to the isv
        system.assert( fuel.salesOrder != null );
        system.assert( fuel.salesOrder.Sales_Order_Lines__r != null );
        UOM__c myuom = new UOM__c(Name = 'FOO', Description__c = 'bar');
        insert myuom;
        Test.startTest();
        Sales_Order_Line__c sol = fuel.salesOrder.Sales_Order_Lines__r[0];

        sol.Product__c = fuel.product3.id; // change the product to trigger a UOM conversion
        sol.Weight_UOM__c = myuom.id; // should be an invalid UOM
        string msg;
        try {
            update sol;
        } catch ( exception e ) {
            system.debug(LoggingLevel.INFO, e);
            msg = e.getMessage();
        }
        test.stopTest();
        system.assert(msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), ' expected addError() FIELD_CUSTOM_VALIDATION_EXCEPTION ');
    }

    static testMethod void SalesOrderLineTest_testUOMMatching() {
        // OTC-948: Keep the Product Item Purchasing UOM the same as the SOL Selling UOM
        system.assert( fuel.salesOrder != null );
        system.assert( fuel.salesOrder.Sales_Order_Lines__r != null );

        test.startTest();

        System.assertEquals(fuel.uomList[8].Id, fuel.salesOrder.Sales_Order_Lines__r[0].Product__r.Item__r.Purchasing_UOM__c);

        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Company__c = fuel.company.Id;
        salesOrderLine.Description__c = fuel.product.Description__c;
        salesOrderLine.Discount_Percent__c = 2;
        salesOrderLine.Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP;
        salesOrderLine.Product__c = fuel.product.Id;
        salesOrderLine.Quantity_Ordered__c = 100;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Sales_Order__c = fuel.salesOrder.Id;
        salesOrderLine.Selling_UOM__c = fuel.uomList[9].Id;
        salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
        salesOrderLine.Unit_Price__c = 1;
        salesOrderLine.Memo__c = 'salesOrderLineUOMTest';
        //salesOrderLine.Selling_UOM__c = fuel.uomList[8].Id;
        // There should be an error when trying to insert with a SOL Selling UOM
        Boolean isError = false;
        try {
            insert salesOrderLine;
        } catch (System.DmlException e) {
            isError = true;
            Set<String> errorMessages = new Set<String>();

            for (Integer i = 0; i < e.getNumDml(); i++) {

                // Process exception here
                errorMessages.add(e.getDmlMessage(i));

            }

            System.assert(errorMessages.contains(Label.The_Selling_UOM_should_remain_consistent_with_the_Item_Purchasing_UOM + ': ' + fuel.uomList[8].Name));
        }
        System.assertEquals(true, isError);

        // After assigning the correct Selling UOM, there should be no error inserting it
        salesOrderLine.Selling_UOM__c = fuel.uomList[8].Id;
        try {
            insert salesOrderLine;
        } catch (Exception e) {
            System.assert(false, e.getMessage());
        }

        // After inserting, you should not be able to change the UOM
        Sales_Order_Line__c SOL = [SELECT Id FROM Sales_Order_Line__c WHERE Memo__c = 'salesOrderLineUOMTest' LIMIT 1];
        SOL.Selling_UOM__c = fuel.uomList[9].Id;
        isError = false;
        try {
            update SOL;
        } catch (System.DmlException e) {
            isError = true;
            Set<String> errorMessages = new Set<String>();

            for (Integer i = 0; i < e.getNumDml(); i++) {

                // Process exception here
                errorMessages.add(e.getDmlMessage(i));

            }

            System.assert(errorMessages.contains(Label.The_Selling_UOM_should_remain_consistent_with_the_Item_Purchasing_UOM + ': ' + fuel.uomList[8].Name));
        }
        System.assertEquals(true, isError);

        test.stopTest();
    }

    // KNDY-9596
    static testMethod void SalesOrderLineTest_testCloseBundleParentSalesOrderLine() {
        Sales_Order__c salesOrder = fuel.salesOrder;
        List<Sales_Order_Line__c> salesOrderLines = fuel.salesOrder.Sales_Order_Lines__r;
        Product__c product = fuel.product;

        // sol 0 parent, sol 1 child
        salesOrderLines[1].Parent_Sales_Order_Line__c = salesOrderLines[0].Id;
        update salesOrderLines;

        product.Bundle__c = true;   // update the product bundle of the parent
        update product;

        Fulfillment__c fulfillment1 = new Fulfillment__c(Name = 'F1',
                Sales_Order_Line__c = salesOrderLines[1].Id,
                Status__c = 'Complete');
        insert fulfillment1;
        // One more should have gotten created for the parent SOL
        System.assertEquals(2, [SELECT Id FROM Fulfillment__c].size());

        for (Sales_Order_Line__c SOL : [SELECT Id, Status__c, Sales_Order__r.Status__c FROM Sales_Order_Line__c]) {
            System.assertEquals('Closed', SOL.Status__c);
            System.assertEquals('Closed', SOL.Sales_Order__r.Status__c);
        }

        for (Fulfillment__c fulfillment : [SELECT Id, Status__c, Type__c, Unit_Price__c, Quantity__c, Sales_Order_Line__c
                                           FROM Fulfillment__c
                                           WHERE Sales_Order_Line__c = :salesOrderLines[0].Id]) {
            System.assertEquals('Complete', fulfillment.Status__c);
            System.assertEquals('Bundle', fulfillment.Type__c);
            System.assertEquals(salesOrderLines[0].Unit_Price__c, fulfillment.Unit_Price__c);
            System.assertEquals(salesOrderLines[0].Quantity_Ordered__c, fulfillment.Quantity__c);
            System.assertEquals(salesOrderLines[0].Id, fulfillment.Sales_Order_Line__c);
        }
    }

    ///*******************************************************************************************************************************************************************************************************
    //*   Copied From SalesOrderConfirmShipTest -  TESTS
    //*******************************************************************************************************************************************************************************************************/

    public static testMethod void SalesOrderConfirmShipTest_testConfirmShip() { //test happy scenario
        ApexPages.Standardcontroller con;
        con = new ApexPages.Standardcontroller(fuel.salesOrder);

        List<SKID__c> stockSkids = fillStock();

        SOPlanExt SOPExt = new SOPlanExt(con);
        SOPExt.plan();
        System.assertEquals(false, SOPExt.hasErrors);

        fuel.salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c from Sales_Order__c where id = :fuel.salesOrder.Id limit 1];

        Test.startTest();
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);

        system.assert( SOAExt.solWrapperList.size() == 2 );

        for ( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ) {

            system.assert( sw.skidList.size() == 1); // number of available location skids

            sw.skidList[0].Quantity_Allocated__c  = sw.sol.Quantity_Ordered__c;
        }

        SOAExt.allocate();

        con = new ApexPages.Standardcontroller(fuel.salesOrder);

        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);

        socpExt.confirmPick();

        SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension(con);

        socsExt.last();
        socsExt.previous();
        socsExt.next();

        DateTime adjustedShipDate = DateTime.newInstance(System.today() - 1, Time.newInstance(7, 42, 00, 0));
        socsExt.shipment.Date_Shipped__c = adjustedShipDate;

        try {
            socsExt.confirmShip();
        } catch (exception e) {
            System.assert(false, 'Unexpected exception thrown.');
        }

        Test.stopTest();
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Error) == false, ApexPages.getMessages() );
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Warning) == false );

        List<Sales_Order_Line__c> soLines =  [select ID, Quantity_Ordered__c, Quantity_Shipped__c, Quantity_Backordered__c, Status__c,
                                              Product__r.Item__r.Non_Inventory__c, Has_Exceptions__c, Sales_Order__c, Sales_Order__r.Status__c
                                              from Sales_Order_Line__c
                                              where Sales_Order__c = :fuel.salesOrder.Id
                                                      and Has_Exceptions__c = false
                                                              order by Line__c ASC];
        System.assertEquals(2, soLines.size());
        system.assert( soLines[0].Quantity_Shipped__c == soLines[0].Quantity_Ordered__c );
        system.assert( soLines[1].Quantity_Shipped__c == soLines[1].Quantity_Ordered__c );

        system.assertEquals(SalesOrderService.SO_STATUS_CLOSED, soLines[0].Sales_Order__r.Status__c);
        system.assertEquals(SalesOrderService.SO_STATUS_CLOSED, soLines[0].Status__c);
        system.assertEquals(SalesOrderService.SO_STATUS_CLOSED, soLines[1].Status__c);

        List<Shipment__c> shList1 = [Select Id, Status__c, Date_Shipped__c from Shipment__c];
        system.assertEquals(1, shList1.size());
        system.assert( shList1[0].Status__c == 'Confirmed');
        system.assertEquals(shList1[0].Date_Shipped__c, adjustedShipDate);

        List<Shipment_Line__c> shlList = [select Id, Quantity_Shipped__c, Shipment__c, Sales_Order__c, Sales_Order_Line__r.Product__c, Product__c,
                                          Sales_Order_Line__r.Ship_From_Location__c, Location__c, Sales_Order_Line__r.Quantity_Ordered__c
                                          From Shipment_Line__c
                                          where Sales_Order_Line__r.Sales_Order__c = :fuel.salesOrder.Id];
        System.assertEquals(2, shlList.size()); // 2 Shipment lines corresponding to 2 SO lines
        system.assert( shlList[0].Quantity_Shipped__c == shlList[0].Sales_Order_Line__r.Quantity_Ordered__c );
        system.assert( shlList[1].Quantity_Shipped__c == shlList[1].Sales_Order_Line__r.Quantity_Ordered__c );

        List<Inventory_Transaction__c> shipmentTransactions = [Select Id, Item__c, Inventory_Change__c, From_Skid__c, Finalized__c, From_Location__c, Quantity__c, Sales_Order_Line__c, Type__c,
                                       Sales_Order_Line__r.Quantity_Ordered__c
                                       from Inventory_Transaction__c
                                       where Type__c = 'Sales Order Shipment'];
        system.assertNotEquals(0, shipmentTransactions.size());
        system.assert( shipmentTransactions.size() == 2 );
        system.assert( shipmentTransactions[0].From_Skid__c == null ); //as we shipped everything we allocated
        system.assert( shipmentTransactions[1].From_Skid__c == null );
        system.assert( shipmentTransactions[0].Quantity__c == shipmentTransactions[0].Sales_Order_Line__r.Quantity_Ordered__c  );
        system.assert( shipmentTransactions[1].Quantity__c == shipmentTransactions[1].Sales_Order_Line__r.Quantity_Ordered__c );
        system.assert( shipmentTransactions[0].Inventory_Change__c != null );
        system.assert( shipmentTransactions[1].Inventory_Change__c != null  );
    }

    // OTC-720: For a SO with 2 SOLs where 1 SOL is complete shipped and has a deactivated item, release the other SOL with active item
    public static testMethod void SalesOrderConfirmShipTest_testShipConfirmWhenCancelLineHasInactiveProduct() {
        List<Period__c> periodList = fuel.periodList;
        List<SKID__c> skids = fillStock();
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
        //Transit_Route__c route = fuel.transitRoute;

        Sales_Order__c sorder = fuel.salesOrder;
        Sales_Order_Line__c[] sols = fuel.salesOrder.Sales_Order_Lines__r;

        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(sorder);

        // cancel open SOL line
        SalesOrderLinesAddManageExt solam = new SalesOrderLinesAddManageExt(con);
        List <SalesOrderLinesAddManageExt.SOLineWrapper>  solWrapedLines = solam.wrapLines([select id, Product__c, Quantity_Ordered__c from Sales_Order_Line__c ]);
        System.assertEquals(2, solWrapedLines.size()); // check that we have 2 lines open
        solam.soLineList = solWrapedLines;
        // set index to select line for cancellation
        String selected_indexes = Apexpages.currentPage().getParameters().put('selected_indexes', '0'); // select the first line in our solWrapedLines Index to be cancelled
        solam.cancelLines();

        // verify that the SO is closed once SOL is cancelled
        Sales_Order_Line__c[] closedSol = [select id, Sales_Order__r.status__c from Sales_Order_Line__c where status__c = :SalesOrderService.SO_STATUS_CANCEL];
        system.assertEquals(1, closedSol.size());

        // chance cancelled line item's to deactivate
        Item__c cancelledSOLItem = [select id, product__r.Item__c, product__r.item__r.Active__c from Sales_Order_Line__c where status__c = :SalesOrderService.SO_STATUS_CANCEL].Product__r.Item__r;
        cancelledSOLItem.Active__c = false;
        update cancelledSOLItem;

        //ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(sorder);
        SOPlanExt soPlanExt = new SOPlanExt(con);
        Test.startTest();

        soPlanExt.plan();
        System.assertEquals(false, ExceptionService.hasErrors, ExceptionService.messages);
        System.assertEquals(false, soPlanExt.hasErrors);

        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);
        system.assert( SOAExt.solWrapperList.size() == 1 );
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Error) == false, ApexPages.getMessages() );

        SOAExt.allocate();
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Error) == false, ApexPages.getMessages() );
        system.debug(LoggingLevel.INFO, 'Queries plan()' + Limits.getQueries() );

        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        socpExt.confirmPick();
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Error) == false, ApexPages.getMessages() );
        system.debug(LoggingLevel.INFO, 'Queries plan()' + Limits.getQueries() );


        SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension(con);
        socsExt.confirmShip();
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Error) == false, ApexPages.getMessages() );
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Warning) == false );


        system.debug(LoggingLevel.INFO, 'Queries plan()' + Limits.getQueries() );

        //shipment is finalized even though 1 SHL has 0 shipped. This needs to happen for accounting reasons
        for (Shipment__c ship : [select id, status__c, Finalized__c, Locked__c from Shipment__c]) {
            system.assertEquals('Confirmed', ship.status__c);
            system.assertEquals(false, ship.Finalized__c);
            system.assertEquals(true, ship.Locked__c);
        }
    }

    /*
    public static testMethod void SalesOrderConfirmShipTest_testConfirmShipBracketsPricingUpdate() {

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

        BracketPricingUpchargeManageExt.BracketPriceWrapper brack1, brack2, brack3, brack4;

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
        //brack5 = bracketWraps[4];
        //brack5.inUse = true;
        //brack5.volumeRangeBottom = 0;
        //brack5.percentUpcharge = 4;
        //brack5.pricebookLineField = 'Price_5__c';

        // Persist to DB
        ext.onSave();
        Test.startTest();
        // Reload extension to verify
        ext = new BracketPricingUpchargeManageExt(new ApexPages.StandardController(fuel.company));

        Pricebook__c pricebook = new Pricebook__c();
        pricebook.Name = fuel.company.Name +  ' Orange Pricebook2-CPY';
        pricebook.Company__c = fuel.company.Id;
        pricebook.Currency__c = fuel.currencyUSD.id;
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
                FROM Pricebook_Line__c WHERE Id IN :new Set<Id> {pl.Id, pl2.Id}]);
        Pricebook_Line__c plReloaded = [Select Price__c, Price_2__c, Price_3__c, Price_4__c, Price_5__c from Pricebook_Line__c Where Id = :pl.Id];
        System.debug (LoggingLevel.INFO, 'plReloaded : ' + plReloaded);

        //Check that our pricing is working properly
        System.assertEquals(10.1, plReloaded.Price_2__c);
        System.assertEquals(10.2, plReloaded.Price_3__c);
        System.assertEquals(10.3, plReloaded.Price_4__c);
        //System.assertEquals(10.4, plReloaded.Price_5__c);

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Company__c = fuel.company.id;
        salesOrder.Customer__c = fuel.customerSoldTo.id;
        salesOrder.Bill_To__c = fuel.customerBillTo.id;
        salesOrder.Ship_To__c = fuel.customerShipTo.Id;
        salesOrder.Payment_Term__c = fuel.terms.id;
        salesOrder.pricebook__c = pricebook.id;// make sure its pointing to normal pricebook
        salesOrder.Ship_From_Location__c = fuel.location2.Id;
        //salesOrder.Price_Determination_Date__c = SalesOrderService.PRICE_DET_SHIPMENT;
        //salesOrder.Price_Determination_Date__c = SalesOrderService.PRICE_DET_ORDER;
        salesOrder.Price_Determination_Date__c = SalesOrderService.PRICE_DET_MANUAL;
        //salesOrder.Pricing_Date__c = System.today() + 3;
        salesOrder.Required_Date__c = System.today() + 5;
        salesOrder.Currency__c = fuel.currencyUSD.id;
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

        // Plan
        ApexPages.Standardcontroller con;
        con = new ApexPages.Standardcontroller(salesOrder);

        List<SKID__c> stockSkids = fillStock();
        system.debug(Logginglevel.INFO, 'stockSkids  ' + stockSkids);

        salesOrder.Price_Determination_Date__c = SalesOrderService.PRICE_DET_SHIPMENT;
        update salesOrder;

        SOPlanExt SOPExt = new SOPlanExt(con);
        SOPExt.plan();
        System.assertEquals(false, SOPExt.hasErrors, ExceptionService.messages);

        //salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c from Sales_Order__c where id = :salesOrder.Id limit 1];
        Sales_Order__c SO = [SELECT Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c, Bracket_Price_Field_In_Use__c, Total_Product_Weight__c, Price_Determination_Date__c,
                             Pricing_Date__c,
                             (SELECT Id, Quantity_Ordered__c, Unit_Price__c, Product__c, Estimated_Ship_date__c FROM Sales_Order_Lines__r)
                             FROM Sales_Order__c WHERE Id = :salesOrder.Id LIMIT 1];

        Date shipmentDate = system.today() + 5;
        System.debug(LoggingLevel.INFO, SO.Sales_Order_Lines__r[0]);
        system.debug(Logginglevel.INFO, SO);
        System.assertEquals(shipmentDate, SO.Pricing_Date__c);
        System.assert(SO.Sales_Order_Lines__r[0].Unit_Price__c == 10.3, SO.Sales_Order_Lines__r[0].Unit_Price__c);
        System.assert(SO.Bracket_Price_Field_In_Use__c.contains('Price_4__c'));

        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave, ApexPages.getMessages());


        system.assert( SOAExt.solWrapperList.size() == 1 );

        for ( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ) {
            system.assert( sw.skidList.size() == 1); // number of available location skids
            sw.skidList[0].Quantity_Allocated__c  = sw.sol.Quantity_Ordered__c;
        }

        // Allocate
        SOAExt.allocate();

        con = new ApexPages.Standardcontroller(salesOrder);

        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        socpExt.confirmPick();

        //Set the pricing date to match pricing 1. After confirm ship, the date will be today() and change the pricing date to today.
        salesOrder.Pricing_Date__c = System.today() + 3;
        update salesOrder;
        Test.stopTest();
        // Confirm Ship
        SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension(con);
        socsExt.confirmShip();

        system.assert( ApexPages.hasMessages(ApexPages.Severity.Error) == false, ApexPages.getMessages() );
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Warning) == false );


        SO = [SELECT Id, Bracket_Price_Field_In_Use__c, Pricing_Bracket__c, Total_Product_Weight__c, Pricing_Date__c,
              (SELECT Id, Quantity_Ordered__c, Unit_Price__c, Product__c, Has_Exceptions__c FROM Sales_Order_Lines__r)
              FROM Sales_Order__c WHERE Id = :salesOrder.Id LIMIT 1];
        Shipment__c SH = [select Id, Shipment_Date_Estimated__c, Date_Shipped__c FROM Shipment__c LIMIT 1];
        System.debug(LoggingLevel.INFO, '*** SH: ' + SH);
        // Unit price should be 20 + upcharge for bracket
        System.debug(LoggingLevel.INFO, SO.Sales_Order_Lines__r);
        //System.assertEquals(shipmentDate, SO.pricing_date__c);

        System.assertEquals(SO.Pricing_Date__c, SH.Date_Shipped__c.date(), 'Expected pricing date is the confirm ship date which is today');
        System.assertEquals(20.6, SO.Sales_Order_Lines__r[0].Unit_Price__c, 'Expected price has an upcharge of > 20. This is PBL price for today.');
        System.assertEquals(false, SO.Sales_Order_Lines__r[0].Has_Exceptions__c);

        System.debug(LoggingLevel.INFO, SO);

        // OTC-699
        // Update the Pricing Bracket to Bracket 2
        SO.Pricing_Bracket__c = 'Bracket 2';
        update SO;

        SO = [SELECT Id, Bracket_Price_Field_In_Use__c, Pricing_Bracket__c, Total_Product_Weight__c, Pricing_Date__c,
              (SELECT Id, Quantity_Ordered__c, Unit_Price__c, Product__c, Has_Exceptions__c FROM Sales_Order_Lines__r)
              FROM Sales_Order__c WHERE Id = :salesOrder.Id LIMIT 1];
        System.assert(SO.Bracket_Price_Field_In_Use__c.contains('Price_2__c'));

        System.assertEquals(20.2, SO.Sales_Order_Lines__r[0].Unit_Price__c);
        System.assertEquals(false, SO.Sales_Order_Lines__r[0].Has_Exceptions__c);

        // Update the Pricing Bracket to Bracket 5
        SO.Pricing_Bracket__c = 'Bracket 5';
        update SO;


        SO = [SELECT Id, Bracket_Price_Field_In_Use__c, Pricing_Bracket__c, Total_Product_Weight__c, Pricing_Date__c,
              (SELECT Id, Quantity_Ordered__c, Unit_Price__c, Product__c, Has_Exceptions__c FROM Sales_Order_Lines__r)
              FROM Sales_Order__c WHERE Id = :salesOrder.Id LIMIT 1];
        System.assert(SO.Bracket_Price_Field_In_Use__c.contains('Price_5__c'));

        System.assertEquals(null, SO.Sales_Order_Lines__r[0].Unit_Price__c);
        System.assertEquals(true, SO.Sales_Order_Lines__r[0].Has_Exceptions__c);
        System.assert(ExceptionService.hasOpenTask(SO.Sales_Order_Lines__r[0].Id, ExceptionUtil.SOL_MISSING_PRICE.code), 'Expects sales order line to have an exception');
    }
    */

    private static testMethod void SalesOrderConfirmShipTest_testNonInvItem() {
        Item__c item = fuel.itemList[0];
        item.Source__c = 'Expense';
        item.Non_Inventory__c = true;
        update item;

        SalesOrderConfirmShipExtension socsExt;
        ApexPages.Standardcontroller con;

        con = new ApexPages.Standardcontroller(fuel.salesOrder);

        List<SKID__c> stockSkids = fillStock();

        SOPlanExt SOPExt = new SOPlanExt(con);
        SOPExt.plan();
        System.assertEquals(false, SOPExt.hasErrors);

        Test.startTest();
        fuel.salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c from Sales_Order__c where id = :fuel.salesOrder.Id limit 1];
        Shipment_Line__c createdShipmentLineNonInv = [SELECT Id, Quantity_Shipped__c FROM Shipment_Line__c ORDER BY Quantity_Shipped__c ASC limit 1];

        system.assertEquals(0, createdShipmentLineNonInv.Quantity_Shipped__c);
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);

        system.assert( SOAExt.solWrapperList.size() == 1 );

        for ( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ) {

            system.assert( sw.skidList.size() == 1);
            sw.skidList[0].Quantity_Allocated__c  = 15;
        }

        SOAExt.allocate();

        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        socpExt.confirmPick();

        con = new ApexPages.Standardcontroller(fuel.salesOrder);
        socsExt = new SalesOrderConfirmShipExtension(con);
        socsExt.confirmShip();

        createdShipmentLineNonInv = [SELECT Id, Quantity_Shipped__c FROM Shipment_Line__c ORDER BY Quantity_Shipped__c ASC limit 1];
        Test.stopTest();
        system.assertEquals(15, createdShipmentLineNonInv.Quantity_Shipped__c);
    }

    public static testMethod void SalesOrderConfirmShipTest_testAllocationErrors() {

        // OTC-260 Make sure you can't ship where there are allocation SKIDs for the SO

        SalesOrderConfirmShipExtension socsExt;
        ApexPages.Standardcontroller con;
        Test.startTest();
        con = new ApexPages.Standardcontroller(fuel.salesOrder);

        List<SKID__c> stockSkids = fillStock();

        SOPlanExt SOPExt = new SOPlanExt(con);
        SOPExt.plan();
        System.assertEquals(false, SOPExt.hasErrors);

        fuel.salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c from Sales_Order__c where id = :fuel.salesOrder.Id limit 1];

        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);

        system.assert( SOAExt.solWrapperList.size() == 2 );

        for ( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ) {

            system.assert( sw.skidList.size() == 1); // number of available location skids
            sw.skidList[0].Quantity_Allocated__c  = 15;
        }

        SOAExt.allocate();

        con = new ApexPages.Standardcontroller(fuel.salesOrder);
        socsExt = new SalesOrderConfirmShipExtension(con);
        system.assertEquals(true, socsExt.disableConfirmShip);
        Test.stopTest();
    }

    public static testMethod void SalesOrderConfirmShipTest_testErrors() {
        SalesOrderConfirmShipExtension socsExt;
        ApexPages.Standardcontroller con;
        Test.startTest();
        con = new ApexPages.Standardcontroller(fuel.salesOrder);

        Item__c item = fuel.itemList[5];
        item.Source__c = 'Expense';
        item.Non_Inventory__c = true;
        update item;

        // Make sure that there are two SOLs
        List<Sales_Order_Line__c> solList = [SELECT Id FROM Sales_Order_Line__c];
        System.assertEquals(2, solList.size());

        List<SKID__c> stockSkids = fillStock();

        SOPlanExt SOPExt = new SOPlanExt(con);
        SOPExt.plan();
        System.assertEquals(false, SOPExt.hasErrors);

        fuel.salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c from Sales_Order__c where id = :fuel.salesOrder.Id limit 1];

        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);

        system.assert( SOAExt.solWrapperList.size() == 1 );

        for ( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ) {

            system.assert( sw.skidList.size() == 1); // number of available location skids
            sw.skidList[0].Quantity_Allocated__c  = 15;
        }

        SOAExt.allocate();

        con = new ApexPages.Standardcontroller(fuel.salesOrder);

        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        socpExt.confirmPick();

        // Cancel the Non-inventory item
        Sales_Order_Line__c solNonInv = [SELECT Id FROM Sales_Order_Line__c
                                         WHERE Product__c = :fuel.product2.Id LIMIT 1];
        solNonInv.Status__c = 'Cancelled';
        update solNonInv;

        // Test if Credit Hold can be overridden.
        fuel.salesOrder = [select Id, Customer__r.Top_Parent_Customer__r.Credit_Hold__c,
                           Override_Credit_Hold__c, Status__c
                           from Sales_Order__c
                           where Id = :fuel.salesOrder.Id];

        fuel.salesOrder.Customer__r.Top_Parent_Customer__r.Credit_Hold__c = true; //KNDy-2114
        update fuel.salesOrder.Customer__r.Top_Parent_Customer__r;

        con = new ApexPages.Standardcontroller(fuel.salesOrder);
        // Allocate quantity to the sales order.
        socsExt = new SalesOrderConfirmShipExtension(con);

        // Test that 'Confirm Ship' is disabled.
        system.assertNotEquals(true, socsExt.disableConfirmShip);

        fuel.salesOrder.Override_Credit_Hold__c = true;
        update fuel.salesOrder;

        socsExt = new SalesOrderConfirmShipExtension(con);

        system.assertNotEquals(null, socsExt.soLineList);

        // There should only be one line, because one is cancelled
        system.assertEquals(1, socsExt.soLineList.size());

        // Test that 'Confirm Ship' is enabled.
        system.assertNotEquals(true, socsExt.disableConfirmShip);
        Test.stopTest();
    }

    public static testMethod void SalesOrderConfirmShipTest_testUndoConfirmPick() {
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType,Currency__c.sObjectType ,Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,
            Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, item_attribute__c.sObjectType,Shipment__c.sObjectType,Customer__c.sObjectType, Shipment_Line__c.sObjectType,Product__c.sObjectType,Item__c.sObjectType};

        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        Sales_Order__c salesOrder = fuel.salesOrder;

        List<SKID__c> skids = fillStock();
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;

        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        
        delete configList;
        
        SOPlanExt soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();
        System.assertEquals(false, soPlanExt.hasErrors);

        salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c from Sales_Order__c where id = :salesOrder.Id limit 1];

        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);

        system.assert( SOAExt.solWrapperList.size() == 2 );

        for ( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ) {

            system.assert( sw.skidList.size() == 1); // number of available location skids

            sw.skidList[0].Quantity_Allocated__c  = sw.sol.Quantity_Ordered__c;
        }
        test.startTest();
        SOAExt.allocate();


        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);

        socpExt.confirmPick();

        Map<Id, Sales_Order_Line__c> soLineMap = new Map<Id, Sales_Order_Line__c>(socpExt.soLineList);
        map<Id, Inventory_Transaction__c> itList = new map<Id, Inventory_Transaction__c>([Select Id, Quantity__c, Type__c from Inventory_Transaction__c]); //where Sales_Order_Line__c IN :soLineMap.keySet()
        system.assertEquals( 2, itList.values().size(), itList );

        String selectedLines = '';
        for (Id selectedId : itList.keySet()) {
            selectedLines += selectedId + ',';
        }

        SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension(con);

        ApexPages.currentPage().getParameters().put('selectedIndexes', selectedLines);
        socsExt.undoConfirmPick();

        list<Inventory_Transaction__c> unallocITList = [Select Id, Inventory_Change__c, Quantity__c, To_Location__c, From_Location__c, Type__c, Sales_Order_Line__r.Ship_From_Location__c from Inventory_Transaction__c where type__c = 'Sales Order Undo Pick'];
        system.assert( unallocITList.size() == 2, ApexPages.getMessages() );
        for (Inventory_Transaction__c it : unallocITList)
            System.assert(it.Inventory_Change__c != null);

        list<Inventory_Transaction__c> allocITList = [Select Id, Quantity__c, Type__c, Reversed__c from Inventory_Transaction__c where type__c = 'Sales Order Pick'];
        system.assert( allocITList.size() == 2 );
        system.assert( allocITList[0].Reversed__c == true);
        system.assert( allocITList[1].Reversed__c == true);

        set<Id> shipFromLocations = new set<Id>();
        shipFromLocations.add(unallocITList[0].Sales_Order_Line__r.Ship_From_Location__c);
        shipFromLocations.add(unallocITList[1].Sales_Order_Line__r.Ship_From_Location__c);

        list<SKID__c> allocatedSkids = [ select id , Quantity__c, Sales_Order_Line__c, Sales_Order_Line__r.Quantity_Ordered__c from SKID__c where type__c = 'Allocated'];
        system.assert( allocatedSkids.size() == 2);
        system.assert( allocatedSkids[0].Quantity__c == allocatedSkids[0].Sales_Order_Line__r.Quantity_Ordered__c );
        system.assert( allocatedSkids[1].Quantity__c == allocatedSkids[1].Sales_Order_Line__r.Quantity_Ordered__c );

        list<SKID__c> skidsAtShippingDock = [ select id , Quantity__c, Sales_Order_Line__c, Sales_Order_Line__r.Quantity_Ordered__c from SKID__c where type__c = 'Location' and Location__c IN:shipFromLocations];
        system.assert(skidsAtShippingDock.size() == 0, skidsAtShippingDock + ',::' + shipFromLocations );

        list<SKID__c> skidsAtStock = [ select id , Quantity__c, Sales_Order_Line__c, Sales_Order_Line__r.Quantity_Ordered__c from SKID__c where type__c = 'Location' and Location__c = :fuel.location3.id and Quantity__c = 200];
        system.assert(skidsAtStock.size() == fuel.itemList.size());

        Test.stopTest();
    }

    //public static testMethod void SalesOrderConfirmShipTest_testRunningThroughTwoPlanAllocationCycles() { //KNDY-1832

    //    system.assert(fuel.periodList != null && fuel.periodList.size() > 0);

    //    Sales_Order__c salesOrder = fuel.salesOrder;

    //    List<SKID__c> skids = fillStock();

    //    List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
    //    List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;

    //    ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
    //    SOPlanExt soPlanExt = new SOPlanExt(con);
    //    soPlanExt.plan();
    //    System.assertEquals(false, soPlanExt.hasErrors);

    //    salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c from Sales_Order__c where id = :salesOrder.Id limit 1];

    //    SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
    //    system.assertEquals(false, SOAExt.hideSave);

    //    system.assert( SOAExt.solWrapperList.size() == 2 );

    //    // Allocate one sales order line.
    //    system.assert( SOAExt.solWrapperList[0].skidList.size() == 1); // number of available location skids

    //    SOAExt.solWrapperList[0].skidList[0].Quantity_Allocated__c = 0;

    //    SOAExt.allocate();

    //    Test.startTest();

    //    SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
    //    socpExt.confirmPick();

    //    SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension(con);
    //    socsExt.confirmShip(); // Pick and confirm the 1 SO Line

    //    // After this point, one of the SO lines will be marked as Closed and shipment header as Confirmed

    //    List<Sales_Order_Line__c> soLines =  [select ID, Quantity_Ordered__c, Quantity_Shipped__c, Quantity_Backordered__c, Status__c,
    //                                          Product__r.Item__r.Non_Inventory__c, Has_Exceptions__c,
    //                                          (select Id, Type__c, Quantity__c, Location__c, Shipment_Line__c, Sales_Order_Line__c
    //                                           from SKIDs__r
    //                                           where Type__c = :SKIDService.SKID_TYPE_SO_DEMAND)
    //                                          from Sales_Order_Line__c
    //                                          where Sales_Order__c = :fuel.salesOrder.Id
    //                                                  and Has_Exceptions__c = false and Status__c != 'Closed'
    //                                                          order by Line__c ASC];
    //    //system.debug(LoggingLevel.INFO, soLines);
    //    system.assert(soLines.size() > 0);

    //    for (Sales_Order_Line__c sol : soLines) {
    //        system.assertEquals(0, sol.SKIDs__r.size(), 'SO Demand skids should have been deleted.');
    //    }

    //    //before KNDY-1832 You get an error if you try to release a SO again regardless if all lines have been allocated or not
    //    soPlanExt = new SOPlanExt(con);
    //    soPlanExt.plan();
    //    System.assertEquals(false, soPlanExt.hasErrors, 'Sales Order Plan has errors: ' + ExceptionService.messages);

    //    SOAExt = new SalesOrderAllocateExt(con);
    //    system.debug(LoggingLevel.INFO, SOAExt.solWrapperList);
    //    SOAExt.solWrapperList[0].skidList[0].Quantity_Allocated__c = 0;
    //    SOAExt.allocate();

    //    List<Shipment__c> shList2 = [Select Id, Status__c from Shipment__c ORDER BY Status__c DESC];
    //    system.assertEquals(2, shList2.size()); // You have 2 Shipments resulting from running through the process twice

    //    // Check that the first shipment is confirmed and the second is released
    //    system.assertEquals(ShipmentService.SHIPMENT_STATUS_CONFIRMED, shList2[0].Status__c);
    //    system.assertEquals(ShipmentService.SHIPMENT_STATUS_RELEASED, shList2[1].Status__c);

    //    List<Shipment_Line__c> shlList = [select Id, Quantity_Shipped__c, Shipment__c, Sales_Order__c, Sales_Order_Line__r.Product__c, Product__c,
    //                                      Sales_Order_Line__r.Ship_From_Location__c, Location__c
    //                                      From Shipment_Line__c
    //                                      where Sales_Order_Line__r.Sales_Order__c = :fuel.salesOrder.Id];

    //    //Now, you should have shipment lines corresponding to 2 shipment headers.
    //    system.assertEquals(3, shlList.size());

    //    Set<Id> allocatedLines = new Set<Id>();

    //    for ( Sales_Order_Line__c sol : socpExt.soLineList ) {
    //        allocatedLines.add( sol.SKIDs__r[0].id ); //as there is only one allocated skid per so line here
    //        //allocatedLines.add( sol.id ); //as there is only one allocated skid per so line here
    //    }

    //    String selectedLines = '';
    //    for (Id selectedId : allocatedLines) {
    //        selectedLines += selectedId + ',';
    //    }

    //    //system.debug(LoggingLevel.INFO, 'selectedLines ' + selectedLines);
    //    //con = new ApexPages.Standardcontroller(fuel.salesOrder);
    //    //socpExt = new SalesOrderConfirmPickExt(con);
    //    ApexPages.currentPage().getParameters().put('selectedIndexes', selectedLines);
    //    System.assertNotEquals(null, socpExt.unallocate()); //unallocating the selected lines

    //    // After unallocating, the first shipment is confirmed and the second is planned
    //    shList2 = [Select Id, Status__c from Shipment__c ORDER BY Status__c DESC];
    //    system.assertEquals(2, shList2.size()); // You have 2 Shipments resulting from running through the process twice
    //    system.assertEquals(ShipmentService.SHIPMENT_STATUS_CONFIRMED, shList2[0].Status__c);
    //    system.assertEquals(ShipmentService.SHIPMENT_STATUS_PLANNED, shList2[1].Status__c);

    //    Test.stopTest();
    //}

    public static testMethod void SalesOrderConfirmShipTest_testonhold() {
        test.startTest();
        ApexPages.Standardcontroller con;
        fuel.salesOrder.Hold__c = true;
        update fuel.salesOrder;

        con = new ApexPages.Standardcontroller(fuel.salesOrder);
        SalesOrderConfirmShipExtension SOCsExt1 = new SalesOrderConfirmShipExtension(con);
        //socsExt = new SalesOrderConfirmShipExtension(con);
        System.assertEquals(true, SOCsExt1.disableConfirmShip);


        System.assertequals('This sales order is on hold and cannot be packed.', 'This sales order is on hold and cannot be packed.') ;
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Error) == true, ApexPages.getMessages() );

        Test.stopTest();
    }

    public static testMethod void resaleOrderTest(){
        test.startTest();
        Sales_Order__c rsaleOrder = resaleOrder;
        List<Sales_Order_Line__c> rsoLs = resaleOrderLines;
        System.assert(rsoLs.size() == 2, 'Resales orders are not created successfully');
        System.assert(rsaleOrder != null, rsaleOrder);

        //Insert Non-Resale fulfillment source sales order line: Should throw exception
        Sales_Order_Line__c sol = new Sales_Order_Line__c();
        sol.Product__c = fuel.product.Id;
        sol.Unit_Price__c = 10;
        sol.Quantity_Ordered__c = 10;
        sol.Sales_Order__c = rsaleOrder.Id;
        sol.Company__c = rsaleOrder.Company__c;
        sol.Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY;

        try{
            insert sol;
            System.assert(false, 'Cannot insert sales order line of Fulfillment source Inventory on a Sales Order of type Resale');
        } catch(DMLException e){
            System.assert(true, e);
        }
        
        //Update Sales Order from Resale to any other type: Should throw an exception
        rsaleOrder.Type__c = SalesOrderService.SO_TYPE_REPAIR;
        try{
            update resaleOrder;
            System.assert(false, 'Cannot update the Sales Order type from Resale to other types');
        } catch(DMLException e){
            System.assert(true, e);
        }

        Test.stopTest();
    }
}