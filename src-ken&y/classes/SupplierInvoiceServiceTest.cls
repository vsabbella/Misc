/**
 * This class contains unit tests for SupplierInvoiceService.cls
 */
@isTest
private class SupplierInvoiceServiceTest {
	
    static testMethod void testSetDefaultPaymentMethod() {
    	TestData globalTestData = new TestData();
    	globalTestData.remittosupplier.Payment_Method_G__c = 'Credit Card';
    	update globalTestData.remittosupplier;
    	
        Supplier_Invoice__c supplierInvoice = new Supplier_Invoice__c();
        supplierInvoice.Company__c = globalTestData.company.Id;
        supplierInvoice.Date_Invoiced__c = system.now();
        supplierInvoice.Date_Received__c = system.now();
        supplierInvoice.Currency__c = TestFuel.currencyUSD.id;
        supplierInvoice.Invoice_Type__c = 'Invoice';
		supplierInvoice.Supplier__c = globalTestData.remittosupplier.Id;
        supplierInvoice.Supplier_Invoice__c = 'SI-1234';
        supplierInvoice.Invoice_Amount__c = 1000.00;
        
        insert supplierInvoice;
        
        supplierInvoice = [select Id, Payment_Method_G__c, Supplier__r.Payment_Method_G__c 
        					from Supplier_Invoice__c 
        					where Id = :supplierInvoice.Id];
        					
        system.assertEquals(supplierInvoice.Supplier__r.Payment_Method_G__c, supplierInvoice.Payment_Method_G__c);
    }
    
    static testMethod void test_manualCMwithoutPO_Cancel() {
    	TestFuel globaltestdata = new TestFuel();
    	//creating SI
    	Supplier_Invoice__c supplierInvoice = new Supplier_Invoice__c();{
    		supplierInvoice.Company__c = globaltestdata.company.id;
    		supplierInvoice.Supplier__c = globaltestdata.remitToSupplier.id;
    		supplierInvoice.Date_Invoiced__c = system.now();
    		supplierInvoice.Supplier_Invoice__c = '12343';
    		supplierInvoice.Invoice_Type__c = 'Credit Memo';
    		supplierInvoice.Invoice_Amount__c = -200;
    		supplierInvoice.Status__c = 'Incomplete';
    		supplierInvoice.Currency__c = TestFuel.currencyUSD.id;
    		supplierInvoice.Finalized__c = false;
            supplierInvoice.Void__c = false;
            supplierInvoice.Historical__c = false;
    		insert supplierInvoice;
    	}
    	
    	//update item source to Misc
    	list<Item__c> lstItem = [Select Id, Source__c from Item__c where Id in: globaltestdata.ItemList limit 2];
    	for(Item__c item: lstItem){
    		item.Source__c = 'Miscellaneous';
    		item.Non_Inventory__c = true;
    	}
    	update lstItem;
    	
    	//creating SIL
    	List<Supplier_Invoice_Line__c> suppInvLineList = new List<Supplier_Invoice_Line__c>();
        Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c(); 
        suppInvLine1.Supplier_Invoice__c = supplierInvoice.id;
        suppInvLine1.Item__c = lstItem[0].id;
        suppInvLine1.Invoice_Quantity__c = -1; 
        suppInvLine1.Unit_Price__c = 100;
        suppInvLineList.add(suppInvLine1);
        
        Supplier_Invoice_Line__c suppInvLine2 = new Supplier_Invoice_Line__c();
        suppInvLine2.Supplier_Invoice__c = supplierInvoice.id;
        suppInvLine2.Item__c = lstItem[0].id;
        suppInvLine2.Invoice_Quantity__c = -1; 
        suppInvLine2.Unit_Price__c = 100; 
        suppInvLineList.add(suppInvLine2);
        
        insert suppInvLineList;
        
        Test.startTest();
        SupplierInvoiceVoidCancelExt sivoidext = new SupplierInvoiceVoidCancelExt(new ApexPages.standardController(supplierInvoice));
        
        //cancelling SI
        sivoidext.cancelDocs();
        
        system.assert([Select Status__c from Supplier_Invoice__c where Id =:supplierInvoice.Id].Status__c == 'Cancelled');
        Test.stopTest();
    }
    
    static testMethod void test_manualCMwithPO_Cancel() {
    	TestFuel globaltestdata = new TestFuel();
    	Purchase_Order__c purchaseOrder1 = new Purchase_Order__c();
		Purchase_Order__c purchaseOrder2 = new Purchase_Order__c();
	    //creating PO
        purchaseOrder1.Order_Date__c = system.today();
        purchaseOrder1.status__c = 'Open';
        purchaseOrder1.Supplier__c = globaltestdata.supplier.id;
        purchaseOrder1.Remit_To_Supplier__c = globaltestdata.remitToSupplier.id; 
        purchaseOrder1.Company__c = globaltestdata.company.id;
        purchaseOrder1.Payment_Term__c = globaltestdata.terms.id;
        purchaseOrder1.Currency__c = TestFuel.currencyUSD.id;
   
        purchaseOrder2.Order_Date__c = system.today();
        purchaseOrder2.Supplier__c = globaltestdata.supplier.id; 
        purchaseOrder2.Remit_To_Supplier__c = globaltestdata.remitToSupplier.id;
        purchaseOrder2.Company__c = globaltestdata.company.id;
        purchaseOrder2.Payment_Term__c = globaltestdata.terms.id;
        purchaseOrder2.status__c = 'Open';
        purchaseOrder2.Currency__c = TestFuel.currencyUSD.id;

		insert new List<sobject>{purchaseOrder1, purchaseOrder2};

		List<Purchase_Order_Line__c> purchaseOrderLineList = new List<Purchase_Order_Line__c>();
 		
 		//creating POL
 		Purchase_Order_Line__c purchaseOrderLine1 = new Purchase_Order_Line__c();
		purchaseOrderLine1.Purchase_Order__c = purchaseOrder1.Id;
		purchaseOrderLine1.Order_Quantity__c = 10;        
		purchaseOrderLine1.Unit_Price__c = 25;
		purchaseOrderLine1.Item__c = globaltestdata.ItemList[1].Id;
		purchaseOrderLine1.Status__c = Label.Open;    
		purchaseOrderLine1.Need_Date__c = System.today();
		purchaseOrderLine1.Company__c = globaltestdata.company.id;
		purchaseOrderLine1.Line_Type__c = 'Standard';
		purchaseOrderLineList.add(purchaseOrderLine1);                    
		
		Purchase_Order_Line__c purchaseOrderLine2 = new Purchase_Order_Line__c();
		purchaseOrderLine2.Purchase_Order__c = purchaseOrder2.Id;
		purchaseOrderLine2.Order_Quantity__c = 5;        
		purchaseOrderLine2.Unit_Price__c = 15;
		purchaseOrderLine2.Item__c = globaltestdata.ItemList[1].Id;
		purchaseOrderLine2.Status__c = Label.Open;    
		purchaseOrderLine2.Need_Date__c = System.today();
		purchaseOrderLine2.Company__c = globaltestdata.company.id;
		purchaseOrderLine2.Line_Type__c = 'Standard';
		purchaseOrderLineList.add(purchaseOrderLine2);
		
		insert purchaseOrderLineList;
		
    	//creating SI
    	Supplier_Invoice__c supplierInvoice = new Supplier_Invoice__c();{
    		supplierInvoice.Company__c = globaltestdata.company.id;
    		supplierInvoice.Supplier__c = globaltestdata.remitToSupplier.id;
    		supplierInvoice.Date_Invoiced__c = system.now();
    		supplierInvoice.Supplier_Invoice__c = '12343';
    		supplierInvoice.Invoice_Type__c = 'Credit Memo';
    		supplierInvoice.Invoice_Amount__c = -200;
    		supplierInvoice.Status__c = 'Incomplete';
    		supplierInvoice.Currency__c = TestFuel.currencyUSD.id;
    		supplierInvoice.Finalized__c = false;
            supplierInvoice.Void__c = false;
            supplierInvoice.Historical__c = false;
    		insert supplierInvoice;
    	}
    	
    	//update item source to Misc
    	list<Item__c> lstItem = [Select Id, Source__c from Item__c where Id in: globaltestdata.ItemList limit 2];
    	for(Item__c item: lstItem){
    		item.Source__c = 'Miscellaneous';
    		item.Non_Inventory__c = true;
    	}
    	update lstItem;
    	
    	//creating SIL
    	List<Supplier_Invoice_Line__c> suppInvLineList = new List<Supplier_Invoice_Line__c>();
        Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c(); 
        suppInvLine1.Supplier_Invoice__c = supplierInvoice.id;
        suppInvLine1.Item__c = lstItem[0].id;
        suppInvLine1.Invoice_Quantity__c = -1; 
        suppInvLine1.Unit_Price__c = 100;
        suppInvLine1.Purchase_Order__c = purchaseOrder1.id;
        suppInvLine1.Purchase_Order_Line__c = purchaseOrderLineList[0].id;
        suppInvLineList.add(suppInvLine1);
        
        Supplier_Invoice_Line__c suppInvLine2 = new Supplier_Invoice_Line__c();
        suppInvLine2.Supplier_Invoice__c = supplierInvoice.id;
        suppInvLine2.Item__c = lstItem[0].id;
        suppInvLine2.Invoice_Quantity__c = -1; 
        suppInvLine2.Unit_Price__c = 100; 
        suppInvLine2.Purchase_Order__c = purchaseOrder2.id;
        suppInvLine2.Purchase_Order_Line__c = purchaseOrderLineList[1].id;
        suppInvLineList.add(suppInvLine2);
        
        insert suppInvLineList;
        
        Test.startTest();
        SupplierInvoiceVoidCancelExt sivoidext = new SupplierInvoiceVoidCancelExt(new ApexPages.standardController(supplierInvoice));
        
        //cancelling SI
        sivoidext.cancelDocs();
        
        system.assert([Select Status__c from Supplier_Invoice__c where Id =:supplierInvoice.Id].Status__c == 'Cancelled');
        Test.stopTest();
    }
    
    static testMethod void test_manualSIwithoutPO_Cancel() {
    	TestFuel globaltestdata = new TestFuel();
    	//creating SI
    	Supplier_Invoice__c supplierInvoice = new Supplier_Invoice__c();{
    		supplierInvoice.Company__c = globaltestdata.company.id;
    		supplierInvoice.Supplier__c = globaltestdata.remitToSupplier.id;
    		supplierInvoice.Date_Invoiced__c = system.now();
    		supplierInvoice.Supplier_Invoice__c = '12343';
    		supplierInvoice.Invoice_Type__c = 'Invoice';
    		supplierInvoice.Invoice_Amount__c = 200;
    		supplierInvoice.Status__c = 'Incomplete';
    		supplierInvoice.Currency__c = TestFuel.currencyUSD.id;
    		supplierInvoice.Finalized__c = false;
            supplierInvoice.Void__c = false;
            supplierInvoice.Historical__c = false;
    		insert supplierInvoice;
    	}
    	
    	//update item source to Misc
    	list<Item__c> lstItem = [Select Id, Source__c from Item__c where Id in: globaltestdata.ItemList limit 2];
    	for(Item__c item: lstItem){
    		item.Source__c = 'Miscellaneous';
    		item.Non_Inventory__c = true;
    	}
    	update lstItem;
    	
    	//creating SIL
    	List<Supplier_Invoice_Line__c> suppInvLineList = new List<Supplier_Invoice_Line__c>();
        Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c(); 
        suppInvLine1.Supplier_Invoice__c = supplierInvoice.id;
        suppInvLine1.Invoice_Quantity__c = 1;
        suppInvLine1.Unit_Price__c = 100;
        suppInvLine1.Item__c = lstItem[0].id;
        suppInvLineList.add(suppInvLine1);
        
        Supplier_Invoice_Line__c suppInvLine2 = new Supplier_Invoice_Line__c();
        suppInvLine2.Supplier_Invoice__c = supplierInvoice.id;
        suppInvLine2.Invoice_Quantity__c = 1;
        suppInvLine2.Unit_Price__c = 100;
        suppInvLine2.Item__c = lstItem[0].id;
        suppInvLineList.add(suppInvLine2);
        
        insert suppInvLineList;
        
        Test.startTest();
        SupplierInvoiceVoidCancelExt sivoidext = new SupplierInvoiceVoidCancelExt(new ApexPages.standardController(supplierInvoice));
        
        //cancelling SI
        sivoidext.cancelDocs();
        
        system.assert([Select Status__c from Supplier_Invoice__c where Id =:supplierInvoice.Id].Status__c == 'Cancelled');
        Test.stopTest();
    }
    
    static testMethod void test_manualSIwithPO_Cancel() {
    	TestFuel globaltestdata = new TestFuel();
    	Purchase_Order__c purchaseOrder1 = new Purchase_Order__c();
		Purchase_Order__c purchaseOrder2 = new Purchase_Order__c();
	    //creating PO
        purchaseOrder1.Order_Date__c = system.today();
        purchaseOrder1.status__c = 'Open';
        purchaseOrder1.Supplier__c = globaltestdata.supplier.id;
        purchaseOrder1.Remit_To_Supplier__c = globaltestdata.remitToSupplier.id; 
        purchaseOrder1.Company__c = globaltestdata.company.id;
        purchaseOrder1.Payment_Term__c = globaltestdata.terms.id;
        purchaseOrder1.Currency__c = TestFuel.currencyUSD.id;
   
        purchaseOrder2.Order_Date__c = system.today();
        purchaseOrder2.Supplier__c = globaltestdata.supplier.id; 
        purchaseOrder2.Remit_To_Supplier__c = globaltestdata.remitToSupplier.id;
        purchaseOrder2.Company__c = globaltestdata.company.id;
        purchaseOrder2.Payment_Term__c = globaltestdata.terms.id;
        purchaseOrder2.status__c = 'Open';
        purchaseOrder2.Currency__c = TestFuel.currencyUSD.id;

		insert new List<sobject>{purchaseOrder1, purchaseOrder2};

		List<Purchase_Order_Line__c> purchaseOrderLineList = new List<Purchase_Order_Line__c>();
 		
 		//creating POL
 		Purchase_Order_Line__c purchaseOrderLine1 = new Purchase_Order_Line__c();
		purchaseOrderLine1.Purchase_Order__c = purchaseOrder1.Id;
		purchaseOrderLine1.Order_Quantity__c = 10;        
		purchaseOrderLine1.Unit_Price__c = 25;
		purchaseOrderLine1.Item__c = globaltestdata.ItemList[1].Id;
		purchaseOrderLine1.Status__c = Label.Open;    
		purchaseOrderLine1.Need_Date__c = System.today();
		purchaseOrderLine1.Company__c = globaltestdata.company.id;
		purchaseOrderLine1.Line_Type__c = 'Standard';
		purchaseOrderLineList.add(purchaseOrderLine1);                    
		
		Purchase_Order_Line__c purchaseOrderLine2 = new Purchase_Order_Line__c();
		purchaseOrderLine2.Purchase_Order__c = purchaseOrder2.Id;
		purchaseOrderLine2.Order_Quantity__c = 5;        
		purchaseOrderLine2.Unit_Price__c = 15;
		purchaseOrderLine2.Item__c = globaltestdata.ItemList[1].Id;
		purchaseOrderLine2.Status__c = Label.Open;    
		purchaseOrderLine2.Need_Date__c = System.today();
		purchaseOrderLine2.Company__c = globaltestdata.company.id;
		purchaseOrderLine2.Line_Type__c = 'Standard';
		purchaseOrderLineList.add(purchaseOrderLine2);
		
		insert purchaseOrderLineList;
		
    	//creating SI
    	Supplier_Invoice__c supplierInvoice = new Supplier_Invoice__c();{
    		supplierInvoice.Company__c = globaltestdata.company.id;
    		supplierInvoice.Supplier__c = globaltestdata.remitToSupplier.id;
    		supplierInvoice.Date_Invoiced__c = system.now();
    		supplierInvoice.Supplier_Invoice__c = '12343';
    		supplierInvoice.Invoice_Type__c = 'Invoice';
    		supplierInvoice.Invoice_Amount__c = 200;
    		supplierInvoice.Status__c = 'Incomplete';
    		supplierInvoice.Currency__c = TestFuel.currencyUSD.id;
    		supplierInvoice.Finalized__c = false;
            supplierInvoice.Void__c = false;
            supplierInvoice.Historical__c = false;
    		insert supplierInvoice;
    	}
    	
    	//update item source to Misc
    	list<Item__c> lstItem = [Select Id, Source__c from Item__c where Id in: globaltestdata.ItemList limit 2];
    	for(Item__c item: lstItem){
    		item.Source__c = 'Miscellaneous';
    		item.Non_Inventory__c = true;
    	}
    	update lstItem;
    	
    	//creating SIL
    	List<Supplier_Invoice_Line__c> suppInvLineList = new List<Supplier_Invoice_Line__c>();
        Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c(); 
        suppInvLine1.Supplier_Invoice__c = supplierInvoice.id;
        suppInvLine1.Invoice_Quantity__c = 1;
        suppInvLine1.Unit_Price__c = 100;
        suppInvLine1.Item__c = lstItem[0].id;
        suppInvLine1.Purchase_Order__c = purchaseOrder1.id;
        suppInvLine1.Purchase_Order_Line__c = purchaseOrderLineList[0].id;
        suppInvLineList.add(suppInvLine1);
        
        Supplier_Invoice_Line__c suppInvLine2 = new Supplier_Invoice_Line__c();
        suppInvLine2.Supplier_Invoice__c = supplierInvoice.id;
        suppInvLine2.Invoice_Quantity__c = 1;
        suppInvLine2.Unit_Price__c = 100;
        suppInvLine2.Item__c = lstItem[0].id;
        suppInvLine2.Purchase_Order__c = purchaseOrder2.id;
        suppInvLine2.Purchase_Order_Line__c = purchaseOrderLineList[1].id;
        suppInvLineList.add(suppInvLine2);
        
        insert suppInvLineList;
        
        Test.startTest();
        SupplierInvoiceVoidCancelExt sivoidext = new SupplierInvoiceVoidCancelExt(new ApexPages.standardController(supplierInvoice));
        
        //cancelling SI
        sivoidext.cancelDocs();
        
        system.assert([Select Status__c from Supplier_Invoice__c where Id =:supplierInvoice.Id].Status__c == 'Cancelled');
        Test.stopTest();
    }
    
    static testMethod void testValidateTransactionCurrency() {
    	TestFuel globaltestdata = new TestFuel();
    	
    	Purchase_Order__c purchaseOrder1 = new Purchase_Order__c();
		Purchase_Order__c purchaseOrder2 = new Purchase_Order__c();

        purchaseOrder1.Order_Date__c = system.today();
        purchaseOrder1.status__c = 'Open';
        purchaseOrder1.Supplier__c = globaltestdata.supplier.id;
        purchaseOrder1.Remit_To_Supplier__c = globaltestdata.remitToSupplier.id; 
        purchaseOrder1.Company__c = globaltestdata.company.id;
        purchaseOrder1.Payment_Term__c = globaltestdata.terms.id;
        purchaseOrder1.Currency__c = TestFuel.currencyUSD.id;
   
        purchaseOrder2.Order_Date__c = system.today();
        purchaseOrder2.Supplier__c = globaltestdata.supplier.id; 
        purchaseOrder2.Remit_To_Supplier__c = globaltestdata.remitToSupplier.id;
        purchaseOrder2.Company__c = globaltestdata.company.id;
        purchaseOrder2.Payment_Term__c = globaltestdata.terms.id;
        purchaseOrder2.status__c = 'Open';
        purchaseOrder2.Currency__c = TestFuel.currencyCAD.id;

		insert new List<sobject>{purchaseOrder1, purchaseOrder2};

		List<Purchase_Order_Line__c> purchaseOrderLineList = new List<Purchase_Order_Line__c>();
 
 		Purchase_Order_Line__c purchaseOrderLine1 = new Purchase_Order_Line__c();
		purchaseOrderLine1.Purchase_Order__c = purchaseOrder1.Id;
		purchaseOrderLine1.Order_Quantity__c = 10;        
		purchaseOrderLine1.Unit_Price__c = 25;
		purchaseOrderLine1.Item__c = globaltestdata.ItemList[1].Id;
		purchaseOrderLine1.Status__c = Label.Open;    
		purchaseOrderLine1.Need_Date__c = System.today();
		purchaseOrderLine1.Company__c = globaltestdata.company.id;
		purchaseOrderLine1.Line_Type__c = 'Standard';
		purchaseOrderLineList.add(purchaseOrderLine1);                    
		
		Purchase_Order_Line__c purchaseOrderLine2 = new Purchase_Order_Line__c();
		purchaseOrderLine2.Purchase_Order__c = purchaseOrder2.Id;
		purchaseOrderLine2.Order_Quantity__c = 5;        
		purchaseOrderLine2.Unit_Price__c = 15;
		purchaseOrderLine2.Item__c = globaltestdata.ItemList[1].Id;
		purchaseOrderLine2.Status__c = Label.Open;    
		purchaseOrderLine2.Need_Date__c = System.today();
		purchaseOrderLine2.Company__c = globaltestdata.company.id;
		purchaseOrderLine2.Line_Type__c = 'Standard';
		purchaseOrderLineList.add(purchaseOrderLine2);  
		
    	Supplier_Invoice__c supplierInvoice = new Supplier_Invoice__c();{
    		supplierInvoice.Company__c = globaltestdata.company.id;
    		supplierInvoice.Supplier__c = globaltestdata.remitToSupplier.id;
    		supplierInvoice.Date_Invoiced__c = system.now();
    		supplierInvoice.Supplier_Invoice__c = '12343';
    		supplierInvoice.Invoice_Amount__c = 10;
    		supplierInvoice.Status__c = 'Incomplete';
    		supplierInvoice.Currency__c = TestFuel.currencyUSD.id;
    		insert supplierInvoice;
    	}
    	List<Supplier_Invoice_Line__c> suppInvLineList = new List<Supplier_Invoice_Line__c>();
        Supplier_Invoice_Line__c suppInvLine1 = new Supplier_Invoice_Line__c(); 
        suppInvLine1.Supplier_Invoice__c = supplierInvoice.id;
        suppInvLine1.Extended_Cost__c = 100;
        suppInvLine1.Invoice_Quantity__c = 1;
        suppInvLine1.Item__c = globaltestdata.ItemList[1].id;
        suppInvLine1.Purchase_Order__c = purchaseOrder1.id;
        suppInvLine1.Purchase_Order_Line__c = purchaseOrderLineList[0].id;
        suppInvLine1.Quantity_Received__c = 1;
        suppInvLine1.Unit_Price__c = 100; 
        suppInvLineList.add(suppInvLine1);
        
        Supplier_Invoice_Line__c suppInvLine2 = new Supplier_Invoice_Line__c();
        suppInvLine2.Supplier_Invoice__c = supplierInvoice.id;
        suppInvLine2.Extended_Cost__c = 100;
        suppInvLine2.Invoice_Quantity__c = 1;
        suppInvLine2.Item__c = globaltestdata.ItemList[1].id;
        suppInvLine2.Purchase_Order__c = purchaseOrder2.id;
        suppInvLine2.Purchase_Order_Line__c = purchaseOrderLineList[1].id;
        suppInvLine2.Quantity_Received__c = 1;
        suppInvLine2.Unit_Price__c = 100; 
        suppInvLineList.add(suppInvLine2);
        
        try{
        	insert suppInvLineList;
        }catch(Exception ex){
        	system.assert(ex.getMessage().contains('The supplier invoice currency must be the same as the purchase order currency.'));	
        }
        
    }
    
    static testMethod void testExceptionHandlingWithprepayment_2Way() {//KNDY-13435
    	Testfuel globaltestdata = new testFuel();
    	List<Period__c> periodList = globaltestdata.periodList;
    	Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Quantity_Received__c = 20;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 10;
            POLine1.Need_Date__c = System.today();
            POLine1.Invoice_Matching__c = 'Two Way';
        	POLine1.Approved__c = true;
            insert POLine1;
        }
        
         Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
	        si_mrl.Company__c = globalTestData.company.id;
	        si_mrl.Supplier__c = globalTestData.remittosupplier.id;
	        si_mrl.Invoice_Type__c = 'Prepayment';
	        si_mrl.Date_Invoiced__c = system.now();
	        si_mrl.Currency__c = TestFuel.currencyUSD.id;
	        si_mrl.Supplier_Invoice__c = '987612';
	        si_mrl.Payment_Term__c = globalTestData.terms.Id;
	        si_mrl.Invoice_Amount__c = 50;
	        si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
	        si_mrl.Status__c = 'Draft';
	        si_mrl.exception__c = false;
	        si_mrl.exception_Details__c = null;
	        si_mrl.hold__c = false;
        	insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
	        sil_mrl.Purchase_Order_Line__c = POLine1.id;
	        sil_mrl.Item__c = globalTestData.itemList[1].id;
	        sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
	        sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
	        sil_mrl.Description__c = 'test';
	        sil_mrl.Invoice_Quantity__c = 5;
	        sil_mrl.Unit_Price__c = 10;//KNDY-14371
	        sil_mrl.Supplier_Invoice__c = si_mrl.id;
	        sil_mrl.segment_exception__c = false;
	        sil_mrl.price_exception__c = false;
	        sil_mrl.quantity_exception__c = false;
	        sil_mrl.exception_details__c = null;
	        sil_mrl.matched__c = false;
	        insert sil_mrl;   
        } 
        
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c
            from Supplier_Invoice__c where id =: si_mrl.id];
           

        system.assertEquals('Approved',si.status__c); //Invoice should be approved
        
        si_mrl = new Supplier_Invoice__c();{
	        si_mrl.Company__c = globalTestData.company.id;
	        si_mrl.Supplier__c = globalTestData.remittosupplier.id;
	        si_mrl.Invoice_Type__c = 'Invoice';
	        si_mrl.Date_Invoiced__c = system.now();
	        si_mrl.Currency__c = TestFuel.currencyUSD.id;
	        si_mrl.Supplier_Invoice__c = '987612-INv';
	        si_mrl.Payment_Term__c = globalTestData.terms.Id;
	        si_mrl.Invoice_Amount__c = 50;
	        si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
	        si_mrl.Status__c = 'Draft';
	        si_mrl.exception__c = false;
	        si_mrl.exception_Details__c = null;
	        si_mrl.hold__c = false;
        	insert si_mrl;
        }
        
        sil_mrl = new Supplier_Invoice_Line__c();{
	        sil_mrl.Purchase_Order_Line__c = POLine1.id;
	        sil_mrl.Item__c = globalTestData.itemList[1].id;
	        sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
	        sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
	        sil_mrl.Description__c = 'test';
	        sil_mrl.Invoice_Quantity__c = 5;
	        sil_mrl.Unit_Price__c = 10;//KNDY-14371
	        sil_mrl.Supplier_Invoice__c = si_mrl.id;
	        sil_mrl.segment_exception__c = false;
	        sil_mrl.price_exception__c = false;
	        sil_mrl.quantity_exception__c = false;
	        sil_mrl.exception_details__c = null;
	        sil_mrl.matched__c = false;
	        insert sil_mrl;   
        } 
        
        sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectDraftInvoices(sup);
         si = [select id, name, exception__c, exception_details__c, status__c
            from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Approved',si.status__c,[Select Id, Subject from Task where whatId = :sil_mrl.Id]); //Invoice should be approved
    }
    
     static testMethod void testExceptionHandlingWithprepayment_3Way() {//KNDY-13435
    	Testfuel globaltestdata = new testFuel();
    	List<Period__c> periodList = globaltestdata.periodList;
    	Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Quantity_Received__c = 10;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 10;
            POLine1.Need_Date__c = System.today();
            
            insert POLine1;
        }
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            receivingDocument1.Date_Created__c = system.today();
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = 10;
            receiptLine1.Uninvoiced_Quantity__c = 10;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            insert receiptLine1;
        }  
        
         Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
	        si_mrl.Company__c = globalTestData.company.id;
	        si_mrl.Supplier__c = globalTestData.remittosupplier.id;
	        si_mrl.Invoice_Type__c = 'Prepayment';
	        si_mrl.Date_Invoiced__c = system.now();
	        si_mrl.Currency__c = TestFuel.currencyUSD.id;
	        si_mrl.Supplier_Invoice__c = '987612';
	        si_mrl.Payment_Term__c = globalTestData.terms.Id;
	        si_mrl.Invoice_Amount__c = 50;
	        si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
	        si_mrl.Status__c = 'Draft';
	        si_mrl.exception__c = false;
	        si_mrl.exception_Details__c = null;
	        si_mrl.hold__c = false;
        	insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
	        sil_mrl.Purchase_Order_Line__c = POLine1.id;
	        sil_mrl.Item__c = globalTestData.itemList[1].id;
	        sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
	        sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
	        sil_mrl.Description__c = 'test';
	        sil_mrl.Invoice_Quantity__c = 5;
	        sil_mrl.Unit_Price__c = 10;//KNDY-14371
	        sil_mrl.Supplier_Invoice__c = si_mrl.id;
	        sil_mrl.segment_exception__c = false;
	        sil_mrl.price_exception__c = false;
	        sil_mrl.quantity_exception__c = false;
	        sil_mrl.exception_details__c = null;
	        sil_mrl.matched__c = false;
	        insert sil_mrl;   
        } 
        
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c
            from Supplier_Invoice__c where id =: si_mrl.id];
           

        system.assertEquals('Approved',si.status__c); //Invoice should be approved
        
        si_mrl = new Supplier_Invoice__c();{
	        si_mrl.Company__c = globalTestData.company.id;
	        si_mrl.Supplier__c = globalTestData.remittosupplier.id;
	        si_mrl.Invoice_Type__c = 'Invoice';
	        si_mrl.Date_Invoiced__c = system.now();
	        si_mrl.Currency__c = TestFuel.currencyUSD.id;
	        si_mrl.Supplier_Invoice__c = '987612-INv';
	        si_mrl.Payment_Term__c = globalTestData.terms.Id;
	        si_mrl.Invoice_Amount__c = 50;
	        si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
	        si_mrl.Status__c = 'Draft';
	        si_mrl.exception__c = false;
	        si_mrl.exception_Details__c = null;
	        si_mrl.hold__c = false;
        	insert si_mrl;
        }
        
        sil_mrl = new Supplier_Invoice_Line__c();{
	        sil_mrl.Purchase_Order_Line__c = POLine1.id;
	        sil_mrl.Item__c = globalTestData.itemList[1].id;
	        sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
	        sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
	        sil_mrl.Description__c = 'test';
	        sil_mrl.Invoice_Quantity__c = 5;
	        sil_mrl.Unit_Price__c = 10;//KNDY-14371
	        sil_mrl.Supplier_Invoice__c = si_mrl.id;
	        sil_mrl.segment_exception__c = false;
	        sil_mrl.price_exception__c = false;
	        sil_mrl.quantity_exception__c = false;
	        sil_mrl.exception_details__c = null;
	        sil_mrl.matched__c = false;
	        insert sil_mrl;   
        } 
        
        sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);

		 Test.startTest();
        supplierInvoiceService.inspectDraftInvoices(sup);

         si = [select id, name, exception__c, exception_details__c, status__c
            from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Approved',si.status__c,[Select Id, Exception_Code__c, Subject from Task where whatId = :sil_mrl.Id]); //Invoice should be approved
		 Test.stopTest();
    }
    
    //PTP-98 Test method to invoice for full amount when multiple receipt lines are available on the PO
    static testMethod void testMultipleReceiptLinetoInvoice(){
    	Testfuel globaltestdata = new testFuel();
    	List<Period__c> periodList = globaltestdata.periodList;
    	Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Quantity_Received__c = 20;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 10;
            POLine1.Need_Date__c = System.today();
        	POLine1.Invoice_Matching__c = 'Three Way';
        	POLine1.Approved__c = true;
            insert POLine1;
        }
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            receivingDocument1.Date_Created__c = system.today();
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            //receiptLine1.Quantity_Declared__c = POLine.Order_Quantity__c;
            receiptLine1.Quantity_Received__c = 10;
            receiptLine1.Uninvoiced_Quantity__c = 10;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            //insert receiptLine1;
        }  
        
        Receipt_Line__c receiptLine2 = new Receipt_Line__c();{
            receiptLine2.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine2.Purchase_Order_Line__c = POLine1.Id;
            receiptLine2.Item__c = globalTestData.itemList[1].Id;
            receiptLine2.Company__c = globalTestData.company.Id;
            receiptLine2.Supplier__c = globalTestData.supplier.Id;
            //receiptLine2.Quantity_Declared__c = POLine.Order_Quantity__c;
            receiptLine2.Quantity_Received__c = 10;
            receiptLine2.Uninvoiced_Quantity__c = 10;
            receiptLine2.Facility__c = globalTestData.facility.Id;
            receiptLine2.Location__c = globalTestData.location.Id;
            receiptLine2.Receiving_Document__c = receivingDocument1.Id;
            //insert receiptLine2;
        }
        List<Receipt_Line__c> RecLineList = new List<Receipt_Line__c>();
        RecLineList.add(receiptLine1);
        RecLineList.add(receiptLine2);
        insert RecLineList;
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
	        si_mrl.Company__c = globalTestData.company.id;
	        si_mrl.Supplier__c = globalTestData.remittosupplier.id;
	        si_mrl.Invoice_Type__c = 'Invoice';
	        si_mrl.Date_Invoiced__c = system.now();
	        si_mrl.Currency__c = TestFuel.currencyUSD.id;
	        si_mrl.Supplier_Invoice__c = '987612';
	        si_mrl.Payment_Term__c = globalTestData.terms.Id;
	        si_mrl.Invoice_Amount__c = 200;
	        si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
	        si_mrl.Status__c = 'Draft';
	        si_mrl.exception__c = false;
	        si_mrl.exception_Details__c = null;
	        si_mrl.hold__c = false;
        	insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
	        sil_mrl.Purchase_Order_Line__c = POLine1.id;
	        sil_mrl.Item__c = globalTestData.itemList[1].id;
	        sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
	        sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
	        sil_mrl.Description__c = 'test';
	        sil_mrl.Invoice_Quantity__c = 20;
	        sil_mrl.Unit_Price__c = 10;//KNDY-14371
	        sil_mrl.Supplier_Invoice__c = si_mrl.id;
	        sil_mrl.segment_exception__c = false;
	        sil_mrl.price_exception__c = false;
	        sil_mrl.quantity_exception__c = false;
	        sil_mrl.exception_details__c = null;
	        sil_mrl.matched__c = false;
	        insert sil_mrl;   
        } 
        
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];
            Supplier_Invoice_Line__c ril = si.Supplier_Invoice_Lines__r;

        system.assertEquals('Approved',si.status__c); //Invoice should be approved
    }
    
    //PTP-98 Test method to verify if the receipt line has matched = false when the uninvoiced quantity is >0
    static testMethod void testMultipleReceiptLineforMatchedflag(){
    	Testfuel globaltestdata = new testFuel();
    	List<Period__c> periodList = globaltestdata.periodList;
    	Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Quantity_Received__c = 15;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 10;
            POLine1.Need_Date__c = System.today();
        	POLine1.Invoice_Matching__c = 'Three Way';
            insert POLine1;
        }
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            receivingDocument1.Date_Created__c = system.today();
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = 10;
            receiptLine1.Uninvoiced_Quantity__c = 10;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            insert receiptLine1;
        }  
        
        Receipt_Line__c receiptLine2 = new Receipt_Line__c();{
            receiptLine2.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine2.Purchase_Order_Line__c = POLine1.Id;
            receiptLine2.Item__c = globalTestData.itemList[1].Id;
            receiptLine2.Company__c = globalTestData.company.Id;
            receiptLine2.Supplier__c = globalTestData.supplier.Id;
            receiptLine2.Quantity_Received__c = 5;
            receiptLine2.Uninvoiced_Quantity__c = 5;
            receiptLine2.Facility__c = globalTestData.facility.Id;
            receiptLine2.Location__c = globalTestData.location.Id;
            receiptLine2.Receiving_Document__c = receivingDocument1.Id;
            insert receiptLine2;
        }
        List<Receipt_Line__c> RecLineList = new List<Receipt_Line__c>();
        RecLineList.add(receiptLine1);
        RecLineList.add(receiptLine2);
        //insert RecLineList;
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
	        si_mrl.Company__c = globalTestData.company.id;
	        si_mrl.Supplier__c = globalTestData.remittosupplier.id;
	        si_mrl.Invoice_Type__c = 'Invoice';
	        si_mrl.Date_Invoiced__c = system.now();
	        si_mrl.Currency__c = TestFuel.currencyUSD.id;
	        si_mrl.Supplier_Invoice__c = '987612';
	        si_mrl.Payment_Term__c = globalTestData.terms.Id;
	        si_mrl.Invoice_Amount__c = 50;
	        si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
	        si_mrl.Status__c = 'Draft';
	        si_mrl.exception__c = false;
	        si_mrl.exception_Details__c = null;
	        si_mrl.hold__c = false;
        	insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
	        sil_mrl.Purchase_Order_Line__c = POLine1.id;
	        sil_mrl.Item__c = globalTestData.itemList[1].id;
	        sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
	        sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
	        sil_mrl.Description__c = 'test';
	        sil_mrl.Invoice_Quantity__c = 5;
	        sil_mrl.Unit_Price__c = 10;//KNDY-14371
	        sil_mrl.Supplier_Invoice__c = si_mrl.id;
	        sil_mrl.segment_exception__c = false;
	        sil_mrl.price_exception__c = false;
	        sil_mrl.quantity_exception__c = false;
	        sil_mrl.exception_details__c = null;
	        sil_mrl.matched__c = false;
	        insert sil_mrl;   
        } 
        
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];
		system.assertEquals('Approved',si.status__c); //Invoice should be approved
        
        Supplier_Invoice_Line__c sil = si.Supplier_Invoice_Lines__r;
        system.assertEquals(sil.matched__c, true);
		
        decimal uninvoiced = 0, matched = 0;
		for (Receipt_Line__c rlLine: [select id, name, Uninvoiced_Quantity__c, matched__c, Quantity_Received__c 
                                      from Receipt_Line__c where id in :RecLineList 
                                      Order By Receiving_Document__r.Transaction_Date__c ASC]){

            uninvoiced += rlLine.Uninvoiced_Quantity__c;
            if ( rlLine.Matched__c  ) matched++;
		}
        system.assertEquals(10, uninvoiced, ' expected 10 remaining from 15 original' );

    }
    
    //PTP-98 Test method to verify if the invoices are approved accordingly for a PO with multiple lines
    static testMethod void testMultipleInvoicedforReceiptLine(){
    	Testfuel globaltestdata = new testFuel();
    	List<Period__c> periodList = globaltestdata.periodList;
    	Test.startTest();
    	Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Quantity_Received__c = 20;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 10;
            POLine1.Need_Date__c = System.today();
        	POLine1.Invoice_Matching__c = 'Three Way';
            insert POLine1;
        }
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            receivingDocument1.Date_Created__c = system.today();
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = 10;
            receiptLine1.Uninvoiced_Quantity__c = 10;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            //insert receiptLine1;
        }  
        
        Receipt_Line__c receiptLine2 = new Receipt_Line__c();{
            receiptLine2.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine2.Purchase_Order_Line__c = POLine1.Id;
            receiptLine2.Item__c = globalTestData.itemList[1].Id;
            receiptLine2.Company__c = globalTestData.company.Id;
            receiptLine2.Supplier__c = globalTestData.supplier.Id;
            receiptLine2.Quantity_Received__c = 10;
            receiptLine2.Uninvoiced_Quantity__c = 10;
            receiptLine2.Facility__c = globalTestData.facility.Id;
            receiptLine2.Location__c = globalTestData.location.Id;
            receiptLine2.Receiving_Document__c = receivingDocument1.Id;
            //insert receiptLine2;
        }
        List<Receipt_Line__c> RecLineList = new List<Receipt_Line__c>();
        RecLineList.add(receiptLine1);
        RecLineList.add(receiptLine2);
        insert RecLineList;
        
        Supplier_Invoice__c si_mrl1 = new Supplier_Invoice__c();{
	        si_mrl1.Company__c = globalTestData.company.id;
	        si_mrl1.Supplier__c = globalTestData.remittosupplier.id;
	        si_mrl1.Invoice_Type__c = 'Invoice';
	        si_mrl1.Date_Invoiced__c = system.now();
	        si_mrl1.Currency__c = TestFuel.currencyUSD.id;
	        si_mrl1.Supplier_Invoice__c = '987612';
	        si_mrl1.Payment_Term__c = globalTestData.terms.Id;
	        si_mrl1.Invoice_Amount__c = 50;
	        si_mrl1.Purchase_Order__c = globalTestData.PurchaseOrder.id;
	        si_mrl1.Status__c = 'Draft';
	        si_mrl1.exception__c = false;
	        si_mrl1.exception_Details__c = null;
	        si_mrl1.hold__c = false;
        }
        
        Supplier_Invoice__c si_mrl2 = new Supplier_Invoice__c();{
	        si_mrl2.Company__c = globalTestData.company.id;
	        si_mrl2.Supplier__c = globalTestData.remittosupplier.id;
	        si_mrl2.Invoice_Type__c = 'Invoice';
	        si_mrl2.Date_Invoiced__c = system.now();
	        si_mrl2.Currency__c = TestFuel.currencyUSD.id;
	        si_mrl2.Supplier_Invoice__c = '987614';
	        si_mrl2.Payment_Term__c = globalTestData.terms.Id;
	        si_mrl2.Invoice_Amount__c = 100;
	        si_mrl2.Purchase_Order__c = globalTestData.PurchaseOrder.id;
	        si_mrl2.Status__c = 'Draft';
	        si_mrl2.exception__c = false;
	        si_mrl2.exception_Details__c = null;
	        si_mrl2.hold__c = false;
        }
        
        Supplier_Invoice__c si_mrl3 = new Supplier_Invoice__c();{
	        si_mrl3.Company__c = globalTestData.company.id;
	        si_mrl3.Supplier__c = globalTestData.remittosupplier.id;
	        si_mrl3.Invoice_Type__c = 'Invoice';
	        si_mrl3.Date_Invoiced__c = system.now();
	        si_mrl3.Currency__c = TestFuel.currencyUSD.id;
	        si_mrl3.Supplier_Invoice__c = '987613';
	        si_mrl3.Payment_Term__c = globalTestData.terms.Id;
	        si_mrl3.Invoice_Amount__c = 100;
	        si_mrl3.Purchase_Order__c = globalTestData.PurchaseOrder.id;
	        si_mrl3.Status__c = 'Draft';
	        si_mrl3.exception__c = false;
	        si_mrl3.exception_Details__c = null;
	        si_mrl3.hold__c = false;
        }
        
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl1);
        sup.add(si_mrl2);
        sup.add(si_mrl3);
        insert sup;
        
        Supplier_Invoice_Line__c sil_mrl1 = new Supplier_Invoice_Line__c();{
	        sil_mrl1.Purchase_Order_Line__c = POLine1.id;
	        sil_mrl1.Item__c = globalTestData.itemList[1].id;
	        sil_mrl1.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
	        sil_mrl1.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
	        sil_mrl1.Description__c = 'test';
	        sil_mrl1.Invoice_Quantity__c = 5;
	        sil_mrl1.Unit_Price__c = 10;//KNDY-14371
	        sil_mrl1.Supplier_Invoice__c = sup[0].id;
	        sil_mrl1.segment_exception__c = false;
	        sil_mrl1.price_exception__c = false;
	        sil_mrl1.quantity_exception__c = false;
	        sil_mrl1.exception_details__c = null;
	        sil_mrl1.matched__c = false;  
        }
        
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c();{
	        sil_mrl2.Purchase_Order_Line__c = POLine1.id;
	        sil_mrl2.Item__c = globalTestData.itemList[1].id;
	        sil_mrl2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
	        sil_mrl2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
	        sil_mrl2.Description__c = 'test';
	        sil_mrl2.Invoice_Quantity__c = 10;
	        sil_mrl2.Unit_Price__c = 10;//KNDY-14371
	        sil_mrl2.Supplier_Invoice__c = sup[1].id;
	        sil_mrl2.segment_exception__c = false;
	        sil_mrl2.price_exception__c = false;
	        sil_mrl2.quantity_exception__c = false;
	        sil_mrl2.exception_details__c = null;
	        sil_mrl2.matched__c = false;  
        } 
        
        
        Supplier_Invoice_Line__c sil_mrl3 = new Supplier_Invoice_Line__c();{
	        sil_mrl3.Purchase_Order_Line__c = POLine1.id;
	        sil_mrl3.Item__c = globalTestData.itemList[1].id;
	        sil_mrl3.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
	        sil_mrl3.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
	        sil_mrl3.Description__c = 'test';
	        sil_mrl3.Invoice_Quantity__c = 10;
	        sil_mrl3.Unit_Price__c = 10;//KNDY-14371
	        sil_mrl3.Supplier_Invoice__c = sup[2].id;
	        sil_mrl3.segment_exception__c = false;
	        sil_mrl3.price_exception__c = false;
	        sil_mrl3.quantity_exception__c = false;
	        sil_mrl3.exception_details__c = null;
	        sil_mrl3.matched__c = false;  
        }  
        List<Supplier_Invoice_Line__c> supline = new list<Supplier_Invoice_Line__c>();
        supline.add(sil_mrl1);
        supline.add(sil_mrl2);
        supline.add(sil_mrl3);
        insert supline;
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        Supplier_Invoice__c si1 = [select id, name, exception__c, exception_details__c, status__c from Supplier_Invoice__c where id =: sup[0].id];
		Supplier_Invoice__c si2 = [select id, name, exception__c, exception_details__c, status__c from Supplier_Invoice__c where id =: sup[1].id];
		Supplier_Invoice__c si3 = [select id, name, exception__c, exception_details__c, status__c from Supplier_Invoice__c where id =: sup[2].id];

		Test.stopTest();
		system.assertEquals('Approved',si1.status__c); //Invoice should be approved
		system.assertEquals('Approved',si2.status__c); //Invoice should be approved
		system.assertEquals('Draft',si3.status__c); //Invoice should be draft with Quantity Exception
        
    }
    //PTP-281 Freight line exp routed to appropriate user
    static testMethod void testFreightExpAssignment(){
    	
    	Testfuel globaltestdata = new testFuel();
    	List<Period__c> periodList = globaltestdata.periodList;
    	
    	Assignment__c assignment = new Assignment__c();{
    		assignment.Assigned_To_Field__c = 'Purchase_Order_Line__r.Purchase_Order__r.Purchase_Agreement__r.Corporate_Buyer__c';
    		assignment.Exception_Code__c = 'SI-FRGHT000001';
    		assignment.name = 'SI-FRGHT000001';
        	insert assignment;
        }
    	
    	Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
    	User CorpUser = new User(Alias = 'newUser', Email='newuser@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
         LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='Kenandytestuser@testorg.com');
    	insert CorpUser;
    	
    	//User CorpUser = [select id, firstName, LastName, Alias, Email from User where id = user];
    	Contract__c contract = new Contract__c();{
	        contract.Name = 'TestContract';
	        contract.Contract_Start__c = Date.today().addDays(-1);
	        contract.Contract_End__c = Date.today().addDays(10);
	        contract.OwnerID = System.Userinfo.getUserId();
	        contract.Status__c = 'Open';
	        contract.Supplier__c = globalTestData.supplier.id;
	        contract.Company__c = globalTestData.company.Id;
	        contract.Approval_Status__c = 'Approved';
	        contract.Corporate_Buyer__c = CorpUser.id;
	        insert contract;
        }
        
        //Contract Item that is active
        Contract_Line__c contractLine1 = new Contract_Line__c();{
	        contractLine1.Contract__c = contract.Id;
	        contractLine1.Company__c = globalTestData.company.Id;
	        contractLine1.Item__c = globalTestData.itemlist[1].Id;
	        contractLine1.Name = 'Test CTL 1';
	        contractLine1.Contract_Start__c = Date.today().addDays(-1);
	        contractLine1.Contract_End__c = Date.today().addDays(4);
	        contractLine1.Negotiated_Price__c = 10;
	        contractLine1.Contract_Quantity__c = 100;
	        contractLine1.Type__c = 'Fixed';
	        contractLine1.Line__c = 1;
	        contractLine1.Status__c = 'Open';
	        contractLine1.Approved__c = true;
	        insert contractLine1;
        }
		Configuration__c rf = new Configuration__c();{
    		rf.name = 'Contract Release Field';
    		rf.Value__c = 'Remaining_Quantity__c';
    		insert rf;
    	}
    	purchase_order__c purchaseorder = new Purchase_Order__c();{
    		purchaseorder.Supplier__c = globalTestData.supplier.id;
	        purchaseorder.Company__c = globalTestData.company.id;
	        purchaseorder.Payment_Term__c = globalTestData.terms.id;
	        purchaseorder.Delivery_Facility__c = globalTestData.facility2.id;
	        purchaseorder.Delivery_Location__c = globalTestData.location2.ID;
	        purchaseorder.Remit_To_Supplier__c = globalTestData.remitToSupplier.id;
	        purchaseorder.Approval_Status__c = 'Approved';
	        purchaseorder.fob_term__c = globalTestData.fobTerm.id;
	        purchaseorder.Status__c = 'Open';
	        purchaseorder.Purchase_AGreement__c = contract.id;
	        insert purchaseorder;
    	}
    	
    	Test.startTest();
    	Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Purchase_Order__c = purchaseOrder.Id;
            POLine1.Unit_Price__c = 10;
            POLine1.Need_Date__c = System.today();
            POLine1.Contract_Line__c = contractLine1.id;
            POLine1.Invoice_Matching__c = 'Three Way';
            insert POLine1;
        }
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            receivingDocument1.Date_Created__c = system.today();
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = 100;
            receiptLine1.Uninvoiced_Quantity__c = 100;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            insert receiptLine1;
        } 
        
        Supplier_Invoice__c si = new Supplier_Invoice__c();{
	        si.Company__c = globalTestData.company.id;
	        si.Supplier__c = globalTestData.remittosupplier.id;
	        si.Invoice_Type__c = 'Invoice';
	        si.Date_Invoiced__c = system.now();
	        si.Currency__c = TestFuel.currencyUSD.id;
	        si.Supplier_Invoice__c = '987612';
	        si.Payment_Term__c = globalTestData.terms.Id;
	        si.Invoice_Amount__c = 1000;
	        si.Purchase_Order__c = PurchaseOrder.id;
	        si.Status__c = 'Draft';
	        si.exception__c = false;
	        si.exception_Details__c = null;
	        si.hold__c = false;
        }
        
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si);
        insert sup;
        
        Supplier_Invoice_Line__c sil = new Supplier_Invoice_Line__c();{
	        sil.Purchase_Order_Line__c = POLine1.id;
	        sil.Item__c = globalTestData.itemList[1].id;
	        sil.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
	        sil.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
	        sil.Description__c = 'test';
	        sil.Invoice_Quantity__c = 100;
	        sil.Unit_Price__c = 10;//KNDY-14371
	        sil.Supplier_Invoice__c = sup[0].id;
	        sil.segment_exception__c = false;
	        sil.price_exception__c = false;
	        sil.quantity_exception__c = false;
	        sil.exception_details__c = null;
	        sil.matched__c = false;  
        }
        
        Supplier_Invoice_Line__c sil1 = new Supplier_Invoice_Line__c();{
	        sil1.Item__c = globalTestData.FreightItem.id;
	        sil1.Item__r = new Item__c( id= globalTestData.FreightItem.id, Source__c = globalTestData.FreightItem.Source__c, Class__c = globalTestData.FreightItem.Class__c );
	        sil1.Item__r.Class__r = new Class__c( id = globalTestData.FreightClass.id, type__c = globalTestData.FreightClass.type__c );
	        sil1.Description__c = 'test';
	        sil1.Invoice_Quantity__c = 5;
	        sil1.Unit_Price__c = 0;//KNDY-14371
	        sil1.Supplier_Invoice__c = sup[0].id;
	        sil1.segment_exception__c = false;
	        sil1.price_exception__c = false;
	        sil1.quantity_exception__c = false;
	        sil1.exception_details__c = null;
	        sil1.matched__c = false;  
        }
 
        List<Supplier_Invoice_Line__c> supline = new list<Supplier_Invoice_Line__c>();
        supline.add(sil);
        supline.add(sil1);
        insert supline;
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        Supplier_Invoice__c si1 = [select id, name, exception__c, exception_details__c, status__c from Supplier_Invoice__c where id =: sup[0].id];
		Task t = [SELECT Id, Subject, Status, Exception_Code__c, Description, WhatId, OwnerID FROM Task WHERE WhatId = :supline[1].id ];
		
		system.assertEquals('Draft',si1.status__c); //Invoice should be draft with Freight Exception
		system.assertEquals(t.Exception_Code__c, 'SI-FRGHT000001');
		//Freight Exception should be assigned based on the Assignment Custom Setting
		system.assertEquals(t.OwnerID, contract.Corporate_Buyer__c);
        
        //KNDY-6315 Run the batch again to see if the invoices are still draft
        supplierInvoiceService.inspectDraftInvoices(sup);
        si1 = [select id, name, exception__c, exception_details__c, status__c from Supplier_Invoice__c where id =: sup[0].id];
        Test.stopTest();
		system.assertEquals('Draft',si1.status__c); //Invoice should be draft with Freight Exception
    }
    
   
    
    //KNDY-12241
    static testMethod void testCancel_Supplier_And_Invoice() {
        TestFuel fuel = new TestFuel();
        Supplier_Invoice__c suppInv1 = new Supplier_Invoice__c();
            suppInv1.Company__c = fuel.company.id;
            suppInv1.Invoice_Type__c = 'Invoice';
            suppInv1.Date_Invoiced__c = System.now();
            suppInv1.transaction_date__c = system.now();
            suppInv1.Currency__c = TestFuel.currencyUSD.Id;
            suppInv1.Supplier__c = fuel.remittosupplier.id;
            suppInv1.Invoice_Amount__c = 160;
            suppInv1.Supplier_Invoice__c = String.valueOfGmt(system.today());
            suppInv1.Finalized__c = false;
            suppInv1.Void__c = false;
            suppInv1.historical__c = false;
            insert suppInv1;
            suppInv1 = [select id, Supplier_And_Invoice__c from Supplier_Invoice__c where Id = :suppInv1.ID];
            system.assertNotEquals(null, suppInv1.Supplier_And_Invoice__c);
            Test.startTest();
            suppInv1.Status__c = 'Cancelled';
            update suppInv1;
            suppInv1 = [select id, Supplier_And_Invoice__c from Supplier_Invoice__c where Id = :suppInv1.ID];
            //system.assertEquals(null, suppInv1.Supplier_And_Invoice__c);
            Test.stopTest();
        
    }
    
    static testMethod void testVoid_Supplier_And_Invoice() {
        TestFuel fuel = new TestFuel();
        Supplier_Invoice__c suppInv1 = new Supplier_Invoice__c();
            suppInv1.Company__c = fuel.company.id;
            suppInv1.Invoice_Type__c = 'Invoice';
            suppInv1.Date_Invoiced__c = System.now();
            suppInv1.transaction_date__c = system.now();
            suppInv1.Currency__c = TestFuel.currencyUSD.Id;
            suppInv1.Supplier__c = fuel.remittosupplier.id;
            suppInv1.Invoice_Amount__c = 160;
            suppInv1.Supplier_Invoice__c = String.valueOfGmt(system.today());
            suppInv1.Finalized__c = false;
            suppInv1.Void__c = false;
            suppInv1.historical__c = false;
            insert suppInv1;
        
            suppInv1 = [select id, Supplier_And_Invoice__c from Supplier_Invoice__c where Id = :suppInv1.ID];
            system.assertNotEquals(null, suppInv1.Supplier_And_Invoice__c);
            Test.startTest();
            suppInv1.Status__c = 'void';
            update suppInv1;
            suppInv1 = [select id, Supplier_And_Invoice__c from Supplier_Invoice__c where Id = :suppInv1.ID];
            //system.assertEquals(null,suppInv1.Supplier_And_Invoice__c);
            Test.stopTest();
    }
    
    
    //KNDY-7257 Throw segment exception only for SI Lines where Item is blank
    static testMethod void testMissingSegmentsforFreight(){
    	Testfuel globaltestdata = new testFuel();
    	List<Period__c> periodList = globaltestdata.periodList;
    	
    	Class__c miscClass = new Class__c();{
            miscClass.Name = 'Class Misc';
            miscClass.Type__c = 'Miscellaneous';
            insert miscClass;
        }
        
        Item__c item2 = new Item__c();{
            item2.Name = 'testitemmisc';
            item2.Active__c = true;
            item2.Class__c = miscClass.id;
            item2.Company__c = globalTestData.company.Id; 
            item2.Source__c = 'Miscellaneous';
            item2.Non_Inventory__c = true;
            item2.Packaging_UOM__c = JSON.serialize(new List<Id>{ globaltestdata.uomList[8].Id });        
            insert item2;
        }
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
	        si_mrl.Company__c = globalTestData.company.id;
	        si_mrl.Supplier__c = globalTestData.remittosupplier.id;
	        si_mrl.Invoice_Type__c = 'Invoice';
	        si_mrl.Currency__c = TestFuel.currencyUSD.id;
	        si_mrl.Date_Invoiced__c = system.now();
	        si_mrl.Supplier_Invoice__c = 'Test Inv for Line Type';
	        si_mrl.Payment_Term__c = globalTestData.terms.Id;
	        si_mrl.Invoice_Amount__c = 40;
	        si_mrl.Status__c = 'Incomplete';
	        si_mrl.exception__c = false;
	        si_mrl.exception_Details__c = null;
	        si_mrl.hold__c = false;
        	insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
	        sil_mrl.Description__c = 'test';
	        sil_mrl.Invoice_Quantity__c = 20;
	        sil_mrl.Unit_Price__c = 1;//KNDY-14371
	        sil_mrl.Supplier_Invoice__c = si_mrl.id;
	        sil_mrl.segment_exception__c = false;
	        sil_mrl.price_exception__c = false;
	        sil_mrl.quantity_exception__c = false;
	        sil_mrl.exception_details__c = null;
	        sil_mrl.matched__c = false;
	        insert sil_mrl;   
        } 
        
        Supplier_Invoice_Line__c sil_mrl1 = new Supplier_Invoice_Line__c();{
        	sil_mrl1.Item__c = item2.id;
	        sil_mrl1.Item__r = new Item__c( id= item2.id, Source__c = item2.Source__c, Class__c = item2.Class__c );
	        sil_mrl1.Item__r.Class__r = new Class__c( id = miscClass.id, type__c = miscClass.type__c );
	        sil_mrl1.Description__c = 'test';
	        sil_mrl1.Invoice_Quantity__c = 20;
	        sil_mrl1.Unit_Price__c = 1;//KNDY-14371
	        sil_mrl1.Supplier_Invoice__c = si_mrl.id;
	        sil_mrl1.segment_exception__c = false;
	        sil_mrl1.price_exception__c = false;
	        sil_mrl1.quantity_exception__c = false;
	        sil_mrl1.exception_details__c = null;
	        sil_mrl1.matched__c = false;
	        insert sil_mrl1;   
        }
        
        Test.startTest();
        Supplier_Invoice__c si = [select id, name, company__c, supplier__c, exception__c, Line_Exceptions_Count__c, exception_details__c, Payment_Due_Override_Date__c, Date_Invoiced__c, Supplier_Invoice__c, Payment_Term__c,Invoice_Amount__c,
		Status__c, hold__c,   Invoice_Type__c, Total_Extended_Price__c from Supplier_Invoice__c where id =: si_mrl.id];
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si);
        supplierInvoiceService.inspectIncompleteInvoices(sup);
        si = [select id, name, company__c, supplier__c, exception__c, Line_Exceptions_Count__c, exception_details__c, Date_Invoiced__c, Supplier_Invoice__c, Payment_Term__c,Invoice_Amount__c,
		Status__c, hold__c,   Invoice_Type__c, Total_Extended_Price__c from Supplier_Invoice__c where id =: si_mrl.id];
		system.assertEquals(si.Line_Exceptions_Count__c, 1); //Only 1 line should have the segment exception
		system.assertEquals(si.Status__c, 'Incomplete');
		Task t = [SELECT Id, Subject, Status, Exception_Code__c, Description, WhatId, OwnerID FROM Task WHERE WhatId = :sil_mrl.id ];
		system.assertEquals(t.Exception_Code__c, 'SI-SEGMENT001'); //Missing Segment Exception has to be thrown
		Test.stopTest();
    }

    //PTP-465 Tolerance Success scenario:
    //PO for 100 with 10% tolerance, Can be invoiced upto 110
    //SI 1 is for 50 and SI2 is for 60, both the invoices has to be approved as it satisfies the tolerance limit
    static testMethod void testToleraceException_success(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        
        globaltestdata.purchaseorder.Quantity_Tolerance_Over__c = 10;
        update globaltestdata.purchaseorder;

        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 10;
            POLine1.Need_Date__c = System.today();
            POLine1.Quantity_Received__c = 100;
            POLine1.Invoice_Matching__c = 'Three Way';
            insert POLine1;
        }
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            receivingDocument1.Date_Created__c = system.today();
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            //receiptLine1.Quantity_Declared__c = POLine.Order_Quantity__c;
            receiptLine1.Quantity_Received__c = 100;
            receiptLine1.Uninvoiced_Quantity__c = 100;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            //insert receiptLine1;
        }  

        List<Receipt_Line__c> RecLineList = new List<Receipt_Line__c>();
        RecLineList.add(receiptLine1);
        insert RecLineList;

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 500;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 50;
            sil_mrl.Unit_Price__c = 10;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;   
        } 

        Supplier_Invoice__c si_mrl2 = new Supplier_Invoice__c();{
            si_mrl2.Company__c = globalTestData.company.id;
            si_mrl2.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl2.Invoice_Type__c = 'Invoice';
            si_mrl2.Date_Invoiced__c = system.now();
            si_mrl2.Currency__c = TestFuel.currencyUSD.id;
            si_mrl2.Supplier_Invoice__c = '987612a';
            si_mrl2.Payment_Term__c = globalTestData.terms.Id;
            si_mrl2.Invoice_Amount__c = 600;
            si_mrl2.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl2.Status__c = 'Draft';
            si_mrl2.exception__c = false;
            si_mrl2.exception_Details__c = null;
            si_mrl2.hold__c = false;
            insert si_mrl2;
        }
        
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c();{
            sil_mrl2.Purchase_Order_Line__c = POLine1.id;
            sil_mrl2.Item__c = globalTestData.itemList[1].id;
            sil_mrl2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl2.Description__c = 'test';
            sil_mrl2.Invoice_Quantity__c = 50;
            sil_mrl2.Unit_Price__c = 10;//KNDY-14371
            sil_mrl2.Supplier_Invoice__c = si_mrl2.id;
            sil_mrl2.segment_exception__c = false;
            sil_mrl2.price_exception__c = false;
            sil_mrl2.quantity_exception__c = false;
            sil_mrl2.exception_details__c = null;
            sil_mrl2.matched__c = false;
            insert sil_mrl2;   
        } 
        
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        sup.add(si_mrl2);
        Test.startTest();
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];

        system.assertEquals('Approved',si.status__c); //Invoice should be approved

        Supplier_Invoice__c si2 = [select id, name, exception__c, exception_details__c, status__c, has_exceptions__c, has_Line_Exceptions__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl2.id];

        system.assertEquals('Approved',si2.status__c); //Invoice should be approved
        
        Purchase_Order_Line__c polinedata = [select id, Invoice_Status__c from Purchase_Order_Line__c where id = :POLine1.id];
        System.debug(logginglevel.error, 'polinedata.Invoice_Status__c-->'+polinedata.Invoice_Status__c);
        system.assertEquals(polinedata.Invoice_Status__c, 'Open for Invoicing', 'The Order Quantity is not correct'); // Total Quantity = 110, Quantity Invoiced = 100
        Test.stopTest();
        
    }

    //PTP-465 Tolerance failure scenario:
    //PO for 100 with 10% tolerance, Can be invoiced upto 110
    //SI 1 is for 50 and SI2 is for 70, only one of the invoices has to be approved and other has to be in tolerance exception
    static testMethod void testToleraceException_failure(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        
        globaltestdata.purchaseorder.Quantity_Tolerance_Over__c = 10;
        update globaltestdata.purchaseorder;

        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 10;
            POLine1.Need_Date__c = System.today();
            POLine1.Quantity_Received__c = 100;
            POLine1.Invoice_Matching__c = 'Two Way';
            insert POLine1;
        }
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            receivingDocument1.Date_Created__c = system.today();
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            //receiptLine1.Quantity_Declared__c = POLine.Order_Quantity__c;
            receiptLine1.Quantity_Received__c = 100;
            receiptLine1.Uninvoiced_Quantity__c = 100;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            //insert receiptLine1;
        }  

        List<Receipt_Line__c> RecLineList = new List<Receipt_Line__c>();
        RecLineList.add(receiptLine1);
        insert RecLineList;

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 500;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 50;
            sil_mrl.Unit_Price__c = 10;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;   
        } 

        Supplier_Invoice__c si_mrl2 = new Supplier_Invoice__c();{
            si_mrl2.Company__c = globalTestData.company.id;
            si_mrl2.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl2.Invoice_Type__c = 'Invoice';
            si_mrl2.Date_Invoiced__c = system.now();
            si_mrl2.Currency__c = TestFuel.currencyUSD.id;
            si_mrl2.Supplier_Invoice__c = '987612a';
            si_mrl2.Payment_Term__c = globalTestData.terms.Id;
            si_mrl2.Invoice_Amount__c = 700;
            si_mrl2.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl2.Status__c = 'Draft';
            si_mrl2.exception__c = false;
            si_mrl2.exception_Details__c = null;
            si_mrl2.hold__c = false;
            insert si_mrl2;
        }
        
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c();{
            sil_mrl2.Purchase_Order_Line__c = POLine1.id;
            sil_mrl2.Item__c = globalTestData.itemList[1].id;
            sil_mrl2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl2.Description__c = 'test';
            sil_mrl2.Invoice_Quantity__c = 70;
            sil_mrl2.Unit_Price__c = 10;//KNDY-14371
            sil_mrl2.Supplier_Invoice__c = si_mrl2.id;
            sil_mrl2.segment_exception__c = false;
            sil_mrl2.price_exception__c = false;
            sil_mrl2.quantity_exception__c = false;
            sil_mrl2.exception_details__c = null;
            sil_mrl2.matched__c = false;
            insert sil_mrl2;   
        } 
        
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        sup.add(si_mrl2);
        Test.startTest();
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];

        system.assertEquals('Approved',si.status__c); //Invoice should be approved

        Supplier_Invoice__c si2 = [select id, name, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl2.id];

        system.assertEquals('Draft',si2.status__c); //Invoice should be draft since Quanity to be invoiced = 60, Tried to invoice quantity = 70
        
        Purchase_Order_Line__c polinedata = [select id, Invoice_Status__c from Purchase_Order_Line__c where id = :POLine1.id];
        System.debug(logginglevel.error, 'polinedata.Invoice_Status__c-->'+polinedata.Invoice_Status__c);
        system.assertEquals(polinedata.Invoice_Status__c, 'Open for Invoicing', 'The Order Quantity is not correct'); // Total Quantity = 110, Quantity Invoiced = 50

        Test.stopTest();

    }
    
    //PTP-595
    static testMethod void testCMQtyCreditedException(){

        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        
        globaltestdata.purchaseorder.Quantity_Tolerance_Over__c = 10;
        update globaltestdata.purchaseorder;

        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 10;
            POLine1.Need_Date__c = System.today();
            POLine1.Quantity_Received__c = 100;
            POLine1.Quantity_Credited__c = -10;
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Invoice_Type__c = 'Credit Memo';
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = -500;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = -50;
            sil_mrl.Unit_Price__c = 10;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
            insert sil_mrl;   
        } 

        Process_Job__c job = new Process_Job__c(Company__c = globalTestData.company.Id); {
            job.Batch_Size__c = 10;
            insert job;   
        } 

        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);

        SupplierInvoiceDraftInspectBatch jpBatch = new SupplierInvoiceDraftInspectBatch();
        Test.startTest();
        jpBatch.runBatch(job);
        Test.stopTest();
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];

        system.assertEquals('Draft',si.status__c); //Invoice should be draft

        Task t = [SELECT Id, Subject, Status, Exception_Code__c, Description, WhatId, OwnerID FROM Task WHERE WhatId = :sil_mrl.id ];
        system.assertEquals(t.Exception_Code__c, 'SI-CMQTY000002'); //Quantity Credited exception should be thrown


    }
    
    //PTP-650 Three Way - PO is fully received after invoiced with qty more than order qty
    static testMethod void test3WayFullInvoicedFullyReceived_InvoicedQtyOver(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order__c po = globalTestData.purchaseOrder;
        po.Quantity_Tolerance_Over__c = 3; //Can invoice for 3% more than receipt qty
        po.Amount_Tolerance__c = 10;//Invoice Amount can be 10 more
        update po;
        
        // when recd in full, invoice amount can be upto 110
        // when invoiced in full, invoice qty can be upto 103
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Quantity_Matched__c = null;
            POLine1.Amount_Matched__c = null;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Quantity_Received__c = 0; 
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 102; // less than 110 which is the max invoice amount
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 102;// less than 103 which is the max invoice quantity
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectDraftInvoices(sup);
         // No receipts yet, hence the exception
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, Quantity_Exception__c, Price_Exception__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Draft',si.status__c);
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, false);
            system.assertEquals(sil.Exceptions_Count__c, 1); // one exception at a time in Draft inspections
        }
        
        Test.startTest();
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Date_Created__c = system.today();
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = 100;
            receiptLine1.Uninvoiced_Quantity__c = 100;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            insert receiptLine1;
        }
        // Receive POL order quantity in full
        POLine1.Quantity_Received__c = 100; 
        update POLine1;
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, quantity_received__c from Supplier_Invoice_lines__r)
             from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Approved',si.status__c); //Invoice should be approved
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, true);
            system.assertEquals(sil.Exceptions_Count__c, 0);
            system.assertEquals(sil.Quantity_Received__c, 100, '3 Way - expected 100 Qty Received on SIL');
        }
        Test.stopTest();
    }
 
    static testMethod void test3Way_InTransitReceipts(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order__c po = globalTestData.purchaseOrder;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Quantity_Matched__c = null;
            POLine1.Amount_Matched__c = null;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Quantity_Received__c = 0; 
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }

        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Date_Created__c = system.today();
            receivingDocument1.Type__c = 'In Transit';
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = -100;
            receiptLine1.Uninvoiced_Quantity__c = null;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            insert receiptLine1;
        }
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612ASN';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 100; // less than 110 which is the max invoice amount
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 100;// less than 103 which is the max invoice quantity
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);

        Test.startTest();        
        supplierInvoiceService.inspectDraftInvoices(sup);
        Supplier_Invoice__c si = [select id, name, exception__c, status__c,
                                    (select id, Exceptions_Count__c, matched__c,  
                                     Quantity_Received__c,Purchase_Order_Line__c 
                                     from Supplier_Invoice_lines__r) 
                                  from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Draft',si.status__c);
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, false);
            system.assertEquals(sil.Exceptions_Count__c, 1); // one exception at a time in Draft inspections
            system.assertEquals(sil.Quantity_Received__c,0, '3 Way In-Transit RD Matching - expected zero Qty Received on SIL');
        
        }
        Map<Id, Set<Task>> mapExceptionTasks = ExceptionService.fetchExceptionTasks(new Set<Id> {sil_mrl.Id});
        system.assert(mapExceptionTasks.size() == 1);
        system.assert(mapExceptionTasks.containsKey(sil_mrl.Id));
        Set<Task> exceptions = mapExceptionTasks.get(sil_mrl.Id);
        //system.debug('>>> exceptions: ' + exceptions);
        system.assert(exceptions.size() == 1);
        for (Task t: exceptions){
        	   system.assert(t.Description == ExceptionUtil.SI_INVOICE_QUANTITY.Description, t.Exception_Code__c);
        }
        Test.stopTest();
    }
   
    static testMethod void test3Way_ASNReceipts_NoException(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order__c po = globalTestData.purchaseOrder;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Quantity_Matched__c = null;
            POLine1.Amount_Matched__c = null;
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Quantity_Received__c = 0; 
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }

        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Date_Created__c = system.today();
            receivingDocument1.Type__c = 'In Transit';
        }
        Receiving_Document__c receivingDocument2 = new Receiving_Document__c();{
            receivingDocument2 = new Receiving_Document__c();
            receivingDocument2.Company__c = globalTestData.company.Id;
            receivingDocument2.Supplier__c = globalTestData.supplier.Id;
            receivingDocument2.Status__c = 'Open';
            receivingDocument2.Date_Created__c = system.today();
            receivingDocument2.Type__c = 'Purchase Order Receipt';
        }
        List<Receiving_Document__c> rds = new List<Receiving_Document__c>{receivingDocument1, receivingDocument2};           
        insert rds;
                
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = -100;
            receiptLine1.Uninvoiced_Quantity__c = null;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
        }
                
        Receipt_Line__c receiptLine2 = new Receipt_Line__c();{
            receiptLine2.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine2.Purchase_Order_Line__c = POLine1.Id;
            receiptLine2.Item__c = globalTestData.itemList[1].Id;
            receiptLine2.Company__c = globalTestData.company.Id;
            receiptLine2.Supplier__c = globalTestData.supplier.Id;
            receiptLine2.Quantity_Received__c = 100;
            receiptLine2.Uninvoiced_Quantity__c = 100;
            receiptLine2.Facility__c = globalTestData.facility.Id;
            receiptLine2.Location__c = globalTestData.location.Id;
            receiptLine2.Receiving_Document__c = receivingDocument2.Id;
        } 
        List<Receipt_Line__c>  receiptLines = new List<Receipt_Line__c>{receiptLine1, receiptLine2}; 
        insert receiptLines;
        // Receive POL order quantity in full
        POLine1.Quantity_Received__c = 100; 
        update POLine1; 
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Supplier_Invoice__c = '987612ASN';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 100;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 100;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);

        Test.startTest();        
        supplierInvoiceService.inspectDraftInvoices(sup);
        Supplier_Invoice__c si = [select id, name, exception__c, status__c,
                                    (select id, Exceptions_Count__c, matched__c,  
                                     Quantity_Received__c,Purchase_Order_Line__c 
                                     from Supplier_Invoice_lines__r) 
                                  from Supplier_Invoice__c where id =: si_mrl.id];    
        system.assertEquals('Approved',si.status__c);
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, true);
            system.assertEquals(sil.Exceptions_Count__c, null);
            system.assertEquals(sil.Quantity_Received__c,100, '3 Way Matching - expected 100 Qty Received on SIL');
        
        }
        
        List<Receipt_Line__c> rls = [Select id, Name, Matched__c, Purchase_Order_Line__c, Quantity_Received__c,
                                     Uninvoiced_Quantity__c, Receiving_Document__r.Type__c  
                                     From Receipt_Line__c where Id in :receiptLines];
        for (Receipt_Line__c rl: rls){                                    
            if (rl.Receiving_Document__r.Type__c == 'Purchase Order Receipt'){
            	   system.assert(rl.Uninvoiced_Quantity__c == 0);
            	   system.assert(rl.Matched__c);
            }
            else if (rl.Receiving_Document__r.Type__c == 'In Transit'){
               system.assert(!rl.Matched__c);
            }
        }
        Test.stopTest();
    }   
    
    static testMethod void test3Way_ASNReceipts_WithException(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order__c po = globalTestData.purchaseOrder;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Quantity_Received__c = 0; 
            //POLine1.Quantity_Uninvoiced__c = 96;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }

        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Date_Created__c = system.today();
            receivingDocument1.Type__c = 'In Transit';
        }
        Receiving_Document__c receivingDocument2 = new Receiving_Document__c();{
            receivingDocument2 = new Receiving_Document__c();
            receivingDocument2.Company__c = globalTestData.company.Id;
            receivingDocument2.Supplier__c = globalTestData.supplier.Id;
            receivingDocument2.Status__c = 'Open';
            receivingDocument2.Date_Created__c = system.today();
            receivingDocument2.Type__c = 'Purchase Order Receipt';
        }
        List<Receiving_Document__c> rds = new List<Receiving_Document__c>{receivingDocument1, receivingDocument2};           
        insert rds;
                
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = -100;
            receiptLine1.Uninvoiced_Quantity__c = null;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
        }
                
        Receipt_Line__c receiptLine2 = new Receipt_Line__c();{
            receiptLine2.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine2.Purchase_Order_Line__c = POLine1.Id;
            receiptLine2.Item__c = globalTestData.itemList[1].Id;
            receiptLine2.Company__c = globalTestData.company.Id;
            receiptLine2.Supplier__c = globalTestData.supplier.Id;
            receiptLine2.Quantity_Received__c = 2;
            receiptLine2.Uninvoiced_Quantity__c = 2;
            receiptLine2.Facility__c = globalTestData.facility.Id;
            receiptLine2.Location__c = globalTestData.location.Id;
            receiptLine2.Receiving_Document__c = receivingDocument2.Id;
        } 
        List<Receipt_Line__c>  receiptLines = new List<Receipt_Line__c>{receiptLine1, receiptLine2}; 
        insert receiptLines;
        
        POLine1.Quantity_Received__c = 2;
        update POLine1; 
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Supplier_Invoice__c = '987612ASN';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 4;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 3;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c();{
            sil_mrl2.Purchase_Order_Line__c = POLine1.id;
            sil_mrl2.Item__c = globalTestData.itemList[1].id;
            sil_mrl2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl2.Description__c = 'test';
            sil_mrl2.Invoice_Quantity__c = 1;
            sil_mrl2.Unit_Price__c = 1;//KNDY-14371
            sil_mrl2.Supplier_Invoice__c = si_mrl.id;
            sil_mrl2.segment_exception__c = false;
            sil_mrl2.price_exception__c = false;
            sil_mrl2.quantity_exception__c = false;
            sil_mrl2.exception_details__c = null;
            sil_mrl2.matched__c = false;
        }        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl,sil_mrl2};
        insert supILs; 
     
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);

        Test.startTest();        
        supplierInvoiceService.inspectDraftInvoices(sup);
        Supplier_Invoice__c si = [select id, name, exception__c, status__c,
                                    (select id, Exceptions_Count__c, matched__c,  
                                     Quantity_Received__c,Purchase_Order_Line__c 
                                     from Supplier_Invoice_lines__r) 
                                  from Supplier_Invoice__c where id =: si_mrl.id];    
        system.assertEquals('Draft',si.status__c);
        Decimal silQtyReceived = 0;
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
        	   if (sil.Quantity_Received__c != null){
        	       silQtyReceived += sil.Quantity_Received__c;
        	   }
        }
        system.assertEquals(silQtyReceived, 2);

        Map<Id, Set<Task>> mapExceptionTasks = ExceptionService.fetchExceptionTasks(new Set<Id> {sil_mrl.Id});
        system.assert(mapExceptionTasks.size() == 1);
        system.assert(mapExceptionTasks.containsKey(sil_mrl.Id));
        Set<Task> exceptions = mapExceptionTasks.get(sil_mrl.Id);
        //system.debug('>>> exceptions: ' + exceptions);
        system.assert(exceptions.size() == 2);
        Set<String> expectedExceptionCodes = new Set<String>{'SI-INVQTY000001', 'SI-AMOUNTOVER000001'};
        Set<String> actualExceptionCodes = new Set<String>();
        for (Task t: exceptions){
        	   actualExceptionCodes.add(t.Exception_Code__c);
        }
        system.assert(expectedExceptionCodes.containsAll(actualExceptionCodes));
        
        // In-Transit RDs are not considered during matching       
        List<Receipt_Line__c> rls = [Select id, Name, Matched__c, Purchase_Order_Line__c, Quantity_Received__c,
                                     Uninvoiced_Quantity__c, Receiving_Document__r.Type__c  
                                     From Receipt_Line__c where Id in :receiptLines];
        for (Receipt_Line__c rl: rls){                                    
            if (rl.Receiving_Document__r.Type__c == 'Purchase Order Receipt'){
                   system.assert(rl.Uninvoiced_Quantity__c == 0);
                   system.assert(rl.Matched__c);
            }
            else if (rl.Receiving_Document__r.Type__c == 'In Transit'){
               system.assert(!rl.Matched__c);
            }
        }
        Test.stopTest();   
    }
       
    static testMethod void test2WayFullInvoicedFullyReceived_InvoiceQtyOver(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order__c po = globalTestData.purchaseOrder;
        po.Quantity_Tolerance_Over__c = 3;//Can invoice for 3% more than receipt qty
        po.Amount_Tolerance__c = 10;//Invoice Amount can be 10 more
        update po;
        
        // when recd in full, no checks for Two Way POL
        // when invoiced in full, invoice qty can be upto 103, invoice amount can be upto 110
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 104;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 104; // greater than max invoice quantity of 103
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        // Exception as Invoice quanity is higher than 103
        // No Amount Exception
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, Quantity_Exception__c, Price_Exception__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Draft',si.status__c); 
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, false);
            system.assertEquals(sil.Exceptions_Count__c, 1); // one exception at a time in Draft inspections
        }
        
        Test.startTest();
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Date_Created__c = system.today();
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = 100;
            receiptLine1.Uninvoiced_Quantity__c = 100;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            insert receiptLine1;
        }
        //receive in full
        POLine1.Quantity_Received__c = 100;
        update POLine1;
        
        // No change in SI exceptions due to receipts
        // Qty Received is not updated on SIL for 2-way
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Draft',si.status__c);
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, false);
            system.assertEquals(sil.Exceptions_Count__c, 1);
            system.assertEquals(sil.Quantity_Received__c, 0, '2 Way - expected 0 Qty Received on SIL');
        }
        Test.stopTest();
    }
    
    //PTP-402 Two Way - PO is fully received and partially invoiced with multiple SILs
    static testMethod void test2WayFullyReceivedPartiallyInvoiced(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 20;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            POLine1.Approved__c = true;
            insert POLine1;
        }
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Date_Created__c = system.today();
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = 20;
            receiptLine1.Uninvoiced_Quantity__c = 20;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            insert receiptLine1;
        }  
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 3;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 1;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c(
            Purchase_Order_Line__c = POLine1.id,
            Item__c = globalTestData.itemList[1].id,
            Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c ),
            //Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c ),
            Description__c = 'test',
            Invoice_Quantity__c = 1,
            Unit_Price__c = 1,//KNDY-14371
            Supplier_Invoice__c = si_mrl.id,
            segment_exception__c = false,
            price_exception__c = false,
            quantity_exception__c = false,
            exception_details__c = null,
            matched__c = false
        );
        
        Supplier_Invoice_Line__c sil_mrl3 = new Supplier_Invoice_Line__c(
            Purchase_Order_Line__c = POLine1.id,
            Item__c = globalTestData.itemList[1].id,
            Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c ),
            Description__c = 'test',
            Invoice_Quantity__c = 1,
            Unit_Price__c = 1,//KNDY-14371
            Supplier_Invoice__c = si_mrl.id,
            segment_exception__c = false,
            price_exception__c = false,
            quantity_exception__c = false,
            exception_details__c = null,
            matched__c = false
        );
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl,sil_mrl2,sil_mrl3};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        Test.startTest();
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Approved',si.status__c); 
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, true);
            system.assertEquals(sil.Quantity_Received__c, 0, '2-Way - expected 0 Qty Received on SIL');
        }
        decimal uninvoiced = 0, matched = 0;
        for (Receipt_Line__c rlLine: [select id, name, Uninvoiced_Quantity__c, matched__c, Quantity_Received__c 
                                      from Receipt_Line__c where id = :receiptLine1.Id 
                                      Order By Receiving_Document__r.Transaction_Date__c ASC]){
            uninvoiced += rlLine.Uninvoiced_Quantity__c;
            if ( rlLine.Matched__c  ) matched++;
        }
        // Receipt Lines Uninvoiced Qty is not reset for Two Way Matching
        system.assertEquals(20, uninvoiced, ' 2-Way - expected 20 Uninvoiced Qty on Receipts' );
        system.assertEquals(0, matched, ' 2-Way - expected 0 matched receipts' );
        Test.stopTest();
    }
    
    static testMethod void test2Way_NonApprovedPOL(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;        
        Source_Document_Approval__c sd = new Source_Document_Approval__c();{
            sd.Name = 'Purchase Order';
            sd.Allow_Approval__c = true;
            insert sd;
        }   
        Purchase_Order__c po = new Purchase_Order__c(
           Supplier__c = globaltestdata.supplier.id, 
           Company__c = globaltestdata.company.id,
           Payment_Term__c = globaltestdata.terms.id,
           Delivery_Facility__c = globaltestdata.facility2.id,
           Delivery_Location__c = globaltestdata.location2.ID,
           Remit_To_Supplier__c = globaltestdata.remitToSupplier.id,
           Approval_Status__c = 'Pending Approval',
           Status__c = 'Open'
        );
        insert po;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            POLine1.Approved__c = false;
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 100;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Incomplete';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
        	sil_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 100;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl};
        insert supILs;
        Test.startTest(); 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectIncompleteInvoices(sup);
        Supplier_Invoice__c si = [select id, name, exception__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c from Supplier_Invoice_lines__r) 
            from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Incomplete',si.status__c); 
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, false);
            system.assertEquals(sil.Exceptions_Count__c, 1);
        }
        Map<Id, Set<Task>> mapExceptionTasks = ExceptionService.fetchExceptionTasks(new Set<Id> {sil_mrl.Id});
        system.assert(mapExceptionTasks.size() == 1);
        system.assert(mapExceptionTasks.containsKey(sil_mrl.Id));
        Set<Task> exceptions = mapExceptionTasks.get(sil_mrl.Id);
        system.assert(exceptions.size() == 1);
        for (Task t: exceptions){
            system.assert(t.Exception_Code__c == 'SI-PO_NA_0001');
        }      
        Test.stopTest();      
    }
    
    
    //PTP-402 Two Way Matching when other matched SIs exist
    static testMethod void test2Way_RunJobOnMatchedAndUnmatchedSI(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order__c po = globalTestData.purchaseOrder;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            //POLine1.Quantity_Uninvoiced__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }
        // Insert SIs with total invoice qty == 20
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 6;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        }
        Supplier_Invoice__c si_mrl2 = new Supplier_Invoice__c();{
            si_mrl2.Company__c = globalTestData.company.id;
            si_mrl2.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl2.Invoice_Type__c = 'Invoice';
            si_mrl2.Date_Invoiced__c = system.now();
            si_mrl2.Currency__c = TestFuel.currencyUSD.id;
            si_mrl2.Supplier_Invoice__c = 'TEST_SIST2';
            si_mrl2.Payment_Due_Override_Date__c = system.now().date();
            si_mrl2.Payment_Term__c = globalTestData.terms.Id;
            si_mrl2.Invoice_Amount__c = 14;
            si_mrl2.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl2.Status__c = 'Draft';
            si_mrl2.exception__c = false;
            si_mrl2.exception_Details__c = null;
            si_mrl2.hold__c = false;
        }
        List<Supplier_Invoice__c> sis = new List<Supplier_Invoice__c> {si_mrl,si_mrl2};
        insert sis;
        
        // SILs for 1st SI, total quantity == 6
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 1; 
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c();{
            sil_mrl2.Purchase_Order_Line__c = POLine1.id;
            sil_mrl2.Item__c = globalTestData.itemList[1].id;
            sil_mrl2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl2.Description__c = 'test';
            sil_mrl2.Invoice_Quantity__c = 2; 
            sil_mrl2.Unit_Price__c = 1;//KNDY-14371
            sil_mrl2.Supplier_Invoice__c = si_mrl.id;
            sil_mrl2.segment_exception__c = false;
            sil_mrl2.price_exception__c = false;
            sil_mrl2.quantity_exception__c = false;
            sil_mrl2.exception_details__c = null;
            sil_mrl2.matched__c = false;
        }
        Supplier_Invoice_Line__c sil_mrl3 = new Supplier_Invoice_Line__c();{
            sil_mrl3.Purchase_Order_Line__c = POLine1.id;
            sil_mrl3.Item__c = globalTestData.itemList[1].id;
            sil_mrl3.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl3.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl3.Description__c = 'test';
            sil_mrl3.Invoice_Quantity__c = 3; 
            sil_mrl3.Unit_Price__c = 1;//KNDY-14371
            sil_mrl3.Supplier_Invoice__c = si_mrl.id;
            sil_mrl3.segment_exception__c = false;
            sil_mrl3.price_exception__c = false;
            sil_mrl3.quantity_exception__c = false;
            sil_mrl3.exception_details__c = null;
            sil_mrl3.matched__c = false;
        } 
        // Insert SILs for 2nd SI,total invoice qty == 14
        Supplier_Invoice_Line__c sil_mrl1_2 = new Supplier_Invoice_Line__c();{
            sil_mrl1_2.Purchase_Order_Line__c = POLine1.id;
            sil_mrl1_2.Item__c = globalTestData.itemList[1].id;
            sil_mrl1_2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl1_2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl1_2.Description__c = 'test';
            sil_mrl1_2.Invoice_Quantity__c = 10; 
            sil_mrl1_2.Unit_Price__c = 1;//KNDY-14371
            sil_mrl1_2.Supplier_Invoice__c = si_mrl2.id;
            sil_mrl1_2.segment_exception__c = false;
            sil_mrl1_2.price_exception__c = false;
            sil_mrl1_2.quantity_exception__c = false;
            sil_mrl1_2.exception_details__c = null;
            sil_mrl1_2.matched__c = false;
        }
        Supplier_Invoice_Line__c sil_mrl2_2 = new Supplier_Invoice_Line__c();{
            sil_mrl2_2.Purchase_Order_Line__c = POLine1.id;
            sil_mrl2_2.Item__c = globalTestData.itemList[1].id;
            sil_mrl2_2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl2_2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl2_2.Description__c = 'test';
            sil_mrl2_2.Invoice_Quantity__c = 2; 
            sil_mrl2_2.Unit_Price__c = 1;//KNDY-14371
            sil_mrl2_2.Supplier_Invoice__c = si_mrl2.id;
            sil_mrl2_2.segment_exception__c = false;
            sil_mrl2_2.price_exception__c = false;
            sil_mrl2_2.quantity_exception__c = false;
            sil_mrl2_2.exception_details__c = null;
            sil_mrl2_2.matched__c = false;
        }
        Supplier_Invoice_Line__c sil_mrl3_2 = new Supplier_Invoice_Line__c();{
            sil_mrl3_2.Purchase_Order_Line__c = POLine1.id;
            sil_mrl3_2.Item__c = globalTestData.itemList[1].id;
            sil_mrl3_2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl3_2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl3_2.Description__c = 'test';
            sil_mrl3_2.Invoice_Quantity__c = 2; 
            sil_mrl3_2.Unit_Price__c = 1;//KNDY-14371
            sil_mrl3_2.Supplier_Invoice__c = si_mrl2.id;
            sil_mrl3_2.segment_exception__c = false;
            sil_mrl3_2.price_exception__c = false;
            sil_mrl3_2.quantity_exception__c = false;
            sil_mrl3_2.exception_details__c = null;
            sil_mrl3_2.matched__c = false;
        } 
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl,sil_mrl2,sil_mrl3,sil_mrl1_2,sil_mrl2_2,sil_mrl3_2};
        insert supILs;
        
        // Reset POL`s Qty Uninvoiced
        //POLine1.Quantity_Uninvoiced__c = 0;
        //update POLine1;

        // Run job on unmatched SI - the first SI        
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        supplierInvoiceService.inspectDraftInvoices(sup);

        Supplier_Invoice__c si = [select id, name, status__c, Finalized__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, 
              Invoice_Quantity__c from Supplier_Invoice_lines__r) 
             from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Approved',si.status__c);
        system.assert(si.Finalized__c); 
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, true);
        }
        
        Test.startTest();    
        //Run job on Matched and Unmatched SIs        
        sup = new List<Supplier_Invoice__c>{si_mrl,si_mrl2};
        supplierInvoiceService.inspectDraftInvoices(sup);

        List<Supplier_Invoice__c> siList = [select id, name, status__c, Finalized__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, 
              Invoice_Quantity__c from Supplier_Invoice_lines__r) 
             from Supplier_Invoice__c where id in : sup];
        for (Supplier_Invoice__c sInv : siList){
	        system.assertEquals('Approved',sInv.status__c);
	        system.assert(sInv.Finalized__c); 
	        for (Supplier_Invoice_Line__c sil : sInv.Supplier_Invoice_Lines__r){
	            system.assertEquals(sil.matched__c, true);
	        }
        }        
        Test.stopTest();   
    }

    //PTP-402 Two Way - Over Invoice a PO Line
    static testMethod void test2Way_OverInvoicePOL(){
        Testfuel globaltestdata = new testFuel();
        Set<String> expectedExceptionCodes = new Set<String>{'SI-INVQTY000002', 'SI-AMOUNTOVER000002'};
        //Exception task should be assigned to specified user in custom setting
        Assignment__c assignment = new Assignment__c();{
            assignment.Assigned_To_Field__c = 'Purchase_Order_Line__r.Purchase_Order__r.Buyer__c';
            assignment.Exception_Code__c = 'SI-INVQTY000002';
            assignment.name = 'SI-INVQTY000002';
            insert assignment;
        }
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User CorpUser = new User(Alias = 'newUser', Email='newuser@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
         LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='Kenandytestuser@testorg.com');
        insert CorpUser;
        
        List<Period__c> periodList = globaltestdata.periodList;
        
        // Change Buyer on PO to another User
        Purchase_Order__c po = globalTestData.purchaseOrder;
        po.Buyer__c = CorpUser.Id;
        update po;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 20;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 21; // POL Order Qty was 20
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 21;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        // Set POL Qty Uninvoiced
        //POLine1.Quantity_Uninvoiced__c = -1;
        //update POLine1;
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        Test.startTest();
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        Supplier_Invoice__c si = [select id, name, exception__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c from Supplier_Invoice_lines__r) 
            from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Draft',si.status__c); 
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, false);
            system.assertEquals(sil.Exceptions_Count__c, 2);
        }
        
       List<Task> exceptions = [SELECT Id, Subject, Status, Exception_Code__c, 
                    Description, WhatId, OwnerId FROM Task 
                       WHERE WhatId = :sil_mrl.Id
                       AND Status = :TaskType.EXCEPTION_STATUS_OPEN 
                       AND WhatId != null
                      AND Type = 'Exception'];
        system.assert(exceptions.size() == 2);
        for (Task t: exceptions){
            system.assert(expectedExceptionCodes.contains(t.Exception_Code__c));
            if (t.Exception_Code__c == 'SI-INVQTY000002'){
                system.assert(t.OwnerId == CorpUser.Id);
            }
        }      
        Test.stopTest();   
    }
    
    static testMethod void test2Way_ChangeSIQty(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order__c po = globalTestData.purchaseOrder;
        po.Quantity_Tolerance_Over__c = null;
        po.Amount_Tolerance__c = 10;//Invoice Amount can be 10 more
        update po;
        
        // when recd in full, no checks for Two Way POL
        // when invoiced in full, invoice qty can be upto 103, invoice amount can be upto 110
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            POLine1.Status__c = 'Open';
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 21;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 21; // greater than max invoice quantity of 20
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        // Set Qty bucket on POL
        //POLine1.Quantity_Uninvoiced__c = -1;
        //update POLine1;
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        // Exception as Invoice quanity is higher than 20
        // No Amount Exception
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, Quantity_Exception__c, Price_Exception__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Draft',si.status__c); 
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, false);
            system.assertEquals(sil.Exceptions_Count__c, 1); // one exception at a time in Draft inspections
        }
        Map<Id, Set<Task>> mapExceptionTasks = ExceptionService.fetchExceptionTasks(new Set<Id> {sil_mrl.Id});
        system.assert(mapExceptionTasks.size() == 1);
        system.assert(mapExceptionTasks.containsKey(sil_mrl.Id));
        Set<Task> exceptions = mapExceptionTasks.get(sil_mrl.Id);
        system.assert(exceptions.size() == 1);
        for (Task t: exceptions){
            system.assert(t.Exception_Code__c == 'SI-INVQTY000002');
        }  
        
        Test.startTest();
        si_mrl.Invoice_Amount__c = 20;
        update si_mrl;
        sil_mrl.Invoice_Quantity__c = 20;
        update sil_mrl;
        POLine1 = [Select Id  from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        system.assert(POLine1.id != null);  
        Test.stopTest();
    } 
    
    //PTP-402 Two Way - Multiple lines on 1 invoice, one line has exceptions
    static testMethod void test2WayMulitpleSILs_OneExceptionLine(){
        Integer matchedSILs = 0;
        Integer exceptionSILs = 0;
        Integer expectedMatchedSILs = 2;
        Integer expectedSILsWithException = 1;
        
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            POLine1.Approved__c = true;
            insert POLine1;
        }
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 21; //Over Invoice
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 10;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c(
            Purchase_Order_Line__c = POLine1.id,
            Item__c = globalTestData.itemList[1].id,
            Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c ),
            //Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c ),
            Description__c = 'test',
            Invoice_Quantity__c = 5,
            Unit_Price__c = 1,//KNDY-14371
            Supplier_Invoice__c = si_mrl.id,
            segment_exception__c = false,
            price_exception__c = false,
            quantity_exception__c = false,
            exception_details__c = null,
            matched__c = false
        );
        
        Supplier_Invoice_Line__c sil_mrl3 = new Supplier_Invoice_Line__c(
            Purchase_Order_Line__c = POLine1.id,
            Item__c = globalTestData.itemList[1].id,
            Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c ),
            Description__c = 'test',
            Invoice_Quantity__c = 6,
            Unit_Price__c = 1,//KNDY-14371
            Supplier_Invoice__c = si_mrl.id,
            segment_exception__c = false,
            price_exception__c = false,
            quantity_exception__c = false,
            exception_details__c = null,
            matched__c = false
        );
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl,sil_mrl2,sil_mrl3};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        Test.startTest();
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c
             from Supplier_Invoice_lines__r) from Supplier_Invoice__c 
             where id =: si_mrl.id];
        system.assertEquals('Draft',si.status__c);
         
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            if (sil.matched__c == true){
            	   matchedSILs ++;
            }
            else{
            	   system.assert(sil.Exceptions_Count__c != null);
            	   system.assert(sil.Exceptions_Count__c != 0);
            	   exceptionSILs ++;
            }
        }
        system.assertEquals(matchedSILs, expectedMatchedSILs);
        system.assertEquals(exceptionSILs, expectedSILsWithException);
        Test.stopTest();
    }
   
    //PTP-402 Two Way - cancel SI
    static testMethod void test2WayCancelSI(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 6;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 3;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c(
            Purchase_Order_Line__c = POLine1.id,
            Item__c = globalTestData.itemList[1].id,
            Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c ),
            //Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c ),
            Description__c = 'test',
            Invoice_Quantity__c = 2,
            Unit_Price__c = 1,//KNDY-14371
            Supplier_Invoice__c = si_mrl.id,
            segment_exception__c = false,
            price_exception__c = false,
            quantity_exception__c = false,
            exception_details__c = null,
            matched__c = false
        );
        
        Supplier_Invoice_Line__c sil_mrl3 = new Supplier_Invoice_Line__c(
            Purchase_Order_Line__c = POLine1.id,
            Item__c = globalTestData.itemList[1].id,
            Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c ),
            Description__c = 'test',
            Invoice_Quantity__c = 1,
            Unit_Price__c = 1,//KNDY-14371
            Supplier_Invoice__c = si_mrl.id,
            segment_exception__c = false,
            price_exception__c = false,
            quantity_exception__c = false,
            exception_details__c = null,
            matched__c = false
        );
        
        // set qty uninvoiced on POL
        //POLine1.Quantity_Uninvoiced__c = 14;
        //update POLine1;
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl,sil_mrl2,sil_mrl3};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);

        Test.startTest();
        si_mrl.Status__c = 'Cancelled';
        si_mrl.Finalized__c = false;
        update si_mrl;
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c
             from Supplier_Invoice_lines__r) from Supplier_Invoice__c 
             where id =: si_mrl.id];
        system.assertEquals('Cancelled',si.status__c);
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, false);
        }
        // invoice quantity should be added back to POL qty uninvoiced
        POLine1 = [Select Id from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        system.assert(POLine1.Id != null);
   
        Test.stopTest();
    }
   
    static testMethod void test2Way_RemoveException(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order__c po = globalTestData.purchaseOrder;
        po.Quantity_Tolerance_Over__c = 0;
        po.Amount_Tolerance__c = 10;//Invoice Amount can be 10 more
        update po;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            POLine1.Status__c = 'Open';
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 21; // more than Order Quantity
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 21; // greater than max invoice quantity of 20
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        // Set Qty bucket on POL
        //POLine1.Quantity_Uninvoiced__c = -1;
        //update POLine1;
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        // Over Tolerance Exception as Invoice quanity is higher than 20,
        // and over tolerance is 0
        // No Amount Exception
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, Quantity_Exception__c, Price_Exception__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Draft',si.status__c); 
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, false);
            system.assertEquals(sil.Exceptions_Count__c, 1); // one exception at a time in Draft inspections
        }
        Map<Id, Set<Task>> mapExceptionTasks = ExceptionService.fetchExceptionTasks(new Set<Id> {sil_mrl.Id});
        system.assert(mapExceptionTasks.size() == 1);
        system.assert(mapExceptionTasks.containsKey(sil_mrl.Id));
        Set<Task> exceptions = mapExceptionTasks.get(sil_mrl.Id);
        system.assert(exceptions.size() == 1);
        for (Task t: exceptions){
            system.assert(t.Exception_Code__c == 'SI-QTYOVER000001');
        }  
        
        Test.startTest();
        si_mrl.Invoice_Amount__c = 20;
        update si_mrl;
        sil_mrl.Invoice_Quantity__c = 20;
        update sil_mrl;
        POLine1 = [Select Id from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        system.assert(POLine1.id != null);
        supplierInvoiceService.inspectDraftInvoices(sup);

        // No Exceptions
        si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, Quantity_Exception__c, Price_Exception__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Approved',si.status__c); 
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, true);
            system.assertEquals(sil.Exceptions_Count__c, 0); // one exception at a time in Draft inspections
        }
        Test.stopTest();
    }
    
    static testMethod void test2Way_PriceException(){
        Integer maxUnitPrice;
        Integer minUnitPrice;
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order__c po = globalTestData.purchaseOrder;
        po.Quantity_Tolerance_Over__c = null;
        po.Unit_Price_Tolerance_Over__c = 10;
        po.Amount_Tolerance__c = 2000;//Ridiculously high to avoid exception
        update po;
        
        // POL unit price == 100
        // SIL unit price max = 110, min = 90
        maxUnitPrice = 110;
        minUnitPrice = 90;
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 100;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 100;
            POLine1.Need_Date__c = System.today();
            POLine1.Status__c = 'Open';
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 491;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 1; 
            sil_mrl.Unit_Price__c = 100; // within price tolerance//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        Supplier_Invoice_Line__c sil_mrl2 = new Supplier_Invoice_Line__c();{
            sil_mrl2.Purchase_Order_Line__c = POLine1.id;
            sil_mrl2.Item__c = globalTestData.itemList[1].id;
            sil_mrl2.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl2.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl2.Description__c = 'test';
            sil_mrl2.Invoice_Quantity__c = 1; 
            sil_mrl2.Unit_Price__c = 110; // within price tolerance//KNDY-14371
            sil_mrl2.Supplier_Invoice__c = si_mrl.id;
            sil_mrl2.segment_exception__c = false;
            sil_mrl2.price_exception__c = false;
            sil_mrl2.quantity_exception__c = false;
            sil_mrl2.exception_details__c = null;
            sil_mrl2.matched__c = false;
        }
        
        Supplier_Invoice_Line__c sil_mrl3 = new Supplier_Invoice_Line__c();{
            sil_mrl3.Purchase_Order_Line__c = POLine1.id;
            sil_mrl3.Item__c = globalTestData.itemList[1].id;
            sil_mrl3.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl3.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl3.Description__c = 'test';
            sil_mrl3.Invoice_Quantity__c = 1; 
            sil_mrl3.Unit_Price__c = 90; // within price tolerance//KNDY-14371
            sil_mrl3.Supplier_Invoice__c = si_mrl.id;
            sil_mrl3.segment_exception__c = false;
            sil_mrl3.price_exception__c = false;
            sil_mrl3.quantity_exception__c = false;
            sil_mrl3.exception_details__c = null;
            sil_mrl3.matched__c = false;
        }
        
        Supplier_Invoice_Line__c sil_overPriced = new Supplier_Invoice_Line__c();{
            sil_overPriced.Purchase_Order_Line__c = POLine1.id;
            sil_overPriced.Item__c = globalTestData.itemList[1].id;
            sil_overPriced.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_overPriced.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_overPriced.Description__c = 'test';
            sil_overPriced.Invoice_Quantity__c = 1; 
            sil_overPriced.Unit_Price__c = 111;//KNDY-14371
            sil_overPriced.Supplier_Invoice__c = si_mrl.id;
            sil_overPriced.segment_exception__c = false;
            sil_overPriced.price_exception__c = false;
            sil_overPriced.quantity_exception__c = false;
            sil_overPriced.exception_details__c = null;
            sil_overPriced.matched__c = false;
        }
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl,sil_mrl2, sil_mrl3, sil_overPriced};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        Test.startTest();
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        // Over Tolerance Exception as over tolerance is null
        // No Amount Exception
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, Quantity_Exception__c, Price_Exception__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Draft',si.status__c); 
        System.debug(logginglevel.error,si.exception_details__c); 
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            if (sil.Id == sil_overPriced.Id){
	            system.assertEquals(sil.matched__c, false);
	            system.assertEquals(sil.Exceptions_Count__c, 1);
            }
            else{
                system.assertEquals(sil.matched__c, true);
                system.assertEquals(sil.Exceptions_Count__c, null);            	
            }
        }
        
        // 1 SILs should have exceptions
        Map<Id, Set<Task>> mapExceptionTasks = ExceptionService.fetchExceptionTasks(new Set<Id> {sil_overPriced.Id});
        system.assert(mapExceptionTasks.size() == 1);
        system.assert(mapExceptionTasks.containsKey(sil_overPriced.Id));
               
        Set<Task> exceptions = mapExceptionTasks.get(sil_overPriced.Id);
        system.assert(exceptions.size() == 1);
        for (Task t: exceptions){
            system.assert(t.Exception_Code__c == 'SI-PRICEOVER000001');
        }
        
        Test.stopTest();
    }
    
    static testMethod void testPrepayment_ChangeSIQty(){ // KNDY-9649
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order__c po = globalTestData.purchaseOrder;
        po.Quantity_Tolerance_Over__c = null;
        po.Amount_Tolerance__c = 10;//Invoice Amount can be 10 more
        update po;
        
        // when recd in full, no checks for Two Way POL
        // when invoiced in full, invoice qty can be upto 103, invoice amount can be upto 110
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Two Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            POLine1.Status__c = 'Open';
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Prepayment';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 20;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 20; // greater than max invoice quantity of 20
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        // When prepayments are inserted, Qty uninvoiced on POL does not change        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        Test.startTest();
        si_mrl.Invoice_Amount__c = 19;
        update si_mrl;
        sil_mrl.Invoice_Quantity__c = 19;
        update sil_mrl;
        POLine1 = [Select Id from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        system.assert(POLine1.id != null);
        Test.stopTest();
    } 
    
    static testMethod void testPrepayment_CancelSI(){
        Testfuel globaltestdata = new testFuel();
        List<Period__c> periodList = globaltestdata.periodList;
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 20;
            POLine1.Quantity_Received__c = 0;
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Prepayment';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 6;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
            insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 6;
            sil_mrl.Unit_Price__c = 1;//KNDY-14371
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }

        // For Prepayment, a new Prepayment insert does not change POL Qty Uninvoiced.
        POLine1 = [Select Id from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        system.assert(POLine1.id != null);
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);

        Test.startTest();
        si_mrl.Status__c = 'Cancelled';
        si_mrl.Finalized__c = false;
        update si_mrl;
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c
             from Supplier_Invoice_lines__r) from Supplier_Invoice__c 
             where id =: si_mrl.id];
        system.assertEquals('Cancelled',si.status__c);
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, false);
        }
        // invoice quantity should be added back to POL qty uninvoiced
        POLine1 = [Select Id from Purchase_Order_Line__c
                    where Id = :POLine1.Id];
        system.assert(POLine1.id != null);
   
        Test.stopTest();
    }
    
    public static testMethod void test_NewSIwithInvalidPaymentTerm(){ //KNDY-11064 KNDY-11689
        TestFuel globalTestData = new TestFuel(); 
        Payment_Term__c terms = globalTestData.terms;
        terms.Type__c = null; // blank the type
        update terms;
        List<Period__c> periodList = globaltestdata.periodList;
        
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 6;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        }
        try{
            insert si_mrl;
        }
        catch (Exception ex){
            system.assert(ex.getMessage().contains(Label.Please_enter_Type_on_associated_Payment_Term), 'Unexpected Exception: '+ ex.getMessage());
        }
     }
     
    public static testMethod void test_NewSIPaymentDueDate(){ //KNDY-11064 KNDY-11689
        TestFuel globalTestData = new TestFuel(); 
        Payment_Term__c terms = globalTestData.terms;
        terms.Type__c = 'Due Day of Month';
        terms.Day_Of_Month__c = 5;
        terms.Cut_Off_Day__c = 9;
        terms.Months_Ahead__c = 3;
        update terms;
        List<Period__c> periodList = globaltestdata.periodList;
        DateTime invoiceDate = DateTime.newInstanceGmt(2015, 2, 3);
        DateTime expectedPaymentDate = DateTime.newInstanceGMT(2015,5,5);
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = invoiceDate;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = globalTestData.terms.Id;
            si_mrl.Invoice_Amount__c = 6;
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        }
        Boolean isSuccess = true;
        try{
            insert si_mrl;
        }
        catch (Exception ex){
            isSuccess = false;
            system.assert(1!=1, 'Insert SI Unexpected Exception thrown: '+ ex.getMessage());
        }
        system.assert(isSuccess);
        Supplier_Invoice__c si = [Select Id, Payment_Due_Date__c from Supplier_Invoice__c
                                    where Id = : si_mrl.Id];
        system.assert(si.Payment_Due_Date__c == expectedPaymentDate, 'si payment Date: ' + si.Payment_Due_Date__c + '>>> expected: ' + expectedPaymentDate);
        
     }
     
     static testMethod void testSaveSI_NoRequiredFields() { //KNDY-12325 KNDY-12490
        TestFuel globalTestData = new TestFuel(); 
        List<Period__c> periodList = globaltestdata.periodList;
        
        Test.startTest();
        Supplier_Invoice__c si = new Supplier_Invoice__c();{
            si.Supplier__c = null;
            si.Invoice_Type__c = 'Invoice';
            si.Date_Invoiced__c = null;
            si.Supplier_Invoice__c = null;
            si.Payment_Term__c = globalTestData.terms.Id;
            si.Invoice_Amount__c = null;
            si.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si.Status__c = 'Incomplete';
            si.hold__c = false;
            si.Company__c = null;
        }
        JsonResult result = new JSONResult();
        Boolean isValid = SupplierInvoiceService.validateSave(si, null, result);
        system.assert(false == result.success, '>>>> result.messages: ' + result.messages);
        system.assert(false == isValid);
        system.assert(result.messages.size() == 5);
        Set<String> expectedErrorMessages = new Set<String>{ExceptionUtil.MISSING_COMPANY.description, 
                                ExceptionUtil.MISSING_DATE_INVOICED.description,
                                ExceptionUtil.MISSING_INVOICE_NUMBER.description,
                                ExceptionUtil.NEGATIVE_INVOICE_AMOUNT.description,
                                ExceptionUtil.MISSING_SUPPLIER.description};
        for (Map<String, String> error : result.messages) {
            system.assert(expectedErrorMessages.contains(error.get('message')));
        }
        si.Invoice_Type__c = 'Prepayment';
        result = new JSONResult();
        isValid = SupplierInvoiceService.validateSave(si, null, result);
        system.assert(false == result.success, '>>>> result.messages: ' + result.messages);
        system.assert(false == isValid);
        for (Map<String, String> error : result.messages) {
            system.assert(expectedErrorMessages.contains(error.get('message')));
        }
        
        si.Invoice_Type__c = 'Credit Memo';
        result = new JSONResult();
        expectedErrorMessages.remove(ExceptionUtil.NEGATIVE_INVOICE_AMOUNT.description);
        expectedErrorMessages.add(ExceptionUtil.POSITIVE_INVOICE_AMOUNT.description);
        expectedErrorMessages.add(ExceptionUtil.MISSING_CREDIT_MEMO_AMT.description);
        isValid = SupplierInvoiceService.validateSave(si, null, result);
        system.assert(false == result.success, '>>>> result.messages: ' + result.messages);
        system.assert(false == isValid);
        for (Map<String, String> error : result.messages) {
            system.assert(expectedErrorMessages.contains(error.get('message')));
        }
        Test.stopTest();
    }
    
    //Test to round the Invoice Amount >= 0.5 precision value to 1.0
    static testMethod void test3WayFullyInvoicedFullyReceived_VerifyPartiallyInvoiced_AmountRounding(){
        Testfuel globaltestdata = new testFuel();
        
        Configuration__c defaultPOAmountTolerance = new Configuration__c();  
        defaultPOAmountTolerance.name = 'Default_PO_Amount_Tolerance';
        defaultPOAmountTolerance.Value__c = '0.03';
        insert defaultPOAmountTolerance;
        
        Payment_Term__c userterms = new Payment_Term__c(); 
        userterms.name = 'Net 30'; 
        userterms.Description__c = '0% discount in 0 days, due 30 days';
        userterms.Type__c = KSE.PAYMENT_TERM_DUE_DAYS; //AR-3 need to define type on Payment Terms. 
        userterms.Discount_Days__c = 0;
        userterms.Discount_Percent__c = 0;
        userterms.Due_Days__c = 30;
        insert userterms; 
        
        List<Period__c> periodList = globaltestdata.periodList;  
        Purchase_Order__c po = globalTestData.purchaseOrder;
        po.Payment_Term__c = userterms.id;
        update po;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Quantity_Matched__c = null;
            POLine1.Amount_Matched__c = null;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 119;
            POLine1.Quantity_Received__c = 0; 
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1.27803;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }
    
        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Payment_Term__c = userterms.Id;
            si_mrl.Supplier_Invoice__c = '234dsfsa56dfd';
            si_mrl.Invoice_Amount__c = 76.6818; 
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.Id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 60;
            sil_mrl.Unit_Price__c = 1.27803;
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        Supplier_Invoice__c si_mrl1 = new Supplier_Invoice__c();{
            si_mrl1.Company__c = globalTestData.company.id;
            si_mrl1.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl1.Invoice_Type__c = 'Invoice';
            si_mrl1.Date_Invoiced__c = system.now();
            si_mrl1.Currency__c = TestFuel.currencyUSD.id;
            si_mrl1.Payment_Term__c = userterms.Id;
            si_mrl1.Supplier_Invoice__c = '234dsfsadfd';
            si_mrl1.Invoice_Amount__c = 75.4037; 
            si_mrl1.Purchase_Order__c = globalTestData.PurchaseOrder.Id;
            si_mrl1.Status__c = 'Draft';
            si_mrl1.exception__c = false;
            si_mrl1.exception_Details__c = null;
            si_mrl1.hold__c = false;
        insert si_mrl1;
        }
        
        Supplier_Invoice_Line__c sil_mrl1 = new Supplier_Invoice_Line__c();{
            sil_mrl1.Purchase_Order_Line__c = POLine1.id;
            sil_mrl1.Item__c = globalTestData.itemList[1].id;
            sil_mrl1.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl1.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl1.Description__c = 'test';
            sil_mrl1.Invoice_Quantity__c = 59;
            sil_mrl1.Unit_Price__c = 1.27803;
            sil_mrl1.Supplier_Invoice__c = si_mrl1.id;
            sil_mrl1.segment_exception__c = false;
            sil_mrl1.price_exception__c = false;
            sil_mrl1.quantity_exception__c = false;
            sil_mrl1.exception_details__c = null;
            sil_mrl1.matched__c = false;
        }
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl,sil_mrl1};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        sup.add(si_mrl1);
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        List<Id> siIds = new List<Id>();
        siIds.add(si_mrl.id);
        siIds.add(si_mrl1.id);  
        
        List<Supplier_Invoice__c> siList = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, Quantity_Exception__c, Price_Exception__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id in :siIds];
        
        for(Supplier_Invoice__c si : siList){
        system.assertEquals('Draft',si.status__c);
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, false);
            system.assertEquals(sil.Exceptions_Count__c, 1); // one exception at a time in Draft inspections
        }
      }  
        
        Test.startTest();
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Date_Created__c = system.today();
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = 119;
            receiptLine1.Uninvoiced_Quantity__c = 119;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            insert receiptLine1;
        }
        // Receive POL order quantity in full
        POLine1.Quantity_Received__c = 119; 
        update POLine1;
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        siList = [select id, name, exception__c, exception_details__c, status__c,Invoice_Amount__c,
            (select id, Exceptions_Count__c, matched__c, quantity_received__c, Unit_Price__c from Supplier_Invoice_lines__r)
             from Supplier_Invoice__c where id in :siIds];
            system.debug(logginglevel.error,'siList--->'+siList);
            
        Decimal invoicedAmount = 0.00;
        for(Supplier_Invoice__c si : siList){
            system.assertEquals('Approved',si.status__c); //Invoice should be approved
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, true);
            system.assertEquals(sil.Exceptions_Count__c, 0);
            invoicedAmount += sil.Quantity_Received__c * sil.Unit_Price__c;
            //system.assertEquals(sil.Quantity_Received__c, 119, '3 Way - expected 119 Qty Received on SIL');
          }
        }
        system.assertEquals((POLine1.Order_Quantity__c * POLine1.Unit_Price__c), invoicedAmount, 'With Rounding the Invoice amount did not match partially invoiced SIs');
        Test.stopTest();
    }
    
    //Test to round the Invoice Amount < 0.5 precision value to 0.0
    static testMethod void test3WayFullyInvoicedFullyReceived_VerifyFullyInvoiced_AmountRounding(){
        Testfuel globaltestdata = new testFuel();
        
        Configuration__c defaultPOAmountTolerance = new Configuration__c();  
        defaultPOAmountTolerance.name = 'Default_PO_Amount_Tolerance';
        defaultPOAmountTolerance.Value__c = '0.03';
        insert defaultPOAmountTolerance;
        
        Payment_Term__c userterms = new Payment_Term__c(); 
        userterms.name = 'Net 30'; 
        userterms.Description__c = '0% discount in 0 days, due 30 days';
        userterms.Type__c = KSE.PAYMENT_TERM_DUE_DAYS; //AR-3 need to define type on Payment Terms. 
        userterms.Discount_Days__c = 0;
        userterms.Discount_Percent__c = 0;
        userterms.Due_Days__c = 30;
        insert userterms; 
        
        List<Period__c> periodList = globaltestdata.periodList;  
        Purchase_Order__c po = globalTestData.purchaseOrder;
        po.Payment_Term__c = userterms.id;
        update po;
        
        Purchase_Order_Line__c POLine1 = new Purchase_Order_Line__c();{
            POLine1.Company__c = globalTestData.company.Id;
            POLine1.Quantity_Matched__c = null;
            POLine1.Amount_Matched__c = null;
            POLine1.Invoice_Matching__c = 'Three Way';
            POLine1.Item__c = globalTestData.itemlist[1].Id;
            POLine1.Order_Quantity__c = 119;
            POLine1.Quantity_Received__c = 0; 
            POLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            POLine1.Unit_Price__c = 1.278;
            POLine1.Need_Date__c = System.today();
            insert POLine1;
        }

        Supplier_Invoice__c si_mrl = new Supplier_Invoice__c();{
            si_mrl.Company__c = globalTestData.company.id;
            si_mrl.Supplier__c = globalTestData.remittosupplier.id;
            si_mrl.Invoice_Type__c = 'Invoice';
            si_mrl.Date_Invoiced__c = system.now();
            si_mrl.Currency__c = TestFuel.currencyUSD.id;
            si_mrl.Supplier_Invoice__c = '987612';
            si_mrl.Payment_Term__c = userterms.Id;
            si_mrl.Invoice_Amount__c = 152.082; 
            si_mrl.Purchase_Order__c = globalTestData.PurchaseOrder.id;
            si_mrl.Status__c = 'Draft';
            si_mrl.exception__c = false;
            si_mrl.exception_Details__c = null;
            si_mrl.hold__c = false;
        insert si_mrl;
        }
        
        Supplier_Invoice_Line__c sil_mrl = new Supplier_Invoice_Line__c();{
            sil_mrl.Purchase_Order_Line__c = POLine1.id;
            sil_mrl.Item__c = globalTestData.itemList[1].id;
            sil_mrl.Item__r = new Item__c( id= globalTestData.itemList[1].id, Source__c = globalTestData.itemList[1].Source__c, Class__c = globalTestData.itemList[1].Class__c );
            sil_mrl.Item__r.Class__r = new Class__c( id = globalTestData.clsObj.id, type__c = globalTestData.clsObj.type__c );
            sil_mrl.Description__c = 'test';
            sil_mrl.Invoice_Quantity__c = 119;
            sil_mrl.Unit_Price__c = 1.278;
            sil_mrl.Supplier_Invoice__c = si_mrl.id;
            sil_mrl.segment_exception__c = false;
            sil_mrl.price_exception__c = false;
            sil_mrl.quantity_exception__c = false;
            sil_mrl.exception_details__c = null;
            sil_mrl.matched__c = false;
        }
        
        List<Supplier_Invoice_Line__c> supILs = new List<Supplier_Invoice_Line__c>{sil_mrl};
        insert supILs; 
        List<supplier_Invoice__c> sup = new List<Supplier_Invoice__c>();
        sup.add(si_mrl);
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, Exceptions_Count__c, matched__c, Purchase_Order_Line__c, Quantity_Exception__c, Price_Exception__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: si_mrl.id];
        system.assertEquals('Draft',si.status__c);
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, false);
            system.assertEquals(sil.Exceptions_Count__c, 1); 
        }
        
        Test.startTest();
        
        Receiving_Document__c receivingDocument1 = new Receiving_Document__c();{
            receivingDocument1 = new Receiving_Document__c();
            receivingDocument1.Company__c = globalTestData.company.Id;
            receivingDocument1.Supplier__c = globalTestData.supplier.Id;
            receivingDocument1.Status__c = 'Open';
            receivingDocument1.Date_Created__c = system.today();
            receivingDocument1.Type__c = 'Purchase Order Receipt';
            insert receivingDocument1;
        }
        
        Receipt_Line__c receiptLine1 = new Receipt_Line__c();{
            receiptLine1.Purchase_Order__c = globalTestData.purchaseOrder.Id;
            receiptLine1.Purchase_Order_Line__c = POLine1.Id;
            receiptLine1.Item__c = globalTestData.itemList[1].Id;
            receiptLine1.Company__c = globalTestData.company.Id;
            receiptLine1.Supplier__c = globalTestData.supplier.Id;
            receiptLine1.Quantity_Received__c = 119;
            receiptLine1.Uninvoiced_Quantity__c = 119;
            receiptLine1.Facility__c = globalTestData.facility.Id;
            receiptLine1.Location__c = globalTestData.location.Id;
            receiptLine1.Receiving_Document__c = receivingDocument1.Id;
            insert receiptLine1;
        }
        // Receive POL order quantity in full
        POLine1.Quantity_Received__c = 119; 
        update POLine1;
        
        supplierInvoiceService.inspectDraftInvoices(sup);
        
        si = [select id, name, exception__c, exception_details__c, status__c,Invoice_Amount__c,
            (select id, Exceptions_Count__c, matched__c, quantity_received__c from Supplier_Invoice_lines__r)
             from Supplier_Invoice__c where id =: si_mrl.id];
        system.debug(logginglevel.error,'si--->'+si);
        system.assertEquals('Approved',si.status__c); //Invoice should be approved
        system.assertEquals(si.Invoice_Amount__c, 152.08, 'With Rounding the Invoice amount did not match'); // Actual Invoice Amount - 152.082, rounded to - 152.08
        for (Supplier_Invoice_Line__c sil : si.Supplier_Invoice_Lines__r){
            system.assertEquals(sil.matched__c, true);
            system.assertEquals(sil.Exceptions_Count__c, 0);
            system.assertEquals(sil.Quantity_Received__c, 119, '3 Way - expected 119 Qty Received on SIL');
        }
        Test.stopTest();
    }
}