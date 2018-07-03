@isTest
private class TestFuelTests {
    
    @testSetup static void ts() { 
        TestFuel data = new TestFuel(); 
        // these asserts cause TestFuel to insert data
        system.assert(      
            data.company != null &&
            data.bankAccount != null &&
            data.customerSoldTo != null &&
            data.customerBillTo != null &&
            data.product_Misc != null &&
            data.product != null &&
            data.periodList != null &&
            data.salesOrder != null &&
            data.salesOrderLines != null &&
            data.purchaseOrder != null &&
            data.stockMovementRuleList != null &&
            data.smrsList != null &&
            data.itemList != null &&
            data.itemAttrObj != null &&
            data.itemAttrObj2 != null &&
            data.bin != null &&
            data.location != null &&
            data.RENTAL_MONTH != null &&
            data.resolutionCode != null
        );
        
        
    	insert new Segment_Validation__c(Active__c = true, Segment_1__c ='*',  Segment_2__c ='*');													   
    }
    
    static testMethod void CustomerInvoiceManageExtTest_createCI_BillToCustomerCurrency() {
        
        TestFuelQuery fuel = new TestFuelQuery();

        Currency__c currencyCAD = new Currency__c();
        currencyCAD.name = 'CAD TestFuel';
        currencyCAD.ISO_Code__c = 'CAD';
        currencyCAD.Currency__c = 'CAD Currency';
        insert currencyCAD;
        
        fuel.customerBillTo.Currency__c = currencyCAD.Id;
        update fuel.customerBillTo;
        
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Currency__c = currencyCAD.id; // updated by Script in the VF.
        CustomerInvoice.Transaction_Date__c = Date.today();
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
        CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
        system.assertEquals(ext.pgError, false);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
        List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
        Customer_invoice_line__C cil= new Customer_invoice_line__C(product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1);
        CustomerInvoiceManageExt.SHILineWrapper sw= new CustomerInvoiceManageExt.SHILineWrapper(cil);
        List<CustomerInvoiceManageExt.SHILineWrapper> newList = new List<CustomerInvoiceManageExt.SHILineWrapper>();
        sw.shiline=cil;
        sw.c = new Customer_invoice__C(id=CustomerInvoice.id);
        newList.add(sw);    
                        
        JSONREsult jr=   CustomerInvoiceManageExt.saveAction(CustomerInvoice,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),newList,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),1,jr);
        Customer_Invoice__c ci = [Select id, Status__c, Finalized__c, Currency__r.Name, (Select Id, Product__c, Accounting_Segment__c from Customer_Invoice_Lines__r) from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1];
        system.assertEquals(ci.Customer_Invoice_Lines__r.size(), 1);
        system.assertEquals(ci.Finalized__c, false);
        system.assertEquals(ci.Customer_Invoice_Lines__r[0].Product__c, fuel.product_Misc.Id);
        system.assertEquals(ci.Currency__r.Name, 'CAD');
       
       
    }
    
    

    /* KNDY-8862 - due to change in requirements the page will be loaded and the finalized invoices can be modified (Additional Inbfo Section)
      static testMethod void CustomerInvoiceManageExtTest_cannotLoadPage_Finalized() {
        
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
        Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
        cil.Customer_Invoice__c = CustomerInvoice.Id;
        cil.Quantity_Shipped__c = 1;
        cil.Unit_Price__c = 100;
        insert cil;
        
        CustomerInvoice.Finalized__c = true;
        update CustomerInvoice;
        
       CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
       system.assertEquals(ext.pgError, true);
       boolean ErrorExists = false;
        for( ApexPages.Message msg :ApexPages.GetMessages())
            if(msg.getDetail()  == 'Cannot edit finalized customer Invoice.')
            {
                ErrorExists = true;
                break;
            }
        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
    }   
    */
    
    static testmethod void BankAccountTest_CurrencyIsRequired(){
        TestFuelQuery fuel = new TestFuelQuery();
        Bank_Account__c ba = fuel.bankAccount;
        ba.Currency__c = null;
        Boolean sawException = false;
        try{
            update ba;
        }
        catch (Exception ex){
            sawException = true;
            system.assert(ex.getMessage().contains('Currency is required.'));
        }
        system.assertEquals(sawException, true);
    }
    //KNDY-17561 - number of advice lines are required when preprinted stock option is selected
    static testmethod void BankAccountTest_AdviceLinesPerPageIsRequired(){
        TestFuelQuery fuel = new TestFuelQuery();
        Bank_Account__c ba = fuel.bankAccount;
        ba.Use_Pre_Printed_Check_Stock__c = true;
        ba.Number_of_Advice_Lines_Per_Page__c = null;
        Boolean sawException = false;
        try{
            update ba;
        }
        catch (Exception ex){
            sawException = true;
            system.assert(ex.getMessage().contains('You must enter a value for the Number of Advice Lines per Page field when the Use Preprinted Check Stock field is selected.'));
        }
        //check if it is > 0
        ba.Use_Pre_Printed_Check_Stock__c = true;
        ba.Number_of_Advice_Lines_Per_Page__c = 0;
        sawException = false;
        try{
            update ba;
        }
        catch (Exception ex){
            sawException = true;
            system.assert(ex.getMessage().contains('You must enter a value for the Number of Advice Lines per Page field when the Use Preprinted Check Stock field is selected.'));
        }
        system.assertEquals(sawException, true);
        //check if it is < 0 throw exception
        ba.Use_Pre_Printed_Check_Stock__c = true;
        ba.Number_of_Advice_Lines_Per_Page__c = -1;
        sawException = false;
        try{
            update ba;
        }
        catch (Exception ex){
            sawException = true;
            system.assert(ex.getMessage().contains('You must enter a value for the Number of Advice Lines per Page field when the Use Preprinted Check Stock field is selected.'));
        }
        system.assertEquals(sawException, true);
        //insert bank account
        Bank_Account__c bankAccount = new Bank_Account__c(
    				Name = 'Test BOFA',
    				account_type__c = 'Checking',
    				GL_Account__c = fuel.receivablesGL.id,
    				Company__c = fuel.company.Id,
    				Active__c = true,
    				Currency__c = fuel.currencyUSD.id,
    				Use_Pre_Printed_Check_Stock__c = true,
    				Number_of_Advice_Lines_Per_Page__c = 0
				);
		sawException = false;
		try{
            insert bankAccount; 
        }
        catch (Exception ex){
            sawException = true;
            system.assert(ex.getMessage().contains('You must enter a value for the Number of Advice Lines per Page field when the Use Preprinted Check Stock field is selected.'));
        }
        system.assertEquals(sawException, true);
        //bank account with < 0 number of advice lines per page. 
        bankAccount = new Bank_Account__c(
    				Name = 'Test BOFA',
    				account_type__c = 'Checking',
    				GL_Account__c = fuel.receivablesGL.id,
    				Company__c = fuel.company.Id,
    				Active__c = true,
    				Currency__c = fuel.currencyUSD.id,
    				Use_Pre_Printed_Check_Stock__c = true,
    				Number_of_Advice_Lines_Per_Page__c = -1
				);
		sawException = false;
		try{
            insert bankAccount; 
        }
        catch (Exception ex){
            sawException = true;
            system.assert(ex.getMessage().contains('You must enter a value for the Number of Advice Lines per Page field when the Use Preprinted Check Stock field is selected.'));
        }	
        system.assertEquals(sawException, true);	
        
		//insert bank account with valid values
        bankAccount = new Bank_Account__c(
    				Name = 'Test BOFA',
    				account_type__c = 'Checking',
    				GL_Account__c = fuel.receivablesGL.id,
    				Company__c = fuel.company.Id,
    				Active__c = true,
    				Currency__c = fuel.currencyUSD.id,
    				Use_Pre_Printed_Check_Stock__c = true,
    				Number_of_Advice_Lines_Per_Page__c = 1
				);
		
        insert bankAccount; 
        List<Bank_Account__c> baValidList = [select id,Use_Pre_Printed_Check_Stock__c,Number_of_Advice_Lines_Per_Page__c from Bank_Account__c where Id =: bankAccount.id];
        system.assertEquals(baValidList.size() ==1, true);	
        system.assertEquals(baValidList[0].Use_Pre_Printed_Check_Stock__c == true && baValidList[0].Number_of_Advice_Lines_Per_Page__c > 0 , true);	
        
       
    }

    static testMethod void testAmountOnCIL_Sales() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	Customer_INvoice__c ci = new Customer_Invoice__c(Company__c = fuel.company.Id, Customer__c = fuel.customerParent.Id);
    	insert ci;
    	
    	Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c(Customer_Invoice__c = ci.Id, Unit_Price__c = 1, Quantity_Shipped__c = 100, Off_Invoice_Rate__c = 0.123, Discount_Amount__c = 10, Allowances__c = 10, Sales_Tax__c = 10, Value_Added_Tax__c = 10);
    	insert cil;
    	cil = [Select id, Amount__c from Customer_Invoice_Line__c where Id = :cil.ID limit 1];
    	system.assertEquals(107.70, cil.Amount__c);
    	
    }
    
    static testMethod void testAmountOnCIL_Recurring() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	Customer_INvoice__c ci = new Customer_Invoice__c(Company__c = fuel.company.Id, Customer__c = fuel.customerParent.Id);
    	insert ci;
    	Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c(Customer_Invoice__c = ci.Id, Unit_Price__c = 1, Quantity_Shipped__c = 100, Off_Invoice_Rate__c = 0.123, Discount_Amount__c = 10, Allowances__c = 10, Sales_Tax__c = 10, Value_Added_Tax__c = 10,
    																Start_Date__c = system.now().addDays(-10), End_Date__c = system.now(), Pricing_UOM__c = fuel.RentalMonth.Id, Price_Type__c = 'Recurring');
    	insert cil;
    	
    	cil = [Select id, Amount__c, ProRate_Factor__c from Customer_Invoice_Line__c where Id = :cil.ID limit 1];
    	
    	system.assertEquals(0.357143, cil.ProRate_Factor__c);
    	system.assertEquals(51.32, cil.Amount__c);
    	
    }
    
    static testMethod void testAmountOnSIL() {
    	TestFuelQuery fuel = new TestFuelQuery();
    	Supplier_Invoice__c si = new Supplier_Invoice__c (Supplier__c = fuel.supplier.Id, Invoice_Amount__c = 100, Supplier_Invoice__c= '124', Invoice_Type__c = 'Invoice');
    	insert si;
    	
    	Supplier_Invoice_Line__c sil = new Supplier_Invoice_Line__c(Supplier_Invoice__c = si.Id, Unit_Price__c = 1.001, VAT_Amount__c = .22, Invoice_Quantity__c = 100);//KNDY-14371
    	insert sil;
    	
    	sil = [Select id, Amount__c from Supplier_Invoice_Line__c where Id = :sil.ID limit 1];
    	system.assertEquals(100.32, sil.Amount__c);
    }
    static testMethod  void SIValidateButton() {
        TestFuelQuery fuel = new TestFuelQuery();
        Supplier_Invoice__c si = new Supplier_Invoice__c (Supplier__c = fuel.supplier.Id, Invoice_Amount__c = 100, Supplier_Invoice__c= '124', Invoice_Type__c = 'Invoice');
        insert si;

        Supplier_Invoice_Line__c sil = new Supplier_Invoice_Line__c(Supplier_Invoice__c = si.Id, Unit_Price__c = 1.001, VAT_Amount__c = .22, Invoice_Quantity__c = 100);//KNDY-14371
        insert sil;
        SupplierInvoiceValidateExt ext = new SupplierInvoiceValidateExt(new Apexpages.standardcontroller(si));

        system.assertEquals(false, ext.OnholdFlag);
        ext.inspect();
        system.assertNotEquals(null,ApexPages.GetMessages());
        PageReference page = ext.close();
        system.assertNotEquals(null, page);


        si.Status__c = 'Cancelled';
        update si;
        ext = new SupplierInvoiceValidateExt(new Apexpages.standardcontroller(si));

        system.assertEquals(true, ext.OnholdFlag);

    }
    
    static testMethod void CustomerInvoiceLineInsertSalesTax() {
    	TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
        Customer_invoice_Line__c cil = new Customer_Invoice_Line__c(Customer_invoice__c = CustomerInvoice.Id, Product__c = fuel.product_Misc.Id, Quantity_Shipped__c = 1, Unit_Price__c = 1, Sales_Tax__c = 1.119);
        insert cil;
        cil = [Select Id, Sales_Tax__c from Customer_Invoice_Line__c where id = :cil.ID];
        system.assertEquals(1.12, cil.Sales_Tax__c); 
        cil.Sales_Tax__c = 1.323;
        update cil;
        cil = [Select Id, Sales_Tax__c from Customer_Invoice_Line__c where id = :cil.ID];
        system.assertEquals(1.32, cil.Sales_Tax__c); 
        
    }
    
    
    static testMethod void CustomerInvoiceManageExtTest_canLoadPage() {
        
        //insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test'); 
        
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
                
       CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
       system.assertEquals(ext.pgError, false);
       system.assertNotEquals(null, ext.getCustomerInvoiceAmountFieldList());
    }
    
    

      static testMethod void CustomerInvoiceManageExtTest_clone() {
        
       // insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test'); 
        
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
       CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
       system.assertEquals(ext.pgError, false);
         system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
         List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
             Customer_invoice_line__C cil= new Customer_invoice_line__C(Customer_invoice__c=customerinvoice.id,product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1);
          insert cil; 
          Customer_invoice__c cinvClone = (Customer_invoice__c) CustomerInvoiceManageExt.getInvoice(CustomerInvoice.Id,true).records[0];
             
          Integer countlines =[select id  from Customer_invoice_Line__c where customer_invoice__c = :customerinvoice.id].size();
          List<CustomerInvoiceManageExt.SHILineWrapper> ciLinesWrapClone=(List<CustomerInvoiceManageExt.SHILineWrapper>) CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.Id,true).records;
                      
        JSONREsult jr=   CustomerInvoiceManageExt.saveAction(cinvClone,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),ciLinesWrapClone,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(cinvClone.id,false).records.size(),1,jr);
        Customer_Invoice__c ci = [Select id, Status__c, Finalized__c,(Select Id, Product__c, Accounting_Segment__c from Customer_Invoice_Lines__r) from Customer_Invoice__c where id = :cinvClone.Id limit 1];
        system.assertEquals(ci.Customer_Invoice_Lines__r.size(), 1,countlines);
        system.assertEquals(ci.Finalized__c, false);
        system.assertEquals(ci.Customer_Invoice_Lines__r[0].Product__c, fuel.product_Misc.Id);
       
    }
    
    static testMethod void CustomerInvoiceManageExtTest_cloneClosedCI_AmountPaidWriteOffAmount() {
        
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
       CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
       system.assertEquals(ext.pgError, false);
         system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
         List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
             Customer_invoice_line__C cil= new Customer_invoice_line__C(Customer_invoice__c=customerinvoice.id,product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1);
          insert cil; 

       Customer_Invoice__c ci = new Customer_Invoice__c (
           Id = CustomerInvoice.Id,
           Amount_Paid__c = cil.Unit_Price__c * cil.quantity_shipped__c - 1,
           Write_Off_Amount__c = 1,
           Status__c = 'Closed'
       );
       update ci;
       Customer_Invoice__c cinv = [Select Amount_Paid__c, Status__c from Customer_Invoice__c where Id = :CustomerInvoice.Id];
       system.assertEquals(cinv.Status__c, 'Closed', '>>> cinv: ' + cinv);
      
          Customer_invoice__c cinvClone = (Customer_invoice__c) CustomerInvoiceManageExt.getInvoice(CustomerInvoice.Id,true).records[0];
             
          Integer countlines =[select id  from Customer_invoice_Line__c where customer_invoice__c = :customerinvoice.id].size();
          List<CustomerInvoiceManageExt.SHILineWrapper> ciLinesWrapClone=(List<CustomerInvoiceManageExt.SHILineWrapper>) CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.Id,true).records;
        test.startTest();              
        JSONREsult jr=   CustomerInvoiceManageExt.saveAction(cinvClone,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),ciLinesWrapClone,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(cinvClone.id,false).records.size(),1,jr);
        ci = [Select id, Status__c, Finalized__c,(Select Id, Product__c, Accounting_Segment__c from Customer_Invoice_Lines__r) from Customer_Invoice__c where id = :cinvClone.Id limit 1];
        system.assertEquals(ci.Customer_Invoice_Lines__r.size(), 1,countlines);
        system.assertEquals(ci.Finalized__c, false);
        system.assertEquals(ci.Customer_Invoice_Lines__r[0].Product__c, fuel.product_Misc.Id);
        test.stopTest();
       
    }
    
    static testMethod void CustomerInvoiceManageExtTest_cloneClosedCI_DeductionAndDiscount() {
        
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        insert CustomerInvoice;
        
       CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
       system.assertEquals(ext.pgError, false);
         system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
         List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
             Customer_invoice_line__C cil= new Customer_invoice_line__C(Customer_invoice__c=customerinvoice.id,product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=2);
          insert cil; 
       
       Customer_Invoice__c ci = new Customer_Invoice__c (
           Id = CustomerInvoice.Id,
           Amount_Paid__c = cil.Unit_Price__c * cil.quantity_shipped__c - 1,
           Deduction_Amount__c = .90,
           Discount_Taken__c = .10,
           Status__c = 'Closed'
       );
       update ci;
       Customer_Invoice__c cinv = [Select Amount_Paid__c, Status__c from Customer_Invoice__c where Id = :CustomerInvoice.Id];
       system.assertEquals(cinv.Status__c, 'Closed', '>>> cinv: ' + cinv);
      
          Customer_invoice__c cinvClone = (Customer_invoice__c) CustomerInvoiceManageExt.getInvoice(CustomerInvoice.Id,true).records[0];
             
          Integer countlines =[select id  from Customer_invoice_Line__c where customer_invoice__c = :customerinvoice.id].size();
          List<CustomerInvoiceManageExt.SHILineWrapper> ciLinesWrapClone=(List<CustomerInvoiceManageExt.SHILineWrapper>) CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.Id,true).records;
         test.startTest();                
        JSONREsult jr=   CustomerInvoiceManageExt.saveAction(cinvClone,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),ciLinesWrapClone,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(cinvClone.id,false).records.size(),1,jr);
        ci = [Select id, Status__c, Finalized__c,(Select Id, Product__c, Accounting_Segment__c from Customer_Invoice_Lines__r) from Customer_Invoice__c where id = :cinvClone.Id limit 1];
        system.assertEquals(ci.Customer_Invoice_Lines__r.size(), 1,countlines);
        system.assertEquals(ci.Finalized__c, false);
        system.assertEquals(ci.Customer_Invoice_Lines__r[0].Product__c, fuel.product_Misc.Id);
         test.stopTest();  
       
    }
    
    //Settle a CI against a claim will set Debit Appplied on CI
    static testMethod void CustomerInvoiceManageExtTest_cloneClosedCI_DebitApplied() {
        
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        insert CustomerInvoice;
        
       CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
       system.assertEquals(ext.pgError, false);
         system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
         List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
             Customer_invoice_line__C cil= new Customer_invoice_line__C(Customer_invoice__c=customerinvoice.id,product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1);
          insert cil; 
       
       Customer_Invoice__c ci = new Customer_Invoice__c (
           Id = CustomerInvoice.Id,
           Debit_Applied__c = cil.Unit_Price__c * cil.quantity_shipped__c,
          Status__c = 'Closed'
       );
       update ci;
       Customer_Invoice__c cinv = [Select Amount_Paid__c, Status__c from Customer_Invoice__c where Id = :CustomerInvoice.Id];
       system.assertEquals(cinv.Status__c, 'Closed', '>>> cinv: ' + cinv);
      
          Customer_invoice__c cinvClone = (Customer_invoice__c) CustomerInvoiceManageExt.getInvoice(CustomerInvoice.Id,true).records[0];
             
          Integer countlines =[select id  from Customer_invoice_Line__c where customer_invoice__c = :customerinvoice.id].size();
          List<CustomerInvoiceManageExt.SHILineWrapper> ciLinesWrapClone=(List<CustomerInvoiceManageExt.SHILineWrapper>) CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.Id,true).records;
           test.startTest();              
        JSONREsult jr=   CustomerInvoiceManageExt.saveAction(cinvClone,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),ciLinesWrapClone,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(cinvClone.id,false).records.size(),1,jr);
        ci = [Select id, Status__c, Finalized__c,(Select Id, Product__c, Accounting_Segment__c from Customer_Invoice_Lines__r) from Customer_Invoice__c where id = :cinvClone.Id limit 1];
        system.assertEquals(ci.Customer_Invoice_Lines__r.size(), 1,countlines);
        system.assertEquals(ci.Finalized__c, false);
        system.assertEquals(ci.Customer_Invoice_Lines__r[0].Product__c, fuel.product_Misc.Id);
         test.stopTest();  
    }
    
    static testMethod void CustomerInvoiceManageExtTest_cloneClosedCI_CreditApplied() {
        
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Prepayment';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        insert CustomerInvoice;
        
       CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
       system.assertEquals(ext.pgError, false);
         system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
         List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
             Customer_invoice_line__C cil= new Customer_invoice_line__C(Customer_invoice__c=customerinvoice.id,product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=-1,quantity_shipped__c=1);
          insert cil; 
          
       Customer_Invoice__c ci = new Customer_Invoice__c (
           Id = CustomerInvoice.Id,
           Credit_Applied__c = -1 * cil.Unit_Price__c * cil.quantity_shipped__c,
           Status__c = 'Closed'
       );
       update ci;
          
       Customer_Invoice__c cinv = [Select Amount_Paid__c, Status__c from Customer_Invoice__c where Id = :CustomerInvoice.Id];
       system.assertEquals(cinv.Status__c, 'Closed', '>>> cinv: ' + cinv);
      
          Customer_invoice__c cinvClone = (Customer_invoice__c) CustomerInvoiceManageExt.getInvoice(CustomerInvoice.Id,true).records[0];
             
          Integer countlines =[select id  from Customer_invoice_Line__c where customer_invoice__c = :customerinvoice.id].size();
          List<CustomerInvoiceManageExt.SHILineWrapper> ciLinesWrapClone=(List<CustomerInvoiceManageExt.SHILineWrapper>) CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.Id,true).records;
         test.startTest();                
        JSONREsult jr=   CustomerInvoiceManageExt.saveAction(cinvClone,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),ciLinesWrapClone,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(cinvClone.id,false).records.size(),1,jr);
        ci = [Select id, Status__c, Finalized__c,(Select Id, Product__c, Accounting_Segment__c from Customer_Invoice_Lines__r) from Customer_Invoice__c where id = :cinvClone.Id limit 1];
        system.assertEquals(ci.Customer_Invoice_Lines__r.size(), 1,countlines);
        system.assertEquals(ci.Finalized__c, false);
        system.assertEquals(ci.Customer_Invoice_Lines__r[0].Product__c, fuel.product_Misc.Id);
         test.stopTest();  
       
    }
    
    static testMethod void CustomerInvoiceManageExtTest_saveLines_MiscProduct() {
        
        //insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        CustomerInvoice.Transaction_Date__c = Date.today();
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
       CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
       system.assertEquals(ext.pgError, false);
         system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
         List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
             Customer_invoice_line__C cil= new Customer_invoice_line__C(product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1);
        CustomerInvoiceManageExt.SHILineWrapper sw= new CustomerInvoiceManageExt.SHILineWrapper(cil);
        List<CustomerInvoiceManageExt.SHILineWrapper> newList = new List<CustomerInvoiceManageExt.SHILineWrapper>();
        sw.shiline=cil;
        sw.c = new Customer_invoice__C(id=CustomerInvoice.id);
        newList.add(sw);
        

                    
     JSONREsult jr=   CustomerInvoiceManageExt.saveAction(CustomerInvoice,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),newList,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),1,jr);
        Customer_Invoice__c ci = [Select id, Status__c, Finalized__c,(Select Id, Product__c, Subtransaction_Type__c, Accounting_Segment__c from Customer_Invoice_Lines__r) from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1];
        system.assertEquals(ci.Customer_Invoice_Lines__r.size(), 1);
        system.assertEquals(ci.Finalized__c, false);
        system.assertEquals(ci.Customer_Invoice_Lines__r[0].Product__c, fuel.product_Misc.Id);
        system.assertEquals(ci.Customer_Invoice_Lines__r[0].Accounting_Segment__c, null);
        //product_Misc item class is Goods
        system.assertEquals('Goods',ci.Customer_Invoice_Lines__r[0].Subtransaction_Type__c);
        system.debug(logginglevel.error,'ReturnURL--->'+ext.getReturnURL());
        system.assertEquals(ext.getReturnURL(),'/' + ci.Id);
    }
    
    static testMethod void CustomerInvoiceManageExtTest_clonenotSaved_goback() {
        
       // insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test'); 
        
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();  
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
         CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
         system.assertEquals(ext.pgError, false);
         system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
         List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
         Customer_invoice_line__c cil= new Customer_invoice_line__C(Customer_invoice__c=customerinvoice.id,product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1);
         insert cil; 
         
         Customer_invoice__c cinvCloneNotSaved = (Customer_invoice__c) CustomerInvoiceManageExt.getInvoice(CustomerInvoice.Id,true).records[0];
         Integer countlines =[select id  from Customer_invoice_Line__c where customer_invoice__c = :customerinvoice.id].size();
         List<CustomerInvoiceManageExt.SHILineWrapper> ciLinesWrapClone = (List<CustomerInvoiceManageExt.SHILineWrapper>) CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.Id,true).records;
		 system.assertEquals(cinvCloneNotSaved.id, null, 'ciClone not created');
        
         CustomerInvoiceManageExt ext1 = new CustomerInvoiceManageExt(new ApexPages.standardController(cinvCloneNotSaved));
         Apexpages.currentPage().getParameters().put('retURL','/'+CustomerInvoice.Id);  
         system.debug(logginglevel.error,'ReturnURL--->'+ext1.getReturnURL());
         system.assertEquals(ext1.getReturnURL(),'/' + CustomerInvoice.Id); //goes to previous CI 
         
    }
    
    static testMethod void CustomerInvoiceManageExtTest_saveLines_0QTY() {
        
         //insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        CustomerInvoice.Transaction_Date__c = Date.today();
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
       CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
       system.assertEquals(ext.pgError, false);
         system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
         List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
             Customer_invoice_line__C cil= new Customer_invoice_line__C(product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=1, quantity_shipped__c = 0);
        CustomerInvoiceManageExt.SHILineWrapper sw= new CustomerInvoiceManageExt.SHILineWrapper(cil);
        List<CustomerInvoiceManageExt.SHILineWrapper> newList = new List<CustomerInvoiceManageExt.SHILineWrapper>();
        sw.shiline=cil;
        sw.c = new Customer_invoice__C(id=CustomerInvoice.id);
        newList.add(sw);
        
		CustomerInvoice.Finalized__c = true;
                    
     JSONREsult jr=   CustomerInvoiceManageExt.saveAction(CustomerInvoice,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),newList,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        system.assertEquals(false, jr.success);
       
       
    }
 
    static testMethod void CustomerInvoiceManageExtTest_saveLines_Error_NoMiscProduct() {
        
        //insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
        
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        CustomerInvoice.Transaction_Date__c = Date.today();
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
       CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
       system.assertEquals(ext.pgError, false);
         system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
         List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
             Customer_invoice_line__C cil= new Customer_invoice_line__C(product__c= fuel.product.Id , Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1);
        CustomerInvoiceManageExt.SHILineWrapper sw= new CustomerInvoiceManageExt.SHILineWrapper(cil);
        List<CustomerInvoiceManageExt.SHILineWrapper> newList = new List<CustomerInvoiceManageExt.SHILineWrapper>();
        sw.shiline=cil;
        sw.c = new Customer_invoice__C(id=CustomerInvoice.id);
        newList.add(sw);
        

                    
     JSONREsult jr=   CustomerInvoiceManageExt.saveAction(CustomerInvoice,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),newList,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0,jr);
        Customer_Invoice__c ci = [Select id, Status__c, Finalized__c,(Select Id, Product__c, Accounting_Segment__c from Customer_Invoice_Lines__r) from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1];
        boolean errorchk = false;
        for(Map<String, String> errMsg: jr.messages){
           String msg = errMsg.get('message');
                system.debug('Message :::'+ msg + 'errMsg:'+ errMsg);
            if(msg.equalsIgnorecase(Label.Only_items_of_source_miscellanous_can_be_added))
            errorchk=true;
            
       }
       system.assertEquals(true,errorchk,jr);

       Customer_Invoice__c cinv = [Select id, Status__c, Finalized__c,(Select Id, Product__c, Accounting_Segment__c from Customer_Invoice_Lines__r) from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1];
       system.assertEquals(cinv.Customer_Invoice_Lines__r.size(), 0);
       system.assertEquals(cinv.Finalized__c, false);
       
       
    }
    
    static testMethod void CustomerInvoiceManageExtTest_saveAndFinalize() {
        
        //insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test'); 
        
                
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
    
       CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
       system.assertEquals(ext.pgError, false);
         system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
         List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
             Customer_invoice_line__C cil= new Customer_invoice_line__C(product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1);
        CustomerInvoiceManageExt.SHILineWrapper sw= new CustomerInvoiceManageExt.SHILineWrapper(cil);
        List<CustomerInvoiceManageExt.SHILineWrapper> newList = new List<CustomerInvoiceManageExt.SHILineWrapper>();
        sw.shiline=cil;
        sw.c = new Customer_invoice__C(id=CustomerInvoice.id);
        newList.add(sw);
        
        CustomerInvoice.Finalized__c=true;
                    
     JSONREsult jr=   CustomerInvoiceManageExt.saveAction(CustomerInvoice,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),newList,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),1,jr);
      
       Customer_invoice__c cinv = (Customer_invoice__c) CustomerInvoiceManageExt.getInvoice(CustomerInvoice.Id,false).records[0];
       List<CustomerInvoiceManageExt.SHILineWrapper> ciLinesWrap=(List<CustomerInvoiceManageExt.SHILineWrapper>) CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.Id,false).records;
      // Customer_Invoice__c cinv = [Select id, Status__c, Finalized__c,(Select Id, Product__c, Accounting_Segment__c from Customer_Invoice_Lines__r) from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1];
       system.assertEquals(ciLinesWrap.size(), 1);
       system.assertEquals(cinv.Finalized__c, true);
       
    }
        
    static testMethod void CustomerInvoiceManageExtTest_createNewLineNoProductNoSegment() {
        
        //insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
    	TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
        CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
        system.assertEquals(ext.pgError, false);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
        
        List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
        Customer_invoice_line__C cil= new Customer_invoice_line__C( Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1);
        CustomerInvoiceManageExt.SHILineWrapper sw= new CustomerInvoiceManageExt.SHILineWrapper(cil);
        List<CustomerInvoiceManageExt.SHILineWrapper> newList = new List<CustomerInvoiceManageExt.SHILineWrapper>();
        sw.shiline=cil;
        sw.c = new Customer_invoice__C(id=CustomerInvoice.id);
        newList.add(sw);
        
        test.startTest();
        	JSONREsult jr=   CustomerInvoiceManageExt.saveAction(CustomerInvoice,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),newList,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        	system.assertEquals(false, jr.success);
        	boolean errorchk = false;
	        for(Map<String, String> errMsg: jr.messages){
	           String msg = errMsg.get('message');
	                system.debug('Message :::'+ msg + 'errMsg:'+ errMsg);
	            if(msg.equalsIgnorecase(Label.Cannot_leave_both_product_and_accounting_segments_blank))
	            errorchk=true;
	            
	       }
       	   system.assertEquals(true,errorchk,jr);
        test.stopTest();
    	
    }
    
    static testMethod void CustomerInvoiceManageExtTest_createNewLineWithSegmentsNoProduct() {
        
       // insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
    	TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
        CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
        system.assertEquals(ext.pgError, false);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
        
        List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
        Customer_invoice_line__C cil= new Customer_invoice_line__C( Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1);
        CustomerInvoiceManageExt.SHILineWrapper sw= new CustomerInvoiceManageExt.SHILineWrapper(cil);
        List<CustomerInvoiceManageExt.SHILineWrapper> newList = new List<CustomerInvoiceManageExt.SHILineWrapper>();
        sw.shiline=cil;
        sw.c = new Customer_invoice__C(id=CustomerInvoice.id);
        sw.segments = new Accounting_Default__c(GL_Account__c = fuel.cashGL.Id,Intercompany__c =fuel.company.Id);
        newList.add(sw);
        
        test.startTest();
        	JSONREsult jr=   CustomerInvoiceManageExt.saveAction(CustomerInvoice,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),newList,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        	system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),1,jr);
        	cil = [Select Id, Subtransaction_Type__c, Accounting_Segment__c, Accounting_Segment__r.Company__c, Accounting_Segment__r.GL_Account__c from Customer_Invoice_Line__c limit 1];
        	system.assertNotEquals(null,cil.Accounting_Segment__r);
        	system.assertEquals(fuel.cashGL.Id,cil.Accounting_Segment__r.GL_Account__c);
        	system.assertEquals(fuel.company.Id,cil.Accounting_Segment__r.Company__c);
        	system.assertEquals('Miscellaneous',cil.Subtransaction_Type__c); //KNDY-14619
        	
        test.stopTest();
    	
    }
    
    static testMethod void CustomerInvoiceManageExtTest_createNewLineWithSegmentsWithProduct() {
        
       // insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
    	TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        
        CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
        system.assertEquals(ext.pgError, false);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
        
        List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
        Customer_invoice_line__C cil= new Customer_invoice_line__C(product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1);
        CustomerInvoiceManageExt.SHILineWrapper sw= new CustomerInvoiceManageExt.SHILineWrapper(cil);
        List<CustomerInvoiceManageExt.SHILineWrapper> newList = new List<CustomerInvoiceManageExt.SHILineWrapper>();
        sw.shiline=cil;
        sw.c = new Customer_invoice__C(id=CustomerInvoice.id);
        sw.segments = new Accounting_Default__c(GL_Account__c = fuel.cashGL.Id,Intercompany__c =fuel.company.Id);
        newList.add(sw);
        
        test.startTest();
        	JSONREsult jr=   CustomerInvoiceManageExt.saveAction(CustomerInvoice,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),newList,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        	system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),1,jr);
        	cil = [Select Id, Subtransaction_Type__c, Accounting_Segment__c, Accounting_Segment__r.Company__c, Accounting_Segment__r.GL_Account__c from Customer_Invoice_Line__c limit 1];
        	system.assertNotEquals(null,cil.Accounting_Segment__r);
        	system.assertEquals(fuel.cashGL.Id,cil.Accounting_Segment__r.GL_Account__c);
        	system.assertEquals(fuel.company.Id,cil.Accounting_Segment__r.Company__c);
        //product_Misc item class is Goods
        	system.assertEquals('Goods',cil.Subtransaction_Type__c); //KNDY-14619
        	
        test.stopTest();
    	
    }
    
    static testMethod void CustomerInvoiceManageExtTest_testManualCIActions() {
        
        String initialTestMapStr = CustomerInvoiceService.populateCIActions(null); 
        System.debug(logginglevel.error,'initialTestMapStr--->'+initialTestMapStr);
       
        Map<String,Object> initialActionTestMap = (Map<String,Object>) JSON.deserializeUntyped(initialTestMapStr);  
        System.debug(logginglevel.error, 'initialTestMap--->'+initialActionTestMap +' '+ initialActionTestMap.size());
       
        system.assert(initialActionTestMap.isEmpty() && initialActionTestMap.size()==0,'Action Avaialble Already');// all the actions are set to false  
        
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        insert CustomerInvoice;
    
        CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
        system.assertEquals(ext.pgError, false);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
        List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
        Customer_invoice_line__C cil= new Customer_invoice_line__C(product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1);
        CustomerInvoiceManageExt.SHILineWrapper sw= new CustomerInvoiceManageExt.SHILineWrapper(cil);
        List<CustomerInvoiceManageExt.SHILineWrapper> newList = new List<CustomerInvoiceManageExt.SHILineWrapper>();
        sw.shiline=cil;
        sw.c = new Customer_invoice__C(id=CustomerInvoice.id);
        newList.add(sw);
        
        //CustomerInvoice.Finalized__c=true;
                    
        JSONREsult jr= CustomerInvoiceManageExt.saveAction(CustomerInvoice,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),newList,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),1,jr);
      
       Customer_invoice__c cinv = (Customer_invoice__c) CustomerInvoiceManageExt.getInvoice(CustomerInvoice.Id,false).records[0];
       List<CustomerInvoiceManageExt.SHILineWrapper> ciLinesWrap=(List<CustomerInvoiceManageExt.SHILineWrapper>) CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.Id,false).records;
	   system.assertEquals(ciLinesWrap.size(), 1);
       system.assertEquals(cinv.Status__c, 'Open'); 
       
       
       String ciTestMapStr = CustomerInvoiceService.populateCIActions(cinv.id); 
       System.debug(logginglevel.error,'ciTestMapStr--->'+ciTestMapStr);
       
       Map<String,Object> ciActionTestMap = (Map<String,Object>) JSON.deserializeUntyped(ciTestMapStr);  
       System.debug(logginglevel.error, 'initialTestMap--->'+ciActionTestMap);
       
       system.assertEquals(ciActionTestMap.get('Clone'),true);
       system.assertEquals(ciActionTestMap.get('Cancel'),true);
       system.assertEquals(ciActionTestMap.get('Get_Tax'),true);
       system.assertEquals(ciActionTestMap.get('Refund_Credit'),false);
       system.assertEquals(ciActionTestMap.get('Unfinalize'),false);
       system.assertEquals(ciActionTestMap.get('Void'),false); 
       system.assertEquals(ciActionTestMap.get('Write_Off'),false); 
       
       cinv.Finalized__c=true;
       update cinv;
       
       system.assertEquals(cinv.Finalized__c, true);
        
       String actionTestMapStr = CustomerInvoiceService.populateCIActions(cinv.id); 
       System.debug(logginglevel.error,'actionTestMapStr--->'+actionTestMapStr);
       
       Map<String,Object> actionTestMap = (Map<String,Object>) JSON.deserializeUntyped(actionTestMapStr);  
       System.debug(logginglevel.error, 'actionTestMap--->'+actionTestMap);
       
       system.assertEquals(actionTestMap.get('Clone'),true);
	   system.assertEquals(actionTestMap.get('Cancel'),true);
       system.assertEquals(actionTestMap.get('Get_Tax'),false);
       system.assertEquals(actionTestMap.get('Refund_Credit'),false);
       system.assertEquals(actionTestMap.get('Unfinalize'),true);
       system.assertEquals(actionTestMap.get('Void'),false); 
       system.assertEquals(actionTestMap.get('Write_Off'),true);      

       
    }
    
    static testMethod void CustomerInvoiceManageExtTest_testNonManualCIActions() {
        
        String initialTestMapStr = CustomerInvoiceService.populateCIActions(null); 
        System.debug(logginglevel.error,'initialTestMapStr--->'+initialTestMapStr);
       
        Map<String,Object> initialActionTestMap = (Map<String,Object>) JSON.deserializeUntyped(initialTestMapStr);  
        System.debug(logginglevel.error, 'initialTestMap--->'+initialActionTestMap +' '+ initialActionTestMap.size());
       
        system.assert(initialActionTestMap.isEmpty() && initialActionTestMap.size()==0,'Action Avaialble Already');// all the actions are set to false  
        
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'NonManual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        insert CustomerInvoice;
    
        CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
        system.assertEquals(ext.pgError, false);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
        List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
        Customer_invoice_line__C cil= new Customer_invoice_line__C(product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1);
        CustomerInvoiceManageExt.SHILineWrapper sw= new CustomerInvoiceManageExt.SHILineWrapper(cil);
        List<CustomerInvoiceManageExt.SHILineWrapper> newList = new List<CustomerInvoiceManageExt.SHILineWrapper>();
        sw.shiline=cil;
        sw.c = new Customer_invoice__C(id=CustomerInvoice.id);
        newList.add(sw);
        
        //CustomerInvoice.Finalized__c=true;
                    
        JSONREsult jr= CustomerInvoiceManageExt.saveAction(CustomerInvoice,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),newList,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),1,jr);
      
       Customer_invoice__c cinv = (Customer_invoice__c) CustomerInvoiceManageExt.getInvoice(CustomerInvoice.Id,false).records[0];
       List<CustomerInvoiceManageExt.SHILineWrapper> ciLinesWrap=(List<CustomerInvoiceManageExt.SHILineWrapper>) CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.Id,false).records;
       system.assertEquals(ciLinesWrap.size(), 1);
       system.assertEquals(cinv.Status__c, 'Open'); 
       
       
       String ciTestMapStr = CustomerInvoiceService.populateCIActions(cinv.id); 
       System.debug(logginglevel.error,'ciTestMapStr--->'+ciTestMapStr);
       
       Map<String,Object> ciActionTestMap = (Map<String,Object>) JSON.deserializeUntyped(ciTestMapStr);  
       System.debug(logginglevel.error, 'initialTestMap--->'+ciActionTestMap);
       
       system.assertEquals(ciActionTestMap.get('Clone'),false);
       system.assertEquals(ciActionTestMap.get('Cancel'),true);
       system.assertEquals(ciActionTestMap.get('Get_Tax'),true);
       system.assertEquals(ciActionTestMap.get('Refund_Credit'),false);
       system.assertEquals(ciActionTestMap.get('Unfinalize'),false);
       system.assertEquals(ciActionTestMap.get('Void'),false); 
       system.assertEquals(ciActionTestMap.get('Write_Off'),false); 
       
       cinv.Finalized__c=true;
       update cinv;
       
       system.assertEquals(cinv.Finalized__c, true);
        
       String actionTestMapStr = CustomerInvoiceService.populateCIActions(cinv.id); 
       System.debug(logginglevel.error,'actionTestMapStr--->'+actionTestMapStr);
       
       Map<String,Object> actionTestMap = (Map<String,Object>) JSON.deserializeUntyped(actionTestMapStr);  
       System.debug(logginglevel.error, 'actionTestMap--->'+actionTestMap);
       
       system.assertEquals(actionTestMap.get('Clone'),false);
       system.assertEquals(actionTestMap.get('Cancel'),true);
       system.assertEquals(actionTestMap.get('Get_Tax'),false);
       system.assertEquals(actionTestMap.get('Refund_Credit'),false);
       system.assertEquals(actionTestMap.get('Unfinalize'),false);
       system.assertEquals(actionTestMap.get('Void'),false); 
       system.assertEquals(actionTestMap.get('Write_Off'),true);        

       
    }
    
    static testMethod void CustomerInvoiceManageExtTest_updateLinesAndDeleteSegments() {
        
       // insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
    	TestFuelQuery fuel = new TestFuelQuery();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
        //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
        Accounting_Default__c ad = new Accounting_Default__c(GL_Account__c = fuel.cashGL.Id,Intercompany__c =fuel.company.Id);
        insert ad;
        Customer_invoice_line__C cil= new Customer_invoice_line__C(product__c= fuel.product_Misc.Id , Line_Type__c ='Standard',unit_price__c=1,quantity_shipped__c=1, Accounting_Segment__c = ad.Id, Customer_Invoice__c = CustomerInvoice.Id);
        insert cil;
       
        CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
        system.assertEquals(ext.pgError, false);
        system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),1);
        
        List<String> datefields = new List<String>{'Transaction_date__c','Date_Invoiced__c'};
       
        CustomerInvoiceManageExt.SHILineWrapper sw= new CustomerInvoiceManageExt.SHILineWrapper(cil);
        List<CustomerInvoiceManageExt.SHILineWrapper> newList = new List<CustomerInvoiceManageExt.SHILineWrapper>();
        sw.shiline=cil;
        sw.c = new Customer_invoice__C(id=CustomerInvoice.id);
        sw.segments = new Accounting_Default__c(Id = ad.Id, GL_Account__c = null,Intercompany__c = null);
        newList.add(sw);
        
        test.startTest();
        	JSONREsult jr=   CustomerInvoiceManageExt.saveAction(CustomerInvoice,datefields,(new List<CustomerInvoiceManageExt.SHILineWrapper>()),newList,( new List<CustomerInvoiceManageExt.SHILineWrapper>()), datefields);
        	system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),1,jr);
        	cil = [Select Id, Accounting_Segment__c, Accounting_Segment__r.Intercompany__c, Accounting_Segment__r.Company__c, Accounting_Segment__r.GL_Account__c from Customer_Invoice_Line__c where Id = :cil.Id];
        	system.assertEquals(null,cil.Accounting_Segment__r);
        	
        test.stopTest();
    	
    }
   static testMethod void CustomerInvoiceManageExtTest_getCustomerInfo() {
         
        
         TestFuelQuery fuel = new TestFuelQuery();
         Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
        CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
         CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
        CustomerInvoice.Currency__c = fuel.company.Default_Transaction_Currency__c;
         //CustomerInvoice.Finalized__c =true;
        insert CustomerInvoice;
         
         CustomerInvoiceManageExt ext = new CustomerInvoiceManageExt(new ApexPages.standardController(CustomerInvoice));
         system.assertEquals(ext.pgError, false);
         system.assertEquals(CustomerInvoiceManageExt.getCustomerInvoiceLines(CustomerInvoice.id,false).records.size(),0);
 
        test.startTest();
            JSONREsult jr=   CustomerInvoiceManageExt.getCustomerInfo((string) fuel.customerBillTo.Id);
             system.assertNotEquals(null,jr);
         test.stopTest();
        
    }
  
  
  /********************************************************************************************
  * BEGIN CustomerInvoiceAccountingTest Tests
  *********************************************************************************************/
  
  static testMethod void CustomerInvoiceAccountingTest_testCIHeaderFinalize(){
    
    TestFuelQuery fuel = new TestFuelQuery();
      List<Period__c> periods = fuel.periodList;
      
      Customer_Invoice__c custInv1 = new Customer_Invoice__c();
      custInv1.Invoice_Type__c = 'Ship Invoice';
      custInv1.Date_Invoiced__c = System.today();
      custInv1.Sold_To_Customer__c = fuel.customerSoldTo.id;
      custInv1.Bill_To_Customer__c = fuel.customerbillto.id;
      custInv1.Subtotal__c = 0;
      custInv1.Sales_Order__c = fuel.salesOrder.id;
      custInv1.transaction_date__c = system.now();
      custInv1.Currency__c = fuel.company.Default_Transaction_Currency__c;
      
      Test.startTest();
      boolean sawException = false;
      string exMsg = null;
      
      try{
        custInv1.finalized__c = true;
        custInv1.company__c = null;
        insert custInv1;
      }catch(Exception ex){
        exMsg = ex.getMessage();
        sawException = true;
      }
      system.assertEquals(true, sawException); // company can not be null
      
      exMsg = null;
      sawException = false;
      custInv1.Company__c = fuel.company.id;
      custInv1.Transaction_date__c = null;
      custInv1.finalized__c = true;
      try{
        update custInv1;
      }catch(Exception ex){
        exMsg = ex.getMessage();
        sawException = true;
      }
      system.assertEquals(true, sawException);// transaction date can not be null
      
      exMsg = null;
      sawException = false;
      custInv1.Currency__c = null;
      custInv1.Transaction_date__c = system.now();
      custInv1.finalized__c = true;
      try{
        update custInv1;
      }catch(Exception ex){
        exMsg = ex.getMessage();
        sawException = true;
      }
      system.assertEquals(true, sawException); // transaction currency can not be null
      
      exMsg = null;
      sawException = false;
      custInv1.Currency__c = fuel.company.Default_Transaction_Currency__c;
      custInv1.finalized__c = true;
      try{
        update custInv1;
      }catch(Exception ex){
        exMsg = ex.getMessage();
        sawException = true;
      }
      // shipment without lines can not be finalized
      system.assert(sawException, 'We are expecting to see an exception for attempting to finalized a doc without lines' + exMsg );
      Test.stopTest();
  }         
  
  
  static testMethod void CustomerInvoiceAccountingTest_testCRLineUpdate(){
    TestFuelQuery fuel = new TestFuelQuery();
    //Company__c company = fuel.company;
      List<Period__c> periods = fuel.periodList;
    
    Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = fuel.company.id;
    custInvoice1.Bill_To_Customer__c = fuel.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = fuel.customerSoldTo.id;
        custInvoice1.Sales_Order__c = fuel.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = fuel.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = fuel.company.id;
        ciLine1.Sales_Order_Line__c = fuel.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = fuel.salesOrder.id;
        ciLine1.Product__c = fuel.product.id ; 
        ciLine1.Discount_Percent__c = fuel.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
     
      custInvoice1.Finalized__c = true;
      update  custInvoice1;
      
      Test.startTest();
      String exMsg = null;
      boolean sawException = false;
      try{
        ciLine1.product__c = fuel.product2.id; // product field exists in finalize field set which is not meant to be modified after doc is finalized
        update ciLine1; 
      }catch(Exception ex){
        exMsg = ex.getMessage();
        sawException = true;
      }
      Test.stopTest();
      
      system.assert(sawException, 'We are expecting to see an exception for attempting to edit a line of a finalized doc ' + exMsg);
  }
  
  static testMethod void CustomerInvoiceAccountingTest_testCILineInsert(){
    TestFuelQuery fuel = new TestFuelQuery();
    //company__c company = fuel.company;
      List<Period__c> periods = fuel.periodList;

      Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = fuel.company.id;
    custInvoice1.Bill_To_Customer__c = fuel.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = fuel.customerSoldTo.id;
        custInvoice1.Sales_Order__c = fuel.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = fuel.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = fuel.company.id;
        ciLine1.Sales_Order_Line__c = fuel.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = fuel.salesOrder.id;
        ciLine1.Product__c = fuel.product.id ; 
        ciLine1.Discount_Percent__c = fuel.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
     
      custInvoice1.Finalized__c = true;
      update  custInvoice1;
      
      Customer_Invoice_Line__c ciLine2 = new Customer_Invoice_Line__c();
        ciLine2.Quantity_Shipped__c = 5;
        ciLine2.Company__c = fuel.company.id;
        ciLine2.Sales_Order_Line__c = fuel.salesOrderLine.id;
        ciLine2.Unit_Price__c = 10;
        ciLine2.Sales_Order__c = fuel.salesOrder.id;
        ciLine2.Product__c = fuel.product.id ; 
        ciLine2.Discount_Percent__c = fuel.salesOrderLine2.Discount_Percent__c;
        ciLine2.Customer_Invoice__c = custInvoice1.Id; 
    
      Test.startTest();
      String exMsg = null;
      boolean sawException = false;
      try{
        insert ciLine2; // new line can not be added to source doc once it is finalized
      }catch(Exception ex){
        exMsg = ex.getMessage();
        sawException = true;
      }
      
      Test.stopTest();
      
      system.assert(sawException, 'We are expecting to see an exception for attempting to add a line to a finalized doc ' + exMsg);
  }
  
  static testMethod void CustomerInvoiceAccountingTest_testCILineDelete(){
    TestFuelQuery fuel = new TestFuelQuery();
    //company__c company = fuel.company;
      List<Period__c> periods = fuel.periodList;
    
      Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = fuel.company.id;
    custInvoice1.Bill_To_Customer__c = fuel.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = fuel.customerSoldTo.id;
        custInvoice1.Sales_Order__c = fuel.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = fuel.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = fuel.company.id;
        ciLine1.Sales_Order_Line__c = fuel.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = fuel.salesOrder.id;
        ciLine1.Product__c = fuel.product.id ; 
        ciLine1.Discount_Percent__c = fuel.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
     
      custInvoice1.Finalized__c = true;
      update  custInvoice1;
            
      Test.startTest();
      String exMsg = null;
      boolean sawException = false;
      try{
        delete ciLine1; //  line can not be deleted from a source doc once it is finalized
      }catch(Exception ex){
        exMsg = ex.getMessage();
        sawException = true;
      }
      Test.stopTest();
      
      system.assert(sawException, 'We are expecting to see an exception for attempting to delete a line from a finalized doc ' + exMsg);
  }
  
  static testMethod void CustomerInvoiceAccountingTest_testCILineUndelete(){
    TestFuelQuery fuel = new TestFuelQuery();
      List<Period__c> periods = fuel.periodList;

      Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = fuel.company.id;
    custInvoice1.Bill_To_Customer__c = fuel.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = fuel.customerSoldTo.id;
        custInvoice1.Sales_Order__c = fuel.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = fuel.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        List<Customer_Invoice_Line__c> ciLineList = new List<Customer_Invoice_Line__c>();
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = fuel.company.id;
        ciLine1.Sales_Order_Line__c = fuel.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = fuel.salesOrder.id;
        ciLine1.Product__c = fuel.product.id ; 
        ciLine1.Discount_Percent__c = fuel.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
        ciLineList.add(ciLine1);
        
        Customer_Invoice_Line__c ciLine2 = new Customer_Invoice_Line__c();
        ciLine2.Quantity_Shipped__c = 5;
        ciLine2.Company__c = fuel.company.id;
        ciLine2.Sales_Order_Line__c = fuel.salesOrderLine2.id;
        ciLine2.Unit_Price__c = 10;
        ciLine2.Sales_Order__c = fuel.salesOrder.id;
        ciLine2.Product__c = fuel.product.id ; 
        ciLine2.Discount_Percent__c = fuel.salesOrderLine2.Discount_Percent__c;
        ciLine2.Customer_Invoice__c = custInvoice1.Id;
        ciLineList.add(ciLine2);
        
        insert ciLineList;        
     
    delete ciLine1;
    
    custInvoice1.finalized__c = true;
      update custInvoice1;
      
      Test.startTest();
      String exMsg = null;
      boolean sawException = false;
      try{
        undelete ciLine2; 
      }catch(Exception ex){
        exMsg = ex.getMessage();
        sawException = true;
      }
      Test.stopTest();
  
      system.assert(sawException, 'We are expecting to see an exception for attempting to undelete a line for a finalized doc ' + exMsg);
  }
  
  
  
  //This test is being disabled whilst RFX is being re-designed
  
  static testMethod void CustomerInvoiceAccountingTest_testRFX(){
    
    /*TestFuelQuery fuel = new TestFuelQuery();
    List<Period__c> periodList = fuel.periodList;
    Testfuel.Accounting accting = new Testfuel.Accounting(fuel.company.Id);
    accting.ReceivablesGL.FX_Type__c = 'Monetary Non-cash';
    update accting.ReceivablesGL;
    
    for(Accounting_Rule__c ar : accting.rules){
      
      if(ar.object_name__c == 'Customer_Invoice__c'
          && ar.gl_account__c == accting.receivablesGL.Id){
        ar.fx_flow__c = 'In';
      }else if(ar.object_name__c == 'Customer_Receipt__c'
          && ar.gl_account__c == accting.receivablesGL.Id){
        ar.fx_flow__c = 'Out';
        ar.fx_date_path__c = 'Customer_Invoice__r.Transaction_Date__c';
      }
      
    }
    
    update accting.rules;
    Datetime baseDT = system.now();
    
    Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = fuel.company.id;
    custInvoice1.Bill_To_Customer__c = fuel.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = fuel.customerSoldTo.id;
        custInvoice1.Sales_Order__c = fuel.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = baseDT.addHours(-6);
        custInvoice1.transaction_date__c = baseDT.addHours(-6);
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = fuel.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Manual';
        
        Customer_Invoice__c custInvoice2 = new Customer_Invoice__c();
        custInvoice2.Company__c = fuel.company.id;
    custInvoice2.Bill_To_Customer__c = fuel.customerbillto.id;
        custInvoice2.Sold_To_Customer__c = fuel.customerSoldTo.id;
        custInvoice2.Sales_Order__c = fuel.salesOrder.Id;
        custInvoice2.Date_Invoiced__c = baseDT.addHours(-1);
        custInvoice2.transaction_date__c = baseDT.addHours(-1);
        custInvoice2.status__c = 'Open';
        custInvoice2.Currency__c = fuel.company.Default_Transaction_Currency__c;
        custInvoice2.Invoice_Type__c = 'Ship Invoice';
        
        insert  new List<Customer_Invoice__c>{custInvoice1, custInvoice2};
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = fuel.company.id;
        ciLine1.Sales_Order_Line__c = fuel.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = fuel.salesOrder.id;
        ciLine1.Product__c = fuel.product.id ; 
        ciLine1.Taxable__c = fuel.salesOrderLine.Taxable__c;
        ciLine1.Discount_Percent__c = fuel.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
        
        Customer_Invoice_Line__c ciLine2 = new Customer_Invoice_Line__c();
        ciLine2.Quantity_Shipped__c = 5;
        ciLine2.Company__c = fuel.company.id;
        ciLine2.Sales_Order_Line__c = fuel.salesOrderLine.id;
        ciLine2.Unit_Price__c = 10;
        ciLine2.Sales_Order__c = fuel.salesOrder.id;
        ciLine2.Product__c = fuel.product.id ; 
        ciLine2.Taxable__c = fuel.salesOrderLine.Taxable__c;
        ciLine2.Discount_Percent__c = fuel.salesOrderLine.Discount_Percent__c;
        ciLine2.Customer_Invoice__c = custInvoice2.Id; 
        
        
        insert new List<Customer_Invoice_Line__c>{ciLine1, ciLine2};   
        
        custInvoice1.Finalized__c = true;
        custInvoice2.Finalized__c = true;
        update new List<Customer_Invoice__c>{custInvoice1, custInvoice2};
        
        Exchange_Rate__c exchangeRate1, exchangeRate2, exchangeRate3;
        exchangeRate1= new Exchange_Rate__c();
        exchangeRate1.Active__c = true;
        exchangeRate1.From_Currency__c = fuel.company.Default_Transaction_Currency__c;
        exchangeRate1.To_Currency__c = TestFuel.currencySGD.id;
        exchangeRate1.Daily_Monthly__c = 'Daily';
        exchangeRate1.Multiplier_Exchange_Rate__c = 1.250000;
        exchangeRate1.rate_start_datetime__c = baseDT.addHours(-12);
        exchangeRate1.rate_end_datetime__c = baseDT.addHours(-3); 
        
        exchangeRate2= new Exchange_Rate__c();
        exchangeRate2.Active__c = true;
        exchangeRate2.From_Currency__c = fuel.company.Default_Transaction_Currency__c;
        exchangeRate2.To_Currency__c = TestFuel.currencySGD.id;
        exchangeRate2.Daily_Monthly__c = 'Daily';
        exchangeRate2.Multiplier_Exchange_Rate__c = 1.290000;
        exchangeRate2.rate_start_datetime__c = baseDT.addHours(-3);
        exchangeRate2.rate_end_datetime__c = baseDT.addHours(3); 
        
        exchangeRate3= new Exchange_Rate__c();
        exchangeRate3.Active__c = true;
        exchangeRate3.From_Currency__c = fuel.company.Default_Transaction_Currency__c;
        exchangeRate3.To_Currency__c = TestFuel.currencySGD.id;
        exchangeRate3.Daily_Monthly__c = 'Monthly';
        exchangeRate3.Multiplier_Exchange_Rate__c = 1.270000;
        exchangeRate3.rate_start_datetime__c = baseDT.addDays(-12);
        exchangeRate3.rate_end_datetime__c = baseDT.addDays(3);
        
        insert new List<Exchange_Rate__c>{exchangeRate1, exchangeRate2, exchangeRate3};
        
        Customer_Receipt__c cr1 = new Customer_Receipt__c();
        cr1.company__c = fuel.company.Id;
        cr1.customer__c = fuel.customerbillto.id;
        cr1.Date_Received__c = baseDT.addHours(-1);
        cr1.Transaction_Date__c = baseDT.addHours(-1);
        cr1.Type__c = 'Receipt';
        cr1.Currency__c = fuel.company.Default_Transaction_Currency__c;
        
        insert cr1;
        
        list <Customer_Receipt_Line__c> crlines = new List<Customer_Receipt_Line__c>();
        Customer_Receipt_Line__c crl1 = new Customer_Receipt_Line__c();
        crl1.Customer_Receipt__c = cr1.Id;
        crl1.amount__c = 50;
        crl1.type__c = PaymentService.TYPE_PAYMENT;
        crl1.Customer_Invoice__c = custInvoice1.Id;
    crlines.add(crl1);
           
        Customer_Receipt_Line__c genDeduction = new Customer_Receipt_Line__c();
      genDeduction.Amount__c = 50;
      genDeduction.Type__c = PaymentService.TYPE_GEN_DED;
      genDeduction.Customer_Receipt__c =cr1.Id;
    crlines.add(genDeduction);
        
        insert crlines;
        cr1.finalized__c = true;
        
        test.startTest();
        update cr1;
        
        CustomerReceiptAccounting cra = new CustomerReceiptAccounting();
        cra.execute(crlines);
        
        List<Accounting_Entry_Line__c> aelCR1s = [SELECT Id, name, gl_account__c, gl_account__r.fx_type__c, 
                                fx_flow__c, fx_date__c, comp_functional_conversion_rate__c,
                                COMP_Functional_Currency_Amount_CR__c,
                                COMP_Functional_Currency_Amount_DR__c,
                                amount_dr__c, amount_cr__c,
                                COMP_Transaction_Currency_Amount_CR__c,
                                COMP_Transaction_Currency_Amount_DR__c, 
                                accounting_rule__c, subtransaction_type__c, line_type__c,
                                error_message__c
                              FROM Accounting_Entry_Line__c
                              WHERE Accounting_Entry__r.Customer_Receipt__c = :cr1.Id];
        
        boolean sawAR = false;
        boolean sawRFX = false;
        
        for(Accounting_Entry_Line__c ael : aelCR1s){
          if(ael.gl_account__c == accting.receivablesGL.Id){
            sawAR = true;
            system.assertEquals('Out', ael.fx_flow__c, 'This should represent the outbound flow of RFX');
            system.assertEquals(custInvoice1.Transaction_Date__c, ael.fx_date__c, 'This should represent the outbound date of RFX from the upstream source doc');
            system.assertEquals(exchangeRate1.Multiplier_Exchange_Rate__c, ael.comp_functional_conversion_rate__c, 'The conversion rate should match the customer invoice transaction date conversion rate');
          }
          if(ael.gl_account__r.fx_type__c == 'RFX'){
            sawRFX = true;
            system.assertEquals((50*exchangeRate3.Multiplier_Exchange_Rate__c)-(50*exchangeRate1.Multiplier_Exchange_Rate__c), ael.COMP_Functional_Currency_Amount_CR__c, ael + ' - ' + aelCR1s);
          }
        }
        
        test.stopTest();
        
        system.assert(sawAR, 'We should have seen AR for this Receipt');
        system.assert(sawRFX, 'We should have seen RFX for this Receipt');
        */  
  }
  


  static testMethod void CustomerInvoiceAccountingTest_testReverseRules(){
    TestFuelQuery fuel = new TestFuelQuery();
    //Company__c company = fuel.company;
      List<Period__c> periods = fuel.periodList;
    
    Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = fuel.company.id;
    custInvoice1.Bill_To_Customer__c = fuel.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = fuel.customerSoldTo.id;
        custInvoice1.Sales_Order__c = fuel.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = system.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = fuel.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Adjustment';
        
        Customer_Invoice__c custInvoice2 = new Customer_Invoice__c();
        custInvoice2.Company__c = fuel.company.id;
    custInvoice2.Bill_To_Customer__c = fuel.customerbillto.id;
        custInvoice2.Sold_To_Customer__c = fuel.customerSoldTo.id;
        custInvoice2.Sales_Order__c = fuel.salesOrder.Id;
        custInvoice2.Date_Invoiced__c = system.now();
        custInvoice2.transaction_date__c = system.now();
        custInvoice2.status__c = 'Open';
        custInvoice2.Currency__c = fuel.company.Default_Transaction_Currency__c;
        custInvoice2.Invoice_Type__c = 'Adjustment';
        
        
        insert new List<Customer_Invoice__c>{custInvoice1, custInvoice2};
        
         List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = fuel.company.id;
        ciLine1.Sales_Order_Line__c = fuel.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = fuel.salesOrder.id;
        ciLine1.Product__c = fuel.product.id ; 
        ciLine1.Discount_Percent__c = fuel.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
        cils.add(ciLine1);
        
        Customer_Invoice_Line__c ciLine2 = new Customer_Invoice_Line__c();
        ciLine2.Quantity_Shipped__c = -5;
        ciLine2.Company__c = fuel.company.id;
        ciLine2.Sales_Order_Line__c = fuel.salesOrderLine.id;
        ciLine2.Unit_Price__c = 10;
        ciLine2.Sales_Order__c = fuel.salesOrder.id;
        ciLine2.Product__c = fuel.product.id ; 
        ciLine2.Discount_Percent__c = fuel.salesOrderLine.Discount_Percent__c;
        ciLine2.Customer_Invoice__c = custInvoice2.Id; 
        cils.add(ciLine2);
            
        insert cils;        
        
        Test.startTest();
     
      custInvoice1.Finalized__c = true;
      custInvoice2.Finalized__c = true;
      update new List<Customer_Invoice__c>{custInvoice1, custInvoice2};
      
      AccountingService asv = new CustomerInvoiceAccounting();
      asv.execute(cils);
      
      Test.stopTest();
  }
  
  
  /********************************************************************************************
  * BEGIN PurchaseOrderReceiveExtTest Tests
  *********************************************************************************************/        
       
       static testMethod void PurchaseOrderReceiveExtV2Test_testPurchaseOrderReceive() {
        
            TestFuelQuery fuel = new TestFuelQuery();
            ApexPages.StandardController con; 
            PurchaseOrderReceiveExtV2 PORExt;
            
            List<Period__c> periodList = fuel.periodList;
            List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
            ///List<Stock_Movement_Rule__c> stockMovementRuleList = data.stockMovementRuleList;
                
            fuel.location3.Bin_Tracked__c = true;
            fuel.location3.Mixed_Bins_Allowed__c = true; 
            update fuel.location3;
            
            Item_Cross_Reference__c iref = new Item_Cross_Reference__c(Item__c =fuel.itemList[3].Id, Active__c = true, 
                                            Approval_Status__c = 'Approved', Consigned__c = true, Supplier__c = fuel.supplier.Id);
            insert iref;
            
            fuel.itemList[3].Item_Attribute__c = fuel.itemAttrObj.id;
            fuel.itemList[2].Item_Attribute__c = fuel.itemAttrObj2.id;
            update new list<Item__c>{fuel.itemList[2],fuel.itemList[3]};
            Purchase_Order__c po = fuel.purchaseOrder;
            
            Test.startTest();
            
            Purchase_Order_Line__c objPODetail4 = new Purchase_Order_Line__c();
            objPODetail4.Purchase_Order__c = po.Id;
            objPODetail4.Consigned__c = true;
            objPODetail4.Order_Quantity__c = 25;        
            objPODetail4.Unit_Price__c = 1.29;
            objPODetail4.Item__c = fuel.itemList[3].Id;
            objPODetail4.Description__c = fuel.itemList[3].Description__c;
            objPODetail4.Purchase_UOM__c = fuel.itemList[3].Purchasing_UOM__c;
            objPODetail4.Packaging_UOM__c = fuel.itemList[3].Purchasing_UOM__c;
            objPODetail4.Company__c = fuel.company.id;
            objPODetail4.Need_Date__c = system.today() + 17;
            objPODetail4.Delivery_Facility__c = fuel.facility2.id;
            objPODetail4.Delivery_Location__c = fuel.location2.ID;
            objPODetail4.Supplier__c = fuel.supplier.Id;
            
            insert objPODetail4;
            
            po.Approval_Status__c = 'Approved';
            update po;
            
            con = new ApexPages.StandardController( po );
            PORExt = new PurchaseOrderReceiveExtV2(con);
            system.assert( PORExt != null );
            
            list<Id> locList = (list<Id>)JSON.deserialize(String.valueOf(fuel.stockMovementRule1.Location_List__c), list<Id>.Class);
            system.assert( locList.size() > 0 );
            
            JsonResult result = PurchaseOrderReceiveExtV2.getList( po.id );
            system.assert(result.success == true,result);
            system.assert( result.records.size() == 2, result ); // number of lines on the screen
            
            list<receivingWrapper> polWrapperList = ( list<receivingWrapper> )result.records;
            
            system.assert( polWrapperList.size() == 2 );
            
            system.assert( polWrapperList[0].serialWrapperList.size() == 1 );
            system.assert( polWrapperList[1].serialWrapperList.size() == 1 );
            
            for( Integer i = 0 ; i< polWrapperList.size() ; i ++ ){
                
                system.assertEquals( locList[0], polWrapperList[i].serialWrapperList[0].skid.Location__c, polWrapperList[i].serialWrapperList[0].skid);
                
                if( polWrapperList[i].rl.get('Consigned__c') == true){
                    system.assert( polWrapperList[i].trackedAttributes.size() == 5 ); // lot, expiration date, bin, consigned owner, packaging uom
                    system.assert( polWrapperList[i].serialWrapperList[0].skid.consigned_Owner__c == po.Supplier__c);
                    system.assertEquals(0,polWrapperList[i].serialWrapperList[0].serialList.size(),polWrapperList[i].serialWrapperList[0]);
                }
                else{
                    system.assert( polWrapperList[i].trackedAttributes.size() == 4, polWrapperList[i].rl.getSObject('Item__r').getSObject('Item_Attribute__r')); // lot, expiration date, bin, packaging uom
                    system.assertEquals(1,polWrapperList[i].serialWrapperList[0].serialList.size(), polWrapperList[i].rl.getSObject('Item__r'));
                    
                    Serial__c ser = polWrapperList[i].serialWrapperList[0].serialList[0];
                    ser.Name = 'ser0';
                    
                    for(Integer j=1; j < (Decimal)polWrapperList[i].rl.get('Order_Quantity__c'); j++ ){
                        Serial__c serClone = ser.Clone(false,true);
                        serClone.Name = 'ser'+String.valueOf(j);
                        polWrapperList[i].serialWrapperList[0].serialList.add(serClone);
                    }    
                }
                polWrapperList[i].serialWrapperList[0].skid.Quantity__c = (Decimal)polWrapperList[i].rl.get('Order_Quantity__c'); //receive the entire quantity 
                polWrapperList[i].serialWrapperList[0].skid.Lot_Number__c = '1234bc'; // lowercase
                polWrapperList[i].serialWrapperList[0].skid.Bin__c = fuel.bin.id;
                polWrapperList[i].serialWrapperList[0].skid.expiration_date__c = system.today()+30;  
                
            }
            
            // Reset the flag so that the trigger runs again.
          KSE.flagvalue = false;
          
            result = PurchaseOrderReceiveExtV2.receivePurchaseOrders( polWrapperList);
            system.assertEquals(true, result.success, result);
            
            Purchase_Order__c poAfterReceive = [ select id, Name, Status__c, Approval_Status__c, Supplier__c,
                                                ( select id, Name, Status__c, Consigned__c, Quantity_Received__c,Order_Quantity__c
                                                from Purchase_Order_Lines__r ), 
                                                ( select id, Name, Status__c, Quantity_Received__c, Quantity_Consumed__c,Purchase_Order_Line__r.Order_Quantity__c,
                                                Quantity_To_Consume__c, Uninvoiced_Quantity__c, Receiving_Document__c, Line_Type__c , Putaway_Location__c
                                                from Receipt_Lines__r)
                                                from Purchase_Order__c where Id =:po.id];
                                                    
           system.assert( poAfterReceive.Status__c == 'Closed', poAfterReceive.Purchase_Order_Lines__r+','+result);     
           
           for( Purchase_Order_Line__c pol : poAfterReceive.Purchase_Order_Lines__r ){
            
                if( pol.Consigned__c ){
                    
                    system.assertEquals( pol.Quantity_Received__c, pol.Order_Quantity__c, pol);
                    //system.assertEquals( pol.Quantity_Uninvoiced__c, 0, pol );
                    
                }
                else{
                    system.assertEquals( pol.Quantity_Received__c, pol.Order_Quantity__c, pol);
                    //system.assertEquals( pol.Quantity_Uninvoiced__c, pol.Order_Quantity__c, pol );
                    
                }
                system.assert( pol.Status__c == 'Closed');
           }
           
           for( Receipt_Line__c rl : poAfterReceive.Receipt_Lines__r ){
            
                if( rl.Line_Type__c == 'Consigned' ){
                    
                    system.assert( rl.Quantity_Received__c == rl.Purchase_Order_Line__r.Order_Quantity__c );
                    system.assert( rl.Uninvoiced_Quantity__c == null );
                }
                else{
                    system.assertEquals( rl.Quantity_Received__c , rl.Purchase_Order_Line__r.Order_Quantity__c );
                    system.assertEquals( rl.Uninvoiced_Quantity__c , rl.Purchase_Order_Line__r.Order_Quantity__c );
                }
                
                
                //PTP-89 Verify if the putaway is obtained from Stock Movement rules and saved on the Receipt Line
                system.assertEquals( rl.putaway_location__c, locList[0] );  
                system.assertEquals( rl.putaway_location__c, fuel.location3.id);
           }                                
               
            list<Lot__c> lots = [ select id, Name, Supplier__c, Company__c, Item__c from Lot__c ];
            system.assertEquals(lots.size() , 2, lots); // new lots has been created.
            system.assertEquals(lots[0].Name , '1234BC');// lot is stored in uppercase.   
                
            Test.stopTest();
            
            system.assertEquals( [ select id, Name from Serial__c ].size(), 10 );
            system.assertEquals( [ select id, Name from Serial_Transaction__c ].size(), 10 );
            
            result = PurchaseOrderReceiveExtV2.receive( polWrapperList, new list<String>(),new list<String>());
            PORExt.cancel();
        }
        
        static testMethod void PurchaseOrderReceiveExtV2_testPurchaseOrderReceiveErrors() {
        
            TestFuelQuery fuel = new TestFuelQuery();
            ApexPages.StandardController con; 
            PurchaseOrderReceiveExtV2 PORExt;
            
            fuel.Company.Serial_Control__c = 'At receipt and all processes';
            update fuel.company;
            
            List<Period__c> periodList = fuel.periodList;
            List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
            
            fuel.location3.Bin_Tracked__c = true;
            fuel.location3.Mixed_Bins_Allowed__c = true;
            update fuel.location3;
            
            Test.startTest();
            
            fuel.itemAttrObj.Minimum_Shelf_Life_In_Days__c = true;
            update fuel.itemAttrObj;
            
            Item_Cross_Reference__c icr = new Item_Cross_Reference__c( Item__c = fuel.itemList[2].id, Minimum_Shelf_Life_In_Days__c = 40, 
                                            Active__c = true , Approval_Status__c = 'Approved', Supplier__c = fuel.supplier.Id );
            Item_Cross_Reference__c icr2 = new Item_Cross_Reference__c(Item__c =fuel.itemList[3].Id, Active__c = true, 
                                            Approval_Status__c = 'Approved', Consigned__c = true, Supplier__c = fuel.supplier.Id);
            insert new list<Item_Cross_Reference__c>{icr,icr2};
                
            fuel.itemList[3].Item_Attribute__c = fuel.itemAttrObj.id;
            fuel.itemList[2].Item_Attribute__c = fuel.itemAttrObj2.id;
            update new list<Item__c>{fuel.itemList[2],fuel.itemList[3]};
            
            Purchase_Order__c po = fuel.purchaseOrder;
            
            Purchase_Order_Line__c objPODetail4 = new Purchase_Order_Line__c();
            objPODetail4.Purchase_Order__c = po.Id;
            objPODetail4.Consigned__c = true;
            objPODetail4.Order_Quantity__c = 25;        
            objPODetail4.Unit_Price__c = 1.29;
            objPODetail4.Item__c = fuel.itemList[3].Id;
            objPODetail4.Description__c = fuel.itemList[3].Description__c;
            objPODetail4.Purchase_UOM__c = fuel.itemList[3].Purchasing_UOM__c;
            objPODetail4.Packaging_UOM__c = fuel.itemList[3].Purchasing_UOM__c;
            objPODetail4.Company__c = fuel.company.id;
            objPODetail4.Need_Date__c = system.today() + 17;
            objPODetail4.Delivery_Facility__c = fuel.facility2.id;
            objPODetail4.Delivery_Location__c = fuel.location2.ID;
            objPODetail4.Supplier__c = fuel.supplier.Id;
            
            insert objPODetail4;
            
            po.Approval_Status__c = 'Approved';
            update po;
    
            con = new ApexPages.StandardController( po );
            PORExt = new PurchaseOrderReceiveExtV2(con);
            system.assert( PORExt != null );
            
            JsonResult result = PurchaseOrderReceiveExtV2.getList( po.id );
            
            system.assertEquals(result.success, true, result);
            system.assert( result.records.size() == 2 ); // number of lines on the screen
            
            list<ReceivingWrapper> polWrapperList = ( list<ReceivingWrapper> )result.records;
            
            system.assert( polWrapperList.size() == 2 );
            
            system.assert( polWrapperList[0].serialWrapperList.size() == 1 );
            
            for( Integer i = 0 ; i< polWrapperList.size() ; i ++ ){
                if( polWrapperList[i].rl.get('Consigned__c') == true){
                    system.assertEquals( polWrapperList[i].trackedAttributes.size(), 5 ); // lot, expiration date, bin, consigned owner,packaging uom
                    system.assert( polWrapperList[i].serialWrapperList[0].skid.consigned_Owner__c == po.Supplier__c);
    
                }
                else{
                    system.assertEquals( polWrapperList[i].trackedAttributes.size(), 4 ); // lot, expiration date, bin,packaging uom
                    Serial__c ser = polWrapperList[i].serialWrapperList[0].serialList[0];
                    ser.Name = 'ser0';
                    
                    for(Integer j=1; j < (Decimal)polWrapperList[i].rl.get('Order_Quantity__c'); j++ ){
                        Serial__c serClone = ser.Clone(false,true);
                        serClone.Name = 'ser'+String.valueOf(j);
                        polWrapperList[i].serialWrapperList[0].serialList.add(serClone);
                    }   
                }
                polWrapperList[i].serialWrapperList[0].skid.Quantity__c = (Decimal)polWrapperList[i].rl.get('Order_Quantity__c'); //receive the entire quantity 
                polWrapperList[i].serialWrapperList[0].skid.Lot_Number__c = '1234';
                polWrapperList[i].serialWrapperList[0].skid.Bin__c = fuel.bin.id;
                polWrapperList[i].serialWrapperList[0].skid.expiration_date__c = system.today()+30;   
            }
            
            // Reset the flag so that the trigger runs again.
          KSE.flagvalue = false;
          
            result = PurchaseOrderReceiveExtV2.receivePurchaseOrders( polWrapperList);
            
            system.assert( result.success == false,'minimum shelf life requirement failed'+result ); 
            
            for( Integer i = 0 ; i< polWrapperList.size() ; i ++ ){
    
                polWrapperList[i].serialWrapperList[0].skid.expiration_date__c = null;   
            }
            
            result = PurchaseOrderReceiveExtV2.receivePurchaseOrders( polWrapperList);
            
            system.assert( result.success == false,'expiration date not filled'+result+','+polWrapperList ); 
            
            for( Integer i = 0 ; i< polWrapperList.size() ; i ++ ){
    
                polWrapperList[i].serialWrapperList[0].skid.expiration_date__c = system.today() + 42;
                polWrapperList[i].serialWrapperList[0].skid.Quantity__c = polWrapperList[i].serialWrapperList[0].skid.Quantity__c+1;
                if(polWrapperList[i].serialWrapperList[0].serialList != null){
                    polWrapperList[i].serialWrapperList[0].serialList.add(new Serial__c());
                }
            }
            
            result = PurchaseOrderReceiveExtV2.receivePurchaseOrders( polWrapperList);
            
            system.assert( result.success == false,'over received'+result+','+polWrapperList ); 
            
            for( Integer i = 0 ; i< polWrapperList.size() ; i ++ ){
    
                polWrapperList[i].serialWrapperList[0].skid.Quantity__c = (Decimal)polWrapperList[i].rl.get('Order_Quantity__c');   
            }
            
            result = PurchaseOrderReceiveExtV2.receivePurchaseOrders( polWrapperList);
            
            system.assert( result.success == false,'number of serials do not match'+result); 
            
            for( Integer i = 0 ; i< polWrapperList.size() ; i ++ ){
    
                if(polWrapperList[i].serialWrapperList[0].serialList != null){
                    polWrapperList[i].serialWrapperList[0].serialList.remove(polWrapperList[i].serialWrapperList[0].serialList.size()-1);
                }
            }
            
            result = PurchaseOrderReceiveExtV2.receivePurchaseOrders( polWrapperList);
            
            system.assert( result.success == true,'Receive Successful'+result );
            
            Test.stopTest();
        }


    private static testMethod void mixedBinError() {
        TestFuelQuery fuel = new TestFuelQuery();

        delete [SELECT Id FROM Item_Attribute__c];
        update new Location__c(Id = fuel.location3.Id, Bin_Tracked__c = true, Mixed_Bins_Allowed__c = true);

        insert new SKID__c(
            Company__c = fuel.company.Id,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Quantity__c = 1,
            Quantity_Stocking_UOM__c = 1,
            Item__c = fuel.itemList[0].Id,
            Container_Item__c = fuel.itemList[0].Id,
            Packaging_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Stocking_UOM__c = fuel.itemList[0].Stocking_UOM__c,
            Facility2__c = fuel.location3.Facility__c,
            Location__c = fuel.location3.Id,
            Bin__c = fuel.bin.Id
        );
        insert new SKID__c(
            Company__c = fuel.company.Id,
            Type__c = SkidService3.SKID_TYPE_LOCATION,
            Quantity__c = 1,
            Quantity_Stocking_UOM__c = 1,
            Item__c = fuel.itemList[1].Id,
            Container_Item__c = fuel.itemList[1].Id,
            Packaging_UOM__c = fuel.itemList[1].Stocking_UOM__c,
            Stocking_UOM__c = fuel.itemList[1].Stocking_UOM__c,
            Facility2__c = fuel.location3.Facility__c,
            Location__c = fuel.location3.Id,
            Bin__c = fuel.bin.Id
        );

        try {
            update new Location__c(Id = fuel.location3.Id, Mixed_Bins_Allowed__c = false);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
    }
    private static testMethod void bankAccount_GL_Acount_Unique() {

        TestFuelQuery fuel = new TestFuelQuery();
        Bank_Account__c ba = [Select GL_Account_Unique__c, GL_Account__c, Bank_Account_Number_2__c from Bank_Account__c where Id = :fuel.bankAccount.ID limit 1];
        system.assertEquals(ba.GL_Account_Unique__c, ba.GL_Account__c);

        Bank_Account__c newBa = new Bank_Account__c (Company__c = fuel.company.Id, GL_Account__c = fuel.cashGL.ID, Bank_Account_Number_2__c = '12345');
        boolean sawError = false;
        try{
            insert newBa;
        }catch(Exception ex) {
            system.assert(ex.getMessage().contains('DUPLICATE_VALUE, duplicate value found'), ex.getMessage());
            sawError = true;
        }
        system.assertEquals(true, sawError,'why not!!');
        sawError = false;
        system.assertNotEquals(null, fuel.receivablesGL.ID);
        newBa = new Bank_Account__c (Company__c = fuel.company.Id, GL_Account__c = fuel.receivablesGL.ID, Bank_Account_Number_2__c = '12345');
        insert newBa;
        system.assertNotEquals(null,newBa.Id);
    }

    private static testMethod void validateCR_DepositID() {
        TestFuelQuery fuel = new TestFuelQuery();
        Customer_Receipt__c cr = new Customer_REceipt__c(Type__c = 'Receipt', Company__c = fuel.company.Id, bank_Account_2__c = fuel.bankAccount.Id, Customer__c = fuel.customerBillTo.Id, Amount_Received__c =100, Payment_Method_G__c = 'Check', Reference__c = '1234');
        insert cr;

        JSonresult result = CustomerReceiptAddDepositIDExt.validateCustomerReceipts(new list<String>{cr.iD});
        system.assertEquals(result.success, true);

        result = CustomerReceiptAddDepositIDExt.saveDepositIDs(new list<String>{cr.iD},'depositID');
        system.assertEquals(result.success, true);

        cr = [Select Deposit_Identifier__c from Customer_Receipt__c where Id = :cr.Id limit 1];
        system.assertEquals(cr.Deposit_Identifier__c, 'depositID');


        cr.Type__c = 'Refund';
        update cr;
        result = CustomerReceiptAddDepositIDExt.validateCustomerReceipts(new list<String>{cr.iD});
        system.assertEquals(result.success, false);

        cr.Type__c = 'Receipt';
        cr.Status__c = 'Cancelled';
        update cr;
        result = CustomerReceiptAddDepositIDExt.validateCustomerReceipts(new list<String>{cr.iD});
        system.assertEquals(result.success, false);

        cr.Status__c = 'Open';
        cr.Bank_Account_2__c = null;
        cr.Payment_Method_G__c = null;
        cr.Reference__c = null;
        cr.Amount_Received__c = null;
        update cr;
        result = CustomerReceiptAddDepositIDExt.validateCustomerReceipts(new list<String>{cr.iD});
        system.assertEquals(result.success, false);
    }

    private static testMethod void UniqueKeyOnBTM() {
        TestFuelQuery fuel = new TestfuelQuery();
        Bank_Transaction__c bt  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = 100, Transaction_Date__c =  system.now(),
                Bank_Account__c = fuel.bankAccount.Id);

        Bank_Transaction__c bt1  = new Bank_Transaction__c (Company__c = fuel.company.id, Amount__c = -200, Transaction_Date__c =  system.now(),
                Bank_Account__c = fuel.bankAccount.Id);
        insert bt;
        insert bt1;
        Bank_Transaction_Match__c btm = new Bank_Transaction_Match__c(Bank_Transaction__c = bt.Id, Bank_Transfer_Transaction__c = bt1.Id, Amount__c = 100);
        insert btm;

        Bank_Transaction_Match__c btmQ = [Select Id, Unique_Key__c, Bank_Transaction__c, Bank_Transfer_Transaction__c  from Bank_Transaction_Match__c where Id = :btm.Id];
        system.assertEquals(btmQ.Unique_Key__c,String.valueOf(btmQ.Bank_Transaction__c)+String.valueOf(btmQ.Bank_Transfer_Transaction__c), 'what went wrong '+btm);


    }

    private static testMethod void bankAccountOpeningDate() {
        TestFuelquery fuel = new TestFuelQuery();
        DateTime now = system.now();
        Bank_Account__c ba = new Bank_Account__c (Name = 'Test BOFA',
                account_type__c = 'Checking',
                GL_Account__c = fuel.receivablesGL.id,
                Company__c = fuel.company.Id,
                Active__c = true,
                Bank_Account_Number_2__c = '12345',
                Currency__c = fuel.currencyUSD.id,
                Opening_Balance_Date__c = now
        );
        insert ba;

        ba = [Select Id, Opening_Balance_Date__c from Bank_Account__c where id = :ba.Id];
        system.assertEquals(ba.Opening_Balance_Date__c, DateTime.newInstance(now.year(), now.month(), now.day()+1, 0, 0, 0).addSeconds(-1));

        now = now.addMonths(-2);
        ba.Opening_Balance_Date__c = now;
        update ba;
        ba = [Select Id, Opening_Balance_Date__c from Bank_Account__c where id = :ba.Id];
        system.assertEquals(ba.Opening_Balance_Date__c, DateTime.newInstance(now.year(), now.month(), now.day()+1, 0, 0, 0).addSeconds(-1));

    }

    private static testMethod void invDeduction_lessThanEqualtoZero() {
        TestFuelquery fuel = new TestFuelQuery();
        Claim__c c = new Claim__c(Company__c = fuel.company.Id, Parent_Customer__c = fuel.customerParent.Id, Source__c = 'Invoice Deduction', Amount__c = -100);
        boolean errorFound = false;
        try {
            insert c;
        }catch(Exception ex) {

            system.assert(ex.getMessage().contains('You can\'t enter a zero or negative amount for an invoice or general deduction claim.'));
            errorFound = true;
        }

        system.assertEquals(true,errorFound);
        errorFound = false;
        c.Amount__c = 0;
        try {
            insert c;
        }catch(Exception ex) {

            system.assert(ex.getMessage().contains('You can\'t enter a zero or negative amount for an invoice or general deduction claim.'));
            errorFound = true;
        }
    }

}