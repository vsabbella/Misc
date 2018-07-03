@isTest
private class InvoiceManageExtTest {
	
	@testSetup static void ts() { 
		TestFuel data = new TestFuel();	
		// these asserts cause TestFuelQuery to insert data
		system.assert(		
			data.company != null &&
			data.altCompany != null &&
			data.UnappliedCashGL != null &&
			data.intercompanyInvestmentInvoice != null
		);
	}
	private static TestFuelQuery fuel;

	@isTest 
	static void testExtentionLoadNew() {
		fuel = new TestFuelQuery();
        Invoice_Line__c invLine = new Invoice_Line__c(Extended_Amount__c=100);
        loadNew('Intercompany Investment', invLine);
        
	}

	private static void loadNew(String type, Invoice_Line__c invLine){
        Schema.DescribeSObjectResult dsr = Invoice__c.SObjectType.getDescribe();
        String invoiceListViewURL = new PageReference('/' + dsr.getKeyPrefix()).getUrl();
        Company__c company = fuel.company;
        Company__c altCompany = fuel.altCompany;

		Invoice__c inv = new Invoice__c();

		Test.startTest();

        InvoiceManageExt ext = new InvoiceManageExt(new Apexpages.Standardcontroller(inv));

        String s = ext.InvoiceHeaderFieldList;
        s = ext.InvoiceJson;
        s = ext.InvoiceHeaderAddlFieldList;
        s = ext.InvoiceLineFieldList;
        s = ext.InvoiceLinesConfigJson;
        s = ext.exceptionsConfigJson;
        s = ext.NamespaceUU;
        s = (ext.displayExceptions==true?'yes' : 'no');
        s = (ext.invalidType==true?'yes' : 'no');
        s = ext.ReturnUrl;
        system.assertEquals(s,invoiceListViewURL, s);//KNDY-16033
        
        ext.getExceptionsFieldList();

        System.assertEquals(null, inv.Id);

        inv.Type__c = type;
        ext.onInvoiceTypeChange();
        ext = new InvoiceManageExt(new Apexpages.Standardcontroller(inv));
        s = ext.ReturnUrl;
        system.assertEquals(s, invoiceListViewURL, s);//KNDY-16033


        System.debug('#### Header field');
        System.debug(ext.InvoiceHeaderFieldList);

		s = ext.InvoiceHeaderFieldList;
        s = ext.InvoiceJson;
        s = ext.InvoiceHeaderAddlFieldList;
        s = ext.InvoiceLineFieldList;
        s = ext.InvoiceLinesConfigJson;
        s = ext.exceptionsConfigJson;



        inv.To_Company__c = company.Id;
        inv.From_Company__c = altCompany.Id;
        
        inv.Currency__c = company.Default_Transaction_Currency__c;
        inv.Transaction_Date__c = System.now();


        List<InvoiceManageExt.InvoiceLineWrapper> newLines = new List<InvoiceManageExt.InvoiceLineWrapper>{
        		new InvoiceManageExt.InvoiceLineWrapper(invLine)
        };

        JsonResult jr = InvoiceManageExt.saveAction(inv, new List<String>(), new List<InvoiceManageExt.InvoiceLineWrapper>(), newLines, new List<InvoiceManageExt.InvoiceLineWrapper>(), new List<String>());
        System.assertNotEquals(null, inv.Id, jr);
        System.assertEquals(invLine.Invoice__c, inv.Id);

        invLine.Extended_Amount__c = 200;
        jr = InvoiceManageExt.saveAction(inv, new List<String>(), newLines, new List<InvoiceManageExt.InvoiceLineWrapper>(), new List<InvoiceManageExt.InvoiceLineWrapper>(), new List<String>());

        Invoice_Line__c ilcheck = [Select Id, Extended_Amount__c From Invoice_Line__c Where Id=:invLine.Id];
        SYstem.assertEquals(200, ilcheck.Extended_Amount__c);


        jr = InvoiceManageExt.saveAction(inv, new List<String>(), new List<InvoiceManageExt.InvoiceLineWrapper>(), new List<InvoiceManageExt.InvoiceLineWrapper>(), newLines, new List<String>());

        List<Invoice_Line__c>remainingLines = [Select Id From Invoice_Line__c Where Invoice__c =:inv.Id];
        System.assertEquals(0, remainingLines.size());

        s = ext.ReturnUrl;


        Test.stopTest();
	}

	@isTest 
	static void testExtentionLoadExisting() {

		fuel = new TestFuelQuery();
        Company__c company = fuel.company;
        Company__c altCompany = fuel.altCompany;
        Invoice__c inv = fuel.intercompanyInvestmentInvoice;

        Test.startTest();

        InvoiceManageExt ext = new InvoiceManageExt(new Apexpages.Standardcontroller(inv));

        String s = ext.InvoiceHeaderFieldList;
        s = ext.InvoiceJson;
        s = ext.InvoiceHeaderAddlFieldList;
        s = ext.InvoiceLineFieldList;
        s = ext.InvoiceLinesConfigJson;
        s = ext.exceptionsConfigJson;
        s = ext.NamespaceUU;
        s = (ext.displayExceptions==true?'yes' : 'no');
        s = (ext.invalidType==true?'yes' : 'no');
        s = ext.ReturnUrl;
        ext.getExceptionsFieldList();

        InvoiceManageExt.getInvoiceDetails(inv.Id, inv.Type__c);

        GridRelatedListController.GridRelatedListConfig config = new GridRelatedListController.GridRelatedListConfig();
        config.uniqueId = 'InvoiceLinesGrid';
        config.title = inv.Type__c + ' Lines';
        config.parentRecord = inv;
        config.objectName = 'Invoice_Line__c';  
        config.parentField = 'Invoice__c';
        config.fieldset = inv.Type__c.replace(' ', '_');
        config.additionalFields = String.join(new List<String>{'id', 'Has_Exceptions__c'}, ',');  

        InvoiceManageExt.getInvoiceLines(config);

        inv.Finalized__c = true;
        JsonResult jr = InvoiceManageExt.saveAction(inv, new List<String>(), new List<InvoiceManageExt.InvoiceLineWrapper>(), new List<InvoiceManageExt.InvoiceLineWrapper>(), new List<InvoiceManageExt.InvoiceLineWrapper>(), new List<String>());

        InvoiceManageExt.getInvoiceDetails(inv.Id, inv.Type__c);
		InvoiceManageExt.getInvoiceLines(config);

        Test.stopTest();

	}

	@isTest 
	static void testIntercoCrossCharge() {
		fuel = new TestFuelQuery();
		Accounting_Default__c ad = new Accounting_Default__c();
		ad.Company__c = fuel.altCompany.Id;
		ad.Intercompany__c = fuel.company.Id;
		ad.GL_Account__c = fuel.UnappliedCashGL.Id;

		DML.insertAsSystem(ad);

		Invoice_Line__c invLine = new Invoice_Line__c(Extended_Amount__c=100, Accounting_Default__c=ad.Id, Accounting_Default__r=ad);
        loadNew('Intercompany Cross Charge', invLine);
	}

	@isTest
	static void testIntercoCrossChargeValidations(){

		fuel = new TestFuelQuery();
		Company__c company = fuel.company;
        Company__c altCompany = fuel.altCompany;

		Invoice__c inv = new Invoice__c();
		inv.Type__c = 'Intercompany Cross Charge';
		inv.To_Company__c = company.Id;
        inv.From_Company__c = altCompany.Id;
        
        inv.Currency__c = company.Default_Transaction_Currency__c;
        inv.Transaction_Date__c = System.now();

		Invoice_Line__c invLine = new Invoice_Line__c(Extended_Amount__c=100);

		Boolean result = InvoiceService.validateAndUpsert(new List<Invoice__c>{inv}, new List<Invoice_Line__c>{invLine}, new JsonResult(), true);
		System.assertEquals(false, result);

		Accounting_Default__c ad = new Accounting_Default__c();
		invLine.Accounting_Default__r = ad;
		result = InvoiceService.validateAndUpsert(new List<Invoice__c>{inv}, new List<Invoice_Line__c>{invLine}, new JsonResult(), true);
		System.assertEquals(false, result);

		ad.Company__c = inv.From_Company__c;
		ad.Intercompany__c = inv.To_Company__c;
		result = InvoiceService.validateAndUpsert(new List<Invoice__c>{inv}, new List<Invoice_Line__c>{invLine}, new JsonResult(), true);
		System.assertEquals(false, result);


	}
	//KNDY-10984
	@isTest 
	static void testFromCoToCoValidationOnSave() {

		fuel = new TestFuelQuery();
        Company__c company = fuel.company;
        Company__c altCompany = fuel.altCompany;
        Invoice__c inv = fuel.intercompanyInvestmentInvoice;

        Test.startTest();

        InvoiceManageExt ext = new InvoiceManageExt(new Apexpages.Standardcontroller(inv));

        String s = ext.InvoiceHeaderFieldList;
        s = ext.InvoiceJson;
        s = ext.InvoiceHeaderAddlFieldList;
        s = ext.InvoiceLineFieldList;
        s = ext.InvoiceLinesConfigJson;
        s = ext.exceptionsConfigJson;
        s = ext.NamespaceUU;
        s = (ext.displayExceptions==true?'yes' : 'no');
        s = (ext.invalidType==true?'yes' : 'no');
        s = ext.ReturnUrl;
        ext.getExceptionsFieldList();

        InvoiceManageExt.getInvoiceDetails(inv.Id, inv.Type__c);

        GridRelatedListController.GridRelatedListConfig config = new GridRelatedListController.GridRelatedListConfig();
        config.uniqueId = 'InvoiceLinesGrid';
        config.title = inv.Type__c + ' Lines';
        config.parentRecord = inv;
        config.objectName = 'Invoice_Line__c';  
        config.parentField = 'Invoice__c';
        config.fieldset = inv.Type__c.replace(' ', '_');
        config.additionalFields = String.join(new List<String>{'id', 'Has_Exceptions__c'}, ',');  

        InvoiceManageExt.getInvoiceLines(config);

        inv.Finalized__c = true;
        inv.To_Company__c = company.Id;
        inv.From_Company__c = company.Id;
        JsonResult jr = InvoiceManageExt.saveAction(inv, new List<String>(), new List<InvoiceManageExt.InvoiceLineWrapper>(), new List<InvoiceManageExt.InvoiceLineWrapper>(), new List<InvoiceManageExt.InvoiceLineWrapper>(), new List<String>());
		system.assertEquals(jr.success,false);
		
		Invoice__c interCoPayInv = new Invoice__c();
		interCoPayInv.Type__c = 'Intercompany Cross Charge';
		interCoPayInv.To_Company__c = company.Id;
        interCoPayInv.From_Company__c = company.Id;
        
        interCoPayInv.Currency__c = company.Default_Transaction_Currency__c;
        interCoPayInv.Transaction_Date__c = System.now();

		Invoice_Line__c invLine1 = new Invoice_Line__c(Extended_Amount__c=100);
		List<InvoiceManageExt.InvoiceLineWrapper> newLines = new List<InvoiceManageExt.InvoiceLineWrapper>{
        		new InvoiceManageExt.InvoiceLineWrapper(invLine1)
        };
        jr = InvoiceManageExt.saveAction(interCoPayInv, new List<String>(), new List<InvoiceManageExt.InvoiceLineWrapper>(), newLines, new List<InvoiceManageExt.InvoiceLineWrapper>(), new List<String>());
        
		system.assertEquals(jr.success,false);
        

        Test.stopTest();

	}


	
}