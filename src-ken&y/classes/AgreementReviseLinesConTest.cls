@isTest
private class AgreementReviseLinesConTest {
static testMethod void testAgreementRevision() {
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
        Category__c categoryBilling = fuel.categoryBilling;
        Category__c categoryFulfillment = fuel.categoryFulfillment;
        Agreement__c agreement = fuel.agreement.clone(false, false, false, false);
        agreement.Status__c = 'Draft';
        insert agreement;
        Agreement_Line__c agreementLine = fuel.agreementLine;
        agreementLine.Revision_Status__c = null;
        agreementLine.Billing_Category__c = categoryBilling.id;
        agreementLine.Fulfillment_Category__c = categoryFulfillment.id;
        update agreementLine;
        agreement.Status__c = 'Approved';
        update agreement;
        Test.startTest();
        agreement = [Select Customer__c, Customer__r.RecordType.DeveloperName, Currency__c, Status__c,
                       Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Name, 
                       Customer__r.Parent_Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Parent_Customer__r.Name, 
                       Customer__r.Top_Parent_Customer__c, Customer__r.Top_Parent_Customer__r.Name From Agreement__c where id =:fuel.agreement.id limit 1];        
        AgreementReviseLinesCon ext = new AgreementReviseLinesCon(new Apexpages.Standardcontroller(agreement));
        ext.lws[0].selected = true;
        ext.lws[0].revAl.Agreement_Price__c = 200;
        ext.revise();
        list<Agreement_Line__c> aList = [SELECT id ,Revision_Status__c FROM
                                            Agreement_Line__c  WHERE ID != :agreementLine.id
                                            AND agreement__c = :agreement.id];   
        
        system.assertNotEquals(0, aList.size());
        system.assertEquals('Pending Approval', aList[0].Revision_Status__c);
        

        Test.stopTest();
    }

}