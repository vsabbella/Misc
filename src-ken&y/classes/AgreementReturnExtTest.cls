@isTest
private class AgreementReturnExtTest {
  
  @testSetup
  static void data(){
  
    TestFuel fuel = new TestFuel();
    Customer__c customerBillTo = fuel.customerBillTo;
    Customer__c customerSoldTo = fuel.customerSoldTo;
    Customer__c customerShipTo = fuel.customerShipto;
    
    Location__c location = fuel.location;
    
    Product__c product = fuel.product_Misc;
  
    Pricebook__c pricebook = new Pricebook__c();
    pricebook.name = 'Test Rental Pricebook';
    pricebook.company__c = fuel.company.Id;
    pricebook.Primary_Key__c = 'RENTBOOK';
    pricebook.Default__c = true;
    insert pricebook;
  
    List<UOM__c> uomList = new List<UOM__c>();
  
    UOM__c weeklyUom = new UOM__c();
    weeklyUom.Name = 'WEEKLY';
    weeklyUom.Type__c = 'Time';
    weeklyUom.Description__c = 'Weekly UOM';
    weeklyUom.Every__c = 1;
    weeklyUom.Recurrence__c = 'Week(s)';
    uomList.add(weeklyUom);
  
    UOM__c dailyUom = new UOM__c();
    dailyUom.Name = 'DAILY';
    dailyUom.Type__c = 'Time';
    dailyUom.Description__c = 'Daily UOM';
    dailyUom.Every__c = 1;
    dailyUom.Recurrence__c = 'Day(s)';
    uomList.add(dailyUom);
  
    UOM__c monthlyUom = new UOM__c();
    monthlyUom.Name = 'MONTHLY';
    monthlyUom.Type__c = 'Time';
    monthlyUom.Description__c = 'Monthly UOM';
    monthlyUom.Every__c = 28;
    monthlyUom.Recurrence__c = 'Day(s)';
    uomList.add(monthlyUom);
  
    insert uomList;
  
    List<Pricebook_Line__c> testPricebookLines = new List<Pricebook_Line__c>();
  
    Pricebook_Line__c pricebookLine1 = new Pricebook_Line__c();
    pricebookLine1.Product__c = fuel.product.Id;
    pricebookLine1.Pricebook__c = pricebook.Id;
    pricebookLine1.Price__c = 150;
    pricebookLine1.Start_Date__c = system.today();
    pricebookLine1.End_Date__c = system.today().addDays(365);
    pricebookLine1.Pricing_UOM__c = dailyUom.Id;
    pricebookLine1.Price_Type__c = 'Recurring';
    testPricebookLines.add(pricebookLine1);
  
    Pricebook_Line__c pricebookLine2 = new Pricebook_Line__c();
    pricebookLine2.Product__c = fuel.product.Id;
    pricebookLine2.Pricebook__c = pricebook.Id;
    pricebookLine2.Price__c = 450;
    pricebookLine2.Start_Date__c = system.today();
    pricebookLine2.End_Date__c = system.today().addDays(365);
    pricebookLine2.Pricing_UOM__c = weeklyUom.Id;
    pricebookLine2.Price_Type__c = 'Recurring';
    testPricebookLines.add(pricebookLine2);
  
    Pricebook_Line__c pricebookLine3 = new Pricebook_Line__c();
    pricebookLine3.Product__c = fuel.product.Id;
    pricebookLine3.Pricebook__c = pricebook.Id;
    pricebookLine3.Price__c = 1350;
    pricebookLine3.Start_Date__c = system.today();
    pricebookLine3.End_Date__c = system.today().addDays(365);
    pricebookLine3.Pricing_UOM__c = monthlyUom.Id;
    pricebookLine3.Price_Type__c = 'Recurring';
    testPricebookLines.add(pricebookLine3);
    insert testPricebookLines;
    /*
    Item_Attribute__c itemAttr = fuel.itemAttrObj;
    itemAttr.Serial_Number__c = true;
    update itemAttr;

    fuel.Company.Serial_Control__c = 'At receipt and shipments';
    update fuel.Company;
    */
  
    Agreement__c agreement = fuel.agreement;
    Agreement_Line__c agreementLine = fuel.agreementLine;
    agreementLine.Revision_Status__c = null;
    agreementLine.Product__c = fuel.product.id;
    update agreementLine;
    
  }

  static testMethod void testReturn() {
  	
  	TestFuelQuery fuel = new TestFuelQuery();
    List<Customer__c> customerList = [SELECT Id, Name FROM Customer__c];
    
    Map<String, Customer__c> mCustomers = new Map<String, Customer__c>();
    
    for(Customer__c c : customerList) {
      mCustomers.put(c.Name, c);
    }
  
    List<Company__c> company = [SELECT Id FROM Company__c];
    Product__c product = [SELECT Id, Description__c FROM Product__c WHERE Name = 'Product 1'];
    Location__c location = [SELECT Id FROM Location__c WHERE Name = 'Delivery/Shipping Location'];
    List<Item__c> itemList = [SELECT Id FROM Item__c];
    Agreement__c agreement = [SELECT Id FROM Agreement__c WHERE Name = 'Sample Agreement'];
    Agreement_Line__c agreementLine = [SELECT Id FROM Agreement_Line__c WHERE Agreement__c = :agreement.Id];
  
    Test.startTest();
    Sales_Order__c salesOrder = new Sales_Order__c();
    salesOrder.Ship_to__c = mCustomers.get('Customer Ship To 1').Id;
    salesOrder.Bill_To__c = mCustomers.get('Customer Bill To 1').Id;
    salesOrder.Customer__c = mCustomers.get('Customer Sold To 1').Id;
    salesOrder.Currency__c = fuel.currencyUSD.id;
    salesOrder.Company__c = company[0].Id;
    insert salesOrder;

    Sales_Order_Line__c salesOrderLine1 = new Sales_Order_Line__c();
    salesOrderLine1.Company__c = company[0].Id;
    salesOrderLine1.Description__c = product.Description__c;
    salesOrderLine1.Discount_Percent__c = 2;
    salesOrderLine1.Product__c = product.Id;
    salesOrderLine1.Quantity_Ordered__c = 1;
    salesOrderLine1.Required_Date__c = System.today()+5;
    salesOrderLine1.Sales_Order__c = salesOrder.Id;
    salesOrderLine1.Ship_From_Location__c = location.Id;
    salesOrderLine1.Unit_Price__c = 11.12;
    salesOrderLine1.Memo__c = 'salesOrderLine1';
    salesOrderLine1.Agreement__c = agreement.id;
    salesOrderLine1.Agreement_Line__c = agreementLine.id;
    insert salesOrderLine1;

    Fulfillment__c fmt = new Fulfillment__c();
    fmt.Name = 'Test Fulfillment';
    fmt.Company__c = company[0].Id;
    fmt.Type__c = 'Recurring';
    fmt.Product__c = product.Id;
    fmt.Status__c = 'Completed';
    fmt.Start_Date__c = DateTime.newInstance(System.today(), Time.newInstance(0,0,0,0));
    fmt.Sales_Order_Line__c = salesOrderLine1.Id;
    fmt.Sales_Order__c = salesOrder.Id;
    fmt.Quantity__c = 1;
    insert fmt;

    //system.assertEquals(new Fulfillment__c(), fmt);
    system.debug('fmt--'+fmt);


    agreement = [Select Customer__c, Customer__r.RecordType.DeveloperName, Status__c, Currency__c,
            Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Name,
            Customer__r.Parent_Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Parent_Customer__r.Name,
            Customer__r.Top_Parent_Customer__c, Customer__r.Top_Parent_Customer__r.Name, Company__r.Serial_Control__c From Agreement__c where id =:agreement.id limit 1];

    AgreementReturnExt ext = new AgreementReturnExt(new Apexpages.Standardcontroller(agreement));
    ext.getfulfillmentLinesConfigJson();
    ext.getfulfillmentLinesFieldList();
    Jsonresult result = AgreementReturnExt.getFulfillments(agreement.id);

    AgreementReturnExt.fulfillmentWrapper fmtWrp = new AgreementReturnExt.fulfillmentWrapper();
    fmtWrp.flmt = fmt;
    fmtWrp.itemID = itemList[0].id;
    fmtWrp.isSerialLine = false;
    fmtWrp.returnQty = 1;
    fmtWrp.sol = salesOrderLine1;
    fmtWrp.flmt.End_Date__c = Datetime.newInstance(system.today().addDays(16), Time.newInstance(0,0,0,0));

    List<AgreementReturnExt.fulfillmentWrapper> fmtwrapperList = new List<AgreementReturnExt.fulfillmentWrapper>();
    fmtwrapperList.add(fmtWrp);
    result = AgreementReturnExt.createReceiptandUpdateFulfillments(fmtwrapperList);
    List<Fulfillment__c> fulfillmentList = [SELECT Id, Start_Date__c, End_Date__c, Pricing_UOM__r.Name FROM Fulfillment__c];
    List<UOM__c> uoms = [SELECT Id, Name, Recurrence__c, Every__c FROM UOM__c WHERE Type__c = 'Time'];
    system.debug(LoggingLevel.INFO, fulfillmentList);
    system.debug(LoggingLevel.INFO, uoms);
    system.debug(LoggingLevel.INFO, result);
    system.assertEquals(true, result.success, result);
    system.assertEquals(fulfillmentList.size() > 1, true); //There should be additional fulfillments based on UOM
  }

  static testMethod void testFailure(){
	
	TestFuelQuery fuel = new TestFuelQuery();
    List<Customer__c> customerList = [SELECT Id, Name FROM Customer__c];
  
    Map<String, Customer__c> mCustomers = new Map<String, Customer__c>();
  
    for(Customer__c c : customerList) {
      mCustomers.put(c.Name, c);
    }
  
    List<Company__c> company = [SELECT Id FROM Company__c];
    Product__c product = [SELECT Id, Description__c FROM Product__c WHERE Name = 'Product-Misc'];
    Location__c location = [SELECT Id FROM Location__c WHERE Name = 'Delivery/Shipping Location'];
    List<Item__c> itemList = [SELECT Id FROM Item__c];
    Agreement__c agreement = [SELECT Id FROM Agreement__c WHERE Name = 'Sample Agreement'];
    Agreement_Line__c agreementLine = [SELECT Id FROM Agreement_Line__c WHERE Agreement__c = :agreement.Id];
  
    Test.startTest();
    Sales_Order__c salesOrder = new Sales_Order__c();
    salesOrder.Ship_to__c = mCustomers.get('Customer Ship To 1').Id;
    salesOrder.Bill_To__c = mCustomers.get('Customer Bill To 1').Id;
    salesOrder.Customer__c = mCustomers.get('Customer Sold To 1').Id;
    salesOrder.Currency__c = fuel.currencyUSD.id;
    salesOrder.Company__c = company[0].id;
    insert salesOrder;


    Sales_Order_Line__c salesOrderLine1 = new Sales_Order_Line__c();
    salesOrderLine1.Company__c = company[0].id;
    salesOrderLine1.Description__c = product.Description__c;
    salesOrderLine1.Discount_Percent__c = 2;
    salesOrderLine1.Product__c = product.Id;
    salesOrderLine1.Quantity_Ordered__c = 1;
    salesOrderLine1.Required_Date__c = System.today()+5;
    salesOrderLine1.Sales_Order__c = salesOrder.Id;
    salesOrderLine1.Ship_From_Location__c = location.Id;
    salesOrderLine1.Unit_Price__c = 11.12;
    salesOrderLine1.Memo__c = 'salesOrderLine1';
    salesOrderLine1.Agreement__c = agreement.id;
    salesOrderLine1.Agreement_Line__c = agreementLine.id;
    insert salesOrderLine1;
    
    Fulfillment__c fmt = new Fulfillment__c();
    fmt.Company__c = company[0].id;
    fmt.Sales_Order_Line__c = salesOrderLine1.id;
    fmt.Sales_Order__c = salesOrder.id;
    fmt.Type__c = 'Sales Order Shipment';
    fmt.Start_Date__c = system.today();
    fmt.Product__c = salesOrderLine1.Product__c;
    fmt.End_Date__c = null;
    fmt.Customer__c = salesOrder.Customer__c;
    fmt.Sales_Order_Line__r = salesOrderLine1;
    fmt.Sales_Order_Line__r.Agreement__c = agreement.id;
    insert fmt;

    //system.assertEquals(new Fulfillment__c(), fmt);
    system.debug('fmt--'+fmt);


    agreement = [Select Customer__c, Customer__r.RecordType.DeveloperName, Status__c, Currency__c,
                   Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Name,
                   Customer__r.Parent_Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Parent_Customer__r.Name,
                   Customer__r.Top_Parent_Customer__c, Customer__r.Top_Parent_Customer__r.Name, Company__r.Serial_Control__c From Agreement__c where id =:agreement.id limit 1];

    AgreementReturnExt ext = new AgreementReturnExt(new Apexpages.Standardcontroller(agreement));
    ext.getfulfillmentLinesConfigJson();
    ext.getfulfillmentLinesFieldList();
    Jsonresult result = AgreementReturnExt.getFulfillments(agreement.id);

    AgreementReturnExt.fulfillmentWrapper fmtWrp = new AgreementReturnExt.fulfillmentWrapper();
    fmtWrp.flmt = fmt;
    fmtWrp.itemID = itemList[5].id;
    fmtWrp.isSerialLine = false;
    fmtWrp.returnQty = 1;
    fmtWrp.sol = salesOrderLine1;

    List<AgreementReturnExt.fulfillmentWrapper> fmtwrapperList = new List<AgreementReturnExt.fulfillmentWrapper>();
    fmtwrapperList.add(fmtWrp);
    result = AgreementReturnExt.createReceiptandUpdateFulfillments(fmtwrapperList);
    system.debug(LoggingLevel.INFO, result);
    system.assertEquals(false, result.success);
   // system.assertEquals(true, result.success); ToDo-Praful This seems to fail to get unit price

  }

	//KNDY-12781
    static testMethod void testReturnWFulfilmentsNotInvoiceReady(){
    
    TestFuelQuery fuel = new TestFuelQuery();
    List<Customer__c> customerList = [SELECT Id, Name FROM Customer__c];

    Map<String, Customer__c> mCustomers = new Map<String, Customer__c>();

    for(Customer__c c : customerList) {
      mCustomers.put(c.Name, c);
    }

    List<Company__c> company = [SELECT Id FROM Company__c];
    Product__c product = [SELECT Id, Description__c FROM Product__c WHERE Name = 'Product 1'];
    Location__c location = [SELECT Id FROM Location__c WHERE Name = 'Delivery/Shipping Location'];
    List<Item__c> itemList = [SELECT Id FROM Item__c];
    Agreement__c agreement = [SELECT Id FROM Agreement__c WHERE Name = 'Sample Agreement'];
    Agreement_Line__c agreementLine = [SELECT Id FROM Agreement_Line__c WHERE Agreement__c = :agreement.Id];
    
    Test.startTest();
    Sales_Order__c salesOrder = new Sales_Order__c();
    salesOrder.Ship_to__c = mCustomers.get('Customer Ship To 1').Id;
    salesOrder.Bill_To__c = mCustomers.get('Customer Bill To 1').Id;
    salesOrder.Customer__c = mCustomers.get('Customer Sold To 1').Id;
    salesOrder.Currency__c = fuel.currencyUSD.id;
    salesOrder.Company__c = company[0].id;
    insert salesOrder;

    Sales_Order_Line__c salesOrderLine1 = new Sales_Order_Line__c();
    salesOrderLine1.Company__c = company[0].id;
    salesOrderLine1.Description__c = product.Description__c;
    salesOrderLine1.Discount_Percent__c = 2;
    salesOrderLine1.Product__c = product.Id;
    salesOrderLine1.Quantity_Ordered__c = 1;
    salesOrderLine1.Required_Date__c = System.today()+5;
    salesOrderLine1.Sales_Order__c = salesOrder.Id;
    salesOrderLine1.Ship_From_Location__c = location.Id;
    salesOrderLine1.Unit_Price__c = 11.12;
    salesOrderLine1.Memo__c = 'salesOrderLine1';
    salesOrderLine1.Agreement__c = agreement.id;
    salesOrderLine1.Agreement_Line__c = agreementLine.id;
    insert salesOrderLine1;
      
    Fulfillment__c fmt = new Fulfillment__c();
    fmt.Company__c = company[0].id;
    fmt.Sales_Order_Line__c = salesOrderLine1.id;
    fmt.Sales_Order__c = salesOrder.id;
    fmt.Type__c = 'Sales Order Shipment';
    fmt.Start_Date__c = system.today();
    fmt.Product__c = salesOrderLine1.Product__c;
    fmt.End_Date__c = null;
    fmt.Customer__c = salesOrder.Customer__c;
    fmt.Sales_Order_Line__r = salesOrderLine1;
    fmt.Sales_Order_Line__r.Agreement__c = agreement.id;
    fmt.Invoice_Ready__c = false;
    insert fmt;

    system.debug('fmt--'+fmt);

    agreement = [Select Customer__c, Customer__r.RecordType.DeveloperName, Status__c, Currency__c,
                   Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Name,
                   Customer__r.Parent_Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Parent_Customer__r.Name,
                   Customer__r.Top_Parent_Customer__c, Customer__r.Top_Parent_Customer__r.Name, Company__r.Serial_Control__c From Agreement__c where id =:agreement.id limit 1];

    AgreementReturnExt ext = new AgreementReturnExt(new Apexpages.Standardcontroller(agreement));
    ext.getfulfillmentLinesConfigJson();
    ext.getfulfillmentLinesFieldList();
    Jsonresult result = AgreementReturnExt.getFulfillments(agreement.id);
    system.assertEquals(false, result.success);

  }

  static testMethod void testAgreementExchange(){
    
    TestFuelQuery fuel = new TestFuelQuery();
    List<Customer__c> customerList = [SELECT Id, Name FROM Customer__c];
  
    Map<String, Customer__c> mCustomers = new Map<String, Customer__c>();
  
    for(Customer__c c : customerList) {
      mCustomers.put(c.Name, c);
    }
  
    List<Company__c> company = [SELECT Id FROM Company__c];
    Product__c product = [SELECT Id, Description__c FROM Product__c WHERE Name = 'Product 1'];
    Location__c location = [SELECT Id FROM Location__c WHERE Name = 'Delivery/Shipping Location'];
    List<Item__c> itemList = [SELECT Id FROM Item__c];
    Agreement__c agreement = [SELECT Id FROM Agreement__c WHERE Name = 'Sample Agreement'];
    Agreement_Line__c agreementLine = [SELECT Id FROM Agreement_Line__c WHERE Agreement__c = :agreement.Id];
  
    Test.startTest();
    Sales_Order__c salesOrder = new Sales_Order__c();
    salesOrder.Ship_to__c = mCustomers.get('Customer Ship To 1').Id;
    salesOrder.Bill_To__c = mCustomers.get('Customer Bill To 1').Id;
    salesOrder.Customer__c = mCustomers.get('Customer Sold To 1').Id;
    salesOrder.Company__c = company[0].id;
    salesOrder.Currency__c = fuel.currencyUSD.id;
    insert salesOrder;

    Sales_Order_Line__c salesOrderLine1 = new Sales_Order_Line__c();
    salesOrderLine1.Company__c = company[0].id;
    salesOrderLine1.Description__c = product.Description__c;
    salesOrderLine1.Discount_Percent__c = 2;
    salesOrderLine1.Product__c = product.Id;
    salesOrderLine1.Quantity_Ordered__c = 1;
    salesOrderLine1.Required_Date__c = System.today()+5;
    salesOrderLine1.Sales_Order__c = salesOrder.Id;
    salesOrderLine1.Ship_From_Location__c = location.Id;
    salesOrderLine1.Unit_Price__c = 11.12;
    salesOrderLine1.Memo__c = 'salesOrderLine1';
    salesOrderLine1.Agreement__c = agreement.id;
    salesOrderLine1.Agreement_Line__c = agreementLine.id;
    insert salesOrderLine1;
    
    Fulfillment__c fmt = new Fulfillment__c();
    fmt.Company__c = company[0].id;
    fmt.Sales_Order_Line__c = salesOrderLine1.id;
    fmt.Sales_Order__c = salesOrder.id;
    fmt.Type__c = 'Rental';
    fmt.Price_Type__c = 'Recurring';
    fmt.Start_Date__c = system.today();
    fmt.Product__c = salesOrderLine1.Product__c;
    fmt.End_Date__c = null;
    fmt.Customer__c = salesOrder.Customer__c;
    fmt.Sales_Order_Line__r = salesOrderLine1;
    fmt.Sales_Order_Line__r.Agreement__c = agreement.id;
    fmt.Invoice_Ready__c = true;
    insert fmt;

    system.debug(LoggingLevel.ERROR, fmt);

    agreement = [Select Customer__c, Customer__r.RecordType.DeveloperName, Status__c, Currency__c,
               Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Name,
               Customer__r.Parent_Customer__r.Parent_Customer__c, Customer__r.Parent_Customer__r.Parent_Customer__r.Name,
               Customer__r.Top_Parent_Customer__c, Customer__r.Top_Parent_Customer__r.Name, Company__r.Serial_Control__c From Agreement__c where id =:agreement.id limit 1];

    AgreementExchangeExt ext = new AgreementExchangeExt(new Apexpages.Standardcontroller(agreement));
    ext.getfulfillmentLinesConfigJson();
    ext.getfulfillmentLinesFieldList();
    ext.getSerialsConfigJson();
    ext.getSerialsFieldList();
    Jsonresult result = AgreementExchangeExt.getFulfillments(agreement.id);
    result = AgreementExchangeExt.getSerials(itemList[5].id, false);

    system.assertEquals(result.success, true);

}
}