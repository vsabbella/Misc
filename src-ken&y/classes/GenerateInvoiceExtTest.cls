@isTest
private class GenerateInvoiceExtTest {
	@testSetup static void createTestDate() {
		TestFuel fuel = new TestFuel();
		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
	    list<Configuration__c> lConfigs = new list<Configuration__c>();
	    lConfigs.add(new Configuration__c(Name = 'Sales_Order__c-'+Sales_Order__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Sales_Order_Line__c-'+Sales_Order_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Product__c-'+Product__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Customer__c-'+Customer__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Item__c-'+Item__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Location__c-'+Location__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Facility__c-'+Facility__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Agreement__c-'+Agreement__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Agreement_Line__c-'+Agreement_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Shipment_Line__c-'+Shipment_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    lConfigs.add(new Configuration__c(Name = 'Shipment__c-'+Shipment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    
	    insert lConfigs;
	    
	    list<Process__c> lstProcess = new list<Process__c>();
	    lstProcess.add(new Process__c(Name = 'TaxService', Active__c = true, Object_Step__c = 'DefaultSalesTax'));
	    insert lstProcess;
	    
	    ///create fulfillments in individual methods
	    system.assert(fuel.accountingStandard != null);
	    system.assert(fuel.account != null);
	    system.assert(fuel.company != null);
	    system.assert(fuel.facility != null);
	    system.assert(fuel.facility2 != null);
	    system.assert(fuel.clsObj != null);
	    system.assert(fuel.itemList != null);
	    system.assert(fuel.stockMovementRuleList != null);
	    system.assert(fuel.customerParent != null);
	    system.assert(fuel.customerShipTo != null);
	    system.assert(fuel.customerBillTo != null);
	    system.assert(fuel.customerSoldTo != null);
	    system.assert(fuel.product != null);
	    system.assert(fuel.product2 != null);
	    system.assert(fuel.location != null);
	    system.assert(fuel.location2 != null);
	    system.assert(fuel.pricebook != null);
	    system.assert(fuel.terms != null);
	    system.assert(fuel.uomcList != null); 
	    system.assert(fuel.CALENDAR_MONTH != null);
	    system.assert(fuel.uomList != null);
	    system.assert(fuel.salesOrder != null);
	    system.assert(fuel.agreement != null);
	    system.assert(fuel.agreementLine != null); 
	    system.assert(fuel.WEEK != null); 
	}
	
	static testMethod void SO_nofulfillments() {
        SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
        Test.StartTest();
        ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(!jr.success);
       
   	    boolean ErrorExists = false;
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
        Test.StopTest();
    }
    
    static testMethod void SO_Exceptions() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    soql3.setWhereClause('ISO_Code__c =: USDname');			
   		Currency__c usd = Database.query(soql3.getQuery());
   		system.assertNotEquals(null,usd.Id);
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
        Fulfillment__c f = new Fulfillment__c(Customer__c = billToCustomer.Id, Start_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = usd.id, Payment_Term__c = terms.ID, Sales_Order_Line__c = lSOLs[0].Id, Occurrence__c = 'Monthly',
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c);
        insert f;
       
        Task t = new Task(WhatID = lSOLs[0].Id, Type = 'Exception', Subject='Some Exception', Status= 'Open', Exception_Code__c = 'TEST-001');
        insert t;
       
        Test.StartTest();
        ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(!jr.success);
       
   	    boolean ErrorExists = false;
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('We did not invoice the following fulfillments as the related sales order has an exception')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
        Test.StopTest();
    }
    
    static testMethod void validate_FlDoesnthaveStartDate() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
   		SOQLUtil soql5 = new SOQLUtil('Company__c');
	    soql5.addFields(new set<string>{'Id'});
	    soql5.setLimit(1);		
   		Company__c company = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,company.Id);
   		
   		SOQLUtil soql6 = new SOQLUtil('UOM__c');
	    soql6.addFields(new set<string>{'Id'});
	    string month = 'Month(s)';
	    soql6.setWhereClause('Recurrence__c =: month');	
   		UOM__c calMonth = Database.query(soql6.getQuery());
   		system.assertNotEquals(null,calMonth.Id);
    	
    	Payment_Term__c terms1 = new Payment_Term__c(); 
        terms1.name = 'PT 2'; 
        terms1.Description__c = '2% discount in 10 days, due 30 days';
        terms1.Type__c = KSE.PAYMENT_TERM_DUE_DAYS; //AR-3 need to define type on Payment Terms. 
        terms1.Discount_Days__c = 20;
        terms1.Discount_Percent__c = 2;
        terms1.Due_Days__c = 30;
        insert terms1; 
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Company__c = company.Id,Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order__c = salesOrder.Id, 
                                              Start_Date__c = System.Now().addDays(-30), End_Date__c = System.Now().addDays(334),  Price_Type__c = 'Recurring', Status__c ='Complete', Recurrence_Start_Date__c = System.Now().addDays(-30), Pricing_UOM__c = calMonth.ID,
                                              Last_Bill_Date__c = System.Now().addDays(-10), Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c));
      
        lFs.add(new Fulfillment__c(Company__c = company.Id,Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[1].id, Payment_Term__c = terms1.Id, Sales_Order_Line__c = lSOLs[0].Id,
                                              Start_Date__c = System.Now().addDays(-30), End_Date__c = System.Now().addDays(334), 
                                               Last_Bill_Date__c = System.Now().addDays(10), Type__c = 'Recurring', Name = 'F1', Invoice_Ready__c = true, 
                                               Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c,  Price_Type__c = 'Recurring', Status__c ='Complete', Recurrence_Start_Date__c = System.Now().addDays(-30), Pricing_UOM__c = calMonth.ID));                                      
        insert lFs;
        
        Test.StartTest();
        ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(jr.success);
        
       	jr = GenerateInvoiceExt.next(false,salesorder.Id, salesorder);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	
       	JsonResult jr1 = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(!jr1.success);
       	system.assertEquals(null, jr1.records);
       	
       	boolean ErrorExists = false;
       	system.debug('***'+jr1.messages);
   	    for(Map<String, String> msg :jr1.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('Fulfillment can only be invoiced on')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
       	Test.StopTest();
    }
    
    static testMethod void AG_nofulfillments() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Agreement__c');
	    soql2.addFields(new set<string>{'Id'});
	    soql2.setLimit(1);		
   		Agreement__c agmt = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,agmt.Id);

        agmt.Activation_Date__c = system.today().addDays(-30);
        update agmt;
        
        salesOrder.Agreement__c = agmt.Id;
        update salesOrder;
        
        Test.StartTest();
        ApexPages.standardController con = new ApexPages.standardController(agmt);
        AgreementGenerateInvoiceExt ext = new AgreementGenerateInvoiceExt(con);
        JsonResult jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(!jr.success);
       
   	    boolean ErrorExists = false;
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
        Test.StopTest();     
    }
    
    static testMethod void AG_Activation_DateInFuture() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Agreement__c');
	    soql2.addFields(new set<string>{'Id'});
	    soql2.setLimit(1);		
   		Agreement__c agmt = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,agmt.Id);
		
		SOQLUtil soql5 = new SOQLUtil('Customer__c');
	    soql5.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql5.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    soql3.setWhereClause('ISO_Code__c =: USDname');			
   		Currency__c usd = Database.query(soql3.getQuery());
   		system.assertNotEquals(null,usd.Id);
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
        agmt.Activation_Date__c = system.today().addDays(30);
        update agmt;
        
        salesOrder.Agreement__c = agmt.Id;
        update salesOrder;
        
        Fulfillment__c f = new Fulfillment__c(Customer__c = billToCustomer.Id, Start_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = usd.id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, Occurrence__c = 'Monthly',
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete');
        insert f;
        
        Test.StartTest();
        ApexPages.standardController con = new ApexPages.standardController(agmt);
        AgreementGenerateInvoiceExt ext = new AgreementGenerateInvoiceExt(con);
        JsonResult jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(!jr.success);
       
   	    boolean ErrorExists = false;
   	    system.debug('***'+jr.messages);
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.Acceptance_Date_in_future)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assertEquals(ErrorExists,true, ApexPages.GetMessages());
        Test.StopTest();
    }
    
    static testMethod void AG_Activation_DateBlank() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Agreement__c');
	    soql2.addFields(new set<string>{'Id'});
	    soql2.setLimit(1);		
   		Agreement__c agmt = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,agmt.Id);
		
		SOQLUtil soql5 = new SOQLUtil('Customer__c');
	    soql5.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql5.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    soql3.setWhereClause('ISO_Code__c =: USDname');			
   		Currency__c usd = Database.query(soql3.getQuery());
   		system.assertNotEquals(null,usd.Id);
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
        
        salesOrder.Agreement__c = agmt.Id;
        update salesOrder;
        
        Fulfillment__c f = new Fulfillment__c(Customer__c = billToCustomer.Id, Start_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = usd.id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, Occurrence__c = 'Monthly',
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete');
        insert f;
        
        Test.StartTest();
        ApexPages.standardController con = new ApexPages.standardController(agmt);
        AgreementGenerateInvoiceExt ext = new AgreementGenerateInvoiceExt(con);
        JsonResult jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(!jr.success);
       
   	    boolean ErrorExists = false;
   	    system.debug('***'+jr.messages);
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.Acceptance_Date_Unspecified)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assertEquals(ErrorExists,true, ApexPages.GetMessages());
        Test.StopTest();
    }

    static testMethod void SO_warningForMorThanOneInvoice() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Sold To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c custSoldTo = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,custSoldTo.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
    	
    	Payment_Term__c terms1 = new Payment_Term__c(); 
        terms1.name = 'PT 2'; 
        terms1.Description__c = '2% discount in 10 days, due 30 days';
        terms1.Type__c = KSE.PAYMENT_TERM_DUE_DAYS; //AR-3 need to define type on Payment Terms. 
        terms1.Discount_Days__c = 20;
        terms1.Discount_Percent__c = 2;
        terms1.Due_Days__c = 30;
        insert terms1;
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[1].id, Payment_Term__c = terms1.Id, Sales_Order_Line__c = lSOLs[0].Id,
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));                                      
        insert lFs;
       
        Test.StartTest();
        ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(jr.success);
        
       	jr = GenerateInvoiceExt.next(false,salesorder.Id, salesorder);
       	system.assertEquals(null,jr.success);
       	boolean ErrorExists = false;
       	system.debug(logginglevel.error,'***'+jr.messages);
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('2 customer invoices for this sales order')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
        
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success, jr);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = GenerateInvoiceExt.finalizeInvoices(salesorder.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	ErrorExists = false;
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
       	
       	ErrorExists = false;
        jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(!jr.success);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
   	    
       	Test.StopTest();
    }
    
    static testMethod void AG_warningForMorThanOneInvoice() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		for(Sales_Order_Line__c sol : lSOLs){
        	sol.Rate_Basis__c = 'Quantity';
        }
        update lSOLs;
        
        SOQLUtil soql7 = new SOQLUtil('Customer__c');
	    soql7.addFields(new set<string>{'Id'});
	    string sname = 'Customer Ship To 1';
	    soql7.setWhereClause('Name =: sname');			
   		Customer__c shipToCustomer = Database.query(soql7.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
   	
   		SOQLUtil soql2 = new SOQLUtil('Agreement__c');
	    soql2.addFields(new set<string>{'Id','Company__c'});
	    soql2.setLimit(1);		
   		Agreement__c agmt = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,agmt.Id);
		
		SOQLUtil soql5 = new SOQLUtil('Customer__c');
	    soql5.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql5.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
   		SOQLUtil soql6 = new SOQLUtil('Agreement_Line__c');
	    soql6.addFields(new set<string>{'Id'});
	    Id AgreementId = agmt.Id;
	    soql6.setWhereClause('Agreement__c =: AgreementId');			
   		Agreement_Line__c agmtLine = Database.query(soql6.getQuery());
   		system.assertNotEquals(null,agmtLine.Id);
        
        agmt.Activation_Date__c = system.today().addDays(-30);
        update agmt;
        
        salesOrder.Agreement__c = agmt.Id;
        salesOrder.Ship_to__c = shipToCustomer.Id;
        update salesOrder;
        
		Payment_Term__c terms1 = new Payment_Term__c(); 
        terms1.name = 'PT 2'; 
        terms1.Description__c = '2% discount in 10 days, due 30 days';
        terms1.Type__c = KSE.PAYMENT_TERM_DUE_DAYS; //AR-3 need to define type on Payment Terms. 
        terms1.Discount_Days__c = 20;
        terms1.Discount_Percent__c = 2;
        terms1.Due_Days__c = 30;
        insert terms1; 
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Agreement_Line__c = agmtLine.Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        lFs.add(new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[1].id, Payment_Term__c = terms1.Id, Sales_Order_Line__c = lSOLs[0].Id,
                                              Agreement_Line__c = agmtLine.Id, Name = 'F2', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));                                      
        insert lFs;
       
        Test.StartTest();
        
        ApexPages.standardController con = new ApexPages.standardController(agmt);
        AgreementGenerateInvoiceExt ext = new AgreementGenerateInvoiceExt(con);
        JsonResult jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(jr.success);
        
       	jr = AgreementGenerateInvoiceExt.next(false,agmt.Id, agmt);
       	system.assertEquals(null,jr.success);
       	system.debug(logginglevel.error,'***'+jr.messages);
       	boolean ErrorExists = false;
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('2 customer invoices for this agreement')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }

        system.assert(ErrorExists);
        
       	jr = AgreementGenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	//To be remove - populating ship to on CI explicitly
       	list<Customer_Invoice__c> lstCI = new list<Customer_Invoice__c>();
       	for(Customer_Invoice__c ci: (list<Customer_Invoice__c>)jr.records){
       		lstCI.add(new Customer_Invoice__c(Id=ci.Id, Ship_to__c = shipToCustomer.Id));
       	}
       	update lstCI;
       	
       	jr = AgreementGenerateInvoiceExt.prefinalizeActions(lstCI);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = AgreementGenerateInvoiceExt.finalizeInvoices(agmt.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Agreement__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	ErrorExists = false;
       	jr = AgreementGenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>)jr.records);
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
       	
       	ErrorExists = false;
        jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(!jr.success);
        system.debug('***'+jr.messages);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
   	    
       	Test.StopTest();  
    }
    
    static testMethod void AG_warningMoreThanOneOrderType() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c','Product__r.Description__c','Ship_From_Location__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		for(Sales_Order_Line__c sol : lSOLs){
        	sol.Rate_Basis__c = 'Quantity';
        }
        update lSOLs;
        
        SOQLUtil soql7 = new SOQLUtil('Customer__c');
	    soql7.addFields(new set<string>{'Id'});
	    string sname = 'Customer Ship To 1';
	    soql7.setWhereClause('Name =: sname');			
   		Customer__c shipToCustomer = Database.query(soql7.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
   		
   		SOQLUtil soql8 = new SOQLUtil('Customer__c');
	    soql8.addFields(new set<string>{'Id'});
	    string soname = 'Customer Sold To 1';
	    soql8.setWhereClause('Name =: soname');			
   		Customer__c soldToCustomer = Database.query(soql8.getQuery());
   		system.assertNotEquals(null,soldToCustomer.Id);
   	
   		SOQLUtil soql2 = new SOQLUtil('Agreement__c');
	    soql2.addFields(new set<string>{'Id','Company__c'});
	    soql2.setLimit(1);		
   		Agreement__c agmt = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,agmt.Id);
		
		SOQLUtil soql5 = new SOQLUtil('Customer__c');
	    soql5.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql5.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
   		SOQLUtil soql6 = new SOQLUtil('Agreement_Line__c');
	    soql6.addFields(new set<string>{'Id'});
	    Id AgreementId = agmt.Id;
	    soql6.setWhereClause('Agreement__c =: AgreementId');			
   		Agreement_Line__c agmtLine = Database.query(soql6.getQuery());
   		system.assertNotEquals(null,agmtLine.Id);
        
        agmt.Activation_Date__c = system.today().addDays(-30);
        update agmt;
        
        salesOrder.Agreement__c = agmt.Id;
        salesOrder.Ship_to__c = shipToCustomer.Id;
        update salesOrder;
    
        Sales_Order__c salesOrderNew = new Sales_Order__c(
                Company__c = salesorder.Company__c,
                Customer__c = soldToCustomer.id,
                Ship_To__c = shipToCustomer.id,
                Payment_Term__c = terms.id,
                Currency__c = lstCurrency[0].Id,
		        Bill_To__c = billToCustomer.Id,
		        Original_Sales_Order__c = 'so123', 
		        Type__c = 'Adjustment1',
		        Agreement__c = agmt.Id
	    );
		insert salesOrderNew;
		
		Sales_Order_Line__c salesOrderLineNew = new Sales_Order_Line__c();
        salesOrderLineNew.Company__c = salesorder.Company__c;
        salesOrderLineNew.Description__c = lSOLs[0].Product__r.Description__c;
        salesOrderLineNew.Discount_Percent__c = 2;
        salesOrderLineNew.Product__c = lSOLs[0].Product__c;
        salesOrderLineNew.Quantity_Ordered__c = 100;
        salesOrderLineNew.Required_Date__c = System.today()+5;
        salesOrderLineNew.Sales_Order__c = salesOrderNew.Id;
        salesOrderLineNew.Ship_From_Location__c = lSOLs[0].Ship_From_Location__c;
        salesOrderLineNew.Unit_Price__c = 11.12;
        salesOrderLineNew.Memo__c = 'salesOrderLine';
        salesOrderLineNew.Occurrence__c = 'Immediate';
        insert salesOrderLineNew;
       
	    list<Fulfillment__c> lFs = new list<Fulfillment__c>();
	    lFs.add(new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].Id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
	                                              Agreement_Line__c = agmtLine.Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
	    lFs.add(new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].Id, Payment_Term__c = terms.Id, Sales_Order_Line__c = salesOrderLineNew.Id,
	                                              Agreement_Line__c = agmtLine.Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = salesOrderLineNew.Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));                                      
	    insert lFs;
	    
	    Test.StartTest();
        
        ApexPages.standardController con = new ApexPages.standardController(agmt);
        AgreementGenerateInvoiceExt ext = new AgreementGenerateInvoiceExt(con);
        JsonResult jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(jr.success);
        
       	jr = AgreementGenerateInvoiceExt.next(false,agmt.Id, agmt);
       	system.assertEquals(null,jr.success);
       	boolean ErrorExists = false;
       	system.debug(logginglevel.error,'***'+jr.messages);
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('2 customer invoices for this agreement')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
        
       	jr = AgreementGenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	//To be remove - populating ship to on CI explicitly
       	list<Customer_Invoice__c> lstCI = new list<Customer_Invoice__c>();
       	for(Customer_Invoice__c ci: (list<Customer_Invoice__c>)jr.records){
       		lstCI.add(new Customer_Invoice__c(Id=ci.Id, Ship_to__c = shipToCustomer.Id));
       	}
       	update lstCI;
       	
       	jr = AgreementGenerateInvoiceExt.prefinalizeActions(lstCI);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = AgreementGenerateInvoiceExt.finalizeInvoices(agmt.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Agreement__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	ErrorExists = false;
       	jr = AgreementGenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>)jr.records);
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
        
        ErrorExists = false;
        jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(!jr.success);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
   	    
       	Test.StopTest();	
    }
	
    static testMethod void SO_success_AndNoFulfillment() {
		SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Sold To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c custSoldTo = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,custSoldTo.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
		
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        insert lFs;
       
        Test.StartTest();
        
        ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(jr.success);
        
       	jr = GenerateInvoiceExt.next(false,salesorder.Id, salesorder);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = GenerateInvoiceExt.finalizeInvoices(salesorder.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
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
       	
       	ErrorExists = false;
        jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(!jr.success);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
   	    
       	Test.StopTest();
    }
    
    static testMethod void SO_success() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c','Customer__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    	system.assertNotEquals(null, salesorder.Customer__c);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c', 'Discount_Percent__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Sold To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c custSoldTo = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,custSoldTo.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		system.assertEquals(lSOls[0].Discount_Percent__c, 2, lSols);//KNDY-16310
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order__c = salesorder.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        Fulfillment__c accrualFF = new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order__c = salesorder.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL, Name = 'F2', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete');
        lFs.add(accrualFF);
        insert lFs;
        Test.StartTest();
        
        ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);

        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(jr.success);
        
       	jr = GenerateInvoiceExt.next(false,salesorder.Id, salesorder);
        Boolean ErrorExists = false;
        for(Map<String, String> msg :jr.messages){
            if(msg.containsKey('message')){
                if(msg.get('message').contains('The fulfillments ready to invoice have values that will create 2 customer invoices for this sales order.')){
                    ErrorExists = true;
                    break;
                }
            }
        }
        system.assert(ErrorExists);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size());
       	
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = GenerateInvoiceExt.finalizeInvoices(salesorder.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	

        
       	ErrorExists = false; 
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
        Customer_Invoice__c allowanceAccrualCI;
        Customer_Invoice_Line__c allowanceAccrualCIL;
        list<Customer_Invoice__c> lCI = [Select Id, Sold_To_Customer__c, Invoice_Type__c,Finalized__c,Payment_Term__c,Agreement__c, Sales_Order__c, Shipment__c,
                                         (Select Id, Customer_Invoice__c, Agreement_Line__c, Agreement__c,
                                          Sales_Order_Line__c, Sales_Order__c, Shipment_Line__c, Shipment__c,
                                          Discount_Amount__c,Discount_Percent__c,Off_Invoice_Rate__c,
                                          Allowances__c,Freight_Allowance__c, Extended_Price__c,
                                          Unit_Price__c, Quantity_Shipped__c
                                          From Customer_Invoice_Lines__r) 
                                         from Customer_Invoice__c where Sales_Order__c = :salesOrder.Id];
        system.assertEquals(2,lCI.size(),ApexPages.GetMessages());
        
        for (Customer_Invoice__c ci: lCI){
            if (ci.Invoice_Type__c == AllowanceRuleService.ALLOWANCE_ACCRUAL){
                allowanceAccrualCI = ci;
                break;
            }
            else {
                system.assertNotEquals(ci.Sold_To_Customer__c, null, '>>> ci '+ ci);//KNDY-16332
            }
           
        }
        
        // CI should have sales order and payment term
        system.assertEquals(allowanceAccrualCI.Sales_Order__c, accrualFF.Sales_Order__c, '>>> allowanceAccrualCI: ' + allowanceAccrualCI);
        system.assertEquals(allowanceAccrualCI.Payment_Term__c, terms.Id, '>>> allowanceAccrualCI: ' + allowanceAccrualCI);
        system.assertEquals(allowanceAccrualCI.Sold_To_Customer__c, null, '>>> allowanceAccrualCI: ' + allowanceAccrualCI);//KNDY-16332

        // CI line should have related line lookups
        List<Customer_Invoice_Line__c> cils = allowanceAccrualCI.Customer_Invoice_Lines__r;
        system.assertEquals(cils.size(), 1);
        allowanceAccrualCIL = cils[0];
        system.assertEquals(allowanceAccrualCIL.Sales_Order__c, accrualFF.Sales_Order__c, '>>> allowanceAccrualCIL: ' + allowanceAccrualCIL);
        system.assertEquals(allowanceAccrualCIL.Sales_Order_Line__c, accrualFF.Sales_Order_Line__c, '>>> allowanceAccrualCIL: ' + allowanceAccrualCIL);
        
        //KNDY-16301
        system.assertEquals(allowanceAccrualCIL.Discount_Amount__c, null,  '>>> allowanceAccrualCIL: ' + allowanceAccrualCIL);
        system.assertEquals(allowanceAccrualCIL.Discount_Percent__c, 0,  '>>> allowanceAccrualCIL: ' + allowanceAccrualCIL);
        system.assertEquals(allowanceAccrualCIL.Off_Invoice_Rate__c, 0,  '>>> allowanceAccrualCIL: ' + allowanceAccrualCIL);
        system.assertEquals(allowanceAccrualCIL.Allowances__c, 0,  '>>> allowanceAccrualCIL: ' + allowanceAccrualCIL);
        system.assertEquals(allowanceAccrualCIL.Freight_Allowance__c, 0,  '>>> allowanceAccrualCIL: ' + allowanceAccrualCIL);
        system.assertEquals(allowanceAccrualCIL.Quantity_Shipped__c, accrualFF.Quantity__c,  '>>> allowanceAccrualCIL: ' + allowanceAccrualCIL);
        system.assertEquals(allowanceAccrualCIL.Extended_Price__c, allowanceAccrualCIL.Quantity_Shipped__c * allowanceAccrualCIL.Unit_Price__c,  '>>> allowanceAccrualCIL: ' + allowanceAccrualCIL);

        // CI sub line should be associated with Allowance Accrual FF and CIL
        List<Customer_Invoice_Sub_Line__c> ciSubLines = [Select Id, Fulfillment__c, Customer_Invoice_Line__c from Customer_Invoice_Sub_line__c where Fulfillment__c = :accrualFF.Id];
        system.assertEquals(ciSubLines.size(),1,'>>> ciSubLines: ' + ciSubLines);
        system.assertEquals(ciSubLines[0].Customer_Invoice_Line__c, allowanceAccrualCIL.Id);
               
       	ErrorExists = false;
        jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(!jr.success);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
   	    
       	Test.StopTest();
    }
	
    static testMethod void AG_success() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		for(Sales_Order_Line__c sol : lSOLs){
        	sol.Rate_Basis__c = 'Quantity';
        }
        update lSOLs;
   	
   		SOQLUtil soql2 = new SOQLUtil('Agreement__c');
	    soql2.addFields(new set<string>{'Id','Company__c'});
	    soql2.setLimit(1);		
   		Agreement__c agmt = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,agmt.Id);
		
		SOQLUtil soql5 = new SOQLUtil('Customer__c');
	    soql5.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql5.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
   		SOQLUtil soql6 = new SOQLUtil('Agreement_Line__c');
	    soql6.addFields(new set<string>{'Id'});
	    Id AgreementId = agmt.Id;
	    soql6.setWhereClause('Agreement__c =: AgreementId');			
   		Agreement_Line__c agmtLine = Database.query(soql6.getQuery());
   		system.assertNotEquals(null,agmtLine.Id);
        
        agmt.Activation_Date__c = system.today().addDays(-30);
        update agmt;
        
        salesOrder.Agreement__c = agmt.Id;
        update salesOrder;
    
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                             Agreement__c = agmt.Id, Agreement_Line__c = agmtLine.Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        Fulfillment__c accrualFF = new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                   Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL, Agreement__c = agmt.Id, Agreement_Line__c = agmtLine.Id, Name = 'F2', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete');
        lFs.add(accrualFF);
        insert lFs;
        
        Test.StartTest();
        
        ApexPages.standardController con = new ApexPages.standardController(agmt);
        AgreementGenerateInvoiceExt ext = new AgreementGenerateInvoiceExt(con);
        JsonResult jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(jr.success);
        
       	jr = AgreementGenerateInvoiceExt.next(false,agmt.Id, agmt);
        Boolean ErrorExists = false;
        for(Map<String, String> msg :jr.messages){
            if(msg.containsKey('message')){
                if(msg.get('message').contains('The fulfillments ready to invoice have values that will create 2 customer invoices for this agreement.')){
                    ErrorExists = true;
                    break;
                }
            }
        }
        system.assert(ErrorExists);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size());
       	
       	jr = AgreementGenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	//To be remove - populating ship to on CI explicitly
       	SOQLUtil soql8 = new SOQLUtil('Customer__c');
	    soql8.addFields(new set<string>{'Id'});
	    string sname = 'Customer Ship To 1';
	    soql8.setWhereClause('Name =: sname');			
   		Customer__c shipToCustomer = Database.query(soql8.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
       	list<Customer_Invoice__c> lstCI = new list<Customer_Invoice__c>();
       	for(Customer_Invoice__c ci: (list<Customer_Invoice__c>)jr.records){
       		lstCI.add(new Customer_Invoice__c(Id=ci.Id, Ship_to__c = shipToCustomer.Id));
       	}
       	update lstCI;
       	
       	jr = AgreementGenerateInvoiceExt.prefinalizeActions(lstCI);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = AgreementGenerateInvoiceExt.finalizeInvoices(agmt.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Agreement__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	ErrorExists = false; 
       	jr = AgreementGenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>)jr.records);
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
        
        Customer_Invoice__c allowanceAccrualCI;
        Customer_Invoice_Line__c allowanceAccrualCIL;
        list<Customer_Invoice__c> lCI = [Select Id, Invoice_Type__c,Finalized__c,Payment_Term__c,Agreement__c, Sales_Order__c, Shipment__c,
                                         (Select Id, Customer_Invoice__c, Agreement_Line__c, Agreement__c,
                                          Sales_Order_Line__c, Sales_Order__c, Shipment_Line__c, Shipment__c 
                                          From Customer_Invoice_Lines__r) 
                                         from Customer_Invoice__c where Agreement__c = :agmt.Id];
        system.assertEquals(2,lCI.size(),ApexPages.GetMessages());
        for (Customer_Invoice__c ci: lCI){
            if (ci.Invoice_Type__c == AllowanceRuleService.ALLOWANCE_ACCRUAL){
                allowanceAccrualCI = ci;
                break;
            }
        }
        // CI should have agreement, sales order and payment term
        system.assertEquals(allowanceAccrualCI.Agreement__c, accrualFF.Agreement__c, '>>> allowanceAccrualCI: ' + allowanceAccrualCI);
        system.assertEquals(allowanceAccrualCI.Payment_Term__c, terms.Id, '>>> allowanceAccrualCI: ' + allowanceAccrualCI);
        // CI line should have related line lookups
        List<Customer_Invoice_Line__c> cils = allowanceAccrualCI.Customer_Invoice_Lines__r;
        system.assertEquals(cils.size(), 1);
        allowanceAccrualCIL = cils[0];
        system.assertEquals(allowanceAccrualCIL.Agreement_Line__c, accrualFF.Agreement_Line__c, '>>> allowanceAccrualCIL: ' + allowanceAccrualCIL);
        system.assertEquals(allowanceAccrualCIL.Agreement__c, accrualFF.Agreement__c, '>>> allowanceAccrualCIL: ' + allowanceAccrualCIL);
     
        // CI sub line should be associated with Allowance Accrual FF and CIL

   		SOQLUtil soql7 = new SOQLUtil('Customer_Invoice_Sub_Line__c');
	    soql7.addFields(new set<string>{'Id', 'Fulfillment__c', 'Customer_Invoice_Line__c'});
	    Id accrualId = accrualFF.Id;
	    soql7.setWhereClause('Fulfillment__c =: accrualId');			
   	    list<Customer_Invoice_Sub_Line__c> ciSubLines = Database.query(soql7.getQuery());
   		system.assertEquals(1,ciSubLines.size(),'>>> ciSubLines: ' + ciSubLines);
   		system.assertEquals(ciSubLines[0].Customer_Invoice_Line__c, allowanceAccrualCIL.Id);
        
       	ErrorExists = false;
        jr = AgreementGenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(!jr.success);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
   	    
       	Test.StopTest();
    }
	
    static testMethod void AG_RecurringFF_success() {
        SOQLUtil soql = new SOQLUtil('Sales_Order__c');
        soql.addFields(new set<string>{'Id','Company__c'});            
        soql.setLimit(1);
        Sales_Order__c salesorder = Database.query(soql.getQuery());
        Id soId = salesorder.Id;
        system.assertNotEquals(null,salesorder.Id);
            
        SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
        soql1.addFields(new set<string>{'Id','Product__c'});
        soql1.setWhereClause('Sales_Order__c =: soId');            
        list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
        system.assertEquals(2,lSOLs.size());
        for(Sales_Order_Line__c sol : lSOLs){
            sol.Rate_Basis__c = 'Quantity';
        }
        update lSOLs;
       
        SOQLUtil soql2 = new SOQLUtil('Agreement__c');
        soql2.addFields(new set<string>{'Id','Company__c'});
        soql2.setLimit(1);        
        Agreement__c agmt = Database.query(soql2.getQuery());
        system.assertNotEquals(null,agmt.Id);
        
        SOQLUtil soql5 = new SOQLUtil('Customer__c');
        soql5.addFields(new set<string>{'Id'});
        string cname = 'Customer Bill To 1';
        soql5.setWhereClause('Name =: cname');            
        Customer__c billToCustomer = Database.query(soql5.getQuery());
        system.assertNotEquals(null,billToCustomer.Id);
           
        SOQLUtil soql3 = new SOQLUtil('Currency__c');
        soql3.addFields(new set<string>{'Id'});
        string USDname = 'USD';
        string GBPname = 'GBP';
        soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');            
        list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
        system.assertEquals(2,lstCurrency.size());
           
        SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
        soql4.addFields(new set<string>{'Id'});
        string PTname = '2/10 Net 30';
        soql4.setWhereClause('Name =: PTname');            
        Payment_Term__c terms = Database.query(soql4.getQuery());
        system.assertNotEquals(null,terms.Id);
           
        SOQLUtil soql6 = new SOQLUtil('Agreement_Line__c');
        soql6.addFields(new set<string>{'Id'});
        Id AgreementId = agmt.Id;
        soql6.setWhereClause('Agreement__c =: AgreementId');            
           Agreement_Line__c agmtLine = Database.query(soql6.getQuery());
           system.assertNotEquals(null,agmtLine.Id);
        
        agmt.Activation_Date__c = system.today().addDays(-30);
        update agmt;
        
        salesOrder.Agreement__c = agmt.Id;
        update salesOrder;
        
        // Recurring fulfillment only
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        Fulfillment__c accrualFF = new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                   Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL, Agreement__c = agmt.Id, Agreement_Line__c = agmtLine.Id, Name = 'F2', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Recurring', Status__c ='Complete');
        lFs.add(accrualFF);
        insert lFs;
        
        Test.StartTest();
        
        ApexPages.standardController con = new ApexPages.standardController(agmt);
        AgreementGenerateInvoiceExt ext = new AgreementGenerateInvoiceExt(con);
        JsonResult jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(jr.success);
        
        jr = AgreementGenerateInvoiceExt.next(false,agmt.Id, agmt);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
           
        jr = AgreementGenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
           
        //To be remove - populating ship to on CI explicitly
        SOQLUtil soql8 = new SOQLUtil('Customer__c');
        soql8.addFields(new set<string>{'Id'});
        string sname = 'Customer Ship To 1';
        soql8.setWhereClause('Name =: sname');            
        Customer__c shipToCustomer = Database.query(soql8.getQuery());
        system.assertNotEquals(null,shipToCustomer.Id);
        list<Customer_Invoice__c> lstCI = new list<Customer_Invoice__c>();
        for(Customer_Invoice__c ci: (list<Customer_Invoice__c>)jr.records){
           lstCI.add(new Customer_Invoice__c(Id=ci.Id, Ship_to__c = shipToCustomer.Id));
        }
        update lstCI;
           
        jr = AgreementGenerateInvoiceExt.prefinalizeActions(lstCI);
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
           
        boolean fromProcessFulFilment = false;
        jr = AgreementGenerateInvoiceExt.finalizeInvoices(agmt.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Agreement__c');
        system.assert(jr.success);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(1, jr.records.size());
           
        Boolean ErrorExists = false;
        jr = AgreementGenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>)jr.records);
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
        
        Customer_Invoice__c allowanceAccrualCI;
        Customer_Invoice_Line__c allowanceAccrualCIL;
        list<Customer_Invoice__c> lCI = [Select Id, Invoice_Type__c,Finalized__c,Payment_Term__c,Agreement__c, Sales_Order__c, Shipment__c,
                                         (Select Id, Customer_Invoice__c, Agreement_Line__c, Agreement__c,
                                          Sales_Order_Line__c, Sales_Order__c, Shipment_Line__c, Shipment__c 
                                          From Customer_Invoice_Lines__r) 
                                         from Customer_Invoice__c where Agreement__c = :agmt.Id];
        system.assertEquals(1,lCI.size(),ApexPages.GetMessages());
        for (Customer_Invoice__c ci: lCI){
            if (ci.Invoice_Type__c == AllowanceRuleService.ALLOWANCE_ACCRUAL){
                allowanceAccrualCI = ci;
                break;
            }
        }
        // CI should have agreement, sales order and payment term
        system.assertEquals(allowanceAccrualCI.Agreement__c, accrualFF.Agreement__c, '>>> allowanceAccrualCI: ' + allowanceAccrualCI);
        system.assertEquals(allowanceAccrualCI.Payment_Term__c, terms.Id, '>>> allowanceAccrualCI: ' + allowanceAccrualCI);
        // CI line should have related line lookups
        List<Customer_Invoice_Line__c> cils = allowanceAccrualCI.Customer_Invoice_Lines__r;
        system.assertEquals(cils.size(), 1);
        allowanceAccrualCIL = cils[0];
        system.assertEquals(allowanceAccrualCIL.Agreement_Line__c, accrualFF.Agreement_Line__c, '>>> allowanceAccrualCIL: ' + allowanceAccrualCIL);
        system.assertEquals(allowanceAccrualCIL.Agreement__c, accrualFF.Agreement__c, '>>> allowanceAccrualCIL: ' + allowanceAccrualCIL);
     
        // CI sub line should be associated with Allowance Accrual FF and CIL
        SOQLUtil soql7 = new SOQLUtil('Customer_Invoice_Sub_Line__c');
        soql7.addFields(new set<string>{'Id', 'Fulfillment__c', 'Customer_Invoice_Line__c'});
        Id accrualId = accrualFF.Id;
        soql7.setWhereClause('Fulfillment__c =: accrualId');            
           list<Customer_Invoice_Sub_Line__c> ciSubLines = Database.query(soql7.getQuery());
           system.assertEquals(1,ciSubLines.size(),'>>> ciSubLines: ' + ciSubLines);
           system.assertEquals(ciSubLines[0].Customer_Invoice_Line__c, allowanceAccrualCIL.Id);
        
        ErrorExists = false;
        jr = AgreementGenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(!jr.success);
        for(Map<String, String> msg :jr.messages){
            if(msg.containsKey('message')){
                if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
                    ErrorExists = true;
                    break;
                }
            }
        }
        system.assert(ErrorExists);
           
        Test.StopTest();
    }
    
    static testMethod void SH_nofulfillments() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
		
		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Ship To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c shipToCustomer = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
        
        Shipment__c sh = new Shipment__c(Company__c = salesorder.Company__c, Customer__c = shipToCustomer.Id, Status__c = 'Staged', Type__c = 'Sales Order Shipment');
        insert sh;
        Shipment_Line__c shl = new Shipment_Line__c(Shipment__c = sh.Id, Sales_Order_Line__c = lSOLs[0].Id, Product__c = lSOLs[0].Product__c, Company__c = salesorder.Company__c);
        insert shl;
        
        Test.StartTest();
        ApexPages.standardController con = new ApexPages.standardController(sh);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(sh.Id,'Shipment__c');
        system.assert(!jr.success);
       
   	    boolean ErrorExists = false;
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
        Test.StopTest();
    }
    
    static testMethod void SH_Exceptions() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
		
		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Ship To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c shipToCustomer = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
    	
    	SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Customer__c');
	    soql4.addFields(new set<string>{'Id'});
	    string sname = 'Customer Sold To 1';
	    soql4.setWhereClause('Name =: sname');			
   		Customer__c custSoldTo = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,custSoldTo.Id);
   		
   		SOQLUtil soql5 = new SOQLUtil('Payment_Term__c');
	    soql5.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql5.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,terms.Id);
        
        Shipment__c sh = new Shipment__c(Company__c = salesorder.Company__c, Customer__c = shipToCustomer.Id, Status__c = 'Staged', Type__c = 'Sales Order Shipment');
        insert sh;
        Shipment_Line__c shl = new Shipment_Line__c(Shipment__c = sh.Id, Sales_Order_Line__c = lSOLs[0].Id, Product__c = lSOLs[0].Product__c, Company__c = salesorder.Company__c);
        insert shl;
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Shipment_Line__c = shl.Id, 
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        insert lFs;
        Task t = new Task(WhatID = shl.Id, Type = 'Exception', Subject='Some Exception', Status= 'Open', Exception_Code__c = 'TEST-001');
        insert t;
		       
        Test.StartTest();
        ApexPages.standardController con = new ApexPages.standardController(sh);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(sh.Id,'Shipment__c');
        system.assert(!jr.success);
       
   	    boolean ErrorExists = false;
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('We did not invoice the following fulfillments as the related shipment has an exception')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
        Test.StopTest();
    }
    
    static testMethod void SH_success() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
		
		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Ship To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c shipToCustomer = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
    	
    	SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Customer__c');
	    soql4.addFields(new set<string>{'Id'});
	    string sname = 'Customer Sold To 1';
	    soql4.setWhereClause('Name =: sname');			
   		Customer__c custSoldTo = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,custSoldTo.Id);
   		
   		SOQLUtil soql5 = new SOQLUtil('Payment_Term__c');
	    soql5.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql5.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,terms.Id);
        
        Shipment__c sh = new Shipment__c(Company__c = salesorder.Company__c, Customer__c = shipToCustomer.Id, Status__c = 'Staged', Type__c = 'Sales Order Shipment');
        insert sh;
        Shipment_Line__c shl = new Shipment_Line__c(Shipment__c = sh.Id, Sales_Order_Line__c = lSOLs[0].Id, Product__c = lSOLs[0].Product__c, Company__c = salesorder.Company__c);
        insert shl;
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Shipment_Line__c = shl.Id, 
                                   Sales_Order_Line__c = lSOLs[0].Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        Fulfillment__c accrualFF = new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Shipment_Line__c = shl.Id, 
                                   Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL, Sales_Order_Line__c = lSOLs[0].Id, Name = 'F2', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete');
        lFs.add(accrualFF);
        insert lFs;
        
        Test.StartTest();
        ApexPages.standardController con = new ApexPages.standardController(sh);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(sh.Id,'Shipment__c');
        system.assert(jr.success);
        
        jr = GenerateInvoiceExt.next(false,sh.Id, sh);
        Boolean ErrorExists = false;
        for(Map<String, String> msg :jr.messages){
            if(msg.containsKey('message')){
                if(msg.get('message').contains('The fulfillments ready to invoice have values that will create 2 customer invoices for this shipment.')){
                    ErrorExists = true;
                    break;
                }
            }
        }
        system.assert(ErrorExists);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size());
       	
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = GenerateInvoiceExt.finalizeInvoices(sh.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Shipment__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	ErrorExists = false; 
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
        
        SOQLUtil soql6 = new SOQLUtil('Customer_Invoice_Sub_Line__c');
	    soql6.addFields(new set<string>{'Id'});
	    Id accrualId = accrualFF.Id;
	    soql6.setWhereClause('Fulfillment__c =: accrualId');			
   	    list<Customer_Invoice_Sub_Line__c> ciSubLines = Database.query(soql6.getQuery());
   		system.assertEquals(1,ciSubLines.size());
        
       	ErrorExists = false;
        jr = GenerateInvoiceExt.validate(sh.Id,'Shipment__c');
        system.assert(!jr.success);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
        Test.StopTest();
    }
    
    static testMethod void SH_success_multipleInvoice() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
		
		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Ship To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c shipToCustomer = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
    	
    	SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Customer__c');
	    soql4.addFields(new set<string>{'Id'});
	    string sname = 'Customer Sold To 1';
	    soql4.setWhereClause('Name =: sname');			
   		Customer__c custSoldTo = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,custSoldTo.Id);
   		
   		SOQLUtil soql5 = new SOQLUtil('Payment_Term__c');
	    soql5.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql5.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,terms.Id);
        
        Shipment__c sh = new Shipment__c(Company__c = salesorder.Company__c, Customer__c = shipToCustomer.Id, Status__c = 'Staged', Type__c = 'Sales Order Shipment');
        insert sh;
        Shipment_Line__c shl = new Shipment_Line__c(Shipment__c = sh.Id, Sales_Order_Line__c = lSOLs[0].Id, Product__c = lSOLs[0].Product__c, Company__c = salesorder.Company__c);
        insert shl;
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Shipment_Line__c = shl.Id, 
                                   Sales_Order_Line__c = lSOLs[0].Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[1].id, Payment_Term__c = terms.Id, Shipment_Line__c = shl.Id, 
                                   Sales_Order_Line__c = lSOLs[0].Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        insert lFs;
        
        Test.StartTest();
        ApexPages.standardController con = new ApexPages.standardController(sh);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(sh.Id,'Shipment__c');
        system.assert(jr.success);
        
        jr = GenerateInvoiceExt.next(false,sh.Id, sh);
       	system.assertEquals(null,jr.success);
       	boolean ErrorExists = false;
       	system.debug(logginglevel.error,'***'+jr.messages);
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('2 customer invoices for this shipment')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
       	
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = GenerateInvoiceExt.finalizeInvoices(sh.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Shipment__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
        ErrorExists = false; 
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
        
       	ErrorExists = false;
        jr = GenerateInvoiceExt.validate(sh.Id,'Shipment__c');
        system.assert(!jr.success);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
        Test.StopTest();
    }
    
	static testMethod void SO_success_withExistingIGR() {
		SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Sold To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c custSoldTo = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,custSoldTo.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
   		list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        Fulfillment__c accrualFF = new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL, Name = 'F2', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete');
        lFs.add(accrualFF);
        insert lFs;
		
	    Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
	        Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), 
	        rank__c = 1, 
	        Group_By_Customer_Hierarchy__c = 'Bill To', 
	        Group_By_Sales_Orders__c = true,
	        Company__c = salesorder.Company__c
	    );    
	    insert igr;  
	    igr = [select id, is_Valid__c, Is_Active__c,rank__c,Group_By_Customer_Hierarchy__c,Company__c,Group_By_Sales_Orders__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        system.assertEquals(true, igr.Is_Active__c);
        
	    Test.StartTest();
	    ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);

        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(jr.success);
        
       	jr = GenerateInvoiceExt.next(true,salesorder.Id, salesorder);
        Boolean ErrorExists = false;
        for(Map<String, String> msg :jr.messages){
            if(msg.containsKey('message')){
                if(msg.get('message').contains('The fulfillments ready to invoice have values that will create 2 customer invoices for this sales order.')){
                    ErrorExists = true;
                    break;
                }
            }
        }
        system.assert(ErrorExists);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size());
       	
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
        boolean fromProcessFulFilment = false;
       	jr = GenerateInvoiceExt.finalizeInvoices(salesorder.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	ErrorExists = false; 
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
        
        list<Customer_Invoice__c> lCI = [Select Id, Finalized__c from Customer_Invoice__c where Sales_Order__c = :salesOrder.Id];
        system.assertEquals(2,lCI.size(),ApexPages.GetMessages());
        
   		SOQLUtil soql5 = new SOQLUtil('Customer_Invoice_Sub_Line__c');
	    soql5.addFields(new set<string>{'Id'});
	    Id accrualId = accrualFF.Id;
	    soql5.setWhereClause('Fulfillment__c =: accrualId');			
   	    list<Customer_Invoice_Sub_Line__c> ciSubLines = Database.query(soql5.getQuery());
   		system.assertEquals(1,ciSubLines.size());
        
       	ErrorExists = false;
        jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(!jr.success);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
   	    
       	Test.StopTest();  
    }
    
    static testMethod void SH_success_withExistingIGR() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
		
		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Ship To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c shipToCustomer = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
    	
    	SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Customer__c');
	    soql4.addFields(new set<string>{'Id'});
	    string sname = 'Customer Sold To 1';
	    soql4.setWhereClause('Name =: sname');			
   		Customer__c custSoldTo = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,custSoldTo.Id);
   		
   		SOQLUtil soql5 = new SOQLUtil('Payment_Term__c');
	    soql5.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql5.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,terms.Id);
        
        Shipment__c sh = new Shipment__c(Company__c = salesorder.Company__c, Customer__c = shipToCustomer.Id, Status__c = 'Staged', Type__c = 'Sales Order Shipment');
        insert sh;
        Shipment_Line__c shl = new Shipment_Line__c(Shipment__c = sh.Id, Sales_Order_Line__c = lSOLs[0].Id, Product__c = lSOLs[0].Product__c, Company__c = salesorder.Company__c);
        insert shl;
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Shipment_Line__c = shl.Id, 
                                   Sales_Order_Line__c = lSOLs[0].Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        Fulfillment__c accrualFF = new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Shipment_Line__c = shl.Id, 
                                   Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL, Sales_Order_Line__c = lSOLs[0].Id, Name = 'F2', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete');
        lFs.add(accrualFF);
        insert lFs;
        
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
	        Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), 
	        rank__c = 1, 
	        Group_By_Customer_Hierarchy__c = 'Bill To', 
	        Group_By_Shipments__c = true,
	        Company__c = salesorder.Company__c
	    );    
	    insert igr;
	    
        Test.StartTest();
        ApexPages.standardController con = new ApexPages.standardController(sh);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(sh.Id,'Shipment__c');
        system.assert(jr.success);
        
        jr = GenerateInvoiceExt.next(true,sh.Id, sh);
        Boolean ErrorExists = false;
        for(Map<String, String> msg :jr.messages){
            if(msg.containsKey('message')){
                if(msg.get('message').contains('The fulfillments ready to invoice have values that will create 2 customer invoices for this shipment')){
                    ErrorExists = true;
                    break;
                }
            }
        }
        system.assert(ErrorExists);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size());
       	
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = GenerateInvoiceExt.finalizeInvoices(sh.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Shipment__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	ErrorExists = false; 
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
        
        list<Customer_Invoice__c> lCI = [Select Id, Sold_To_Customer__c, Sales_Order__c, Finalized__c from Customer_Invoice__c where Shipment__c = :sh.Id];
        system.assertEquals(2,lCI.size(),ApexPages.GetMessages());
        system.assertEquals(custSoldTo.Id, lCI[0].Sold_To_Customer__c);
        system.assertEquals(salesOrder.Id, lCI[0].Sales_Order__c);
        SOQLUtil soql6 = new SOQLUtil('Customer_Invoice_Sub_Line__c');
	    soql6.addFields(new set<string>{'Id'});
	    Id accrualId = accrualFF.Id;
	    soql6.setWhereClause('Fulfillment__c =: accrualId');			
   	    list<Customer_Invoice_Sub_Line__c> ciSubLines = Database.query(soql6.getQuery());
   		system.assertEquals(1,ciSubLines.size());
        
       	ErrorExists = false;
        jr = GenerateInvoiceExt.validate(sh.Id,'Shipment__c');
        system.assert(!jr.success);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
        Test.StopTest();
    }
    
    static testMethod void AG_success_withExistingIGR() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		for(Sales_Order_Line__c sol : lSOLs){
        	sol.Rate_Basis__c = 'Quantity';
        }
        update lSOLs;
   	
   		SOQLUtil soql2 = new SOQLUtil('Agreement__c');
	    soql2.addFields(new set<string>{'Id','Company__c'});
	    soql2.setLimit(1);		
   		Agreement__c agmt = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,agmt.Id);
		
		SOQLUtil soql5 = new SOQLUtil('Customer__c');
	    soql5.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql5.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
   		SOQLUtil soql6 = new SOQLUtil('Agreement_Line__c');
	    soql6.addFields(new set<string>{'Id'});
	    Id AgreementId = agmt.Id;
	    soql6.setWhereClause('Agreement__c =: AgreementId');			
   		Agreement_Line__c agmtLine = Database.query(soql6.getQuery());
   		system.assertNotEquals(null,agmtLine.Id);
        
        agmt.Activation_Date__c = system.today().addDays(-30);
        update agmt;
        
        salesOrder.Agreement__c = agmt.Id;
        update salesOrder;
    
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                             Agreement_Line__c = agmtLine.Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        Fulfillment__c accrualFF = new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                   Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL, Agreement_Line__c = agmtLine.Id, Name = 'F2', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete');
        lFs.add(accrualFF);
        insert lFs;
        
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
	        Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), 
	        rank__c = 1, 
	        Group_By_Customer_Hierarchy__c = 'Corporate Parent', 
	        Group_By_Agreements__c = true,
	        Company__c = salesorder.Company__c
	    );    
	    insert igr;
        
        Test.StartTest();
        
        ApexPages.standardController con = new ApexPages.standardController(agmt);
        AgreementGenerateInvoiceExt ext = new AgreementGenerateInvoiceExt(con);
        JsonResult jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(jr.success);
        
       	jr = AgreementGenerateInvoiceExt.next(true,agmt.Id, agmt);
        Boolean ErrorExists = false;
        for(Map<String, String> msg :jr.messages){
            if(msg.containsKey('message')){
                if(msg.get('message').contains('The fulfillments ready to invoice have values that will create 2 customer invoices for this agreement.')){
                    ErrorExists = true;
                    break;
                }
            }
        }
        system.assert(ErrorExists);
        system.assertNotEquals(null, jr.records);
        system.assertEquals(2, jr.records.size());
       	
       	jr = AgreementGenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	//To be remove - populating ship to on CI explicitly
       	SOQLUtil soql8 = new SOQLUtil('Customer__c');
	    soql8.addFields(new set<string>{'Id'});
	    string sname = 'Customer Ship To 1';
	    soql8.setWhereClause('Name =: sname');			
   		Customer__c shipToCustomer = Database.query(soql8.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
       	list<Customer_Invoice__c> lstCI = new list<Customer_Invoice__c>();
       	for(Customer_Invoice__c ci: (list<Customer_Invoice__c>)jr.records){
       		lstCI.add(new Customer_Invoice__c(Id=ci.Id, Ship_to__c = shipToCustomer.Id));
       	}
       	update lstCI;
       	
       	jr = AgreementGenerateInvoiceExt.prefinalizeActions(lstCI);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = AgreementGenerateInvoiceExt.finalizeInvoices(agmt.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Agreement__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	ErrorExists = false; 
       	jr = AgreementGenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
		for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('has been created and finalized.')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
		}
        list<Customer_Invoice__c> lCI = [Select Id, Finalized__c from Customer_Invoice__c where Agreement__c = :agmt.Id];
        system.assertEquals(2,lCI.size(),ApexPages.GetMessages());
        
   		SOQLUtil soql7 = new SOQLUtil('Customer_Invoice_Sub_Line__c');
	    soql7.addFields(new set<string>{'Id'});
	    Id accrualId = accrualFF.Id;
	    soql7.setWhereClause('Fulfillment__c =: accrualId');			
   	    list<Customer_Invoice_Sub_Line__c> ciSubLines = Database.query(soql7.getQuery());
   		system.assertEquals(1,ciSubLines.size());
        
       	ErrorExists = false;
        jr = AgreementGenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(!jr.success);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
   	    
       	Test.StopTest();
    }
    
    static testMethod void SH_Exceptions_withExistingIGR() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
		
		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Ship To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c shipToCustomer = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
    	
    	SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Customer__c');
	    soql4.addFields(new set<string>{'Id'});
	    string sname = 'Customer Sold To 1';
	    soql4.setWhereClause('Name =: sname');			
   		Customer__c custSoldTo = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,custSoldTo.Id);
   		
   		SOQLUtil soql5 = new SOQLUtil('Payment_Term__c');
	    soql5.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql5.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,terms.Id);
        
        Shipment__c sh = new Shipment__c(Company__c = salesorder.Company__c, Customer__c = shipToCustomer.Id, Status__c = 'Staged', Type__c = 'Sales Order Shipment');
        insert sh;
        Shipment_Line__c shl = new Shipment_Line__c(Shipment__c = sh.Id, Sales_Order_Line__c = lSOLs[0].Id, Product__c = lSOLs[0].Product__c, Company__c = salesorder.Company__c);
        insert shl;
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.ID, Shipment_Line__c = shl.Id, 
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        insert lFs;
        Task t = new Task(WhatID = shl.Id, Type = 'Exception', Subject='Some Exception', Status= 'Open', Exception_Code__c = 'TEST-001');
        insert t;
       Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
	        Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), 
	        
	        rank__c = 1, 
	        Group_By_Customer_Hierarchy__c = 'Bill To', 
	        Group_By_Shipments__c = true,
	        Company__c = salesOrder.Company__c
	    );    
	    insert igr;
	    test.startTest();  
       ApexPages.standardController con = new ApexPages.standardController(sh);
       GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
       JsonResult jr = GenerateInvoiceExt.validate(sh.Id,'Shipment__c');
       system.assert(!jr.success);
       boolean ErrorExists = false;
       for(Map<String, String> msg :jr.messages){
        if(msg.containsKey('message')){
            if(msg.get('message').contains('We did not invoice the following fulfillments as the related shipment has an exception')){
                ErrorExists = true;
                break;
            }
        }
       }
       system.assertEquals( ErrorExists,true, jr.messages);
    		test.stopTest();  
    }

    static testMethod void SH_nofulfillments_withExistingIGR() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
		
		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Ship To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c shipToCustomer = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
    	
    	SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Customer__c');
	    soql4.addFields(new set<string>{'Id'});
	    string sname = 'Customer Sold To 1';
	    soql4.setWhereClause('Name =: sname');			
   		Customer__c custSoldTo = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,custSoldTo.Id);
   		
   		SOQLUtil soql5 = new SOQLUtil('Payment_Term__c');
	    soql5.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql5.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,terms.Id);
        
        Shipment__c sh = new Shipment__c(Company__c = salesorder.Company__c, Customer__c = shipToCustomer.Id, Status__c = 'Staged', Type__c = 'Sales Order Shipment');
        insert sh;
        Shipment_Line__c shl = new Shipment_Line__c(Shipment__c = sh.Id, Sales_Order_Line__c = lSOLs[0].Id, Product__c = lSOLs[0].Product__c, Company__c = salesorder.Company__c);
        insert shl;
        
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
	        Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), 
	        
	        rank__c = 1, 
	        Group_By_Customer_Hierarchy__c = 'Bill To', 
	        Group_By_Shipments__c = true,
	        Company__c = salesOrder.Company__c
	    );    
	    insert igr; 
	    test.startTest();  
       ApexPages.standardController con = new ApexPages.standardController(sh);
       GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
       JsonResult jr = GenerateInvoiceExt.validate(sh.Id,'Shipment__c');
       system.assert(!jr.success);
       boolean ErrorExists = false;
       for(Map<String, String> msg :jr.messages){
        if(msg.containsKey('message')){
            if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
                ErrorExists = true;
                break;
            }
        }
       }
        system.assertEquals( ErrorExists,true, jr.messages);
     	test.stopTest();      
    }
    
     static testMethod void AG_warningMoreThanOneOrderType_withExistingIGR() {
     	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c','Product__r.Description__c','Ship_From_Location__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		for(Sales_Order_Line__c sol : lSOLs){
        	sol.Rate_Basis__c = 'Quantity';
        }
        update lSOLs;
        
        SOQLUtil soql7 = new SOQLUtil('Customer__c');
	    soql7.addFields(new set<string>{'Id'});
	    string sname = 'Customer Ship To 1';
	    soql7.setWhereClause('Name =: sname');			
   		Customer__c shipToCustomer = Database.query(soql7.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
   		
   		SOQLUtil soql8 = new SOQLUtil('Customer__c');
	    soql8.addFields(new set<string>{'Id'});
	    string soname = 'Customer Sold To 1';
	    soql8.setWhereClause('Name =: soname');			
   		Customer__c soldToCustomer = Database.query(soql8.getQuery());
   		system.assertNotEquals(null,soldToCustomer.Id);
   	
   		SOQLUtil soql2 = new SOQLUtil('Agreement__c');
	    soql2.addFields(new set<string>{'Id','Company__c'});
	    soql2.setLimit(1);		
   		Agreement__c agmt = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,agmt.Id);
		
		SOQLUtil soql5 = new SOQLUtil('Customer__c');
	    soql5.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql5.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
   		SOQLUtil soql6 = new SOQLUtil('Agreement_Line__c');
	    soql6.addFields(new set<string>{'Id'});
	    Id AgreementId = agmt.Id;
	    soql6.setWhereClause('Agreement__c =: AgreementId');			
   		Agreement_Line__c agmtLine = Database.query(soql6.getQuery());
   		system.assertNotEquals(null,agmtLine.Id);
        
        agmt.Activation_Date__c = system.today().addDays(-30);
        update agmt;
        
        salesOrder.Agreement__c = agmt.Id;
        salesOrder.Ship_to__c = shipToCustomer.Id;
        update salesOrder;
    
        Sales_Order__c salesOrderNew = new Sales_Order__c(
                Company__c = salesorder.Company__c,
                Customer__c = soldToCustomer.id,
                Ship_To__c = shipToCustomer.id,
                Payment_Term__c = terms.id,
                Currency__c = lstCurrency[0].Id,
		        Bill_To__c = billToCustomer.Id,
		        Original_Sales_Order__c = 'so123', 
		        Type__c = 'Adjustment1',
		        Agreement__c = agmt.Id
	    );
		insert salesOrderNew;
		
		Sales_Order_Line__c salesOrderLineNew = new Sales_Order_Line__c();
        salesOrderLineNew.Company__c = salesorder.Company__c;
        salesOrderLineNew.Description__c = lSOLs[0].Product__r.Description__c;
        salesOrderLineNew.Discount_Percent__c = 2;
        salesOrderLineNew.Product__c = lSOLs[0].Product__c;
        salesOrderLineNew.Quantity_Ordered__c = 100;
        salesOrderLineNew.Required_Date__c = System.today()+5;
        salesOrderLineNew.Sales_Order__c = salesOrderNew.Id;
        salesOrderLineNew.Ship_From_Location__c = lSOLs[0].Ship_From_Location__c;
        salesOrderLineNew.Unit_Price__c = 11.12;
        salesOrderLineNew.Memo__c = 'salesOrderLine';
        salesOrderLineNew.Occurrence__c = 'Immediate';
        insert salesOrderLineNew;
       
	    list<Fulfillment__c> lFs = new list<Fulfillment__c>();
	    lFs.add(new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].Id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
	                                              Agreement_Line__c = agmtLine.Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
	    lFs.add(new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].Id, Payment_Term__c = terms.Id, Sales_Order_Line__c = salesOrderLineNew.Id,
	                                              Agreement_Line__c = agmtLine.Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = salesOrderLineNew.Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));                                      
	    insert lFs;
	    Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
	        Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), 
	        rank__c = 1, 
	        Group_By_Sales_Order_Types__c = true,
	        Group_By_Customer_Hierarchy__c = 'Corporate Parent', 
	        Group_By_Agreements__c = true,
	        Company__c = salesorder.Company__c
		);    
	    insert igr;
		    
	    Test.StartTest();
        
        ApexPages.standardController con = new ApexPages.standardController(agmt);
        AgreementGenerateInvoiceExt ext = new AgreementGenerateInvoiceExt(con);
        JsonResult jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(jr.success);
        
       	jr = AgreementGenerateInvoiceExt.next(true,agmt.Id, agmt);
       	system.assertEquals(null,jr.success);
       	boolean ErrorExists = false;
       	system.debug(logginglevel.error,'***'+jr.messages);
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('2 customer invoices for this agreement')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
        
       	jr = AgreementGenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	//To be remove - populating ship to on CI explicitly
       	list<Customer_Invoice__c> lstCI = new list<Customer_Invoice__c>();
       	for(Customer_Invoice__c ci: (list<Customer_Invoice__c>)jr.records){
       		lstCI.add(new Customer_Invoice__c(Id=ci.Id, Ship_to__c = shipToCustomer.Id));
       	}
       	update lstCI;
       	
       	jr = AgreementGenerateInvoiceExt.prefinalizeActions(lstCI);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = AgreementGenerateInvoiceExt.finalizeInvoices(agmt.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Agreement__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	ErrorExists = false;
       	jr = AgreementGenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>)jr.records);
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
        
        ErrorExists = false;
        jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(!jr.success);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
   	    
       	Test.StopTest();	
     }
    
     static testMethod void SO_warningForMorThanOneInvoice_withExistingIGR() {
     	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Sold To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c custSoldTo = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,custSoldTo.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
    	
    	Payment_Term__c terms1 = new Payment_Term__c(); 
        terms1.name = 'PT 2'; 
        terms1.Description__c = '2% discount in 10 days, due 30 days';
        terms1.Type__c = KSE.PAYMENT_TERM_DUE_DAYS; //AR-3 need to define type on Payment Terms. 
        terms1.Discount_Days__c = 20;
        terms1.Discount_Percent__c = 2;
        terms1.Due_Days__c = 30;
        insert terms1;
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[1].id, Payment_Term__c = terms1.Id, Sales_Order_Line__c = lSOLs[0].Id,
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));                                      
        insert lFs;
        
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
	        Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), 
	        
	        rank__c = 1, 
	        Group_By_Customer_Hierarchy__c = 'Bill To', 
	        Group_By_Sales_Orders__c = true,
	        Company__c = salesorder.Company__c
	    );    
	    insert igr;
	    
        Test.StartTest();
        ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(jr.success);
        
       	jr = GenerateInvoiceExt.next(true, salesorder.Id, salesorder);
       	system.assertEquals(null,jr.success);
       	boolean ErrorExists = false;
       	system.debug(logginglevel.error,'***'+jr.messages);
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('2 customer invoices for this sales order')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
        
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = GenerateInvoiceExt.finalizeInvoices(salesorder.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	ErrorExists = false;
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
       	
       	ErrorExists = false;
        jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(!jr.success);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
   	    
       	Test.StopTest();  
    }
    
    static testMethod void AG_warningForMorThanOneInvoice_withExistingIGR() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		for(Sales_Order_Line__c sol : lSOLs){
        	sol.Rate_Basis__c = 'Quantity';
        }
        update lSOLs;
        
        SOQLUtil soql7 = new SOQLUtil('Customer__c');
	    soql7.addFields(new set<string>{'Id'});
	    string sname = 'Customer Ship To 1';
	    soql7.setWhereClause('Name =: sname');			
   		Customer__c shipToCustomer = Database.query(soql7.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
   	
   		SOQLUtil soql2 = new SOQLUtil('Agreement__c');
	    soql2.addFields(new set<string>{'Id','Company__c'});
	    soql2.setLimit(1);		
   		Agreement__c agmt = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,agmt.Id);
		
		SOQLUtil soql5 = new SOQLUtil('Customer__c');
	    soql5.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql5.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
   		SOQLUtil soql6 = new SOQLUtil('Agreement_Line__c');
	    soql6.addFields(new set<string>{'Id'});
	    Id AgreementId = agmt.Id;
	    soql6.setWhereClause('Agreement__c =: AgreementId');			
   		Agreement_Line__c agmtLine = Database.query(soql6.getQuery());
   		system.assertNotEquals(null,agmtLine.Id);
        
        agmt.Activation_Date__c = system.today().addDays(-30);
        update agmt;
        
        salesOrder.Agreement__c = agmt.Id;
        salesOrder.Ship_to__c = shipToCustomer.Id;
        update salesOrder;
        
		Payment_Term__c terms1 = new Payment_Term__c(); 
        terms1.name = 'PT 2'; 
        terms1.Description__c = '2% discount in 10 days, due 30 days';
        terms1.Type__c = KSE.PAYMENT_TERM_DUE_DAYS; //AR-3 need to define type on Payment Terms. 
        terms1.Discount_Days__c = 20;
        terms1.Discount_Percent__c = 2;
        terms1.Due_Days__c = 30;
        insert terms1; 
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Agreement_Line__c = agmtLine.Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        lFs.add(new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[1].id, Payment_Term__c = terms1.Id, Sales_Order_Line__c = lSOLs[0].Id,
                                              Agreement_Line__c = agmtLine.Id, Name = 'F2', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));                                      
        insert lFs;
       
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
	        Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), 
	        rank__c = 1, 
	        Group_By_Customer_Hierarchy__c = 'Corporate Parent', 
	        Group_By_Agreements__c = true,
	        Company__c = salesOrder.Company__c
		    );    
		    
	    insert igr;
	   
        Test.StartTest();
        
        ApexPages.standardController con = new ApexPages.standardController(agmt);
        AgreementGenerateInvoiceExt ext = new AgreementGenerateInvoiceExt(con);
        JsonResult jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(jr.success);
        
       	jr = AgreementGenerateInvoiceExt.next(true, agmt.Id, agmt);
       	system.assertEquals(null,jr.success);
       	boolean ErrorExists = false;
       	system.debug(logginglevel.error,'***'+jr.messages);
   	    for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('2 customer invoices for this agreement')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
        
       	jr = AgreementGenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	//To be remove - populating ship to on CI explicitly
       	list<Customer_Invoice__c> lstCI = new list<Customer_Invoice__c>();
       	for(Customer_Invoice__c ci: (list<Customer_Invoice__c>)jr.records){
       		lstCI.add(new Customer_Invoice__c(Id=ci.Id, Ship_to__c = shipToCustomer.Id));
       	}
       	update lstCI;
       	
       	jr = AgreementGenerateInvoiceExt.prefinalizeActions(lstCI);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = AgreementGenerateInvoiceExt.finalizeInvoices(agmt.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Agreement__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(2, jr.records.size());
       	
       	ErrorExists = false;
       	jr = AgreementGenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>)jr.records);
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
        list<Customer_Invoice__c> lCI = [Select Id, Finalized__c from Customer_Invoice__c where Agreement__c = :agmt.Id];
        system.assertEquals(2,lCI.size(),ApexPages.GetMessages());
        
       	ErrorExists = false;
        jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(!jr.success);
        system.debug('***'+jr.messages);
       	for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.No_Fulfillments_To_Invoice)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
   	    system.assert(ErrorExists);
   	    
       	Test.StopTest();
    }
    
    static testMethod void AG_SOHasExceptions() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c','Product__r.Description__c','Ship_From_Location__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		for(Sales_Order_Line__c sol : lSOLs){
        	sol.Rate_Basis__c = 'Quantity';
        }
        update lSOLs;
        
        SOQLUtil soql7 = new SOQLUtil('Customer__c');
	    soql7.addFields(new set<string>{'Id'});
	    string sname = 'Customer Ship To 1';
	    soql7.setWhereClause('Name =: sname');			
   		Customer__c shipToCustomer = Database.query(soql7.getQuery());
   		system.assertNotEquals(null,shipToCustomer.Id);
   		
   		SOQLUtil soql8 = new SOQLUtil('Customer__c');
	    soql8.addFields(new set<string>{'Id'});
	    string soname = 'Customer Sold To 1';
	    soql8.setWhereClause('Name =: soname');			
   		Customer__c soldToCustomer = Database.query(soql8.getQuery());
   		system.assertNotEquals(null,soldToCustomer.Id);
   	
   		SOQLUtil soql2 = new SOQLUtil('Agreement__c');
	    soql2.addFields(new set<string>{'Id','Company__c'});
	    soql2.setLimit(1);		
   		Agreement__c agmt = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,agmt.Id);
		
		SOQLUtil soql5 = new SOQLUtil('Customer__c');
	    soql5.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql5.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
   		SOQLUtil soql6 = new SOQLUtil('Agreement_Line__c');
	    soql6.addFields(new set<string>{'Id'});
	    Id AgreementId = agmt.Id;
	    soql6.setWhereClause('Agreement__c =: AgreementId');			
   		Agreement_Line__c agmtLine = Database.query(soql6.getQuery());
   		system.assertNotEquals(null,agmtLine.Id);
        
        agmt.Activation_Date__c = system.today().addDays(-30);
        update agmt;
        
        salesOrder.Agreement__c = agmt.Id;
        salesOrder.Ship_to__c = shipToCustomer.Id;
        update salesOrder;
    
        Sales_Order__c salesOrderNew = new Sales_Order__c(
                Company__c = salesorder.Company__c,
                Customer__c = soldToCustomer.id,
                Ship_To__c = shipToCustomer.id,
                Payment_Term__c = terms.id,
                Currency__c = lstCurrency[0].Id,
		        Bill_To__c = billToCustomer.Id,
		        Original_Sales_Order__c = 'so123', 
		        Type__c = 'Adjustment1',
		        Agreement__c = agmt.Id
	    );
		insert salesOrderNew;
		
		Sales_Order_Line__c salesOrderLineNew = new Sales_Order_Line__c();
        salesOrderLineNew.Company__c = salesorder.Company__c;
        salesOrderLineNew.Description__c = lSOLs[0].Product__r.Description__c;
        salesOrderLineNew.Discount_Percent__c = 2;
        salesOrderLineNew.Product__c = lSOLs[0].Product__c;
        salesOrderLineNew.Quantity_Ordered__c = 100;
        salesOrderLineNew.Required_Date__c = System.today()+5;
        salesOrderLineNew.Sales_Order__c = salesOrderNew.Id;
        salesOrderLineNew.Ship_From_Location__c = lSOLs[0].Ship_From_Location__c;
        salesOrderLineNew.Unit_Price__c = 11.12;
        salesOrderLineNew.Memo__c = 'salesOrderLine';
        salesOrderLineNew.Occurrence__c = 'Immediate';
        insert salesOrderLineNew;
        
        //creating task to make has exception true
		Task t = new Task();
		t.OwnerId = UserInfo.getUserId();
		t.Subject = 'Exception';
		t.Status = 'Open';
		t.Priority = 'High';
		t.WhatId = lSOLs[0].Id;
		t.Type = 'Exception';
		t.Exception_Code__c = '010';
		insert t;
       
	    list<Fulfillment__c> lFs = new list<Fulfillment__c>();
	    lFs.add(new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].Id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
	                                              Agreement_Line__c = agmtLine.Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
	    lFs.add(new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].Id, Payment_Term__c = terms.Id, Sales_Order_Line__c = salesOrderLineNew.Id,
	                                              Agreement_Line__c = agmtLine.Id, Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = salesOrderLineNew.Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));                                      
	    insert lFs;
		    
	    Test.StartTest();
        
        ApexPages.standardController con = new ApexPages.standardController(agmt);
        AgreementGenerateInvoiceExt ext = new AgreementGenerateInvoiceExt(con);
        JsonResult jr = AgreementGenerateInvoiceExt.validate(agmt.Id,'Agreement__c');
        system.assert(jr.success);
        
        jr = AgreementGenerateInvoiceExt.next(true,agmt.Id, agmt);
       	system.assertEquals(false,jr.success);
       	boolean ErrorExists = false;
		system.debug('***'+jr.messages);
		for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.Check_IGR_checkbox)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
        
        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
	        Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), 
	        rank__c = 1, 
	        Group_By_Sales_Order_Types__c = true,
	        Group_By_Customer_Hierarchy__c = 'Corporate Parent', 
	        Group_By_Agreements__c = true,
	        Company__c = salesorder.Company__c
		);    
	    insert igr;
	    
       	jr = AgreementGenerateInvoiceExt.next(true,agmt.Id, agmt);
       	system.assertEquals(true,jr.success);
       	ErrorExists = false;
		system.debug('***'+jr.messages);
		for(Map<String, String> msg :jr.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('Related Sales Order is having exceptions')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
   	    }
        system.assert(ErrorExists);
        
       	jr = AgreementGenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	//To be remove - populating ship to on CI explicitly
       	list<Customer_Invoice__c> lstCI = new list<Customer_Invoice__c>();
       	for(Customer_Invoice__c ci: (list<Customer_Invoice__c>)jr.records){
       		lstCI.add(new Customer_Invoice__c(Id=ci.Id, Ship_to__c = shipToCustomer.Id));
       	}
       	update lstCI;
       	
       	jr = AgreementGenerateInvoiceExt.prefinalizeActions(lstCI);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = AgreementGenerateInvoiceExt.finalizeInvoices(agmt.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Agreement__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	ErrorExists = false;
       	jr = AgreementGenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>)jr.records);
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
        
       	Test.StopTest();
    }
    
    static testMethod void callOtherMethods() {
    	Test.StartTest();
    	JsonResult jr = AgreementGenerateInvoiceExt.callUserDefinedMethod(null, null);
        jr = AgreementGenerateInvoiceExt.getValues();
        Test.StopTest();
    }
    
    static testMethod void Adhoc_withoutRules() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    soql3.setWhereClause('ISO_Code__c =: USDname');			
   		Currency__c usd = Database.query(soql3.getQuery());
   		system.assertNotEquals(null,usd.Id);
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
   		SOQLUtil soql5 = new SOQLUtil('UOM__c');
	    soql5.addFields(new set<string>{'Id'});
	    string strWeek = 'Week';
	    soql5.setWhereClause('Name =: strWeek');			
   		UOM__c week = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,week.Id);

        Test.startTest(); 
        insert new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = usd.id, Payment_Term__c = terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
	                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Recurring', Status__c ='Complete',
	                                              Start_Date__c = DateTime.newInstance(2016,11,13,0,0,0), End_Date__c = DateTime.newInstance(2016,12,2,0,0,0), Pricing_UOM__c = week.Id, Billing_UOM__c = week.Id, 
	                                              Recurrence_Start_Date__c =  DateTime.newInstance(2016,11,13,0,0,0));
       
       ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(jr.success);
        
       	jr = GenerateInvoiceExt.next(false,salesorder.Id, salesorder);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = GenerateInvoiceExt.finalizeInvoices(salesorder.Id, fromProcessFulFilment,(list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
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
	   list<Customer_Invoice__c> lCI = [Select Id, Invoice_Type__c, Finalized__c, (Select Id from Customer_Invoice_Lines__r) from Customer_Invoice__c where Sales_Order__c = :salesOrder.Id];
	   system.assertEquals(1,lCI.size(),ApexPages.GetMessages());
	   system.assertEquals(3,lCI[0].Customer_Invoice_Lines__r.size(),ApexPages.GetMessages());
    }

	static testMethod void Adhoc_withoutRules_InvoiceAhead() {
		SOQLUtil soql = new SOQLUtil('Sales_Order__c');
		soql.addFields(new set<string>{
				'Id', 'Company__c'
		});
		soql.setLimit(1);
		Sales_Order__c salesorder = Database.query(soql.getQuery());
		Id soId = salesorder.Id;
		system.assertNotEquals(null, salesorder.Id);

		SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
		soql1.addFields(new set<string>{
				'Id', 'Product__c'
		});
		soql1.setWhereClause('Sales_Order__c =: soId');
		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
		system.assertEquals(2, lSOLs.size());

		SOQLUtil soql2 = new SOQLUtil('Customer__c');
		soql2.addFields(new set<string>{
				'Id'
		});
		string cname = 'Customer Bill To 1';
		soql2.setWhereClause('Name =: cname');
		Customer__c billToCustomer = Database.query(soql2.getQuery());
		system.assertNotEquals(null, billToCustomer.Id);

		SOQLUtil soql3 = new SOQLUtil('Currency__c');
		soql3.addFields(new set<string>{
				'Id'
		});
		string USDname = 'USD';
		soql3.setWhereClause('ISO_Code__c =: USDname');
		Currency__c usd = Database.query(soql3.getQuery());
		system.assertNotEquals(null, usd.Id);

		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
		soql4.addFields(new set<string>{
				'Id'
		});
		string PTname = '2/10 Net 30';
		soql4.setWhereClause('Name =: PTname');
		Payment_Term__c terms = Database.query(soql4.getQuery());
		system.assertNotEquals(null, terms.Id);

		SOQLUtil soql5 = new SOQLUtil('UOM__c');
		soql5.addFields(new set<string>{
				'Id'
		});
		string strWeek = 'Week';
		soql5.setWhereClause('Name =: strWeek');
		UOM__c week = Database.query(soql5.getQuery());
		system.assertNotEquals(null, week.Id);

		Test.startTest();
		insert new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015, 5, 20, 0, 0, 0), Currency__c = usd.id, Payment_Term__c = terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
				Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Recurring', Status__c = 'Complete',
				Start_Date__c = DateTime.newInstance(2016, 11, 13, 0, 0, 0), End_Date__c = DateTime.newInstance(2016, 12, 2, 0, 0, 0), Pricing_UOM__c = week.Id, Billing_UOM__c = week.Id,
				Recurrence_Start_Date__c = DateTime.newInstance(2016, 11, 13, 0, 0, 0), Invoice_Ahead__c = true);

		ApexPages.standardController con = new ApexPages.standardController(salesorder);
		GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
		JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id, 'Sales_Order__c');
		system.assert(jr.success);

		jr = GenerateInvoiceExt.next(false, salesorder.Id, salesorder);
		system.assert(jr.success);
		system.assertNotEquals(null, jr.records);
		system.assertEquals(1, jr.records.size());

		jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
		system.assert(jr.success);
		system.assertNotEquals(null, jr.records);
		system.assertEquals(1, jr.records.size());

		jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>) jr.records);
		system.assert(jr.success);
		system.assertNotEquals(null, jr.records);
		system.assertEquals(1, jr.records.size());

		boolean fromProcessFulFilment = false;
		jr = GenerateInvoiceExt.finalizeInvoices(salesorder.Id, fromProcessFulFilment, (list<Customer_Invoice__c>) jr.records, 'Sales_Order__c');
		system.assert(jr.success);
		system.assertNotEquals(null, jr.records);
		system.assertEquals(1, jr.records.size());

		boolean ErrorExists = false;
		jr = GenerateInvoiceExt.autoApplyPrepayments((list<Customer_Invoice__c>) jr.records);
		system.assert(jr.success);
		for (Map<String, String> msg :jr.messages) {
			if (msg.containsKey('message')) {
				if (msg.get('message').contains('has been created and finalized.')) {
					ErrorExists = true;
					break;
				}
			}
		}
		system.assert(ErrorExists);

		Test.stopTest();
		list<Customer_Invoice__c> lCI = [Select Id, Invoice_Type__c, Finalized__c, (Select Id from Customer_Invoice_Lines__r) from Customer_Invoice__c where Sales_Order__c = :salesOrder.Id];
		system.assertEquals(1, lCI.size(), ApexPages.GetMessages());
		system.assertEquals(3, lCI[0].Customer_Invoice_Lines__r.size(), ApexPages.GetMessages());
	}

    static testMethod void Adhoc_withoutRules_withLastBillDate() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    soql3.setWhereClause('ISO_Code__c =: USDname');			
   		Currency__c usd = Database.query(soql3.getQuery());
   		system.assertNotEquals(null,usd.Id);
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
   		SOQLUtil soql5 = new SOQLUtil('UOM__c');
	    soql5.addFields(new set<string>{'Id'});
	    string strWeek = 'Week';
	    soql5.setWhereClause('Name =: strWeek');			
   		UOM__c week = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,week.Id);

        Test.startTest(); 
        insert new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = usd.id, Payment_Term__c = terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
	                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Recurring', Status__c ='Complete',
	                                              Start_Date__c = DateTime.newInstance(2016,11,13,0,0,0), End_Date__c = DateTime.newInstance(2016,12,2,0,0,0), Pricing_UOM__c = week.Id, Billing_UOM__c = week.Id, 
	                                              Recurrence_Start_Date__c =  DateTime.newInstance(2016,11,13,0,0,0), Last_Bill_Date__c =  DateTime.newInstance(2016,11,20,0,0,0));
       
       
       ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(jr.success);
        
       	jr = GenerateInvoiceExt.next(false,salesorder.Id, salesorder);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = GenerateInvoiceExt.finalizeInvoices(salesorder.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
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
    	
	   list<Customer_Invoice__c> lCI = [Select Id, Invoice_Type__c, Finalized__c, (Select Id from Customer_Invoice_Lines__r) from Customer_Invoice__c where Sales_Order__c = :salesOrder.Id];
	   system.assertEquals(1,lCI.size(),ApexPages.GetMessages());
	   system.assertEquals(2,lCI[0].Customer_Invoice_Lines__r.size(),ApexPages.GetMessages());
    }
    
    static testMethod void zero_dollar_CI_closed() {
    	SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		for(Sales_Order_Line__c sol:lSOLs){
   			sol.Discount_Percent__c = 100;
   		}
   		update lSOLs;
   		
   		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Sold To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c custSoldTo = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,custSoldTo.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    string GBPname = 'GBP';
	    soql3.setWhereClause('ISO_Code__c =: USDname or ISO_Code__c =: GBPname');			
   		list<Currency__c> lstCurrency = Database.query(soql3.getQuery());
   		system.assertEquals(2,lstCurrency.size());
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = custSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = lstCurrency[0].id, Payment_Term__c = terms.Id, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Sales', Status__c ='Complete'));
        insert lFs;
        Test.StartTest();
        
        ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(jr.success);
        
       	jr = GenerateInvoiceExt.next(false,salesorder.Id, salesorder);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	boolean fromProcessFulFilment = false;
       	jr = GenerateInvoiceExt.finalizeInvoices(salesorder.Id, fromProcessFulFilment, (list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
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
        
   		SOQLUtil soql5 = new SOQLUtil('Customer_Invoice__c');
	    soql5.addFields(new set<string>{'Id','Status__c','Date_Time_Paid__c'});
	    soql5.setWhereClause('Sales_Order__c =: soId');			
   	    list<Customer_Invoice__c> lstCI = Database.query(soql5.getQuery());
   		system.assertEquals(1,lstCI.size());
   		system.assertEquals('Closed',lstCI.get(0).Status__c);
   		system.assertNotEquals(null,lstCI.get(0).Date_Time_Paid__c);
   	    
       	Test.StopTest();
    }
    
    static testMethod void Adhoc_withRules_Cancel() {
		SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    soql3.setWhereClause('ISO_Code__c =: USDname');			
   		Currency__c usd = Database.query(soql3.getQuery());
   		system.assertNotEquals(null,usd.Id);
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
   		SOQLUtil soql5 = new SOQLUtil('UOM__c');
	    soql5.addFields(new set<string>{'Id'});
	    string strWeek = 'Week';
	    soql5.setWhereClause('Name =: strWeek');			
   		UOM__c week = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,week.Id);
   		
   		 Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
	        Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), 
	        rank__c = 1, 
	        Group_By_Customer_Hierarchy__c = 'Bill To', 
	        Group_By_Sales_Orders__c = true,
	        Company__c = salesorder.Company__c,
	        Use_Billing_Frequency_on_Fulfillment__c = true 
	    );    
	    insert igr;

        Test.startTest(); 
        Fulfillment__c f = new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = usd.id, Payment_Term__c = terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
	                                          Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Recurring', Status__c ='Complete',
	                                          Start_Date__c = DateTime.newInstance(2016,11,13,0,0,0), End_Date__c = DateTime.newInstance(2016,12,2,0,0,0), Pricing_UOM__c = week.Id, Billing_UOM__c = week.Id, 
	                                          Recurrence_Start_Date__c =  DateTime.newInstance(2016,11,13,0,0,0),Invoice_Ahead__c = true); 
        insert f;

       ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(jr.success);
        
       	jr = GenerateInvoiceExt.next(true,salesorder.Id, salesorder);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(3, jr.records.size());
       	
       	jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(3, jr.records.size());
       	
       	jr = GenerateInvoiceExt.finalizeInvoices(salesorder.Id, false, (list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(3, jr.records.size());
       	
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
       system.assertNotEquals(null,[Select Last_Bill_Date__c from Fulfillment__c where Id =:f.Id].Last_Bill_Date__c);
	   Test.stopTest();
    	
	   list<Customer_Invoice__c> lCI = [Select Id, Invoice_Type__c, Finalized__c, (Select Id from Customer_Invoice_Lines__r) from Customer_Invoice__c where Sales_Order__c = :salesOrder.Id];
	   system.assertEquals(3,lCI.size(),ApexPages.GetMessages());
	   system.assertEquals(1,lCI[0].Customer_Invoice_Lines__r.size(),ApexPages.GetMessages());
	   system.assertEquals(1,lCI[1].Customer_Invoice_Lines__r.size(),ApexPages.GetMessages());
	   system.assertEquals(1,lCI[2].Customer_Invoice_Lines__r.size(),ApexPages.GetMessages());
	   
	   list<Customer_Invoice__c> lstCI = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Currency__c from Customer_Invoice__c where id = :lCI];
	   CustomerInvoiceVoidCancelExt controller = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(lstCI[2]));
	   system.assert(!controller.getDisableCancel() == true);
	   controller.cancelDocs();
	   system.assertNotEquals(null,[Select Last_Bill_Date__c from Fulfillment__c where Id =:f.Id].Last_Bill_Date__c);
	   
	   controller = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(lstCI[1]));
	   system.assert(!controller.getDisableCancel() == true);
	   controller.cancelDocs();
	   system.assertNotEquals(null,[Select Last_Bill_Date__c from Fulfillment__c where Id =:f.Id].Last_Bill_Date__c);
	   
	   controller = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(lstCI[0]));
	   system.assert(!controller.getDisableCancel() == true);
	   controller.cancelDocs();
	   system.assertEquals(null,[Select Last_Bill_Date__c from Fulfillment__c where Id =:f.Id].Last_Bill_Date__c);
	   
	   for(Customer_Invoice__c ci: [Select id,Status__c, Transaction_Date__c,Balance__c from Customer_Invoice__c where id = :lstCI]){
	   		system.assertEquals(ci.Status__c, 'Cancelled');
	   }  
	}
	
	static testMethod void Adhoc_withRules_Cancel2(){
		SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new set<string>{'Id','Company__c'});			
   	    soql.setLimit(1);
   		Sales_Order__c salesorder = Database.query(soql.getQuery());
   		Id soId = salesorder.Id;
    	system.assertNotEquals(null,salesorder.Id);
    		
    	SOQLUtil soql1 = new SOQLUtil('Sales_Order_Line__c');
	    soql1.addFields(new set<string>{'Id','Product__c'});
	    soql1.setWhereClause('Sales_Order__c =: soId');			
   		list<Sales_Order_Line__c> lSOLs = Database.query(soql1.getQuery());
   		system.assertEquals(2,lSOLs.size());
   		
   		SOQLUtil soql2 = new SOQLUtil('Customer__c');
	    soql2.addFields(new set<string>{'Id'});
	    string cname = 'Customer Bill To 1';
	    soql2.setWhereClause('Name =: cname');			
   		Customer__c billToCustomer = Database.query(soql2.getQuery());
   		system.assertNotEquals(null,billToCustomer.Id);
   		
   		SOQLUtil soql3 = new SOQLUtil('Currency__c');
	    soql3.addFields(new set<string>{'Id'});
	    string USDname = 'USD';
	    soql3.setWhereClause('ISO_Code__c =: USDname');			
   		Currency__c usd = Database.query(soql3.getQuery());
   		system.assertNotEquals(null,usd.Id);
   		
   		SOQLUtil soql4 = new SOQLUtil('Payment_Term__c');
	    soql4.addFields(new set<string>{'Id'});
	    string PTname = '2/10 Net 30';
	    soql4.setWhereClause('Name =: PTname');			
   		Payment_Term__c terms = Database.query(soql4.getQuery());
   		system.assertNotEquals(null,terms.Id);
   		
   		SOQLUtil soql5 = new SOQLUtil('UOM__c');
	    soql5.addFields(new set<string>{'Id'});
	    string Month = 'Calendar Month';
	    soql5.setWhereClause('Name =: Month');			
   		UOM__c MonthUOM = Database.query(soql5.getQuery());
   		system.assertNotEquals(null,MonthUOM.Id);
   		
   		 Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
	        Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), 
	        rank__c = 1, 
	        Group_By_Customer_Hierarchy__c = 'Bill To', 
	        Group_By_Sales_Orders__c = true,
	        Company__c = salesorder.Company__c,
	        Use_Billing_Frequency_on_Fulfillment__c = true 
	    );    
	    insert igr;

        Test.startTest(); 
        Fulfillment__c f = new Fulfillment__c(Customer__c = billToCustomer.Id, Fulfillment_Date__c = DateTime.newInstance(2017,1,27,0,0,0), Currency__c = usd.id, Payment_Term__c = terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
	                                          Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Price_Type__c = 'Recurring', Status__c ='Complete',
	                                          Start_Date__c = DateTime.newInstance(2017,1,27,0,0,0),End_Date__c = DateTime.newInstance(2017,6,22,0,0,0), Pricing_UOM__c = MonthUOM.Id, Billing_UOM__c = MonthUOM.Id, 
	                                          Recurrence_Start_Date__c =  DateTime.newInstance(2017,4,27,0,0,0),Invoice_Ahead__c = true); 
        insert f;

       ApexPages.standardController con = new ApexPages.standardController(salesorder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        JsonResult jr = GenerateInvoiceExt.validate(salesorder.Id,'Sales_Order__c');
        system.assert(jr.success);
        
       	jr = GenerateInvoiceExt.next(true,salesorder.Id, salesorder);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(1, jr.records.size());
       	
       	jr = GenerateInvoiceExt.createInvoice(JSON.serialize(jr.records));
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(3, jr.records.size());
       	
       	jr = GenerateInvoiceExt.prefinalizeActions((list<Customer_Invoice__c>)jr.records);
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(3, jr.records.size());
       	
       	jr = GenerateInvoiceExt.finalizeInvoices(salesorder.Id, false, (list<Customer_Invoice__c>)jr.records, 'Sales_Order__c');
       	system.assert(jr.success);
       	system.assertNotEquals(null, jr.records);
       	system.assertEquals(3, jr.records.size());
       	
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
       system.assertNotEquals(null,[Select Last_Bill_Date__c from Fulfillment__c where Id =:f.Id].Last_Bill_Date__c);
	   Test.stopTest();
    	
	   list<Customer_Invoice__c> lCI = [Select Id, Invoice_Type__c, Finalized__c, (Select Id from Customer_Invoice_Lines__r) from Customer_Invoice__c where Sales_Order__c = :salesOrder.Id];
	   system.assertEquals(3,lCI.size(),ApexPages.GetMessages());
	   system.assertEquals(1,lCI[0].Customer_Invoice_Lines__r.size(),ApexPages.GetMessages());
	   system.assertEquals(1,lCI[1].Customer_Invoice_Lines__r.size(),ApexPages.GetMessages());
	   system.assertEquals(1,lCI[2].Customer_Invoice_Lines__r.size(),ApexPages.GetMessages());
	   
	   list<Customer_Invoice__c> lstCI = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Currency__c from Customer_Invoice__c where id = :lCI];
	   CustomerInvoiceVoidCancelExt controller = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(lstCI[2]));
	   system.assert(!controller.getDisableCancel() == true);
	   controller.cancelDocs();
	   Fulfillment__c fl = [Select Last_Bill_Date__c from Fulfillment__c where Id =:f.Id];
	   system.assertEquals(true,string.valueOf(fl.Last_Bill_Date__c).contains('2017-04-27'),fl.Last_Bill_Date__c);
	   
	   controller = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(lstCI[1]));
	   system.assert(!controller.getDisableCancel() == true);
	   controller.cancelDocs();
	   fl = [Select Last_Bill_Date__c from Fulfillment__c where Id =:f.Id];
	   system.assertEquals(true,string.valueOf(fl.Last_Bill_Date__c).contains('2017-01-27'),fl.Last_Bill_Date__c);
	   
	   controller = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(lstCI[0]));
	   system.assert(!controller.getDisableCancel() == true);
	   controller.cancelDocs();
	   fl = [Select Last_Bill_Date__c from Fulfillment__c where Id =:f.Id];
	   system.assertEquals(null,fl.Last_Bill_Date__c);
	   
	   for(Customer_Invoice__c ci: [Select id,Status__c, Transaction_Date__c,Balance__c from Customer_Invoice__c where id = :lstCI]){
	   		system.assertEquals(ci.Status__c, 'Cancelled');
	   }  
	}
}