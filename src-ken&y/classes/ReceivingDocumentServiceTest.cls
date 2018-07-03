/**
 * This class contains unit tests for validating the behavior of methods in ReceivingDocumentService.cls.
 *
 */
@isTest
public class ReceivingDocumentServiceTest {
    
    static testMethod void ReceivingDocumentNewEditExtCreateTest(){
        
        TestFuel data = new TestFuel();
        Receiving_Document__c rd = new Receiving_Document__c();
        rd.Company__c = data.Company.Id;
        
        Test.startTest();
        
        ReceivingDocumentNewEditExt rdnee = new ReceivingDocumentNewEditExt( new Apexpages.Standardcontroller( rd));
        rd.Status__c = 'Draft';
        rd.Type__c = 'Miscellaneous Receipt';
        
        rdnee.save();
        
        Test.stopTest();
        
        Receiving_Document__c rdSaved = [ select id, Name, Status__c , Type__c from Receiving_Document__c Limit 1 ];
        system.assertNotEquals(null, rdSaved);
        system.assertEquals('Draft', rdSaved.Status__c);
        system.assertEquals('Miscellaneous Receipt', rdSaved.Type__c);
    }
    
    static testMethod void ReceivingDocumentNewEditExtEditTest(){
        
        TestFuel data = new TestFuel();
        Receiving_Document__c rd = new Receiving_Document__c();
        rd.Company__c = data.Company.Id;
        
        Test.startTest();
        
        ReceivingDocumentNewEditExt rdnee = new ReceivingDocumentNewEditExt( new Apexpages.Standardcontroller( rd));
        rd.Status__c = 'Draft';
        rd.Type__c = 'Advanced Shipment Notice';
        rdnee.save();
        
        system.assertEquals(1, ApexPages.getMessages().size());
        
        rd.Type__c = 'Miscellaneous Receipt';
        rdnee.save();
        Receiving_Document__c rdSaved = [ select id, Name, Status__c , Type__c from Receiving_Document__c Limit 1 ];
        system.assertNotEquals(null, rdSaved);
        system.assertEquals('Draft', rdSaved.Status__c);
        system.assertEquals('Miscellaneous Receipt', rdSaved.Type__c);
        
        rdSaved.Status__c = 'Closed';
        update rdSaved;
        rdnee = new ReceivingDocumentNewEditExt( new Apexpages.Standardcontroller( rdSaved));
        system.assertEquals(1, ApexPages.getMessages().size(), ApexPages.getMessages()); 
        
        Test.stopTest();
    }
    
    static testmethod void ReceivingDocumentLinesAddManageExt_test1() {
        
        TestFuel data = new TestFuel();
        List<Period__c> periods = data.periodList;
        
        Receiving_Document__c rd = data.receivingDocumentMisc;
        
        Test.startTest();
            
        rd.Status__c = 'Closed';
        update rd;
        
        ReceivingDocumentLinesAddManageExt con1 = new ReceivingDocumentLinesAddManageExt( new Apexpages.Standardcontroller( rd));
        
        test.stopTest();
        
        system.assert(con1.selecterror == true, ' Status Closed error');
    }
    
    static testmethod void ReceivingDocumentLinesAddManageExt_test2() {
        
        TestFuel data = new TestFuel();
        List<Period__c> periods = data.periodList;
        
        Receiving_Document__c rd = data.receivingDocumentMisc;  
        
        Test.startTest();
        rd.Status__c = 'Draft';
        update rd;
        ReceivingDocumentLinesAddManageExt con = new ReceivingDocumentLinesAddManageExt( new Apexpages.Standardcontroller( rd ));
        system.assert(con.selecterror == false, ' Status Draft error');
        Test.setCurrentPage(Page.ReceivingDocumentLinesAddManage);
        system.assert(con.objectList.size() == 1 );
        
        con.addNewRow();
        
        con.objectList[1].Purchase_Order__c = data.purchaseOrder.Id;
        con.objectList[1].Purchase_Order_Line__c = data.purchaseOrderLines[0].Id;
        
        ApexPages.currentPage().getParameters().put('rowNum','1');
        
        con.objectList[1].Quantity_Declared__c = 5;
        
        system.assert(con.objectList.size() == 2 );
        
        Apexpages.currentPage().getParameters().put('selected_indexes','0');
        system.assert(con.cloneporline()==null, ' cloneporline error');
        
        system.assert(con.objectList.size() == 3 );
        
        Apexpages.currentPage().getParameters().put('selected_indexes','0');
        con.remove();
        
        system.assert(con.objectList.size() == 2, Apexpages.getMessages() );
        
        Test.stopTest();
        
        system.assert(con.save()!=null, ' expected record id ' +  Apexpages.getMessages() );
    
    }
    
    
    static testMethod void testGenerateInvoicesFromReceiptLines() {
        if(KSE.checkTestDispatch()){return;}        

        TestDataForSupplierAutoInvoice td = new TestDataForSupplierAutoInvoice();
             
        Test.startTest();
        
        ReceivingDocumentService.generateInvoicesFromReceiptLines(td.rlIdSet);
        
        //query the Supplier Invoices and Lines to make sure they were created properly             
        List<Supplier_Invoice__c> siList = TestDataForSupplierAutoInvoice.querySupInvoices();

        //make sure the total number of Supplier Invoices got created.  This will be 1 per receipt line.
        System.assertEquals(td.INT_TOTAL, siList.size());
            
        //loop through all the Supplier Invoices that were created and make sure the values are correct
        for (Supplier_Invoice__c si : siList) {
            //get the original objects we created as part of the test data
            Purchase_Order__c po = td.poIdtoPoMap.get(si.Purchase_Order__c);            
            Receiving_Document__c rd = td.PoIdRdMap.get(si.Purchase_Order__c);  
            
            System.assertEquals('Invoice', si.Invoice_Type__c);
            System.assertEquals(po.Company__c, si.Company__c);
            System.assertEquals(po.Remit_To_Supplier__c, si.Supplier__c);
            System.assertNotEquals(null, si.Date_Invoiced__c);
            System.assertEquals(rd.Date_Received__c, si.Date_Received__c);          
            System.assertEquals((10*12) ,si.Invoice_Amount__c);
            System.assertEquals('Incomplete',si.Status__c);
            System.assertEquals(true, si.Hold__c);
            System.assertEquals('Check', si.Payment_Method_G__c);
            System.assertEquals(td.terms.Id, si.Payment_Term__c);
            System.assertNotEquals(null, si.Purchase_Order__c);         
            
            //do assertions on the related invoice line
            System.assertEquals(1, si.Supplier_Invoice_Lines__r.size());
            System.assertEquals((si.Autonumber__c+po.Name+si.Supplier_Invoice_Lines__r[0].Purchase_Order_Line__r.Name), si.Supplier_Invoice__c);
            System.assertEquals(si.Id, si.Supplier_Invoice_Lines__r[0].Supplier_Invoice__c);
            System.assertEquals(po.Id, td.poLineIdToPoIdMap.get(si.Supplier_Invoice_Lines__r[0].Purchase_Order_Line__c));
            System.assertEquals(td.purchasedItem.Id, si.Supplier_Invoice_Lines__r[0].Item__c);
            System.assertEquals('pol desc', si.Supplier_Invoice_Lines__r[0].Description__c);
            System.assertEquals(10, si.Supplier_Invoice_Lines__r[0].Invoice_Quantity__c);
            System.assertEquals(12, si.Supplier_Invoice_Lines__r[0].Unit_Price__c);//KNDY-14371             
        }
        
        //try to generate them again
        ReceivingDocumentService.generateInvoicesFromReceiptLines(td.rlIdSet);
        
        //requery the Supplier Invoices and Lines       
        siList = TestDataForSupplierAutoInvoice.querySupInvoices();       
        
        //make sure they weren't generated a second time
        System.assertEquals(td.INT_TOTAL, siList.size());
        
        Test.stopTest();
    }


    static testMethod void testUpdateReceiptLineLineType() 
    {
        //KNDY-3155
        
        //This test will test the trigger that sets Receipt_Lines__c.Line_Type__c to Receipt_Line__c.Purchase_Order_Line__r.Line_Type__c
        
        
        final Integer INT_POS = 100; //POs to create
        final Integer INT_POLINES_PER_PO = 2; //Lines per PO to create
        
        TestFuel fuel = new TestFuel();
        
        Company__c co = fuel.company;
        Location__c loc = fuel.location;
        Item__c purchasedItem = fuel.itemList[1];        
        Supplier__c sup = fuel.supplier;
        
        //create purchase order(s)
        List<Purchase_Order__c> poList = new List<Purchase_Order__c>();
        for (Integer i=1; i<=INT_POS; i++)
        {
            Purchase_Order__c po = new Purchase_Order__c();
            po.Supplier__c = sup.id;
            po.Remit_To_Supplier__c = sup.id;
            po.Company__c = co.id;          
            poList.add(po);         
        }
        insert poList;          
        
        //create purchase order line(s)
        List<Purchase_Order_Line__c> polList = new List<Purchase_Order_Line__c>();
        for (Purchase_Order__c po: poList) 
        {
            for (Integer i=1; i<=INT_POLINES_PER_PO; i++)
            {
                Purchase_Order_Line__c pol = new Purchase_Order_Line__c();
                pol.Purchase_Order__c = po.Id;
                pol.Order_Quantity__c = 10;        
                pol.Unit_Price__c = 12;
                pol.Item__c = purchasedItem.Id;
                pol.Company__c = co.id;
                pol.Need_Date__c = system.today() + 7;
                pol.Delivery_Location__c = loc.Id;
                pol.Delivery_facility__c = loc.facility__c;
                pol.Line_Type__c = 'lineType1';
                polList.add(pol);                               
            }               
        }
        insert polList;

        //create Receving Documents to receive the POs.  Build a map of PO Id->RD so we have them linked together.
        Map<Id, Receiving_Document__c> PoIdRdMap = new Map<Id, Receiving_Document__c>();
        for (Purchase_Order__c po: poList) 
        { //loop through and create one RD for each PO
            Receiving_Document__c rd = new Receiving_Document__c();            
            rd.Company__c = co.Id;
            rd.Supplier__c = sup.Id;
            rd.Date_Received__c = system.today();
            rd.Currency__c = TestFuel.currencyUSD.id;
            PoIdRdMap.put(po.Id, rd);
        }
        insert(PoIdRdMap.values());         
        
        //create Receipt Lines for the Receving Documents that correspond to the PO lines
        List<Receipt_Line__c> rlList = new List<Receipt_Line__c>();
        for (Purchase_Order_Line__c pol: polList) 
        {
            Receipt_Line__c rl = new Receipt_Line__c();
            rl.Company__c = co.Id;
            rl.Supplier__c = sup.Id;
            rl.Receiving_Document__c = PoIdRdMap.get(pol.Purchase_Order__c).Id;
            rl.Purchase_Order__c = pol.Purchase_Order__c;
            rl.Purchase_Order_Line__c = pol.Id;
            rl.Item__c = purchasedItem.Id;
            rl.Uninvoiced_Quantity__c = 10;
            rl.Unit_Price__c = 12;          
            rlList.add(rl);         
        }
        insert rlList;
        Test.startTest();
         
        //requery to get the values updated by the trigger
        //loop through all the RLs to make sure the line types were set correctly
        for(Receipt_Line__c rl: [SELECT Id, Line_Type__c FROM Receipt_Line__c]) 
        {
            System.assertEquals('lineType1', rl.Line_Type__c);  
        }
        
        Test.stopTest();
        
    }
    
    static testMethod void testReceivingDocumentClose() 
    {
        
        TestFuel testData = new TestFuel();
        List<Period__c> periods = testData.periodList;
        
        testData.fobTerm.FOB_Point__c = 'Origin';
        DML.updateAsUser( testData.fobTerm );
        
        Receiving_Document__c rd = testData.receivingDocumentASN;
        
        Test.startTest();
        
        ApexPages.StandardController con = new ApexPages.StandardController(rd);
        ReceivingDocumentCloseExt rdce = new ReceivingDocumentCloseExt(con);
        
        rdce.close();
        
        Test.stopTest();
        
        list<Receipt_Line__c> rlList = [ select id, Status__c , ( select id, Quantity__c, Type__c FROM SKIDs__r ), Receiving_Document__r.Status__c, Receiving_Document__r.Finalized__c From Receipt_Line__c where Receiving_Document__c =:rd.id ];
        
        system.assert( rlList.size() == 1 );
        system.assert( rlList[0].Status__c == 'Closed', Apexpages.getMessages() );
        system.assert( rlList[0].Receiving_Document__r.Status__c == 'Closed' );
        system.assert( rlList[0].Receiving_Document__r.Finalized__c == true ); //PTP-400
        system.assert( rlList[0].Skids__r.size() == 0 );
    }
    
    static testMethod void testPurchaseOrderClose() {
        
        TestFuel testData = new TestFuel();
        
        Purchase_Order__c po = testData.purchaseOrder;

        Purchase_Order__c poVerify = [select id,Status__c from Purchase_Order__c where id = :po.id];
        //system.assert(poVerify.Finalized__c == false, 'PO is finalized: ' + poVerify.finalized__c);
        system.assert(poVerify.Status__c == 'Open', 'PO is not open: ' + poVerify.Status__c);

        ApexPages.StandardController con = new ApexPages.StandardController(po);
        PurchaseOrderCloseExt poce = new PurchaseOrderCloseExt(con);
        
        Test.startTest();
        poce.close();
        //Querying the po, poline, skids individually for the Roll up summary to get evaluated
        po = [select id, Status__c,Total_Number_Of_Lines__c, Open_Purchase_Order_Lines__c, Cancelled_Purchase_Order_Lines__c from Purchase_Order__c where id = :po.id];
        Purchase_Order_Line__c poLine = [select id, name, Status__c from Purchase_Order_Line__c where Purchase_Order__c =:po.id];
        List<Skid__c> skids = [select id, Quantity__c, Type__c FROM SKID__c where Purchase_Order_Line__c = :poLine.id];
        
        system.assert( skids.size() == 0 );
        system.assert( poLine.Status__c == 'Closed' );
        system.assert( po.Status__c == 'Closed', 'PO is not closed: ' + po.Status__c );
       // system.assert( po.Finalized__c == false,'PO is finalized: ' + po.finalized__c);
        Test.stopTest();

    }
    
    // PTP-404
    static testMethod void testPOClosewithCancelledclosedLines() {
        TestFuel testData = new TestFuel();
        //TestData.Accounting acctData = new TestData.Accounting(testData.company.Id);
        Purchase_Order__c po = testData.purchaseOrder;
        List<Purchase_Order_Line__c> pollist = new List<Purchase_Order_Line__c>();  
        
        Purchase_Order_Line__c pol1 = new Purchase_Order_Line__c();
        pol1.Purchase_Order__c = po.Id;
        pol1.Order_Quantity__c = 10;     
        pol1.Unit_Price__c = 12;
        pol1.Item__c = testdata.itemList[2].Id;
        pol1.Description__c = testdata.itemList[2].Description__c;
        pol1.Purchase_UOM__c = testdata.itemList[2].Purchasing_UOM__c;
        pol1.Company__c = testdata.company.id;
        pol1.Need_Date__c = system.today() + 7;
        pol1.Delivery_Facility__c = testdata.facility2.id;
        pol1.Delivery_Location__c = testdata.location2.ID;
        pol1.Supplier__c = testdata.supplier.Id;
        pol1.Line__c = 1;
        pollist.add(pol1);
        
        
        Purchase_Order_Line__c pol2 = new Purchase_Order_Line__c();
        pol2.Purchase_Order__c = po.id;
        pol2.Order_Quantity__c = 5;
        pol2.Unit_Price__c = 10;
        pol2.Item__c = testdata.itemList[1].id;
        pol2.Description__c = testdata.itemList[1].Description__c;
        pol2.Purchase_UOM__c = testdata.itemList[1].Purchasing_UOM__c;
        pol2.Company__c = testdata.company.id;
        pol2.Need_Date__c = system.today() + 7;
        pol2.Delivery_Facility__c = testdata.facility2.id;
        pol2.Delivery_Location__c = testdata.location2.ID;
        pol2.Supplier__c = testdata.supplier.Id;
        pol2.Line__c = 2;
        pollist.add(pol2);
        
        Purchase_Order_Line__c pol3 = new Purchase_Order_Line__c();
        pol3.Purchase_Order__c = po.id;
        pol3.Order_Quantity__c = 15;
        pol3.Unit_Price__c = 10;
        pol3.Item__c = testdata.itemList[1].id;
        pol3.Description__c = testdata.itemList[1].Description__c;
        pol3.Purchase_UOM__c = testdata.itemList[1].Purchasing_UOM__c;
        pol3.Company__c = testdata.company.id;
        pol3.Need_Date__c = system.today() + 7;
        pol3.Delivery_Facility__c = testdata.facility2.id;
        pol3.Delivery_Location__c = testdata.location2.ID;
        pol3.Supplier__c = testdata.supplier.Id;
        pol3.Line__c = 3;
        pollist.add(pol3);
        
        insert pollist;
        
        List<Purchase_Order_Line__c> pOrderLineList = [select id, status__c from purchase_order_line__c where purchase_order__c = :po.id];
        system.assert( pOrderLineList[0].status__c != 'Closed', 'Expected Open status' );
        system.assertEquals(po.Status__c, 'Open'); //check if the initial status is Open for a PO
        
        po.Approval_Status__c = 'Approved';
        update po;
        /*
        KNDY-13591 - commenting out this as the PurchaseOrderLinesAddManageExt is no longer used.
        So just set the status to closed and cancelled to satisfy the test case
        PurchaseOrderLinesAddManageExt poc = new PurchaseOrderLinesAddManageExt(new apexpages.standardController(po));
        Apexpages.currentPage().getParameters().put('selected_indexes','0');
        poc.poLineList[0].poLine.short_close__c = true;  
        
        system.assertEquals(poc.save(), Null, ' Expected Null');
        List<Purchase_Order_Line__c> poLine = [select id, status__c from purchase_order_line__c where purchase_order__c = :po.id];
        system.assert( poLine[0].status__c == 'Closed', 'Expected Closed status' ); 
        
        Apexpages.currentPage().getParameters().put('selected_indexes','1');
        Test.startTest();
        poc.cancelPOLines(); 
        */
        pollist[0].Status__c = 'Closed';
        polList[1].Status__c = 'Cancelled';
        update polList; 
        
        ApexPages.StandardController con = new ApexPages.StandardController(po);
        PurchaseOrderCloseExt poce = new PurchaseOrderCloseExt(con);
        
        Test.startTest();
        poce.close();
        Purchase_Order__c po1 = [select id, Status__c, Total_Number_Of_Lines__c, Open_Purchase_Order_Lines__c, Cancelled_Purchase_Order_Lines__c from Purchase_Order__c where id = :po.id];
        system.assertEquals(po1.Cancelled_Purchase_Order_Lines__c, 1); //One of the lines is cancelled, so cancelled lines = 1
        system.assertEquals(po1.Total_Number_Of_Lines__c, 4); //PO already has a line and 3 new lines are added in this method
        system.assertEquals(po1.Open_Purchase_Order_Lines__c, 0); //when PO header is closed all open lines should be closed, so 0
        system.assertEquals(po1.Status__c, 'Closed');
        Test.stopTest();
            
        
    }

    // Drop Ship Tests
    public static TestFuel fuel = new TestFuel();
	public static Sales_Order__c salesOrder = new Sales_Order__c();
	public static List<Sales_Order_Line__c> salesOrderLines = new List<Sales_Order_Line__c>();
	public static Requisition__c req = new Requisition__c();
	public static Requisition_Line__c reqLine = new Requisition_Line__c();
	public static Purchase_Order__c po = new Purchase_Order__c();
	public static Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
	public static Purchase_Order_Line__c poLine1 = new Purchase_Order_Line__c();

    public static void setupDropShipAdvanced(){
        // The advanced data setup will populate all necessary data to test latter flows in the Drop Ship process
        // It is created to minimize the inital SOQL queries by bypassing the steps to create the data using the processes in place
        // The flows that use this method to generate data are making an assumption that the early flows are clean
        
        DML.systemTime = system.now().addHours(-2); // Going back in time to allow skipping triggers 
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{ Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,Requisition__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType };
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        List<Period__c> periodList = fuel.periodList;
        salesOrder = fuel.salesOrder;
        salesOrder.Status__c = 'Open';
        update salesOrder;

        salesOrderLines = fuel.salesOrderLines;
        salesOrderLines[0].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP;
        salesOrderLines[1].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY;
        update salesOrderLines; //Fix for test failures
		salesOrderLines[0].Status__c = SalesOrderLineService.SO_LINE_STATUS_OPEN;
		salesOrderLines[1].Status__c = SalesOrderLineService.SO_LINE_STATUS_OPEN;
		update salesOrderLines;

		SKID__c soDemandSkid = new SKID__c();
		soDemandSkid.Type__c = SkidService2.SKID_TYPE_SO_DEMAND;
		soDemandSkid.Item__c = fuel.itemList[0].Id;
		soDemandSkid.Item__R = fuel.itemList[0];
		//soDemandSkid.Item_UOM__c = fuel.uomList[8].Id;
        soDemandSkid.Facility2__c = fuel.facility2.Id;
		soDemandSkid.Location__c = fuel.location2.Id;
		soDemandSkid.Sales_Order_Line__c = salesOrderLines[0].Id;
		soDemandSkid.Company__c = fuel.company.Id;
		// Item Source, Item Lead Time, Item Active, Qty Used

		SKID__c soDemandSkid2 = new SKID__c();
		soDemandSkid2.Type__c = SkidService2.SKID_TYPE_SO_DEMAND;
		soDemandSkid2.Item__c = fuel.itemList[0].Id;
		soDemandSkid2.Item__R = fuel.itemList[0];
		//soDemandSkid2.Item_UOM__c = fuel.uomList[8].Id;
        soDemandSkid2.Facility2__c = fuel.facility2.Id;
		soDemandSkid2.Location__c = fuel.location2.Id;
		soDemandSkid2.Sales_Order_Line__c = salesOrderLines[1].Id;
		soDemandSkid2.Company__c = fuel.company.Id;
		// Shipment Line?, Item Source, Item Lead Time, Item Active, Qty Used
		insert new List<SKID__c>{soDemandSkid, soDemandSkid2};

		req.Ship_To_Customer__c = salesOrder.Ship_to__c;
		req.Delivery_Facility__c = fuel.facility2.Id;
		req.Type__c = RequisitionService.RQ_TYPE_PURCHASE_REQUISITION;
		req.Sales_Order__c = salesOrder.Id;
		req.Status__c = 'Open'; // Should this really be open?
		req.Approval_Status__c = 'Approved';
		req.Delivery_Address__c = fuel.customerShipTo.Address__c;
        req.Currency__c = TestFuel.currencyUSD.id;
		insert req;

		reqLine.Requisition__c = req.Id;
		//reqLine.Location__c = fuel.location2.Id;
		reqLine.Quantity_Ordered__c = salesOrderLines[0].Quantity_Ordered__c;
		reqLine.Purchasing_UOM__c = fuel.uomList[8].Id;
		reqLine.Item__c = fuel.itemList[0].Id;
		//reqLine.Class__c = 'Class-1';
		reqLine.Sales_Order_Line__c = salesOrderLines[0].Id;
		reqLine.Approved__c = true;
		reqLine.Status__c = 'Closed';
		insert reqLine;

		po.Company__c = fuel.company.Id;
		po.Supplier__c = fuel.supplier.Id; 
		po.Company__c = fuel.company.Id;
		po.Payment_Term__c = fuel.terms.Id;
		po.Delivery_Facility__c = fuel.facility2.Id;
		po.Delivery_Location__c = fuel.location2.Id;
		po.Remit_To_Supplier__c = fuel.remitToSupplier.Id;
		po.Fob_term__c = fuel.fobTerm.Id;
		po.Approval_Status__c = 'Approved';
		po.Status__c = 'Open';
		po.Type__c =  PurchaseOrderService.PO_TYPE_DROP_SHIP;
		po.Memo__c = 'purchaseOrder';
		po.Currency__c = TestFuel.currencyUSD.id;
		// Purchase Agreement
		insert po;

		poLine.Company__c = fuel.company.Id;
		poLine.Purchase_Order__c = po.Id;
		poLine.Item__c = fuel.itemList[0].Id;
		poLine.Item__r = fuel.itemList[0];
		poLine.Order_Quantity__c = salesOrderLines[0].Quantity_Ordered__c;
		poLine.Unit_Price__c = 12;
        poLine.Description__c = fuel.itemList[0].Description__c;
        poLine.Purchase_UOM__c = fuel.itemList[0].Purchasing_UOM__c;
        poLine.Packaging_UOM__c = fuel.itemList[0].Purchasing_UOM__c;
        poLine.Need_Date__c = System.today() + 7;
        poLine.Delivery_Facility__c = fuel.facility2.Id;
        poLine.Delivery_Facility__r = fuel.facility2;
        poLine.Delivery_Location__c = fuel.location2.Id;
        poLine.Supplier__c = fuel.supplier.Id;
        poLine.Line__c = 1;
        poLine.Sales_Order_Line__c = salesOrderLines[0].Id;
        poLine.Putaway_Location__c = fuel.location2.Id;
        poLine.Type__c = 'Goods';
        poLine.Quantity_Received__c = 0;
        //poLine.Quantity_Still_Due__c = salesOrderLines[0].Quantity_Ordered__c;
        //poLine.Quantity_Uninvoiced__c = salesOrderLines[0].Quantity_Ordered__c;
        // Contracted, Contract Line
        insert poLine;


        SKID__c poSupplySkid = new SKID__c();

		poSupplySkid.Type__c = SkidService2.SKID_TYPE_TO_SUPPLY;
		poSupplySkid.Item__c = fuel.itemList[0].Id;
		poSupplySkid.Item__r = fuel.itemList[0];
		//poSupplySkid.Item_UOM__c = fuel.uomList[8].Id;
        poSupplySkid.Facility2__c = fuel.facility2.Id;
		poSupplySkid.Location__c = fuel.location2.Id;
		poSupplySkid.Purchase_Order_Line__c = poLine.Id;
		poSupplySkid.Company__c = fuel.company.Id;
		insert poSupplySkid;

		po.Approval_Status__c = 'Approved';
        update po;

        delete configList;
        System.debug(LoggingLevel.INFO, '*** Limits.getQueries-1(): ' + Limits.getQueries());
    }

    public static void setupDropShipBasic(){
        // The basic data is used to test the earliest flows in the Drop Ship process that are common for those tests 
        List<Product__c> products = new List<Product__c>{ fuel.newProduct(), fuel.newProduct2() };
        for (Product__c product:products) product.Item__c = fuel.itemList[2].Id;
        insert products;

        fuel.product = products[0];
        fuel.product2 = products[1];
       
        List<Period__c> periodList = fuel.periodList;
        salesOrder = fuel.salesOrder;
        salesOrderLines = fuel.salesOrderLines;
        salesOrderLines[0].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP;
        salesOrderLines[1].Fulfillment_Source__c = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY;
        // Change the uom on sales order line to match that of product
        salesOrderLines[0].Selling_UOM__c = fuel.uomList[8].ID;
        salesOrderLines[1].Selling_UOM__c = fuel.uomList[8].ID;
        update salesOrderLines;
        
        fuel.facility2.Default_Purchasing_Delivery_Location__c = fuel.location2.id;
        update fuel.facility2;

        System.debug(LoggingLevel.INFO, '*** Limits.getQueries-1(): ' + Limits.getQueries());
    }

    static testMethod void testDropShipSOToPO() {    
        // Test from start to the creation of a PO
        // Test 1: Create a Drop Ship SO Order w/ mixed Lines
        setupDropShipBasic();
        System.debug(LoggingLevel.INFO, '*** Limits.getQueries0(): ' + Limits.getQueries());
        ApexPages.StandardController con = new ApexPages.StandardController(salesOrder);
        SOPlanExt planExt = new SOPlanExt(con);
        planExt.plan();
        System.debug(LoggingLevel.INFO, '*** Limits.getQueries1(): ' + Limits.getQueries());
        
        salesOrderLines = [SELECT Id, Product__r.Item__c, Ship_From_Location__r.Facility__c,
                                  Quantity_Ordered__c, Purchase_From_Supplier__c, Ship_From_Location__c,
                                  Selling_UOM__c, Status__c, Sales_Order__r.Status__c, Company__c, Sales_Order__r.Has_Exceptions__c,
                                  (SELECT Id, Quantity_Ordered__c, Remaining_Quantity__c, Item__c, Need_Date__c, Facility__c,
                                          Sales_Order_Line__c, Supplier__c, Purchasing_UOM__c,
                                          Requisition__r.Id, Requisition__r.Name, Requisition__r.Source__c, Requisition__r.Sales_Order__c, 
                                          Requisition__r.Sales_Order__r.name, Requisition__r.Sales_Order__r.Override_Credit_Hold__c,
                                          Requisition__r.Ship_To_Customer__c, Requisition__r.Ship_To_Customer__r.Address__c, Requisition__r.Deliver_To_City__c, 
                                          Requisition__r.Sales_Order__r.Credit_Hold__c, Requisition__r.Deliver_To_Country__c, Requisition__r.Deliver_To_State__c, 
                                          Requisition__r.Deliver_Street__c, Requisition__r.Deliver_To_Zip_Code__c, Requisition__r.Currency__c FROM Requisition_Lines__r),
                                  (SELECT Id, Shipment__r.Id FROM Shipment_Lines__r)
                             FROM Sales_Order_Line__c];
        System.assertEquals(2, salesOrderLines.size());
        System.assertEquals(false, salesOrderLines[0].Sales_Order__r.Has_Exceptions__c);
        System.assertEquals(false, planExt.hasErrors, 'Unexpected errors: ' + ApexPages.getMessages());

        List<Requisition__c> reqList = new List<Requisition__c>();
        List<Requisition_Line__c> reqLineList = new List<Requisition_Line__c>();
        for (Sales_Order_Line__c SOL : salesOrderLines){
            if (SOL.Id == fuel.salesOrderLines[0].Id){
                System.assertEquals(1, SOL.Requisition_Lines__r.size());
                reqList.add(SOL.Requisition_Lines__r[0].Requisition__r);
                reqLineList.add(SOL.Requisition_Lines__r[0]);
            }

            if (SOL.Id == fuel.salesOrderLines[1].Id){
                System.assertEquals(1, SOL.Shipment_Lines__r.size());
            }
        }

        Test.startTest();
        // change the contract lines uom and item 
        // to match the sales order line uom and item
        List<Contract_Line__c> contractLines = fuel.contractLines;
        for (Contract_Line__c contractLine: contractLines){
            contractLine.Purchase_UOM__c = fuel.uomList[8].ID; //KNDY-10904
            contractLine.Item__c = fuel.itemList[2].Id;
        }
        insert contractLines;
        Contract__c contract = fuel.contract;
        contract.Approval_Status__c = 'Approved';
        update contract;
        // Test 2: Release the Requisition
        JsonResult result = new JsonResult();        
        ApexPages.StandardSetController setCon = new Apexpages.StandardSetController(reqList); 
        RequisitionToPurchaseOrdersExt req2po = new RequisitionToPurchaseOrdersExt(setCon);
        
        System.debug(LoggingLevel.INFO, '*** Limits.getQueries2(): ' + Limits.getQueries());

        System.assertEquals(1, reqLineList.size());
        RequisitionToPurchaseOrdersExt.releaseReqLines(fuel.company.Id, fuel.facility2.Id, reqLineList);
        Purchase_Order_Line__c POL = [SELECT Id, Name, Order_Quantity__c, Purchase_Order__r.Type__c, Company__c, Purchase_Order__r.Currency__c,Purchase_Order__r.Currency__r.ISO_code__c,
                                             Delivery_Facility__c, Delivery_Location__c,
                                             Delivery_Location__r.Facility__c, Delivery_Location__r.Facility__r.Company__c
                                        FROM Purchase_Order_Line__c LIMIT 1];

        System.assertEquals(POL.Order_Quantity__c, reqLineList[0].Quantity_Ordered__c); //Check if a PO has been created
        System.assertEquals(POL.Purchase_Order__r.Currency__r.ISO_code__c, 'USD');
        result = RequisitionToPurchaseOrdersExt.getPOLines(reqLineList);
        System.assertEquals(result.success, true);
        System.assertEquals(result.total,1); //Verify if 1 po line rec is created
        System.debug(LoggingLevel.INFO, '*** Limits.getQueries3(): ' + Limits.getQueries());
        Test.stopTest();

        System.debug(LoggingLevel.INFO, '*** Limits.getQueries4(): ' + Limits.getQueries());

        
    }
    static testMethod void testDeleteDropShipPOL(){
        setupDropShipAdvanced();
        
        poLine = [SELECT Id, Name, Order_Quantity__c, Unit_Price__c, Delivery_Facility__c, Item__c, Delivery_Location__c, Purchase_Order__r.Type__c, Purchase_Order__r.Name, Purchase_Order__r.Approval_Status__c, Purchase_Order__r.Status__c, 
                   Purchase_Order__r.Company__c,Purchase_Order__r.Company__r.Id, Purchase_Order__r.Company__r.Name, Accounting_Segment__c, Sales_Order_Line__c  FROM Purchase_Order_Line__c LIMIT 1];
        
        Purchase_Order_Line__c deletePOL = poLine;
        PO = deletePOL.Purchase_Order__r;  
        
        PageReference pageRef = Page.PurchaseOrderManage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController setCon = new Apexpages.StandardController(PO);
        PurchaseOrderManageExt con = new PurchaseOrderManageExt(setCon);
        List<String> headerDateFields = new List<String>();
        List<String> lineDateFields = new List<String>{'Need_Date__c','Promised_Date__c','Latest_Promise_Date__c'};
       
        // one new POL 
        PurchaseOrderManageExt.POLineWrapper DeletePOLineWrapper = new PurchaseOrderManageExt.POLineWrapper(deletePOL);
        List<PurchaseOrderManageExt.POLineWrapper> deletedList = new List<PurchaseOrderManageExt.POLineWrapper>{DeletePOLineWrapper};

        // empty lists
        List<PurchaseOrderManageExt.POLineWrapper> newList  = new List<PurchaseOrderManageExt.POLineWrapper>();
        List<PurchaseOrderManageExt.POLineWrapper> updatedList = new List<PurchaseOrderManageExt.POLineWrapper>(); 
        Test.startTest();
        try{
            PurchaseOrderManageExt.deleteLines(PO,deletedList);
        }catch(Exception e){
            system.assert(e.getMessage().contains('Drop Ship Purchase Order Line cannot be deleted'));
        }
     
        Test.stopTest();
    }    
    

}