@isTest
private class PaymentBatchExtTest {
    
    static String NamespaceUU = KSE.NamespaceUU;
    
    @testSetup static void ts() { 
        TestFuel data = new TestFuel(); 
        // these asserts cause TestFuelQuery to insert data
        system.assert(      
            data.company != null &&
            data.remittosupplier != null &&
            data.purchaseOrder != null &&
            data.purchaseOrder2 != null &&
            data.periodList != null &&
            data.itemList != null &&
            data.bankAccount != null && 
            TestFuel.currencyGBP != null &&
            TestFuel.currencyUSD != null
            
        );
    }
	class PaymentBatchExtTestData {
    	private SchemaUtil util = SchemaUtil.getInstance();
		TestFuelQuery fuel = new TestFuelQuery();
	        
		public PaymentBatchExtTestData() {
			
		}
		
		public List<Period__c> periodList = fuel.periodList;
		   
        public Item__c purchasedItem = fuel.itemList[1];    
       	public Company__c company = fuel.company;
       	 
        public Supplier_Invoice__c NonPOInvoicePymtMethod = new Supplier_Invoice__c();
        public Supplier_Invoice__c NonPOInvoice = new Supplier_Invoice__c();
        public Supplier_Invoice__c matchToPOSupplierInvoice = new Supplier_Invoice__c();
        public Supplier_Invoice__c ACHSupplierInvoice = new Supplier_Invoice__c();
        public Supplier_Invoice__c paidPrepayment = new Supplier_Invoice__c();
        public Supplier_Invoice__c toPayPrepayment = new Supplier_Invoice__c();
        
        //Create payment terms info
        public Payment_Term__c paymentTermInfo = new Payment_Term__c();{
        paymentTermInfo.due_days__c = 30;
        paymentTermInfo.discount_days__c = 10;
        paymentTermInfo.Discount_Percent__c = 1.0;
        insert paymentTermInfo;
        }
        
        public Bank_Account__c bankAccount = new Bank_Account__c();{
        bankAccount.Name = 'TESTBNK';
        bankAccount.Company__c = company.Id;
        insert bankAccount;
        }
    	
        public Supplier_Invoice__c createSI(String invType, Decimal invAmount, String siNumber, String paymentMethod, Company__c company, Supplier__c supplier){
           Supplier_Invoice__c suppInv1 = new Supplier_Invoice__c();
           suppInv1.Company__c = company.id;
           suppInv1.Invoice_Type__c = invType;
           suppInv1.Date_Invoiced__c = System.now();
           suppInv1.transaction_date__c = system.now();
           suppInv1.Currency__c = fuel.company.Default_Transaction_Currency__c;
           suppInv1.Supplier__c = supplier.id;
           suppInv1.Invoice_Amount__c = invAmount;
           suppInv1.Supplier_Invoice__c = siNumber;
           suppInv1.Payment_Term__c = paymentTermInfo.id;
           if (paymentMethod != null){
               suppInv1.Payment_Method_G__c = paymentMethod;
           }
           suppInv1.Finalized__c = false;
           suppInv1.Void__c = false;
           suppInv1.historical__c = false;
           return suppInv1;
        }
        
        public  Supplier_Invoice_Line__c createSILine(Decimal invQty, Decimal invUnitPrice, 
                                        Supplier_Invoice__c si, Purchase_Order_Line__c pol, Id itemId){
            Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c();
            suppInvLine1.Supplier_Invoice__c = si.id;
            suppInvLine1.Extended_Cost__c = 50;
            suppInvLine1.Invoice_Quantity__c = invQty;
            suppInvLine1.Unit_Price__c = invUnitPrice;//KNDY-14371
            if (itemId != null){
                suppInvLine1.Item__c = itemId; //data.itemList[0].id;
            }
            if (pol != null){
                suppInvLine1.Purchase_Order__c = fuel.purchaseOrder2.id;
                suppInvLine1.Purchase_Order_Line__c = pol.id;
                //suppInvLine1.Quantity_Received__c = 4;
            } 
            return suppInvLine1;
        }
    
        List<Supplier_Invoice__c> suppInvList = new List<Supplier_Invoice__c>();{
            NonPOInvoicePymtMethod = createSI(PaymentService.TYPE_INVOICE, 1000, 'test101p', 'Online', fuel.company, fuel.remittosupplier); 
            NonPOInvoice = createSI(PaymentService.TYPE_INVOICE, 1000, 'test101a', 'Check', fuel.company, fuel.remittosupplier);
            matchToPOSupplierInvoice = createSI(PaymentService.TYPE_INVOICE, 1000, 'test101', null, fuel.company, fuel.remittosupplier); 
            matchToPOSupplierInvoice.Purchase_Order__c = fuel.purchaseOrder.Id;
            matchToPOSupplierInvoice.Date_Invoiced__c = system.now().addDays(-1);
            matchToPOSupplierInvoice.Payment_Term__c = paymentTermInfo.id;
            
            ACHSupplierInvoice = createSI(PaymentService.TYPE_INVOICE, 1000, 'test101ACH', 'ACH', fuel.company, fuel.remittosupplier); 
            ACHSupplierInvoice.Date_Invoiced__c = system.now().addDays(-1);
            ACHSupplierInvoice.Payment_Term__c = paymentTermInfo.id;
            
            // status will be closed
            paidPrepayment = createSI('Prepayment', 100,'paidPrepayment', null, fuel.company, fuel.remittosupplier); 
            paidPrepayment.Credit_Memo_Amount__c = -100;
            paidPrepayment.Credit_Memo_Balance__c = -100;// available to apply
            
            // status will be approved
            toPayPrepayment = createSI('Prepayment', 100, 'toPayPrepayment', null, fuel.company, fuel.remittosupplier); 
            toPayPrepayment.Credit_Memo_Amount__c = -100;
            toPayPrepayment.Credit_Memo_Balance__c = -10; 
            
            suppInvList.add(NonPOInvoicePymtMethod);
            suppInvList.add(NonPOInvoice);
            suppInvList.add(matchToPOSupplierInvoice);
            suppInvList.add(ACHSupplierInvoice);
            suppInvList.add(paidPrepayment);
            suppInvList.add(toPayPrepayment);
            
            DML.insertAsUser( suppInvList );
        }
        
        List<Supplier_Invoice_Line__c> suppInvLineList = new List<Supplier_Invoice_Line__c>();{
            // create si line (Decimal invQty, Decimal invUnitPrice, 
            //                            Supplier_Invoice__c si, Purchase_Order_Line__c pol, Id itemId){
            Supplier_Invoice_Line__c suppInvLine1 = createSILine(1, 1000, NonPOInvoicePymtMethod, null, null);
            suppInvLineList.add(suppInvLine1);
            Supplier_Invoice_Line__c suppInvLine2 = createSILine(1, 1000, NonPOInvoice, null, null);
            suppInvLineList.add(suppInvLine2);
            Supplier_Invoice_Line__c suppInvLine3=  createSILine(1, 1000, matchToPOSupplierInvoice, null, purchasedItem.Id);
            suppInvLineList.add(suppInvLine3);
            
            Supplier_Invoice_Line__c suppInvLine4=  createSILine(1, 1000, ACHSupplierInvoice, null, purchasedItem.Id);
            suppInvLineList.add(suppInvLine4);
            // Create 1 prepayment siline for amount 10 
            Supplier_Invoice_Line__c prepaymentSILine = createSILine(100, 1, paidPrepayment, null, null);
            suppInvLineList.add(prepaymentSILine);
            
            // Create 1 siline for amount 100 
            Supplier_Invoice_Line__c appliedPrepaymentSILine = createSILine(100, 1, toPayPrepayment, null, null);
            suppInvLineList.add(appliedPrepaymentSILine);
            
            DML.insertAsUser( suppInvLineList );
            
            // approve and finalize SI
            NonPOInvoicePymtMethod.Status__c = 'Approved';
            NonPOInvoicePymtMethod.Finalized__c = true;
            NonPOInvoicePymtMethod.Transaction_Date__c = system.now();
            NonPOInvoice.Status__c = 'Approved';
            NonPOInvoice.Finalized__c = true;
            NonPOInvoice.Transaction_Date__c = system.now();
            matchToPOSupplierInvoice.Status__c = 'Approved';
            matchToPOSupplierInvoice.Finalized__c = true;
            matchToPOSupplierInvoice.Transaction_Date__c = system.now();
            
            ACHSupplierInvoice.Status__c = 'Approved';
            ACHSupplierInvoice.Finalized__c = true;
            ACHSupplierInvoice.Transaction_Date__c = system.now();
            
            paidPrepayment.Status__c = 'Approved';
            paidPrepayment.Finalized__c = true;
            paidPrepayment.Transaction_Date__c = system.now();

            toPayPrepayment.Status__c = 'Approved';
            toPayPrepayment.Transaction_Date__c = system.now();
            toPayPrepayment.Finalized__c = true;
            
            DML.allowUpdateFields( new list<string>{'Finalized__c', 'Status__c'}, Supplier_Invoice__c.SObjectType );
            DML.sobjectUpdate( suppInvList );
            
            paidPrepayment.Status__c = 'Closed';
            update paidPrepayment;
        }

        public GridRelatedListController.GridRelatedListConfig supplierInvoicePreviewConfig = new GridRelatedListController.GridRelatedListConfig(); {
	        supplierInvoicePreviewConfig.uniqueId = 'SupplierInvoicesPreviewGrid';
	        supplierInvoicePreviewConfig.title = 'Supplier Invoices';
	        supplierInvoicePreviewConfig.objectName = 'Supplier_Invoice__c';
        	supplierInvoicePreviewConfig.fieldset = 'Payment_Batch_Preview_List';	        
	        supplierInvoicePreviewConfig.buttons = 'columnmenu, search';
	        supplierInvoicePreviewConfig.alwaysUseFullDateTimeFormat = false;
	        supplierInvoicePreviewConfig.additionalFields ='Supplier__r.Name,Supplier__r.Id, Currency__c, Company__c, Status__c ,Supplier__r.Parent_Supplier__c,Supplier__r.Top_Parent_Supplier__c' +
        											',Supplier__r.Parent_Hold_Payment__c,Supplier__r.Top_Parent_Hold_Payment__c,Discount_Override_Date__c,Payment_term__r.Discount_Days__c' +
        											' ,Always_Take_Discount__c,Early_Payment_Rate__c,Invoice_Amount__c,Amount_Paid__c,Discount_Taken__c'+
        											//add  mandatory fields in case not included in the fieldset or removed 
        											//KNDY-16758 - add invoice type in additional field set so it won't break even if fieldset doesn't contain field
        											',Date_Invoiced__c,invoice_type__c,Balance_Due__c,Credit_Memo_Balance__c,Credit_Memo_Applied__c,Supplier__c';//,Discount_to_Take__c' KNDY-18011 - DEPRECATED ;
    	
	        supplierInvoicePreviewConfig.sortField ='Balance_Due__c';
	        supplierInvoicePreviewConfig.sortOrder ='DESC';
	    }
	    public GridRelatedListController.GridRelatedListConfig supplierPaymentMasterPreviewConfig = new GridRelatedListController.GridRelatedListConfig();{
	    	//KNDY-17712 - grid config for preview payment master grid
	    	//Supplier payment master Preview Grid config
	        supplierPaymentMasterPreviewConfig = new GridRelatedListController.GridRelatedListConfig();
	        supplierPaymentMasterPreviewConfig.uniqueId = 'supplierPaymentMasterPreviewConfig';
	        supplierPaymentMasterPreviewConfig.title = 'Supplier Payment';
	        supplierPaymentMasterPreviewConfig.objectName = 'Supplier_Payment__c';
	        supplierPaymentMasterPreviewConfig.buttons = 'columnmenu, search';
	        supplierPaymentMasterPreviewConfig.fieldset = 'Payment_Preview';
			supplierPaymentMasterPreviewConfig.pageSize = 10;
	        supplierPaymentMasterPreviewConfig.alwaysUseFullDateTimeFormat = false;
	        //KNDY-17923 - deperecated 'payment_number__c' 	
	        supplierPaymentMasterPreviewConfig.additionalFields ='Reference__c,Payment_Amount__c, Currency__c, Payment_Method_G__c, Date_Paid__c ,Supplier__c,Name,Status__c,Status_Reason__c,Bank_Account__c,Total_Number_of_Lines__c,Source_Key__c,Batch_Job_ID__c ';
	    }
	    public GridRelatedListController.GridRelatedListConfig supplierPaymentChildPreviewConfig = new GridRelatedListController.GridRelatedListConfig();{
	    	//KNDY-17712 - grid config for preview payment master grid
	    	//Supplier payment child Preview Grid config
	        supplierPaymentChildPreviewConfig = new GridRelatedListController.GridRelatedListConfig();
	        supplierPaymentChildPreviewConfig.uniqueId = 'supplierPaymentChildPreviewConfig';
	        supplierPaymentChildPreviewConfig.title = 'Supplier Payment Line';
	        supplierPaymentChildPreviewConfig.objectName = 'Supplier_Payment_Line__c';
	        supplierPaymentChildPreviewConfig.fieldset = 'Payment_Lines_Preview';
	        supplierPaymentChildPreviewConfig.alwaysUseFullDateTimeFormat = false;
	    }
        public List<KendoUtils.FilterDescriptor> filters = new List<KendoUtils.FilterDescriptor>();{
	        KendoUtils.FilterDescriptor filter = new KendoUtils.FilterDescriptor();
	        filter.field = 'Supplier__c';
            filter.fieldType = null;
            filter.operator = 'contains';
            filter.value = JSON.serialize(new List<Id>{ fuel.remittosupplier.id});
	        filters.add(filter);
	        
	        DateTime dtpymtdtd = system.today().addDays(45);
	        DateTime dtnow = system.now();
	        DateTime dtdisdtd = system.today().addDays(-5);
	        
	        KendoUtils.FilterDescriptor filter2 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter3 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter4 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter5 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter6 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter7 = new KendoUtils.FilterDescriptor();
			KendoUtils.FilterDescriptor filter8 = new KendoUtils.FilterDescriptor();
			KendoUtils.FilterDescriptor filter9 = new KendoUtils.FilterDescriptor();
			
	        filter2.field = 'totalCreditsExceedsDebits';
	        filter2.fieldType = 'boolean';
	        filter2.operator = 'eq';
	        filter2.value = false;
	        filters.add(filter2);
	        filter3.field = 'Payment_Method_G__c';
	        filter3.fieldType = 'string';
	        filter3.operator = 'eq';
	        filter3.value = 'Check';
	        filters.add(filter3);
	        filter4.field = 'Payment_Due_Date__c';
	        filter4.fieldType = 'date';
	        filter4.operator = 'lte';
	        filter4.value = dtpymtdtd.format('MM/dd/yyy');
	        filters.add(filter4);
	        filter5.field = 'Discount_Date__c';
	        filter5.fieldType = 'date';
	        filter5.operator = 'lte';
	        filter5.value = dtdisdtd.format('MM/dd/yyy');
	        filters.add(filter5);
	        filter6.field = 'Bank_Account__c';
	        filter6.fieldType = 'string';
	        filter6.operator = 'eq';
	        filter6.value = bankAccount.id;
	        filters.add(filter6);
	        filter7.field = 'PaymentDate';
	        filter7.fieldType = 'date';
	        filter7.operator = 'lte';
	        filter7.value = dtnow.format('MM/dd/yyy hh:mm a');
	        filters.add(filter7);    
	        filter8.field = 'Id';
	        filter8.fieldType = 'string';
	        filter8.operator = 'eq';
	        filter8.value = null;
	        filters.add(filter8);
	        filter9.field = 'Currency__c';
	        filter9.fieldType = 'string';
	        filter9.operator = 'eq';
	        filter9.value = null;
	        filters.add(filter9);
        }
    }
	
	static testMethod void testRemitMethodPicklistValues() {
    	List<SelectListItem> selectList = PaymentBatchExt.getRemitMethodPicklistValues('Supplier__c', 'Payment_Method_G__c');
        system.assertEquals(selectList.get(0).text != null,true);
    }
	
    static testMethod void testDefaultCompany_WithDisbursementBankAccount(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Company__c defaultCompany = testData.company;
        defaultCompany.Disbursement_Bank_Account__c = testData.bankAccount.Id;
        update defaultCompany;
        UserPreference.getInstance().preference.Default_Company__c = defaultCompany.Id;
        UserPreference.getInstance().updateUserPreference();
        
        Supplier_Payment__c sp = new Supplier_Payment__c();
        PaymentBatchExt con = new PaymentBatchExt();
        system.assertEquals(con.defaultCompanyId, defaultCompany.Id, '>>> con.defaultCompanyId: ' + con.defaultCompanyId);
        system.assertNotEquals(con.defaultDisbursementBankAcct, null, '>>> con.defaultDisbursementBankAcct: ' + con.defaultDisbursementBankAcct);
        system.assertEquals(con.defaultDisbursementBankAcct.Id, testData.bankAccount.Id, '>>> con.defaultDisbursementBankAcct: ' + con.defaultDisbursementBankAcct);
        system.assertEquals(con.defaultDisbursementBankAcct.Company__c, testData.company.Id, '>>> con.defaultDisbursementBankAcct: ' + con.defaultDisbursementBankAcct);
        system.assertEquals(con.defaultDisbursementBankAcct.Currency__c, testData.company.Default_Transaction_Currency__c, '>>> con.defaultDisbursementBankAcct: ' + con.defaultDisbursementBankAcct);
    }
    
    static testMethod void testDefaultCompany_WithoutDisbursementBankAccount(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Company__c defaultCompany = testData.company;
        defaultCompany.Disbursement_Bank_Account__c = null;
        update defaultCompany;
        
        UserPreference.getInstance().preference.Default_Company__c = defaultCompany.Id;
        UserPreference.getInstance().updateUserPreference();
        
        Supplier_Payment__c sp = new Supplier_Payment__c();
        PaymentBatchExt con = new PaymentBatchExt();
        system.assertEquals(con.defaultCompanyId, defaultCompany.Id, '>>> con.defaultCompanyId: ' + con.defaultCompanyId);
        system.assertEquals(con.defaultDisbursementBankAcct, null, '>>> con.defaultDisbursementBankAcct: ' + con.defaultDisbursementBankAcct);
    }
    
    static testMethod void testGetSupplierInvoicePreviewConfigJson() {
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	// Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        PaymentBatchExt con = new PaymentBatchExt();
        con.supplierInvoicePreviewConfig = testData.supplierInvoicePreviewConfig;
        
        // Act
        string result = con.getSupplierInvoicePreviewConfigJson();
        
        // Assert
        System.assertEquals(result, JSON.serialize(con.supplierInvoicePreviewConfig));
    }
    //KNDY-17712 immediate mode master grid configurations
    static testMethod void testGetSupplierPaymentMasterPreviewConfigJson() {
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	// Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        PaymentBatchExt con = new PaymentBatchExt();
        con.supplierPaymentMasterPreviewConfig = testData.supplierPaymentMasterPreviewConfig;
    
        // Act
        string result = con.getSupplierPaymentMasterPreviewConfigJson();
        
        // Assert
        System.assertEquals(result, JSON.serialize(con.supplierPaymentMasterPreviewConfig));
    }
    //KNDY-17712 immediate mode child grid configurations
    static testMethod void testGetSupplierPaymentChildPreviewConfigJson() {
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	// Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        PaymentBatchExt con = new PaymentBatchExt();
        con.supplierPaymentChildPreviewConfig = testData.supplierPaymentChildPreviewConfig;
        
        // Act
        string result = con.getSupplierPaymentChildPreviewConfigJson();
        
        // Assert
        System.assertEquals(result, JSON.serialize(con.supplierPaymentChildPreviewConfig));
    }
    static testMethod void testGetBankAccount(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Bank_Account__c ba = testData.fuel.bankAccount;
        Test.startTest();
        JSONResult result = PaymentBatchExt.getBankAccount(ba.Id);
        system.assertEquals (result.success, true, '>>> result: ' + result);
        system.assertEquals (result.total, 1, '>>> result: ' + result);
        Test.stopTest();
    }
    static testMethod void testGetBankAccountFailure(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Bank_Account__c ba = testData.fuel.bankAccount;
        Test.startTest();
        JSONResult result = PaymentBatchExt.getBankAccount('xyz bank');
        system.assertEquals (result.success, false, '>>> result: ' + result);
        system.assert(result.message != null,'Error occurred in batch'+result.message );
        system.assert(result.message == 'Invalid id: xyz bank','Error occurred in batch'+result.message );        	
        Test.stopTest();
    }
    static testMethod void testGetSupplierInvoicesFieldList() {
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	Test.startTest();
    	
        // Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;

        PaymentBatchExt con = new PaymentBatchExt();
        
        // Act
        string result = con.getSupplierInvoicesFieldList();
        
        // Assert
        System.assertNotEquals(result, '');
        
        Test.stopTest();
    }
    //KNDY-17712 immediate mode fieldset configurations
    static testMethod void testGetSupplierPaymentMasterFieldList() {
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	Test.startTest();
    	
        // Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;

        PaymentBatchExt con = new PaymentBatchExt();
        
        // Act
        string result = con.getSupplierPaymentMasterFieldList();
        
        // Assert
        System.assertNotEquals(result, '');
        
        Test.stopTest();
    }
    //KNDY-17712 immediate mode fieldset configurations
    static testMethod void testGetSupplierPaymentChildFieldListt() {
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	Test.startTest();
    	
        // Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;

        PaymentBatchExt con = new PaymentBatchExt();
        
        // Act
        string result = con.getSupplierPaymentChildFieldList();
        
        // Assert
        System.assertNotEquals(result, '');
        
        Test.stopTest();
    }
	// Assumption testData.suppInvList contains SIs valid for payments
    static testMethod void testGetSupplierInvoicesWithoutBank(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Set<Id> invalidSIIds = new Set<Id>();
        Set<Id> validSIIds = new Set<Id>();
        for (KendoUtils.FilterDescriptor fdSet: testData.filters){
        	if (fdSet.field == 'Bank_Account__c')
        		fdSet.value = '';
        }
        
        
        
        // Valid SIs for payment batch
        for (Supplier_Invoice__c siValid: testData.suppInvList){
            validSIIds.add(siValid.Id);
        }
        
        Test.startTest();
        
        // Arrange
        List<Supplier_Invoice__c> siList = [select id, Status__c, Hold__c, Supplier__c, Balance_Due__c, Supplier__r.Hold_Payment__c from Supplier_Invoice__c where Id = :testData.matchToPOSupplierInvoice.id];
        System.assertNotEquals(0, siList.size());
        // Act
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(testData.filters, testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();  
        system.debug(LoggingLevel.Error,'invoiceRecordsFromUI==' + invoiceRecordsFromUI);      
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        SupplierPaymentService spService = new SupplierPaymentService();
        Boolean exceptionThrown = false;
        try{
        spService.processPayments( testData.filters, scopeSupInvIdsToPay,testData.suppInvList, new List<Supplier__c>{testData.fuel.remittosupplier}, null);
        }catch (exception ex){
            exceptionThrown = true;
            system.assert(ex.getMessage().contains(Label.Missing_Bank_Account), 'Exception not thrown: '+ ex.getMessage() + 'Stack:' + ex.getStackTraceString());
        }
		system.assertEquals(exceptionThrown, true,' Bank account found to create payments ');
        Test.stopTest();        
        
    }
    //KNDY-17714 Fetch supplier invoice selected 
    // Assumption testData.suppInvList contains SIs valid for payments
    static testMethod void testGetSupplierInvoicesUsingParam(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
       
        for (KendoUtils.FilterDescriptor fdSet: testData.filters){
        	if (fdSet.field == 'Id')
        		fdSet.value = string.valueOf(testData.matchToPOSupplierInvoice.id);
        }
        Test.startTest();
        List<Supplier_Invoice__c> siList = [select id, Status__c, Hold__c, Supplier__c, Balance_Due__c, Supplier__r.Hold_Payment__c,Payment_MEthod_g__c,Payment_Term__c,Date_Invoiced__c,Payment_Due_Date__c,Currency__c,Company__c from Supplier_Invoice__c where Id = :testData.matchToPOSupplierInvoice.id];
        System.assertEquals(1, siList.size(),'no/multiple invoices found : ' + siList);
        Test.setCurrentPage(new PageReference('Page.PaymentBatch')); 
		ApexPages.currentPage().getParameters().put('supplierInvoiceId', testData.matchToPOSupplierInvoice.id);
		ApexPages.currentPage().getParameters().put('action', 'Immediately');
        PaymentBatchExt paymentBatchCls = new PaymentBatchExt();
        system.assertEquals(paymentBatchCls.supplierInvoiceId ==  siList[0].id,true,'wrong SI Id : ' + paymentBatchCls.supplierInvoiceId);
        system.assertEquals(paymentBatchCls.defaultCompanyId ==  siList[0].Company__c,true,'wrong SI company Id : ' + paymentBatchCls.defaultCompanyId);
        system.assertEquals(paymentBatchCls.defaultSICurrencyId ==  siList[0].Currency__c,true,'wrong SI currency Id: ' + paymentBatchCls.defaultSICurrencyId);
        system.assertEquals(siList[0].Payment_MEthod_g__c == paymentBatchCls.defaultPaymentMethod,true,'wrong SI Payment method Id : ' + paymentBatchCls.defaultPaymentMethod + '='+siList[0].Payment_MEthod_g__c);
        system.assertEquals(paymentBatchCls.defaultPaymentDueDate ==  siList[0].Payment_Due_Date__c,true,'wrong SI Payment due date: ' + paymentBatchCls.defaultPaymentDueDate + 'SI Due date = ' + siList[0].Payment_Due_Date__c);      
        //KNDY-16750 first default payment method
        system.assertEquals(paymentBatchCls.defaultStandardPaymentMethod != null,true,'can not find active payment methods : ' + paymentBatchCls.defaultStandardPaymentMethod);
        system.assertEquals(paymentBatchCls.defaultStandardPaymentMethod == paymentBatchCls.defaultPaymentMethod,true,'wrong SI Payment method Id : ' + paymentBatchCls.defaultStandardPaymentMethod + '='+siList[0].Payment_MEthod_g__c);
        // Act
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(testData.filters, testData.supplierInvoicePreviewConfig);
        System.assertEquals(invoiceRecordsFromUI.size() == 1,true,'no invoices found : ' + invoiceRecordsFromUI.size());
        //send correct SI with payment method
         for (KendoUtils.FilterDescriptor fdSet: testData.filters){
        	if (fdSet.field == 'Id')
        		fdSet.value = string.valueOf(testData.NonPOInvoice.id);
        }
        invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(testData.filters, testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();  
        system.debug(LoggingLevel.Error,'invoiceRecordsFromUI==' + invoiceRecordsFromUI);      
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	//if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        System.assertEquals(scopeSupInvIdsToPay.size() == 1,true,'no invoices found : ' + scopeSupInvIdsToPay.size());
        SupplierPaymentService spService = new SupplierPaymentService();
        
    	List<Supplier__c> supplierList = [select id,Pay_Per_Invoice__c from supplier__c where Id =:testData.fuel.remittosupplier.Id];
   		List<SupplierPaymentService.invoicePaymentWrapper>  payWrapper = spService.processPayments( testData.filters, scopeSupInvIdsToPay,new List<Supplier_Invoice__c>{testData.NonPOInvoice}, supplierList, null);
        system.debug(LoggingLevel.Error,'test method paywrapper : '+payWrapper[0].paymentWrapperList);
        System.assertEquals(payWrapper[0].paymentWrapperList.size() == 1,true,'no invoices found : ' + payWrapper[0].paymentWrapperList);
		List<Supplier_Payment__c> sps = new List<Supplier_Payment__c>();
		List<Supplier_Payment_Line__c>  splines = new List<Supplier_Payment_Line__c>();
		for (SupplierPaymentService.paymentWithLinesWrapper paylineWrapper :payWrapper[0].paymentWrapperList){
			sps.add(paylineWrapper.supplierPayment);
			splines.addAll(paylineWrapper.lstPaymentLines);
		}
		system.debug(LoggingLevel.Error,'test method sps : '+sps );
		system.debug(LoggingLevel.Error,'test method splines : '+splines );
		System.assertEquals(sps.size() == 1,true,'no invoices found : ' + sps.size());
		System.assertEquals(splines.size() == 2,true,'no invoices found : ' + splines.size());
		List<SupplierPaymentService.paymentWithLinesWrapper> paymentWrapperList = spService.CreateFinalizePaymentsForImmediate(false,testData.supplierPaymentMasterPreviewConfig,sps,splines); 
        //KNDY-19040 - Update invoices 
        PaymentBatchExt.updateSupplierInoiceForFinalizedPayments(new List<String>{testData.NonPOInvoice.id},null);
        siList = [select id, name, Discount_Date__c, Status__c,Credit_Memo_Balance__c,Invoice_Type__c,Credit_Memo_Amount__c,Amount_Paid__c,Balance_Due__c from Supplier_Invoice__c where id =:testData.NonPOInvoice.id]; 
        
        system.assert(siList[0].Status__c == 'Closed', 'Supplier invoice is not closed: ' + siList[0]);
        
        Set<Id> spIds = new Set<Id>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where supplier_invoice__c = :testData.NonPOInvoice.id];
        system.assert(splines.size() == 2, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
            if (spLine.type__c == 'Payment')
            	system.assert(spLine.Amount__c == 990, 'Supplier Payment line amount is not correct: ' + spLine.Amount__c);
            if (spLine.type__c == PaymentService.TYPE_EARNED_DISCOUNT)
            	system.assert(spLine.Amount__c == 10, 'Supplier Payment line amount is not correct: ' + spLine.Amount__c);
        }
      
        
        system.assertEquals(spIds.size(), 1, 'Incorrent number of SPs created: spIds - ' + spIds);
        sps = [select id, status__c, Transaction_Date__c, Payment_Amount__c from Supplier_Payment__c where id in:spIds];
        system.assertEquals(sps.size(), 1, 'Incorrent number of SPs created: spIds - ' + sps);
        for (Supplier_Payment__c sp: sps){
            system.assert(sp.status__c == 'Applied', 'Supplier Payment status is not correct: ' + sp.status__c);            
            system.assert(sp.Transaction_Date__c != null); //KNDY-10280 KNDY-12343
        }
		
        Test.stopTest();        
        
    }
    // Assumption testData.suppInvList contains SIs valid for payments
    static testMethod void testGetSupplierInvoices(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Set<Id> invalidSIIds = new Set<Id>();
        Set<Id> validSIIds = new Set<Id>();
        
        // construct invalid SIs for payment batch
        Supplier_Invoice__c incompletePrepayment = testData.createSI('Prepayment', 1000, 'test101p-a', 'Online', testData.fuel.company, testData.fuel.remittosupplier); 
        incompletePrepayment.Status__c = 'Incomplete';
        Supplier_Invoice__c draftPrepayment = testData.createSI('Prepayment', 1000, 'test101a-a', 'Check', testData.fuel.company, testData.fuel.remittosupplier); 
        draftPrepayment.Status__c = 'Draft';
        Supplier_Invoice__c appliedPrepayment = testData.createSI('Prepayment', 1000, 'test101a-b', 'Check', testData.fuel.company, testData.fuel.remittosupplier); 
        appliedPrepayment.Credit_Memo_Balance__c = 0;
        Supplier_Invoice__c appliedCM = testData.createSI('Credit Memo', -1000, 'test101a-cm', 'Check', testData.fuel.company, testData.fuel.remittosupplier); 
        appliedCM.Credit_Memo_Balance__c = 0;

        List<Supplier_Invoice__c> invalidSIs = new List<Supplier_Invoice__c>();
        invalidSIs.add(incompletePrepayment);
        invalidSIs.add(draftPrepayment);
        invalidSIs.add(appliedPrepayment);
        invalidSIs.add(appliedCM);
        insert invalidSIs;
        for (Supplier_Invoice__c si: invalidSIs){
            invalidSIIds.add(si.Id);
        }
        
        // Valid SIs for payment batch
        for (Supplier_Invoice__c siValid: testData.suppInvList){
            validSIIds.add(siValid.Id);
        }
        
        Test.startTest();
        
        // Arrange
        List<Supplier_Invoice__c> siList = [select id, Status__c, Hold__c, Supplier__c, Balance_Due__c, Supplier__r.Hold_Payment__c from Supplier_Invoice__c where Id = :testData.matchToPOSupplierInvoice.id];
        System.assertNotEquals(0, siList.size());
        // Act
        JsonResult result = PaymentBatchExt.getSupplierInvoices(testData.filters, testData.supplierInvoicePreviewConfig);
        
        // Assert
        System.assertNotEquals(0, result.total, result);
        List<SupplierPaymentService.InvoiceWrapper> invWrapperList = (List<SupplierPaymentService.InvoiceWrapper> )result.records;
        for (SupplierPaymentService.InvoiceWrapper invWrapper: invWrapperList){
            Supplier_Invoice__c si = (Supplier_Invoice__c) invWrapper.invoiceRecord;
            system.assert(!invalidSIIds.contains(si.Id), '>>> si');
            system.assert(validSIIds.contains(si.Id), '>>> si');
        }
        Test.stopTest();        
        
    }
    
    static testMethod void testCreateSPaymentBatch_OneSupplier(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Test.startTest();
        
        // Arrange
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        List<Supplier_Invoice__c> siListToTest = new List<Supplier_Invoice__c>();
        siListToTest.add(si);
        List<SupplierPaymentService.InvoiceWrapper> invWrapperList = new List<SupplierPaymentService.InvoiceWrapper>();
        SupplierPaymentService.InvoiceWrapper invWrapper = new SupplierPaymentService.InvoiceWrapper();
        invWrapper.invoiceRecord = si;
        invWrapper.Amount_To_Apply = si.Invoice_Amount__c;
        invWrapper.Invoice_Status = si.Status__c;
    	invWrapper.Invoice_Type = si.Invoice_Type__c;
        invWrapperList.add(invWrapper);
        List<KendoUtils.FilterDescriptor> filters = testData.filters;
        JsonResult result = PaymentBatchExt.createSPaymentBatch(filters, invWrapperList);
        
        // Assert
        System.assertNotEquals(0, result.total, result);
        
        Test.stopTest();        
        
    }

    static testMethod void testCreateSPaymentBatch_MultiSuppliers(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        JsonResult jsResult = new JsonResult();
        //Create supplier
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2 = testData.fuel.remittosupplier.clone();
        remitToSupp2.Name = 'RemitToSupplier-2';
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = false;
        remitToSupp2.Pay_Per_Invoice__c = false;
        update new List<Supplier__c>{supp2,testData.fuel.remittosupplier};

        // create SI for a supplier2
        Supplier_Invoice__c siSupplier2 = testData.createSI(PaymentService.TYPE_INVOICE, 1000, 'supp2Invoice', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier2;
        Supplier_Invoice_Line__c siLineSupplier2 = testData.createSILine(1, 1000, siSupplier2, null, null);
        insert siLineSupplier2;
        // approve and finalize SI
        siSupplier2.Status__c = 'Approved';
        siSupplier2.Finalized__c = true;
        siSupplier2.Transaction_Date__c = system.now();
        update siSupplier2;
        
        //SI for supplier1
        Supplier_Invoice__c si = testData.NonPOInvoice;
        
        //Both SIs, 1 per supplier, are chosen for payment batch
        Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.Id);
        siSetToTest.add(siSupplier2.Id);
        
        
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{ testData.fuel.remittosupplier.id,remitToSupp2.id};//
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c'){            	
                newFilters.add(fd);
            }
            else {
                KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supplierIds);
                newFilters.add(filter1);
            }
        }
        
        Test.startTest();
        // cannot call payment batch with batch size > 1        
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();  
        SupplierPaymentService.invoicePaymentWrapper originalSISPRecordsFromUI = new SupplierPaymentService.invoicePaymentWrapper();
        originalSISPRecordsFromUI.invWrapperList = new List<SupplierPaymentService.InvoiceWrapper> ();  
        system.debug(LoggingLevel.Error,'invoiceRecordsFromUI==' + invoiceRecordsFromUI);      
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	//if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        	if (siWrapper.invoiceRecord.Invoice_Type__c != PaymentService.TYPE_CREDITMEMO && siWrapper.invoiceRecord.Status__c == PaymentService.STATUS_APPROVED)
        		originalSISPRecordsFromUI.invWrapperList.add(siWrapper);
        } 
        SupplierPaymentService spService = new SupplierPaymentService();
        
        originalSISPRecordsFromUI.dateTimeNow = system.now() +'#';
        // try to throw error
        jsResult = PaymentBatchExt.createSPaymentRealTime(newFilters,invoiceRecordsFromUI,null);
        system.assert(jsResult.success == false, 'Found problem in processing SIs immediate mode: ' + jsResult);
		system.assert(jsResult.messages.size() > 0,'Error occurred in batch'+jsResult );
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jsResult.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.Payments_Cannot_Be_Previewed  +'.' + Label.Contact_Kenandy_administrator_for_help)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
    	}
        system.assert(ErrorExists, 'Exception not thrown: '+jsResult);        
        jsResult = PaymentBatchExt.createSPaymentRealTime(newFilters,invoiceRecordsFromUI,originalSISPRecordsFromUI);
        system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        List<SupplierPaymentService.invoicePaymentWrapper>  payWrapper= (List<SupplierPaymentService.invoicePaymentWrapper>)jsResult.records;
        system.debug(LoggingLevel.Error,'test method paywrapper : '+payWrapper[0].paymentWrapperList);
        
		List<Supplier_Payment__c> sps = new List<Supplier_Payment__c>();
		List<Supplier_Payment_Line__c> splines = new List<Supplier_Payment_Line__c>();
		map<string,SupplierPaymentService.paymentWithLinesWrapper> SPmap = new map<string,SupplierPaymentService.paymentWithLinesWrapper>();
		for (SupplierPaymentService.paymentWithLinesWrapper paylineWrapper :payWrapper[0].paymentWrapperList){
			if (!SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c)){
				SPmap.put(paylineWrapper.supplierPayment.Source_Key__c,paylineWrapper);
				sps.add(paylineWrapper.supplierPayment);
			}
			splines.addAll(paylineWrapper.lstPaymentLines);
		}
		List<SupplierPaymentService.paymentWithLinesWrapper> paymentWrapperList = spService.CreateFinalizePaymentsForImmediate(false,testData.supplierPaymentMasterPreviewConfig,sps,splines); 
		
        Test.stopTest();
        Set<Id> spIds = new Set<Id>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where supplier_invoice__c in :siSetToTest];
        system.assert(splines.size() == 4, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
            if (spLine.type__c == 'Payment')
            	system.assert(spLine.Amount__c == 990, 'Supplier Payment line amount is not correct: ' + spLine.Amount__c);
            if (spLine.type__c == PaymentService.TYPE_EARNED_DISCOUNT)
            	system.assert(spLine.Amount__c == 10, 'Supplier Payment line amount is not correct: ' + spLine.Amount__c);
        }
        system.assertEquals(SIsRelatedToSPLs.size(), siSetToTest.size());
        system.assert(SIsRelatedToSPLs.containsAll(siSetToTest));
        
        system.assertEquals(spIds.size(), 2, 'Incorrent number of SPs created: spIds - ' + spIds);
        sps = [select id, status__c, Transaction_Date__c, Payment_Amount__c from Supplier_Payment__c where id in:spIds];
        system.assertEquals(sps.size(), 2, 'Incorrent number of SPs created: spIds - ' + sps);
        for (Supplier_Payment__c sp: sps){
            system.assert(sp.status__c == 'Applied', 'Supplier Payment status is not correct: ' + sp.status__c);            
            system.assert(sp.Transaction_Date__c != null); //KNDY-10280 KNDY-12343
        }
    }
    
   
    
    
    static testMethod void testCreateSPaymentBatch_SingleSuppliersBatch(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Test.startTest();
        
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = false;
        update new List<Supplier__c>{testData.fuel.remittosupplier};
        
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{testData.fuel.remittosupplier.id};
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c'){
                newFilters.add(fd);
            }
            else {
                KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supplierIds);
                newFilters.add(filter1);
            }
        }
        system.assertEquals(newFilters != null, true, 'filters used =' + newFilters);

        Set<Id> supSetToPass = new Set<Id>{testdata.fuel.remittosupplier.id};

        List<Supplier_Invoice__c> supplierInvoiceList = [select id from supplier_Invoice__c where Supplier__c IN:supSetToPass];
        system.assertEquals(supplierInvoiceList.size() ,6,'total SI mismatch' + supplierInvoiceList.size());
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        system.assertEquals(invoiceRecordsFromUI.size() ,4,'total SI mismatch' + invoiceRecordsFromUI);        
        PaymentBatchExt.createSPaymentBatch(newFilters,invoiceRecordsFromUI);

        Test.stopTest();
        Set<Id> spIds = new Set<Id>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        system.debug('Remit To Supplier1=' + testdata.fuel.remittosupplier.id);
        List<Supplier_Payment__c> sps = [select id, status__c, Transaction_Date__c, Payment_Amount__c,Supplier__c from Supplier_Payment__c where Supplier__c IN:supSetToPass];
        system.assertEquals(sps.size(), 1, 'Incorrent number of SPs created: spIds - ' + sps);
        // supplier lines for remit to supplier1
        List<Supplier_Payment_Line__c> splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Payment__r.Supplier__c =:testData.fuel.remittosupplier.id];
        system.assert(splines.size() == 6, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
        }

        system.assertEquals(spIds.size(), 1, 'Incorrent number of SPs created: spIds - ' + spIds);
    }
    static testMethod void testCreateSPaymentBatch_SingleSuppliersBatchPartialPayment(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Test.startTest();
               	
        Supplier_Invoice__c si = testData.ACHSupplierInvoice;
        Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(testData.fuel.remittosupplier.id);
        
        //KNDY-17277 - discount earned deprecated
        si = [select id, name, Invoice_Amount__c, Discount_Date__c, Discount_Taken__c, Status__c from Supplier_Invoice__c where id =:testData.ACHSupplierInvoice.id];
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c =:si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        for (KendoUtils.FilterDescriptor fdSet: testData.filters){
          if (fdSet.field == 'Payment_Method_G__c')
            fdSet.value = 'ACH';
        }
        
        Supplier_Invoice__c CreditMemoInvoice = testData.createSI('Credit Memo',-500, 'testCMabc', 'ACH', testData.fuel.company, testData.fuel.remittosupplier);
        CreditMemoInvoice.Credit_Memo_Balance__c = -500;
        CreditMemoInvoice.Credit_Memo_Amount__c = -500;
        insert CreditMemoInvoice;
        Supplier_Invoice_Line__c siLine = testData.createSILine(1, -500, CreditMemoInvoice, null, testData.purchasedItem.Id);
        insert siLine;
        CreditMemoInvoice.Status__c = 'Approved';
        CreditMemoInvoice.Transaction_Date__c = system.now();
        update CreditMemoInvoice;
        system.debug(LoggingLevel.ERROR,'CM queried back: ' + CreditMemoInvoice);
   		siSetToTest.add(CreditMemoInvoice.id);

        List<Supplier_Invoice__c> supplierInvoiceList = [select id from supplier_Invoice__c where Id IN:siSetToTest];
        system.assertEquals(supplierInvoiceList.size() ,2,'total SI mismatch' + supplierInvoiceList.size());  
               
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(testData.filters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){      
        	siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply >= 0 ? siWrapper.invoiceRecord.Balance_Due__c - 100 : siWrapper.invoiceRecord.Credit_Memo_Balance__c + 50;
        	siWrapper.Discount_Earned = siWrapper.Amount_To_Apply >= 0 ? siWrapper.Amount_To_Apply  * 0.01 : 0;
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
 			siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
			siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
			siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
			ID sID = siWrapper.invoiceRecord.id;
			if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
			scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        system.assert(scopeSupInvIdsToPay.size()== 2, 'Scope of invoices' + scopeSupInvIdsToPay);
        PaymentBatch jpBatch = new PaymentBatch( testData.filters, scopeSupInvIdsToPay, supSetToPass);
        jpBatch.runBatch(null);
        Test.stopTest();

        Set<Id> spIds = new Set<Id>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        system.debug('Remit To Supplier1=' + testdata.fuel.remittosupplier.id);
        List<Supplier_Payment__c> sps = [select id, status__c, Transaction_Date__c, Payment_Amount__c,Supplier__c,Total_Number_Of_Lines__c from Supplier_Payment__c where Supplier__c IN:supSetToPass];
        system.assertEquals(sps.size(), 1, 'Incorrent number of SPs created: spIds - ' + sps);
        system.assert(sps[0].Total_Number_Of_Lines__c == 3, 'Found incorrect Payment lines tied to invoices: ' + sps[0]);
        system.assert(sps[0].Payment_Amount__c == 441, 'Found incorrect Payment amount : ' + sps[0].Payment_Amount__c);
        List<Supplier_Invoice__c > siList = new List<Supplier_Invoice__c>();
        siList = [select id, name, Discount_Date__c, Discount_Taken__c, Status__c,Amount_Paid__c,Balance_Due__c from Supplier_Invoice__c where id =:testData.ACHSupplierInvoice.id];
        si = siList[0];
        system.assert(si.Discount_Taken__c == 9, 'Discount Taken is not right: ' + si.Discount_Taken__c);       
        system.assert(si.Balance_Due__c == 100, 'Balance due is not right: ' + si.Balance_Due__c);
        system.assert(si.Status__c == 'Approved', 'Supplier invoice is not closed: ' + si.Status__c);
        
        siList = [select id, name, Discount_Date__c, Status__c,Credit_Memo_Balance__c,Invoice_Type__c,Credit_Memo_Amount__c from Supplier_Invoice__c where id =:CreditMemoInvoice.id]; 
        si = siList[0];      
        system.assert(si.Credit_Memo_Balance__c == -50, 'Credit Memo balance is not right: ' + si );
        system.assert(si.Status__c == 'Approved', 'Supplier invoice is not closed: ' + si.Status__c);

    }
    static testMethod void testCreateSPaymentBatch_SingleSuppliersAlwaysTakeDiscount(){
    	
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Test.startTest();              
        //Create supplier
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2 = testData.fuel.remittosupplier.clone();
        remitToSupp2.Name = 'RemitToSupplier-2';
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = false;
        remitToSupp2.Pay_Per_Invoice__c = false;
        remitToSupp2.Always_Take_Discount__c = true;
        update new List<Supplier__c>{supp2,testData.fuel.remittosupplier};

        // create SI for a supplier2
        Supplier_Invoice__c siSupplier1 = testData.createSI(PaymentService.TYPE_INVOICE, 1000, 'supp1Invoice', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier1;
        Supplier_Invoice_Line__c siLineSupplier1 = testData.createSILine(1, 1000, siSupplier1, null, null);
        insert siLineSupplier1;
        // approve and finalize SI
        siSupplier1.Status__c = 'Approved';
        siSupplier1.Finalized__c = true;
        siSupplier1.Always_Take_Discount__c = true;
        siSupplier1.Transaction_Date__c = system.now();
        update siSupplier1;
        
        Supplier_Invoice__c siSupplier2 = testData.createSI(PaymentService.TYPE_INVOICE, 1000, 'supp2Invoice', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier2;
        Supplier_Invoice_Line__c siLineSupplier2 = testData.createSILine(1, 1000, siSupplier2, null, null);
        insert siLineSupplier2;
        // approve and finalize SI
        siSupplier2.Status__c = 'Approved';
        siSupplier2.Finalized__c = true;
        siSupplier2.Transaction_Date__c = system.now();
        siSupplier2.Always_Take_Discount__c = false;
        update siSupplier2;
        
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{remitToSupp2.id};
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor filter1 ;
        DateTime dtnow = system.now().addDays(20);
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c' && fd.field != 'PaymentDate' ){
                newFilters.add(fd);
            }
            else {
            	if (fd.field == 'Supplier__c'){
	                filter1 = new KendoUtils.FilterDescriptor();
	                filter1.field = 'Supplier__c';
	                filter1.fieldType = null;
	                filter1.operator = 'contains';
	                filter1.value = JSON.serialize(supplierIds);
	                newFilters.add(filter1);
            	}
            	if (fd.field == 'PaymentDate'){
	                filter1 = new KendoUtils.FilterDescriptor();
	                filter1.field = 'PaymentDate';
			        filter1.fieldType = 'date';
			        filter1.operator = 'lte';
			        filter1.value = dtnow.format('MM/dd/yyy hh:mm a');
	                newFilters.add(filter1);
            	}
            }
        }
        system.assertEquals(newFilters != null, true, 'filters used =' + newFilters);

        Set<Id> supSetToPass = new Set<Id>{remitToSupp2.id};

        List<Supplier_Invoice__c> supplierInvoiceList = [select id,Always_Take_Discount__c from supplier_Invoice__c where Supplier__c IN:supSetToPass];
        system.assertEquals(supplierInvoiceList.size() ,2,'total SI mismatch' + supplierInvoiceList.size());
        for (Supplier_Invoice__c supplierInv :supplierInvoiceList){
        	if (supplierInv.id == siSupplier1.id)
        		system.assertEquals(supplierInv.Always_Take_Discount__c ,true,' always take discount mismatch, it should be true : ' + supplierInv);
        	if (supplierInv.id == siSupplier2.id)
        		system.assertEquals(supplierInv.Always_Take_Discount__c ,false,' always take discount mismatch, it should be false : ' + supplierInv);
        }
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        system.assertEquals(invoiceRecordsFromUI.size() ,2,'total SI mismatch' + invoiceRecordsFromUI);        
        PaymentBatchExt.createSPaymentBatch(newFilters,invoiceRecordsFromUI);

        Test.stopTest();
        Set<Id> spIds = new Set<Id>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        system.debug('Remit To Supplier1=' + remitToSupp2.id);
        List<Supplier_Payment__c> sps = [select id, status__c, Transaction_Date__c, Payment_Amount__c,Supplier__c from Supplier_Payment__c where Supplier__c IN:supSetToPass];
        system.assertEquals(sps.size(), 1, 'Incorrent number of SPs created: spIds - ' + sps);
        // supplier lines for remit to supplier1
        List<Supplier_Payment_Line__c> splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c,Supplier_Payment__r.Supplier__c,Supplier_Invoice__r.Always_Take_Discount__c from Supplier_Payment_Line__c where Supplier_Payment__r.Supplier__c =:remitToSupp2.id];
        system.assert(splines.size() == 3, 'Found incorrect Payment lines tied to invoices: ' + splines);
        boolean discountTakenFlag = false;
        for (Supplier_Payment_Line__c spLine: spLines){
           if (spLine.Type__c == PaymentService.TYPE_EARNED_DISCOUNT)
           		discountTakenFlag = true; 
        }
        //Discount Taken
		splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Invoice__c =:siSupplier1.id];
        system.assert(splines.size() == 2, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
           if (spLine.Type__c == PaymentService.TYPE_EARNED_DISCOUNT)
           		system.assertEquals(spLine.Amount__c, 10, 'discount not taken : ' + spLine.Amount__c);
        }
        //No discount taken
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Invoice__c =:siSupplier2.id];
        system.assert(splines.size() == 1, 'Found incorrect Payment lines tied to invoices: ' + splines);
        supplierInvoiceList = [select id,Always_Take_Discount__c,Discount_Taken__c from supplier_Invoice__c where id =:siSupplier1.id];
        system.assertEquals(supplierInvoiceList[0].Discount_Taken__c ,10,'total SI discount mismatch' + supplierInvoiceList);
        supplierInvoiceList = [select id,Always_Take_Discount__c,Discount_Taken__c from supplier_Invoice__c where id =:siSupplier2.id];
        system.assertEquals(supplierInvoiceList[0].Discount_Taken__c ,0,'total SI discount mismatch' + supplierInvoiceList);
    }
    
    static testMethod void testCreateSPaymentBatch_MultiSuppliersBatchCheckOverflow(){
    	Test.startTest();
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        
        //Create supplier
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2 = testData.fuel.remittosupplier.clone();
        remitToSupp2.Name = 'RemitToSupplier-2';
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = false;
        remitToSupp2.Pay_Per_Invoice__c = false;
        update new List<Supplier__c>{supp2,testData.fuel.remittosupplier,remitToSupp2};
        
        Bank_Account__c ba = testData.bankAccount;
        ba.Use_Pre_Printed_Check_Stock__c = true;
        ba.Number_of_Advice_Lines_Per_Page__c = 2;
        update ba;
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{testData.fuel.remittosupplier.id, remitToSupp2.id};
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c'){
            	if(fd.field == 'totalCreditsExceedsDebits')
            	{
            		filter1 = new KendoUtils.FilterDescriptor();
	                filter1.field = 'totalCreditsExceedsDebits';
	                filter1.fieldType = 'boolean';
	                filter1.operator = 'eq';
	                filter1.value = true;
	                newFilters.add(filter1);
            	}else	
                	newFilters.add(fd);
            }
            else {
                filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supplierIds);
                newFilters.add(filter1);
            }
        }
        system.assertEquals(newFilters != null, true, 'filters used =' + newFilters);
        
        // create SI for a remitToSupplier2
        Supplier_Invoice__c siSupplier2 = testData.createSI(PaymentService.TYPE_INVOICE, 800, 'remittosupp2Invoice1', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier2;
        Supplier_Invoice_Line__c siLineSupplier2 = testData.createSILine(1, 800, siSupplier2, null, null);
        insert siLineSupplier2;
        // approve and finalize SI
        siSupplier2.Status__c = 'Approved';
        siSupplier2.Finalized__c = true;
        siSupplier2.Transaction_Date__c = system.now();
        update siSupplier2;
      	//create SI for a remitToSupplier2  
        Supplier_Invoice__c siSupplier3 = testData.createSI(PaymentService.TYPE_INVOICE, 700, 'remittosupp2Invoice2', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier3;
        Supplier_Invoice_Line__c siLineSupplier3 = testData.createSILine(1, 700, siSupplier3, null, null);
        insert siLineSupplier3;
        // approve and finalize SI
        siSupplier3.Status__c = 'Approved';
        siSupplier3.Finalized__c = true;
        siSupplier3.Transaction_Date__c = system.now();
        update siSupplier3;
        
        
        Supplier_Invoice__c CreditMemoInvoice = new Supplier_Invoice__c();{
			CreditMemoInvoice.Invoice_Type__c = 'Credit Memo';
	    	CreditMemoInvoice.Company__c = testData.fuel.company.Id;
	        CreditMemoInvoice.Supplier__c = remitToSupp2.id;
	        CreditMemoInvoice.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			CreditMemoInvoice.Date_Invoiced__c = system.now();
	        CreditMemoInvoice.Supplier_Invoice__c = 'test101b';
	        CreditMemoInvoice.Supplier_and_Invoice__c = 'test 101b';
	        CreditMemoInvoice.Invoice_Amount__c = -1100;
	        CreditMemoInvoice.Credit_Memo_Balance__c = -1100;
	        CreditMemoInvoice.Credit_Memo_Amount__c = -1100;
	        CreditMemoInvoice.Payment_Term__c = testData.paymentTermInfo.id;
	        CreditMemoInvoice.Payment_Method_G__c = 'Check';
	        insert CreditMemoInvoice;
	        
	        Supplier_Invoice_Line__c siLineCM = new Supplier_Invoice_Line__c();
	       	siLineCM.Supplier_Invoice__c = CreditMemoInvoice.Id;
	        siLineCM.Invoice_Quantity__c = 1;
	        siLineCM.Unit_Price__c = -1100;//KNDY-14371
	        siLineCM.Description__c = 'test';
	        insert siLineCM;
	        
	        CreditMemoInvoice.Status__c = 'Approved';
	        CreditMemoInvoice.Transaction_Date__c = system.now();
	        update CreditMemoInvoice;
		}
		
		Supplier_Invoice__c CreditMemoInvoice1 = new Supplier_Invoice__c();{
			CreditMemoInvoice1.Invoice_Type__c = 'Credit Memo';
	    	CreditMemoInvoice1.Company__c = testData.fuel.company.Id;
	        CreditMemoInvoice1.Supplier__c = remitToSupp2.id;
	        CreditMemoInvoice1.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			CreditMemoInvoice1.Date_Invoiced__c = system.now();
	        CreditMemoInvoice1.Supplier_Invoice__c = 'test101c';
	        CreditMemoInvoice1.Supplier_and_Invoice__c = 'test 101c';
	        CreditMemoInvoice1.Invoice_Amount__c = -100;
	        CreditMemoInvoice1.Credit_Memo_Balance__c = -100;
	        CreditMemoInvoice1.Credit_Memo_Amount__c = -100;
	        CreditMemoInvoice1.Payment_Term__c = testData.paymentTermInfo.id;
	        CreditMemoInvoice1.Payment_Method_G__c = 'Check';
	        insert CreditMemoInvoice1;
	        
	        Supplier_Invoice_Line__c siLineCM = new Supplier_Invoice_Line__c();
	       	siLineCM.Supplier_Invoice__c = CreditMemoInvoice1.Id;
	        siLineCM.Invoice_Quantity__c = 1;
	        siLineCM.Unit_Price__c = -100;//KNDY-14371
	        siLineCM.Description__c = 'test';
	        insert siLineCM;
	        
	        CreditMemoInvoice1.Status__c = 'Approved';
	        CreditMemoInvoice1.Transaction_Date__c = system.now();
	        update CreditMemoInvoice1;
		}

        
        Set<Id> supSetToPass = new Set<Id>{remitToSupp2.id,testdata.fuel.remittosupplier.id};

        List<Supplier_Invoice__c> supplierInvoiceList = [select id from supplier_Invoice__c where Supplier__c IN:supSetToPass];
        system.assertEquals(supplierInvoiceList.size() ,10,'total SI mismatch' + supplierInvoiceList);
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        system.assertEquals(invoiceRecordsFromUI.size() ,8,'total SI mismatch' + invoiceRecordsFromUI.size());        
        PaymentBatchExt.createSPaymentBatch(newFilters,invoiceRecordsFromUI);

        Test.stopTest();
        Bank_Account__c bankAcc = [select id,Use_Pre_Printed_Check_Stock__c,Number_of_Advice_Lines_Per_Page__c from Bank_Account__c where id =: ba.id];
        system.assertEquals(bankAcc.Use_Pre_Printed_Check_Stock__c, true, bankAcc);
        Set<Id> spIds = new Set<Id>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        system.debug('Remit To Supplier1=' + testdata.fuel.remittosupplier.id);
        system.debug('Remit To Supplier2=' + remitToSupp2.id);
        List<Supplier_Payment__c> sps = [select id, status__c,Status_Reason__c, Transaction_Date__c, Payment_Amount__c,Supplier__c,Total_Number_Of_Lines__c from Supplier_Payment__c where Supplier__c IN:supSetToPass];
        system.assertEquals(sps.size(), 7, 'Incorrent number of SPs created: spIds - ' + sps);
        system.debug(LoggingLevel.Error,'Total SPs created=' + sps);
        boolean cancelledflg = false;
        for (Supplier_Payment__c payment : sps){
        	if (payment.status__C == PaymentService.STATUS_CANCELLED){
        		cancelledflg = true;
        		system.assertEquals(payment.Status_Reason__c ,PaymentService.STATUS_REASON_VOID_FROM_OVERFLOW_ADVICE,' wrongly cancelled status does not match ' +payment);
        		system.assertEquals(payment.Total_Number_Of_Lines__c == 0,true, 'lines created for payment voided by overflow ' + payment);
        	}        	
        }
        system.assert(cancelledflg == true,' no cancelled payments found ' + sps); 
        // supplier lines for remit to supplier1
        List<Supplier_Payment_Line__c> splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Payment__r.Supplier__c =:testData.fuel.remittosupplier.id];
        system.assert(splines.size() == 6, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
        }
        
        // supplier lines for remit to supplier2
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Payment__r.Supplier__c =:remitToSupp2.id];
        system.assert(splines.size() == 7, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
        }
        
        system.assertEquals(spIds.size(), 2, 'Incorrent number of SPs created: spIds - ' + spIds);             
    }
 	
 	static testMethod void testPaymentBatch_MultiSuppliersCheckOverflowPayperInv(){
    	Test.startTest();
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        
        //Create supplier
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2 = testData.fuel.remittosupplier.clone();
        remitToSupp2.Name = 'RemitToSupplier-2';
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = true;
        remitToSupp2.Pay_Per_Invoice__c = true;
        update new List<Supplier__c>{supp2,testData.fuel.remittosupplier,remitToSupp2};
        
        Bank_Account__c ba = testData.bankAccount;
        ba.Use_Pre_Printed_Check_Stock__c = true;
        ba.Number_of_Advice_Lines_Per_Page__c = 2;
        update ba;
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{testData.fuel.remittosupplier.id, remitToSupp2.id};
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c'){
            	if(fd.field == 'totalCreditsExceedsDebits')
            	{
            		filter1 = new KendoUtils.FilterDescriptor();
	                filter1.field = 'totalCreditsExceedsDebits';
	                filter1.fieldType = 'boolean';
	                filter1.operator = 'eq';
	                filter1.value = true;
	                newFilters.add(filter1);
            	}else	
                	newFilters.add(fd);
            }
            else {
                filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supplierIds);
                newFilters.add(filter1);
            }
        }
        system.assertEquals(newFilters != null, true, 'filters used =' + newFilters);
        
        // create SI for a remitToSupplier2
        Supplier_Invoice__c siSupplier2 = testData.createSI(PaymentService.TYPE_INVOICE, 800, 'remittosupp2Invoice1', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier2;
        Supplier_Invoice_Line__c siLineSupplier2 = testData.createSILine(1, 800, siSupplier2, null, null);
        insert siLineSupplier2;
        // approve and finalize SI
        siSupplier2.Status__c = 'Approved';
        siSupplier2.Finalized__c = true;
        siSupplier2.Transaction_Date__c = system.now();
        update siSupplier2;
      	//create SI for a remitToSupplier2  
        Supplier_Invoice__c siSupplier3 = testData.createSI(PaymentService.TYPE_INVOICE, 700, 'remittosupp2Invoice2', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier3;
        Supplier_Invoice_Line__c siLineSupplier3 = testData.createSILine(1, 700, siSupplier3, null, null);
        insert siLineSupplier3;
        // approve and finalize SI
        siSupplier3.Status__c = 'Approved';
        siSupplier3.Finalized__c = true;
        siSupplier3.Transaction_Date__c = system.now();
        update siSupplier3;
        
        
        Supplier_Invoice__c CreditMemoInvoice = new Supplier_Invoice__c();{
			CreditMemoInvoice.Invoice_Type__c = 'Credit Memo';
	    	CreditMemoInvoice.Company__c = testData.fuel.company.Id;
	        CreditMemoInvoice.Supplier__c = remitToSupp2.id;
	        CreditMemoInvoice.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			CreditMemoInvoice.Date_Invoiced__c = system.now();
	        CreditMemoInvoice.Supplier_Invoice__c = 'test101b';
	        CreditMemoInvoice.Supplier_and_Invoice__c = 'test 101b';
	        CreditMemoInvoice.Invoice_Amount__c = -1100;
	        CreditMemoInvoice.Credit_Memo_Balance__c = -1100;
	        CreditMemoInvoice.Credit_Memo_Amount__c = -1100;
	        CreditMemoInvoice.Payment_Term__c = testData.paymentTermInfo.id;
	        CreditMemoInvoice.Payment_Method_G__c = 'Check';
	        insert CreditMemoInvoice;
	        
	        Supplier_Invoice_Line__c siLineCM = new Supplier_Invoice_Line__c();
	       	siLineCM.Supplier_Invoice__c = CreditMemoInvoice.Id;
	        siLineCM.Invoice_Quantity__c = 1;
	        siLineCM.Unit_Price__c = -1100;//KNDY-14371
	        siLineCM.Description__c = 'test';
	        insert siLineCM;
	        
	        CreditMemoInvoice.Status__c = 'Approved';
	        CreditMemoInvoice.Transaction_Date__c = system.now();
	        update CreditMemoInvoice;
		}
		
		Supplier_Invoice__c CreditMemoInvoice1 = new Supplier_Invoice__c();{
			CreditMemoInvoice1.Invoice_Type__c = 'Credit Memo';
	    	CreditMemoInvoice1.Company__c = testData.fuel.company.Id;
	        CreditMemoInvoice1.Supplier__c = remitToSupp2.id;
	        CreditMemoInvoice1.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			CreditMemoInvoice1.Date_Invoiced__c = system.now();
	        CreditMemoInvoice1.Supplier_Invoice__c = 'test101c';
	        CreditMemoInvoice1.Supplier_and_Invoice__c = 'test 101c';
	        CreditMemoInvoice1.Invoice_Amount__c = -100;
	        CreditMemoInvoice1.Credit_Memo_Balance__c = -100;
	        CreditMemoInvoice1.Credit_Memo_Amount__c = -100;
	        CreditMemoInvoice1.Payment_Term__c = testData.paymentTermInfo.id;
	        CreditMemoInvoice1.Payment_Method_G__c = 'Check';
	        insert CreditMemoInvoice1;
	        
	        Supplier_Invoice_Line__c siLineCM = new Supplier_Invoice_Line__c();
	       	siLineCM.Supplier_Invoice__c = CreditMemoInvoice1.Id;
	        siLineCM.Invoice_Quantity__c = 1;
	        siLineCM.Unit_Price__c = -100;//KNDY-14371
	        siLineCM.Description__c = 'test';
	        insert siLineCM;
	        
	        CreditMemoInvoice1.Status__c = 'Approved';
	        CreditMemoInvoice1.Transaction_Date__c = system.now();
	        update CreditMemoInvoice1;
		}

        
        Set<Id> supSetToPass = new Set<Id>{remitToSupp2.id,testdata.fuel.remittosupplier.id};

        List<Supplier_Invoice__c> supplierInvoiceList = [select id from supplier_Invoice__c where Supplier__c IN:supSetToPass];
        system.assertEquals(supplierInvoiceList.size() ,10,'total SI mismatch' + supplierInvoiceList);
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        system.assertEquals(invoiceRecordsFromUI.size() ,8,'total SI mismatch' + invoiceRecordsFromUI.size());        
        PaymentBatchExt.createSPaymentBatch(newFilters,invoiceRecordsFromUI);

        Test.stopTest();
        Bank_Account__c bankAcc = [select id,Use_Pre_Printed_Check_Stock__c,Number_of_Advice_Lines_Per_Page__c from Bank_Account__c where id =: ba.id];
        system.assertEquals(bankAcc.Use_Pre_Printed_Check_Stock__c, true, bankAcc);
        Set<Id> spIds = new Set<Id>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        system.debug('Remit To Supplier1=' + testdata.fuel.remittosupplier.id);
        system.debug('Remit To Supplier2=' + remitToSupp2.id);
        List<Supplier_Payment__c> sps = [select id, status__c,Status_Reason__c, Transaction_Date__c, Payment_Amount__c,Supplier__c,Total_Number_Of_Lines__c from Supplier_Payment__c where Supplier__c IN:supSetToPass];
        system.assertEquals(sps.size(), 8, 'Incorrent number of SPs created: spIds - ' + sps);
        boolean cancelledflg = false;
        for (Supplier_Payment__c payment : sps){
        	if (payment.status__C == PaymentService.STATUS_CANCELLED){
        		cancelledflg = true;
        		system.assertEquals(payment.Status_Reason__c ,PaymentService.STATUS_REASON_VOID_FROM_OVERFLOW_ADVICE,' wrongly cancelled status does not match ' +payment);
        		system.assertEquals(payment.Total_Number_Of_Lines__c == 0,true, 'lines created for payment voided by overflow ' + payment);
        	}        	
        }
        system.assert(cancelledflg == true,' no cancelled payments found ' + sps); 
        // supplier lines for remit to supplier1
        List<Supplier_Payment_Line__c> splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Payment__r.Supplier__c =:testData.fuel.remittosupplier.id];
        system.assert(splines.size() == 6, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
        }
        
        // supplier lines for remit to supplier2
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Payment__r.Supplier__c =:remitToSupp2.id];
        system.assert(splines.size() == 7, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
        }
        
        system.assertEquals(spIds.size(), 5, 'Incorrent number of SPs created: spIds - ' + spIds);              
    }
    
 	static testMethod void testPaymentBatch_MultiSuppliersNoCheckOVerflow(){
    	Test.startTest();
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        
        //Create supplier
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2 = testData.fuel.remittosupplier.clone();
        remitToSupp2.Name = 'RemitToSupplier-2';
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = false;
        remitToSupp2.Pay_Per_Invoice__c = false;
        update new List<Supplier__c>{supp2,testData.fuel.remittosupplier,remitToSupp2};
        
        Bank_Account__c ba = testData.bankAccount;
        ba.Use_Pre_Printed_Check_Stock__c = true;
        ba.Number_of_Advice_Lines_Per_Page__c = 20;
        update ba;
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{testData.fuel.remittosupplier.id, remitToSupp2.id};
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c'){
            	if(fd.field == 'totalCreditsExceedsDebits')
            	{
            		filter1 = new KendoUtils.FilterDescriptor();
	                filter1.field = 'totalCreditsExceedsDebits';
	                filter1.fieldType = 'boolean';
	                filter1.operator = 'eq';
	                filter1.value = true;
	                newFilters.add(filter1);
            	}else	
                	newFilters.add(fd);
            }
            else {
                filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supplierIds);
                newFilters.add(filter1);
            }
        }
        system.assertEquals(newFilters != null, true, 'filters used =' + newFilters);
        
        // create SI for a remitToSupplier2
        Supplier_Invoice__c siSupplier2 = testData.createSI(PaymentService.TYPE_INVOICE, 800, 'remittosupp2Invoice1', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier2;
        Supplier_Invoice_Line__c siLineSupplier2 = testData.createSILine(1, 800, siSupplier2, null, null);
        insert siLineSupplier2;
        // approve and finalize SI
        siSupplier2.Status__c = 'Approved';
        siSupplier2.Finalized__c = true;
        siSupplier2.Transaction_Date__c = system.now();
        update siSupplier2;
      	//create SI for a remitToSupplier2  
        Supplier_Invoice__c siSupplier3 = testData.createSI(PaymentService.TYPE_INVOICE, 700, 'remittosupp2Invoice2', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier3;
        Supplier_Invoice_Line__c siLineSupplier3 = testData.createSILine(1, 700, siSupplier3, null, null);
        insert siLineSupplier3;
        // approve and finalize SI
        siSupplier3.Status__c = 'Approved';
        siSupplier3.Finalized__c = true;
        siSupplier3.Transaction_Date__c = system.now();
        update siSupplier3;
        
        
        Supplier_Invoice__c CreditMemoInvoice = new Supplier_Invoice__c();{
			CreditMemoInvoice.Invoice_Type__c = 'Credit Memo';
	    	CreditMemoInvoice.Company__c = testData.fuel.company.Id;
	        CreditMemoInvoice.Supplier__c = remitToSupp2.id;
	        CreditMemoInvoice.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			CreditMemoInvoice.Date_Invoiced__c = system.now();
	        CreditMemoInvoice.Supplier_Invoice__c = 'test101b';
	        CreditMemoInvoice.Supplier_and_Invoice__c = 'test 101b';
	        CreditMemoInvoice.Invoice_Amount__c = -1100;
	        CreditMemoInvoice.Credit_Memo_Balance__c = -1100;
	        CreditMemoInvoice.Payment_Term__c = testData.paymentTermInfo.id;
	        CreditMemoInvoice.Payment_Method_G__C = 'Check';
	        insert CreditMemoInvoice;
	        
	        Supplier_Invoice_Line__c siLineCM = new Supplier_Invoice_Line__c();
	       	siLineCM.Supplier_Invoice__c = CreditMemoInvoice.Id;
	        siLineCM.Invoice_Quantity__c = 1;
	        siLineCM.Unit_Price__c = -1100;//KNDY-14371
	        siLineCM.Description__c = 'test';
	        insert siLineCM;
	        
	        CreditMemoInvoice.Status__c = 'Approved';
	        CreditMemoInvoice.Transaction_Date__c = system.now();
	        update CreditMemoInvoice;
		}
		
		Supplier_Invoice__c CreditMemoInvoice1 = new Supplier_Invoice__c();{
			CreditMemoInvoice1.Invoice_Type__c = 'Credit Memo';
	    	CreditMemoInvoice1.Company__c = testData.fuel.company.Id;
	        CreditMemoInvoice1.Supplier__c = remitToSupp2.id;
	        CreditMemoInvoice1.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			CreditMemoInvoice1.Date_Invoiced__c = system.now();
	        CreditMemoInvoice1.Supplier_Invoice__c = 'test101c';
	        CreditMemoInvoice1.Supplier_and_Invoice__c = 'test 101c';
	        CreditMemoInvoice1.Invoice_Amount__c = -100;
	        CreditMemoInvoice1.Credit_Memo_Balance__c = -100;
	        CreditMemoInvoice1.Payment_Term__c = testData.paymentTermInfo.id;
	        CreditMemoInvoice1.Payment_Method_G__C = 'Check';
	        insert CreditMemoInvoice1;
	        
	        Supplier_Invoice_Line__c siLineCM = new Supplier_Invoice_Line__c();
	       	siLineCM.Supplier_Invoice__c = CreditMemoInvoice1.Id;
	        siLineCM.Invoice_Quantity__c = 1;
	        siLineCM.Unit_Price__c = -100;//KNDY-14371
	        siLineCM.Description__c = 'test';
	        insert siLineCM;
	        
	        CreditMemoInvoice1.Status__c = 'Approved';
	        CreditMemoInvoice1.Transaction_Date__c = system.now();
	        update CreditMemoInvoice1;
		}

        
        Set<Id> supSetToPass = new Set<Id>{remitToSupp2.id,testdata.fuel.remittosupplier.id};

        List<Supplier_Invoice__c> supplierInvoiceList = [select id from supplier_Invoice__c where Supplier__c IN:supSetToPass];
        system.assertEquals(supplierInvoiceList.size() ,10,'total SI mismatch' + supplierInvoiceList);
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        system.assertEquals(invoiceRecordsFromUI.size() ,8,'total SI mismatch' + invoiceRecordsFromUI.size());        
        PaymentBatchExt.createSPaymentBatch(newFilters,invoiceRecordsFromUI);

        Test.stopTest();
        Bank_Account__c bankAcc = [select id,Use_Pre_Printed_Check_Stock__c,Number_of_Advice_Lines_Per_Page__c from Bank_Account__c where id =: ba.id];
        system.assertEquals(bankAcc.Use_Pre_Printed_Check_Stock__c, true, bankAcc);
        Set<Id> spIds = new Set<Id>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        system.debug('Remit To Supplier1=' + testdata.fuel.remittosupplier.id);
        system.debug('Remit To Supplier2=' + remitToSupp2.id);
        List<Supplier_Payment__c> sps = [select id, status__c,Status_Reason__c, Transaction_Date__c, Payment_Amount__c,Supplier__c from Supplier_Payment__c where Supplier__c IN:supSetToPass];
        system.assertEquals(sps.size(), 2, 'Incorrent number of SPs created: spIds - ' + sps);
        // supplier lines for remit to supplier1
        List<Supplier_Payment_Line__c> splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Payment__r.Supplier__c =:testData.fuel.remittosupplier.id];
        system.assert(splines.size() == 6, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
        }
        
        // supplier lines for remit to supplier2
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Payment__r.Supplier__c =:remitToSupp2.id];
        system.assert(splines.size() == 7, 'Found incorrect Payment lines tied to invoices: ' + splines.size());
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
        }
        
        system.assertEquals(spIds.size(), 2, 'Incorrent number of SPs created: spIds - ' + spIds);             
    }
     //KNDY-17564 skip checks if payment lines are more than no of advice lines in case of preprinted checks
    static testMethod void testCreateSPaymentBatch_MultiSuppliersPayPerInvoiceBatch(){
    	Test.startTest();
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        
        //Create supplier
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2 = testData.fuel.remittosupplier.clone();
        remitToSupp2.Name = 'RemitToSupplier-2';
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = true;
        remitToSupp2.Pay_Per_Invoice__c = true;
        update new List<Supplier__c>{supp2,testData.fuel.remittosupplier,remitToSupp2};
        
        Bank_Account__c ba = testData.bankAccount;
        ba.Use_Pre_Printed_Check_Stock__c = true;
        ba.Number_of_Advice_Lines_Per_Page__c = 2;
        update ba;
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{testData.fuel.remittosupplier.id, remitToSupp2.id};
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c'){
            	if(fd.field == 'totalCreditsExceedsDebits')
            	{
            		filter1 = new KendoUtils.FilterDescriptor();
	                filter1.field = 'totalCreditsExceedsDebits';
	                filter1.fieldType = 'boolean';
	                filter1.operator = 'eq';
	                filter1.value = true;
	                newFilters.add(filter1);
            	}else	
                	newFilters.add(fd);
            }
            else {
                filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supplierIds);
                newFilters.add(filter1);
            }
        }
        system.assertEquals(newFilters != null, true, 'filters used =' + newFilters);
        
        // create SI for a remitToSupplier2
        Supplier_Invoice__c siSupplier2 = testData.createSI(PaymentService.TYPE_INVOICE, 800, 'remittosupp2Invoice1', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier2;
        Supplier_Invoice_Line__c siLineSupplier2 = testData.createSILine(1, 800, siSupplier2, null, null);
        insert siLineSupplier2;
        // approve and finalize SI
        siSupplier2.Status__c = 'Approved';
        siSupplier2.Finalized__c = true;
        siSupplier2.Transaction_Date__c = system.now();
        update siSupplier2;
      	//create SI for a remitToSupplier2  
        Supplier_Invoice__c siSupplier3 = testData.createSI(PaymentService.TYPE_INVOICE, 700, 'remittosupp2Invoice2', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier3;
        Supplier_Invoice_Line__c siLineSupplier3 = testData.createSILine(1, 700, siSupplier3, null, null);
        insert siLineSupplier3;
        // approve and finalize SI
        siSupplier3.Status__c = 'Approved';
        siSupplier3.Finalized__c = true;
        siSupplier3.Transaction_Date__c = system.now();
        update siSupplier3;
        
        
        Supplier_Invoice__c CreditMemoInvoice = new Supplier_Invoice__c();{
			CreditMemoInvoice.Invoice_Type__c = 'Credit Memo';
	    	CreditMemoInvoice.Company__c = testData.fuel.company.Id;
	        CreditMemoInvoice.Supplier__c = remitToSupp2.id;
	        CreditMemoInvoice.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			CreditMemoInvoice.Date_Invoiced__c = system.now();
	        CreditMemoInvoice.Supplier_Invoice__c = 'test101b';
	        CreditMemoInvoice.Supplier_and_Invoice__c = 'test 101b';
	        CreditMemoInvoice.Invoice_Amount__c = -1100;
	        CreditMemoInvoice.Credit_Memo_Balance__c = -1100;
	        CreditMemoInvoice.Payment_Term__c = testData.paymentTermInfo.id;
	        CreditMemoInvoice.Payment_Method_G__c = 'Check';
	        insert CreditMemoInvoice;
	        
	        Supplier_Invoice_Line__c siLineCM = new Supplier_Invoice_Line__c();
	       	siLineCM.Supplier_Invoice__c = CreditMemoInvoice.Id;
	        siLineCM.Invoice_Quantity__c = 1;
	        siLineCM.Unit_Price__c = -1100;//KNDY-14371
	        siLineCM.Description__c = 'test';
	        insert siLineCM;
	        
	        CreditMemoInvoice.Status__c = 'Approved';
	        CreditMemoInvoice.Transaction_Date__c = system.now();
	        update CreditMemoInvoice;
		}
		
		Supplier_Invoice__c CreditMemoInvoice1 = new Supplier_Invoice__c();{
			CreditMemoInvoice1.Invoice_Type__c = 'Credit Memo';
	    	CreditMemoInvoice1.Company__c = testData.fuel.company.Id;
	        CreditMemoInvoice1.Supplier__c = remitToSupp2.id;
	        CreditMemoInvoice1.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			CreditMemoInvoice1.Date_Invoiced__c = system.now();
	        CreditMemoInvoice1.Supplier_Invoice__c = 'test101c';
	        CreditMemoInvoice1.Supplier_and_Invoice__c = 'test 101c';
	        CreditMemoInvoice1.Invoice_Amount__c = -100;
	        CreditMemoInvoice1.Credit_Memo_Balance__c = -100;
	        CreditMemoInvoice1.Payment_Term__c = testData.paymentTermInfo.id;
	        CreditMemoInvoice1.Payment_Method_G__c = 'Check';
	        insert CreditMemoInvoice1;
	        
	        Supplier_Invoice_Line__c siLineCM = new Supplier_Invoice_Line__c();
	       	siLineCM.Supplier_Invoice__c = CreditMemoInvoice1.Id;
	        siLineCM.Invoice_Quantity__c = 1;
	        siLineCM.Unit_Price__c = -100;//KNDY-14371
	        siLineCM.Description__c = 'test';
	        insert siLineCM;
	        
	        CreditMemoInvoice1.Status__c = 'Approved';
	        CreditMemoInvoice1.Transaction_Date__c = system.now();
	        update CreditMemoInvoice1;
		}

        
        Set<Id> supSetToPass = new Set<Id>{remitToSupp2.id,testdata.fuel.remittosupplier.id};

        List<Supplier_Invoice__c> supplierInvoiceList = [select id from supplier_Invoice__c where Supplier__c IN:supSetToPass];
        system.assertEquals(supplierInvoiceList.size() ,10,'total SI mismatch ' + supplierInvoiceList);
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        system.assertEquals(invoiceRecordsFromUI.size() ,8,'total SI mismatch ' + invoiceRecordsFromUI.size());        
        PaymentBatchExt.createSPaymentBatch(newFilters,invoiceRecordsFromUI);
        
        Test.stopTest();
        Bank_Account__c bankAcc = [select id,Use_Pre_Printed_Check_Stock__c,Number_of_Advice_Lines_Per_Page__c from Bank_Account__c where id =: ba.id];
        system.assertEquals(bankAcc.Use_Pre_Printed_Check_Stock__c, true, bankAcc);
        Set<Id> spIds = new Set<Id>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        system.debug('Remit To Supplier1=' + testdata.fuel.remittosupplier.id);
        system.debug('Remit To Supplier2=' + remitToSupp2.id);
        List<Supplier_Payment__c> sps = [select id, status__c,Status_Reason__c, Transaction_Date__c, Payment_Amount__c,Supplier__c from Supplier_Payment__c where Supplier__c IN:supSetToPass];
        system.assertEquals(sps.size(), 8, 'Incorrent number of SPs created: spIds - ' + sps);
        // supplier lines for remit to supplier1
        List<Supplier_Payment_Line__c> splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Payment__r.Supplier__c =:testData.fuel.remittosupplier.id];
        system.assert(splines.size() == 6, 'Found incorrect Payment lines tied to invoices: ' + splines.size());
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
        }
         system.assertEquals(spIds.size(), 3, 'Incorrent number of SPs created: spIds - ' + spIds);       
        // supplier lines for remit to supplier2
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Payment__r.Supplier__c =:remitToSupp2.id];
        system.assert(splines.size() == 7, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
        }
        
        system.assertEquals(spIds.size(), 5, 'Incorrent number of SPs created: spIds - ' + spIds);             
    }
    
    //PTP-363
     static testMethod void testPymtBatchWithCM_HappyPathScenario(){
    	PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(testData.fuel.remittosupplier.id);
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c'){
            	if(fd.field == 'Payment_Method_G__c')
            	{
            		filter1 = new KendoUtils.FilterDescriptor();
	                filter1.field = 'Payment_Method_G__c';
	                filter1.fieldType = 'string';
	                filter1.operator = 'eq';
	                filter1.value = 'Online';
	                newFilters.add(filter1);
            	}else	
                	newFilters.add(fd);
            }
            else {
                filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supSetToPass);
                newFilters.add(filter1);
            }
        }
        
        Supplier_Invoice__c CreditMemoInvoice = new Supplier_Invoice__c();{
			CreditMemoInvoice.Invoice_Type__c = 'Credit Memo';
	    	CreditMemoInvoice.Company__c = testData.fuel.company.Id;
	        CreditMemoInvoice.Supplier__c = testData.fuel.remittosupplier.id;
	        CreditMemoInvoice.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			CreditMemoInvoice.Date_Invoiced__c = system.now();
	        CreditMemoInvoice.Supplier_Invoice__c = 'test101b';
	        CreditMemoInvoice.Supplier_and_Invoice__c = 'test 101b';
	        CreditMemoInvoice.Payment_Term__c = testData.paymentTermInfo.id;
	        CreditMemoInvoice.Payment_Method_G__c = 'Online';
	        CreditMemoInvoice.Invoice_Amount__c = -10;
	        CreditMemoInvoice.Credit_Memo_Amount__c = -10;
	        CreditMemoInvoice.Credit_Memo_Balance__c = -10;
	        insert CreditMemoInvoice;
	        
	        Supplier_Invoice_Line__c siLineCM = new Supplier_Invoice_Line__c();
	       	siLineCM.Supplier_Invoice__c = CreditMemoInvoice.Id;
	        siLineCM.Invoice_Quantity__c = 1;
	        siLineCM.Unit_Price__c = -10;//KNDY-14371
	        siLineCM.Description__c = 'test';
	        insert siLineCM;
	        
	        CreditMemoInvoice.Status__c = 'Approved';
	        CreditMemoInvoice.Transaction_Date__c = system.now();
	        update CreditMemoInvoice;
		}
		siSetToTest.add(CreditMemoInvoice.id);
		Supplier_Invoice__c CMInv = [select id, name, Credit_Memo_Balance__c, Status__c from Supplier_Invoice__c where id = :CreditMemoInvoice.id];
		system.debug(LoggingLevel.ERROR,'CM queried back: ' + CMInv);
		system.assert(CMInv.Credit_Memo_Balance__c < 0, 'Credit Memo balance is wrong: ' + CMInv.Credit_Memo_Balance__c);
        
        //KNDY-17277 - discount earned deprecated
        si = [select id, name, Discount_Date__c, Discount_Taken__c, Status__c from Supplier_Invoice__c where id =:testData.matchToPOSupplierInvoice.id];        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c =:si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){        
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned;       
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        system.assert(scopeSupInvIdsToPay.size()== 2, 'Scope of invoices' + scopeSupInvIdsToPay);
        PaymentBatch jpBatch = new PaymentBatch( newFilters, scopeSupInvIdsToPay, supSetToPass);
        Test.startTest();
        jpBatch.runBatch(null);
        Test.stopTest();
        
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where supplier_invoice__c =:CMInv.id];
        system.assert(splines.size() == 1, 'Found more than three Payment lines tied to invoice or CM: ' + splines);
        
        List<Supplier_Payment__c> sp = [select id, status__c, Transaction_Date__c, Payment_Amount__c,Finalized__c from Supplier_Payment__c where id = :splines[0].supplier_Payment__c];
        system.assert(sp.size() == 1, 'Multiple Supplier Payments were created: ' + sp.size());
        system.assert(sp[0].status__c == 'Applied', 'Supplier Payment status is not correct: ' + sp[0].status__c);
        system.assert(sp[0].Finalized__c == true, 'Supplier Payment finalized status is not correct: ' + sp[0].Finalized__c);
        system.assert(sp[0].Payment_Amount__c == 980, 'Supplier Payment amount is not correct: ' + sp[0].Payment_Amount__c);
        system.assert(sp[0].Transaction_Date__c != null); //KNDY-10280 KNDY-12343
        
        for (Supplier_Payment_Line__c spl: splines){
        	if (spl.type__c =='Payment')
        		system.assert(spl.amount__c == 990,'Payment amount is not right: ' + spl.amount__c);
        	else if (spl.type__c ==PaymentService.TYPE_EARNED_DISCOUNT)
        		system.assert(spl.amount__c == 10,'Discount amount is not right: ' + spl.amount__c);
        	else if (spl.type__c =='Credit Memo')
        		system.assert(spl.amount__c == -10,'Credit Memo amount is not right: ' + spl.amount__c);	
        		
        }
        //KNDY-17277 - discount earned deprecated
        si = [select id, name, Discount_Date__c, Discount_Taken__c, Status__c from Supplier_Invoice__c where id =:testData.NonPOInvoicePymtMethod.id];
        system.assert(si.Discount_Taken__c == 10, 'Discount Taken is not right: ' + si.Discount_Taken__c);
        system.assert(si.Status__c == 'Closed', 'Supplier invoice is not closed: ' + si.Status__c);
        
        si = [select id, name, Credit_Memo_Balance__c, Status__c from Supplier_Invoice__c where id =:CreditMemoInvoice.id];
        system.assert(si.Credit_Memo_Balance__c == 0, 'Credit consumed is not right: ' + si.Credit_Memo_Balance__c);
        system.assert(si.Status__c == 'Closed', 'Credit Memo is not closed: ' + si.Status__c);
    }
    
    //PTP-624 
    static testMethod void testPaymentAmtTakesDiscountIntoConsideration(){
    	PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	Supplier_Invoice__c si = testData.NonPOInvoice;
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(testData.fuel.remittosupplier.id);
        //KNDY-17277 - discount earned deprecated
        si = [select id, name, Discount_Date__c, Discount_Taken__c, Status__c from Supplier_Invoice__c where id =:testData.NonPOInvoice.id];        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c =:si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(testData.filters,testData.supplierInvoicePreviewConfig);
        
        Test.startTest();
		system.assertEquals(invoiceRecordsFromUI.size() ,4,'total SI mismatch' + invoiceRecordsFromUI);        
		PaymentBatchExt.createSPaymentBatch(testData.filters,invoiceRecordsFromUI);
        Test.stopTest();
        
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where supplier_invoice__c =:si.id];
        system.assert(splines.size() == 2, 'Found more than two Payment lines tied to invoice: ' + splines);
        List<Supplier_Payment__c> sp = [select id, status__c, Payment_Amount__c from Supplier_Payment__c where id = :splines[0].supplier_Payment__c];
        system.assert(sp.size() == 1, 'Multiple Supplier Payments were created: ' + sp.size());
        system.assert(sp[0].status__c == 'Applied', 'Supplier Payment status is not correct: ' + sp[0].status__c);
        system.assert(sp[0].Payment_Amount__c == 1980, 'Supplier Payment amount is not correct: ' + sp[0].Payment_Amount__c);
        
        for (Supplier_Payment_Line__c spl: splines){
        	if (spl.type__c =='Payment')
        		system.assert(spl.amount__c == 990,'Payment amount is not right: ' + spl.amount__c);
        	else if (spl.type__c ==PaymentService.TYPE_EARNED_DISCOUNT)
        		system.assert(spl.amount__c == 10,'Discount amount is not right: ' + spl.amount__c);
        		 
        }
        //KNDY-17277 - discount earned deprecated
        si = [select id, name, Discount_Date__c, Discount_Taken__c, Status__c from Supplier_Invoice__c where id =:testData.NonPOInvoice.id];
        system.assert(si.Discount_Taken__c == 10, 'Discount Taken is not right: ' + si.Discount_Taken__c);
        system.assert(si.Status__c == 'Closed', 'Supplier invoice is not closed: ' + si.Status__c);
    }

    static testMethod void testPymtBatchWithCreditsEqualsDebits_CM_CancelSPs(){
    	Test.startTest();
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(testData.fuel.remittosupplier.id);
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if(fd.field != 'Payment_Method_G__c')
            	newFilters.add(fd);            
            else {
            		filter1 = new KendoUtils.FilterDescriptor();
	                filter1.field = 'Payment_Method_G__c';
	                filter1.fieldType = 'string';
	                filter1.operator = 'eq';
	                filter1.value = 'Online';
	                newFilters.add(filter1);
            	}
        }
        
        Supplier_Invoice__c CreditMemoInvoice = testData.createSI('Credit Memo',-990.00, 'testCMabc', 'Online', testData.fuel.company, testData.fuel.remittosupplier);
        CreditMemoInvoice.Credit_Memo_Balance__c = -990; // si amount - earned discount
        CreditMemoInvoice.Credit_Memo_Amount__c = -990;
        insert CreditMemoInvoice;
        Supplier_Invoice_Line__c siLineCM = testData.createSILine(1, -990.00 , CreditMemoInvoice, null, testData.purchasedItem.Id);
        insert siLineCM;
            
        CreditMemoInvoice.Status__c = 'Approved';
        update CreditMemoInvoice;

        // KNDY-13532 add CM to set of selected invoices
        siSetToTest.add(CreditMemoInvoice.id);
        
        Map<Id, Supplier_Invoice__c> siMap = new Map<Id, Supplier_Invoice__c>([select id, name, Credit_Memo_Balance__c, 
                            Balance_Due__c, Status__c 
                            from Supplier_Invoice__c where 
                            id in :siSetToTest]);
        Supplier_Invoice__c CMInv = siMap.get(CreditMemoInvoice.id);
        system.assertEquals(CMInv.Credit_Memo_Balance__c , -990, 'Credit Memo balance is wrong: ' + CMInv.Credit_Memo_Balance__c);
        Supplier_Invoice__c INVsi = siMap.get(si.id);
        system.assertEquals(INVsi.Balance_Due__c, 1000, 'Invoice Balance Due is wrong: ' + INVsi);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c =:si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);

        PaymentBatchExt.createSPaymentBatch(newFilters,invoiceRecordsFromUI);
        Test.stopTest();

        List<Supplier_Payment__c> sp = [select id, status__c, Payment_Amount__c,Status_Reason__c from Supplier_Payment__c where Supplier__c IN  :supSetToPass];
        system.assert(sp.size() == 1, 'Multiple Supplier Payments were created: ' + sp);
        system.assert(sp[0].Status__c == PaymentService.STATUS_CANCELLED, 'Multiple Supplier Payments were created with cancelled status: ' + sp);
        system.assert(sp[0].Status_Reason__c == PaymentService.STATUS_REASON_ZERO_AMT_PAYMENT_NOT_ALLOWED, 'Multiple Supplier Payments were created with status reason of zero payment not allowed : ' + sp);
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where Supplier_Payment__c =: sp[0].id];
        system.assert(splines.size() == 3, 'Payment Lines were created: ' + splines);
        
        //check supplier invoice. status would remain same
        List<Supplier_Invoice__c > siList = new List<Supplier_Invoice__c>();
        siList = [select id, name, Discount_Date__c, Discount_Taken__c, Status__c,Amount_Paid__c,Balance_Due__c from Supplier_Invoice__c where id =:si.id];
        si = siList[0];
        system.assert(si.Discount_Taken__c == 0, 'Discount Taken is not right: ' + si.Discount_Taken__c);
        system.assert(si.Amount_Paid__c == null, 'Amount Paid is not right: ' + si.Amount_Paid__c);
        system.assert(si.Balance_Due__c == 1000, 'Balance due is not right: ' + si.Balance_Due__c);
        system.assert(si.Status__c == 'Approved', 'Supplier invoice is not closed: ' + si.Status__c);
        
        siList = [select id, name, Discount_Date__c, Discount_Taken__c, Status__c,Amount_Paid__c,Credit_Memo_Balance__c from Supplier_Invoice__c where id =:CMInv.id]; 
        si = siList[0];      
        system.assert(si.Credit_Memo_Balance__c == -990, 'Credit Memo balance is not right: ' + si.Credit_Memo_Balance__c);
        system.assert(si.Status__c == 'Approved', 'Supplier invoice is not closed: ' + si.Status__c);
        
    }
    static testMethod void testPymtBatchWithCreditsEqualsDebits_Prepay_CancelSPs(){
    	Test.startTest();
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Supplier_Invoice__c si = testData.ACHSupplierInvoice;
        Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(testData.fuel.remittosupplier.id);
        
        //KNDY-17277 - discount earned deprecated
        si = [select id, name, Invoice_Amount__c, Discount_Date__c, Discount_Taken__c, Status__c from Supplier_Invoice__c where id =:testData.ACHSupplierInvoice.id];
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c =:si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        for (KendoUtils.FilterDescriptor fdSet: testData.filters){
        	if (fdSet.field == 'Payment_Method_G__c')
        		fdSet.value = 'ACH';
        }
        
        Supplier_Invoice__c prepaymentSI = testData.createSI('Prepayment',990, 'testCMabc', 'ACH', testData.fuel.company, testData.fuel.remittosupplier);
        prepaymentSI.Credit_Memo_Balance__c = -990;
        prepaymentSI.Credit_Memo_Amount__c = -990;
        insert prepaymentSI;
        Supplier_Invoice_Line__c siLine = testData.createSILine(1, 990, prepaymentSI, null, testData.purchasedItem.Id);
        insert siLine;
	    prepaymentSI.Status__c = PaymentService.STATUS_APPROVED;
	    update prepaymentSI;
	    
		siSetToTest.add(prepaymentSI.id);
		Supplier__c supplier = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :testData.fuel.remittosupplier.id];
        List<Supplier_Invoice__c > siList = new List<Supplier_Invoice__c>();
        //pay out prepayment
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(testData.filters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_PREPAYMENT){
	        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
	        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
	        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
	        	ID sID = siWrapper.invoiceRecord.id;
	        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
	        	scopeSupInvIdsToPay.put(sID,siWrapper);
        	}
        } 
        system.assertEquals(scopeSupInvIdsToPay.size() ,1,'Wrong number of scope of invoices found : '+ scopeSupInvIdsToPay);
        SupplierPaymentService spService = new SupplierPaymentService();
		
        List<SupplierPaymentService.invoicePaymentWrapper>  payWrapper= spService.processPayments( testData.filters, scopeSupInvIdsToPay,new List<Supplier_Invoice__c>{prepaymentSI}, new List<Supplier__c>{supplier}, null);
        system.debug(LoggingLevel.Error,'test method paywrapper : '+payWrapper[0].paymentWrapperList);
		
		List<Supplier_Payment__c> sps = new List<Supplier_Payment__c>();
		splines = new List<Supplier_Payment_Line__c>();
		List<string> spIdsList = new List<String>();
		for (SupplierPaymentService.paymentWithLinesWrapper paylineWrapper :payWrapper[0].paymentWrapperList){
			sps.add(paylineWrapper.supplierPayment);
			spIdsList.add(paylineWrapper.supplierPayment.id);
			splines.addAll(paylineWrapper.lstPaymentLines);
		}
		List<SupplierPaymentService.paymentWithLinesWrapper> paymentWrapperList = spService.CreateFinalizePaymentsForImmediate(false,testData.supplierPaymentMasterPreviewConfig,sps,splines); 
		//KNDY-19040 update invoices
		PaymentBatchExt.updateSupplierInoiceForFinalizedPayments(New List<String> {prepaymentSI.Id},spIdsList);
		 
        siList = [select id, name, Discount_Date__c, Status__c,Credit_Memo_Balance__c,Invoice_Type__c,Credit_Memo_Amount__c,Amount_Paid__c,Balance_Due__c from Supplier_Invoice__c where id =:prepaymentSI.id]; 
        si = siList[0];
        system.assert(si.Status__c == 'Closed', 'Supplier invoice is not closed: ' + si);
        
        invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(testData.filters,testData.supplierInvoicePreviewConfig);
        PaymentBatchExt.createSPaymentBatch(testData.filters,invoiceRecordsFromUI);
        Test.stopTest();
     
        List<Supplier_Payment__c> sp = [select id, status__c, Payment_Amount__c,Status_Reason__c,Total_Number_Of_Lines__c from Supplier_Payment__c where Supplier__c IN  :supSetToPass];
        system.assert(sp.size() == 2, 'Multiple Supplier Payments were created: ' + sp);
        boolean cancelledSPFound = false;
        id cancelledSPID = null;
        for (Supplier_Payment__c payment :sp){
        	if (payment.Status__c == PaymentService.STATUS_CANCELLED)
        	{
        		cancelledSPFound = true;
        		cancelledSPID = payment.id;
        		system.assert(payment.Total_Number_Of_Lines__c == 3, 'wrong Payment Lines were created: ' + payment.Total_Number_Of_Lines__c);
        		system.assert(payment.Status__c == PaymentService.STATUS_CANCELLED, 'Multiple Supplier Payments were created with cancelled status: ' + payment);
        		system.assert(payment.Status_Reason__c == PaymentService.STATUS_REASON_ZERO_AMT_PAYMENT_NOT_ALLOWED, 'Multiple Supplier Payments were created with status reason of zero payment not allowed : ' + payment);
        	}
        }
        system.assertEquals(cancelledSPFound,true,'no cancelled sps found' +sp );
       
        //check supplier invoice. status would remain same
        
        siList = [select id, name, Discount_Date__c, Discount_Taken__c, Status__c,Amount_Paid__c,Balance_Due__c from Supplier_Invoice__c where id =:testData.ACHSupplierInvoice.id];
        si = siList[0];
        system.assert(si.Discount_Taken__c == 0, 'Discount Taken is not right: ' + si.Discount_Taken__c);        
        system.assert(si.Balance_Due__c == 1000, 'Balance due is not right: ' + si);
        system.assert(si.Status__c == 'Approved', 'Supplier invoice is not closed: ' + si.Status__c);
        
        siList = [select id, name, Discount_Date__c, Status__c,Credit_Memo_Balance__c,Invoice_Type__c,Credit_Memo_Amount__c,Amount_Paid__c,Balance_Due__c from Supplier_Invoice__c where id =:prepaymentSI.id]; 
        si = siList[0];      
        system.assert(si.Credit_Memo_Balance__c == -990, 'Credit Memo balance is not right: ' + si);
        system.assert(si.Status__c == 'Closed', 'Supplier invoice is not closed: ' + si);
    }
   
    
    static testMethod void testNegativeAmount_DontPaySIWithDiscountEarned_CM(){
    	Test.startTest();
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Supplier_Invoice__c si = testData.ACHSupplierInvoice;
        Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(testData.fuel.remittosupplier.id);            
        
        //KNDY-17277 - discount earned deprecated
        si = [select id, name, Invoice_Amount__c, Discount_Date__c, Discount_Taken__c, Status__c from Supplier_Invoice__c where id =:testData.ACHSupplierInvoice.id];
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c =:si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        for (KendoUtils.FilterDescriptor fdSet: testData.filters){
        	if (fdSet.field == 'Payment_Method_G__c')
        		fdSet.value = 'ACH';
        }
        
        Supplier_Invoice__c CreditMemoInvoice = testData.createSI('Credit Memo',-2500, 'testCMabc', 'ACH', testData.fuel.company, testData.fuel.remittosupplier);
        CreditMemoInvoice.Credit_Memo_Balance__c = -2500;
        CreditMemoInvoice.Credit_Memo_Amount__c = -2500;
        insert CreditMemoInvoice;
        Supplier_Invoice_Line__c siLine = testData.createSILine(1, -2500, CreditMemoInvoice, null, testData.purchasedItem.Id);
        insert siLine;
        CreditMemoInvoice.Status__c = 'Approved';
        CreditMemoInvoice.Transaction_Date__c = system.now();
        update CreditMemoInvoice;
        system.debug(LoggingLevel.ERROR,'CM queried back: ' + CreditMemoInvoice);
		siSetToTest.add(CreditMemoInvoice.id);
		Supplier_Invoice__c CMInv = [select id, name, Credit_Memo_Balance__c, Status__c from Supplier_Invoice__c where id = :CreditMemoInvoice.id];
		system.debug(LoggingLevel.ERROR,'CM queried back: ' + CMInv);
		system.assert(CMInv.Credit_Memo_Balance__c < 0, 'Credit Memo balance is wrong: ' + CMInv.Credit_Memo_Balance__c);
        
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(testData.filters,testData.supplierInvoicePreviewConfig);

        system.assert(invoiceRecordsFromUI.size() ==2,'Scope of invoices found incorrect' + invoiceRecordsFromUI);
        PaymentBatchExt.createSPaymentBatch(testData.filters,invoiceRecordsFromUI);
       	Test.stopTest();
        List<Supplier_Payment__c> sp = [select id, status__c, Payment_Amount__c,Status_Reason__c from Supplier_Payment__c where Supplier__c IN  :supSetToPass];
        system.assert(sp.size() == 1, 'Multiple Supplier Payments were created: ' + sp);
        system.assert(sp[0].Status__c == PaymentService.STATUS_CANCELLED, 'Multiple Supplier Payments were created with cancelled status: ' + sp);
        system.assert(sp[0].Status_Reason__c == PaymentService.STATUS_REASON_ZERO_AMT_PAYMENT_NOT_ALLOWED, 'Multiple Supplier Payments were created with status reason of zero payment not allowed : ' + sp);
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where Supplier_Payment__c =: sp[0].id];
        system.assert(splines.size() == 3, 'Payment Lines were created: ' + splines);
        
        //check supplier invoice. status would remain same
        List<Supplier_Invoice__c > siList = new List<Supplier_Invoice__c>();
        siList = [select id, name, Discount_Date__c, Discount_Taken__c, Status__c,Amount_Paid__c,Balance_Due__c from Supplier_Invoice__c where id =:si.id];
        si = siList[0];
        system.assert(si.Discount_Taken__c == 0, 'Discount Taken is not right: ' + si.Discount_Taken__c);       
        system.assert(si.Balance_Due__c == 1000, 'Balance due is not right: ' + si.Balance_Due__c);
        system.assert(si.Status__c == 'Approved', 'Supplier invoice is not closed: ' + si.Status__c);
        
        siList = [select id, name, Discount_Date__c, Status__c,Credit_Memo_Balance__c,Invoice_Type__c,Credit_Memo_Amount__c from Supplier_Invoice__c where id =:CMInv.id]; 
        si = siList[0];      
        system.assert(si.Credit_Memo_Balance__c == -2500, 'Credit Memo balance is not right: ' + si );
        system.assert(si.Status__c == 'Approved', 'Supplier invoice is not closed: ' + si.Status__c);
        
    }
    
    static testMethod void testNegativeAmount_DontPaySIWithDiscountEarned_PP(){
    	Test.startTest();
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Supplier_Invoice__c si = testData.ACHSupplierInvoice;
        Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(testData.fuel.remittosupplier.id);
        
        //KNDY-17277 - discount earned deprecated
        si = [select id, name, Invoice_Amount__c, Discount_Date__c, Discount_Taken__c, Status__c from Supplier_Invoice__c where id =:testData.ACHSupplierInvoice.id];
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c =:si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        for (KendoUtils.FilterDescriptor fdSet: testData.filters){
        	if (fdSet.field == 'Payment_Method_G__c')
        		fdSet.value = 'ACH';
        }
        
        Supplier_Invoice__c prepaymentSI = testData.createSI('Prepayment',2500, 'testCMabc', 'ACH', testData.fuel.company, testData.fuel.remittosupplier);
        prepaymentSI.Credit_Memo_Balance__c = -2500;
        prepaymentSI.Credit_Memo_Amount__c = -2500;
        insert prepaymentSI;
        Supplier_Invoice_Line__c siLine = testData.createSILine(1, 2500, prepaymentSI, null, testData.purchasedItem.Id);
        insert siLine;
	    prepaymentSI.Status__c = PaymentService.STATUS_APPROVED;
	    //prepaymentSI.Amount_Paid__c = 2500;
	    update prepaymentSI;
	    
		siSetToTest.add(prepaymentSI.id);
		Supplier__c supplier = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :testData.fuel.remittosupplier.id];
        List<Supplier_Invoice__c > siList = new List<Supplier_Invoice__c>();
        //pay out prepayment
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(testData.filters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_PREPAYMENT){
	        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
	        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
	        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
	        	ID sID = siWrapper.invoiceRecord.id;
	        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
	        	scopeSupInvIdsToPay.put(sID,siWrapper);
        	}
        } 
        system.assertEquals(scopeSupInvIdsToPay.size() ,1,'Wrong number of scope of invoices found : '+ scopeSupInvIdsToPay);
        SupplierPaymentService spService = new SupplierPaymentService();
        List<SupplierPaymentService.invoicePaymentWrapper>  payWrapper= spService.processPayments( testData.filters, scopeSupInvIdsToPay,new List<Supplier_Invoice__c>{prepaymentSI}, new List<Supplier__c>{supplier}, null);        
        system.debug(LoggingLevel.Error,'test method paywrapper : '+payWrapper[0].paymentWrapperList);
		
		List<Supplier_Payment__c> sps = new List<Supplier_Payment__c>();
		splines = new List<Supplier_Payment_Line__c>();
		List<String> spIdsList = new List<String>();
		for (SupplierPaymentService.paymentWithLinesWrapper paylineWrapper :payWrapper[0].paymentWrapperList){
			sps.add(paylineWrapper.supplierPayment);
			spIdsList.add(paylineWrapper.supplierPayment.id);
			splines.addAll(paylineWrapper.lstPaymentLines);
		}
		List<SupplierPaymentService.paymentWithLinesWrapper> paymentWrapperList = spService.CreateFinalizePaymentsForImmediate(false,testData.supplierPaymentMasterPreviewConfig,sps,splines); 
		//KNDY-19040 update invoices
		PaymentBatchExt.updateSupplierInoiceForFinalizedPayments(New List<String> {prepaymentSI.Id},spIdsList);
		
        siList = [select id, name, Discount_Date__c, Status__c,Credit_Memo_Balance__c,Invoice_Type__c,Credit_Memo_Amount__c,Amount_Paid__c,Balance_Due__c from Supplier_Invoice__c where id =:prepaymentSI.id]; 
        si = siList[0];
        system.assert(si.Status__c == 'Closed', 'Supplier invoice is not closed: ' + si);
        
        invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(testData.filters,testData.supplierInvoicePreviewConfig);

        PaymentBatchExt.createSPaymentBatch(testData.filters,invoiceRecordsFromUI);
        Test.stopTest();     
        List<Supplier_Payment__c> sp = [select id, status__c, Payment_Amount__c,Status_Reason__c,Total_Number_Of_Lines__c from Supplier_Payment__c where Supplier__c IN  :supSetToPass];
        system.assert(sp.size() == 2, 'Multiple Supplier Payments were created: ' + sp);
        boolean cancelledSPFound = false;
        id cancelledSPID = null;
        for (Supplier_Payment__c payment :sp){
        	if (payment.Status__c == PaymentService.STATUS_CANCELLED)
        	{
        		cancelledSPFound = true;
        		cancelledSPID = payment.id;
        		system.assert(payment.Total_Number_Of_Lines__c == 3, 'wrong Payment Lines were created: ' + payment.Total_Number_Of_Lines__c);
        		system.assert(payment.Status__c == PaymentService.STATUS_CANCELLED, 'Multiple Supplier Payments were created with cancelled status: ' + payment);
        		system.assert(payment.Status_Reason__c == PaymentService.STATUS_REASON_ZERO_AMT_PAYMENT_NOT_ALLOWED, 'Multiple Supplier Payments were created with status reason of zero payment not allowed : ' + payment);
        	}
        }
        system.assertEquals(cancelledSPFound,true,'no cancelled sps found' +sp );
       
        //check supplier invoice. status would remain same        
        siList = [select id, name, Discount_Date__c, Discount_Taken__c, Status__c,Amount_Paid__c,Balance_Due__c from Supplier_Invoice__c where id =:testData.ACHSupplierInvoice.id];
        si = siList[0];
        system.assert(si.Discount_Taken__c == 0, 'Discount Taken is not right: ' + si.Discount_Taken__c);        
        system.assert(si.Balance_Due__c == 1000, 'Balance due is not right: ' + si);
        system.assert(si.Status__c == 'Approved', 'Supplier invoice is not closed: ' + si.Status__c);
        
        siList = [select id, name, Discount_Date__c, Status__c,Credit_Memo_Balance__c,Invoice_Type__c,Credit_Memo_Amount__c,Amount_Paid__c,Balance_Due__c from Supplier_Invoice__c where id =:prepaymentSI.id]; 
        si = siList[0];      
        system.assert(si.Credit_Memo_Balance__c == -2500, 'Credit Memo balance is not right: ' + si);
        system.assert(si.Status__c == 'Closed', 'Supplier invoice is not closed: ' + si);
    }
    
    static testMethod void testPymtBatch_CMOnly_DontPayOut(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Set<Id> siSetToTest = new Set<Id>();

        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(testData.fuel.remittosupplier.id);
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if(fd.field != 'Payment_Method_G__c')
            	newFilters.add(fd);            
            else {
            		filter1 = new KendoUtils.FilterDescriptor();
	                filter1.field = 'Payment_Method_G__c';
	                filter1.fieldType = 'string';
	                filter1.operator = 'eq';
	                filter1.value = 'Credit Card';
	                newFilters.add(filter1);
            	}
        }
        Supplier_Invoice__c CreditMemoInvoice = testData.createSI('Credit Memo' ,-1000.00, 'testCMabc', 'Credit Card', testData.fuel.company, testData.fuel.remittosupplier);
        CreditMemoInvoice.Credit_Memo_Balance__c = -1000;
        CreditMemoInvoice.Credit_Memo_Amount__c = -1000;
        insert CreditMemoInvoice;
        Supplier_Invoice_Line__c siLineCM = testData.createSILine(1, -1000.00, CreditMemoInvoice, null, testData.purchasedItem.Id);
        insert siLineCM;
            
        CreditMemoInvoice.Status__c = 'Approved';
        CreditMemoInvoice.Transaction_Date__c = system.now();
        update CreditMemoInvoice;

        // KNDY-13532 add CM to set of selected invoices
        siSetToTest.add(CreditMemoInvoice.id);
        
        Supplier_Invoice__c CMInv = [select id, name, Credit_Memo_Balance__c, Status__c from Supplier_Invoice__c where id = :CreditMemoInvoice.id];
        system.debug(LoggingLevel.ERROR,'CM queried back: ' + CMInv);
        system.assert(CMInv.Credit_Memo_Balance__c < 0, 'Credit Memo balance is wrong: ' + CMInv.Credit_Memo_Balance__c);
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        
         Test.startTest();
        system.assertEquals(invoiceRecordsFromUI.size() ,1,'total SI mismatch' + invoiceRecordsFromUI);        
    	JSONResult jsResult = PaymentBatchExt.createSPaymentBatch(newFilters,invoiceRecordsFromUI);
        Test.stopTest();
   		system.assert(jsResult.success == false,'Error occurred in batch'+jsResult );
   		system.assert(jsResult.messages.size() > 0,'Error occurred in batch'+jsResult );
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jsResult.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.Only_invoices_with_credit_balances_selected_negative_payment_cannot_be_issued)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
        }
        system.assert(ErrorExists, 'Exception not thrown: '+jsResult);
        
        
        List<Supplier_Payment_Line__c>splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where supplier_invoice__c =:CMInv.id];
        system.assert(splines.size() == 0, 'Payment Lines were created: ' + splines.size());
        
    }
    
     //PTP-564
    static testMethod void testPymtBatchWithCreditsGreaterThanDebits_PayOut(){
    	PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	Supplier_Invoice__c si = testData.NonPOInvoicePymtMethod;
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(testData.fuel.remittosupplier.id);
        
        Supplier_Invoice__c CreditMemoInvoice = new Supplier_Invoice__c();{
			CreditMemoInvoice.Invoice_Type__c = 'Credit Memo';
	    	CreditMemoInvoice.Company__c = testData.fuel.company.Id;
	        CreditMemoInvoice.Supplier__c = testData.fuel.remittosupplier.id;
	        CreditMemoInvoice.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			CreditMemoInvoice.Date_Invoiced__c = system.now();
	        CreditMemoInvoice.Supplier_Invoice__c = 'test101b';
	        CreditMemoInvoice.Supplier_and_Invoice__c = 'test 101b';
	        CreditMemoInvoice.Payment_Term__c = testData.paymentTermInfo.id;
	        CreditMemoInvoice.Payment_Method_G__c ='Online';
	        CreditMemoInvoice.Invoice_Amount__c = -10000;
	        CreditMemoInvoice.Credit_Memo_Balance__c = -10000;
	        CreditMemoInvoice.Credit_Memo_Amount__c = -10000;
	        insert CreditMemoInvoice;
	        
	        Supplier_Invoice_Line__c siLineCM = new Supplier_Invoice_Line__c();
	       	siLineCM.Supplier_Invoice__c = CreditMemoInvoice.Id;
	        siLineCM.Invoice_Quantity__c = 1;
	        siLineCM.Unit_Price__c = -10000;//KNDY-14371
	        siLineCM.Description__c = 'test';
	        insert siLineCM;
	        
	        CreditMemoInvoice.Status__c = 'Approved';
	        CreditMemoInvoice.Transaction_Date__c = system.now();
	        update CreditMemoInvoice;
		}
		
		// KNDY-13532 add CM to set of selected invoices
		siSetToTest.add(CreditMemoInvoice.id);
		
		Supplier_Invoice__c CMInv = [select id, name, Credit_Memo_Balance__c, Status__c from Supplier_Invoice__c where id = :CreditMemoInvoice.id];
		system.debug(LoggingLevel.ERROR,'CM queried back: ' + CMInv);
		system.assert(CMInv.Credit_Memo_Balance__c < 0, 'Credit Memo balance is wrong: ' + CMInv.Credit_Memo_Balance__c);
        
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c =:si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        for (KendoUtils.FilterDescriptor fdSet: testData.filters){
        	if (fdSet.field == 'totalCreditsExceedsDebits')
        		fdSet.value = true;
        	if (fdSet.field == 'Payment_Method_G__c')
        		fdSet.value = 'Online';
        }
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(testData.filters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;        	
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        system.assert(scopeSupInvIdsToPay.size() == 2,'Scope of SI :'+ scopeSupInvIdsToPay);
        try {
	        PaymentBatch jpBatch = new PaymentBatch(testData.filters, scopeSupInvIdsToPay, supSetToPass);
	        Test.startTest();
	        jpBatch.runBatch(null);
	        Test.stopTest();
        }catch (exception ex){
        	system.assert(ex.getMessage().contains('Total credits exceeds debits, input filter set not to pay out'), 'Exception not thrown: '+ ex.getMessage());
        }
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where supplier_invoice__c =:si.id or supplier_invoice__c =:CMInv.id];
        system.assert(splines.size() == 3, 'Payment Lines were created: ' + splines);
        
        List<Supplier_Payment__c> sp = [select id, status__c, Payment_Amount__c from Supplier_Payment__c where id = :splines[0].supplier_Payment__c];
        system.assert(sp.size() == 1, 'Multiple Supplier Payments were created: ' + sp.size());
        system.assert(sp[0].status__c == 'Applied', 'Supplier Payment status is not correct: ' + sp[0].status__c);
        system.assert(sp[0].Payment_Amount__c == 0, 'Supplier Payment amount is not correct: ' + sp[0].Payment_Amount__c);
        
        for (Supplier_Payment_Line__c spl: splines){
        	if (spl.type__c =='Payment')
        		system.assert(spl.amount__c == 990,'Payment amount is not right: ' + spl.amount__c);
        	else if (spl.type__c =='Discount')
        		system.assert(spl.amount__c == 10,'Discount amount is not right: ' + spl.amount__c);
        	else if (spl.type__c =='Credit Memo')
        		system.assert(spl.amount__c == -990,'Credit Memo amount is not right: ' + spl.amount__c);	
        		
        }
        si = [select id, name, Credit_Memo_Balance__c, Status__c from Supplier_Invoice__c where id =:CreditMemoInvoice.id];
        system.assert(si.Credit_Memo_Balance__c == -9010, 'Credit consumed is not right: ' + si.Credit_Memo_Balance__c);
        system.assert(si.Status__c == 'Approved', 'Credit Memo is not approved: ' + si.Status__c);
        
        si = [select id, name, Balance_Due__c, Amount_Paid__c, Status__c from Supplier_Invoice__c where id =:testData.NonPOInvoicePymtMethod.id];
        system.assert(si.Balance_Due__c == 0, 'Balance due is not right: ' + si.Balance_Due__c);
        system.assert(si.Status__c == 'Closed', 'Supplier Invoice is not closed: ' + si.Status__c);
        system.assert(si.Amount_Paid__c == 990.00, 'Supplier Invoice is not fully paid: ' + si.Amount_Paid__c);
    }
    
    //PTP-563
    static testMethod void testPymtBatchWithPayPerInvoice_PayOut(){
    	PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
    	Supplier__c sp = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :testData.fuel.remittosupplier.id];
    	sp.Pay_Per_Invoice__c = true;
    	update sp;
    	
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(testData.matchToPOSupplierInvoice.id);
        siSetToTest.add(testData.NonPOInvoice.id);
        
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(sp.id);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c =:si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(testData.filters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE)   siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        system.assert(scopeSupInvIdsToPay.size()== 4 ,' Scope of invoices does not match' + scopeSupInvIdsToPay);
	    PaymentBatch jpBatch = new PaymentBatch(testData.filters, scopeSupInvIdsToPay, supSetToPass);
        Test.startTest();
        jpBatch.runBatch(null);
        Test.stopTest();
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where supplier_invoice__c =:testData.matchToPOSupplierInvoice.id or supplier_invoice__c =:testData.NonPOInvoice.id];
        
        Set<ID> spHdrIDs = new Set<ID>();
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);
        }
        List<Supplier_Payment__c> spHdrs = [select id, status__c, Payment_Amount__c from Supplier_Payment__c where id IN :spHdrIDs];
        //KNDY-16750 it will not create SP for matchToPOSupplierInvoice SI since it doesn't have payment method
        system.assert(spHdrs.size() == 2, 'Multiple Supplier Payments were created: ' + spHdrs.size());
        
    }
    
    //KNDY-7916
    static testMethod void testORConditionW_DueDateAndPymtDate(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        Test.startTest();
        //KNDY-17277 - discount earned deprecated
        Supplier_Invoice__c si = [select id, Name, Payment_Due_Date__c, Discount_Date__c, status__c from Supplier_Invoice__c where Id = :testData.matchToPOSupplierInvoice.Id];
        system.assert(si.Discount_Date__c == system.today() + 9, 'Discount_Date__c is wrong: ' + si.Discount_Date__c);
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        
        for(KendoUtils.FilterDescriptor fd: testData.filters){
        	if (fd.field != 'Discount_Date__c' && fd.field != 'Payment_Due_Date__c' && fd.field != 'supplierPymtMethodFilter')
        		newFilters.add(fd);
            
            KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter2 = new KendoUtils.FilterDescriptor();
	        DateTime dtpymtdtd = system.today();
	        DateTime dtdisdtd = system.today().addDays(10);
	        
            if (fd.field == 'Payment_Due_Date__c'){
        		filter1.field = 'Payment_Due_Date__c';
	            filter1.fieldType = 'date';
	            filter1.operator = 'lte';
	            filter1.value = dtpymtdtd.format('MM/dd/yyy');
	            newFilters.add(filter1);
	        
            }
        	else if (fd.field == 'Discount_Date__c'){
        		filter2.field = 'Discount_Date__c';
	            filter2.fieldType = 'date';
	            filter2.operator = 'lte';
	            filter2.value = dtdisdtd.format('MM/dd/yyy');
	            newFilters.add(filter2);
        	}
        }
        
        JSONResult result = PaymentBatchExt.getSupplierInvoices(newFilters, testData.supplierInvoicePreviewConfig);
        //KNDY-16750 result would be 0 as SI created without payment method and we tried to search with check payment method
        System.assertEquals(1, result.total, result);
        
        Test.stopTest();        
    }
    
    
    //KNDY-11118 Using Payment Method other than Check
    static testMethod void testPymtBatchWithPaymentMethodOtherThanCheck(){
    	PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	Supplier_Invoice__c si = testData.NonPOInvoicePymtMethod;
    	Supplier__c sp = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :testData.fuel.remittosupplier.id];
    	
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(testData.NonPOInvoicePymtMethod.id);
        
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(sp.id);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c =:si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        
        for(KendoUtils.FilterDescriptor fd: testData.filters){
        	if (fd.field != 'Discount_Date__c' && fd.field != 'Payment_Due_Date__c' && fd.field != 'Payment_Method_G__c')
        		newFilters.add(fd);
            
            KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter2 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter3 = new KendoUtils.FilterDescriptor();
	        DateTime dtpymtdtd = system.today().addDays(40);
	        DateTime dtdisdtd = system.today().addDays(-10);
	        
            if (fd.field == 'Payment_Due_Date__c'){
        		filter1.field = 'Payment_Due_Date__c';
	            filter1.fieldType = 'date';
	            filter1.operator = 'lte';
	            filter1.value = dtpymtdtd.format('MM/dd/yyy');
	            newFilters.add(filter1);
	        
            }
        	else if (fd.field == 'Discount_Date__c'){
        		filter2.field = 'Discount_Date__c';
	            filter2.fieldType = 'date';
	            filter2.operator = 'lte';
	            filter2.value = dtdisdtd.format('MM/dd/yyy');
	            newFilters.add(filter2);
        	}else if (fd.field == 'Payment_Method_G__c'){
        		filter3.field = 'Payment_Method_G__c';
	            filter3.fieldType = 'string';
	        	filter3.operator = 'eq';
	        	filter3.value = 'Online';
	            newFilters.add(filter3);
        	}
        }
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE)  siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        system.assert(scopeSupInvIdsToPay.size()== 1 ,' Scope of invoices does not match' + scopeSupInvIdsToPay);
	    PaymentBatch jpBatch = new PaymentBatch( newFilters, scopeSupInvIdsToPay, supSetToPass);
        Test.startTest();
        jpBatch.runBatch(null);
        Test.stopTest();
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where supplier_invoice__c =:testData.NonPOInvoicePymtMethod.id];
        
        Set<ID> spHdrIDs = new Set<ID>();
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);
        }
        List<Supplier_Payment__c> spHdrs = [select id, status__c, Payment_Amount__c from Supplier_Payment__c where id IN :spHdrIDs];
        system.assert(spHdrs.size() == 1, 'Multiple Supplier Payments were created: ' + spHdrs.size());
        
    }
    
    //KNDY-12336 Prepayments created does not include any discounts, CMs or other pre-payments
    static testMethod void testPymtBatchPrePayments(){
    	PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	 //Create supplier
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2 = testData.fuel.remittosupplier.clone();
        remitToSupp2.Name = 'RemitToSupplier-2';
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = false;
        remitToSupp2.Pay_Per_Invoice__c = false;
        update new List<Supplier__c>{supp2,testData.fuel.remittosupplier};
        
    	Supplier_Invoice__c NonPOPrePymt = new Supplier_Invoice__c();{
			NonPOPrePymt.Invoice_Type__c = 'Prepayment';
	    	NonPOPrePymt.Company__c = testData.fuel.company.Id;
	        NonPOPrePymt.Supplier__c = remitToSupp2.id;
			NonPOPrePymt.Date_Invoiced__c = system.now();
	        NonPOPrePymt.Supplier_Invoice__c = 'test101s';
	        NonPOPrePymt.Supplier_and_Invoice__c = 'test 101s';
	        NonPOPrePymt.Invoice_Amount__c = 10;
	        NonPOPrePymt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
	        NonPOPrePymt.Payment_Method_G__c = 'ACH';
	        NonPOPrePymt.Payment_Term__c = testData.paymentTermInfo.id;
	        NonPOPrePymt.Credit_Memo_Amount__c = -10;
	        NonPOPrePymt.Credit_Memo_Balance__c = -10;
	        insert NonPOPrePymt;
	        
	        Supplier_Invoice_Line__c siLine3 = new Supplier_Invoice_Line__c();
	       	siLine3.Supplier_Invoice__c = NonPOPrePymt.Id;
	        siLine3.Invoice_Quantity__c = 1;
	        siLine3.Unit_Price__c = 10;//KNDY-14371
	        siLine3.Description__c = 'test';
	        insert siLine3;
	        
	        NonPOPrePymt.Status__c = 'Approved';
	        NonPOPrePymt.Transaction_Date__c = system.now();
	        update NonPOPrePymt;
		}
    	Supplier__c sp = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :remitToSupp2.id];
    	
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(NonPOPrePymt.id);
        
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(sp.id);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c = :NonPOPrePymt.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        
        for(KendoUtils.FilterDescriptor fd: testData.filters){
        	if (fd.field != 'Discount_Date__c' && fd.field != 'Payment_Due_Date__c' && fd.field != 'Payment_Method_G__c' && fd.field != 'Supplier__c')
        		newFilters.add(fd);
            
            KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter2 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter3 = new KendoUtils.FilterDescriptor();
	        DateTime dtpymtdtd = system.today().addDays(45);
	        DateTime dtdisdtd = system.today().addDays(-5);
	        
            if (fd.field == 'Payment_Due_Date__c'){
            	filter1 = new KendoUtils.FilterDescriptor();
        		filter1.field = 'Payment_Due_Date__c';
	            filter1.fieldType = 'date';
	            filter1.operator = 'lte';
	            filter1.value = dtpymtdtd.format('MM/dd/yyy');
	            newFilters.add(filter1);
	        
            }
        	else if (fd.field == 'Discount_Date__c'){
        		filter2.field = 'Discount_Date__c';
	            filter2.fieldType = 'date';
	            filter2.operator = 'lte';
	            filter2.value = dtdisdtd.format('MM/dd/yyy');
	            newFilters.add(filter2);
        	}else if (fd.field == 'Payment_Method_G__c'){
        		filter3.field = 'Payment_Method_G__c';
	            filter3.fieldType = 'string';
	        	filter3.operator = 'eq';
	        	filter3.value = 'ACH';
	            newFilters.add(filter3);
        	}else if  (fd.field == 'Supplier__c'){
        		filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supSetToPass);
                newFilters.add(filter1);
        	}
        }
        system.assert(newFilters != null, 'Filters : ' + newFilters);
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE)  siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        system.assert(scopeSupInvIdsToPay.size() ==1,'Scope of SI to be paid out : ' + scopeSupInvIdsToPay);
	    PaymentBatch jpBatch = new PaymentBatch( newFilters, scopeSupInvIdsToPay, supSetToPass);
        Test.startTest();
        jpBatch.runBatch(null);
        Test.stopTest();
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where supplier_invoice__c =:NonPOPrePymt.id];
        system.assert(splines.size() == 1 ,'SP Lines mismatch' + splines);
        Set<ID> spHdrIDs = new Set<ID>();
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);
        }
        List<Supplier_Payment__c> spHdrs = [select id, status__c, Payment_Amount__c, Total_Number_of_Lines__c from Supplier_Payment__c where id IN :spHdrIDs];
        system.assert(spHdrs.size() == 1, 'Multiple Supplier Payments were created: ' + spHdrs.size());
        system.assert(spHdrs[0].Payment_Amount__c == 10, 'Prepymt created for another amount: ' + spHdrs[0]);
        system.assert(spHdrs[0].Total_Number_of_Lines__c == 1, 'Multiple Supplier Payment lines were created: ' + spHdrs[0]);
        //KNDY-17277 - discount earned deprecated
        Supplier_Invoice__c si = [select id,name, Status__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c from Supplier_Invoice__c where ID = :NonPOPrePymt.id];
        system.assert(si.Amount_Paid__c == 10, 'Amount paid not updated on Prepymt SI: ' + si.Amount_Paid__c);
        system.assert(si.Status__c == 'Closed', 'Prepymt SI is not marked as closed: ' + si.Status__c);
        
    }
    
    //KNDY-12336
    static testMethod void testPymtBatchPrePaymentsAppliedToOtherPrepayments(){
    	PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	//Create supplier
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2 = testData.fuel.remittosupplier.clone();
        remitToSupp2.Name = 'RemitToSupplier-2';
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = true;
        remitToSupp2.Pay_Per_Invoice__c = true;
        update new List<Supplier__c>{supp2,testData.fuel.remittosupplier,remitToSupp2};
        
    	Supplier_Invoice__c NonPOPrePymt = new Supplier_Invoice__c();{
			NonPOPrePymt.Invoice_Type__c = 'Prepayment';
	    	NonPOPrePymt.Company__c = testData.fuel.company.Id;
	        NonPOPrePymt.Supplier__c = remitToSupp2.id;
			NonPOPrePymt.Date_Invoiced__c = system.now();
	        NonPOPrePymt.Supplier_Invoice__c = 'test101s';
	        NonPOPrePymt.Supplier_and_Invoice__c = 'test 101s';
	        NonPOPrePymt.Invoice_Amount__c = 10;
	        NonPOPrePymt.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
	        NonPOPrePymt.Payment_Method_G__c = 'ACH';
	        NonPOPrePymt.Payment_Term__c = testData.paymentTermInfo.id;
	        NonPOPrePymt.Credit_Memo_Amount__c = -10;
	        NonPOPrePymt.Credit_Memo_Balance__c = -10;
	        insert NonPOPrePymt;
	        
	        Supplier_Invoice_Line__c siLine3 = new Supplier_Invoice_Line__c();
	       	siLine3.Supplier_Invoice__c = NonPOPrePymt.Id;
	        siLine3.Invoice_Quantity__c = 1;
	        siLine3.Unit_Price__c = 10;//KNDY-14371
	        siLine3.Description__c = 'test';
	        insert siLine3;
	        
	        NonPOPrePymt.Status__c = 'Closed';
	        NonPOPrePymt.Transaction_Date__c = system.now();
	        update NonPOPrePymt;
		}
    	
    	Supplier__c sp = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :remitToSupp2.id];
    	Set<Id> siSetToTest = new Set<Id>();
    
    	Supplier_Invoice__c NonPOPrePymt2 = new Supplier_Invoice__c();{
			NonPOPrePymt2.Invoice_Type__c = 'Prepayment';
	    	NonPOPrePymt2.Company__c = testData.fuel.company.Id;
	        NonPOPrePymt2.Supplier__c = remitToSupp2.id;
			NonPOPrePymt2.Date_Invoiced__c = system.now();
	        NonPOPrePymt2.Supplier_Invoice__c = 'test101u';
	        NonPOPrePymt2.Supplier_and_Invoice__c = 'test 101u';
	        NonPOPrePymt2.Invoice_Amount__c = 100;
	        NonPOPrePymt2.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
	        NonPOPrePymt2.Payment_Term__c = testData.paymentTermInfo.id;
	        NonPOPrePymt2.Payment_Method_G__c = 'ACH';
	        NonPOPrePymt2.Credit_Memo_Amount__c = -100;
	        NonPOPrePymt2.Credit_Memo_Balance__c = -100;
	        insert NonPOPrePymt2;
	        
	        Supplier_Invoice_Line__c siLine3 = new Supplier_Invoice_Line__c();
	       	siLine3.Supplier_Invoice__c = NonPOPrePymt2.Id;
	        siLine3.Invoice_Quantity__c = 1;
	        siLine3.Unit_Price__c = 100;//KNDY-14371
	        siLine3.Description__c = 'test';
	        insert siLine3;
	        
	        NonPOPrePymt2.Status__c = 'Approved';
	        NonPOPrePymt2.Transaction_Date__c = system.now();
	        update NonPOPrePymt2;
		}
		// Approved prepayment and paid out prepayment
		siSetToTest.add(NonPOPrePymt2.id);
		siSetToTest.add(NonPOPrePymt.id);

        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(sp.id);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c =:NonPOPrePymt2.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        Supplier_Invoice__c si = [select Id, Name, Credit_Memo_Balance__c, Credit_Memo_Amount__c, Status__c, Invoice_Type__c, Hold__c from Supplier_Invoice__c where ID =:NonPOPrePymt.id];
        system.assert(si.Status__c == 'Closed', 'Prepaymt 1 is not closed');
        system.assert(si.Credit_Memo_Balance__c == -10, 'Prepaymt 1 Credit Balance is wrong: ' + si.Credit_Memo_Balance__c);
        system.assert(si.Hold__c == false, 'Prepaymt 1 is on hold');
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        
        for(KendoUtils.FilterDescriptor fd: testData.filters){
        	if ( fd.field != 'Payment_Due_Date__c' && fd.field != 'Payment_Method_G__c' && fd.field != 'Supplier__c')//fd.field != 'Discount_Date__c' &&
        		newFilters.add(fd);
            
            KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter2 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter3 = new KendoUtils.FilterDescriptor();
	        DateTime dtpymtdtd = system.today().addDays(45);
	        DateTime dtdisdtd = system.today().addDays(-5);
	        
            if (fd.field == 'Payment_Due_Date__c'){
            	filter1 = new KendoUtils.FilterDescriptor();
        		filter1.field = 'Payment_Due_Date__c';
	            filter1.fieldType = 'date';
	            filter1.operator = 'lte';
	            filter1.value = dtpymtdtd.format('MM/dd/yyy');
	            newFilters.add(filter1);
	        
            }
        	else if (fd.field == 'Discount_Date__c'){
        		filter2.field = 'Discount_Date__c';
	            filter2.fieldType = 'date';
	            filter2.operator = 'lte';
	            filter2.value = dtdisdtd.format('MM/dd/yyy');
	            //newFilters.add(filter2);
        	}else if (fd.field == 'Payment_Method_G__c'){
        		filter3.field = 'Payment_Method_G__c';
	            filter3.fieldType = 'string';
	        	filter3.operator = 'eq';
	        	filter3.value = 'ACH';
	            newFilters.add(filter3);	       
        	}else if (fd.field == 'Supplier__c'){
        		filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supSetToPass);
                newFilters.add(filter1);
        	}
        }
        system.assert(newFilters != null, 'Filters : ' + newFilters);
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        system.assert(scopeSupInvIdsToPay.size() ==2,'Scope of SI to be paid out : ' + scopeSupInvIdsToPay);
	    PaymentBatch jpBatch = new PaymentBatch( newFilters, scopeSupInvIdsToPay, supSetToPass);
        Test.startTest();
        jpBatch.runBatch(null);
        Test.stopTest();
        
        
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where supplier_invoice__c in :siSetToTest];
        system.assert(splines.size() == 1, 'Multiple Supplier Payments were created: ' + splines);
        system.assertEquals(splines[0].Supplier_Invoice__c, NonPOPrePymt2.id, 'SPL created for closed prepayment SI. splines[0]: ' + splines[0]);
        system.assert(splines[0].Amount__c == 100, 'Prepayment2 paid out with wrong amount: ' + splines[0]);
        
        
        Set<ID> spHdrIDs = new Set<ID>();
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);
        }
        List<Supplier_Payment__c> spHdrs = [select id, status__c, Payment_Amount__c, Total_Number_of_Lines__c from Supplier_Payment__c where id IN :spHdrIDs];
        system.assert(spHdrs.size() == 1, 'Multiple Supplier Payments were created: ' + spHdrs.size());
        system.assert(spHdrs[0].Payment_Amount__c == 100, 'Prepymt created for another amount: ' + spHdrs[0]);
        system.assert(spHdrs[0].Total_Number_of_Lines__c == 1, 'Multiple Supplier Payment lines were created: ' + spHdrs[0]);
        
        
    }
       
    
    static testMethod void testPymtBatch_PrepaymentAndSIPayedAtSameTime(){
    	PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	
    	Test.startTest();
    	
    	//creating credit memo
    	 Supplier_Invoice__c cm = new Supplier_Invoice__c();{
			 cm.Invoice_Type__c = 'Credit Memo';
		     cm.Company__c = testData.fuel.company.Id;
		     cm.Supplier__c = testData.fuel.remittosupplier.Id;
		     cm.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			 cm.Date_Invoiced__c = system.now();
		     cm.Supplier_Invoice__c = 'test1';
		     cm.Supplier_and_Invoice__c = 'CM-1231';
		     cm.Payment_Method_G__c = 'ACH';
		     cm.Payment_Term__c = testData.paymentTermInfo.id;
		     cm.Invoice_Amount__c = -520;
		     cm.Credit_Memo_Balance__c = -520;
		     cm.Credit_Memo_Amount__c = -520;
		     insert cm;
		        
		     Supplier_Invoice_Line__c cml = new Supplier_Invoice_Line__c();
		     cml.Supplier_Invoice__c = cm.Id;
		     cml.Invoice_Quantity__c = 1;
		     cml.Unit_Price__c = -520;//KNDY-14371
		     cml.Description__c = 'test';
		     insert cml;
		        
		     cm.Status__c = 'Approved';
		     cm.Transaction_Date__c = system.now();
		     update cm;
    	 }
    	//creating prepayment
    	Supplier_Invoice__c pp = new Supplier_Invoice__c();
		pp.Invoice_Type__c = 'Prepayment';
	    pp.Company__c = testData.fuel.company.Id;
	    pp.Supplier__c = testData.fuel.remittosupplier.Id;
		pp.Date_Invoiced__c = system.now();
	    pp.Supplier_Invoice__c = 'test2';
	    pp.Supplier_and_Invoice__c = 'PP-1231';
	    pp.Invoice_Amount__c = 275;
	    pp.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
	    pp.Payment_Method_G__c = 'ACH';
	    pp.Payment_Term__c = testData.paymentTermInfo.id;
	    pp.Credit_Memo_Amount__c = -275;
	    pp.Credit_Memo_Balance__c = -275;
	    insert pp;
	        
	    Supplier_Invoice_Line__c ppl = new Supplier_Invoice_Line__c();
	    ppl.Supplier_Invoice__c = pp.Id;
	    ppl.Invoice_Quantity__c = 1;
	    ppl.Unit_Price__c = 275;//KNDY-14371
	    ppl.Description__c = 'test';
	    insert ppl;
	        
	    pp.Status__c = 'Approved';
	    pp.Transaction_Date__c = system.now();
	    update pp;
    	
    	//creating invoice
    	Supplier_Invoice__c si = new Supplier_Invoice__c();
    	si =  testData.ACHSupplierInvoice;
    	
    	Supplier__c sp = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :testData.fuel.remittosupplier.id];
    	
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(pp.id);
        siSetToTest.add(si.Id);
        siSetToTest.add(cm.Id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(sp.id);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c = :pp.id or supplier_invoice__c = :si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        
        for(KendoUtils.FilterDescriptor fd: testData.filters){
        	if (fd.field != 'Discount_Date__c' && fd.field != 'Payment_Due_Date__c' && fd.field != 'Payment_Method_G__c' && fd.field != 'totalCreditsExceedsDebits')
        		newFilters.add(fd);
            KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter2 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter3 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter4 = new KendoUtils.FilterDescriptor();
	        DateTime dtpymtdtd = system.today().addDays(40);
	        DateTime dtdisdtd = system.today().addDays(-10);
	        
            if (fd.field == 'Payment_Due_Date__c'){
        		filter1.field = 'Payment_Due_Date__c';
	            filter1.fieldType = 'date';
	            filter1.operator = 'lte';
	            filter1.value = dtpymtdtd.format('MM/dd/yyy');
	            newFilters.add(filter1);
        	}else if (fd.field == 'Payment_Method_G__c'){
        		filter3.field = 'Payment_Method_G__c';
	            filter3.fieldType = 'string';
	        	filter3.operator = 'eq';
	        	filter3.value = 'ACH';
	            newFilters.add(filter3);
        	}else if (fd.field == 'Discount_Date__c'){
        		filter2.field = 'Discount_Date__c';
	            filter2.fieldType = 'date';
	            filter2.operator = 'lte';
	            filter2.value = dtdisdtd.format('MM/dd/yyy');
	            newFilters.add(filter2);
        	}else if(fd.field == 'totalCreditsExceedsDebits'){
        		filter4.field = 'totalCreditsExceedsDebits';
	            filter4.fieldType = 'boolean';
	            filter4.operator = 'eq';
	            filter4.value = true;
	            newFilters.add(filter4);
        	}
        }
        
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        
	    PaymentBatch jpBatch = new PaymentBatch( newFilters, scopeSupInvIdsToPay, supSetToPass);
        jpBatch.runBatch(null);
        Test.stopTest();
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where supplier_invoice__c =:pp.id or supplier_invoice__c = :si.id];
        Set<ID> spHdrIDs = new Set<ID>();
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);
        }
        List<Supplier_Payment__c> spHdrs = [select id, status__c, Payment_Amount__c, Total_Number_of_Lines__c from Supplier_Payment__c where id IN :spHdrIDs];
        system.assert(spHdrs.size() == 1, 'Multiple Supplier Payments were created: ' + spHdrs.size());
        system.assert(spHdrs[0].Payment_Amount__c == 745, 'Prepymt created for another amount: ' + spHdrs[0]);
        system.assert(spHdrs[0].Total_Number_of_Lines__c == 4, 'unexpected no of Supplier Payment lines were created: ' + spHdrs[0]);
        //KNDY-17277 - discount earned deprecated
        Supplier_Invoice__c si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :pp.id];
        system.assert(si1.Credit_Memo_Balance__c == -275, 'Credit Memo Balance not updated on Prepymt SI: ' + si1.Credit_Memo_Balance__c); 
        system.assert(si1.Status__c == 'Closed', 'Prepayment Status not updated: ' + si1.Status__c);
    	
	}
	
	static testMethod void testPymtBatch_AmountToCreditIsLessThanPrepayment(){
		Test.startTest();
		PaymentBatchExtTestData testData = new PaymentBatchExtTestData();		
		
    	//creating credit memo
    	 Supplier_Invoice__c cm = new Supplier_Invoice__c();{
			 cm.Invoice_Type__c = 'Credit Memo';
		     cm.Company__c = testData.fuel.company.Id;
		     cm.Supplier__c = testData.fuel.remittosupplier.Id;
		     cm.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			 cm.Date_Invoiced__c = system.now();
		     cm.Supplier_Invoice__c = 'test1';
		     cm.Supplier_and_Invoice__c = 'CM-1231';
		     cm.Payment_Method_G__c = 'ACH';
		     cm.Invoice_Amount__c = -520;
		     cm.Credit_Memo_Balance__c = -520;
		     cm.Credit_Memo_Amount__c = -520;
		     cm.Payment_Term__c = testData.paymentTermInfo.id;
		     insert cm;
		        
		     Supplier_Invoice_Line__c cml = new Supplier_Invoice_Line__c();
		     cml.Supplier_Invoice__c = cm.Id;
		     cml.Invoice_Quantity__c = 1;
		     cml.Unit_Price__c = -520;//KNDY-14371
		     cml.Description__c = 'test';
		     insert cml;
		        
		     cm.Status__c = 'Approved';
		     cm.Transaction_Date__c = system.now();
		     update cm;
    	 }
	     System.debug(logginglevel.error,'cm-->'+cm +'cm.status__c-->'+cm.status__c);
    	
    	//creating prepayment
    	Supplier_Invoice__c pp = new Supplier_Invoice__c();
		pp.Invoice_Type__c = 'Prepayment';
	    pp.Company__c = testData.fuel.company.Id;
	    pp.Supplier__c = testData.fuel.remittosupplier.Id;
		pp.Date_Invoiced__c = system.now();
	    pp.Supplier_Invoice__c = 'test2';
	    pp.Supplier_and_Invoice__c = 'PP-1231';
	    pp.Invoice_Amount__c = 1275;
	    pp.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
	    pp.Payment_Method_G__c = 'ACH';
	    pp.Payment_Term__c = testData.paymentTermInfo.id;
	    pp.Credit_Memo_Amount__c = -1275;
	    pp.Credit_Memo_Balance__c = -1275;
	    insert pp;
	        
	    Supplier_Invoice_Line__c ppl = new Supplier_Invoice_Line__c();
	    ppl.Supplier_Invoice__c = pp.Id;
	    ppl.Invoice_Quantity__c = 1;
	    ppl.Unit_Price__c = 1275;//KNDY-14371
	    ppl.Description__c = 'test';
	    insert ppl;
	        
	    pp.Status__c = 'Closed';
	    pp.Transaction_Date__c = system.now();
	    update pp;
    	
    	//creating invoice
    	Supplier_Invoice__c si = new Supplier_Invoice__c();
    	si = testData.ACHSupplierInvoice;
    	
    	Supplier__c sp = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :testData.fuel.remittosupplier.id];
    	
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.Id);
        siSetToTest.add(pp.Id);
        siSetToTest.add(cm.Id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(sp.id);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c = :si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        
        for(KendoUtils.FilterDescriptor fd: testData.filters){
        	if (fd.field != 'Discount_Date__c' && fd.field != 'Payment_Due_Date__c' && fd.field != 'Payment_Method_G__c' && fd.field != 'totalCreditsExceedsDebits')
        		newFilters.add(fd);
            KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter2 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter3 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter4 = new KendoUtils.FilterDescriptor();
	        DateTime dtpymtdtd = system.today().addDays(40);
	        DateTime dtdisdtd = system.today().addDays(-10);
	        
            if (fd.field == 'Payment_Due_Date__c'){
        		filter1.field = 'Payment_Due_Date__c';
	            filter1.fieldType = 'date';
	            filter1.operator = 'lte';
	            filter1.value = dtpymtdtd.format('MM/dd/yyy');
	            newFilters.add(filter1);
        	}else if (fd.field == 'Payment_Method_G__c'){
        		filter3.field = 'Payment_Method_G__c';
	            filter3.fieldType = 'string';
	        	filter3.operator = 'eq';
	        	filter3.value = 'ACH';
	            newFilters.add(filter3);
        	}else if (fd.field == 'Discount_Date__c'){
        		filter2.field = 'Discount_Date__c';
	            filter2.fieldType = 'date';
	            filter2.operator = 'lte';
	            filter2.value = dtdisdtd.format('MM/dd/yyy');
	            newFilters.add(filter2);
        	}else if(fd.field == 'totalCreditsExceedsDebits'){
        		filter4.field = 'totalCreditsExceedsDebits';
	            filter4.fieldType = 'boolean';
	            filter4.operator = 'eq';
	            filter4.value = true;
	            newFilters.add(filter4);
        	}
        }
        
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){        	
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned;         	
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;        	
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        
	    PaymentBatch jpBatch = new PaymentBatch( newFilters, scopeSupInvIdsToPay, supSetToPass);
        
        jpBatch.runBatch(null);
        Test.stopTest();
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where supplier_invoice__c =:pp.id or supplier_invoice__c = :si.id];
        Set<ID> spHdrIDs = new Set<ID>();
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);
        }
        List<Supplier_Payment__c> spHdrs = [select id, status__c, Payment_Amount__c, Total_Number_of_Lines__c from Supplier_Payment__c where id IN :spHdrIDs];
        system.assert(spHdrs.size() == 1, 'Multiple Supplier Payments were created: ' + spHdrs.size());
        system.assert(spHdrs[0].Payment_Amount__c == 0, 'Prepymt created for another amount: ' + spHdrs[0].Payment_Amount__c);
        system.assert(spHdrs[0].Total_Number_of_Lines__c == 3, 'unexpected no of Supplier Payment lines were created: ' + spHdrs[0]); 
    	//KNDY-17277 - discount earned deprecated
    	Supplier_Invoice__c si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :pp.id];
        system.assert(si1.Credit_Memo_Balance__c == -285, 'Credit Memo Balance not updated on Prepymt SI: ' + si1.Credit_Memo_Balance__c);
    	
	}
	
	static testMethod void testPymtBatch_AmountToCreditIsMoreThanPrepayment(){
		Test.startTest();
		PaymentBatchExtTestData testData = new PaymentBatchExtTestData();		
		
    	//creating credit memo
    	 Supplier_Invoice__c cm = new Supplier_Invoice__c();{
			 cm.Invoice_Type__c = 'Credit Memo';
		     cm.Company__c = testData.fuel.company.Id;
		     cm.Supplier__c = testData.fuel.remittosupplier.Id;
		     cm.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			 cm.Date_Invoiced__c = system.now();
		     cm.Supplier_Invoice__c = 'test1';
		     cm.Supplier_and_Invoice__c = 'CM-1231';
		     cm.Payment_Method_G__c = 'ACH';
		     cm.Invoice_Amount__c = -720;
		     cm.Credit_Memo_Balance__c = -720;
		     cm.Credit_Memo_Amount__c = -720;
		     cm.Payment_Term__c = testData.paymentTermInfo.id;
		     insert cm;
		        
		     Supplier_Invoice_Line__c cml = new Supplier_Invoice_Line__c();
		     cml.Supplier_Invoice__c = cm.Id;
		     cml.Invoice_Quantity__c = 1;
		     cml.Unit_Price__c = -720;//KNDY-14371
		     cml.Description__c = 'test';
		     insert cml;
		        
		     cm.Status__c = 'Approved';
		     cm.Transaction_Date__c = system.now();
		     update cm;
    	 }
    	//creating prepayment
    	Supplier_Invoice__c pp = new Supplier_Invoice__c();
		pp.Invoice_Type__c = 'Prepayment';
	    pp.Company__c = testData.fuel.company.Id;
	    pp.Supplier__c = testData.fuel.remittosupplier.Id;
		pp.Date_Invoiced__c = system.now();
	    pp.Supplier_Invoice__c = 'test2';
	    pp.Supplier_and_Invoice__c = 'PP-1231';
	    pp.Invoice_Amount__c = 275;
	    pp.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
	    pp.Payment_Method_G__c = 'ACH';
	    pp.Payment_Term__c = testData.paymentTermInfo.id;
	    pp.Credit_Memo_Amount__c = -275;
	    pp.Credit_Memo_Balance__c = -275;
	    insert pp;
	        
	    Supplier_Invoice_Line__c ppl = new Supplier_Invoice_Line__c();
	    ppl.Supplier_Invoice__c = pp.Id;
	    ppl.Invoice_Quantity__c = 1;
	    ppl.Unit_Price__c = 275;//KNDY-14371
	    ppl.Description__c = 'test';
	    insert ppl;
	        
	    pp.Status__c = 'Closed';
	    pp.Transaction_Date__c = system.now();
	    update pp;
    	
    	//creating invoice
    	Supplier_Invoice__c si = new Supplier_Invoice__c();
    	si = testData.ACHSupplierInvoice;
    	
    	Supplier__c sp = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :testData.fuel.remittosupplier.id];
    	
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.Id);
        siSetToTest.add(pp.Id);
        siSetToTest.add(cm.Id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(sp.id);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c = :si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        
        for(KendoUtils.FilterDescriptor fd: testData.filters){
        	if (fd.field != 'Discount_Date__c' && fd.field != 'Payment_Due_Date__c' && fd.field != 'Payment_Method_G__c' && fd.field != 'totalCreditsExceedsDebits')
        		newFilters.add(fd);
            KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter2 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter3 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter4 = new KendoUtils.FilterDescriptor();
	        DateTime dtpymtdtd = system.today().addDays(40);
	        DateTime dtdisdtd = system.today().addDays(-10);
	        
            if (fd.field == 'Payment_Due_Date__c'){
        		filter1.field = 'Payment_Due_Date__c';
	            filter1.fieldType = 'date';
	            filter1.operator = 'lte';
	            filter1.value = dtpymtdtd.format('MM/dd/yyy');
	            newFilters.add(filter1);
        	}else if (fd.field == 'Payment_Method_G__c'){
        		filter3.field = 'Payment_Method_G__c';
	            filter3.fieldType = 'string';
	        	filter3.operator = 'eq';
	        	filter3.value = 'ACH';
	            newFilters.add(filter3);
        	}else if (fd.field == 'Discount_Date__c'){
        		filter2.field = 'Discount_Date__c';
	            filter2.fieldType = 'date';
	            filter2.operator = 'lte';
	            filter2.value = dtdisdtd.format('MM/dd/yyy');
	            newFilters.add(filter2);
        	}else if(fd.field == 'totalCreditsExceedsDebits'){
        		filter4.field = 'totalCreditsExceedsDebits';
	            filter4.fieldType = 'boolean';
	            filter4.operator = 'eq';
	            filter4.value = true;
	            newFilters.add(filter4);
        	}
        }
        
         //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        
	    PaymentBatch jpBatch = new PaymentBatch( newFilters, scopeSupInvIdsToPay, supSetToPass);
        
        jpBatch.runBatch(null);
        Test.stopTest();
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where supplier_invoice__c =:pp.id or supplier_invoice__c = :si.id];
        Set<ID> spHdrIDs = new Set<ID>();
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);
        }
        List<Supplier_Payment__c> spHdrs = [select id, status__c, Payment_Amount__c, Total_Number_of_Lines__c from Supplier_Payment__c where id IN :spHdrIDs];
        system.assert(spHdrs.size() == 1, 'Multiple Supplier Payments were created: ' + spHdrs.size());
        system.assert(spHdrs[0].Payment_Amount__c == 0, 'Prepymt created for another amount: ' + spHdrs[0].Payment_Amount__c);
        system.assert(spHdrs[0].Total_Number_of_Lines__c == 4, 'unexpected no of Supplier Payment lines were created: ' + spHdrs[0]); 
    	//KNDY-17277 - discount earned deprecated
    	Supplier_Invoice__c si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :pp.id];
        system.assert(si1.Credit_Memo_Balance__c == 0, 'Credit Memo Balance not updated on Prepymt SI: ' + si1.Credit_Memo_Balance__c);
        
        si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :cm.id];
        system.assert(si1.Credit_Memo_Balance__c == -5, 'Credit Memo Balance not updated on CM SI: ' + si1.Credit_Memo_Balance__c);
    	system.assert(si1.Status__c == 'Approved', 'Credit Memo Status not updated on CM SI: ' + si1.Status__c);
	}
	//KNDY-17192
	static testMethod void testCreateSPaymentBatch_SuppliersAddressOnSPTest(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        //Create supplier     
                
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2;// = testData.fuel.remittosupplier.clone();
        remitToSupp2 = new Supplier__c(); 
        remitToSupp2.Name = ' RemitToSupplier-2';
        remitToSupp2.Company__c = testData.fuel.company.ID;
        remitToSupp2.Tax_ID__c = 'tax ID';
        remitToSupp2.Supplier_Street__c = '657 test ave';
        remitToSupp2.Street_1__c ='';
        remitToSupp2.Street_2__c = 'apt #2';
        remitToSupp2.Supplier_City__c = 'MV';
        remitToSupp2.Supplier_State__c ='CA';
        remitToSupp2.Supplier_Zip_Code__c ='98008';
        remitToSupp2.Supplier_Country__c ='USA';        
        remitToSupp2.Status__c = 'Active';
        remitToSupp2.Payment_Term__c = testData.fuel.terms.ID;
        remitToSupp2.Always_Take_Discount__c = false;
        remitToSupp2.Type__c = 'Remit-To';
        remitToSupp2.RecordTypeId = testData.fuel.SupplierRecordTypes.get('Remit_To');
        remitToSupp2.Alternate_Name__c = 'Remit to Supplier';               
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = false;
        remitToSupp2.Pay_Per_Invoice__c = false;
        update new List<Supplier__c>{supp2,remitToSupp2,testData.fuel.remittosupplier};
        
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{testData.fuel.remittosupplier.id, remitToSupp2.id};
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c'){
                newFilters.add(fd);
            }
            else {
                KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supplierIds);
                newFilters.add(filter1);
            }
        }
        
        
        // create SI for a supplier2
        Supplier_Invoice__c siSupplier2 = testData.createSI(PaymentService.TYPE_INVOICE, 1000, 'supp2Invoice', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier2;
        Supplier_Invoice_Line__c siLineSupplier2 = testData.createSILine(1, 1000, siSupplier2, null, null);
        insert siLineSupplier2;
        // approve and finalize SI
        siSupplier2.Status__c = 'Approved';
        siSupplier2.Finalized__c = true;
        siSupplier2.Transaction_Date__c = system.now();
        update siSupplier2;
        
        //SI for supplier1
        Supplier_Invoice__c si = testData.NonPOInvoice;
        
        //Both SIs, 1 per supplier, are chosen for payment batch
        Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.Id);
        siSetToTest.add(siSupplier2.Id);
        
        Test.startTest();
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        system.assertEquals(invoiceRecordsFromUI.size() ,5,'total SI mismatch' + invoiceRecordsFromUI.size());        
        PaymentBatchExt.createSPaymentBatch(newFilters,invoiceRecordsFromUI);
        
        Test.stopTest();
        Set<Id> spIds = new Set<Id>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        List<Supplier_Payment_Line__c> splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where supplier_invoice__c in :siSetToTest];
        system.assert(splines.size() == 4, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
        }
        system.assertEquals(SIsRelatedToSPLs.size(), siSetToTest.size());
        system.assert(SIsRelatedToSPLs.containsAll(siSetToTest));
        
        system.assertEquals(spIds.size(), 2, 'Incorrent number of SPs created: spIds - ' + spIds);
        List<Supplier_Payment__c> sps = [select id, status__c, Transaction_Date__c, Payment_Amount__c,Supplier__c,Supplier_Street__c,
        								Supplier_Street_1__c,Supplier_Street_2__c,Supplier_City__c,Supplier_State__c,Supplier_Postal_Code__c,Supplier_Country__c,Remittance_Address__c
        							 from Supplier_Payment__c where id in:spIds];
        for (Supplier_Payment__c sp: sps){
            system.assert(sp.status__c == 'Applied', 'Supplier Payment status is not correct: ' + sp.status__c);            
            system.assert(sp.Transaction_Date__c != null); //KNDY-10280 KNDY-12343
            if (sp.supplier__C == testData.fuel.remittosupplier.id){
            	system.assertEquals(sp.Remittance_Address__c == '303 Twin Dolphin Drive, Suite 500,Redwood City,CA,94065,USA',true,'Address incorrect ' + sp);
            }
            if (sp.supplier__C == remitToSupp2.id){
            	system.assertEquals(sp.Remittance_Address__c.equals( '657 test ave,apt #2,MV,CA,98008,USA'), true,'Address incorrect ' + sp);
            	system.assertEquals(String.isBlank(sp.Supplier_Street_1__c),true,'Address incorrect ' + sp);
            	system.assertEquals(sp.Supplier_City__c == 'MV',true,'Address incorrect ' + sp);
            }
        }
    }     
    //KNDY-17712 - immediate mode create and finalize payments    
    static testMethod void testCreatePaymentImmediateMode(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        JsonResult jsResult = new JsonResult();
		List<Supplier_Payment__c> sps = new List<Supplier_Payment__c>();
		List<Supplier_Payment_Line__c> splines = new List<Supplier_Payment_Line__c>();
        //Create supplier
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2 = testData.fuel.remittosupplier.clone();
        remitToSupp2.Name = 'RemitToSupplier-2';
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = false;
        remitToSupp2.Pay_Per_Invoice__c = false;
        update new List<Supplier__c>{supp2,testData.fuel.remittosupplier};

        // create SI for a supplier2
        Supplier_Invoice__c siSupplier2 = testData.createSI(PaymentService.TYPE_INVOICE, 1000, 'supp2Invoice', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier2;
        Supplier_Invoice_Line__c siLineSupplier2 = testData.createSILine(1, 1000, siSupplier2, null, null);
        insert siLineSupplier2;
        // approve and finalize SI
        siSupplier2.Status__c = 'Approved';
        siSupplier2.Finalized__c = true;
        siSupplier2.Transaction_Date__c = system.now();
        update siSupplier2;
        
        //SI for supplier1
        Supplier_Invoice__c si = testData.NonPOInvoice;
        
        //Both SIs, 1 per supplier, are chosen for payment batch
        Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.Id);
        siSetToTest.add(siSupplier2.Id);
        
        
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{ testData.fuel.remittosupplier.id,remitToSupp2.id};//
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c'){            	
                newFilters.add(fd);
            }
            else {
                KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supplierIds);
                newFilters.add(filter1);
            }
        }
        
        Test.startTest();
     
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();
        SupplierPaymentService.invoicePaymentWrapper originalSISPRecordsFromUI = new SupplierPaymentService.invoicePaymentWrapper();
        originalSISPRecordsFromUI.invWrapperList = new List<SupplierPaymentService.InvoiceWrapper> ();  
        system.assertEquals(invoiceRecordsFromUI.size() ==5,true,'Incorrect nunmber of SIs fetched : ' +invoiceRecordsFromUI.size());       
        system.debug(LoggingLevel.Error,'invoiceRecordsFromUI==' + invoiceRecordsFromUI);      
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	//if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	
        	if (siWrapper.invoiceRecord.Invoice_Type__c != PaymentService.TYPE_CREDITMEMO && siWrapper.invoiceRecord.Status__c == PaymentService.STATUS_APPROVED)
        		scopeSupInvIdsToPay.put(sID,siWrapper);
        	
        	originalSISPRecordsFromUI.invWrapperList.add(siWrapper);
        } 
        SupplierPaymentService spService = new SupplierPaymentService();
        
        originalSISPRecordsFromUI.dateTimeNow = system.now() +'#';
        //preview payments
        jsResult = PaymentBatchExt.createSPaymentRealTime(newFilters,scopeSupInvIdsToPay.values(),originalSISPRecordsFromUI);
        system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        List<SupplierPaymentService.invoicePaymentWrapper>  payWrapper= (List<SupplierPaymentService.invoicePaymentWrapper>)jsResult.records;
        system.debug(LoggingLevel.Error,'test method paywrapper : '+payWrapper[0].paymentWrapperList);
        system.assertEquals(payWrapper[0].invWrapperList.size() ==5,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].invWrapperList.size());   
		system.assertEquals(payWrapper[0].paymentWrapperList.size() ==4,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].paymentWrapperList.size()); 
		
		//combine same sourcekey payments
		List<SupplierPaymentService.paymentWithLinesWrapper> payWrapperList = new List<SupplierPaymentService.paymentWithLinesWrapper> ();
		map<string,SupplierPaymentService.paymentWithLinesWrapper> SPmap = new map<string,SupplierPaymentService.paymentWithLinesWrapper>();
		for (SupplierPaymentService.paymentWithLinesWrapper paylineWrapper :payWrapper[0].paymentWrapperList){
			system.debug(LoggingLevel.Error,'Source key : ' +paylineWrapper.supplierPayment.Source_Key__c);
			system.debug(LoggingLevel.Error,'Source key contains: ' +SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c));
			if (!SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c)){
				SPmap.put(paylineWrapper.supplierPayment.Source_Key__c,paylineWrapper);				
			}else{
				SPmap.get(paylineWrapper.supplierPayment.Source_Key__c).lstPaymentLines.addAll(paylineWrapper.lstPaymentLines);
			}
			
		}
		system.debug(LoggingLevel.Error,'test method paywrapper after merging common records: '+SPmap.values());
		
		jsResult = PaymentBatchExt.CreateFinalizePaymentsForImmediate(newFilters,testData.supplierPaymentMasterPreviewConfig,SPmap.values());
		payWrapperList = (List<SupplierPaymentService.paymentWithLinesWrapper>)jsResult.records;
		system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        system.assert(payWrapperList.size() == 2,'incorrect payment wrappers created ' + payWrapperList);
		
        Test.stopTest();
        Set<Id> spIds = new Set<Id>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        for (SupplierPaymentService.paymentWithLinesWrapper payWrap :payWrapperList){
        	spIds.add(payWrap.supplierPayment.id);
        }
        system.assertEquals(spIds.size(), 2, 'Incorrent number of SPs created: spIds - ' + spIds);
        
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where supplier_invoice__c in :siSetToTest];
        system.assert(splines.size() == 4, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
            if (spLine.type__c == 'Payment')
            	system.assert(spLine.Amount__c == 990, 'Supplier Payment line amount is not correct: ' + spLine.Amount__c);
            if (spLine.type__c == PaymentService.TYPE_EARNED_DISCOUNT)
            	system.assert(spLine.Amount__c == 10, 'Supplier Payment line amount is not correct: ' + spLine.Amount__c);
        }
        system.assertEquals(SIsRelatedToSPLs.size(), siSetToTest.size());
        system.assert(SIsRelatedToSPLs.containsAll(siSetToTest));
        
        system.assertEquals(spIds.size(), 2, 'Incorrent number of SPs created: spIds - ' + spIds);
        sps = [select id, status__c, Transaction_Date__c, Payment_Amount__c from Supplier_Payment__c where id in:spIds];
        system.assertEquals(sps.size(), 2, 'Incorrent number of SPs created: spIds - ' + sps);
        for (Supplier_Payment__c sp: sps){
            system.assert(sp.status__c == 'Applied', 'Supplier Payment status is not correct: ' + sp.status__c);            
            system.assert(sp.Transaction_Date__c != null); //KNDY-10280 KNDY-12343
        }
    }
    //KNDY-17714 - immediate mode create and finalize payments with bankacc currency and SI currency mismatch
    static testMethod void testCreatePaymentImmediateModeMismatchBACurrency(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        
        JsonResult jsResult = new JsonResult();
		List<Supplier_Payment__c> sps = new List<Supplier_Payment__c>();
		List<Supplier_Payment_Line__c> splines = new List<Supplier_Payment_Line__c>();
        //Create supplier
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2 = testData.fuel.remittosupplier.clone();
        remitToSupp2.Name = 'RemitToSupplier-2';
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = false;
        remitToSupp2.Pay_Per_Invoice__c = false;
        update new List<Supplier__c>{supp2,testData.fuel.remittosupplier};

        // create SI for a supplier2
        Supplier_Invoice__c siSupplier2 = testData.createSI(PaymentService.TYPE_INVOICE, 1000, 'supp2Invoice', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier2;
        Supplier_Invoice_Line__c siLineSupplier2 = testData.createSILine(1, 1000, siSupplier2, null, null);
        insert siLineSupplier2;
        // approve and finalize SI
        siSupplier2.Status__c = 'Approved';
        siSupplier2.Finalized__c = true;
        siSupplier2.Transaction_Date__c = system.now();
        update siSupplier2;
        
        Bank_Account__c ba = [select id,Currency__c,Company__c from Bank_Account__c where ID =:testData.bankAccount.id];
        system.assertEquals(ba.Currency__C == testData.fuel.currencyUSD.Id, true,'wrong Bank account : ' + ba );
        ba.Currency__c = testData.fuel.currencyGBP.Id;        
        update ba;
        
        //SI for supplier1
        Supplier_Invoice__c si = testData.NonPOInvoice;
        
        //Both SIs, 1 per supplier, are chosen for payment batch
        Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.Id);
        siSetToTest.add(siSupplier2.Id);
        
        
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{ testData.fuel.remittosupplier.id,remitToSupp2.id};//
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c'){            	
                newFilters.add(fd);
            }
            else {
                KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supplierIds);
                newFilters.add(filter1);
            }
        }
        
        Test.startTest();
     
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();
        SupplierPaymentService.invoicePaymentWrapper originalSISPRecordsFromUI = new SupplierPaymentService.invoicePaymentWrapper();
        originalSISPRecordsFromUI.invWrapperList = new List<SupplierPaymentService.InvoiceWrapper> ();  
        system.assertEquals(invoiceRecordsFromUI.size() ==5,true,'Incorrect nunmber of SIs fetched : ' +invoiceRecordsFromUI.size());       
        system.debug(LoggingLevel.Error,'invoiceRecordsFromUI==' + invoiceRecordsFromUI);      
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	//if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	
        	if (siWrapper.invoiceRecord.Invoice_Type__c != PaymentService.TYPE_CREDITMEMO && siWrapper.invoiceRecord.Status__c == PaymentService.STATUS_APPROVED)
        		scopeSupInvIdsToPay.put(sID,siWrapper);
        	
        	originalSISPRecordsFromUI.invWrapperList.add(siWrapper);
        } 
        SupplierPaymentService spService = new SupplierPaymentService();
        
        originalSISPRecordsFromUI.dateTimeNow = system.now() +'#';
        //preview payments
        jsResult = PaymentBatchExt.createSPaymentRealTime(newFilters,scopeSupInvIdsToPay.values(),originalSISPRecordsFromUI);
        system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        List<SupplierPaymentService.invoicePaymentWrapper>  payWrapper= (List<SupplierPaymentService.invoicePaymentWrapper>)jsResult.records;
        system.debug(LoggingLevel.Error,'test method paywrapper : '+payWrapper[0].paymentWrapperList);
        system.assertEquals(payWrapper[0].invWrapperList.size() ==5,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].invWrapperList.size());   
		system.assertEquals(payWrapper[0].paymentWrapperList.size() ==4,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].paymentWrapperList.size()); 
		
		//combine same sourcekey payments
		List<SupplierPaymentService.paymentWithLinesWrapper> payWrapperList = new List<SupplierPaymentService.paymentWithLinesWrapper> ();
		map<string,SupplierPaymentService.paymentWithLinesWrapper> SPmap = new map<string,SupplierPaymentService.paymentWithLinesWrapper>();
		for (SupplierPaymentService.paymentWithLinesWrapper paylineWrapper :payWrapper[0].paymentWrapperList){
			system.debug(LoggingLevel.Error,'Source key : ' +paylineWrapper.supplierPayment.Source_Key__c);
			system.debug(LoggingLevel.Error,'Source key contains: ' +SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c));
			if (!SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c)){
				SPmap.put(paylineWrapper.supplierPayment.Source_Key__c,paylineWrapper);				
			}else{
				SPmap.get(paylineWrapper.supplierPayment.Source_Key__c).lstPaymentLines.addAll(paylineWrapper.lstPaymentLines);
			}
			
		}
		system.debug(LoggingLevel.Error,'test method paywrapper after merging common records: '+SPmap.values());
		
		jsResult = PaymentBatchExt.CreateFinalizePaymentsForImmediate(newFilters,testData.supplierPaymentMasterPreviewConfig,SPmap.values());
		payWrapperList = (List<SupplierPaymentService.paymentWithLinesWrapper>)jsResult.records;
		system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == false, 'Found problem in processing SIs immediate mode: ' + jsResult);
		system.assert(jsResult.messages.size() > 0,'Error occurred in immediate mode'+jsResult );
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jsResult.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('The invoices and credit memos you select to pay must have the same company and currency as your disbursement bank account. You need to review and change your selections.')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
    	}
        system.assert(ErrorExists, 'Exception not thrown: '+jsResult);        
        
        Test.stopTest();
        
    }
    static testMethod void testPymtImmediateWithCreditsEqualsDebits_CM_CancelSPs(){
    	Test.startTest();
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        JsonResult jsResult = new JsonResult();
        Supplier_Invoice__c si = testData.matchToPOSupplierInvoice;
        Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(testData.fuel.remittosupplier.id);
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if(fd.field != 'Payment_Method_G__c')
            	newFilters.add(fd);            
            else {
            		filter1 = new KendoUtils.FilterDescriptor();
	                filter1.field = 'Payment_Method_G__c';
	                filter1.fieldType = 'string';
	                filter1.operator = 'eq';
	                filter1.value = 'Online';
	                newFilters.add(filter1);
            	}
        }
        
        Supplier_Invoice__c CreditMemoInvoice = testData.createSI('Credit Memo',-990.00, 'testCMabc', 'Online', testData.fuel.company, testData.fuel.remittosupplier);
        CreditMemoInvoice.Credit_Memo_Balance__c = -990; // si amount - earned discount
        CreditMemoInvoice.Credit_Memo_Amount__c = -990;
        insert CreditMemoInvoice;
        Supplier_Invoice_Line__c siLineCM = testData.createSILine(1, -990.00 , CreditMemoInvoice, null, testData.purchasedItem.Id);
        insert siLineCM;
            
        CreditMemoInvoice.Status__c = 'Approved';
        update CreditMemoInvoice;

        // KNDY-13532 add CM to set of selected invoices
        siSetToTest.add(CreditMemoInvoice.id);
        
        Map<Id, Supplier_Invoice__c> siMap = new Map<Id, Supplier_Invoice__c>([select id, name, Credit_Memo_Balance__c, 
                            Balance_Due__c, Status__c 
                            from Supplier_Invoice__c where 
                            id in :siSetToTest]);
        Supplier_Invoice__c CMInv = siMap.get(CreditMemoInvoice.id);
        system.assertEquals(CMInv.Credit_Memo_Balance__c , -990, 'Credit Memo balance is wrong: ' + CMInv.Credit_Memo_Balance__c);
        Supplier_Invoice__c INVsi = siMap.get(si.id);
        system.assertEquals(INVsi.Balance_Due__c, 1000, 'Invoice Balance Due is wrong: ' + INVsi);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c =:si.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        //KNDY-16750
 		List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();
        SupplierPaymentService.invoicePaymentWrapper originalSISPRecordsFromUI = new SupplierPaymentService.invoicePaymentWrapper();
        originalSISPRecordsFromUI.invWrapperList = new List<SupplierPaymentService.InvoiceWrapper> ();  
        system.assertEquals(invoiceRecordsFromUI.size() ==2,true,'Incorrect nunmber of SIs fetched : ' +invoiceRecordsFromUI.size());       
        system.debug(LoggingLevel.Error,'invoiceRecordsFromUI==' + invoiceRecordsFromUI);      
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
	       	if (siWrapper.invoiceRecord.Invoice_Type__c != PaymentService.TYPE_CREDITMEMO && siWrapper.invoiceRecord.Status__c == PaymentService.STATUS_APPROVED)
        		scopeSupInvIdsToPay.put(sID,siWrapper);
        	
        	originalSISPRecordsFromUI.invWrapperList.add(siWrapper);
        } 
        SupplierPaymentService spService = new SupplierPaymentService();
        
        originalSISPRecordsFromUI.dateTimeNow = system.now() +'#';
        //preview payments
        jsResult = PaymentBatchExt.createSPaymentRealTime(newFilters,scopeSupInvIdsToPay.values(),originalSISPRecordsFromUI);
        system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        List<SupplierPaymentService.invoicePaymentWrapper>  payWrapper= (List<SupplierPaymentService.invoicePaymentWrapper>)jsResult.records;
        system.debug(LoggingLevel.Error,'test method paywrapper : '+payWrapper[0].paymentWrapperList);
        system.assertEquals(payWrapper[0].invWrapperList.size() ==2,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].invWrapperList);   
		system.assertEquals(payWrapper[0].paymentWrapperList.size() ==1,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].paymentWrapperList.size()); 
		
		//combine same sourcekey payments
		List<SupplierPaymentService.paymentWithLinesWrapper> payWrapperList = new List<SupplierPaymentService.paymentWithLinesWrapper> ();
		map<string,SupplierPaymentService.paymentWithLinesWrapper> SPmap = new map<string,SupplierPaymentService.paymentWithLinesWrapper>();
		for (SupplierPaymentService.paymentWithLinesWrapper paylineWrapper :payWrapper[0].paymentWrapperList){
			system.debug(LoggingLevel.Error,'Source key : ' +paylineWrapper.supplierPayment.Source_Key__c);
			system.debug(LoggingLevel.Error,'Source key contains: ' +SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c));
			if (!SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c)){
				SPmap.put(paylineWrapper.supplierPayment.Source_Key__c,paylineWrapper);				
			}else{
				SPmap.get(paylineWrapper.supplierPayment.Source_Key__c).lstPaymentLines.addAll(paylineWrapper.lstPaymentLines);
			}
			
		}
		system.debug(LoggingLevel.Error,'test method paywrapper after merging common records: '+SPmap.values());
		
		jsResult = PaymentBatchExt.CreateFinalizePaymentsForImmediate(newFilters,testData.supplierPaymentMasterPreviewConfig,SPmap.values());
		payWrapperList = (List<SupplierPaymentService.paymentWithLinesWrapper>)jsResult.records;
		system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        system.assert(payWrapperList.size() == 1,'incorrect payment wrappers created ' + payWrapperList);

     	
        Test.stopTest();

        List<Supplier_Payment__c> sp = [select id, status__c, Payment_Amount__c,Status_Reason__c from Supplier_Payment__c where Supplier__c IN  :supSetToPass];
        system.assert(sp.size() == 1, 'Multiple Supplier Payments were created: ' + sp);
        system.assert(sp[0].Status__c == PaymentService.STATUS_CANCELLED, 'Multiple Supplier Payments were created with cancelled status: ' + sp);
        system.assert(sp[0].Status_Reason__c == PaymentService.STATUS_REASON_ZERO_AMT_PAYMENT_NOT_ALLOWED, 'Multiple Supplier Payments were created with status reason of zero payment not allowed : ' + sp);
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where Supplier_Payment__c =: sp[0].id];
        system.assert(splines.size() == 3, 'Payment Lines were created: ' + splines);
        
        //check supplier invoice. status would remain same
        List<Supplier_Invoice__c > siList = new List<Supplier_Invoice__c>();
        siList = [select id, name, Discount_Date__c, Discount_Taken__c, Status__c,Amount_Paid__c,Balance_Due__c from Supplier_Invoice__c where id =:si.id];
        si = siList[0];
        system.assert(si.Discount_Taken__c == 0, 'Discount Taken is not right: ' + si.Discount_Taken__c);
        system.assert(si.Amount_Paid__c == null, 'Amount Paid is not right: ' + si.Amount_Paid__c);
        system.assert(si.Balance_Due__c == 1000, 'Balance due is not right: ' + si.Balance_Due__c);
        system.assert(si.Status__c == 'Approved', 'Supplier invoice is not closed: ' + si.Status__c);
        
        siList = [select id, name, Discount_Date__c, Discount_Taken__c, Status__c,Amount_Paid__c,Credit_Memo_Balance__c from Supplier_Invoice__c where id =:CMInv.id]; 
        si = siList[0];      
        system.assert(si.Credit_Memo_Balance__c == -990, 'Credit Memo balance is not right: ' + si.Credit_Memo_Balance__c);
        system.assert(si.Status__c == 'Approved', 'Supplier invoice is not closed: ' + si.Status__c);
        
    }
    static testMethod void testPaymentImmediate_MultiSuppliersBatchCheckOverflow(){
    	Test.startTest();
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        JsonResult jsResult = new JsonResult();
        //Create supplier
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2 = testData.fuel.remittosupplier.clone();
        remitToSupp2.Name = 'RemitToSupplier-2';
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = false;
        remitToSupp2.Pay_Per_Invoice__c = false;
        update new List<Supplier__c>{supp2,testData.fuel.remittosupplier,remitToSupp2};
        
        Bank_Account__c ba = testData.bankAccount;
        ba.Use_Pre_Printed_Check_Stock__c = true;
        ba.Number_of_Advice_Lines_Per_Page__c = 2;
        update ba;
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{testData.fuel.remittosupplier.id, remitToSupp2.id};
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c'){
            	if(fd.field == 'totalCreditsExceedsDebits')
            	{
            		filter1 = new KendoUtils.FilterDescriptor();
	                filter1.field = 'totalCreditsExceedsDebits';
	                filter1.fieldType = 'boolean';
	                filter1.operator = 'eq';
	                filter1.value = true;
	                newFilters.add(filter1);
            	}else	
                	newFilters.add(fd);
            }
            else {
                filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supplierIds);
                newFilters.add(filter1);
            }
        }
        system.assertEquals(newFilters != null, true, 'filters used =' + newFilters);
    
        // create SI for a remitToSupplier2
        Supplier_Invoice__c siSupplier2 = testData.createSI(PaymentService.TYPE_INVOICE, 800, 'remittosupp2Invoice1', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier2;
        Supplier_Invoice_Line__c siLineSupplier2 = testData.createSILine(1, 800, siSupplier2, null, null);
        insert siLineSupplier2;
        // approve and finalize SI
        siSupplier2.Status__c = 'Approved';
        siSupplier2.Finalized__c = true;
        siSupplier2.Transaction_Date__c = system.now();
        update siSupplier2;
      	//create SI for a remitToSupplier2  
        Supplier_Invoice__c siSupplier3 = testData.createSI(PaymentService.TYPE_INVOICE, 700, 'remittosupp2Invoice2', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier3;
        Supplier_Invoice_Line__c siLineSupplier3 = testData.createSILine(1, 700, siSupplier3, null, null);
        insert siLineSupplier3;
        // approve and finalize SI
        siSupplier3.Status__c = 'Approved';
        siSupplier3.Finalized__c = true;
        siSupplier3.Transaction_Date__c = system.now();
        update siSupplier3;
        
        
        Supplier_Invoice__c CreditMemoInvoice = new Supplier_Invoice__c();{
			CreditMemoInvoice.Invoice_Type__c = 'Credit Memo';
	    	CreditMemoInvoice.Company__c = testData.fuel.company.Id;
	        CreditMemoInvoice.Supplier__c = remitToSupp2.id;
	        CreditMemoInvoice.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			CreditMemoInvoice.Date_Invoiced__c = system.now();
	        CreditMemoInvoice.Supplier_Invoice__c = 'test101b';
	        CreditMemoInvoice.Supplier_and_Invoice__c = 'test 101b';
	        CreditMemoInvoice.Invoice_Amount__c = -1100;
	        CreditMemoInvoice.Credit_Memo_Balance__c = -1100;
	        CreditMemoInvoice.Credit_Memo_Amount__c = -1100;
	        CreditMemoInvoice.Payment_Term__c = testData.paymentTermInfo.id;
	        CreditMemoInvoice.Payment_Method_G__c = 'Check';
	        insert CreditMemoInvoice;
	        
	        Supplier_Invoice_Line__c siLineCM = new Supplier_Invoice_Line__c();
	       	siLineCM.Supplier_Invoice__c = CreditMemoInvoice.Id;
	        siLineCM.Invoice_Quantity__c = 1;
	        siLineCM.Unit_Price__c = -1100;//KNDY-14371
	        siLineCM.Description__c = 'test';
	        insert siLineCM;
	        
	        CreditMemoInvoice.Status__c = 'Approved';
	        CreditMemoInvoice.Transaction_Date__c = system.now();
	        update CreditMemoInvoice;
		}
		
		Supplier_Invoice__c CreditMemoInvoice1 = new Supplier_Invoice__c();{
			CreditMemoInvoice1.Invoice_Type__c = 'Credit Memo';
	    	CreditMemoInvoice1.Company__c = testData.fuel.company.Id;
	        CreditMemoInvoice1.Supplier__c = remitToSupp2.id;
	        CreditMemoInvoice1.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
			CreditMemoInvoice1.Date_Invoiced__c = system.now();
	        CreditMemoInvoice1.Supplier_Invoice__c = 'test101c';
	        CreditMemoInvoice1.Supplier_and_Invoice__c = 'test 101c';
	        CreditMemoInvoice1.Invoice_Amount__c = -100;
	        CreditMemoInvoice1.Credit_Memo_Balance__c = -100;
	        CreditMemoInvoice1.Credit_Memo_Amount__c = -100;
	        CreditMemoInvoice1.Payment_Term__c = testData.paymentTermInfo.id;
	        CreditMemoInvoice1.Payment_Method_G__c = 'Check';
	        insert CreditMemoInvoice1;
	        
	        Supplier_Invoice_Line__c siLineCM = new Supplier_Invoice_Line__c();
	       	siLineCM.Supplier_Invoice__c = CreditMemoInvoice1.Id;
	        siLineCM.Invoice_Quantity__c = 1;
	        siLineCM.Unit_Price__c = -100;//KNDY-14371
	        siLineCM.Description__c = 'test';
	        insert siLineCM;
	        
	        CreditMemoInvoice1.Status__c = 'Approved';
	        CreditMemoInvoice1.Transaction_Date__c = system.now();
	        update CreditMemoInvoice1;
		}

        
        Set<Id> supSetToPass = new Set<Id>{remitToSupp2.id,testdata.fuel.remittosupplier.id};

        List<Supplier_Invoice__c> supplierInvoiceList = [select id from supplier_Invoice__c where Supplier__c IN:supSetToPass];
        system.assertEquals(supplierInvoiceList.size() ,10,'total SI mismatch' + supplierInvoiceList);
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();
        SupplierPaymentService.invoicePaymentWrapper originalSISPRecordsFromUI = new SupplierPaymentService.invoicePaymentWrapper();
        originalSISPRecordsFromUI.invWrapperList = new List<SupplierPaymentService.InvoiceWrapper> ();  
        system.assertEquals(invoiceRecordsFromUI.size() ==8,true,'Incorrect nunmber of SIs fetched : ' +invoiceRecordsFromUI.size());       
        system.debug(LoggingLevel.Error,'invoiceRecordsFromUI==' + invoiceRecordsFromUI);      
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
	       	if (siWrapper.invoiceRecord.Invoice_Type__c != PaymentService.TYPE_CREDITMEMO && siWrapper.invoiceRecord.Status__c == PaymentService.STATUS_APPROVED)
        		scopeSupInvIdsToPay.put(sID,siWrapper);
        	
        	originalSISPRecordsFromUI.invWrapperList.add(siWrapper);
        } 
        SupplierPaymentService spService = new SupplierPaymentService();
        
        originalSISPRecordsFromUI.dateTimeNow = system.now() +'#';
        //preview payments
        jsResult = PaymentBatchExt.createSPaymentRealTime(newFilters,scopeSupInvIdsToPay.values(),originalSISPRecordsFromUI);
        system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        List<SupplierPaymentService.invoicePaymentWrapper>  payWrapper= (List<SupplierPaymentService.invoicePaymentWrapper>)jsResult.records;
        system.debug(LoggingLevel.Error,'test method paywrapper : '+payWrapper[0].paymentWrapperList);
        system.assertEquals(payWrapper[0].invWrapperList.size() ==8,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].invWrapperList.size());   
		system.assertEquals(payWrapper[0].paymentWrapperList.size() ==5,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].paymentWrapperList.size()); 
		
		//combine same sourcekey payments
		List<SupplierPaymentService.paymentWithLinesWrapper> payWrapperList = new List<SupplierPaymentService.paymentWithLinesWrapper> ();
		map<string,SupplierPaymentService.paymentWithLinesWrapper> SPmap = new map<string,SupplierPaymentService.paymentWithLinesWrapper>();
		for (SupplierPaymentService.paymentWithLinesWrapper paylineWrapper :payWrapper[0].paymentWrapperList){
			system.debug(LoggingLevel.Error,'Source key : ' +paylineWrapper.supplierPayment.Source_Key__c);
			system.debug(LoggingLevel.Error,'Source key contains: ' +SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c));
			if (!SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c)){
				SPmap.put(paylineWrapper.supplierPayment.Source_Key__c,paylineWrapper);				
			}else{
				SPmap.get(paylineWrapper.supplierPayment.Source_Key__c).lstPaymentLines.addAll(paylineWrapper.lstPaymentLines);
			}
			
		}
		system.debug(LoggingLevel.Error,'test method paywrapper after merging common records: '+SPmap.values());
		
		jsResult = PaymentBatchExt.CreateFinalizePaymentsForImmediate(newFilters,testData.supplierPaymentMasterPreviewConfig,SPmap.values());
		payWrapperList = (List<SupplierPaymentService.paymentWithLinesWrapper>)jsResult.records;
		system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        system.assert(payWrapperList.size() == 7,'incorrect payment wrappers created: ' + payWrapperList.size());


        Test.stopTest();
        Bank_Account__c bankAcc = [select id,Use_Pre_Printed_Check_Stock__c,Number_of_Advice_Lines_Per_Page__c from Bank_Account__c where id =: ba.id];
        system.assertEquals(bankAcc.Use_Pre_Printed_Check_Stock__c, true, bankAcc);
        Set<Id> spIds = new Set<Id>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        system.debug('Remit To Supplier1=' + testdata.fuel.remittosupplier.id);
        system.debug('Remit To Supplier2=' + remitToSupp2.id);
        List<Supplier_Payment__c> sps = [select id, status__c,Status_Reason__c, Transaction_Date__c, Payment_Amount__c,Supplier__c,Total_Number_Of_Lines__c from Supplier_Payment__c where Supplier__c IN:supSetToPass];
        system.assertEquals(sps.size(), 7, 'Incorrent number of SPs created: spIds - ' + sps.size()); 
        boolean cancelledflg = false;
        for (Supplier_Payment__c payment : sps){
        	if (payment.status__C == PaymentService.STATUS_CANCELLED){
        		cancelledflg = true;
        		system.assertEquals(payment.Status_Reason__c ,PaymentService.STATUS_REASON_VOID_FROM_OVERFLOW_ADVICE,' wrongly cancelled status does not match ' +payment);
        		system.assertEquals(payment.Total_Number_Of_Lines__c == 0,true, 'lines created for payment voided by overflow ' + payment);
        	}       	
        }
        system.assert(cancelledflg == true,' no cancelled payments found ' + sps); 
        // supplier lines for remit to supplier1
        List<Supplier_Payment_Line__c> splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Payment__r.Supplier__c =:testData.fuel.remittosupplier.id];
        system.assert(splines.size() == 6, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
        }
        
        // supplier lines for remit to supplier2
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Payment__r.Supplier__c =:remitToSupp2.id];
        system.assert(splines.size() == 7, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
        }
        
        system.assertEquals(spIds.size(), 2, 'Incorrent number of SPs created: spIds - ' + spIds);             
    }
    //KNDY-17712 - validation check if same invoice used to pay multiple times
    static testMethod void testUtilizeSameSIMultipleTimes(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        JSonResult jsResult = new JSonResult();
        Test.startTest();
        
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = false;
        update new List<Supplier__c>{testData.fuel.remittosupplier};
        
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{testData.fuel.remittosupplier.id};
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c'){
                newFilters.add(fd);
            }
            else {
                KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supplierIds);
                newFilters.add(filter1);
            }
        }
        system.assertEquals(newFilters != null, true, 'filters used =' + newFilters);

        Set<Id> supSetToPass = new Set<Id>{testdata.fuel.remittosupplier.id};

        List<Supplier_Invoice__c> supplierInvoiceList = [select id from supplier_Invoice__c where Supplier__c IN:supSetToPass];
        system.assertEquals(supplierInvoiceList.size() ,6,'total SI mismatch' + supplierInvoiceList.size());
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUIKeep = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
       
        system.debug(LoggingLevel.Error,'invoiceRecordsFromUIKeep==' + invoiceRecordsFromUIKeep);      
        system.assertEquals(invoiceRecordsFromUI.size() ,4,'total SI mismatch' + invoiceRecordsFromUI);        
        //batch mode execute SIs
        PaymentBatchExt.createSPaymentBatch(newFilters,invoiceRecordsFromUI);
        
		//***********************use same SIs for immediate mode
		
		Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();
        
        SupplierPaymentService.invoicePaymentWrapper originalSISPRecordsFromUI = new SupplierPaymentService.invoicePaymentWrapper();
        originalSISPRecordsFromUI.invWrapperList = new List<SupplierPaymentService.InvoiceWrapper> ();             
        system.debug(LoggingLevel.Error,'invoiceRecordsFromUIKeep==' + invoiceRecordsFromUIKeep);      
        List<String> siIdList = new List<string>(); 
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUIKeep){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;        	
        	if (siWrapper.invoiceRecord.Invoice_Type__c != PaymentService.TYPE_CREDITMEMO && siWrapper.invoiceRecord.Status__c == PaymentService.STATUS_APPROVED)
        		scopeSupInvIdsToPay.put(sID,siWrapper);
        	
        	originalSISPRecordsFromUI.invWrapperList.add(siWrapper);
        	siIdList.add(siWrapper.invoiceRecord.id);
        } 
        SupplierPaymentService spService = new SupplierPaymentService();
        
        originalSISPRecordsFromUI.dateTimeNow = system.now() +'#';
        //preview payments
        jsResult = PaymentBatchExt.createSPaymentRealTime(newFilters,scopeSupInvIdsToPay.values(),originalSISPRecordsFromUI);
        system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        List<SupplierPaymentService.invoicePaymentWrapper>  payWrapper= (List<SupplierPaymentService.invoicePaymentWrapper>)jsResult.records;
        system.debug(LoggingLevel.Error,'test method paywrapper : '+payWrapper[0].paymentWrapperList);
        system.assertEquals(payWrapper[0].invWrapperList.size() ==4,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].invWrapperList);   
		system.assertEquals(payWrapper[0].paymentWrapperList.size() ==3,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].paymentWrapperList.size()); 
		Test.stopTest();
		
		
		//combine same sourcekey payments
		List<SupplierPaymentService.paymentWithLinesWrapper> payWrapperList = new List<SupplierPaymentService.paymentWithLinesWrapper> ();
		map<string,SupplierPaymentService.paymentWithLinesWrapper> SPmap = new map<string,SupplierPaymentService.paymentWithLinesWrapper>();
		for (SupplierPaymentService.paymentWithLinesWrapper paylineWrapper :payWrapper[0].paymentWrapperList){
			system.debug(LoggingLevel.Error,'Source key : ' +paylineWrapper.supplierPayment.Source_Key__c);
			system.debug(LoggingLevel.Error,'Source key contains: ' +SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c));
			if (!SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c)){
				SPmap.put(paylineWrapper.supplierPayment.Source_Key__c,paylineWrapper);				
			}else{
				SPmap.get(paylineWrapper.supplierPayment.Source_Key__c).lstPaymentLines.addAll(paylineWrapper.lstPaymentLines);
			}
			
		}
		system.debug(LoggingLevel.Error,'test method paywrapper after merging common records: '+SPmap.values());
		//verify if invoices are valid to process or not
		originalSISPRecordsFromUI = new SupplierPaymentService.invoicePaymentWrapper();
		originalSISPRecordsFromUI.invWrapperList = new List<SupplierPaymentService.InvoiceWrapper> ();  
		for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUIKeep){
			originalSISPRecordsFromUI.invWrapperList.add(siWrapper);
		}
		system.debug(LoggingLevel.Error,'originalSISPRecordsFromUI='+originalSISPRecordsFromUI);
		jsResult = PaymentBatchExt.verifySelectedSupplierInvoices(originalSISPRecordsFromUI);
		system.assertEquals(jsResult.success , false, ' wrong result while verification : ' +jsResult);
		
		jsResult = PaymentBatchExt.CreateFinalizePaymentsForImmediate(newFilters,testData.supplierPaymentMasterPreviewConfig,SPmap.values());
		payWrapperList = (List<SupplierPaymentService.paymentWithLinesWrapper>)jsResult.records;
		system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
	 	Set<Id> spIds = new Set<Id>();
	 	List<String> spIdsList = new List<String>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        for (SupplierPaymentService.paymentWithLinesWrapper payWrap :payWrapperList){
        	spIds.add(payWrap.supplierPayment.id);
        	spIdsList.add(payWrap.supplierPayment.id);
        }      
		//KNDY-19040 update invoices
		jsResult = PaymentBatchExt.updateSupplierInoiceForFinalizedPayments(siIdList,spIdsList);	
		
        system.assert(jsResult.success == false, 'Found problem in processing SIs immediate mode: ' + jsResult);
        
        system.assert(jsResult.messages.size() > 0,'Error occurred in immediate mode'+jsResult );
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jsResult.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('You can\'t enter an Amount to Apply that\'s greater than the balance due. Review the selected invoices to pay to find the correct amount.')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
    	}
        system.assert(ErrorExists, 'Exception not thrown: '+jsResult);
        
        
        system.debug('Remit To Supplier1=' + testdata.fuel.remittosupplier.id);
        List<Supplier_Payment__c> sps = [select id, status__c, Transaction_Date__c, Payment_Amount__c,Supplier__c from Supplier_Payment__c where Supplier__c IN:supSetToPass and Status__c = :PaymentService.STATUS_APPLIED];
        system.assertEquals(sps.size(), 1, 'Incorrent number of SPs created: spIds - ' + sps);
        // supplier lines for remit to supplier1
        spIds = new set<Id>();
        List<Supplier_Payment_Line__c> splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where Supplier_Payment__r.Supplier__c =:testData.fuel.remittosupplier.id and Supplier_Payment__r.Status__c = :PaymentService.STATUS_APPLIED];
        system.assert(splines.size() == 7, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
        }

        system.assertEquals(spIds.size(), 1, 'Incorrent number of SPs created: spIds - ' + spIds);
    }
    //KNDY-18763 - add currency in filter criteria
    static testMethod void testFetchDifferentSIandBACurrencyData(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        
        JsonResult jsResult = new JsonResult();
		List<Supplier_Payment__c> sps = new List<Supplier_Payment__c>();
		List<Supplier_Payment_Line__c> splines = new List<Supplier_Payment_Line__c>();
        //Create supplier
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2 = testData.fuel.remittosupplier.clone();
        remitToSupp2.Name = 'RemitToSupplier-2';
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = false;
        remitToSupp2.Pay_Per_Invoice__c = false;
        update new List<Supplier__c>{supp2,testData.fuel.remittosupplier};

        // create SI for a supplier2
        Supplier_Invoice__c siSupplier2 = testData.createSI(PaymentService.TYPE_INVOICE, 1000, 'supp2Invoice', 'Check', testData.fuel.company, remitToSupp2);
        siSupplier2.currency__c =  testData.fuel.currencyGBP.Id;
        insert siSupplier2;
        Supplier_Invoice_Line__c siLineSupplier2 = testData.createSILine(1, 1000, siSupplier2, null, null);
        insert siLineSupplier2;
        // approve and finalize SI
        siSupplier2.Status__c = 'Approved';
        siSupplier2.Finalized__c = true;
        siSupplier2.Transaction_Date__c = system.now();
        update siSupplier2;
         //SI for supplier1
        Supplier_Invoice__c siSupplier1 = testData.createSI(PaymentService.TYPE_INVOICE, 1000, 'supp2Invoice', 'Check', testData.fuel.company, testData.fuel.remittosupplier);
        siSupplier1.currency__c =  testData.fuel.currencyGBP.Id;
        insert siSupplier1;
        Supplier_Invoice_Line__c siLineSupplier1 = testData.createSILine(1, 1000, siSupplier1, null, null);
        insert siLineSupplier1;
        // approve and finalize SI
        siSupplier1.Status__c = 'Approved';
        siSupplier1.Finalized__c = true;
        siSupplier1.Transaction_Date__c = system.now();
        update siSupplier1;
        
        Bank_Account__c ba = [select id,Currency__c,Company__c from Bank_Account__c where ID =:testData.bankAccount.id];
        system.assertEquals(ba.Currency__C == testData.fuel.currencyUSD.Id, true,'wrong Bank account : ' + ba );

        //Both SIs, 1 per supplier, are chosen for payment batch
        Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(siSupplier1.id);
        siSetToTest.add(siSupplier2.Id);
        
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{ testData.fuel.remittosupplier.id,remitToSupp2.id};//
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c' && fd.field != 'Currency__c'){            	
                newFilters.add(fd);
            }
            else {
                KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
                if (fd.field == 'Supplier__c'){
	                filter1.field = 'Supplier__c';
	                filter1.fieldType = null;
	                filter1.operator = 'contains';
	                filter1.value = JSON.serialize(supplierIds);
	                newFilters.add(filter1);
                }
                if (fd.field == 'Currency__c'){
                	filter1 = new KendoUtils.FilterDescriptor();
	                filter1.field = 'Currency__c';
	                filter1.fieldType = 'string';
	                filter1.operator = 'eq';
	                filter1.value = testData.fuel.currencyGBP.Id;
	                newFilters.add(filter1);
                }
                
            }
        }
        
        Test.startTest();
     
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();
        SupplierPaymentService.invoicePaymentWrapper originalSISPRecordsFromUI = new SupplierPaymentService.invoicePaymentWrapper();
        originalSISPRecordsFromUI.invWrapperList = new List<SupplierPaymentService.InvoiceWrapper> ();  
        system.assertEquals(invoiceRecordsFromUI.size() ==2,true,'Incorrect nunmber of SIs fetched : ' +invoiceRecordsFromUI.size());       
        system.debug(LoggingLevel.Error,'invoiceRecordsFromUI==' + invoiceRecordsFromUI);      
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	//if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	
        	if (siWrapper.invoiceRecord.Invoice_Type__c != PaymentService.TYPE_CREDITMEMO && siWrapper.invoiceRecord.Status__c == PaymentService.STATUS_APPROVED)
        		scopeSupInvIdsToPay.put(sID,siWrapper);
        	
        	originalSISPRecordsFromUI.invWrapperList.add(siWrapper);
        } 
        SupplierPaymentService spService = new SupplierPaymentService();
        
        originalSISPRecordsFromUI.dateTimeNow = system.now() +'#';
        //preview payments
        jsResult = PaymentBatchExt.createSPaymentRealTime(newFilters,scopeSupInvIdsToPay.values(),originalSISPRecordsFromUI);
        system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        List<SupplierPaymentService.invoicePaymentWrapper>  payWrapper= (List<SupplierPaymentService.invoicePaymentWrapper>)jsResult.records;
        system.debug(LoggingLevel.Error,'test method paywrapper : '+payWrapper[0].paymentWrapperList);
        system.assertEquals(payWrapper[0].invWrapperList.size() ==2,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].invWrapperList);   
		system.assertEquals(payWrapper[0].paymentWrapperList.size() ==2,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].paymentWrapperList.size()); 
		
		//combine same sourcekey payments
		List<SupplierPaymentService.paymentWithLinesWrapper> payWrapperList = new List<SupplierPaymentService.paymentWithLinesWrapper> ();
		map<string,SupplierPaymentService.paymentWithLinesWrapper> SPmap = new map<string,SupplierPaymentService.paymentWithLinesWrapper>();
		for (SupplierPaymentService.paymentWithLinesWrapper paylineWrapper :payWrapper[0].paymentWrapperList){
			system.debug(LoggingLevel.Error,'Source key : ' +paylineWrapper.supplierPayment.Source_Key__c);
			system.debug(LoggingLevel.Error,'Source key contains: ' +SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c));
			if (!SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c)){
				SPmap.put(paylineWrapper.supplierPayment.Source_Key__c,paylineWrapper);				
			}else{
				SPmap.get(paylineWrapper.supplierPayment.Source_Key__c).lstPaymentLines.addAll(paylineWrapper.lstPaymentLines);
			}
			
		}
		system.debug(LoggingLevel.Error,'test method paywrapper after merging common records: '+SPmap.values());
		
		jsResult = PaymentBatchExt.CreateFinalizePaymentsForImmediate(newFilters,testData.supplierPaymentMasterPreviewConfig,SPmap.values());
		payWrapperList = (List<SupplierPaymentService.paymentWithLinesWrapper>)jsResult.records;
		system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == false, 'Found problem in processing SIs immediate mode: ' + jsResult);
		system.assert(jsResult.messages.size() > 0,'Error occurred in immediate mode'+jsResult );
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jsResult.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('The invoices and credit memos you select to pay must have the same company and currency as your disbursement bank account. You need to review and change your selections.')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
    	}
        system.assert(ErrorExists, 'Exception not thrown: '+jsResult);        
        
        Test.stopTest();
        
    }
    //KNDY-18888 - consume CM for prepayments
    static testMethod void testPymtBatch_CMAgainstPP_NoInvoice(){
    	PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	
    	Test.startTest();
    	
    	//creating credit memo
    	 Supplier_Invoice__c cm = new Supplier_Invoice__c();
		 cm.Invoice_Type__c = 'Credit Memo';
	     cm.Company__c = testData.fuel.company.Id;
	     cm.Supplier__c = testData.fuel.remittosupplier.Id;
	     cm.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
		 cm.Date_Invoiced__c = system.now();
	     cm.Supplier_Invoice__c = 'test1';
	     cm.Supplier_and_Invoice__c = 'CM-1231';
	     cm.Payment_Method_G__c = 'Cash';
	     cm.Payment_Term__c = testData.paymentTermInfo.id;
	     cm.Invoice_Amount__c = -520;
	     cm.Credit_Memo_Balance__c = -520;
	     cm.Credit_Memo_Amount__c = -520;
	     insert cm;
	        
	     Supplier_Invoice_Line__c cml = new Supplier_Invoice_Line__c();
	     cml.Supplier_Invoice__c = cm.Id;
	     cml.Invoice_Quantity__c = 1;
	     cml.Unit_Price__c = -520;//KNDY-14371
	     cml.Description__c = 'test';
	     insert cml;
	        
	     cm.Status__c = 'Approved';
	     cm.Transaction_Date__c = system.now();
	     update cm;
    	
    	//creating prepayment
    	Supplier_Invoice__c pp = new Supplier_Invoice__c();
		pp.Invoice_Type__c = 'Prepayment';
	    pp.Company__c = testData.fuel.company.Id;
	    pp.Supplier__c = testData.fuel.remittosupplier.Id;
		pp.Date_Invoiced__c = system.now();
	    pp.Supplier_Invoice__c = 'test2';
	    pp.Supplier_and_Invoice__c = 'PP-1231';
	    pp.Invoice_Amount__c = 275;
	    pp.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
	    pp.Payment_Method_G__c = 'Cash';
	    pp.Payment_Term__c = testData.paymentTermInfo.id;
	    pp.Credit_Memo_Amount__c = -275;
	    pp.Credit_Memo_Balance__c = -275;
	    insert pp;
	        
	    Supplier_Invoice_Line__c ppl = new Supplier_Invoice_Line__c();
	    ppl.Supplier_Invoice__c = pp.Id;
	    ppl.Invoice_Quantity__c = 1;
	    ppl.Unit_Price__c = 275;//KNDY-14371
	    ppl.Description__c = 'test';
	    insert ppl;
	        
	    pp.Status__c = 'Approved';
	    pp.Transaction_Date__c = system.now();
	    update pp;
    	
    	Supplier__c sp = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :testData.fuel.remittosupplier.id];
    	
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(pp.id);        
        siSetToTest.add(cm.Id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(sp.id);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c = :pp.id or supplier_invoice__c = :cm.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        
        for(KendoUtils.FilterDescriptor fd: testData.filters){
        	if (fd.field != 'Discount_Date__c' && fd.field != 'Payment_Due_Date__c' && fd.field != 'Payment_Method_G__c' && fd.field != 'totalCreditsExceedsDebits')
        		newFilters.add(fd);
            KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter2 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter3 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter4 = new KendoUtils.FilterDescriptor();
	        DateTime dtpymtdtd = system.today().addDays(40);
	        DateTime dtdisdtd = system.today().addDays(-10);
	        
            if (fd.field == 'Payment_Due_Date__c'){
        		filter1.field = 'Payment_Due_Date__c';
	            filter1.fieldType = 'date';
	            filter1.operator = 'lte';
	            filter1.value = dtpymtdtd.format('MM/dd/yyy');
	            newFilters.add(filter1);
        	}else if (fd.field == 'Payment_Method_G__c'){
        		filter3.field = 'Payment_Method_G__c';
	            filter3.fieldType = 'string';
	        	filter3.operator = 'eq';
	        	filter3.value = 'Cash';
	            newFilters.add(filter3);
        	}else if (fd.field == 'Discount_Date__c'){
        		filter2.field = 'Discount_Date__c';
	            filter2.fieldType = 'date';
	            filter2.operator = 'lte';
	            filter2.value = dtdisdtd.format('MM/dd/yyy');
	            newFilters.add(filter2);
        	}else if(fd.field == 'totalCreditsExceedsDebits'){
        		filter4.field = 'totalCreditsExceedsDebits';
	            filter4.fieldType = 'boolean';
	            filter4.operator = 'eq';
	            filter4.value = true;
	            newFilters.add(filter4);
        	}
        }
        
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        system.assertEquals(scopeSupInvIdsToPay.size() ==2,true,'wrong scope of invoices fetched : ' + scopeSupInvIdsToPay.size());
	    PaymentBatch jpBatch = new PaymentBatch( newFilters, scopeSupInvIdsToPay, supSetToPass);
        jpBatch.runBatch(null);
        Test.stopTest();
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where supplier_invoice__c =:pp.id or supplier_invoice__c = :cm.id];
        Set<ID> spHdrIDs = new Set<ID>();
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);
        }
        List<Supplier_Payment__c> spHdrs = [select id, status__c, Payment_Amount__c, Total_Number_of_Lines__c from Supplier_Payment__c where id IN :spHdrIDs];
        system.assert(spHdrs.size() == 1, 'Multiple Supplier Payments were created: ' + spHdrs.size());
        system.assert(spHdrs[0].Payment_Amount__c == 0, 'Prepymt created for another amount: ' + spHdrs[0]);
        system.assert(spHdrs[0].Total_Number_of_Lines__c == 2, 'unexpected no of Supplier Payment lines were created: ' + spHdrs[0]);
        //KNDY-17277 - discount earned deprecated
        Supplier_Invoice__c si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :cm.id];
        system.assert(si1.Credit_Memo_Balance__c == -245, 'Credit Memo Balance not updated on Prepymt SI: ' + si1.Credit_Memo_Balance__c);
        system.assert(si1.Status__c == 'Approved', 'Prepayment Status not updated: ' + si1.Status__c); 
        si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :pp.id];
        system.assert(si1.Credit_Memo_Balance__c == -275, 'Credit Memo Balance not updated on Prepymt SI: ' + si1.Credit_Memo_Balance__c); 
        system.assert(si1.Status__c == 'Closed', 'Prepayment Status not updated: ' + si1.Status__c);
    	
	}
	//KNDY-18888 - consume CM for approved PP and Supplier invoice
	static testMethod void testPymtBatch_ApplyCMOn_PPAndSI(){
		Test.startTest();
		PaymentBatchExtTestData testData = new PaymentBatchExtTestData();		
		
    	//creating credit memo
    	 Supplier_Invoice__c cm = new Supplier_Invoice__c();
		 cm.Invoice_Type__c = 'Credit Memo';
	     cm.Company__c = testData.fuel.company.Id;
	     cm.Supplier__c = testData.fuel.remittosupplier.Id;
	     cm.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
		 cm.Date_Invoiced__c = system.now();
	     cm.Supplier_Invoice__c = 'test1';
	     cm.Supplier_and_Invoice__c = 'CM-1231';
	     cm.Payment_Method_G__c = 'ACH';
	     cm.Invoice_Amount__c = -1310;
	     cm.Credit_Memo_Balance__c = -1310;
	     cm.Credit_Memo_Amount__c = -1310;
	     cm.Payment_Term__c = testData.paymentTermInfo.id;
	     insert cm;
	        
	     Supplier_Invoice_Line__c cml = new Supplier_Invoice_Line__c();
	     cml.Supplier_Invoice__c = cm.Id;
	     cml.Invoice_Quantity__c = 1;
	     cml.Unit_Price__c = -1310;//KNDY-14371
	     cml.Description__c = 'test';
	     insert cml;
	        
	     cm.Status__c = 'Approved';
	     cm.Transaction_Date__c = system.now();
	     update cm;
    	 
    	//creating prepayment
    	Supplier_Invoice__c pp = new Supplier_Invoice__c();
		pp.Invoice_Type__c = 'Prepayment';
	    pp.Company__c = testData.fuel.company.Id;
	    pp.Supplier__c = testData.fuel.remittosupplier.Id;
		pp.Date_Invoiced__c = system.now();
	    pp.Supplier_Invoice__c = 'test2';
	    pp.Supplier_and_Invoice__c = 'PP-1231';
	    pp.Invoice_Amount__c = 275;
	    pp.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
	    pp.Payment_Method_G__c = 'ACH';
	    pp.Payment_Term__c = testData.paymentTermInfo.id;
	    pp.Credit_Memo_Amount__c = -275;
	    pp.Credit_Memo_Balance__c = -275;
	    insert pp;
	        
	    Supplier_Invoice_Line__c ppl = new Supplier_Invoice_Line__c();
	    ppl.Supplier_Invoice__c = pp.Id;
	    ppl.Invoice_Quantity__c = 1;
	    ppl.Unit_Price__c = 275;//KNDY-14371
	    ppl.Description__c = 'test';
	    insert ppl;
	        
	    pp.Status__c = 'Approved';
	    pp.Transaction_Date__c = system.now();
	    update pp;
    	
    	//creating invoice
    	Supplier_Invoice__c si = new Supplier_Invoice__c();
    	si = testData.ACHSupplierInvoice;
    	
    	Supplier__c sp = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :testData.fuel.remittosupplier.id];
    	
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.Id);
        siSetToTest.add(pp.Id);
        siSetToTest.add(cm.Id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(sp.id);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where  supplier_invoice__c = :si.id or supplier_invoice__c = :cm.id or supplier_invoice__c = :pp.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        
        for(KendoUtils.FilterDescriptor fd: testData.filters){
        	if (fd.field != 'Discount_Date__c' && fd.field != 'Payment_Due_Date__c' && fd.field != 'Payment_Method_G__c' && fd.field != 'totalCreditsExceedsDebits')
        		newFilters.add(fd);
            KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter2 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter3 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter4 = new KendoUtils.FilterDescriptor();
	        DateTime dtpymtdtd = system.today().addDays(40);
	        DateTime dtdisdtd = system.today().addDays(-10);
	        
            if (fd.field == 'Payment_Due_Date__c'){
        		filter1.field = 'Payment_Due_Date__c';
	            filter1.fieldType = 'date';
	            filter1.operator = 'lte';
	            filter1.value = dtpymtdtd.format('MM/dd/yyy');
	            newFilters.add(filter1);
        	}else if (fd.field == 'Payment_Method_G__c'){
        		filter3.field = 'Payment_Method_G__c';
	            filter3.fieldType = 'string';
	        	filter3.operator = 'eq';
	        	filter3.value = 'ACH';
	            newFilters.add(filter3);
        	}else if (fd.field == 'Discount_Date__c'){
        		filter2.field = 'Discount_Date__c';
	            filter2.fieldType = 'date';
	            filter2.operator = 'lte';
	            filter2.value = dtdisdtd.format('MM/dd/yyy');
	            newFilters.add(filter2);
        	}else if(fd.field == 'totalCreditsExceedsDebits'){
        		filter4.field = 'totalCreditsExceedsDebits';
	            filter4.fieldType = 'boolean';
	            filter4.operator = 'eq';
	            filter4.value = true;
	            newFilters.add(filter4);
        	}
        }
        
         //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();        
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        system.assertEquals(scopeSupInvIdsToPay.size() == 3, true, 'wrong number of supplier invoices fetched as a scope : ' + scopeSupInvIdsToPay.size());
	    PaymentBatch jpBatch = new PaymentBatch( newFilters, scopeSupInvIdsToPay, supSetToPass);
        
        jpBatch.runBatch(null);
        Test.stopTest();
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c,supplier_invoice__c from Supplier_Payment_Line__c where supplier_invoice__c =:pp.id or supplier_invoice__c =:cm.id or supplier_invoice__c = :si.id];
        Set<ID> spHdrIDs = new Set<ID>();
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);       
        	if (spl.type__c == 'Payment' && spl.supplier_invoice__c == si.id)
        		system.assertEquals(spl.Amount__c ,990 ,'Payment amount wrong : ' + spl.Amount__c);
        	if (spl.type__c == 'Earned Terms Discount' && spl.supplier_invoice__c == si.id)
        		system.assertEquals(spl.Amount__c ,10 ,'Payment amount wrong : ' + spl.Amount__c);
        	if (spl.type__c == 'Payment' && spl.supplier_invoice__c == pp.id)
        		system.assertEquals(spl.Amount__c, 275 ,'Payment amount wrong : ' + spl.Amount__c);        	
        }
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where  supplier_invoice__c =:cm.id ];
        decimal cmAmount = 0;
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);       
        	system.assertEquals(spl.Type__c == 'Credit Memo',true ,'wrong payment line picked up ' + spl );        
        	cmAmount +=spl.Amount__c; 	
    		   	      	
        }
        system.assertEquals((cmAmount == -1265),true,'Payment amount wrong : ' + splines);     
        List<Supplier_Payment__c> spHdrs = [select id, status__c, Payment_Amount__c, Total_Number_of_Lines__c from Supplier_Payment__c where id IN :spHdrIDs];
        system.assert(spHdrs.size() == 1, 'Multiple Supplier Payments were created: ' + spHdrs.size());
        system.assert(spHdrs[0].Payment_Amount__c == 0, 'Prepymt created for another amount: ' + spHdrs[0].Payment_Amount__c);
        system.assert(spHdrs[0].Total_Number_of_Lines__c == 5, 'unexpected no of Supplier Payment lines were created: ' + spHdrs[0]); 
    	//check for prepayment SI status
    	Supplier_Invoice__c si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :pp.id];
        system.assert(si1.Credit_Memo_Balance__c == -275, 'Credit Memo Balance not updated on Prepymt SI: ' + si1.Credit_Memo_Balance__c);
        system.assert(si1.Status__c == 'Closed', 'Prepayment status not updated on Prepymt SI: ' + si1.Status__c);
    	//check for CM status
    	si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :cm.id];
        system.assert(si1.Credit_Memo_Balance__c == -45, 'Credit Memo Balance not updated on Prepymt SI: ' + si1.Credit_Memo_Balance__c);
        system.assert(si1.Status__c == 'Approved', 'Credit Memo status not updated on Prepymt SI: ' + si1.Status__c);
         
        //check for SI status
    	si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :si.id];
        system.assertEquals((si1.Balance_due__c == 0 && si1.Amount_Paid__c == 990),true, 'Balance due not updated on Invocie : ' + si1.Balance_due__c + ' Amount Paid : ' + si1.Amount_Paid__c);
        system.assert(si1.Status__c == 'Closed', 'Invoice status not updated on Invocie SI: ' + si1.Status__c);
	}
	//KNDY-18888 - consume CM for approved PP and Supplier invoice with immediate mode
	static testMethod void testPymtImmediate_ApplyCMOn_PPAndSI(){
		Test.startTest();
		PaymentBatchExtTestData testData = new PaymentBatchExtTestData();		
		
    	//creating credit memo
    	 Supplier_Invoice__c cm = new Supplier_Invoice__c();
		 cm.Invoice_Type__c = 'Credit Memo';
	     cm.Company__c = testData.fuel.company.Id;
	     cm.Supplier__c = testData.fuel.remittosupplier.Id;
	     cm.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
		 cm.Date_Invoiced__c = system.now();
	     cm.Supplier_Invoice__c = 'test1';
	     cm.Supplier_and_Invoice__c = 'CM-1231';
	     cm.Payment_Method_G__c = 'ACH';
	     cm.Invoice_Amount__c = -1000;
	     cm.Credit_Memo_Balance__c = -1000;
	     cm.Credit_Memo_Amount__c = -1000;
	     cm.Payment_Term__c = testData.paymentTermInfo.id;
	     insert cm;
	        
	     Supplier_Invoice_Line__c cml = new Supplier_Invoice_Line__c();
	     cml.Supplier_Invoice__c = cm.Id;
	     cml.Invoice_Quantity__c = 1;
	     cml.Unit_Price__c = -1000;//KNDY-14371
	     cml.Description__c = 'test';
	     insert cml;
	        
	     cm.Status__c = 'Approved';
	     cm.Transaction_Date__c = system.now();
	     update cm;
    	 
    	//creating prepayment
    	Supplier_Invoice__c pp = new Supplier_Invoice__c();
		pp.Invoice_Type__c = 'Prepayment';
	    pp.Company__c = testData.fuel.company.Id;
	    pp.Supplier__c = testData.fuel.remittosupplier.Id;
		pp.Date_Invoiced__c = system.now();
	    pp.Supplier_Invoice__c = 'test2';
	    pp.Supplier_and_Invoice__c = 'PP-1231';
	    pp.Invoice_Amount__c = 275;
	    pp.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
	    pp.Payment_Method_G__c = 'ACH';
	    pp.Payment_Term__c = testData.paymentTermInfo.id;
	    pp.Credit_Memo_Amount__c = -275;
	    pp.Credit_Memo_Balance__c = -275;
	    insert pp;
	        
	    Supplier_Invoice_Line__c ppl = new Supplier_Invoice_Line__c();
	    ppl.Supplier_Invoice__c = pp.Id;
	    ppl.Invoice_Quantity__c = 1;
	    ppl.Unit_Price__c = 275;//KNDY-14371
	    ppl.Description__c = 'test';
	    insert ppl;
	        
	    pp.Status__c = 'Approved';
	    pp.Transaction_Date__c = system.now();
	    update pp;
    	
    	//creating invoice
    	Supplier_Invoice__c si = new Supplier_Invoice__c();
    	si = testData.ACHSupplierInvoice;
    	
    	Supplier__c sp = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :testData.fuel.remittosupplier.id];
    	
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.Id);
        siSetToTest.add(pp.Id);
        siSetToTest.add(cm.Id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(sp.id);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where  supplier_invoice__c = :si.id or supplier_invoice__c = :cm.id or supplier_invoice__c = :pp.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        
        for(KendoUtils.FilterDescriptor fd: testData.filters){
        	if (fd.field != 'Discount_Date__c' && fd.field != 'Payment_Due_Date__c' && fd.field != 'Payment_Method_G__c' && fd.field != 'totalCreditsExceedsDebits')
        		newFilters.add(fd);
            KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter2 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter3 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter4 = new KendoUtils.FilterDescriptor();
	        DateTime dtpymtdtd = system.today().addDays(40);
	        DateTime dtdisdtd = system.today().addDays(-10);
	        
            if (fd.field == 'Payment_Due_Date__c'){
        		filter1.field = 'Payment_Due_Date__c';
	            filter1.fieldType = 'date';
	            filter1.operator = 'lte';
	            filter1.value = dtpymtdtd.format('MM/dd/yyy');
	            newFilters.add(filter1);
        	}else if (fd.field == 'Payment_Method_G__c'){
        		filter3.field = 'Payment_Method_G__c';
	            filter3.fieldType = 'string';
	        	filter3.operator = 'eq';
	        	filter3.value = 'ACH';
	            newFilters.add(filter3);
        	}else if (fd.field == 'Discount_Date__c'){
        		filter2.field = 'Discount_Date__c';
	            filter2.fieldType = 'date';
	            filter2.operator = 'lte';
	            filter2.value = dtdisdtd.format('MM/dd/yyy');
	            newFilters.add(filter2);
        	}else if(fd.field == 'totalCreditsExceedsDebits'){
        		filter4.field = 'totalCreditsExceedsDebits';
	            filter4.fieldType = 'boolean';
	            filter4.operator = 'eq';
	            filter4.value = true;
	            newFilters.add(filter4);
        	}
        }
        
        
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();
        SupplierPaymentService.invoicePaymentWrapper originalSISPRecordsFromUI = new SupplierPaymentService.invoicePaymentWrapper();
        originalSISPRecordsFromUI.invWrapperList = new List<SupplierPaymentService.InvoiceWrapper> ();  
        system.assertEquals(invoiceRecordsFromUI.size() ==3,true,'Incorrect nunmber of SIs fetched : ' +invoiceRecordsFromUI.size());       
        system.debug(LoggingLevel.Error,'invoiceRecordsFromUI==' + invoiceRecordsFromUI);      
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
	       	if (siWrapper.invoiceRecord.Invoice_Type__c != PaymentService.TYPE_CREDITMEMO && siWrapper.invoiceRecord.Status__c == PaymentService.STATUS_APPROVED)
        		scopeSupInvIdsToPay.put(sID,siWrapper);
        	
        	originalSISPRecordsFromUI.invWrapperList.add(siWrapper);
        } 
        SupplierPaymentService spService = new SupplierPaymentService();
        
        originalSISPRecordsFromUI.dateTimeNow = system.now() +'#';
        //preview payments
        JSONResult jsResult = PaymentBatchExt.createSPaymentRealTime(newFilters,scopeSupInvIdsToPay.values(),originalSISPRecordsFromUI);
        system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        List<SupplierPaymentService.invoicePaymentWrapper>  payWrapper= (List<SupplierPaymentService.invoicePaymentWrapper>)jsResult.records;
        system.debug(LoggingLevel.Error,'test method paywrapper : '+payWrapper[0].paymentWrapperList);
        system.assertEquals(payWrapper[0].invWrapperList.size() ==3,true,'Incorrect number of payments ready for preview : ' +payWrapper[0].invWrapperList.size());   
		system.assertEquals(payWrapper[0].paymentWrapperList.size() ==2,true,'Incorrect number of payments ready for preview : ' +payWrapper[0].paymentWrapperList.size()); 
		
		//combine same sourcekey payments
		List<SupplierPaymentService.paymentWithLinesWrapper> payWrapperList = new List<SupplierPaymentService.paymentWithLinesWrapper> ();
		map<string,SupplierPaymentService.paymentWithLinesWrapper> SPmap = new map<string,SupplierPaymentService.paymentWithLinesWrapper>();
		for (SupplierPaymentService.paymentWithLinesWrapper paylineWrapper :payWrapper[0].paymentWrapperList){
			system.debug(LoggingLevel.Error,'Source key : ' +paylineWrapper.supplierPayment.Source_Key__c);
			system.debug(LoggingLevel.Error,'Source key contains: ' +SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c));
			if (!SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c)){
				SPmap.put(paylineWrapper.supplierPayment.Source_Key__c,paylineWrapper);				
			}else{
				SPmap.get(paylineWrapper.supplierPayment.Source_Key__c).lstPaymentLines.addAll(paylineWrapper.lstPaymentLines);
			}
			
		}
		system.debug(LoggingLevel.Error,'test method paywrapper after merging common records: '+SPmap.values());
		
		jsResult = PaymentBatchExt.CreateFinalizePaymentsForImmediate(newFilters,testData.supplierPaymentMasterPreviewConfig,SPmap.values());
		payWrapperList = (List<SupplierPaymentService.paymentWithLinesWrapper>)jsResult.records;
		system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        system.assert(payWrapperList.size() == 1,'incorrect payment wrappers created: ' + payWrapperList.size());
        
        //KNDY-19040 update invoices
		PaymentBatchExt.updateSupplierInoiceForFinalizedPayments(New List<String> {si.id,pp.Id,cm.id},null);
        
        Test.stopTest();
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c,supplier_invoice__c from Supplier_Payment_Line__c where supplier_invoice__c =:pp.id or supplier_invoice__c =:cm.id or supplier_invoice__c = :si.id];
        Set<ID> spHdrIDs = new Set<ID>();
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);       
        	if (spl.type__c == 'Payment' && spl.supplier_invoice__c == si.id)
        		system.assertEquals(spl.Amount__c ,990 ,'Payment amount wrong : ' + spl.Amount__c);
        	if (spl.type__c == 'Earned Terms Discount' && spl.supplier_invoice__c == si.id)
        		system.assertEquals(spl.Amount__c ,10 ,'Payment amount wrong : ' + spl.Amount__c);
        	if (spl.type__c == 'Payment' && spl.supplier_invoice__c == pp.id)
        		system.assertEquals(spl.Amount__c, 275 ,'Payment amount wrong : ' + spl.Amount__c);        	
        }
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where  supplier_invoice__c =:cm.id ];
        decimal cmAmount = 0;
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);       
        	system.assertEquals(spl.Type__c == 'Credit Memo',true ,'wrong payment line picked up ' + spl );        
        	cmAmount +=spl.Amount__c; 	
    		   	      	
        }
        system.assertEquals((cmAmount == -1000),true,'Payment amount wrong : ' + splines);     
        List<Supplier_Payment__c> spHdrs = [select id, status__c, Payment_Amount__c, Total_Number_of_Lines__c from Supplier_Payment__c where id IN :spHdrIDs];
        system.assert(spHdrs.size() == 1, 'Multiple Supplier Payments were created: ' + spHdrs.size());
        system.assert(spHdrs[0].Payment_Amount__c == 265, 'Prepymt created for another amount: ' + spHdrs[0].Payment_Amount__c);
        system.assert(spHdrs[0].Total_Number_of_Lines__c == 5, 'unexpected no of Supplier Payment lines were created: ' + spHdrs[0]); 
    	//check for prepayment SI status
    	Supplier_Invoice__c si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :pp.id];
        system.assert(si1.Credit_Memo_Balance__c == -275, 'Credit Memo Balance not updated on Prepymt SI: ' + si1.Credit_Memo_Balance__c);
        system.assert(si1.Status__c == 'Closed', 'Prepayment status not updated on Prepymt SI: ' + si1.Status__c);
    	//check for CM status
    	si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :cm.id];
        system.assert(si1.Credit_Memo_Balance__c == 0, 'Credit Memo Balance not updated on Credit Memo SI: ' + si1.Credit_Memo_Balance__c);
        system.assert(si1.Status__c == 'Closed', 'Credit Memo status not updated on Credit Memo SI: ' + si1.Status__c);
         
        //check for SI status
    	si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :si.id];
        system.assertEquals((si1.Balance_due__c == 0 && si1.Amount_Paid__c == 990),true, 'Balance due not updated on Invocie : ' + si1.Balance_due__c + ' Amount Paid : ' + si1.Amount_Paid__c);
        system.assert(si1.Status__c == 'Closed', 'Invoice status not updated on Invocie SI: ' + si1.Status__c);
	}
	//KNDY-18888 - consume CM for approved PP and Supplier invoice with immediate mode (Payper invoice true)
	static testMethod void testPymtImmediate_PayPerInvoice_ApplyCMOn_PPAndSI(){
		Test.startTest();
		PaymentBatchExtTestData testData = new PaymentBatchExtTestData();		
		
    	//creating credit memo
    	 Supplier_Invoice__c cm = new Supplier_Invoice__c();
		 cm.Invoice_Type__c = 'Credit Memo';
	     cm.Company__c = testData.fuel.company.Id;
	     cm.Supplier__c = testData.fuel.remittosupplier.Id;
	     cm.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
		 cm.Date_Invoiced__c = system.now();
	     cm.Supplier_Invoice__c = 'test1';
	     cm.Supplier_and_Invoice__c = 'CM-1231';
	     cm.Payment_Method_G__c = 'ACH';
	     cm.Invoice_Amount__c = -1000;
	     cm.Credit_Memo_Balance__c = -1000;
	     cm.Credit_Memo_Amount__c = -1000;
	     cm.Payment_Term__c = testData.paymentTermInfo.id;
	     insert cm;
	        
	     Supplier_Invoice_Line__c cml = new Supplier_Invoice_Line__c();
	     cml.Supplier_Invoice__c = cm.Id;
	     cml.Invoice_Quantity__c = 1;
	     cml.Unit_Price__c = -1000;//KNDY-14371
	     cml.Description__c = 'test';
	     insert cml;
	        
	     cm.Status__c = 'Approved';
	     cm.Transaction_Date__c = system.now();
	     update cm;
    	 
    	//creating prepayment
    	Supplier_Invoice__c pp = new Supplier_Invoice__c();
		pp.Invoice_Type__c = 'Prepayment';
	    pp.Company__c = testData.fuel.company.Id;
	    pp.Supplier__c = testData.fuel.remittosupplier.Id;
		pp.Date_Invoiced__c = system.now();
	    pp.Supplier_Invoice__c = 'test2';
	    pp.Supplier_and_Invoice__c = 'PP-1231';
	    pp.Invoice_Amount__c = 275;
	    pp.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
	    pp.Payment_Method_G__c = 'ACH';
	    pp.Payment_Term__c = testData.paymentTermInfo.id;
	    pp.Credit_Memo_Amount__c = -275;
	    pp.Credit_Memo_Balance__c = -275;
	    insert pp;
	        
	    Supplier_Invoice_Line__c ppl = new Supplier_Invoice_Line__c();
	    ppl.Supplier_Invoice__c = pp.Id;
	    ppl.Invoice_Quantity__c = 1;
	    ppl.Unit_Price__c = 275;//KNDY-14371
	    ppl.Description__c = 'test';
	    insert ppl;
	        
	    pp.Status__c = 'Approved';
	    pp.Transaction_Date__c = system.now();
	    update pp;
    	
    	//creating invoice
    	Supplier_Invoice__c si = new Supplier_Invoice__c();
    	si = testData.ACHSupplierInvoice;
    	
    	Supplier__c sp = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :testData.fuel.remittosupplier.id];
    	sp.Pay_Per_Invoice__c = true;
    	update sp;
    	
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.Id);
        siSetToTest.add(pp.Id);
        siSetToTest.add(cm.Id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(sp.id);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where  supplier_invoice__c = :si.id or supplier_invoice__c = :cm.id or supplier_invoice__c = :pp.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        
        for(KendoUtils.FilterDescriptor fd: testData.filters){
        	if (fd.field != 'Discount_Date__c' && fd.field != 'Payment_Due_Date__c' && fd.field != 'Payment_Method_G__c' && fd.field != 'totalCreditsExceedsDebits')
        		newFilters.add(fd);
            KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter2 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter3 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter4 = new KendoUtils.FilterDescriptor();
	        DateTime dtpymtdtd = system.today().addDays(40);
	        DateTime dtdisdtd = system.today().addDays(-10);
	        
            if (fd.field == 'Payment_Due_Date__c'){
        		filter1.field = 'Payment_Due_Date__c';
	            filter1.fieldType = 'date';
	            filter1.operator = 'lte';
	            filter1.value = dtpymtdtd.format('MM/dd/yyy');
	            newFilters.add(filter1);
        	}else if (fd.field == 'Payment_Method_G__c'){
        		filter3.field = 'Payment_Method_G__c';
	            filter3.fieldType = 'string';
	        	filter3.operator = 'eq';
	        	filter3.value = 'ACH';
	            newFilters.add(filter3);
        	}else if (fd.field == 'Discount_Date__c'){
        		filter2.field = 'Discount_Date__c';
	            filter2.fieldType = 'date';
	            filter2.operator = 'lte';
	            filter2.value = dtdisdtd.format('MM/dd/yyy');
	            newFilters.add(filter2);
        	}else if(fd.field == 'totalCreditsExceedsDebits'){
        		filter4.field = 'totalCreditsExceedsDebits';
	            filter4.fieldType = 'boolean';
	            filter4.operator = 'eq';
	            filter4.value = true;
	            newFilters.add(filter4);
        	}
        }
        
        
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();
        SupplierPaymentService.invoicePaymentWrapper originalSISPRecordsFromUI = new SupplierPaymentService.invoicePaymentWrapper();
        originalSISPRecordsFromUI.invWrapperList = new List<SupplierPaymentService.InvoiceWrapper> ();  
        system.assertEquals(invoiceRecordsFromUI.size() ==3,true,'Incorrect nunmber of SIs fetched : ' +invoiceRecordsFromUI.size());       
        system.debug(LoggingLevel.Error,'invoiceRecordsFromUI==' + invoiceRecordsFromUI);      
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
	       	if (siWrapper.invoiceRecord.Invoice_Type__c != PaymentService.TYPE_CREDITMEMO && siWrapper.invoiceRecord.Status__c == PaymentService.STATUS_APPROVED)
        		scopeSupInvIdsToPay.put(sID,siWrapper);
        	
        	originalSISPRecordsFromUI.invWrapperList.add(siWrapper);
        } 
        SupplierPaymentService spService = new SupplierPaymentService();
        
        originalSISPRecordsFromUI.dateTimeNow = system.now() +'#';
        //preview payments
        JSONResult jsResult = PaymentBatchExt.createSPaymentRealTime(newFilters,scopeSupInvIdsToPay.values(),originalSISPRecordsFromUI);
        system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        List<SupplierPaymentService.invoicePaymentWrapper>  payWrapper= (List<SupplierPaymentService.invoicePaymentWrapper>)jsResult.records;
        system.debug(LoggingLevel.Error,'test method paywrapper : '+payWrapper[0].paymentWrapperList);
        system.assertEquals(payWrapper[0].invWrapperList.size() ==3,true,'Incorrect number of payments ready for preview : ' +payWrapper[0].invWrapperList.size());   
		system.assertEquals(payWrapper[0].paymentWrapperList.size() ==2,true,'Incorrect number of payments ready for preview : ' +payWrapper[0].paymentWrapperList.size()); 
		
		//combine same sourcekey payments
		List<SupplierPaymentService.paymentWithLinesWrapper> payWrapperList = new List<SupplierPaymentService.paymentWithLinesWrapper> ();
		map<string,SupplierPaymentService.paymentWithLinesWrapper> SPmap = new map<string,SupplierPaymentService.paymentWithLinesWrapper>();
		for (SupplierPaymentService.paymentWithLinesWrapper paylineWrapper :payWrapper[0].paymentWrapperList){
			system.debug(LoggingLevel.Error,'Source key : ' +paylineWrapper.supplierPayment.Source_Key__c);
			system.debug(LoggingLevel.Error,'Source key contains: ' +SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c));
			if (!SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c)){
				SPmap.put(paylineWrapper.supplierPayment.Source_Key__c,paylineWrapper);				
			}else{
				SPmap.get(paylineWrapper.supplierPayment.Source_Key__c).lstPaymentLines.addAll(paylineWrapper.lstPaymentLines);
			}
			
		}
		system.debug(LoggingLevel.Error,'test method paywrapper after merging common records: '+SPmap.values());
		
		jsResult = PaymentBatchExt.CreateFinalizePaymentsForImmediate(newFilters,testData.supplierPaymentMasterPreviewConfig,SPmap.values());
		payWrapperList = (List<SupplierPaymentService.paymentWithLinesWrapper>)jsResult.records;
		system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        system.assert(payWrapperList.size() == 2,'incorrect payment wrappers created: ' + payWrapperList.size());
        //KNDY-19040 update invoices
		PaymentBatchExt.updateSupplierInoiceForFinalizedPayments(New List<String> {si.id,pp.Id,cm.id},null);
        
        //verify if invoices are valid to process or not
		jsResult = PaymentBatchExt.verifySelectedSupplierInvoices(originalSISPRecordsFromUI);
		system.assertEquals(jsResult.success , false, ' wrong result while verification : ' +jsResult);
        
        Test.stopTest();
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c,supplier_invoice__c from Supplier_Payment_Line__c where supplier_invoice__c = :si.id ];
        Set<ID> spHdrIDs = new Set<ID>();
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);       
        	if (spl.type__c == 'Payment' && spl.supplier_invoice__c == si.id)
        		system.assertEquals(spl.Amount__c ,990 ,'Payment amount wrong : ' + spl.Amount__c);
        	if (spl.type__c == 'Earned Terms Discount' && spl.supplier_invoice__c == si.id)
        		system.assertEquals(spl.Amount__c ,10 ,'Payment amount wrong : ' + spl.Amount__c);
        	if (spl.type__c == 'Payment' && spl.supplier_invoice__c == pp.id)
        		system.assertEquals(spl.Amount__c, 275 ,'Payment amount wrong : ' + spl.Amount__c);        	
        }
        List<Supplier_Payment__c> spHdrs = [select id, status__c, Payment_Amount__c, Total_Number_of_Lines__c from Supplier_Payment__c where id IN :spHdrIDs];
        system.assert(spHdrs.size() == 1, 'Multiple Supplier Payments were created: ' + spHdrs.size());
        system.assert(spHdrs[0].Payment_Amount__c == 0, 'Prepymt created for another amount: ' + spHdrs[0].Payment_Amount__c);
        system.assert(spHdrs[0].Total_Number_of_Lines__c == 3, 'unexpected no of Supplier Payment lines were created: ' + spHdrs[0]);
         
        spHdrIDs = new Set<ID>();
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where  supplier_invoice__c =:pp.id   ];
        
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);              	
    		system.assertEquals(spl.Amount__c == 275,true ,'wrong payment line picked up ' + spl );                	
        }
                
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where  supplier_invoice__c =:cm.id   ];
        decimal cmAmount = 0;
        for (Supplier_Payment_Line__c spl: splines){        	        	
    		system.assertEquals(spl.type__c == 'Credit Memo',true ,'wrong payment line picked up ' + spl );        
        	cmAmount +=spl.Amount__c; 	
    		   	      	
        }
        system.assertEquals((cmAmount == -1000),true,'Payment amount wrong : ' + splines);  
           
        spHdrs = [select id, status__c, Payment_Amount__c, Total_Number_of_Lines__c from Supplier_Payment__c where id IN :spHdrIDs];
        system.assert(spHdrs.size() == 1, 'Multiple Supplier Payments were created: ' + spHdrs.size());
        system.assert(spHdrs[0].Payment_Amount__c == 265, 'Prepymt created for another amount: ' + spHdrs[0].Payment_Amount__c);
        system.assert(spHdrs[0].Total_Number_of_Lines__c == 2, 'unexpected no of Supplier Payment lines were created: ' + spHdrs[0]);
         
    	//check for prepayment SI status
    	Supplier_Invoice__c si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :pp.id];
        system.assert(si1.Credit_Memo_Balance__c == -275, 'Credit Memo Balance not updated on Prepymt SI: ' + si1.Credit_Memo_Balance__c);
        system.assert(si1.Status__c == 'Closed', 'Prepayment status not updated on Prepymt SI: ' + si1.Status__c);
    	//check for CM status
    	si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :cm.id];
        system.assert(si1.Credit_Memo_Balance__c == 0, 'Credit Memo Balance not updated on Credit Memo SI: ' + si1.Credit_Memo_Balance__c);
        system.assert(si1.Status__c == 'Closed', 'Credit Memo status not updated on Credit Memo SI: ' + si1.Status__c);
         
        //check for SI status
    	si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :si.id];
        system.assertEquals((si1.Balance_due__c == 0 && si1.Amount_Paid__c == 990),true, 'Balance due not updated on Invocie : ' + si1.Balance_due__c + ' Amount Paid : ' + si1.Amount_Paid__c);
        system.assert(si1.Status__c == 'Closed', 'Invoice status not updated on Invocie SI: ' + si1.Status__c);
	}
	//KNDY-17712 - immediate mode Verify  
    static testMethod void testVerifyPaymentImmediateMode(){
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        JsonResult jsResult = new JsonResult();
		List<Supplier_Payment__c> sps = new List<Supplier_Payment__c>();
		List<Supplier_Payment_Line__c> splines = new List<Supplier_Payment_Line__c>();
        //Create supplier
        Supplier__c supp2 = testData.fuel.supplier.clone();
        supp2.Name = 'Supplier-2';
        Supplier__c remitToSupp2 = testData.fuel.remittosupplier.clone();
        remitToSupp2.Name = 'RemitToSupplier-2';
        List<Supplier__c> newSuppliers = new List<Supplier__c> { supp2, remitToSupp2};
        insert newSuppliers;
        supp2.Remit_To__c =  remitToSupp2.id;
        testData.fuel.remittosupplier.Pay_Per_Invoice__c = false;
        remitToSupp2.Pay_Per_Invoice__c = false;
        update new List<Supplier__c>{supp2,testData.fuel.remittosupplier};

        // create SI for a supplier2
        Supplier_Invoice__c siSupplier2 = testData.createSI(PaymentService.TYPE_INVOICE, 1000, 'supp2Invoice', 'Check', testData.fuel.company, remitToSupp2); 
        insert siSupplier2;
        Supplier_Invoice_Line__c siLineSupplier2 = testData.createSILine(1, 1000, siSupplier2, null, null);
        insert siLineSupplier2;
        // approve and finalize SI
        siSupplier2.Status__c = 'Approved';
        siSupplier2.Finalized__c = true;
        siSupplier2.Transaction_Date__c = system.now();
        update siSupplier2;
        
        //SI for supplier1
        Supplier_Invoice__c si = testData.NonPOInvoice;
        
        //Both SIs, 1 per supplier, are chosen for payment batch
        Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(si.Id);
        siSetToTest.add(siSupplier2.Id);
        
        
        // Payments to be created for 2 suppliers
        List<Id> supplierIds = new List<Id>{ testData.fuel.remittosupplier.id,remitToSupp2.id};//
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        for(KendoUtils.FilterDescriptor fd: testData.filters){
            if (fd.field != 'Supplier__c'){            	
                newFilters.add(fd);
            }
            else {
                KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
                filter1.field = 'Supplier__c';
                filter1.fieldType = null;
                filter1.operator = 'contains';
                filter1.value = JSON.serialize(supplierIds);
                newFilters.add(filter1);
            }
        }
        
        Test.startTest();
     
        List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();
        SupplierPaymentService.invoicePaymentWrapper originalSISPRecordsFromUI = new SupplierPaymentService.invoicePaymentWrapper();
        originalSISPRecordsFromUI.invWrapperList = new List<SupplierPaymentService.InvoiceWrapper> ();  
        system.assertEquals(invoiceRecordsFromUI.size() ==5,true,'Incorrect nunmber of SIs fetched : ' +invoiceRecordsFromUI.size());       
        system.debug(LoggingLevel.Error,'invoiceRecordsFromUI==' + invoiceRecordsFromUI);      
        List<String> SIIdList = new List<String>();
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	//if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	
        	if (siWrapper.invoiceRecord.Invoice_Type__c != PaymentService.TYPE_CREDITMEMO && siWrapper.invoiceRecord.Status__c == PaymentService.STATUS_APPROVED)
        		scopeSupInvIdsToPay.put(sID,siWrapper);
        	
        	originalSISPRecordsFromUI.invWrapperList.add(siWrapper);
        	SIIdList.add(siWrapper.invoiceRecord.id);
        } 
        SupplierPaymentService spService = new SupplierPaymentService();
        
        originalSISPRecordsFromUI.dateTimeNow = system.now() +'#';
        //verify if invoices are valid to process or not
		jsResult = PaymentBatchExt.verifySelectedSupplierInvoices(originalSISPRecordsFromUI);
		system.assertEquals(jsResult.success , true, ' wrong result while verification : ' +jsResult);
			
			
        //preview payments
        jsResult = PaymentBatchExt.createSPaymentRealTime(newFilters,scopeSupInvIdsToPay.values(),originalSISPRecordsFromUI);
        system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        List<SupplierPaymentService.invoicePaymentWrapper>  payWrapper= (List<SupplierPaymentService.invoicePaymentWrapper>)jsResult.records;
        system.debug(LoggingLevel.Error,'test method paywrapper : '+payWrapper[0].paymentWrapperList);
        system.assertEquals(payWrapper[0].invWrapperList.size() ==5,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].invWrapperList.size());   
		system.assertEquals(payWrapper[0].paymentWrapperList.size() ==4,true,'Incorrect nunmber of payments ready for preview : ' +payWrapper[0].paymentWrapperList.size()); 
		
		//combine same sourcekey payments
		List<SupplierPaymentService.paymentWithLinesWrapper> payWrapperList = new List<SupplierPaymentService.paymentWithLinesWrapper> ();
		map<string,SupplierPaymentService.paymentWithLinesWrapper> SPmap = new map<string,SupplierPaymentService.paymentWithLinesWrapper>();
		for (SupplierPaymentService.paymentWithLinesWrapper paylineWrapper :payWrapper[0].paymentWrapperList){
			system.debug(LoggingLevel.Error,'Source key : ' +paylineWrapper.supplierPayment.Source_Key__c);
			system.debug(LoggingLevel.Error,'Source key contains: ' +SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c));
			if (!SPmap.containsKey(paylineWrapper.supplierPayment.Source_Key__c)){
				SPmap.put(paylineWrapper.supplierPayment.Source_Key__c,paylineWrapper);				
			}else{
				SPmap.get(paylineWrapper.supplierPayment.Source_Key__c).lstPaymentLines.addAll(paylineWrapper.lstPaymentLines);
			}
			
		}
		system.debug(LoggingLevel.Error,'test method paywrapper after merging common records: '+SPmap.values());
		
		jsResult = PaymentBatchExt.CreateFinalizePaymentsForImmediate(newFilters,testData.supplierPaymentMasterPreviewConfig,SPmap.values());
		payWrapperList = (List<SupplierPaymentService.paymentWithLinesWrapper>)jsResult.records;
		system.debug(LoggingLevel.Error,'result of creating payment realtime : '+jsResult);        
        system.assert(jsResult.success == true, 'Found problem in processing SIs immediate mode: ' + jsResult);
        system.assert(payWrapperList.size() == 2,'incorrect payment wrappers created ' + payWrapperList);
        
        Set<Id> spIds = new Set<Id>();
        List<String> spIdsList = new List<String>();
        Set<Id> SIsRelatedToSPLs = new Set<Id>();
        for (SupplierPaymentService.paymentWithLinesWrapper payWrap :payWrapperList){
        	spIds.add(payWrap.supplierPayment.id);
        	spIdsList.add(payWrap.supplierPayment.id);
        }
        system.assertEquals(spIds.size(), 2, 'Incorrent number of SPs created: spIds - ' + spIds);
        
        //KNDY-19040 update invoices
		PaymentBatchExt.updateSupplierInoiceForFinalizedPayments(SIIdList,spIdsList);
		
		//verify if invoices are valid to process or not
		jsResult = PaymentBatchExt.verifySelectedSupplierInvoices(originalSISPRecordsFromUI);
		system.assertEquals(jsResult.success , false, ' wrong result while verification : ' +jsResult);
			
        Test.stopTest();
        
        system.assert(jsResult.messages.size() > 0,'Error occurred in batch'+jsResult );
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jsResult.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.Supplier_Payment_Preview_Validation_Message)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
    	}
    	system.assertEquals(ErrorExists , true, ' Error occurred while verification : ' +jsResult);
        
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c, Supplier_Invoice__c from Supplier_Payment_Line__c where supplier_invoice__c in :siSetToTest];
        system.assert(splines.size() == 4, 'Found incorrect Payment lines tied to invoices: ' + splines);
        for (Supplier_Payment_Line__c spLine: spLines){
            SIsRelatedToSPLs.add(spLine.Supplier_Invoice__c);
            spIds.add(spLine.supplier_Payment__c);
            if (spLine.type__c == 'Payment')
            	system.assert(spLine.Amount__c == 990, 'Supplier Payment line amount is not correct: ' + spLine.Amount__c);
            if (spLine.type__c == PaymentService.TYPE_EARNED_DISCOUNT)
            	system.assert(spLine.Amount__c == 10, 'Supplier Payment line amount is not correct: ' + spLine.Amount__c);
        }
        system.assertEquals(SIsRelatedToSPLs.size(), siSetToTest.size());
        system.assert(SIsRelatedToSPLs.containsAll(siSetToTest));
        
        system.assertEquals(spIds.size(), 2, 'Incorrent number of SPs created: spIds - ' + spIds);
        sps = [select id, status__c, Transaction_Date__c, Payment_Amount__c from Supplier_Payment__c where id in:spIds];
        system.assertEquals(sps.size(), 2, 'Incorrent number of SPs created: spIds - ' + sps);
        for (Supplier_Payment__c sp: sps){
            system.assert(sp.status__c == 'Applied', 'Supplier Payment status is not correct: ' + sp.status__c);            
            system.assert(sp.Transaction_Date__c != null); //KNDY-10280 KNDY-12343
        }
    }
    
    //KNDY-18888 - consume CM for prepayments
    static testMethod void testVerifyPaymentBatchMode(){
    	PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
    	
    	Test.startTest();
    	
    	//creating credit memo
    	 Supplier_Invoice__c cm = new Supplier_Invoice__c();
		 cm.Invoice_Type__c = 'Credit Memo';
	     cm.Company__c = testData.fuel.company.Id;
	     cm.Supplier__c = testData.fuel.remittosupplier.Id;
	     cm.Currency__c = testData.fuel.company.Default_Transaction_Currency__c;
		 cm.Date_Invoiced__c = system.now();
	     cm.Supplier_Invoice__c = 'test1';
	     cm.Supplier_and_Invoice__c = 'CM-1231';
	     cm.Payment_Method_G__c = 'Cash';
	     cm.Payment_Term__c = testData.paymentTermInfo.id;
	     cm.Invoice_Amount__c = -520;
	     cm.Credit_Memo_Balance__c = -520;
	     cm.Credit_Memo_Amount__c = -520;
	     insert cm;
	        
	     Supplier_Invoice_Line__c cml = new Supplier_Invoice_Line__c();
	     cml.Supplier_Invoice__c = cm.Id;
	     cml.Invoice_Quantity__c = 1;
	     cml.Unit_Price__c = -520;//KNDY-14371
	     cml.Description__c = 'test';
	     insert cml;
	        
	     cm.Status__c = 'Approved';
	     cm.Transaction_Date__c = system.now();
	     update cm;
    	
    	// create SI for a supplier2
        Supplier_Invoice__c siSupplier2 = testData.createSI(PaymentService.TYPE_INVOICE, 1000.00, 'supp2Invoice', 'Cash', testData.fuel.company, testData.fuel.remittosupplier); 
        insert siSupplier2;
        Supplier_Invoice_Line__c siLineSupplier2 = testData.createSILine(1, 1000, siSupplier2, null, null);
        insert siLineSupplier2;
        // approve and finalize SI
        siSupplier2.Status__c = 'Approved';
        siSupplier2.Finalized__c = true;
        siSupplier2.Transaction_Date__c = system.now();
        update siSupplier2;
    	
    	Supplier__c sp = [select Id, Name, Pay_Per_Invoice__c from Supplier__c where Id = :testData.fuel.remittosupplier.id];
    	
    	Set<Id> siSetToTest = new Set<Id>();
        siSetToTest.add(siSupplier2.id);        
        siSetToTest.add(cm.Id);
        Set<Id> supSetToPass = new Set<Id>();
        supSetToPass.add(sp.id);
        
        List<Supplier_Payment_Line__c> splines = [select id, name from Supplier_Payment_Line__c where supplier_invoice__c = :siSupplier2.id or supplier_invoice__c = :cm.id];
        system.assert(splines.size() == 0, 'Found Payment lines tied to invoice');
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        
        for(KendoUtils.FilterDescriptor fd: testData.filters){
        	if (fd.field != 'Discount_Date__c' && fd.field != 'Payment_Due_Date__c' && fd.field != 'Payment_Method_G__c' && fd.field != 'totalCreditsExceedsDebits')
        		newFilters.add(fd);
            KendoUtils.FilterDescriptor filter1 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter2 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter3 = new KendoUtils.FilterDescriptor();
	        KendoUtils.FilterDescriptor filter4 = new KendoUtils.FilterDescriptor();
	        DateTime dtpymtdtd = system.today().addDays(40);
	        DateTime dtdisdtd = system.today().addDays(-10);
	        
            if (fd.field == 'Payment_Due_Date__c'){
        		filter1.field = 'Payment_Due_Date__c';
	            filter1.fieldType = 'date';
	            filter1.operator = 'lte';
	            filter1.value = dtpymtdtd.format('MM/dd/yyy');
	            newFilters.add(filter1);
        	}else if (fd.field == 'Payment_Method_G__c'){
        		filter3.field = 'Payment_Method_G__c';
	            filter3.fieldType = 'string';
	        	filter3.operator = 'eq';
	        	filter3.value = 'Cash';
	            newFilters.add(filter3);
        	}else if (fd.field == 'Discount_Date__c'){
        		filter2.field = 'Discount_Date__c';
	            filter2.fieldType = 'date';
	            filter2.operator = 'lte';
	            filter2.value = dtdisdtd.format('MM/dd/yyy');
	            newFilters.add(filter2);
        	}else if(fd.field == 'totalCreditsExceedsDebits'){
        		filter4.field = 'totalCreditsExceedsDebits';
	            filter4.fieldType = 'boolean';
	            filter4.operator = 'eq';
	            filter4.value = true;
	            newFilters.add(filter4);
        	}
        }
        
        //KNDY-16750
     	List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI = SupplierPaymentService.getSupplierInvoices(newFilters,testData.supplierInvoicePreviewConfig);
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();
        SupplierPaymentService.invoicePaymentWrapper originalSISPRecordsFromUI = new SupplierPaymentService.invoicePaymentWrapper();
        originalSISPRecordsFromUI.invWrapperList = new List<SupplierPaymentService.InvoiceWrapper> ();          
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned; 
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	originalSISPRecordsFromUI.invWrapperList.add(siWrapper);
        	//if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        system.assertEquals(scopeSupInvIdsToPay.size() ==2,true,'wrong scope of invoices fetched : ' + scopeSupInvIdsToPay.size());
        system.assertEquals(originalSISPRecordsFromUI != null,true,'wrong scope of original invoices fetched : ' + originalSISPRecordsFromUI);
	    PaymentBatch jpBatch = new PaymentBatch( newFilters, scopeSupInvIdsToPay, supSetToPass);
        jpBatch.runBatch(null);
        Test.stopTest();
        system.debug(LoggingLevel.Error,'originalSISPRecordsFromUI=' + originalSISPRecordsFromUI);
        JSONResult jsResult = PaymentBatchExt.verifySelectedSupplierInvoices(originalSISPRecordsFromUI);
		system.assertEquals(jsResult.success , false, ' wrong result while verification : ' +jsResult);
			
         
        system.assert(jsResult.messages.size() > 0,'Error occurred in batch'+jsResult );
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jsResult.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.Supplier_Payment_Preview_Validation_Message)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
    	}
    	system.assertEquals(ErrorExists , true, ' Error occurred while verification : ' +jsResult);
    	
        splines = [select id, name, type__c, Amount__c, Supplier_Payment__c from Supplier_Payment_Line__c where supplier_invoice__c =:siSupplier2.id or supplier_invoice__c = :cm.id];
        Set<ID> spHdrIDs = new Set<ID>();
        for (Supplier_Payment_Line__c spl: splines){
        	spHdrIDs.add(spl.Supplier_Payment__c);
        }
        List<Supplier_Payment__c> spHdrs = [select id, status__c, Payment_Amount__c, Total_Number_of_Lines__c from Supplier_Payment__c where id IN :spHdrIDs];
        system.assert(spHdrs.size() == 1, 'Multiple Supplier Payments were created: ' + spHdrs.size());
        system.assert(spHdrs[0].Payment_Amount__c == 470, 'Prepymt created for another amount: ' + spHdrs[0]);
        system.assert(spHdrs[0].Total_Number_of_Lines__c == 3, 'unexpected no of Supplier Payment lines were created: ' + spHdrs[0]);
        //KNDY-17277 - discount earned deprecated
        Supplier_Invoice__c si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :cm.id];
        system.assert(si1.Credit_Memo_Balance__c == 0, 'Credit Memo Balance not updated on Prepymt SI: ' + si1.Credit_Memo_Balance__c);
        system.assert(si1.Status__c == 'Closed', 'Prepayment Status not updated: ' + si1.Status__c); 
        si1 = [select id,name, Status__c, Balance_due__c, Amount_Paid__c, Credit_Memo_Balance__c, Invoice_Type__c, Invoice_Amount__c from Supplier_Invoice__c where ID = :siSupplier2.id];
        system.assert(si1.Balance_Due__c == 0, 'Credit Memo Balance not updated on Prepymt SI: ' + si1.Balance_due__c); 
        system.assert(si1.Status__c == 'Closed', 'Prepayment Status not updated: ' + si1.Status__c);
    	
	}
	//KNDY-18900 bank account next check number validation
	static testMethod void testBankAccountValidationOnCheckNumber(){
    	Test.startTest();
        PaymentBatchExtTestData testData = new PaymentBatchExtTestData();
        boolean errorOccurred = false;
        string errorMsg = '';
        Bank_Account__c ba = new Bank_Account__c();
        ba.Name = 'TESTBNK';
        ba.Company__c = testData.fuel.company.Id;
        ba.Use_Pre_Printed_Check_Stock__c = false;
        ba.Number_of_Advice_Lines_Per_Page__c = 2;
        ba.Next_Check_Number_2__c = '2.3';
        try{
        	insert ba;
        }catch(exception e){
        	errorOccurred = true;
        	errorMsg = e.getMessage();
        }
        system.assertEquals(errorOccurred ,true, 'Bank account successfully inserted  '+ ba);
        system.assertEquals(errorMsg.contains('You can enter only a numeric value in the Next Check Number field.') ,true, 'Bank account successfully inserted  '+ ba);
        errorOccurred = false;
        errorMsg = '';
        ba = testData.bankAccount;
        ba.Use_Pre_Printed_Check_Stock__c = true;
        ba.Number_of_Advice_Lines_Per_Page__c = 2;
        ba.Next_Check_Number_2__c = '2,2';
        try{
        	update ba;
        }catch(exception e){
        	errorOccurred = true;
        	errorMsg = e.getMessage();
        }
        system.assertEquals(errorOccurred ,true, 'Bank account successfully inserted  '+ ba);
        system.assertEquals(errorMsg.contains('You can enter only a numeric value in the Next Check Number field.') ,true, 'Bank account successfully updated  '+ ba);
        
        errorOccurred = false;
        errorMsg = '';
        ba = testData.bankAccount;
        ba.Use_Pre_Printed_Check_Stock__c = true;
        ba.Number_of_Advice_Lines_Per_Page__c = 2;
        ba.Next_Check_Number_2__c = '22';
        try{
        	update ba;
        }catch(exception e){
        	errorOccurred = true;
        	errorMsg = e.getMessage();
        }
        system.assertEquals(errorOccurred ,false, 'Bank account successfully inserted  '+ ba);
        ba = [select id,Next_Check_Number_2__c from Bank_Account__c where id =:testData.bankAccount.id];
        system.assertEquals(ba.Next_Check_Number_2__c ,'22', 'Bank account successfully inserted  '+ ba);
        
	}
}