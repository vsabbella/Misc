@isTest
private class CustomerCreditBucketbatchTest {
	public static TestFuel globalTestData = new TestFuel();		
	public  class setupData
	{
		 public list<Customer_Invoice__c> positveCIs;
		 public list<Customer_Invoice__c> negativeCIs;
		public list<Customer_Invoice__c> allInvoices;
		
		public setupData()
		{
			positveCIs = new list<Customer_Invoice__c>();
			negativeCIs =  new list<Customer_Invoice__c>();
			allInvoices = new list<Customer_Invoice__c>();
			list<Customer_Invoice_Line__c> lines = new list<Customer_Invoice_Line__c>();

			for(integer i =1; i<=5; i++)
			{
				Customer_Invoice__c custInvoice = new Customer_Invoice__c();
				custInvoice.Company__c = globalTestData.company.Id;
				custInvoice.bill_to_customer__c = globalTestData.customerBillTo.Id;
				custInvoice.Currency__c = TestFuel.currencyUSD.id;
				custInvoice.Invoice_Type__c = 'Ship Invoice';
				custInvoice.Status__c = 'Open';
				positveCIs.add(custInvoice);
			}

			
			//KNDY-16823
			for(integer i =1; i<=2; i++)
			{
				Customer_Invoice__c custInvoice = new Customer_Invoice__c();
				custInvoice.Company__c = globalTestData.company.Id;
				custInvoice.sold_to_customer__c = globalTestData.customerSoldTo.Id;
				custInvoice.bill_to_customer__c = globalTestData.customerBillTo.Id;
				custInvoice.Currency__c = TestFuel.currencyUSD.id;
				custInvoice.Invoice_Type__c = 'Ship Invoice';
				custInvoice.Status__c = 'Open';
				positveCIs.add(custInvoice);
			}
			allInvoices.addAll(positveCIs);
			 
			 for(integer i =1; i<=3; i++)
			{
				Customer_Invoice__c custInvoice = new Customer_Invoice__c();
				custInvoice.Company__c = globalTestData.company.Id;
				custInvoice.bill_to_customer__c = globalTestData.customerBillTo.Id;
				custInvoice.Currency__c = TestFuel.currencyUSD.id;
				custInvoice.Status__c = 'Open';
				negativeCIs.add(custInvoice);
			}
			allInvoices.addAll(negativeCIs);


			//KNDY-15808
			Customer_Invoice__c custInvPrepay = new Customer_Invoice__c();
			custInvPrepay.Company__c = globalTestData.company.id;
			custInvPrepay.Invoice_Type__c = 'Prepayment';
			custInvPrepay.Date_Invoiced__c = System.today();
			custInvPrepay.Customer__c = globalTestData.customerParent.Id;
			custInvPrepay.Sold_To_Customer__c = globalTestData.customerSoldTo.id;
			custInvPrepay.Bill_To_Customer__c = globalTestData.customerbillto.id;
			custInvPrepay.Subtotal__c = -100;
			custInvPrepay.Currency__c = TestFuel.currencyUSD.id;
			custInvPrepay.transaction_date__c = system.now();
			allInvoices.add(custInvPrepay);


			Customer_Invoice__c custInvPrepay1 = new Customer_Invoice__c();
			custInvPrepay1.Company__c = globalTestData.company.id;
			custInvPrepay1.Invoice_Type__c = 'Prepayment';
			custInvPrepay1.Date_Invoiced__c = System.today();
			custInvPrepay1.Customer__c = globalTestData.customerParent.Id;
			custInvPrepay1.Subtotal__c = -100;
			custInvPrepay1.Currency__c = TestFuel.currencyUSD.id;
			custInvPrepay1.transaction_date__c = system.now();
			allInvoices.add(custInvPrepay1);

			insert allInvoices;

			for(Customer_Invoice__c ci : positveCIs)
			{
				Customer_Invoice_Line__c custInvoiceLine = new Customer_Invoice_Line__c();
				custInvoiceLine.Customer_Invoice__c = ci.Id;
				custInvoiceLine.Product__c = globalTestData.product.Id;
				custInvoiceLine.Quantity_Shipped__c = 1;
				custInvoiceLine.Unit_Price__c = 10;
				custInvoiceLine.Extended_Price__c = 10;
				//KNDY-16823
				custInvoiceLine.Sales_Tax__c = 0.79;
				custInvoiceLine.Sales_Tax_Rate__c = 7.9;
				lines.add(custInvoiceLine);
			}

			for(Customer_Invoice__c ci : negativeCIs)
			{
				Customer_Invoice_Line__c custInvoiceLine = new Customer_Invoice_Line__c();
				custInvoiceLine.Customer_Invoice__c = ci.Id;
				custInvoiceLine.Product__c = globalTestData.product.Id;
				custInvoiceLine.Quantity_Shipped__c = -1;
				custInvoiceLine.Unit_Price__c = 10;
				custInvoiceLine.Extended_Price__c = 10;
				lines.add(custInvoiceLine);
			}

			Customer_Invoice_Line__c custInvLinePre = new Customer_Invoice_Line__c();
			custInvLinePre.Quantity_Shipped__c = 10;
			custInvLinePre.Product__c = globalTestData.product.id ;
			custInvLinePre.Company__c = globalTestData.company.id;
			custInvLinePre.Unit_Price__c = -10;
			custInvLinePre.Customer_Invoice__c = custInvPrepay.id;
			custInvLinePre.Extended_Price__c = custInvLinePre.Quantity_Shipped__c * custInvLinePre.Unit_Price__c;
			lines.add(custInvLinePre);

			Customer_Invoice_Line__c custInvLinePre1 = new Customer_Invoice_Line__c();
			custInvLinePre1.Quantity_Shipped__c = 10;
			custInvLinePre1.Product__c = globalTestData.product.id ;
			custInvLinePre1.Company__c = globalTestData.company.id;
			custInvLinePre1.Unit_Price__c = -10;
			custInvLinePre1.Customer_Invoice__c = custInvPrepay1.id;
			custInvLinePre1.Extended_Price__c = custInvLinePre1.Quantity_Shipped__c * custInvLinePre1.Unit_Price__c;
			lines.add(custInvLinePre1);

			insert lines;

			for(Customer_Invoice__c ci : allInvoices) {
				ci.Finalized__c = true;
			}
			update allInvoices;
			 
			Reason_Code__c invoiceHoldReasonCode = new Reason_Code__c();
            invoiceHoldReasonCode.Company__c = globalTestData.company.Id;
            invoiceHoldReasonCode.Type__c = 'Invoice Hold';
            invoiceHoldReasonCode.Code__c = 'R101';
            
            insert invoiceHoldReasonCode;
			 
              list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        	lFs.add(new Fulfillment__c(Customer__c = globalTestData.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = TestFuel.currencyUSD.id, Payment_Term__c = globalTestData.terms.ID,
	                                   Name = 'F1', Invoice_Ready__c = true, Invoice_Hold__c = true, Reason_Code__c = invoiceHoldReasonCode.Id, Unit_Price__c = 100, Quantity__c = 3, Product__c = globalTestData.product2.id  , Extended_price__c=1, Status__c ='Complete', Price_Type__c = 'Sales') );
        	lFs.add(new Fulfillment__c(Customer__c = globalTestData.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,6,20,0,0,0), Currency__c = TestFuel.currencyUSD.id, Payment_Term__c = globalTestData.terms.ID,
	                                   Name = 'F1', Invoice_Ready__c = true, Invoice_Hold__c = false, Unit_Price__c = 100, Quantity__c = 4, Product__c = globalTestData.product2.id,Extended_price__c=2 , Status__c ='Complete', Price_Type__c = 'Sales' ));
        	lFs.add(new Fulfillment__c(Customer__c = globalTestData.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,7,20,0,0,0), Currency__c = TestFuel.currencyUSD.id, Payment_Term__c = globalTestData.terms.ID,
	                                   Name = 'F1', Invoice_Ready__c = true, Invoice_Hold__c = true, Reason_Code__c = invoiceHoldReasonCode.Id, Unit_Price__c = 100, Quantity__c = 5, Product__c = globalTestData.product2.id,Extended_price__c=3, Status__c ='Complete', Price_Type__c = 'Sales' ));
        	lFs.add(new Fulfillment__c(Customer__c = globalTestData.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,8,20,0,0,0), Currency__c = TestFuel.currencyUSD.id, Payment_Term__c = globalTestData.terms.ID,
	                                   Name = 'F1', Invoice_Ready__c = true, Invoice_Hold__c = false, Unit_Price__c = 120, Quantity__c = 6, Product__c = globalTestData.product2.id,Extended_price__c=5, Status__c ='Complete', Price_Type__c = 'Sales' ));

        	insert lFs;


		}
	}

    static testMethod void myUnitTest() {
    	
    	SetupData sd = new setUpData();
    	system.assertNotEquals(null,globalTestData.customerSoldTo.Id);
    	String ns = KSE.NamespaceUU;
    	insert new Process__c(Name ='test',Object_Step__c ='CustomerOutstandingBalanceService',State__c = '1',Object__c =ns+'Customer__c',Sequence__c = 1, Bulk__c = true, Active__c =true, Namespace__c = ns);
    	Test.startTest(); 
    	list<Customer_Invoice__c> CIs = [Select id, bill_to_customer__c, bill_to_customer__r.Top_Parent_Customer__c  from Customer_Invoice__c];
    	system.debug('inside test, CIs: '+Cis);
    	system.assert(CIs.size() == 12,'SETUP DATA should create 10 Customer Invoices');
    	
    	CustomerOutstandingBalanceBatch testbatch = new CustomerOutstandingBalanceBatch();
    	
    	Id jobId=Database.executebatch(testbatch,10);
       Test.stopTest();
       

       Customer__c corpParent = [Select id, Open_Invoices__c, Open_Credits__c, Total_Due__c, Outstanding_Balance2__c,Uninvoiced_Shipments__c,Open_Sales_Orders__c from Customer__c where id = :globalTestData.customerParent.id limit 1 ];
       System.debug(logginglevel.error,'corpParent---->'+corpParent);
       system.assert(corpParent.Open_Invoices__c == 75.53,' Open invoices is sum of positive Cis balance = ' + corpParent.Open_Invoices__c);
       system.assert(corpParent.Open_Credits__c == -230,' Open invoices is sum of positive Cis balance = ' + corpParent.Open_Credits__c);
       system.assert(corpParent.Total_Due__c == (75.53 - 230), 'Total Due is Open Invoices + Open Credits '+corpParent.Total_Due__c);
		system.assert(corpParent.Uninvoiced_Shipments__c == 11,' corpParent.Uninvoiced_Shipments__c ' + corpParent.Uninvoiced_Shipments__c);
       system.assert(corpParent.Outstanding_Balance2__c == corpParent.Open_Invoices__c + corpParent.Open_Credits__c+ corpParent.Uninvoiced_Shipments__c+ corpParent.Open_Sales_Orders__c,' Outstanding_Balance__c = 11, ' + corpParent.Outstanding_Balance2__c);
        
    }
    
    static testMethod void myUnitTest2() {
    	
    	SetupData sd = new setUpData();
    	system.assertNotEquals(null,globalTestData.customerSoldTo.Id);
    	String ns = KSE.NamespaceUU;
    	insert new Process__c(Name ='test',Object_Step__c ='CustomerOutstandingBalanceService',State__c = '1',Object__c =ns+'Customer__c',Sequence__c = 1, Bulk__c = true, Active__c =true, Namespace__c = ns);
    	Test.startTest(); 
    	list<Customer_Invoice__c> CIs = [Select id, bill_to_customer__c, bill_to_customer__r.Top_Parent_Customer__c  from Customer_Invoice__c];
    	system.debug('inside test, CIs: '+Cis);
    	system.assert(CIs.size() == 12,'SETUP DATA should create 10 Customer Invoices');
    	
    	Process_Job__c j = new Process_Job__c(Active__c = true, Apex_Class__c = 'CustomerOutstandingBalanceBatch',Name = 'test',Batch_size__c =1,Namespace__c = ns);
    	insert j;
    	CustomerOutstandingBalanceBatch testbatch = new CustomerOutstandingBalanceBatch();
    	testbatch.runBatch(j);
       Test.stopTest();
       
       Customer__c billcust = [Select id, Open_Invoices__c, Open_Credits__c, Outstanding_Balance2__c,Uninvoiced_Shipments__c,Open_Sales_Orders__c from Customer__c where id = :globalTestData.customerbillTo.id limit 1 ];
       System.debug(logginglevel.error,'corpParent---->'+billcust);
       system.assert(billcust.Open_Invoices__c == 75.53,' Open invoices is sum of positive Cis balance = ' + billcust.Open_Invoices__c);
       system.assert(billcust.Open_Credits__c == -130,' Open invoices is sum of positive Cis balance = ' + billcust.Open_Credits__c);
       system.assert(billcust.Uninvoiced_Shipments__c == 11,' corpParent.Uninvoiced_Shipments__c ' + billcust.Uninvoiced_Shipments__c);
       system.assert(billcust.Outstanding_Balance2__c == billcust.Open_Invoices__c + billcust.Open_Credits__c+ billcust.Uninvoiced_Shipments__c+ billcust.Open_Sales_Orders__c,' Outstanding_Balance__c = 11, ' + billcust.Outstanding_Balance2__c);
    }
    
    //KNDY-15869
    static testMethod void myUnitTestWithSO() {
    	SetupData sd = new setUpData();
    	system.assertNotEquals(null,globalTestData.customerSoldTo.Id);
    	String ns = KSE.NamespaceUU;
    	insert new Process__c(Name ='test',Object_Step__c ='CustomerOutstandingBalanceService',State__c = '1',Object__c =ns+'Customer__c',Sequence__c = 1, Bulk__c = true, Active__c =true, Namespace__c = ns);
    	Test.startTest(); 
    	list<Customer_Invoice__c> CIs = [Select id, bill_to_customer__c, bill_to_customer__r.Top_Parent_Customer__c  from Customer_Invoice__c];
    	system.debug('inside test, CIs: '+Cis);
    	system.assert(CIs.size() == 12,'SETUP DATA should create 10 Customer Invoices');
    	//Other than RMA SO
    	
    	Sales_Order__c salesOrder = globalTestData.newSalesOrder();
        salesOrder.Ship_to__c = globalTestData.customerShipTo.Id;
        salesOrder.Bill_To__c = globalTestData.customerBillTo.Id;
        salesOrder.Currency__c = TestFuel.currencyUSD.id;
        salesOrder.Original_Sales_Order__c = 'so123';         
        salesOrder.Status__c = SalesOrderService.SO_STATUS_OPEN;
        salesOrder.Type__c = 'Standard';
        insert salesOrder;        
        
                
        Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Company__c = globalTestData.company.Id;
        salesOrderLine.Description__c = globalTestData.product.Description__c;
        salesOrderLine.Discount_Percent__c = 0;
        salesOrderLine.Product__c = globalTestData.product.Id;
        salesOrderLine.Quantity_Ordered__c = 10;
        salesOrderLine.Required_Date__c = System.today()+5;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Ship_From_Location__c = globalTestData.location2.Id;
        salesOrderLine.Unit_Price__c = 10;
        salesOrderLine.Memo__c = 'salesOrderLine';
        insert salesOrderLine;     
        salesOrder.Status__c = SalesOrderService.SO_STATUS_OPEN;
        update salesOrder;    
        List<Sales_Order__c> so = [select Subtotal__c,Status__c,Credit_Hold__c from Sales_Order__c where id = :salesOrder.Id];
        system.assertEquals(so[0].Subtotal__c,100,so);
        system.assertEquals(so[0].Status__c,'Open',so);
        
        //Other than RMA SO
    	
    	salesOrder = globalTestData.newSalesOrder();
        salesOrder.Ship_to__c = globalTestData.customerShipTo.Id;
        salesOrder.Bill_To__c = globalTestData.customerBillTo.Id;
        salesOrder.Currency__c = TestFuel.currencyUSD.id;
        salesOrder.Original_Sales_Order__c = 'so123';         
        salesOrder.Type__c = 'Drop Ship';
        insert salesOrder;        
        
                
        salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Company__c = globalTestData.company.Id;
        salesOrderLine.Description__c = globalTestData.product.Description__c;
        salesOrderLine.Discount_Percent__c = 0;
        salesOrderLine.Product__c = globalTestData.product.Id;
        salesOrderLine.Quantity_Ordered__c = 10;
        salesOrderLine.Required_Date__c = System.today()+5;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Ship_From_Location__c = globalTestData.location2.Id;
        salesOrderLine.Unit_Price__c = 10;
        salesOrderLine.Memo__c = 'salesOrderLine';
        insert salesOrderLine;     
        salesOrder.Status__c = SalesOrderService.SO_STATUS_OPEN;
        update salesOrder;  
        
    	//RMA-Credit Salesorder
    	salesOrder = globalTestData.newSalesOrder();
        salesOrder.Ship_to__c = globalTestData.customerShipTo.Id;
        salesOrder.Bill_To__c = globalTestData.customerBillTo.Id;
        salesOrder.Currency__c = TestFuel.currencyUSD.id;
        salesOrder.Original_Sales_Order__c = 'so123'; 
        salesOrder.Type__c = SalesOrderService.SO_TYPE_RMA;
        salesOrder.Status__c = SalesOrderService.SO_STATUS_OPEN;
        insert salesOrder;        
        
      
        salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Company__c = globalTestData.company.Id;
        salesOrderLine.Description__c = globalTestData.product.Description__c;
        salesOrderLine.Discount_Percent__c = 0;
        salesOrderLine.Product__c = globalTestData.product.Id;
        salesOrderLine.Quantity_Ordered__c = 10;
        salesOrderLine.Required_Date__c = System.today()+5;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Ship_From_Location__c = globalTestData.location2.Id;
        salesOrderLine.Unit_Price__c = 10;
        salesOrderLine.Memo__c = 'salesOrderLine';
        insert salesOrderLine; 
        salesOrder.Status__c = SalesOrderService.SO_STATUS_OPEN;
        update salesOrder;
        
    	List<Sales_Order__c> so1 = [select Subtotal__c,Status__c,Credit_Hold__c from Sales_Order__c where id = :salesOrder.Id];
        system.assertEquals(so1[0].Subtotal__c,100,so1);
        system.assertEquals(so1[0].Status__c,'Open',so1);
        system.assertEquals(so1[0].Credit_Hold__c,false,so1);
        
        //RMA-Repair Salesorder
    	salesOrder = globalTestData.newSalesOrder();
        salesOrder.Ship_to__c = globalTestData.customerShipTo.Id;
        salesOrder.Bill_To__c = globalTestData.customerBillTo.Id;
        salesOrder.Currency__c = TestFuel.currencyUSD.id;
        salesOrder.Original_Sales_Order__c = 'so123'; 
        salesOrder.Type__c = SalesOrderService.SO_TYPE_RMA_REPAIR;
        insert salesOrder;        
        
      
        salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Company__c = globalTestData.company.Id;
        salesOrderLine.Description__c = globalTestData.product.Description__c;
        salesOrderLine.Discount_Percent__c = 0;
        salesOrderLine.Product__c = globalTestData.product.Id;
        salesOrderLine.Quantity_Ordered__c = 10;
        salesOrderLine.Required_Date__c = System.today()+5;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Ship_From_Location__c = globalTestData.location2.Id;
        salesOrderLine.Unit_Price__c = 10;
        salesOrderLine.Memo__c = 'salesOrderLine';
        insert salesOrderLine; 
        salesOrder.Status__c = SalesOrderService.SO_STATUS_OPEN;
        update salesOrder;
        
        //RMA-Replacement Salesorder
    	salesOrder = globalTestData.newSalesOrder();
        salesOrder.Ship_to__c = globalTestData.customerShipTo.Id;
        salesOrder.Bill_To__c = globalTestData.customerBillTo.Id;
        salesOrder.Currency__c = TestFuel.currencyUSD.id;
        salesOrder.Original_Sales_Order__c = 'so123'; 
        salesOrder.Type__c = SalesOrderService.SO_TYPE_RMA_REPLACEMENT;
        insert salesOrder;        
        
      
        salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Company__c = globalTestData.company.Id;
        salesOrderLine.Description__c = globalTestData.product.Description__c;
        salesOrderLine.Discount_Percent__c = 0;
        salesOrderLine.Product__c = globalTestData.product.Id;
        salesOrderLine.Quantity_Ordered__c = 10;
        salesOrderLine.Required_Date__c = System.today()+5;
        salesOrderLine.Sales_Order__c = salesOrder.Id;
        salesOrderLine.Ship_From_Location__c = globalTestData.location2.Id;
        salesOrderLine.Unit_Price__c = 10;
        salesOrderLine.Memo__c = 'salesOrderLine';
        insert salesOrderLine; 
        salesOrder.Status__c = SalesOrderService.SO_STATUS_OPEN;
        update salesOrder;
        
        
    	Process_Job__c j = new Process_Job__c(Active__c = true, Apex_Class__c = 'CustomerOutstandingBalanceBatch',Name = 'test',Batch_size__c =1,Namespace__c = ns);
    	insert j;
    	CustomerOutstandingBalanceBatch testbatch = new CustomerOutstandingBalanceBatch();
    	testbatch.runBatch(j);
       Test.stopTest();
       
       Customer__c soldcust = [Select id, Open_Invoices__c, Open_Credits__c, Outstanding_Balance2__c,Uninvoiced_Shipments__c,Open_Sales_Orders__c from Customer__c where id = :globalTestData.customerSoldTo.id limit 1 ];
       System.debug(logginglevel.error,'soldcust---->'+soldcust);
       system.assert(soldcust.Open_Sales_Orders__c == 200,' Open SO is sum of positive Cis balance = ' + soldcust.Open_Sales_Orders__c);
       system.assert(soldcust.Outstanding_Balance2__c == soldcust.Open_Invoices__c + soldcust.Open_Credits__c+ soldcust.Uninvoiced_Shipments__c+ soldcust.Open_Sales_Orders__c,' Outstanding_Balance__c = 11, ' + soldcust.Outstanding_Balance2__c);
    }

	static testMethod void InvoicedNotTobeIncluded() {

		SetupData sd = new setUpData();
		list<Configuration__c> lConfigs = new list<Configuration__c>();
		lConfigs.add(new Configuration__c(Name = 'Customer_Invoice__c-'+Customer_Invoice__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserId()));
		insert lConfigs;

		list<String> statuses = new list<String>{'Open', 'Cancelled', 'Void'};
		list<Customer_Invoice__c> notIcludedCIs = new list<Customer_Invoice__c>();
		for(integer i=0; i < 6; ++i) {
			notIcludedCIs.add(new Customer_Invoice__c(Company__c = globalTestData.company.Id,
													  sold_to_customer__c = globalTestData.customerSoldTo.Id,
													  bill_to_customer__c = globalTestData.customerBillTo.Id,
													  Customer__c = globalTestData.customerParent.Id,
													  Currency__c = TestFuel.currencyUSD.id,
													  Invoice_Type__c = 'Manual',
					 								  Status__c = statuses[(i >=3 ? i-3 : i)])); //0 -> 0, 1 -> 1, 2 -> 2, 3 -> 0, 4 ->1, 5 ->2
		}
		insert notIcludedCIs;
		list<Customer_Invoice_Line__c> notIcludedCILs = new list<Customer_Invoice_Line__c>();
		for(integer i=0; i < 6; ++i) {
			notIcludedCILs.add(new Customer_Invoice_Line__c(Customer_Invoice__c = notIcludedCIs[i].Id,
													  Quantity_Shipped__c =  i >=3 ? 1 : -1,
													  Unit_Price__c = 10));
		}

		insert notIcludedCILs;
		delete lConfigs;
		system.assertNotEquals(null,globalTestData.customerSoldTo.Id);
		String ns = KSE.NamespaceUU;
		insert new Process__c(Name ='test',Object_Step__c ='CustomerOutstandingBalanceService',State__c = '1',Object__c =ns+'Customer__c',Sequence__c = 1, Bulk__c = true, Active__c =true, Namespace__c = ns);
		Test.startTest();
		list<Customer_Invoice__c> CIs = [Select id, bill_to_customer__c, bill_to_customer__r.Top_Parent_Customer__c  from Customer_Invoice__c];
		system.debug('inside test, CIs: '+Cis);
		system.assert(CIs.size() == 18,'SETUP DATA should create 18 Customer Invoices '+CIs.size());

		CustomerOutstandingBalanceBatch testbatch = new CustomerOutstandingBalanceBatch();
		Id jobId=Database.executebatch(testbatch,10);
		Test.stopTest();


		Customer__c corpParent = [Select id, Open_Invoices__c, Open_Credits__c, Outstanding_Balance2__c,Uninvoiced_Shipments__c,Open_Sales_Orders__c from Customer__c where id = :globalTestData.customerParent.id limit 1 ];
		System.debug(logginglevel.error,'corpParent---->'+corpParent);
		system.assert(corpParent.Open_Invoices__c == 75.53,' Open invoices is sum of positive Cis balance = ' + corpParent.Open_Invoices__c);
		system.assert(corpParent.Open_Credits__c == -230,' Open invoices is sum of positive Cis balance = ' + corpParent.Open_Credits__c);
		system.assert(corpParent.Uninvoiced_Shipments__c == 11,' corpParent.Uninvoiced_Shipments__c ' + corpParent.Uninvoiced_Shipments__c);
		system.assert(corpParent.Outstanding_Balance2__c == corpParent.Open_Invoices__c + corpParent.Open_Credits__c+ corpParent.Uninvoiced_Shipments__c+ corpParent.Open_Sales_Orders__c,' Outstanding_Balance__c = 11, ' + corpParent.Outstanding_Balance2__c);


	}
}