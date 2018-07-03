@isTest
private class AgreementTriggerTest{
static testMethod void testDelete() {
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
        boolean checkError;
        
        Test.startTest();
         try {
            delete agreement;
            checkError = false;
        }
        catch(exception e ){
            checkError = true;
        }
       
        Test.stopTest();
        System.assert(checkError);

        
    }
    
    
    static testMethod void testPaymentTerms() {
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
        
        Test.startTest();
        agreement = [Select id,Customer__c,Payment_Terms__c From Agreement__c where id =:fuel.agreement.id limit 1]; 
        system.assertEquals(agreement.Payment_Terms__c, customerBillTo.Payment_Term__c);
        Test.stopTest();
    }

}