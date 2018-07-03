@isTest
private class AgreementDeinstallExtTest {

//    static testMethod void myUnitTest() {
//
//        TestFuel fuel = new TestFuel();
//        Company__c company = fuel.company;
//        Customer__c customerBillTo = fuel.customerBillTo;
//        Customer__c customerSoldTo = fuel.customerSoldTo;
//        Customer__c customerShipTo = fuel.customerShipto;
//        customerShipTo.Track_Install_Base__c = true;
//        update customerShipTo;
//        Pricebook__c pricebook = fuel.pricebook;
//        Product__c product = fuel.product;
//        List<Item__c> itemList = fuel.itemList;
//        Item_Specification__c configItemSpec = fuel.configItemSpec;
//        List<Component__c> components = fuel.components;
//        Product__c configProduct = fuel.configProduct;
//        Item__c item = new Item__c(Id = configProduct.Item__c);
//        item.Track_Install_Base__c = true;
//        update item;
//        Agreement__c agreement = fuel.agreement;
//        Customer__c site = fuel.customerSite;
//        Agreement_Line__c agreementLine = fuel.agreementLine;
//        agreementLine.Revision_Status__c = null;
//        update agreementLine;
//
//
//        agreement = [Select Customer__c, Customer__r.RecordType.DeveloperName, Status__c,
//                       Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Name, Company__r.Serial_Control__c,
//                       Customer__r.Parent_Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Parent_Customer__r.Name,
//                       Customer__r.Top_Parent_Customer__c, Customer__r.Top_Parent_Customer__r.Name From Agreement__c where id =:fuel.agreement.id limit 1];
//
//
//
//        AgreementReleaseExt ext = new AgreementReleaseExt(new Apexpages.Standardcontroller(agreement));
//        ext.updateLines();
//        JsonResult jsonResult = AgreementReleaseExt.getAgreementLineData(agreement.Id);
//        system.assertNotEquals(0, jsonResult.records.size(), Apexpages.getMessages());
//
//        AgreementReleaseExt.LineWrapper lineWrapper = new AgreementReleaseExt.LineWrapper();
//        lineWrapper.al = agreementLine;
//        lineWrapper.qty = 10;
//        lineWrapper.selected = true;
//        lineWrapper.used = false;
//        lineWrapper.isSerialProduct = false;
//        List<AgreementReleaseExt.LineWrapper> lineWrapperList = new List<AgreementReleaseExt.LineWrapper>();
//        lineWrapperList.add(lineWrapper);
//        Test.startTest();
//        DataSourceResult result = AgreementReleaseExt.createSalesOrders(lineWrapperList, agreement.Id, customerBillTo.Id, customerSoldTo.Id, customerShipTo.Id, null);
//        List<Sales_Order_Line__c> sols = [SELECT Id FROM Sales_Order_Line__c];
//        system.assertNotEquals(0, sols.size(), Apexpages.getMessages());
//
//        Fulfillment__c tmpFulf = new Fulfillment__c();
//        tmpFulf.Sales_Order_Line__c = sols[0].Id;
//        tmpFulf.Company__c = company.Id;
//        tmpFulf.Agreement__c = agreement.Id;
//        tmpFulf.Agreement_Line__c = fuel.agreementLine.Id;
//        tmpFulf.customer__c = customerSoldTo.Id;
//        tmpFulf.Quantity__c = 10;
//        tmpFulf.status__c = 'Complete';
//        insert tmpFulf;
//
//
//        List<SKID__c> skids = [SELECT Id FROM SKID__c]; // WHERE Customer__c = :site.Id
//        system.assertNotEquals(0, skids.size());
//
//        List<Fulfillment__c> fs = [SELECT Id, Status__c FROM Fulfillment__c WHERE Agreement_Line__r.Agreement__c = :agreement.Id];
//        system.assertNotEquals(0, fs.size(), fs);
//        for(Fulfillment__c f : fs){
//            f.Status__c = 'Complete';
//            f.quantity__c = 10;
//        }
//
//        update fs;
//
//
//        AgreementDeinstallExt extd = new AgreementDeinstallExt(new Apexpages.Standardcontroller(agreement));
//        system.assertNotEquals(0, extd.installationDetails.size(), extd);
//        system.assertNotEquals(0, extd.installationDetails[0].skids.size(), extd.installationDetails[0]);
//        Id skidId = extd.installationDetails[0].skids[0].skid.Id;
//        extd.installationDetails[0].skids[0].selected = true;
//        extd.installationDetails[0].skids[0].qty = 10;
//        extd.deinstall();
//
//
//        Test.stopTest();
//        List<Sales_Order__c> so = [SELECT Id, Agreement__c, (Select Id, Unit_Price__c from Sales_Order_Lines__r) FROM Sales_Order__c WHERE Type__c = 'Adjustment'];
//        //Test.stopTest();
//        system.assertNotEquals(0, so.size());
//        system.assertEquals(agreement.Id, so[0].Agreement__c);
//        system.assertEquals(1,so[0].Sales_Order_Lines__r.size());
//        system.assertEquals(100,so[0].Sales_Order_Lines__r[0].Unit_Price__c);//KNDY-7929
//
//
//        Fulfillment__c deinstallFulf = new Fulfillment__c();
//        deinstallFulf.Sales_Order_Line__c = sols[0].Id;
//        deinstallFulf.Company__c = company.Id;
//        deinstallFulf.Agreement__c = agreement.Id;
//        deinstallFulf.Agreement_Line__c = fuel.agreementLine.Id;
//        deinstallFulf.customer__c = customerSoldTo.Id;
//        deinstallFulf.Quantity__c = -10;
//        deinstallFulf.status__c = 'Complete';
//        deinstallFulf.Type__c = 'Deinstall';
//        deinstallFulf.SKID__c = skidId;
//        insert deinstallFulf;
//
//        SKID__c skid = [SELECT Id, Quantity__c FROM SKID__c WHERE Id = :skidId];
//        system.assertEquals(0, skid.Quantity__c, 'There should be 0 quantity left at the install base');
//
//    }
}