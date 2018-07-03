@isTest
private class Supplier1099ServiceTest {
	
	public class TestData{
        
        //create account records
        public Account accRecord, accRecord1;
        public Integer currentYear;{
            currentYear =  System.today().year();
        }
        public List<Account> accounts; {
        	
        	accounts = new List<Account>();
        	accRecord = new Account();
	        accRecord.Name = 'testAcc';
	        accRecord.Type = 'Prospect';
	        accRecord.BillingCity = 'New York';
	        accRecord.BillingStreet = '10 Main Rd.';
	        accRecord.BillingState = 'NY';
	        accRecord.BillingPostalCode = '31349';
	        accRecord.BillingCountry = 'United States'; //KNDY-18842
	        accRecord.Phone = '(555) 555 5555'; 
	        accounts.add(accRecord);
	        
	        accRecord1 = new Account();
	        accRecord1.Name = 'testAcc';
	        accRecord1.Type = 'Prospect';
	        accRecord1.BillingCity = 'New York';
	        accRecord1.BillingStreet = '10 Main Rd.';
	        accRecord1.BillingState = 'NY';
	        accRecord1.BillingPostalCode = '31349';
	        accRecord1.BillingCountry = 'USA';
	        accounts.add(accRecord1);
	        
	        insert accounts;
        }
        
        //create company record
        public Company__c companyRecord;{
        	companyRecord = new Company__c(); 
	        companyRecord.Name = 'testCompany';
	        companyRecord.Address__c = accRecord.Id;
	        companyRecord.TIN__c = '987562';
	        companyRecord.Comp_Currency__c = TestFuel.currencySGD.id;
	        companyRecord.Consol_Currency__c = TestFuel.currencyEUR.id;
	        companyRecord.Stat_Currency__c = TestFuel.currencyGBP.id;
	        companyRecord.Subs_Currency__c = TestFuel.currencyUSD.id;
	        companyRecord.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;        
	        insert companyRecord;
	        
	        // query to get 18 digit ids
	        companyRecord = [Select Id, Name, Address__c, TIN__c,Default_Transaction_Currency__c,Comp_Currency__c ,Consol_Currency__c,Stat_Currency__c,Subs_Currency__c from Company__c where Id =:companyRecord.Id];
	        
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
			    iPeriod.Company__c = companyRecord.Id;
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
			    iPeriod.JE_Cutoff__c = iPeriod.Period_End__c; 
			    
			    periodList.add(iPeriod);
			}
			Fiscal_Year__c fy = new Fiscal_Year__c();
			fy.company__c = companyRecord.Id;
			fy.fiscal_year_start_date__c = periodList[0].period_start__c;
			fy.fiscal_year_end_date__c = periodList[periodList.size()-1].period_end__c.addMonths(3);
			
			insert fy;
	
	    	for(Period__c p : periodList){
				p.fiscalyear__c = fy.Id;
	    	}
    		insert periodList;
        }

        //create bank account
        public List<Bank_Account__c> baList = new List<Bank_Account__c>();
        public Bank_Account__c ba, baGBP;{
        		ba = new Bank_Account__c();
        		ba.Name = 'TestBA';
        		ba.Company__c = companyRecord.Id;
        		ba.Currency__c = companyRecord.Default_Transaction_Currency__c;
        		baList.add(ba);
        		
        		baGBP = new Bank_Account__c();
        		baGBP.Name = 'TestBA';
        		baGBP.Company__c = companyRecord.Id;
        		baGBP.Currency__c = TestFuel.currencyGBP.Id;
        		baList.add(baGBP);
        		insert baList;
        }
        
        public UOM__c uomObj = new UOM__c();{
		    
            uomObj.Name = 'EA';
            uomObj.Description__c = 'EA';
            insert uomObj;            
		}
        
        //Create an item
        public Item__c item;
         public Item__c itemRecord;{
        	item = new Item__c();
            item.Name = 'testitem';
            item.Active__c = true;
            item.Company__c = companyRecord.Id;
            item.Stocking_UOM__c = uomObj.Id;
            item.Packaging_UOM__c = JSON.serialize(new List<Id>{ uomObj.Id });
            insert item;
         }
        
        public map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c');
                
        //create supplier record
        public Supplier__c supplierRecord;{
        	supplierRecord = new Supplier__c();
	        supplierRecord.X1099_Supplier__c = true;
	        supplierRecord.Address__c = accRecord.Id;
	        supplierRecord.Company__c =  companyRecord.Id;
	        supplierRecord.Tax_ID__c = '653568'; 
	        supplierRecord.X1099_Box_G__c = '3 Other Income';//can do describe calls and get all picklist values and create supplier records      
	        supplierRecord.Type__c = 'Remit-To';
        	supplierRecord.RecordTypeId = rtMap.get('Remit_To');
        	insert supplierRecord;
        }
        
        //create supplier inventory record
        public Supplier_Invoice__c supplierInv, supplierInv1, supplierInvGBP;
        public List<Supplier_Invoice__c> supplierInvoices;{
        	
        	supplierInvoices = new List<Supplier_Invoice__c>();
        
	        supplierInv = new Supplier_Invoice__c();
	        supplierInv.Company__c = companyRecord.Id;
	        supplierInv.Currency__c = companyRecord.Default_Transaction_Currency__c;
	        supplierInv.Supplier__c = supplierRecord.Id;
	        //supplierInvRecord.X1099_Box_G__c = '3 Other Income';
	        supplierInv.Amount_Paid__c = 1000.00;
	        supplierInv.Invoice_Amount__c = 1000.00;
	        supplierInv.Supplier_Invoice__c = '200.00';
	        supplierInvoices.add(supplierInv);

	        supplierInv1 = new Supplier_Invoice__c();
	        supplierInv1.Company__c = companyRecord.Id;
	        supplierInv1.Currency__c = companyRecord.Default_Transaction_Currency__c;
	        supplierInv1.Supplier__c = supplierRecord.Id;
	        //supplierInvRecord1.X1099_Box_G__c = '3 Other Income';
	        supplierInv1.Amount_Paid__c = 1500.00;
	        supplierInv1.Invoice_Amount__c = 1500.00;
	        supplierInv1.Supplier_Invoice__c = '300.00';
	       // supplierInv1.Status__c = 'Incomplete';
	        supplierInvoices.add(supplierInv1);
	        
	        supplierInvGBP = new Supplier_Invoice__c();
	        supplierInvGBP.Company__c = companyRecord.Id;
	        supplierInvGBP.Currency__c = TestFuel.currencyGBP.Id;
	        supplierInvGBP.Supplier__c = supplierRecord.Id;
	        //supplierInvRecord.X1099_Box_G__c = '3 Other Income';
	        supplierInvGBP.Amount_Paid__c = 1000.00;
	        supplierInvGBP.Invoice_Amount__c = 1000.00;
	        supplierInvGBP.Supplier_Invoice__c = '1000.00';
	        supplierInvoices.add(supplierInvGBP);
	        insert supplierInvoices;
	        
	        List<Supplier_Invoice_Line__c> RCPLines = new List<Supplier_Invoice_Line__c>();     
            Supplier_Invoice_Line__c RCPLine = new Supplier_Invoice_Line__c();
                RCPLine.Quantity_Received__c = 80; 
                RCPLine.Invoice_Quantity__c = 80;
                RCPLine.Unit_Price__c = 10;
                RCPLine.Item__c = item.Id;
                RCPLine.Supplier_Invoice__c = supplierInv.Id;
                RCPLines.add(RCPLine);
            
            Supplier_Invoice_Line__c RCPLine2 = new Supplier_Invoice_Line__c();
                RCPLine2.Quantity_Received__c = 10;
                RCPLine2.Invoice_Quantity__c = 10;
                RCPLine2.Unit_Price__c = 20;
                RCPLine2.Item__c = item.Id;                
                RCPLine2.Supplier_Invoice__c = supplierInv.Id;
                RCPLines.add(RCPLine2);
                
            Supplier_Invoice_Line__c RCPLine3 = new Supplier_Invoice_Line__c();
                RCPLine3.Quantity_Received__c = 150; 
                RCPLine3.Invoice_Quantity__c = 150;
                RCPLine3.Unit_Price__c = 10;
                RCPLine3.Item__c = item.Id;
                RCPLine3.Supplier_Invoice__c = supplierInv1.Id;
                RCPLines.add(RCPLine3);   

            Supplier_Invoice_Line__c siLineGBP = new Supplier_Invoice_Line__c();
                siLineGBP.Quantity_Received__c = 80; 
                siLineGBP.Invoice_Quantity__c = 80;
                siLineGBP.Unit_Price__c = 10;
                siLineGBP.Item__c = item.Id;
                siLineGBP.Supplier_Invoice__c = supplierInvGBP.Id;
                RCPLines.add(siLineGBP);
                insert RCPLines;
                
                supplierInv1.Status__c = 'Approved';
                supplierInv1.Transaction_Date__c = system.now();
                supplierInvGBP.Status__c = 'Approved';
                supplierInvGBP.Transaction_Date__c = system.now();
                update supplierInvoices;
        }
        
        
        public Supplier_Payment__c suppPayment;{
        	suppPayment = new Supplier_Payment__c();
        	suppPayment.Company__c = companyRecord.Id;
        	suppPayment.Supplier__c = supplierRecord.Id;
        	suppPayment.Date_Paid__c = system.now();
        	suppPayment.Payment_Amount__c = 1000;
        	suppPayment.Bank_Account__c = ba.Id;
        	suppPayment.Currency__c = companyRecord.Default_Transaction_Currency__c;
        	insert suppPayment;
        }
        
        public Supplier_Payment_Line__c paymentLine,paymentLine2,paymentLine3,paymentLine4;
        public List<Supplier_Payment_Line__c> paymentLines;{
        	
        	paymentLines = new List<Supplier_Payment_Line__c>();
        	
        	paymentLine = new Supplier_Payment_Line__c();
	        paymentLine.Supplier_Invoice__c = supplierInv1.Id;
	        paymentLine.Amount__c = 800.00;
	        paymentLine.Supplier_Payment__c = suppPayment.Id;
	        paymentLine.X1099_Box_G__c = '1 Rents';
	        paymentLine.Type__c = 'Payment';
	        paymentLines.add(paymentLine);
	        
	        paymentLine2 = new Supplier_Payment_Line__c();
	        paymentLine2.Supplier_Invoice__c = supplierInv1.Id;
	        paymentLine2.Amount__c = 300.00;
	        paymentLine2.Supplier_Payment__c = suppPayment.Id;
	        //paymentLine2.X1099_Box_G__c = '2 Royalties';
	        paymentLine2.Type__c = 'Payment';
	        paymentLines.add(paymentLine2);
	        
	        paymentLine3 = new Supplier_Payment_Line__c();
	        paymentLine3.Supplier_Invoice__c = supplierInv1.Id;
	        paymentLine3.Amount__c = 0.00;
	        paymentLine3.Supplier_Payment__c = suppPayment.Id;
	        paymentLine3.X1099_Box_G__c = '1 Rents';
	        paymentLine3.Type__c = 'Credit Memo';
	        paymentLines.add(paymentLine3);
	        
	        paymentLine4 = new Supplier_Payment_Line__c();
	        paymentLine4.Supplier_Invoice__c = supplierInv1.Id;
	        paymentLine4.Amount__c = -100.00;
	        paymentLine4.Supplier_Payment__c = suppPayment.Id;
	        paymentLine4.X1099_Box_G__c = '1 Rents';
	        paymentLine4.Type__c = 'Prepayment';
	        paymentLines.add(paymentLine4);
	        insert  paymentLines;
	        
	        suppPayment.Payment_Amount__c = 1000;
	        suppPayment.Finalized__c = true;
	        update suppPayment;
        }
        
       public Merge_Document__c md;{
			md = new Merge_Document__c();
	    	md.name = 'test';
	    	md.Target_Object__c = 'Account';
	    	md.Target_Object_Label__c = 'Account';
	    	md.document_name__c = 'abc-123.pdf';
	    	insert md;
		}
    	
    	public List<Merge_Field__c> mfs; {
    		
	    	mfs = new List<Merge_Field__c>();
	    	Merge_Field__c mf1 = new Merge_Field__c();
	    	mf1.Merge_Document__c = md.Id;
	    	mf1.Database_Field__c = 'Name';
	    	mf1.Database_Label__c = 'Name';
	    	mf1.Document_Field__c = 'Name';
	    	mfs.add(mf1);
	    	
	    	Merge_Field__c mf2 = new Merge_Field__c();
	    	mf2.Merge_Document__c = md.Id;
	    	mf2.Database_Field__c = 'BillingStreet';
	    	mf2.Database_Label__c = 'Billing Street';
	    	mf2.Document_Field__c = 'BillingStreet';
	    	mfs.add(mf2);
	    	
	    	Merge_Field__c mf3 = new Merge_Field__c();
	    	mf3.Merge_Document__c = md.Id;
	    	mf3.Database_Field__c = 'AccountNumber';
	    	mf3.Database_Label__c = 'Account Number';
	    	mf3.Document_Field__c = 'AccountNumber';
	    	mfs.add(mf3);
	    	
	    	insert mfs;
    	}
    	
    	public Attachment att; {
    		att = new Attachment();
	    	att.Name = 'file.pdf';
	    	att.parentId = md.Id;
	    	att.Body = blob.valueOf('test file body');
	    	att.ContentType = 'application/pdf';
	    	insert att;
    	}
	}
	
	/*
    *	Test that the 1099s are generated
    */
    static testMethod void test1099GenerationSuccess_1099Created() {
        TestData sampleData = new TestData();
        test.startTest();
        //KNDY-19465 amount is equal to sp payment amount
        Supplier1099Batch job = new Supplier1099Batch(sampleData.companyRecord.Id, sampleData.currentYear, 1000);

        	Database.executeBatch(job);
        test.stopTest();
        
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c , Batch_Job_ID__c, Company__r.Country__c,Payer_Phone__c, Supplier__r.Country__c, PayerCountry__c, Recipient_Country__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 1, 'Expected 1, received ' + supplier1099s.size());
        system.assert(supplier1099s[0].Box1__c != null);
        system.assert(supplier1099s[0].Box3__c != null);
        system.assertEquals(supplier1099s[0].Payer_Phone__c, sampleData.accRecord.Phone, supplier1099s[0]); //KNDY-18844
        system.assertEquals(supplier1099s[0].PayerCountry__c, supplier1099s[0].Company__r.Country__c, supplier1099s[0]); //KNDY-18842
        system.assertEquals(supplier1099s[0].Recipient_Country__c, supplier1099s[0].Supplier__r.Country__c, supplier1099s[0]); //KNDY-18842
        
        //KNDY-18558 paymentLineGBP is excluded from below box totals as its not USD currency
        //paymentLine - paymentLine3 - paymentLine4
        system.assertEquals(supplier1099s[0].Box1__c, 700, supplier1099s[0]);
        //paymentLine2
        system.assertEquals(supplier1099s[0].Box3__c, 300, supplier1099s[0]);
        system.assert(supplier1099s[0].Batch_Job_ID__c != null );
    }

    static testMethod void test1099GenerationSuccess_No1099Created() { //KNDY-19469
        TestData sampleData = new TestData();
        Boolean hasException = false;
        Id testBatchJobId = sampleData.supplierRecord.Id;
        Integer supp1099Ct = 0;
        Test.startTest();
        try{
            // SP amounts are much less that 70000, so no records exists to process for supplier 1099s
            supp1099Ct = Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 70000, sampleData.companyRecord.Id);
        }
        catch (Exception ex){
            hasException = true;
        }
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c];
        system.assertEquals(supplier1099s.size(), 0, 'Expected 0, received ' + supplier1099s.size());
        system.assertEquals(hasException, false);
        system.assertEquals(supp1099Ct, 0, supp1099Ct);
        Test.stopTest();
    }
    
    static testMethod void test1099GenerationBatchSuccess_No1099Created() { //KNDY-19469
        TestData sampleData = new TestData();
        Test.startTest();
        Supplier1099Batch job = new Supplier1099Batch(sampleData.companyRecord.Id, sampleData.currentYear, 70000);
        Database.executeBatch(job);
        test.stopTest();
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c , Batch_Job_ID__c, Company__r.Country__c,Payer_Phone__c, Supplier__r.Country__c, PayerCountry__c, Recipient_Country__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 0, 'Expected 1, received ' + supplier1099s.size());
    }
    
    static testMethod void test1099Generation_InvalidSupplierTIN() { //KNDY-17762
        TestData sampleData = new TestData();
        
        sampleData.supplierRecord.Tax_ID__c = '';
        update sampleData.supplierRecord;
        
        Boolean hasException = false;
        String expectedErrorMsg = 'is missing a tax identification number';
        Id testBatchJobId = sampleData.supplierRecord.Id;
        Integer supp1099Ct = 0;
        Test.startTest();
        try{
            supp1099Ct = Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
        }
        catch (Exception ex){
            system.assert(ex.getMessage().contains(expectedErrorMsg), ex);
            hasException = true;
        }
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c];
        system.assertEquals(supplier1099s.size(), 0, 'Expected 0, received ' + supplier1099s.size());
        system.assertEquals(hasException, true);
        system.assertEquals(supp1099Ct, 0, supp1099Ct);
        sampleData.supplierRecord.Tax_ID__c = '123456789101112';
        update sampleData.supplierRecord;

        hasException = false;
        expectedErrorMsg = 'has a tax identification number that exceeds the valid length.';
        try{
            Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
        }
        catch (Exception ex){
            system.assert(ex.getMessage().contains(expectedErrorMsg), ex);
            hasException = true;
        }
        Test.stopTest();
        supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c];
        system.assertEquals(supplier1099s.size(), 0, 'Expected 0, received ' + supplier1099s.size());
        system.assertEquals(hasException, true);
        
    }
    
    static testMethod void test1099Generation_NoCompanyTIN() { //KNDY-17905
        TestData sampleData = new TestData();
        Id testBatchJobId = sampleData.supplierRecord.Id;
        
        sampleData.companyRecord.TIN__c = '';
        update sampleData.companyRecord;
        
        Boolean hasException = false;
        String expectedErrorMsg = 'is missing a tax identification number';
        
        Test.startTest();
        try{
            Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
        }
        catch (Exception ex){
            system.assert(ex.getMessage().contains(expectedErrorMsg), ex);
            hasException = true;
        }
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c];
        system.assertEquals(supplier1099s.size(), 0, 'Expected 0, received ' + supplier1099s.size());
        system.assertEquals(hasException, true);
        
        Test.stopTest();
    }
    
    static testMethod void test1099_NewDeleteClone() { //KNDY-17935
        TestData sampleData = new TestData();
        String expectedErrorMsg = Label.Button_Not_Available;
        Id testBatchJobId = sampleData.supplierRecord.Id;
        
        Test.startTest();
        Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
        
        // Not filed
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c, Filed__c FROM Supplier_1099__c];
        system.assertEquals(supplier1099s.size(), 1, 'Expected 1, received ' + supplier1099s.size());
        PageReference pageRef = Page.Supplier1099NewCloneDelete;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(supplier1099s[0].Id));
        Apexpages.Standardcontroller stdcon = new Apexpages.standardcontroller(supplier1099s[0]);
        NewEditCloneDeleteExt ext = new NewEditCloneDeleteExt(stdcon);
        ext.errMsg();
        
        system.assertEquals(ApexPages.hasMessages(), true);
        system.assertEquals(Apexpages.getMessages().size(), 1);
        system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains(expectedErrorMsg), Apexpages.getMessages());

        //Filed
        supplier1099s[0].Filed__c = true;
        update supplier1099s;
        ext.errMsg();
        
        system.assertEquals(ApexPages.hasMessages(), true);
        system.assertNotEquals(Apexpages.getMessages().size(), 0,Apexpages.getMessages());
        system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains(expectedErrorMsg), Apexpages.getMessages());

        Test.stopTest();
    }

    /*
    *	Test 1099 Rollback
    */
    static testMethod void test1099Rollback() {
    	
        TestData sampleData = new TestData();
        Id testBatchJobId = sampleData.supplierRecord.Id;
        
        Integer supp1099ct = Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 1);
        system.assertEquals(supp1099ct, 1, supp1099ct);
        test.startTest();
        	Database.executeBatch(new Supplier1099RollbackBatch(sampleData.companyRecord.Id));
        test.stopTest();
       
        supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 0);
    }
    
    /*
    *	Test 1099 Rollback
    */
    static testMethod void test1099RunRollback() {
    	
        TestData sampleData = new TestData();
        Id testBatchJobId = sampleData.supplierRecord.Id;
        
        Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c, Batch_Job_Id__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 1);

        test.startTest();
        	Supplier1099RollbackBatch batch = new Supplier1099RollbackBatch();
        	batch.runBatch(sampleData.companyRecord.Id);
        test.stopTest();
       
        supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 0);
    }
    
    /*
    *	Test 1099 Rollback
    */
    static testMethod void test1099RunRollbackBatch_batchJobId() {
    	
        TestData sampleData = new TestData();
        Id testBatchJobId = sampleData.supplierRecord.Id;
        
        Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 1);
        
        test.startTest();
        	Database.executeBatch(new Supplier1099RollbackBatch(sampleData.companyRecord.Id, String.ValueOf(testBatchJobId)));
        test.stopTest();
       
        supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c where Batch_Job_ID__c =: testBatchJobId];
        system.assert(supplier1099s.size() == 0);
    }
    
    static testMethod void test1099RunRollbackExt_Filed1099s() {
    	
        TestData sampleData = new TestData();
        Id testBatchJobId = sampleData.supplierRecord.Id;
        
        Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 1);
        supplier1099s[0].Filed__c = true;
        update supplier1099s;
        
        test.startTest();
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sampleData.companyRecord);
        Supplier1099RollbackExt ext = new Supplier1099RollbackExt(con);
        system.assertEquals(ext.disableRollback, true);
        JsonResult result = Supplier1099RollbackExt.getSupplier1099s(sampleData.companyRecord.Id, String.ValueOf( testBatchJobId));
        system.assertEquals(result.success, false, result);
        system.assertEquals(result.messages.size(), 1, result);
        system.assertEquals(result.messages[0].get('message'), Label.No_supplier_1099_records, result);
        test.stopTest();
    }
    
    static testMethod void test1099RunRollbackExt_UnFiled1099s() {
    	
        TestData sampleData = new TestData();
        Id testBatchJobId = sampleData.supplierRecord.Id;
        
        Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c, Filed__c, Company__c, Batch_Job_ID__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 1);
        system.assertEquals(supplier1099s[0].Filed__c,false, supplier1099s[0]);
        system.assertEquals(supplier1099s[0].Batch_Job_ID__c, testBatchJobId, supplier1099s[0]);
        system.assertEquals(supplier1099s[0].Company__c, sampleData.supplierRecord.Company__c, supplier1099s[0]);
        
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sampleData.companyRecord);
        Supplier1099RollbackExt ext = new Supplier1099RollbackExt(con);
        system.assertEquals(ext.disableRollback, true);
        
        test.startTest();
        JsonResult result = Supplier1099RollbackExt.getSupplier1099s( testBatchJobId,sampleData.supplierRecord.Company__c);
        test.stopTest();
        system.assertEquals(result.success, true, result);
        system.assertEquals(result.messages.size(), 0, result);
        
    }
    
    static testMethod void test1099RunRollbackBatchExt_RollBackWithoutBatchJobId() {
    	
        TestData sampleData = new TestData();
        Id testBatchJobId = sampleData.supplierRecord.Id;
        
        Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 1);
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sampleData.companyRecord);
        Supplier1099RollbackExt ext = new Supplier1099RollbackExt(con);
        
        test.startTest();
        JsonResult result = Supplier1099RollbackExt.rollBack( null,sampleData.companyRecord.Id);
        test.stopTest();
        system.assertEquals(result.success, true, result);
        system.assertEquals(result.messages.size(),1, result);
        system.assert(result.messages[0].get('message').contains(Label.Your_batch_job_was_created), result);
        
        supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c where Batch_Job_ID__c =: testBatchJobId];
        system.assert(supplier1099s.size() == 0);
    }
    
    static testMethod void test1099RunRollbackBatchExt_RollBackWithBatchJobId() {
    	
        TestData sampleData = new TestData();
        Id testBatchJobId = sampleData.supplierRecord.Id;
        
        Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 1);
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sampleData.companyRecord);
        Supplier1099RollbackExt ext = new Supplier1099RollbackExt(con);
        
        test.startTest();
        JsonResult result = Supplier1099RollbackExt.rollBack( testBatchJobId,sampleData.companyRecord.Id);
        test.stopTest();
        system.assertEquals(result.success, true, result);
        system.assertEquals(result.messages.size(),1, result);
        system.assert(result.messages[0].get('message').contains(Label.Your_batch_job_was_created), result);
        
        supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c where Batch_Job_ID__c =: testBatchJobId];
        system.assert(supplier1099s.size() == 0);
    }
    /*
    *	Test 1099 Generation from a batch
    */
    static testMethod void test1099RunBatchExt() {
    	
        TestData sampleData = new TestData();
        
        test.startTest();
        
        	Apexpages.Standardcontroller badcon = new Apexpages.Standardcontroller(new Company__c());
        	Supplier1099BatchExt badext = new Supplier1099BatchExt(badcon);
        	system.assertEquals(ApexPages.hasMessages(), true);
        	system.assertEquals(ApexPages.getMessages().size(), 1,ApexPages.getMessages());
        	system.assertEquals(ApexPages.getMessages()[0].getDetail(), Label.Company_not_found,ApexPages.getMessages());
        	
        	Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sampleData.companyRecord);
        	Supplier1099BatchExt ext = new Supplier1099BatchExt(con);
        	Supplier1099BatchExt.startOffBatch(sampleData.companyRecord.Id, String.ValueOf(sampleData.currentYear), '500');
        test.stopTest();
       
       	List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 1);
    }

   static testMethod void testRerunBatchWithFiled1099s() { //KNDY-17912
        TestData sampleData = new TestData();
        Id testBatchJobId = sampleData.supplierRecord.Id;
        Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
       
        List<Supplier_1099__c> supplier1099s = [SELECT Id, Filed__c,Company__c, Company__r.Name,supplier__c, box1__c, box3__c FROM Supplier_1099__c];
        system.assertEquals(supplier1099s.size(),1,supplier1099s);
        supplier1099s[0].Filed__c = true;
        update supplier1099s;
        Boolean hasException = false;
        test.startTest();
        try{
            Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
        }catch (Exception ex){
            hasException = true;
            String error = Label.Supplier_1099_Filed;
            error = error.replace('<companyName>', supplier1099s[0].Company__r.Name);
            error = error.replace('<reportingYear>', String.ValueOf(sampleData.currentYear));
            system.assertEquals(ex.getMessage(), error, ex);
        }
        test.stopTest();
        system.assertEquals(hasException, true);
        List<Supplier_1099__c> supplier1099sNew = [SELECT Id, Filed__c, Exclude__c, supplier__c, box1__c, box3__c FROM Supplier_1099__c];
        system.assert(supplier1099sNew.size() == 1);
        system.assertEquals(supplier1099sNew[0].Id, supplier1099s[0].Id);
        system.assertEquals(supplier1099sNew[0].Exclude__c, false);
    }
    
    static testMethod void testMultiCompany_Create1099s() {
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice__c-'+Supplier_Invoice__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice_Line__c-'+Supplier_Invoice_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Company__c-'+ Company__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Period__c-'+Period__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        TestData sampleData = new TestData();
        Id testBatchJobId = sampleData.supplierRecord.Id;
        Company__c coNew = sampleData.companyRecord.clone();
        coNew.Name = 'New company';
        coNew.Address__c = sampleData.accRecord1.Id;
        insert coNew;
        
        Boolean hasException = false;
        try{
            sampleData.supplierRecord.x1099_Box_G__c = null;
            update sampleData.supplierRecord;
        }catch(Exception ex){
            hasException = true;
            String error = ex.getMessage();
            system.assert(ex.getMessage().contains('You must select a 1099 Box value for a 1099 reportable supplier.'), ex.getMessage());
        }
        system.assertEquals(hasException, true);
        //Change supplier company
        sampleData.supplierRecord.X1099_Box_G__c = '3 Other Income';
        sampleData.supplierRecord.Company__c = coNew.Id;
        update sampleData.supplierRecord;
        
        //create sp for new company, same supplier
        Supplier_Payment__c spNew = sampleData.suppPayment.clone();
        spNew.Finalized__c = false;
        spNew.Company__c = coNew.Id;
        insert spNew;
        Supplier_Payment_Line__c paymentLine3 = new Supplier_Payment_Line__c();
        paymentLine3.Supplier_Invoice__c = sampleData.supplierInv1.Id;
        paymentLine3.Amount__c = 100.00;
        paymentLine3.Supplier_Payment__c = spNew.Id;
        paymentLine3.X1099_Box_G__c = '1 Rents';
        insert paymentLine3;
        spNew.Finalized__c = true;
        update spNew;
        
        Test.startTest();
        //generate 1099s for old company
        Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
       
        List<Supplier_1099__c> supplier1099s = [SELECT Id, Filed__c,Company__c, Company__r.Name,supplier__c, box1__c, box3__c FROM Supplier_1099__c where Exclude__c = false];
        system.assertEquals(supplier1099s.size(),1,supplier1099s);
        system.assertEquals(supplier1099s[0].Company__c, sampleData.companyRecord.Id);
        system.assertEquals(supplier1099s[0].Supplier__c, sampleData.supplierRecord.Id);
        
        // generate 1099s for new company
        Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, coNew.Id);
       
        supplier1099s = [SELECT Id, Filed__c,Company__c, Company__r.Name,supplier__c, box1__c, box3__c FROM Supplier_1099__c where Exclude__c = false and Company__c = :coNew.Id];
        system.assertEquals(supplier1099s.size(),1,supplier1099s);
        system.assertEquals(supplier1099s[0].Company__c, coNew.Id);
        system.assertEquals(supplier1099s[0].Supplier__c, sampleData.supplierRecord.Id);

        Test.stopTest();
    }
    
    static testMethod void testMultiCompany_Rollback1099s() {
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Supplier_Payment__c-'+Supplier_Payment__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice__c-'+Supplier_Invoice__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Supplier_Invoice_Line__c-'+Supplier_Invoice_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Company__c-'+ Company__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        lConfigs.add(new Configuration__c(Name = 'Period__c-'+Period__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        TestData sampleData = new TestData();
        Id testBatchJobId = sampleData.supplierRecord.Id;
        Company__c coNew = sampleData.companyRecord.clone();
        coNew.Name = 'New company';
        coNew.Address__c = sampleData.accRecord1.Id;
        insert coNew;

        //Change supplier company
        sampleData.supplierRecord.Company__c = coNew.Id;
        update sampleData.supplierRecord;
        
        //create sp for new company, same supplier
        Supplier_Payment__c spNew = sampleData.suppPayment.clone();
        spNew.Finalized__c = false;
        spNew.Company__c = coNew.Id;
        insert spNew;
        Supplier_Payment_Line__c paymentLine3 = new Supplier_Payment_Line__c();
        paymentLine3.Supplier_Invoice__c = sampleData.supplierInv1.Id;
        paymentLine3.Amount__c = 100.00;
        paymentLine3.Supplier_Payment__c = spNew.Id;
        paymentLine3.X1099_Box_G__c = '1 Rents';
        insert paymentLine3;
        spNew.Finalized__c = true;
        update spNew;
       
        //generate 1099s for old company
        Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, sampleData.companyRecord.Id);
        
        // generate 1099s for new company
        Supplier1099Service.generateSupplier1099s(new List<Supplier__c>{sampleData.supplierRecord}, testBatchJobId, sampleData.currentYear, 600, coNew.Id);
       
        List<Supplier_1099__c> supplier1099s = [SELECT Id, Filed__c,Company__c, Company__r.Name,supplier__c, box1__c, box3__c FROM Supplier_1099__c];
        system.assertEquals(supplier1099s.size(),2,supplier1099s);
        
        Set<Id> companyIds= new Set<Id>();
        // Same supplier for both 1099 records
        for (Supplier_1099__c sup1099: supplier1099s){
           companyIds.add(sup1099.Company__c);
           system.assertEquals(supplier1099s[0].Supplier__c, sampleData.supplierRecord.Id);
        }
        // different company on both 1099 records
        system.assertEquals(companyIds.size(), 2, companyIds);
        system.assert(companyIds.contains(coNew.Id), companyIds);
        system.assert(companyIds.contains(sampleData.companyRecord.Id), companyIds);
       
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sampleData.companyRecord);
        Supplier1099RollbackExt ext = new Supplier1099RollbackExt(con);
        
        test.startTest();
        JsonResult result = Supplier1099RollbackExt.rollBack( null,sampleData.companyRecord.Id);
        system.assertEquals(result.success, true, result);
        system.assertEquals(result.messages.size(),1, result);
        system.assert(result.messages[0].get('message').contains(Label.Your_batch_job_was_created), result);
        Test.stopTest();
        
        // 1099 record for other company should not be deleted
        supplier1099s = [SELECT Id, Filed__c,Company__c, Company__r.Name,supplier__c, box1__c, box3__c FROM Supplier_1099__c];
        system.assertEquals(supplier1099s.size(),1,supplier1099s);
        system.assertEquals(supplier1099s[0].Company__c, coNew.Id, supplier1099s);
    }
    
    static testMethod void testExport1099Records_get1099Fields() {
        TestData sampleData = new TestData();
        test.startTest();
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sampleData.companyRecord);
        Export1099RecordsExt ext = new Export1099RecordsExt(con);
        system.assertEquals (String.isBlank(ext.s1099Fields), false, ext);
        system.assertEquals (ext.s1099Fields.contains('\"title\":\"Id\"'), false, ext.s1099Fields);
        test.stopTest();
    }
    
    static testMethod void testExport1099Records_getReturnURL() {
        TestData sampleData = new TestData();
        test.startTest();
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(sampleData.companyRecord);
        Export1099RecordsExt ext = new Export1099RecordsExt(con);
        String retURL = ext.getReturnURL();
        Schema.DescribeSObjectResult result = Supplier_1099__c.SObjectType.getDescribe();
        system.assertEquals (retURL.contains(result.getKeyPrefix()), true, retURL);
        test.stopTest();
    }
    
    static testMethod void testExport1099Records_getSupplier1099RecordsForCompany() {
        TestData sampleData = new TestData();
        
        Test.startTest();
        Supplier1099Batch job = new Supplier1099Batch(sampleData.companyRecord.Id, sampleData.currentYear, 600);
        	Database.executeBatch(job);
        Test.stopTest();
        
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c , Batch_Job_ID__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 1, 'Expected 1, received ' + supplier1099s.size());
        
        JsonResult result =  Export1099RecordsExt.getSupplier1099Records(new List<String> {sampleData.companyRecord.Id}, String.ValueOf(sampleData.currentYear));
        //result.records = new List<Map<String, List<Supplier_1099__c>>>{mapCompanyId1099Records};
        system.assertEquals(result.success, true, result);
        List<Map<String, List<Supplier_1099__c>>> mapCompanyId1099Records = (List<Map<String, List<Supplier_1099__c>>>) result.records;
        system.assertEquals(mapCompanyId1099Records.size(), 1, mapCompanyId1099Records);
        String expectedKey = 'Supplier 1099s-' + sampleData.companyRecord.Name + '-' + sampleData.currentYear;
        system.assert(mapCompanyId1099Records[0].get(expectedKey) != null, mapCompanyId1099Records);
        List<Supplier_1099__c> s1099Recs = mapCompanyId1099Records[0].get(expectedKey) ;
        system.assertEquals(s1099Recs.size(), 1);
    }

    static testMethod void testExport1099Records_getSupplier1099Records_NoCompanySpecified() {
        TestData sampleData = new TestData();
        
        Test.startTest();
        Supplier1099Batch job = new Supplier1099Batch(sampleData.companyRecord.Id, sampleData.currentYear, 600);
        	Database.executeBatch(job);
        Test.stopTest();
        
        List<Supplier_1099__c> supplier1099s = [SELECT Id, box1__c, box3__c , Batch_Job_ID__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 1, 'Expected 1, received ' + supplier1099s.size());
        
        JsonResult result =  Export1099RecordsExt.getSupplier1099Records(null, String.ValueOf(sampleData.currentYear));
        //result.records = new List<Map<String, List<Supplier_1099__c>>>{mapCompanyId1099Records};
        system.assertEquals(result.success, true, result);
        List<Map<String, List<Supplier_1099__c>>> mapCompanyId1099Records = (List<Map<String, List<Supplier_1099__c>>>) result.records;
        system.assertEquals(mapCompanyId1099Records.size(), 1, mapCompanyId1099Records);
        String expectedKey = 'Supplier 1099s-' + sampleData.companyRecord.Name + '-' + sampleData.currentYear;
        system.assert(mapCompanyId1099Records[0].get(expectedKey) != null, mapCompanyId1099Records);
        List<Supplier_1099__c> s1099Recs = mapCompanyId1099Records[0].get(expectedKey) ;
        system.assertEquals(s1099Recs.size(), 1);
    }
    
    static testMethod void testExport1099Records_getSupplier1099RecordsFailure() {
        TestData sampleData = new TestData();
        
        Test.startTest();
        Supplier1099Batch job = new Supplier1099Batch(sampleData.companyRecord.Id, sampleData.currentYear, 600);
        	Database.executeBatch(job);
        Test.stopTest();
        
        List<Supplier_1099__c> supplier1099s = [SELECT Id, Exclude__c, box1__c, box3__c , Batch_Job_ID__c FROM Supplier_1099__c];
        system.assert(supplier1099s.size() == 1, 'Expected 1, received ' + supplier1099s.size());
        supplier1099s[0].Exclude__c = true;
        update supplier1099s;
        
        
        JsonResult result =  Export1099RecordsExt.getSupplier1099Records(new List<String> {sampleData.companyRecord.Id}, String.ValueOf(sampleData.currentYear));
        //result.records = new List<Map<String, List<Supplier_1099__c>>>{mapCompanyId1099Records};
        system.assertEquals(result.success, false, result);
        system.assertEquals(result.messages.size(), 1);
        system.assertEquals(True,result.messages[0].get('message').contains(Label.No_records_are_available_to_export), result);
    }
}