@isTest
private class PaymentLinesManageExtTest {
	
	static testMethod void testExtensionLoadNew() {
    	
        TestFuel fuel = new TestFuel();
        Company__c company = fuel.company;
        Company__c altCompany = fuel.altCompany;
        List<Period__c> periodList = fuel.periodList;
        List<Period__c> altCompanyPeriodList = fuel.altCompanyPeriodList;
        Invoice__c inv = fuel.intercompanyInvestmentInvoice;
        
        inv.Finalized__c = true;
        update inv;
        
        Payment__c pmt = new Payment__c();
        
        test.startTest();
        
        PaymentLinesManageExt ext = new PaymentLinesManageExt(new Apexpages.Standardcontroller(pmt));
        ext.getPaymentHeaderAdditionalFieldList();
        ext.getPaymentHeaderManageFieldList();
        ext.getPaymentLineFieldList();
        ext.getInvoiceFieldList();
        ext.getPaymentMatchFieldList();
        ext.getExceptionFieldList();
        List<Integer> inds = ext.selected_indexes;
        ext.getInvoiceOptionsConfigJson();
        ext.getPaymentLinesConfigJson();
        
        system.assertEquals(null, pmt.Id);
        
        JSONResult pmtDetailResult = PaymentLinesManageExt.getPaymentDetails(pmt.Id);
        system.assertEquals(0, pmtDetailResult.records.size());
        
        pmt.From_Company__c = company.Id;
		pmt.To_Company__c = altCompany.Id;
		pmt.Currency__c = TestFuel.currencyUSD.id;
		pmt.Transaction_Date__c = system.now();
		pmt.Type__c = 'Intercompany Payment';
		pmt.Transaction_Type__c = 'Intercompany Payment';
        
        JSONResult pmtSaveResult = PaymentLinesManageExt.savePaymentDetails(JSON.serialize(pmt));
        system.assertEquals(1, pmtSaveResult.total, pmtSaveResult);
        pmt = (Payment__c)pmtSaveResult.records[0];
        
        ext = new PaymentLinesManageExt(new Apexpages.Standardcontroller(pmt));
        ext.invoiceOptionsConfig.parentRecord = pmt;
        
        JsonResult invoiceOptions = PaymentLinesManageExt.getInvoiceOptions(ext.invoiceOptionsConfig);
        system.assertEquals(1, invoiceOptions.total, invoiceOptions);
        
        JSONResult addInvoicesResult = PaymentLinesManageExt.addInvoicesToPayment(pmt.Id, new list<string>{inv.Id});
        system.assertEquals(1, addInvoicesResult.total, addInvoicesResult);
		
		inv = [SELECT Id, Name, Balance__c FROM Invoice__c WHERE Id = :inv.Id];
        pmt = [SELECT Id, payment_amount__c, (SELECT Id FROM Payment_Lines__r) FROM Payment__c WHERE Id = :pmt.Id];
        system.assertEquals(inv.Balance__c, pmt.payment_amount__c);
        system.assertNotEquals(0, pmt.Payment_Lines__r.size());
        
        pmt.finalized__c = true;
        pmtSaveResult = PaymentLinesManageExt.savePaymentDetails(JSON.serialize(pmt));
        system.assertEquals(1, pmtSaveResult.total, pmtSaveResult);
        pmt = (Payment__c)pmtSaveResult.records[0];
        system.assert(pmt.Finalized__c);
        
        
        test.stopTest();
        
        
    }
	
    static testMethod void testExtensionLoadExisting() {
    	
        TestFuel fuel = new TestFuel();
        Company__c company = fuel.company;
        Company__c altCompany = fuel.altCompany;
        List<Period__c> periodList = fuel.periodList;
        List<Period__c> altCompanyPeriodList = fuel.altCompanyPeriodList;
        
        Payment__c pmt = fuel.intercompanyPayment;
        
        test.startTest();
        
        PaymentLinesManageExt ext = new PaymentLinesManageExt(new Apexpages.Standardcontroller(pmt));
        ext.getPaymentHeaderAdditionalFieldList();
        ext.getPaymentHeaderManageFieldList();
        ext.getPaymentLineFieldList();
        ext.getInvoiceFieldList();
        ext.getPaymentMatchFieldList();
        ext.getExceptionFieldList();
        List<Integer> inds = ext.selected_indexes;
        GridRelatedListController.GridRelatedListConfig invOptsConfig = (GridRelatedListController.GridRelatedListConfig)JSON.deserialize(ext.getInvoiceOptionsConfigJson(), GridRelatedListController.GridRelatedListConfig.class);
        GridRelatedListController.GridRelatedListConfig pmtLinesConfig = (GridRelatedListController.GridRelatedListConfig)JSON.deserialize(ext.getPaymentLinesConfigJson(), GridRelatedListController.GridRelatedListConfig.class);
        
		JSONResult pmtDetailResult = PaymentLinesManageExt.getPaymentDetails(pmt.Id);
        system.assertEquals(1, pmtDetailResult.records.size());
        Payment__c refPmt = (Payment__c)pmtDetailResult.records[0];
        system.assertEquals(pmt.Id, refPmt.Id);
        
        JSONResult pmtSaveResult = PaymentLinesManageExt.savePaymentDetails(JSON.serialize(pmt));
        system.assertEquals(1, pmtSaveResult.total, pmtSaveResult);
        refPmt = (Payment__c)pmtSaveResult.records[0];
        system.assertEquals(pmt.Id, refPmt.Id);
        
        DataSourceResult pmtLinesSaveResult = PaymentLinesManageExt.savePaymentLines(new list<sObject>{pmt}, new list<sObject>(), new list<sObject>(), new list<string>());
        system.assertEquals(1, pmtLinesSaveResult.total, pmtLinesSaveResult);
        
        JSONResult pmtLines = PaymentLinesManageExt.getPaymentLines(pmtLinesConfig);
        
        JSONResult invOpts = PaymentLinesManageExt.getInvoiceOptions(invOptsConfig);
        
        test.stopTest();
        
        
    }
}