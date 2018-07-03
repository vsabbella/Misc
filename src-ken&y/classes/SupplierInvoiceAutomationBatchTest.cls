@isTest
private class SupplierInvoiceAutomationBatchTest {

    
    
    static testMethod void testBatch() {
        if(KSE.checkTestDispatch()){return;}        
        
    	TestDataForSupplierAutoInvoice td = new TestDataForSupplierAutoInvoice();   
    	
    	Process_Job__c job = new Process_Job__c(Company__c = td.co.Id); {
        	job.Batch_Size__c = 200;
            
            insert job;   
        }    
    	
    	SupplierInvoiceAutomationBatch batch = new SupplierInvoiceAutomationBatch();
        Test.startTest();
        	batch.runBatch(job);
        Test.stopTest();
    	
        //query the Supplier Invoices and Lines to make sure they were created properly				
		List<Supplier_Invoice__c> siList = TestDataForSupplierAutoInvoice.querySupInvoices();

		//make sure the total number of Supplier Invoices got created.  This will be 1 per receipt line.
		System.assertEquals(td.INT_TOTAL, siList.size());
			
        //loop through all the Supplier Invoices that were created and make sure the values are correct
        for (Supplier_Invoice__c si : siList) {
        	//get the original objects we created as part of the test data
        	Purchase_Order__c po = td.poIdtoPoMap.get(si.Purchase_Order__c);        	
        	Receiving_Document__c rd = td.PoIdRdMap.get(si.Purchase_Order__c);  
        	
        	System.assertEquals('Invoice', si.Invoice_Type__c);
        	System.assertEquals(po.Company__c, si.Company__c);
        	System.assertEquals(po.Remit_To_Supplier__c, si.Supplier__c);
        	System.assertNotEquals(null, si.Date_Invoiced__c);
        	System.assertEquals(rd.Date_Received__c, si.Date_Received__c);        	
        	System.assertEquals((10*12) ,si.Invoice_Amount__c);
        	System.assertEquals('Incomplete',si.Status__c);
        	System.assertEquals(true, si.Hold__c);
        	System.assertEquals('Check', si.Payment_Method_G__c);
        	System.assertEquals(td.terms.Id, si.Payment_Term__c);
        	System.assertNotEquals(null, si.Purchase_Order__c);        	
        	
        	//do assertions on the related invoice line
        	System.assertEquals(1, si.Supplier_Invoice_Lines__r.size());
        	System.assertEquals((si.Autonumber__c+po.Name+si.Supplier_Invoice_Lines__r[0].Purchase_Order_Line__r.Name), si.Supplier_Invoice__c);
        	System.assertEquals(si.Id, si.Supplier_Invoice_Lines__r[0].Supplier_Invoice__c);
        	System.assertEquals(po.Id, td.poLineIdToPoIdMap.get(si.Supplier_Invoice_Lines__r[0].Purchase_Order_Line__c));
        	System.assertEquals(td.purchasedItem.Id, si.Supplier_Invoice_Lines__r[0].Item__c);
        	System.assertEquals('pol desc', si.Supplier_Invoice_Lines__r[0].Description__c);
        	System.assertEquals(10, si.Supplier_Invoice_Lines__r[0].Invoice_Quantity__c);
        	System.assertEquals(12, si.Supplier_Invoice_Lines__r[0].Unit_Price__c);        		
        }

    
    }




}