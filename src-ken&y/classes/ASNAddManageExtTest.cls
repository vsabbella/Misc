@isTest
public class ASNAddManageExtTest {

    public class ASNData{

        TestFuel Fuel = new TestFuel();

        FOB_Terms__c fob = new FOB_Terms__c();{
            
            fob = fuel.fobTerm;
            fob.FOB_Point__c = 'Origin';
            update fob;
        }
        
        ASN__c asn = new ASN__c();{
            asn.Company__c = fuel.company.id;
            asn.Supplier__c = fuel.supplier.id;
            asn.Facility__c = fuel.facility2.id;
            asn.FOB__c = fob.id;
            asn.Status__c = 'Draft';
            asn.Transaction_Date__c = system.today();
            asn.Currency__c = TestFuel.currencyUSD.id;
            asn.Transaction_Type__c = 'Purchase Order ASN';
            insert asn;
        }

        ASN_Line__c asnLine = new ASN_Line__c();{
            asnLine.Purchase_Order__c = fuel.purchaseOrder.id;
            asnLine.Purchase_Order_Line__c = fuel.purchaseOrderLines[0].id;
            asnLine.Item__c = fuel.itemList[2].id;
            asnLine.Item__r = fuel.itemList[2];
            asnLine.Quantity_Shipped__c = 100;
            asnLine.Quantity_Received__c = 0;
            asnLine.Unit_Price__c = 10;
            asnLine.Status__c = 'New';
            asnLine.ASN__c = asn.id;
            asnLine.ASN__r = asn;
            asnLine.Company__c = fuel.company.id;
            asnLine.Supplier__c = fuel.supplier.id;
            asnLine.Is_Changed__c = true;
            insert asnLine;
        }
        
         ASN__c asn1 = new ASN__c();

        //ASN Lines Grid config
        GridRelatedListController.GridRelatedListConfig asnLinesConfig = new GridRelatedListController.GridRelatedListConfig(); {
            asnLinesConfig.uniqueId = 'ASNLinesGrid';
            asnLinesConfig.title = 'ASN Lines';
            asnLinesConfig.parentRecord = asn;
            asnLinesConfig.objectName = 'ASN_Line__c';  
            asnLinesConfig.parentField = 'ASN__c';
            asnLinesConfig.fieldset = 'ASN_Line';
            asnLinesConfig.buttons = 'delete, cancel, columnmenu, search';
        }

        // Purchase Order Lines Grid config
        GridRelatedListController.GridRelatedListConfig purchaseOrderLinesConfig = new GridRelatedListController.GridRelatedListConfig(); {
            purchaseOrderLinesConfig.uniqueId = 'POLinesGrid';
            purchaseOrderLinesConfig.title = 'Purchase Order Lines';
            purchaseOrderLinesConfig.objectName = 'Purchase_Order_Line__c';  
            purchaseOrderLinesConfig.fieldset = 'ASN_New';
            purchaseOrderLinesConfig.buttons = 'columnmenu, search';
        }


    }
    
    
    
      //Create ASN from PO
    static testMethod void createASNfromPO(){
        if(KSE.checkTestDispatch()){return;}        

        ASNData data = new ASNData();
       
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn1); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        
        Test.setCurrentPage(Page.ASNAddManage);
        ApexPages.currentPage().getParameters().put('poID',data.fuel.purchaseOrder.id);
        String poID = ApexPages.currentPage().getParameters().get('poID');
        
        JSONResult result = new JSONResult();
		
        result = ASNAddManageExt.getasnLinesByPurchaseOrderId(ID.valueOf(poID) , null, 1);
        system.assertEquals(result.success, true);
        system.assertNotEquals(result.total, 0); 
    }

    //Test to just make sure all the fieldsets have some fields on it
    static testMethod void dummyTestForCoverage(){
        if(KSE.checkTestDispatch()){return;}        

        ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        String fields = '';
        fields = createASN.getasnJson();
        system.assertNotEquals(fields, '');
        fields = createASN.getasnHeaderFieldList();
        system.assertNotEquals(fields, '');
        fields = createASN.getasnAddlHeaderFieldList();
        system.assertNotEquals(fields, '');
        fields = createASN.getasnLinesConfigJson();
        system.assertNotEquals(fields, '');
        fields = createASN.getasnLinesFieldList();
        system.assertNotEquals(fields, '');
        fields = createASN.getdetailFieldList();
        system.assertNotEquals(fields, '');
        fields = createASN.getskidFieldList();
        system.assertNotEquals(fields, '');
        fields = createASN.getPurchaseOrderLinesConfigJson();
        system.assertNotEquals(fields, '');
        fields = createASN.getPurchaseOrderLinesFieldList();
        system.assertNotEquals(fields, '');
        fields = createASN.getserialFieldList();
        system.assertNotEquals(fields, '');
        
        String pageRef = createASN.getReturnUrl();
        system.assert(pageRef !=null);

    }
    
    //get ASN Lines from PO
    static testMethod void getasnLinefromPO(){
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();
        JSONResult result = new JSONResult();
        
        result = ASNAddManageExt.getasnLinesByPurchaseOrderId(data.fuel.purchaseOrder.id, data.fuel.facility2.id, 1);
        system.assertEquals(result.success, true);
        system.assertNotEquals(result.total, 0); //Make sure the records are pulled from the PO
    }
    
    //get ASN
    static testMethod void getasnDetails(){
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();
        JSONResult result = new JSONResult();

        result = ASNAddManageExt.getasnDetails(data.asn.id);
        system.assertEquals(result.success, true);
        system.assertNotEquals(result.total, 0); //Make sure the function passed and has a record

    }

    //get ASN Line details
    static testMethod void getasnLineDetails(){
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();

        result = ASNAddManageExt.getasnLines(data.asnLinesConfig);
        system.assertEquals(result.success, true);
        system.assertNotEquals(result.total, 0); //Make sure the function passed and has a record

    }

    //Cancel ASN Line
    static testMethod void cancelASNLine(){
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        
        result = ASNAddManageExt.HeaderActions(data.asn, 'confirm', new list<String>());
        system.assertEquals(result.success, true);

        List <ASNAddManageExt.ASNLineWrapper> asnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper a = new ASNAddManageExt.ASNLineWrapper();
        a.asnl = data.asnLine;
        a.asnl.Status__c = 'Open';
        
        asnlWrapper.add(a);
        
        Test.startTest();

        result = ASNAddManageExt.cancelLines(asnlWrapper);
        system.assertEquals(result.success, true);
        
        Test.stopTest();

        ASN_Line__c asnLinetoCheck = [select id, name, Status__c from ASN_Line__c where id = :data.asnLine.id];
        system.assertEquals(asnLinetoCheck.Status__c, 'Cancelled');

    }

    //Close ASN Line
    static testMethod void closeASNLine(){
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        
        result = ASNAddManageExt.HeaderActions(data.asn, 'confirm', new list<String>());
        system.assertEquals(result.success, true);

        List <ASNAddManageExt.ASNLineWrapper> asnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper a = new ASNAddManageExt.ASNLineWrapper();
        a.asnl = data.asnLine;
        a.asnl.Status__c = 'Open';
        a.asnl.Quantity_Received__c = 1;
        
        asnlWrapper.add(a);
        
        Test.startTest();

        result = ASNAddManageExt.closeLines(asnlWrapper);
        system.assertEquals(result.success, true, result);
        
        Test.stopTest();

        ASN_Line__c asnLinetoCheck = [select id, name, Status__c from ASN_Line__c where id = :data.asnLine.id];
        system.assertEquals(asnLinetoCheck.Status__c, 'Closed');

    }
    
    //Confirm ASN 
    static testMethod void confirmASN(){
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();

        result = ASNAddManageExt.HeaderActions(data.asn, 'confirm', null);
        system.assertEquals(result.success, true);

    }

    //Save ASN
    static testMethod void saveASN(){
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        list<SkidService3.SerialWrapper> serialwrapperlist = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> serialwrapperlist1 = new list<SkidService3.SerialWrapper>();
        
        SkidService3.SerialWrapper aserialWrapper;
        SkidService3.SerialWrapper bserialWrapper;

        data.asnLine.Item__r.Item_Attribute__r = data.fuel.itemAttrObj;

        List <ASNAddManageExt.ASNLineWrapper> updateasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper a;
        data.asnLine.Quantity_Shipped__c = 10;
        //a.asnl = data.asnLine;

        SKID__c skid1 = new SKID__c();
        skid1.ASN_Line__c = data.asnLine.id;
        skid1.Type__c = 'Draft In-Transit';
        skid1.Item__c = data.asnLine.Item__c;
        skid1.Item__r = data.asnLine.Item__r;
        skid1.Expiration_Date__c = system.today();
        skid1.Lot_Number__c = '1';
        skid1.Quantity__c = 10;
        skid1.Quantity_Stocking_UOM__c = 10;
        skid1.Company__c = data.fuel.company.Id;
        skid1.Stocking_UOM__c = data.asnLine.Item__r.Stocking_UOM__c;
        skid1.Packaging_UOM__c = data.asnLine.Item__r.Stocking_UOM__c;
        //a.skidList = new List<SKID__c>{skid1};

        aserialwrapper = new SkidService3.SerialWrapper(skid1, new list<Serial__c>());
        serialwrapperlist.add(aserialwrapper);
        
	    a = new ASNAddManageExt.ASNLineWrapper(data.asnLine,serialwrapperlist);
	    a.trackedAttributes = SKIDService3.trackedAttributes(null, null, data.asnLine.Item__r);
		
	    updateasnlWrapper.add(a);
        List <ASNAddManageExt.ASNLineWrapper> newasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper b;
        //b.asnl = data.asnLine.clone(false, true);

        SKID__c skid2 = new SKID__c();
        skid2.ASN_Line__c = data.asnLine.id;
        skid2.Type__c = 'Draft In-Transit';
        skid2.Item__c = data.asnLine.Item__c;
        skid2.Item__r = data.asnLine.Item__r;
        skid2.Expiration_Date__c = system.today();
        skid2.Lot_Number__c = '2';
        skid2.Quantity__c = 10;
        skid2.Quantity_Stocking_UOM__c = 10;
        skid2.Company__c = data.fuel.company.Id;
        skid2.Stocking_UOM__c = data.asnLine.Item__r.Stocking_UOM__c;
        skid2.Packaging_UOM__c = data.asnLine.Item__r.Stocking_UOM__c;
        //b.skidList = new List<SKID__c>{skid2};

        bserialwrapper = new SkidService3.SerialWrapper(skid2, new list<Serial__c>());
		
        serialwrapperlist1.add(bserialwrapper);
		b = new ASNAddManageExt.ASNLineWrapper(data.asnLine.clone(false, true),serialwrapperlist1);
        b.trackedAttributes = SKIDService3.trackedAttributes(null, null, data.asnLine.Item__r);
		
        newasnlWrapper.add(b);

        result = ASNAddManageExt.saveAction(data.asn, null, updateasnlWrapper, newasnlWrapper, new List<ASNAddManageExt.ASNLineWrapper>(), new List<SkidService3.SerialWrapper>(), null, null);
        system.assertEquals(result.success, true);

    }
    
    //changing attributes and saving should not create new asn line
    
    static testMethod void saveASNchangeAttribute(){
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        list<SkidService3.SerialWrapper> serialwrapperlist = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> serialwrapperlist1 = new list<SkidService3.SerialWrapper>();
        
        SkidService3.SerialWrapper aserialWrapper;
        SkidService3.SerialWrapper bserialWrapper;

        data.asnLine.Item__r.Item_Attribute__r = data.fuel.itemAttrObj;

        List <ASNAddManageExt.ASNLineWrapper> updateasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper a;
        ASNAddManageExt.ASNLineWrapper b;
        data.asnLine.Quantity_Shipped__c = 10;

        SKID__c skid1 = new SKID__c();
        skid1.ASN_Line__c = data.asnLine.id;
        skid1.Type__c = 'Draft In-Transit';
        skid1.Item__c = data.asnLine.Item__c;
        skid1.Item__r = data.asnLine.Item__r;
        skid1.Expiration_Date__c = system.today();
        skid1.Lot_Number__c = '1';
        skid1.Quantity__c = 10;
        skid1.Quantity_Stocking_UOM__c = 10;
        skid1.Company__c = data.fuel.company.Id;
        skid1.Stocking_UOM__c = data.asnLine.Item__r.Stocking_UOM__c;
        skid1.Packaging_UOM__c = data.asnLine.Item__r.Stocking_UOM__c;
        

        aserialwrapper = new SkidService3.SerialWrapper(skid1, new list<Serial__c>());
        serialwrapperlist.add(aserialwrapper);
        
	    a = new ASNAddManageExt.ASNLineWrapper(data.asnLine,serialwrapperlist);
	    a.trackedAttributes = SKIDService3.trackedAttributes(null, null, data.asnLine.Item__r);
		
	    updateasnlWrapper.add(a);

        result = ASNAddManageExt.saveAction(data.asn, null, updateasnlWrapper,  new List<ASNAddManageExt.ASNLineWrapper>(), new List<ASNAddManageExt.ASNLineWrapper>(), new List<SkidService3.SerialWrapper>(), null, null);
        system.assertEquals(result.success, true);
        
       
	    skid1.Lot_Number__c = '2';
	    aserialwrapper.skid = skid1;
	    serialwrapperlist.add(aserialwrapper);
	    
        
	    b = new ASNAddManageExt.ASNLineWrapper(data.asnLine,serialwrapperlist);
	    b.trackedAttributes = SKIDService3.trackedAttributes(null, null, data.asnLine.Item__r);
		
	    updateasnlWrapper.add(b);
	    
	    result = ASNAddManageExt.saveAction(data.asn, null, updateasnlWrapper,  new List<ASNAddManageExt.ASNLineWrapper>(), new List<ASNAddManageExt.ASNLineWrapper>(), new List<SkidService3.SerialWrapper>(), null, null);
       
        list<skid__c> skidList = [SELECT id,ASN_Line__c,Type__c,Item__c,Expiration_Date__c,Lot_Number__c,Quantity__c,Company__c from skid__c where
	                                ASN_Line__c = :data.asnLine.id];
	    system.assertEquals(skidList.size(), 1);
	    
    }
    
    
    
    private static testMethod void testDropShip() {
        if(KSE.checkTestDispatch()){return;}        
        
        ReceivingDocumentServiceTest.setupDropShipAdvanced();
        List<Stock_Movement_Rule_Settings__c> smrsList = ReceivingDocumentServiceTest.fuel.smrsList;
        List<Stock_Movement_Rule__c> smrs = ReceivingDocumentServiceTest.fuel.stockMovementRuleList;
        update new Location__c(Id=ReceivingDocumentServiceTest.fuel.location3.Id,Bin_Tracked__c=true);
        update new Item__c(Id=ReceivingDocumentServiceTest.fuel.itemList[0].Id,Item_Attribute__c=null);
        update new Facility__c(Id=ReceivingDocumentServiceTest.fuel.facility2.Id,Default_Purchasing_Delivery_Location__c=ReceivingDocumentServiceTest.fuel.location2.Id);
        Purchase_Order_Line__c poline = ReceivingDocumentServiceTest.poLine;
        poline.Packaging_UOM__c = ReceivingDocumentServiceTest.fuel.uomObj.Id;
        update poline;
        ASN__c asn = new ASN__c(
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Supplier__c = ReceivingDocumentServiceTest.po.Supplier__c,
            Facility__c = ReceivingDocumentServiceTest.po.Delivery_Facility__c,
            FOB__c = ReceivingDocumentServiceTest.po.FOB_Term__c,
            Status__c = 'Draft',
            Transaction_Date__c = System.today(),
            Currency__c = TestFuel.currencyUSD.id,
            Transaction_Type__c = 'Purchase Order ASN'
        );
        insert asn;
        ASN_Line__c asnLine = new ASN_Line__c(
            Purchase_Order__c = ReceivingDocumentServiceTest.po.Id,
            Purchase_Order_Line__c = poLine.Id,
            Item__c = ReceivingDocumentServiceTest.poLine.Item__c,
            Item__r = ReceivingDocumentServiceTest.fuel.itemList[0],
            Quantity_Shipped__c = 100,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = asn.Company__c,
            Supplier__c = asn.Supplier__c,
            Is_Changed__c = true,
            Facility__c = ReceivingDocumentServiceTest.fuel.facility2.Id,
            Location__c = ReceivingDocumentServiceTest.fuel.location2.Id
        );
        insert asnLine;
        SKID__c skid = new SKID__c(
            ASN_Line__c = asnLine.Id,
            Facility2__c = ReceivingDocumentServiceTest.fuel.facility2.Id,
            Location__c = ReceivingDocumentServiceTest.fuel.location2.Id,
            Type__c = 'Draft In-Transit',
            Item__c = asnLine.Item__c,
            Item__r = asnLine.Item__r,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Company__c = asn.Company__c,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );
        skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
        skid.Packaging_UOM__r.Package_Class__r = null;
        insert skid;
        Test.startTest();
        JsonResult result = ASNService.confirmASN(asn);
        System.assert(result.success,result);
        Test.stopTest();
        
        List<Receipt_Line__c> receiptLines = [SELECT Id,Purchase_Order__r.Status__c,Quantity_Received__c,Receiving_Document__r.Transaction_Type__c,Receiving_Document__r.Status__c,
                                                     Purchase_Order_Line__r.Quantity_Received__c,Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c,Purchase_Order_Line__c,
                                                     (SELECT Id,Quantity__c,Purchase_Order_Line__c,Sales_Order_Line__c,Shipment_Line__c,Inventory_Change__c FROM Inventory_Transactions__r) 
                                              FROM Receipt_Line__c 
                                              WHERE Receiving_Document__r.Type__c = 'Purchase Order Receipt'];
        System.assert(receiptLines.size() == 1);
        System.assert(receiptLines[0].Purchase_Order__r.Status__c == 'Closed');
        System.assert(receiptLines[0].Quantity_Received__c == 100);
        System.assert(receiptLines[0].Receiving_Document__r.Transaction_Type__c == 'Logical Purchase Order Receipt');
        System.assert(receiptLines[0].Receiving_Document__r.Status__c == 'Closed');
        System.assert(receiptLines[0].Purchase_Order_Line__r.Quantity_Received__c == 100);
        System.assert(receiptLines[0].Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c == 100);
        System.assert(receiptLines[0].Inventory_Transactions__r.size() == 2,receiptLines[0].Inventory_Transactions__r);
        
        for (Inventory_Transaction__c it:receiptLines[0].Inventory_Transactions__r) {
            System.assert(it.Quantity__c == 100);
            System.assert(it.Purchase_Order_Line__c == receiptLines[0].Purchase_Order_Line__c);
            System.assert(it.Sales_Order_Line__c == ReceivingDocumentServiceTest.fuel.salesOrderLines[0].Id);
            System.assert(it.Shipment_Line__c != null);
            System.assert(it.Inventory_Change__c != null);
        }
        
        List<Fulfillment__c> fulfillments = [SELECT Id,Company__c,Quantity__c,Unit_Price__c,Extended_Price__c,Type__c,Status__c,
                                                       Sales_Order_Line__c,Shipment_Line__c,Customer__c,Sales_Order_Line__r.Status__c
                                                  FROM Fulfillment__c];
        System.assert(fulfillments.size() == 1);
        System.assert(fulfillments[0].Company__c == ReceivingDocumentServiceTest.fuel.salesOrderLines[0].Company__c);
        System.assert(fulfillments[0].Quantity__c == 100);
        System.assert(fulfillments[0].Unit_Price__c == 11.12);
        System.assert(fulfillments[0].Extended_Price__c == 1089.760000, fulfillments[0].Extended_Price__c);
        System.assert(fulfillments[0].Type__c == 'Sales Order Shipment');
        System.assert(fulfillments[0].Status__c == 'Complete');
        System.assert(fulfillments[0].Sales_Order_Line__c == ReceivingDocumentServiceTest.fuel.salesOrderLines[0].Id);
        System.assert(fulfillments[0].Sales_Order_Line__r.Status__c == 'Closed');
    }
    
    private static testMethod void testDropShip_CopyShipmentAttributes() {
        if(KSE.checkTestDispatch()){return;}
        
        ReceivingDocumentServiceTest.setupDropShipAdvanced();
        List<Stock_Movement_Rule_Settings__c> smrsList = ReceivingDocumentServiceTest.fuel.smrsList;
        List<Stock_Movement_Rule__c> smrs = ReceivingDocumentServiceTest.fuel.stockMovementRuleList;
        update new Location__c(Id=ReceivingDocumentServiceTest.fuel.location3.Id,Bin_Tracked__c=true);
        update new Item__c(Id=ReceivingDocumentServiceTest.fuel.itemList[0].Id,Item_Attribute__c=null);
        update new Facility__c(Id=ReceivingDocumentServiceTest.fuel.facility2.Id,Default_Purchasing_Delivery_Location__c=ReceivingDocumentServiceTest.fuel.location2.Id);
        ASN__c asn = new ASN__c(
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Supplier__c = ReceivingDocumentServiceTest.po.Supplier__c,
            Facility__c = ReceivingDocumentServiceTest.po.Delivery_Facility__c,
            FOB__c = ReceivingDocumentServiceTest.po.FOB_Term__c,
            Status__c = 'Draft',
            Transaction_Date__c = System.today(),
            Currency__c = TestFuel.currencyUSD.id,
            Transaction_Type__c = 'Purchase Order ASN',
            Date_Shipped__c = system.now().addDays(10),
            Carrier__c = 'Fedex',
            Tracking_Number__c = 'fedTrck1234'
        );
        insert asn;
        ASN_Line__c asnLine = new ASN_Line__c(
            Purchase_Order__c = ReceivingDocumentServiceTest.po.Id,
            Purchase_Order_Line__c = ReceivingDocumentServiceTest.poLine.Id,
            Item__c = ReceivingDocumentServiceTest.poLine.Item__c,
            Item__r = ReceivingDocumentServiceTest.fuel.itemList[0],
            Quantity_Shipped__c = 10,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = asn.Company__c,
            Supplier__c = asn.Supplier__c,
            Is_Changed__c = true,
            Facility__c = ReceivingDocumentServiceTest.fuel.facility2.Id,
            Location__c = ReceivingDocumentServiceTest.fuel.location2.Id
        );
        insert asnLine;
        SKID__c skid =  new SKID__c(
            ASN_Line__c = asnLine.Id,
            Facility2__c = ReceivingDocumentServiceTest.fuel.facility2.Id,
            Location__c = ReceivingDocumentServiceTest.fuel.location2.Id,
            Type__c = 'Draft In-Transit',
            Item__c = asnLine.Item__c,
            Item__r = asnLine.Item__r,
            Quantity__c = 10,
            Quantity_Stocking_UOM__c = 10,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Company__c = asn.Company__c
        );
        skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
        skid.Packaging_UOM__r.Package_Class__r = null;
        insert skid; 
        Test.startTest();
        JsonResult result = ASNService.confirmASN(asn);
        System.assert(result.success,result);
        Test.stopTest();
        
        List<Receipt_Line__c> receiptLines = [SELECT Id,Purchase_Order_Line__r.Quantity_Received__c,
        Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c,ASN_Line__r.ASN__r.Date_Shipped__c,ASN_Line__r.ASN__r.Carrier__c,
        ASN_Line__r.ASN__r.Tracking_Number__c,(SELECT Id,Type__c, Shipment_Line__r.Shipment__r.Date_Shipped__c, 
        Shipment_Line__r.Shipment__r.Tracking_Id__c, Shipment_Line__r.Shipment__r.Carrier__c  FROM Inventory_Transactions__r) 
        FROM Receipt_Line__c WHERE Receiving_Document__r.Type__c = 'Purchase Order Receipt'];
        
        System.assert(receiptLines.size() == 1);
        System.assert(receiptLines[0].Purchase_Order_Line__r.Quantity_Received__c == 10,receiptLines[0].Purchase_Order_Line__r.Quantity_Received__c);
        System.assert(receiptLines[0].Inventory_Transactions__r.size() == 2,receiptLines[0].Inventory_Transactions__r);
        System.assert(receiptLines[0].Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c == 10,receiptLines[0].Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c);
        system.assertEquals(receiptLines[0].Inventory_Transactions__r[0].Shipment_Line__r.Shipment__r.Date_Shipped__c, receiptLines[0].ASN_Line__r.ASN__r.Date_Shipped__c);
        system.assertEquals(receiptLines[0].Inventory_Transactions__r[0].Shipment_Line__r.Shipment__r.Tracking_Id__c, receiptLines[0].ASN_Line__r.ASN__r.Tracking_Number__c);
        system.assertEquals(receiptLines[0].Inventory_Transactions__r[0].Shipment_Line__r.Shipment__r.Carrier__c, receiptLines[0].ASN_Line__r.ASN__r.Carrier__c);
    }

    
    
    
    private static testMethod void testDropShipWithManualLines() {
        if(KSE.checkTestDispatch()){return;}
        
        ReceivingDocumentServiceTest.setupDropShipAdvanced();
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Inventory_Change__c.sObjectType,SKID__c.sObjectType,Location__c.sObjectType,Lot__c.sObjectType,Serial__c.sObjectType,
        	                                  FOB_Terms__c.sObjectType,Serial_Transaction__c.sObjectType,Inventory_Transaction__c.sObjectType,Receipt_Line__c.sObjectType,
        	                                  Receiving_Document__c.sObjectType,Item__c.sObjectType,Purchase_Order_Line__c.sObjectType,
        	                                  Company__c.sObjectType,Component__c.sObjectType,Customer__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        List<Stock_Movement_Rule_Settings__c> smrsList = ReceivingDocumentServiceTest.fuel.smrsList;
        List<Stock_Movement_Rule__c> smrs = ReceivingDocumentServiceTest.fuel.stockMovementRuleList;
        update new Location__c(Id=ReceivingDocumentServiceTest.fuel.location3.Id,Bin_Tracked__c=true);
        update new Item__c(Id=ReceivingDocumentServiceTest.fuel.itemList[0].Id,Item_Attribute__c=null);
        update new Facility__c(Id=ReceivingDocumentServiceTest.fuel.facility2.Id,Default_Purchasing_Delivery_Location__c=ReceivingDocumentServiceTest.fuel.location2.Id);
        
        FOB_Terms__c fobTerm1 = new FOB_Terms__c(
                                     Name = 'test term origin',
                                     FOB_Point__c = 'Origin'
                                );
        insert fobTerm1;
        
        Purchase_Order_Line__c manualPOLine = new Purchase_Order_Line__c();
        manualPOLine.Company__c = ReceivingDocumentServiceTest.fuel.company.Id;
        manualPOLine.Purchase_Order__c = ReceivingDocumentServiceTest.po.Id;
        manualPOLine.Item__c = ReceivingDocumentServiceTest.fuel.itemList[2].Id;
        manualPOLine.Item__r = ReceivingDocumentServiceTest.fuel.itemList[2];
        manualPOLine.Order_Quantity__c = 10;
        manualPOLine.Unit_Price__c = 12;
        manualPOLine.Description__c = ReceivingDocumentServiceTest.fuel.itemList[2].Description__c;
        manualPOLine.Purchase_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[2].Purchasing_UOM__c;
        manualPOLine.Need_Date__c = System.today() + 7;
        manualPOLine.Delivery_Facility__c = ReceivingDocumentServiceTest.fuel.facility2.Id;
        manualPOLine.Delivery_Location__c = ReceivingDocumentServiceTest.fuel.location2.Id;
        manualPOLine.Supplier__c = ReceivingDocumentServiceTest.fuel.supplier.Id;
        manualPOLine.Line__c = 2;
        manualPOLine.Putaway_Location__c = ReceivingDocumentServiceTest.fuel.location2.Id;
        manualPOLine.Type__c = 'Goods';
        manualPOLine.Quantity_Received__c = 0;
        //manualPOLine.Quantity_Uninvoiced__c = 10;
        insert manualPOLine;
        
        ReceivingDocumentServiceTest.po.FOB_Term__c = fobTerm1.Id;
        update ReceivingDocumentServiceTest.po;
        
        ReceivingDocumentServiceTest.po.Approval_Status__c = 'Approved';
        update ReceivingDocumentServiceTest.po;
        
        system.assertEquals('Approved', ReceivingDocumentServiceTest.po.Approval_Status__c);

        ASN__c asn = new ASN__c(
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Supplier__c = ReceivingDocumentServiceTest.po.Supplier__c,
            Facility__c = ReceivingDocumentServiceTest.po.Delivery_Facility__c,
            FOB__c = ReceivingDocumentServiceTest.po.FOB_Term__c,
            Status__c = 'Draft',
            Transaction_Date__c = System.today(),
            Currency__c = TestFuel.currencyUSD.id,
            Transaction_Type__c = 'Purchase Order ASN'
        );
        insert asn;
        
        ASN_Line__c asnLine = new ASN_Line__c(
            Purchase_Order__c = ReceivingDocumentServiceTest.po.Id,
            Purchase_Order_Line__c = ReceivingDocumentServiceTest.poLine.Id,
            Purchase_Order_Line__r = ReceivingDocumentServiceTest.poLine,
            Item__c = ReceivingDocumentServiceTest.poLine.Item__c,
            Item__r = ReceivingDocumentServiceTest.fuel.itemList[0],
            Quantity_Shipped__c = 10,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = asn.Company__c,
            Supplier__c = asn.Supplier__c,
            Is_Changed__c = true,
            Facility__c = ReceivingDocumentServiceTest.fuel.facility2.Id,
            Location__c = ReceivingDocumentServiceTest.fuel.location2.Id
        );
        ASN_Line__c asnLine2 = new ASN_Line__c(
            Purchase_Order__c = ReceivingDocumentServiceTest.po.Id,
            Purchase_Order_Line__c = manualPOLine.Id,
            Item__c = manualPOLine.Item__c,
            Item__r = ReceivingDocumentServiceTest.fuel.itemList[2],
            Quantity_Shipped__c = 10,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = asn.Company__c,
            Supplier__c = asn.Supplier__c,
            Is_Changed__c = true,
            Facility__c = ReceivingDocumentServiceTest.fuel.facility2.Id,
            Location__c = ReceivingDocumentServiceTest.fuel.location2.Id
        );
        insert new list<ASN_Line__c>{asnLine,asnLine2};
        
        SKID__c skid1 = new SKID__c(
            ASN_Line__c = asnLine.Id,
            Facility2__c = ReceivingDocumentServiceTest.fuel.facility2.Id,
            Location__c = ReceivingDocumentServiceTest.fuel.location2.Id,
            Type__c = 'Draft In-Transit',
            Item__c = asnLine.Item__c,
            Item__r = asnLine.Item__r,
            Quantity__c = 10,
            Quantity_Stocking_UOM__c = 10,
            Company__c = asn.Company__c,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );
        SKID__c skid2 = new SKID__c(
            ASN_Line__c = asnLine2.Id,
            Facility2__c = ReceivingDocumentServiceTest.fuel.facility2.Id,
            Location__c = ReceivingDocumentServiceTest.fuel.location2.Id,
            Type__c = 'Draft In-Transit',
            Item__c = asnLine2.Item__c,
            Item__r = asnLine2.Item__r,
            Quantity__c = 10,
            Quantity_Stocking_UOM__c = 10,
            Company__c = asn.Company__c,
            Stocking_UOM__c = asnLine2.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine2.Item__r.Stocking_UOM__c
        );
        
        insert new list<SKID__c>{skid1, skid2};
        
        system.assert(  Limits.getQueries() <= 50, ' expected TestDataForFinance to use 99 queries or less!  '+Limits.getQueries());
        Test.startTest();
        JsonResult result = ASNService.confirmASN(asn);
        System.assert(result.success,result);
        delete configList;
        Boolean errorFOBflag = false;
        try{
        	fobTerm1.FOB_Point__c = 'Destination';
       	 	update fobTerm1;
        }catch(Exception ex){
        	if(ex.getMessage().contains('You cannot change the FOB Point associated with the asn or purchase order with quantity received greater than 0')){
        		errorFOBflag = true;
        	}
        	
        }
        system.assert(errorFOBflag == true);
        FOB_Terms__c fobTerm2 = new FOB_Terms__c(
                                     Name = 'test term destinationX',
                                     FOB_Point__c = 'Destination'
                                );
        insert fobTerm2;
       
        Boolean errorPOflag = false;
        try{
        	 ReceivingDocumentServiceTest.po.FOB_Term__c = fobTerm2.Id;
        	 update ReceivingDocumentServiceTest.po;
        }catch(Exception ex){
        	if(ex.getMessage().contains('You cannot change the FOB Terms if purchase order is associated with the asn or quantity received greater than 0')){
        		errorPOflag = true;
        	}
        	
        }
        system.assert(errorPOflag == true);
        
        Test.stopTest();
        
        List<Receipt_Line__c> receiptLines = [SELECT Id,Item__c,Purchase_Order_Line__r.Quantity_Received__c,Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c,
                Receiving_Document__r.Type__c, (SELECT Id,Type__c FROM Inventory_Transactions__r) FROM Receipt_Line__c];
        
        System.assert(receiptLines.size() == 1, receiptLines);
        //RD will only be created or drop ship line.
        for( receipt_line__c rl : receiptLines ){
             //drop ship line
            System.assert(rl.Purchase_Order_Line__r.Quantity_Received__c == 10,rl.Purchase_Order_Line__r.Quantity_Received__c);
            System.assert(rl.Inventory_Transactions__r.size() == 2,rl.Inventory_Transactions__r);
            System.assertEquals( 'Purchase Order Receipt', rl.Receiving_Document__r.Type__c );
            System.assert(rl.Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c == 10,rl.Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c);
            
        }
    }
    
    static testMethod void saveASNwithSerials(){
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();
        data.fuel.company.Serial_Control__c = 'At receipt and all processes';
        update data.fuel.company;
        data.fuel.purchaseOrder.Type__c = 'Standard';
        data.fuel.purchaseOrderLines[0].Company__c = data.fuel.company.Id;
        data.fuel.itemAttrObj.Serial_Number__c = true;
        update data.fuel.itemAttrObj;
       	//data.fuel.purchaseOrderLines[0].company__r.Serial_Control__c = 'At receipt and all processes';
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        list<SkidService3.SerialWrapper> serialwrapperlist = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> serialwrapperlist1 = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> serialwrapperlist2 = new list<SkidService3.SerialWrapper>();
        
        SkidService3.SerialWrapper aserialWrapper;
        SkidService3.SerialWrapper bserialWrapper;
        SkidService3.SerialWrapper cserialWrapper;

        //data.asnLine.Item__r.Item_Attribute__r = data.fuel.itemAttrObj2;
        
		List<ASN_Line__c> queriedASNLine = [Select ASN__r.Company__c, Purchase_Order__r.Type__c, Name, Item__c, Line__c, Quantity_Shipped__c, Company__c, Item__r.Name,Item__r.Item_Attribute__c, Item__r.Non_Inventory__c, Item__r.Stocking_UOM__c, Item__r.Source__c, Company__r.Serial_Control__c, Purchase_Order_Line__r.Item__r.Stocking_UOM__c,Purchase_Order_Line__r.Company__r.Serial_Control__c, Purchase_Order_Line__r.Item__c,
											Item__r.Packaging_UOM__c, Purchase_Order_Line__r.Packaging_UOM__c,Purchase_Order_Line__r.Purchase_UOM__c,Purchase_Order_Line__r.Sales_Order_Line__c, item__r.item_attribute__r.Serial_Number__c, Purchase_Order_Line__r.item__r.Packaging_UOM__c, Purchase_Order_Line__r.Delivery_Facility__r.Facility_Identifier__c
									  From ASN_Line__c where Id =:data.asnLine.Id Limit 1];
		
		
        List <ASNAddManageExt.ASNLineWrapper> updateasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper a;
        queriedASNLine[0].Quantity_Shipped__c = 1;
        
        SKID__c skid1 = new SKID__c();
        skid1.ASN_Line__c = queriedASNLine[0].id;
        skid1.Type__c = 'Draft In-Transit';
        skid1.Item__c = queriedASNLine[0].Item__c;
        skid1.Item__r = queriedASNLine[0].Item__r;
        skid1.Expiration_Date__c = system.today();
        skid1.Lot_Number__c = '1';
        skid1.Quantity__c = 1;
        skid1.Quantity_Stocking_UOM__c = 1;
        skid1.Company__c = data.fuel.company.Id;
        skid1.Stocking_UOM__c = queriedASNLine[0].Item__r.Stocking_UOM__c;
        skid1.Packaging_UOM__c = queriedASNLine[0].Item__r.Stocking_UOM__c;
        skid1.Packaging_UOM__r = data.fuel.uomObj;
        
        
        List<Serial__c> seriallist = new List<Serial__c>();
        
        Serial__c ser = new Serial__c(
            Name = 'inTransit Serial 1',
            Item__c = skid1.Item__c,
            Company__c = data.asn.Company__c
            
        );
        ser.Unique_Key2__c = data.asn.Company__c + '-' + ser.Item__c + '-' + ser.Name;
        
		serialList.add(ser);
        aserialwrapper = new SkidService3.SerialWrapper(skid1, serialList);
        serialwrapperlist.add(aserialwrapper);
        
	    a = new ASNAddManageExt.ASNLineWrapper(queriedASNLine[0],serialwrapperlist);
	    a.trackedAttributes = SKIDService3.trackedAttributes(null, null, data.asnLine.Item__r);
		
	    updateasnlWrapper.add(a);
        List <ASNAddManageExt.ASNLineWrapper> newasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper b;
        
        SKID__c skid2 = new SKID__c();
        skid2.ASN_Line__c = queriedASNLine[0].id;
        skid2.Type__c = 'Draft In-Transit';
        skid2.Item__c = queriedASNLine[0].Item__c;
        skid2.Item__r = queriedASNLine[0].Item__r;
        skid2.Expiration_Date__c = system.today();
        skid2.Lot_Number__c = '2';
        skid2.Quantity__c = 1;
        skid2.Quantity_Stocking_UOM__c = 10;
        skid2.Company__c = data.fuel.company.Id;
        skid2.Stocking_UOM__c = queriedASNLine[0].Item__r.Stocking_UOM__c;
        skid2.Packaging_UOM__c = queriedASNLine[0].Item__r.Stocking_UOM__c;
        skid2.Packaging_UOM__r = data.fuel.uomObj;
       
        List<Serial__c> seriallist1 = new List<Serial__c>();
        
        bserialwrapper = new SkidService3.SerialWrapper(skid2, serialList1);
		
        serialwrapperlist1.add(bserialwrapper);
		b = new ASNAddManageExt.ASNLineWrapper(queriedASNLine[0].clone(false, true),serialwrapperlist1);
        b.trackedAttributes = SKIDService3.trackedAttributes(null, null, data.asnLine.Item__r);
		
        newasnlWrapper.add(b);
        

        result = ASNAddManageExt.saveAction(data.asn, null, updateasnlWrapper, newasnlWrapper, new List<ASNAddManageExt.ASNLineWrapper>(),new List<SkidService3.SerialWrapper>(), null, null);

        system.assertEquals(result.success, false);//asn qty doesn't match serials
        Boolean serialmismatch = false;
        
        if(result.messages != null && result.messages.size() > 0){
				for (Map<String, String> msg : result.messages) {
					if(msg.get('message').contains(Label.ASN_Quantity_Not_Matching_Number_Of_Serials)){
				    	serialmismatch = true;
				    }
				}
			}
     
        system.assert(serialmismatch == true);
        
        List <ASNAddManageExt.ASNLineWrapper> newupdatedasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper c;
       
       
        List<Serial__c> seriallist2 = new List<Serial__c>();
        
        Serial__c ser1 = new Serial__c(
            Name = 'inTransit Serial 2',
            Item__c = skid1.Item__c,
            Company__c = data.asn.Company__c
        );
        ser1.Unique_Key2__c = data.asn.Company__c + '-' + ser1.Item__c + '-' + ser1.Name;
        
		serialList2.add(ser1);

        cserialwrapper = new SkidService3.SerialWrapper(skid2, serialList2);
		
        serialwrapperlist2.add(cserialwrapper);
		c = new ASNAddManageExt.ASNLineWrapper(queriedASNLine[0].clone(false, true),serialwrapperlist2);
        c.trackedAttributes = SKIDService3.trackedAttributes(null, null, data.asnLine.Item__r);
        newupdatedasnlWrapper.add(c);
        
        result = ASNAddManageExt.saveAction(data.asn, null, updateasnlWrapper, newupdatedasnlWrapper, new List<ASNAddManageExt.ASNLineWrapper>(), new List<SkidService3.SerialWrapper>(),null, null);

        system.assert(result.success==true, result);
        
        List<SKID__c> skidlist = [Select Id, Quantity__c, ( select Id, Unique_Key2__c, Name, Item__c, Allow_Reentry__c, SKID__c,Status__c from Serials__r) from SKID__c where ASN_Line__c =:data.asnLine.id and Type__c = 'Draft In-Transit'];
		system.assert(skidlist.size() == 2, skidlist);
		for(SKID__c sk:skidlist){
			system.assert(sk.Serials__r.size() == 1);
			if(sk.Id == skid1.Id){
				system.assert(sk.Serials__r[0].Name == ser.Name);
				system.assert(sk.Serials__r[0].Unique_Key2__c == ser.Unique_Key2__c);
				system.assert(sk.Serials__r[0].Allow_Reentry__c == false);
				system.assert(sk.Serials__r[0].Status__c == 'Draft In-Transit');
			}
			if(sk.Id == skid2.Id){
				system.assert(sk.Serials__r[0].Name == ser1.Name);
				system.assert(sk.Serials__r[0].Unique_Key2__c == ser1.Unique_Key2__c);
				system.assert(sk.Serials__r[0].Allow_Reentry__c == false);
				system.assert(sk.Serials__r[0].Status__c == 'Draft In-Transit');
			}
				
		}
    }
    
     
        private static testMethod void testDropShipwithSerials() {
	        if(KSE.checkTestDispatch()){return;}
            
            ReceivingDocumentServiceTest.setupDropShipAdvanced();
            List<Stock_Movement_Rule_Settings__c> smrsList = ReceivingDocumentServiceTest.fuel.smrsList;
            List<Stock_Movement_Rule__c> smrs = ReceivingDocumentServiceTest.fuel.stockMovementRuleList;
            update new Company__c(Id=ReceivingDocumentServiceTest.fuel.company.Id, Serial_Control__c = 'At receipt and all processes');
           // update new Location__c(Id=ReceivingDocumentServiceTest.fuel.location3.Id,Bin_Tracked__c=true);
            update new Item__c(Id=ReceivingDocumentServiceTest.fuel.itemList[0].Id,Item_Attribute__c=ReceivingDocumentServiceTest.fuel.itemAttrObj2.id);
            update new Facility__c(Id=ReceivingDocumentServiceTest.fuel.facility2.Id,Default_Purchasing_Delivery_Location__c=ReceivingDocumentServiceTest.fuel.location2.Id);
            
            ASN__c asn = new ASN__c(
                Company__c = ReceivingDocumentServiceTest.po.Company__c,
                Supplier__c = ReceivingDocumentServiceTest.po.Supplier__c,
                Facility__c = ReceivingDocumentServiceTest.po.Delivery_Facility__c,
                FOB__c = ReceivingDocumentServiceTest.po.FOB_Term__c,
                Status__c = 'Draft',
                Transaction_Date__c = System.today(),
                Currency__c = TestFuel.currencyUSD.id,
                Transaction_Type__c = 'Purchase Order ASN'
            );
            insert asn;
            ASN_Line__c asnLine = new ASN_Line__c(
                Purchase_Order__c = ReceivingDocumentServiceTest.po.Id,
                Purchase_Order_Line__c = ReceivingDocumentServiceTest.poLine.Id,
                Item__c = ReceivingDocumentServiceTest.poLine.Item__c,
                Item__r = ReceivingDocumentServiceTest.fuel.itemList[0],
                Quantity_Shipped__c = 5,
                Quantity_Received__c = 0,
                Unit_Price__c = 10,
                Status__c = 'New',
                ASN__c = asn.Id,
                Company__c = asn.Company__c,
                Supplier__c = asn.Supplier__c,
                Is_Changed__c = true,
                Facility__c = ReceivingDocumentServiceTest.fuel.facility2.Id,
                Location__c = ReceivingDocumentServiceTest.fuel.location2.Id
            );
            insert asnLine;
            
            Lot__c lot1 = new Lot__c(Company__c = asn.company__c, Item__c = ReceivingDocumentServiceTest.poLine.Item__c, Expiration_Date__c = system.today()+7, Name='LOT 1' );
            insert lot1;
            SKID__c fromSKID = new SKID__c(
                ASN_Line__c = asnLine.Id,
                Facility2__c = asnLine.Facility__c,
                Location__c = asnLine.Location__c,
                Type__c = 'Draft In-Transit',
                Item__c = asnLine.Item__c,
                Quantity__c = 3,
                Quantity_Stocking_UOM__c = 3,
                Expiration_Date__c = system.today() + 7,
        		//Date_received__c = system.today(), attribute is not present on assigned Item Attrib..
        		Lot_Number__c = lot1.Name,
        		Lot__c = lot1.Id,
        		Company__c = ReceivingDocumentServiceTest.fuel.company.Id,
        		Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
                Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
            );
            fromSKID.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
            fromSKID.Packaging_UOM__r.Package_Class__r = null;
            insert fromSKID; 
            
            Serial__c ser1 = new Serial__c(
                Name = 'Serial One',
                Item__c = ReceivingDocumentServiceTest.fuel.itemList[0].id,
                Company__c = ReceivingDocumentServiceTest.fuel.company.Id,
                Allow_Reentry__c = true,
                SKID__c = fromSKID.Id,
                Status__c = 'In-Transit'
            );
            ser1.Unique_Key2__c = ser1.Company__c + '-' + ser1.Item__c + '-' + ser1.Name;
            
            Serial__c ser2 = new Serial__c(
                Name = 'Serial Two',
                Item__c = ReceivingDocumentServiceTest.fuel.itemList[0].id,
                Company__c = ReceivingDocumentServiceTest.fuel.company.Id,
                Allow_Reentry__c = true,
                SKID__c = fromSKID.Id,
                Status__c = 'In-Transit'
            );
             ser2.Unique_Key2__c = ser2.Company__c+ '-' + ser2.Item__c + '-' + ser2.Name;
              
            Serial__c ser3 = new Serial__c(
                Name = 'Serial Three',
                Item__c = ReceivingDocumentServiceTest.fuel.itemList[0].id,
                Company__c = ReceivingDocumentServiceTest.fuel.company.Id,
                Allow_Reentry__c = true,
                SKID__c = fromSKID.Id,
                Status__c = 'In-Transit'
            );
            ser3.Unique_Key2__c = ser3.Company__c + '-' + ser3.Item__c + '-' + ser3.Name;
            insert new list<Serial__c>{ser1, ser2, ser3};

            Test.startTest();
            JsonResult result = ASNService.confirmASN(asn);
            System.assert(result.success,result);
            Test.stopTest();
            Set<ID> receiptlineSet = new Set<ID>();
            List<Receipt_Line__c> receiptLines = [SELECT Id,Purchase_Order_Line__r.Quantity_Received__c,Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c,(SELECT Id,Type__c FROM Inventory_Transactions__r) FROM Receipt_Line__c WHERE Receiving_Document__r.Type__c = 'Purchase Order Receipt'];
            System.assert(receiptLines.size() == 1);
            System.assert(receiptLines[0].Purchase_Order_Line__r.Quantity_Received__c == 3,receiptLines[0].Purchase_Order_Line__r.Quantity_Received__c);
            System.assert(receiptLines[0].Inventory_Transactions__r.size() == 2,receiptLines[0].Inventory_Transactions__r);
            System.assert(receiptLines[0].Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c == 3,receiptLines[0].Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c);
            for(Receipt_Line__c rcptline: receiptlines){
        	    receiptlineSet.add(rcptline.Id);
            }    
            List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Inventory_Change__c,Inventory_Change__r.Type__c, Subtransaction_Type__c, Finalized__c, 
                Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, 
                To_SKID__r.Name, To_SKID__r.Location__c, ( select Id, Serial__c, Serial__r.Allow_Reentry__c, Serial__r.SKID__c, Type__c From Serial_Transactions__r) 
        		FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
            System.assertEquals(itList.size(),2,itList);
            
           for(Inventory_Transaction__c itx : itList) {
	            if (itx.Type__c == 'Logical Purchase Order Receipt'){
	               System.assertEquals(itx.Quantity__c,3,itx);
	               System.assertEquals(itx.Type__c,'Logical Purchase Order Receipt',itx);
	               System.assertEquals(itx.Subtransaction_Type__c,'Logical Purchase Order Receipt',itx);
	               System.assertEquals(itx.Serial_Transactions__r.size(),3,itx.Serial_Transactions__r);
	            } else if(itx.Type__c == 'Logical Sales Order Shipment'){
	               System.assertEquals(itx.Quantity__c,3,itx);
	               System.assertEquals(itx.Type__c,'Logical Sales Order Shipment',itx);
	               System.assertEquals(itx.Subtransaction_Type__c,'Logical Sales Order Shipment',itx);
	               System.assertEquals(itx.Serial_Transactions__r.size(),3,itx.Serial_Transactions__r);            
	            }
	            else{
	                 System.assert(false);
	            }
            }                                          
            Integer ReceiptCount = 0;
            Integer ShipmentCount = 0;
            
            Set<ID> itSet = new Set<ID>();
            for(Inventory_Transaction__c invtrans: itList) {
                itSet.add(invtrans.Id);
            }
            
            ReceiptCount = [Select count() From Serial_Transaction__c where Inventory_Transaction__c IN :itSet and Type__c = 'Logical Receipt'];
        	ShipmentCount = [Select count() From Serial_Transaction__c where Inventory_Transaction__c IN :itSet and Type__c = 'Logical Shipment'];

            System.assertEquals(3,ReceiptCount);
            System.assertEquals(3,ShipmentCount);        
            
        }
        
    static testMethod void testCancelNewASN(){
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        
        Test.startTest();
        
        result = ASNAddManageExt.HeaderActions(data.asn, 'cancel', new list<String>());
        system.assertEquals(result.success, true); // can also cancel if there are lines with New status (with no receipts)
        
        Test.stopTest();
        
        ASN_Line__c asnLinetoCheck = [select id, name, Status__c, ASN__r.Status__c from ASN_Line__c where id = :data.asnLine.id];
        system.assertEquals(asnLinetoCheck.Status__c, 'Cancelled');
        system.assertEquals(asnLinetoCheck.ASN__r.Status__c, 'Cancelled');
        
    }
    
    static testMethod void testCancelASN(){ //happy path
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        
        result = ASNAddManageExt.HeaderActions(data.asn, 'confirm', new list<String>());
        system.assertEquals(result.success, true);
        
        Test.startTest();
        
        result = ASNAddManageExt.HeaderActions(data.asn, 'cancel', new list<String>());
        system.assertEquals(result.success, true);
        
        Test.stopTest();

        
        ASN_Line__c asnLinetoCheck = [select id, name, Status__c, ASN__r.Status__c, ( select id, Status__c, Quantity_Received__c from Receipt_Lines__r)
                                        from ASN_Line__c where id = :data.asnLine.id];
        system.assertEquals(asnLinetoCheck.Status__c, 'Cancelled');
        system.assertEquals(asnLinetoCheck.ASN__r.Status__c, 'Cancelled');
        system.assertEquals(0, asnLinetoCheck.Receipt_Lines__r.size());
    }
    
    static testMethod void testUndoConfirmRegularASN(){ //happy path
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        
        result = ASNAddManageExt.HeaderActions(data.asn, 'confirm', new list<String>());
        system.assertEquals(result.success, true);
        
        ASN_Line__c asnLinetoCheck = [select id, name, Status__c, ASN__r.Status__c,Purchase_Order_Line__r.Item__r.Stocking_UOM__c,
                                     Purchase_Order_Line__r.Packaging_UOM__c,
                                    ( select id, Status__c, Quantity_Received__c from Receipt_Lines__r)
                                        from ASN_Line__c where id = :data.asnLine.id];
        system.assertEquals(asnLinetoCheck.Status__c, 'Open');
        system.assertEquals(asnLinetoCheck.ASN__r.Status__c, 'Confirmed');
        system.assertEquals(0, asnLinetoCheck.Receipt_Lines__r.size());
        
        Test.startTest();
        
        result = ASNAddManageExt.HeaderActions(data.asn, 'undoconfirm', new list<String>());
        system.assert(result.success==true, result);
        
        Test.stopTest();

        asnLinetoCheck = [select id, name, Status__c, ASN__r.Status__c, ( select id, Status__c, Quantity_Received__c from Receipt_Lines__r)
                                        from ASN_Line__c where id = :data.asnLine.id];
        system.assertEquals(asnLinetoCheck.Status__c, 'New');
        system.assertEquals(asnLinetoCheck.ASN__r.Status__c, 'Draft');
        system.assertEquals(0, asnLinetoCheck.Receipt_Lines__r.size());

    }
    
    static testMethod void testUndoConfirmASNErrors(){
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        
        Test.startTest();
        
        result = ASNAddManageExt.HeaderActions(data.asn, 'undoconfirm', new list<String>());
        system.assertEquals(result.success, false); // can cancel only if there are no lines or have lines that are confirmed but with no receipts
        
        Test.stopTest();

        ASN_Line__c asnLinetoCheck = [select id, name, Status__c, ASN__r.Status__c from ASN_Line__c where id = :data.asnLine.id];
        system.assertEquals(asnLinetoCheck.Status__c, 'New');
        system.assertEquals(asnLinetoCheck.ASN__r.Status__c, 'Draft');

    }
    
    private static testMethod void testDropShipUndoConfirm() {
        if(KSE.checkTestDispatch()){return;}
        
        ReceivingDocumentServiceTest.setupDropShipAdvanced();
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Inventory_Change__c.sObjectType,SKID__c.sObjectType,Location__c.sObjectType,Lot__c.sObjectType,Serial__c.sObjectType,
        	                                  FOB_Terms__c.sObjectType,Serial_Transaction__c.sObjectType,Inventory_Transaction__c.sObjectType,Receipt_Line__c.sObjectType,
        	                                  Receiving_Document__c.sObjectType,Item__c.sObjectType,Purchase_Order_Line__c.sObjectType,
        	                                  Company__c.sObjectType,Component__c.sObjectType,Customer__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        List<Stock_Movement_Rule_Settings__c> smrsList = ReceivingDocumentServiceTest.fuel.smrsList;
        List<Stock_Movement_Rule__c> smrs = ReceivingDocumentServiceTest.fuel.stockMovementRuleList;
        update new Location__c(Id=ReceivingDocumentServiceTest.fuel.location3.Id,Bin_Tracked__c=true);
        update new Item__c(Id=ReceivingDocumentServiceTest.fuel.itemList[0].Id,Item_Attribute__c=null,Packaging_UOM__c = JSON.serialize(new List<Id>{ ReceivingDocumentServiceTest.fuel.uomList[8].Id }));
        update new Facility__c(Id=ReceivingDocumentServiceTest.fuel.facility2.Id,Default_Purchasing_Delivery_Location__c=ReceivingDocumentServiceTest.fuel.location2.Id);
        Purchase_Order_Line__c poline = ReceivingDocumentServiceTest.poLine;
        poline.Packaging_UOM__c = ReceivingDocumentServiceTest.fuel.uomObj.Id;
        update poline;
        ASN__c asn = new ASN__c(
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Supplier__c = ReceivingDocumentServiceTest.po.Supplier__c,
            Facility__c = ReceivingDocumentServiceTest.po.Delivery_Facility__c,
            FOB__c = ReceivingDocumentServiceTest.po.FOB_Term__c,
            Status__c = 'Draft',
            Transaction_Date__c = System.today(),
            Currency__c = TestFuel.currencyUSD.id,
            Transaction_Type__c = 'Purchase Order ASN'
        );
        insert asn;
        
        ASN_Line__c asnLine = new ASN_Line__c(
            Purchase_Order__c = ReceivingDocumentServiceTest.po.Id,
            Purchase_Order_Line__c = poLine.Id,
            Purchase_Order_Line__r = poLine,
            Item__c = ReceivingDocumentServiceTest.poLine.Item__c,
            Item__r = ReceivingDocumentServiceTest.fuel.itemList[0],
            Quantity_Shipped__c = 10,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = asn.Company__c,
            Supplier__c = asn.Supplier__c,
            Is_Changed__c = true,
            Facility__c = ReceivingDocumentServiceTest.fuel.facility2.Id,
            Location__c = ReceivingDocumentServiceTest.fuel.location2.Id
        );
        insert asnLine;
        
        SKID__c skid = new SKID__c(
            ASN_Line__c = asnLine.Id,
            ASN_Line__r = asnLine,
            Facility2__c = asnLine.Facility__c,
            Location__c = asnLine.Location__c,
            Type__c = 'Draft In-Transit',
            Item__c = asnLine.Item__c,
            Item__r = asnLine.Item__r,
            Quantity__c = 10,
            Quantity_Stocking_UOM__c = 10,
            Company__c = ReceivingDocumentServiceTest.fuel.company.Id,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );

        skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
        skid.Packaging_UOM__r.Package_Class__r = null;
        insert skid;
        Test.startTest();

        
        JsonResult result = ASNService.confirmASN(asn);
        System.assert(result.success,result);
    
        List<Receipt_Line__c> receiptLines = [SELECT Id,Purchase_Order_Line__r.Item__r.Packaging_UOM__c, Purchase_Order_Line__r.Quantity_Received__c,Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c,(SELECT Id,Type__c FROM Inventory_Transactions__r) FROM Receipt_Line__c WHERE Receiving_Document__r.Type__c = 'Purchase Order Receipt'];
        System.assert(receiptLines.size() == 1);
        System.assert(receiptLines[0].Purchase_Order_Line__r.Quantity_Received__c == 10,receiptLines[0].Purchase_Order_Line__r.Quantity_Received__c);
        System.assert(receiptLines[0].Inventory_Transactions__r.size() == 2,receiptLines[0].Inventory_Transactions__r);
        System.assert(receiptLines[0].Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c == 10,receiptLines[0].Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c);
        
        Test.stopTest();
        result = ASNAddManageExt.HeaderActions(asn, 'undoconfirm', new list<String>());
        system.assert(result.success==true, result);

        receiptLines = [SELECT Id,Purchase_Order_Line__r.Quantity_Received__c, ASN_Line__r.Status__c, ASN_Line__r.ASN__r.Status__c,Status__c,
        Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c,(SELECT Id,Type__c FROM Inventory_Transactions__r) 
        FROM Receipt_Line__c WHERE Receiving_Document__r.Type__c = 'Purchase Order Receipt'];
        
        System.assert(receiptLines.size() == 1);
        
        System.assert(receiptLines[0].Status__c == 'Cancelled');
        System.assert(receiptLines[0].Purchase_Order_Line__r.Quantity_Received__c == 0,receiptLines[0].Purchase_Order_Line__r.Quantity_Received__c);
        System.assert(receiptLines[0].Inventory_Transactions__r.size() == 4,receiptLines[0].Inventory_Transactions__r);
        System.assert(receiptLines[0].Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c == 0,receiptLines[0].Purchase_Order_Line__r.Sales_Order_Line__r.Quantity_Shipped__c);
    }
    //Cancel POL Cancels Confirm ASN 
    static testMethod void cancelPOLCancelConfirmASN(){
        if(KSE.checkTestDispatch()){return;}        
       
        ASNData data = new ASNData();
        Test.startTest();
        Purchase_Order_Line__c poLine = [select id, status__c, Item__r.Packaging_UOM__c from purchase_order_line__c where purchase_order__c = :data.fuel.purchaseOrder.id];
        system.assert( poLine.status__c != 'Cancelled', 'Expected Open status' );
        system.assertEquals(data.fuel.purchaseOrder.Status__c, 'Open'); //check if the initial status is Open for a PO
        
        data.fuel.purchaseOrder.Approval_Status__c = 'Approved';
        update data.fuel.purchaseOrder;
        
        
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();

        result = ASNAddManageExt.HeaderActions(data.asn, 'confirm', null);
        system.assertEquals(result.success, true);
        PurchaseOrderService.cancelPOLines(data.fuel.purchaseOrderLines,false);
    
        Test.stopTest();
        poLine = [select id, status__c from purchase_order_line__c where purchase_order__c = :data.fuel.purchaseOrder.id];
        
        system.assertEquals('Cancelled', poLine.Status__c); //Cancel the line
        ASN_Line__c asnLinetoCheck = [select id, name, Status__c, ASN__r.Status__c from ASN_Line__c where id = :data.asnLine.id AND Purchase_Order_Line__c = :data.fuel.purchaseOrderLines[0].id];
        system.assertEquals(asnLinetoCheck.Status__c, 'Cancelled');
        

    }


    
    
    
    private static testMethod void saveASNExistingSerial() {
        if(KSE.checkTestDispatch()){return;}       
        
        ASNData data = new ASNData();

        update new Item_Attribute__c(Id = data.fuel.itemAttrObj.Id, Serial_Number__c = true);

        SOQLUtil asnLineQuery = new SOQLUtil('ASN_Line__c');
        asnLineQuery.addAllCustomFields();
        asnLineQuery.addAllCustomFields(Item__c.sObjectType, 'Item__r');
        asnLineQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
        asnLineQuery.addFields(new Set<String>{ 'ASN__r.Company__c', 'Purchase_Order__r.Type__c', 'Company__r.Serial_Control__c', 
            'Purchase_Order_Line__r.Item__r.Stocking_UOM__c', 'Purchase_Order_Line__r.Company__r.Serial_Control__c', 'Purchase_Order_Line__r.Item__r.Packaging_UOM__c','Purchase_Order_Line__r.Delivery_Facility__r.Facility_Identifier__c',
            'Purchase_Order_Line__r.Item__c', 'Purchase_Order_Line__r.Purchase_UOM__c','Purchase_Order_Line__r.Packaging_UOM__c', 'Purchase_Order_Line__r.Sales_Order_Line__c' });
        asnLineQuery.setWhereClause('Id = \'' + data.asnLine.Id + '\'');
        ASN_Line__c asnLine = Database.query(asnLineQuery.getQuery());

        Serial__c serial = new Serial__c(
            Company__c = data.fuel.company.Id,
            Name = 'Serial1',
            Item__c = asnLine.Item__c,
            Unique_Key2__c = data.fuel.company.Id + '-' + asnLine.Item__c + '-Serial1',
            Allow_Reentry__c = true
        );
        insert serial;

        SKID__c skid = new SKID__c(
            ASN_Line__c = asnLine.Id,
            Type__c = SkidService3.SKID_TYPE_INTRANSIT,
            Item__c = asnLine.Item__c,
            Item__r = asnLine.Item__r,
            Expiration_Date__c = System.today() + 365,
            Lot_Number__c = 'LOTA',
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Company__c = data.fuel.company.Id,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );

        List<Serial__c> serials = new List<Serial__c>();
        for (Integer i=0;i<100;i++) {
            serials.add(new Serial__c(Name = 'Serial' + i));
        }

        ASNAddManageExt.ASNLineWrapper asnLineWrapper = new ASNAddManageExt.ASNLineWrapper(asnLine,new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,serials) });
        asnLineWrapper.trackedAttributes = SkidService3.trackedAttributes(null, null, asnLine.Item__r);

        JsonResult result = ASNAddManageExt.saveAction(data.asn, new List<String>(), new List<ASNAddManageExt.ASNLineWrapper>(), new List<ASNAddManageExt.ASNLineWrapper>{ asnLineWrapper }, new List<ASNAddManageExt.ASNLineWrapper>(),new List<SkidService3.SerialWrapper>(), null, null);
        System.assert(result.success == false, result);

        delete serial;

        result = ASNAddManageExt.saveAction(data.asn, new List<String>(), new List<ASNAddManageExt.ASNLineWrapper>(), new List<ASNAddManageExt.ASNLineWrapper>{ asnLineWrapper }, new List<ASNAddManageExt.ASNLineWrapper>(),new List<SkidService3.SerialWrapper>(), null, null);
        System.assert(result.success == true, result);

        serial = [SELECT Id,Status__c FROM Serial__c WHERE Name = 'Serial1'];
        System.assert(serial.Status__c == 'In-Transit', serial);
    }
    
    private static testMethod void cancelASNVoidSerial() {
        if(KSE.checkTestDispatch()){return;}        
        
        ASNData data = new ASNData();

        update new Item_Attribute__c(Id = data.fuel.itemAttrObj.Id, Serial_Number__c = true);

        SOQLUtil asnLineQuery = new SOQLUtil('ASN_Line__c');
        asnLineQuery.addAllCustomFields();
        asnLineQuery.addAllCustomFields(ASN__c.sObjectType, 'ASN__r');
        asnLineQuery.addAllCustomFields(Item__c.sObjectType, 'Item__r');
        asnLineQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
        asnLineQuery.addFields(new Set<String>{ 'ASN__r.Company__c', 'Purchase_Order__r.Type__c', 'Company__r.Serial_Control__c','Purchase_Order_Line__r.Quantity_Shipped__c','Purchase_Order_Line__r.Status__c', 
            'Purchase_Order_Line__r.Item__r.Stocking_UOM__c', 'Purchase_Order_Line__r.Company__r.Serial_Control__c', 'Purchase_Order_Line__r.Item__r.Packaging_UOM__c', 'Purchase_Order_Line__r.Delivery_Facility__r.Facility_Identifier__c',
            'Purchase_Order_Line__r.Item__c', 'Purchase_Order_Line__r.Purchase_UOM__c','Purchase_Order_Line__r.Packaging_UOM__c', 'Purchase_Order_Line__r.Sales_Order_Line__c' });
        asnLineQuery.setWhereClause('Id = \'' + data.asnLine.Id + '\'');
        ASN_Line__c asnLine = Database.query(asnLineQuery.getQuery());

        SKID__c skid = new SKID__c(
            ASN_Line__c = asnLine.Id,
            Type__c = SkidService3.SKID_TYPE_INTRANSIT,
            Item__c = asnLine.Item__c,
            Item__r = asnLine.Item__r,
            Expiration_Date__c = System.today() + 365,
            Lot_Number__c = 'LOTA',
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Company__c = data.fuel.company.Id,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );

        List<Serial__c> serials = new List<Serial__c>();
        for (Integer i=0;i<100;i++) {
            serials.add(new Serial__c(Name = 'Serial' + i));
        }

        ASNAddManageExt.ASNLineWrapper asnLineWrapper = new ASNAddManageExt.ASNLineWrapper(asnLine,new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,serials) });
        asnLineWrapper.trackedAttributes = SkidService3.trackedAttributes(null, null, asnLine.Item__r);

        ASNAddManageExt.saveAction(data.asn, new List<String>(), new List<ASNAddManageExt.ASNLineWrapper>(), new List<ASNAddManageExt.ASNLineWrapper>{ asnLineWrapper }, new List<ASNAddManageExt.ASNLineWrapper>(),new List<SkidService3.SerialWrapper>(), null, null);
        ASNService.confirmASN(asnLine.ASN__r);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.addFields(new Set<String>{ 'Facility2__r.Facility_Identifier__c', 'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c' });
        skidQuery.setWhereClause('Type__c = \'In-Transit\'');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery,'Serials__r');
        serialQuery.addAllCustomFields();
        skidQuery.addChildRelationship(serialQuery);

        asnLine = Database.query(asnLineQuery.getQuery());
        skid = Database.query(skidQuery.getQuery());

        asnLineWrapper = new ASNAddManageExt.ASNLineWrapper(asnLine,new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,skid.Serials__r) });
        asnLineWrapper.trackedAttributes = SkidService3.trackedAttributes(null, null, asnLine.Item__r);

        ASNService.CancelCloseASNLines(new List<ASNAddManageExt.ASNLineWrapper>{ asnLineWrapper }, 'Cancelled', false);

        Serial__c serial = [SELECT Id,Status__c FROM Serial__c WHERE Name = 'Serial1'];
        System.assert(serial.Status__c == 'Voided', serial);
    }
    
    private static testMethod void deleteASNLineVoidSerial() {
        if(KSE.checkTestDispatch()){return;}
        
        ASNData data = new ASNData();

        update new Item_Attribute__c(Id = data.fuel.itemAttrObj.Id, Serial_Number__c = true);

        SOQLUtil asnLineQuery = new SOQLUtil('ASN_Line__c');
        asnLineQuery.addAllCustomFields();
        asnLineQuery.addAllCustomFields(ASN__c.sObjectType, 'ASN__r');
        asnLineQuery.addAllCustomFields(Item__c.sObjectType, 'Item__r');
        asnLineQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
        asnLineQuery.addFields(new Set<String>{ 'ASN__r.Company__c', 'Purchase_Order__r.Type__c', 'Company__r.Serial_Control__c', 'Purchase_Order_Line__r.Item__r.Packaging_UOM__c',
            'Item__r.Stocking_UOM__c','Purchase_Order_Line__r.Item__r.Stocking_UOM__c','Purchase_Order_Line__r.Packaging_UOM__c', 'Purchase_Order_Line__r.Company__r.Serial_Control__c','Purchase_Order_Line__r.Delivery_Facility__r.Facility_Identifier__c',
            'Purchase_Order_Line__r.Item__c', 'Purchase_Order_Line__r.Purchase_UOM__c', 'Purchase_Order_Line__r.Sales_Order_Line__c' });
        asnLineQuery.setWhereClause('Id = \'' + data.asnLine.Id + '\'');
        ASN_Line__c asnLine = Database.query(asnLineQuery.getQuery());

        SKID__c skid = new SKID__c(
            ASN_Line__c = asnLine.Id,
            Type__c = SkidService3.SKID_TYPE_INTRANSIT,
            Item__c = asnLine.Item__c,
            Item__r = asnLine.Item__r,
            Expiration_Date__c = System.today() + 365,
            Lot_Number__c = 'LOTA',
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Company__c = data.fuel.company.Id,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );

        List<Serial__c> serials = new List<Serial__c>();
        for (Integer i=0;i<100;i++) {
            serials.add(new Serial__c(Name = 'Serial' + i));
        }

        ASNAddManageExt.ASNLineWrapper asnLineWrapper = new ASNAddManageExt.ASNLineWrapper(asnLine,new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,serials) });
        asnLineWrapper.trackedAttributes = SkidService3.trackedAttributes(null, null, asnLine.Item__r);

        ASNAddManageExt.saveAction(data.asn, new List<String>(), new List<ASNAddManageExt.ASNLineWrapper>(), new List<ASNAddManageExt.ASNLineWrapper>{ asnLineWrapper }, new List<ASNAddManageExt.ASNLineWrapper>(),new List<SkidService3.SerialWrapper>(), null, null);

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.addFields(new Set<String>{ 'Facility2__r.Facility_Identifier__c', 'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c' });
        skidQuery.setWhereClause('Type__c = \'In-Transit\'');

        SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery,'Serials__r');
        serialQuery.addAllCustomFields();
        skidQuery.addChildRelationship(serialQuery);

        asnLine = Database.query(asnLineQuery.getQuery());
        skid = Database.query(skidQuery.getQuery());

        asnLineWrapper = new ASNAddManageExt.ASNLineWrapper(asnLine,new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,skid.Serials__r) });
        asnLineWrapper.trackedAttributes = SkidService3.trackedAttributes(null, null, asnLine.Item__r);

        ASNAddManageExt.saveAction(data.asn, new List<String>(), new List<ASNAddManageExt.ASNLineWrapper>(),new List<ASNAddManageExt.ASNLineWrapper>(),new List<ASNAddManageExt.ASNLineWrapper>{ asnLineWrapper },new List<SkidService3.SerialWrapper>(), null, null);

        Serial__c serial = [SELECT Id,Status__c FROM Serial__c WHERE Name = 'Serial1'];
        System.assert(serial.Status__c == 'Voided', serial);
    }

    
    static testMethod void saveandconfirmASN(){

        ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        list<SkidService3.SerialWrapper> serialwrapperlist = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> serialwrapperlist1 = new list<SkidService3.SerialWrapper>();
        
        SkidService3.SerialWrapper aserialWrapper;
        SkidService3.SerialWrapper bserialWrapper;
        
        data.fuel.itemList[2].Packaging_UOM__c = JSON.serialize(new List<Id>{ data.fuel.uomList[8].Id });
		update data.fuel.itemList[2];
        data.asnLine.Item__r.Item_Attribute__r = data.fuel.itemAttrObj;

        List <ASNAddManageExt.ASNLineWrapper> updateasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper a;
        data.asnLine.Quantity_Shipped__c = 10;
        //a.asnl = data.asnLine;

        SKID__c skid1 = new SKID__c();
        skid1.ASN_Line__c = data.asnLine.id;
        skid1.Type__c = 'Draft In-Transit';
        skid1.Item__c = data.asnLine.Item__c;
        skid1.Item__r = data.asnLine.Item__r;
        skid1.Expiration_Date__c = system.today();
        skid1.Lot_Number__c = '1';
        skid1.Quantity__c = 10;
        skid1.Company__c = data.fuel.company.Id;
        skid1.Stocking_UOM__c = data.asnLine.Item__r.Stocking_UOM__c;
        skid1.Packaging_UOM__c = data.asnLine.Item__r.Stocking_UOM__c;
        //a.skidList = new List<SKID__c>{skid1};

        aserialwrapper = new SkidService3.SerialWrapper(skid1, new list<Serial__c>());
        serialwrapperlist.add(aserialwrapper);
        
	    a = new ASNAddManageExt.ASNLineWrapper(data.asnLine,serialwrapperlist);
	    a.trackedAttributes = SKIDService3.trackedAttributes(null, null, data.asnLine.Item__r);
		
	    updateasnlWrapper.add(a);
        List <ASNAddManageExt.ASNLineWrapper> newasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        
        result = ASNAddManageExt.saveAction(data.asn, null, updateasnlWrapper, newasnlWrapper, new List<ASNAddManageExt.ASNLineWrapper>(), new List<SkidService3.SerialWrapper>(), null, null);
        system.assertEquals(result.success, true);
        List<SKID__c> skidlist = [Select Id,Type__c,ASN_Line__c from SKID__c where ASN_Line__c !=null and Type__c ='Draft In-Transit'];
        system.assert(skidlist.size()==1);
        
        JSONResult confirmresult = new JSONResult();
		Test.startTest();
        confirmresult = ASNAddManageExt.HeaderActions(data.asn, 'confirm', null);
        system.assert(confirmresult.success==true, confirmresult);
        List<SKID__c> intransitskidList = [Select Id,Type__c,ASN_Line__c from SKID__c where ASN_Line__c =: data.asnLine.id];
        system.assert(intransitskidList.size()==1,intransitskidList);
        system.assert(intransitskidList[0].Type__c=='In-Transit');
       
        List<Inventory_Transaction__c> itlist = [Select Id,Type__c from Inventory_Transaction__c where ASN_Line__c =:data.asnLine.Id];
        system.assert(itlist.size()==1);
        system.assert(itlist[0].Type__c =='In-Transit',itlist[0]);
        
        result = ASNAddManageExt.HeaderActions(data.asn, 'undoconfirm', new list<String>());
        system.assertEquals(result.success, true);
        
        Test.stopTest();

        ASN_Line__c asnLinetoCheck = [select id, name, Status__c, ASN__r.Status__c, ( select id, Status__c, Quantity_Received__c from Receipt_Lines__r)
                                        from ASN_Line__c where id = :data.asnLine.id limit 1];
        system.assertEquals(asnLinetoCheck.Status__c, 'New');
        system.assertEquals(asnLinetoCheck.ASN__r.Status__c, 'Draft');
        system.assertEquals(0, asnLinetoCheck.Receipt_Lines__r.size());
        
        List<Inventory_Transaction__c> itlist1 = [Select Id,Type__c,ASN_Line__c from Inventory_Transaction__c where ASN_Line__c = :data.asnline.Id and Type__c ='Void - In-Transit'];//where ASN_Line__c = :data.asnline.Id and Type__c ='Void - In-Transit' Void - In-Transit
        system.assert(itlist1.size()==1,itlist1);
        
        List<SKID__c> skidlist1 = [Select Id,Type__c from SKID__c where ASN_Line__c = :data.asnline.Id and Type__c ='Draft In-Transit'];
        system.assert(skidlist1.size()==1,skidlist1);

    }
    
    //upgrade scenario no In-Transit ITs
    static testMethod void testUndoConfirmASN_UpgradeScenario(){ //happy path
    	
    	
    	ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        list<SkidService3.SerialWrapper> serialwrapperlist = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> serialwrapperlist1 = new list<SkidService3.SerialWrapper>();
        
        SkidService3.SerialWrapper aserialWrapper;
        SkidService3.SerialWrapper bserialWrapper;
		
		data.fuel.itemList[2].Packaging_UOM__c = JSON.serialize(new List<Id>{ data.fuel.uomList[8].Id });
		update data.fuel.itemList[2];
		
        data.asnLine.Item__r.Item_Attribute__r = data.fuel.itemAttrObj;

        List <ASNAddManageExt.ASNLineWrapper> updateasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper a;
        data.asnLine.Quantity_Shipped__c = 10;
        //a.asnl = data.asnLine;

        SKID__c skid1 = new SKID__c();
        skid1.ASN_Line__c = data.asnLine.id;
        skid1.Type__c = 'Draft In-Transit';
        skid1.Item__c = data.asnLine.Item__c;
        skid1.Item__r = data.asnLine.Item__r;
        skid1.Expiration_Date__c = system.today();
        skid1.Lot_Number__c = '1';
        skid1.Quantity__c = 10;
        skid1.Company__c = data.fuel.company.Id;
        skid1.Stocking_UOM__c = data.asnLine.Item__r.Stocking_UOM__c;
        skid1.Packaging_UOM__c = data.asnLine.Item__r.Stocking_UOM__c;
        aserialwrapper = new SkidService3.SerialWrapper(skid1, new list<Serial__c>());
        serialwrapperlist.add(aserialwrapper);
        
	    a = new ASNAddManageExt.ASNLineWrapper(data.asnLine,serialwrapperlist);
	    a.trackedAttributes = SKIDService3.trackedAttributes(null, null, data.asnLine.Item__r);
		
	    updateasnlWrapper.add(a);
        List <ASNAddManageExt.ASNLineWrapper> newasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        
        result = ASNAddManageExt.saveAction(data.asn, null, updateasnlWrapper, newasnlWrapper, new List<ASNAddManageExt.ASNLineWrapper>(), new List<SkidService3.SerialWrapper>(), null, null);
        system.assertEquals(result.success, true);
        
        JSONResult confirmresult = new JSONResult();
		Test.startTest();
        confirmresult = ASNAddManageExt.HeaderActions(data.asn, 'confirm', null);
        system.assert(confirmresult.success==true, confirmresult);
        List<SKID__c> intransitskidList = [Select Id,Type__c,ASN_Line__c from SKID__c where ASN_Line__c =: data.asnLine.id];
        system.assert(intransitskidList.size()==1,intransitskidList);
        system.assert(intransitskidList[0].Type__c=='In-Transit');
        
        
        List<Inventory_Transaction__c> inTransitITs = [Select Id,Type__c,ASN_Line__c from Inventory_Transaction__c where ASN_Line__c = :data.asnline.Id and Type__c ='In-Transit'];//where ASN_Line__c = :data.asnline.Id and Type__c ='In-Transit'
        system.assert(inTransitITs.size()==1,inTransitITs);
        
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Inventory_Transaction__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        delete inTransitITs;
        delete configList;
        Receiving_Document__c RD = new Receiving_Document__c(
            Company__c = data.asn.Company__c,
            Supplier__c = data.asn.Supplier__c,
            Type__c = 'In-Transit',
            Transaction_Type__c = 'In-Transit',
            Status__c = 'Closed',
            Transaction_Date__c = System.now(),
            Currency__c = data.asn.Currency__c
        );
        insert RD;
       
        result = ASNAddManageExt.HeaderActions(data.asn, 'undoconfirm', new list<String>());
        system.assertEquals(result.success, true);
        
        Test.stopTest();

        ASN_Line__c asnLinetoCheck = [select id, name, Status__c, ASN__r.Status__c, ( select id, Status__c, Quantity_Received__c from Receipt_Lines__r)
                                        from ASN_Line__c where id = :data.asnLine.id limit 1];
        system.assertEquals(asnLinetoCheck.Status__c, 'New');
        system.assertEquals(asnLinetoCheck.ASN__r.Status__c, 'Draft');
        system.assertEquals(0, asnLinetoCheck.Receipt_Lines__r.size());
        
        
        List<Inventory_Transaction__c> itlist1 = [Select Id,Type__c,ASN_Line__c from Inventory_Transaction__c where ASN_Line__c = :data.asnline.Id and Type__c ='Void - In-Transit'];
        system.assert(itlist1.size()==0,itlist1);//No Void In-Transit should be created for upgrade scenario..
        
        List<SKID__c> skidlist1 = [Select Id,Type__c from SKID__c where ASN_Line__c = :data.asnline.Id and Type__c ='Draft In-Transit' ];//where ASN_Line__c = :data.asnline.Id
        system.assert(skidlist1.size()==1,skidlist1);
        
    }


static testMethod void cancelconfirmASN(){
    	
    	ASNData data = new ASNData();
        ApexPages.StandardController setCon = new Apexpages.StandardController(data.asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        list<SkidService3.SerialWrapper> serialwrapperlist = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> serialwrapperlist1 = new list<SkidService3.SerialWrapper>();
        
        SkidService3.SerialWrapper aserialWrapper;
        SkidService3.SerialWrapper bserialWrapper;
        
        data.fuel.itemList[2].Packaging_UOM__c = JSON.serialize(new List<Id>{ data.fuel.uomList[8].Id });
		update data.fuel.itemList[2];
        data.asnLine.Item__r.Item_Attribute__r = data.fuel.itemAttrObj;

        List <ASNAddManageExt.ASNLineWrapper> updateasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper a;
        data.asnLine.Quantity_Shipped__c = 10;
        //a.asnl = data.asnLine;

        SKID__c skid1 = new SKID__c();
        skid1.ASN_Line__c = data.asnLine.id;
        skid1.Type__c = 'Draft In-Transit';
        skid1.Item__c = data.asnLine.Item__c;
        skid1.Item__r = data.asnLine.Item__r;
        skid1.Expiration_Date__c = system.today();
        skid1.Lot_Number__c = '1';
        skid1.Quantity__c = 10;
        skid1.Company__c = data.fuel.company.Id;
        skid1.Stocking_UOM__c = data.asnLine.Item__r.Stocking_UOM__c;
        skid1.Packaging_UOM__c = data.asnLine.Item__r.Stocking_UOM__c;
        //a.skidList = new List<SKID__c>{skid1};

        aserialwrapper = new SkidService3.SerialWrapper(skid1, new list<Serial__c>());
        serialwrapperlist.add(aserialwrapper);
        
	    a = new ASNAddManageExt.ASNLineWrapper(data.asnLine,serialwrapperlist);
	    a.trackedAttributes = SKIDService3.trackedAttributes(null, null, data.asnLine.Item__r);
		
	    updateasnlWrapper.add(a);
        List <ASNAddManageExt.ASNLineWrapper> newasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        
        result = ASNAddManageExt.saveAction(data.asn, null, updateasnlWrapper, newasnlWrapper, new List<ASNAddManageExt.ASNLineWrapper>(), new List<SkidService3.SerialWrapper>(), null, null);
        system.assertEquals(result.success, true);
        List<SKID__c> skidlist = [Select Id,Type__c,ASN_Line__c from SKID__c where ASN_Line__c !=null and Type__c ='Draft In-Transit'];
        system.assert(skidlist.size()==1);
        
        JSONResult confirmresult = new JSONResult();
		Test.startTest();
        confirmresult = ASNAddManageExt.HeaderActions(data.asn, 'confirm', null);
        system.assert(confirmresult.success==true, confirmresult);
        List<SKID__c> intransitskidList = [Select Id,Type__c,ASN_Line__c from SKID__c where ASN_Line__c =: data.asnLine.id];
        system.assert(intransitskidList.size()==1,intransitskidList);
        system.assert(intransitskidList[0].Type__c=='In-Transit');
       
        List<Inventory_Transaction__c> itlist = [Select Id,Type__c from Inventory_Transaction__c where ASN_Line__c =:data.asnLine.Id];
        system.assert(itlist.size()==1);
        system.assert(itlist[0].Type__c =='In-Transit',itlist[0]);
        
        result = ASNAddManageExt.HeaderActions(data.asn, 'cancel', new list<String>());
        system.assertEquals(result.success, true);
        
        Test.stopTest();

        ASN_Line__c asnLinetoCheck = [select id, name, Status__c, ASN__r.Status__c, ( select id, Status__c, Quantity_Received__c from Receipt_Lines__r)
                                        from ASN_Line__c where id = :data.asnLine.id limit 1];
        system.assertEquals(asnLinetoCheck.Status__c, 'Cancelled');
        system.assertEquals(asnLinetoCheck.ASN__r.Status__c, 'Cancelled');
        system.assertEquals(0, asnLinetoCheck.Receipt_Lines__r.size());
        
        List<Inventory_Transaction__c> itlist1 = [Select Id,Type__c,ASN_Line__c from Inventory_Transaction__c where ASN_Line__c = :data.asnline.Id and Type__c ='Void - In-Transit'];
        system.assert(itlist1.size()==1,itlist1);
        
        List<SKID__c> skidlist1 = [Select Id,Type__c from SKID__c where ASN_Line__c = :data.asnline.Id and Type__c ='Draft In-Transit'];
        system.assert(skidlist1.size()==0,skidlist1);//No Draft In-Transit Skid for Cancelled ASN
    }
}