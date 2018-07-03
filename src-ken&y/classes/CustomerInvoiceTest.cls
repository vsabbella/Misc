@isTest 
public with sharing class CustomerInvoiceTest {

	
	public class custInvoiceData{
		//TestDataForFinance data = new TestDataForFinance();
		
		TestFuel fuel = new TestFuel();        
       	Company__c co = fuel.company;
        Location__c loc = fuel.location;
        Item__c purchasedItem = fuel.itemList[1];        
		Supplier__c sup = fuel.supplier;	
		Product__c prod = fuel.product3;
		//Added Bill To for field filters
		Customer__c customerBillTo = fuel.customerBillTo;	
		Customer__c customerSoldTo = fuel.customerSoldTo;
		
		Payment_Term__c terms = fuel.terms;
		List<Period__c> periodList = fuel.periodList;
        
        
		
		string custInvName = SchemaUtil.getInstance().getLocalNameFromObject(new Customer_Invoice__c());
	
  		//public TestData.Accounting  Acctdata = new TestData.Accounting(co.Id);				
		
        {        
        Product__c updProd = [SELECT Id, Item__r.Class__c FROM Product__c where Id=:prod.Id];
       	Class__c updClass =  new Class__c(Id=updProd.Item__r.Class__c);   
        Id glId = fuel.cashGL.Id;
        updClass.Inventory_GL_Account__c = glId;
        updClass.Revenue_GL_Account__c = glId;          
        update updClass;         
        }

        
		Accounting_Default__c testDefault = new Accounting_Default__c();
		{
	        	testDefault.Company__c = fuel.company.Id;
	        	testDefault.GL_Account__c = fuel.cashGL.Id;
	        
	        	insert testDefault;
        }
        

        
		public Sales_Order__c salesOrder1=new Sales_Order__c();
   		public Sales_Order__c salesOrder2=new Sales_Order__c();
            { 
            salesOrder1.Customer__c=fuel.customerSoldTo.id;
            salesOrder1.Currency__c = TestFuel.currencyUSD.id ;
            salesOrder1.Status__c='Open';
            salesOrder1.Type__c = 'Standard';
            salesOrder1.Payment_Term__c = terms.id;
            salesOrder1.Company__c = co.id;
            salesOrder1.Ship_Complete__c = true;
  
            salesOrder2.Customer__c=fuel.customerSoldTo.id;
            salesOrder2.Currency__c = TestFuel.currencyUSD.id ;
            salesOrder2.Status__c='Open';
            salesOrder2.Type__c = 'Special';
            salesOrder2.Payment_Term__c = terms.id;
            salesOrder2.company__c = co.id;
                              
            insert new List<Sales_Order__c> { salesorder1, salesOrder2 } ;
       }
        
        public List<Sales_Order_Line__c> SalesOrderLineList = new List<Sales_Order_Line__c>();
        {
            Sales_Order_Line__c salesOrderLineObj1 = new Sales_Order_Line__c();
            salesOrderLineObj1.Sales_Order__c=salesOrder1.Id;
            salesOrderLineObj1.Quantity_Ordered__c =12; 
            salesOrderLineObj1.Unit_Price__c = 480;
            salesOrderLineObj1.Required_Date__c=System.today()+5;
            salesOrderLineObj1.Status__c='Open';
            salesOrderLineObj1.Company__c = co.id;
            salesOrderLineObj1.Product__c = prod.id;
            salesOrderLineObj1.Ship_From_Location__c = loc.id;
            salesOrderLineObj1.Line_Type__c = 'Standard';
                                    
            SalesOrderLineList.add(salesOrderLineObj1);
            
            Sales_Order_Line__c salesOrderLineObj2 = new Sales_Order_Line__c();
            salesOrderLineObj2.Sales_Order__c=salesOrder1.Id;
            salesOrderLineObj2.Quantity_Ordered__c =5; 
            salesOrderLineObj2.Unit_Price__c = 480;
            salesOrderLineObj2.Required_Date__c=System.today()+30;
            salesOrderLineObj2.Status__c='Open';
            salesOrderLineObj2.Company__c = co.id;
            salesOrderLineObj2.Product__c = prod.id;
            salesOrderLineObj2.Ship_From_Location__c = loc.id;
            salesOrderLineObj2.Line_Type__c = 'Standard';
                                
            SalesOrderLineList.add(salesOrderLineObj2);
            
            Sales_Order_Line__c salesOrderLineObj3 = new Sales_Order_Line__c();
            salesOrderLineObj3.Sales_Order__c=salesOrder2.Id;
            salesOrderLineObj3.Quantity_Ordered__c =3; 
            salesOrderLineObj3.Unit_Price__c = 480;
            salesOrderLineObj3.Required_Date__c=System.today()+5;
            salesOrderLineObj3.Status__c='Open';
            salesOrderLineObj3.Company__c = co.id;
            salesOrderLineObj3.Product__c = prod.id;
            salesOrderLineObj3.Ship_From_Location__c = loc.id;
            salesOrderLineObj3.Line_Type__c = 'Standard';
                        
            SalesOrderLineList.add(salesOrderLineObj3);
            
            Sales_Order_Line__c salesOrderLineObj4 = new Sales_Order_Line__c();
            salesOrderLineObj4.Sales_Order__c=salesOrder2.Id;
            salesOrderLineObj4.Quantity_Ordered__c =3; 
            salesOrderLineObj4.Unit_Price__c = 480;
            salesOrderLineObj4.Required_Date__c=System.today()+5;
            salesOrderLineObj4.Status__c='Open';
            salesOrderLineObj4.Company__c = co.id;
            salesOrderLineObj4.Product__c = prod.id;
            salesOrderLineObj4.Ship_From_Location__c = loc.id;
            salesOrderLineObj4.Line_Type__c = 'Distribution Sample';            
            SalesOrderLineList.add(salesOrderLineObj4);
            
            insert SalesOrderLineList;

           }        
     
        
	 	public Customer_Invoice__c custInv1, custInv2, custInv3;
	 	
	 	List<Customer_Invoice__c> custInvAEList = new List<Customer_Invoice__c>();
	 	{
			custInv1 = new Customer_Invoice__c();
		    custInv1.Company__c = fuel.company.Id;
		    custInv1.Invoice_Type__c = 'Ship Invoice';
		    custInv1.Date_Invoiced__c = System.now();
		    //Added Bill To for field filters
		    custInv1.Bill_To_Customer__c = customerBillTo.id;
		    custInv1.Sold_to_customer__c = customerSoldTo.Id;
		     
		    custInv1.Subtotal__c = 0;
		    custInv1.Sales_Order__c = salesOrder1.Id;
		    custInv1.transaction_date__c = system.now();
		    custInvAEList.add(custInv1);
		    
		    custInv2 = new Customer_Invoice__c();
		    custInv2.Company__c = fuel.company.Id;
		    custInv2.Invoice_Type__c = 'Ship Invoice';
		    custInv2.Date_Invoiced__c = System.now();
		     //Added Bill To for field filters
		    custInv2.Bill_To_Customer__c = customerBillTo.id;
		    custInv2.Sold_to_customer__c = fuel.customerSoldTo.Id;
		    
		    custInv2.Subtotal__c = 0;
		    custInv2.Sales_Order__c = salesOrder2.Id;
		    custInv2.transaction_date__c = system.now();
		    custInvAEList.add(custInv2);
		    
		    custInv3 = new Customer_Invoice__c();
		    custInv3.Company__c = fuel.company.Id;
		    custInv3.Invoice_Type__c = 'Miscellaneous';
		    custInv3.Date_Invoiced__c = System.now();
		    //Added Bill To for field filters
		    custInv3.Bill_To_Customer__c = customerBillTo.id;
		    custInv3.Sold_to_customer__c = customerSoldTo.Id;
		    custInv3.transaction_date__c = system.now();
		    //custInv3.Accounting_Segment__c = testDefault.id;
		    custInvAEList.add(custInv3);
		    
		    insert custInvAEList;
	 	}
	    
	    List<Customer_Invoice_Line__c> custInvLineList = new List<Customer_Invoice_Line__c>();
	    {
		    	accounting_default__c accdef = new accounting_default__c();
		    	accdef.company__c = fuel.company.Id;
		    	accdef.gl_account__c = fuel.cashGL.Id;
		    	insert accdef;
		    	
		    Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
		    custInvLine1.Quantity_Shipped__c = 2;
		    custInvLine1.Company__c = fuel.company.Id;
		    //custInvLine1.Sales_Order_Line__c = data.SalesOrderLineList[0].id;
		    custInvLine1.Unit_Price__c = 7;
		    custInvLine1.Extended_Price__c = 14;
            custInvLine1.Quantity_Shipped__c = 3;
		    //custInvLine1.Sales_Order__c = data.salesOrder1.id;
		    custInvLine1.Product__c = prod.Id ; 
		    custInvLine1.Discount_Percent__c = 2;
		    custInvLine1.Customer_Invoice__c = custInvAEList[0].id;
		    custInvLineList.add(custInvLine1);
		    Customer_Invoice_Line__c custInvLine2 = new Customer_Invoice_Line__c();
		    custInvLine2.Quantity_Shipped__c = 3;
		    custInvLine2.Company__c = fuel.company.Id;
		    //custInvLine2.Sales_Order_Line__c = data.SalesOrderLineList[1].id;
		    custInvLine2.Unit_Price__c = 9;
		    custInvLine2.Extended_Price__c = 27;
		    //custInvLine2.Sales_Order__c = data.salesOrder1.id;
		    custInvLine2.Product__c = prod.Id ; 
		    custInvLine2.Discount_Percent__c = 2;
		    custInvLine2.Customer_Invoice__c = custInvAEList[0].id;
		    custInvLineList.add(custInvLine2);
		    Customer_Invoice_Line__c custInvLine3 = new Customer_Invoice_Line__c();
		    custInvLine3.Quantity_Shipped__c = 2;
		    custInvLine3.Company__c = fuel.company.Id;
		    //custInvLine3.Sales_Order_Line__c = data.SalesOrderLineList[2].id;
		    custInvLine3.Unit_Price__c = 7;
		    custInvLine3.Extended_Price__c = 21;
		    //custInvLine3.Sales_Order__c = data.salesOrder2.id;
		    custInvLine3.Product__c = prod.Id ; 
		    custInvLine3.Discount_Percent__c = 2;
		    custInvLine3.Customer_Invoice__c = custInvAEList[1].id;
		    custInvLineList.add(custInvLine3);
		    Customer_Invoice_Line__c custInvLine4 = new Customer_Invoice_Line__c();
		    custInvLine4.Quantity_Shipped__c = 3;
		    custInvLine4.Company__c = fuel.company.Id;
		    //custInvLine4.Sales_Order_Line__c = data.SalesOrderLineList[3].id;
		    custInvLine4.Unit_Price__c = 9;
		    custInvLine4.Extended_Price__c = 27;
		    //custInvLine4.Sales_Order__c = data.salesOrder2.id;
		    custInvLine4.Product__c = prod.Id ; 
		    custInvLine4.Discount_Percent__c = 2;
		    custInvLine4.Customer_Invoice__c = custInvAEList[1].id;
		    custInvLineList.add(custInvLine4);
		    
		    Customer_Invoice_Line__c custInvLine5 = new Customer_Invoice_Line__c();
		    custInvLine5.Quantity_Shipped__c = -3;
		    custInvLine5.subtransaction_type__c = null;
		    custInvLine5.accounting_segment__c = accdef.id;
		    custInvLine5.Company__c = fuel.company.Id;
		    custInvLine5.Unit_Price__c = 9;
		    custInvLine5.Accounting_Segment__c = testDefault.id;
		    custInvLine5.Product__c = prod.Id ; 
		    custInvLine5.Customer_Invoice__c = custInvAEList[2].id;
		    custInvLineList.add(custInvLine5);
		    
		    insert custInvLineList;
		    
		    for(Customer_Invoice__c custInv: custInvAEList){
		    	custInv.finalized__c = true;
	    }
		
		    update custInvAEList;
	    }
		
		Set<Id> invoiceIds = new Set<Id>();{
		    for(Customer_Invoice__c invoice: custInvAEList){
		        invoiceIds.add(invoice.id);
		    }
		}
	}
    


	
     static testMethod void testPeriodPaid() {
        custInvoiceData data = new custInvoiceData();
        Test.StartTest();
      	
      	data.custInv1.Date_Time_Paid__c = system.today(); 
      	
      	update  data.custInv1; 

		data.custInv1 = [ select id , Period_paid__c,Date_Time_Paid__c from Customer_Invoice__c 
			where id=:data.custInv1.id limit 1];
		system.debug(LoggingLevel.INFO, data.custInv1  );
		//TODO: RS 8/1/2014 Fix this issue for wrapping periods over month end
		//system.assert( data.custInv1.Period_paid__c != null );
		Test.stopTest();
    }
    
    static testMethod void testFreezeDueDate() {
        custInvoiceData data = new custInvoiceData();
      
        Test.StartTest();
        
        Customer_Invoice__c custInv1 = new Customer_Invoice__c();
        custInv1.Company__c = data.fuel.company.Id;
        custInv1.Invoice_Type__c = 'Ship Invoice';
        custInv1.Date_Invoiced__c = System.now();
        custInv1.Bill_To_Customer__c = data.customerBillTo.id;
        custInv1.Sold_to_customer__c = data.customerSoldTo.Id;
        custInv1.Subtotal__c = 0;
        custInv1.Sales_Order__c = data.salesOrder1.Id;
        custInv1.transaction_date__c = system.now();
        insert custInv1;
        
        
        custInv1.Freeze_Due_Date__c = true;
        update custInv1;
        
        
        try{
        custInv1.Due_Date__c = System.today() + 2;
        update  custInv1;
        }catch(DMLException exp){
            System.assert(exp.getMessage().contains(Label.Customer_Invoice_Due_Date_Frozen));
        }

		List<Customer_Invoice__c> custInv = [ select id ,Due_Date__c from Customer_Invoice__c 
															where id = :custInv1.id limit 1];
		system.assertNotEquals(custInv[0].Due_Date__c,System.today() + 2);
	
		Test.stopTest();
    }
    
    static testMethod void testListViewGenerateAccounting() {
        CustomerInvoiceAccountingExt GAEC;
        custInvoiceData custInvData = new custInvoiceData();
        List<Accounting_Rule__c> acctRuleList = custInvData.fuel.ciAccountingRuleList;
        Test.StartTest();
                
        Apexpages.StandardSetController setcon = new Apexpages.StandardSetController(custInvData.custInvAEList);
        
        setcon.setSelected(custInvData.custInvAEList);
        GAEC = new CustomerInvoiceAccountingExt(setcon);
        GAEC.GenerateCustomerInvoiceAccounting(); 
        
        Test.stopTest();
        
        
        system.assertNotEquals(null, custInvData.custInv1.id);
        
        
        Accounting_Entry__c acctEntry = [Select id, Name, (Select id, Name, GL_Account__c from Accounting_Entry_Lines__r) 
        								from Accounting_Entry__c where Customer_Invoice__c = :custInvData.custInv1.id ];
       	system.assertNotEquals(null, acctEntry);
       	system.assertNotEquals(null, acctEntry.Accounting_Entry_Lines__r[0].GL_Account__c);
       	system.assertNotEquals(null, acctEntry.Accounting_Entry_Lines__r[1].GL_Account__c);
       	
       	acctEntry = [Select id, Name, (Select id, Name, GL_Account__c from Accounting_Entry_Lines__r) 
        								from Accounting_Entry__c where Customer_Invoice__c = :custInvData.custInv3.id];
       	system.assertNotEquals(null, acctEntry);
       	// TODO RS 2014-05-09 Review rules for this GL Assignment
       	//system.assertNotEquals(null, acctEntry.Accounting_Entry_Lines__r[0].GL_Account__c);
       	//system.assertNotEquals(null, acctEntry.Accounting_Entry_Lines__r[1].GL_Account__c);
       	
       	
    }
    
    
    
    static testMethod void testEntryGeneration() {
        
        custInvoiceData custInvData = new custInvoiceData();
        
		Set<Id> companyIds = new Set<Id>{custInvData.co.Id};		

		Test.startTest();
			database.executebatch(new CustomerInvoiceAccountingBatch(companyIds));
		Test.stopTest();	

		List<Accounting_Entry__c> acctEntryList = [Select id, Name, (Select id, Name, GL_Account__c from Accounting_Entry_Lines__r) 
        								from Accounting_Entry__c where Customer_Invoice__c IN :custInvData.invoiceIds ];
        								
       	system.assertNotEquals(null, acctEntryList);
       	
				
    }
    
    static testMethod void setStatus_hardSetClose() //ar-134
    {
    	TestFuel fuel = new TestFuel();
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Chargeback';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
		insert CustomerInvoice;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
		
		CustomerInvoice.Finalized__c = true;
		CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_CLOSED;
		update CustomerInvoice;
		
		CustomerInvoice = [Select Id, Balance__c, Status__c from Customer_Invoice__c where Id = :CustomerInvoice.Id limit 1];
		system.assertEquals(CustomerInvoiceService.STATUS_OPEN, CustomerInvoice.Status__c);
		
		
    }
    
    static testMethod void setStatus_partialPay()//ar-134
    {
    	TestFuel fuel = new TestFuel();
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Chargeback';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
		insert CustomerInvoice;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
		
		CustomerInvoice.Finalized__c = true;
		CustomerInvoice.Amount_Paid__c = 10;
		update CustomerInvoice;
		
		CustomerInvoice = [Select Id, Balance__c, Status__c from Customer_Invoice__c where Id = :CustomerInvoice.Id limit 1];
		system.assertEquals(CustomerInvoiceService.STATUS_OPEN, CustomerInvoice.Status__c);
		
		
    }
    
    static testMethod void setStatus_fullyPay()//ar-134
    {
    	TestFuel fuel = new TestFuel();
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Chargeback';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
		insert CustomerInvoice;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
		
		CustomerInvoice.Finalized__c = true;
		CustomerInvoice.Amount_Paid__c = 100;
		update CustomerInvoice;
		
		CustomerInvoice = [Select Id, Balance__c, Status__c from Customer_Invoice__c where Id = :CustomerInvoice.Id limit 1];
		system.assertEquals(CustomerInvoiceService.STATUS_CLOSED, CustomerInvoice.Status__c);
		system.assertEquals(0, CustomerInvoice.Balance__c);
		
		
    }
    /* KNDY-11830
    static testMethod void testClone() {
    	
    	
    	
    	TestFuel fuel = new TestFuel();
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today()-1;
		insert CustomerInvoice;
        
        Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
        
    	
    	CustomerInvoice.Finalized__c =true;
    	update CustomerInvoice;
            Customer_Invoice__c ci = [Select id, Balance__c, Status__c, Resolution_Code__c,Finalized__c,Company__c, (Select Id, Customer_Invoice__c, Finalized__c from Customer_Invoice_Lines__r) from Customer_Invoice__c where id =:CustomerInvoice.id ];
        system.assertEquals(1,ci.Customer_Invoice_Lines__r.size());
        system.assertEquals(ci.Finalized__c,true);
     
        
    	Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(CustomerInvoice);
        CustomerInvoiceCloneExt ext = new CustomerInvoiceCloneExt(con);
        ext.actiontype='save';
        
        PageReference p= ext.saveClone();
        
        Customer_Invoice__c newci = [Select id, Balance__c, Status__c, Resolution_Code__c,Finalized__c,Company__c,transaction_date__c, (Select Id, Customer_Receipt__c, Finalized__c from Customer_Receipt_Lines__r) from Customer_Invoice__c where id !=:CustomerInvoice.id ];
        system.assertEquals(newci.Finalized__c,false);
        system.assertEquals(newci.Company__c,fuel.company.Id);
       boolean Datetimematches=    KSE.areDateTimesClose(newci.transaction_date__c,system.now() ).bCloseEnough;
        system.assertEquals(Datetimematches,true);
        
        system.assertEquals(p.getURL(),'/'+newci.Id);
        
    }
 
	 static testMethod void testCannotClone() {
    	
    	TestFuel fuel = new TestFuel();
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Standard';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = Date.today();
		insert CustomerInvoice;
        
        Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
    	CustomerInvoice.Finalized__c =true;
    	update CustomerInvoice;
     
    	Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(CustomerInvoice);
        CustomerInvoiceCloneExt ext = new CustomerInvoiceCloneExt(con);
        ext.actiontype='save';
         List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(Apexpages.Message msg:msgs){
   			 if (msg.getDetail().contains('Cannot clone "Standard" type Customer Invoice.')) b = true;
			}
          system.assert(b,msgs);
       
        
        
    }
   */
    Static testmethod void testdefaultTransactionDate(){
        TestFuel fuel = new TestFuel();
        Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = fuel.company.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
		insert CustomerInvoice;
       CustomerInvoice= [select transaction_date__c from customer_invoice__C where id = :CustomerInvoice.id];
        system.assert(CustomerInvoice.transaction_date__c !=null);
        
    }
 

}