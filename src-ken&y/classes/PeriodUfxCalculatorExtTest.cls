@isTest
private class PeriodUfxCalculatorExtTest {

	private static Period__c period;
	private static TestFuel fuel;
	@testSetup static void ts() { 
		fuel = new TestFuel();
		period = fuel.periodList.get(0);
		setupTestData();
		createORAccountingEntryLine(period);

	}

/*	@isTest static void testInitalPageLoadMissingConfigs() {
		Period__c p = [Select Id From Period__c limit 1];

		Test.startTest();

		PeriodUfxCalculatorExt ufxCalc = new PeriodUfxCalculatorExt( new ApexPages.StandardController(p));

		Test.stopTest();

		System.assertEquals(false, ufxCalc.HasBeginingExchangeRate);
		System.assertEquals(false, ufxCalc.HasGlAccounts);

	}*/
	
	static testmethod void testInitalPageLoadConfigured() {
	
		//setupTestData();
		
		Test.startTest();

		Period__c p = [Select Id From Period__c limit 1];

		PeriodUfxCalculatorExt ufxCalc = new PeriodUfxCalculatorExt( new ApexPages.StandardController(p));

		Map<String,String>range = new Map<String,String>{'first'=>'0', 'last'=>'100'};

		//PeriodUfxCalculatorExt.getORAccountingEntries(range,fuel.periodList.get(0).Id, true);

		Test.stopTest();

		System.assertEquals(true, ufxCalc.HasBeginingExchangeRate);
		System.assertEquals(true, ufxCalc.HasEndExchangeRate);
		System.assertEquals(true, ufxCalc.HasGlAccounts);

	}

	static testmethod void testGetORAccountingEntries() {
		//setupTestData();
		//createORAccountingEntryLine();
		Test.startTest();
		List<Accounting_Entry_Line__c>lines = [Select Id From Accounting_Entry_Line__c order By Id];
		Period__c p = [Select Id From Period__c limit 1];


		PeriodUfxCalculatorExt ufxCalc = new PeriodUfxCalculatorExt( new ApexPages.StandardController(p));

		Map<String,String>range = new Map<String,String>{'first'=>lines.get(0).Id, 'last'=>lines.get(lines.size()-1).Id};

		List<PeriodUfxCalculatorExt.AEResults> aeresults = PeriodUfxCalculatorExt.getEntriesForUfx(range,p.Id, true);
		System.debug(LoggingLevel.ERROR,'#### ' + aeresults);
		
		Test.stopTest();

		System.assert(aeresults.size() == 4, 'Expect 4 got ' + aeresults.size() );
	}

/*	@isTest static void testgetAPAccountingEntries(){

		//setupTestData();

		//createAPAccountingEntryLine();
		Period__c p = [Select Id From Period__c limit 1];
		List<Accounting_Entry_Line__c>lines = [Select Id From Accounting_Entry_Line__c order By Id];

		Test.startTest();
		PeriodUfxCalculatorExt ufxCalc = new PeriodUfxCalculatorExt( new ApexPages.StandardController(p));

		Map<String,String>range = new Map<String,String>{'first'=>lines.get(0).Id, 'last'=>lines.get(lines.size()-1).Id};

		List<PeriodUfxCalculatorExt.AEResults> aeresults = PeriodUfxCalculatorExt.getAPAccountingEntries(range, p.Id, true);
		Test.stopTest();

	}

	@isTest static void testGetGRNIAccountingEntries(){
		//setupTestData();

		//createGRNIAccounting();
		Period__c p = [Select Id From Period__c limit 1];
		List<Accounting_Entry_Line__c>lines = [Select Id From Accounting_Entry_Line__c order By Id];

		Test.startTest();
		PeriodUfxCalculatorExt ufxCalc = new PeriodUfxCalculatorExt( new ApexPages.StandardController(p));

		Map<String,String>range = new Map<String,String>{'first'=>lines.get(0).Id, 'last'=>lines.get(lines.size()-1).Id};

		List<PeriodUfxCalculatorExt.AEResults> aeresults = PeriodUfxCalculatorExt.getGRNIAccountingEntries(range, p.Id, true);
		Test.stopTest();

	}*/

	static testmethod void testCreateJournalEntryHeader(){
		//setupTestData();
		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Task-'+Task.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        //lConfigs.add(new Configuration__c(Name = 'Task', Value__c = currentUser.id)); //-00T
        insert lConfigs;
		
		Test.startTest();

		Id ufxGL = [Select Id From GL_Account__c Where FX_Type__c = 'UFX' limit 1].Id;
		Period__c p = [Select Id From Period__c limit 1];
		Company__c c = [Select Id From Company__c limit 1];

		PeriodUfxCalculatorExt ufxCalc = new PeriodUfxCalculatorExt( new ApexPages.StandardController(p));


		List<Journal_Entry__c> jes = PeriodUfxCalculatorExt.createJournalEntryHeader(new List<String>{c.id}, p.Id, 'UFX');

		Journal_Entry_Line__c jje = new Journal_Entry_Line__c();
		jje.Amount_CR__c = 0;
		jje.Amount_DR__c = 100;
		jje.GL_Account__c = ufxGL;
		jje.Journal_Entry__c = jes.get(0).Id;

		PeriodUfxCalculatorExt.createeJournalEntryLines(new List<Journal_Entry_Line__c>{jje});

		PeriodUfxCalculatorExt.finalizeJournalEntries(jes);

		Test.stopTest();
	}


	private static void createORAccountingEntryLine(Period__c p){

	    User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice__c-'+Supplier_Invoice__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;

		Id nonMonGl = [Select Id From GL_Account__c Where FX_Type__c = 'Monetary Non-cash' limit 1].Id;
		GL_Account__c plMon = [Select Id, Normal_Balance__c From GL_Account__c Where FX_Type__c = 'P/L Monetary' limit 1];

		Purchase_Order__c po = fuel.purchaseOrder1;
		po.Currency__c = TestFuel.currencyCAD.id;
		update po;

		List<Supplier_Invoice__c>sis = new List<Supplier_Invoice__c>();

		Supplier_Invoice__c suppInv = new Supplier_Invoice__c();
		suppInv.Company__c = fuel.company.id;
        suppInv.Invoice_Type__c = 'Invoice';
        suppInv.Date_Invoiced__c = p.Period_End__c.addDays(-3);
        suppInv.currency__c = TestFuel.currencyCAD.id;
        suppInv.Transaction_Date__c = p.Period_End__c.addDays(-3);
        suppInv.Supplier__c = fuel.remittosupplier.id;
        suppInv.Amount_Due__c = 100;
        suppInv.Invoice_Amount__c = 100;
        suppInv.Supplier_Invoice__c = String.valueOfGmt(system.today()) + 1;
        suppInv.historical__c = false;
        sis.add(suppInv);

        Supplier_Invoice__c suppInv2 = new Supplier_Invoice__c();
		suppInv2.Company__c = fuel.company.id;
        suppInv2.Invoice_Type__c = 'Invoice';
        suppInv2.Date_Invoiced__c = p.Period_End__c.addDays(-3);
        suppInv2.Currency__c = TestFuel.currencyCAD.id;
        suppInv2.Transaction_Date__c = p.Period_End__c.addDays(-3);
        suppInv2.Supplier__c = fuel.remittosupplier.id;
        suppInv2.Amount_Due__c = 100;
        suppInv2.Invoice_Amount__c = 100;
        suppInv2.Supplier_Invoice__c = String.valueOfGmt(system.today()) + 3;
        suppInv2.historical__c = false;
        sis.add(suppInv2);

        Supplier_Invoice__c suppInv3 = new Supplier_Invoice__c();
		suppInv3.Company__c = fuel.company.id;
        suppInv3.Invoice_Type__c = 'Invoice';
        suppInv3.Date_Invoiced__c = p.Period_End__c.addDays(-3);
        suppInv3.Currency__c = TestFuel.currencyCAD.id;
        suppInv3.Transaction_Date__c = p.Period_End__c.addDays(-3);
        suppInv3.Supplier__c = fuel.remittosupplier.id;
        suppInv3.Amount_Due__c = 100;
        suppInv3.Invoice_Amount__c = 100;
        suppInv3.Supplier_Invoice__c = String.valueOfGmt(system.today()) + 2;
        suppInv3.historical__c = false;
        suppInv3.Status__c = 'Void';
        suppInv3.Void_Date__c = p.Period_End__c.addDays(-2);
        sis.add(suppInv3);

        insert sis;

        Journal_Entry__c je1 = new Journal_Entry__c();
		je1.name = 'JE001';
	    je1.Company__c = fuel.company.id;	
	    je1.type__c = 'Manual';   
	    je1.Transaction_Type__c = 'Manual';
	    je1.Transaction_Date__c = p.Period_End__c.addDays(-3);  
	    //je1.GL_Date__c = System.today();  
		je1.Currency__c = TestFuel.currencyCAD.id;
		//je1.Finalized__c = true;		
	    insert je1;

	    List<Journal_Entry_Line__c> jeLineList = new List<Journal_Entry_Line__c>();
		    
	    Journal_Entry_Line__c jeLine1 = new Journal_Entry_Line__c(); 
	    jeLine1.Journal_Entry__c = je1.id;
		jeLine1.Amount_CR__c = 5;
		jeLine1.Amount_DR__c = 0;
		jeLine1.GL_Account__c = nonMonGl;
		jeLine1.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine1); 
	    
	    Journal_Entry_Line__c jeLine2 = new Journal_Entry_Line__c(); 
	    jeLine2.Journal_Entry__c = je1.id;
		jeLine2.Amount_CR__c = 0;
		jeLine2.Amount_DR__c = 5;
		jeLine2.GL_Account__c = plMon.Id;
		jeLine2.Subtransaction_Type__c = 'Write Off';
	    jeLineList.add(jeLine2); 

	    insert jeLineList;



        List<Supplier_Invoice_Line__c>silines = new List<Supplier_Invoice_Line__c>();

        Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c(); 
        suppInvLine1.Supplier_Invoice__c = suppInv.id;
        suppInvLine1.Invoice_Quantity__c = 3;
        suppInvLine1.Invoice_Quantity_to_Stock__c = 8;
        suppInvLine1.Item__c = fuel.itemList[0].id;
        suppInvLine1.Purchase_Order__c = po.Id;
        suppInvLine1.Purchase_Order_Line__c = fuel.purchaseOrder1Lines.get(0).Id;
        suppInvLine1.Quantity_Received__c = 4;
        suppInvLine1.Unit_Price__c = 15; 
        suppInvLine1.Line_Type__c = 'Item';
        silines.add(suppInvLine1);

        Supplier_Invoice_Line__c suppInvLine2 = new Supplier_Invoice_Line__c(); 
        suppInvLine2.Supplier_Invoice__c = suppInv2.id;
        suppInvLine2.Invoice_Quantity__c = 3;
        suppInvLine2.Invoice_Quantity_to_Stock__c = 8;
        suppInvLine2.Item__c = fuel.itemList[0].id;
        suppInvLine2.Purchase_Order__c = po.Id;
        suppInvLine2.Purchase_Order_Line__c = fuel.purchaseOrder1Lines.get(0).Id;
        suppInvLine2.Quantity_Received__c = 4;
        suppInvLine2.Unit_Price__c = 15; 
        suppInvLine2.Line_Type__c = 'Item';
        silines.add(suppInvLine2);
        
        Supplier_Invoice_Line__c suppInvLine3 = new Supplier_Invoice_Line__c(); 
        suppInvLine3.Supplier_Invoice__c = suppInv3.id;
        suppInvLine3.Invoice_Quantity__c = 3;
        suppInvLine3.Invoice_Quantity_to_Stock__c = 8;
        suppInvLine3.Item__c = fuel.itemList[0].id;
        suppInvLine3.Purchase_Order__c = po.Id;
        suppInvLine3.Purchase_Order_Line__c = fuel.purchaseOrder1Lines.get(0).Id;
        suppInvLine3.Quantity_Received__c = 4;
        suppInvLine3.Unit_Price__c = 15; 
        suppInvLine3.Line_Type__c = 'Item';
        silines.add(suppInvLine3);
        
        insert silines;
		
        delete lConfigs;
		
		Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = p.Period_End__c.addDays(-3);
        CustomerInvoice.Transaction_Date__c = Date.today();
		//CustomerInvoice.Finalized__c =true;
		insert CustomerInvoice;

		Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
	    custInvLine1.Quantity_Shipped__c = 2;
	    custInvLine1.Company__c = fuel.company.Id;
	    //custInvLine1.Sales_Order_Line__c = data.SalesOrderLineList[0].id;
	    custInvLine1.Unit_Price__c = 7;
	    custInvLine1.Extended_Price__c = 14;
        custInvLine1.Quantity_Shipped__c = 3;
	    //custInvLine1.Sales_Order__c = data.salesOrder1.id;
	    custInvLine1.Product__c = fuel.product.Id; 
	    custInvLine1.Discount_Percent__c = 2;
	    custInvLine1.Customer_Invoice__c = CustomerInvoice.id;
	    insert custInvLine1;
		
		Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Company__c = fuel.company.Id;
		custReceipt.Customer__c = fuel.customerParent.Id;
		custReceipt.Date_Received__c = p.Period_End__c.addDays(-3);
		custReceipt.Type__c = 'Receipt';
		custReceipt.Currency__c = TestFuel.currencyCAD.id;
		insert custReceipt;

		Customer_Receipt_Line__c edt = new Customer_Receipt_Line__c();
		edt.Amount__c = 100;
		edt.Customer_Receipt__c = custReceipt.Id;
		edt.Customer_Invoice__c = CustomerInvoice.id;
		edt.Type__c = PaymentService.TYPE_EARNED_DISCOUNT;
		
		insert edt;

		List<Accounting_Entry__c>accEntries = new List<Accounting_Entry__c>();
		List<Accounting_Entry_Line__c> accEntryLines = new List<Accounting_Entry_Line__c>();

		Accounting_Entry__c ciEntry = new Accounting_Entry__c();
		ciEntry.company__c = fuel.company.id; 
        ciEntry.Transaction_Date__c = p.Period_End__c.addDays(-3);
        ciEntry.Finalized_Date__c = p.Period_End__c.addDays(-3);
        //acctEntry.GL_Date__c = system.today();
        ciEntry.Period__c = fuel.periodList.get(0).Id;
        ciEntry.Transaction_Type__c = 'Customer Invoice';
        ciEntry.Source_Document_Object_Name__c = 'Customer_Invoice__c';
        ciEntry.Currency__c = TestFuel.currencyCAD.id;
        ciEntry.Customer_Invoice__c = CustomerInvoice.id;
        ciEntry.Status__c = 'Active';

        accEntries.add(ciEntry);

		Accounting_Entry__c ciEntry1 = new Accounting_Entry__c();
		ciEntry1.company__c = fuel.company.id; 
        ciEntry1.Transaction_Date__c = p.Period_End__c.addDays(-3);
        ciEntry1.Finalized_Date__c = p.Period_End__c.addDays(-3);
        //acctEntry.GL_Date__c = system.today();
        ciEntry1.Period__c = fuel.periodList.get(0).Id;
        ciEntry1.Transaction_Type__c = 'Supplier Invoice';
        ciEntry1.Source_Document_Object_Name__c = 'Supplier_Invoice__c';
        ciEntry1.Currency__c = TestFuel.currencyCAD.id;
        ciEntry1.Supplier_Invoice__c = suppInv.Id;
        ciEntry1.Status__c = 'Active';
        accEntries.add(ciEntry1);

        Accounting_Entry__c ciEntry2 = new Accounting_Entry__c();
		ciEntry2.company__c = fuel.company.id; 
        ciEntry2.Transaction_Date__c = p.Period_End__c.addDays(-3);
        ciEntry2.Finalized_Date__c = p.Period_End__c.addDays(-3);
        //acctEntry.GL_Date__c = system.today();
        ciEntry2.Period__c = fuel.periodList.get(0).Id;
        ciEntry2.Transaction_Type__c = 'Supplier Invoice';
        ciEntry2.Source_Document_Object_Name__c = 'Supplier_Invoice__c';
        ciEntry2.Currency__c = TestFuel.currencyCAD.id;
        ciEntry2.Supplier_Invoice__c = suppInv2.Id;
        ciEntry2.Status__c = 'Active';
        accEntries.add(ciEntry2);

        Accounting_Entry__c ciEntry3 = new Accounting_Entry__c();
		ciEntry3.company__c = fuel.company.id; 
        ciEntry3.Transaction_Date__c = p.Period_End__c.addDays(-3);
        ciEntry3.Finalized_Date__c = p.Period_End__c.addDays(-3);
        //acctEntry.GL_Date__c = system.today();
        ciEntry3.Period__c = fuel.periodList.get(0).Id;
        ciEntry3.Transaction_Type__c = 'Supplier Invoice';
        ciEntry3.Source_Document_Object_Name__c = 'Supplier_Invoice__c';
        ciEntry3.Currency__c = TestFuel.currencyCAD.id;
        ciEntry3.Supplier_Invoice__c = suppInv3.Id;
        ciEntry3.Status__c = 'Active';
        accEntries.add(ciEntry3);

        Accounting_Entry__c ciEntry4 = new Accounting_Entry__c();
		ciEntry4.company__c = fuel.company.id; 
        ciEntry4.Transaction_Date__c = p.Period_End__c.addDays(-3);
        ciEntry4.Finalized_Date__c = p.Period_End__c.addDays(-3);
        //acctEntry.GL_Date__c = system.today();
        ciEntry4.Period__c = fuel.periodList.get(0).Id;
        ciEntry4.Transaction_Type__c = 'Journal Entry';
        ciEntry4.Source_Document_Object_Name__c = 'Journal_Entry__c';
        ciEntry4.Currency__c = TestFuel.currencyCAD.id;
        ciEntry4.Journal_Entry__c = je1.Id;
        ciEntry4.Status__c = 'Active';
        accEntries.add(ciEntry4);

        insert accEntries;

        Accounting_Entry_Line__c ciLineDr1 = new Accounting_Entry_Line__c();
        ciLineDr1.COMP_Functional_Currency__c = 'USD';
        ciLineDr1.COMP_Transaction_Currency__c = 'CAD';
        ciLineDr1.Amount_CR__c = 125;
        ciLineDr1.GL_Account__c = nonMonGl;
        ciLineDr1.Transaction_Date__c = system.today();
        ciLineDr1.Accounting_Entry__c = ciEntry1.id;
        ciLineDr1.Supplier_Invoice_Line__c = suppInvLine1.Id;

        accEntryLines.add(ciLineDr1);

        Accounting_Entry_Line__c ciLineDr = new Accounting_Entry_Line__c();
        ciLineDr.COMP_Functional_Currency__c = 'USD';
        ciLineDr.COMP_Transaction_Currency__c = 'CAD';
        ciLineDr.Amount_DR__c = 125;
        ciLineDr.GL_Account__c = nonMonGl;
        ciLineDr.Transaction_Date__c = system.today();
        ciLineDr.Accounting_Entry__c = ciEntry.id;
        ciLineDr.Customer_Invoice_Line__c = custInvLine1.Id;
        accEntryLines.add(ciLineDr);

        Accounting_Entry_Line__c ciLineDr2 = new Accounting_Entry_Line__c();
        ciLineDr2.COMP_Functional_Currency__c = 'USD';
        ciLineDr2.COMP_Transaction_Currency__c = 'CAD';
        ciLineDr2.Amount_DR__c = 125;
        ciLineDr2.GL_Account__c = nonMonGl;
        ciLineDr2.Transaction_Date__c = system.today();
        ciLineDr2.Accounting_Entry__c = ciEntry2.id;
        ciLineDr2.Supplier_Invoice_Line__c = suppInvLine2.Id;
        accEntryLines.add(ciLineDr2);

        Accounting_Entry_Line__c ciLineDr3 = new Accounting_Entry_Line__c();
        ciLineDr3.COMP_Functional_Currency__c = 'USD';
        ciLineDr3.COMP_Transaction_Currency__c = 'CAD';
        ciLineDr3.Amount_CR__c = 125;
        ciLineDr3.GL_Account__c = nonMonGl;
        ciLineDr3.Transaction_Date__c = system.today();
        ciLineDr3.Supplier_Invoice_Line__c = suppInvLine3.Id;
        ciLineDr3.Accounting_Entry__c = ciEntry3.id;
        accEntryLines.add(ciLineDr3);

        Accounting_Entry_Line__c ciLineDr4 = new Accounting_Entry_Line__c();
        ciLineDr4.COMP_Functional_Currency__c = 'USD';
        ciLineDr4.COMP_Transaction_Currency__c = 'CAD';
        ciLineDr4.Amount_CR__c = 125;
        ciLineDr4.GL_Account__c = nonMonGl;
        ciLineDr4.Transaction_Date__c = system.today();
        ciLineDr4.Journal_Entry_Line__c = jeLine1.Id;
        ciLineDr4.Accounting_Entry__c = ciEntry4.id;
        accEntryLines.add(ciLineDr4);

        Accounting_Entry_Line__c ciLineDr5 = new Accounting_Entry_Line__c();
        ciLineDr5.COMP_Functional_Currency__c = 'USD';
        ciLineDr5.COMP_Transaction_Currency__c = 'CAD';
        ciLineDr5.Amount_CR__c = 125;
        ciLineDr5.GL_Account__c = plMon.Id;
        ciLineDr5.Transaction_Date__c = system.today();
        ciLineDr5.Journal_Entry_Line__c = jeLine2.Id;
        ciLineDr5.Accounting_Entry__c = ciEntry4.id;
        accEntryLines.add(ciLineDr5);

        insert accEntryLines;
	}

	private static void setupTestData(){
		

		List<Period__c> periods = fuel.periodList;

		List<GL_Account__c> fAcc = fuel.GLAccountTestData;

		boolean hasMonetary = false;
		boolean hasufx = false;
		boolean hasrfx = false;

		for(GL_Account__c gl : fAcc){
			if(gl.FX_Type__c == 'P/L Monetary'){
				hasMonetary = true;
			}else if(gl.FX_Type__c == 'UFX'){
				hasufx = true;
			}else if(gl.FX_Type__c == 'RFX'){
				hasrfx = true;
			}
		}

		List<GL_Account__c> updates = new List<GL_Account__c>();
		if(hasMonetary == false){
			GL_Account__c gl = fAcc.get(0);
			gl.FX_Type__c = 'P/L Monetary';
			gl.Normal_Balance__c = 'Credit';
			updates.add(gl);
		}

		if(hasufx == false){
			GL_Account__c gl = fAcc.get(1);
			gl.FX_Type__c = 'UFX';
			updates.add(gl);
		}

		if(hasrfx = false){
			GL_Account__c gl = fAcc.get(2);
			gl.FX_Type__c = 'RFX';
			updates.add(gl);
		}

		if(updates.size() > 0){
			update updates;
		}


		List<Exchange_Rate__c>rates = new List<Exchange_Rate__c>();

		for(Period__c p : periods){

			Exchange_Rate__c exStart = new Exchange_Rate__c();
			exStart.Active__c = true;
            exStart.Currency_From__c = 'CAD';
            exStart.Currency_To__c = 'USD';
            exStart.To_Currency__c = TestFuel.currencyUSD.id;
            exStart.From_Currency__c = TestFuel.currencyCAD.id;
            exStart.Daily_Monthly__c = 'Daily';
            exStart.Multiplier_Exchange_Rate__c = 1.140000;
            exStart.rate_start_datetime__c = p.Period_Start__c;
            exStart.rate_end_datetime__c = p.Period_Start__c + 2;

            Exchange_Rate__c exStop = new Exchange_Rate__c();
            exStop.Active__c = true;
            exStop.Currency_From__c = 'CAD';
            exStop.Currency_To__c = 'USD';
            exStart.To_Currency__c = TestFuel.currencyUSD.id;
            exStart.From_Currency__c = TestFuel.currencyCAD.id;            
            exStop.Daily_Monthly__c = 'Daily';
            exStop.Multiplier_Exchange_Rate__c = 1.240000;
            exStop.rate_start_datetime__c = p.Period_End__c-2;
            exStop.rate_end_datetime__c = p.Period_End__c;

            rates.add(exStart);
            rates.add(exStop);
		}

		insert rates;


	}
	
}