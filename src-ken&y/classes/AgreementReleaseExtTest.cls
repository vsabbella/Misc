@isTest
private class AgreementReleaseExtTest {

    static testMethod void testRelease() {
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
        agreementLine.Revision_Status__c = null;
        update agreementLine;
        Test.startTest();
        agreement = [Select Customer__c, Customer__r.RecordType.DeveloperName, Currency__c, Status__c,
                       Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Name, 
                       Customer__r.Parent_Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Parent_Customer__r.Name, 
                       Customer__r.Top_Parent_Customer__c, Customer__r.Top_Parent_Customer__r.Name, Company__r.Serial_Control__c From Agreement__c where id =:fuel.agreement.id limit 1];        

        AgreementReleaseExt ext = new AgreementReleaseExt(new Apexpages.Standardcontroller(agreement));
        ext.updateLines();
        JsonResult jsonResult = AgreementReleaseExt.getAgreementLineData(agreement.Id);
        system.assertNotEquals(0, jsonResult.records.size(), Apexpages.getMessages());

        AgreementReleaseExt.LineWrapper lineWrapper = new AgreementReleaseExt.LineWrapper();
        lineWrapper.al = agreementLine;
        lineWrapper.qty = 10;
        lineWrapper.selected = true;
        lineWrapper.used = false;
        lineWrapper.isCreateRelease = false;
        List<AgreementReleaseExt.LineWrapper> lineWrapperList = new List<AgreementReleaseExt.LineWrapper>();
        lineWrapperList.add(lineWrapper);
        DataSourceResult result = AgreementReleaseExt.createSalesOrders(lineWrapperList, agreement.Id, customerBillTo.Id, customerSoldTo.Id, customerShipTo.Id, null);

        List<Sales_Order_Line__c> sols = [SELECT Id FROM Sales_Order_Line__c];
        system.assertNotEquals(0, sols.size(), Apexpages.getMessages());
        /* Commenting out as KNDY-7504 should not be needed
        list<Fulfillment__c> lF = [Select Id, Inventory_Transaction__c, Inventory_Transaction__r.Item__c from Fulfillment__c where Sales_Order_line__c in :sols];
        for(Fulfillment__c f : lF){
        	system.assertNotEquals(null, f.inventory_transaction__c, f);
        	system.assertNotEquals(null, f.inventory_transaction__r.Item__c, f);	
        }
        system.assertEquals(sols.size(), lF.size());
        */
        Sales_Order__c so = [select id, Currency__c from Sales_Order__c where Agreement__c = :agreement.Id];
        system.assertEquals(agreement.Currency__c, so.Currency__c);

        Test.stopTest();
    }
	
	//KNDY-11699 Allocate Serials    
    static testMethod void testRelease_serialEnabled(){ 

        TestFuel fuel = new TestFuel();
       
        Customer__c customerBillTo = fuel.customerBillTo;
        Customer__c customerSoldTo = fuel.customerSoldTo;
        Customer__c customerShipTo = fuel.customerShipto;
        Pricebook__c pricebook = fuel.pricebook;
        Product__c product = fuel.product3;
        Item__c item = fuel.itemList[5];
        
        //Enable serial on Item Attribute
        Item_Attribute__c itemAttr = fuel.itemAttrObj;
        itemAttr.Serial_Number__c = true;
        update itemAttr;

        //Enable serial on Company
        fuel.Company.Serial_Control__c = 'At receipt and shipments';
        update fuel.Company;         

        Agreement__c agreement = fuel.agreement;
        Agreement_Line__c agreementLine = fuel.agreementLine;
        agreementLine.Revision_Status__c = null;
        agreementLine.Product__c = product.id;
        agreementLine.Price_Type__c = 'Recurring';
        agreementLine.Pricing_UOM__c = fuel.week.id;
        agreementLine.List_Price__c = 1;
        update agreementLine;

        Test.startTest();
        agreement = [Select Customer__c, Customer__r.RecordType.DeveloperName, Status__c, Currency__c,
                       Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Name, 
                       Customer__r.Parent_Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Parent_Customer__r.Name, 
                       Customer__r.Top_Parent_Customer__c, Customer__r.Top_Parent_Customer__r.Name, Company__r.Serial_Control__c From Agreement__c where id =:fuel.agreement.id limit 1];

        AgreementReleaseExt ext = new AgreementReleaseExt(new Apexpages.Standardcontroller(agreement));
        ext.updateLines();
        JsonResult jsonResult = AgreementReleaseExt.getAgreementLineData(agreement.Id);
        system.assertNotEquals(0, jsonResult.records.size(), Apexpages.getMessages());
        system.assertEquals(1, jsonResult.records.size(), Apexpages.getMessages());  //check if the updated row is retrieved

        AgreementReleaseExt.LineWrapper lineWrapper = new AgreementReleaseExt.LineWrapper();
        lineWrapper.al = agreementLine;
        lineWrapper.qty = 2; //Lets release qty 2, this should create SO with 2 sales order lines
        lineWrapper.selected = true;
        lineWrapper.isSerialProduct = true; //set this to true and the UI sends this to controller
        lineWrapper.serialList = new List<Serial__c>();
        lineWrapper.used = false;
        lineWrapper.isCreateRelease = false;
        List<AgreementReleaseExt.LineWrapper> lineWrapperList = new List<AgreementReleaseExt.LineWrapper>();
        lineWrapperList.add(lineWrapper);
        DataSourceResult result = AgreementReleaseExt.createSalesOrders(lineWrapperList, agreement.Id, customerBillTo.Id, customerSoldTo.Id, customerShipTo.Id, null);

        List<Sales_Order_Line__c> sols = [SELECT Id FROM Sales_Order_Line__c];
        system.assertNotEquals(0, sols.size(), Apexpages.getMessages());
        system.assertEquals(2, sols.size(), Apexpages.getMessages()); //Serial enabled, so for 1 wrapper record we should be getting 2 SOLs

        Test.stopTest();

    }

    static testMethod void test_serials(){

        TestFuel fuel = new TestFuel();
       
        Customer__c customerBillTo = fuel.customerBillTo;
        Customer__c customerSoldTo = fuel.customerSoldTo;
        Customer__c customerShipTo = fuel.customerShipto;
        Pricebook__c pricebook = fuel.pricebook;
        Product__c product = fuel.product3;
        Item__c item = fuel.itemList[5];
        
        //Enable serial on Item Attribute
        Item_Attribute__c itemAttr = fuel.itemAttrObj;
        itemAttr.Serial_Number__c = true;
        update itemAttr;

        //Enable serial on Company
        fuel.Company.Serial_Control__c = 'At receipt and shipments';
        update fuel.Company;    

        //Mock the cycle count skid
        Skid__c s = new Skid__c();
        s.Company__c = fuel.Company.id;
        s.Type__c = 'Location';
        //s.Item_Source__c = 'Purchased';
        s.Location__c = fuel.location.id;
        s.Item__c = item.id;
        s.Quantity__c = 2;
        insert s;

        //Create some serials to the skid
        List<Serial__c> serialList = new List<Serial__c>();
        for (integer i=0 ; i<2 ; i++){
            Serial__c s1 = new Serial__c();
            s1.Name = 'Serial'+i;
            s1.Skid__c = s.id;
            s1.Item__c = item.id;
            s1.Company__c = fuel.Company.id;
            serialList.add(s1);
        }
        insert serialList;

        Agreement__c agreement = fuel.agreement;
        Agreement_Line__c agreementLine = fuel.agreementLine;
        agreementLine.Revision_Status__c = null;
        agreementLine.Product__c = product.id;
        agreementLine.Price_Type__c = 'Recurring';
        agreementLine.Pricing_UOM__c = fuel.week.id;
        agreementLine.List_Price__c = 1;
        update agreementLine;

        Test.startTest();
        agreement = [Select Customer__c, Customer__r.RecordType.DeveloperName, Status__c, Currency__c,
                       Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Name, 
                       Customer__r.Parent_Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Parent_Customer__r.Name, 
                       Customer__r.Top_Parent_Customer__c, Customer__r.Top_Parent_Customer__r.Name, Company__r.Serial_Control__c From Agreement__c where id =:fuel.agreement.id limit 1];
        AgreementReleaseExt ext = new AgreementReleaseExt(new Apexpages.Standardcontroller(agreement));
        ext.getSerialsFieldList();
        ext.getSerialsConfigJson();

        JsonResult result_serials = AgreementReleaseExt.getSerials(item.id, false, 'Sales');
        system.assertNotEquals(0, result_serials.records.size(), Apexpages.getMessages());
        system.assertEquals(2, result_serials.records.size(), Apexpages.getMessages()); //Serial enabled, size should be 2 as 2 serials are inserted

        AgreementReleaseExt.LineWrapper lineWrapper = new AgreementReleaseExt.LineWrapper();
        lineWrapper.al = agreementLine;
        lineWrapper.qty = 2; //Lets release qty 2, this should create SO with 2 sales order lines
        lineWrapper.selected = true;
        lineWrapper.isSerialProduct = true; //set this to true and the UI sends this to controller
        lineWrapper.serialList = serialList;
        lineWrapper.used = false;
        lineWrapper.isCreateRelease = false;
        List<AgreementReleaseExt.LineWrapper> lineWrapperList = new List<AgreementReleaseExt.LineWrapper>();
        lineWrapperList.add(lineWrapper);
        DataSourceResult result = AgreementReleaseExt.createSalesOrders(lineWrapperList, agreement.Id, customerBillTo.Id, customerSoldTo.Id, customerShipTo.Id, null);

        List<Sales_Order_Line__c> sols = [SELECT Id FROM Sales_Order_Line__c];
        system.assertNotEquals(0, sols.size(), Apexpages.getMessages());
        system.assertEquals(2, sols.size(), Apexpages.getMessages()); //Serial enabled, so for 1 wrapper record we should be getting 2 SOLs

        Test.stopTest();

    }

}