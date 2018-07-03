@isTest
private class AgreementCloneTest {
static testMethod void testAgreementClone() {
        TestFuel fuel = new TestFuel();
       
        Customer__c customerBillTo = fuel.customerBillTo;
        Customer__c customerSoldTo = fuel.customerSoldTo;
        Customer__c customerShipTo = fuel.customerShipto;
        Pricebook__c pricebook = fuel.pricebook;
        update pricebook;
        Product__c product = fuel.product;
        
        Agreement__c agreement = new Agreement__c(); 
        agreement.Company__c = fuel.company.Id;
        agreement.Name = 'Sample Agreement';
        agreement.Currency__c = TestFuel.currencyUSD.Id;
        agreement.Customer__c = fuel.customerParent.Id;
        agreement.Bill_To__c = fuel.customerBillTo.Id;
        agreement.Sold_To__c = fuel.customerSoldTo.Id;
        agreement.Start_Date__c = system.today();
        agreement.End_Date__c = system.today().addDays(730);
        agreement.Activation_Date__c = system.today();
        agreement.Recurrence_Start_Date__c = system.today()+5;
        agreement.Status__c = 'Draft';
        agreement.Payment_Terms__c  = fuel.terms.Id;
        
       
        insert agreement;

    
        Agreement_Line__c agreementLine = new Agreement_Line__c();
        
        agreementLine.Agreement__c = agreement.Id;
        agreementLine.Start_Date__c = agreement.Start_Date__c;
        agreementLine.End_Date__c = agreement.End_Date__c;
        agreementLine.Occurrence__c = 'Annually';
        agreementLine.Rate_Basis__c = 'Quantity';
        agreementLine.Product__c = product.Id;
        agreementLine.Product_Type__c = 'Product';
        agreementLine.Sales_Agreement_Quantity__c = 100;
        agreementLine.Revision_Status__c = null;
        agreementLine.Agreement_Price__c = 100;
        insert agreementLine;
    
        Agreement_Line__c agreementLine2 = new Agreement_Line__c();
        
        agreementLine2.Agreement__c = agreement.Id;
        agreementLine2.Start_Date__c = agreement.Start_Date__c;
        agreementLine2.End_Date__c = agreement.End_Date__c;
        agreementLine2.Occurrence__c = 'Annually';
        agreementLine2.Rate_Basis__c = 'Quantity';
        agreementLine2.Product__c = product.Id;
        agreementLine2.Product_Type__c = 'Product';
        agreementLine2.Sales_Agreement_Quantity__c = 100;
        agreementLine2.Revision_Status__c = null;
        agreementLine2.Agreement_Price__c = 100;
        agreementLine2.Parent_Agreement_Line__c = agreementLine.id;
        insert agreementLine2;
    
        Test.startTest();
          
        AgreementCloneCon ext = new AgreementCloneCon(new Apexpages.Standardcontroller(agreement));
        ext.lws[0].selected = true;
        ext.lws[1].selected = true;
        ext.agreement.name = 'AG-1';
        ext.agmtClone();
        list<Agreement__c> agmtList = [SELECT id, Activation_Date__c, Recurrence_Start_Date__c   FROM
                                        Agreement__c  WHERE ID != :agreement.id];
        list<Agreement_Line__c> aList = [SELECT id, Parent_Agreement_Line__c  FROM
                                            Agreement_Line__c  WHERE ID != :agreementLine.id
                                            AND agreement__c != :agreement.id];   
        
        system.assertEquals(agmtList[0].Activation_Date__c, null);
        system.assertEquals(agmtList[0].Recurrence_Start_Date__c, null);
        system.assertEquals(1, agmtList.size());
        system.assertEquals(2, aList.size()); 
        system.assertEquals(aList[1].Parent_Agreement_Line__c, aList[0].id); //verify if the first line is the parent line for second line
        Test.stopTest();
    }

}