@isTest
private class AgreementLineTriggerTest {

static testMethod void testPrice() {
        TestFuel fuel = new TestFuel();

        Customer__c customerBillTo = fuel.customerBillTo;
        Customer__c customerSoldTo = fuel.customerSoldTo;
        Customer__c customerShipTo = fuel.customerShipto;

        Pricebook__c pricebook1 = new Pricebook__c();
        pricebook1.name = fuel.company.Name +  ' Orange ';
        pricebook1.company__c = fuel.company.id;
        pricebook1.Primary_Key__c = 'BOOK';
        pricebook1.Currency__c = TestFuel.currencyGBP.id;
        insert pricebook1;


        Pricebook_Line__c pl =new Pricebook_Line__c();
        pl.product__c = fuel.product.id;
        pl.Price_Type__c  = 'Sales';
        pl.Pricing_UOM__c = null;
        pl.pricebook__c = pricebook1.id;
        pl.price__c = 11.12;
        pl.start_date__c = system.today();
        pl.end_date__c = system.today().addDays(100);

        Pricebook_Line__c pl2 =new Pricebook_Line__c();
        pl2.product__c = fuel.product2.id;
        pl2.pricebook__c = pricebook1.id;
        pl2.price__c = 12.11;
        pl2.start_date__c = system.today();
        pl2.end_date__c = system.today().addDays(100);

        insert new List<Pricebook_Line__c>{pl,pl2};


        Product__c product = fuel.product;
        customerSoldTo.Pricebook__c = pricebook1.id;
        update customerSoldTo;
        Test.startTest();
        Agreement__c agreement = new Agreement__c();
        agreement.Company__c = fuel.company.Id;
        agreement.Name = 'Sample Agreement';
        agreement.Customer__c = fuel.customerParent.Id;
        agreement.Bill_To__c = fuel.customerBillTo.Id;
        agreement.Sold_To__c = fuel.customerSoldTo.Id;
        agreement.Start_Date__c = system.today();
        agreement.End_Date__c = system.today().addDays(730);
        agreement.Status__c = 'Draft';
        agreement.Currency__c = TestFuel.currencyGBP.id;
        agreement.Payment_Terms__c  = fuel.terms.Id;

        insert agreement;


        Agreement_Line__c agreementLine = new Agreement_Line__c();

        agreementLine.Agreement__c = agreement.Id;
        agreementLine.Start_Date__c = agreement.Start_Date__c;
        agreementLine.End_Date__c = agreement.End_Date__c;
        agreementLine.Occurrence__c = 'Annually';
        agreementLine.Rate_Basis__c = 'Quantity';
        agreementLine.Product__c = product.Id;
        agreementLine.Price_Type__c  = 'Sales';
        agreementLine.Pricing_UOM__c = null;
        agreementLine.Product_Type__c = 'Product';
        agreementLine.Sales_Agreement_Quantity__c = 100;
        agreementLine.Revision_Status__c = null;
        agreementLine.Agreement_Price__c = 100;
        agreementLine.List_Price__c = null;
        insert agreementLine;
        Test.stopTest();
        list<Agreement_Line__c> aList = [SELECT id,product__c,List_Price__c,Total_Agreement_Quantity__c ,Sales_Agreement_Quantity__c ,Remaining_Quantity__c,Sold_Quantity__c  FROM
                                            Agreement_Line__c  WHERE ID = :agreementLine.id];
        system.assertEquals(11.12, aList[0].List_Price__c);



    }



    static testMethod void getProductCategoryTest() {
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
        configProduct.Billing_Category__c = categoryBilling.id;
        configProduct.Fulfillment_Category__c = categoryFulfillment.id;
        update configProduct;
        Agreement__c agreement = fuel.agreement;
        Test.startTest();
        Agreement_Line__c agreementLine = fuel.agreementLine;
        agreementLine = [SELECT Id,Billing_Category__c,Fulfillment_Category__c  FROM Agreement_Line__c WHERE Id = :agreementLine.Id];
        system.assertEquals(categoryBilling.id, agreementLine.Billing_Category__c );
        system.assertEquals(categoryFulfillment.id, agreementLine.Fulfillment_Category__c);

        Test.stopTest();
    }

    static testMethod void testSpecPrice() {
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
        agreementLine.Agreement_Price__c = 0;
        update agreementLine;
        Test.startTest();
        list<Agreement_Line__c> arlList = new list<Agreement_Line__c>();
        arlList.add(agreementLine);
        AgreementLineService.getParentAgreementLineAgPrice(arlList);
        system.assertEquals(0, agreementLine.Agreement_Price__c );

        Test.stopTest();
    }

    static testMethod void testOccurenceSetEndDate() {
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
        list<Agreement_Line__c> aList = [SELECT id ,Start_Date__c,End_Date__c,Occurrence_Count__c,Occurrence__c,Agreement__r.Activation_Date__c FROM
                                            Agreement_Line__c  WHERE ID = :agreementLine.id];
        AgreementLineService.setEndDate(aList) ; //sets end date based on occurence count,occurence,start date
        system.assertNotEquals(null, aList[0].End_Date__c);

        Test.stopTest();
    }
    static testMethod void testDefaultDates() {
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


        system.assertEquals(agreementLine.Start_Date__c,agreement.Start_Date__c);
        system.assertEquals(agreementLine.End_Date__c,agreement.End_Date__c);
        Test.stopTest();
    }
    static testMethod void testTotalAgreementQuantities() {
        TestFuel fuel = new TestFuel();

        Customer__c customerBillTo = fuel.customerBillTo;
        Customer__c customerSoldTo = fuel.customerSoldTo;
        Customer__c customerShipTo = fuel.customerShipto;
        Pricebook__c pricebook = fuel.pricebook;
        Product__c product = fuel.product;
        Test.startTest();

        UOM__c uom = new UOM__c();
        uom.Name = 'YEARLY';
        uom.Type__c = 'Time';
        uom.Recurrence__c = 'Year(s)';
        uom.Every__c = 1;
        insert uom;

        Agreement__c agreement = new Agreement__c();
        agreement.Company__c = fuel.company.Id;
        agreement.Name = 'Sample Agreement';
        agreement.Customer__c = fuel.customerParent.Id;
        agreement.Bill_To__c = fuel.customerBillTo.Id;
        agreement.Start_Date__c = system.today();
        agreement.End_Date__c = system.today().addDays(730);
        agreement.Status__c = 'Draft';
        agreement.Currency__c = TestFuel.currencyGBP.id;
        agreement.Payment_Terms__c  = fuel.terms.Id;

        insert agreement;


        Agreement_Line__c agreementLine = new Agreement_Line__c();

        agreementLine.Agreement__c = agreement.Id;
        agreementLine.Start_Date__c = agreement.Start_Date__c;
        agreementLine.End_Date__c = agreement.End_Date__c;
        agreementLine.Pricing_UOM__c = uom.Id;
        agreementLine.Rate_Basis__c = 'Quantity';
        agreementLine.Product__c = product.Id;
        agreementLine.Product_Type__c = 'Product';
        agreementLine.Sales_Agreement_Quantity__c = 100;
        agreementLine.Revision_Status__c = null;
        agreementLine.Agreement_Price__c = 100;
        insert agreementLine;
        agreement.Status__c = 'Approved';
        update agreement;




        Test.stopTest();
        list<Agreement_Line__c> aList = [SELECT id,product__c,Total_Agreement_Quantity__c ,Sales_Agreement_Quantity__c ,Remaining_Quantity__c,Sold_Quantity__c  FROM
                                            Agreement_Line__c  WHERE ID = :agreementLine.id];

        system.assertEquals(200, aList[0].Total_Agreement_Quantity__c);
        system.assertEquals(200, aList[0].Remaining_Quantity__c);




    }

}