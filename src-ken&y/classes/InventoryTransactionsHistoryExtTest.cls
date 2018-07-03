/*
*   Test methods for InventoryTransactionsHistoryExt
*/
@isTest
public with sharing class InventoryTransactionsHistoryExtTest {
    static TestFuel fuel = new TestFuel();
    
    static testMethod void testgetLotMasterHistoryFieldList() {
        // Arrange
        Item__c item = getItem();
        ApexPages.StandardController stdCon = new Apexpages.StandardController(item);
        InventoryTransactionsHistoryExt lmhCon = new InventoryTransactionsHistoryExt(stdCon);
        GridRelatedListController con = new GridRelatedListController();
        con.config = getLotMasterHistoryLinesConfig();
        
        // Act
        String result = lmhCon.getLotMasterHistoryFieldList();
        
        // Assert
        System.assertNotEquals('', result);
    }
    
    static testMethod void testGetlotMasterHistoryLinesConfigJson() {
        // Arrange
        Item__c item = getItem();
        ApexPages.StandardController stdCon = new Apexpages.StandardController(item);
        InventoryTransactionsHistoryExt lmhCon = new InventoryTransactionsHistoryExt(stdCon);
        GridRelatedListController con = new GridRelatedListController();
        con.config = getLotMasterHistoryLinesConfig();
        
        // Act
        string result = lmhCon.getlotMasterHistoryLinesConfigJson();
        
        // Assert
        System.assertEquals(result, JSON.serialize(lmhCon.lotMasterHistoryLinesConfig));
    }
    
    static testMethod void testGetTransactionTypeOptions() {
    	Test.startTest();
        
        // Arrange
        Item__c item = getItem();
        ApexPages.StandardController stdCon = new Apexpages.StandardController(item);
        InventoryTransactionsHistoryExt lmhCon = new InventoryTransactionsHistoryExt(stdCon);
        GridRelatedListController con = new GridRelatedListController();
        con.config = getLotMasterHistoryLinesConfig();
        
        // Act
        List<SelectOption> result = lmhCon.getTransactionTypeOptions();
        
        // Assert
        System.assertNotEquals(0, result.size());
        
        Test.stopTest();
    }
    
    static testMethod void testGetLotMasterHistoryLines(){
        Test.startTest();
        
        // Arrange
        String referenceNumber = '';
        Item__c item = getItem();
        List<Inventory_Transaction__c> itList = new List<Inventory_Transaction__c>();
        
        Inventory_Transaction__c itLine = new Inventory_Transaction__c();
        itLine.Item__c = item.Id;
        itLine.Type__c = 'Transfer';
        itLine.From_Facility__c = fuel.facility.Id;
        itLine.From_Location__c = fuel.location.Id;
        itLine.Quantity__c = 100;
        itLine.Company__c = fuel.company.Id;
        itList.add(itLine);
        
        itLine = new Inventory_Transaction__c();
        itLine.Item__c = item.Id;
        itLine.Type__c = 'Transfer';
        itLine.To_Facility__c = fuel.facility.Id;
        itLine.To_Location__c = fuel.location.Id;
        itLine.Quantity__c = 20;
        itLine.Company__c = fuel.company.Id;
        itList.add(itLine);
        
        insert itList;
        
        GridRelatedListController.GridRelatedListConfig config = getLotMasterHistoryLinesConfig();
        
        List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor filter = new KendoUtils.FilterDescriptor();
        
        filter.field = 'Item__c';
        filter.fieldType = 'string';
        filter.operator = 'eq';
        filter.value = item.Id;
        
        filters.add(filter);
        
        // Act
        JsonResult result = InventoryTransactionsHistoryExt.getLotMasterHistoryLines(filters, referenceNumber, config);
        
        // Assert
        System.assertNotEquals(0, result.total);
        
        Test.stopTest();
    }
    
    private static Item__c getItem() {
        Item__c item = fuel.itemList[0];
        
        return item;
    }
    
    private static GridRelatedListController.GridRelatedListConfig getLotMasterHistoryLinesConfig() {
        GridRelatedListController.GridRelatedListConfig config = new GridRelatedListController.GridRelatedListConfig();
        config.objectName = 'Inventory_Transaction__c';
        config.fieldSet = 'Inventory_History_Lines';
        config.additionalFields = 'From_Lot__c,From_Lot__r.Name,Purchase_Order_Line__c, Purchase_Order_Line__r.Name, Purchase_Order_Line__r.Purchase_Order__c, Purchase_Order_Line__r.Purchase_Order__r.Name, Receipt_Line__c, Receipt_Line__r.Name, Receipt_Line__r.Purchase_Order__r.Name, Sales_Order_Line__c, Sales_Order_Line__r.Name, Sales_Order_Line__r.Sales_Order__c, Sales_Order_Line__r.Sales_Order__r.Name, Receipt_Line__r.Name, Shipment_Line__r.Name, Work_Order__c, Work_Order__r.Name, Inventory_Change__c, Inventory_Change__r.Name, Inventory_Change__r.Reason_Code__r.Name, Order_Line__c, Order_Line__r.Order__c, Order_Line__r.Order__r.Name';
        config.sortField = 'Transaction_Date__c';
        config.sortOrder = 'DESC';

        return config;
    }
}