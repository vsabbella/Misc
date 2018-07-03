@isTest
private class SupplierInvoiceIncompleteBatchTest {

    static testMethod void inspectIncompleteInvoicesTest() {
        
        siTestData data = new siTestData();
        data.si1.hold__c = true;
        data.si3.hold__c = true;
        data.siCM.hold__c = true;
        data.siCM1.hold__c = true;
        update data.si1; update data.si3; update data.siCM; update data.siCM1;
        
        Test.startTest();
        
        SupplierInvoiceIncompleteInspectBatch inspectBatch = new SupplierInvoiceIncompleteInspectBatch();
        inspectBatch.runBatch( data.job );
        
        Test.stopTest();
        
        Supplier_Invoice__c supplierInvoice =  [select id, name, Hold__c, Supplier_Invoice__c, Invoice_Amount__c, Credit_Memo_Amount__c, Invoice_Type__c, Total_Extended_Price__c,
                                                         exception__c, exception_details__c, status__c from Supplier_Invoice__c where id = :data.si.id];
        system.assertEquals('Draft', supplierInvoice.Status__c);
        system.assertEquals(false, supplierInvoice.Exception__c);
        system.assertEquals(null, supplierInvoice.Exception_Details__c);
        
    }
    

    
    class siTestData{
        
        public set<Id> supplierInvoiceIds = new set<Id>();
        
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
        
        //Create a company
        public Company__c company = new Company__c();{
            company.name = 'TestDataCo';
            company.A_Days__c = 6;
            company.B_Days__c = 20;
            company.C_Days__c = 90;
            company.Company_Identifier__c = 'SOL';
            company.Comp_Currency__c = TestFuel.currencySGD.id;
            company.Consol_Currency__c = TestFuel.currencyEUR.id;
            company.Stat_Currency__c = TestFuel.currencyGBP.id;
            company.Subs_Currency__c = TestFuel.currencyUSD.id;
            company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;          
            insert company;
        }
        
        
        //Create payment terms info
        public Payment_Term__c paymentTermInfo = new Payment_Term__c();{
        	paymentTermInfo.Type__c = KSE.PAYMENT_TERM_DUE_DAYS;
        	paymentTermInfo.Due_Days__c = 0;
            insert paymentTermInfo;
        }
        
        public map <string,string> rtMap1 = KSE.RecordTypeDevNameMap('Supplier__c');
        
        
        //Create Supplier, assign remit and payment terms info
        public Supplier__c supplier = new Supplier__c();{
            supplier.Name = 'Test';
            supplier.Payment_Term__c = paymentTermInfo.Id;
            supplier.Status__c = 'Active';
        	supplier.Type__c = 'Remit-To';
            supplier.RecordTypeId = rtMap1.get('Remit_To');
            supplier.company__c = company.id;
            insert supplier;
        }
        
        public Supplier__c posupplier = new Supplier__c();{
            posupplier.Name = 'Purchasing Supplier';
            posupplier.Payment_Term__c = paymentTermInfo.Id;
            posupplier.Status__c = 'Active';
        	posupplier.Type__c = 'Purchasing';
            posupplier.RecordTypeId = rtMap1.get('Purchase_From');
        	posupplier.Remit_To__c =  supplier.id;
        	posupplier.company__c = company.id;
        	insert posupplier;
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
        public List<Item__c> items = new List<Item__c>();{
        
            Item__c item = new Item__c();
            item.Name = 'testitem';
            item.Active__c = true;
            item.Class__c = regClass.id;
            item.Source__c = 'Services';
            item.Company__c = company.Id;
            item.Stocking_UOM__c = uomObj.Id;
            item.Packaging_UOM__c = JSON.serialize(new List<Id>{ uomObj.Id });
            
            items.add(item);
            
            Item__c item2 = new Item__c();
            item2.Name = 'testServices';
            item2.Active__c = true;
            item.Class__c = regClass.id;
            item2.Company__c = company.Id;
            item2.Source__c = 'Services';
            item2.Stocking_UOM__c = uomObj.Id;
            item2.Packaging_UOM__c = JSON.serialize(new List<Id>{ uomObj.Id });
            
            items.add(item2);
            
            insert items;
        }
        
        //Create some PO and PO Lines and receipt invoice line
        public Purchase_Order__c PO = new Purchase_Order__c();{
            PO.Supplier__c = posupplier.Id;
            PO.Remit_To_Supplier__c = supplier.Id;
            PO.Company__c = company.Id;
            PO.Status__c = 'Open';
            
            insert PO;
        }
        
        public List<Purchase_Order_Line__c> POLines = new List<Purchase_Order_Line__c>();{
                
            Purchase_Order_Line__c POLine = new Purchase_Order_Line__c();
            POLine.Company__c = company.Id;
            POLine.Item__c = items[0].Id;
            POLine.Order_Quantity__c = 10;
            POLine.Purchase_Order__c = PO.Id;
            POLine.Unit_Price__c = 10;
            //POLine.Quantity_unInvoiced__c = 10;
            POLine.Need_Date__c = System.today();
            
            POLines.add(POLine);
            
            Purchase_Order_Line__c POLine2 = new Purchase_Order_Line__c();
            POLine2.Company__c = company.Id;
            POLine2.Item__c = items[0].Id;
            POLine2.Order_Quantity__c = 10;
            //POLine.Quantity_unInvoiced__c = 10;
            POLine2.Purchase_Order__c = PO.Id;
            POLine2.Unit_Price__c = 10;
            POLine2.Need_Date__c = System.today();
            
            POLines.add(POLine2);
            
            insert POLines;
        }
        
        public Process_Configuration__c pc1 = new Process_Configuration__c();{
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
        }       
        
       

        public Supplier_Invoice__c si = new Supplier_Invoice__c();{
            si.Company__c = company.id;
            si.Supplier__c = supplier.id;
            si.Supplier_Invoice__c = KSE.getUniqueNumberString();
            si.Date_Invoiced__c = system.now();            
            si.Invoice_Amount__c = 1000;
            si.Purchase_Order__c = PO.id;
            si.status__c = 'Incomplete'; 
            si.Invoice_Type__c = 'Invoice';
            si.Hold__c = false;
            si.Payment_Due_Override_Date__c = system.today() + 5; 
            insert si;
        }
        
        public Supplier_Invoice__c si1 = new Supplier_Invoice__c();{
            si1.Company__c = company.id;
            si1.Supplier__c = supplier.id;
            si1.Supplier_Invoice__c = KSE.getUniqueNumberString();
            si1.Date_Invoiced__c = system.now();           
            si1.Invoice_Amount__c = 1000;
            si1.Purchase_Order__c = PO.id;
            si1.status__c = 'Incomplete';
            si1.Invoice_Type__c = 'Invoice';
            si1.Hold__c = false;
            insert si1;
        }
        
        
        
        public Supplier_Invoice__c si3 = new Supplier_Invoice__c();{
            si3.Company__c = company.id;
            si3.Supplier__c = supplier.id;
            si3.Supplier_Invoice__c = KSE.getUniqueNumberString();
            si3.Date_Invoiced__c = system.now();           
            si3.Invoice_Amount__c = 2000;
           
            si3.status__c = 'Incomplete';
            si3.Invoice_Type__c = 'Invoice';
            si3.Hold__c = false;
            insert si3;
        }
        
        public List<Supplier_Invoice_Line__c> RILlines = new List<Supplier_Invoice_Line__c>();{
                
            Supplier_Invoice_Line__c rilt5 = new Supplier_Invoice_Line__c();
            rilt5.Purchase_Order_Line__c = POLines[0].id;
            rilt5.Item__c = items[0].id;
            rilt5.Item__r = new Item__c( id= items[0].id, Source__c = items[0].Source__c, Class__c = items[0].Class__c );
            rilt5.Item__r.Class__r = new Class__c( id = regClass.id, type__c = regClass.type__c );
            rilt5.Description__c = 'test';
            rilt5.Invoice_Quantity__c = 10;
            rilt5.Unit_Price__c = 100; //KNDY-14371
            rilt5.Supplier_Invoice__c = si.id;
            rilt5.Supplier_Invoice__r = si;
            RILlines.add(rilt5);
            
            Supplier_Invoice_Line__c rilt = new Supplier_Invoice_Line__c();
            rilt.Item__c = items[1].id;
            rilt.Item__r = new Item__c( id= items[1].id, Source__c = items[1].Source__c, Class__c = items[1].Class__c );
            rilt.Item__r.Class__r = new Class__c( id = miscClass.id, type__c = miscClass.type__c );
            rilt.Description__c = 'test';
            rilt.Invoice_Quantity__c = 1; 
            rilt.Unit_Price__c = 500; //KNDY-14371
            rilt.Supplier_Invoice__c = si1.id;
            rilt.Supplier_Invoice__r = si1;
            RILlines.add(rilt);
            
            Supplier_Invoice_Line__c rilt1 = new Supplier_Invoice_Line__c();
            rilt1.Purchase_Order_Line__c = POLines[0].id;
            rilt1.Item__c = items[0].id;
            rilt1.Item__r = new Item__c( id= items[0].id, Source__c = items[0].Source__c, Class__c = items[0].Class__c );
            rilt1.Item__r.Class__r = new Class__c( id = regClass.id, type__c = regClass.type__c );
            rilt1.Description__c = 'test';
            rilt1.Invoice_Quantity__c = 1;
            rilt1.Unit_Price__c = 500; //KNDY-14371
            rilt1.Supplier_Invoice__c = si1.id;
            rilt1.Supplier_Invoice__r = si1;
            
            RILlines.add(rilt1);
            
            Supplier_Invoice_Line__c rilt2 = new Supplier_Invoice_Line__c();
            rilt2.Purchase_Order_Line__c = POLines[0].id;
            rilt2.Item__c = items[0].id;
            rilt2.Item__r = new Item__c( id= items[0].id, Source__c = items[0].Source__c, Class__c = items[0].Class__c );
            rilt2.Item__r.Class__r = new Class__c( id = regClass.id, type__c = regClass.type__c );
            rilt2.Description__c = 'test';
            rilt2.Invoice_Quantity__c = 1;
            rilt2.Unit_Price__c = 500; //KNDY-14371
            rilt2.Supplier_Invoice__c = si3.id;
            rilt2.Supplier_Invoice__r = si3;
            rilt5.Line_Type__c = 'Item';
            RILlines.add(rilt2);
            
            Supplier_Invoice_Line__c rilt3 = new Supplier_Invoice_Line__c();
            rilt3.Purchase_Order_Line__c = POLines[0].id;
            rilt3.Item__c = items[0].id;
            rilt3.Item__r = new Item__c( id= items[0].id, Source__c = items[0].Source__c, Class__c = items[0].Class__c );
            rilt3.Item__r.Class__r = new Class__c( id = regClass.id, type__c = regClass.type__c );
            rilt3.Description__c = 'test';
            rilt3.Invoice_Quantity__c = -1;
            rilt3.Unit_Price__c = -500; //KNDY-14371
            rilt3.Supplier_Invoice__c = si3.id;
            rilt3.Supplier_Invoice__r = si3;
            RILlines.add(rilt3);
            
            Supplier_Invoice_Line__c rilt4 = new Supplier_Invoice_Line__c();
            rilt4.Purchase_Order_Line__c = POLines[0].id;
            rilt4.Item__c = items[0].id;
            rilt4.Item__r = new Item__c( id= items[0].id, Source__c = items[0].Source__c, Class__c = items[0].Class__c );
            rilt4.Item__r.Class__r = new Class__c( id = regClass.id, type__c = regClass.type__c );
            rilt4.Description__c = 'test';
            rilt4.Invoice_Quantity__c = 3;
            rilt4.Unit_Price__c = 500; //KNDY-14371
            rilt4.Supplier_Invoice__c = si3.id;
            rilt4.Supplier_Invoice__r = si3;
            RILlines.add(rilt4);
            
            insert RILlines;
        }
        
        public Supplier_Invoice__c siCM1 = new Supplier_Invoice__c();{
            siCM1.Company__c = company.id;  
            siCM1.Credit_Memo_Amount__c = 1000;
            siCM1.Invoice_Amount__c = -1000;
            siCM1.Supplier_Invoice__c = KSE.getUniqueNumberString();
            siCM1.invoice_type__c = 'Credit Memo';
            siCM1.status__c = 'Incomplete';
            insert siCM1;
        }
            
        public Supplier_Invoice__c siCM = new Supplier_Invoice__c();{
            siCM.Company__c = company.id;
            siCM.Supplier__c = supplier.id;
            siCM.Date_Invoiced__c = system.now();
            siCM.Supplier_Invoice__c = KSE.getUniqueNumberString();
            siCM.Credit_Memo_Amount__c = 1000;
            siCM.Invoice_Amount__c = -1000;
            siCM.Apply_To_Invoice__c = si1.id;
            siCM.invoice_type__c = 'Credit Memo';
            siCM.status__c = 'Incomplete';
            insert siCM;
            
            supplierInvoiceIds.addAll(new Set<Id>{si.id,si1.id,siCM.id, si3.id,siCM1.id} );
        }
        
        
        
        public List<Supplier_Invoice_Line__c> RICMlines = new List<Supplier_Invoice_Line__c>();{
                
            Supplier_Invoice_Line__c rilt = new Supplier_Invoice_Line__c();
            rilt.Item__c = items[1].id;
            rilt.Item__r = new Item__c( id= items[1].id );
            
            rilt.Description__c = 'test';
            rilt.Invoice_Quantity__c = -1; 
            rilt.Unit_Price__c = 500; //KNDY-14371
            rilt.Supplier_Invoice__c = siCM.id;
            rilt.Invoice_Line__c = RILlines[0].id;
            rilt.Line_Type__c = 'Item';
            rilt.Invoice_Line__r = [ select id, Extended_Price__c from Supplier_Invoice_Line__c where id=:RILlines[0].id ];         
            RICMlines.add(rilt);
            
           Supplier_Invoice_Line__c rilt1 = new Supplier_Invoice_Line__c();
            rilt1.Item__c = items[1].id;
            rilt1.Item__r = new Item__c( id= items[1].id );
            
            rilt1.Description__c = 'test';
            rilt1.Invoice_Quantity__c = -1; 
            rilt1.Unit_Price__c = 500; //KNDY-14371
            rilt1.Supplier_Invoice__c = siCM.id;
            rilt1.Invoice_Line__c = RILlines[1].id;
            rilt1.Line_Type__c = 'Item';
            rilt1.Invoice_Line__r = [ select id, Extended_Price__c from Supplier_Invoice_Line__c where id=:RILlines[1].id ];    
            RICMlines.add(rilt1);
            
            insert RICMlines;
        }        
                
        Process_Job__c job = new Process_Job__c(Company__c = company.Id); {
        	job.Batch_Size__c = 10;
            
            insert job;   
        }       
                
    }
}