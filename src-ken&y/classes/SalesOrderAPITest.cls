@isTest
public class SalesOrderAPITest {
    private static testMethod void testReleaseSuccess() {
        SalesOrderTestData.CreateSoData = false;
        SalesOrderTestData data = new SalesOrderTestData();
        FacilityAndLocations locs = new FacilityAndLocations(data.company.Id);
        data.company.Default_Sales_Order_Ship_From_Facility__c = locs.facility.Id;
        update data.company;
        TestFuel tf = new TestFuel();
        List<Stock_Movement_Rule_Settings__c> smrsList = tf.smrsList; 
        StockMovement mov = new StockMovement(data.company.Id,locs.facility.Id,locs.stock.Id);
        InventoryData inv = new InventoryData(data.company.Id,locs.stock.Id,data.itemList,false);
        Sales_Order__c so = new Sales_Order__c();
        so.Company__c = data.company.Id;
        so.Customer__c = data.customer.Id;
        so.Ship_To__c = data.customerShipTo.Id;
        so.Bill_To__c = data.customerBillTo.Id;
        so.Payment_Term__c = data.terms.Id;
        so.Currency__c = TestFuel.currencyUSD.id;
        insert so;
        Sales_Order_Line__c soLine = new Sales_Order_Line__c();
        soLine.Product__c = data.product.Id;
        soLine.Description__c = data.product.Description__c;
        soLine.Company__c = data.company.Id;
        soLine.Sales_Order__c = so.Id;
        soLine.Quantity_Ordered__c = 1;
        soLine.Required_Date__c = System.today()+5;
        soLine.Discount_Percent__c = 2;
        soLine.Ship_From_Location__c = locs.shippingDock.Id;
        insert soLine;
        Map<Id,SalesOrderAPI.SalesOrderWrapper> soMap = new Map<Id,SalesOrderAPI.SalesOrderWrapper>();
        SalesOrderAPI.SalesOrderWrapper soWrapper = new SalesOrderAPI.SalesOrderWrapper(so.Id);
        soMap.put(soWrapper.salesOrderId,soWrapper);

        Test.startTest();
        Map<Id,SalesOrderAPI.SalesOrderAPIStatus> statuses = SalesOrderAPI.release(soMap);
        Test.stopTest();

        for (SalesOrderAPI.SalesOrderAPIStatus status:statuses.values())
            System.assert(status.success,'Plan should succeed');
        System.assert([SELECT Id FROM Sales_Order__c WHERE Status__c = 'Open'].size() == 1,'sales order should be released/open');
        System.assert([SELECT Id FROM SKID__c WHERE Type__c=:SkidService2.SKID_TYPE_SO_DEMAND].size() == 1,'should have one demand SKID');
    }
    
    private static testMethod void testReleaseFail() {
        SalesOrderTestData.CreateSoData = false;
        SalesOrderTestData data = new SalesOrderTestData();
        FacilityAndLocations locs = new FacilityAndLocations(data.company.Id);
        data.company.Default_Sales_Order_Ship_From_Facility__c = locs.facility.Id;
        update data.company;
        TestFuel tf = new TestFuel();
        List<Stock_Movement_Rule_Settings__c> smrsList = tf.smrsList; 
        StockMovement mov = new StockMovement(data.company.Id,locs.facility.Id,locs.stock.Id);
        InventoryData inv = new InventoryData(data.company.Id,locs.stock.Id,data.itemList,false);
        Sales_Order__c so = new Sales_Order__c();
        so.Company__c = data.company.Id;
        so.Customer__c = data.customer.Id;
        so.Ship_To__c = data.customerShipTo.Id;
        so.Bill_To__c = data.customerBillTo.Id;
        so.Payment_Term__c = data.terms.Id;
        so.Currency__c = TestFuel.currencyUSD.id;
        insert so;
        Sales_Order_Line__c soLine = new Sales_Order_Line__c();
        soLine.Product__c = data.product.Id;
        soLine.Description__c = data.product.Description__c;
        soLine.Company__c = data.company.Id;
        soLine.Sales_Order__c = so.Id;
        soLine.Quantity_Ordered__c = 1;
        soLine.Required_Date__c = System.today()+5;
        soLine.Discount_Percent__c = 2;
        insert soLine;
        Map<Id,SalesOrderAPI.SalesOrderWrapper> soMap = new Map<Id,SalesOrderAPI.SalesOrderWrapper>();
        SalesOrderAPI.SalesOrderWrapper soWrapper = new SalesOrderAPI.SalesOrderWrapper(so.Id);
        soMap.put(soWrapper.salesOrderId,soWrapper);

        Test.startTest();
        Map<Id,SalesOrderAPI.SalesOrderAPIStatus> statuses = SalesOrderAPI.release(soMap);
        Test.stopTest();

        for (SalesOrderAPI.SalesOrderAPIStatus status:statuses.values())
            System.assert(!status.success,'Plan should fail');
        System.assert([SELECT Id FROM Sales_Order__c WHERE Status__c = 'Open'].size() == 0,'sales orders should not be released (missing ship from location)');
        System.assert([SELECT Id FROM SKID__c WHERE Type__c=:SkidService2.SKID_TYPE_SO_DEMAND].size() == 0,'should have any demand skids');
    }
    
    private static testMethod void testCloseSuccess() {
        SalesOrderTestData.CreateSoData = false;
        SalesOrderTestData data = new SalesOrderTestData();
        FacilityAndLocations locs = new FacilityAndLocations(data.company.Id);
        data.company.Default_Sales_Order_Ship_From_Facility__c = locs.facility.Id;
        update data.company;
        Sales_Order__c so = new Sales_Order__c();
        so.Company__c = data.company.Id;
        so.Customer__c = data.customer.Id;
        so.Ship_To__c = data.customerShipTo.Id;
        so.Bill_To__c = data.customerBillTo.Id;
        so.Payment_Term__c = data.terms.Id;
        so.Currency__c = TestFuel.currencyUSD.id;
        insert so;
        Sales_Order_Line__c soLine = new Sales_Order_Line__c();
        soLine.Product__c = data.product.Id;
        soLine.Description__c = data.product.Description__c;
        soLine.Company__c = data.company.Id;
        soLine.Sales_Order__c = so.Id;
        soLine.Quantity_Ordered__c = 1;
        soLine.Required_Date__c = System.today()+5;
        soLine.Discount_Percent__c = 2;
        soLine.Ship_From_Location__c = locs.shippingDock.Id;
        insert soLine;

        Map<Id,SalesOrderAPI.SalesOrderWrapper> soMap = new Map<Id,SalesOrderAPI.SalesOrderWrapper>();
        SalesOrderAPI.SalesOrderWrapper soWrapper = new SalesOrderAPI.SalesOrderWrapper(so.Id);
        soMap.put(soWrapper.salesOrderId,soWrapper);
        SalesOrderAPI.release(soMap);

        Test.startTest();
        Map<Id,SalesOrderAPI.SalesOrderAPIStatus> statuses = SalesOrderAPI.close(soMap);
        Test.stopTest();

        for (SalesOrderAPI.SalesOrderAPIStatus status:statuses.values())
            System.assert(status.success,'Close should succeed');
        System.assert([SELECT Id FROM Sales_Order_Line__c WHERE Status__c = 'Closed'].size() == 1,'Sales order line should be closed');
        System.assert([SELECT Id FROM Sales_Order__c WHERE Status__c = 'Closed'].size() == 1,'Sales order should be closed');
    }
    
    private static testMethod void testCloseFail() {
        SalesOrderTestData.CreateSoData = false;
        SalesOrderTestData data = new SalesOrderTestData();
        FacilityAndLocations locs = new FacilityAndLocations(data.company.Id);
        data.company.Default_Sales_Order_Ship_From_Facility__c = locs.facility.Id;
        update data.company;
        Sales_Order__c so = new Sales_Order__c();
        so.Company__c = data.company.Id;
        so.Customer__c = data.customer.Id;
        so.Ship_To__c = data.customerShipTo.Id;
        so.Bill_To__c = data.customerBillTo.Id;
        so.Payment_Term__c = data.terms.Id;
        so.Currency__c = TestFuel.currencyUSD.id;

        insert so;
        Sales_Order_Line__c soLine = new Sales_Order_Line__c();
        soLine.Product__c = data.product.Id;
        soLine.Description__c = data.product.Description__c;
        soLine.Company__c = data.company.Id;
        soLine.Sales_Order__c = so.Id;
        soLine.Quantity_Ordered__c = 1;
        soLine.Required_Date__c = System.today()+5;
        soLine.Discount_Percent__c = 2;
        soLine.Ship_From_Location__c = locs.shippingDock.Id;
        insert soLine;

        Map<Id,SalesOrderAPI.SalesOrderWrapper> soMap = new Map<Id,SalesOrderAPI.SalesOrderWrapper>();
        SalesOrderAPI.SalesOrderWrapper soWrapper = new SalesOrderAPI.SalesOrderWrapper(so.Id);
        soMap.put(soWrapper.salesOrderId,soWrapper);

        Test.startTest();
        Map<Id,SalesOrderAPI.SalesOrderAPIStatus> statuses = SalesOrderAPI.close(soMap);
        Test.stopTest();

        for (SalesOrderAPI.SalesOrderAPIStatus status:statuses.values())
            System.assert(!status.success,'Close should fail');
        System.assert([SELECT Id FROM Sales_Order_Line__c WHERE Status__c = 'Draft'].size() == 1,'Sales order line should still be in draft');
        System.assert([SELECT Id FROM Sales_Order__c WHERE Status__c = 'Draft'].size() == 1,'Sales order should still be in draft');
    }

    private static testMethod void testDeprecated() {
        try {
            SalesOrderAPI.allocate(null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        try {
            SalesOrderAPI.unallocate(null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        try {
            SalesOrderAPI.pick(null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        try {
            SalesOrderAPI.confirmShip(null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        try {
            SalesOrderAPI.ship(null,null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
    }

    public class FacilityAndLocations {
        public Facility__c facility { get; set; } { facility = new Facility__c(); }
        public Location__c stock { get; set; } { stock = new Location__c(); }
        public Location__c shippingDock { get; set; } { shippingDock = new Location__c(); }
        public Location__c receivingDock { get; set; } { receivingDock = new Location__c(); }
        public Facility__c facility2 { get; set; } { facility2 = new Facility__c(); }
        public Location__c stock2 { get; set; } { stock2 = new Location__c(); }
        public Location__c shippingDock2 { get; set; } { shippingDock2 = new Location__c(); }
        public Location__c receivingDock2 { get; set; } { receivingDock2 = new Location__c(); }
        public FacilityAndLocations(Id companyId) {
            facility.Name = 'Facility 1';
            facility.Company__c = companyId;
            facility.Description__c = 'Facility 1';
            facility2.Name = 'Facility 2';
            facility2.Company__c = companyId;
            facility2.Description__c = 'Facility 2';
            insert new List<Facility__c>{facility,facility2};
            stock.Facility__c = facility.Id;
            stock.Name = 'Stock';
            stock.Nettable__c = true;
            shippingDock.Facility__c = facility.Id;
            shippingDock.Name = 'Shipping Dock';
            shippingDock.Nettable__c = true;
            receivingDock.Facility__c = facility.Id;
            receivingDock.Name = 'Receiving Dock';
            receivingDock.Nettable__c = false;
            stock2.Facility__c = facility2.Id;
            stock2.Name = 'Stock 2';
            stock2.Nettable__c = true;
            shippingDock2.Facility__c = facility2.Id;
            shippingDock2.Name = 'Shipping Dock 2';
            shippingDock2.Nettable__c = true;
            receivingDock2.Facility__c = facility2.Id;
            receivingDock2.Name = 'Receiving Dock 2';
            receivingDock2.Nettable__c = false;
            insert new List<Location__c>{stock,shippingDock,receivingDock,stock2,shippingDock2,receivingDock2};
            facility.Default_Sales_Order_Ship_From_Location__c = shippingDock.Id;
            facility.Default_Purchasing_Delivery_Location__c = receivingDock.Id;
            facility2.Default_Sales_Order_Ship_From_Location__c = shippingDock2.Id;
            facility2.Default_Purchasing_Delivery_Location__c = receivingDock2.Id;
            update new List<Facility__c>{facility,facility2};
        }
    }
    private class StockMovement {
        public Stock_Movement_Rule__c pickRule { get; set; } { pickRule = new Stock_Movement_Rule__c(); }
        public StockMovement(Id companyId,Id facilityId,Id stockLocationId) {
            pickRule.Name = 'Pick Rule 1';
            pickRule.Rule_Type__c = 'Pick';
            pickRule.Company__c = companyId;
            pickRule.Facility__c = facilityId;
            pickRule.Source_Document__c = 'Sales Order';
            pickRule.Priority__c = 1;
            pickRule.Location_List__c = JSON.serialize(new List<Id>{stockLocationId});
            pickRule.Active__c = true;
            insert pickRule;
        }
    }
    public class InventoryData {
        public Item_Attribute__c itemAttr { get; set; } { itemAttr = new Item_Attribute__c(); }
        public List<Lot__c> lotList { get; set; } { lotList = new List<Lot__c>(); }
        public List<SKID__c> skidList { get; set; } { skidList = new List<SKID__c>(); }

        public InventoryData(Id companyId,Id stockLocationId,List<Item__c> itemList,Boolean createSecondLot) {
            itemAttr.Expiration_Date__c = true;
            itemAttr.Date_Received__c = true;
            itemAttr.Lot_Number__c = true;
            insert itemAttr;
            for (Item__c item:itemList) {
                item.Item_Attribute__c = itemAttr.Id;
                Lot__c lot = new Lot__c();
                lot.Name = 'A';
                lot.Company__c = companyId;
                lot.Item__c = item.Id;
                lot.Expiration_Date__c = System.today() + 365;
                lotList.add(lot);
                SKID__c skid = new SKID__c();
                skid.Location__c = stockLocationId;
                skid.Quantity__c = 100;
                skid.Item__c = item.Id;
                skid.Type__c = SKIDService.SKID_TYPE_LOCATION;
                skid.Expiration_Date__c = System.today() + 365;
                skid.Date_Received__c = System.today() + 365;
                skid.Lot_Number__c = 'A';
                skid.Company__c = companyId;
                skidList.add(skid);
            }
            if (createSecondLot) {
                Lot__c lot = new Lot__c();
                lot.Name = 'B';
                lot.Company__c = companyId;
                lot.Item__c = itemList[0].Id;
                lot.Expiration_Date__c = System.today() + 365;
                lotList.add(lot);
                SKID__c skid = new SKID__c();
                skid.Location__c = stockLocationId;
                skid.Quantity__c = 100;
                skid.Item__c = itemList[0].Id;
                skid.Type__c = SKIDService.SKID_TYPE_LOCATION;
                skid.Expiration_Date__c = System.today() + 365;
                skid.Date_Received__c = System.today() + 365;
                skid.Lot_Number__c = 'B';
                skid.Company__c = companyId;
                skidList.add(skid);
            }
            update itemList;
            insert lotList;
            for (Integer i=0;i<lotList.size();i++)
                skidList[i].Lot__c = lotList[i].Id;
            insert skidList;
        }
    } 
}