@isTest
public with sharing class SalesOrderConfirmPickTest {

    static testMethod void testConfirmPick() { //happy scenario
        
        TestData globalTestData = new TestData();
        ApexPages.Standardcontroller con;
        Test.startTest();
        con = new ApexPages.Standardcontroller(globalTestData.salesOrder);
        
        List<SKID__c> stockSkids = fillStock(globalTestData);

        SOPlanExt SOPExt = new SOPlanExt(con);
        SOPExt.plan();
        //System.assertEquals(false, SOPExt.selecterror);
        System.assertEquals(false, SOPExt.hasErrors); 
        
        globalTestData.salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c from Sales_Order__c where id = :globalTestData.salesOrder.Id limit 1];
        
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);
        
        system.assert( SOAExt.solWrapperList.size() == 2 );
        
        for( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ){
            
            system.assert( sw.skidList.size() == 1); // number of available location skids
            sw.skidList[0].Quantity_Allocated__c  = 15;
        }
        
        SOAExt.allocate();
        
        con = new ApexPages.Standardcontroller(globalTestData.salesOrder);
        
        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        
        List<Skid__c> allocatedSkids = new List<Skid__c>();
        
        
        for(Sales_Order_Line__c sol : socpExt.soLineList){
                
                allocatedSkids.addAll( sol.SKIDs__r);
        }
        system.assert(allocatedSkids.size()>0,allocatedSkids.size());
        for(Skid__c sk : allocatedSkids){
                
                system.assert(sk.Sales_Order_Line__r.Ship_From_Location__c!=null,sk.Sales_Order_Line__r.Ship_From_Location__c);
        }
        
        socpExt.confirmPick();
        
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Error) == false );
        system.assert( ApexPages.hasMessages(ApexPages.Severity.Warning) == false );
    
        Map<Id, Sales_Order_Line__c> soLineMap = new Map<Id, Sales_Order_Line__c>(socpExt.soLineList);

        list<Inventory_Transaction__c> itList =[Select Id,Inventory_Change__c, Quantity__c, Type__c from Inventory_Transaction__c where Sales_Order_Line__c IN :soLineMap.keySet()];
        system.assert( itList.size() == 2, itList );
        
        for( Inventory_Transaction__c it : itList ){
            
            system.assert( it.Quantity__c == 15 );
            system.assert( it.Type__c == 'Sales Order Pick');
            system.assert( it.Inventory_Change__c != null);
        }
        
        List<Shipment_Line__c> shlList = [select Id, Quantity_Shipped__c, Sales_Order__c,Sales_Order_Line__r.Product__c, Product__c,
                                            Sales_Order_Line__r.Ship_From_Location__c, Location__c, Shipment__c, Shipment__r.Status__c
                                            From Shipment_Line__c 
                                            where Sales_Order_Line__r.Sales_Order__c = :globalTestData.salesOrder.Id];
                                            
        system.assert( shlList.size() == 2 );
        system.assert( shlList[0].Shipment__r.Status__c == 'Staged');
        system.assert( shlList[0].Quantity_Shipped__c == 0);
        system.assert( shlList[1].Quantity_Shipped__c == 0);                                    
        
        Test.stopTest();
    }
    
    static testMethod void testConfirmPickShipFromStock() { //PTM-431
        TestFuel fuel = new TestFuel();
        List<Period__c> periodList = fuel.periodList;
        
        Sales_Order__c salesOrder = fuel.salesOrder;
        
        List<SKID__c> skids = fuel.skids;    
        List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
        
        list<SKID__c> skidList = [ select id, quantity__c, item__c from SKID__c where Item__c =:fuel.itemList[0].id 
                                    and Location__c =:fuel.location3.id and type__c=:skidService2.SKID_TYPE_LOCATION];
                                    
        system.assertEquals(skidList.size() ,  1);
        system.assertEquals(skidList[0].Quantity__c ,  200);
        
        for(Sales_Order_Line__c sol : fuel.salesOrderLines ){
            sol.Ship_From_Location__c = fuel.location3.id; // same as pick from location on stock movement rule
        }
        
        update fuel.salesOrderLines;
        
        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SOPlanExt soPlanExt = new SOPlanExt(con);
        soPlanExt.plan();
        System.assertEquals(false, soPlanExt.hasErrors);
        
        salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c, Customer__r.top_parent_customer__c,order_total__c from Sales_Order__c where id = :salesOrder.Id limit 1];
        
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);
        
        system.assert( SOAExt.solWrapperList.size() == 2 );
        
        for( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ){
            
            system.assert( sw.skidList.size() == 1); // number of available location skids
            
            sw.skidList[0].Quantity_Allocated__c  = sw.sol.Quantity_Ordered__c;
        }
        
        SOAExt.allocate();
        
        Test.startTest();
 
        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        
        socpExt.confirmPick();
        
        Test.stopTest();   
        
        skidList = [ select id, quantity__c, item__c from SKID__c where Item__c =:fuel.itemList[0].id 
                                    and Location__c =:fuel.location3.id and type__c=:skidService2.SKID_TYPE_LOCATION];
                                    
        system.assertEquals(skidList.size() ,  1);
        system.assertEquals(skidList[0].Quantity__c ,  200);
    }
    
    public static testMethod void testErrors(){ //all the negative scenarios
        
        TestData globalTestData = new TestData();
        ApexPages.Standardcontroller con;
        Test.startTest();
        con = new ApexPages.Standardcontroller(globalTestData.salesOrder);
        ExceptionService exServ = new ExceptionService();
        
        List<SKID__c> stockSkids = fillStock(globalTestData);
        
        SOPlanExt SOPExt = new SOPlanExt(con);
        SOPExt.plan();
        
        List<Shipment_Line__c> shlList = [select Id, Quantity_Shipped__c, Sales_Order__c,Sales_Order_Line__r.Product__c, Product__c,
                                            Sales_Order_Line__r.Ship_From_Location__c, Location__c
                                            From Shipment_Line__c 
                                            where Sales_Order_Line__r.Sales_Order__c = :globalTestData.salesOrder.Id];
        System.assertNotEquals(0, shlList.size());
                                                
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        for( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ){
            //KNDY-4989
            system.assertEquals(1, sw.skidList.size(), 'sw.skidList: '+ sw.skidList + ' *** sw: ' + sw); // number of available location skids
            sw.skidList[0].Quantity_Allocated__c  = 15;
        }
        
        SOAExt.allocate();
  
        SalesOrderConfirmPickExt socpExt; // = new SalesOrderConfirmPickExt(con);
        
        socpExt = new SalesOrderConfirmPickExt(new ApexPages.StandardController(new Sales_Order__c()));
        //KNDY-4989
        System.assert(socpExt.disableConfirmPick == true, '(disableConfirmPick 1) socpExt: '+ socpExt);
        System.assert(socpExt.disableUnallocate == true, '(disableUnallocate 1) socpExt: '+ socpExt);
        
        globalTestData.salesOrder.Status__c = SalesOrderService.SO_STATUS_DRAFT;
        update globalTestData.salesOrder;
        
        con = new ApexPages.Standardcontroller(globalTestData.salesOrder);
        socpExt = new SalesOrderConfirmPickExt(con);
        
        globalTestData.salesOrder.Status__c = 'Open';
        update globalTestData.salesOrder;
        
        for(Sales_Order_Line__c sol : globalTestData.salesOrder.Sales_Order_Lines__r){
            exServ.setException(sol, ExceptionUtil.PRODUCT_IS_BLOCKED);
        }
        exServ.finish();
        
        con = new ApexPages.Standardcontroller(globalTestData.salesOrder);
        socpExt = new SalesOrderConfirmPickExt(con);
        
        //KNDY-4989
        System.assert(socpExt.disableConfirmPick == true, '(disableConfirmPick 2) socpExt: '+ socpExt);
        System.assert(socpExt.disableUnallocate == true, '(disableUnallocate 2) socpExt: '+ socpExt);
        
        for(Sales_Order_Line__c sol : globalTestData.salesOrder.Sales_Order_Lines__r){
            exServ.clearException(sol, ExceptionUtil.PRODUCT_IS_BLOCKED);
        }
        exServ.finish();
        
        // Check if confirm pick throws error if there is no quantity in the actual skid. 
        // (Quantity might have been removed from the skid after allocation.)
        
        for(SKID__c skid : stockSkids){
            skid.Quantity__c = 0;
        }
        update stockSkids;
        
        con = new ApexPages.Standardcontroller(globalTestData.salesOrder);
        socpExt = new SalesOrderConfirmPickExt(con);
        
        socpExt.confirmPick();

        //did not generate any inventory transactions as confirm pick did not complete.
        Map<Id, Sales_Order_Line__c> soLineMap = new Map<Id, Sales_Order_Line__c>(socpExt.soLineList);
        list<Inventory_Transaction__c> itList =[Select Id, Finalized__c from Inventory_Transaction__c where Sales_Order_Line__c IN :soLineMap.keySet()];

        //KNDY-4989
        System.assertEquals(0, itList.size(), 'itList: '+ itList + ' *** soLineMap.keySet()' + soLineMap.keySet());
        
        for(SKID__c skid : stockSkids){
            skid.Quantity__c = 200;
        }
        update stockSkids;
        
        globalTestData.salesOrder = [select Id, Customer__r.Top_Parent_Customer__r.Credit_Hold__c, 
                                    Override_Credit_Hold__c, Status__c 
                                    from Sales_Order__c 
                                    where Id = :globalTestData.salesOrder.Id];
        
        globalTestData.salesOrder.Customer__r.Top_Parent_Customer__r.Credit_Hold__c = true; //KNDy-2114
        update globalTestData.salesOrder.Customer__r.Top_Parent_Customer__r;
        
        con = new ApexPages.Standardcontroller(globalTestData.salesOrder);
        // Allocate quantity to the sales order.
        socpExt = new SalesOrderConfirmPickExt(con);
                                        
        // Test that 'Unallocate' and 'Confirm Pick' are disabled.
        system.assertNotEquals(true, socpExt.disableConfirmPick, ApexPages.getMessages());
        system.assertNotEquals(true, socpExt.disableUnallocate);
        
        globalTestData.salesOrder.Override_Credit_Hold__c = true;
        update globalTestData.salesOrder;
        
        socpExt = new SalesOrderConfirmPickExt(con);
        
        system.assertNotEquals(null, socpExt.soLineList);
                                        
        //KNDY-4989
        system.assertNotEquals(0, socpExt.soLineList.size(), 'No available sales order lines for confirm pick.');
                                        
        // Test that 'Unallocate' and 'Confirm Pick' are enabled.
        system.assertNotEquals(true, socpExt.disableConfirmPick);
        system.assertNotEquals(true, socpExt.disableUnallocate);
        
        Test.stopTest();
        socpExt.last();
        socpExt.previous();
        socpExt.next();
    }
    
     public static testMethod void testonhold(){
    
        TestData globalTestData = new TestData();
        test.startTest();
        ApexPages.Standardcontroller con;
        globalTestData.salesOrder.Hold__c = true;
        update globalTestData.salesOrder;

        con = new ApexPages.Standardcontroller(globalTestData.salesOrder);
        SalesOrderConfirmPickExt SOCpExt = new SalesOrderConfirmPickExt(con);

        System.assertEquals(true, SOCpExt.disableConfirmPick);
        System.assertEquals(true, SOCpExt.disableUnallocate);
        
        Test.stopTest();
    }
    
    static testMethod void testUnallocate() { 
        
        TestData globalTestData = new TestData();
        ApexPages.Standardcontroller con;
        Test.startTest();
        con = new ApexPages.Standardcontroller(globalTestData.salesOrder);
        
        List<SKID__c> stockSkids = fillStock(globalTestData);

        SOPlanExt SOPExt = new SOPlanExt(con);
        SOPExt.plan();
        //System.assertEquals(false, SOPExt.selecterror);
        System.assertEquals(false, SOPExt.hasErrors);
        globalTestData.salesOrder = [select Id, Company__c, Customer__c, Name, Status__c, Ship_To__c, Currency__c from Sales_Order__c where id = :globalTestData.salesOrder.Id limit 1];
        
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        system.assertEquals(false, SOAExt.hideSave);
        
        system.assert( SOAExt.solWrapperList.size() == 2 );
        
        for( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ){
            
            system.assert( sw.skidList.size() == 1); // number of available location skids
            sw.skidList[0].Quantity_Allocated__c  = 15;
        }
        
        SOAExt.allocate();
        
        Set<Id> allocatedLines = new Set<Id>();

        con = new ApexPages.Standardcontroller(globalTestData.salesOrder);
        
        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        
        for( Sales_Order_Line__c sol : socpExt.soLineList ){
            
            allocatedLines.add( sol.SKIDs__r[0].id ); //as there is only one allocated skid per so line here
        }
        
        String selectedLines='';
        
        System.assertEquals(null, socpExt.unallocate()); //no selected lines to unallocate
        
        ApexPages.currentPage().getParameters().put('selectedIndexes', selectedLines);
        System.assertEquals(null, socpExt.unallocate()); //no selected lines to unallocate
        
        for(Id selectedId : allocatedLines){
            selectedLines += selectedId + ',';
        }
        ApexPages.currentPage().getParameters().put('selectedIndexes', selectedLines);
        System.assertNotEquals(null, socpExt.unallocate()); //unallocating the selected lines

        Map<Id, Sales_Order_Line__c> soLineMap = new Map<Id, Sales_Order_Line__c>(socpExt.soLineList);

        list<SKID__c> demandSkidList = [select id, Quantity__c, Sales_Order_Line__r.Quantity_Ordered__c,Sales_Order_Line__r.Quantity_Backordered__c from Skid__c where type__c=:SkidService2.SKID_TYPE_SO_DEMAND and Sales_Order_Line__c IN :soLineMap.keySet()];
        list<SKID__c> allocatedSkidList = [select id, Quantity__c from Skid__c where type__c=:SkidService2.SKID_TYPE_ALLOCATED and Sales_Order_Line__c IN:soLineMap.keySet()];
        
        system.assert( demandSkidList.size() == 2 );
        system.assert( allocatedSkidList.size() == 0 ); //allocated skids should be deleted as we unallocated everything
        
        for( SKID__c ds : demandSkidList ){
            system.assertEquals( ds.Sales_Order_Line__r.Quantity_Ordered__c, ds.Quantity__c, 'Demand skids should be back to the original quantity');
            system.assertEquals( ds.Sales_Order_Line__r.Quantity_Ordered__c, ds.Sales_Order_Line__r.Quantity_Backordered__c);
        }
        

        List<Shipment_Line__c> shipLines = [SELECT Id, Shipment__c, Shipment__r.Status__c FROM Shipment_Line__c 
                                            WHERE Sales_Order__c =: globalTestData.salesOrder.Id];
        
        system.assertEquals(shipLines[0].Shipment__r.Status__c, 'Planned');

        Test.stopTest();
    }
    
    public static List<SKID__c> fillStock(TestData testData){
        
        List<SKID__c> availableSkids = new List<SKID__c>();
        for (Item__c item : testData.itemList) {
            SKID__c skid = new SKID__c();
            skid.location__c = testData.location3.id;
            skid.Quantity__c = 200.0;
            skid.Item__c= item.Id;
            skid.Type__c = SKIDService.SKID_TYPE_LOCATION;
            skid.Expiration_Date__c = System.today() + 365;
            skid.Company__c = testData.company.Id;
            
            availableSkids.add(skid);
        }
        insert availableSkids;
        
        return availableSkids;
    }
    private static testMethod void testConsigned() {
        TestFuel fuel = new TestFuel();
        Source_Document_Approval__c sd = new Source_Document_Approval__c();{
            sd.Name = 'Purchase Order';
            sd.Allow_Approval__c = true;
            insert sd;
        }
        insert new Item_Cross_Reference__c(
            Supplier__c = fuel.supplier.Id,
            Ship_to_Facility__c = fuel.facility2.Id,
            Cross_Reference_Type__c = 'Supplier',
            Item__c = fuel.itemList[0].Id,
            Name = 'ICR Consigned' + fuel.itemList[0].Id,
            Active__c = true,
            Consigned__c = true
        );
        List<Stock_Movement_Rule_Settings__c> smrs = fuel.smrsList;
        List<Stock_Movement_Rule__c> smr = fuel.stockMovementRuleList;
        List<Period__c> periodList = fuel.periodList;
        //Creating different POs and SOs in order to avoid query limits
        Purchase_Order__c po = new Purchase_Order__c(
            Supplier__c = fuel.supplier.Id,
            Company__c = fuel.company.Id,
            Payment_Term__c = fuel.terms.Id,
            Delivery_Facility__c = fuel.facility2.Id,
            Delivery_Location__c = fuel.location2.Id,
            Remit_To_Supplier__c = fuel.remitToSupplier.Id,
            Approval_Status__c = 'Approved',
            FOB_Term__c = fuel.fobTerm.Id,
            Status__c = 'Open',
            Memo__c = 'purchaseOrder',
            Currency__c = TestFuel.currencyUSD.id
        );
        insert po;
        insert new Purchase_Order_Line__c(
            Purchase_Order__c = po.Id,
            Order_Quantity__c = 1000,
            Unit_Price__c = 12,
            Item__c = fuel.itemList[0].Id,
            Description__c = fuel.itemList[0].Description__c,
            Purchase_UOM__c = fuel.itemList[0].Purchasing_UOM__c,
            Company__c = fuel.company.Id,
            Need_Date__c = System.today() + 7,
            Delivery_Facility__c = fuel.facility2.Id,
            Delivery_Location__c = fuel.location2.Id,
            Supplier__c = fuel.supplier.Id,
            Line__c = 1
        );
        update new Purchase_Order__c(Id = po.Id, Approval_Status__c = 'Approved');
        Sales_Order__c so = new Sales_Order__c(
            Company__c = fuel.company.Id,
            Customer__c = fuel.customerSoldTo.Id,
            Ship_To__c = fuel.customerShipTo.Id,
            Bill_To__c = fuel.customerBillTo.Id,
            Currency__c = TestFuel.currencyUSD.id,
            Original_Sales_Order__c = 'so123',
            Payment_Term__c = fuel.terms.Id
        );
        insert so;
        insert new Sales_Order_Line__c(
            Company__c = fuel.company.Id,
            Description__c = fuel.product.Description__c,
            Discount_Percent__c = 2,
            Product__c = fuel.product.Id,
            Quantity_Ordered__c = 100,
            Required_Date__c = System.today() + 5,
            Sales_Order__c = so.Id,
            Ship_From_Location__c = fuel.location3.Id,
            Unit_Price__c = 11.12,
            Memo__c = 'salesOrderLine'
        );
        
        List<ReceivingWrapper> polWrappers = (List<ReceivingWrapper>)PurchaseOrderReceiveExtV2.getList(po.Id).records;
        polWrappers[0].serialWrapperList[0].skid.Quantity__c = 1000;
        polWrappers[0].serialWrapperList[0].skid.Lot_Number__c = 'A';
        polWrappers[0].serialWrapperList[0].skid.Expiration_Date__c = System.today() + 365;
        Test.startTest();
        PurchaseOrderReceiveExtV2.receivePurchaseOrders(polWrappers);

        ApexPages.StandardController con = new ApexPages.StandardController(so);
        SOPlanExt planExt = new SOPlanExt(con);
        planExt.plan();
        SalesOrderAllocateExt allocateExt = new SalesOrderAllocateExt(con);
        allocateExt.allocate();
        SalesOrderConfirmPickExt pickExt = new SalesOrderConfirmPickExt(con);
        pickExt.confirmPick();
        Test.stopTest();
        
        List<Inventory_Transaction__c> itList = [SELECT Id,Type__c,From_SKID__c,To_SKID__c FROM Inventory_Transaction__c WHERE Sales_Order_Line__r.Sales_Order__c = :so.Id];
        System.assert(itList.size() == 2,itList);
        for (Inventory_Transaction__c it:itList )
            System.assert((it.Type__c == 'Sales Order Pick' || it.Type__c == 'Transfer Of Ownership') && it.From_SKID__c != it.To_SKID__c,it);
    }
}