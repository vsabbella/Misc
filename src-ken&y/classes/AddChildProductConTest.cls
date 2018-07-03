@isTest
public class AddChildProductConTest{
 
    static testMethod void AddChildProductConTest() {
        TestFuel fuel = new TestFuel();
        Customer__c customerBillTo = fuel.customerBillTo;
        Customer__c customerSoldTo = fuel.customerSoldTo;
        Customer__c customerShipTo = fuel.customerShipto;
        Pricebook__c pricebook = fuel.pricebook;
        Product__c product = fuel.product;
        List<Item__c> itemList = fuel.itemList;
        Item_Specification__c configItemSpec = fuel.configItemSpec;
        List<Component__c> components = fuel.components;
        Product__c configProduct = fuel.configProduct;
        
        Agreement__c agreement = fuel.agreement;
        Agreement_Line__c agreementLine = fuel.agreementLine;
        Test.startTest();
        
        AddChildProductsCon con = new AddChildProductsCon(new Apexpages.Standardcontroller(agreementLine));
        JsonResult jsonResult = AddChildProductsCon.searchProd('P');
        String s = con.getiFieldList();
        system.assertNotEquals(0, jsonResult.records.size(), Apexpages.getMessages());

        AddChildProductsCon.ProductWrapper ProductWrapper = new AddChildProductsCon.ProductWrapper();
        ProductWrapper.p = product;
        ProductWrapper.qty = 10;
        ProductWrapper.selected = true;
        List<AddChildProductsCon.ProductWrapper> ProductWrapperList = new List<AddChildProductsCon.ProductWrapper>();
        ProductWrapperList.add(ProductWrapper);
        DataSourceResult result = AddChildProductsCon.CreateProducts(ProductWrapperList, agreementLine.Id);

        //con.pwList[0].selected = true;
        //con.pwList[0].qty = 1;
        //con.CreateProducts1();

        List<Agreement_Line__c> agls = [SELECT Id FROM Agreement_Line__c WHERE Id != :agreementLine.Id];
        system.assertNotEquals(0, agls.size(), agls);      

        Test.stopTest();
    }
    static testMethod void AddChildProductConTestNoQty() {
        TestFuel fuel = new TestFuel();
        Customer__c customerBillTo = fuel.customerBillTo;
        Customer__c customerSoldTo = fuel.customerSoldTo;
        Customer__c customerShipTo = fuel.customerShipto;
        Pricebook__c pricebook = fuel.pricebook;
        Product__c product = fuel.product;
        List<Item__c> itemList = fuel.itemList;
        Item_Specification__c configItemSpec = fuel.configItemSpec;
        List<Component__c> components = fuel.components;
        Product__c configProduct = fuel.configProduct;
        
        Agreement__c agreement = fuel.agreement;
        Agreement_Line__c agreementLine = fuel.agreementLine;
        Test.startTest();
        
        AddChildProductsCon con = new AddChildProductsCon(new Apexpages.Standardcontroller(agreementLine));
        JsonResult jsonResult = AddChildProductsCon.searchProd('');
        String s = con.getiFieldList();
        system.assertNotEquals(0, jsonResult.records.size(), Apexpages.getMessages());

        AddChildProductsCon.ProductWrapper ProductWrapper = new AddChildProductsCon.ProductWrapper();
        ProductWrapper.p = product;
        ProductWrapper.selected = true;
        List<AddChildProductsCon.ProductWrapper> ProductWrapperList = new List<AddChildProductsCon.ProductWrapper>();
        ProductWrapperList.add(ProductWrapper);
        DataSourceResult result = AddChildProductsCon.CreateProducts(ProductWrapperList, agreementLine.Id);
        

        List<Agreement_Line__c> agls = [SELECT Id FROM Agreement_Line__c WHERE Id != :agreementLine.Id];
        system.assertEquals(0, agls.size(), agls);      

        Test.stopTest();
    }
}