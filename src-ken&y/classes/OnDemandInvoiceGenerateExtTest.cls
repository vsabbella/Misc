@isTest
private class OnDemandInvoiceGenerateExtTest {
    
    @testSetup static void ts() { 
        TestFuel data = new TestFuel(); 
        // these asserts cause TestFuelQuery to insert data
        system.assert(      
            data.company != null && 
            data.salesOrder != null && 
            data.salesOrderLines != null &&
            data.terms != null &&
            data.customerBillTo != null &&
            data.agreement != null &&
            data.agreementLine != null &&
            data.customerParent != null &&
            data.WEEK != null && 
            data.CALENDAR_QUARTER != null && 
            data.customerSoldTo != null &&
            data.product != null &&
            data.customerSite != null 
        );
    }
    
    static testMethod void testUtilityMethods() {

    	TestFuelQuery fuel = new TestFuelQuery();
    	User_Preference__c up = new User_Preference__c();
        up.Default_Company__c = fuel.company.id;
        up.ownerID = UserInfo.getUserID();
        insert up;
        
        OnDemandInvoiceGenerateExt ext = new OnDemandInvoiceGenerateExt(new ApexPages.StandardSetController(new list<Fulfillment__c>()));
        system.assert(ext.defaultCompany == fuel.company.Id, 'default company is not the same');
        
        ext.getinvoiceHoldGridConfigJson();
        ext.getreleaseHoldGridConfigJson();
        ext.getReturnUrl();
        ext.getinvoiceHoldFieldList();
        ext.getreleaseHoldFieldList();
        ext.getRuleGroupingFieldList();
        
        String objectName = 'Fulfillment__c';
        String fieldSetName = 'InvoicingAndHold';
        
        List<FieldInfo> fieldInfoList = OnDemandInvoiceGenerateExt.fetchJsonFieldInfosWithReferenceToObectTitle(objectName, fieldSetName);
        for(FieldInfo fi : fieldInfoList){
            if(fi.field.contains('Sales_Order_Line__r')){
                system.assert(fi.title.contains('Sales Order Line'), 'title of the referencing field object is not correct');
            }
        }
    }
    
    static testMethod void getFulfillmentsForHold() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        Test.startTest();
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c ='Complete'));

        insert lFs;
        
        OnDemandInvoiceGenerateExt ext = new OnDemandInvoiceGenerateExt(new ApexPages.StandardSetController(new list<Fulfillment__c>()));
        
        JsonResult result = OnDemandInvoiceGenerateExt.getFulfillments(fuel.company.Id, new list<Id>{}, new list<Id>{}, new list<Id>{fuel.salesOrder.Id}, new list<Id>{},new list<Id>{}, new list<Id>{});
        system.assertEquals(true, result.success, result.messages);
        system.assertEquals(1, result.records.size()); 
        Test.stopTest();
    }
    
    static testMethod void getFulfillmentsForHold_ShowZero() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        Test.startTest();
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c));
        insert lFs;
        
        OnDemandInvoiceGenerateExt ext = new OnDemandInvoiceGenerateExt(new ApexPages.StandardSetController(new list<Fulfillment__c>()));
        
        JsonResult result = OnDemandInvoiceGenerateExt.getFulfillments(fuel.company.Id, new list<Id>{fuel.customerBillTo.Id}, new list<Id>{}, new list<Id>{fuel.salesOrder.Id}, new list<Id>{},new list<Id>{}, new list<Id>{});
        system.assertEquals(true, result.success, result.messages);
        system.assertEquals(0, result.records.size()); 
        Test.stopTest();
        
    }
    
    static testMethod void putFulfillmentsOnHold() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        Test.startTest();
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c));
        insert lFs;
        Reason_Code__c holdCode = new Reason_Code__c();
        holdCode.Company__c = fuel.company.Id;
        holdCode.Type__c = 'Invoice Hold';
        holdCode.Code__c = 'D001';
        insert holdCode;
        OnDemandInvoiceGenerateExt ext = new OnDemandInvoiceGenerateExt(new ApexPages.StandardSetController(new list<Fulfillment__c>()));
        
        JsonResult result = OnDemandInvoiceGenerateExt.putOnHold(lFs, holdCode.Id,new  list<String> {'Fulfillment_Date__c'});
        system.assertEquals(true, result.success, result.messages);
        boolean foundRecords = false;
        lFs = [Select Id, Invoice_Hold__c, Reason_Code__c from Fulfillment__c where Id in :lFs and Invoice_Hold__c = true and Reason_Code__c = :holdCode.Id];
        system.assertEquals(1, lFs.size()); 
        Test.stopTest();
        
    }
    
    static testMethod void getFulfillmentsForRelease() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	Reason_Code__c holdCode = new Reason_Code__c();
        holdCode.Company__c = fuel.company.Id;
        holdCode.Type__c = 'Invoice Hold';
        holdCode.Code__c = 'D001';
        insert holdCode;
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        Test.startTest();
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true,Invoice_Hold__c = true, Reason_Code__c = holdCode.Id, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c));
        insert lFs;
        OnDemandInvoiceGenerateExt ext = new OnDemandInvoiceGenerateExt(new ApexPages.StandardSetController(new list<Fulfillment__c>()));
        
        JsonResult result = OnDemandInvoiceGenerateExt.getFulfillmentsForRelease(fuel.company.Id, new list<Id>{}, new list<Id>{}, new list<Id>{fuel.salesOrder.Id}, new list<Id>{},new list<Id>{}, new list<Id>{});
        system.assertEquals(true, result.success, result.messages);
        system.assertEquals(1, result.records.size()); 
        Test.stopTest();
        
    }
    
    static testMethod void releaseHold() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	Reason_Code__c holdCode = new Reason_Code__c();
        holdCode.Company__c = fuel.company.Id;
        holdCode.Type__c = 'Invoice Hold';
        holdCode.Code__c = 'D001';
        insert holdCode;
        
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        Test.startTest();
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c( Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true,Invoice_Hold__c = true,Reason_Code__c = holdCode.Id, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c));
        insert lFs;
        OnDemandInvoiceGenerateExt ext = new OnDemandInvoiceGenerateExt(new ApexPages.StandardSetController(new list<Fulfillment__c>()));
        
        JsonResult result = OnDemandInvoiceGenerateExt.releaseHold(lFs,new  list<String> {'Fulfillment_Date__c'});
        system.assertEquals(true, result.success, result.messages);
        system.assertEquals(1, result.records.size()); 
        lFs = [Select Id, Invoice_Hold__c, Reason_Code__c from Fulfillment__c where Id in :lFs and Invoice_Hold__c = false and Reason_Code__c = null];
        system.assertEquals(1, lFs.size()); 
        Test.stopTest();
    }
    
    static testMethod void createOneInvoice() {
        TestFuelQuery fuel = new TestFuelQuery();
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        Test.startTest();
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerSite.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));

        insert lFs;
        
        Fulfillment__c f = [select id, Customer__c from Fulfillment__c where Id  = :lFs[0].Id limit 1];
        system.assertEquals(fuel.customerSite.Id,f.Customer__c);
        
        ApexPages.standardSetController con = new ApexPages.standardSetController(lFs);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        
        JsonResult jr = GenerateInvoiceExt.nextOnProcessFulfillment(false,lFs, null);
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
        system.assert(jr.success == null);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        boolean fromProcessFulFilment = true;
        jr = GenerateInvoiceExt.finalizeInvoices(null, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        boolean ErrorExists = false; 
        jr = GenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>)jr.records);
        system.assert(jr.success);
        for(Map<String, String> msg :jr.messages){
            if(msg.containsKey('message')){
                if(msg.get('message').contains('has been created and finalized.')){
                    ErrorExists = true;
                    break;
                }
            }
        }
        system.assert(ErrorExists);
        
        Test.stopTest();
        
    }
    
    static testMethod void createOneInvoice_RecurringOn31() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	system.assertNotEquals(null,fuel.salesOrder.Id);
    	
    	UOM__c CALENDAR_MONTH = new UOM__c(Name = 'Calendar Month', Type__c = 'Time', Every__c = 1, Recurrence__c = 'Month(s)');
        insert CALENDAR_MONTH;
        
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        Test.startTest();
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerSite.Id, Start_Date__c = DateTime.newInstance(2015,5,31,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              End_Date__c = DateTime.newInstance(2015,8,31,0,0,0),  Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Recurring', Status__c = 'Complete', Pricing_UOM__c = CALENDAR_MONTH.ID));

        insert lFs;
        
        Fulfillment__c f = [select id, Customer__c from Fulfillment__c where Id  = :lFs[0].Id limit 1];
        system.assertEquals(fuel.customerSite.Id,f.Customer__c);
        
        ApexPages.standardSetController con = new ApexPages.standardSetController(lFs);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        
        JsonResult jr = GenerateInvoiceExt.nextOnProcessFulfillment(false,lFs, null);
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        
        list<Customer_Invoice__c> lCI = (list<Customer_Invoice__c>)jr.records;
        list<Customer_Invoice_Line__c> lCILs = [Select Id, Extended_Price__c, Start_Date__c, End_Date__c from Customer_Invoice_line__c where Customer_Invoice__c in :lCI order by Start_Date__c ASC];
        system.assertEquals(3, lCILs.size());
        for(Customer_Invoice_Line__c cil : lCILs) {
        	system.assertEquals(98, cil.Extended_Price__c);
        } 
        
        jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
        system.assert(jr.success == null);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        boolean fromProcessFulFilment = true;
        jr = GenerateInvoiceExt.finalizeInvoices(null, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        boolean ErrorExists = false; 
        jr = GenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>)jr.records);
        system.assert(jr.success);
        for(Map<String, String> msg :jr.messages){
            if(msg.containsKey('message')){
                if(msg.get('message').contains('has been created and finalized.')){
                    ErrorExists = true;
                    break;
                }
            }
        }
        system.assert(ErrorExists);
        
        Test.stopTest();
        
    }
    
    static testMethod void shouldCreateOneInvoice() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        Test.startTest();
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));

        insert lFs;
        
        ApexPages.standardSetController con = new ApexPages.standardSetController(lFs);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        
        JsonResult jr = GenerateInvoiceExt.nextOnProcessFulfillment(false,lFs, null);
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        system.assertEquals(true, jr.success, jr.messages);
        
        Test.stopTest();
        
    }
    
     static testMethod void shouldCreateOneInvoiceandValidateDesc() { //KNDY-12605
    	TestFuelQuery fuel = new TestFuelQuery();
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        Test.startTest();
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        system.assertEquals(2,lSOLs.size());
        lSOLs[0].Description__c = 'Testing description update';
        update lSOLs[0];
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerSite.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));

        insert lFs;
        
        Fulfillment__c f = [select id, Customer__c from Fulfillment__c where Id  = :lFs[0].Id limit 1];
        system.assertEquals(fuel.customerSite.Id,f.Customer__c);
        
        ApexPages.standardSetController con = new ApexPages.standardSetController(lFs);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        
        JsonResult jr = GenerateInvoiceExt.nextOnProcessFulfillment(false,lFs, null);
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        Id CIId = ((Customer_Invoice__c)jr.records[0]).Id;
    	list<Customer_Invoice_Line__c> lstCIL = [Select Description__c from Customer_Invoice_Line__c where Customer_Invoice__c =:CIId ];
        system.assertEquals('Testing description update', lstCIL[0].Description__c, 'Description value doesnt match');
        Test.stopTest();  
    }
    
     static testMethod void shouldCreatetwoInvoiceForDymanicIgr() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        Test.startTest();
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyGBP.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete')); 
        insert lFs;
        

		list<Invoice_Grouping_Rule__c> lstIgr = new list<Invoice_Grouping_Rule__c>();
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c();
        igr.Group_By_Sales_Orders__c = true;
        igr.Group_By_Customer_Hierarchy__c = 'Bill to';
        lstIgr.add(igr);
        
        ApexPages.standardSetController con = new ApexPages.standardSetController(lFs);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        
        
        JsonResult result = OnDemandInvoiceGenerateExt.validateIGR(lstIgr[0]);
        system.assertEquals(false, result.success, result.messages);
    	
        JsonResult jr = GenerateInvoiceExt.nextOnProcessFulfillment(false, lFs, lstIgr);
        system.assert(jr.success == null);
        System.debug(logginglevel.error,'jr-->'+jr);
        System.debug(logginglevel.error,'jr.messages--->'+jr.messages);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        jr  = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size()); // 2 invoices created
    	
        Test.stopTest();
    }
    
    static testMethod void DuplicateIgrs_NeglectOneIgr_createInvoices(){
        TestFuelQuery fuel = new TestFuelQuery();
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        Test.startTest();
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyGBP.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete')); 

        insert lFs;
        
        Invoice_grouping_rule__c igr= new Invoice_grouping_rule__c();
        igr.Company__c =fuel.company.id;
        igr.Start_Date__c =system.today()-100;
        igr.Group_By_Sales_Orders__c = true;
        igr.Group_By_Sales_Order_Types__c = true;
        igr.Group_By_Customer_Hierarchy__c = 'Bill to';
        insert igr;
        
        list<Invoice_Grouping_Rule__c> lstIgr = new list<Invoice_Grouping_Rule__c>();
        Invoice_Grouping_Rule__c igrule = new Invoice_Grouping_Rule__c();
        igrule.Company__c = fuel.company.id;
        igrule.Group_By_Sales_Orders__c = true;
        igrule.Group_By_Sales_Order_Types__c = true;
        igrule.Group_By_Customer_Hierarchy__c = 'Bill to';
        lstIgr.add(igrule);
        
        ApexPages.standardSetController con = new ApexPages.standardSetController(lFs);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        
        JsonResult igrResult = OnDemandInvoiceGenerateExt.validateIGR(lstIgr[0]);
        system.assert(igrResult.success == false);
        
        JsonResult jr = GenerateInvoiceExt.nextOnProcessFulfillment(false, lFs, lstIgr);
        system.assert(jr.success == null);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size());
        
        Test.stopTest();   
        
    }
    
    static testMethod void shouldAskfortwoInvoice_MultipleProduct() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        Test.startTest();
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[1].Id,
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[1].Product__c, Status__c = 'Complete')); 

        insert lFs;
        
		list<Invoice_Grouping_Rule__c> lstIgr = new list<Invoice_Grouping_Rule__c>();
        Invoice_Grouping_Rule__c igrule = new Invoice_Grouping_Rule__c();
        igrule.Company__c = fuel.company.id;
        igrule.Group_By_Product__c = true;
        igrule.Group_By_Customer_Hierarchy__c = 'Corporate Parent';
        lstIgr.add(igrule);
		
    	ApexPages.standardSetController con = new ApexPages.standardSetController(lFs);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        
        JsonResult igrResult = OnDemandInvoiceGenerateExt.validateIGR(lstIgr[0]);
        system.assert(igrResult.success == false);
        
        JsonResult jr = GenerateInvoiceExt.nextOnProcessFulfillment(false, lFs, lstIgr);
        system.assert(jr.success == null);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size()); // Invoice per product created
        System.debug(logginglevel.error,jr.messages);
        
    	Test.stopTest();
    }
    
    static testMethod void shouldAskfortwoInvoice_MultipleShipment() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c, Product__r.Item__c, Quantity_Ordered__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        Test.startTest();
        Shipment__c sh = new Shipment__c(Company__c = fuel.company.Id, Customer__c = fuel.customerShipTo.Id, Status__c = 'Staged', Type__c = 'Sales Order Shipment');
        insert sh;
        Shipment_Line__c shl = new Shipment_Line__c(Shipment__c = sh.Id, Sales_Order_Line__c = lSOLs[0].Id, Item__c = lSOLs[0].Product__r.Item__c, Product__c = lSOLs[0].Product__c, Company__c = fuel.company.Id, Quantity_Planned__c = lSOLs[0].Quantity_Ordered__c, Quantity_Allocated__c = 0, Quantity_To_Pick__c = 0, Quantity_Picked__c = 0, Quantity_Shipped__c = lSOLs[0].Quantity_Ordered__c);
        insert shl;
        
        Shipment__c sh1 = new Shipment__c(Company__c = fuel.company.Id, Customer__c = fuel.customerShipTo.Id, Status__c = 'Staged', Type__c = 'Sales Order Shipment');
        insert sh1;
        Shipment_Line__c shl1 = new Shipment_Line__c(Shipment__c = sh1.Id, Sales_Order_Line__c = lSOLs[1].Id, Item__c = lSOLs[1].Product__r.Item__c, Product__c = lSOLs[1].Product__c, Company__c = fuel.company.Id, Quantity_Planned__c = lSOLs[1].Quantity_Ordered__c, Quantity_Allocated__c = 0, Quantity_To_Pick__c = 0, Quantity_Picked__c = 0, Quantity_Shipped__c = lSOLs[1].Quantity_Ordered__c);
        insert shl1;
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id, Customer__c = fuel.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Shipment_Line__c = shl.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id, Customer__c = fuel.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Shipment_Line__c = shl1.Id, Sales_Order_Line__c = lSOLs[1].Id, 
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[1].Product__c, Status__c = 'Complete'));

        insert lFs;
        
		list<Invoice_Grouping_Rule__c> lstIgr = new list<Invoice_Grouping_Rule__c>();
        Invoice_Grouping_Rule__c igrule = new Invoice_Grouping_Rule__c();
        igrule.Company__c = fuel.company.id;
        igrule.Group_By_Product__c = true;
        igrule.Group_By_Customer_Hierarchy__c = 'Corporate Parent';
        lstIgr.add(igrule);
		
        ApexPages.standardSetController con = new ApexPages.standardSetController(lFs);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        
        JsonResult igrResult = OnDemandInvoiceGenerateExt.validateIGR(lstIgr[0]);
        system.assert(igrResult.success == false);
        
        JsonResult jr = GenerateInvoiceExt.nextOnProcessFulfillment(false, lFs, lstIgr);
        system.assert(jr.success == null);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size()); // Invoice per shippment created
        System.debug(logginglevel.error,jr.messages);
        
    	Test.stopTest();
    }
    static testMethod void validate_FlDoesnthaveStartDate() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        Test.startTest();
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order__c = fuel.salesOrder.Id, 
                                    Type__c = 'Recurring', Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete', Sales_Order_Line__c = lSOLs[0].Id, Price_Type__c = 'Recurring'));

        insert lFs;
        
    	ApexPages.standardSetController con = new ApexPages.standardSetController(lFs);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        
        JsonResult jr = GenerateInvoiceExt.nextOnProcessFulfillment(false, lFs, null);
        System.debug(logginglevel.error,jr);
        System.debug(logginglevel.error,jr.records);
        system.assert(jr.success == false);
        system.assertEquals(null, jr.records);
        
       	boolean ErrorExists = false;
        for(map<String,String> message : jr.messages) {
    		System.debug('message'+message.get('message'));
    		if(message.get('message').contains('Fulfillment doesnt have start date')) {
    			ErrorExists = true;
    			break;
    		}
    	}
        system.assertEquals(true, ErrorExists, jr.messages);
        Test.stopTest();
    }
    static testMethod void validate_FlGrBySONotMatch() {
    	
    	TestFuelQuery fuel = new TestFuelQuery();
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        Test.startTest();
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        Payment_Term__c terms = new Payment_Term__c(); 
        terms.name = 'PT 2'; 
        terms.Description__c = '2% discount in 10 days, due 30 days';
        terms.Type__c = KSE.PAYMENT_TERM_DUE_DAYS; //AR-3 need to define type on Payment Terms. 
        terms.Discount_Days__c = 20;
        terms.Discount_Percent__c = 2;
        terms.Due_Days__c = 30;
        insert terms; 
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order__c = fuel.salesOrder.Id, 
                                              Start_Date__c = System.Now().addDays(-1), Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyGBP.id, Payment_Term__c = terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));                                      

        insert lFs;
        
    	ApexPages.standardSetController con = new ApexPages.standardSetController(lFs);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        
        JsonResult jr = GenerateInvoiceExt.nextOnProcessFulfillment(false, lFs, null);
        System.debug(logginglevel.error,jr);
        System.debug(logginglevel.error,jr.messages);
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        
    	boolean ErrorExists = false;
        for(map<String,String> message : jr.messages) {
            System.debug('message'+message.get('message'));
    		if(message.get('message').contains('Group By SalesOrders not matching')) {
    			ErrorExists = true;
    			break;
    		}
    	}
        system.assertEquals(true, ErrorExists, jr.messages);
    	Test.stopTest();
    }
    
     static testMethod void callOtherMethods() {
        Test.StartTest();
        JsonResult jr = GenerateInvoiceExt.callUserDefinedMethod(null, null);
        jr = GenerateInvoiceExt.getValues();
        Test.StopTest();
    }
    
    static testMethod void shouldCreateMoreThanOneInvoice() {
    	
    	TestFuelQuery fuel = new TestFuelQuery();
    	system.assertNotEquals(null,fuel.salesOrder.Id);
        Test.startTest();
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        Payment_Term__c terms = new Payment_Term__c(); 
        terms.name = 'PT 2'; 
        terms.Description__c = '2% discount in 10 days, due 30 days';
        terms.Type__c = KSE.PAYMENT_TERM_DUE_DAYS; //AR-3 need to define type on Payment Terms. 
        terms.Discount_Days__c = 20;
        terms.Discount_Percent__c = 2;
        terms.Due_Days__c = 30;
        insert terms; 
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyGBP.id, Payment_Term__c = terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));                                      

        insert lFs;
        
        ApexPages.standardSetController con = new ApexPages.standardSetController(lFs);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        
        list<Invoice_Grouping_Rule__c> lstIgr = new list<Invoice_Grouping_Rule__c>();
        Invoice_Grouping_Rule__c igrule = new Invoice_Grouping_Rule__c();
        igrule.Company__c = fuel.company.id;
        igrule.Group_By_Sales_Orders__c = true;
        igrule.Group_By_Sales_Order_Types__c = true;
        igrule.Group_By_Customer_Hierarchy__c = 'Bill to';
        lstIgr.add(igrule);
        
        JsonResult jr = GenerateInvoiceExt.nextOnProcessFulfillment(false, lFs, lstIgr);
        system.assert(jr.success == null);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size()); 
        System.debug(logginglevel.error,jr.messages);
    	
    	Test.stopTest();
    }
    
    static testMethod void shouldCreatetwoInvoiceForExistingIgr(){ 
        TestFuelQuery fuel = new TestFuelQuery();
        system.assertNotEquals(null,fuel.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        Test.startTest();
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();

        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyUSD.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Company__c = fuel.company.Id,Customer__c = fuel.customerBillTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = fuel.currencyGBP.id, Payment_Term__c = fuel.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete')); 
        insert lFs;
        
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
            Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), 
            rank__c = 1, 
            Group_By_Customer_Hierarchy__c = 'Bill To', 
            Group_By_Sales_Orders__c = true,
            Company__c = fuel.company.Id
        );    
        insert igr;  
       
        
        ApexPages.standardSetController con = new ApexPages.standardSetController(lFs);
        GenerateInvoiceExt extGenInv = new GenerateInvoiceExt(con);
        
        JsonResult jr = GenerateInvoiceExt.nextOnProcessFulfillment(true, lFs, null);
        system.assert(jr.success == null);
        System.debug(logginglevel.error,'jr.messages--->'+jr.messages);  
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
        
        jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size());
        
        jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
        system.assert(jr.success == null);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size());
        
        boolean fromProcessFulFilment = true;
        jr = GenerateInvoiceExt.finalizeInvoices(null, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
        System.debug(logginglevel.error,'jr--->'+jr);
        System.debug(logginglevel.error,'jr.success--->'+jr.success);
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size());
        
        boolean ErrorExists = false; 
        jr = GenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>)jr.records);
        system.assert(jr.success);
        for(Map<String, String> msg :jr.messages){
            if(msg.containsKey('message')){
                if(msg.get('message').contains('has been created and finalized.')){
                    ErrorExists = true;
                    break;
                }
            }
        }
        system.assert(ErrorExists);
        
        Test.stopTest();
    }
    
}