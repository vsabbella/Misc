@isTest
public class ReceivingDocumentRTVTestV2 {
     @testSetup
    private static void setupData() {
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Item_Attribute__c.sObjectType,Location__c.sObjectType,Customer_Receipt__c.sObjectType,Working_Day__c.sObjectType,Stock_Movement_Rule_Settings__c.sObjectType, Currency__c.sObjectType,UOM__c.sObjectType,Supplier__c.sObjectType,Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Facility__c.sObjectType,Item_Specification__c.sObjectType,Order_Line__c.sObjectType,Contract__c.sObjectType,Bank_Transaction__c.sObjectType,
            Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, Shipment__c.sObjectType,Customer__c.sObjectType, Shipment_Line__c.sObjectType,Product__c.sObjectType,Item__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        TestFuel f = new TestFuel();

        System.assert(f.periodList != null);
        System.assert(f.itemList != null);
        System.assert(f.location != null);
        System.assert(f.location3 != null);
        System.assert(f.location5 != null);
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.itemAttrObj != null);
        System.assert(f.uomList != null);

        delete configlist;
        System.assert(f.purchaseOrder != null);
       
        
        insert new User_Preference__c(
            OwnerId = UserInfo.getUserId(),
            Default_Company__c = f.company.Id,
            Default_Facility__c = f.facility2.Id,
            User__c = UserInfo.getUserId()
        );
    }

    private static TestFuelQuery fuel = new TestFuelQuery();
    
    private class RTVDataSetup {
        public Receiving_Document__c rd { get; set; }
    
        public RTVDataSetup() {
            //try{
            update new Company__c(Id = fuel.company.Id, Serial_Control__c = 'At receipt and all processes');
            update new Item_Attribute__c(Id = fuel.itemAttrObj.Id, Expiration_Date__c = false, Lot_Number__c = false, Serial_Number__c = true);
            
            Purchase_Order__c po = fuel.purchaseOrder;
        
            //Receive
            JsonResult receiveResult = PurchaseOrderReceiveExtV2.getList(po.Id);
            List<ReceivingWrapper> polWrappers = (List<ReceivingWrapper>)receiveResult.records;
            polWrappers[0].serialWrapperList[0].skid.Quantity__c = 10;
            Serial__c serial = polWrappers[0].serialWrapperList[0].serialList[0];
            serial.Name = 'SERIAL0';
            for (Integer i=1;i<10;i++) {
                Serial__c serialClone = serial.clone(false,true);
                serialClone.Name = 'SERIAL' + i;
                polWrappers[0].serialWrapperList[0].serialList.add(serialClone);
            }
            PurchaseOrderReceiveExtV2.receivePurchaseOrders(polWrappers);
        
            //PO RTV
            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Purchase_Order__c>{po});
            ssc.setSelected(new List<Purchase_Order__c>{po});
            PurchaseOrderReturnToVendorExt poRTV = new PurchaseOrderReturnToVendorExt(ssc);
            
            poRTV.retrievePOLines();
            poRTV.POLinesForDisplay[0].newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c = 2;
            poRTV.save();
            //}catch(Exception e){
            //system.debug('Error: ' + e.getstacktracestring());
            //}
            
            rd = [SELECT Id FROM Receiving_Document__c WHERE Type__c = 'Purchase Order Return' LIMIT 1];


        }
    }
    private class RTVDataSetupCases {
        public Receiving_Document__c rd { get; set; }
    
        public RTVDataSetupCases() {
            DML.systemTime = system.now().addMinutes(-20);
            List<Configuration__c> configList = new List<Configuration__c>();
            List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType,Currency__c.sObjectType ,Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
                Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,
                Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, item_attribute__c.sObjectType,Shipment__c.sObjectType,Customer__c.sObjectType, Shipment_Line__c.sObjectType,Product__c.sObjectType,Item__c.sObjectType};
            
            for (sObjectType s:skipTriggers) {
                configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));
            }
            insert configList;
            update new Company__c(Id = fuel.company.Id, Serial_Control__c = 'At receipt and all processes');
            update new Item_Attribute__c(Id = fuel.itemAttrObj.Id, Expiration_Date__c = false, Lot_Number__c = false, Serial_Number__c = true);
            
            Purchase_Order__c po =  new Purchase_Order__c(
                                Supplier__c = fuel.supplier.id, 
                                Company__c = fuel.company.id,
                                Payment_Term__c = fuel.terms.id,
                                Delivery_Facility__c = fuel.facility2.id,
                                Delivery_Location__c = fuel.location2.ID,
                                Remit_To_Supplier__c = fuel.remitToSupplier.id,
                                Approval_Status__c = 'Approved',
                                fob_term__c = fuel.fobTerm.id,
                                Acknowledge_Via__c = 'Email',
                                Status__c = 'Open',
                                Memo__c = 'purchaseOrder',
                                Currency__c = fuel.currencyUSD.id   
                    );
            insert po;
             Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
                poLine.Purchase_Order__c = po.Id;  
                poLine.Item__c = fuel.itemList[14].Id;
                poLine.Order_Quantity__c = 1;
                poLine.Unit_Price__c = 1;
                poLine.Purchase_UOM__c = fuel.uomList[12].Id;
                poLine.Stocking_UOM__c = fuel.itemList[14].Stocking_UOM__c;
                poLine.Description__c = 'purchaseOrderLine0';
                poLine.Company__c = fuel.company.id;
                poLine.Need_Date__c = system.today() + 7;
                poLine.Delivery_Facility__c = fuel.facility2.id;
                poLine.Delivery_Location__c = fuel.location2.ID;
                poLine.Supplier__c = fuel.supplier.Id;
                poLine.Line__c = 1;
                poLine.Quantity_Matched__c = 0;
                poLine.Amount_Matched__c = 0;
                
            
            insert poLine;
            po.Approval_Status__c = 'Approved';
            update po;
            delete configList;
          
            
            //Receive
            JsonResult receiveResult = PurchaseOrderReceiveExtV2.getList(po.Id);
            List<ReceivingWrapper> polWrappers = (List<ReceivingWrapper>)receiveResult.records;
            polWrappers[0].serialWrapperList[0].skid.Quantity__c = 1;
            Serial__c serial = polWrappers[0].serialWrapperList[0].serialList[0];
            serial.Name = 'SERIAL0';
            for (Integer i=1;i<2;i++) {
                Serial__c serialClone = serial.clone(false,true);
                serialClone.Name = 'SERIAL' + i;
                polWrappers[0].serialWrapperList[0].serialList.add(serialClone);
            }
            PurchaseOrderReceiveExtV2.receivePurchaseOrders(polWrappers);

            //PO RTV
            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Purchase_Order__c>{po});
            ssc.setSelected(new List<Purchase_Order__c>{po});
            PurchaseOrderReturnToVendorExt poRTV = new PurchaseOrderReturnToVendorExt(ssc);
            
            poRTV.retrievePOLines();
            poRTV.POLinesForDisplay[0].newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c = 1;
            poRTV.save();
            
            rd = [SELECT Id FROM Receiving_Document__c WHERE Type__c = 'Purchase Order Return' LIMIT 1];
        }
    }
    private class RTVDataSetupKiloGrams {
        public Receiving_Document__c rd { get; set; }

        public RTVDataSetupKiloGrams() {
            DML.systemTime = system.now().addMinutes(-20);
            List<Configuration__c> configList = new List<Configuration__c>();
            List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType,Currency__c.sObjectType ,Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
                    Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,
                    Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, item_attribute__c.sObjectType,Shipment__c.sObjectType,Customer__c.sObjectType, Shipment_Line__c.sObjectType,Product__c.sObjectType,Item__c.sObjectType};

            for (sObjectType s:skipTriggers) {
                configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));
            }
            insert configList;
            update new Company__c(Id = fuel.company.Id, Serial_Control__c = 'At receipt and all processes');
            update new Item_Attribute__c(Id = fuel.itemAttrObj.Id, Expiration_Date__c = false, Lot_Number__c = false, Serial_Number__c = false);



            // get the UOMs by Name
            Map<String,UOM__c> UOMbyName = new Map<String,UOM__c>();

            for(UOM__c uom:fuel.uomList ) {
                UOMbyName.put(uom.name, uom);
            }
            System.debug(LoggingLevel.ERROR, 'UOM List:'+JSON.serialize(UOMbyName));


            system.assert(UOMbyName.get('LB')!=null);
            UOM__c uomKG = new UOM__c(
                    Name = 'KG',
                    Description__c = 'KiloGrams'
            );
            Insert uomKG;
            UOMbyName.put(uomKG.name,uomKG);

            UOM_Conversion_Details__c Obj = new UOM_Conversion_Details__c();
            //KG-LBs UOM Conversion
            Obj.Name = ((String)UOMbyName.get('KG').Id).substring(3, 15) + ((String)UOMbyName.get('LB').Id).substring(3, 15);
            Obj.uom_1__c = UOMbyName.get('KG').Id;
            Obj.uom_1_Quantity__c =1;
            Obj.uom_2__c = UOMbyName.get('LB').Id;
            Obj.uom_2_Quantity__c = 2.2;
            Obj.Key_1__c = string.valueof(UOMbyName.get('KG').Id)+string.valueof(UOMbyName.get('LB').Id);
            Obj.Key_2__c = string.valueof(UOMbyName.get('LB').Id)+string.valueof(UOMbyName.get('KG').Id);

            insert Obj;


            Item__c item = new Item__c(
                    Name = fuel.company.Name + ' Item-'+String.valueOf(fuel.itemList.size()+'testKGS_LBS') ,
                    Company__c = fuel.company.Id,
                    Active__c = true,
                    Non_Inventory__c = false,
                    Description__c = 'Item-'+fuel.itemList.size()+1,
                    Purchasing_UOM__c = uomKG.Id,
                    Item_Attribute__c = fuel.itemAttrObj.Id,
                    Stocking_UOM__c = UOMbyName.get('LB').Id,
                    Packaging_UOM__c = JSON.serialize(new List<Id>{  UOMbyName.get('LB').Id })
            );

            insert item;

            Purchase_Order__c po =  new Purchase_Order__c(
                    Supplier__c = fuel.supplier.id,
                    Company__c = fuel.company.id,
                    Payment_Term__c = fuel.terms.id,
                    Delivery_Facility__c = fuel.facility2.id,
                    Delivery_Location__c = fuel.location2.ID,
                    Remit_To_Supplier__c = fuel.remitToSupplier.id,
                    Approval_Status__c = 'Approved',
                    fob_term__c = fuel.fobTerm.id,
                    Acknowledge_Via__c = 'Email',
                    Status__c = 'Open',
                    Memo__c = 'purchaseOrder',
                    Currency__c = fuel.currencyUSD.id
            );
            insert po;
            Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
            poLine.Purchase_Order__c = po.Id;
            poLine.Item__c = item.Id;
            poLine.Order_Quantity__c = 100;
            poLine.Unit_Price__c = 1;
            poLine.Purchase_UOM__c = UOMbyName.get('KG').Id;
            //poLine.Stocking_UOM__c = UOMbyName.get('LB').Id;
            poLine.Description__c = 'purchaseOrderLine0';
            poLine.Company__c = fuel.company.id;
            poLine.Need_Date__c = system.today() + 7;
            poLine.Delivery_Facility__c = fuel.facility2.id;
            poLine.Delivery_Location__c = fuel.location2.ID;
            poLine.Supplier__c = fuel.supplier.Id;
            poLine.Line__c = 1;
            poLine.Quantity_Matched__c = 0;
            poLine.Amount_Matched__c = 0;


            insert poLine;

            system.debug(LoggingLevel.ERROR,'poline:'+JSON.serialize(poLine));
            po.Approval_Status__c = 'Approved';
            update po;
            delete configList;

            system.assert(poLine.Id!=null,'poLine is not Null..');


            //Receive
            JsonResult receiveResult = PurchaseOrderReceiveExtV2.getList(po.Id);
            List<ReceivingWrapper> polWrappers = (List<ReceivingWrapper>)receiveResult.records;
            polWrappers[0].serialWrapperList[0].skid.Quantity__c = 100;

            system.assert(polWrappers!=null,'polWrappers required.');
            JsonResult result = PurchaseOrderReceiveExtV2.receivePurchaseOrders(polWrappers);
            system.assert(result.success, 'Not successful'+result.message);
            system.assert(po.id!=null,'Po ID does not exist.');

            //PO RTV
            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Purchase_Order__c>{po});
            ssc.setSelected(new List<Purchase_Order__c>{po});
            System.assert(ssc.getSelected()!=null,'No PO records selected.');
            PurchaseOrderReturnToVendorExt poRTV = new PurchaseOrderReturnToVendorExt(ssc);

            poRTV.retrievePOLines();
            poRTV.POLinesForDisplay[0].newPolRecord.Quantity_Returned_To_Supplier_For_Credit__c = 45; // In Kgs
            poRTV.save();

            rd = [SELECT Id FROM Receiving_Document__c WHERE Type__c = 'Purchase Order Return' LIMIT 1];
            system.assert(rd!=null, 'Purchase Order Return not created..s');
        }
    }
    private static testMethod void testSuccess() {
        RTVDataSetup dataSetup = new RTVDataSetup();
        
        ReceivingDocumentRTVExtV2 rdRTV = new ReceivingDocumentRTVExtV2(new ApexPages.StandardController(dataSetup.rd));
        String config = rdRTV.rtvGridConfigJson;
        String rlFL = rdRTV.receiptLineFieldListJSON;
        String skidFL = rdRTV.skidFieldListJSON;
        
        JsonResult rtvResult = ReceivingDocumentRTVExtV2.getRTVData(dataSetup.rd.Id);
        System.assert(rtvResult.success,rtvResult);
        System.assert(rtvResult.total == 1,rtvResult);
        
        List<LineWrapper> rlWrappers = (List<LineWrapper>)rtvResult.records;
        System.assert(rlWrappers.size() == 1);
        
        rlWrappers[0].serialWrappers[0].skid.Quantity_To_Return__c = 2;
        rlWrappers[0].serialWrappers[0].serialList = new List<Serial__c>{ rlWrappers[0].serialWrappers[0].serialList[0], rlWrappers[0].serialWrappers[0].serialList[1] };
        
        Test.startTest();
        rtvResult = ReceivingDocumentRTVExtV2.save(rlWrappers,new List<String>(),new List<String>());
        System.assert(rtvResult.success,rtvResult);
        
        List<Inventory_Transaction__c> itList = [SELECT Id,Type__c,Quantity__c,(SELECT Id,Type__c FROM Serial_Transactions__r) FROM Inventory_Transaction__c WHERE Receipt_Line__r.Receiving_Document__c = :dataSetup.rd.Id];
        System.assert(itList.size() == 1);
        System.assert(itList[0].Type__c == 'Purchase Order Return');
        System.assert(itList[0].Quantity__c == 2);
        System.assert(itList[0].Serial_Transactions__r.size() == 2);
        for (Serial_Transaction__c st:itList[0].Serial_Transactions__r)
            System.assert(st.Type__c == 'Return To Vendor');
    }
    
    private static testMethod void testNegativeQuantity() {
        RTVDataSetup dataSetup = new RTVDataSetup();
        
        JsonResult rtvResult = ReceivingDocumentRTVExtV2.getRTVData(dataSetup.rd.Id);
        List<LineWrapper> rlWrappers = (List<LineWrapper>)rtvResult.records;
        
        rlWrappers[0].serialWrappers[0].skid.Quantity_To_Return__c = -2;
        Test.startTest();
        rtvResult = ReceivingDocumentRTVExtV2.save(rlWrappers,new List<String>(),new List<String>());
        System.assert(!rtvResult.success,rtvResult);
        Test.stopTest();
    }
    
    private static testMethod void testMoreQtyThanAvail() {
        RTVDataSetup dataSetup = new RTVDataSetup();
        
        JsonResult rtvResult = ReceivingDocumentRTVExtV2.getRTVData(dataSetup.rd.Id);
        List<LineWrapper> rlWrappers = (List<LineWrapper>)rtvResult.records;
        
        rlWrappers[0].serialWrappers[0].skid.Quantity_To_Return__c = 999999;
        Test.startTest();
        rtvResult = ReceivingDocumentRTVExtV2.save(rlWrappers,new List<String>(),new List<String>());
        System.assert(!rtvResult.success,rtvResult);
        Test.stopTest();
    }
    
    private static testMethod void testSerialNotMatching() {
        RTVDataSetup dataSetup = new RTVDataSetup();
        
        JsonResult rtvResult = ReceivingDocumentRTVExtV2.getRTVData(dataSetup.rd.Id);
        List<LineWrapper> rlWrappers = (List<LineWrapper>)rtvResult.records;
        
        rlWrappers[0].serialWrappers[0].skid.Quantity_To_Return__c = 2;
        Test.startTest();
        rtvResult = ReceivingDocumentRTVExtV2.save(rlWrappers,new List<String>(),new List<String>());
        System.assert(!rtvResult.success,rtvResult);
        Test.stopTest();
    }
    
    private static testMethod void testDupSerial() {
        RTVDataSetup dataSetup = new RTVDataSetup();
        
        JsonResult rtvResult = ReceivingDocumentRTVExtV2.getRTVData(dataSetup.rd.Id);
        List<LineWrapper> rlWrappers = (List<LineWrapper>)rtvResult.records;
        
        rlWrappers[0].serialWrappers[0].skid.Quantity_To_Return__c = 2;
        rlWrappers[0].serialWrappers[0].serialList = new List<Serial__c>{ rlWrappers[0].serialWrappers[0].serialList[0], rlWrappers[0].serialWrappers[0].serialList[0] };
        Test.startTest();
        rtvResult = ReceivingDocumentRTVExtV2.save(rlWrappers,new List<String>(),new List<String>());
        System.assert(!rtvResult.success,rtvResult);
        Test.stopTest();
    }
    private static testMethod void testRTVWithCasesPurchaseUOM() {
        RTVDataSetupCases dataSetup = new RTVDataSetupCases();
        
        ReceivingDocumentRTVExtV2 rdRTV = new ReceivingDocumentRTVExtV2(new ApexPages.StandardController(dataSetup.rd));
        String config = rdRTV.rtvGridConfigJson;
        String rlFL = rdRTV.receiptLineFieldListJSON;
        String skidFL = rdRTV.skidFieldListJSON;
        Test.startTest();
        JsonResult rtvResult = ReceivingDocumentRTVExtV2.getRTVData(dataSetup.rd.Id);
        System.assert(rtvResult.success,rtvResult);
        System.assert(rtvResult.total == 1,rtvResult);
        
        List<LineWrapper> rlWrappers = (List<LineWrapper>)rtvResult.records;
        System.assert(rlWrappers.size() == 1);
        
        rlWrappers[0].serialWrappers[0].skid.Quantity_To_Return__c = 1;
        rlWrappers[0].serialWrappers[0].serialList = new List<Serial__c>{ rlWrappers[0].serialWrappers[0].serialList[0], rlWrappers[0].serialWrappers[0].serialList[1] };
        
        
        rtvResult = ReceivingDocumentRTVExtV2.save(rlWrappers,new List<String>(),new List<String>());
        System.assert(rtvResult.success,rtvResult);
        
        List<Inventory_Transaction__c> itList = [SELECT Id,Type__c,Quantity__c,(SELECT Id,Type__c FROM Serial_Transactions__r) FROM Inventory_Transaction__c WHERE Receipt_Line__r.Receiving_Document__c = :dataSetup.rd.Id];
        System.assert(itList.size() == 1);
        System.assert(itList[0].Type__c == 'Purchase Order Return');
        System.assert(itList[0].Quantity__c == 1);
        System.assert(itList[0].Serial_Transactions__r.size() == 2);
        for (Serial_Transaction__c st:itList[0].Serial_Transactions__r)
            System.assert(st.Type__c == 'Return To Vendor');
    }

    private static testMethod void testRTVWithKGsPurchaseUOM() {
        RTVDataSetupKiloGrams dataSetup = new RTVDataSetupKiloGrams();

        ReceivingDocumentRTVExtV2 rdRTV = new ReceivingDocumentRTVExtV2(new ApexPages.StandardController(dataSetup.rd));
        String config = rdRTV.rtvGridConfigJson;
        String rlFL = rdRTV.receiptLineFieldListJSON;
        String skidFL = rdRTV.skidFieldListJSON;

        Test.StartTest();
        JsonResult rtvResult = ReceivingDocumentRTVExtV2.getRTVData(dataSetup.rd.Id);
        System.assert(rtvResult.success,rtvResult);
        System.assert(rtvResult.total == 1,rtvResult);

        List<LineWrapper> rlWrappers = (List<LineWrapper>)rtvResult.records;
        System.assert(rlWrappers.size() == 1);

        system.debug(LoggingLevel.ERROR, 'rtvResult'+JSON.serialize(rtvResult));


        Decimal QuantityToReturn=90;// in lbs
        rlWrappers[0].serialWrappers[0].skid.Quantity_To_Return__c = QuantityToReturn;// in lbs


        rtvResult = ReceivingDocumentRTVExtV2.save(rlWrappers,new List<String>(),new List<String>());
        System.assert(rtvResult.success,rtvResult);
        List<Inventory_Transaction__c> itList = [SELECT Id,Type__c,Quantity__c,(SELECT Id,Type__c FROM Serial_Transactions__r) FROM Inventory_Transaction__c WHERE Receipt_Line__r.Receiving_Document__c = :dataSetup.rd.Id];
        System.assert(itList.size() == 1);
        System.assert(itList[0].Type__c == 'Purchase Order Return');
        System.assert(itList[0].Quantity__c == 90,''+itList[0].Quantity__c);

        Receipt_Line__c rcptLine =  [select id,name, Quantity_Actually_Returned__c, Quantity_Still_Due_For_Putaway__c, Quantity_Returned_to_Supplier_for_Credit__c from Receipt_Line__c where Receiving_Document__c =:dataSetup.rd.Id ];
        system.debug(LoggingLevel.ERROR, 'Rcpt Line.'+JSON.serialize(rcptLine));
        system.assert(rcptLine.Quantity_Actually_Returned__c== QuantityToReturn/(rlWrappers[0].convFactor)); //Quantity_Actually_Returned__c = 40.9090909090909090909090909090909 = 90/2.2
        Test.StopTest();

    }
}