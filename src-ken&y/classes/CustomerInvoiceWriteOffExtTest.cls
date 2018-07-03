@isTest
private class CustomerInvoiceWriteOffExtTest {
	public static TestFuel tdf = new TestFuel();
	
	public static Customer_Invoice__c custInvoice
	{
		get 
		{
			if(custInvoice == null)
			{
				custInvoice = new Customer_Invoice__c();
				custInvoice.Company__c = tdf.company.Id;
				custInvoice.Customer__c = tdf.customerParent.Id;
				custInvoice.Bill_to_Customer__c = tdf.customerBillTo.Id;
				custInvoice.Currency__c = TestFuel.currencyUSD.id;
				custInvoice.date_invoiced__c = system.now();
				custInvoice.transaction_date__c = system.now();
				custInvoice.Invoice_Type__c = 'Ship Invoice';
				custInvoice.Status__c = 'Open';
				custInvoice.Sales_Order__c = tdf.salesOrder.Id;
                
			}
			 return custInvoice;
		}
		set;
	}
	
	public static Customer_Invoice_Line__c custInvoiceLine
	{
		get 
		{
			if(custInvoiceLine == null)
			{
				custInvoiceLine = new Customer_Invoice_Line__c();
				custInvoiceLine.Customer_Invoice__c = custInvoice.Id;
				custInvoiceLine.Product__c = tdf.product.Id;
				custInvoiceLine.Quantity_Shipped__c = 10;
				custInvoiceLine.Unit_Price__c = 10;
				custInvoiceLine.Extended_Price__c = 100;
                
			}
			 return custInvoiceLine;
		}
		set;
	}
	
    static testMethod void testExtension() {
    	
    	Reason_Code__c res = new Reason_Code__c(Name= 'resolution', Type__c ='Resolution');
    	insert res;
    	
    	insert custInvoice;
    	insert custInvoiceLine;
    	custInvoice.Finalized__c =true;
    	update custInvoice;
    	
    	custInvoice.Resolution_Code__c = res.Id;
    	Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(custInvoice);
        CustomerInvoiceWriteOffExt ext = new CustomerInvoiceWriteOffExt(con);
        ext.writeOff();
        
        Customer_Invoice__c ci = [Select id, Balance__c, Status__c, Resolution_Code__c, (Select Id, Type__c, Customer_Receipt__c, Finalized__c from Customer_Receipt_Lines__r) from Customer_Invoice__c where id =:custInvoice.id limit 1];
        //system.debug([select id, subject from Task where whatId =:ci.Customer_Receipt_Lines__r[0].Customer_Receipt__c]);
        system.assertEquals(ci.Status__c,'Closed');
        system.assertEquals(ci.Balance__c,0);
        system.assertEquals(ci.Resolution_Code__c,res.Id);
        system.assertEquals(ci.Customer_Receipt_Lines__r.size(),1);
        system.assertEquals(ci.Customer_Receipt_Lines__r[0].Finalized__c,true);
        system.assertEquals(ci.Customer_Receipt_Lines__r[0].Type__c,PaymentService.TYPE_WRITEOFF);
    }
    
    static testMethod void testExtension_unfinalized() {
    	
    	insert custInvoice;
    	insert custInvoiceLine;
    	
    	
    	Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(custInvoice);
        CustomerInvoiceWriteOffExt ext = new CustomerInvoiceWriteOffExt(con);
        system.assertEquals(ext.disableAction,true,'It should be disable as CI is not finalized');
        system.assertEquals(ApexPages.hasMessages(), true,'There should be some error messages');
        system.assert(ApexPages.getMessages()[0].getSummary().contains(Label.Cannot_writeoff_invoice_not_finalized));
        
    }
    
    static testMethod void testExtension_closed() {
    	
    	insert custInvoice;
    	insert custInvoiceLine;
    	
    	custInvoice.Finalized__c =true;
    	custInvoice.Amount_Paid__c = 100;
    	update custInvoice;
    	
    	custInvoice = [select id, Balance__c, Amount_Paid__c, Status__c from Customer_Invoice__c where id = :custInvoice.id limit 1];
    	system.debug('after update ci : '+custInvoice);
    	Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(custInvoice);
        CustomerInvoiceWriteOffExt ext = new CustomerInvoiceWriteOffExt(con);
        system.assertEquals(ext.disableAction,true,'It should be disable as CI is not finalized');
        system.assertEquals(ApexPages.hasMessages(), true,'There should be some error messages');
        system.assert(ApexPages.getMessages()[0].getSummary().contains(Label.This_invoice_is_not_open));
        
    }
    
    static testMethod void testExtension_negative() {
    	
    	custInvoice.Write_Off_Amount__c = -10;
    	custInvoice.Resolution_Code__c = tdf.resolutionCode.Id;
    	custInvoice.Invoice_Type__c = 'Adjustment';
    	insert custInvoice;
    	
    	custInvoiceLine.Quantity_Shipped__c = -1;
    	insert custInvoiceLine;
    	
    	custInvoice.Finalized__c =true;
    	update custInvoice;
    	
    	Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(custInvoice);
        CustomerInvoiceWriteOffExt ext = new CustomerInvoiceWriteOffExt(con);
        ext.writeOff();
        
        List<Customer_Invoice__c> ciList = [Select id, Balance__c, Status__c
        	, (Select Id, Customer_Receipt__c, Finalized__c from Customer_Receipt_Lines__r) //KNDY-13995
        	from Customer_Invoice__c where id =:custInvoice.id limit 1];
        system.assertEquals(ciList[0].Balance__c,0,'The balance is more than 0'); 
        system.assertEquals(ciList[0].Customer_Receipt_Lines__r.size(),0);
        
    }
    

    static testMethod void testExtension_WriteoffCredit() {//KNDY-19379
        custInvoice.Resolution_Code__c = tdf.resolutionCode.Id;
        custInvoice.Invoice_Type__c = 'Prepayment';
        insert custInvoice;
        
        custInvoiceLine.Quantity_Shipped__c = -1;
        insert custInvoiceLine;
        
        custInvoice.Finalized__c =true;
        update custInvoice;
        
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(custInvoice);
        CustomerInvoiceWriteOffExt ext = new CustomerInvoiceWriteOffExt(con);
        ext.writeOff();

        List<Customer_Invoice__c> ciList = [Select id, Balance__c, Status__c
            , (Select Id, Customer_Receipt__c, Type__c, Finalized__c from Customer_Receipt_Lines__r) 
            from Customer_Invoice__c where id =:custInvoice.id limit 1];
        system.assertEquals(ciList[0].Customer_Receipt_Lines__r.size(),1);
        system.assertEquals(ciList[0].Customer_Receipt_Lines__r[0].Type__c, PaymentService.TYPE_WRITEOFF_CREDIT);
        
    }
}