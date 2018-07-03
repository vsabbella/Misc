@isTest
private class AgreementRevisionApprovalConTest {
static testMethod void testAgreementRevisionApproval() {
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
        agreementLine.Revision_Status__c = 'Pending Approval';
        update agreementLine;
        Test.startTest();
        agreement = [Select Customer__c, Customer__r.RecordType.DeveloperName, Currency__c, Status__c,
                       Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Name, 
                       Customer__r.Parent_Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Parent_Customer__r.Name, 
                       Customer__r.Top_Parent_Customer__c, Customer__r.Top_Parent_Customer__r.Name From Agreement__c where id =:fuel.agreement.id limit 1];        
        AgreementRevisionApprovalCon ext = new AgreementRevisionApprovalCon(new Apexpages.Standardcontroller(agreement));
        ext.lws[0].selected = true;
        
        ext.approve();
        list<Agreement_Line__c> aList = [SELECT id ,Revision_Status__c,Start_Date__c,End_Date__c,Occurrence_Count__c,Occurrence__c,Agreement__r.Activation_Date__c FROM
                                            Agreement_Line__c  WHERE ID = :agreementLine.id];   
        
        system.assertNotEquals(null, aList.size());
        system.assertEquals('Approved', aList[0].Revision_Status__c);
        

        Test.stopTest();
    }

}