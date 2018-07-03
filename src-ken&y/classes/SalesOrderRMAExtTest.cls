@isTest 
public with sharing class SalesOrderRMAExtTest {
	
	// ba-todo refactor
	static testMethod void dropShipforRMA(){
        if(KSE.checkTestDispatch()){return;}        
        
        ReceivingDocumentServiceTest.setupDropShipAdvanced();
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{ Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,
            Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, Shipment__c.sObjectType, Shipment_Line__c.sObjectType };
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        //Trigger disable for test methods?? not a good idea!
        insert configList;
        
        List<Stock_Movement_Rule_Settings__c> smrsList = ReceivingDocumentServiceTest.fuel.smrsList;
        List<Stock_Movement_Rule__c> smrs = ReceivingDocumentServiceTest.fuel.stockMovementRuleList;
        update new Location__c(Id=ReceivingDocumentServiceTest.fuel.location3.Id,Bin_Tracked__c=false);
        update new Item__c(Id=ReceivingDocumentServiceTest.fuel.itemList[0].Id,Item_Attribute__c=null, Stocking_UOM__c = ReceivingDocumentServiceTest.fuel.uomList[8].Id);
        update new Facility__c(Id=ReceivingDocumentServiceTest.fuel.facility2.Id,Default_Purchasing_Delivery_Location__c=ReceivingDocumentServiceTest.fuel.location2.Id);
        
        ASN__c asn = new ASN__c(
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Supplier__c = ReceivingDocumentServiceTest.po.Supplier__c,
            Facility__c = ReceivingDocumentServiceTest.po.Delivery_Facility__c,
            FOB__c = ReceivingDocumentServiceTest.po.FOB_Term__c,
            Status__c = 'Draft',
            Transaction_Date__c = System.today(),
            Currency__c = TestFuel.currencyUSD.ID,
            Transaction_Type__c = 'Purchase Order ASN'
        );
        insert asn;
        ASN_Line__c asnLine = new ASN_Line__c(
            Purchase_Order__c = ReceivingDocumentServiceTest.po.Id,
            Purchase_Order_Line__c = ReceivingDocumentServiceTest.poLine.Id,
            Item__c = ReceivingDocumentServiceTest.poLine.Item__c,
            Item__r = ReceivingDocumentServiceTest.fuel.itemList[0],
            Quantity_Shipped__c = 100,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = asn.Company__c,
            Supplier__c = asn.Supplier__c,
            Is_Changed__c = true
        );
        insert asnLine;
        insert new SKID__c(
            ASN_Line__c = asnLine.Id,
            Location__c = asnLine.Location__c,
            Type__c = 'Draft In-Transit',
            Item__c = asnLine.Item__c,
            Quantity__c = 100,
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );
        
        JsonResult result = ASNService.confirmASN(asn);
        System.assert(result.success,result);
        Sales_Order__c so = ReceivingDocumentServiceTest.salesOrder;
        Sales_Order_Line__c soline = ReceivingDocumentServiceTest.salesOrderLines[0];
        Sales_Order_Line__c soline1 = ReceivingDocumentServiceTest.salesOrderLines[1];
        
        
        
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Sales_Order__c>{so});
        setCon.setSelected(new List<Sales_Order__c>{so});
        
        SalesOrderRMAExt soRMAExt = new SalesOrderRMAExt(setCon);
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        msgList = ApexPages.getMessages(); 
        System.assert(msgList.size() == 0, msgList);

        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
        // SalesOrderRMAExt.SalesOrderLineWrapper
        //so.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        
        JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines(so.id);

        for (SalesOrderRMAExt.SalesOrderLineWrapper obj : (List<SalesOrderRMAExt.SalesOrderLineWrapper>) rmaLinesResult.records){
            System.assert(obj.soLine.Related_Sales_Order_Line__c != null, obj.soLine);
            if(obj.soLine.Product__c == ReceivingDocumentServiceTest.fuel.product.Id){
                obj.soLine.Quantity_Ordered__c = 10;
                obj.soLine.Fulfillment_Source__c = 'Inventory';
                obj.soLine.Returned_To_Vendor__c = false;
                solList.add( obj.soLine);
            }
            else
                obj.soLine.Quantity_Ordered__c = 0;
                
            
        }
        System.assertEquals(1, solList.size());
        Sales_order__c header = (Sales_Order__c) SalesOrderRMAExt.getSODetails(so.id).records[0];
        system.assert(header != null, 'Expecting RMA Header to not be null');
        header.Type__c = SalesOrderService.SO_TYPE_RMA;
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 20  queries or less. Actual: '+Limits.getQueries()); 
        JsonResult rma = SalesOrderRMAExt.createRMA(solList, header, new List<String>());
        system.assert(  Limits.getQueries() <= 100, ' Before create RMA 50  queries or less. Actual: '+Limits.getQueries()); 

        Sales_Order_Line__c[] rmaLines = [select Id, Sales_Order__r.Type__c,Returned_To_Vendor__c, Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c 
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA];//SO_TYPE_RMA_REPLACEMENT
        
        system.assertEquals(1, rmaLines.size());//replacement line creates a regular so line too.

        for (Sales_order_Line__c sol : rmaLines){
            system.assert(sol.Related_Sales_Order_Line__c != null);
            System.assertEquals('Draft', sol.Status__c);
            System.assert(sol.Quantity_Ordered__c < 0, sol.Quantity_Ordered__c + 'Expecting negative qty');
            
        }
        
        Sales_order__c soRMA = rmaLines[0].Sales_Order__r;
        System.assertEquals('Draft', soRMA.Status__c);
        System.assert(soRMA.Related_Sales_Order__c != null);
        delete configList;
        Test.startTest();
        System.debug( LoggingLevel.ERROR, 'Before Release queries : '+ Limits.getQueries() ); 
        system.assert(  Limits.getQueries() <= 72, ' expected TestData to use 50  queries or less. Actual: '+Limits.getQueries()); 
        new SalesOrderService().plan(soRMA.id);
        System.debug( LoggingLevel.ERROR, 'Before Release queries : '+ Limits.getQueries() ); 
        system.assert(  Limits.getQueries() <= 78, ' expected TestData to use 78  queries or less. Actual: '+Limits.getQueries()); 
        System.debug( LoggingLevel.INFO, 'Before Release queries : '+ Limits.getQueries() ); 
        rmaLines = [select Id, Has_Exceptions__c, Quantity_Fulfilled__c, Sales_Order__r.Has_Exceptions__c, Sales_Order__r.Type__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA];

        for (Sales_order_Line__c sol : rmaLines){
            System.assertEquals('Open', sol.Status__c, sol);
            system.assertEquals(false, sol.Has_Exceptions__c, ExceptionService.fetchExceptionTasks(new set<Id>{sol.id}));
        }
        
        ReceivingWorkBenchExt.setGridConfig('RMA' , ReceivingDocumentServiceTest.fuel.facility2.id);
        
        //Create ASN with inTransit SKID       
       
        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Type__c, Currency__c, Customer__c, Ship_From_Location__r.Facility__c  from Sales_Order__c where Id =:soRMA.Id]; 
        
        String docnum = queriedSO.Id;
        String facilityId = queriedSO.Ship_From_Location__r.Facility__c;
        String customerFilter = queriedSO.Customer__c;
        ID currencyfilter = queriedSO.Currency__c;
        JSONResult jsonresult = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
             
        //test.startTest();
        //Now Search for this ASN on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('RMA');
        ReceivingWorkBenchExt.refreshTrackedAttr(ReceivingDocumentServiceTest.fuel.Location, ReceivingDocumentServiceTest.fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('RMA');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, docnum, customerFilter, currencyfilter, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
        
        //Manage Receive        
         
        List<Sales_Order_Line__c> newSOLinelist = [Select Id, Ship_From_Location__r.Facility__c, Quantity_Ordered__c, Sales_Order__r.Customer__c, Sales_Order__r.Currency__c,
                                             Sales_Order__r.Status__c, Sales_Order__r.Name,Sales_Order__r.Type__c, Product__r.Item__r.Name, Status__c 
                                            from Sales_Order_Line__c where Sales_Order__c =:queriedSO.Id];
        system.assert(newSOLinelist.size() == 1, newSOLinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,ReceivingDocumentServiceTest.fuel.facility2.Id,null,'RMA');
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
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(solineIds, 'RMA', TestFuel.currencyUSD.ID);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(solineIds), new set<String>{'Sales_Order_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == ReceivingDocumentServiceTest.fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                    skid.Stocking_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
                    skid.Packaging_UOM__r.Package_Class__r = null;
                }
                
    }
        }
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        //delete configList;
        test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
    
        List<Fulfillment__c> fulfillmentrecs = [Select Id, Status__c, Invoice_Ready__c, Quantity__c, Sales_Order__c,Sales_Order_Line__c from Fulfillment__c where Sales_Order__c =:queriedSO.Id];
        
        system.assert(fulfillmentrecs.size() == 1, fulfillmentrecs);    
        
        for(Fulfillment__c rec:fulfillmentrecs){
        system.assert(rec.Invoice_Ready__c == true);
            if(rec.Sales_Order_Line__c == soline.Id)
                system.assert(rec.Quantity__c == -5, rec);
        }
                                        
        //Also check Quantity_Fulfilled__c on updated solines.  
        
        List<Sales_Order_Line__c> updatedsolinelist = [Select Id, Status__c, Quantity_Fulfilled__c from Sales_Order_Line__c where Sales_Order__c =:queriedSO.Id];
        
        
        for(Sales_Order_Line__c sol:updatedsolinelist){
            if(sol.Id == soline.Id)
                system.assert(sol.Quantity_Fulfilled__c == -5, sol);
            
        }
                                    
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Status__c, Item__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Sales_Order__c =:queriedSO.Id and Sales_Order__r.Type__c = :SalesOrderService.SO_TYPE_RMA];
        system.assert(receiptlines.size() == 1, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c == null);
            system.assert(rcptline.Sales_Order__c == queriedSO.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'RMA Receipt',rcptline.Receiving_Document__r.Type__c);
            if(rcptline.Item__c == ReceivingDocumentServiceTest.fuel.itemList[0].ID){
                system.assert(rcptline.Quantity_Received__c == 5, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 0, rcptline.Quantity_Still_Due_For_Putaway__c);
            }
             
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'RMA Receipt', rcptline);            
        }
    
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        system.assert(itlist.size() == 1, itlist);
    }
    
    
    
    static testMethod void dropShipforRMAReplacementwithRTV(){
        if(KSE.checkTestDispatch()){return;}        
        
        ReceivingDocumentServiceTest.setupDropShipAdvanced();
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Facility__c.sObjectType,Location__c.sObjectType,Item__c.sObjectType,ASN__c.sObjectType,ASN_Line__c.sObjectType, Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,
            Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, Shipment__c.sObjectType, Shipment_Line__c.sObjectType };
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        List<Stock_Movement_Rule_Settings__c> smrsList = ReceivingDocumentServiceTest.fuel.smrsList;
        List<Stock_Movement_Rule__c> smrs = ReceivingDocumentServiceTest.fuel.stockMovementRuleList;
        update new Location__c(Id=ReceivingDocumentServiceTest.fuel.location3.Id,Bin_Tracked__c=false);
        update new Item__c(Id=ReceivingDocumentServiceTest.fuel.itemList[0].Id,Item_Attribute__c=null, Stocking_UOM__c = ReceivingDocumentServiceTest.fuel.uomList[8].Id);
        update new Facility__c(Id=ReceivingDocumentServiceTest.fuel.facility2.Id,Default_Purchasing_Delivery_Location__c=ReceivingDocumentServiceTest.fuel.location2.Id);
        
        ASN__c asn = new ASN__c(
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Supplier__c = ReceivingDocumentServiceTest.po.Supplier__c,
            Facility__c = ReceivingDocumentServiceTest.po.Delivery_Facility__c,
            FOB__c = ReceivingDocumentServiceTest.po.FOB_Term__c,
            Status__c = 'Draft',
            Transaction_Date__c = System.today(),
            Currency__c = TestFuel.currencyUSD.ID,
            Transaction_Type__c = 'Purchase Order ASN'
        );
        insert asn;
        ASN_Line__c asnLine = new ASN_Line__c(
            Purchase_Order__c = ReceivingDocumentServiceTest.po.Id,
            Purchase_Order_Line__c = ReceivingDocumentServiceTest.poLine.Id,
            Item__c = ReceivingDocumentServiceTest.poLine.Item__c,
            Item__r = ReceivingDocumentServiceTest.fuel.itemList[0],
            Quantity_Shipped__c = 100,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = asn.Company__c,
            Supplier__c = asn.Supplier__c,
            Is_Changed__c = true
        );
        insert asnLine;
        insert new SKID__c(
            ASN_Line__c = asnLine.Id,
            Location__c = asnLine.Location__c,
            Type__c = 'Draft In-Transit',
            Item__c = asnLine.Item__c,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );
        
        JsonResult result = ASNService.confirmASN(asn);
        System.assert(result.success,result);
        Sales_Order__c so = ReceivingDocumentServiceTest.salesOrder;
        Sales_Order_Line__c soline = ReceivingDocumentServiceTest.salesOrderLines[0];
        Sales_Order_Line__c soline1 = ReceivingDocumentServiceTest.salesOrderLines[1];
        
        
        
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Sales_Order__c>{so});
        setCon.setSelected(new List<Sales_Order__c>{so});
        
        SalesOrderRMAExt soRMAExt = new SalesOrderRMAExt(setCon);
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        msgList = ApexPages.getMessages(); 
        System.assert(msgList.size() == 0, msgList);

        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
        // SalesOrderRMAExt.SalesOrderLineWrapper
        //so.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        
        JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines(so.id);

        for (SalesOrderRMAExt.SalesOrderLineWrapper obj : (List<SalesOrderRMAExt.SalesOrderLineWrapper>) rmaLinesResult.records){
            System.assert(obj.soLine.Related_Sales_Order_Line__c != null, obj.soLine);
            if(obj.soLine.Product__c == ReceivingDocumentServiceTest.fuel.product.Id){
                obj.soLine.Quantity_Ordered__c = -10;
                obj.soLine.Returned_To_Vendor__c = true;
                obj.soLine.Line__c = 1;
                obj.soLine.Allowances__c =0;
                obj.soLine.Freight_Allowance__c =0;
                obj.soLine.Discount_Percent__c =0;
                obj.soLine.Off_Invoice_Rate__c = 0;
                solList.add( obj.soLine);
            }
            else
                obj.soLine.Quantity_Ordered__c = 0;
                
            
        }
        System.assertEquals(1, solList.size());
        Sales_order__c header = (Sales_Order__c) SalesOrderRMAExt.getSODetails(so.id).records[0];
        system.assert(header != null, 'Expecting RMA Header to not be null');
        header.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 20  queries or less. Actual: '+Limits.getQueries()); 
        JsonResult rma = SalesOrderRMAExt.createRMA(solList, header, new List<String>());
        system.assert(  Limits.getQueries() <= 100, ' Before create RMA 50  queries or less. Actual: '+Limits.getQueries()); 

        //Sales_Order_Line__c[] solines = [select Id, Sales_Order__r.Type__c,Returned_To_Vendor__c, Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
         //                                from Sales_Order_Line__c];
                                         
        Sales_Order_Line__c[] rmaLines = [select Id, Sales_Order__r.Type__c,Returned_To_Vendor__c, Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];//SO_TYPE_RMA_REPLACEMENT
        
        system.assert(rmaLines.size() == 2, rmaLines[0].Sales_Order__r);//replacement line creates a regular so line too.
        Boolean negativeQty = false;
        Boolean positiveQty = false;
        for (Sales_order_Line__c sol : rmaLines){
            system.assert(sol.Related_Sales_Order_Line__c != null);
            System.assertEquals('Draft', sol.Status__c);
            if(sol.Quantity_Ordered__c < 0){
                negativeQty = true;
            }
            if(sol.Quantity_Ordered__c > 0){
                positiveQty = true;
            }
            
        }
        System.assert(positiveQty == true && negativeQty == true, rmaLines + 'Expecting both negative qty and positive qty');
        delete configList;
        Sales_order__c soRMA = rmaLines[0].Sales_Order__r;
        System.assertEquals('Draft', soRMA.Status__c);
        System.assert(soRMA.Related_Sales_Order__c != null);
        
        System.debug( LoggingLevel.INFO, 'Before Release queries : '+ Limits.getQueries() ); 
        system.assert(  Limits.getQueries() <= 74, ' expected TestData to use 50  queries or less. Actual: '+Limits.getQueries()); 
        new SalesOrderService().plan(soRMA.id);
        system.assert(  Limits.getQueries() <= 90, ' expected TestData to use 78  queries or less. Actual: '+Limits.getQueries()); 
        System.debug( LoggingLevel.INFO, 'Before Release queries : '+ Limits.getQueries() ); 
        rmaLines = [select Id, Has_Exceptions__c, Quantity_Fulfilled__c, Sales_Order__r.Has_Exceptions__c, Sales_Order__r.Type__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];
		system.assert(rmaLines.size()==2,rmaLines);
        for (Sales_order_Line__c sol : rmaLines){
            System.assertEquals('Open', sol.Status__c, sol);
            system.assertEquals(false, sol.Has_Exceptions__c, ExceptionService.fetchExceptionTasks(new set<Id>{sol.id}));
        }
        
        ReceivingWorkBenchExt.setGridConfig('RMA' , ReceivingDocumentServiceTest.fuel.facility2.id);
        
        //Create ASN with inTransit SKID       
       
        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Type__c, Currency__c, Customer__c, Ship_From_Location__r.Facility__c  from Sales_Order__c where Id =:soRMA.Id]; 
        
        String docnum = queriedSO.Id;
        String facilityId = queriedSO.Ship_From_Location__r.Facility__c;
        String customerFilter = queriedSO.Customer__c;
        ID currencyfilter = queriedSO.Currency__c;
        JSONResult jsonresult = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
        Test.startTest();
        //test.startTest();
        //Now Search for this ASN on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('RMA');
        ReceivingWorkBenchExt.refreshTrackedAttr(ReceivingDocumentServiceTest.fuel.Location, ReceivingDocumentServiceTest.fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('RMA');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, docnum, customerFilter, currencyfilter, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total == 1, searchresult);
        
        //Manage Receive        
         
        List<Sales_Order_Line__c> newSOLinelist = [Select Id, Ship_From_Location__r.Facility__c, Quantity_Ordered__c, Sales_Order__r.Customer__c, Sales_Order__r.Currency__c,
                                             Sales_Order__r.Status__c, Sales_Order__r.Name,Sales_Order__r.Type__c, Product__r.Item__r.Name, Status__c 
                                            from Sales_Order_Line__c where Sales_Order__c =:queriedSO.Id];
        system.assert(newSOLinelist.size() == 2, newSOLinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,ReceivingDocumentServiceTest.fuel.facility2.Id,null,'RMA');
        List<Id> solineIds = new List<Id>();
        for(Sales_Order_Line__c line:newSOLinelist){
            if(facilityId ==null)
                facilityId = line.Ship_From_Location__r.Facility__c;
            system.assert(line.Status__c == 'Open', newSOLinelist);
            system.assert(line.Sales_Order__r.Customer__c == customerFilter, newSOLinelist);            
            system.assert(line.Sales_Order__c == docnum, newSOLinelist); 
            system.assert(line.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_RMA_REPLACEMENT, newSOLinelist); 
            system.assert(line.Sales_Order__r.Status__c == 'Open', newSOLinelist); 
            solineIds.add(line.id);
        }
        
        getListresult = ReceivingWorkBenchExt.getList(solineIds, 'RMA');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total == 1, getListresult);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(solineIds, 'RMA', TestFuel.currencyUSD.ID);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(solineIds), new set<String>{'Sales_Order_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == ReceivingDocumentServiceTest.fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                    skid.Quantity_Stocking_UOM__c = 5;
                    skid.Stocking_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
                    skid.Packaging_UOM__r.Package_Class__r = null;
                }
                
    }
        }
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
    
        List<Fulfillment__c> fulfillmentrecs = [Select Id, Status__c, Quantity__c, Sales_Order__c,Sales_Order_Line__c from Fulfillment__c where Sales_Order__c =:queriedSO.Id];
        
        system.assert(fulfillmentrecs.size() == 1, fulfillmentrecs);    
        
        for(Fulfillment__c rec:fulfillmentrecs){
            if(rec.Sales_Order_Line__c == soline.Id)
                system.assert(rec.Quantity__c == -5, rec);
        }
                                        
        //Also check Quantity_Fulfilled__c on updated solines.  
        
        List<Sales_Order_Line__c> updatedsolinelist = [Select Id, Status__c, Quantity_Fulfilled__c from Sales_Order_Line__c where Sales_Order__c =:queriedSO.Id];
        
        
        for(Sales_Order_Line__c sol:updatedsolinelist){
            if(sol.Id == soline.Id)
                system.assert(sol.Quantity_Fulfilled__c == -5, sol);
            
        }
                                    
        Set<ID> receiptlineSet = new Set<ID>();
        Set<ID> relatedReceiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Status__c, Item__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Sales_Order__c =:queriedSO.Id and Sales_Order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];
        system.assert(receiptlines.size() == 1, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c == null);
            system.assert(rcptline.Sales_Order__c == queriedSO.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'Logical RMA Receipt',rcptline.Receiving_Document__r.Type__c);
            if(rcptline.Item__c == ReceivingDocumentServiceTest.fuel.itemList[0].ID){
                system.assert(rcptline.Quantity_Received__c == 5, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 0, rcptline.Quantity_Still_Due_For_Putaway__c);
            }
             
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'Logical RMA Receipt', rcptline);            
        }
    
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        
        system.assert(itlist.size() == 1, itlist);
        system.assert(itlist[0].Type__c == 'Logical RMA Receipt', itlist);
        
        List<Receipt_Line__c> returnReceiptlines = [Select Id, Status__c, Item__c, Quantity_Returned_to_Supplier__c, Quantity_Returned_To_Supplier_For_Credit__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Related_Receipt_Line__c IN :receiptlineSet];
        
        system.assert(returnReceiptlines.size() == 1, returnReceiptlines[0].Receiving_Document__r);
        
        for(Receipt_Line__c rline: returnReceiptlines){
            relatedReceiptlineSet.add(rline.Id);
            system.assert(rline.Receiving_Document__r.Type__c == 'Logical Purchase Order Return');
            system.assert(rline.Quantity_Returned_to_Supplier__c == 5,rline);
        }
        
        List<Inventory_Transaction__c> logicalITs = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :relatedReceiptlineSet];
        
        
        test.stopTest();
        
        system.assert(logicalITs.size() == 1, logicalITs);
        system.assert(logicalITs[0].Type__c == 'Logical Purchase Order Return', logicalITs);
    }
    
     
    
    /*static testMethod void dropShipforRMAReplacementwithRTV_twostep_fully_putaway(){
        
        ReceivingDocumentServiceTest.setupDropShipAdvanced();
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{ Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,
            Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, Shipment__c.sObjectType, Shipment_Line__c.sObjectType };
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        List<Stock_Movement_Rule_Settings__c> smrsList = ReceivingDocumentServiceTest.fuel.smrsList;
        List<Stock_Movement_Rule__c> smrs = ReceivingDocumentServiceTest.fuel.stockMovementRuleList;
        update new Location__c(Id=ReceivingDocumentServiceTest.fuel.location3.Id,Bin_Tracked__c=false);
        update new Item__c(Id=ReceivingDocumentServiceTest.fuel.itemList[0].Id,Item_Attribute__c=null, Stocking_UOM__c = ReceivingDocumentServiceTest.fuel.uomList[8].Id);
        update new Item__c(Id=ReceivingDocumentServiceTest.fuel.itemList[5].Id,Item_Attribute__c=null, Stocking_UOM__c = ReceivingDocumentServiceTest.fuel.uomList[8].Id);
        update new Facility__c(Id=ReceivingDocumentServiceTest.fuel.facility2.Id,Default_Purchasing_Delivery_Location__c=ReceivingDocumentServiceTest.fuel.location2.Id, RMA_Receipt_Routing__c = 'Inspect');
        
        Purchase_Order_Line__c poline1 = new Purchase_Order_Line__c();
        poLine1.Company__c = ReceivingDocumentServiceTest.fuel.company.Id;
        poLine1.Purchase_Order__c = ReceivingDocumentServiceTest.po.Id;
        poLine1.Item__c = ReceivingDocumentServiceTest.fuel.itemList[5].Id;
        poLine1.Order_Quantity__c = ReceivingDocumentServiceTest.fuel.salesOrderLines[1].Quantity_Ordered__c;
        poLine1.Unit_Price__c = 12;
        poLine1.Description__c = ReceivingDocumentServiceTest.fuel.itemList[5].Description__c;
        poLine1.Purchase_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[5].Purchasing_UOM__c;
        poLine1.Need_Date__c = System.today() + 7;
        poLine1.Delivery_Facility__c = ReceivingDocumentServiceTest.fuel.facility2.Id;
        poLine1.Delivery_Location__c = ReceivingDocumentServiceTest.fuel.location2.Id;
        poLine1.Supplier__c = ReceivingDocumentServiceTest.fuel.supplier.Id;
        poLine1.Line__c = 2;
        poLine1.Sales_Order_Line__c = ReceivingDocumentServiceTest.fuel.salesOrderLines[1].Id;
        poLine1.Putaway_Location__c = ReceivingDocumentServiceTest.fuel.location2.Id;
        poLine1.Type__c = 'Goods';
        poLine1.Quantity_Received__c = 0;
        //poLine1.Quantity_Uninvoiced__c = ReceivingDocumentServiceTest.fuel.salesOrderLines[1].Quantity_Ordered__c;
        // Contracted, Contract Line
        insert poLine1;
        
        SKID__c poSupplySkid1 = new SKID__c();
        poSupplySkid1.Type__c = SkidService2.SKID_TYPE_TO_SUPPLY;
        poSupplySkid1.Item__c = ReceivingDocumentServiceTest.fuel.itemList[5].Id;
        poSupplySkid1.Location__c = ReceivingDocumentServiceTest.fuel.location2.Id;
        poSupplySkid1.Purchase_Order_Line__c = poLine1.Id;
        poSupplySkid1.Company__c = ReceivingDocumentServiceTest.po.Company__c;
        insert poSupplySkid1;
        
        update new Purchase_Order__c(Id=ReceivingDocumentServiceTest.po.Id,Approval_Status__c = 'Approved');
        
        
        ASN__c asn = new ASN__c(
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Supplier__c = ReceivingDocumentServiceTest.po.Supplier__c,
            Facility__c = ReceivingDocumentServiceTest.po.Delivery_Facility__c,
            FOB__c = ReceivingDocumentServiceTest.po.FOB_Term__c,
            Status__c = 'Draft',
            Transaction_Date__c = System.today(),
            Currency__c = TestFuel.currencyUSD.ID,
            Transaction_Type__c = 'Purchase Order ASN'
        );
        insert asn;
        ASN_Line__c asnLine = new ASN_Line__c(
            Purchase_Order__c = ReceivingDocumentServiceTest.po.Id,
            Purchase_Order_Line__c = ReceivingDocumentServiceTest.poLine.Id,
            Item__c = ReceivingDocumentServiceTest.poLine.Item__c,
            Item__r = ReceivingDocumentServiceTest.fuel.itemList[0],
            Quantity_Shipped__c = 100,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = asn.Company__c,
            Supplier__c = asn.Supplier__c,
            Is_Changed__c = true
        );
        insert asnLine;
        
        ASN_Line__c asnLine1 = new ASN_Line__c(
            Purchase_Order__c = ReceivingDocumentServiceTest.po.Id,
            Purchase_Order_Line__c = poLine1.Id,
            Item__c = poLine1.Item__c,
            Item__r = ReceivingDocumentServiceTest.fuel.itemList[5],
            Quantity_Shipped__c = 15,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = asn.Company__c,
            Supplier__c = asn.Supplier__c,
            Is_Changed__c = true
        );
        insert asnLine1;
        
        insert new SKID__c(
            ASN_Line__c = asnLine.Id,
            Location__c = asnLine.Location__c,
            Type__c = 'In-Transit',
            Item__c = asnLine.Item__c,
            Quantity__c = 100,
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );
        
        insert new SKID__c(
            ASN_Line__c = asnLine1.Id,
            Location__c = asnLine1.Location__c,
            Type__c = 'In-Transit',
            Item__c = asnLine1.Item__c,
            Quantity__c = 15,
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Stocking_UOM__c = asnLine1.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine1.Item__r.Stocking_UOM__c
        );
        
        JsonResult result = ASNService.confirmASN(asn);
        System.assert(result.success,result);
        Sales_Order__c so = ReceivingDocumentServiceTest.salesOrder;
        Sales_Order_Line__c soline = ReceivingDocumentServiceTest.salesOrderLines[0];
        Sales_Order_Line__c soline1 = ReceivingDocumentServiceTest.salesOrderLines[1];
        
        
        
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Sales_Order__c>{so});
        setCon.setSelected(new List<Sales_Order__c>{so});
        
        SalesOrderRMAExt soRMAExt = new SalesOrderRMAExt(setCon);
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        msgList = ApexPages.getMessages(); 
        System.assert(msgList.size() == 0, msgList);

        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
        // SalesOrderRMAExt.SalesOrderLineWrapper
        //so.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        
        JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines(so.id);

        for (SalesOrderRMAExt.SalesOrderLineWrapper obj : (List<SalesOrderRMAExt.SalesOrderLineWrapper>) rmaLinesResult.records){
            System.assert(obj.soLine.Related_Sales_Order_Line__c != null, obj.soLine);
            if(obj.soLine.Product__c == ReceivingDocumentServiceTest.fuel.product.Id){
                obj.soLine.Quantity_Ordered__c = -10;
                obj.soLine.Returned_To_Vendor__c = true;
                obj.soLine.Line__c = 1;
                obj.soLine.Allowances__c =0;
                obj.soLine.Freight_Allowance__c =0;
                obj.soLine.Discount_Percent__c =0;
                obj.soLine.Off_Invoice_Rate__c = 0;
                solList.add( obj.soLine);
            }
            else{
                obj.soLine.Quantity_Ordered__c = -2;
                obj.soLine.Line__c = 2;
                obj.soLine.Allowances__c =0;
                obj.soLine.Freight_Allowance__c =0;
                obj.soLine.Discount_Percent__c =0;
                obj.soLine.Off_Invoice_Rate__c = 0;
                solList.add( obj.soLine);
            }
                
            
        }
        System.assertEquals(2, solList.size());
        Sales_order__c header = (Sales_Order__c) SalesOrderRMAExt.getSODetails(so.id).records[0];
        system.assert(header != null, 'Expecting RMA Header to not be null');
        header.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 20  queries or less. Actual: '+Limits.getQueries()); 
        JsonResult rma = SalesOrderRMAExt.createRMA(solList, header, new List<String>());
        system.assert(  Limits.getQueries() <= 100, ' Before create RMA 50  queries or less. Actual: '+Limits.getQueries()); 

        //Sales_Order_Line__c[] solines = [select Id, Sales_Order__r.Type__c,Returned_To_Vendor__c, Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
         //                                from Sales_Order_Line__c];
                                         
        Sales_Order_Line__c[] rmaLines = [select Id, Sales_Order__r.Type__c,Returned_To_Vendor__c, Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];//SO_TYPE_RMA_REPLACEMENT
        
        system.assert(rmaLines.size() == 4, rmaLines);//replacement line creates a regular so line too.
        Boolean negativeQty = false;
        Boolean positiveQty = false;
        for (Sales_order_Line__c sol : rmaLines){
            system.assert(sol.Related_Sales_Order_Line__c != null);
            System.assertEquals('Draft', sol.Status__c);
            if(sol.Quantity_Ordered__c < 0){
                negativeQty = true;
            }
            if(sol.Quantity_Ordered__c > 0){
                positiveQty = true;
            }
            
        }
        System.assert(positiveQty == true && negativeQty == true, rmaLines + 'Expecting both negative qty and positive qty');
        
        Sales_order__c soRMA = rmaLines[0].Sales_Order__r;
        System.assertEquals('Draft', soRMA.Status__c);
        System.assert(soRMA.Related_Sales_Order__c != null);
        //delete configList;
        System.debug(loggingLevel.Error, '*** Before release query limit: ' + Limits.getQueries());
        System.debug( LoggingLevel.INFO, 'Before Release queries : '+ Limits.getQueries() ); 
        system.assert(  Limits.getQueries() <= 72, ' expected TestData to use 50  queries or less. Actual: '+Limits.getQueries()); 
        new SalesOrderService().plan(soRMA.id);
        system.assert(  Limits.getQueries() <= 80, ' expected TestData to use 80  queries or less. Actual: '+Limits.getQueries()); 
        System.debug( LoggingLevel.INFO, 'Before Release queries : '+ Limits.getQueries() ); 
        rmaLines = [select Id, Has_Exceptions__c, Quantity_Fulfilled__c, Sales_Order__r.Has_Exceptions__c, Sales_Order__r.Type__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];
        System.debug(loggingLevel.Error, '*** after release query limit: ' + Limits.getQueries());                                 
        for (Sales_order_Line__c sol : rmaLines){
            //System.assertEquals('Open', sol.Status__c, sol); //Since trigger is disabled the SO status will not be open
            system.assertEquals(false, sol.Has_Exceptions__c, ExceptionService.fetchExceptionTasks(new set<Id>{sol.id}));
        }

        //for(Configuration__c config: configList) {
        //    config.Id = null;
        //}
        Test.startTest();
        //insert configList;
        ReceivingWorkBenchExt.setGridConfig('RMA' , ReceivingDocumentServiceTest.fuel.facility2.id);
        
        //Create ASN with inTransit SKID       
       
        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Type__c, Currency__c, Customer__c, Ship_From_Location__r.Facility__c  from Sales_Order__c where Id =:soRMA.Id]; 
        
        //Since the trigger is disabled we have to manual set the SO status to Open
        queriedSO.Status__c = 'Open';
        update queriedSO;

        String docnum = queriedSO.Id;
        String facilityId = queriedSO.Ship_From_Location__r.Facility__c;
        String customerFilter = queriedSO.Customer__c;
        ID currencyfilter = queriedSO.Currency__c;
        JSONResult jsonresult = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
             
        //test.startTest();
        //Now Search for this ASN on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('RMA');
        ReceivingWorkBenchExt.refreshTrackedAttr(ReceivingDocumentServiceTest.fuel.Location, ReceivingDocumentServiceTest.fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('RMA');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, docnum, customerFilter, currencyfilter, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total == 2, searchresult);
        
        //Manage Receive        
         
        List<Sales_Order_Line__c> newSOLinelist = [Select Id, Ship_From_Location__r.Facility__c, Quantity_Ordered__c, Sales_Order__r.Customer__c, Sales_Order__r.Currency__c,
                                             Sales_Order__r.Status__c, Sales_Order__r.Name,Sales_Order__r.Type__c, Product__r.Item__r.Name, Status__c 
                                            from Sales_Order_Line__c where Sales_Order__c =:queriedSO.Id];
        system.assert(newSOLinelist.size() == 4, newSOLinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,ReceivingDocumentServiceTest.fuel.facility2.Id,null,'RMA');
        List<Id> solineIds = new List<Id>();
        for(Sales_Order_Line__c line:newSOLinelist){
            if(facilityId ==null)
                facilityId = line.Ship_From_Location__r.Facility__c;
            system.assert(line.Status__c == 'Open', newSOLinelist);
            system.assert(line.Sales_Order__r.Customer__c == customerFilter, newSOLinelist);            
            system.assert(line.Sales_Order__c == docnum, newSOLinelist); 
            system.assert(line.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_RMA_REPLACEMENT, newSOLinelist); 
            system.assert(line.Sales_Order__r.Status__c == 'Open', newSOLinelist); 
            solineIds.add(line.id);
        }
        
        getListresult = ReceivingWorkBenchExt.getList(solineIds, 'RMA');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total == 2, getListresult.total);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(solineIds, 'RMA', TestFuel.currencyUSD.ID);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(solineIds), new set<String>{'Sales_Order_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == ReceivingDocumentServiceTest.fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                    skid.Packaging_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
                }
                else{
                    skid.Quantity__c = 2;
                    skid.Packaging_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
                }
                skid.Packaging_UOM__r.Package_Class__r = null;
                
    }
        }
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        //test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
    
        List<Fulfillment__c> fulfillmentrecs = [Select Id, Status__c, Quantity__c, Sales_Order__c,Sales_Order_Line__r.Product__c from Fulfillment__c where Sales_Order__c =:queriedSO.Id];
        
        system.assert(fulfillmentrecs.size() == 2, fulfillmentrecs);    
        
        for(Fulfillment__c rec:fulfillmentrecs){
            if(rec.Sales_Order_Line__r.Product__c == ReceivingDocumentServiceTest.fuel.product.Id)
                system.assert(rec.Quantity__c == -5, rec);
            else if(rec.Sales_Order_Line__r.Product__c == ReceivingDocumentServiceTest.fuel.product2.Id)
                system.assert(rec.Quantity__c == -2, rec);
        }
                                        
        
                                    
        Set<ID> receiptlineSet = new Set<ID>();
        Set<ID> relatedReceiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Status__c, Item__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Sales_Order__c =:queriedSO.Id and Sales_Order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c == null);
            system.assert(rcptline.Sales_Order__c == queriedSO.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'Logical RMA Receipt',rcptline.Receiving_Document__r.Type__c);
            if(rcptline.Item__c == ReceivingDocumentServiceTest.fuel.itemList[0].ID){
                system.assert(rcptline.Quantity_Received__c == 5, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 5, rcptline.Quantity_Still_Due_For_Putaway__c);
            }
            else{
                system.assert(rcptline.Quantity_Received__c == 2, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 2, rcptline.Quantity_Still_Due_For_Putaway__c);
            }
             
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'Logical RMA Receipt', rcptline);            
        }
    
        //Putaway
        
        PutawayReceiptsExt putawayext = new PutawayReceiptsExt();
        PutawayReceiptsExt.setGridConfig('RMA');
        
        putawayext.getreceiptLinesConfigJson();
        //Create ASN with inTransit SKID       
       
        Receiving_Document__c queriedrd = [Select Id, Name, Transaction_Currency__c  from Receiving_Document__c where Id =:receiptlines[0].Receiving_Document__c]; 
        String docnum1 = queriedrd.Name;
       //   String currencyfilter1 = queriedrd.Transaction_Currency__c;
        
        List<Receipt_Line__c> newreceiptlinelist = [Select Id,Receiving_Document__r.Name from Receipt_Line__c where Receiving_Document__c =:queriedrd.Id];
        system.assert(newreceiptlinelist.size() == 2, newreceiptlinelist);
        
        List<Id> rlineIds = new List<Id>();
        for(Receipt_Line__c line:newreceiptlinelist){
            rlineIds.add(line.id);
        }
        
        JSONResult resultforputaway = new JSONResult();
        JSONResult putawaysearchresult = new JSONResult();
        //JSONResult putawaysearchresult1 = new JSONResult();
        //JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult1 = new JSONResult();
        JSONResult receiveLinesresult1 = new JSONResult();
        JSONResult rdocresult1 = new JSONResult();
             
        //test.startTest();
       
        PutawayReceiptsExt putawaycon = new PutawayReceiptsExt();
        Map<String,String> configMap1 = new Map<String,String>();
        
        //String headerfieldlist1 = putawaycon.getrdHeaderFieldList();
        PutawayReceiptsExt.refreshTrackedAttr(ReceivingDocumentServiceTest.fuel.Location, ReceivingDocumentServiceTest.fuel.itemList[4]);
        String LinesFieldList;
        LinesFieldList = PutawayReceiptsExt.setFieldConfig('RMA');
        
        String receivingLinesConfigJson1 = configMap1.get('config');
        String receivingLinesFieldListJson1 = configMap1.get('fieldList');
        putawaysearchresult = PutawayReceiptsExt.getLinesToReceive(null, null, null, null, queriedrd.Id,'RMA');
        system.assertEquals(putawaysearchresult.success, true);
        system.assert(putawaysearchresult.total >0, putawaysearchresult);
        
        //Manage Putaway 
        
        getListresult1 = PutawayReceiptsExt.getList(rlineIds, 'RMA');
        system.assert(getListresult1.success == true, getListresult1);
        system.assert(getListresult1.total >0);
        
        //Create RD with some info and Receive
        rdocresult1 = PutawayReceiptsExt.getrdDetails(rlineIds, 'RMA');
        
        list<ReceivingWrapper> rwrapperlist1 = new list<ReceivingWrapper>();
        rwrapperlist1 = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(rlineIds), new set<String>{'Receipt_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist1){
            
            Receipt_Line__c receiptobj = (Receipt_Line__c)rw.rl;
            receiptobj.PutAway_Location__c = ReceivingDocumentServiceTest.fuel.location3.Id;
            receiptobj.PutAway_Location__r = ReceivingDocumentServiceTest.fuel.location3;
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == ReceivingDocumentServiceTest.fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                    skid.Location__c = ReceivingDocumentServiceTest.fuel.location3.Id;
                    rw.putawayType = 'Inventory';
                    skid.Packaging_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
                }
                else if(skid.Item__c == ReceivingDocumentServiceTest.fuel.itemList[5].ID){
                    skid.Quantity__c = 2;
                    skid.Location__c = ReceivingDocumentServiceTest.fuel.location3.Id;
                    rw.putawayType = 'Scrap';
                    skid.Packaging_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
                }
                    
                skid.Packaging_UOM__r.Package_Class__r = null;
            }
        }
        
        Receiving_Document__c rdoc1 = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        ReceivingDocumentServiceV2.skipPutaway = false;
        receiveLinesresult1 = PutawayReceiptsExt.putaway(rwrapperlist1, null, null, rdoc1, null,'RMA',false);
        delete configList;
        test.stopTest();
        system.assert(receiveLinesresult1.success == true, receiveLinesresult1);
        //Also check Quantity_Fulfilled__c on updated solines.                              
        Set<ID> receiptlineSet1 = new Set<ID>();
        List<Receipt_Line__c> receiptlines1 = [Select Id, Quantity_Still_Due_For_Putaway__c, Item__c, Quantity_Received__c, Quantity_To_Stock__c, Receiving_Document__r.Transaction_Type__c
                                               from Receipt_Line__c where Id =: rlineIds];
        system.assert(receiptlines1.size() == 2, receiptlines1);
        for(Receipt_Line__c rcptline: receiptlines1){
            receiptlineSet1.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c ==rcptline.Quantity_Received__c);
            system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 0, rcptline);
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'Logical RMA Receipt', rcptline.Receiving_Document__r.Transaction_Type__c);            
        }
        system.assert(receiptlineSet1.size() == 2,receiptlineSet1.size());       
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Inventory_Change__c,Inventory_Change__r.Type__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :rlineIds];
        
        system.assert(itlist.size() == 2, itlist);
        Set<Id> inventorychangeset = new Set<Id>();
        Boolean invflag, scrapflag;
        for(Inventory_Transaction__c it: itlist){

            if (it.Inventory_Change__r.Type__c == 'Logical RMA Receipt') {
                invflag = true;
            }
            if(it.Inventory_Change__r.Type__c == 'RMA Scrap'){
                scrapflag = true;
            }
            
            inventorychangeset.add(it.Inventory_Change__c);
        }
        system.assert(inventorychangeset.size() ==2);//one for scrap and one for inventory
        system.assert(invflag ==true && scrapflag == true);
        
        List<Receipt_Line__c> returnReceiptlines = [Select Id, Status__c, Item__c, Quantity_Returned_To_Supplier__c, Quantity_Returned_To_Supplier_For_Credit__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Related_Receipt_Line__c IN :receiptlineSet1];
        
        system.assert(returnReceiptlines.size() == 1, returnReceiptlines[0].Receiving_Document__r);
        
        for(Receipt_Line__c rline: returnReceiptlines){
            relatedReceiptlineSet.add(rline.Id);
            system.assert(rline.Receiving_Document__r.Type__c == 'Logical Purchase Order Return');
            system.assert(rline.Quantity_Returned_To_Supplier_For_Credit__c == 0,rline);
            system.assert(rline.Quantity_Returned_To_Supplier__c == 5,rline);
        }
        
        List<Inventory_Transaction__c> logicalITs = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :relatedReceiptlineSet];
        
        
        system.assert(logicalITs.size() == 1, logicalITs);
        system.assert(logicalITs[0].Type__c == 'Logical Purchase Order Return', logicalITs);
    }*/
    
    
    
    static testMethod void dropShipforRMAReplacementwithRTV_twostep_partial_putway(){
        if(KSE.checkTestDispatch()){return;}        
        
        ReceivingDocumentServiceTest.setupDropShipAdvanced();
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{ Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,
            Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, Shipment__c.sObjectType, Shipment_Line__c.sObjectType };
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        List<Stock_Movement_Rule_Settings__c> smrsList = ReceivingDocumentServiceTest.fuel.smrsList;
        List<Stock_Movement_Rule__c> smrs = ReceivingDocumentServiceTest.fuel.stockMovementRuleList;
        update new Location__c(Id=ReceivingDocumentServiceTest.fuel.location3.Id,Bin_Tracked__c=false);
        update new Item__c(Id=ReceivingDocumentServiceTest.fuel.itemList[0].Id,Item_Attribute__c=null, Stocking_UOM__c = ReceivingDocumentServiceTest.fuel.uomList[8].Id);
        update new Item__c(Id=ReceivingDocumentServiceTest.fuel.itemList[5].Id,Item_Attribute__c=null, Stocking_UOM__c = ReceivingDocumentServiceTest.fuel.uomList[8].Id);
        update new Facility__c(Id=ReceivingDocumentServiceTest.fuel.facility2.Id,Default_Purchasing_Delivery_Location__c=ReceivingDocumentServiceTest.fuel.location2.Id, RMA_Receipt_Routing__c = 'Inspect');
        
        Purchase_Order_Line__c poline1 = new Purchase_Order_Line__c();
        poLine1.Company__c = ReceivingDocumentServiceTest.fuel.company.Id;
        poLine1.Purchase_Order__c = ReceivingDocumentServiceTest.po.Id;
        poLine1.Item__c = ReceivingDocumentServiceTest.fuel.itemList[5].Id;
        poLine1.Order_Quantity__c = ReceivingDocumentServiceTest.fuel.salesOrderLines[1].Quantity_Ordered__c;
        poLine1.Unit_Price__c = 12;
        poLine1.Description__c = ReceivingDocumentServiceTest.fuel.itemList[5].Description__c;
        poLine1.Purchase_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[5].Purchasing_UOM__c;
        poLine1.Need_Date__c = System.today() + 7;
        poLine1.Delivery_Facility__c = ReceivingDocumentServiceTest.fuel.facility2.Id;
        poLine1.Delivery_Location__c = ReceivingDocumentServiceTest.fuel.location2.Id;
        poLine1.Supplier__c = ReceivingDocumentServiceTest.fuel.supplier.Id;
        poLine1.Line__c = 2;
        poLine1.Sales_Order_Line__c = ReceivingDocumentServiceTest.fuel.salesOrderLines[1].Id;
        poLine1.Putaway_Location__c = ReceivingDocumentServiceTest.fuel.location2.Id;
        poLine1.Type__c = 'Goods';
        poLine1.Quantity_Received__c = 0;
        //poLine1.Quantity_Uninvoiced__c = ReceivingDocumentServiceTest.fuel.salesOrderLines[1].Quantity_Ordered__c;
        // Contracted, Contract Line
        insert poLine1;
        
        SKID__c poSupplySkid1 = new SKID__c();
        poSupplySkid1.Type__c = SkidService2.SKID_TYPE_TO_SUPPLY;
        poSupplySkid1.Item__c = ReceivingDocumentServiceTest.fuel.itemList[5].Id;
        poSupplySkid1.Location__c = ReceivingDocumentServiceTest.fuel.location2.Id;
        poSupplySkid1.Purchase_Order_Line__c = poLine1.Id;
        poSupplySkid1.Company__c = ReceivingDocumentServiceTest.po.Company__c;
        insert poSupplySkid1;
        
        update new Purchase_Order__c(Id=ReceivingDocumentServiceTest.po.Id,Approval_Status__c = 'Approved');
        
        ASN__c asn = new ASN__c(
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Supplier__c = ReceivingDocumentServiceTest.po.Supplier__c,
            Facility__c = ReceivingDocumentServiceTest.po.Delivery_Facility__c,
            FOB__c = ReceivingDocumentServiceTest.po.FOB_Term__c,
            Status__c = 'Draft',
            Transaction_Date__c = System.today(),
            Currency__c = TestFuel.currencyUSD.ID,
            Transaction_Type__c = 'Purchase Order ASN'
        );
        insert asn;
        ASN_Line__c asnLine = new ASN_Line__c(
            Purchase_Order__c = ReceivingDocumentServiceTest.po.Id,
            Purchase_Order_Line__c = ReceivingDocumentServiceTest.poLine.Id,
            Item__c = ReceivingDocumentServiceTest.poLine.Item__c,
            Item__r = ReceivingDocumentServiceTest.fuel.itemList[0],
            Quantity_Shipped__c = 100,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = asn.Company__c,
            Supplier__c = asn.Supplier__c,
            Is_Changed__c = true
        );
        insert asnLine;
        
        ASN_Line__c asnLine1 = new ASN_Line__c(
            Purchase_Order__c = ReceivingDocumentServiceTest.po.Id,
            Purchase_Order_Line__c = poLine1.Id,
            Item__c = poLine1.Item__c,
            Item__r = ReceivingDocumentServiceTest.fuel.itemList[5],
            Quantity_Shipped__c = 15,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = asn.Company__c,
            Supplier__c = asn.Supplier__c,
            Is_Changed__c = true
        );
        insert asnLine1;
        
        insert new SKID__c(
            ASN_Line__c = asnLine.Id,
            Location__c = asnLine.Location__c,
            Type__c = 'Draft In-Transit',
            Item__c = asnLine.Item__c,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );
        
        insert new SKID__c(
            ASN_Line__c = asnLine1.Id,
            Location__c = asnLine1.Location__c,
            Type__c = 'Draft In-Transit',
            Item__c = asnLine1.Item__c,
            Quantity__c = 15,
            Quantity_Stocking_UOM__c = 15,
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Stocking_UOM__c = asnLine1.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine1.Item__r.Stocking_UOM__c
        );
        
        JsonResult result = ASNService.confirmASN(asn);
        System.assert(result.success,result);
        Sales_Order__c so = ReceivingDocumentServiceTest.salesOrder;
        Sales_Order_Line__c soline = ReceivingDocumentServiceTest.salesOrderLines[0];
        Sales_Order_Line__c soline1 = ReceivingDocumentServiceTest.salesOrderLines[1];
        
        
        
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Sales_Order__c>{so});
        setCon.setSelected(new List<Sales_Order__c>{so});
        
        SalesOrderRMAExt soRMAExt = new SalesOrderRMAExt(setCon);
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        msgList = ApexPages.getMessages(); 
        System.assert(msgList.size() == 0, msgList);

        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
        // SalesOrderRMAExt.SalesOrderLineWrapper
        //so.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        
        JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines(so.id);

        for (SalesOrderRMAExt.SalesOrderLineWrapper obj : (List<SalesOrderRMAExt.SalesOrderLineWrapper>) rmaLinesResult.records){
            System.assert(obj.soLine.Related_Sales_Order_Line__c != null, obj.soLine);
            if(obj.soLine.Product__c == ReceivingDocumentServiceTest.fuel.product.Id){
                obj.soLine.Quantity_Ordered__c = -10;
                obj.soLine.Returned_To_Vendor__c = true;
                obj.soLine.Line__c = 1;
                obj.soLine.Allowances__c =0;
                obj.soLine.Freight_Allowance__c =0;
                obj.soLine.Discount_Percent__c =0;
                obj.soLine.Off_Invoice_Rate__c = 0;
                solList.add( obj.soLine);
            }
            else{
                obj.soLine.Quantity_Ordered__c = -2;
                obj.soLine.Line__c = 2;
                obj.soLine.Allowances__c =0;
                obj.soLine.Freight_Allowance__c =0;
                obj.soLine.Discount_Percent__c =0;
                obj.soLine.Off_Invoice_Rate__c = 0;
                solList.add( obj.soLine);
            }
                
            
        }
        System.assertEquals(2, solList.size());
        Sales_order__c header = (Sales_Order__c) SalesOrderRMAExt.getSODetails(so.id).records[0];
        system.assert(header != null, 'Expecting RMA Header to not be null');
        header.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 20  queries or less. Actual: '+Limits.getQueries()); 
        JsonResult rma = SalesOrderRMAExt.createRMA(solList, header, new List<String>());
        system.assert(  Limits.getQueries() <= 100, ' Before create RMA 50  queries or less. Actual: '+Limits.getQueries()); 

        //Sales_Order_Line__c[] solines = [select Id, Sales_Order__r.Type__c,Returned_To_Vendor__c, Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
         //                                from Sales_Order_Line__c];
                                         
        Sales_Order_Line__c[] rmaLines = [select Id, Sales_Order__r.Type__c,Returned_To_Vendor__c, Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];//SO_TYPE_RMA_REPLACEMENT
        
        system.assert(rmaLines.size() == 4, rmaLines);//replacement line creates a regular so line too.
        Boolean negativeQty = false;
        Boolean positiveQty = false;
        for (Sales_order_Line__c sol : rmaLines){
            system.assert(sol.Related_Sales_Order_Line__c != null);
            System.assertEquals('Draft', sol.Status__c);
            if(sol.Quantity_Ordered__c < 0){
                negativeQty = true;
            }
            if(sol.Quantity_Ordered__c > 0){
                positiveQty = true;
            }
            
        }
        System.assert(positiveQty == true && negativeQty == true, rmaLines + 'Expecting both negative qty and positive qty');
        
        Sales_order__c soRMA = rmaLines[0].Sales_Order__r;
        System.assertEquals('Draft', soRMA.Status__c);
        System.assert(soRMA.Related_Sales_Order__c != null);
        
        Test.startTest();
        System.debug( LoggingLevel.INFO, 'Before Release queries : '+ Limits.getQueries() ); 
        system.assert(  Limits.getQueries() <= 72, ' expected TestData to use 50  queries or less. Actual: '+Limits.getQueries()); 
        new SalesOrderService().plan(soRMA.id);
        system.assert(  Limits.getQueries() <= 85, ' expected TestData to use 78  queries or less. Actual: '+Limits.getQueries()); 
        System.debug( LoggingLevel.INFO, 'Before Release queries : '+ Limits.getQueries() ); 
        rmaLines = [select Id, Has_Exceptions__c, Quantity_Fulfilled__c, Sales_Order__r.Has_Exceptions__c, Sales_Order__r.Type__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];

        for (Sales_order_Line__c sol : rmaLines){
            System.assertEquals('Open', sol.Status__c, sol);
            system.assertEquals(false, sol.Has_Exceptions__c, ExceptionService.fetchExceptionTasks(new set<Id>{sol.id}));
        }
        
        ReceivingWorkBenchExt.setGridConfig('RMA' , ReceivingDocumentServiceTest.fuel.facility2.id);
        
        //Create ASN with inTransit SKID       
       
        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Type__c, Currency__c, Customer__c, Ship_From_Location__r.Facility__c  from Sales_Order__c where Id =:soRMA.Id]; 
        
        //Since Trigger is disabled we have to manually update the status of SO to open
        queriedSO.Status__c = 'Open';
        update queriedSO;
        
        String docnum = queriedSO.Id;
        String facilityId = queriedSO.Ship_From_Location__r.Facility__c;
        String customerFilter = queriedSO.Customer__c;
        ID currencyfilter = queriedSO.Currency__c;
        JSONResult jsonresult = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
             
        //test.startTest();
        //Now Search for this ASN on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('RMA');
        ReceivingWorkBenchExt.refreshTrackedAttr(ReceivingDocumentServiceTest.fuel.Location, ReceivingDocumentServiceTest.fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('RMA');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, docnum, customerFilter, currencyfilter, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total == 2, searchresult);
        
        //Manage Receive        
         
        List<Sales_Order_Line__c> newSOLinelist = [Select Id, Ship_From_Location__r.Facility__c, Quantity_Ordered__c, Sales_Order__r.Customer__c, Sales_Order__r.Currency__c,
                                            Sales_Order__r.Status__c, Sales_Order__r.Name,Sales_Order__r.Type__c, Product__r.Item__r.Name, Status__c 
                                            from Sales_Order_Line__c where Sales_Order__c =:queriedSO.Id];
        system.assert(newSOLinelist.size() == 4, newSOLinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,ReceivingDocumentServiceTest.fuel.facility2.Id,null,'RMA');
        List<Id> solineIds = new List<Id>();
        for(Sales_Order_Line__c line:newSOLinelist){
            if(facilityId ==null)
                facilityId = line.Ship_From_Location__r.Facility__c;
            system.assert(line.Status__c == 'Open', newSOLinelist);
            system.assert(line.Sales_Order__r.Customer__c == customerFilter, newSOLinelist);            
            system.assert(line.Sales_Order__c == docnum, newSOLinelist); 
            system.assert(line.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_RMA_REPLACEMENT, newSOLinelist); 
            system.assert(line.Sales_Order__r.Status__c == 'Open', newSOLinelist); 
            solineIds.add(line.id);
        }
        
        getListresult = ReceivingWorkBenchExt.getList(solineIds, 'RMA');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total == 2, getListresult.total);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(solineIds, 'RMA', TestFuel.currencyUSD.ID);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(solineIds), new set<String>{'Sales_Order_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == ReceivingDocumentServiceTest.fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                    skid.Packaging_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
                    
                }
                else{
                    skid.Quantity__c = 2;
                    skid.Packaging_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
                }
                skid.Quantity_Stocking_UOM__c = skid.Quantity__c ;
                skid.Packaging_UOM__r.Package_Class__r = null;
                
    }
        }
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        //test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
    
        List<Fulfillment__c> fulfillmentrecs = [Select Id, Status__c, Invoice_Ready__c, Quantity__c, Sales_Order__c,Sales_Order_Line__r.Product__c from Fulfillment__c where Sales_Order__c =:queriedSO.Id];
        
        system.assert(fulfillmentrecs.size() == 2, fulfillmentrecs);    
        
        for(Fulfillment__c rec:fulfillmentrecs){
            system.assert(rec.Invoice_Ready__c == false);
            if(rec.Sales_Order_Line__r.Product__c == ReceivingDocumentServiceTest.fuel.product.Id)
                system.assert(rec.Quantity__c == -5, rec);
            else if(rec.Sales_Order_Line__r.Product__c == ReceivingDocumentServiceTest.fuel.product2.Id)
                system.assert(rec.Quantity__c == -2, rec);
        }
                                        
        
                                    
        Set<ID> receiptlineSet = new Set<ID>();
        Set<ID> relatedReceiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Status__c, Item__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Sales_Order__c =:queriedSO.Id and Sales_Order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c == null);
            system.assert(rcptline.Sales_Order__c == queriedSO.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'Logical RMA Receipt',rcptline.Receiving_Document__r.Type__c);
            if(rcptline.Item__c == ReceivingDocumentServiceTest.fuel.itemList[0].ID){
                system.assert(rcptline.Quantity_Received__c == 5, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 5, rcptline.Quantity_Still_Due_For_Putaway__c);
            }
            else{
                system.assert(rcptline.Quantity_Received__c == 2, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 2, rcptline.Quantity_Still_Due_For_Putaway__c);
            }
             
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'Logical RMA Receipt', rcptline);            
        }
    
        //Putaway
        
        PutawayReceiptsExt putawayext = new PutawayReceiptsExt();
        PutawayReceiptsExt.setGridConfig('RMA');
        
        putawayext.getreceiptLinesConfigJson();
        //Create ASN with inTransit SKID       
       
        Receiving_Document__c queriedrd = [Select Id, Name, Transaction_Currency__c  from Receiving_Document__c where Id =:receiptlines[0].Receiving_Document__c]; 
        String docnum1 = queriedrd.Name;
       //   String currencyfilter1 = queriedrd.Transaction_Currency__c;
        
        List<Receipt_Line__c> newreceiptlinelist = [Select Id,Receiving_Document__r.Name from Receipt_Line__c where Receiving_Document__c =:queriedrd.Id];
        system.assert(newreceiptlinelist.size() == 2, newreceiptlinelist);
        
        List<Id> rlineIds = new List<Id>();
        for(Receipt_Line__c line:newreceiptlinelist){
            rlineIds.add(line.id);
        }
        
        JSONResult resultforputaway = new JSONResult();
        JSONResult putawaysearchresult = new JSONResult();
        //JSONResult putawaysearchresult1 = new JSONResult();
        //JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult1 = new JSONResult();
        JSONResult receiveLinesresult1 = new JSONResult();
        JSONResult rdocresult1 = new JSONResult();
             
        //test.startTest();
       
        PutawayReceiptsExt putawaycon = new PutawayReceiptsExt();
        Map<String,String> configMap1 = new Map<String,String>();
        
        //String headerfieldlist1 = putawaycon.getrdHeaderFieldList();
        PutawayReceiptsExt.refreshTrackedAttr(ReceivingDocumentServiceTest.fuel.Location, ReceivingDocumentServiceTest.fuel.itemList[4]);
        String LinesFieldList;
        LinesFieldList = PutawayReceiptsExt.setFieldConfig('RMA');
        
        String receivingLinesConfigJson1 = configMap1.get('config');
        String receivingLinesFieldListJson1 = configMap1.get('fieldList');
        putawaysearchresult = PutawayReceiptsExt.getLinesToReceive(null, null, null, null, queriedrd.Id,'RMA');
        system.assertEquals(putawaysearchresult.success, true);
        system.assert(putawaysearchresult.total >0, putawaysearchresult);
        
        //Manage Putaway 
        
        getListresult1 = PutawayReceiptsExt.getList(rlineIds, 'RMA');
        system.assert(getListresult1.success == true, getListresult1);
        system.assert(getListresult1.total >0);
        
        //Create RD with some info and Receive
        rdocresult1 = PutawayReceiptsExt.getrdDetails(rlineIds, 'RMA');
        
        list<ReceivingWrapper> rwrapperlist1 = new list<ReceivingWrapper>();
        rwrapperlist1 = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(rlineIds), new set<String>{'Receipt_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist1){
            
            Receipt_Line__c receiptobj = (Receipt_Line__c)rw.rl;
            receiptobj.PutAway_Location__c = ReceivingDocumentServiceTest.fuel.location3.Id;
            receiptobj.PutAway_Location__r = ReceivingDocumentServiceTest.fuel.location3;
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == ReceivingDocumentServiceTest.fuel.itemList[0].ID){
                    skid.Quantity__c = 4;
                    skid.Location__c = ReceivingDocumentServiceTest.fuel.location3.Id;
                    rw.putawayType = 'Inventory';
                    skid.Packaging_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
                }
                else if(skid.Item__c == ReceivingDocumentServiceTest.fuel.itemList[5].ID){
                    skid.Quantity__c = 2;
                    skid.Location__c = ReceivingDocumentServiceTest.fuel.location3.Id;
                    rw.putawayType = 'Scrap';
                    skid.Packaging_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
                }
                skid.Quantity_Stocking_UOM__c =  skid.Quantity__c;   
                skid.Packaging_UOM__r.Package_Class__r = null; 
            }
        }
        
        Receiving_Document__c rdoc1 = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        ReceivingDocumentServiceV2.skipPutaway = false;
        receiveLinesresult1 = PutawayReceiptsExt.putaway(rwrapperlist1, null, null, rdoc1, null,'RMA',false);
        delete configList;
        test.stopTest();
        system.assert(receiveLinesresult1.success == true, receiveLinesresult1);
        
        //Also check Quantity_Fulfilled__c on updated solines.                              
        Set<ID> receiptlineSet1 = new Set<ID>();
        List<Receipt_Line__c> receiptlines1 = [Select Id, Quantity_Still_Due_For_Putaway__c, Item__c, Quantity_Received__c, Quantity_To_Stock__c, Receiving_Document__r.Transaction_Type__c
                                               from Receipt_Line__c where Id =: rlineIds];
        system.assert(receiptlines1.size() == 2, receiptlines1);
        for(Receipt_Line__c rcptline: receiptlines1){
            receiptlineSet1.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c ==rcptline.Quantity_Received__c);
            if(rcptline.Item__c == ReceivingDocumentServiceTest.fuel.itemList[0].ID){
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 1, rcptline);
            }
            else if(rcptline.Item__c == ReceivingDocumentServiceTest.fuel.itemList[5].ID){
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 0, rcptline);
            } 
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'Logical RMA Receipt', rcptline.Receiving_Document__r.Transaction_Type__c);            
        }
        system.assert(receiptlineSet1.size() == 2,receiptlineSet1.size());       
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Inventory_Change__c,Inventory_Change__r.Type__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :rlineIds];
        
        system.assert(itlist.size() == 2, itlist);
        Set<Id> inventorychangeset = new Set<Id>();
        Boolean invflag, scrapflag;
        for(Inventory_Transaction__c it: itlist){

            if (it.Inventory_Change__r.Type__c == 'Logical RMA Receipt') {
                invflag = true;
            }
            if(it.Inventory_Change__r.Type__c == 'RMA Scrap'){
                scrapflag = true;
            }
            
            inventorychangeset.add(it.Inventory_Change__c);
        }
        system.assert(inventorychangeset.size() ==2);//one for scrap and one for inventory
        system.assert(invflag ==true && scrapflag == true);
        
        List<Receipt_Line__c> returnReceiptlines = [Select Id, Status__c, Item__c, Quantity_Returned_To_Supplier__c, Quantity_Returned_To_Supplier_For_Credit__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Related_Receipt_Line__c IN :receiptlineSet1];
        
        system.assert(returnReceiptlines.size() == 1, returnReceiptlines[0].Receiving_Document__r);
        
        for(Receipt_Line__c rline: returnReceiptlines){
            relatedReceiptlineSet.add(rline.Id);
            system.assert(rline.Receiving_Document__r.Type__c == 'Logical Purchase Order Return');
            system.assert(rline.Quantity_Returned_To_Supplier_For_Credit__c == 0,rline);
            system.assert(rline.Quantity_Returned_To_Supplier__c == 4,rline);
        }
        
        List<Inventory_Transaction__c> logicalITs = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :relatedReceiptlineSet];
        
        
        system.assert(logicalITs.size() == 1, logicalITs);
        system.assert(logicalITs[0].Type__c == 'Logical Purchase Order Return', logicalITs);
    }
    
    public static testMethod void CreateSalesOrderRMAReplacementFlowTest(){
        if(KSE.checkTestDispatch()){return;}       
        
        TestFuel fuel = new TestFuel();
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{ Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Customer__c.sObjectType,
            Shipment__c.sObjectType, Shipment_Line__c.sObjectType };
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        List<Period__c> periodList = fuel.periodList;
        List<SKID__c> skids = fuel.skids;    
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;

        Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soline = fuel.salesOrderLines[0];
        Sales_Order_Line__c soline1 = fuel.salesOrderLines[1];
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
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 92  queries or less. Actual: '+Limits.getQueries()); 
        
        
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        List<ApexPages.Message> msgList1 = ApexPages.getMessages();
        
        
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Sales_Order__c>{so});
        setCon.setSelected(new List<Sales_Order__c>{so});
        SalesOrderRMAExt soRMAExt = new SalesOrderRMAExt(setCon);
        msgList = ApexPages.getMessages();   
        System.assert(msgList.size() == 0, msgList);
        
        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
        
        
        JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines(so.id);
        
        for (SalesOrderRMAExt.SalesOrderLineWrapper obj : (List<SalesOrderRMAExt.SalesOrderLineWrapper>) rmaLinesResult.records){
            System.assert(obj.soLine.Related_Sales_Order_Line__c != null, obj.soLine);
            if(obj.soLine.Product__c == fuel.product.Id){
                obj.soLine.Quantity_Ordered__c = -10;
                obj.soLine.Returned_To_Vendor__c = false;
                obj.soLine.Fulfillment_Source__c = 'Inventory';
                solList.add( obj.soLine);
            }
            else
                obj.soLine.Quantity_Ordered__c = 0;
            
        }
        
        
        System.assertEquals(1, solList.size());
        Sales_order__c header = (Sales_Order__c) SalesOrderRMAExt.getSODetails(so.id).records[0];
        header.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        
        system.assert(header != null, 'Expecting RMA Header to not be null');
        header.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        JsonResult rma = SalesOrderRMAExt.createRMA(solList, header, new List<String>());
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 92  queries or less. Actual: '+Limits.getQueries()); 
        Sales_Order_Line__c[] rmaLines = [select Id, Sales_Order__r.Type__c,Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c 
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];
        
        system.assertEquals(2, rmaLines.size());//replacement line creates a regualr so line too.
        Boolean negativeQty = false;
        Boolean positiveQty = false;
        for (Sales_order_Line__c sol : rmaLines){
            system.assert(sol.Related_Sales_Order_Line__c != null);
            System.assertEquals('Draft', sol.Status__c);
            //System.assert(sol.Quantity_Ordered__c < 0, sol.Quantity_Ordered__c + 'Expecting negative qty');
            if(sol.Quantity_Ordered__c < 0){
                negativeQty = true;
            }
            if(sol.Quantity_Ordered__c > 0){
                positiveQty = true;
            }
        }
        system.assert(negativeQty == true && positiveQty == true);
        Sales_order__c soRMA = rmaLines[0].Sales_Order__r;
        System.assertEquals('Draft', soRMA.Status__c);
        System.assert(soRMA.Related_Sales_Order__c != null);

        system.assert(  Limits.getQueries() <= 92, ' Before plan RMA SO 92  queries or less. Actual: '+Limits.getQueries()); 
        new SalesOrderService().plan(soRMA.id);
        delete configList;
        Test.startTest();

        rmaLines = [select Id, Has_Exceptions__c, Quantity_Fulfilled__c, Sales_Order__r.Has_Exceptions__c, Sales_Order__r.Type__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];
        system.assert(rmaLines.size() ==2,rmaLines);
        
        for (Sales_order_Line__c sol : rmaLines){
            System.assertEquals('Open', sol.Status__c, sol);
            system.assertEquals(false, sol.Has_Exceptions__c, ExceptionService.fetchExceptionTasks(new set<Id>{sol.id}));
        }
        
        shlListforRMA =  [select id,Name, Quantity_Planned__c, Quantity_Allocated__c, Quantity_Picked__c, Quantity_Shipped__c,
            Item__r.Item_Attribute__c, Location__c, Location__r.Name,
            Product__r.Item__r.Item_Attribute__r.Serial_Number__c,
            Shipment__c, Shipment__r.Status__c, Shipment__r.Finalized__c, Shipment__r.Date_Shipped__c, Shipment__r.Tracking_Id__c,
            Sales_Order__c, Sales_Order__r.Status__c, Shipment__r.Company__r.Serial_Control__c,
            Sales_Order_Line__r.Quantity_Ordered__c, Sales_Order_Line__r.Quantity_Allocated__c, Sales_Order_Line__r.Quantity_Shipped__c,
                (Select id, Quantity_Allocated__c, Shipment_line__c, Sales_order_line__c, Location__c, Location__r.Name, Name, Is_Demand__c, Quantity__c, Type__c, Item__c from Skids__r),
                (Select id, 
                    Quantity__c, Type__c, Net_Quantity__c, Item__c,
                    From_Skid__r.Quantity__c, From_SKID__c, From_Facility__c, From_Location__c, From_Skid__r.Location__c, From_Location__r.Name,
                    To_Skid__r.Quantity__c, To_SKID__c, To_Facility__c, To_Location__c, To_Skid__r.Location__c, To_Location__r.Name
                    from Inventory_Transactions__r where Reversed__c = false)           
            from Shipment_Line__c where Sales_Order__c = :soRMA.id ORDER BY Id ASC];

        if (shlListforRMA.size() > 0){
            shipmentforRMA = shlListforRMA[0].Shipment__r;
            soRMA = shlListforRMA[0].Sales_Order__r;
        }
        system.assert(shlListforRMA.size() > 0);

        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipmentforRMA.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Location__c == fuel.location3.Id) sw.skid.Input_Quantity__c = 5;
                else sw.skid.Input_Quantity__c = 0;
                sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
            }
        }
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipmentforRMA.Id }, 'planpick'));
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            wrapper.serialWrappers[0].skid.Quantity_to_Issue__c = 5;
            wrapper.serialWrappers[0].skid.Input_Quantity__c = 5;
            wrapper.serialWrappers[0].skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }
        ShipmentInventoryService.plan(wrappers);

        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipmentforRMA.Id }, 'pick'));
        wrappers = ShipmentInventoryService.getInventoryForPick(shipmentLines.values());
        for (LineWrapper wrapper:wrappers) {
            wrapper.line = shipmentLines.get(wrapper.line.Id);
            wrapper.header = wrapper.line.getSObject('Shipment__r');
            wrapper.serialWrappers[0].skid.Quantity_to_Issue__c = 5;
            wrapper.serialWrappers[0].skid.Input_Quantity__c = 5;
            wrapper.serialWrappers[0].skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
        }
        ShipmentInventoryService.pick(wrappers);
        
        ShipmentManageDeliveryExtV2 ext = new ShipmentManageDeliveryExtV2(new ApexPages.StandardController(shipmentforRMA));
        shipmentforRMA = (Shipment__c)JSON.deserialize(ext.shipmentJson,Shipment__c.Class);
        wrappers = (List<LineWrapper>)ShipmentManageDeliveryExtV2.getShipmentLineData(shipmentforRMA.Id, ext.shipMode).records;
        JsonResult result = ShipmentManageDeliveryExtV2.save(shipmentforRMA, wrappers, new List<String>(), new List<String>(), new List<String>(), ext.shipMode);
        System.assert(result.success, result);
        
        Test.stopTest();

    }
    
    private static testMethod void fulfillRMAlines(){
        if(KSE.checkTestDispatch()){return;}        
        
        TestFuel fuel = new TestFuel();
        
        List<Period__c> periodList = fuel.periodList;
        List<SKID__c> skids = fuel.skids;    
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;

        Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soline = fuel.salesOrderLines[0];
        Sales_Order_Line__c soline1 = fuel.salesOrderLines[1];
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
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 92  queries or less. Actual: '+Limits.getQueries()); 
        
        
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        List<ApexPages.Message> msgList1 = ApexPages.getMessages();
        
        
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Sales_Order__c>{so});
        setCon.setSelected(new List<Sales_Order__c>{so});
        SalesOrderRMAExt soRMAExt = new SalesOrderRMAExt(setCon);
        msgList = ApexPages.getMessages();   
        System.assert(msgList.size() == 0, msgList);
        
        List<Sales_Order_Line__c> sorderlList = new List<Sales_Order_Line__c>();
        // SalesOrderRMAExt.SalesOrderLineWrapper
        //so.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        
        JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines(so.id);
        
        for (SalesOrderRMAExt.SalesOrderLineWrapper obj : (List<SalesOrderRMAExt.SalesOrderLineWrapper>) rmaLinesResult.records){
            System.assert(obj.soLine.Related_Sales_Order_Line__c != null, obj.soLine);
            if(obj.soLine.Product__c == fuel.product.Id){
                obj.soLine.Quantity_Ordered__c = -10;
                obj.soLine.Returned_To_Vendor__c = false;
                obj.soLine.Fulfillment_Source__c = 'Inventory';
                sorderlList.add( obj.soLine);
            }
            else
                obj.soLine.Quantity_Ordered__c = 0;
            
        }
        
        
        System.assertEquals(1, sorderlList.size());
        Sales_order__c header = (Sales_Order__c) SalesOrderRMAExt.getSODetails(so.id).records[0];
        system.assert(header != null, 'Expecting RMA Header to not be null');
        header.Type__c = SalesOrderService.SO_TYPE_RMA;
        JsonResult rma = SalesOrderRMAExt.createRMA(sorderlList, header, new List<String>());
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 92  queries or less. Actual: '+Limits.getQueries()); 
        Sales_Order_Line__c[] rmaLines = [select Id, Sales_Order__r.Type__c,Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c 
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA];
        
        system.assertEquals(1, rmaLines.size());//replacement line creates a regualr so line too.
        
        for (Sales_order_Line__c sol : rmaLines){
            system.assert(sol.Related_Sales_Order_Line__c != null);
            System.assertEquals('Draft', sol.Status__c);
            System.assert(sol.Quantity_Ordered__c < 0, sol.Quantity_Ordered__c + 'Expecting negative qty');
            
        }
        
        Sales_order__c soRMA = rmaLines[0].Sales_Order__r;
        System.assertEquals('Draft', soRMA.Status__c);
        System.assert(soRMA.Related_Sales_Order__c != null);

        system.assert(  Limits.getQueries() <= 92, ' Before plan RMA SO 92  queries or less. Actual: '+Limits.getQueries()); 
        Test.startTest();
        
        //new SalesOrderService().plan(soRMA.id);
        rmaLines = [select Id, Has_Exceptions__c, Quantity_Fulfilled__c, Sales_Order__r.Has_Exceptions__c, Sales_Order__r.Type__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA];
        system.assert(rmaLines.size() ==1,rmaLines);
        
        //Fulfill RMA Lines:
        
        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();

        JsonResult soJS = SalesOrderFulfillmentExt.getSOLines((String) soRMA.id);

        system.assert(soJS.records != null, soJS);
   
        for (SalesOrderFulfillmentExt.SOLWrapper obj : (List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records){
       
          obj.qtyToFulfill = 10;
        }
        
        soJS = SalesOrderFulfillmentExt.createFulfillments((List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records, new List<String>());
        System.assert(soJS.success == true, soJS);
        System.assert(soJS.records.size() > 0, soJS);

        // verify skid qty and serial count
        List<Skid__c> skidslist = [select id, Sales_Order_Line__c, Customer__c, Item__c, Quantity__c, Type__c, Sales_Order_Line__r.Quantity_Ordered__c, (select id, name from Serials__r) from Skid__c ];
        
        List<Fulfillment__c> fuls = [select id, Type__c, Sales_Order_Line__c, Invoice_Ready__c, Sales_Order_Line__r.Product__r.Item__r.Track_Install_Base__c,Sales_Order_Line__r.Sales_Order__r.Ship_To__r.Track_Install_Base__c, Skid__c from Fulfillment__c];
        system.assertEquals(1, fuls.size());


        for (fulfillment__c ful : fuls){

            system.assert(ful.Type__c == Label.RMA_Without_Receipt, ful);
            system.assert(ful.Invoice_Ready__c ==true, ful);
        }

        solList = [select id, Invoiceable__c from Sales_order_line__c where Sales_Order__c = :soRMA.id and Quantity_Ordered__c < 0];

        system.assertEquals(1, solList.size(), solList.size());
        system.assert(solList[0].Invoiceable__c == true);
    }
    
    private static testMethod void fulfillRMAReplacementlines(){
        if(KSE.checkTestDispatch()){return;}        
        
        TestFuel fuel = new TestFuel();
        
        List<Period__c> periodList = fuel.periodList;
        List<SKID__c> skids = fuel.skids;    
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;

        Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soline = fuel.salesOrderLines[0];
        Sales_Order_Line__c soline1 = fuel.salesOrderLines[1];
        
        
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
        
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        List<ApexPages.Message> msgList1 = ApexPages.getMessages();
        
       
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Sales_Order__c>{so});
        setCon.setSelected(new List<Sales_Order__c>{so});
        SalesOrderRMAExt soRMAExt = new SalesOrderRMAExt(setCon);
        msgList = ApexPages.getMessages();   
        System.assert(msgList.size() == 0, msgList);
        
        List<Sales_Order_Line__c> sorderlList = new List<Sales_Order_Line__c>();
       
        JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines(so.id);
        
        for (SalesOrderRMAExt.SalesOrderLineWrapper obj : (List<SalesOrderRMAExt.SalesOrderLineWrapper>) rmaLinesResult.records){
            System.assert(obj.soLine.Related_Sales_Order_Line__c != null, obj.soLine);
            if(obj.soLine.Product__c == fuel.product.Id){
                obj.soLine.Quantity_Ordered__c = -10;
                obj.soLine.Returned_To_Vendor__c = false;
                obj.soLine.Fulfillment_Source__c = 'Inventory';
                sorderlList.add( obj.soLine);
            }
            else
                obj.soLine.Quantity_Ordered__c = 0;
            
        }
        
        
        System.assertEquals(1, sorderlList.size());
        Sales_order__c header = (Sales_Order__c) SalesOrderRMAExt.getSODetails(so.id).records[0];
        system.assert(header != null, 'Expecting RMA Header to not be null');
        header.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        JsonResult rma = SalesOrderRMAExt.createRMA(sorderlList, header, new List<String>());
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 92  queries or less. Actual: '+Limits.getQueries()); 
        Sales_Order_Line__c[] rmaLines = [select Id, Sales_Order__r.Type__c,Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c 
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];
        
        system.assertEquals(2, rmaLines.size());//replacement line creates a regualr so line too.
        system.assert(rmaLines[0].Sales_order__r.Type__c == SalesOrderService.SO_TYPE_RMA_REPLACEMENT);
        for (Sales_order_Line__c sol : rmaLines){
            system.assert(sol.Related_Sales_Order_Line__c != null);
            System.assertEquals('Draft', sol.Status__c);
        }
        
        Sales_order__c soRMA = rmaLines[0].Sales_Order__r;
        System.assertEquals('Draft', soRMA.Status__c);
        System.assert(soRMA.Related_Sales_Order__c != null);
        System.assert(soRMA.Type__c == SalesOrderService.SO_TYPE_RMA_REPLACEMENT, soRMA.Type__c);

         
        Test.startTest();
        
        //Fulfill RMA Lines:
        
        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
        //soRMA.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        JsonResult soJS = SalesOrderFulfillmentExt.getSOLines((String) soRMA.id);
    
        for (SalesOrderFulfillmentExt.SOLWrapper obj : (List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records){
   
          obj.qtyToFulfill = 10;
        }

        system.assert(soJS.records != null, soJS);

        soJS = SalesOrderFulfillmentExt.createFulfillments((List<SalesOrderFulfillmentExt.SOLWrapper>) soJS.records, new List<String>());
        System.assert(soJS.success == true, soJS);
        System.assert(soJS.records.size() > 0, soJS);

        List<Fulfillment__c> fuls = [select id, Type__c, Sales_Order_Line__r.Sales_Order__r.Type__c, Sales_Order_Line__c, Invoice_Ready__c, Skid__c from Fulfillment__c];
        system.assert(fuls.size() == 1,fuls);

        for (fulfillment__c ful : fuls){

           system.assert(ful.Type__c == Label.RMA_Without_Receipt, ful);
            system.assert(ful.Invoice_Ready__c ==false, ful);
        }

        solList = [select id, Invoiceable__c from Sales_order_line__c where Sales_Order__c = :soRMA.id and Quantity_Ordered__c < 0];

        system.assertEquals(1, solList.size(), solList.size());
        system.assert(solList[0].Invoiceable__c == false);
    }
    
    private static testMethod void createReqforReplacementRMA(){
        if(KSE.checkTestDispatch()){return;}
        
        TestFuel fuel = new TestFuel();
        
        List<Period__c> periodList = fuel.periodList;
        List<SKID__c> skids = fuel.skids;    
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;

        Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soline = fuel.salesOrderLines[0];
        Sales_Order_Line__c soline1 = fuel.salesOrderLines[1];
        Shipment__c shipmentforRMA;
        List<Shipment_Line__c> shlListforRMA;
        
        so.Type__c = 'Standard';
        so.Status__c = 'Open';
        update so;
        
        soline.Fulfillment_Source__c = 'Drop Ship';
        soline1.Fulfillment_Source__c = 'Inventory';
        update soline;
        update soline1;

        soline.Status__c = 'Open';
        soline.Quantity_Fulfilled__c = 15;
        soline1.Status__c = 'Open';
        soline.Quantity_Fulfilled__c = 10;
        update soline;
        update soline1;
  
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 92  queries or less. Actual: '+Limits.getQueries()); 
        
        
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        List<ApexPages.Message> msgList1 = ApexPages.getMessages();
        
       
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Sales_Order__c>{so});
        setCon.setSelected(new List<Sales_Order__c>{so});
        SalesOrderRMAExt soRMAExt = new SalesOrderRMAExt(setCon);
        msgList = ApexPages.getMessages();   
        System.assert(msgList.size() == 0, msgList);
        
        List<Sales_Order_Line__c> sorderlList = new List<Sales_Order_Line__c>();
        // SalesOrderRMAExt.SalesOrderLineWrapper
        //so.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        
        JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines(so.id);
        
        for (SalesOrderRMAExt.SalesOrderLineWrapper obj : (List<SalesOrderRMAExt.SalesOrderLineWrapper>) rmaLinesResult.records){
            System.assert(obj.soLine.Related_Sales_Order_Line__c != null, obj.soLine);
            if(obj.soLine.Product__c == fuel.product.Id){
                obj.soLine.Quantity_Ordered__c = -10;
                obj.soLine.Returned_To_Vendor__c = true;
                obj.soLine.Fulfillment_Source__c = 'Drop Ship';
                sorderlList.add( obj.soLine);
            }
            else
                obj.soLine.Quantity_Ordered__c = 0;
            
        }
        
        
        System.assertEquals(1, sorderlList.size());
        Sales_order__c header = (Sales_Order__c) SalesOrderRMAExt.getSODetails(so.id).records[0];
        system.assert(header != null, 'Expecting RMA Header to not be null');
        header.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        JsonResult rma = SalesOrderRMAExt.createRMA(sorderlList, header, new List<String>());
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 92  queries or less. Actual: '+Limits.getQueries()); 
        Sales_Order_Line__c[] rmaLines = [select Id, Sales_Order__r.Type__c,Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c 
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];
        
        system.assertEquals(2, rmaLines.size());//replacement line creates a regualr so line too.
        
        for (Sales_order_Line__c sol : rmaLines){
            system.assert(sol.Related_Sales_Order_Line__c != null);
            System.assertEquals('Draft', sol.Status__c);
            
            
        }
        
        Sales_order__c soRMA = rmaLines[0].Sales_Order__r;
        System.assertEquals('Draft', soRMA.Status__c);
        System.assert(soRMA.Related_Sales_Order__c != null);

        system.assert(  Limits.getQueries() <= 92, ' Before plan RMA SO 92  queries or less. Actual: '+Limits.getQueries()); 
        Test.startTest();
        
        new SalesOrderService().plan(soRMA.id);
        rmaLines = [select Id, Company__c, Has_Exceptions__c, Product__r.Item__c, Quantity_Fulfilled__c, Sales_Order__r.Has_Exceptions__c, Sales_Order__r.Type__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c,
                    Purchase_From_Supplier__c, Ship_From_Location__c,Selling_UOM__c, Ship_From_Location__r.Facility__c,
                    (SELECT Id, Approved__c, Item__c, Facility__c, Quantity_Ordered__c,
                                                                Supplier__c, Sales_Order_Line__c, Status__c, Delivery_Location__c,
                                                                Purchasing_UOM__c,
                                                                Requisition__r.Id, Requisition__r.Company__c, Requisition__r.Ship_To_Customer__c,
                                                                Requisition__r.Sales_Order__c, Requisition__r.Transaction_Date__c, Requisition__r.Delivery_Facility__c,
                                                                Requisition__r.Source__c, Requisition__r.Status__c, Requisition__r.Type__c
                                                          FROM Requisition_Lines__r)
                                         from Sales_Order_Line__c
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPLACEMENT];
        system.assert(rmaLines.size() == 2,rmaLines);
        
         for(Sales_Order_Line__c SOL: rmaLines) {
            for(Requisition_Line__c RQL: SOL.Requisition_Lines__r) {
                System.assertEquals(true, RQL.Approved__c);
                System.assertEquals(SOL.Product__r.Item__c, RQL.Item__c);
                System.assertEquals(SOL.Quantity_Ordered__c, RQL.Quantity_Ordered__c);
                System.assertEquals(SOL.Purchase_From_Supplier__c, RQL.Supplier__c);
                System.assertEquals(SOL.Id, RQL.Sales_Order_Line__c);
                System.assertEquals(SOL.Ship_From_Location__c, RQL.Delivery_Location__c);
                System.assertEquals(SOL.Selling_UOM__c, RQL.Purchasing_UOM__c);

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
        
        
    }
    
    static testMethod void dropShipforRMAwithRTV(){
        if(KSE.checkTestDispatch()){return;}
        
        ReceivingDocumentServiceTest.setupDropShipAdvanced();
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{ ASN__c.sObjectType,ASN_Line__c.sObjectType,Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,
            Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, Shipment__c.sObjectType, Shipment_Line__c.sObjectType };
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        List<Stock_Movement_Rule_Settings__c> smrsList = ReceivingDocumentServiceTest.fuel.smrsList;
        List<Stock_Movement_Rule__c> smrs = ReceivingDocumentServiceTest.fuel.stockMovementRuleList;
        update new Location__c(Id=ReceivingDocumentServiceTest.fuel.location3.Id,Bin_Tracked__c=false);
        update new Item__c(Id=ReceivingDocumentServiceTest.fuel.itemList[0].Id,Item_Attribute__c=null, Stocking_UOM__c = ReceivingDocumentServiceTest.fuel.uomList[8].Id);
        update new Facility__c(Id=ReceivingDocumentServiceTest.fuel.facility2.Id,Default_Purchasing_Delivery_Location__c=ReceivingDocumentServiceTest.fuel.location2.Id);
        
        ASN__c asn = new ASN__c(
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Supplier__c = ReceivingDocumentServiceTest.po.Supplier__c,
            Facility__c = ReceivingDocumentServiceTest.po.Delivery_Facility__c,
            FOB__c = ReceivingDocumentServiceTest.po.FOB_Term__c,
            Status__c = 'Draft',
            Transaction_Date__c = System.today(),
            Currency__c = TestFuel.currencyUSD.ID,
            Transaction_Type__c = 'Purchase Order ASN'
        );
        insert asn;
        ASN_Line__c asnLine = new ASN_Line__c(
            Purchase_Order__c = ReceivingDocumentServiceTest.po.Id,
            Purchase_Order_Line__c = ReceivingDocumentServiceTest.poLine.Id,
            Item__c = ReceivingDocumentServiceTest.poLine.Item__c,
            Item__r = ReceivingDocumentServiceTest.fuel.itemList[0],
            Quantity_Shipped__c = 100,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = asn.Company__c,
            Supplier__c = asn.Supplier__c,
            Is_Changed__c = true
        );
        insert asnLine;
        insert new SKID__c(
            ASN_Line__c = asnLine.Id,
            Location__c = asnLine.Location__c,
            Type__c = 'Draft In-Transit',
            Item__c = asnLine.Item__c,
            Quantity__c = 100,
            Quantity_Stocking_UOM__c = 100,
            Company__c = ReceivingDocumentServiceTest.po.Company__c,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );
        
        JsonResult result = ASNService.confirmASN(asn);
        System.assert(result.success,result);
        Sales_Order__c so = ReceivingDocumentServiceTest.salesOrder;
        Sales_Order_Line__c soline = ReceivingDocumentServiceTest.salesOrderLines[0];
        Sales_Order_Line__c soline1 = ReceivingDocumentServiceTest.salesOrderLines[1];
        
        
        
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Sales_Order__c>{so});
        setCon.setSelected(new List<Sales_Order__c>{so});
        
        SalesOrderRMAExt soRMAExt = new SalesOrderRMAExt(setCon);
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        msgList = ApexPages.getMessages(); 
        System.assert(msgList.size() == 0, msgList);

        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
        // SalesOrderRMAExt.SalesOrderLineWrapper
        //so.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        
        JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines(so.id);

        for (SalesOrderRMAExt.SalesOrderLineWrapper obj : (List<SalesOrderRMAExt.SalesOrderLineWrapper>) rmaLinesResult.records){
            System.assert(obj.soLine.Related_Sales_Order_Line__c != null, obj.soLine);
            if(obj.soLine.Product__c == ReceivingDocumentServiceTest.fuel.product.Id){
                obj.soLine.Quantity_Ordered__c = 10;
                obj.soLine.Returned_To_Vendor__c = true;
                solList.add( obj.soLine);
            }
            else
                obj.soLine.Quantity_Ordered__c = 0;
                
            
        }
        System.assertEquals(1, solList.size());
        Sales_order__c header = (Sales_Order__c) SalesOrderRMAExt.getSODetails(so.id).records[0];
        system.assert(header != null, 'Expecting RMA Header to not be null');
        header.Type__c = SalesOrderService.SO_TYPE_RMA;
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 20  queries or less. Actual: '+Limits.getQueries()); 
        JsonResult rma = SalesOrderRMAExt.createRMA(solList, header, new List<String>());
        system.assert(  Limits.getQueries() <= 100, ' Before create RMA 50  queries or less. Actual: '+Limits.getQueries()); 

        Sales_Order_Line__c[] rmaLines = [select Id, Sales_Order__r.Type__c,Returned_To_Vendor__c, Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c, Sales_order__r.Currency__c
                                         from Sales_Order_Line__c 
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA];//SO_TYPE_RMA_REPLACEMENT
        
        system.assertEquals(1, rmaLines.size());//replacement line creates a regular so line too.

        for (Sales_order_Line__c sol : rmaLines){
            system.assert(sol.Related_Sales_Order_Line__c != null);
            System.assertEquals('Draft', sol.Status__c);
            System.assert(sol.Quantity_Ordered__c < 0, sol.Quantity_Ordered__c + 'Expecting negative qty');
            
        }
        
        Sales_order__c soRMA = rmaLines[0].Sales_Order__r;
        System.assertEquals('Draft', soRMA.Status__c);
        System.assert(soRMA.Related_Sales_Order__c != null);
        delete configList;
        
        System.debug( LoggingLevel.INFO, 'Before Release queries : '+ Limits.getQueries() ); 
        system.assert(  Limits.getQueries() <= 76, ' expected TestData to use 50  queries or less. Actual: '+Limits.getQueries()); 
        new SalesOrderService().plan(soRMA.id);
        system.assert(  Limits.getQueries() <= 90, ' expected TestData to use 78  queries or less. Actual: '+Limits.getQueries()); 
        System.debug( LoggingLevel.INFO, 'Before Release queries : '+ Limits.getQueries() ); 
        rmaLines = [select Id, Has_Exceptions__c, Quantity_Fulfilled__c, Sales_Order__r.Has_Exceptions__c, Sales_Order__r.Type__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA];

        for (Sales_order_Line__c sol : rmaLines){
            System.assertEquals('Open', sol.Status__c, sol);
            system.assertEquals(false, sol.Has_Exceptions__c, ExceptionService.fetchExceptionTasks(new set<Id>{sol.id}));
        }
        
        ReceivingWorkBenchExt.setGridConfig('RMA' , ReceivingDocumentServiceTest.fuel.facility2.id);
        
        //Create ASN with inTransit SKID       
       
        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Type__c, Currency__c, Customer__c, Ship_From_Location__r.Facility__c  from Sales_Order__c where Id =:soRMA.Id]; 
        
        String docnum = queriedSO.Id;
        String facilityId = queriedSO.Ship_From_Location__r.Facility__c;
        String customerFilter = queriedSO.Customer__c;
        ID currencyfilter = queriedSO.Currency__c;
        JSONResult jsonresult = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
        Test.startTest();    
        //test.startTest();
        //Now Search for this ASN on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('RMA');
        ReceivingWorkBenchExt.refreshTrackedAttr(ReceivingDocumentServiceTest.fuel.Location, ReceivingDocumentServiceTest.fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('RMA');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, docnum, customerFilter, currencyfilter, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
        
        //Manage Receive        
         
        List<Sales_Order_Line__c> newSOLinelist = [Select Id, Ship_From_Location__r.Facility__c, Quantity_Ordered__c, Sales_Order__r.Customer__c,
                                            Sales_Order__r.Currency__c, Sales_Order__r.Status__c, Sales_Order__r.Name,Sales_Order__r.Type__c, Product__r.Item__r.Name, Status__c 
                                            from Sales_Order_Line__c where Sales_Order__c =:queriedSO.Id];
        system.assert(newSOLinelist.size() == 1, newSOLinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,ReceivingDocumentServiceTest.fuel.facility2.Id,null,'RMA');
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
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(solineIds, 'RMA', TestFuel.currencyUSD.ID);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(solineIds), new set<String>{'Sales_Order_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == ReceivingDocumentServiceTest.fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                    skid.Stocking_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__c = ReceivingDocumentServiceTest.fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = ReceivingDocumentServiceTest.fuel.uomObj;
                    skid.Packaging_UOM__r.Package_Class__r = null;
                }
                skid.Quantity_Stocking_UOM__c = skid.Quantity__c;
    }
        }
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        rdoc.Currency__c = TestFuel.currencyUSD.ID;
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        //delete configList;
        test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
    
        List<Fulfillment__c> fulfillmentrecs = [Select Id, Status__c, Quantity__c, Sales_Order__c,Sales_Order_Line__c from Fulfillment__c where Sales_Order__c =:queriedSO.Id];
        
        system.assert(fulfillmentrecs.size() == 1, fulfillmentrecs);    
        
        for(Fulfillment__c rec:fulfillmentrecs){
            if(rec.Sales_Order_Line__c == soline.Id)
                system.assert(rec.Quantity__c == -5, rec);
        }
                                        
        //Also check Quantity_Fulfilled__c on updated solines.  
        
        List<Sales_Order_Line__c> updatedsolinelist = [Select Id, Status__c, Quantity_Fulfilled__c from Sales_Order_Line__c where Sales_Order__c =:queriedSO.Id];
        
        
        for(Sales_Order_Line__c sol:updatedsolinelist){
            if(sol.Id == soline.Id)
                system.assert(sol.Quantity_Fulfilled__c == -5, sol);
            
        }
                                    
        Set<ID> receiptlineSet = new Set<ID>();
        Set<ID> relatedReceiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Status__c, Item__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c, Sales_Order__r.Currency__c from Receipt_Line__c where Sales_Order__c =:queriedSO.Id and Sales_Order__r.Type__c = :SalesOrderService.SO_TYPE_RMA];
        system.assert(receiptlines.size() == 1, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c == null);
            system.assert(rcptline.Sales_Order__c == queriedSO.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'Logical RMA Receipt',rcptline.Receiving_Document__r.Type__c);
            if(rcptline.Item__c == ReceivingDocumentServiceTest.fuel.itemList[0].ID){
                system.assert(rcptline.Quantity_Received__c == 5, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 0, rcptline.Quantity_Still_Due_For_Putaway__c);
            }
             
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'Logical RMA Receipt', rcptline);            
        }
    
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        
        system.assert(itlist.size() == 1, itlist);
        system.assert(itlist[0].Type__c == 'Logical RMA Receipt', itlist);
        
        List<Receipt_Line__c> returnReceiptlines = [Select Id, Status__c, Item__c, Quantity_Returned_To_Supplier_For_Credit__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Related_Receipt_Line__c IN :receiptlineSet];
        
        system.assert(returnReceiptlines.size() == 1, returnReceiptlines[0].Receiving_Document__r);
        
        for(Receipt_Line__c rline: returnReceiptlines){
            relatedReceiptlineSet.add(rline.Id);
            system.assert(rline.Receiving_Document__r.Type__c == 'Logical Purchase Order Return');
            system.assert(rline.Quantity_Returned_To_Supplier_For_Credit__c == 5,rline);
        }
        
        List<Inventory_Transaction__c> logicalITs = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :relatedReceiptlineSet];
        
        
        system.assert(logicalITs.size() == 1, logicalITs);
        system.assert(logicalITs[0].Type__c == 'Logical Purchase Order Return', logicalITs);
    }
    
    /* FIX ME
    public static testMethod void CreateWO_on_RMARepair_no_Warranty_Test(){
        if(KSE.checkTestDispatch()){return;}       
        
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{ Facility__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Customer__c.sObjectType,
            Shipment__c.sObjectType, Shipment_Line__c.sObjectType,Item_Attribute__c.sObjectType, SKID__c.sObjectType,Period__c.sObjectType,Product__c.sObjectType,Reason_Code__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        TestFuel fuel = new TestFuel();
        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id,Expiration_Date__c = false, Lot_Number__c = false);
        List<Period__c> periodList = fuel.periodList;
        System.assert(fuel.reasonCodes != null);
        List<SKID__c> skids = fuel.skids;    
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
		
        Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soline = fuel.salesOrderLines[0];
        Sales_Order_Line__c soline1 = fuel.salesOrderLines[1];
        
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
        system.assert(Limits.getQueries() <= 92, ' Before create RMA 92  queries or less. Actual: '+Limits.getQueries()); 
        
        
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        List<ApexPages.Message> msgList1 = ApexPages.getMessages();
        
        
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Sales_Order__c>{so});
        setCon.setSelected(new List<Sales_Order__c>{so});
        SalesOrderRMAExt soRMAExt = new SalesOrderRMAExt(setCon);
        msgList = ApexPages.getMessages();   
        System.assert(msgList.size() == 0, msgList);
        
        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
        
        JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines(so.id);
        
        for (SalesOrderRMAExt.SalesOrderLineWrapper obj : (List<SalesOrderRMAExt.SalesOrderLineWrapper>) rmaLinesResult.records){
            System.assert(obj.soLine.Related_Sales_Order_Line__c != null, obj.soLine);
            if(obj.soLine.Product__c == fuel.product.Id){
                obj.soLine.Quantity_Ordered__c = -10;
                obj.soLine.Returned_To_Vendor__c = false;
                obj.soLine.Fulfillment_Source__c = 'Inventory';
                solList.add( obj.soLine);
            }
            else
                obj.soLine.Quantity_Ordered__c = 0;
        }
        
        
        System.assertEquals(1, solList.size());
        Sales_order__c header = (Sales_Order__c) SalesOrderRMAExt.getSODetails(so.id).records[0];
        header.Type__c = SalesOrderService.SO_TYPE_RMA_REPAIR;
        
        system.assert(header != null, 'Expecting RMA Header to not be null');
        header.Type__c = SalesOrderService.SO_TYPE_RMA_REPAIR;
        JsonResult rma = SalesOrderRMAExt.createRMA(solList, header, new List<String>());
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 92  queries or less. Actual: '+Limits.getQueries()); 
        Sales_Order_Line__c[] rmaLines = [select Id, Sales_Order__r.Type__c,Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c 
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPAIR];
        
        system.assertEquals(2, rmaLines.size());//repair line creates a regualr so line too.
        Boolean negativeQty = false;
        Boolean positiveQty = false;
        for (Sales_order_Line__c sol : rmaLines){
            system.assert(sol.Related_Sales_Order_Line__c != null);
            System.assertEquals('Draft', sol.Status__c);
            //System.assert(sol.Quantity_Ordered__c < 0, sol.Quantity_Ordered__c + 'Expecting negative qty');
            if(sol.Quantity_Ordered__c < 0){
                negativeQty = true;
            }
            if(sol.Quantity_Ordered__c > 0){
                positiveQty = true;
            }
        }
        system.assert(negativeQty == true && positiveQty == true);
        Sales_order__c soRMA = rmaLines[0].Sales_Order__r;
        System.assertEquals('Draft', soRMA.Status__c);
        System.assert(soRMA.Related_Sales_Order__c != null);

        system.assert(  Limits.getQueries() <= 92, ' Before plan RMA SO 92  queries or less. Actual: '+Limits.getQueries()); 
        
        
        SOQLUtil rcQuery = new SOQLUtil('Reason_Code__c');
        rcQuery.addAllCustomFields();
        rcQuery.setWhereClause('Type__c = \'Work Order\' limit 1');
        Reason_Code__c reasonCode = Database.query(rcQuery.getQuery());
                
        
        system.assert(Limits.getQueries() < 72,Limits.getQueries());
        
        
		new SalesOrderService().plan(soRMA.id);
		
		
		system.assert(Limits.getQueries() < 99,Limits.getQueries());
        rmaLines = [select Id, Has_Exceptions__c, Work_Order__c,Work_Order__r.Type__c,Type__c,Quantity_Fulfilled__c, Sales_Order__r.Has_Exceptions__c, Sales_Order__r.Type__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPAIR];
        system.assert(rmaLines.size() ==2,rmaLines);
        Boolean foundWO = false;
        Id woId;
        Id solineId;
        Id repairSOLId;
        
        for(Sales_order_Line__c sol:rmaLines){
        	System.assertEquals('Open', sol.Status__c, sol);
            system.assertEquals(false, sol.Has_Exceptions__c, ExceptionService.fetchExceptionTasks(new set<Id>{sol.id}));
        	if(sol.Type__c == 'Repair'){
        		system.assert(sol.Work_Order__c !=null);
        		woId = sol.Work_Order__c;
        		system.assert(sol.Work_Order__r.Type__c =='Repair');
        		repairSOLId = sol.Id;
        		foundWO = true;
        	}
        	else
        		solineId = sol.Id;
        }
        system.assert(foundWO==true);
        
        
        Work_Order__c workorder = [select Id, Name, Type__c,Complete_to_Location__c from Work_Order__c where Id = :woId and Type__c = 'Repair'];
        system.assert(workorder!=null);
        workorder.Reason_Code__c = reasonCode.Id;
        workorder.Complete_to_Location__c = fuel.location5.Id;
        workorder.Default_WIP_Location__c = fuel.location7.Id;
        workorder.MRB_Location__c = fuel.location2.Id;
        update workorder;
        
        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ solineId },'RMA',TestFuel.currencyUSD.Id).records[0];
		
        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ solineId },new Set<String>{ 'sales_order_line__c'});
        for (ReceivingWrapper rw:rWrappers) {
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                
                sw.skid.Quantity__c = 10;
                sw.skid.Packaging_UOM__c = fuel.uomObj.Id;
                sw.skid.Packaging_UOM__r = fuel.uomObj;
                sw.skid.Packaging_UOM__r.Package_Class__r = null;
            }
        }
        system.assert(rd != null, rd);
        
        Test.startTest();
        JSONResult receiveLinesresult = ReceivingWorkBenchExt.receive(rWrappers, null, null, rd, null);
        
        
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        //Release WO and Kit
        
        WorkOrderPlanningService.release(new Set<Id>{workorder.Id});
        
        List<Material_Tracking__c> mtList = [SELECT Id,Type__c FROM Material_Tracking__c WHERE Work_Order__c = :workorder.Id];
        System.assert(mtList.size() == 1);
        System.assert(mtList[0].Type__c == 'Repair');

        List<Operation_Tracking__c> opList = [SELECT Id FROM Operation_Tracking__c WHERE Work_Order__c = :workorder.Id];
        System.assert(opList.size() == 1);

        Id opId = opList[0].Id;
        JsonResult kitResult = WorkOrderKitExtV2.getKitData(workorder.Id);
        System.assert(kitResult.success,kitResult);
        System.assert(kitResult.records.size() == 1);
        
        List<WorkOrderWrapper> wowList = (List<WorkOrderWrapper>)kitResult.records;
        System.assert(wowList[0].serialWrapperList.size() == 1);
        System.assert(wowList[0].serialWrapperList[0].skid.Type__c == 'Location');
        
        wowList[0].serialWrapperList[0].skid.Quantity_to_Issue__c = 1;
        
        JsonResult result = WorkOrderKitExtV2.save(wowList,new List<String>(),new List<String>());
        System.assert(result.success);
        
        List<Inventory_Transaction__c> itList = [SELECT Id,To_SKID__c,To_SKID__r.Type__c,Type__c FROM Inventory_Transaction__c WHERE Inventory_Change__r.Type__c = 'Work Order Kit' AND Inventory_Change__r.Work_Order__c = :workorder.Id];
        System.assert(itList.size() == 1);
        System.assert(itList[0].To_SKID__c != null);
        System.assert(itList[0].To_SKID__r.Type__c == 'WIP');
        System.assert(itList[0].Type__c == 'Work Order Repair Component Issue');
        
        workorder = WorkOrderCompleteExtV2.getWorkOrder(workorder.Id);
        Operation_Tracking__c op = workorder.Operation_Trackings__r[0];

        SkidService3.SerialWrapper assembly = (SkidService3.SerialWrapper)WorkOrderCompleteExtV2.getAssemblyData(workorder, op, true).records[0];
        assembly.skid.Quantity_Used__c = 1;
		WorkOrderService.completeV2(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(workorder, op, null, assembly, null, null, true) });
        delete configList;
        itList = [SELECT Id,To_SKID__c,To_SKID__r.Type__c,Type__c FROM Inventory_Transaction__c WHERE Inventory_Change__r.Type__c = 'Work Order Complete' AND Inventory_Change__r.Work_Order__c = :workorder.Id];
        System.assert(itList.size() == 2);
        for (Inventory_Transaction__c it:itList) {
            if (it.Type__c == 'Work Order Repair Assembly Completion') {
                System.assert(it.To_SKID__c != null);
                System.assert(it.To_SKID__r.Type__c == 'Location');
            } else if (it.Type__c == 'Work Order Repair Issue From WIP') {
                System.assert(it.To_SKID__c == null);
            } else {
                System.assert(false,'Unexpected IT type: ' + it.Type__c);
            }
        }
        Test.stopTest();
        List<SKID__c> allocatedSkids = [SELECT Id,Sales_Order_Line__r.Quantity_Allocated__c FROM SKID__c WHERE Type__c = 'Allocated' AND Sales_Order_Line__c = :repairSOLId];
        System.assert(allocatedSkids.size() == 1);
        System.assert(allocatedSkids[0].Sales_Order_Line__r.Quantity_Allocated__c == 1,allocatedSkids[0].Sales_Order_Line__r);

    }*/
    
    public static testMethod void RMARepair_Use_Warranty_Flow_Test(){
        if(KSE.checkTestDispatch()){return;}       
        
        TestFuel fuel = new TestFuel();
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{ Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Customer__c.sObjectType,
            Shipment__c.sObjectType, Shipment_Line__c.sObjectType,Item_Attribute__c.sObjectType,Reason_Code__c.sObjectType };
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id,Expiration_Date__c = false, Lot_Number__c = false);
        List<Period__c> periodList = fuel.periodList;
        System.assert(fuel.reasonCodes != null);
        List<SKID__c> skids = fuel.skids;    
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
		
		
		update new Company__c(Id=fuel.company.Id,Use_Warranty_Repairs__c = true);
		
        Sales_Order__c so = fuel.salesOrder;
        Sales_Order_Line__c soline = fuel.salesOrderLines[0];
        Sales_Order_Line__c soline1 = fuel.salesOrderLines[1];
        
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
        system.assert(Limits.getQueries() <= 92, ' Before create RMA 92  queries or less. Actual: '+Limits.getQueries()); 
        
        
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        List<ApexPages.Message> msgList1 = ApexPages.getMessages();
        
        
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Sales_Order__c>{so});
        setCon.setSelected(new List<Sales_Order__c>{so});
        SalesOrderRMAExt soRMAExt = new SalesOrderRMAExt(setCon);
        msgList = ApexPages.getMessages();   
        System.assert(msgList.size() == 0, msgList);
        
        List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
        
        JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines(so.id);
        
        for (SalesOrderRMAExt.SalesOrderLineWrapper obj : (List<SalesOrderRMAExt.SalesOrderLineWrapper>) rmaLinesResult.records){
            System.assert(obj.soLine.Related_Sales_Order_Line__c != null, obj.soLine);
            if(obj.soLine.Product__c == fuel.product.Id){
                obj.soLine.Quantity_Ordered__c = -10;
                obj.soLine.Returned_To_Vendor__c = false;
                obj.soLine.Fulfillment_Source__c = 'Inventory';
                solList.add( obj.soLine);
            }
            else
                obj.soLine.Quantity_Ordered__c = 0;
        }
        
        
        System.assertEquals(1, solList.size());
        Sales_order__c header = (Sales_Order__c) SalesOrderRMAExt.getSODetails(so.id).records[0];
        header.Type__c = SalesOrderService.SO_TYPE_RMA_REPAIR;
        
        system.assert(header != null, 'Expecting RMA Header to not be null');
        header.Type__c = SalesOrderService.SO_TYPE_RMA_REPAIR;
        JsonResult rma = SalesOrderRMAExt.createRMA(solList, header, new List<String>());
        system.assert(  Limits.getQueries() <= 92, ' Before create RMA 92  queries or less. Actual: '+Limits.getQueries()); 
        Sales_Order_Line__c[] rmaLines = [select Id, Sales_Order__r.Type__c,Fulfillment_Source__c, Sales_Order__r.Status__c, Status__c, Related_Sales_Order_Line__c, Sales_Order__r.Related_Sales_Order__c, Quantity_Ordered__c
                                         from Sales_Order_Line__c 
                                         where Sales_order__r.Type__c = :SalesOrderService.SO_TYPE_RMA_REPAIR];
        
        system.assertEquals(1, rmaLines.size());//old warranty flow only creates one RMA Line.
        
    }
    
    
}