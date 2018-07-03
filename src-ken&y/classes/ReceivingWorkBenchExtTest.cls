@isTest
public class ReceivingWorkBenchExtTest {
         
    // TODO: This test method need to be refactored to avoid Too Many SOQL queries KNDY-9752 is logged to fix this.
    public static Sales_Order__c so = new Sales_Order__c(); 
    public static Sales_Order_Line__c soline = new Sales_Order_Line__c();
    public static Sales_Order_Line__c soline1 = new Sales_Order_Line__c();
    
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
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.periodList != null);
        System.assert(f.itemAttrObj2 != null);
        System.assert(f.customerShipTo != null);
        System.assert(f.location != null);
        delete configlist;
        System.assert(f.purchaseOrder != null);
        System.assert(f.workOrder != null);

        update new Component__c(Id = f.components[0].Id, Allocation_Required__c = true, Allocate_On_Receipt__c = true);
        WorkOrderPlanningService.release(new Set<Id>{ f.workOrder.Id });
    }

    public static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void autoAllocateWONoAttributes() {
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        update new Item__c(Id = poLine.Item__c,Item_Attribute__c = null);

        Material_Tracking__c mt = [SELECT Id FROM Material_Tracking__c WHERE Item__c = :poLine.Item__c];
        poLine.Material_Tracking__c = mt.Id;
        update poLine;

        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ poLine.Id },'Purchase Order',fuel.currencyUSD.Id).records[0];

        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ poLine.Id },new Set<String>{ 'purchase_order_line__c' });
        for (ReceivingWrapper rw:rWrappers) {
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 10;
                sw.skid.Packaging_UOM__r.Package_Class__r = null;
            }
        }

        Test.startTest();
        JsonResult result = ReceivingWorkBenchExt.receive(rWrappers,null,null,rd,null);
        System.assert(result.success,result);
        Test.stopTest();

        poLine = [SELECT Id,Status__c,Quantity_Still_Due__c,Quantity_Received__c,(SELECT Id,Quantity_Received__c,Status__c,Purchase_Order__c,Receiving_Document__r.Transaction_Type__c,Receiving_Document__r.Finalized__c,Receiving_Document__r.Status__c,Receiving_Document__r.Type__c FROM Receipt_Lines__r) FROM Purchase_Order_Line__c WHERE Id = :poLine.Id];
        System.assert(poLine.Status__c == 'Closed',poLine);
        System.assert(poLine.Quantity_Still_Due__c == 0,poLine);
        System.assert(poLine.Quantity_Received__c == 10,poLine);
        System.assert(poLine.Receipt_Lines__r.size() == 1,poLine.Receipt_Lines__r);

        Receipt_Line__c rl = poLine.Receipt_Lines__r[0];
        System.assert(rl.Purchase_Order__c == po.Id,rl);
        System.assert(rl.Status__c == 'Closed',rl);
        System.assert(rl.Quantity_Received__c == 10,rl);
        System.assert(rl.Receiving_Document__r.Status__c == 'Closed',rl.Receiving_Document__r);
        System.assert(rl.Receiving_Document__r.Finalized__c,rl.Receiving_Document__r);
        System.assert(rl.Receiving_Document__r.Type__c == 'Purchase Order Receipt',rl.Receiving_Document__r);
        System.assert(rl.Receiving_Document__r.Transaction_Type__c == 'Purchase Order Receipt',rl.Receiving_Document__r);

        Inventory_Transaction__c it = [SELECT Id,Quantity__c,Subtransaction_Type__c,Type__c FROM Inventory_Transaction__c WHERE Receipt_Line__c = :rl.Id];
        System.assert(it.Quantity__c == 10,it);
        System.assert(it.Subtransaction_Type__c == 'Purchase Order Receipt',it);   
        System.assert(it.Type__c == 'Purchase Order Receipt',it);
        /*Commenting auto allocate
        mt = [SELECT Id,Work_Order__r.Status__c,Quantity_Allocated__c,(SELECT Id FROM SKIDs__r WHERE Type__c = 'Allocated') FROM Material_Tracking__c WHERE Id = :mt.Id];
        System.assert(mt.Work_Order__r.Status__c == 'In Process',mt.Work_Order__r);
        System.assert(mt.Quantity_Allocated__c == 10,mt);
        System.assert(mt.SKIDs__r.size() == 1,mt.SKIDs__r);
        */
    }

    private static testMethod void autoAllocateWOAttributes() {
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        Material_Tracking__c mt = [SELECT Id FROM Material_Tracking__c WHERE Item__c = :poLine.Item__c];
        poLine.Material_Tracking__c = mt.Id;
        update poLine;

        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ poLine.Id },'Purchase Order',fuel.currencyUSD.Id).records[0];

        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ poLine.Id },new Set<String>{ 'purchase_order_line__c' });
        for (ReceivingWrapper rw:rWrappers) {
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 10;
                sw.skid.Lot_Number__c = 'LOT1';
                sw.skid.Expiration_Date__c = System.today() + 10;
                sw.skid.Packaging_UOM__r.Package_Class__r = null;
            }
        }

        Test.startTest();
        JsonResult result = ReceivingWorkBenchExt.receive(rWrappers,null,null,rd,null);
        System.assert(result.success,result);
        Test.stopTest();

        poLine = [SELECT Id,Status__c,Quantity_Still_Due__c,Quantity_Received__c,(SELECT Id,Quantity_Received__c,Status__c,Purchase_Order__c,Receiving_Document__r.Transaction_Type__c,Receiving_Document__r.Finalized__c,Receiving_Document__r.Status__c,Receiving_Document__r.Type__c FROM Receipt_Lines__r) FROM Purchase_Order_Line__c WHERE Id = :poLine.Id];
        System.assert(poLine.Status__c == 'Closed',poLine);
        System.assert(poLine.Quantity_Still_Due__c == 0,poLine);
        System.assert(poLine.Quantity_Received__c == 10,poLine);
        System.assert(poLine.Receipt_Lines__r.size() == 1,poLine.Receipt_Lines__r);

        Receipt_Line__c rl = poLine.Receipt_Lines__r[0];
        System.assert(rl.Purchase_Order__c == po.Id,rl);
        System.assert(rl.Status__c == 'Closed',rl);
        System.assert(rl.Quantity_Received__c == 10,rl);
        System.assert(rl.Receiving_Document__r.Status__c == 'Closed',rl.Receiving_Document__r);
        System.assert(rl.Receiving_Document__r.Finalized__c,rl.Receiving_Document__r);
        System.assert(rl.Receiving_Document__r.Type__c == 'Purchase Order Receipt',rl.Receiving_Document__r);
        System.assert(rl.Receiving_Document__r.Transaction_Type__c == 'Purchase Order Receipt',rl.Receiving_Document__r);

        Inventory_Transaction__c it = [SELECT Id,Quantity__c,Subtransaction_Type__c,Type__c FROM Inventory_Transaction__c WHERE Receipt_Line__c = :rl.Id];
        System.assert(it.Quantity__c == 10,it);
        System.assert(it.Subtransaction_Type__c == 'Purchase Order Receipt',it);   
        System.assert(it.Type__c == 'Purchase Order Receipt',it);
        /*Commenting autoallocate
        mt = [SELECT Id,Work_Order__r.Status__c,Quantity_Allocated__c,(SELECT Id FROM SKIDs__r WHERE Type__c = 'Allocated') FROM Material_Tracking__c WHERE Id = :mt.Id];
        System.assert(mt.Work_Order__r.Status__c == 'In Process',mt.Work_Order__r);
        System.assert(mt.Quantity_Allocated__c == 10,mt);
        System.assert(mt.SKIDs__r.size() == 1,mt.SKIDs__r);
        */
    }

    private static testMethod void autoAllocateWOSerials() {
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        update new Item__c(Id = poLine.Item__c,Item_Attribute__c = fuel.itemAttrObj2.Id);

        Material_Tracking__c mt = [SELECT Id FROM Material_Tracking__c WHERE Item__c = :poLine.Item__c];
        poLine.Material_Tracking__c = mt.Id;
        update poLine;

        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ poLine.Id },'Purchase Order',fuel.currencyUSD.Id).records[0];

        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ poLine.Id },new Set<String>{ 'purchase_order_line__c' });
        for (ReceivingWrapper rw:rWrappers) {
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 10;
                sw.skid.Lot_Number__c = 'LOT1';
                sw.skid.Expiration_Date__c = System.today() + 10;
				sw.skid.Packaging_UOM__r.Package_Class__r = null;
                sw.serialList = new List<Serial__c>();
                for (Integer i=0;i<10;i++) {
                    sw.serialList.add(new Serial__c(Name = 'SERIAL' + i));
                }
            }
        }

        Test.startTest();
        JsonResult result = ReceivingWorkBenchExt.receive(rWrappers,null,null,rd,null);
        System.assert(result.success,result);
        Test.stopTest();

        poLine = [SELECT Id,Status__c,Quantity_Still_Due__c,Quantity_Received__c,(SELECT Id,Quantity_Received__c,Status__c,Purchase_Order__c,Receiving_Document__r.Transaction_Type__c,Receiving_Document__r.Finalized__c,Receiving_Document__r.Status__c,Receiving_Document__r.Type__c FROM Receipt_Lines__r) FROM Purchase_Order_Line__c WHERE Id = :poLine.Id];
        System.assert(poLine.Status__c == 'Closed',poLine);
        System.assert(poLine.Quantity_Still_Due__c == 0,poLine);
        System.assert(poLine.Quantity_Received__c == 10,poLine);
        System.assert(poLine.Receipt_Lines__r.size() == 1,poLine.Receipt_Lines__r);

        Receipt_Line__c rl = poLine.Receipt_Lines__r[0];
        System.assert(rl.Purchase_Order__c == po.Id,rl);
        System.assert(rl.Status__c == 'Closed',rl);
        System.assert(rl.Quantity_Received__c == 10,rl);
        System.assert(rl.Receiving_Document__r.Status__c == 'Closed',rl.Receiving_Document__r);
        System.assert(rl.Receiving_Document__r.Finalized__c,rl.Receiving_Document__r);
        System.assert(rl.Receiving_Document__r.Type__c == 'Purchase Order Receipt',rl.Receiving_Document__r);
        System.assert(rl.Receiving_Document__r.Transaction_Type__c == 'Purchase Order Receipt',rl.Receiving_Document__r);

        Inventory_Transaction__c it = [SELECT Id,Quantity__c,Subtransaction_Type__c,Type__c,(SELECT Id FROM Serial_Transactions__r) FROM Inventory_Transaction__c WHERE Receipt_Line__c = :rl.Id];
        System.assert(it.Quantity__c == 10,it);
        System.assert(it.Subtransaction_Type__c == 'Purchase Order Receipt',it);   
        System.assert(it.Type__c == 'Purchase Order Receipt',it);
        System.assert(it.Serial_Transactions__r.size() == 10,it.Serial_Transactions__r);
        /*
        mt = [SELECT Id,Work_Order__r.Status__c,Quantity_Allocated__c,(SELECT Id FROM SKIDs__r WHERE Type__c = 'Allocated') FROM Material_Tracking__c WHERE Id = :mt.Id];
        System.assert(mt.Work_Order__r.Status__c == 'In Process',mt.Work_Order__r);
        System.assert(mt.Quantity_Allocated__c == 10,mt);
        System.assert(mt.SKIDs__r.size() == 1,mt.SKIDs__r);*/
    }

    private static testMethod void autoAllocateWOASN() {
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];
        poLine.Packaging_UOM__r = fuel.uomObj;
        poLine.Packaging_UOM__c = fuel.uomObj.Id;
        update poLine;

        FOB_Terms__c fobTermOrigin = new FOB_Terms__c(
            Name = 'Origin',
            FOB_Point__c = 'Origin'
        );
        insert fobTermOrigin;

        po.FOB_Term__c = fobTermOrigin.Id;
        update po;

        Material_Tracking__c mt = [SELECT Id FROM Material_Tracking__c WHERE Item__c = :poLine.Item__c];
        poLine.Material_Tracking__c = mt.Id;
        update poLine;

        ASN__c asn = new ASN__c(
            Company__c = fuel.company.Id,
            Supplier__c = fuel.supplier.Id,
            Facility__c = fuel.facility2.Id,
            FOB__c = fobTermOrigin.Id,
            Status__c = 'Draft',
            Transaction_Date__c = System.today(),
            Currency__c = fuel.currencyUSD.Id,
            Transaction_Type__c = 'Purchase Order ASN'
        );
        insert asn;

        ASN_Line__c asnLine = new ASN_Line__c(
            Purchase_Order__c = po.Id,
            Purchase_Order_Line__c = poLine.Id,
            Purchase_Order_Line__r = poLine,
            Item__c = fuel.itemList[2].Id,
            Item__r = fuel.itemList[2],
            Quantity_Shipped__c = 10,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = fuel.company.Id,
            Supplier__c = fuel.supplier.Id,
            Facility__c = fuel.facility2.Id
        );
        insert asnLine;
        asnLine.Item__r.Item_Attribute__r = fuel.itemAttrObj;
        Test.startTest();
        SKID__c skid = new SKID__c(
            ASN_Line__c = asnLine.Id,
            Facility2__c = asnLine.Facility__c,
            Location__c = asnLine.Location__c,
            Type__c = 'In-Transit',
            Item__c = asnLine.Item__c,
            Item__r = asnLine.Item__r,
            Company__c = fuel.company.Id,
            Expiration_Date__c = System.today() + 10,
            Lot_Number__c = 'LOT 1',
            Quantity__c = 10,
            Quantity_Stocking_UOM__c = 10,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );

        ASNAddManageExt.ASNLineWrapper asnLineWrapper = new ASNAddManageExt.ASNLineWrapper(asnLine,new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,new List<Serial__c>()) });        
        asnLineWrapper.trackedAttributes = SkidService3.trackedAttributes(null,null,asnLine.Item__r);

        ASNAddManageExt.saveAction(asn,null,new List<ASNAddManageExt.ASNLineWrapper>{ asnLineWrapper },new List<ASNAddManageExt.ASNLineWrapper>(),new List<ASNAddManageExt.ASNLineWrapper>(),new List<SkidService3.SerialWrapper>(),null,null);
        ASNAddManageExt.HeaderActions(asn,'confirm',null);

        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ asnLine.Id },'ASN',fuel.currencyUSD.Id).records[0];
		
        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ asnLine.Id },new Set<String>{ 'asn_line__c' });
        for(ReceivingWrapper rw: rWrappers){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                
                 sw.skid.Packaging_UOM__r.Package_Class__r = null;
                 
            }
        }
        JsonResult result = ReceivingWorkBenchExt.receive(rWrappers,null,null,rd,null);
        System.assert(result.success,result);

        asnLine = [SELECT Id,Status__c FROM ASN_Line__c WHERE Id = :asnLine.Id];
        System.assert(asnLine.Status__c == 'Closed',asnLine);


        Receipt_Line__c rl = [SELECT Id,Quantity_Received__c,Status__c,Purchase_Order__c,Receiving_Document__r.Transaction_Type__c,Receiving_Document__r.Finalized__c,Receiving_Document__r.Status__c,Receiving_Document__r.Type__c FROM Receipt_Line__c WHERE Receiving_Document__r.Type__c != 'In-Transit'];
        System.assert(rl.Purchase_Order__c == po.Id,rl);
        System.assert(rl.Status__c == 'Closed',rl);
        System.assert(rl.Quantity_Received__c == 10,rl);
        System.assert(rl.Receiving_Document__r.Status__c == 'Closed',rl.Receiving_Document__r);
        System.assert(rl.Receiving_Document__r.Finalized__c,rl.Receiving_Document__r);
        System.assert(rl.Receiving_Document__r.Type__c == 'Purchase Order Receipt',rl.Receiving_Document__r);
        System.assert(rl.Receiving_Document__r.Transaction_Type__c == 'In-Transit Purchase Order Receipt',rl.Receiving_Document__r);

        Inventory_Transaction__c it = [SELECT Id,Quantity__c,From_SKID__c,To_SKID__c,Subtransaction_Type__c,Type__c FROM Inventory_Transaction__c WHERE Receipt_Line__c = :rl.Id];
        System.assert(it.Quantity__c == 10,it);
        System.assert(it.From_SKID__c == null,it);
        System.assert(it.To_SKID__c != null,it);
        System.assert(it.Subtransaction_Type__c == 'Purchase Order Receipt',it);   
        System.assert(it.Type__c == 'Purchase Order Receipt',it);
        /*Commenting
        mt = [SELECT Id,Work_Order__r.Status__c,Quantity_Allocated__c,(SELECT Id FROM SKIDs__r WHERE Type__c = 'Allocated') FROM Material_Tracking__c WHERE Id = :mt.Id];
        System.assert(mt.Work_Order__r.Status__c == 'In Process',mt.Work_Order__r);
        System.assert(mt.Quantity_Allocated__c == 10,mt);
        System.assert(mt.SKIDs__r.size() == 1,mt.SKIDs__r);*/
        Test.stopTest();
    }

    private static testMethod void autoUnallocateWO() {
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        Material_Tracking__c mt = [SELECT Id FROM Material_Tracking__c WHERE Item__c = :poLine.Item__c];
        poLine.Material_Tracking__c = mt.Id;
        poLine.Packaging_UOM__c = fuel.uomObj.Id;
        update poLine;

        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ poLine.Id },'Purchase Order',fuel.currencyUSD.Id).records[0];

        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ poLine.Id },new Set<String>{ 'purchase_order_line__c' });
        for (ReceivingWrapper rw:rWrappers) {
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 10;
                sw.skid.Lot_Number__c = 'LOT1';
                sw.skid.Expiration_Date__c = System.today() + 10;
                sw.skid.Packaging_UOM__c = poLine.Packaging_UOM__c;
                sw.skid.Packaging_UOM__r = fuel.uomObj;
                sw.skid.Packaging_UOM__r.Package_Class__r = null;
            }
        }

        Test.startTest();
        JsonResult result = ReceivingWorkBenchExt.receive(rWrappers,null,null,rd,null);
        System.assert(result.success,result);

        ReceivingDocumentVoidCancelService vcs = new ReceivingDocumentVoidCancelService(new List<Receiving_Document__c>{ rd });
        vcs.getBusinessVoidCancelDetails(new List<Receiving_Document__c>{ rd });
        vcs.businessVoid(new List<Receiving_Document__c>{ rd });

        Test.stopTest();

        List<SKID__c> allocatedSkids = [SELECT Id FROM SKID__c WHERE Type__c = 'Allocated'];
        //System.assert(allocatedSkids.size() == 0);

        Receipt_Line__c rl = [SELECT Id,Status__c,Receiving_Document__r.Status__c FROM Receipt_Line__c WHERE Receiving_Document__c = :rd.Id];
        System.assert(rl.Receiving_Document__r.Status__c == 'Void',rl.Receiving_Document__r);
        System.assert(rl.Status__c == 'Void',rl);
    }

    private static testMethod void autoUnallocateWOASN() {
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        FOB_Terms__c fobTermOrigin = new FOB_Terms__c(
            Name = 'Origin',
            FOB_Point__c = 'Origin'
        );
        insert fobTermOrigin;

        po.FOB_Term__c = fobTermOrigin.Id;
        update po;

        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        Material_Tracking__c mt = [SELECT Id FROM Material_Tracking__c WHERE Item__c = :poLine.Item__c];
        poLine.Material_Tracking__c = mt.Id;
        poLine.Packaging_UOM__c = fuel.uomObj.Id;
        update poLine;

        delete c;

        ASN__c asn = new ASN__c(
            Company__c = fuel.company.Id,
            Supplier__c = fuel.supplier.Id,
            Facility__c = fuel.facility2.Id,
            FOB__c = fobTermOrigin.Id,
            Status__c = 'Draft',
            Transaction_Date__c = System.today(),
            Currency__c = fuel.currencyUSD.Id,
            Transaction_Type__c = 'Purchase Order ASN'
        );
        insert asn;

        ASN_Line__c asnLine = new ASN_Line__c(
            Purchase_Order__c = po.Id,
            Purchase_Order_Line__c = poLine.Id,
            Purchase_Order_Line__r = poLine,
            Item__c = fuel.itemList[2].Id,
            Item__r = fuel.itemList[2],
            Quantity_Shipped__c = 10,
            Quantity_Received__c = 0,
            Unit_Price__c = 10,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = fuel.company.Id,
            Supplier__c = fuel.supplier.Id,
            Facility__c = fuel.facility2.Id
        );
        insert asnLine;
        asnLine.Item__r.Item_Attribute__r = fuel.itemAttrObj;

        SKID__c skid = new SKID__c(
            ASN_Line__c = asnLine.Id,
            Facility2__c = asnLine.Facility__c,
            Location__c = asnLine.Location__c,
            Type__c = 'In-Transit',
            Item__c = asnLine.Item__c,
            Item__r = asnLine.Item__r,
            Company__c = fuel.company.Id,
            Expiration_Date__c = System.today() + 10,
            Lot_Number__c = 'LOT 1',
            Quantity__c = 10,
            Quantity_Stocking_UOM__c = 10,
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
        	Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c
        );

        ASNAddManageExt.ASNLineWrapper asnLineWrapper = new ASNAddManageExt.ASNLineWrapper(asnLine,new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,new List<Serial__c>()) });
        asnLineWrapper.trackedAttributes = SkidService3.trackedAttributes(null,null,asnLine.Item__r);

        ASNAddManageExt.saveAction(asn,null,new List<ASNAddManageExt.ASNLineWrapper>{ asnLineWrapper },new List<ASNAddManageExt.ASNLineWrapper>(),new List<ASNAddManageExt.ASNLineWrapper>(),new List<SkidService3.SerialWrapper>(),null,null);
        ASNAddManageExt.HeaderActions(asn,'confirm',null);

        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ asnLine.Id },'ASN',fuel.currencyUSD.Id).records[0];

        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ asnLine.Id },new Set<String>{ 'asn_line__c' });

        Test.startTest();
        
		for(ReceivingWrapper rw: rWrappers){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                 sw.skid.Packaging_UOM__c = poLine.Packaging_UOM__c;
                 sw.skid.Packaging_UOM__r = fuel.uomObj;
                 sw.skid.Packaging_UOM__r.Package_Class__r = null;
                 sw.skid.Packaging_UOM__r.Package_Class__r = null;
                 
            }
        }
        JsonResult result = ReceivingWorkBenchExt.receive(rWrappers,null,null,rd,null);
        System.assert(result.success,result);

        ReceivingDocumentVoidCancelService vcs = new ReceivingDocumentVoidCancelService(new List<Receiving_Document__c>{ rd });
        vcs.businessVoid(new List<Receiving_Document__c>{ rd });

        

        //List<SKID__c> allocatedSkids = [SELECT Id FROM SKID__c WHERE Type__c = 'Allocated'];
        //System.assert(allocatedSkids.size() == 0);
        
        Receipt_Line__c rl = [SELECT Id,Status__c,Receiving_Document__r.Status__c FROM Receipt_Line__c WHERE Receiving_Document__c = :rd.Id];
        Test.stopTest();
        System.assert(rl.Receiving_Document__r.Status__c == 'Void',rl.Receiving_Document__r);
        System.assert(rl.Status__c == 'Void',rl);
    }

    private static testMethod void autoUnallocateWONotAllocated() {
        Map<Id,Lot__c> lots = new Map<Id,Lot__c>();
        List<SKID__c> skids = new List<SKID__c>();
        for (Item__c item:fuel.itemList) {
            SKID__c skid1 = new SKID__c(
                Company__c = fuel.company.Id,
                Item__c = item.Id,
                Facility2__c = fuel.facility2.Id,
                Location__c = fuel.location3.Id,
                Quantity__c = 100,
                Quantity_Stocking_UOM__c = 100,
                Type__c = SkidService3.SKID_TYPE_LOCATION,
                Expiration_Date__c = System.today() + 365,
                Lot_Number__c = 'ABC',
                Stocking_UOM__c = item.Stocking_UOM__c,
            	Packaging_UOM__c = item.Stocking_UOM__c
            );

            lots.put(item.Id,new Lot__c(Name = 'ABC', Item__c = item.Id, Company__c = fuel.company.Id));

            SKID__c skid2 = skid1.clone(false,true);
            skid2.Location__c = fuel.location5.Id;

            skids.add(skid1);
            skids.add(skid2);
        }
        insert lots.values();

        for (SKID__c skid:skids) {
            skid.Lot__c = lots.get(skid.Item__c).Id;
        }
        insert skids;

        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        Material_Tracking__c mt = [SELECT Id,Work_Order__c FROM Material_Tracking__c WHERE Item__c = :poLine.Item__c];
        poLine.Material_Tracking__c = mt.Id;
        poLine.Packaging_UOM__c = fuel.uomObj.Id;
        update poLine;

        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ poLine.Id },'Purchase Order',fuel.currencyUSD.Id).records[0];

        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ poLine.Id },new Set<String>{ 'purchase_order_line__c' });
        for (ReceivingWrapper rw:rWrappers) {
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                sw.skid.Quantity__c = 10;
                sw.skid.Lot_Number__c = 'LOT1';
                sw.skid.Expiration_Date__c = System.today() + 10;
                sw.skid.Packaging_UOM__r.Package_Class__r = null;
            }
        }

        Test.startTest();

        JsonResult result = ReceivingWorkBenchExt.receive(rWrappers,null,null,rd,null);
        System.assert(result.success,result);

        List<LineWrapper> mData = (List<LineWrapper>)WorkOrderAllocationExt.getMaterialData(mt.Work_Order__c).records;
        for (LineWrapper wrapper:mData) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                if (sw.skid.Quantity_Allocated__c > 0) {
                    sw.skid.Input_Quantity__c = -sw.skid.Quantity_Allocated__c;
                } else if (sw.skid.Location__c == fuel.location3.Id) {
                    sw.skid.Input_Quantity__c = 3;
                }
            }
        }
        WorkOrderAllocationExt.save(mData,new List<String>(),new List<String>());

        ReceivingDocumentVoidCancelService vcs = new ReceivingDocumentVoidCancelService(new List<Receiving_Document__c>{ rd });
        vcs.getBusinessVoidCancelDetails(new List<Receiving_Document__c>{ rd });
        vcs.businessVoid(new List<Receiving_Document__c>{ rd });

        Test.stopTest();
        /* Commenting out for CRP 1..
        List<SKID__c> allocatedSkids = [SELECT Id,Quantity__c,Location__c,Lot_Number__c FROM SKID__c WHERE Type__c = 'Allocated'];
        System.assert(allocatedSkids.size() == 1);
        System.assert(allocatedSkids[0].Quantity__c == 3,allocatedSkids);
        System.assert(allocatedSkids[0].Location__c == fuel.location3.Id,allocatedSkids);
        System.assert(allocatedSkids[0].Lot_Number__c == 'ABC',allocatedSkids);
        */
        Receipt_Line__c rl = [SELECT Id,Status__c,Receiving_Document__r.Status__c FROM Receipt_Line__c WHERE Receiving_Document__c = :rd.Id];
        System.assert(rl.Receiving_Document__r.Status__c == 'Void',rl.Receiving_Document__r);
        System.assert(rl.Status__c == 'Void',rl);
    }
    
    static testMethod void receiveASN() {
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];
        
        poLine.Packaging_UOM__r = fuel.uomObj;
        poLine.Packaging_UOM__c = fuel.uomObj.Id;
        update poLine;
        
        FOB_Terms__c fobTermOrigin = new FOB_Terms__c(
            Name = 'Origin',
            FOB_Point__c = 'Origin'
        );
        insert fobTermOrigin;
        
        Purchase_Order_Line__c poLine1 = new Purchase_Order_Line__c(
            Purchase_Order__c = po.Id,
            Order_Quantity__c = 15,
            Unit_Price__c = 24,
            Item__c = fuel.itemList[1].Id,
            Description__c = fuel.itemList[1].Description__c,
            Purchase_UOM__c = fuel.itemList[1].Purchasing_UOM__c,
            Packaging_UOM__c = fuel.itemList[1].Stocking_UOM__c,
            Company__c = fuel.company.Id,
            Need_Date__c = System.today() + 7,
            Delivery_Facility__c = fuel.facility2.Id,
            Delivery_Location__c = fuel.location2.Id,
            Supplier__c = fuel.supplier.Id,
            Line__c = 2
        );
        poLine1.Packaging_UOM__r = fuel.uomObj;
        poLine1.Packaging_UOM__c = fuel.uomObj.Id;
        insert poLine1;

        po.FOB_Term__c = fobTermOrigin.Id;
        po.Approval_Status__c = 'Approved';
        update po;
        
        ASN__c asn = new ASN__c(
            Company__c = fuel.company.Id,
            Supplier__c = fuel.supplier.Id,
            Facility__c = fuel.facility2.Id,
            FOB__c = fobTermOrigin.Id,
            Status__c = 'Draft',
            Transaction_Date__c = System.today(),
            Currency__c = fuel.currencyUSD.Id,
            Transaction_Type__c = 'Purchase Order ASN'
        );
        insert asn;
        
        ASN_Line__c asnLine = new ASN_Line__c(
            Purchase_Order__c = po.Id,
            Purchase_Order_Line__c = poLine.Id,
            Item__c = fuel.itemList[2].Id,
            Item__r = fuel.itemList[2],
            Quantity_Shipped__c = 10,
            Quantity_Received__c = 0,
            Unit_Price__c = 1,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = fuel.company.Id,
            Supplier__c = fuel.supplier.Id,
            Facility__c = fuel.facility2.Id
        );
        insert asnLine;
        asnLine.Item__r.Item_Attribute__r = fuel.itemAttrObj;

        fuel.itemList[1].Item_Attribute__c = null;
        update fuel.itemList[1];
        
        ASN_Line__c asnLine1 = new ASN_Line__c(
            Purchase_Order__c = po.Id,
            Purchase_Order_Line__c = poLine1.Id,
            Item__c = fuel.itemList[1].Id,
            Item__r = fuel.itemList[1],
            Quantity_Shipped__c = 15,
            Quantity_Received__c = 0,
            Unit_Price__c = 1,
            Status__c = 'New',
            ASN__c = asn.Id,
            Company__c = fuel.company.Id,
            Supplier__c = fuel.supplier.Id,
            Facility__c = fuel.facility2.Id
        );
        insert asnLine1;

        SKID__c skid = new SKID__c(
            ASN_Line__c = asnLine.Id,
            Facility2__c = asnLine.Facility__c,
            Location__c = asnLine.Location__c,
            Type__c = 'In-Transit',
            Item__c = asnLine.Item__c,
            Item__r = asnLine.Item__r,
            Company__c = asn.Company__c,
            Expiration_Date__c = System.today() + 10,
            Lot_Number__c = 'LOT 1',
            Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c,
            Quantity__c = 10
        );

        SKID__c skid1 = new SKID__c(
            ASN_Line__c = asnLine1.Id,
            Facility2__c = asnLine1.Facility__c,
            Location__c = asnLine1.Location__c,
            Type__c = 'In-Transit',
            Item__c = asnLine1.Item__c,
            Item__r = asnLine1.Item__r,
            Company__c = asn.Company__c,
            Stocking_UOM__c = asnLine1.Item__r.Stocking_UOM__c,
            Packaging_UOM__c = asnLine1.Item__r.Stocking_UOM__c,
            Quantity__c = 15
        );

        ASNAddManageExt.ASNLineWrapper asnLineWrapper = new ASNAddManageExt.ASNLineWrapper(asnLine,new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid,new List<Serial__c>()) });
        asnLineWrapper.trackedAttributes = SkidService3.trackedAttributes(null,null,asnLine.Item__r);

        ASNAddManageExt.ASNLineWrapper asnLineWrapper1 = new ASNAddManageExt.ASNLineWrapper(asnLine1,new List<SkidService3.SerialWrapper>{ new SkidService3.SerialWrapper(skid1,new List<Serial__c>()) });
        asnLineWrapper1.trackedAttributes = SkidService3.trackedAttributes(null,null,asnLine1.Item__r);
        Test.startTest();
        ASNAddManageExt.saveAction(asn,null,new List<ASNAddManageExt.ASNLineWrapper>{ asnLineWrapper },new List<ASNAddManageExt.ASNLineWrapper>{ asnLineWrapper1 },new List<ASNAddManageExt.ASNLineWrapper>(),new List<SkidService3.SerialWrapper>(),null,null);
        
        ASNAddManageExt.HeaderActions(asn,'confirm',null);

        String config = ReceivingWorkBenchExt.getGridConfig('ASN').get('config');

        JsonResult result = ReceivingWorkBenchExt.getLinesToReceive(config,asn.Facility__c,asnLine.Item__c,asn.Supplier__c,asn.FOB__c,asn.Id,null,null,null,null);
        System.assert(result.success,result);
        System.assert(result.records.size() == 1,result);

        result = ReceivingWorkBenchExt.getLinesToReceive(config,asn.Facility__c,null,null,null,asn.Id,null,null,null,null);
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result);

        result = ReceivingWorkBenchExt.getLinesToReceive(config,null,null,null,null,asn.Id,null,null,null,null);
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result);

        result = ReceivingWorkBenchExt.getList(new List<Id>{ asnLine.Id, asnLine1.Id },'ASN');
        System.assert(result.success,result);
        System.assert(result.records.size() == 2,result);

        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ asnLine.Id, asnLine1.Id },'ASN',fuel.currencyUSD.Id).records[0];

        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null,new Set<Id>{ asnLine.Id, asnLine1.Id },new Set<String>{ 'asn_line__c' });
        for (ReceivingWrapper rw:rWrappers) {
            for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
                if (sw.skid.Item__c == asnLine.Item__c) {
                    sw.skid.Quantity__c = 4;
                }
                sw.skid.Packaging_UOM__c = fuel.uomObj.Id;
                sw.skid.Packaging_UOM__r = fuel.uomObj;
                sw.skid.Packaging_UOM__r.Package_Class__r = null;
            }
        }
        result = ReceivingWorkBenchExt.receive(rWrappers,null,null,rd,null);
        System.assert(result.success,result);

        List<ASN_Line__c> asnLines = [SELECT Id,Status__c FROM ASN_Line__c WHERE ASN__c = :asn.Id];
        for (ASN_Line__c asnl:asnLines) {
            if (asnl.Id == asnLine.Id) {
                System.assert(asnl.Status__c == 'Open',asnl);
            } else if (asnl.Id == asnLine1.Id) {
                System.assert(asnl.Status__c == 'Closed',asnl);
            }
        }

        List<Receipt_Line__c> receiptLines = [SELECT Id,Purchase_Order__c,Status__c,ASN_Line__c,Quantity_Received__c,Receiving_Document__r.Status__c,Receiving_Document__r.Finalized__c,Receiving_Document__r.Type__c,Receiving_Document__r.Transaction_Type__c FROM Receipt_Line__c WHERE Receipt_Line__c.Receiving_Document__r.Type__c != 'In-Transit'];
        System.assert(receiptLines.size() == 2,receiptLines);
        for (Receipt_Line__c rl:receiptLines) {
            System.assert(rl.Purchase_Order__c == asnLine.Purchase_Order__c,rl);
            System.assert(rl.Status__c == 'Closed',rl);
            System.assert(rl.Receiving_Document__r.Status__c == 'Closed',rl.Receiving_Document__r);
            System.assert(rl.Receiving_Document__r.Finalized__c,rl.Receiving_Document__r);
            System.assert(rl.Receiving_Document__r.Type__c == 'Purchase Order Receipt',rl.Receiving_Document__r);
            System.assert(rl.Receiving_Document__r.Transaction_Type__c == 'In-Transit Purchase Order Receipt',rl.Receiving_Document__r);

            if (rl.ASN_Line__c == asnLine.id) {
                System.assert(rl.Quantity_Received__c == 4,rl);
            } else if (rl.ASN_Line__c == asnLine1.id) {
                System.assert(rl.Quantity_Received__c == 15,rl);
            } 
        }
               
        List<Inventory_Transaction__c> itList = [SELECT Id,Item__c,From_SKID__c,To_SKID__c,Quantity__c,Type__c,Subtransaction_Type__c FROM Inventory_Transaction__c WHERE Receipt_Line__c IN :receiptLines];
        System.assert(itList.size() == 2,itList);
        Test.stopTest();
        for (Inventory_Transaction__c it:itList) {
            if (it.Item__c == asnLine.Item__c){
                //System.assert(it.From_SKID__c != null,it);
                System.assert(it.To_SKID__c != null,it);
                System.assert(it.Quantity__c == 4,it);
            } else if (it.Item__c == asnLine1.Item__c) {
                System.assert(it.From_SKID__c == null,it);
                System.assert(it.To_SKID__c != null,it);
                System.assert(it.Quantity__c == 15,it);
            }

            System.assert(it.Subtransaction_Type__c == 'Purchase Order Receipt',it);
            system.assert(it.Type__c == 'Purchase Order Receipt',it); 
        }
    }
    
    static testMethod void SearchASN_Errors(){     
    
    
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poline = fuel.purchaseOrderLines[0];
        
        Purchase_Order_Line__c poLine1 = new Purchase_Order_Line__c();{
                poLine1.Purchase_Order__c = po.Id;
                poLine1.Order_Quantity__c = 15;     
                poLine1.Unit_Price__c = 24;
                poLine1.Item__c = fuel.itemList[1].Id;
                poLine1.Description__c = fuel.itemList[1].Description__c;
                poLine1.Purchase_UOM__c = fuel.itemList[1].Purchasing_UOM__c;
                poLine1.Company__c = fuel.company.id;
                poLine1.Need_Date__c = system.today() + 7;
                poLine1.Delivery_Facility__c = fuel.facility2.id;
                poLine1.Delivery_Location__c = fuel.location2.ID;
                poLine1.Supplier__c = fuel.supplier.Id;
                poLine1.Line__c = 2;
                insert poLine1; 
        }
        
        po.Approval_Status__c = null;
        update po;  
        FOB_Terms__c fobTerm = new FOB_Terms__c();{
            fobTerm.Name = 'test term destination';
            fobTerm.FOB_Point__c = 'Origin';
            insert fobTerm;
        }
        
        ASN__c asn = new ASN__c();{
            asn.Company__c = fuel.company.id;
            asn.Supplier__c = fuel.supplier.id;
            asn.Facility__c = fuel.facility2.id;
            asn.FOB__c = fobTerm.id;      
            asn.Status__c = 'Draft';
            asn.Transaction_Date__c = system.today();
            asn.Currency__c = fuel.currencyUSD.id;
            asn.Transaction_Type__c = 'Purchase Order ASN';
            insert asn;
        }
        
        ASN_Line__c asnLine = new ASN_Line__c();{
            asnLine.Purchase_Order__c = po.id;
            asnLine.Purchase_Order_Line__c = poLine.id;
            asnLine.Item__c = fuel.itemList[2].id;
            asnLine.Item__r = fuel.itemList[2];
            asnLine.Quantity_Shipped__c = 10;
            asnLine.Quantity_Received__c = 0;
            asnLine.Unit_Price__c = 10;
            asnLine.Status__c = 'New';
            asnLine.ASN__c = asn.id;
            asnLine.Company__c = fuel.company.id;
            asnLine.Supplier__c = fuel.supplier.id;
            asnLine.Facility__c = fuel.facility2.id;
            insert asnLine;
        }
        fuel.itemList[1].item_attribute__c = null;
        update fuel.itemList[1];
        
        fuel.itemList[4].item_attribute__c = null;
        update fuel.itemList[4];
        
        ASN_Line__c asnLine1 = new ASN_Line__c();{
            asnLine1.Purchase_Order__c = fuel.purchaseOrder.id;
            asnLine1.Purchase_Order_Line__c = poLine1.id;
            asnLine1.Item__c = fuel.itemList[1].id;
            asnLine1.Item__r = fuel.itemList[1];
            asnLine1.Quantity_Shipped__c = 15;
            asnLine1.Quantity_Received__c = 0;
            asnLine1.Unit_Price__c = 12;
            asnLine1.Status__c = 'New';
            asnLine1.ASN__c = asn.id;
            asnLine1.Company__c = fuel.company.id;
            asnLine1.Supplier__c = fuel.supplier.id;
            asnLine1.Facility__c = fuel.facility2.id;
            insert asnLine1;
        }
     
        
        ReceivingWorkBenchExt.setGridConfig('ASN', asnLine1.Facility__c);

            
        
        //Create ASN with inTransit SKID       
       
        ASN__c queriedASN = [Select Id,Name, Status__c from ASN__c where Id =:asn.Id]; 
        String docnum = queriedASN.Id;
        String facilityId = asnLine.Facility__c;
        String supplierId = asnLine.Supplier__c;
        String itemId = asnLine.Item__c;        
        String fobId = asn.FOB__c;
        
        //String needDate = (poLine.Need_Date__c).toString();
                
                        
        ApexPages.StandardController setCon = new Apexpages.StandardController(asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
        list<SkidService3.SerialWrapper> serialwrapperlist = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> serialwrapperlist1 = new list<SkidService3.SerialWrapper>();
        
        SkidService3.SerialWrapper aserialWrapper;
        SkidService3.SerialWrapper bserialWrapper;
        

        asnLine.Item__r.Item_Attribute__r = fuel.itemAttrObj;        
        

        List <ASNAddManageExt.ASNLineWrapper> updateasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper a;
        asnLine.Quantity_Shipped__c = 5;
        
        SKID__c skid1 = new SKID__c();
        skid1.ASN_Line__c = asnLine.id;
        skid1.Location__c = asnLine.Location__c;
        skid1.Type__c = 'In-Transit';
        skid1.Item__c = asnLine.Item__c;
        skid1.Item__r = asnLine.Item__r;
        skid1.Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c;
        skid1.Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c;
        skid1.Company__c = asn.Company__c;
        skid1.Expiration_Date__c = system.today();
        skid1.Lot_Number__c = 'LOT 1';
        skid1.Quantity__c = 5;
        skid1.Company__c = fuel.company.Id;

        aserialwrapper = new SkidService3.SerialWrapper(skid1, new list<Serial__c>());
        serialwrapperlist.add(aserialwrapper);
        
        a = new ASNAddManageExt.ASNLineWrapper(asnLine,serialwrapperlist);
        a.trackedAttributes = SKIDService3.trackedAttributes(null, null, asnLine.Item__r);
        
        updateasnlWrapper.add(a);

        List <ASNAddManageExt.ASNLineWrapper> newasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper b;
        asnLine1.Quantity_Shipped__c = 15;
       
        SKID__c skid2 = new SKID__c();
        skid2.ASN_Line__c = asnLine1.id;
        skid2.Location__c = asnLine1.Location__c;
        skid2.Type__c = 'In-Transit';
        skid2.Item__c = asnLine1.Item__c;
        skid2.Item__r = asnLine1.Item__r;
        skid2.Company__c = asn.Company__c;
        skid2.Expiration_Date__c = system.today();
        skid2.Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c;
        skid2.Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c;
        //skid2.Lot_Number__c = 'LOT 2';
        skid2.Quantity__c = 15;
        skid2.Company__c = fuel.company.Id;

        bserialwrapper = new SkidService3.SerialWrapper(skid2, new list<Serial__c>());
        
        serialwrapperlist1.add(bserialwrapper);
        b = new ASNAddManageExt.ASNLineWrapper(asnLine1,serialwrapperlist1);
        b.trackedAttributes = SKIDService3.trackedAttributes(null, null, asnLine1.Item__r);
        
        newasnlWrapper.add(b);
        test.startTest();
        result = ASNAddManageExt.saveAction(asn, null, updateasnlWrapper, newasnlWrapper, new List<ASNAddManageExt.ASNLineWrapper>(), new List<SkidService3.SerialWrapper>(),null, null);
        system.assert(result.success == true, result);
        
        List<SKID__c> skidlist = [Select Id,ASN_Line__c, Quantity__c, Location__c, Lot__c from SKID__c where type__c = 'In-Transit'];
        system.assert(skidlist.size() == 2, skidlist);
        
        //Confirm ASN to be able to receive        
        
        JSONResult resultconfirm = new JSONResult();
        
        resultconfirm = ASNAddManageExt.HeaderActions(asn,'confirm',null);
        system.assert(resultconfirm.success==true, resultconfirm);   
        system.assertEquals(resultconfirm.success, true);              
               
        
        //Now Search for this ASN on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('ASN');
        ReceivingWorkBenchExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('ASN');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        
        
        ASN__c newASN = [Select Id,Name, Status__c from ASN__c where Id =:asn.Id];
        system.assert(newASN != null, newASN);
        system.assert(newASN.Status__c == 'Confirmed', newASN);
        List<Id> asnlineIds = new List<Id>();
        
        ReceivingWorkBenchExt.getCurrencyCode(null,facilityId,newASN.Name,'ASN');
        
        List<ASN_Line__c> newASNLinelist = [Select Id, Facility__c, Purchase_Order__c, Purchase_Order__r.Approval_Status__c, Purchase_Order_Line__c, Purchase_Order_Line__r.Name, Purchase_Order_Line__r.Quantity_Still_Due__c, Quantity_Received__c, 
                                            Item__c, Item__r.Name, ASN__r.FOB__r.Name, ASN__r.Name, ASN__r.FOB__r.FOB_Point__c, Unit_Price__c, Status__c, Quantity_Shipped__c, ASN__c, Company__c, Supplier__c 
                                            from ASN_Line__c where ASN__c =:asn.Id];
        system.assert(newASNLinelist.size() == 2, newASNLinelist);
        
        newASN.Status__c = 'Draft';
        update newASN;
        
        for(ASN_Line__c line:newASNLinelist){
            system.assert(line.Status__c == 'Open', newASNLinelist);
            system.assert(line.Facility__c == facilityId, newASNLinelist);
            system.assert(line.Supplier__c == supplierId, newASNLinelist);          
            system.assert(line.ASN__c == docnum, newASNLinelist);               
            system.assert(line.Purchase_Order__r.Approval_Status__c != 'Approved', line.Purchase_Order__r.Approval_Status__c); 
            asnlineIds.add(line.id);
        }
        
        searchresult = ReceivingWorkBenchExt.getDocumentInfo('ASN_Line__c',asn.Id);
        system.assertEquals(searchresult.success, false);
        
        Boolean errorPOFound = false;
        Boolean errorASNFound = false;
        
        if(searchresult.messages != null && searchresult.messages.size() > 0){
				for (Map<String, String> msg : searchresult.messages) {
					if(msg.get('message').contains(Label.Purchase_order_is_not_approved)){
				    	errorPOFound = true;
				    }
				    if(msg.get('message').contains(Label.Cannot_Receive_Unconfirmed_ASN)){
				    	errorASNFound = true;
				    }
				}
		}
     
        system.assert(errorPOFound == true && errorASNFound == true);
        
        
        po.Approval_Status__c = 'Approved';
        update po; 
         
        newASN.Status__c = 'Draft';
        update newASN;
        
        List<ASN_Line__c> updateasnlines = new List<ASN_Line__c>();
        for(ASN_Line__c asnl:newASNLinelist){
        	asnl.Status__c = 'Closed';
        	updateasnlines.add(asnl);
        }
        update updateasnlines;
        test.stopTest();
        searchresult1 = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, docnum, null, null, null, null);
        system.assertEquals(searchresult1.success, false);
        system.assert(searchresult1.total == 0);
        
        Boolean errorASNLineFound = false;
        
        if(searchresult1.messages != null && searchresult1.messages.size() > 0){
				for (Map<String, String> msg : searchresult1.messages) {
					if(msg.get('message').contains(Label.ASN_line_not_open)){
				    	errorASNLineFound = true;
				    }
				}
		}
        
        system.assert(errorASNLineFound == true,searchresult1.messages);
    }
    
    static testMethod void SearchASN_Receive_Errors(){     
    
    
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poline = fuel.purchaseOrderLines[0];
        
        Purchase_Order_Line__c poLine1 = new Purchase_Order_Line__c();{
                poLine1.Purchase_Order__c = po.Id;
                poLine1.Order_Quantity__c = 15;     
                poLine1.Unit_Price__c = 24;
                poLine1.Item__c = fuel.itemList[1].Id;
                poLine1.Description__c = fuel.itemList[1].Description__c;
                poLine1.Purchase_UOM__c = fuel.itemList[1].Purchasing_UOM__c;
                poLine1.Company__c = fuel.company.id;
                poLine1.Need_Date__c = system.today() + 7;
                poLine1.Delivery_Facility__c = fuel.facility2.id;
                poLine1.Delivery_Location__c = fuel.location2.ID;
                poLine1.Supplier__c = fuel.supplier.Id;
                poLine1.Line__c = 2;
                insert poLine1; 
        }
        
         po.Approval_Status__c = 'Approved';
         update po;               
              
        
        FOB_Terms__c fobTerm = new FOB_Terms__c();{
            fobTerm.Name = 'test term destination';
            fobTerm.FOB_Point__c = 'Origin';
            insert fobTerm;
        }
        
        ASN__c asn = new ASN__c();{
            asn.Company__c = fuel.company.id;
            asn.Supplier__c = fuel.supplier.id;
            asn.Facility__c = fuel.facility2.id;
            asn.FOB__c = fobTerm.id;      
            asn.Status__c = 'Draft';
            asn.Transaction_Date__c = system.today();
            asn.Currency__c = fuel.currencyUSD.id;
            asn.Transaction_Type__c = 'Purchase Order ASN';
            insert asn;
        }
        
        
        JSONResult searchresult = new JSONResult();
        
        searchresult = ReceivingWorkBenchExt.getDocumentInfo('ASN_Line__c',asn.Id);
       
        system.assert(searchresult.total == 0);
        
    }
    

    
    
    static testMethod void SearchPurchaseOrder_Errors(){      
        
    
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poline = fuel.purchaseOrderLines[0];
        
        FOB_Terms__c fobTerm = new FOB_Terms__c();{
            fobTerm.Name = 'test term destination';
            fobTerm.FOB_Point__c = 'Destination';
            insert fobTerm;
        }        
                
        Purchase_Order__c po1 = new Purchase_Order__c(
                                                    Supplier__c = fuel.supplier.id, 
                                                    Company__c = fuel.company.id,
                                                    Payment_Term__c = fuel.terms.id,
                                                    Delivery_Facility__c = fuel.facility2.id,
                                                    Delivery_Location__c = fuel.location2.ID,
                                                    Remit_To_Supplier__c = fuel.remitToSupplier.id,
                                                    Approval_Status__c = 'Approved',
                                                    fob_term__c = fobTerm.id,
                                                    Status__c = 'Open',
                                                    Memo__c = 'purchaseOrder',
                                                    Type__c='Drop Ship',
                                                    Currency__c = fuel.currencyUSD.id
                                        );
        insert po1;
        Purchase_Order_Line__c poLine2 = new Purchase_Order_Line__c();{
                poLine2.Purchase_Order__c = po1.Id;
                poLine2.Order_Quantity__c = 15;     
                poLine2.Unit_Price__c = 24;
                poLine2.Item__c = fuel.itemList[5].Id;
                poLine2.Description__c = fuel.itemList[5].Description__c;
                poLine2.Purchase_UOM__c = fuel.itemList[5].Purchasing_UOM__c;
                poLine2.Company__c = fuel.company.id;
                poLine2.Need_Date__c = system.today() + 7;
                poLine2.Delivery_Facility__c = fuel.facility2.id;
                poLine2.Delivery_Location__c = fuel.location2.ID;
                poLine2.Supplier__c = fuel.supplier.Id;
                poLine2.Line__c = 2;
                insert poLine2; 
        }
        
        po1.Approval_Status__c = null;
        update po1;
        
        
        test.startTest();
        ReceivingWorkBenchExt.setGridConfig('Purchase Order', fuel.facility2.id);
        
        //Create PO    
       
       // List<Purchase_Order_Line__c> queriedPOL = [Select Id,Name, Purchase_Order__r.Delivery_Facility__c, Status__c, Purchase_Order__r.FOB_Term__c from Purchase_Order_Line__c where Id =:poline.Id]; 
        String docnum = po1.Id;
        String facilityId = po1.Delivery_Facility__c;
        String supplierId = po1.Supplier__c;
        String itemId = poline2.Item__c; 
        String fobId = fobTerm.Id;
        
       
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();         
                                       
       
        //Now Search for this POLines on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('Purchase Order');
        ReceivingWorkBenchExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('Purchase Order');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
                
       
        List<Id> polineIds = new List<Id>();
        
        List<Purchase_Order_Line__c> polinelist = [Select Id, Name, Purchase_Order__r.Name, Purchase_Order__r.Approval_Status__c, delivery_facility__c, Purchase_Order__c, Purchase_Order__r.FOB_Term__r.FOB_Point__c, Status__c, Company__c, Supplier__c 
                                            from Purchase_Order_Line__c where delivery_facility__c =:facilityId];
        system.assert(polinelist.size() == 2, polinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,facilityId,polinelist[0].Purchase_Order__r.Name,'Purchase Order');
        
        for(Purchase_Order_Line__c line:polinelist){
            system.assert(line.Status__c == 'Open', polinelist);
            system.assert(line.delivery_facility__c == facilityId, polinelist);
            system.assert(line.Supplier__c == supplierId, polinelist);          
            polineIds.add(line.id);
        }
       
        searchresult = ReceivingWorkBenchExt.getDocumentInfo('Purchase_Order_Line__c',po1.Id);
        system.assertEquals(searchresult.success, false);
        
        Boolean errorPOFound = false;
        if(searchresult.messages != null && searchresult.messages.size() > 0){
				for (Map<String, String> msg : searchresult.messages) {
					
				    if(msg.get('message').contains(Label.Purchase_order_is_not_approved)){
				    	errorPOFound = true;
				    }
				}
		}
		system.assert(errorPOFound == true,searchresult.messages);
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, supplierId, fobId, docnum, null, null, null, null);
        system.assertEquals(searchresult.success, false);
        system.assert(searchresult.total == 0, searchresult);
        
        Boolean errorDropShipFound = false;
        if(searchresult.messages != null && searchresult.messages.size() > 0){
				for (Map<String, String> msg : searchresult.messages) {
					
				    if(msg.get('message').contains(Label.Cannot_Receive_DropShip_PO)){
				    	errorDropShipFound = true;
				    }
				    if(msg.get('message').contains(Label.Purchase_order_is_not_approved)){
				    	errorPOFound = true;
				    }
				}
		}
     
        system.assert(errorDropShipFound == true,searchresult.messages);
        
    }
    
    static testMethod void SearchPurchaseOrder_ReceiveErrors(){      
        
    
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poline = fuel.purchaseOrderLines[0];
        
                
        Purchase_Order__c po1 = new Purchase_Order__c(
                                                    Supplier__c = fuel.supplier.id, 
                                                    Company__c = fuel.company.id,
                                                    Payment_Term__c = fuel.terms.id,
                                                    Delivery_Facility__c = fuel.facility2.id,
                                                    Delivery_Location__c = fuel.location2.ID,
                                                    Remit_To_Supplier__c = fuel.remitToSupplier.id,
                                                    Approval_Status__c = 'Approved',
                                                    Status__c = 'Open',
                                                    Memo__c = 'purchaseOrder',
                                                    Type__c='Drop Ship',
                                                    Currency__c = fuel.currencyUSD.id
                                        );
        insert po1;
        
        
        Purchase_Order_Line__c poLine1 = new Purchase_Order_Line__c();
        poLine1.Purchase_Order__c = po1.Id;
        poLine1.Order_Quantity__c = 10;     
        poLine1.Unit_Price__c = 12;
        poLine1.Item__c = fuel.itemList[2].Id;
        poLine1.Description__c = 'purchaseOrderLine11';
        poLine1.Purchase_UOM__c = fuel.itemList[2].Purchasing_UOM__c;
        poLine1.Company__c = fuel.company.id;
        poLine1.Need_Date__c = system.today() + 7;
        poLine1.Delivery_Facility__c = fuel.facility2.id;
        poLine1.Delivery_Location__c = fuel.location2.ID;
        poLine1.Supplier__c = fuel.supplier.Id;
        poLine1.Line__c = 1;
        poLine1.Quantity_Matched__c = 0;
        poLine1.Amount_Matched__c = 0;
        insert poLine1; 
                
        po1.Approval_Status__c = null;
        po1.Status__c = 'Closed';
        update po1;
        
        
        test.startTest();
        ReceivingWorkBenchExt.setGridConfig('Purchase Order', fuel.facility2.id);
        JSONResult searchresult = new JSONResult();
       
        
        searchresult = ReceivingWorkBenchExt.getDocumentInfo('Purchase_Order_Line__c',po1.Id);
       
        Boolean errorPOFound = false;
        if(searchresult.messages != null && searchresult.messages.size() > 0){
				for (Map<String, String> msg : searchresult.messages) {
					
				    if(msg.get('message').contains(Label.Purchase_Order_has_been_Closed)){
				    	errorPOFound = true;
				    }
				}
		}
     	test.stopTest();
        system.assert(errorPOFound == true,searchresult.messages);
        
    }

    static testMethod void receiveASNwithSerials(){  

        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poline = fuel.purchaseOrderLines[0];
        fuel.company.Serial_Control__c = 'At receipt and all processes';
        update fuel.company;
        
        Purchase_Order_Line__c poLine1 = new Purchase_Order_Line__c();{
                poLine1.Purchase_Order__c = po.Id;
                poLine1.Order_Quantity__c = 15;     
                poLine1.Unit_Price__c = 24;
                poLine1.Item__c = fuel.itemList[1].Id;
                poLine1.Description__c = fuel.itemList[1].Description__c;
                poLine1.Purchase_UOM__c = fuel.itemList[1].Purchasing_UOM__c;
                poLine1.Company__c = fuel.company.id;
                poLine1.Need_Date__c = system.today() + 7;
                poLine1.Delivery_Facility__c = fuel.facility2.id;
                poLine1.Delivery_Location__c = fuel.location2.ID;
                poLine1.Supplier__c = fuel.supplier.Id;
                poLine1.Line__c = 2;
                 
        }
        poLine1.Packaging_UOM__r = fuel.uomObj;
        insert poLine1;
        
         po.Approval_Status__c = 'Approved';
         update po;               
              

        FOB_Terms__c fobTerm = new FOB_Terms__c();{
            fobTerm.Name = 'test term destination';
            fobTerm.FOB_Point__c = 'Origin';
            insert fobTerm;
        }
        
        ASN__c asn = new ASN__c();{
            asn.Company__c = fuel.company.id;
            asn.Supplier__c = fuel.supplier.id;
            asn.Facility__c = fuel.facility2.id;
            asn.FOB__c = fobTerm.id;      
            asn.Status__c = 'Draft';
            asn.Transaction_Date__c = system.today();
            asn.Currency__c = fuel.currencyUSD.id;
            asn.Transaction_Type__c = 'Purchase Order ASN';
            insert asn;
        }
        
        ASN_Line__c asnLine = new ASN_Line__c();{
            asnLine.Purchase_Order__c = po.id;
            asnLine.Purchase_Order_Line__c = poLine.id;
            asnLine.Item__c = fuel.itemList[2].id;
            asnLine.Item__r = fuel.itemList[2];
            asnLine.Quantity_Shipped__c = 10;
            asnLine.Quantity_Received__c = 0;
            asnLine.Unit_Price__c = 10;
            asnLine.Status__c = 'New';
            asnLine.ASN__c = asn.id;
            asnLine.Company__c = fuel.company.id;
            asnLine.Supplier__c = fuel.supplier.id;
            asnLine.Facility__c = fuel.facility2.id;
            insert asnLine;
        }
        fuel.itemList[1].item_attribute__c = null;
        update fuel.itemList[1];
        
        fuel.itemList[4].item_attribute__c = null;
        update fuel.itemList[4];
        
        ASN_Line__c asnLine1 = new ASN_Line__c();{
            asnLine1.Purchase_Order__c = fuel.purchaseOrder.id;
            asnLine1.Purchase_Order_Line__c = poLine1.id;
            asnLine1.Item__c = fuel.itemList[1].id;
            asnLine1.Item__r = fuel.itemList[1];
            asnLine1.Quantity_Shipped__c = 15;
            asnLine1.Quantity_Received__c = 0;
            asnLine1.Unit_Price__c = 12;
            asnLine1.Status__c = 'New';
            asnLine1.ASN__c = asn.id;
            asnLine1.Company__c = fuel.company.id;
            asnLine1.Supplier__c = fuel.supplier.id;
            asnLine1.Facility__c = fuel.facility2.id;
            insert asnLine1;
        }
     
        
        ReceivingWorkBenchExt.setGridConfig('ASN', asnLine1.Facility__c);
                    

        
        //Create ASN with inTransit SKID       
       
        ASN__c queriedASN = [Select Id,Name, Status__c,Company__c from ASN__c where Id =:asn.Id]; 
        String docnum = queriedASN.Id;
        String facilityId = asnLine.Facility__c;
        String supplierId = asnLine.Supplier__c;
        String itemId = asnLine.Item__c;        
        String fobId = asn.FOB__c;
        
        //String needDate = (poLine.Need_Date__c).toString();
                
                        
        ApexPages.StandardController setCon = new Apexpages.StandardController(asn); 
        ASNAddManageExt createASN = new ASNAddManageExt(setCon);
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
        list<SkidService3.SerialWrapper> serialwrapperlist = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> serialwrapperlist1 = new list<SkidService3.SerialWrapper>();
        
        SkidService3.SerialWrapper aserialWrapper;
        SkidService3.SerialWrapper bserialWrapper;
        

        asnLine.Item__r.Item_Attribute__r = fuel.itemAttrObj;        
        

        List <ASNAddManageExt.ASNLineWrapper> updateasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper a;
        asnLine.Quantity_Shipped__c = 2;
        
        SKID__c skid1 = new SKID__c();
        skid1.ASN_Line__c = asnLine.id;
        skid1.Facility2__c = asnLine.Facility__c;
        skid1.Location__c = asnLine.Location__c;
        skid1.Type__c = 'In-Transit';
        skid1.Item__c = asnLine.Item__c;
        skid1.Item__r = asnLine.Item__r;
        skid1.Company__c = fuel.company.id;
        skid1.Expiration_Date__c = system.today();
        skid1.Lot_Number__c = 'LOT 1';
        skid1.Quantity__c = 2;
        skid1.Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c;
        skid1.Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c;
        skid1.Packaging_UOM__r = fuel.uomObj;
        List<Serial__c> seriallist = new List<Serial__c>();
        
        Serial__c ser = new Serial__c(
            Name = 'inTransit Serial 1',
            Item__c = skid1.Item__c,
            Company__c = asn.Company__c
            
        );
        ser.Unique_Key2__c = asn.Company__c + '-' + ser.Item__c + '-' + ser.Name;
        serialList.add(ser);
         Serial__c ser1 = new Serial__c(
            Name = 'inTransit Serial 2',
            Item__c = skid1.Item__c,
            Company__c = asn.Company__c
            
        );
        ser1.Unique_Key2__c = asn.Company__c + '-' + ser1.Item__c + '-' + ser1.Name;
        
        serialList.add(ser1);
        
        aserialwrapper = new SkidService3.SerialWrapper(skid1, serialList);
        serialwrapperlist.add(aserialwrapper);
        
        a = new ASNAddManageExt.ASNLineWrapper(asnLine,serialwrapperlist);
        a.trackedAttributes = SKIDService3.trackedAttributes(null, null, asnLine.Item__r);
        
        updateasnlWrapper.add(a);

        List <ASNAddManageExt.ASNLineWrapper> newasnlWrapper = new List <ASNAddManageExt.ASNLineWrapper>();
        ASNAddManageExt.ASNLineWrapper b;
        asnLine1.Quantity_Shipped__c = 1;
       
        SKID__c skid2 = new SKID__c();
        skid2.ASN_Line__c = asnLine1.id;
        skid2.Facility2__c = asnLine1.Facility__c;
        skid2.Location__c = asnLine1.Location__c;
        skid2.Type__c = 'In-Transit';
        skid2.Item__c = asnLine1.Item__c;
        skid2.Item__r = asnLine1.Item__r;
        skid2.Company__c = asn.Company__c;
        skid2.Expiration_Date__c = system.today();
        skid2.Stocking_UOM__c = asnLine.Item__r.Stocking_UOM__c;
        skid2.Packaging_UOM__c = asnLine.Item__r.Stocking_UOM__c;
        skid2.Packaging_UOM__r = fuel.uomObj;
        //skid2.Lot_Number__c = 'LOT 2';
        skid2.Quantity__c = 1;
        
        List<Serial__c> seriallist1 = new List<Serial__c>();
        
        Serial__c ser3 = new Serial__c(
            Name = 'inTransit Serial 3',
            Item__c = skid2.Item__c,
            Company__c = asn.Company__c
        );
        ser3.Unique_Key2__c = asn.Company__c + '-' + ser3.Item__c + '-' + ser3.Name;
        
        serialList1.add(ser3);
        
        bserialwrapper = new SkidService3.SerialWrapper(skid2, serialList1);
        
        serialwrapperlist1.add(bserialwrapper);
        b = new ASNAddManageExt.ASNLineWrapper(asnLine1,serialwrapperlist1);
        b.trackedAttributes = SKIDService3.trackedAttributes(null, null, asnLine1.Item__r);
        
        newasnlWrapper.add(b);
        test.startTest();
        result = ASNAddManageExt.saveAction(asn, null, updateasnlWrapper, newasnlWrapper, new List<ASNAddManageExt.ASNLineWrapper>(), new List<SkidService3.SerialWrapper>(),null, null);
        system.assert(result.success == true, result);
        
        
        List<SKID__c> skidlist = [Select Id,ASN_Line__c, Quantity__c, Location__c, Lot__c, (Select Id,Name from Serials__r) from SKID__c where type__c = 'In-Transit'];
        system.assert(skidlist.size() == 2, skidlist);
        for(SKID__c sk:skidlist){
            if(sk.Id == skid1.Id)
                system.assert(sk.Serials__r.size() == 2, sk.Serials__r);
            if(sk.Id == skid2.Id)
                system.assert(sk.Serials__r.size() == 1, sk.Serials__r);
        }
        
        //Confirm ASN to be able to receive        
        
        JSONResult resultconfirm = new JSONResult();
        
        resultconfirm = ASNAddManageExt.HeaderActions(asn,'confirm',null);
        system.assertEquals(resultconfirm.success, true);              
               
        
        //Now Search for this ASN on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('ASN');
        ReceivingWorkBenchExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('ASN');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        
        
        ASN__c newASN = [Select Id,Name, Status__c from ASN__c where Id =:asn.Id];
        system.assert(newASN != null, newASN);
        system.assert(newASN.Status__c == 'Confirmed', newASN);
        List<Id> asnlineIds = new List<Id>();
        
        ReceivingWorkBenchExt.getCurrencyCode(null,facilityId,newASN.Name,'ASN');
        
        List<ASN_Line__c> newASNLinelist = [Select Id, Facility__c, Purchase_Order__c, Purchase_Order__r.Approval_Status__c, Purchase_Order_Line__c, Purchase_Order_Line__r.Name, Purchase_Order_Line__r.Quantity_Still_Due__c, Quantity_Received__c, 
                                            Item__c, Purchase_Order_Line__r.Packaging_UOM__c,Item__r.Name, ASN__r.FOB__r.Name, ASN__r.Name, ASN__r.FOB__r.FOB_Point__c, Unit_Price__c, Status__c, Quantity_Shipped__c, ASN__c, Company__c, Supplier__c 
                                            from ASN_Line__c where ASN__c =:asn.Id];
        system.assert(newASNLinelist.size() == 2, newASNLinelist);
        
        for(ASN_Line__c line:newASNLinelist){
            system.assert(line.Status__c == 'Open', newASNLinelist);
            system.assert(line.Facility__c == facilityId, newASNLinelist);
            system.assert(line.Supplier__c == supplierId, newASNLinelist);          
            system.assert(line.ASN__c == docnum, newASNLinelist);               
            system.assert(line.Purchase_Order__r.Approval_Status__c == 'Approved', line.Purchase_Order__r.Approval_Status__c); 
            asnlineIds.add(line.id);
        }
       
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, itemId, supplierId, fobId, docnum, null, null, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
        
        //Manage Receive        
         
        getListresult = ReceivingWorkBenchExt.getList(asnlineIds, 'ASN');
        system.assert(getListresult.success == true, getListresult.message);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(asnlineIds, 'ASN', fuel.currencyUSD.id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(asnlineIds), new set<String>{'ASN_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                skid.Packaging_UOM__r = fuel.uomObj;
                skid.Packaging_UOM__r.Package_Class__r = null;
                skid.Expiration_Date__c = system.today();
                if(skid.Item__c == fuel.itemList[2].id){
                    sw.seriallist = seriallist;
                    skid.Packaging_UOM__c = fuel.itemList[2].Stocking_UOM__c;
                }
                else{
                    sw.seriallist = seriallist1;
                    skid.Packaging_UOM__c = fuel.uomObj.Id;
                }
                
            }
        }
       
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        rdoc.Currency__c = fuel.currencyUSD.id;
        //rdoc.Transaction_Type__c = 'In-Transit Purchase Order Receipt';
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        
        List<ASN_Line__c> updatedasnlines = [Select Id, Status__c, Quantity_Shipped__c, ASN__c from ASN_Line__c where ASN__c =:asn.Id];
        
        for(ASN_Line__c line:updatedasnlines){
            if(line.Id == asnline.Id){
                system.assert(line.Status__c == 'Closed');
            }
            if(line.Id == asnline1.Id){
                system.assert(line.Status__c == 'Closed');
            }
        }                                   
                                            
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Quantity_Received__c, Status__c, Purchase_Order_Line__c, Purchase_Order__c, ASN_Line__c, Receiving_Document__r.Transaction_Type__c, 
                                                Receiving_Document__r.Finalized__c, Receiving_Document__r.Status__c, Receiving_Document__r.Type__c from Receipt_Line__c where Receipt_Line__c.Receiving_Document__r.Type__c != 'In-Transit'];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Purchase_Order__c == asnLine.Purchase_Order__c);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'Purchase Order Receipt');
            if(rcptline.ASN_Line__c == asnLine.id){
                system.assert(rcptline.Quantity_Received__c == 2, rcptline.Quantity_Received__c);
            }
            
            if(rcptline.ASN_Line__c == asnLine1.id){
                system.assert(rcptline.Quantity_Received__c == 1, rcptline.Quantity_Received__c);
            } 
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'In-Transit Purchase Order Receipt', rcptline);  //FOB Point is not passed from ASN correctly
            
        }
               
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, 
                                                    From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c,
                                                    ( select Id, Serial__c, Serial__r.Allow_Reentry__c, Serial__r.SKID__c, Type__c From Serial_Transactions__r)
                                                    FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        system.assert(itlist.size() == 2, itlist);
       
        for(Inventory_Transaction__c it: itlist){
            
            if(it.Item__c == asnLine.Item__c){
                system.assert(it.From_SKID__c == null, it);
                system.assert(it.To_SKID__c != null, it);
                system.assert(it.Quantity__c == 2);
                system.assertEquals(2, it.Serial_Transactions__r.size());
                
            }
            
            if(it.Item__c == asnLine1.Item__c){
                system.assert(it.To_SKID__c != null, it);
                system.assert(it.Quantity__c == 1, itList);
                system.assertEquals(1, it.Serial_Transactions__r.size());
            }
            
            system.assert(it.Subtransaction_Type__c == 'Purchase Order Receipt');
            system.assert(it.Type__c == 'Purchase Order Receipt');
            system.assert(it.Receipt_Line__c !=null);       
            
        }
        
        
    }

    static testMethod void SearchPurchaseOrder_nonFOBOrigin(){      
        
    
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poline = fuel.purchaseOrderLines[0];
        
        FOB_Terms__c fobTerm = new FOB_Terms__c();{
            fobTerm.Name = 'test term destination';
            fobTerm.FOB_Point__c = 'Destination';
            insert fobTerm;
        }        
                
        Purchase_Order__c po1 = new Purchase_Order__c(
                                                    Supplier__c = fuel.supplier.id, 
                                                    Company__c = fuel.company.id,
                                                    Payment_Term__c = fuel.terms.id,
                                                    Delivery_Facility__c = fuel.facility2.id,
                                                    Delivery_Location__c = fuel.location2.ID,
                                                    Remit_To_Supplier__c = fuel.remitToSupplier.id,
                                                    Approval_Status__c = 'Approved',
                                                    fob_term__c = fobTerm.id,
                                                    Status__c = 'Open',
                                                    Memo__c = 'purchaseOrder',
                                                    Currency__c = fuel.currencyUSD.id
                                        );
        insert po1;
        Purchase_Order_Line__c poLine2 = new Purchase_Order_Line__c();{
                poLine2.Purchase_Order__c = po1.Id;
                poLine2.Order_Quantity__c = 15;     
                poLine2.Unit_Price__c = 24;
                poLine2.Item__c = fuel.itemList[5].Id;
                poLine2.Description__c = fuel.itemList[5].Description__c;
                poLine2.Purchase_UOM__c = fuel.itemList[5].Purchasing_UOM__c;
                poLine2.Stocking_UOM__c = fuel.itemList[5].Stocking_UOM__c;
                poLine2.Packaging_UOM__c = fuel.itemList[5].Stocking_UOM__c;
                poLine2.Company__c = fuel.company.id;
                poLine2.Need_Date__c = system.today() + 7;
                poLine2.Delivery_Facility__c = fuel.facility2.id;
                poLine2.Delivery_Location__c = fuel.location2.ID;
                poLine2.Supplier__c = fuel.supplier.Id;
                poLine2.Line__c = 2;
                insert poLine2; 
        }
        
        
        po1.Approval_Status__c = 'Approved';
        update po1;   
         
        fuel.itemList[2].item_attribute__c = null;
        update fuel.itemList[2];
        
        fuel.itemList[5].item_attribute__c = null;
        update fuel.itemList[5];
        
        test.startTest();
        ReceivingWorkBenchExt.setGridConfig('Purchase Order', fuel.facility2.id);
        
        //Create PO    
       
       // List<Purchase_Order_Line__c> queriedPOL = [Select Id,Name, Purchase_Order__r.Delivery_Facility__c, Status__c, Purchase_Order__r.FOB_Term__c from Purchase_Order_Line__c where Id =:poline.Id]; 
        String docnum = po.Id;
        String facilityId = po.Delivery_Facility__c;
        String supplierId = po.Supplier__c;
        String itemId = poline.Item__c; 
        String fobId = fobTerm.Id;
        
       
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();         
                                       
       
        //Now Search for this POLines on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('Purchase Order');
        ReceivingWorkBenchExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('Purchase Order');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
                
       
        List<Id> polineIds = new List<Id>();
        
        List<Purchase_Order_Line__c> polinelist = [Select Id, Name, Purchase_Order__r.Name, Purchase_Order__r.Approval_Status__c, delivery_facility__c, Purchase_Order__c, Purchase_Order__r.FOB_Term__r.FOB_Point__c, Status__c, Company__c, Supplier__c 
                                            from Purchase_Order_Line__c where delivery_facility__c =:facilityId];
        system.assert(polinelist.size() == 2, polinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,facilityId,polinelist[0].Purchase_Order__r.Name,'Purchase Order');
        for(Purchase_Order_Line__c line:polinelist){
            system.assert(line.Status__c == 'Open', polinelist);
            system.assert(line.delivery_facility__c == facilityId, polinelist);
            system.assert(line.Supplier__c == supplierId, polinelist);          
            system.assert(line.Purchase_Order__r.FOB_Term__r.FOB_Point__c != 'Origin', polinelist);  
            //system.assert(line.Purchase_Order__c == po.Id || line.Purchase_Order__c == po1.Id || line.Purchase_Order__c == po2.Id, polinelist);               
            system.assert(line.Purchase_Order__r.Approval_Status__c == 'Approved', line.Purchase_Order__r.Approval_Status__c); 
            polineIds.add(line.id);
        }
       
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, supplierId, fobId, null, null, null, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
        
        searchresult1 = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, docnum, null, null, null, null);
        system.assertEquals(searchresult1.success, true);
        system.assert(searchresult1.total >0);
        
        searchresult2 = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, null, null, null, null, docnum, null, null, null, null);
        system.assertEquals(searchresult2.success, true);
        system.assert(searchresult2.total >0);
        //Manage Receive        
         
        getListresult = ReceivingWorkBenchExt.getList(polineIds, 'Purchase Order');
        system.debug('getListresult: ' + getListresult);
        system.assert(getListresult.success == true, getListresult.message);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(polineIds, 'Purchase Order',fuel.currencyUSD.id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(polineIds), new set<String>{'Purchase_Order_Line__c'.toLowerCase()} );
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        rdoc.Currency__c = fuel.currencyUSD.id;
        rdoc.Transaction_Date__c = system.now() +2;
        system.assert(rdocresult.records.size() == 1, rdocresult);
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                
                 sw.skid.Packaging_UOM__r.Package_Class__r = null;
                 
            }
        }
        //receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        try {
            ReceivingDocumentServiceV2.checkUserErrors(rwrapperlist);
        } catch (Exception e){
            System.assert(e.getMessage().contains(Label.No_Quantities_Entered_To_Receive));
        }
       
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                
                if(skid.Item__c == fuel.itemList[2].Id){
                    skid.Quantity__c = 10;
                }
                else if(skid.Item__c == fuel.itemList[5].Id){
                    skid.Quantity__c = 15;
                }               
            }
        }
        
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        
        List<Purchase_Order_Line__c> updatedpolines = [Select Id, Status__c, Quantity_Still_Due__c, Quantity_Received__c from Purchase_Order_Line__c where delivery_facility__c =:facilityId];
        
        for(Purchase_Order_Line__c line:updatedpolines){            
            system.assert(line.Status__c == 'Closed', line);
            system.assert(line.Quantity_Still_Due__c == 0, line.Quantity_Still_Due__c);         
        }                                   
                                            
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Quantity_Received__c, Status__c, Purchase_Order_Line__c, Purchase_Order__c, ASN_Line__c, Receiving_Document__r.Transaction_Type__c, 
                                                Receiving_Document__r.Finalized__c, Receiving_Document__r.Status__c, Receiving_Document__r.Type__c from Receipt_Line__c where Receipt_Line__c.Receiving_Document__c =: rdoc.Id];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Purchase_Order__c == po.Id || rcptline.Purchase_Order__c == po1.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'Purchase Order Receipt');
            if(rcptline.Purchase_Order__c == po.Id){
                system.assert(rcptline.Quantity_Received__c == 10, rcptline.Quantity_Received__c);
            }
            else if(rcptline.Purchase_Order__c == po1.Id){
                system.assert(rcptline.Quantity_Received__c == 15, rcptline.Quantity_Received__c);
            }
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'Purchase Order Receipt', rcptline);
            
        }
               
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Receipt_Line__r.Receiving_Document__r.Transaction_Date__c, Quantity__c, Transaction_Date__c, Subtransaction_Type__c, Finalized__c, Purchase_Order_Line__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        system.assert(itlist.size() == 2, itlist);       
        for(Inventory_Transaction__c it: itlist){
            
            if(it.Purchase_Order_Line__c == poLine.Id){
                system.assert(it.Quantity__c == 10, itList);
            }
            else if(it.Purchase_Order_Line__c == poLine2.Id){
                system.assert(it.Quantity__c == 15, itList);
            }
            
            system.assert(it.Subtransaction_Type__c == 'Purchase Order Receipt');
            system.assert(it.Type__c == 'Purchase Order Receipt');
            system.assert(it.Receipt_Line__c !=null); 
            system.assert(it.Transaction_Date__c == it.Receipt_Line__r.Receiving_Document__r.Transaction_Date__c);      
            
        }
        
        
    }
    
    static testMethod void receivePurchaseOrder_mixedwithNonInventory(){    

        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poline = fuel.purchaseOrderLines[0];
        
        FOB_Terms__c fobTerm = new FOB_Terms__c();{
            fobTerm.Name = 'test term destination';
            fobTerm.FOB_Point__c = 'Destination';
            insert fobTerm;
        }  
        
        fuel.itemList[5].Non_Inventory__c = true;   
        fuel.itemList[5].Source__c = 'Miscellaneous';
        fuel.itemList[5].Purchasing_UOM__c = fuel.uomList[8].Id;
        update fuel.itemList[5];
                
        Purchase_Order__c po1 = new Purchase_Order__c(
                                                    Supplier__c = fuel.supplier.id, 
                                                    Company__c = fuel.company.id,
                                                    Payment_Term__c = fuel.terms.id,
                                                    Delivery_Facility__c = fuel.facility2.id,
                                                    Delivery_Location__c = fuel.location2.ID,
                                                    Remit_To_Supplier__c = fuel.remitToSupplier.id,
                                                    Approval_Status__c = 'Approved',
                                                    fob_term__c = fobTerm.id,
                                                    Status__c = 'Open',
                                                    Memo__c = 'purchaseOrder',
                                                    Currency__c = fuel.currencyUSD.id
                                        );
        insert po1;
        test.startTest();
        Purchase_Order_Line__c poLine2 = new Purchase_Order_Line__c();{
                poLine2.Purchase_Order__c = po1.Id;
                poLine2.Order_Quantity__c = 15;     
                poLine2.Unit_Price__c = 24;
                poLine2.Item__c = fuel.itemList[5].Id;
                poLine2.Description__c = fuel.itemList[5].Description__c;
                poLine2.Purchase_UOM__c = fuel.itemList[5].Purchasing_UOM__c;
                poLine2.Company__c = fuel.company.id;
                poLine2.Need_Date__c = system.today() + 7;
                poLine2.Delivery_Facility__c = fuel.facility2.id;
                poLine2.Delivery_Location__c = fuel.location2.ID;
                poLine2.Supplier__c = fuel.supplier.Id;
                poLine2.Line__c = 2;
                insert poLine2; 
        }
        
        
        po1.Approval_Status__c = 'Approved';
        update po1;   
         
        fuel.itemList[2].item_attribute__c = null;
        update fuel.itemList[2];
        
        fuel.itemList[5].item_attribute__c = null;
        update fuel.itemList[5];
        
        
        ReceivingWorkBenchExt.setGridConfig('Purchase Order', fuel.facility2.id);
        
        //Create PO    
       
       // List<Purchase_Order_Line__c> queriedPOL = [Select Id,Name, Purchase_Order__r.Delivery_Facility__c, Status__c, Purchase_Order__r.FOB_Term__c from Purchase_Order_Line__c where Id =:poline.Id]; 
        String docnum = po.Id;
        String facilityId = po.Delivery_Facility__c;
        String supplierId = po.Supplier__c;
        String itemId = poline.Item__c; 
        String fobId = fobTerm.Id;
        
       
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();         
                                       
       
        //Now Search for this POLines on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('Purchase Order');
        ReceivingWorkBenchExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('Purchase Order');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
                
       
        List<Id> polineIds = new List<Id>();
        
        List<Purchase_Order_Line__c> polinelist = [Select Id, Name, Purchase_Order__r.Name, Purchase_Order__r.Approval_Status__c, delivery_facility__c, Purchase_Order__c, Purchase_Order__r.FOB_Term__r.FOB_Point__c, Status__c, Company__c, Supplier__c 
                                            from Purchase_Order_Line__c where delivery_facility__c =:facilityId];
        system.assert(polinelist.size() == 2, polinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,facilityId,polinelist[0].Purchase_Order__r.Name,'Purchase Order');
        for(Purchase_Order_Line__c line:polinelist){
            system.assert(line.Status__c == 'Open', polinelist);
            system.assert(line.delivery_facility__c == facilityId, polinelist);
            system.assert(line.Supplier__c == supplierId, polinelist);          
            system.assert(line.Purchase_Order__r.FOB_Term__r.FOB_Point__c != 'Origin', polinelist);  
            //system.assert(line.Purchase_Order__c == po.Id || line.Purchase_Order__c == po1.Id || line.Purchase_Order__c == po2.Id, polinelist);               
            system.assert(line.Purchase_Order__r.Approval_Status__c == 'Approved', line.Purchase_Order__r.Approval_Status__c); 
            polineIds.add(line.id);
        }
       
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, supplierId, fobId, null, null, null, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
        
        searchresult1 = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, docnum, null, null, null, null);
        system.assertEquals(searchresult1.success, true);
        system.assert(searchresult1.total >0);
        
        searchresult2 = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, null, null, null, null, docnum, null, null, null, null);
        system.assertEquals(searchresult2.success, true);
        system.assert(searchresult2.total >0);
        //Manage Receive        
         
        getListresult = ReceivingWorkBenchExt.getList(polineIds, 'Purchase Order');
        system.assert(getListresult.success == true, getListresult.message);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(polineIds, 'Purchase Order',fuel.currencyUSD.id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(polineIds), new set<String>{'Purchase_Order_Line__c'.toLowerCase()} );
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        
        //receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                
                 sw.skid.Packaging_UOM__r.Package_Class__r = null;
                 
            }
        }
        try {
            ReceivingDocumentServiceV2.checkUserErrors(rwrapperlist);
        } catch (Exception e){
            System.assert(e.getMessage().contains(Label.No_Quantities_Entered_To_Receive));
        }
       
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                
                if(skid.Item__c == fuel.itemList[2].Id){
                    skid.Quantity__c = 10;
                }
                else if(skid.Item__c == fuel.itemList[5].Id){
                    skid.Quantity__c = 15;
                }               
            }
        }
        
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        
        List<Purchase_Order_Line__c> updatedpolines = [Select Id, Status__c, Quantity_Still_Due__c, Quantity_Received__c from Purchase_Order_Line__c where delivery_facility__c =:facilityId];
        
        for(Purchase_Order_Line__c line:updatedpolines){            
            system.assert(line.Status__c == 'Closed', line);
            system.assert(line.Quantity_Still_Due__c == 0, line.Quantity_Still_Due__c);         
        }                                   
                                            
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Quantity_Received__c, Status__c, Purchase_Order_Line__c, Purchase_Order__c, ASN_Line__c, Receiving_Document__r.Transaction_Type__c, 
                                                Receiving_Document__r.Finalized__c, Receiving_Document__r.Status__c, Receiving_Document__r.Type__c from Receipt_Line__c where Receipt_Line__c.Receiving_Document__c =: rdoc.Id];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Purchase_Order__c == po.Id || rcptline.Purchase_Order__c == po1.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'Purchase Order Receipt');
            if(rcptline.Purchase_Order__c == po.Id){
                system.assert(rcptline.Quantity_Received__c == 10, rcptline.Quantity_Received__c);
            }
            else if(rcptline.Purchase_Order__c == po1.Id){
                system.assert(rcptline.Quantity_Received__c == 15, rcptline.Quantity_Received__c);
            }
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'Purchase Order Receipt', rcptline);
            
        }
               
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Purchase_Order_Line__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        system.assert(itlist.size() == 1, itlist);   
        
           
        for(Inventory_Transaction__c it: itlist){
            
            system.assert(it.Quantity__c == 10, itList);
            system.assert(it.Subtransaction_Type__c == 'Purchase Order Receipt');
            system.assert(it.Type__c == 'Purchase Order Receipt');
            system.assert(it.Receipt_Line__c !=null);       
            
        }
        
        List<Inventory_Transaction__c> itlist1 = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Purchase_Order_Line__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Purchase_Order_Line__c = :poLine2.Id]; 
        
         system.assert(itlist1.size() == 0, itlist1);  //Non Inventory Item should not create any IT against Receipt/POL KNDY-12822
    }
    
    static testMethod void SearchPurchaseOrder_FOBOrigin(){     
        //PO of FOB Point as 'Origin' should not be received via Receiving Workbench.

        FOB_Terms__c fobTerm = new FOB_Terms__c();{
            fobTerm.Name = 'test term Origin';
            fobTerm.FOB_Point__c = 'Origin';
            insert fobTerm;
        }
                      
                
        Purchase_Order__c po1 = new Purchase_Order__c(
                                                    Supplier__c = fuel.supplier.id, 
                                                    Company__c = fuel.company.id,
                                                    Payment_Term__c = fuel.terms.id,
                                                    Delivery_Facility__c = fuel.facility2.id,
                                                    Delivery_Location__c = fuel.location2.ID,
                                                    Remit_To_Supplier__c = fuel.remitToSupplier.id,
                                                    Approval_Status__c = 'Approved',
                                                    fob_term__c = fobTerm.id,
                                                    Status__c = 'Open',
                                                    Memo__c = 'purchaseOrder1'
                                        );
        insert po1;
        
        Purchase_Order_Line__c poLine2 = new Purchase_Order_Line__c();{
                poLine2.Purchase_Order__c = po1.Id;
                poLine2.Order_Quantity__c = 15;     
                poLine2.Unit_Price__c = 24;
                poLine2.Item__c = fuel.itemList[5].Id;
                poLine2.Description__c = fuel.itemList[5].Description__c;
                poLine2.Purchase_UOM__c = fuel.itemList[5].Purchasing_UOM__c;
                poLine2.Company__c = fuel.company.id;
                poLine2.Need_Date__c = system.today() + 7;
                poLine2.Delivery_Facility__c = fuel.facility2.id;
                poLine2.Delivery_Location__c = fuel.location2.ID;
                poLine2.Supplier__c = fuel.supplier.Id;
                poLine2.Line__c = 2;
                insert poLine2; 
        }
        
        
        po1.Approval_Status__c = 'Approved';
        
        update po1;   
         //update po2;   
        
        test.startTest();
        ReceivingWorkBenchExt.setGridConfig('Purchase Order',fuel.facility2.id);
        
        
        String facilityId = po1.Delivery_Facility__c;        
        String fobId = fobTerm.Id;               
        
        JSONResult searchresult = new JSONResult();  
        JSONResult searchresult1 = new JSONResult();       
       
        //Now Search for this POLines on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('Purchase Order');
        ReceivingWorkBenchExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('Purchase Order');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
                
       
        List<Id> polineIds = new List<Id>();
        
        List<Purchase_Order_Line__c> polinelist = [Select Id, Name, Purchase_Order__r.Approval_Status__c, delivery_facility__c, Purchase_Order__c, Purchase_Order__r.FOB_Term__r.FOB_Point__c, Status__c, Company__c, Supplier__c 
                                            from Purchase_Order_Line__c where delivery_facility__c =:facilityId and Purchase_Order__r.FOB_Term__r.FOB_Point__c = 'Origin'];
        system.assert(polinelist.size() == 1, polinelist);
        
        for(Purchase_Order_Line__c line:polinelist){
                
            system.assert(line.Purchase_Order__r.FOB_Term__r.FOB_Point__c == 'Origin', polinelist);                     
            system.assert(line.Purchase_Order__r.Approval_Status__c == 'Approved', line.Purchase_Order__r.Approval_Status__c); 
            polineIds.add(line.id);
        }
        
        
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, fobId, po1.Id, null, null, null, null);       
        system.assert(searchresult.total == 0, searchresult);
        Boolean errorFound;
        if(searchresult.messages != null && searchresult.messages.size() > 0){
				for (Map<String, String> msg : searchresult.messages) {
					if(msg.get('message').contains(Label.Cannot_Receive_FOB_Origin)){
				    	errorFound = true;
				    }
				}
		}
		
		system.assert(errorFound == true);

        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poline = fuel.purchaseOrderLines[0];
        
        List<Purchase_Order_Line__c> polinelist1 = [Select Id, Name, Purchase_Order__r.Approval_Status__c, delivery_facility__c, Purchase_Order__c, Purchase_Order__r.FOB_Term__r.FOB_Point__c, Status__c, Company__c, Supplier__c 
                                            from Purchase_Order_Line__c where delivery_facility__c =:facilityId];
        system.assert(polinelist1.size() == 2, polinelist1);
        
        searchresult1 = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, fuel.fobTerm.Id, null, null, null, null, null);       
        system.assert(searchresult1.total == 1, searchresult1);
                
    }
    
    //Back to Back auto allocate receive flow
    static testMethod void receivePurchaseOrderLineBackToBack(){       
        
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<Configuration__c> configList1 = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Location__c.sObjectType,Currency__c.sObjectType ,Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,
            Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, item_attribute__c.sObjectType,Shipment__c.sObjectType,Customer__c.sObjectType, Shipment_Line__c.sObjectType,Product__c.sObjectType,Item__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
            configList1.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        sales_order__c sOrder = new sales_order__c();
        sOrder.type__c = 'Standard';
        sOrder.Company__c = fuel.company.id;
        sOrder.Customer__c = fuel.customerSoldTo.id;   
        sOrder.Ship_To__c = fuel.customerShipTo.Id;
        sOrder.Bill_To__c = fuel.customerBillTo.Id;
        sOrder.Payment_Term__c = fuel.terms.id;
        sOrder.Currency__c = fuel.currencyUSD.id;
        insert sOrder;
        
        List<Sales_Order_Line__c> salesOrderLines = new List<Sales_Order_Line__c>();
        
        soline.Company__c = fuel.company.Id;
        soline.Description__c = fuel.product.Description__c;
        soline.Discount_Percent__c = 2;
        soline.Product__c = fuel.product.Id;
        soline.Quantity_Ordered__c = 100;
        soline.Required_Date__c = System.today()+5;
        soline.Sales_Order__c = sOrder.Id;
        soline.Sales_Order__r = sOrder;
        soline.Ship_From_Location__c = fuel.location2.Id;
        soline.Unit_Price__c = 11.12;
        soline.fulfillment_source__c = 'Back To Back';
        soLine.Selling_Uom__c = fuel.uomList[8].id;
        soline.Memo__c = 'soline';
        salesOrderLines.add(soline);
        insert salesOrderLines;
        
        Purchase_Order__c po = new Purchase_Order__c();
         
        po.Supplier__c = fuel.supplier.id;
        po.Company__c = fuel.company.id;
        po.Payment_Term__c = fuel.terms.id;
        po.Delivery_Facility__c = fuel.facility2.id;
        po.Delivery_Location__c = fuel.location2.ID;
        po.Remit_To_Supplier__c = fuel.remitToSupplier.id;
        po.Approval_Status__c = 'Approved';
        po.fob_term__c = fuel.fobTerm.id;
        po.Acknowledge_Via__c = 'Email';
        po.Status__c = 'Open';
        po.Memo__c = 'purchaseOrder';
        po.Currency__c = fuel.currencyUSD.id;
                                       
        insert po;
        
                
        Purchase_Order_Line__c poLine = new Purchase_Order_Line__c();
        poLine.Purchase_Order__c = po.Id;
        poLine.Order_Quantity__c = 10;     
        poLine.Unit_Price__c = 12;
        poLine.Item__c = fuel.itemList[0].Id;
        poLine.Description__c = fuel.itemList[0].Description__c;
        poLine.Purchase_UOM__c = fuel.itemList[0].Purchasing_UOM__c;
        poLine.Company__c = fuel.company.id;
        poLine.Need_Date__c = system.today() + 7;
        poLine.Delivery_Facility__c = fuel.facility2.id;
        poLine.Delivery_Location__c = fuel.location2.ID;
        poLine.Supplier__c = fuel.supplier.Id;
        poLine.Line__c = 1;
        poLine.Quantity_Matched__c = 0;
        poLine.Amount_Matched__c = 0;
        poLine.Type__c = 'Back To Back';
        poLine.sales_order_line__c = soline.id; 
        insert poLine;
        
        po.Approval_Status__c = 'Approved';
        update po;
        fuel.itemList[0].item_attribute__c = null;
        update fuel.itemList[0];
       
        SalesOrderService sos = new SalesOrderService();
       
        Test.startTest();
        sos.plan(sOrder.Id);
        delete configList;
        
        insert configList1;  
        list<shipment_line__c> shipLine = [SELECT id from shipment_line__c where sales_order_line__c = :soline.id];
        system.assertEquals(1, shipLine.size());
        sOrder.Status__c = 'Open';
        update sOrder;
        soline.Status__c = 'Open';
        update soline;
        
        
        ReceivingWorkBenchExt.setGridConfig('Purchase Order' , fuel.facility2.id);
      
        String docnum = po.Id;
        String facilityId = po.Delivery_Facility__c;
        String supplierId = po.Supplier__c;
        String itemId = poline.Item__c; 
        
       
        JSONResult searchresult = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();         
        
        //Now Search for this POLines on Receiving Workbench Page
        
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('Purchase Order');
        ReceivingWorkBenchExt.refreshTrackedAttr(fuel.Location, fuel.itemList[0], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('Purchase Order');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
                
       
        list<Id> polineIds = new list<Id>();
        polineIds.add(poLine.id);
        
        List<Purchase_Order_Line__c> polinelist = [Select Id, Name, Purchase_Order__r.Name, Purchase_Order__r.Approval_Status__c, delivery_facility__c, Purchase_Order__c, Purchase_Order__r.FOB_Term__r.FOB_Point__c, Status__c, Company__c, Supplier__c 
                                            from Purchase_Order_Line__c where delivery_facility__c =:facilityId];
        system.assert(polinelist.size() == 2, polinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,facilityId,po.Name,'Purchase Order');
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, supplierId, null, po.Id, null, null, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
        delete configList1;
        //Manage Receive        
         
        getListresult = ReceivingWorkBenchExt.getList(polineIds, 'Purchase Order');
        system.assert(getListresult.success == true, getListresult.message);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(polineIds, 'Purchase Order', fuel.currencyUSD.id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(polineIds), new set<String>{'Purchase_Order_Line__c'.toLowerCase()} );
        system.assertEquals(1,rwrapperlist.size());
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
       
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                
                
                if(skid.Item__c == fuel.itemList[0].Id){
                    skid.Quantity__c = 10;
                    skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = fuel.uomObj;
                    sw.skid.Packaging_UOM__r.Package_Class__r = null;
                }
                
                List<Serial__c> serialList = new List<Serial__c>();
                for (Integer i=0;i<skid.Quantity__c;i++) {
                    Serial__c ser = new Serial__c(
                        Name = 'Serial ' + i,
                        Item__c = skid.Item__c,
                        Company__c = fuel.company.Id
                    );
                    ser.Unique_Key2__c = fuel.company.Id + '-' + ser.Item__c + '-' + ser.Name;
                    serialList.Add(ser);
                }
                sw.serialList = serialList;             
            }
        }
        
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        Test.stopTest(); 
        List<Purchase_Order_Line__c> updatedpolines = [Select Id, Purchase_Order__c,Status__c, Quantity_Still_Due__c, Quantity_Received__c from Purchase_Order_Line__c where delivery_facility__c =:facilityId];
        sales_Order_Line__c updatedsoline = [Select Id, Status__c,Quantity_Allocated__c from sales_Order_Line__c where id =:soline.id];
        
        //auto allocate sales order line with poline quantity.
        //system.assertEquals(10,updatedsoline.Quantity_Allocated__c); Commented autoallocate for CRP1
        
        for(Purchase_Order_Line__c line:updatedpolines){     
            if(line.Purchase_Order__c == po.Id){
                system.assert(line.Status__c == 'Closed', line);
                system.assert(line.Quantity_Still_Due__c == 0, line.Quantity_Still_Due__c);  
            }       
                   
        }                                   
                                            
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Quantity_Received__c, Status__c, Purchase_Order_Line__c, Purchase_Order__c, ASN_Line__c, Receiving_Document__r.Transaction_Type__c, 
                                                Receiving_Document__r.Finalized__c, Receiving_Document__r.Status__c, Receiving_Document__r.Type__c from Receipt_Line__c where Receipt_Line__c.Receiving_Document__c =: rdoc.Id];
        system.assert(receiptlines.size() == 1, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Purchase_Order__c == po.Id );
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'Purchase Order Receipt');
            if(rcptline.Purchase_Order__c == po.Id){
                system.assert(rcptline.Quantity_Received__c == 10, rcptline.Quantity_Received__c);
            }
            
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'Purchase Order Receipt', rcptline);
            
        }
               
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Purchase_Order_Line__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, 
                                                To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c,
                                                 (Select Id, Serial__c, Serial__r.Allow_Reentry__c, Serial__r.SKID__c, Type__c From Serial_Transactions__r) 
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        system.assert(itlist.size() == 1, itlist);       
        for(Inventory_Transaction__c it: itlist){
            
            if(it.Purchase_Order_Line__c == poLine.Id){
                system.assert(it.Quantity__c == 10, itList);
                 system.assertEquals(10, it.Serial_Transactions__r.size());
            }
            
            
            system.assert(it.Subtransaction_Type__c == 'Purchase Order Receipt');
            system.assert(it.Type__c == 'Purchase Order Receipt');
            system.assert(it.Receipt_Line__c !=null);       
            
        }
      	
        
    }
    
    
    
    static testMethod void receivePurchaseOrderwithSerials(){       
        

        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poline = fuel.purchaseOrderLines[0];
        
        FOB_Terms__c fobTerm = new FOB_Terms__c();{
            fobTerm.Name = 'test term destination';
            fobTerm.FOB_Point__c = 'Destination';
            insert fobTerm;
        }        
                
        Purchase_Order__c po1 = new Purchase_Order__c(
                                                    Supplier__c = fuel.supplier.id, 
                                                    Company__c = fuel.company.id,
                                                    Payment_Term__c = fuel.terms.id,
                                                    Delivery_Facility__c = fuel.facility2.id,
                                                    Delivery_Location__c = fuel.location2.ID,
                                                    Remit_To_Supplier__c = fuel.remitToSupplier.id,
                                                    Approval_Status__c = 'Approved',
                                                    fob_term__c = fobTerm.id,
                                                    Status__c = 'Open',
                                                    Memo__c = 'purchaseOrder',
                                                    Currency__c = fuel.currencyUSD.id
                                        );
        insert po1;
        Purchase_Order_Line__c poLine2 = new Purchase_Order_Line__c();{
                poLine2.Purchase_Order__c = po1.Id;
                poLine2.Order_Quantity__c = 15;     
                poLine2.Unit_Price__c = 24;
                poLine2.Item__c = fuel.itemList[5].Id;
                poLine2.Description__c = fuel.itemList[5].Description__c;
                poLine2.Purchase_UOM__c = fuel.itemList[5].Purchasing_UOM__c;
                poLine2.Company__c = fuel.company.id;
                poLine2.Need_Date__c = system.today() + 7;
                poLine2.Delivery_Facility__c = fuel.facility2.id;
                poLine2.Delivery_Location__c = fuel.location2.ID;
                poLine2.Supplier__c = fuel.supplier.Id;
                poLine2.Line__c = 2;
                insert poLine2; 
        }
        
        
        po1.Approval_Status__c = 'Approved';
        update po1;   
         
        fuel.itemList[2].item_attribute__c = null;
        update fuel.itemList[2];
        
        fuel.itemList[5].item_attribute__c = null;
        update fuel.itemList[5];
        
        test.startTest();
        ReceivingWorkBenchExt.setGridConfig('Purchase Order' , fuel.facility2.id);
        
        //Create PO    
       
       // List<Purchase_Order_Line__c> queriedPOL = [Select Id,Name, Purchase_Order__r.Delivery_Facility__c, Status__c, Purchase_Order__r.FOB_Term__c from Purchase_Order_Line__c where Id =:poline.Id]; 
        String docnum = po.Id;
        String facilityId = po.Delivery_Facility__c;
        String supplierId = po.Supplier__c;
        String itemId = poline.Item__c; 
        String fobId = fobTerm.Id;
        
       
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();         
                                       
       
        //Now Search for this POLines on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('Purchase Order');
        ReceivingWorkBenchExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('Purchase Order');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
                
       
        List<Id> polineIds = new List<Id>();
        
        List<Purchase_Order_Line__c> polinelist = [Select Id, Name, Purchase_Order__r.Name, Purchase_Order__r.Approval_Status__c, delivery_facility__c, Purchase_Order__c, Purchase_Order__r.FOB_Term__r.FOB_Point__c, Status__c, Company__c, Supplier__c 
                                            from Purchase_Order_Line__c where delivery_facility__c =:facilityId];
        system.assert(polinelist.size() == 2, polinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,facilityId,polinelist[0].Purchase_Order__r.Name,'Purchase Order');
        for(Purchase_Order_Line__c line:polinelist){
            system.assert(line.Status__c == 'Open', polinelist);
            system.assert(line.delivery_facility__c == facilityId, polinelist);
            system.assert(line.Supplier__c == supplierId, polinelist);          
            system.assert(line.Purchase_Order__r.FOB_Term__r.FOB_Point__c != 'Origin', polinelist);  
            //system.assert(line.Purchase_Order__c == po.Id || line.Purchase_Order__c == po1.Id || line.Purchase_Order__c == po2.Id, polinelist);               
            system.assert(line.Purchase_Order__r.Approval_Status__c == 'Approved', line.Purchase_Order__r.Approval_Status__c); 
            polineIds.add(line.id);
        }
       
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, supplierId, fobId, null, null, null, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
        
        
        //Manage Receive        
         
        getListresult = ReceivingWorkBenchExt.getList(polineIds, 'Purchase Order');
        system.assert(getListresult.success == true, getListresult.message);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(polineIds, 'Purchase Order', fuel.currencyUSD.id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(polineIds), new set<String>{'Purchase_Order_Line__c'.toLowerCase()} );
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                
                 sw.skid.Packaging_UOM__r.Package_Class__r = null;
                 
            }
        }

        try {
            ReceivingDocumentServiceV2.checkUserErrors(rwrapperlist);
        } catch (Exception e){
            System.assert(e.getMessage().contains(Label.No_Quantities_Entered_To_Receive));
        }
       
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                
                if(skid.Item__c == fuel.itemList[2].Id){
                    skid.Quantity__c = 10;
                }
                else if(skid.Item__c == fuel.itemList[5].Id){
                    skid.Quantity__c = 15;
                }
                List<Serial__c> serialList = new List<Serial__c>();
                for (Integer i=0;i<skid.Quantity__c;i++) {
                    Serial__c ser = new Serial__c(
                        Name = 'Serial ' + i,
                        Item__c = skid.Item__c,
                        Company__c = fuel.company.Id
                    );
                    ser.Unique_Key2__c = fuel.company.Id + '-' + ser.Item__c + '-' + ser.Name;
                    serialList.Add(ser);
                }
                sw.serialList = serialList;             
            }
        }
        
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        test.stopTest();
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
        
        List<Purchase_Order_Line__c> updatedpolines = [Select Id, Status__c, Quantity_Still_Due__c, Quantity_Received__c from Purchase_Order_Line__c where delivery_facility__c =:facilityId];
        
        for(Purchase_Order_Line__c line:updatedpolines){            
            system.assert(line.Status__c == 'Closed', line);
            system.assert(line.Quantity_Still_Due__c == 0, line.Quantity_Still_Due__c);         
        }                                   
                                            
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Quantity_Received__c, Status__c, Purchase_Order_Line__c, Purchase_Order__c, ASN_Line__c, Receiving_Document__r.Transaction_Type__c, 
                                                Receiving_Document__r.Finalized__c, Receiving_Document__r.Status__c, Receiving_Document__r.Type__c from Receipt_Line__c where Receipt_Line__c.Receiving_Document__c =: rdoc.Id];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Purchase_Order__c == po.Id || rcptline.Purchase_Order__c == po1.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'Purchase Order Receipt');
            if(rcptline.Purchase_Order__c == po.Id){
                system.assert(rcptline.Quantity_Received__c == 10, rcptline.Quantity_Received__c);
            }
            else if(rcptline.Purchase_Order__c == po1.Id){
                system.assert(rcptline.Quantity_Received__c == 15, rcptline.Quantity_Received__c);
            }
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'Purchase Order Receipt', rcptline);
            
        }
               
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Purchase_Order_Line__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, 
                                                To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c,
                                                 (Select Id, Serial__c, Serial__r.Allow_Reentry__c, Serial__r.SKID__c, Type__c From Serial_Transactions__r) 
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        system.assert(itlist.size() == 2, itlist);       
        for(Inventory_Transaction__c it: itlist){
            
            if(it.Purchase_Order_Line__c == poLine.Id){
                system.assert(it.Quantity__c == 10, itList);
                 system.assertEquals(10, it.Serial_Transactions__r.size());
            }
            else if(it.Purchase_Order_Line__c == poLine2.Id){
                system.assert(it.Quantity__c == 15, itList);
                 system.assertEquals(15, it.Serial_Transactions__r.size());
            }
            
            system.assert(it.Subtransaction_Type__c == 'Purchase Order Receipt');
            system.assert(it.Type__c == 'Purchase Order Receipt');
            system.assert(it.Receipt_Line__c !=null);       
            
        }
        
        
    }
    
   static testMethod void searchRMALines_Errors(){       
        createSalesOrder(SalesOrderService.SO_TYPE_RMA);
        
        Facility__c facility1 = fuel.facility2;
        facility1.RMA_Receipt_Routing__c = 'Inspect';
        update facility1;
        
        so.Status__c = 'Open';
        update so;
        
        soline.Status__c = 'Open';
        soline1.Status__c = 'Open';
        update soline;
        update soline1;
        
        
        ReceivingWorkBenchExt.setGridConfig('RMA' , fuel.facility2.id);
        
        //Create ASN with inTransit SKID       
       
        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Type__c, Customer__c, Ship_From_Location__r.Facility__c, Currency__c  from Sales_Order__c where Id =:so.Id]; 

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
        //Now Search for this ASN on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('RMA');
        ReceivingWorkBenchExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('RMA');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        
        ReceivingWorkBenchExt.getCurrencyCode(null,facilityId,so.Id,'RMA');
        
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, docnum, customerFilter, currencyfilter, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
        
    }
    
    static testMethod void searchRMALines_ReceiveErrors(){       
        createSalesOrder(SalesOrderService.SO_TYPE_RMA);
        
        Facility__c facility1 = fuel.facility2;
        facility1.RMA_Receipt_Routing__c = 'Inspect';
        update facility1;
        test.startTest();
        List<Sales_Order_Line__c> solinelist = new List<Sales_Order_Line__c>();
        soline.Status__c = 'Closed';
        soline1.Status__c = 'Closed';
        solinelist.add(soline);
        solinelist.add(soline1);
        update solinelist;
        
        
        ReceivingWorkBenchExt.setGridConfig('RMA' , fuel.facility2.id);
        
        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Type__c, Customer__c, Ship_From_Location__r.Facility__c, Currency__c  from Sales_Order__c where Id =:so.Id]; 

        String docnum = queriedSO.Id;

        String facilityId = queriedSO.Ship_From_Location__r.Facility__c;
        String customerFilter = queriedSO.Customer__c;
        ID currencyfilter = queriedSO.Currency__c;
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
       
             
        
        //Now Search for this RMA on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('RMA');
        ReceivingWorkBenchExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('RMA');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, docnum, customerFilter, currencyfilter, null, null);
        system.assertEquals(searchresult.success, false);
        system.assert(searchresult.total ==0, searchresult);
        
        Boolean errorRMAFound = false;
        if(searchresult.messages != null && searchresult.messages.size() > 0){
				for (Map<String, String> msg : searchresult.messages) {
					
				    if(msg.get('message').contains(Label.RMA_No_Open_Lines)){
				    	errorRMAFound = true;
				    }
				}
		}
     
        system.assert(errorRMAFound == true,searchresult.messages);
        
        test.stopTest();
    }
    
    static testMethod void searchRMALines_NotRMA_SO(){       
        
        test.startTest();
        ReceivingWorkBenchExt.setGridConfig('RMA' , fuel.facility.id);
        
        String facilityId = fuel.facility.Id;
       
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
          
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('RMA');
        ReceivingWorkBenchExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('RMA');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, null, null, null, null, null);
        system.assertEquals(searchresult.success, false);
        system.assert(searchresult.total ==0, searchresult);
        
        Boolean errorRMAFound = false;
        if(searchresult.messages != null && searchresult.messages.size() > 0){
				for (Map<String, String> msg : searchresult.messages) {
					
				    if(msg.get('message').contains(Label.No_Receivable_Records_Found)){
				    	errorRMAFound = true;
				    }
				}
		}
     
        system.assert(errorRMAFound == true,searchresult.messages);
        
        test.stopTest();
    }
    
    static testMethod void searchRMALines_Errors1(){       
       
        Sales_Order__c sorder= new Sales_Order__c();
        Sales_Order_Line__c sorderline = new Sales_Order_Line__c();
        
        sorder.Company__c = fuel.company.id;
        sorder.Customer__c = fuel.customerSoldTo.id;   
        sorder.Ship_To__c = fuel.customerShipTo.Id;
        sorder.Bill_To__c = fuel.customerBillTo.Id;
        sorder.Payment_Term__c = fuel.terms.id;
        sorder.Currency__c = fuel.currencyUSD.id;
        sorder.Type__c = 'Standard';
        insert sorder;
        
        
        sorderline.Company__c = fuel.company.Id;
        sorderline.Description__c = fuel.product.Description__c;
        sorderline.Discount_Percent__c = 2;
        sorderline.Product__c = fuel.product.Id;
        sorderline.Quantity_Ordered__c = 100;
        sorderline.Required_Date__c = System.today()+5;
        sorderline.Sales_Order__c = sorder.Id;
        sorderline.Sales_Order__r = sorder;
        sorderline.Ship_From_Location__c = fuel.location2.Id;
        sorderline.Unit_Price__c = 11.12;
        sorderline.Memo__c = 'soline';
        

		insert sorderline;
		
		sorderline.status__c='Open';
        update sorderline;
        
        sorder.Status__c = 'Open';
        update sorder;
        
        ReceivingWorkBenchExt.setGridConfig('RMA' , fuel.facility2.id);
        
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
       
             
        test.startTest();
        
        searchresult = ReceivingWorkBenchExt.getDocumentInfo('Sales_Order_Line__c',sorder.Id);
        system.assertEquals(searchresult.success, false);
        system.assert(searchresult.total ==0, searchresult);
        
        Boolean errorRMAFound = false;
        if(searchresult.messages != null && searchresult.messages.size() > 0){
				for (Map<String, String> msg : searchresult.messages) {
					
				    if(msg.get('message').contains(Label.Cannot_Receive_SO_Type)){
				    	errorRMAFound = true;
				    }
				}
		}
     
        system.assert(errorRMAFound == true,searchresult.messages);
        
        test.stoptest();
    }
    

    static testMethod void receiveRMALines(){       
        createSalesOrder(SalesOrderService.SO_TYPE_RMA);
        
        Facility__c facility1 = fuel.facility2;
        facility1.RMA_Receipt_Routing__c = 'Inspect';
        update facility1;
        
        so.Status__c = 'Open';
        update so;
        
        soline.Status__c = 'Open';
        soline1.Status__c = 'Open';
        update soline;
        update soline1;
        
        
        ReceivingWorkBenchExt.setGridConfig('RMA' , fuel.facility2.id);
        
        //Create ASN with inTransit SKID       
       
        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Type__c, Currency__c, Customer__c, Ship_From_Location__r.Facility__c from Sales_Order__c where Id =:so.Id]; 

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
        //Now Search for this ASN on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
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
                                            from Sales_Order_Line__c where Sales_Order__c =:so.Id];
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
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(solineIds, 'RMA', fuel.currencyUSD.id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(solineIds), new set<String>{'Sales_Order_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                    skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = fuel.uomObj;
                }
                else{
                    skid.Quantity__c = 4;
                    skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = fuel.uomObj;
                }
                skid.Packaging_UOM__r.Package_Class__r = null;   
              
             }
        }
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
    
        List<Fulfillment__c> fulfillmentrecs = [Select Id, Status__c, Quantity__c, Sales_Order__c,Sales_Order_Line__c from Fulfillment__c where Sales_Order__c =:so.Id];
        
        system.assert(fulfillmentrecs.size() == 2, fulfillmentrecs);    
        
        for(Fulfillment__c rec:fulfillmentrecs){
            if(rec.Sales_Order_Line__c == soline.Id)
                system.assert(rec.Quantity__c == -5, rec);
            else
                system.assert(rec.Quantity__c == -4, rec);
            
        }
                                        
        //Also check Quantity_Fulfilled__c on updated solines.  
        
        List<Sales_Order_Line__c> updatedsolinelist = [Select Id, Status__c, Quantity_Fulfilled__c from Sales_Order_Line__c where Sales_Order__c =:so.Id];
        
        
        for(Sales_Order_Line__c sol:updatedsolinelist){
            if(sol.Id == soline.Id)
                system.assert(sol.Quantity_Fulfilled__c == -5, sol);
            else
                system.assert(sol.Quantity_Fulfilled__c == -4, sol);
            
        }
        test.stopTest();                            
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Status__c, Item__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Sales_Order__c =:so.Id and Sales_Order__r.Type__c = 'RMA-Credit'];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c == null);
            system.assert(rcptline.Sales_Order__c == so.Id);
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
    
    }

    static testMethod void receiveRMAForRepairLines(){


        
        createSalesOrder(SalesOrderService.SO_TYPE_RMA_REPAIR);

        Facility__c facility1 = fuel.facility2;
        facility1.RMA_Receipt_Routing__c = 'Inspect';
        update facility1;

        //Update Sales Order Type as RMA
        so.Status__c = 'Open';
        update so;

        soline.Status__c = 'Open';
        soline1.Status__c = 'Open';
        update soline;
        update soline1;


        ReceivingWorkBenchExt.setGridConfig('RMA', fuel.facility2.id);

        //Create ASN with inTransit SKID

        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Currency__c, Customer__c, Ship_From_Location__r.Facility__c  from Sales_Order__c where Id =:so.Id];
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
        //Now Search for this ASN on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
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
        from Sales_Order_Line__c where Sales_Order__c =:so.Id];
        system.assert(newSOLinelist.size() == 2, newSOLinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,facility1.Id,null,'RMA');
        List<Id> solineIds = new List<Id>();
        for(Sales_Order_Line__c line:newSOLinelist){
            if(facilityId ==null)
                facilityId = line.Ship_From_Location__r.Facility__c;
            system.assert(line.Status__c == 'Open', newSOLinelist);
            system.assert(line.Sales_Order__r.Customer__c == customerFilter, newSOLinelist);
            system.assert(line.Sales_Order__c == docnum, newSOLinelist);
            system.assert(line.Sales_Order__r.Type__c == 'RMA-Customer-Repair', newSOLinelist);
            system.assert(line.Sales_Order__r.Status__c == 'Open', newSOLinelist);
            solineIds.add(line.id);
        }

        getListresult = ReceivingWorkBenchExt.getList(solineIds, 'RMA');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total >0);

        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(solineIds, 'RMA', fuel.currencyUSD.id);

        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(solineIds), new set<String>{'Sales_Order_Line__c'.toLowerCase()} );

        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                    skid.Packaging_UOM__c = fuel.uomList[8].id;
                }
                else{
                    skid.Quantity__c = 4;
                    skid.Packaging_UOM__c = fuel.uomList[8].id;
                }


            }
        }
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);

        
        system.assert(receiveLinesresult.success == true, receiveLinesresult);

        List<Fulfillment__c> fulfillmentrecs = [Select Id, Status__c, Quantity__c, Sales_Order__c,Sales_Order_Line__c from Fulfillment__c where Sales_Order__c =:so.Id];

        system.assert(fulfillmentrecs.size() == 2, fulfillmentrecs);

        for(Fulfillment__c rec:fulfillmentrecs){
            if(rec.Sales_Order_Line__c == soline.Id)
                system.assert(rec.Quantity__c == -5, rec);
            else
                    system.assert(rec.Quantity__c == -4, rec);

        }

        //Also check Quantity_Fulfilled__c on updated solines.

        List<Sales_Order_Line__c> updatedsolinelist = [Select Id, Status__c, Quantity_Fulfilled__c from Sales_Order_Line__c where Sales_Order__c =:so.Id];


        for(Sales_Order_Line__c sol:updatedsolinelist){
            if(sol.Id == soline.Id)
                system.assert(sol.Quantity_Fulfilled__c == -5, sol);
            else
                    system.assert(sol.Quantity_Fulfilled__c == -4, sol);

        }

        Set<ID> receiptlineSet = new Set<ID>();
        test.stopTest();
        List<Receipt_Line__c> receiptlines = [Select Id, Status__c, Item__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c,
                Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Sales_Order__c =:so.Id and Sales_Order__r.Type__c = 'RMA-Customer-Repair'];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c == null);
            system.assert(rcptline.Sales_Order__c == so.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'RMA Receipt For Repair');
            if(rcptline.Item__c == fuel.itemList[0].ID){
                system.assert(rcptline.Quantity_Received__c == 5, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 5, rcptline.Quantity_Still_Due_For_Putaway__c);
            }
            else{
                system.assert(rcptline.Quantity_Received__c == 4, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 4, rcptline.Quantity_Still_Due_For_Putaway__c);
            }

            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'RMA Receipt For Repair', rcptline);
        }

        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
        FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];

        system.assert(itlist.size() == 0, itlist);

    }
    
    static testMethod void receiveRMALinesOneStep(){    
        
        createSalesOrder(SalesOrderService.SO_TYPE_RMA);
        test.startTest();
        
        Facility__c facility1 = fuel.facility2;
        
        //Update Sales Order Type as RMA
        
        so.Status__c = 'Open';
        update so;
        
        soline.Status__c = 'Open';
        soline1.Status__c = 'Open';
        update soline;
        update soline1;
        
        ReceivingWorkBenchExt.setGridConfig('RMA', fuel.facility2.id);
       
        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Currency__c, Customer__c, Ship_From_Location__r.Facility__c  from Sales_Order__c where Id =:so.Id]; 
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
         
        List<Sales_Order_Line__c> newSOLinelist = [Select Id, Packaging_UOM__c,Product__r.Item__r.Stocking_UOM__c,Product__r.Item__r.Stocking_UOM__r.Name,Ship_From_Location__r.Facility__c, Quantity_Ordered__c, Sales_Order__r.Customer__c,
                                            Sales_Order__r.Currency__c, Sales_Order__r.Status__c, Sales_Order__r.Name,Sales_Order__r.Type__c, Product__r.Item__r.Name, Status__c 
                                            from Sales_Order_Line__c where Sales_Order__c =:so.Id];
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
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(solineIds, 'RMA', fuel.currencyUSD.id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(solineIds), new set<String>{'Sales_Order_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){

             for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                    skid.Expiration_Date__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Scrap';
                    skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = fuel.uomObj;
                }
                else{
                    skid.Quantity__c = 4;
                    skid.Expiration_Date__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Inventory';
                    skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = fuel.uomObj;
                }
                skid.Packaging_UOM__r.Package_Class__r = null;
                    
              
    }
        }
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
    
        List<Fulfillment__c> fulfillmentrecs = [Select Id, Status__c, Quantity__c, Sales_Order__c,Sales_Order_Line__c from Fulfillment__c where Sales_Order__c =:so.Id];
        
        system.assertEquals(2, fulfillmentrecs.size(), fulfillmentrecs);
        for(Fulfillment__c rec:fulfillmentrecs){
            if(rec.Sales_Order_Line__c == soline.Id)
                system.assert(rec.Quantity__c == -5, rec);
            else
                system.assert(rec.Quantity__c == -4, rec);
            
        }
                                        
        //Also check Quantity_Fulfilled__c on updated solines.  
        
        List<Sales_Order_Line__c> updatedsolinelist = [Select Id, Status__c, Quantity_Fulfilled__c from Sales_Order_Line__c where Sales_Order__c =:so.Id];
        
        
        for(Sales_Order_Line__c sol:updatedsolinelist){
            if(sol.Id == soline.Id)
                system.assert(sol.Quantity_Fulfilled__c == -5, sol);
            else
                system.assert(sol.Quantity_Fulfilled__c == -4, sol);
            
        }
                                    
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Status__c, Item__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Sales_Order__c =:so.Id and Sales_Order__r.Type__c = 'RMA-Credit'];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c == null);
            system.assert(rcptline.Sales_Order__c == so.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'RMA Receipt');
            if(rcptline.Item__c == fuel.itemList[0].ID){
                system.assert(rcptline.Quantity_Received__c == 5, rcptline.Quantity_Received__c);
                system.assertEquals(0, rcptline.Quantity_Still_Due_For_Putaway__c, receiptlines);
            }
            else{
                system.assert(rcptline.Quantity_Received__c == 4, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 0, rcptline.Quantity_Still_Due_For_Putaway__c);
            } 
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'RMA Receipt', rcptline);            
        }
    
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c,Inventory_Change__c,Inventory_Change__r.Type__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        test.stopTest();
        system.assert(itlist.size() == 2, itlist);
        Set<Id> inventorychangeset = new Set<Id>();
        Boolean invflag, scrapflag;
        for(Inventory_Transaction__c it: itlist){

            if (it.Type__c == 'RMA Receipt') {
                invflag = true;
            }
            if(it.Type__c == 'RMA Scrap'){
                scrapflag = true;
            }
            
            inventorychangeset.add(it.Inventory_Change__c);
        }
    
        System.assertEquals(2,inventorychangeset.size(),itlist);
        system.assert(invflag ==true && scrapflag == true);
    }
    
    static testMethod void receiveRMARepairLinesOneStep(){    

        
        createSalesOrder(SalesOrderService.SO_TYPE_RMA_REPAIR);

        
        Facility__c facility1 = fuel.facility2;
        
        //Update Sales Order Type as RMA-Customer-Repair
        so.Status__c = 'Open';
        update so;
        
        soline.Status__c = 'Open';
        soline1.Status__c = 'Open';
        update soline;
        update soline1;
        
        ReceivingWorkBenchExt.setGridConfig('RMA', fuel.facility2.id);
       
        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Currency__c, Customer__c, Ship_From_Location__r.Facility__c  from Sales_Order__c where Id =:so.Id]; 
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
        ReceivingWorkBenchExt.getCurrencyCode(null,null,null,'Purchase Order');        
         
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, docnum, customerFilter, currencyfilter, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
       
         //Manage Receive        
         
        List<Sales_Order_Line__c> newSOLinelist = [Select Id, Ship_From_Location__r.Facility__c, Quantity_Ordered__c, Sales_Order__r.Customer__c,
                                            Sales_Order__r.Currency__c, Sales_Order__r.Status__c, Sales_Order__r.Name,Sales_Order__r.Type__c, Product__r.Item__r.Name, Status__c 
                                            from Sales_Order_Line__c where Sales_Order__c =:so.Id];
        system.assert(newSOLinelist.size() == 2, newSOLinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,facility1.Id,null,'RMA');
        List<Id> solineIds = new List<Id>();
        for(Sales_Order_Line__c line:newSOLinelist){
            if(facilityId ==null)
                facilityId = line.Ship_From_Location__r.Facility__c;
            system.assert(line.Status__c == 'Open', newSOLinelist);
            system.assert(line.Sales_Order__r.Customer__c == customerFilter, newSOLinelist);            
            system.assert(line.Sales_Order__c == docnum, newSOLinelist); 
            system.assert(line.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_RMA_REPAIR, newSOLinelist); 
            system.assert(line.Sales_Order__r.Status__c == 'Open', newSOLinelist); 
            solineIds.add(line.id);
        }
        
        getListresult = ReceivingWorkBenchExt.getList(solineIds, 'RMA');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(solineIds, 'RMA',fuel.currencyUSD.id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(solineIds), new set<String>{'Sales_Order_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){

             for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                    skid.Expiration_Date__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Scrap';
                    skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = fuel.uomObj;
                }
                else{
                    skid.Quantity__c = 4;
                    skid.Expiration_Date__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Inventory';
                    skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = fuel.uomObj;
                }
                skid.Packaging_UOM__r.Package_Class__r = null;
                    
              
    }
        }
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        rdoc.Currency__c = fuel.currencyUSD.id;
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
    
        List<Fulfillment__c> fulfillmentrecs = [Select Id, Status__c, Quantity__c, Sales_Order__c,Sales_Order_Line__c from Fulfillment__c where Sales_Order__c =:so.Id];
        
        system.assertEquals(2, fulfillmentrecs.size(), fulfillmentrecs);
        for(Fulfillment__c rec:fulfillmentrecs){
            if(rec.Sales_Order_Line__c == soline.Id)
                system.assert(rec.Quantity__c == -5, rec);
            else
                system.assert(rec.Quantity__c == -4, rec);
            
        }
                                        
        //Also check Quantity_Fulfilled__c on updated solines.  
        
        List<Sales_Order_Line__c> updatedsolinelist = [Select Id, Status__c, Quantity_Fulfilled__c from Sales_Order_Line__c where Sales_Order__c =:so.Id];
        
        
        for(Sales_Order_Line__c sol:updatedsolinelist){
            if(sol.Id == soline.Id)
                system.assert(sol.Quantity_Fulfilled__c == -5, sol);
            else
                system.assert(sol.Quantity_Fulfilled__c == -4, sol);
            
        }
                                    
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Status__c, Item__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Sales_Order__c =:so.Id and Sales_Order__r.Type__c = 'RMA-Customer-Repair'];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c == null);
            system.assert(rcptline.Sales_Order__c == so.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'RMA Receipt For Repair');
            if(rcptline.Item__c == fuel.itemList[0].ID){
                system.assert(rcptline.Quantity_Received__c == 5, rcptline.Quantity_Received__c);
                system.assertEquals(0, rcptline.Quantity_Still_Due_For_Putaway__c, receiptlines);
            }
            else{
                system.assert(rcptline.Quantity_Received__c == 4, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 0, rcptline.Quantity_Still_Due_For_Putaway__c);
            } 
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'RMA Receipt For Repair', rcptline);            
        }
    
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c,Inventory_Change__c,Inventory_Change__r.Type__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        test.stopTest();
        system.assert(itlist.size() == 2, itlist);
        Set<Id> inventorychangeset = new Set<Id>();
        Boolean invflag, scrapflag;
        for(Inventory_Transaction__c it: itlist){

            if (it.Type__c == 'RMA Receipt For Repair') {
                invflag = true;
            }
            if(it.Type__c == 'RMA Scrap'){
                scrapflag = true;
            }
            
            inventorychangeset.add(it.Inventory_Change__c);
        }
    
        System.assertEquals(2,inventorychangeset.size(),itlist);
        system.assert(invflag ==true && scrapflag == true);
    }
    
    static testMethod void receiveRMALineswithSerialsOneStep(){    
        
        createSalesOrder(SalesOrderService.SO_TYPE_RMA);
    
        
        fuel.company.Serial_Control__c = 'At receipt and all processes';
        update fuel.company;
        
        fuel.itemList[0].item_attribute__c = fuel.itemAttrObj2.id;
        fuel.itemList[5].item_attribute__c = fuel.itemAttrObj2.id;
        update new list<Item__c>{fuel.itemList[0], fuel.itemList[5]};
        
        Facility__c facility1 = fuel.facility2;
        
        //Update Sales Order Type as RMA
        so.Status__c = 'Open';
        update so;
        
        soline.Status__c = 'Open';
        soline1.Status__c = 'Open';
        update soline;
        update soline1;
   
         Serial__c existingSerial = new Serial__c(
                            Name = 'Serial with space',
                            Company__c = fuel.company.Id
                        );
        
         insert existingSerial;
        
        ReceivingWorkBenchExt.setGridConfig('RMA', fuel.facility2.id);

        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Customer__c, Ship_From_Location__r.Facility__c, Currency__c  from Sales_Order__c where Id =:so.Id]; 
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
                                            from Sales_Order_Line__c where Sales_Order__c =:so.Id];
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
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(solineIds, 'RMA', fuel.currencyUSD.id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(solineIds), new set<String>{'Sales_Order_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){

             for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;

                    List<Serial__c> serialList = new List<Serial__c>();
                    Serial__c serwithspace = existingSerial.Clone(false,true);
                    serwithspace.Name = '   ' + serwithspace.Name;
                    serialList.Add(serwithspace);
                if(skid.Item__c == fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                    skid.Expiration_Date__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Scrap';
                    skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = fuel.uomObj;
                }
                else{
                    skid.Quantity__c = 4;
                    skid.Expiration_Date__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Inventory';
                    skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = fuel.uomObj;
                }
                    skid.Packaging_UOM__r.Package_Class__r = null;      
                    for (Integer i=0;i<(skid.Quantity__c-1);i++) {
                        Serial__c ser = new Serial__c(
                            Name = 'Serial ' + i);
                       
                        serialList.Add(ser);
                    }
                    sw.serialList = serialList;                 
                  
                }
        }
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
    
        List<Fulfillment__c> fulfillmentrecs = [Select Id, Status__c, Quantity__c, Sales_Order__c,Sales_Order_Line__c from Fulfillment__c where Sales_Order__c =:so.Id];
        
        system.assertEquals(2, fulfillmentrecs.size(), fulfillmentrecs);
        for(Fulfillment__c rec:fulfillmentrecs){
            if(rec.Sales_Order_Line__c == soline.Id)
                system.assert(rec.Quantity__c == -5, rec);
            else
                system.assert(rec.Quantity__c == -4, rec);
            
        }
                                        
        //Also check Quantity_Fulfilled__c on updated solines.  
        
        List<Sales_Order_Line__c> updatedsolinelist = [Select Id, Status__c, Quantity_Fulfilled__c from Sales_Order_Line__c where Sales_Order__c =:so.Id];
        
        
        for(Sales_Order_Line__c sol:updatedsolinelist){
            if(sol.Id == soline.Id)
                system.assert(sol.Quantity_Fulfilled__c == -5, sol);
            else
                system.assert(sol.Quantity_Fulfilled__c == -4, sol);
            
        }
                                    
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Status__c, Item__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Sales_Order__c =:so.Id and Sales_Order__r.Type__c = 'RMA-Credit'];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c == null);
            system.assert(rcptline.Sales_Order__c == so.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'RMA Receipt');
            if(rcptline.Item__c == fuel.itemList[0].ID){
                system.assert(rcptline.Quantity_Received__c == 5, rcptline.Quantity_Received__c);
                system.assertEquals(0, rcptline.Quantity_Still_Due_For_Putaway__c, receiptlines);
            }
            else{
                system.assert(rcptline.Quantity_Received__c == 4, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 0, rcptline.Quantity_Still_Due_For_Putaway__c);
            } 
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'RMA Receipt', rcptline);            
        }

                                                  
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Inventory_Change__c,Inventory_Change__r.Type__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, 
                                                To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c,
                                                (Select Id, Serial__c, Serial__r.Name, Serial__r.Allow_Reentry__c, Serial__r.SKID__c, Type__c From Serial_Transactions__r) 
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        test.stopTest();
        system.assert(itlist.size() == 2, itlist);
        Set<Id> inventorychangeset = new Set<Id>();
        Boolean invflag, scrapflag;
        for(Inventory_Transaction__c it: itlist){

            if (it.Type__c == 'RMA Receipt') {
                invflag = true;
                
            }
            if(it.Type__c == 'RMA Scrap'){
                scrapflag = true;
            }
            
            inventorychangeset.add(it.Inventory_Change__c);
            system.assertNotEquals(null, it.Serial_Transactions__r);
            Boolean serialSpaceFound = false;
            
            if( it.Item__c == fuel.itemList[0].Id ){
                system.assertEquals(5, it.Quantity__c);
                system.assertEquals(5, it.Serial_Transactions__r.size());
                system.assertEquals('RMA Scrap', it.Serial_Transactions__r[0].Type__c);

                for(Serial_Transaction__c st : it.Serial_Transactions__r){
                    if( st.Serial__r.Name == 'Serial with space'){
                        serialSpaceFound = true;
                    }
                }
                
                system.assertEquals(true, serialSpaceFound);
            }
            else{
                system.assertEquals(4, it.Quantity__c);
                system.assertEquals(4, it.Serial_Transactions__r.size());
                system.assertEquals('RMA Receipt', it.Serial_Transactions__r[0].Type__c);
                
                for(Serial_Transaction__c st : it.Serial_Transactions__r){
                    if( st.Serial__r.Name == 'Serial with space'){
                        serialSpaceFound = true;
                    }
                }
                
                system.assertEquals(true, serialSpaceFound);
            }
        }
    
        System.assertEquals(2,inventorychangeset.size(),itlist);
        system.assert(invflag ==true && scrapflag == true);
    }
    

    static testMethod void receiveRMARepairLineswithSerialsOneStep(){    
        
        createSalesOrder(SalesOrderService.SO_TYPE_RMA_REPAIR);
        test.startTest();
        DML.systemTime = system.now().addMinutes(-20);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{ Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,
            Sales_Order_Line__c.sObjectType,Item_Cost__c.sObjectType,SKID__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,
            Receiving_Document__c.sObjectType,Inventory_Change__c.sObjectType, Inventory_Transaction__c.sObjectType, Shipment__c.sObjectType,Customer__c.sObjectType, Shipment_Line__c.sObjectType,Product__c.sObjectType,Item__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        
        fuel.company.Serial_Control__c = 'At receipt and all processes';
        update fuel.company;
        
        fuel.itemList[0].item_attribute__c = fuel.itemAttrObj2.id;
        fuel.itemList[5].item_attribute__c = fuel.itemAttrObj2.id;
        update new list<Item__c>{fuel.itemList[0], fuel.itemList[5]};
        
        Facility__c facility1 = fuel.facility2;
        
        //Update Sales Order Type as RMA
        so.Status__c = 'Open';
        update so;
        
        soline.Status__c = 'Open';
        soline1.Status__c = 'Open';
        update soline;
        update soline1;
        
        ReceivingWorkBenchExt.setGridConfig('RMA', fuel.facility2.id);
       
        Sales_Order__c queriedSO = [Select Id,Name, Status__c, Currency__c, Customer__c, Ship_From_Location__r.Facility__c, currency__r.ISO_Code__c  from Sales_Order__c where Id =:so.Id];
        String docnum = queriedSO.Id;
        String facilityId = queriedSO.Ship_From_Location__r.Facility__c;
        String customerFilter = queriedSO.Customer__c;
        Id currencyfilter = queriedSO.Currency__c;
        JSONResult result = new JSONResult();
        JSONResult searchresult = new JSONResult();
        JSONResult searchresult1 = new JSONResult();
        JSONResult searchresult2 = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();
             
        
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('RMA');
        ReceivingWorkBenchExt.refreshTrackedAttr(fuel.Location, fuel.itemList[4], false);
        
        configMap = ReceivingWorkBenchExt.getGridConfig('RMA');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
        
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, facilityId, null, null, null, docnum, customerFilter, currencyfilter, null, null);
        system.debug('searchresult: ' + searchresult);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total >0, searchresult);
        
        //Manage Receive        
         
        List<Sales_Order_Line__c> newSOLinelist = [Select Id, Ship_From_Location__r.Facility__c, Quantity_Ordered__c, Sales_Order__r.Customer__c,
                Sales_Order__r.Currency__c, Sales_Order__r.Status__c, Sales_Order__r.Name,Sales_Order__r.Type__c, Product__r.Item__r.Name, Status__c
                from Sales_Order_Line__c where Sales_Order__c =:so.Id];
        system.assert(newSOLinelist.size() == 2, newSOLinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,facility1.Id,null,'RMA');
        List<Id> solineIds = new List<Id>();
        for(Sales_Order_Line__c line:newSOLinelist){
            if(facilityId ==null)
                facilityId = line.Ship_From_Location__r.Facility__c;
            system.assert(line.Status__c == 'Open', newSOLinelist);
            system.assert(line.Sales_Order__r.Customer__c == customerFilter, newSOLinelist);            
            system.assert(line.Sales_Order__c == docnum, newSOLinelist); 
            system.assert(line.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_RMA_REPAIR, newSOLinelist); 
            system.assert(line.Sales_Order__r.Status__c == 'Open', newSOLinelist); 
            solineIds.add(line.id);
        }
        
        getListresult = ReceivingWorkBenchExt.getList(solineIds, 'RMA');
        system.assert(getListresult.success == true, getListresult);
        system.assert(getListresult.total >0);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(solineIds, 'RMA',fuel.currencyUSD.id);

        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(solineIds), new set<String>{'Sales_Order_Line__c'.toLowerCase()} );
       
        for(ReceivingWrapper rw: rwrapperlist){

             for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                if(skid.Item__c == fuel.itemList[0].ID){
                    skid.Quantity__c = 5;
                    skid.Expiration_Date__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Scrap';
                    skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = fuel.uomObj;
                }
                else{
                    skid.Quantity__c = 4;
                    skid.Expiration_Date__c = system.today();
                    skid.Lot_Number__c = 'LOT 1';
                    rw.putawayType = 'Inventory';
                    skid.Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c;
                    skid.Packaging_UOM__r = fuel.uomObj;
                }
             	skid.Packaging_UOM__r.Package_Class__r = null;
                List<Serial__c> serialList = new List<Serial__c>();
                    for (Integer i=0;i<skid.Quantity__c;i++) {
                        Serial__c ser = new Serial__c(
                            Name = 'Serial ' + i,
                            Item__c = skid.Item__c,
                            Company__c = fuel.company.Id
                        );
                        ser.Unique_Key2__c = fuel.company.Id + '-' + ser.Item__c + '-' + ser.Name;
                        serialList.Add(ser);
                    }
                    sw.serialList = serialList;                 
                  
                }
        }
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        
        system.assert(receiveLinesresult.success == true, receiveLinesresult);
    
        List<Fulfillment__c> fulfillmentrecs = [Select Id, Status__c, Quantity__c, Sales_Order__c,Sales_Order_Line__c from Fulfillment__c where Sales_Order__c =:so.Id];
        
        system.assertEquals(2, fulfillmentrecs.size(), fulfillmentrecs);
        for(Fulfillment__c rec:fulfillmentrecs){
            if(rec.Sales_Order_Line__c == soline.Id)
                system.assert(rec.Quantity__c == -5, rec);
            else
                system.assert(rec.Quantity__c == -4, rec);
            
        }
                                        
        //Also check Quantity_Fulfilled__c on updated solines.  
        
        List<Sales_Order_Line__c> updatedsolinelist = [Select Id, Status__c, Quantity_Fulfilled__c from Sales_Order_Line__c where Sales_Order__c =:so.Id];
        
        
        for(Sales_Order_Line__c sol:updatedsolinelist){
            if(sol.Id == soline.Id)
                system.assert(sol.Quantity_Fulfilled__c == -5, sol);
            else
                system.assert(sol.Quantity_Fulfilled__c == -4, sol);
            
        }
                                    
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Status__c, Item__c, Quantity_Still_Due_For_Putaway__c, Quantity_To_Stock__c, Quantity_Received__c, 
                                              Sales_Order__c, Receiving_Document__r.Transaction_Type__c, Receiving_Document__r.Status__c,
                                              Receiving_Document__r.Finalized__c, Receiving_Document__r.Type__c from Receipt_Line__c where Sales_Order__c =:so.Id and Sales_Order__r.Type__c = 'RMA-Customer-Repair'];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Quantity_To_Stock__c == null);
            system.assert(rcptline.Sales_Order__c == so.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'RMA Receipt For Repair');
            if(rcptline.Item__c == fuel.itemList[0].ID){
                system.assert(rcptline.Quantity_Received__c == 5, rcptline.Quantity_Received__c);
                system.assertEquals(0, rcptline.Quantity_Still_Due_For_Putaway__c, receiptlines);
            }
            else{
                system.assert(rcptline.Quantity_Received__c == 4, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_Still_Due_For_Putaway__c == 0, rcptline.Quantity_Still_Due_For_Putaway__c);
            } 
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'RMA Receipt For Repair', rcptline);            
        }
                                                  
        List<Inventory_Transaction__c> itlist = [SELECT Id, Type__c, Quantity__c, Inventory_Change__c,Inventory_Change__r.Type__c, Subtransaction_Type__c, Finalized__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, 
                                                To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c,
                                                (Select Id, Serial__c, Serial__r.Allow_Reentry__c, Serial__r.SKID__c, Type__c From Serial_Transactions__r) 
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        
        test.stopTest();
        system.assert(itlist.size() == 2, itlist);
        Set<Id> inventorychangeset = new Set<Id>();
        Boolean invflag, scrapflag;
        for(Inventory_Transaction__c it: itlist){

            if (it.Type__c == 'RMA Receipt For Repair') {
                invflag = true;
                
            }
            if(it.Type__c == 'RMA Scrap'){
                scrapflag = true;
            }
            
            inventorychangeset.add(it.Inventory_Change__c);
            system.assertNotEquals(null, it.Serial_Transactions__r);
            
            if( it.Item__c == fuel.itemList[0].Id ){
                system.assertEquals(5, it.Quantity__c);
                system.assertEquals(5, it.Serial_Transactions__r.size());
                system.assertEquals('RMA Scrap', it.Serial_Transactions__r[0].Type__c);
            }
            else{
                system.assertEquals(4, it.Quantity__c);
                system.assertEquals(4, it.Serial_Transactions__r.size());
                system.assertEquals('RMA Receipt For Repair', it.Serial_Transactions__r[0].Type__c);
            }
        }
    
        System.assertEquals(2,inventorychangeset.size(),itlist);
        system.assert(invflag ==true && scrapflag == true);
    }

     
     
     public static void createSalesOrder(String sorderType){
        
        so.Company__c = fuel.company.id;
        so.Customer__c = fuel.customerSoldTo.id;   
        so.Ship_To__c = fuel.customerShipTo.Id;
        so.Bill_To__c = fuel.customerBillTo.Id;
        so.Payment_Term__c = fuel.terms.id;
        so.Currency__c = fuel.currencyUSD.id;
        so.Type__c = sorderType;
        insert so;
        
        List<Sales_Order_Line__c> salesOrderLines = new List<Sales_Order_Line__c>();
        
        soline.Company__c = fuel.company.Id;
        soline.Description__c = fuel.product.Description__c;
        soline.Discount_Percent__c = 2;
        soline.Product__c = fuel.product.Id;
        soline.Quantity_Ordered__c = -100;
        soline.Required_Date__c = System.today()+5;
        soline.Sales_Order__c = so.Id;
        soline.Sales_Order__r = so;
        soline.Ship_From_Location__c = fuel.location2.Id;
        soline.Unit_Price__c = 11.12;
        soline.Memo__c = 'soline';
        soline.Selling_UOM__c = fuel.uomList[8].id;
        salesOrderLines.add(soline);
        
        soline1.Company__c = fuel.company.id;
        soline1.Description__c = fuel.product2.Description__c;
        soline1.Discount_Percent__c = 2;
        soline1.Product__c = fuel.product2.Id;
        soline1.Quantity_Ordered__c = -15;
        soline1.Required_Date__c = System.today()+15;
        soline1.Sales_Order__c = so.Id;
        soline1.Sales_Order__r = so;
        soline1.Ship_From_Location__c = fuel.location2.Id;
        soline1.Unit_Price__c = 12.11;
        soline1.Sales_Tax__c = 14.686403;
        soline1.Memo__c = 'soline1';
        soline1.Selling_UOM__c = fuel.uomList[8].id;
        salesOrderLines.add(soline1);
        
        insert salesOrderLines;
     }

    private static testMethod void receivePOExistingSerial() {
        Purchase_Order__c po = fuel.purchaseOrder;
        Purchase_Order_Line__c poLine = fuel.purchaseOrderLines[0];

        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id, Serial_Number__c = true);

        Receiving_Document__c rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ poLine.Id }, 'Purchase Order', fuel.currencyUSD.Id).records[0];

        List<ReceivingWrapper> rWrappers = ReceivingDocumentServiceV2.getReceivingLines(null, new Set<Id>{ poLine.Id }, new Set<String>{ 'purchase_order_line__c' });
        rWrappers[0].serialWrapperList[0].skid.Quantity__c = 2;
        rWrappers[0].serialWrapperList[0].skid.Expiration_Date__c = System.today() + 365;
        rWrappers[0].serialWrapperList[0].skid.Lot_Number__c = 'LOTA';
        rWrappers[0].serialWrapperList[0].skid.Packaging_UOM__r.Package_Class__r = null;
        rWrappers[0].serialWrapperList[0].serialList = new List<Serial__c>{
            new Serial__c(Name = 'Serial1'),
            new Serial__c(Name = 'Serial2')
        };

        Serial__c serial = new Serial__c(
            Company__c = fuel.company.Id,
            Item__c = poLine.Item__c,
            Name = 'Serial1',
            Unique_Key2__c = fuel.company.Id + '-' + poLine.Item__c + '-Serial1',
            Allow_Reentry__c = true
        );
        insert serial;

        JsonResult result = ReceivingWorkBenchExt.receive(rWrappers, null, null, rd, null);
        System.assert(result.success == false, result);

        rd = (Receiving_Document__c)ReceivingWorkBenchExt.getrdDetails(new List<Id>{ poLine.Id }, 'Purchase Order', fuel.currencyUSD.Id).records[0];

        serial.Status__c = 'Voided';
        update serial;

        Test.startTest();
        rWrappers[0].rcl = rWrappers[0].rcl.clone(false,true);
        result = ReceivingWorkBenchExt.receive(rWrappers, null, null, rd, null);
        System.assert(result.success == true, result);

        Test.stopTest();

        serial = [SELECT Id,Status__c FROM Serial__c WHERE Id = :serial.Id];
        System.assert(serial.Status__c == null, serial);
    }
    static testMethod void receivePurchaseOrder_mixedPkgUOM(){    

       Purchase_Order__c po1 = new Purchase_Order__c(
                                                    Supplier__c = fuel.supplier.id, 
                                                    Company__c = fuel.company.id,
                                                    Payment_Term__c = fuel.terms.id,
                                                    Delivery_Facility__c = fuel.facility2.id,
                                                    Delivery_Location__c = fuel.location2.ID,
                                                    Remit_To_Supplier__c = fuel.remitToSupplier.id,
                                                    Approval_Status__c = 'Approved',
                                                    Status__c = 'Open',
                                                    Memo__c = 'purchaseOrder',
                                                    Currency__c = fuel.currencyUSD.id
                                        );
        insert po1;
        
        Purchase_Order_Line__c poLine1 = new Purchase_Order_Line__c();{
                poLine1.Purchase_Order__c = po1.Id;
                poLine1.Order_Quantity__c = 10;     
                poLine1.Unit_Price__c = 24;
                poLine1.Item__c = fuel.itemList[15].Id;
                poLine1.Description__c = fuel.itemList[15].Description__c;
                poLine1.Purchase_UOM__c = fuel.uomList[11].Id;
                poLine1.Company__c = fuel.company.id;
                poLine1.Need_Date__c = system.today() + 7;
                poLine1.Delivery_Facility__c = fuel.facility2.id;
                poLine1.Delivery_Location__c = fuel.location2.ID;
                poLine1.Supplier__c = fuel.supplier.Id;
                poLine1.Line__c = 1;
                insert poLine1; 
        }
        
        Purchase_Order_Line__c poLine2 = new Purchase_Order_Line__c();{
                poLine2.Purchase_Order__c = po1.Id;
                poLine2.Order_Quantity__c = 6;     
                poLine2.Unit_Price__c = 24;
                poLine2.Item__c = fuel.itemList[14].Id;
                poLine2.Description__c = fuel.itemList[14].Description__c;
                poLine2.Purchase_UOM__c = fuel.uomList[12].Id;
                poLine2.Company__c = fuel.company.id;
                poLine2.Need_Date__c = system.today() + 7;
                poLine2.Delivery_Facility__c = fuel.facility2.id;
                poLine2.Delivery_Location__c = fuel.location2.ID;
                poLine2.Supplier__c = fuel.supplier.Id;
                poLine2.Line__c = 2;
                insert poLine2; 
        }
        
        
        
        po1.Approval_Status__c = 'Approved';
        update po1;   
         
        fuel.itemList[15].item_attribute__c = null;
        update fuel.itemList[15];
        
        fuel.itemList[14].item_attribute__c = null;
        update fuel.itemList[14];
        
        test.startTest();
        ReceivingWorkBenchExt.setGridConfig('Purchase Order', fuel.facility2.id);
        
        //Create PO    
       
       // List<Purchase_Order_Line__c> queriedPOL = [Select Id,Name, Purchase_Order__r.Delivery_Facility__c, Status__c, Purchase_Order__r.FOB_Term__c from Purchase_Order_Line__c where Id =:poline.Id]; 
        String docnum = po1.Id;
        String facilityId = po1.Delivery_Facility__c;
        String supplierId = po1.Supplier__c;
        
       
        JSONResult searchresult = new JSONResult();
        JSONResult getListresult = new JSONResult();
        JSONResult receiveLinesresult = new JSONResult();
        JSONResult rdocresult = new JSONResult();         
                                       
       
        //Now Search for this POLines on Receiving Workbench Page
        //ReceivingWorkBenchExt receiveExt = new ReceivingWorkBenchExt();
        ReceivingWorkBenchExt recon = new ReceivingWorkBenchExt();
        Map<String,String> configMap = new Map<String,String>();
        
        String headerfieldlist = ReceivingWorkBenchExt.getrdHeaderFieldList('Purchase Order');
        
        configMap = ReceivingWorkBenchExt.getGridConfig('Purchase Order');
        
        String receivingLinesConfigJson = configMap.get('config');
        String receivingLinesFieldListJson = configMap.get('fieldList');
                
       
        List<Id> polineIds = new List<Id>();
        
        List<Purchase_Order_Line__c> polinelist = [Select Id, Name, Purchase_Order__r.Name, Purchase_Order__r.Approval_Status__c, delivery_facility__c, Purchase_Order__c, Purchase_Order__r.FOB_Term__r.FOB_Point__c, Status__c, Company__c, Supplier__c 
                                            from Purchase_Order_Line__c where Purchase_Order__c =:po1.Id];
        system.assert(polinelist.size() == 2, polinelist);
        ReceivingWorkBenchExt.getCurrencyCode(null,null,polinelist[0].Purchase_Order__r.Name,'Purchase Order');
        for(Purchase_Order_Line__c line:polinelist){
            system.assert(line.Status__c == 'Open', polinelist);
            system.assert(line.delivery_facility__c == facilityId, polinelist);
            system.assert(line.Supplier__c == supplierId, polinelist);          
            system.assert(line.Purchase_Order__r.Approval_Status__c == 'Approved', line.Purchase_Order__r.Approval_Status__c); 
            polineIds.add(line.id);
        }
       
        searchresult = ReceivingWorkBenchExt.getLinesToReceive(receivingLinesConfigJson, null, null, null, null, docnum, null, null, null, null);
        system.assertEquals(searchresult.success, true);
        system.assert(searchresult.total ==2, searchresult);
        
        //Manage Receive        
         
        getListresult = ReceivingWorkBenchExt.getList(polineIds, 'Purchase Order');
        system.assert(getListresult.success == true, getListresult.message);
        system.assert(getListresult.total==2);
        
        //Create RD with some info and Receive
        rdocresult = ReceivingWorkBenchExt.getrdDetails(polineIds, 'Purchase Order',fuel.currencyUSD.id);
        
        list<ReceivingWrapper> rwrapperlist = new list<ReceivingWrapper>();
        rwrapperlist = ReceivingDocumentServiceV2.getReceivingLines( null, new Set<Id>(polineIds), new set<String>{'Purchase_Order_Line__c'.toLowerCase()} );
        
        system.assert(rwrapperlist.size()==2,rwrapperlist.size());
        
        Receiving_Document__c rdoc = (Receiving_Document__c)rdocresult.records[0];
        system.assert(rdocresult.records.size() == 1, rdocresult);
      
        for(ReceivingWrapper rw: rwrapperlist){
            for( SkidService3.serialWrapper sw : rw.serialWrapperList){
                SKID__c skid = sw.skid;
                
                if(skid.Item__c == fuel.itemList[15].Id){
                    skid.Quantity__c = 10;
                    //sw.skid.Packaging_UOM__r.Package_Class__r = null;  
                }
                else if(skid.Item__c == fuel.itemList[14].Id){
                	system.assert(skid.packaging_UOM__c == fuel.uomList[12].Id);
                	//sw.skid.Packaging_UOM__r.Package_Class__r = fuel.packageClassList[1];  
                    skid.Quantity__c = 6;
                }          
                   
            }
        }
        
        
        receiveLinesresult = ReceivingWorkBenchExt.receive(rwrapperlist, null, null, rdoc, null);
        
        
        system.assert(receiveLinesresult.success == true, rwrapperlist.size());
        
        List<Purchase_Order_Line__c> updatedpolines = [Select Id, Status__c, Quantity_Still_Due__c, Quantity_Received__c from Purchase_Order_Line__c where Purchase_Order__c =:po1.Id];
        
        for(Purchase_Order_Line__c line:updatedpolines){            
            system.assert(line.Status__c == 'Closed', line);
            system.assert(line.Quantity_Still_Due__c == 0, line.Quantity_Still_Due__c);         
        }                                   
                                            
        Set<ID> receiptlineSet = new Set<ID>();
        List<Receipt_Line__c> receiptlines = [Select Id, Quantity_To_Stock__c, Quantity_Received__c, Status__c, Purchase_Order_Line__c, Purchase_Order__c, ASN_Line__c, Receiving_Document__r.Transaction_Type__c, 
                                                Receiving_Document__r.Finalized__c, Receiving_Document__r.Status__c, Receiving_Document__r.Type__c from Receipt_Line__c where Receipt_Line__c.Receiving_Document__c =: rdoc.Id];
        system.assert(receiptlines.size() == 2, receiptlines);
        for(Receipt_Line__c rcptline: receiptlines){
            receiptlineSet.add(rcptline.Id);
            system.assert(rcptline.Purchase_Order__c == po1.Id);
            system.assert(rcptline.Status__c == 'Closed', rcptline.Status__c);
            system.assert(rcptline.Receiving_Document__r.Status__c == 'Closed');
            system.assert(rcptline.Receiving_Document__r.Finalized__c == true);
            system.assert(rcptline.Receiving_Document__r.Type__c == 'Purchase Order Receipt');
            if(rcptline.Purchase_Order_Line__c == poline1.Id){
                system.assert(rcptline.Quantity_Received__c == 10, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_To_Stock__c == 10, rcptline.Quantity_To_Stock__c);//EA
            }
            else if(rcptline.Purchase_Order_Line__c == poline2.Id){
                system.assert(rcptline.Quantity_Received__c == 6, rcptline.Quantity_Received__c);
                system.assert(rcptline.Quantity_To_Stock__c == 12, rcptline.Quantity_To_Stock__c);//CS
            }
            
            system.assert(rcptline.Receiving_Document__r.Transaction_Type__c == 'Purchase Order Receipt', rcptline);
            
        }
               
        List<Inventory_Transaction__c> itlist = [SELECT Id,Type__c, Quantity__c,Quantity_Stocking_UOM__c,Subtransaction_Type__c, Finalized__c, Purchase_Order_Line__c, Item__c, Receipt_Line__c, From_SKID__c, From_SKID__r.Name, From_SKID__r.Location__c, From_Lot__c, From_Lot__r.Name, To_SKID__r.Lot__r.Name, To_SKID__c, To_SKID__r.Name, To_SKID__r.Location__c
                                                  FROM Inventory_Transaction__c where Receipt_Line__c IN :receiptlineSet];
        test.stopTest();
        system.assert(itlist.size() == 2, itlist);  
        Boolean lineReceived1 =false;
        Boolean lineReceived2=false;
        for(Inventory_Transaction__c it: itlist){
            system.assert(it.Subtransaction_Type__c == 'Purchase Order Receipt');
	        system.assert(it.Type__c == 'Purchase Order Receipt');
	        system.assert(it.Receipt_Line__c !=null);   
            if(it.Item__c == fuel.itemList[14].Id){
                system.assert(it.Quantity__c == 6, itList);
            	system.assert(it.Quantity_Stocking_UOM__c == 12,it);
            	lineReceived1 = true;
            }
            else if(it.Item__c == fuel.itemList[15].Id){
            	system.assert(it.Quantity__c == 10, itList);
            	system.assert(it.Quantity_Stocking_UOM__c == 10,it);
	            lineReceived2 = true;
            }
        }
        system.assert(lineReceived1 ==true,lineReceived2);
        system.assert(lineReceived2 ==true,lineReceived1);
    }
}