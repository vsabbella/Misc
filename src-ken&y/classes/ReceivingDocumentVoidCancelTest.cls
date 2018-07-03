@isTest 
public with sharing class ReceivingDocumentVoidCancelTest {

    @testSetup
    private static void setupData() {
    	DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Item_Attribute__c.sObjectType,Location__c.sObjectType,Customer_Receipt__c.sObjectType,Working_Day__c.sObjectType,Stock_Movement_Rule_Settings__c.sObjectType, Currency__c.sObjectType,UOM__c.sObjectType,Supplier__c.sObjectType,Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Order__c.sObjectType,Package_Class__c.sObjectType,Period__c.sObjectType,Segment_Validation__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Facility__c.sObjectType,Item_Specification__c.sObjectType,Order_Line__c.sObjectType,Contract__c.sObjectType,Bank_Transaction__c.sObjectType,Lot__c.sObjectType,Bin__c.sObjectType,
            Stock_Movement_Rule__c.sObjectType,Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Fulfillment__c.sObjectType,Inventory_Transaction__c.sObjectType, Shipment__c.sObjectType,Customer__c.sObjectType, Shipment_Line__c.sObjectType,Product__c.sObjectType,Item__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        TestFuel fuel = new TestFuel();
        System.assert(fuel.smrsList != null);
        System.assert(fuel.stockMovementRuleList != null);
        System.assert(fuel.periodList != null);
        System.assert(fuel.purchaseOrder != null);
        System.assert(fuel.salesOrder != null);
        System.assert(fuel.transferOrder != null);
        System.assert(fuel.rdAccountingRuleList != null);
        System.assert(fuel.location != null);
        delete configList;
    }

    public static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void poReceive() {
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ poLine.Id },'Purchase Order',fuel.currencyUSD.Id).records[0];

        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ poLine.Id },new Set<String>{ 'purchase_order_line__c' });
        for (ReceivingWrapper rw:rWrappers) {
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 10;
                sw.skid.Lot_Number__c = 'LOT1';
                sw.skid.Expiration_Date__c = System.today() + 10;
            }
        }

        ReceivingWorkBenchExt.receive(rWrappers,null,null,rd,null);

        ReceivingDocumentVoidCancelService vcs = new ReceivingDocumentVoidCancelService(new List<Receiving_Document__c>{ rd });
        Map<Id,VoidCancelService.VoidCancelDetail> vcsResult = vcs.getBusinessVoidCancelDetails(new List<sObject>{ rd });
        System.assert(vcsResult.get(rd.Id).cancelMessages.size() == 0,vcsResult);

        Test.startTest();
        Map<Id,VoidCancelService.VoidCancelResponse> resp = vcs.businessVoid(new List<sObject>{ rd });
        system.assert(resp.get(rd.Id).success, resp );

        List<Inventory_Transaction__c> itList = [SELECT Id,Receipt_Line__r.Purchase_Order_Line__r.Status__c,Receipt_Line__r.Receiving_Document__r.Void__c,Receipt_Line__r.Receiving_Document__r.Void_Date__c FROM Inventory_Transaction__c WHERE Type__c = 'Void - Purchase Order Receipt'];
        System.assert(itList.size() == 1,itList);
        System.assert(itList[0].Receipt_Line__r.Purchase_Order_Line__r.Status__c == 'Open',itList[0].Receipt_Line__r.Purchase_Order_Line__r);

        Test.stopTest();
    }

    private static testMethod void miscReceive() {
        Receiving_Document__c rd = new Receiving_Document__c(
            Company__c = fuel.company.Id,
            Date_Created__c = System.today(),
            Status__c = 'Draft',
            Type__c = 'Miscellaneous Receipt',
            Transaction_Type__c = 'Miscellaneous Receipt',
            Currency__c = fuel.currencyUSD.Id,
            Transaction_Date__C = System.now()
        );
        insert rd;

        Receipt_Line__c rl = new Receipt_Line__c(
            Company__c = fuel.company.Id,
            Item__c = fuel.itemList[0].Id,
            Quantity_Declared__c = 10,
            Facility__c = fuel.facility2.Id,
            Location__c = fuel.location2.Id,
            Status__c = 'Draft',
            Packaging_UOM__c = fuel.uomList[8].id,
            Packaging_UOM__r = fuel.uomList[8],
            Receiving_Document__c = rd.id
        );
        insert rl;
        Test.startTest();
        ReceivingDocumentService.release(new Set<Id>{ rd.Id });


        rd = (Receiving_Document__c)PutawayReceiptsExt.getrdDetails(new List<Id>{ rl.Id },'Receiving Document').records[0];
        rd.Transaction_Date__c = System.now() + 5;

        List<ReceivingWrapper> rWrappers = (List<ReceivingWrapper>)PutawayReceiptsExt.getList(new List<Id>{ rl.Id },'Receiving Document').records;
        for (ReceivingWrapper rw:rWrappers) {
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                SKID__c skid = sw.skid;
                if (skid.Item__c == fuel.itemList[0].Id) {
                    skid.Quantity__c = 5;
                    skid.Expiration_Date__c = System.today() + 7;
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Inventory';
                    skid.Packaging_UOM__c = fuel.uomObj.Id;
                    skid.Packaging_UOM__r = fuel.uomObj;
                    skid.Packaging_UOM__r.Package_Class__c = null;
                }
            }
        }
        PutawayReceiptsExt.putaway(rWrappers,null,null,rd,null,'Receiving Document',true);


        SOQLUtil rdQuery = new SOQLUtil('Receiving_Document__c');
        rdQuery.addAllCustomFields();
        rdQuery.setWhereClause('Type__c = \'Miscellaneous Receipt\'');
        rd = Database.query(rdQuery.getQuery());

        (new ReceivingDocumentVoidCancelExt(new ApexPages.StandardController(rd))).cancelDocs();
        Test.stopTest();
        System.assert([SELECT Id FROM Inventory_Transaction__c WHERE Type__c = 'Void - Miscellaneous Receipt'].size() == 1);
    }

    /*private static testMethod void TOReceive() {
        Order__c transferOrder = fuel.transferOrder;
        fuel.setupInventory(true,false);

        OrderService.release(new Map<Id,Id>{ transferOrder.Id => null });

        List<OrderService.OrderWrapper> olWrappers = (List<OrderService.OrderWrapper>)OrderLinesAddManageExt.getLinesForAllocation(transferOrder.Id).records;
        for (OrderService.OrderWrapper olWrapper:olWrappers) {
            olWrapper.skidList[0].Quantity_Allocated__c  = (Decimal)olWrapper.order.get('Quantity_Ordered__c');
            olWrapper.skidList[0].Packaging_UOM__c = fuel.uomObj.Id;
            olWrapper.skidList[0].Stocking_UOM__c = fuel.uomObj.Id;
            olWrapper.skidList[0].Packaging_UOM__r = fuel.uomObj;
            //olWrapper.skidList[0].Packaging_UOM__r.Package_Class__c = null;
        }
        OrderService.allocateOrder(olWrappers);
        system.assert( !ExceptionService.hasErrors, ExceptionService.messages);
        OrderService.confirmPickOrder(OrderService.getLinesForConfirmPick(transferOrder.Id));
        system.assert( !ExceptionService.hasErrors, ExceptionService.messages);
        Test.startTest();

        OrderService.confirmShipOrder(OrderService.getLinesForConfirmShip(transferOrder.Id));
        system.assert( !ExceptionService.hasErrors, ExceptionService.messages);
        ReceivingDocumentService.receive(transferOrder.Id,OrderService.getLinesForReceive(transferOrder.Id),'Transfer Order');

        Receiving_Document__c rd = [SELECT Id,Name,Finalized__c,Company__c,Transaction_Date__c,Finalized_Date__c,Status__c,Void__c,Void_Date__c,Historical__c,Type__c FROM Receiving_Document__c WHERE Type__c = 'Transfer Order Receipt'];

        ReceivingDocumentVoidCancelService vcs = new ReceivingDocumentVoidCancelService(new List<Receiving_Document__c>{ rd });
        Map<Id,VoidCancelService.VoidCancelDetail> vcsResult = vcs.getBusinessVoidCancelDetails(new List<sObject>{ rd });
        System.assert(vcsResult.get(rd.Id).cancelMessages.size() == 0,vcsResult);
        vcs.businessVoid(new List<sObject>{ rd });


        List<Inventory_Transaction__c> itList = [SELECT Id,Receipt_Line__r.Order_Line__r.Status__c FROM Inventory_Transaction__c WHERE Type__c = 'Void - Transfer Order Receipt'];
        //System.assert(itList.size() == 2,itList);assertion commented out as transfer orders does not support the new Packaging UOM's #JCI
        Test.stopTest();
        for (Inventory_Transaction__c it:itList) {
            System.assert(it.Receipt_Line__r.Order_Line__r.Status__c == 'Open',it.Receipt_Line__r.Order_Line__r);
        }
    }*/
    
    private static testMethod void RTVCancel() {
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ poLine.Id },'Purchase Order',fuel.currencyUSD.Id).records[0];

        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ poLine.Id },new Set<String>{ 'purchase_order_line__c' });
        for (ReceivingWrapper rw:rWrappers) {
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 10;
                sw.skid.Lot_Number__c = 'LOT1';
                sw.skid.Expiration_Date__c = System.today() + 10;
            }
        }

        ReceivingWorkBenchExt.receive(rWrappers,null,null,rd,null);

        //PO RTV
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Purchase_Order__c>{po});
        ssc.setSelected(new List<Purchase_Order__c>{po});
        PurchaseOrderReturnToVendorExt poRTV = new PurchaseOrderReturnToVendorExt(ssc);
        poRTV.retrievePOLines();
        poRTV.POLinesForDisplay[0].newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c = 2;

        Test.startTest();

        poRTV.save();
        
        //RD RTV
        SOQLUtil rdQuery = new SOQLUtil('Receiving_Document__c');
        rdQuery.addAllCustomFields();
        rdQuery.setWhereClause('Type__c = \'Purchase Order Return\'');
        rd = ((List<Receiving_Document__c>)Database.query(rdQuery.getQuery()))[0];
        
        JsonResult rtvResult = ReceivingDocumentRTVExtV2.getRTVData(rd.Id);
        List<LineWrapper> rlWrappers = (List<LineWrapper>)rtvResult.records;
        rlWrappers[0].serialWrappers[0].skid.Quantity_To_Return__c = 2;
        
        ReceivingDocumentRTVExtV2.save(rlWrappers,new List<String>(),new List<String>());

        //RD Cancel
        ReceivingDocumentVoidCancelExt rdVC = new ReceivingDocumentVoidCancelExt(new ApexPages.StandardController(rd));
        rdVC.cancelDocs();
        
        System.assert([SELECT Id FROM Inventory_Transaction__c WHERE Inventory_Change__c != null AND Type__c = 'Void - Purchase Order Return'].size() == 1);

        Test.stopTest();
    }

    private static testMethod void backToBack() {
       
        Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soLine = fuel.salesOrderLine;

        soLine.Fulfillment_Source__c = 'Back To Back';
        update soLine;

        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        poLine.Approved__c = false;
        poLine.Item__c = fuel.itemList[0].Id;
        poLine.Sales_Order_Line__c = soLine.Id;
        poLine.Type__c = 'Back To Back';
        update poLine;

        poLine.Approved__c = true;
        update poLine;

        update new Item__c(Id = poLine.Item__c,Item_Attribute__c = null);

        delete c;

       
        
        
        new SalesOrderService().plan(so.Id);
        
        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ poLine.Id },'Purchase Order',fuel.currencyUSD.Id).records[0];

        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ poLine.Id },new Set<String>{ 'purchase_order_line__c' });
        for (ReceivingWrapper rw:rWrappers) {
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 10;
                sw.skid.Packaging_UOM__c = fuel.uomObj.Id;
                sw.skid.Packaging_UOM__r = fuel.uomObj;
                sw.skid.Packaging_UOM__r.Package_Class__r = null;
            }
        }
        Test.startTest();
        ReceivingWorkBenchExt.receive(rWrappers,null,null,rd,null);

        SOQLUtil rdQuery = new SOQLUtil('Receiving_Document__c');
        rdQuery.addAllCustomFields();
        rdQuery.setWhereClause('Id = \'' + rd.Id + '\'');

        SOQLUtil.ChildRelationship rlQuery = new SOQLUtil.ChildRelationship(rdQuery,'Receipt_Lines__r');
        rlQuery.addAllCustomFields();
        rdQuery.addChildRelationship(rlQuery);
        
        rd = Database.query(rdQuery.getQuery());
         
        VoidCancelService vcServ = new ReceivingDocumentVoidCancelService(new List<Receiving_Document__c>{ rd });
        vcServ.cancelSourceDocuments(new List<Receiving_Document__c>{ rd });

        Test.stopTest();
    }

    private static testMethod void notEnoughQuantity() {
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        update new Item__c(Id = poLine.Item__c,Item_Attribute__c = null);

        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ poLine.Id },'Purchase Order',fuel.currencyUSD.Id).records[0];

        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ poLine.Id },new Set<String>{ 'purchase_order_line__c' });
        for (ReceivingWrapper rw:rWrappers) {
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 10;
            }
        }

        ReceivingWorkBenchExt.receive(rWrappers,null,null,rd,null);

        SKID__c skid = [SELECT Id FROM SKID__c WHERE Item__c = :poLine.Item__c AND Type__c = 'Location'];
        skid.Quantity__c = 3;
        update skid;

        SOQLUtil rdQuery = new SOQLUtil('Receiving_Document__c');
        rdQuery.addAllCustomFields();
        rdQuery.setWhereClause('Id = \'' + rd.Id + '\'');

        SOQLUtil.ChildRelationship rlQuery = new SOQLUtil.ChildRelationship(rdQuery,'Receipt_Lines__r');
        rlQuery.addAllCustomFields();
        rdQuery.addChildRelationship(rlQuery);
        Test.startTest();
        rd = Database.query(rdQuery.getQuery());

         
        VoidCancelService vcServ = new ReceivingDocumentVoidCancelService(new List<Receiving_Document__c>{ rd });
        vcServ.cancelSourceDocuments(new List<Receiving_Document__c>{ rd });

        rd = Database.query(rdQuery.getQuery());
        System.assert(rd.Status__c != 'Cancelled',rd);
        for (Receipt_Line__c rl:rd.Receipt_Lines__r) {
            System.assert(rl.Status__c != 'Cancelled',rl);
        }

        Test.stopTest();
    }

    private static testMethod void notEnoughQuantityBackToBack() {
        Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soLine = fuel.salesOrderLine;

        soLine.Fulfillment_Source__c = 'Back To Back';
        update soLine;
        
        new SalesOrderService().plan(so.Id);
        
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;


        poLine.Approved__c = false;
        poLine.Item__c = fuel.itemList[0].Id;
        poLine.Sales_Order_Line__c = soLine.Id;
        poLine.Type__c = 'Back To Back';
        update poLine;

        poLine.Approved__c = true;
        update poLine;

        update new Item__c(Id = poLine.Item__c,Item_Attribute__c = null);

        delete c;
        Test.startTest();
        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ poLine.Id },'Purchase Order',fuel.currencyUSD.Id).records[0];

        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ poLine.Id },new Set<String>{ 'purchase_order_line__c' });
        for (ReceivingWrapper rw:rWrappers) {
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 10;
            }
        }

        JsonResult result = ReceivingWorkBenchExt.receive(rWrappers,null,null,rd,null);
        System.assert(result.success,result);

        SKID__c skid = [SELECT Id FROM SKID__c WHERE Item__c = :poLine.Item__c AND Type__c = 'Location'];
        skid.Quantity__c = 3;
        update skid;

        SOQLUtil rdQuery = new SOQLUtil('Receiving_Document__c');
        rdQuery.addAllCustomFields();
        rdQuery.setWhereClause('Id = \'' + rd.Id + '\'');

        SOQLUtil.ChildRelationship rlQuery = new SOQLUtil.ChildRelationship(rdQuery,'Receipt_Lines__r');
        rlQuery.addAllCustomFields();
        rdQuery.addChildRelationship(rlQuery);

        rd = Database.query(rdQuery.getQuery());
         
        VoidCancelService vcServ = new ReceivingDocumentVoidCancelService(new List<Receiving_Document__c>{ rd });
        vcServ.cancelSourceDocuments(new List<Receiving_Document__c>{ rd });

        rd = Database.query(rdQuery.getQuery());
        System.assert(rd.Status__c != 'Cancelled',rd);
        for (Receipt_Line__c rl:rd.Receipt_Lines__r) {
            System.assert(rl.Status__c != 'Cancelled',rl);
        }
        Test.stopTest();
    }
    
 // RD for a RMA cannot be voided after it has been invoiced.       
 static testMethod void testCannotVoidInvoicedRMA() {
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
        List<Period__c> periodList = fuel.periodList;
        sales_order__c sOrder = new sales_order__c();
     
        sOrder.Company__c = fuel.company.id;
        sOrder.Customer__c = fuel.customerSoldTo.id;   
        sOrder.Ship_To__c = fuel.customerShipTo.Id;
        sOrder.Bill_To__c = fuel.customerBillTo.Id;
        sOrder.Payment_Term__c = fuel.terms.id;
        sOrder.Currency__c = fuel.CurrencyUSD.id;
        sOrder.Type__c = SalesOrderService.SO_TYPE_RMA;
        insert sOrder;
        
        List<Sales_Order_Line__c> salesOrderLines = new List<Sales_Order_Line__c>();
        Sales_Order_Line__c soline = new Sales_Order_Line__c();
        Sales_Order_Line__c soline1 = new Sales_Order_Line__c();
         
        soline.Company__c = fuel.company.Id;
        soline.Description__c = fuel.product.Description__c;
        soline.Discount_Percent__c = 2;
        soline.Product__c = fuel.product.Id;
        soline.Quantity_Ordered__c = -100;
        soline.Required_Date__c = System.today()+5;
        soline.Sales_Order__c = sOrder.Id;
        soline.Sales_Order__r = sOrder;
        soline.Ship_From_Location__c = fuel.location2.Id;
        soline.Unit_Price__c = 11.12;
        soline.Memo__c = 'soline';
        salesOrderLines.add(soline);
         
        soline1.Company__c = fuel.company.id;
        soline1.Description__c = fuel.product2.Description__c;
        soline1.Discount_Percent__c = 2;
        soline1.Product__c = fuel.product2.Id;
        soline1.Quantity_Ordered__c = -15;
        soline1.Required_Date__c = System.today()+15;
        soline1.Sales_Order__c = sOrder.Id;
        soline1.Sales_Order__r = sOrder;
        soline1.Ship_From_Location__c = fuel.location2.Id;
        soline1.Unit_Price__c = 12.11;
        soline1.Sales_Tax__c = 14.686403;
        soline1.Memo__c = 'soline1';
        salesOrderLines.add(soline1);
        
       
        insert salesOrderLines;
        sOrder.Status__c = 'Open';
        update sOrder;
        soline.Status__c = 'Open';
        update soline;
        soline1.Status__c = 'Open';
        update soline1;
        
        Facility__c facility1 = fuel.facility2;
        facility1.RMA_Receipt_Routing__c = 'Inspect';
        update facility1;
        
        ReceivingWorkBenchExt.setGridConfig('RMA' , fuel.facility2.id);
       
        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Type__c, Company__c, Customer__c, Ship_From_Location__r.Facility__c, Currency__c  from Sales_Order__c where Id =:sOrder.Id]; 

        String docnum = queriedSO.Id;

        String facilityId = queriedSO.Ship_From_Location__r.Facility__c;
        String customerFilter = queriedSO.Customer__c;
        ID currencyfilter = queriedSO.Currency__c;
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
             
        test.startTest();

        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('RMA');
        ReceivingWorkBenchExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('RMA');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, docnum, customerFilter, currencyfilter, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
        
        //Manage Receive        
         
        List<Sales_Order_Line__c> newSOLinelist = [Select Id, Ship_From_Location__r.Facility__c, Quantity_Ordered__c, Sales_Order__r.Customer__c,
                                            Sales_Order__r.Currency__c, Sales_Order__r.Status__c, Sales_Order__r.Name,Sales_Order__r.Type__c, Product__r.Item__r.Name, Status__c 
                                            from Sales_Order_Line__c where Sales_Order__c =:sOrder.Id];
        system.assert(newSOLinelist.size() == 2, newSOLinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,facility1.Id,null,'RMA');
        List<Id> solineIds = new List<Id>();
        for(Sales_Order_Line__c line:newSOLinelist){
            if(facilityId ==null)
                facilityId = line.Ship_From_Location__r.Facility__c;
            system.assert(line.Status__c == 'Open', newSOLinelist);
            
            system.assert(line.Sales_Order__r.Customer__c == customerFilter, newSOLinelist);            
            system.assert(line.Sales_Order__c == docnum, newSOLinelist); 
            system.assert(line.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_RMA, newSOLinelist); 
            system.assert(line.Sales_Order__r.Status__c == 'Open', newSOLinelist); 
            solineIds.add(line.id);
        }
        
        getListresult = ReceivingWorkBenchExt.getList(solineIds, 'RMA');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total >0);
        

        rdocresult = ReceivingWorkBenchExt.getrdDetails(solineIds, 'RMA', fuel.currencyUSD.id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(solineIds), new set<String>{'Sales_Order_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                }
                else{
                    skid.Quantity__c = 4;
                }
                    
              
    }
        }
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);

        system.assert(receiveLinesresult.success == true, receiveLinesresult);
    
        List<Fulfillment__c> fulfillmentrecs = [Select Id, Status__c, Quantity__c,Fulfillment_Date__c, Sales_Order__c,Sales_Order_Line__c from Fulfillment__c where Sales_Order__c =:sOrder.Id];
        system.assert(fulfillmentrecs.size() == 2, fulfillmentrecs);    
        
        for(Fulfillment__c rec:fulfillmentrecs){

            if(rec.Sales_Order_Line__c == soline.Id)
                system.assert(rec.Quantity__c == -5, rec);

            else
                system.assert(rec.Quantity__c == -4, rec);

        }
        
        List<Sales_Order_Line__c> updatedsolinelist = [Select Id, Status__c, Quantity_Fulfilled__c from Sales_Order_Line__c where Sales_Order__c =:sOrder.Id];
        
        
        for(Sales_Order_Line__c sol:updatedsolinelist){
            if(sol.Id == soline.Id)
                system.assert(sol.Quantity_Fulfilled__c == -5, sol);
            else
                system.assert(sol.Quantity_Fulfilled__c == -4, sol);
            
        }
                                    
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Status__c, Item__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Sales_Order__c =:sOrder.Id and Sales_Order__r.Type__c = 'RMA-Credit'];
        system.assert(receiptlines.size() == 2, receiptlines);
     
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c == null);
            system.assert(rcptline.Sales_Order__c == sOrder.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'RMA Receipt');
            if(rcptline.Item__c == fuel.itemList[0].ID){
                system.assert(rcptline.Quantity_Received__c == 5, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 5, rcptline.Quantity_Still_Due_For_Putaway__c);
            }
            else{
                system.assert(rcptline.Quantity_Received__c == 4, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 4, rcptline.Quantity_Still_Due_For_Putaway__c);
            } 
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'RMA Receipt', rcptline);            
        }
   
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        system.assert(itlist.size() == 0, itlist);

        ApexPages.standardController con = new ApexPages.standardController(queriedSO);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(queriedSO.Id,'Sales_Order__c');
        system.assert(jr.success);
        
      	jr = GenerateInvoiceExt.next(false,queriedSO.Id, queriedSO);
   	    system.assert(jr.success);
      	system.assertNotEquals(null, jr.records);
     	system.assertEquals(1, jr.records.size());
       	
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       		
    	system.assert(jr.success);
     	system.assertNotEquals(null, jr.records);
      	system.assertEquals(1, jr.records.size());
       	
       	jr = GenerateInvoiceExt.finalizeInvoices(queriedSO.Id,false, (list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	boolean ErrorExists = false; 
       	jr = GenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);

        List<Customer_Invoice_Sub_Line__c> ciSubLines = [SELECT Id,Fulfillment__r.Receipt_Line__c FROM Customer_Invoice_Sub_Line__c where Fulfillment__r.Receipt_Line__c IN :receiptlineSet and Customer_Invoice_Line__r.Customer_Invoice__r.Status__c != 'Cancelled' and Customer_Invoice_Line__r.Customer_Invoice__r.Void__c = false];
        system.assertEquals(ciSubLines.size() > 0, true, ciSubLines.size());
        
        ReceivingDocumentServiceV2 rds = ReceivingDocumentServiceV2.getInstance();
	    set<ID> voidRds = new set<ID>();
        voidRds.add(rdoc.Id);
	    
	    try {
            rds.voidOrderReceipts(voidRds, 'Void');
        } catch (Exception e){
           System.assert(e.getMessage().contains(Label.Cannot_Void_this_Document));
           
        } 
        
        Test.stopTest();
    }
}