@isTest public class CreditProfileTest {
	public class custInvoiceData{
		//TestData data = new TestData();
		Testfuel data = new Testfuel();
		List<Period__c> periodList = data.periodList;
		Accounting_Default__c testDefault = new Accounting_Default__c();
		{
	        	testDefault.Company__c = data.company.id;
	        	//testDefault.GL_Account__c = data.cashGL.id;
	        
	        	insert testDefault;
        }
        
	 	Customer_Invoice__c custInv1, custInv2, custInv3;
	 	
	 	List<Customer_Invoice__c> custInvAEList = new List<Customer_Invoice__c>();
	 	{
			custInv1 = new Customer_Invoice__c();
		    custInv1.Company__c = data.company.id;
		    custInv1.Invoice_Type__c = 'Ship Invoice';
		    custInv1.Date_Invoiced__c = System.now();
		    custInv1.transaction_date__c = system.now();
		    custInv1.Currency__c = TestFuel.currencyUSD.id;
		    custInv1.Sold_to_customer__c = data.customerSoldTo.id;
		    //Added Bill To for field filters
		    custInv1.Bill_To_Customer__c = data.customerBillTo.id;
		    custInv1.Subtotal__c = 0;
		    custInv1.Sales_Order__c = data.salesOrder.id;
		    custInvAEList.add(custInv1);
		    
		    custInv2 = new Customer_Invoice__c();
		    custInv2.Company__c = data.company.id;
		    custInv2.Invoice_Type__c = 'Ship Invoice';
		    custInv2.Date_Invoiced__c = System.now();
		    custInv2.transaction_date__c = system.now();
		    custInv2.Currency__c = TestFuel.currencyUSD.id;
		    custInv2.Sold_to_customer__c = data.customerSoldTo.id;
		     //Added Bill To for field filters
		    custInv2.Bill_To_Customer__c = data.customerBillTo.id;
		    custInv2.Subtotal__c = 0;
		    custInv2.Sales_Order__c = data.salesOrder.id;
		    custInvAEList.add(custInv2);
		    
		    custInv3 = new Customer_Invoice__c();
		    custInv3.Company__c = data.company.id;
		    custInv3.Invoice_Type__c = 'Miscellaneous';
		    custInv3.Date_Invoiced__c = System.now();
		    custInv3.transaction_date__c = system.now();
		    custInv3.Currency__c = TestFuel.currencyUSD.id;
		    custInv3.Sold_to_customer__c = data.customerSoldTo.id;
		     //Added Bill To for field filters
		    custInv3.Bill_To_Customer__c = data.customerBillTo.id;
		    custInv3.Accounting_Segment__c = testDefault.id;
		    custInvAEList.add(custInv3);
		    
		    insert custInvAEList;
	 	}
	    
	    List<Customer_Invoice_Line__c> custInvLineList = new List<Customer_Invoice_Line__c>();
	    {
		    	accounting_default__c accdef = new accounting_default__c();
		    	accdef.company__c = data.company.id;
		    	//accdef.gl_account__c = data.acctData.cashGL.id;
		    	insert accdef;
		    	
		    Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
		    custInvLine1.Quantity_Shipped__c = 2;
		    custInvLine1.Company__c = data.company.id;
		    //custInvLine1.Sales_Order_Line__c = data.SalesOrderLineList[0].id;
		    custInvLine1.Unit_Price__c = 7;
		    //custInvLine1.Sales_Order__c = data.salesOrder1.id;
		    custInvLine1.Product__c = data.product.id ; 
		    custInvLine1.Discount_Percent__c = 2;
		    custInvLine1.Customer_Invoice__c = custInvAEList[0].id;
		    custInvLineList.add(custInvLine1);
		    Customer_Invoice_Line__c custInvLine2 = new Customer_Invoice_Line__c();
		    custInvLine2.Quantity_Shipped__c = 3;
		    custInvLine2.Company__c = data.company.id;
		    //custInvLine2.Sales_Order_Line__c = data.SalesOrderLineList[1].id;
		    custInvLine2.Unit_Price__c = 9;
		    //custInvLine2.Sales_Order__c = data.salesOrder1.id;
		    custInvLine2.Product__c = data.product.id ; 
		    custInvLine2.Discount_Percent__c = 2;
		    custInvLine2.Customer_Invoice__c = custInvAEList[0].id;
		    custInvLineList.add(custInvLine2);
		    Customer_Invoice_Line__c custInvLine3 = new Customer_Invoice_Line__c();
		    custInvLine3.Quantity_Shipped__c = 2;
		    custInvLine3.Company__c = data.company.id;
		    //custInvLine3.Sales_Order_Line__c = data.SalesOrderLineList[2].id;
		    custInvLine3.Unit_Price__c = 7;
		    //custInvLine3.Sales_Order__c = data.salesOrder2.id;
		    custInvLine3.Product__c = data.product.id ; 
		    custInvLine3.Discount_Percent__c = 2;
		    custInvLine3.Customer_Invoice__c = custInvAEList[1].id;
		    custInvLineList.add(custInvLine3);
		    Customer_Invoice_Line__c custInvLine4 = new Customer_Invoice_Line__c();
		    custInvLine4.Quantity_Shipped__c = 3;
		    custInvLine4.Company__c = data.company.id;
		    //custInvLine4.Sales_Order_Line__c = data.SalesOrderLineList[3].id;
		    custInvLine4.Unit_Price__c = 9;
		    //custInvLine4.Sales_Order__c = data.salesOrder2.id;
		    custInvLine4.Product__c = data.product.id ; 
		    custInvLine4.Discount_Percent__c = 2;
		    custInvLine4.Customer_Invoice__c = custInvAEList[1].id;
		    custInvLineList.add(custInvLine4);
		    
		    Customer_Invoice_Line__c custInvLine5 = new Customer_Invoice_Line__c();
		    custInvLine5.Quantity_Shipped__c = -3;
		    custInvLine5.accounting_segment__c = accdef.id;
		    custInvLine5.Company__c = data.company.id;
		    custInvLine5.Unit_Price__c = 9;
		    custInvLine5.Product__c = data.product.id ; 
		    custInvLine5.Customer_Invoice__c = custInvAEList[2].id;
		    custInvLineList.add(custInvLine5);
		    
		    insert custInvLineList;
		    
		    for(Customer_Invoice__c thisInv: custInvAEList){
		    	thisInv.finalized__c = true;
		    }
		    update custInvAEList;
	    }
		
		Set<Id> invoiceIds = new Set<Id>();{
		    for(Customer_Invoice__c invoice: custInvAEList){
		        invoiceIds.add(invoice.id);
		    }
		}
	}

	public static testMethod void SO_ExceedsCreditLimit() {
		TestFuel fuel = new TestFuel();
		system.assertNotEquals(null, fuel.customerParent.Id);
		system.assertNotEquals(null, fuel.salesOrder.Id);

		Customer__c top = fuel.customerParent;
		top.Open_Sales_Orders__c = 100000;
		top.Risk_Class__c = 'A';
		top.Credit_Limit__c = 90000;
		update top;

		Credit_Profile_Rules__c cp = new Credit_Profile_Rules__c();
		cp.name='A'; cp.Percent_Over_Credit__c = 5;
		insert cp;

		boolean soOnCreditHold = new CreditProfile().willOrderExceedCreditLimits(fuel.salesOrder.Id);
		system.assertEquals(true, soOnCreditHold);

		top.Credit_Limit__c = 0;
		update top;

		soOnCreditHold = false;
		soOnCreditHold = new CreditProfile().willOrderExceedCreditLimits(fuel.salesOrder.Id);
		system.assertEquals(true, soOnCreditHold);



	}
    
    public static testmethod void t1() { 
		custInvoiceData data = new custInvoiceData();
        Test.startTest();
        //system.debug(LoggingLevel.INFO,data.data.customer_corp);
		Customer__c top = data.data.customerParent;
		top.Open_Sales_Orders__c = 100000; 
		top.Risk_Class__c = 'A';
		top.Credit_Limit__c = 90000;
		
		// the top parent is null at corp level
		update top;
		Credit_Profile_Rules__c cp = new Credit_Profile_Rules__c(); 
		cp.name='A'; cp.Percent_Over_Credit__c = 5;
		insert cp; 
		
		//test for criteria 1
		//system.debug(LoggingLevel.INFO,[select id, Outstanding_Balance2__c from Customer__c     where id = :top.id limit 1] );
		Process_Automation__c pa = new Process_Automation__c(); 
		pa.name='foo'; pa.Object_name__c  = 'Customer__c';
		insert pa; 
		
		top = [ select id,Outstanding_Balance2__c,
					 	Risk_Class__c,Credit_Limit__c, credit_hold__c
					  	from Customer__c     where id = :top.id limit 1];
		
		
		new CreditProfile().processRecords(pa, new list<sobject>{top});  
		
		sobject tmp = [select id,credit_hold__c, Outstanding_Balance2__c 
								from Customer__c     where id = :top.id limit 1] ;
		//system.debug(LoggingLevel.INFO,tmp); 		
		system.assert((boolean)tmp.get('Credit_Hold__c')==true, ' expected a hold');
		
		
		top.Credit_Limit__c = 98000;
		update top;
		
		
		new CreditProfile().processRecords(pa, new list<sobject>{top});
		tmp = [select id,credit_hold__c, Outstanding_Balance2__c 
								from Customer__c     where id = :top.id limit 1] ;
		//system.debug(LoggingLevel.INFO,tmp); 		
		system.assert((boolean)tmp.get('Credit_Hold__c')==false, ' expected NO hold');
		
		// test for criteria 2
		cp.AR_Percent_Past_Due__c = 5;
        update cp;
		
		top.Open_Past_Due__c = 90000;
		update top;
		
		new CreditProfile().processRecords(pa, new list<sobject>{top});
		tmp = [select id,credit_hold__c, Outstanding_Balance2__c 
								from Customer__c     where id = :top.id limit 1] ;
		//system.debug(LoggingLevel.INFO,tmp); 		
		system.assert((boolean)tmp.get('Credit_Hold__c')==true, ' expected a hold'); 
		
		top.Open_Past_Due__c = 2000;
		update top;
		
		new CreditProfile().processRecords(pa, new list<sobject>{top});
		tmp = [select id,credit_hold__c, Outstanding_Balance2__c 
								from Customer__c     where id = :top.id limit 1] ;
		//system.debug(LoggingLevel.INFO,tmp); 		
		system.assert((boolean)tmp.get('Credit_Hold__c')==false, ' expected NO hold'); 
		 
		// test for criteria 3
		cp.Days_Past_Due__c = 5;
        update cp;
		
		top.Days_Past_Due_Max__c = 9;
		update top;
		
		new CreditProfile().processRecords(pa, new list<sobject>{top});
		tmp = [select id,credit_hold__c, Outstanding_Balance2__c 
								from Customer__c     where id = :top.id limit 1] ;
		//system.debug(LoggingLevel.INFO,tmp); 		
		system.assert((boolean)tmp.get('Credit_Hold__c')==true, ' expected a hold'); 
		
		top.Days_Past_Due_Max__c = 2;
		update top;
		
		new CreditProfile().processRecords(pa, new list<sobject>{top});
		tmp = [select id,credit_hold__c, Outstanding_Balance2__c 
								from Customer__c     where id = :top.id limit 1] ;
		//system.debug(LoggingLevel.INFO,tmp); 		
		system.assert((boolean)tmp.get('Credit_Hold__c')==false, ' expected NO hold');

		top.Credit_Limit__c = 0;
		update top;
		new CreditProfile().processRecords(pa, new list<sobject>{top});
		tmp = [select id,credit_hold__c, Outstanding_Balance2__c
		from Customer__c     where id = :top.id limit 1] ;
		//system.debug(LoggingLevel.INFO,tmp);
		system.assert((boolean)tmp.get('Credit_Hold__c')==true, ' expected NO hold');
	}
	
}