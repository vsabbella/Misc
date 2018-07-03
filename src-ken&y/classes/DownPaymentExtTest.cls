@isTest
private class DownPaymentExtTest {
	
	

    static testMethod void DownPaymentFail_NotApproved() {
    	TestFuel fuel = new TestFuel();

       Item__c item = new Item__c(Company__c = fuel.company.ID, Name = 'Down Payment', Non_Inventory__c =true, Source__c = OneTimeInvoiceService.ITEMSOURCE_FEE , Active__c =true);

        insert item;
        
        Product__c product = new Product__c(Company__c = fuel.company.ID, Name = 'Down Payment', Item__c = item.Id);
        insert product;
        
        Agreement__c agreement = new Agreement__c();
        agreement.Name = 'Sample Agreement';
        agreement.Plan__c = fuel.plan.Id;
        agreement.Customer__c = fuel.customerParent.Id;
        agreement.Start_Date__c = system.now();
        agreement.Status__c = 'Draft';
        agreement.Customer_Type__c = 'Bill To';
        agreement.Currency__c = TestFuel.currencyGBP.id;
        agreement.Payment_Terms__c = fuel.terms.Id;
        insert agreement;
        
        Agreement_Line__c agLine = new Agreement_Line__c(Agreement__c = agreement.id, Product__c = product.Id, Sales_Agreement_Quantity__c = 1, Agreement_Price__c = 100, Start_Date__c = system.now());
        insert agLine;
        
        ApexPages.standardController con = new ApexPages.standardController(agreement);
        DownpaymentInvoiceExt ext = new DownpaymentInvoiceExt(con);
        
        ext.createDownPaymentInvoice();
        
        system.assertEquals(true,ext.isDisabled);
        boolean ErrorExists = false;
        for( ApexPages.Message msg :ApexPages.GetMessages())
        	if(msg.getDetail().contains('Cannot invoice if agreement is not approved'))
        	{
        		ErrorExists = true;
        		break;
        	}
        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
    }
    
    static testMethod void DownPaymentFail_NotStarted() {
    	TestFuel fuel = new TestFuel();
		Item__c item = new Item__c(Company__c = fuel.company.ID, Name = 'Down Payment', Non_Inventory__c =true, Source__c = OneTimeInvoiceService.ITEMSOURCE_FEE, Active__c =true);

        insert item;
        
        Product__c product = new Product__c(Company__c = fuel.company.ID, Name = 'Down Payment', Item__c = item.Id);
        insert product;
        
        Agreement__c agreement = new Agreement__c();
        agreement.Name = 'Sample Agreement';
        agreement.Plan__c = fuel.plan.Id;
        agreement.Customer__c = fuel.customerParent.Id;
        agreement.Start_Date__c =DateTime.newInstance(system.today().addYears(1), Time.newInstance(0,0,0,0));
        agreement.Status__c = 'Approved';
        agreement.Customer_Type__c = 'Bill To';
        agreement.Currency__c = TestFuel.currencyGBP.id;
        agreement.Payment_Terms__c = fuel.terms.Id;
        insert agreement;
        
        Agreement_Line__c agLine = new Agreement_Line__c(Agreement__c = agreement.id, Product__c = product.Id, Sales_Agreement_Quantity__c = 1, Agreement_Price__c = 100, Start_Date__c = DateTime.newInstance(system.today().addYears(1), Time.newInstance(0,0,0,0)));
        insert agLine;
        
        ApexPages.standardController con = new ApexPages.standardController(agreement);
        DownpaymentInvoiceExt ext = new DownpaymentInvoiceExt(con);
        
        ext.createDownPaymentInvoice();
        
        system.assertEquals(true,ext.isDisabled);
        boolean ErrorExists = false;
        for( ApexPages.Message msg :ApexPages.GetMessages())
        	if(msg.getDetail().contains('Cannot invoice before agreement start date'))
        	{
        		ErrorExists = true;
        		break;
        	}
        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
    }
    
    static testMethod void DownPaymentFail_NotDPLine() {
    	TestFuel fuel = new TestFuel();
		Item__c item = new Item__c(Company__c = fuel.company.ID, Name = 'Down Payment', Non_Inventory__c =true, Source__c = OneTimeInvoiceService.ITEMSOURCE_FEE, Active__c =true);

        insert item;
        
        Product__c product = new Product__c(Company__c = fuel.company.ID, Name = 'Down Payment', Item__c = item.Id);
        insert product;
        
        Agreement__c agreement = new Agreement__c();
        agreement.Name = 'Sample Agreement';
        agreement.Plan__c = fuel.plan.Id;
        agreement.Customer__c = fuel.customerParent.Id;
        agreement.Start_Date__c = DateTime.newInstance(system.today(), Time.newInstance(0,0,0,0));
        agreement.Status__c = 'Approved';
        agreement.Customer_Type__c = 'Bill To';
        agreement.Currency__c = TestFuel.currencyGBP.id;
        agreement.Payment_Terms__c = fuel.terms.Id;
        insert agreement;
        
        //Agreement_Line__c agLine = new Agreement_Line__c(Agreement__c = agreement.id, Product__c = product.Id, Sales_Agreement_Quantity__c = 1, Agreement_Price__c = 100, Start_Date__c = system.now());
       // insert agLine;
        
        ApexPages.standardController con = new ApexPages.standardController(agreement);
        DownpaymentInvoiceExt ext = new DownpaymentInvoiceExt(con);
        
        ext.createDownPaymentInvoice();
        
        system.assertEquals(true,ext.isDisabled);
        boolean ErrorExists = false;
        for( ApexPages.Message msg :ApexPages.GetMessages())
        	if(msg.getDetail().contains('Cannot invoice as there is no agreement line tied to a fee item'))
        	{
        		ErrorExists = true;
        		break;
        	}
        system.assertEquals( ErrorExists,true, ApexPages.GetMessages());
    }
    
    static testMethod void DownPaymentSuccess() {
    	TestFuel fuel = new TestFuel();
		Item__c item = new Item__c(Company__c = fuel.company.ID, Name = 'Down Payment', Non_Inventory__c =true, Source__c = OneTimeInvoiceService.ITEMSOURCE_FEE, Active__c =true);

        insert item;
        
        Product__c product = new Product__c(Company__c = fuel.company.ID, Name = 'Down Payment', Item__c = item.Id);
        insert product;
        
        Agreement__c agreement = new Agreement__c();
        agreement.Name = 'Sample Agreement';
        agreement.Plan__c = fuel.plan.Id;
        agreement.Company__c = fuel.company.Id;
        agreement.Customer__c = fuel.customerParent.Id;
        agreement.Start_Date__c = DateTime.newInstance(system.today(), Time.newInstance(0,0,0,0));
        agreement.Status__c = 'Draft';
        agreement.Customer_Type__c = 'Bill To';
        agreement.Currency__c = TestFuel.currencyGBP.id;
        agreement.Payment_Terms__c = fuel.terms.Id;
        insert agreement;
        
        Agreement_Line__c agLine = new Agreement_Line__c(Agreement__c = agreement.id,Revision_Status__c = null, Product__c = product.Id, Sales_Agreement_Quantity__c = 1, Agreement_Price__c = 100, Start_Date__c = system.now());
       insert agLine;
        agreement.Status__c = 'Approved';
        update agreement;
        ApexPages.standardController con = new ApexPages.standardController(agreement);
        DownpaymentInvoiceExt ext = new DownpaymentInvoiceExt(con);
        
        ext.createDownPaymentInvoice();
        ext.wrapper.lCILs[0].selected= true;
        system.assertEquals(false,ext.isDisabled);
        
        ext.saveInvoice();
        
		list<Customer_Invoice__c> lCI = [Select Id, Finalized__c, (Select Id, Product__r.Item__r.Source__c from Customer_Invoice_Lines__r where Product__r.Item__r.Source__c = :OneTimeInvoiceService.ITEMSOURCE_FEE) from Customer_Invoice__c];

        
        system.assertEquals(1,lCI.size());
        system.assertEquals(true,lCI[0].Finalized__c);
        system.assertEquals(1,lCI[0].Customer_Invoice_Lines__r.size());
        
        
        
    }
    
    
}