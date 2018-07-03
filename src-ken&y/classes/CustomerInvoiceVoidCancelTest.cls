@isTest
private class CustomerInvoiceVoidCancelTest {
    
    static testMethod void canCancel_StandardCI() {
 		    
		TestFuel fuel = new TestFuel();
		Sales_order__c so = fuel.salesOrder;
		system.assertNotEquals(null,fuel.periodList);
		list<Sales_Order_Line__c> lSOLs = fuel.salesOrderLines;
		Shipment__c sh = new Shipment__c(Company__c = fuel.company.Id, Customer__c = fuel.customerShipTo.Id, Status__c = 'Staged', Type__c = 'Sales Order Shipment');
        insert sh;
        Shipment_Line__c shl = new Shipment_Line__c(Shipment__c = sh.Id, Sales_Order_Line__c = lSOLs[0].Id, Item__c = lSOLs[0].Product__r.Item__c, Product__c = lSOLs[0].Product__c, Company__c = fuel.company.Id, Quantity_Planned__c = 1, Quantity_Allocated__c = 0, Quantity_To_Pick__c = 0, Quantity_Picked__c = 0, Quantity_Shipped__c = 1);
        insert shl;
        Customer_Invoice__c custInv1 = new Customer_Invoice__c();
            custInv1.Company__c = fuel.company.Id;
            custInv1.Invoice_Type__c = 'Standard';
            custInv1.Date_Invoiced__c = System.now();
            //Added Bill To for field filters
            custInv1.Bill_To_Customer__c = fuel.customerBillTo.id;
            custInv1.Sold_to_customer__c = fuel.customerSoldTo.Id;
            custInv1.Batch_Job_ID__c ='70737000006564mAAA';
            custInv1.Subtotal__c = 0;
            custInv1.Sales_Order__c = fuel.salesOrder.id;
            custInv1.transaction_date__c = system.now();
            custInv1.Currency__c = TestFuel.currencyUSD.id;
            
  
            insert custInv1;
        
        Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
        custInvLine1.Customer_Invoice__c = custInv1.Id;
        custInvLine1.Quantity_Shipped__c = 2;
        custInvLine1.Company__c = fuel.company.Id;
        custInvLine1.Sales_Order_Line__c = lSOLs[0].id;
        custInvLine1.Unit_Price__c = 7;
        custInvLine1.Extended_Price__c = 14;
        custInvLine1.Quantity_Shipped__c = 3;
        custInvLine1.Sales_Order__c = so.id;
        custInvLine1.Product__c = lSOLs[0].Product__c;
        custInvLine1.Discount_Percent__c = 2;
        custInvLine1.shipment_Line__C =shl.Id ;
        custInvLine1.Shipment__c = sh.Id;
        insert custInvLine1;
            
         custInv1.finalized__c = true;
         update custInv1;
        
		Customer_invoice__C	CustomerInvoice=[Select Id, Name, Status__c,shipment__C, Invoice_Type__c, Finalized__c, Balance__c, Void__c, Sales_Order__c, Total_Amount__c,Transaction_Date__c,Finalized_Date__c, Posting_Date__c, Historical__c, Currency__c,
 				(Select id, Shipment__c, Sales_Order_Line__c   from Customer_Invoice_Lines__r),
 				(Select id from Customer_Receipt_Lines__r where Finalized__c = true), 
 				//(Select ID from Customer_Credit_Memos_Applied__r where Finalized__c = true),//KNDY-13995
 				(select id, name from Accounting_Entries__r  where status__c = 'Active' and Has_Exceptions__c != true) 
 				From Customer_Invoice__c where id =:custInv1.Id];
 		test.StartTest();
 		CustomerInvoiceVoidCancelExt ext = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(CustomerInvoice));
		system.assert(!ext.getDisableCancel() == true);
		
		
		ext.cancelDocs();
		CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c,Balance__c, Finalized_Date__c, Posting_Date__c, Historical__c, Currency__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
		system.assertEquals(CustomerInvoice.Status__c, 'Cancelled');
		system.assertEquals(CustomerInvoice.Balance__c, 0);
		test.StopTest();	
    }
    
    static testMethod void cannotVoidCancel_IncorrectInvoiceType() {
    	
    	TestFuel globalTestData = new TestFuel();
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        CustomerInvoice.Company__c = globalTestData.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Chargeback';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = TestFuel.currencyUSD.id;
		insert CustomerInvoice;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
		
		CustomerInvoice.Finalized__c = true;
		update CustomerInvoice;
		
		test.StartTest();
			
			CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Currency__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
			CustomerInvoiceVoidCancelExt ext = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(CustomerInvoice));
			
			system.assert(!ext.getDisableVoid() == false,'Cannot void ChargeBack invoices');
			system.assert(!ext.getDisableCancel() == false,'Cannot cancel ChargeBack invoices');
		test.StopTest();	
	
       
    }
    
    static testMethod void cannotVoidCancel_UnfinalizedInvoice() {
    	
    	TestFuel globalTestData = new TestFuel();
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        CustomerInvoice.Company__c = globalTestData.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = TestFuel.currencyUSD.id;
		insert CustomerInvoice;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
		
		
		test.StartTest();
			
			CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Currency__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
			CustomerInvoiceVoidCancelExt ext = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(CustomerInvoice));
			
			system.assert(!ext.getDisableVoid() == false,'Cannot void Unfinalized invoices');
			system.assert(!ext.getDisableCancel() == true,'Cannot cancel Unfinalized invoices'); //AR-143
		test.StopTest();	
	
       
    }
    
    static testMethod void cannotVoidCancel_PartiallyFullyPaid() {
    	
    	TestFuel globalTestData = new TestFuel();
    	system.assert(globalTestData.periodList != null);
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        CustomerInvoice.Company__c = globalTestData.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Chargeback';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = TestFuel.currencyUSD.id;
		insert CustomerInvoice;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
		
		CustomerInvoice.Finalized__c = true;
		update CustomerInvoice;
		
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = globalTestData.company.Id;
		custReceipt.Customer__c = globalTestData.customerParent.Id;
		custReceipt.Date_Received__c = system.now();
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = TestFuel.currencyUSD.id;
		insert custReceipt;
				
				
		Customer_Receipt_Line__c deductionLine = new Customer_Receipt_Line__c();
		deductionLine.Amount__c = 100;
		deductionLine.Customer_Receipt__c = custReceipt.Id;
		deductionLine.Reason_Code__c = globalTestData.deductionCode.Id;
		deductionLine.Type__c = PaymentService.TYPE_GEN_DED;
		insert deductionLine;
		
		Customer_Receipt_Line__c payment = new Customer_Receipt_Line__c();
		payment.Amount__c = 100;
		payment.Customer_Receipt__c = custReceipt.Id;
		payment.Type__c = PaymentService.TYPE_PAYMENT;
		payment.Customer_Invoice__c = CustomerInvoice.Id;
		insert payment;
		
		custReceipt.Finalized__c = true;
		update custReceipt;
		
		test.StartTest();
			
			CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Currency__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
			CustomerInvoiceVoidCancelExt ext = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(CustomerInvoice));
			
			system.assert(!ext.getDisableVoid() == false,'Cannot void ChargeBack invoices');
			system.assert(!ext.getDisableCancel() == false,'Cannot cancel ChargeBack invoices');
			
			ext.cancelDetails();ext.voidDetails();
			system.assertNotEquals(ApexPages.getMessages(),null);
		test.StopTest();	
	
       
    }
    static testMethod void canCancel_NoLines() {//KNDY-10276
    	TestFuel globalTestData = new TestFuel();
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        CustomerInvoice.Company__c = globalTestData.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = TestFuel.currencyUSD.id;
		insert CustomerInvoice;
		
		test.StartTest();
			
			CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c ,Currency__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
			CustomerInvoiceVoidCancelExt ext = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(CustomerInvoice));
			
    
			system.assert(!ext.getDisableCancel() == true);
			
			ext.cancelDocs();
			CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
			system.assertEquals(CustomerInvoice.Status__c, 'Cancelled');
		test.StopTest();	
    }
    
    static testMethod void canCancel_ManualCI() {
    	
    	TestFuel globalTestData = new TestFuel();
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        CustomerInvoice.Company__c = globalTestData.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = TestFuel.currencyUSD.id;
		insert CustomerInvoice;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
		
		CustomerInvoice.Finalized__c = true;
		update CustomerInvoice;
		
		test.StartTest();
			
			CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Currency__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
			CustomerInvoiceVoidCancelExt ext = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(CustomerInvoice));
			
			
			system.assert(!ext.getDisableCancel() == true);
			
			ext.cancelDocs();
			CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c,Balance__c, Finalized_Date__c, Posting_Date__c, Historical__c, Currency__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
			system.assertEquals(CustomerInvoice.Status__c, 'Cancelled');
			system.assertEquals(CustomerInvoice.Balance__c, 0);
		test.StopTest();	
	
       
    }
    
    static testMethod void cannotVoid_NoAEs() {
    	
    	TestFuel globalTestData = new TestFuel();
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        CustomerInvoice.Company__c = globalTestData.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = TestFuel.currencyUSD.id;
		insert CustomerInvoice;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
		
		CustomerInvoice.Finalized__c = true;
		update CustomerInvoice;
		
		test.StartTest();
			
			CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Currency__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
			CustomerInvoiceVoidCancelExt ext = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(CustomerInvoice));
			
			system.assert(!ext.getDisableVoid() == false);
			
		test.StopTest();	
	
       
    }
    
    static testMethod void canVoid() {
    	
    	TestFuel globalTestData = new TestFuel();
    	
    	system.assert(globalTestData.ciAccountingRuleList != null);
        
    	system.assert(globalTestData.periodList.size() > 0,'TestFuel Failure.');
    	
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        CustomerInvoice.Company__c = globalTestData.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Void_Date__c = system.now();
        CustomerInvoice.Currency__c = TestFuel.currencyUSD.id;
		insert CustomerInvoice;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		//cil.SubTransaction_Type__c = 'Goods';
		insert cil;
		
		CustomerInvoice.Finalized__c = true;
		update CustomerInvoice;
		system.debug('cil: '+[Select Id, Line_Type__c, SubTransaction_Type__c from Customer_Invoice_Line__c where id = :cil.ID]);
		
		test.StartTest();
			AccountingService cia = new CustomerInvoiceAccounting();
	        list <Customer_Invoice_Line__c> cilines = new list <Customer_Invoice_Line__c>();
	        cilines.add(cil);
	        cia.execute(cilines);
	        
			CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Currency__c, (Select Id, has_exceptions__c, Transaction_Type__c from Accounting_Entries__r) from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
			system.debug('test: ae '+ CustomerInvoice.Accounting_Entries__r);
			system.debug([select id, subject from Task where whatId = :CustomerInvoice.Accounting_Entries__r.get(0).Id]);
			for(Accounting_Entry_Line__c ael : [Select Id, SubTransaction_type__c, line_Type__c, (select id, subject from Tasks) from Accounting_Entry_Line__c where Accounting_Entry__c = :CustomerInvoice.Accounting_Entries__r.get(0).Id])
			{
				system.debug('ael: '+ael);
				system.debug('ael with tasks: '+ael.Tasks);
			}
			system.assert(CustomerInvoice.Accounting_Entries__r.size() >0);
			CustomerInvoiceVoidCancelExt ext = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(CustomerInvoice));
			
			
			system.assert(!ext.getDisableVoid() == true );
			
			ext.voidDocs();
			CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Date_Invoiced__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Currency__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
			system.assertEquals(CustomerInvoice.Status__c, 'Void');
			system.assertEquals(CustomerInvoice.Void__c, true);
			system.assertEquals(CustomerInvoice.Void_Date__c.date(), CustomerInvoice.Date_Invoiced__c.date());
		test.StopTest();	
	
       
    }

    static testMethod void testAES_NoFuturePeriod(){
        DateTime currentTime = system.now();
        string errorMsg;
        Boolean ErrorExists = false;
        
        Accounting_Standard__c accountingStandard = new Accounting_Standard__c();
        accountingStandard.name = 'US GAAP';
    	insert accountingStandard;
        
        
        Account testAccount = new Account();
        testAccount.name = 'KenandyTestFuel'+ '-' + String.ValueOf((Integer) (Math.random () * 999));
        testAccount.billingstreet = '303 Twin Dolphin Drive, Suite 500';
        testAccount.billingcity = 'Redwood City';
        testAccount.billingstate = 'CA';
        testAccount.billingpostalcode = '94065';
        testAccount.billingcountry = 'USA';
        testAccount.shippingstreet = '303 Twin Dolphin Drive, Suite 500';
        testAccount.shippingcity = 'Redwood City';
        testAccount.shippingstate = 'CA';
        testAccount.shippingpostalcode = '94065';
        testAccount.shippingcountry = 'USA';
        testAccount.phone = '650-468-2000';
        testAccount.fax = '650-468-2010';
        testAccount.website = 'kenandy.com';
        insert testAccount;

        Company__c testCompany = new Company__c();
        testCompany.name = 'KenandyTestFuel'+ '-' + String.ValueOf((Integer) (Math.random () * 999));
        testCompany.Address__c = testAccount.ID;
        testCompany.Accounting_Standard__c = accountingStandard.id;
        testCompany.A_Days__c = 30;
        testCompany.B_Days__c = 60;
        testCompany.C_Days__c = 180;
        testCompany.Company_Identifier__c = 'KEN' + '-' + String.ValueOf((Integer) (Math.random () * 999));
        testCompany.Comp_Currency__c  = TestFuel.currencyUSD.id;
        testCompany.Consol_Currency__c  = TestFuel.currencyUSD.id;
        testCompany.Stat_Currency__c  = TestFuel.currencyUSD.id;
        testCompany.Subs_Currency__c  = TestFuel.currencyUSD.id;
        testCompany.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        //testCompany.Finalize_Supplier_Invoices_w_Exceptions__c = false; //KNDY-2817
        insert testCompany;


        Fiscal_Year__c testFiscalYear = new Fiscal_Year__c();
        testFiscalYear.Company__c = testCompany.id;
        testFiscalYear.Fiscal_Year_End_Date__c = system.now().addDays(200);
        testFiscalYear.Fiscal_Year_Start_Date__c = system.now().addDays(-30);
        insert testFiscalYear;

        Period__c testPeriod1 = new Period__c();
        testPeriod1.Period_Start__c = currentTime;
        testPeriod1.Open__c = True;
        testPeriod1.Period_End__c = currentTime.addSeconds(35);
        testPeriod1.Company__c = testCompany.id;                    
        testPeriod1.Name = string.valueOf(1)+ '-' + String.ValueOf((Integer) (Math.random () * 999) + system.now().getTime());
        testPeriod1.Year_Start_Date__c = date.newInstance(system.now().year(), 1, 1);
        testPeriod1.Year_End_Date__c = date.newInstance(system.now().year() + 1, 1, 1);
        testPeriod1.Period_Number__c = 1;
        testPeriod1.FiscalYear__c = testFiscalYear.id;
        insert testPeriod1;

        //TestFuel fuel = new TestFuel();
        //GL_Type__c currentAssets = fuel.currentAssets;
        //GL_Type__c currentLiabilities = fuel.currentLiabilities;

        GL_Type__c currentAssets = new GL_Type__c();
        currentAssets.Name  = 'Current Assets';
        currentAssets.Normal_Balance__c  = 'Debit';
        currentAssets.Accounting_Type__c  = 'Assets';
        currentAssets.Statement_Type__c  = 'Balance Sheet';
        currentAssets.Account_Range_From__c = '10000000000';
        currentAssets.Account_Range_To__c ='14999999999';
    
        insert currentAssets;

        GL_Type__c currentLiabilities = new GL_Type__c();
        currentLiabilities.Name  = 'Current Liabilities';
        currentLiabilities.Normal_Balance__c  = 'Credit';
        currentLiabilities.Accounting_Type__c  = 'Liabilities';
        currentLiabilities.Statement_Type__c  = 'Balance Sheet';
        currentLiabilities.Account_Range_From__c = '20000000000';
        currentLiabilities.Account_Range_To__c ='24999999999';
        
        insert currentLiabilities;

        GL_Account__c cashGL = new GL_Account__c();
        GL_Account__c receivablesGL = new GL_Account__c();
        GL_Account__c payablesGL = new GL_Account__c();

        List<GL_Account__c> GLAccountList = new List<GL_Account__c>();       
        cashGL = new GL_Account__c();
        cashGL.Name = '12000000000 - Cash';
        cashGL.GL_Account_Number__c = '12000000000';
        cashGL.GL_Account_Name__c = 'Cash';
        cashGL.active__c = true;
        cashGL.Report_Section__c = 'Current Assets';  
        cashGL.Normal_Balance__c = 'Debit';
        cashGL.Statement_Type__c = 'Balance Sheet';
        cashGL.Report_Section_Grouping__c = 'Assets';
        cashGL.Cash_Flow_Report_Section_Grouping__c = 'Operating Cash Flow';
        cashGL.non_cash__c = true;
        cashGL.GL_Type__c = currentAssets.id;

        GLAccountList.add(cashGL);
        
        receivablesGL = new GL_Account__c();
        receivablesGL.Name = '11000000000 - Accounts Receivable';
        receivablesGL.GL_Account_Number__c = '11000000000';
        receivablesGL.GL_Account_Name__c = 'Accounts Receivable';
        receivablesGL.active__c = true;
        receivablesGL.Report_Section__c = 'Current Assets';
        receivablesGL.Statement_Type__c = 'Balance Sheet'; 
        receivablesGL.Report_Section_Grouping__c = 'Assets';
        receivablesGL.Normal_Balance__c = 'Debit'; 
        receivablesGL.GL_Type__c = currentAssets.id;
        GLAccountList.add(receivablesGL);
        
        payablesGL = new GL_Account__c();
        payablesGL.Name = '21000000000 - Accounts Payable ';
        payablesGL.GL_Account_Number__c = '21000000000';
        payablesGL.GL_Account_Name__c = 'Accounts Payable';
        payablesGL.Report_Section__c = 'Accounts Payable';
        payablesGL.Normal_Balance__c = 'Credit';
        payablesGL.active__c = true;
        payablesGL.Statement_Type__c = 'Income Statement';  
        payablesGL.GL_Type__c = currentLiabilities.id; 
        GLAccountList.add(payablesGL);  
        insert GLAccountList;       


        List<Segment_Definition__c> customsegList = new List<Segment_Definition__c>();
        Segment_Definition__c custom_seg1 = new Segment_Definition__c();
        custom_seg1.Name = 'Company__c';
        custom_seg1.Accounting_Entry_Field__c = 'Company__c'; // just need a field to stuff into
        custom_seg1.Object_API_Name__c = 'Company__c';
        custom_seg1.Segment_Number__c = 1;
        customsegList.add(custom_seg1);
        
        Segment_Definition__c custom_seg2 = new Segment_Definition__c();
        custom_seg2.Name = 'GL_Account__c';
        custom_seg2.Accounting_Entry_Field__c = 'GL_Account__c'; // just need a field to stuff into
        custom_seg2.Object_API_Name__c = 'GL_Account__c';
        custom_seg2.Accounting_Rule_Segment__c = 'GL_Account__c';
        custom_seg2.Accounting_Rule_Reference_Value__c = 'GL_Account_Reference_Value__c';
        custom_seg2.Accounting_Rule_Default__c = 'Default_GL_Account__c';
        custom_seg2.Segment_Number__c = 2;
        customsegList.add(custom_seg2);
        
        insert customsegList;  

        List<Segment_Validation__c> svList = new List<Segment_Validation__c>();
        Segment_Validation__c sv1 = new Segment_Validation__c();
        sv1.segment_1__c = '*';
        sv1.segment_2__c = '*';
        sv1.active__c = true;
        svList.add(sv1);
        Segment_Validation__c sv2 = new Segment_Validation__c();
        sv2.segment_1__c = '*';
        sv2.segment_2__c = null;
        sv2.active__c = true;
        svList.add(sv2);
        insert svList;  


        Supplier__c remittosupplier = new Supplier__c(); 
        remittosupplier.Name = Testcompany.Name + ' Supplier-1';
        remittosupplier.Company__c = testCompany.ID;
        remittosupplier.Tax_ID__c = 'tax ID';
        remittosupplier.Address__c = testaccount.ID;  // remittoaccount ?? TODO 
        remittosupplier.Status__c = 'Active';
        //remittosupplier.Payment_Term__c = terms.ID;
        remittosupplier.Always_Take_Discount__c = false;
        remittosupplier.Type__c = 'Remit-To';
        //remitToSupplier.RecordTypeId = SupplierRecordTypes.get('Remit_To');
        remitToSupplier.Alternate_Name__c = 'Remit to Supplier';
        remittosupplier.Currency__c = TestFuel.currencyUSD.id;
        insert remittosupplier;

        Supplier__c supplier = new Supplier__c(); 
        supplier.Name = testCompany.Name + ' Supplier-1';
        supplier.Company__c = testCompany.ID;
        supplier.Tax_ID__c = 'tax ID';
        supplier.Address__c = testaccount.ID;  // remittoaccount ?? TODO 
        supplier.Status__c = 'Active';
        //supplier.Payment_Term__c = terms.ID;
        //supplier.FOB_Term__c = fobTerm.id;
        supplier.Type__c = 'Purchasing';
        //supplier.RecordTypeId = SupplierRecordTypes.get('Purchase_From');
        supplier.Remit_To__c =  remittosupplier.id;
        supplier.Default_Receiving_Tolerance__c = 3;
        supplier.Create_RTV_Credit_Memo__c = true;
        supplier.Alternate_Name__c = 'Test Supplier';
        supplier.Currency__c = TestFuel.currencyUSD.id;
        insert supplier;
        
        UOM__c uom = new UOM__c(
                            Name = 'EA',
                            Description__c = 'EA');
        insert uom;
        Item__c item = new Item__c();
        item.name= testCompany.Name + ' Item-1';
        item.Description__c='Item-1';
        item.Source__c = 'Purchased';
        //item.Supplier__c = supplier.ID;
        //item.Purchasing_UOM__c = uomList[8].Id;
        //item.Lead_Time__c = 1/5;        
        item.company__c = testCompany.id;
        item.Active__c = true;
        item.Item_Type__c = 'Outside Processing';
        item.Packaging_UOM__c = JSON.serialize(new List<Id>{ uom.Id});
        insert item;

        Supplier_Invoice__c testSI = new Supplier_Invoice__c();
        testSI.Company__c = testCompany.id;
        testSI.Supplier__c = remittosupplier.id;
        testSI.Invoice_Amount__c = 500;
        testSI.Currency__c = TestFuel.currencyUSD.id;
        testSI.Invoice_Type__c = 'Invoice';
        testSI.Supplier_Invoice__c = system.today() + ': 123';
        testSI.Historical__c=FALSE;
        testSI.Void__c = false;
        insert testSI;

        Accounting_Default__c testAccountingDefault = new Accounting_Default__c();
        testAccountingDefault.GL_Account__c = receivablesGL.Id;
        insert testAccountingDefault;


        Supplier_Invoice_Line__c testSILine = new Supplier_Invoice_Line__c();
        testSILine.Supplier_Invoice__c = testSI.id;
        testSILine.Invoice_Quantity__c = 1;
        testSILine.Unit_Price__c = 500;//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price
        testSILine.Accounting_Segment__c = testAccountingDefault.id;
        testSILine.Item__c = item.id; 
        insert testSILine;

        List<Supplier_Invoice_Line__c> siLineList = new List<Supplier_Invoice_Line__c>();
        siLineList.add(testSILine);

        List<Supplier_Invoice__c> siList = new List<Supplier_Invoice__c>();
        siList.add(testSI);

        testSI.Finalized__c = true;
        testSI.Transaction_Date__c = system.today();
        testSI.Finalized_Date__c = system.today();
        update TestSi;

        Accounting_Rule__c debitSI_AR = new Accounting_Rule__c();
        debitSI_AR.Accounting_Standard__c = accountingStandard.id;
        debitSI_AR.Default_GL_Account__c = true;
        debitSI_AR.GL_Account__c = receivablesGL.id;
        debitSI_AR.Rule_Type__c = 'DR';
        debitSI_AR.Object__c = 'Supplier Invoice';
        debitSI_AR.Expected_Sign__c= 'Positive';
        debitSI_AR.Transaction__c = 'Supplier Invoice';
        debitSI_AR.Effective_Start_Date__c = system.now();
        debitSI_AR.Effective_End_Date__c =  system.now().addDays(30);
        insert debitSI_AR;

        Accounting_Rule__c creditSI_AR = new Accounting_Rule__c();
        creditSI_AR.Accounting_Standard__c = accountingStandard.id;
        creditSI_AR.Default_GL_Account__c = true;
        creditSI_AR.GL_Account__c = receivablesGL.id;
        creditSI_AR.Rule_Type__c = 'CR';
        creditSI_AR.Object__c = 'Supplier Invoice';
        creditSI_AR.Expected_Sign__c= 'Positive';
        creditSI_AR.Transaction__c = 'Supplier Invoice';
        creditSI_AR.Effective_Start_Date__c = system.now();
        creditSI_AR.Effective_End_Date__c = system.now().addDays(30);

        insert creditSI_AR;

        Period__c p = new Period__c(id = testPeriod1.id);
        p.AR_Subledger_Closed__c =  System.now().addseconds(1);
        p.AP_Subledger_Closed__c = System.now().addseconds(1);
        p.FA_Subledger_Closed__c = System.now().addseconds(1);
        p.Inventory_Subledger_Closed__c = System.now().addseconds(1);
        p.Receiving_Subledger_Closed__c = System.now().addseconds(1);
        p.Shipment_Subledger_Closed__c = System.now().addseconds(1);
        p.GL_Close__c = system.now().addseconds(2);
        p.Open__c = false;
        p.Closed__c = true;
        
        PeriodService.systemEditable.add(p.Id);
        update p;            


        SupplierInvoiceAccounting sia = new SupplierInvoiceAccounting();
        sia.execute(siLineList);  
        
        Test.startTest();
        List<Accounting_Entry__c> generatedAcctEntries = [SELECT Id FROM Accounting_Entry__c];
        system.debug(generatedAcctEntries.size());
        system.assert(generatedAcctEntries.size() > 0);

        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testSI);

        PageReference voidCancelPage = page.SupplierInvoiceVoidCancel;
        Test.setCurrentPage(voidCancelPage);
        SupplierInvoiceVoidCancelExt sivoidext = new SupplierInvoiceVoidCancelExt(new ApexPages.standardController(testSI));
        system.assert(!sivoidext.getDisableVoid() == false);
    
        //system.debug('detail'+detail);
        VoidCancelService voidCancelSvc = new SupplierInvoiceVoidCancelService(new List<sObject>{testSI});
        String vcrMessages;
        Map<Id, VoidCancelService.VoidCancelDetail> VoidCancelDetailInContext = voidCancelSvc.getAccountingVoidCancelDetails(new List<sObject>{testSI});
        for(String m :  VoidCancelDetailInContext.get(sc.getId()).voidMessages){
            vcrMessages +=' ' + m;
        }
        system.debug(vcrMessages);  
        system.assert(vcrMessages.contains('Unable to void a Supplier Invoice. To void a document, an open period must be associated with it.'));      
      

        Test.stopTest();
    }     
}