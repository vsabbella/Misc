@isTest
private class PurchaseOrderAPITest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);
        System.assert(f.purchaseOrder != null);
        insert new Configuration__c(Name = 'STACKTRACE');
    }

    public static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void receiveNoAttributes() {
        delete [SELECT Id FROM Item_Attribute__c];

        Purchase_Order_Line__c pol = fuel.purchaseOrderLines[0];
        Location__c loc = fuel.location3;

        SKID__c skid = new SKID__c(
            Location__c = loc.Id,
            Input_Quantity__c = 1
        );

        Map<Id, List<Map<String, Object>>> lines = new Map<Id, List<Map<String, Object>>>();
        lines.put(pol.Id, new List<Map<String, Object>>{ new Map<String, Object>{ 'skid' => skid }});

        Test.startTest();
        PurchaseOrderAPI.Receive receive = new PurchaseOrderAPI.Receive();
        Action.Response resp = receive.execute(JSON.serialize(lines));
        System.assert(resp.success == true, resp);
        Test.stopTest();

        Inventory_Transaction__c it = [SELECT Id, Quantity__c FROM Inventory_Transaction__c WHERE Type__c = 'Purchase Order Receipt'];
        System.assert(it.Quantity__c == 1, it.Quantity__c);
    }

    private static testMethod void receiveAttributes() {
        Purchase_Order_Line__c pol = fuel.purchaseOrderLines[0];
        Location__c loc = fuel.location3;

        SKID__c skid = new SKID__c(
            Location__c = loc.Id,
            Lot_Number__c = 'LOTA',
            Expiration_Date__c = Date.today().addDays(10),
            Input_Quantity__c = 1
        );

        Map<Id, List<Map<String, Object>>> lines = new Map<Id, List<Map<String, Object>>>();
        lines.put(pol.Id, new List<Map<String, Object>>{ new Map<String, Object>{ 'skid' => skid }});

        Test.startTest();
        PurchaseOrderAPI.Receive receive = new PurchaseOrderAPI.Receive();
        Action.Response resp = receive.execute(JSON.serialize(lines));
        System.assert(resp.success == true, resp);
        Test.stopTest();

        Inventory_Transaction__c it = [SELECT Id, Quantity__c FROM Inventory_Transaction__c WHERE Type__c = 'Purchase Order Receipt' AND Lot__c != null AND Expiration_Date__c != null];
        System.assert(it.Quantity__c == 1, it.Quantity__c);
    }

    private static testMethod void receiveSerials() {
        update new Item_Attribute__c(Id = fuel.itemAttrObj.Id, Serial_Number__c = true);

        Purchase_Order_Line__c pol = fuel.purchaseOrderLines[0];
        Location__c loc = fuel.location3;

        SKID__c skid = new SKID__c(
            Location__c = loc.Id,
            Lot_Number__c = 'LOTA',
            Expiration_Date__c = Date.today().addDays(10),
            Input_Quantity__c = 1
        );

        List<Serial__c> serials = new List<Serial__c>{ new Serial__c(Name = 'SERIAL1') };

        Map<Id, List<Map<String, Object>>> lines = new Map<Id, List<Map<String, Object>>>{ pol.Id => new List<Map<String, Object>>() };
        Map<String, Object> skidWrapper = new Map<String, Object>();
        skidWrapper.put('skid', skid);
        skidWrapper.put('serials', serials);
        lines.get(pol.Id).add(skidWrapper);

        Test.startTest();
        PurchaseOrderAPI.Receive receive = new PurchaseOrderAPI.Receive();
        Action.Response resp = receive.execute(JSON.serialize(lines));
        System.assert(resp.success == true, resp);
        Test.stopTest();

        Inventory_Transaction__c it = [SELECT Id, Quantity__c FROM Inventory_Transaction__c WHERE Type__c = 'Purchase Order Receipt'];
        System.assert(it.Quantity__c == 1, it.Quantity__c);

        Serial_Transaction__c st = [SELECT Id, Serial__c, Serial__r.Name FROM Serial_Transaction__c WHERE Inventory_Transaction__c = :it.Id];
        System.assert(st.Serial__r.Name == serials[0].Name, st);
    }

    private static testMethod void close() {
        Purchase_Order__c po = fuel.purchaseOrder;
        Map<Id, PurchaseOrderAPI.PurchaseOrderWrapper> poMap = new Map<Id, PurchaseOrderAPI.PurchaseOrderWrapper>();
        poMap.put(po.Id, new PurchaseOrderAPI.PurchaseOrderWrapper(po.Id));
        poMap.put(po.Company__c, new PurchaseOrderAPI.PurchaseOrderWrapper(po.Id));

        Test.startTest();

        Map<Id, PurchaseOrderAPI.PurchaseOrderAPIStatus> statuses = PurchaseOrderAPI.close(poMap);

        Boolean isSuccess;
        for (PurchaseOrderAPI.PurchaseOrderAPIStatus status:statuses.values()) {
            if (isSuccess == null) isSuccess = status.success;
            else System.assert(isSuccess == !status.success, statuses);
        }
        
        Test.stopTest();

        Purchase_Order_Line__c pol = [SELECT Id, Purchase_Order__c, Purchase_Order__r.Status__c FROM Purchase_Order_Line__c WHERE Status__c = 'Closed'];
        System.assert(pol.Purchase_Order__r.Status__c == 'Closed', pol.Purchase_Order__r);
    }

    private static testMethod void deprecated() {
        try {
            PurchaseOrderAPI.receive(null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        try {
            PurchaseOrderAPI.PurchaseOrderLineWrapper pol = new PurchaseOrderAPI.PurchaseOrderLineWrapper();
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        try {
            PurchaseOrderAPI.ReceivingLine rl = new PurchaseOrderAPI.ReceivingLine();
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        try {
            PurchaseOrderAPI.PurchaseOrderAPIException ex = new PurchaseOrderAPI.PurchaseOrderAPIException('error');
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
    }
}