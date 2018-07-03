@isTest
private class FinalizeServiceTest {

	static testMethod void testAutoBackdating_DefaultingFD() {
		TestFuel data = new TestFuel();
    	List<Period__c> periods = data.periodList;
    	
        
		// update Configuration
        Configuration__c c = data.AutoBackdatingConfigVal;
		//c.name = 'AutoBackdateToOpenSubledgers';
		c.Value__c = 'Yes';
		update c;
		// create a SD with different TD, SLC combinations
		Datetime tmpTD = system.now().addSeconds(-10);
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = tmpTD;
        custInvoice1.transaction_date__c = tmpTD;
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
     	Datetime tmpnow = system.now();
     	Period__c p;
     	for(Period__c thisPeriod : periods){
        	if(thisPeriod.period_start__c <= tmpnow && tmpnow < thisPeriod.period_end__c ){
        		p = thisPeriod;
        		break;
        	}
        }
        system.assert(p != null,'Expected to find current open period'); 
        //Datetime tmpSLC = system.now().addSeconds(-1);
        Datetime tmpSLClose = system.now().addSeconds(-1);
        //p.AR_Subledger_Cutoff__c = tmpSLC;
        p.AR_Subledger_Closed__c = tmpSLClose;
		
		PeriodService.systemEditable.add(p.Id);
		update p;
		
     	custInvoice1.Finalized__c = true;
     	update  custInvoice1;
     	
     	custInvoice1 = [Select id, Finalized_Date__c, Posting_Date__c, Transaction_Date__c
     										from Customer_Invoice__c
     										where id = :custInvoice1.id];
     										
     	p = [Select id, Name, AR_Subledger_Cutoff__c, AR_Subledger_Closed__c, period_start__c, period_end__c from Period__c where id = :p.id ];
     	
     	// Test that expected date is populated as posting date 
     	system.assertEquals(custInvoice1.Posting_Date__c, custInvoice1.Finalized_Date__c,'custInvoice1:'+custInvoice1 + 'p.AR_Subledger_Closed__c:'+p.AR_Subledger_Closed__c +'p.AR_Subledger_Cutoff__c:'+p.AR_Subledger_Cutoff__c+'p:'+p);
 	
	}
	
	static testMethod void testAutoBackdating_DefaultingTD() {
		TestFuel data = new TestFuel();
    	List<Period__c> periods = data.periodList;
    	
		// update Configuration
        Configuration__c c = data.AutoBackdatingConfigVal;
		//c.name = 'AutoBackdateToOpenSubledgers';
		c.Value__c = 'Yes';
		update c;
		// create a SD with different TD, SLC combinations
		Datetime tmpnow = system.now();
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = tmpnow;
        custInvoice1.transaction_date__c = tmpnow;
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
     	//Datetime tmpnow = system.now();
     	Period__c p;
     	for(Period__c thisPeriod : periods){
        	if(thisPeriod.period_start__c <= tmpnow && tmpnow < thisPeriod.period_end__c ){
        		p = thisPeriod;
        		break;
        	}
        }
        system.assert(p != null,'Expected to find current open period'); 
      
     	custInvoice1.Finalized__c = true;
     	update  custInvoice1;
     	
     	custInvoice1 = [Select id, Finalized_Date__c, Posting_Date__c, Transaction_Date__c
     										from Customer_Invoice__c
     										where id = :custInvoice1.id];
     										
     	p = [Select id, Name, AR_Subledger_Cutoff__c, AR_Subledger_Closed__c, period_start__c, period_end__c from Period__c where id = :p.id ];
     	
     	// Test that expected date is populated as posting date 
     	system.assertEquals(custInvoice1.Posting_Date__c, custInvoice1.Transaction_Date__c,'custInvoice1:'+custInvoice1 + 'p.AR_Subledger_Closed__c:'+p.AR_Subledger_Closed__c +'p.AR_Subledger_Cutoff__c:'+p.AR_Subledger_Cutoff__c+'p:'+p);
 	
	}
	
	static testMethod void testAutoBackdating_DefaultingbasedonCustomSetting_SLCMinus1() {
		TestFuel data = new TestFuel();
    	
		// update Configuration
        Configuration__c c = data.AutoBackdatingConfigVal;
        //c.name = 'AutoBackdateToOpenSubledgers';
        c.Value__c = 'Yes';
        update c;
        
        Configuration__c cutoffsConfig = new Configuration__c();
        cutoffsConfig.Name = 'EnableCutoffs';
        cutoffsConfig.Value__c = 'YeS';
        insert cutoffsConfig;
        
        Integer currentyear = system.now().year();
        Integer currentMonth = system.now().month();
        
		Period__c p = new Period__c();
		p.Company__c = data.company.id;
     	p.Period_Start__c = datetime.newInstance(currentyear, currentMonth, 1, 0, 0, 0);
     	p.Period_End__c = datetime.newInstance((currentMonth == 12 ? currentyear + 1 : currentyear), (currentMonth == 12 ? 1 : currentMonth + 1), 1, 0, 0, 0);
     	p.AR_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.AP_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.FA_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Inventory_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Shipment_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Receiving_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.JE_Cutoff__c = p.Period_End__c;
     	p.Open__c = true;
 		Fiscal_Year__c fy = new Fiscal_Year__c();
		fy.company__c =  data.company.id;
		fy.fiscal_year_start_date__c = p.period_start__c;
		fy.fiscal_year_end_date__c = p.period_end__c.addMonths(3);
		
		insert fy;
		p.fiscalyear__c = fy.Id;
     	
     	insert p;
     	
		// create a SD with different TD, SLC combinations
		Datetime tmpnow = system.now();
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = p.Period_End__c.addDays(-5);
        custInvoice1.transaction_date__c = p.Period_End__c.addDays(-5);
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
       
     	custInvoice1.Finalized__c = true;
     	update  custInvoice1;
     	
     	custInvoice1 = [Select id, Finalized_Date__c, Posting_Date__c, Transaction_Date__c
     										from Customer_Invoice__c
     										where id = :custInvoice1.id];
     										
     	p = [Select id, Name, AR_Subledger_Cutoff__c, AR_Subledger_Closed__c, period_start__c, period_end__c from Period__c where id = :p.id ];
     	
     	// Test that expected date is populated as posting date 
     	system.assertEquals(custInvoice1.Posting_Date__c, p.AR_Subledger_Cutoff__c.addSeconds(-1),'custInvoice1:'+custInvoice1 + 'p.AR_Subledger_Closed__c:'+p.AR_Subledger_Closed__c +'p.AR_Subledger_Cutoff__c:'+p.AR_Subledger_Cutoff__c+'p:'+p);
 	
	}
	
	static testMethod void testAutoBackdating_DefaultingbasedonCustomSetting_TD() {
		TestFuel data = new TestFuel();
    	
		// update Configuration
        Configuration__c c = data.AutoBackdatingConfigVal;
		//c.name = 'AutoBackdateToOpenSubledgers';
		c.Value__c = 'Yes';
		update c;
		
		Integer currentyear = system.now().year();
        Integer currentMonth = system.now().month();
        
		Period__c p = new Period__c();
		p.Company__c = data.company.id;
     	p.Period_Start__c = datetime.newInstance(currentyear, currentMonth, 1, 0, 0, 0);
     	p.Period_End__c = datetime.newInstance((currentMonth == 12 ? currentyear + 1 : currentyear), (currentMonth == 12 ? 1 : currentMonth + 1), 1, 0, 0, 0);
     	//system.assert(p == null,'p.Period_Start__c:'+p.Period_Start__c+'p.Period_End__c:'+p.Period_End__c);
     	p.AR_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.AP_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.FA_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Inventory_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Shipment_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Receiving_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.JE_Cutoff__c = p.Period_End__c;
     	p.Open__c = true;
     	
		Fiscal_Year__c fy = new Fiscal_Year__c();
		fy.company__c =  data.company.id;
		fy.fiscal_year_start_date__c = p.period_start__c;
		fy.fiscal_year_end_date__c = p.period_end__c.addMonths(3);
		
		insert fy;
		p.fiscalyear__c = fy.Id;
     	insert p;
     	
		// create a SD with different TD, SLC combinations
		Datetime tmpnow = system.now();
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = p.Period_End__c.addDays(-8);
        custInvoice1.transaction_date__c = p.Period_End__c.addDays(-8);
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
       
     	custInvoice1.Finalized__c = true;
     	update  custInvoice1;
     	
     	custInvoice1 = [Select id, Finalized_Date__c, Posting_Date__c, Transaction_Date__c
     										from Customer_Invoice__c
     										where id = :custInvoice1.id];
     										
     	p = [Select id, Name, AR_Subledger_Cutoff__c, AR_Subledger_Closed__c, period_start__c, period_end__c from Period__c where id = :p.id ];
     	
     	// Test that expected date is populated as posting date 
     	system.assertEquals(custInvoice1.Posting_Date__c,custInvoice1.Transaction_Date__c ,'custInvoice1:'+custInvoice1 + 'p.AR_Subledger_Closed__c:'+p.AR_Subledger_Closed__c +'p.AR_Subledger_Cutoff__c:'+p.AR_Subledger_Cutoff__c+'p:'+p);
 	
	}
	
	static testMethod void testAutoBackdating_CustomSettingwithValueNo() {
		TestFuel data = new TestFuel();
    	
		// Commenting as Configuration from testFuel  has value No.
        //Configuration__c c = data.AutoBackdatingConfigVal;
		//c.name = 'AutoBackdateToOpenSubledgers';
		//c.Value__c = 'No';
		//update c;
		
		Integer currentyear = system.now().year();
        Integer currentMonth = system.now().month();
        
		Period__c p = new Period__c();
		p.Company__c = data.company.id;
     	p.Period_Start__c = datetime.newInstance(currentyear, currentMonth, 1, 0, 0, 0);
     	p.Period_End__c = datetime.newInstance((currentMonth == 12 ? currentyear + 1 : currentyear), (currentMonth == 12 ? 1 : currentMonth + 1), 1, 0, 0, 0);
     	//system.assert(p == null,'p.Period_Start__c:'+p.Period_Start__c+'p.Period_End__c:'+p.Period_End__c);
     	p.AR_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.AP_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.FA_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Inventory_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Shipment_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Receiving_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.JE_Cutoff__c = p.Period_End__c;
     	p.Open__c = true;

		Fiscal_Year__c fy = new Fiscal_Year__c();
		fy.company__c =  data.company.id;
		fy.fiscal_year_start_date__c = p.period_start__c;
		fy.fiscal_year_end_date__c = p.period_end__c.addMonths(3);
		
		insert fy;
		p.fiscalyear__c = fy.Id;
     	
     	insert p;
     	
		// create a SD with different TD, SLC combinations
		Datetime tmpnow = system.now();
		Datetime tmpTD = tmpnow > p.Period_End__c.addDays(-7) ? tmpnow :p.Period_End__c.addDays(-7);
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = tmpnow;
        custInvoice1.transaction_date__c = tmpnow;
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
       
     	custInvoice1.Finalized__c = true;
     	update  custInvoice1;
     	
     	custInvoice1 = [Select id, Finalized_Date__c, Posting_Date__c, Transaction_Date__c
     										from Customer_Invoice__c
     										where id = :custInvoice1.id];
     										
     	p = [Select id, Name, AR_Subledger_Cutoff__c, AR_Subledger_Closed__c, period_start__c, period_end__c from Period__c where id = :p.id ];
     	
     	// Test that expected date is populated as posting date 
     	system.assertEquals(custInvoice1.Posting_Date__c,custInvoice1.Finalized_Date__c ,'custInvoice1:'+custInvoice1 + 'p.AR_Subledger_Closed__c:'+p.AR_Subledger_Closed__c +'p.AR_Subledger_Cutoff__c:'+p.AR_Subledger_Cutoff__c+'p:'+p);
 	
	}
		
	static testMethod void testAutoBackdating_CustomSettingwithJunk() {
		TestFuel data = new TestFuel();
    	
		// Getting Configuration from testFuel  has value No.
        Configuration__c c = data.AutoBackdatingConfigVal;
		c.name = 'AutoBackdateToOpenSubledgers';
		c.Value__c = 'xxx';
		update c;
		
		Integer currentyear = system.now().year();
        Integer currentMonth = system.now().month();
        
		Period__c p = new Period__c();
		p.Company__c = data.company.id;
     	p.Period_Start__c = datetime.newInstance(currentyear, currentMonth, 1, 0, 0, 0);
     	p.Period_End__c = datetime.newInstance((currentMonth == 12 ? currentyear + 1 : currentyear), (currentMonth == 12 ? 1 : currentMonth + 1), 1, 0, 0, 0);
     	//system.assert(p == null,'p.Period_Start__c:'+p.Period_Start__c+'p.Period_End__c:'+p.Period_End__c);
     	p.AR_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.AP_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.FA_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Inventory_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Shipment_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Receiving_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.JE_Cutoff__c = p.Period_End__c;
     	p.Open__c = true;

		Fiscal_Year__c fy = new Fiscal_Year__c();
		fy.company__c =  data.company.id;
		fy.fiscal_year_start_date__c = p.period_start__c;
		fy.fiscal_year_end_date__c = p.period_end__c.addMonths(3);
		
		insert fy;
		p.fiscalyear__c = fy.Id;
     	
     	insert p;
     	
		// create a SD with different TD, SLC combinations
		Datetime tmpnow = system.now();
		Datetime tmpTD = tmpnow > p.Period_End__c.addDays(-7) ? tmpnow :p.Period_End__c.addDays(-7);
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = tmpnow;
        custInvoice1.transaction_date__c = tmpnow;
        custInvoice1.status__c = 'Open';
        custInvoice1.currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
       
     	custInvoice1.Finalized__c = true;
     	update  custInvoice1;
     	
     	custInvoice1 = [Select id, Finalized_Date__c, Posting_Date__c, Transaction_Date__c
     										from Customer_Invoice__c
     										where id = :custInvoice1.id];
     										
     	p = [Select id, Name, AR_Subledger_Cutoff__c, AR_Subledger_Closed__c, period_start__c, period_end__c from Period__c where id = :p.id ];
     	
     	// Test that posting date is null as autobackdating setting is having some junk val.So On Accounting Finalized Date will be used as Posting Date
     	system.assertEquals(custInvoice1.Posting_Date__c,null ,'custInvoice1:'+custInvoice1 + 'p.AR_Subledger_Closed__c:'+p.AR_Subledger_Closed__c +'p.AR_Subledger_Cutoff__c:'+p.AR_Subledger_Cutoff__c+'p:'+p);
 	
	}
	static testMethod void testAutoBackdating_NoCustomSetting() {
		TestFuel data = new TestFuel();
		
		// Getting Configuration from testFuel  has value No.
        Configuration__c c = data.AutoBackdatingConfigVal;
		delete c;//Remove custom setting	
		
		Integer currentyear = system.now().year();
        Integer currentMonth = system.now().month();
        
		Period__c p = new Period__c();
		p.Company__c = data.company.id;
     	p.Period_Start__c = datetime.newInstance(currentyear, currentMonth, 1, 0, 0, 0);
     	p.Period_End__c = datetime.newInstance((currentMonth == 12 ? currentyear + 1 : currentyear), (currentMonth == 12 ? 1 : currentMonth + 1), 1, 0, 0, 0);
     	//system.assert(p == null,'p.Period_Start__c:'+p.Period_Start__c+'p.Period_End__c:'+p.Period_End__c);
     	p.AR_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.AP_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.FA_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Inventory_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Shipment_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.Receiving_Subledger_Cutoff__c = p.Period_End__c.addDays(-7);
     	p.JE_Cutoff__c = p.Period_End__c;
     	p.Open__c = true;
     	
		Fiscal_Year__c fy = new Fiscal_Year__c();
		fy.company__c =  data.company.id;
		fy.fiscal_year_start_date__c = p.period_start__c;
		fy.fiscal_year_end_date__c = p.period_end__c.addMonths(3);
		
		insert fy;
		p.fiscalyear__c = fy.Id;
     	insert p;
     	
		// create a SD with different TD, SLC combinations
		Datetime tmpnow = system.now();
		Datetime tmpTD = tmpnow > p.Period_End__c.addDays(-7) ? tmpnow :p.Period_End__c.addDays(-7);
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = tmpnow;
        custInvoice1.transaction_date__c = tmpnow;
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = TestFuel.currencyUSD.id;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
       
     	custInvoice1.Finalized__c = true;
     	update  custInvoice1;
     	
     	custInvoice1 = [Select id, Finalized_Date__c, Posting_Date__c, Transaction_Date__c
     										from Customer_Invoice__c
     										where id = :custInvoice1.id];
     										
     	p = [Select id, Name, AR_Subledger_Cutoff__c, AR_Subledger_Closed__c, period_start__c, period_end__c from Period__c where id = :p.id ];
     	
     	// Test that Transaction date is populated as posting date 
     	system.assertEquals(custInvoice1.Posting_Date__c,(p.AR_Subledger_Cutoff__c<custInvoice1.Transaction_Date__c?p.AR_Subledger_Cutoff__c.addSeconds(-1):custInvoice1.Transaction_Date__c),'custInvoice1:'+custInvoice1 + 'p.AR_Subledger_Closed__c:'+p.AR_Subledger_Closed__c +'p.AR_Subledger_Cutoff__c:'+p.AR_Subledger_Cutoff__c+'p:'+p);
 	
	}
	
    static testMethod void testFinalize() {
        SupplierInvoiceAccountingTest.SampleData sd = new SupplierInvoiceAccountingTest.SampleData();
        
        test.startTest();
        List<Supplier_Invoice__c> sis = [SELECT Id, name, transaction_date__c, finalized_date__c, finalized__c
        								FROM Supplier_Invoice__c
        								WHERE Id IN :sd.suppInvAEList];
		for(Supplier_Invoice__c si : sis){
			system.assert(si.finalized__c, 'This Supplier Invoice should be finalized');
			system.assertNotEquals(null, si.transaction_date__c, 'A transaction date is required to finalize');
			system.assertNotEquals(null, si.finalized_date__c, 'There should be a system assigned finalized date');
		}
		test.stopTest();
    }
    
    static testMethod void testVoid(){
    	SupplierInvoiceAccountingTest.SampleData sd = new SupplierInvoiceAccountingTest.SampleData();
        
        test.startTest();
        List<Supplier_Invoice__c> sis = [SELECT Id, name, transaction_date__c, finalized_date__c, finalized__c, void__c, void_date__c
        								FROM Supplier_Invoice__c
        								WHERE Id IN :sd.suppInvAEList];
		for(Supplier_Invoice__c si : sis){
			system.assert(si.finalized__c, 'This Supplier Invoice should be finalized');
			system.assertNotEquals(null, si.transaction_date__c, 'A transaction date is required to finalize');
			system.assertNotEquals(null, si.finalized_date__c, 'There should be a system assigned finalized date');
			si.void__c = true;
			si.void_date__c = system.now();
			si.status__c = 'Void';
		}
		
		boolean sawException = false;
		try{
			update sis;
		}catch(Exception ex){
			sawException = true;
		}
		
		system.assert(sawException, 'There should be an excpetion for attempting to void without going through the proper channel of VoidCancelService');
		test.stopTest();
    }
    
    static testMethod void testUndoVoid(){
    	
    	SupplierInvoiceAccountingTest.SampleData sd = new SupplierInvoiceAccountingTest.SampleData();
        system.assert(sd.data.SuppInvAcctRulesList.size()> 0 );
     	List<Period__c> periods = sd.data.periodList;
 
        List<Supplier_Invoice__c> sis = [SELECT Id, name, transaction_date__c, Posting_Date__c, Status__c, Historical__c,finalized_date__c, finalized__c, void__c, void_date__c,Supplier_and_Invoice__c
         								FROM Supplier_Invoice__c
         								WHERE Id = :sd.suppInv1.id];
         
	    
        SupplierInvoiceAccounting sia = new SupplierInvoiceAccounting();
        list<supplier_invoice_line__c> silList = new list<supplier_invoice_line__c>();
		UnfinalizeService.unfinalizeSourceDocs(new List<sObject>{sd.suppInv1});
        silList.addall(sd.suppInvLineList1);
        //KNDY-12704 reset fields on sil to expected values
        // as WFR/FU that populates
        // SubTransaction_Type__c can be changed by end user
        for (Supplier_Invoice_Line__c sil : silList){
           // sil.SubTransaction_Type__c = 'Goods - Purchase Order';
            sil.Line_Type__c = null;
        }
        Test.startTest();
        update silList;
        sd.suppInv1.finalized__c = true;
        update sd.suppInv1;
        
        
		sia.execute(silList);
        
    	
        SupplierInvoiceVoidCancelService vcs = new SupplierInvoiceVoidCancelService(sis);
 		Map<Id, VoidCancelService.VoidCancelResponse> mResponses = vcs.voidSourceDocuments( (list<sObject>)sis);
		test.stopTest();
		system.assert(mResponses.get(sd.suppInv1.Id).Success, 'This Supplier Invoice should be successfully voided');
		Supplier_Invoice__c si = [SELECT Id, void__c, void_date__c FROM Supplier_Invoice__c WHERE ID = :sd.suppInv1.Id];
		
		system.assert(si.void__c, 'This Supplier Invoice is voided');
		system.assertNotEquals(null, si.void_date__c, 'The void date should be populated');
		
		si.void__c = false;
		si.void_date__c = null;
		boolean sawException = false;
		try{
			update si;
		}catch(Exception ex){
			sawException = true;
		}
		
		system.assert(sawException, 'This update should have failed as the Doc is already void, and cannot be unvoided');
		
    }
    
    static testMethod void testInvoiceFinalizeinOpenSubledgers(){
    	Testfuel fuel = new Testfuel();
    	
    	Invoice__c inv = fuel.intercompanyInvestmentInvoice;
    	String str;
    	Boolean sawException = false;
    	
    	try{
    		inv.Finalized__c = true;
    		update inv;
    	}catch(Exception e){
    		sawException = true;
    		str = e.getMessage();
    	}
    	system.assert(sawException == true,'str:'+str);
    	
    	system.assert(fuel.periodList != null);
    	system.assert(fuel.altCompanyPeriodList != null);
    	
    	sawException = false;
    	try{
    		inv.Finalized__c = true;
    		update inv;
    	}catch(Exception e){
    		sawException = true;
    		str = e.getMessage();
    	}
    	
    	system.assert(sawException == false);
    	inv = [Select id, Name, Finalized__c, Posting_Date__c, Transaction_date__c from Invoice__c where id = :inv.id];
    	
    	system.assert(inv.Finalized__c = true,'Expected to have invoice finalized');
    	system.assert(inv.Transaction_date__c == inv.Posting_Date__c,'Expected to have TD = PD');
    	 
    	
    }
    
    static testMethod void testInvoiceFinalizeinclosedSubledger(){
    	Testfuel fuel = new Testfuel();
    	
    	Invoice__c inv = fuel.intercompanyInvestmentInvoice;
    	String str;
    	Boolean sawException = false;
    	List<Period__c> periods = fuel.periodList;
        
        Period__c p;
        
        for(Period__c thisPeriod : periods){
        	if(thisPeriod.open__c){
        		p = thisPeriod;
        		break;
        	}
        }
        p.intercompany_Subledger_closed__c = system.now();
        PeriodService.systemEditable.add(p.Id);
		update p;
		
    	try{
    		inv.Finalized__c = true;
    		update inv;
    	}catch(Exception e){
    		sawException = true;
    		str = e.getMessage();
    	}
    	system.assert(sawException == true,'str:'+str);
    	
    	
    }
    static testmethod void testPDWithNullTransactionPeriod(){
       	TestFuel fuel = new TestFuel();    
        
       	Supplier__c testSupplierRemitTo = fuel.supplier; 
       	Supplier_Invoice__c supInv = new Supplier_Invoice__c();
   
       	Supplier_Invoice_Line__c suppInvLine = new Supplier_Invoice_Line__c();
       	List<Supplier_Invoice_Line__c> suppInvLineLst = new List<Supplier_Invoice_Line__c>();
       
       	supInv.Supplier__c              = testSupplierRemitTo.id;
       	supInv.Invoice_Type__c          = 'Invoice';
       	supInv.Invoice_Amount__c        = 100;
       	supInv.Company__c               = fuel.Company.Id;   
       	supInv.Currency__c              = TestFuel.currencyUSD.id;
       	supInv.Supplier_Invoice__c      = 'SI1234';
       	
       	//------Transaction date in the past-----------------//
       	supInv.Transaction_Date__c      = system.now().addYears(-1); 
       	
       	insert supInv;
       	
       	suppInvLine.Supplier_Invoice__c     = supInv.id; 
       	suppInvLine.Invoice_Quantity__c     = 10;
        suppInvLine.Unit_Price__c           = 10; 
        suppInvLineLst.add(suppInvLine);
        
        insert suppInvLineLst;
        
        supInv.finalized__c = true;
        
        update supInv;
        
        List<Supplier_Invoice__c> pastTxn = [select id,name,Transaction_Date__c,Posting_Date__c,finalized_date__c 
                                                    from Supplier_Invoice__c limit 1];
        
        system.assertEquals(pastTxn[0].Posting_Date__c ,pastTxn[0].finalized_date__c);
         
        
        //-------Unfinalize the SI to change the Txn Date-------------------------//
        
        Test.setCurrentPage( Page.SourceDocumentUnfinalize);
		Apexpages.currentPage().getParameters().put('id', supInv.id );
		SourceDocumentUnfinalize srcDocUnfinalizeExt = new SourceDocumentUnfinalize();
		srcDocUnfinalizeExt.unfinalizeSourceDoc();
		srcDocUnfinalizeExt.unfinalize();
		
		//------Change the Transaction date to future, Expect Exception--------------//
	
        String message = '';
        Boolean sawException = false ;
        
        try{
            supInv.Transaction_Date__c      = system.now().addYears(1);
            supInv.finalized__c = true; 
            update supInv;
        }catch(Exception ex){
            sawException = true ;
            System.debug(ex.getMessage());
            message = ex.getMessage();
            
        }
        system.assert(message.contains('There are no available periods for one or more companies '+
                                'for this transaction to assign the Finalized Date.')); 
        system.assertEquals(sawException, true); 
    }
}