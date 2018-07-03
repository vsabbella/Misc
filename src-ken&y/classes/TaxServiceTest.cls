@isTest
private class TaxServiceTest {

	public static final String PROCESS_STEP = 'DefaultSalesTax';

	@testSetup static void ts() { 
        TestFuel fuel = new TestFuel(); 
        system.assert(fuel.company.Id != null &&
        			  fuel.customerParent.Id != null &&
        			  fuel.customerBillTo.Id != null &&
        			  fuel.customerSoldTo.Id != null &&
        			  fuel.salesOrder.id != null &&
        			  fuel.custInv1.Id != null &&
        			  TestFuel.currencyUSD.Id != null);
	}

	public static TestFuelQuery globalTestData = new TestFuelQuery();
	
	static testmethod void test_TaxServiceNotConfigured() {

		TaxService txs = TaxService.getInstance();

		System.assertEquals(false, txs.HasTaxService);
		Sales_Order__c so = globalTestData.SalesOrder;
		try{
			txs.getTax(so.Id);
			System.assert(false);
		}catch(TaxService.TaxServiceException ex){
			System.assert(true);
		}

		try{
			txs.getDisplayFieldSet(so.getSobjectType());
			System.assert(false);
		}catch(TaxService.TaxServiceException ex){
			System.assert(true);
		}

		try{
			Customer_Invoice__c ci = globalTestData.custInv1;
			txs.voidTaxes(new List<Sobject>{ci});
			System.assert(false);
		}catch(TaxService.TaxServiceException ex){
			System.assert(true);
		}



	}
	
	static testmethod void test_TaxServiceConfigured() {
		Process__c proc = new Process__c();
		proc.Name = 'TaxService';
		proc.Active__c = true;
		proc.Object_Step__c = PROCESS_STEP;

		insert proc;

		TaxService txs = TaxService.getInstance();

		System.assertEquals(true, txs.HasTaxService);

		Sales_Order__c so = globalTestData.SalesOrder;

		try{
			TaxService.TaxResult tr = txs.getTax(so.Id);
			System.assertEquals(true, tr.isSuccess);
		}catch(Exception ex){
			System.assert(false);
		}

		try{
			List<FieldInfo> fis = txs.getDisplayFieldSet(Sales_Order__c.getSobjectType());
			System.assertEquals(true, fis.size()>0);
		}catch(Exception ex){
			System.assert(false);
		}

		try{
			Customer_Invoice__c ci = globalTestData.custInv1;
			List<TaxService.TaxResult> trCI = txs.voidTaxes(new List<SObject>{ci});
			System.assert(true);
		}catch(Exception ex){
			System.assert(false);
		}

	}

	static testmethod void test_BatchInjector(){
		List<Process__c> procs = new List<Process__c>();
		
		for(Integer i=1; i<=2; i++){
			Process__c proc = new Process__c();
			proc.Name = 'BatchInjector' + i;
			proc.Object__c = Schema.Customer_Invoice__c.getSObjectType().getDescribe().getName();
			proc.Active__c = true;
			proc.Bulk__c = true;
			proc.Sequence__c = i;
			proc.State__c = String.valueOf(100 * i);
			proc.Object_Step__c = PROCESS_STEP;
			procs.add(proc);
		}
		insert procs;

		BatchInjector bi = BatchInjector.getNextBatch(Schema.Customer_Invoice__c.getSObjectType().getDescribe().getName(), 0);
		System.assertEquals(1, bi.sequence);
		System.assertEquals(true, bi.executer != null);

		BatchInjector bi2 = BatchInjector.getNextBatch(Schema.Customer_Invoice__c.getSObjectType().getDescribe().getName(), 1);
		System.assertEquals(2, bi2.sequence);
		System.assertEquals(true, bi2.executer != null);

		BatchInjector bi3 = BatchInjector.getNextBatch(Schema.Customer_Invoice__c.getSObjectType().getDescribe().getName(), 2);
		System.debug('#### b3:' + bi3);
		System.assertEquals(false, bi3.executer != null);
	}

	static testmethod void test_InvoiceBatching(){
		Process__c proc = new Process__c();
		proc.Name = 'TaxService';
		proc.Active__c = true;
		proc.Object_Step__c = PROCESS_STEP;

		insert proc;

        String customers = JSON.serialize(new set<Id>{globalTestData.customerSoldTo.ID});
        

        Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = DateTime.newInstance(2015,5,30,0,0,0), rank__c = 1, For_Customers__c = customers, Group_By_Sales_Orders__c = true, Company__c = globalTestData.company.Id);
        
        insert igr;
        igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
        system.assertEquals(true, igr.is_Valid__c);
        
        
        system.assertNotEquals(null,globalTestData.salesOrder.Id);
        list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :globalTestData.salesOrder.Id];
        
        system.assertEquals(2,lSOLs.size());
        
        list<Fulfillment__c> lFs = new list<Fulfillment__c>();
        lFs.add(new Fulfillment__c(Customer__c = globalTestData.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = globalTestData.currencyUSD.id, Payment_Term__c = globalTestData.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 3, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));
        
        lFs.add(new Fulfillment__c(Customer__c = globalTestData.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,6,20,0,0,0), Currency__c = globalTestData.currencyUSD.id, Payment_Term__c = globalTestData.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 4, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Customer__c = globalTestData.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,7,20,0,0,0), Currency__c = globalTestData.currencyUSD.id, Payment_Term__c = globalTestData.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 5, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));
        lFs.add(new Fulfillment__c(Customer__c = globalTestData.customerSoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,8,20,0,0,0), Currency__c = globalTestData.currencyUSD.id, Payment_Term__c = globalTestData.terms.ID, Sales_Order_Line__c = lSOLs[0].Id,
                                   Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 120, Quantity__c = 6, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));
        insert lFs;
        
        
        test.startTest();
            Id jobID = Database.executebatch(new CustomerInvoiceBatch(new set<ID>{globalTestData.company.Id}),10);
        test.StopTest();

		List<Customer_Invoice_Line__c> invoiceLines = [Select Id,Sales_Tax__c From Customer_Invoice_Line__c Where Sales_Order__c =: globalTestData.salesOrder.Id];

        TaxServiceTest.ExpectedCILTaxAmount = 0;
		for(Customer_Invoice_Line__c cil : invoiceLines){
			System.assertEquals(TaxServiceTest.ExpectedCILTaxAmount, cil.Sales_Tax__c, 'Expectiong: ' + TaxServiceTest.ExpectedCILTaxAmount+ ' Returned: ' + cil.Sales_Tax__c);
		}
	}

	static testMethod void getTaxRunsOncePerCompany() {

		Process__c proc = new Process__c();
		proc.Name = 'TaxService';
		proc.Active__c = true;
		proc.Object_Step__c = PROCESS_STEP;

		insert proc;

		Customer_Invoice__c custInv1 = new Customer_Invoice__c();
		custInv1.Company__c = globalTestData.company.id;
		custInv1.Invoice_Type__c = 'Ship Invoice';
		custInv1.Status__c = 'Open';
		custInv1.Bill_To_Customer__c = globalTestData.customerBillTo.id;
		custInv1.Sold_To_Customer__c = globalTestData.customerSoldTo.id;
		insert custInv1;

		Customer_Invoice__c custInv2 = new Customer_Invoice__c();
		custInv2.Company__c = globalTestData.company.id;
		custInv2.Invoice_Type__c = 'Ship Invoice';
		custInv2.Status__c = 'Open';
		custInv2.Bill_To_Customer__c = globalTestData.customerBillTo.id;
		custInv2.Sold_To_Customer__c = globalTestData.customerSoldTo.id;
		insert custInv2;

		list<Customer_Invoice_Line__c> lCIL = new list<Customer_Invoice_Line__c>();
		lCIL.add(new Customer_Invoice_Line__c(Customer_Invoice__c = custInv1.Id, Unit_Price__c =1, Quantity_Shipped__c =1));
		lCIL.add(new Customer_Invoice_Line__c(Customer_Invoice__c = custInv2.Id, Unit_Price__c =1, Quantity_Shipped__c =1));

		insert lCIL;

		TaxService.CustomerInvoiceTaxBatch ts = new TaxService.CustomerInvoiceTaxBatch();
		ts.executeAction(new list<Customer_INvoice__c>{custInv1, custInv2});
		system.assertEquals(1, ts.count);





	}

	static testmethod void canCancelWithTaxService(){

        Process__c proc = new Process__c();
        proc.Name = 'TaxService';
        proc.Active__c = true;
        proc.Object_Step__c = PROCESS_STEP;

        insert proc;

        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = globalTestData.customerBillTo.Id;
        CustomerInvoice.Company__c = globalTestData.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        insert CustomerInvoice;
        
        Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
        cil.Customer_Invoice__c = CustomerInvoice.Id;
        cil.Quantity_Shipped__c = 1;
        cil.Unit_Price__c = 100;
        insert cil;
        
        CustomerInvoice.Finalized__c = true;
        update CustomerInvoice;
        
        test.StartTest();


        	Id custId = CustomerInvoice.Id;
        	SoqlUtil soql = new SoqlUtil('Customer_Invoice__c');
			soql.addFields(new Set<String>{'Id', 'Name', 'Company__c', 'Finalized__c', 'Void__c',
												'Void_Date__c', 'Status__c', 'Transaction_Date__c',
												'Finalized_Date__c', 'Posting_Date__c', 'Historical__c'});
			soql.setWhereClause('Id =:custId');
			CustomerInvoice = Database.Query(soql.getQuery());


            
            //CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
            CustomerInvoiceVoidCancelExt ext = new CustomerInvoiceVoidCancelExt(new ApexPages.standardController(CustomerInvoice));
            
            
            system.assert(!ext.getDisableCancel() == true);
            
            ext.cancelDocs();

            soql = new SoqlUtil('Customer_Invoice__c');
			soql.addFields(new Set<String>{'Id', 'Status__c'});
			soql.setWhereClause('Id =:custId');
			CustomerInvoice = Database.Query(soql.getQuery());

            system.assertEquals(CustomerInvoice.Status__c, 'Cancelled');
        test.StopTest();    

    }

	static testmethod void SO_success_withExternalProcess() {

		/*Process__c proc = new Process__c();
        proc.Name = 'TaxService';
        proc.Active__c = true;
        proc.Object_Step__c = PROCESS_STEP;

        insert proc;

      	system.assertNotEquals(null,globalTestData.salesOrder.Id);

      	Id soId = globalTestData.salesOrder.Id;

      	SoqlUtil soql = new SoqlUtil('Sales_Order_Line__c');
      	soql.addFields(new Set<String>{'Id', 'Product__c'});
      	soql.setWhereClause('Sales_Order__c =:soId');

      	List<Sales_Order_Line__c>lSOLs = Database.query(soql.getQuery());
        
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
        lFs.add(new Fulfillment__c(Customer__c = globalTestData.customersoldTo.Id, Fulfillment_Date__c = DateTime.newInstance(2015,5,20,0,0,0), Currency__c = globalTestData.currencyUSD.id, Payment_Term__c = globalTestData.terms.ID, Sales_Order_Line__c = lSOLs[0].Id, 
                                              Name = 'F1', Invoice_Ready__c = true, Unit_Price__c = 100, Quantity__c = 1, Product__c = lSOLs[0].Product__c, Status__c = 'Complete'));
        insert lFs;
       
        ApexPages.standardController con = new ApexPages.standardController(globalTestData.salesOrder);
        GenerateInvoiceExt ext = new GenerateInvoiceExt(con);
        //ext.overrideSystemRule = false;
        ext.validate();
        ext.next();
        ext.prefinalizeActions();
        ext.finalizeInvoices();
        system.assertEquals(false, ext.visibleConfirmButton);

        soql = new SoqlUtil('Customer_Invoice__c');
        soql.addFields(new Set<String>{'Id', 'Finalized__c'});
        soql.setWhereClause('Sales_Order__c =:soId');

        List<Customer_Invoice__c> lCI = Database.query(soql.getQuery());
        system.assertEquals(1,lCI.size(),ApexPages.GetMessages());

        Id cId = lCI.get(0).Id;

        soql = new SoqlUtil('Customer_Invoice_Line__c');
        soql.addFields(new Set<String>{'Id', 'Sales_Tax__c'});
        soql.setWhereClause('Customer_Invoice__c =:cId');

        list<Customer_Invoice_Line__c>cils = Database.query(soql.getQuery());
        for(Customer_Invoice_Line__c cil : cils){
        	system.assertEquals(TaxServiceTest.ExpectedCILTaxAmount, cil.Sales_Tax__c);
        }

        
        con = new ApexPages.standardController(globalTestData.salesOrder);
        ext = new GenerateInvoiceExt(con);
        ext.validate();
        boolean ErrorExists = false;
        for( ApexPages.Message msg :ApexPages.GetMessages())
          if(msg.getDetail().contains(Label.No_Fulfillments_To_Invoice))
          {
            ErrorExists = true;
            break;
          }
        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
        system.assertEquals(false, ext.visibleNextButton, ext.visibleNextButton);
        system.assertEquals(false, ext.visibleConfirmButton, ext.visibleConfirmButton);*/
    }	

/*    @isTest static void purchaseOrderGetTaxNoService(){
        Purchase_Order__c po = globalTestData.purchaseOrder;
        po.Company__c = globalTestData.company.id;

        JsonResult tr = PurchaseOrderManageExt.getTax(po.Id);

        system.assertEquals(false, tr.success);
    }

    @isTest static void purchaseOrderGetTaxWithService(){
    	Process__c proc = new Process__c();
        proc.Name = 'TaxService';
        proc.Active__c = true;
        proc.Namespace__c = KSE.Namespace;
        proc.Object_Step__c = PROCESS_STEP;

        insert proc;

    	Testfuel fuel = new Testfuel();
        Purchase_Order__c po = fuel.purchaseOrder;
        po.Company__c = fuel.company.id;

        JsonResult tr = PurchaseOrderManageExt.getTax(po.Id);

        system.assertEquals(true, tr.success);

        List<Purchase_Order_Line__c>lines = [Select Id, Sales_Tax_Amount__c From Purchase_Order_Line__c Where Purchase_Order__c=:po.Id];
        for(Purchase_Order_Line__c l : lines){
        	system.assertEquals(TaxServiceTest.ExpectedCILTaxAmount, l.Sales_Tax_Amount__c);
        }
    }*/

	static testmethod void salesOrderGetTaxNoService(){

		Sales_Order__c so = globalTestData.salesOrder;
		Id soId = so.Id;

		SoqlUtil soql = new SoqlUtil('Sales_Order_Line__c');
		soql.addFields(new Set<String>{'Id', 'Product__c', 'Accounting_Segment__c'});
		soql.setWhereClause('Sales_Order__c =:soId');

		List<Sales_Order_Line__c>sols = Database.query(soql.getQuery());

		JSONResult jr = SalesOrderManageLinesExt.fetchTaxes(JSON.serialize(so), getSOWrapper(sols));
		System.assertEquals(false, jr.success);


	}

	static testmethod void salesOrderGetTaxWithService(){
		Process__c proc = new Process__c();
        proc.Name = 'TaxService';
        proc.Active__c = true;
        proc.Object_Step__c = PROCESS_STEP;

        insert proc;

		Sales_Order__c so = globalTestData.salesOrder;
		Id soId = so.Id;

		SoqlUtil soql = new SoqlUtil('Sales_Order_Line__c');
		soql.addFields(new Set<String>{'Id', 'Product__c', 'Accounting_Segment__c'});
		soql.setWhereClause('Sales_Order__c =:soId');

		List<Sales_Order_Line__c>sols = Database.query(soql.getQuery());

		JSONResult jr = SalesOrderManageLinesExt.fetchTaxes(JSON.serialize(so), getSOWrapper(sols));
		System.assertEquals(true, jr.success);

		soql = new SoqlUtil('Sales_Order_Line__c');
		soql.addFields(new Set<String>{'Id', 'Sales_Tax__c'});
		soql.setWhereClause('Sales_Order__c=:soId');

		sols = Database.query(soql.getQuery());

		for(Sales_Order_Line__c l : sols){
			System.assertEquals(TaxServiceTest.ExpectedCILTaxAmount, l.Sales_Tax__c);
		}

	}
	//----KNDY-16286------SO of Type RMA-Replacement:: Not taxable-----------------//
	static testmethod void testSOGetTaxForBlacklistedInvoiceType(){
		Process__c proc = new Process__c();
        proc.Name = 'TaxService';
        proc.Active__c = true;
        proc.Object_Step__c = PROCESS_STEP;

        insert proc;

		Sales_Order__c so = globalTestData.salesOrder;
		Id soId = so.Id;
		
		so.Type__c = 'RMA-Replacement';
		update so; 
		
		List<Sales_Order_Line__c> sols  = [SELECT Id, Product__c, Accounting_Segment__c,Type__c 
                                                    FROM Sales_Order_Line__c 
                                                    WHERE Sales_Order__c =:soId]; 
		
        Test.StartTest();   
            JSONResult jr = SalesOrderManageLinesExt.fetchTaxes(JSON.serialize(so), getSOWrapper(sols));
    	 
    	    sols  = [SELECT Id,  Sales_Tax__c 
                            FROM Sales_Order_Line__c 
                            WHERE Sales_Order__c =:soId]; 
    
    		for(Sales_Order_Line__c l : sols){
    			System.assertNotEquals(TaxServiceTest.ExpectedCILTaxAmount, l.Sales_Tax__c); 
    		}
        Test.StopTest();   
	  
	}

	private static List<SalesOrderManageLinesExt.SOLineWrapper> getSOWrapper(List<Sales_Order_Line__c>sols){

		List<SalesOrderManageLinesExt.SOLineWrapper> solWs = new List<SalesOrderManageLinesExt.SOLineWrapper>();

		for(Sales_Order_Line__c sol : sols){
			solWs.add(new SalesOrderManageLinesExt.SOLineWrapper(sol));
		}

		return solWs;

	}

	public static Decimal ExpectedCILTaxAmount = 0;
	public static Decimal ExpectedCILTaxRate = 0;

}