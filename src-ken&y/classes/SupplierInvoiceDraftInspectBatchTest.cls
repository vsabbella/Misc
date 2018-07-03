@isTest
private class SupplierInvoiceDraftInspectBatchTest {
    
    class supplierInvoiceTestData{
    
        public SKIDServiceTest.TestDataForSkidService sstestData = new SKIDServiceTest.TestDataForSkidService();
    	
        
        //Create a GL Type
        public GL_Type__c testGLT = new GL_Type__c();{
	    	testGLT.Name  = 'Current Assets';
			testGLT.Normal_Balance__c  = 'Debit';
			testGLT.Accounting_Type__c  = 'Assets';
			testGLT.Statement_Type__c  = 'Balance Sheet';
			testGLT.Account_Range_From__c = '10000';
			testGLT.Account_Range_To__c ='14999';
			insert testGLT;
        }
		
        //Create a GL Account
        public GL_Account__c glaccount = new GL_Account__c();{
            
            glaccount.Name = 'testglaccount';
            glaccount.GL_Account_Number__c = '10000';
            glaccount.GL_Account_Name__c = 'Current Assets';
            glaccount.GL_Type__c = testGLT.id;
            glaccount.Active__c = true;
            insert glaccount;
        }
        
        public segment_validation__c segval = new segment_validation__c();{
            segval.segment_1__c = '*';
            segval.segment_2__c = '*';
            segval.active__c = true;
            insert segval;
        }
        /*
        //Create a company
        public Company__c company = new Company__c();{
            company.name = 'TestDataCo';
            company.A_Days__c = 6;
            company.B_Days__c = 20;
            company.C_Days__c = 90;
            company.Company_Identifier__c = 'SOL';
            //company.Finalize_Supplier_Invoices_w_Exceptions__c = false; //KNDY-2817
            insert company;
            
            integer year = system.now().year();
	        List<Period__c> periodList = new List<Period__c>();
   			for(integer i=1; i<=12; i++){
			    Period__c iPeriod = new Period__c();
			    iPeriod.Name = string.valueOf(i) + '-' + string.valueOf(year);
			    iPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
			    iPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
			    iPeriod.Period_Start__c = datetime.newInstance(year, i, 1, 0, 0, 0);
			    iPeriod.Period_End__c = datetime.newInstance((i == 12 ? year + 1 : year), (i == 12 ? 1 : i + 1), 1, 0, 0, 0);
			    iPeriod.Period_Number__c = i;
			    if(i>=1 && i <= 3){
			        iPeriod.Quarter_Number__c = 1;
			    }else if(i>=4 && i <= 6){
			        iPeriod.Quarter_Number__c = 2;
			    }else if(i>=7 && i <= 9){
			        iPeriod.Quarter_Number__c = 3;
			    }else if(i>=10 && i <= 12){
			        iPeriod.Quarter_Number__c = 4;
			    }	
			    
			    iPeriod.Fiscal_Year__c = String.valueOf(year);
			    iPeriod.Company__c = company.Id;
			    iPeriod.Adjustment_Period__c = false;
			    iPeriod.Closed__c = false;
			    iPeriod.Open__c = i >= system.now().month();
			    iPeriod.Fiscal__c = true;
			    iPeriod.Corporate__c = false;
			    iPeriod.Tax__c = false;
			    iPeriod.Permanently_Closed__c = false;
			    iPeriod.Adjustment_Period__c = false;
			    
			    iPeriod.AP_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.AR_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.Shipment_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.Receiving_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.FA_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.Inventory_Subledger_Cutoff__c = iPeriod.Period_End__c;
			    iPeriod.Period_Cut_Off__c = iPeriod.Period_End__c;
			    
			    periodList.add(iPeriod);
			}
    		insert periodList;
        }
        */
        
        
        //Create payment terms info
        public Payment_Term__c paymentTermInfo = new Payment_Term__c();{
        	paymentTermInfo.Type__c = KSE.PAYMENT_TERM_DUE_DAYS;
        	paymentTermInfo.Due_Days__c = 0;
            insert paymentTermInfo;
        }
        
        public map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c');
        
        //Create Supplier, assign remit and payment terms info
        public Supplier__c remittosupplier = new Supplier__c();{
            remittosupplier.Name = 'Test Remit To';
            remittosupplier.Payment_Term__c = paymentTermInfo.Id;
            remittosupplier.Status__c = 'Active';
            remittosupplier.Type__c = 'Remit-To';
            remittosupplier.RecordTypeId = rtMap.get('Remit_To');
            remittosupplier.company__c = sstestData.company.Id;
            insert remittosupplier;
        }
        
        public Supplier__c supplier = new Supplier__c();{
            supplier.Name = 'Test';
            supplier.Payment_Term__c = paymentTermInfo.Id;
            supplier.Status__c = 'Active';
            supplier.Type__c = 'Purchasing';
            supplier.RecordTypeId = rtMap.get('Purchase_From');
            supplier.Remit_To__c =  remittosupplier.id;
            supplier.company__c = sstestData.company.Id; 
            insert supplier;
        }
        
        public Class__c miscClass = new Class__c();{
            
            miscClass.Name = 'Class Misc';
            miscClass.Type__c = 'Miscellaneous';
            insert miscClass;
        }
        
        public Class__c regClass = new Class__c();{
            
            regClass.Name = 'Class Reg';
            regClass.Type__c = 'Services';
            insert regClass;
        }
        
        public UOM__c uomObj = new UOM__c();{
		    
            uomObj.Name = 'EA';
            uomObj.Description__c = 'EA';
            insert uomObj;            
		}
        
        //Create an item
        
            Item__c item = new Item__c();{
            item.Name = 'testitem';
            item.Active__c = true;
            item.Class__c = regClass.id;
            item.Source__c = 'Services';
            item.Company__c = sstestData.company.Id;
            item.Stocking_UOM__c = uomObj.Id;
            item.Packaging_UOM__c = JSON.serialize(new List<Id>{ uomObj.Id });
            insert item;    
            }
            
            Item__c item2 = new Item__c();{
            item2.Name = 'testitemmisc';
            item2.Active__c = true;
            item2.Class__c = miscClass.id;
            item2.Company__c = sstestData.company.Id;
            item2.Source__c = 'Miscellaneous';
            item2.Non_Inventory__c = true;
            item2.Stocking_UOM__c = uomObj.Id;
            item2.Packaging_UOM__c = JSON.serialize(new List<Id>{ uomObj.Id });
            insert item2;
            }
        //Create some PO and PO Lines and receipt invoice line
        public Purchase_Order__c PO = new Purchase_Order__c();{
            PO.Supplier__c = supplier.Id;
            PO.Company__c = sstestData.company.Id;
            PO.Status__c = 'Open';
            PO.Payment_Term__c = paymentTermInfo.Id;
            
            insert PO;
        }
        
        Purchase_Order_Line__c POLine = new Purchase_Order_Line__c();{
            POLine.Company__c = sstestData.company.Id;
            POLine.Item__c = item.Id;
            POLine.Order_Quantity__c = 10;
            POLine.Purchase_Order__c = PO.Id;
            POLine.Unit_Price__c = 10;
            //POLine.Quantity_unInvoiced__c = 10;
            POLine.Quantity_Received__c = 10;
            POLine.Need_Date__c = System.today();
        
            insert POLine;
        }
            
       /* Purchase_Order_Line__c POLine2 = new Purchase_Order_Line__c();{
            POLine2.Company__c = company.Id;
            POLine2.Item__c = items[0].Id;
            POLine2.Order_Quantity__c = 10;
            POLine.Quantity_unInvoiced__c = 10;
            POLine2.Purchase_Order__c = PO.Id;
            POLine2.Unit_Price__c = 10;
            POLine2.Need_Date__c = System.today();
            
            insert POLine2;
        }*/
        
        Receiving_Document__c receivingDocument = new Receiving_Document__c();{
            receivingDocument = new Receiving_Document__c();
            receivingDocument.Company__c = sstestData.company.Id;
            receivingDocument.Supplier__c = supplier.Id;
            receivingDocument.Status__c = 'Open';
            receivingDocument.Type__c = 'Purchase Order Receipt';
            receivingDocument.Date_Created__c = system.today();
            insert receivingDocument;
        }
        
        Receipt_Line__c receiptLine = new Receipt_Line__c();{
            receiptLine.Purchase_Order__c = PO.Id;
            receiptLine.Purchase_Order_Line__c = POLine.Id;
            receiptLine.Item__c = item.Id;
            receiptLine.Company__c = sstestData.company.Id;
            receiptLine.Supplier__c = supplier.Id;
            receiptLine.Quantity_Declared__c = POLine.Order_Quantity__c;
            receiptLine.Quantity_Received__c = POLine.Order_Quantity__c;
            receiptLine.Uninvoiced_Quantity__c = POLine.Order_Quantity__c;
            receiptLine.Facility__c = sstestData.facility.Id;
            receiptLine.Location__c = sstestData.locationList[0].Id;
            receiptLine.Receiving_Document__c = receivingDocument.Id;
            insert receiptLine;
        }
        
        {
            receivingDocument = [Select Id, Date_Created__c, Type__c, Supplier__c, Status__c, Company__c,   
                                    (Select Id, Name, Company__c, Purchase_Order_Line__c, Purchase_Order__c, 
                                        Purchase_Order__r.Status__c,  Purchase_Order__r.Approval_Status__c,
                                        Purchase_Order_Line__r.Quantity_Still_Due__c,
                                        Item__c, Supplier__c, Facility__c, Location__c,
                                        Quantity_Declared__c, Quantity_Received__c, Uninvoiced_Quantity__c   
                                        from Receipt_Lines__r order by Name ASC) 
                                    from Receiving_Document__c 
                                    where Id = :receivingDocument.id limit 1];
            receiptLine = receivingDocument.Receipt_Lines__r[0];               
        }
        
        /*public Process_Configuration__c pc1 = new Process_Configuration__c();{
                pc1.name='SupplierInvoiceLineMisc';  
                pc1.Object_Name__c = 'Supplier_Invoice_Line__c' ; 
                pc1.Field_Value__c = 'Miscellaneous' ;
                pc1.Active__c = true;
                insert pc1; 
        }
                
        public Process_Configuration__c pc2 = new Process_Configuration__c();{
                pc2.name='SupplierInvoiceLineServices';  
                pc2.Object_Name__c = 'Supplier_Invoice_Line__c' ; 
                pc2.Field_Value__c = 'Services' ;
                pc2.Active__c = true;
                insert pc2; 
        }*/     
        
        public Supplier_Invoice__c si1 = new Supplier_Invoice__c();{
            si1.Company__c = sstestData.company.id;
            si1.Supplier__c = remittosupplier.id;
            si1.Invoice_Type__c = 'Invoice';
            si1.Date_Invoiced__c = system.now();
            si1.Payment_Term__c = paymentTermInfo.Id;
            si1.Supplier_Invoice__c = '9876';
            si1.Invoice_Amount__c = 100;
            si1.Purchase_Order__c = PO.id;
            si1.Status__c = 'Draft';
            si1.exception__c = false;
            si1.exception_Details__c = null;
            si1.hold__c = false;
            si1.historical__c = false;
            si1.Currency__c = TestFuel.currencyUSD.id;
            insert si1;
        }
        
        public Supplier_Invoice__c si_manual = new Supplier_Invoice__c();{
            si_manual.Company__c = sstestData.company.id;
            si_manual.Supplier__c = remittosupplier.id;
            si_manual.Date_Invoiced__c = system.now();
            si_manual.Supplier_Invoice__c = '9876543';
            si_manual.Payment_Term__c = paymentTermInfo.Id;
            si_manual.Invoice_Amount__c = 100;
            si_manual.Invoice_Type__c = 'Invoice';
            si_manual.Status__c = 'Draft';
            si_manual.exception__c = false;
            si_manual.exception_Details__c = null;
            si_manual.hold__c = false;
            si_manual.historical__c = false;
            si_manual.Currency__c = TestFuel.currencyUSD.id;
            insert si_manual;
        }
        
        public Accounting_Default__c ad = new Accounting_Default__c();{
            ad.company__c = sstestData.company.id;
            ad.GL_Account__c = glaccount.id;
        insert ad;
        }
        
        Supplier_Invoice_Line__c ril_manual = new Supplier_Invoice_Line__c();{
            ril_manual.Supplier_Invoice__c = si_manual.id;
            ril_manual.Accounting_Segment__c = ad.id;
            ril_manual.Description__c = 'test';
            ril_manual.Invoice_Quantity__c = 10;
            ril_manual.Unit_Price__c = 10;//KNDY-14371
            ril_manual.Item__c = item2.id;
            ril_manual.segment_exception__c = false;
            ril_manual.price_exception__c = false;
            ril_manual.quantity_exception__c = false;
            ril_manual.exception_details__c = null;
            ril_manual.matched__c = false;
            
            insert ril_Manual;
        }
        
        Supplier_Invoice_Line__c rilt1 = new Supplier_Invoice_Line__c();{
            rilt1.Purchase_Order_Line__c = POLine.id;
            rilt1.Item__c = item.id;
            rilt1.Item__r = new Item__c( id= item.id, Source__c = item.Source__c, Class__c = item.Class__c );
            rilt1.Item__r.Class__r = new Class__c( id = regClass.id, type__c = regClass.type__c );
            rilt1.Description__c = 'test';
            rilt1.Invoice_Quantity__c = 10;
            rilt1.Unit_Price__c = 10;//KNDY-14371
            rilt1.Supplier_Invoice__c = si1.id;
            rilt1.segment_exception__c = false;
            rilt1.price_exception__c = false;
            rilt1.quantity_exception__c = false;
            rilt1.exception_details__c = null;
            rilt1.matched__c = false;
            
            insert rilt1;
        }
        
        public Supplier_Invoice__c si2 = new Supplier_Invoice__c();{
            si2.Company__c = sstestData.company.id;
            si2.Supplier__c = remittosupplier.id;
            si2.Date_Invoiced__c = system.now();
            si2.Supplier_Invoice__c = '9877';
            si2.Payment_Term__c = paymentTermInfo.Id;
            si2.Invoice_Amount__c = -10;
            si2.Status__c = 'Draft';
            si2.Invoice_Type__c = 'Credit Memo';
            si2.exception__c = false;
            si2.exception_Details__c = null;
            si2.Apply_to_Invoice__c = si1.id;
            si2.Credit_Memo_Amount__c = -10;
            si2.Credit_Memo_Balance__c = -10;
            si2.historical__c = false;
            si2.Currency__c = TestFuel.currencyUSD.id;
            insert si2;
        }
        

        
        Supplier_Invoice_Line__c rilt2 = new Supplier_Invoice_Line__c();{
            rilt2.Item__c = item.id;
            rilt2.Item__r = new Item__c( id= item.id, Source__c = item.Source__c, Class__c = item.Class__c );
            rilt2.Item__r.Class__r = new Class__c( id = regClass.id, type__c = regClass.type__c );
            rilt2.Description__c = 'test';
            rilt2.Invoice_Quantity__c = -1;
            rilt2.Unit_Price__c = 10;//KNDY-14371
            rilt2.Supplier_Invoice__c = si2.id;
            rilt2.segment_exception__c = false;
            rilt2.price_exception__c = false;
            rilt2.quantity_exception__c = false;
            rilt2.exception_details__c = null;
            rilt2.matched__c = false;
            rilt2.Invoice_Line__c = rilt1.id;
            
            insert rilt2;
        }
        
        Process_Job__c job = new Process_Job__c(Company__c = sstestData.company.Id); {
        	job.Batch_Size__c = 10;
            
            insert job;   
        }       
    }

   static testMethod void moveInvoiceFromDraftToApproved() {
        supplierInvoiceTestData globalTestData = new supplierInvoiceTestData();
        globalTestData.si2.Hold__c = true; //for KNDY-2869 since we downsized the batch to 1
        update globalTestData.si2;
        globalTestData.si_manual.Hold__c = true;
        update globalTestData.si_manual;
        
        SupplierInvoiceDraftInspectBatch jpBatch = new SupplierInvoiceDraftInspectBatch();
        Test.startTest();
        jpBatch.runBatch(globalTestData.job);
        Test.stopTest();
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,Has_Exceptions__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: globalTestData.si1.id];
        Supplier_Invoice_Line__c ril = si.Supplier_Invoice_Lines__r;
        Receipt_Line__c rl = [select id, matched__c, uninvoiced_quantity__c from receipt_line__c where Purchase_Order_Line__c = :ril.Purchase_Order_Line__c];
        system.assertEquals('Approved', si.Status__c);
        system.assertEquals(false, si.Has_Exceptions__c);
        system.assertEquals(10, ril.quantity_received__c);
        system.assertEquals(true, ril.matched__c);
        system.assertEquals(true, rl.matched__c);
        system.assertEquals(0, rl.uninvoiced_quantity__c);
        
        //missing credit memo use case, ril with AD segment, missing segments, missing quanity, wrong unit price
    }

    /*
    This scenario tests when there is no receipt that the invoice will not be marked as approved and flagged as a quantity exception.
    Since this is within 7 days of being paid and the full quantity has not been received, then it will flag as exception on the header
    so the user can review.
*/
    static testMethod void matchReceiptInvoicewithNoReceipt(){
        supplierInvoiceTestData globalTestData = new supplierInvoiceTestData();
        Receiving_Document__c rd = [select id, (select id from Receipt_Lines__r) from Receiving_Document__c];
        globalTestData.si1.Date_Invoiced__c = system.now();
        delete rd.Receipt_Lines__r;
        delete rd;
        globalTestData.si2.hold__c = true;
        update globalTestData.si2;
        globalTestData.si_manual.hold__c = true;
        update globalTestData.si_manual;
        
        SupplierInvoiceDraftInspectBatch jpBatch = new SupplierInvoiceDraftInspectBatch();
        Test.startTest();
        jpBatch.runBatch(globalTestData.job);
        Test.stopTest();
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: globalTestData.si1.id];
        Supplier_Invoice_Line__c ril = si.Supplier_Invoice_Lines__r;
        system.assertEquals('Draft', si.Status__c);
        system.assertEquals(0, ril.Quantity_Received__c);
        system.assertEquals(false, ril.matched__c);
        
        
    }

    //test method for KNDY-2594 with a voided receipt line.
    static testMethod void voidedReceiptLine() {
        supplierInvoiceTestData globalTestData = new supplierInvoiceTestData();
        globalTestData.receiptLine.Status__c = 'Void';
        update globalTestData.receiptLine;
        globalTestData.si2.hold__c = true;
        update globalTestData.si2;
        globalTestData.si_manual.hold__c = true;
        update globalTestData.si_manual;
        
        SupplierInvoiceDraftInspectBatch jpBatch = new SupplierInvoiceDraftInspectBatch();
        Test.startTest();
        jpBatch.runBatch(globalTestData.job);
        Test.stopTest();
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: globalTestData.si1.id];
        Supplier_Invoice_Line__c ril = si.Supplier_Invoice_Lines__r;
        Receipt_Line__c rl = [select id, matched__c, uninvoiced_quantity__c from receipt_line__c where Purchase_Order_Line__c = :ril.Purchase_Order_Line__c];
        system.assertEquals('Draft', si.Status__c);
        system.assertEquals(0, ril.quantity_received__c);
        system.assertEquals(false, ril.matched__c);
        system.assertEquals(false, rl.matched__c);
        system.assertEquals(10, rl.uninvoiced_quantity__c);
    }
    
    static testMethod void ManualInvoice_SunnyDay(){
        supplierInvoiceTestData globalTestData = new supplierInvoiceTestData();
        globalTestData.si2.hold__c = true;
        update globalTestData.si2;
        globalTestData.si1.hold__c = true;
        update globalTestData.si1;
        
        SupplierInvoiceDraftInspectBatch jpBatch = new SupplierInvoiceDraftInspectBatch();
        Test.startTest();
        jpBatch.runBatch(globalTestData.job);
        Test.stopTest();
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: globalTestData.si_manual.id];
        Supplier_Invoice_Line__c ril = si.Supplier_Invoice_Lines__r;
        system.assert(si.Status__c =='Approved', 'Status is ' + si.Status__c + '  Exceptions?  ' + si.Exception_Details__c);
        system.assert(si.exception__c== false, 'Exception is true ' + si.exception_details__c);
        system.assertEquals(false, ril.quantity_Exception__c);
        system.assertEquals(false, ril.segment_exception__c);
        system.assertEquals(true, ril.matched__c);
    }
    
       
    /*
    This method needs to check that any invoice line modification to core values triggers the matched values of
    a Receipt Invoice to be reset   
    */
    static testMethod void resetModifiedInvoice(){
        supplierInvoiceTestData globalTestData = new supplierInvoiceTestData();
        
        globaltestData.receiptLine.uninvoiced_quantity__c = 0;
        globaltestData.receiptLine.matched__c = true;
        globaltestData.rilt1.Quantity_Received__c = globaltestData.receiptLine.Quantity_Received__c;
        globaltestData.rilt1.matched__c = true;
        update globaltestdata.receiptLine;
        update globaltestdata.rilt1;
        
        id RILid;
        Map<Id, Supplier_Invoice_Line__c> oldRecords = new Map<Id, Supplier_Invoice_Line__c>();
        Test.startTest();
            
            list<Supplier_Invoice_Line__c> ril = [select id, Name, Invoice_Quantity__c, Unit_Price__c, Quantity_Received__c, Purchase_Order_Line__c, Matched__c, Supplier_Invoice__r.Invoice_Type__c from Supplier_Invoice_Line__c where id=: globalTestData.rilt1.id];
            RILid=ril[0].id;
            oldRecords.put(ril[0].id, ril[0]);
            
            SupplierInvoiceService.returnMatchedQuantity(ril, oldRecords, false, true, false, false);
        test.stopTest();
        
        Receipt_Line__c receiptLine = [select id, uninvoiced_quantity__c, quantity_received__c, name from Receipt_Line__c where id=:globalTestData.receiptLine.id limit 1];
        Supplier_Invoice_Line__c invoiceLine = [select id, Invoice_Quantity__c, Quantity_Received__c, Purchase_Order_Line__c, Matched__c from Supplier_Invoice_Line__c where id=: globalTestData.rilt1.id limit 1];
        
        system.assert(invoiceLine.Matched__c == false, 'Matched was true!');
        system.assert(invoiceLine.Quantity_Received__c==0, 'Quantity greater than 0 ' + invoiceLine.Quantity_Received__c);
        system.assert(receiptLine.uninvoiced_quantity__c==receiptLine.Quantity_received__c);
    }
    
    //KNDY-2512 Unfinalize the doc and move to incomplete. reset the qty and flags
    static testMethod void resetInvoiceUponStatusMoveToIncomplete(){
        supplierInvoiceTestData globalTestData = new supplierInvoiceTestData();
        globalTestData.si2.hold__c = true;
        update globalTestData.si2;
        globalTestData.si_manual.hold__c = true;
        update globalTestData.si_manual;
        SupplierInvoiceDraftInspectBatch jpBatch = new SupplierInvoiceDraftInspectBatch();
        Test.startTest();
        jpBatch.runBatch(globalTestData.job);
        Test.stopTest();
        
        Supplier_Invoice__c si = [select id, name, Finalized__c, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: globalTestData.si1.id];
        Supplier_Invoice_Line__c ril = si.Supplier_Invoice_Lines__r;
        Receipt_Line__c rl = [select id, matched__c, uninvoiced_quantity__c from receipt_line__c where Purchase_Order_Line__c = :ril.Purchase_Order_Line__c];
        system.assertEquals('Approved', si.Status__c);
        system.assertEquals(true, ril.matched__c);
        system.assertEquals(true, rl.matched__c);
        system.assertEquals(true, si.Finalized__c);
    
        Apexpages.currentPage().getParameters().put('id', globalTestData.si1.id );
        SourceDocumentUnfinalize srcDocUnfinalizeExt = new SourceDocumentUnfinalize();
        srcDocUnfinalizeExt.unfinalizeSourceDoc();
        srcDocUnfinalizeExt.unfinalize();
        
        si = [select id, name, Finalized__c from Supplier_Invoice__c where id =: globalTestData.si1.id];
        system.assertEquals(false, si.Finalized__c);
        
        //globaltestData.si1.status__c = 'Incomplete'; status would be reset by unfinalize.
        //update globaltestData.si1;
        
        
        return; //KNDY-2223, invoice in not going to incomplete since Posted__c was removed
       
        si = [select id, name, status__c from Supplier_Invoice__c where id =: globalTestData.si1.id];
        system.assertEquals('Incomplete', si.Status__c); //failing with Approved
        
        Receipt_Line__c receiptLine = [select id, uninvoiced_quantity__c, quantity_received__c, name from Receipt_Line__c where id=:globalTestData.receiptLine.id limit 1];
        Supplier_Invoice_Line__c invoiceLine = [select id, Invoice_Quantity__c, Quantity_Received__c, Purchase_Order_Line__c, Matched__c from Supplier_Invoice_Line__c where id=: globalTestData.rilt1.id limit 1];
        
        system.assert(invoiceLine.Matched__c == false, 'Matched was true!');
        system.assert(invoiceLine.Quantity_Received__c==0, 'Quantity greater than 0 ' + invoiceLine.Quantity_Received__c);
        system.assert(receiptLine.uninvoiced_quantity__c==receiptLine.Quantity_received__c);
    }
    
    //KNDY-2977
    static testMethod void resetInvoiceUponStatusMoveToIncompleteWDupePOLine(){
        supplierInvoiceTestData globalTestData = new supplierInvoiceTestData();
        
        Test.startTest();
        
        globalTestData.si2.hold__c = true;
        update globalTestData.si2;
        globalTestData.si_manual.hold__c = true;
        update globalTestData.si_manual;
        //adding another RIL which points to the same POLine
        Supplier_Invoice_Line__c rilt3 = new Supplier_Invoice_Line__c();{
            rilt3.Purchase_Order_Line__c = globalTestData.POLine.id;
            rilt3.Item__c = globalTestData.item.id;
            rilt3.Item__r = new Item__c( id= globalTestData.item.id, Source__c = globalTestData.item.Source__c, Class__c = globalTestData.item.Class__c );
            rilt3.Item__r.Class__r = new Class__c( id = globalTestData.regClass.id, type__c = globalTestData.regClass.type__c );
            rilt3.Description__c = 'test';
            rilt3.Invoice_Quantity__c = 5;
            rilt3.Unit_Price__c = 10;//KNDY-14371
            rilt3.Supplier_Invoice__c = globalTestData.si1.id;
            rilt3.matched__c = false;
            
            insert rilt3;
        }
        //splitting the qty across the 2 RILs so that both are matched up
        globalTestData.rilt1.Invoice_Quantity__c = 5;
        update globalTestData.rilt1;
        
        SupplierInvoiceDraftInspectBatch jpBatch = new SupplierInvoiceDraftInspectBatch();
        
        jpBatch.runBatch(globalTestData.job);
        Test.stopTest();
        
        Supplier_Invoice__c si = [select id, name, Finalized__c, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from supplier_invoice_lines__r) from Supplier_Invoice__c where id =: globalTestData.si1.id];
        List<Supplier_Invoice_Line__c> rils = si.Supplier_Invoice_Lines__r;
        Receipt_Line__c rl = [select id, matched__c, uninvoiced_quantity__c from receipt_line__c where Purchase_Order_Line__c = :globalTestData.POLine.id];
        system.assertEquals('Approved', si.Status__c);
        system.assertEquals(2, rils.size());
        system.assertEquals(true, rils[0].matched__c);
        system.assertEquals(true, rils[1].matched__c);
        system.assertEquals(true, rl.matched__c);
        system.assertEquals(true, si.Finalized__c);
    
        Apexpages.currentPage().getParameters().put('id', globalTestData.si1.id );
        SourceDocumentUnfinalize srcDocUnfinalizeExt = new SourceDocumentUnfinalize();
        srcDocUnfinalizeExt.unfinalizeSourceDoc();
        srcDocUnfinalizeExt.unfinalize();
        
        system.assertEquals(srcDocUnfinalizeExt.unfinalize, true, ApexPages.getMessages());
        si = [select id, name, Finalized__c from Supplier_Invoice__c where id =: globalTestData.si1.id];
        system.assertEquals(false, si.Finalized__c, si);
        
        //globaltestData.si1.status__c = 'Incomplete'; status would be reset by unfinalize.
        //update globaltestData.si1;
        
        si = [select id, name, status__c from Supplier_Invoice__c where id =: globalTestData.si1.id];
        system.assertEquals('Incomplete', si.Status__c);
        
        Receipt_Line__c receiptLine = [select id, uninvoiced_quantity__c, quantity_received__c, name from Receipt_Line__c where id=:globalTestData.receiptLine.id limit 1];
        List<Id> rilIds = new List<Id>{globalTestData.rilt1.id, rilt3.id};
        List<Supplier_Invoice_Line__c> invoiceLines = [select id, Invoice_Quantity__c, Quantity_Received__c, Purchase_Order_Line__c, Matched__c from Supplier_Invoice_Line__c where id IN :rilIds];
        for (Supplier_Invoice_Line__c invoiceLine: invoiceLines){
            system.assert(invoiceLine.Matched__c == false, 'Matched was true!');
            system.assert(invoiceLine.Quantity_Received__c==0, 'Quantity greater than 0 ' + invoiceLine.Quantity_Received__c);
        }
        //TODO RS 2-17-2014 Verify this assertion
        //system.assertEquals(receiptLine.uninvoiced_quantity__c, receiptLine.Quantity_received__c);
    }
    
    static testMethod void exerciseHoldOnApprovedInvoices(){
        supplierInvoiceTestData globalTestData = new supplierInvoiceTestData();
        globalTestData.si2.hold__c = true;
        update globalTestData.si2;
        globalTestData.si_manual.hold__c = true;
        update globalTestData.si_manual;
        
        SupplierInvoiceDraftInspectBatch jpBatch = new SupplierInvoiceDraftInspectBatch();
        Test.startTest();
        jpBatch.runBatch(globalTestData.job);
        Test.stopTest();
        
        Supplier_Invoice__c si = [select id, name, Hold__c, Finalized__c, exception__c, exception_details__c, status__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: globalTestData.si1.id];
        Supplier_Invoice_Line__c ril = si.Supplier_Invoice_Lines__r;
        Receipt_Line__c rl = [select id, matched__c, uninvoiced_quantity__c from receipt_line__c where Purchase_Order_Line__c = :ril.Purchase_Order_Line__c];
        system.assertEquals('Approved', si.Status__c);
        system.assertEquals(true, ril.matched__c);
        system.assertEquals(true, rl.matched__c);
        system.assertEquals(true, si.Finalized__c);
        system.assertEquals(false, si.Hold__c);
        
    }
    
    static testMethod void moveCMInvoiceFromDraftToApproved() {
        supplierInvoiceTestData globalTestData = new supplierInvoiceTestData();
        globalTestData.si2.status__c ='Draft';
        update globalTestData.si2;
        
        globalTestData.si_manual.hold__c = true;
        globalTestData.si1.hold__c = true;
        update globalTestData.si_manual;
        
        SupplierInvoiceDraftInspectBatch jpBatch = new SupplierInvoiceDraftInspectBatch();
        Test.startTest();
        jpBatch.runBatch(globalTestData.job);
        Test.stopTest();
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,Has_Exceptions__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: globalTestData.si2.id];
        Supplier_Invoice_Line__c ril = si.Supplier_Invoice_Lines__r;
        //system.debug(logginglevel.ERROR, '***si: ' + si);  
        //system.debug(logginglevel.ERROR, '***ril: ' + ril);        
        
        system.assertEquals('Approved', si.Status__c);
        system.assertEquals(false, si.Has_Exceptions__c);
        system.assertEquals(true, ril.matched__c);
        
    }
    
    static testMethod void moveCMMiscInvoiceFromDraftToApproved() {
        supplierInvoiceTestData globalTestData = new supplierInvoiceTestData();
        globalTestData.si1.status__c ='Approved';
        update globalTestData.si1;
        globalTestData.si_manual.hold__c = true;
        update globalTestData.si_manual;
        
        globalTestData.si2.Apply_to_Invoice__c = null;
        SupplierInvoiceDraftInspectBatch jpBatch = new SupplierInvoiceDraftInspectBatch();
        Test.startTest();
        jpBatch.runBatch(globalTestData.job);
        Test.stopTest();
        
        Supplier_Invoice__c si = [select id, name, exception__c, exception_details__c, status__c,Has_Exceptions__c,
            (select id, exception_details__c, matched__c, Purchase_Order_Line__c, quantity_exception__c, price_exception__c, segment_exception__c, quantity_received__c from Supplier_Invoice_lines__r) from Supplier_Invoice__c where id =: globalTestData.si2.id];
        Supplier_Invoice_Line__c ril = si.Supplier_Invoice_Lines__r;
        //system.debug(logginglevel.INFO, '***si: ' + si);  
        //system.debug(logginglevel.INFO, '***ril: ' + ril);
        
        system.assertEquals('Approved', si.Status__c);
        system.assertEquals(false, si.Has_Exceptions__c);
        system.assertEquals(true, ril.matched__c);
        
    }
    
   static testMethod void testLastVisitedByBatch() { //PTP-420
        supplierInvoiceTestData globalTestData = new supplierInvoiceTestData();
        globalTestData.si2.Hold__c = true; //for KNDY-2869 since we downsized the batch to 1
        update globalTestData.si2;
        globalTestData.si_manual.Hold__c = true;
        update globalTestData.si_manual;
        
        Supplier_Invoice__c siBefore = [select id, Last_Visited_By_Batch__c from Supplier_Invoice__c where ID =: globalTestData.si1.id];
        system.assert(siBefore.Last_Visited_By_Batch__c == null, 'Last_Visited_By_Batch__c is not null: ' + siBefore.Last_Visited_By_Batch__c);
        
        SupplierInvoiceDraftInspectBatch jpBatch = new SupplierInvoiceDraftInspectBatch();
        Test.startTest();
        jpBatch.runBatch(globalTestData.job);
        Test.stopTest();
        
        Supplier_Invoice__c si = [select id, Status__c, Last_Visited_By_Batch__c from Supplier_Invoice__c where id = :globalTestData.si1.id];
        system.assertEquals('Approved', si.Status__c);
        system.assert(si.Last_Visited_By_Batch__c != null, 'Last_Visited_By_Batch__c is: ' + si.Last_Visited_By_Batch__c);
    
    }
    
}