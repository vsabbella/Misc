@isTest
public class CustomerInvoiceVoidCancelBatchExtTest {
   
     @testSetup static void ts() { 
        TestFuel data = new TestFuel(); 
        // these asserts cause TestFuelQuery to insert data
        system.assert(      
            data.company != null &&
            data.customerParent != null &&
            data.customerBillTo != null &&
            data.customerSoldTo != null &&
            data.product != null &&
            data.periodList != null &&
            data.location != null &&
            data.supplier != null &&
            data.product3 != null &&
            data.itemList != null &&
            data.cashGL != null &&
            data.terms != null &&
            data.ciAccountingRuleList != null  
        );
    }
    
    public class custInvoiceData{
        
        TestFuelQuery fuel = new TestFuelQuery();  
        Company__c co = fuel.company;
        Location__c loc = fuel.location;
        Item__c purchasedItem = fuel.itemList[1];        
        Supplier__c sup = fuel.supplier;	
        Product__c prod = fuel.product3;
        Currency__c currencyUSD = fuel.currencyUSD;
        
        //Added Bill To for field filters
        Customer__c customerBillTo = fuel.customerBillTo;	
        Customer__c customerSoldTo = fuel.customerSoldTo;
        
        Payment_Term__c terms = fuel.terms;
        List<Period__c> periodList = fuel.periodList;
        
        
        
        string custInvName = SchemaUtil.getInstance().getLocalNameFromObject(new Customer_Invoice__c());
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
            salesOrder1.Currency__c = currencyUSD.id ;
            salesOrder1.Status__c='Open';
            salesOrder1.Type__c = 'Standard';
            salesOrder1.Payment_Term__c = fuel.terms.id;
            salesOrder1.Company__c = co.id;
            salesOrder1.Ship_Complete__c = true;
            
            salesOrder2.Customer__c=fuel.customerSoldTo.id;
            salesOrder2.Currency__c = currencyUSD.id ;
            salesOrder2.Status__c='Open';
            salesOrder2.Type__c = 'Special';
            salesOrder2.Payment_Term__c = fuel.terms.id;
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
            custInv1.Batch_Job_ID__c ='70737000006564mAAA';
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
            custInv2.Batch_Job_ID__c ='70737000006564mAAA';
            
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
            custInv3.Batch_Job_ID__c ='70737000006564mAAA';
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
    
    
    static testMethod void CustomerInvoiceCancel() {
        custInvoiceData cidata = new custInvoiceData();
        Test.startTest(); 
        CustomerInvoiceVoidCancelBatchExt.cancel1('70737000006564mAAA',String.valueOf(System.now()));
        Test.stopTest();
        for(   customer_invoice__c cis: [select id,Status__c from customer_invoice__c where Batch_Job_ID__c ='70737000006564mAAA']){
            system.assertEquals('Cancelled',cis.status__c);
        }
    }
    
    static testMethod void CustomerInvoiceVoidFail() {
        custInvoiceData cidata = new custInvoiceData();
        Test.startTest(); // database.executeBatch(new CustomerInvoiceVoidCancelBatch('Cancel','70737000006564mAAA'),10); 
        JsonResult js= CustomerInvoiceVoidCancelBatchExt.void('707370000',String.valueOf(System.now())); // invalid batch id 
        Test.stopTest();
        system.assertEquals(false,js.success);
        boolean errorInvalidMsg =false;
        for(String s :js.messages[0].values()){
            if (s.contains('Invalid Batch')){
                errorInvalidMsg=true;
            }
        }
        system.assertEquals(true,errorInvalidMsg);
    }
    
    static testMethod void CustomerInvoiceCancelFail() {
        custInvoiceData cidata = new custInvoiceData();
        Test.startTest(); 
        JsonResult js= CustomerInvoiceVoidCancelBatchExt.cancel1('707370000',String.valueOf(System.now())); // invalid batch id 
        Test.stopTest();
        system.assertEquals(false,js.success);
        boolean errorInvalidMsg =false;
        for(String s :js.messages[0].values()){
            if (s.contains('Invalid Batch')){
                errorInvalidMsg=true;
            }
        }
        system.assertEquals(true,errorInvalidMsg);
    }
    
    static testMethod void canCancelBatch() {
        custInvoiceData cidata = new custInvoiceData();
        Test.startTest(); 
         database.executeBatch(new CustomerInvoiceVoidCancelBatch('Cancel','70737000006564mAAA',String.valueOf(System.now())),10); 
        Test.stopTest();
        for(   customer_invoice__c cis: [select id,Status__c from customer_invoice__c where Batch_Job_ID__c ='70737000006564mAAA']){
            system.assertEquals('Cancelled',cis.status__c);
        }
    }
    
    static testMethod void canVoid_Failure() { //Transaction Date is greater than void date
    	custInvoiceData cidata = new custInvoiceData();
    	system.assert(cidata.fuel.periodList.size() > 0,'TestFuel Failure.');
    	
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = cidata.fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = cidata.co.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = system.now()-10;
        CustomerInvoice.Batch_Job_ID__c='70737000006564mAAA';
		insert CustomerInvoice;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
		
		CustomerInvoice.Finalized__c = true;
		update CustomerInvoice;
		system.debug('cil: '+[Select Id, Line_Type__c, SubTransaction_Type__c from Customer_Invoice_Line__c where id = :cil.ID]);
		
	    test.StartTest(); 
		AccountingService cia = new CustomerInvoiceAccounting();
        list <Customer_Invoice_Line__c> cilines = new list <Customer_Invoice_Line__c>();
        cilines.add(cil);
        cia.execute(cilines);
        
		CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, (Select Id, has_exceptions__c, Transaction_Type__c from Accounting_Entries__r) from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
		system.debug('test: ae '+ CustomerInvoice.Accounting_Entries__r);
		system.debug([select id, subject from Task where whatId = :CustomerInvoice.Accounting_Entries__r.get(0).Id]);
		for(Accounting_Entry_Line__c ael : [Select Id, SubTransaction_type__c, line_Type__c, (select id, subject from Tasks) from Accounting_Entry_Line__c where Accounting_Entry__c = :CustomerInvoice.Accounting_Entries__r.get(0).Id])
		{
			system.debug('ael: '+ael);
			system.debug('ael with tasks: '+ael.Tasks);
		}
		system.assert(CustomerInvoice.Accounting_Entries__r.size() >0);
    
        //DateTime dt = system.now()-15;
        CustomerInvoice.void_date__c = system.now()-15;
        database.executeBatch(new CustomerInvoiceVoidCancelBatch('void','70737000006564mAAA', String.valueOf(CustomerInvoice.void_date__c.format('yyyy-MM-dd HH:mm:ss'))),10);         
    	test.StopTest();
		CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
		system.assertEquals(CustomerInvoice.Status__c, 'Open');
		System.debug(logginglevel.error,'CustomerInvoice-->'+CustomerInvoice);
		system.assertEquals(CustomerInvoice.Void__c, false);
		system.assertEquals(CustomerInvoice.Void_Date__c, null);
    }
    	
    static testMethod void canVoid() { //Transaction Date is after void date
    	custInvoiceData cidata = new custInvoiceData();
    	system.assert(cidata.fuel.periodList.size() > 0,'TestFuel Failure.');
    	
    	Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
		CustomerInvoice.Bill_To_Customer__c = cidata.fuel.customerBillTo.Id;
        CustomerInvoice.Company__c = cidata.co.Id;
        CustomerInvoice.Invoice_Type__c = 'Manual';
        CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
        CustomerInvoice.Date_Invoiced__c = system.now();
        CustomerInvoice.Transaction_Date__c = system.now()-1;
        CustomerInvoice.Batch_Job_ID__c='70737000006564mAAA';
		insert CustomerInvoice;
		
		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Customer_Invoice__c = CustomerInvoice.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		insert cil;
		
		CustomerInvoice.Finalized__c = true;
		update CustomerInvoice;
		system.debug('cil: '+[Select Id, Line_Type__c, SubTransaction_Type__c from Customer_Invoice_Line__c where id = :cil.ID]);
		
	    test.StartTest(); 
			AccountingService cia = new CustomerInvoiceAccounting();
	        list <Customer_Invoice_Line__c> cilines = new list <Customer_Invoice_Line__c>();
	        cilines.add(cil);
	        cia.execute(cilines);
	        
			CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, (Select Id, has_exceptions__c, Transaction_Type__c from Accounting_Entries__r) from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
			system.debug('test: ae '+ CustomerInvoice.Accounting_Entries__r);
			system.debug([select id, subject from Task where whatId = :CustomerInvoice.Accounting_Entries__r.get(0).Id]);
			for(Accounting_Entry_Line__c ael : [Select Id, SubTransaction_type__c, line_Type__c, (select id, subject from Tasks) from Accounting_Entry_Line__c where Accounting_Entry__c = :CustomerInvoice.Accounting_Entries__r.get(0).Id])
			{
				system.debug('ael: '+ael);
				system.debug('ael with tasks: '+ael.Tasks);
			}
			system.assert(CustomerInvoice.Accounting_Entries__r.size() >0);
	    
        database.executeBatch(new CustomerInvoiceVoidCancelBatch('void','70737000006564mAAA', String.valueOf(System.now().format('yyyy-MM-dd HH:mm:ss'))),10);         
        	test.StopTest();
			CustomerInvoice = [Select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c from Customer_Invoice__c where id = :CustomerInvoice.Id limit 1 ];
			system.assertEquals(CustomerInvoice.Status__c, 'Void');
			system.assertEquals(CustomerInvoice.Void__c, true);
        system.assertEquals(CustomerInvoice.Void_Date__c.date(), System.now().date());
    }
		
	
     static testMethod void canCancelOnlyOpenCIInBatch() { 
        custInvoiceData cidata = new custInvoiceData();
        
        Customer_Invoice__c custInv4 = new Customer_Invoice__c();
        custInv4.Company__c = cidata.co.id;
        custInv4.Invoice_Type__c = 'Miscellaneous';
        custInv4.Date_Invoiced__c = System.now();
        //Added Bill To for field filters
        custInv4.Bill_To_Customer__c = cidata.fuel.customerBillTo.id;
        custInv4.Sold_to_customer__c = cidata.fuel.customerSoldTo.Id;
        custInv4.transaction_date__c = system.now();
        custInv4.Batch_Job_ID__c ='70737000006564mAAA';
        custInv4.status__c = 'Cancelled'; 
        insert custInv4; 
        
        cidata.custInvAEList.add(custInv4);
        
        Customer_Invoice_Line__c custInvLine6 = new Customer_Invoice_Line__c();
        custInvLine6.Quantity_Shipped__c = -3;
        custInvLine6.subtransaction_type__c = null;
        custInvLine6.Company__c = cidata.co.id;
        custInvLine6.Unit_Price__c = 9;
        custInvLine6.Product__c = cidata.prod.Id ; 
        custInvLine6.Customer_Invoice__c = custInv4.id;
        insert custInvLine6; 

        cidata.custInvLineList.add(custInvLine6);

        List<customer_invoice__c> ciListinBatch =  [select id,Status__c from customer_invoice__c where Batch_Job_ID__c ='70737000006564mAAA'];
        system.assertEquals(ciListinBatch.size(),4); // 3- Open CI and 1- Cancelled CIs
        
        List<customer_invoice__c> cisListBeforeBatchexec  =  [select id,Status__c from customer_invoice__c where Batch_Job_ID__c ='70737000006564mAAA' and status__c = 'Open'];
        system.assertEquals(cisListBeforeBatchexec.size(),3); // 3- Open CIs in the list, Eligible for the batch
        
        Test.startTest(); 
        database.executeBatch(new CustomerInvoiceVoidCancelBatch('Cancel','70737000006564mAAA',String.valueOf(System.now())),10); 
        Test.stopTest();
        
        List<customer_invoice__c> cancelledCIsListAfterBatch =  [select id,Status__c from customer_invoice__c where Batch_Job_ID__c ='70737000006564mAAA' and status__c = 'Cancelled'];
        system.assertEquals(cancelledCIsListAfterBatch.size(),4); // 4 CI's(All) cancelled in the list
         
        List<customer_invoice__c> openCIsListAfterBatch  =  [select id,Status__c from customer_invoice__c where Batch_Job_ID__c ='70737000006564mAAA' and status__c = 'Open'];
        system.assertEquals(openCIsListAfterBatch.size(),0); // 0- Open CIs in the list
        
    }
    
    
}