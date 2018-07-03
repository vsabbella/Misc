@isTest
private class CustomerInvoiceAccountingTest {
	@testSetup static void ts() { 
		TestFuel data = new TestFuel();	
		// these asserts cause TestFuelQuery to insert data
		system.assert(		
			data.company != null &&
			data.customerSoldTo != null &&
			data.customerBillTo != null &&
			data.product != null &&
			data.product2 != null &&
			data.periodList != null &&
			data.salesOrder != null &&
			data.salesOrderLines != null &&
			data.terms != null &&
			data.uomList != null
						
		);
		system.assert(data.cashGL != null &&
			data.receivablesGL != null &&
			data.custInv1 != null &&
			data.accountingStandard != null);
	}
	
	class CIAccountingTestData {
        public CIAccountingTestData() {}
	    	public datetime effStartDate{
	        get{
		            if(effStartDate==null)
		            {
		                //Give the earliest eff date possible - Previous yr used to make sure Transactions created are in effectivity range of accounting rules.
		                return datetime.newInstance(system.now().year()-1, 1, 1, 0, 0, 0);
		            }
		            else
		            {
		                return effStartDate;
		            }
	         }set;
	    }
	}
    // Test Customer Invoice Accounting
 	public static testMethod void testCustInvAccounting() {
 	 	//TestDataForFinance data = new TestDataForFinance();
 	 	TestfuelQuery data = new TestfuelQuery();
		Test.startTest();
	    
     	Sales_Order__c salesOrder2=new Sales_Order__c();
     	Sales_Order__c salesOrder3=new Sales_Order__c();
     
     	salesOrder2.Customer__c = data.customerSoldTo.id;
        salesOrder2.Currency__c = data.company.Default_Transaction_Currency__c ;
        salesOrder2.Status__c='Open';
        salesOrder2.Type__c = 'Special';
        salesOrder2.Payment_Term__c = data.terms.id;
        salesOrder2.company__c = data.company.id;
        salesOrder2.Weight_UOM__c = data.uomList[0].ID;
    	salesOrder2.Dimension_UOM__c = data.uomList[5].ID;
    	salesOrder2.Original_Sales_Order__c = 'salesOrder2';
    
        salesOrder3.Customer__c = data.customerSoldTo.id;
        salesOrder3.Currency__c = data.company.Default_Transaction_Currency__c ;
        salesOrder3.Status__c='Open';
        salesOrder3.Type__c = 'Adjustment';
        salesOrder3.Payment_Term__c = data.terms.id;
        salesOrder3.company__c = data.company.id;
        salesOrder3.Weight_UOM__c = data.uomList[0].ID;
    	salesOrder3.Dimension_UOM__c = data.uomList[5].ID;
    	salesOrder3.Original_Sales_Order__c = 'salesOrder3';
     	
     	insert new List<Sales_Order__c> { salesOrder2,salesOrder3 } ;
     	
	    List<Customer_Invoice_Line__c> custInvLineList1 = new List<Customer_Invoice_Line__c>();
	    List<Customer_Invoice_Line__c> custInvLineList2 = new List<Customer_Invoice_Line__c>();
	    List<Customer_Invoice__c> custInvAEList = new List<Customer_Invoice__c>();
	    
	    accounting_default__c accdef = new accounting_default__c();
		accdef.company__c = data.company.id;		
		accdef.gl_account__c = data.cashGL.id;//data.acctData.cashGL.id;
		insert accdef;
		
		string custInvName = SchemaUtil.getInstance().getLocalNameFromObject(new Customer_Invoice__c());
		
	    Customer_Invoice__c custInv1 = new Customer_Invoice__c();
	    custInv1.Company__c = data.company.id;
	    custInv1.Invoice_Type__c = 'Ship Invoice';
	    custInv1.Date_Invoiced__c = System.today();
	    custInv1.Sold_To_Customer__c = data.customerSoldTo.id;
	    custInv1.Bill_To_Customer__c = data.customerbillto.id;
	    custInv1.Subtotal__c = 0;
	    custInv1.Sales_Order__c = data.salesOrder.id;
	    custInv1.transaction_date__c = system.now();
	    custInv1.Currency__c = data.company.Default_Transaction_Currency__c;
	    custInvAEList.add(custInv1);
	    
	    Customer_Invoice__c custInv2 = new Customer_Invoice__c();
	    custInv2.Company__c = data.company.id;
	    custInv2.Invoice_Type__c = 'Ship Invoice';
	    custInv2.Date_Invoiced__c = System.today();
	    custInv2.Sold_To_Customer__c = data.customerSoldTo.id;
	    custInv2.Bill_To_Customer__c = data.customerbillto.id;
	    custInv2.Subtotal__c = 0;
	    custInv2.Sales_Order__c = salesOrder2.id;
	    custInv2.transaction_date__c = system.now();
	    custInv2.Currency__c = data.company.Default_Transaction_Currency__c;
	    custInvAEList.add(custInv2);
	    
	    Customer_Invoice__c custInv3 = new Customer_Invoice__c();
	    custInv3.Company__c = data.company.id;
	    //custInv3.Invoice_Type__c = 'Credit Memo';
	    custInv3.Invoice_Type__c = 'Miscellaneous Credit';
	    //custInv3.Credit_Memo_Type__c = 'On Account';
	    custInv3.Date_Invoiced__c = System.today();
	    custInv3.Sold_To_Customer__c = data.customerSoldTo.id;
	    custInv3.Bill_To_Customer__c = data.customerbillto.id;
	    custInv3.Subtotal__c = 0;
	    custInv3.Currency__c = data.company.Default_Transaction_Currency__c;	    
	    custInv3.transaction_date__c = system.now();
		custInv3.finalized_date__c = system.now();
		custInvAEList.add(custInv3);
	    
		Customer_Invoice__c custInv4 = new Customer_Invoice__c();
	    custInv4.Company__c = data.company.id;
	    custInv4.Invoice_Type__c = 'Adjustment';
	    custInv4.Date_Invoiced__c = System.today();
	    custInv4.Sold_To_Customer__c = data.customerSoldTo.id;
	    custInv4.Bill_To_Customer__c = data.customerbillto.id;
	    //custInv4.Subtotal__c = -80;
	    //custInv4.Deduction_Amount__c = 80;
	    custInv4.Sales_Order__c = salesOrder3.id;
	    custInv4.Currency__c = data.company.Default_Transaction_Currency__c;
	    custInv4.transaction_date__c = system.now();
	    custInvAEList.add(custInv4);
	    
	    Customer_Invoice__c custInv5 = new Customer_Invoice__c();
	    custInv5.Company__c = data.company.id;
	    //custInv5.Invoice_Type__c = 'Credit Memo';
	    custInv5.Invoice_Type__c = 'Prepayment';
	    //custInv5.Credit_Memo_Type__c = 'Prepayment';
	    custInv5.Date_Invoiced__c = System.today();
	    custInv5.Sold_To_Customer__c = data.customerSoldTo.id;
	    custInv5.Bill_To_Customer__c = data.customerbillto.id;
	    custInv5.Subtotal__c = 0;
	    custInv5.Currency__c = data.company.Default_Transaction_Currency__c;
	    custInv5.transaction_date__c = system.now();
	    custInvAEList.add(custInv5);
	    
	    
	    // insert all the headers at one go
	    insert new list<sobject>{custInv1, custInv2, custInv3, custInv4, custInv5};
	    
        list <Customer_Invoice_line__c> cilines = new List<Customer_Invoice_line__c>();
	    Customer_Invoice_Line__c custInvLine11 = new Customer_Invoice_Line__c();
	    custInvLine11.Company__c = data.company.id;
	    custInvLine11.Quantity_Shipped__c = 2;
	    custInvLine11.Unit_Price__c = 7;
	    custInvLine11.Product__c = data.product.id ; 
	    custInvLine11.Discount_Percent__c = 0.2;
	    custInvLine11.Customer_Invoice__c = custInv1.id;
	    custInvLine11.Extended_Price__c = custInvLine11.Quantity_Shipped__c * custInvLine11.Unit_Price__c;
		cilines.add(custInvLine11);
	    
	    Customer_Invoice_Line__c custInvLine12 = new Customer_Invoice_Line__c();
	    custInvLine12.Company__c = data.company.id;
	    custInvLine12.Quantity_Shipped__c = 3;
	    custInvLine12.Unit_Price__c = 9;
	    custInvLine12.Product__c = data.product.id ; 
	    custInvLine12.Discount_Percent__c = 0.2;
	    custInvLine12.Customer_Invoice__c = custInv1.id;
		custInvLine12.Extended_Price__c = custInvLine12.Quantity_Shipped__c * custInvLine12.Unit_Price__c;
		cilines.add(custInvLine12);
	    
	    Customer_Invoice_Line__c custInvLine21 = new Customer_Invoice_Line__c();
	    custInvLine21.Company__c = data.company.id;
	    custInvLine21.Quantity_Shipped__c = 2;
	    custInvLine21.Unit_Price__c = 7;
	    custInvLine21.Product__c = data.product.id ; 
	    custInvLine21.Discount_Percent__c = 0.2;
	    custInvLine21.Customer_Invoice__c = custInv2.id;
	    custInvLine21.Extended_Price__c = custInvLine21.Quantity_Shipped__c * custInvLine21.Unit_Price__c;
		cilines.add(custInvLine21);
	    
	    Customer_Invoice_Line__c custInvLine22 = new Customer_Invoice_Line__c();
	    custInvLine22.Company__c = data.company.id;
	    custInvLine22.Quantity_Shipped__c = 3;
	    custInvLine22.Unit_Price__c = 9;
	    custInvLine22.Product__c = data.product.id ; 
	    custInvLine22.Discount_Percent__c = 0.2;
	    custInvLine22.Customer_Invoice__c = custInv2.id;
	    custInvLine22.Extended_Price__c = custInvLine22.Quantity_Shipped__c * custInvLine22.Unit_Price__c;
		cilines.add(custInvLine22);
	    
	    Customer_Invoice_Line__c custInvLine31 = new Customer_Invoice_Line__c();
		custInvLine31.Quantity_Shipped__c = 10;
		//custInvLine31.accounting_segment__c = accdef.id;
		custInvLine31.Company__c = data.company.id;
		custInvLine31.Unit_Price__c = -10;
		custInvLine31.Product__c = data.product.id ; 
		custInvLine31.Customer_Invoice__c = custInv3.id;
		custInvLine31.Extended_Price__c = custInvLine31.Quantity_Shipped__c * custInvLine31.Unit_Price__c;
		cilines.add(custInvLine31);
	    
	    Customer_Invoice_Line__c custInvLine41 = new Customer_Invoice_Line__c();
	    custInvLine41.Company__c = data.company.id;
	    custInvLine41.Quantity_Shipped__c = -2;
	    custInvLine41.Unit_Price__c = 40;
	    custInvLine41.Product__c = data.product.id ; 
	    custInvLine41.Customer_Invoice__c = custInv4.id;
	    custInvLine41.Line_Type__c = 'Deduction Credit';
	    custInvLine41.Extended_Price__c = custInvLine41.Quantity_Shipped__c * custInvLine41.Unit_Price__c;
		cilines.add(custInvLine41);
	    
	    
	    Customer_Invoice_Line__c custInvLine51 = new Customer_Invoice_Line__c();
		custInvLine51.Quantity_Shipped__c = 10;
		//custInvLine51.accounting_segment__c = accdef.id;
		custInvLine51.Product__c = data.product.id ; 
		custInvLine51.Company__c = data.company.id;
		custInvLine51.Unit_Price__c = -10;
		custInvLine51.Customer_Invoice__c = custInv5.id;
		custInvLine51.Extended_Price__c = custInvLine51.Quantity_Shipped__c * custInvLine51.Unit_Price__c;
		cilines.add(custInvLine51);
		
		// insert all the lines at one go, consumes fewer queries in the rollup process
		insert cilines;   
	
	    
	    for(Customer_Invoice__c thisInv: custInvAEList){
	    	thisInv.finalized__c = true;
	    }
	    
	    update custInvAEList;
	    
	    custInv1 = [Select id, Name, Finalized__c, Finalized_hidden__c
	    			from Customer_Invoice__c
	    			where id = :custInv1.id];
	    system.assertEquals(true, custInv1.Finalized__c);
	    //system.assertEquals(true, custInv1.Finalized_hidden__c);
	    
	    boolean sawException = false;
	    try{
	    	custInv1.Finalized__c = false;
	    	update custInv1;
	    }catch(Exception e){
	    	sawException = true;
	    }
	    
	    system.assertEquals(true, sawException);
		system.assertEquals(5, custInvAEList.size(), 'We should see 5 invoices submitted for accounting');
		
	    CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
	    Test.stopTest();
	    cia.execute(cilines);
	    
	    
	    Set<Id> custInvIds = KSE.grepIdSetFromList(custInvAEList) ;
	    
	    List<Accounting_Entry__c> acctEntries = [SELECT id, Name, Customer_Invoice__c, COMP_Total_Credit__c, COMP_Total_Debit__c, Transaction_Type__c, Customer__c,
	    										(SELECT id, Name, Subtransaction_Type__c, Line_Type__c FROM Accounting_Entry_Lines__r)
	                                            FROM Accounting_Entry__c 
	                                            WHERE (Customer_Invoice__c IN :custInvIds)];
	    
	    Map<Id, Accounting_Entry__c> mAEs = new Map<Id, Accounting_Entry__c>();
	    for(Accounting_Entry__c ae : acctEntries){
    		mAEs.put(ae.customer_invoice__c, ae);
	    }
	    

	    system.debug('acctEntries: ' + acctEntries.size() + ' - ' +  acctEntries);   
	    system.assertNotEquals(null, acctEntries);
	    // TODO: SK retest these asserts when the accounting rules are modified to populate the COMP Ledger
	    system.assertEquals(mAEs.get(custInv1.ID).COMP_Total_Credit__c, mAEs.get(custInv1.Id).COMP_Total_Debit__c, mAEs.get(custInv1.ID));
	    //system.assertEquals(41, mAEs.get(custInv1.ID).COMP_Total_Credit__c, mAEs.get(custInv1.ID));
	    //system.assertNotEquals(0, mAEs.get(custInv1.ID).COMP_Total_Debit__c, mAEs.get(custInv1.ID));
	    //system.assertEquals(41, mAEs.get(custInv1.ID).COMP_Total_Debit__c, mAEs.get(custInv1.ID));
	   
	    system.assert(mAEs.containsKey(custInv1.Id));
	    system.assert(mAEs.containsKey(custInv2.Id));
	    system.assert(mAEs.containsKey(custInv3.Id));
	    system.assert(mAEs.containsKey(custInv4.Id));
	    system.assert(mAEs.containsKey(custInv5.Id));
	    system.assertEquals(5, acctEntries.size(), 'We should have 5 accounting entries generated');
	    
	    
	    system.assertEquals('Adjustment', mAEs.get(custInv4.id).Transaction_Type__c);
	    system.assertEquals('Deduction Credit', mAEs.get(custInv4.id).Accounting_Entry_Lines__r[0].Line_Type__c );
	    system.assertEquals('Deduction Credit', mAEs.get(custInv4.id).Accounting_Entry_Lines__r[1].Line_Type__c );
	    Integer listsize = acctEntries.size();
	    for(Integer i=0; i< listsize; i++){
	    	system.assertEquals( data.customerbillto.id, acctEntries[i].Customer__c);
	    }
	   
	    
	    system.assertEquals('Miscellaneous Credit', mAEs.get(custInv3.id).Transaction_Type__c);
	    listsize = acctEntries.size();
	    for(Integer i=0; i< listsize; i++){
	    	system.assertEquals( data.customerbillto.id ,acctEntries[i].Customer__c);
	    }

	    
		system.assertEquals(custInv5.id, mAEs.get(custInv5.id).Customer_Invoice__c);
	    system.assertEquals('Prepayment', mAEs.get(custInv5.id).Transaction_Type__c);
	    
 	}
 	
 	//1. Create header missing company, transaction currency , transaction date 
	//2. Create header without line and finalize it 
	//3. create header and one line finalize
	//4. update line created in step3
	//5. add new line to the header created in step3
	//6. delete new line created in step 5
	//7. undelete line deleted in step 6 
		
	static testmethod void testCIHeaderFinalize(){
		
		TestFuelQuery data = new TestFuelQuery();

	   	Customer_Invoice__c custInv1 = new Customer_Invoice__c();
	    custInv1.Invoice_Type__c = 'Ship Invoice';
	    custInv1.Date_Invoiced__c = System.today();
	    custInv1.Sold_To_Customer__c = data.customerSoldTo.id;
	    custInv1.Bill_To_Customer__c = data.customerbillto.id;
	    custInv1.Subtotal__c = 0;
	    custInv1.Sales_Order__c = data.salesOrder.id;
	    custInv1.transaction_date__c = system.now();
	    custInv1.Currency__c = data.company.Default_Transaction_Currency__c;
	    
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
	   	custInv1.Company__c = data.company.id;
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
	   	custInv1.Currency__c = data.company.Default_Transaction_Currency__c;
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
	
	
	static testmethod void testCIPostingDate(){
		TestFuelQuery data = new TestFuelQuery();
		
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now().addDays(10);
        custInvoice1.transaction_date__c = system.now().addDays(10);
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = data.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
     
     	custInvoice1.Finalized__c = true;
     	update  custInvoice1;
     	
     	custInvoice1 = [Select id, Finalized_Date__c, Posting_Date__c, Transaction_Date__c
     										from Customer_Invoice__c
     										where id = :custInvoice1.id];
     	
     	system.assertEquals(custInvoice1.Transaction_Date__c, custInvoice1.Posting_Date__c);
     	
     	custInvoice1.Finalized__c = false;
     	custInvoice1.Finalized_hidden__c = false;
     	update custInvoice1;
     	
     	custInvoice1.Date_Invoiced__c = System.now().addDays(-10);
        custInvoice1.transaction_date__c = system.now().addDays(-10);
     	
     	custInvoice1 = [Select id, Finalized_Date__c, Posting_Date__c, Transaction_Date__c
     										from Customer_Invoice__c
     										where id = :custInvoice1.id];
     	
     	system.assertEquals(custInvoice1.Finalized_Date__c, custInvoice1.Posting_Date__c);
     	
	}
	
	static testmethod void testCRLineUpdate(){
		TestFuelQuery data = new TestFuelQuery();
		//Company__c company = fuel.company;
		
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = data.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
     
     	custInvoice1.Finalized__c = true;
     	update  custInvoice1;
	    
	    Test.startTest();
	    String exMsg = null;
	    boolean sawException = false;
	    try{
	    	ciLine1.product__c = data.product2.id; // product field exists in finalize field set which is not meant to be modified after doc is finalized
	    	update ciLine1; 
	    }catch(Exception ex){
	    	exMsg = ex.getMessage();
	    	sawException = true;
	    }
	    Test.stopTest();
	    
	    system.assert(sawException, 'We are expecting to see an exception for attempting to edit a line of a finalized doc ' + exMsg);
	}
	
	static testmethod void testCILineInsert(){
		TestFuelQuery data = new TestFuelQuery();

	   	Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = data.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
            
        insert ciLine1;        
     
     	custInvoice1.Finalized__c = true;
     	update  custInvoice1;
     	
	   	Customer_Invoice_Line__c ciLine2 = new Customer_Invoice_Line__c();
        ciLine2.Quantity_Shipped__c = 5;
        ciLine2.Company__c = data.company.id;
        ciLine2.Sales_Order_Line__c = data.salesOrderLine.id;
        ciLine2.Unit_Price__c = 10;
        ciLine2.Sales_Order__c = data.salesOrder.id;
        ciLine2.Product__c = data.product.id ; 
        ciLine2.Discount_Percent__c = data.salesOrderLine2.Discount_Percent__c;
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
	
	static testmethod void testCILineDelete(){
		TestFuelQuery data = new TestFuelQuery();
		
	   	Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = data.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLine.Discount_Percent__c;
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
	
	static testmethod void testCILineUndelete(){
		TestFuelQuery data = new TestFuelQuery();

	   	Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = System.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = data.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        List<Customer_Invoice_Line__c> ciLineList = new List<Customer_Invoice_Line__c>();
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
        ciLineList.add(ciLine1);
        
        Customer_Invoice_Line__c ciLine2 = new Customer_Invoice_Line__c();
        ciLine2.Quantity_Shipped__c = 5;
        ciLine2.Company__c = data.company.id;
        ciLine2.Sales_Order_Line__c = data.salesOrderLine2.id;
        ciLine2.Unit_Price__c = 10;
        ciLine2.Sales_Order__c = data.salesOrder.id;
        ciLine2.Product__c = data.product.id ; 
        ciLine2.Discount_Percent__c = data.salesOrderLine2.Discount_Percent__c;
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
 	
 	
 	/*
 	This test is being disabled whilst RFX is being re-designed
 	
 	static testMethod void testRFX(){
 		
 		TestFuel data = new TestFuel();
 		List<Period__c> periodList = data.periodList;
 		TestData.Accounting accting = new TestData.Accounting(data.company.Id);
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
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = baseDT.addHours(-6);
        custInvoice1.transaction_date__c = baseDT.addHours(-6);
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = data.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Manual';
        
        Customer_Invoice__c custInvoice2 = new Customer_Invoice__c();
        custInvoice2.Company__c = data.company.id;
		custInvoice2.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice2.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice2.Sales_Order__c = data.salesOrder.Id;
        custInvoice2.Date_Invoiced__c = baseDT.addHours(-1);
        custInvoice2.transaction_date__c = baseDT.addHours(-1);
        custInvoice2.status__c = 'Open';
        custInvoice2.Currency__c = data.company.Default_Transaction_Currency__c;
        custInvoice2.Invoice_Type__c = 'Ship Invoice';
        
        insert  new List<Customer_Invoice__c>{custInvoice1, custInvoice2};
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Taxable__c = data.salesOrderLines[0].Taxable__c;
        ciLine1.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
        
        Customer_Invoice_Line__c ciLine2 = new Customer_Invoice_Line__c();
        ciLine2.Quantity_Shipped__c = 5;
        ciLine2.Company__c = data.company.id;
        ciLine2.Sales_Order_Line__c = data.salesOrderLines[0].id;
        ciLine2.Unit_Price__c = 10;
        ciLine2.Sales_Order__c = data.salesOrder.id;
        ciLine2.Product__c = data.product.id ; 
        ciLine2.Taxable__c = data.salesOrderLines[0].Taxable__c;
        ciLine2.Discount_Percent__c = data.salesOrderLines[0].Discount_Percent__c;
        ciLine2.Customer_Invoice__c = custInvoice2.Id; 
        
        
        insert new List<Customer_Invoice_Line__c>{ciLine1, ciLine2};   
        
        custInvoice1.Finalized__c = true;
        custInvoice2.Finalized__c = true;
        update new List<Customer_Invoice__c>{custInvoice1, custInvoice2};
        
        Exchange_Rate__c exchangeRate1, exchangeRate2, exchangeRate3;
        exchangeRate1= new Exchange_Rate__c();
        exchangeRate1.Active__c = true;
        exchangeRate1.From_Currency__c = data.company.Default_Transaction_Currency__c;
        exchangeRate1.Currency_To__c = TestFuel.currencySGD.id;
        exchangeRate1.Daily_Monthly__c = 'Daily';
        exchangeRate1.Multiplier_Exchange_Rate__c = 1.250000;
        exchangeRate1.rate_start_datetime__c = baseDT.addHours(-12);
        exchangeRate1.rate_end_datetime__c = baseDT.addHours(-3); 
        
        exchangeRate2= new Exchange_Rate__c();
        exchangeRate2.Active__c = true;
        exchangeRate2.From_Currency__c = data.company.Default_Transaction_Currency__c;
        exchangeRate2.Currency_To__c = TestFuel.currencySGD.id;
        exchangeRate2.Daily_Monthly__c = 'Daily';
        exchangeRate2.Multiplier_Exchange_Rate__c = 1.290000;
        exchangeRate2.rate_start_datetime__c = baseDT.addHours(-3);
        exchangeRate2.rate_end_datetime__c = baseDT.addHours(3); 
        
        exchangeRate3= new Exchange_Rate__c();
        exchangeRate3.Active__c = true;
        exchangeRate3.From_Currency__c = data.company.Default_Transaction_Currency__c;
        exchangeRate3.Currency_To__c = TestFuel.currencySGD.id;
        exchangeRate3.Daily_Monthly__c = 'Monthly';
        exchangeRate3.Multiplier_Exchange_Rate__c = 1.270000;
        exchangeRate3.rate_start_datetime__c = baseDT.addDays(-12);
        exchangeRate3.rate_end_datetime__c = baseDT.addDays(3);
        
        insert new List<Exchange_Rate__c>{exchangeRate1, exchangeRate2, exchangeRate3};
        
        Customer_Receipt__c cr1 = new Customer_Receipt__c();
        cr1.company__c = data.company.Id;
        cr1.customer__c = data.customerbillto.id;
        cr1.Date_Received__c = baseDT.addHours(-1);
        cr1.Transaction_Date__c = baseDT.addHours(-1);
        cr1.Type__c = 'Receipt';
        cr1.Currency__c = data.company.Default_Transaction_Currency__c;
        
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
 	}
 	*/
 	static testMethod void testAllowancesAccounting(){
 		
 		TestFuelQuery data = new TestFuelQuery();
 		CIAccountingTestData ciActingtd = new CIAccountingTestData();
 		Accounting_Rule__c arHdrApCR = new Accounting_Rule__c();
 		arHdrApCR.Accounting_Standard__c = data.accountingStandard.Id;
 		arHdrApCR.Object_Name__c = 'Customer_Invoice__c';
 		//arHdrApCR.Company__c = data.company.Id;
 		arHdrApCR.transaction__c = 'Ship Invoice';
 		arHdrApCR.Allocation_Type__c = 'Header';
 		arHdrApCR.Allocation__c = 'Manual';
 		arHdrApCR.Rule_Type__c = 'CR';
 		arHdrApCR.GL_Account__c = data.receivablesGL.Id;
 		arHdrApCR.Effective_Start_Date__c = ciActingtd.effStartDate;
 		arHdrApCR.Default_GL_Account__c = true;
 		
 		Accounting_Rule__c arHdrApDR = new Accounting_Rule__c();
 		arHdrApDR.Accounting_Standard__c = data.accountingStandard.Id;
 		arHdrApDR.Object_Name__c = 'Customer_Invoice__c'; 
 		//arHdrApDR.Company__c = data.company.Id;
 		arHdrApDR.transaction__c = 'Ship Invoice';
 		arHdrApDR.Allocation_Type__c = 'Header';
 		arHdrApDR.Allocation__c = 'Manual';
 		arHdrApDR.Rule_Type__c = 'DR';
 		arHdrApDR.Default_GL_Account__c = false;
 		arHdrApDR.Effective_Start_Date__c = ciActingtd.effStartDate; 		
 		arHdrApDR.GL_Account_Reference_Value__c = 'Customer_Invoice_Line__r.Product__r.Item__r.Class__r.Revenue_GL_Account__c';
 		
 		Accounting_Rule__c arLineApCR = new Accounting_Rule__c();
 		arLineApCR.Accounting_Standard__c = data.accountingStandard.Id;
 		arLineApCR.Object_Name__c = 'Customer_Invoice__c';
 		//arLineApCR.Company__c = data.company.Id;
 		arLineApCR.transaction__c = 'Ship Invoice';
 		arLineApCR.subtransaction_type__c = 'Goods';
 		arLineApCR.Allocation_Type__c = 'Line';
 		arLineApCR.Allocation__c = 'Manual';
 		arLineApCR.Rule_Type__c = 'CR';
 		arLineApCR.GL_Account__c = data.receivablesGL.Id;
 		arLineApCR.Effective_Start_Date__c = ciActingtd.effStartDate; 				
 		arLineApCR.Default_GL_Account__c = true;
 		
 		
 		Accounting_Rule__c arLineApDR = new Accounting_Rule__c();
 		arLineApDR.Accounting_Standard__c = data.accountingStandard.Id;
 		arLineApDR.Object_Name__c = 'Customer_Invoice__c';
 		//arLineApDR.Company__c = data.company.Id;
 		arLineApDR.transaction__c = 'Ship Invoice';
 		arLineApDR.subtransaction_type__c = 'Goods';
 		arLineApDR.Allocation_Type__c = 'Line';
 		arLineApDR.Allocation__c = 'Manual';
 		arLineApDR.Rule_Type__c = 'DR';
 		arLineApDR.Default_GL_Account__c = false;
 		arLineApDR.Effective_Start_Date__c = ciActingtd.effStartDate; 				 		
 		arLineApDR.GL_Account_Reference_Value__c = 'Customer_Invoice_Line__r.Product__r.Item__r.Class__r.Revenue_GL_Account__c';
 		
 		insert new List<Accounting_Rule__c>{arHdrApCR, arHdrApDR, arLineApCR, arLineApDR};
 		
 		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = system.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = data.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
        insert ciLine1;
        
        Allowance_Type__c aType = new Allowance_Type__c();
        aType.Name = 'Test Allowance Type';
        aType.Allowance_Class__c = 'Manual';
        aType.Basis__c = 'Flat';
        aType.Manual__c = true;
        aType.Allow_Override__c = true;
        insert aType;

        Allowance_Applied__c apHdr = new Allowance_Applied__c();

        apHdr.Customer_Invoice2__c = custInvoice1.Id;
        apHdr.Allowance_Type__c = aType.Id;
        apHdr.allowance_amount__c = 1;
        apHdr.Unique_Key__c = '1';
        apHdr.Allowance_Class__c = 'Manual';
        
        Allowance_Applied__c apLine = new Allowance_Applied__c();
        apLine.Allowance_Type__c = aType.Id;
        apLine.Customer_Invoice_Line__c = ciLine1.Id;
        apLine.allowance_amount__c = 2;
        apLine.Unique_Key__c = '2';
        apLine.Allowance_Class__c = 'Manual';
        
        //FIN-615
        Allowance_Applied__c apHdr2 = new Allowance_Applied__c();
        apHdr2.Allowance_Type__c = aType.Id;
        apHdr2.Customer_Invoice2__c = custInvoice1.Id;
        apHdr2.allowance_amount__c = 3;
        apHdr2.Unique_Key__c = '3';
        apHdr2.Allowance_Class__c = 'Manual';
        
        Allowance_Applied__c apLine2 = new Allowance_Applied__c();
        apLine2.Allowance_Type__c = aType.Id;
        apLine2.Customer_Invoice_Line__c = ciLine1.Id;
        apLine2.allowance_amount__c = 4;
        apLine2.Unique_Key__c = '4';
        apLine2.Allowance_Class__c = 'Manual';
        
        insert new List<Allowance_Applied__c>{apHdr, apLine, apHdr2, apLine2}; //
        
        custInvoice1.finalized__c = true;
        update custInvoice1;
        
        test.startTest();
        
        CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
        cia.execute(new List<Customer_Invoice_Line__c>{ciLine1});
        
        List<Accounting_Entry_Line__c> aeLines = [SELECT Id, accounting_rule__c, customer_invoice_line__c, accounting_rule__r.allocation_type__c
        												FROM Accounting_Entry_Line__c
        												WHERE Accounting_Entry__r.Customer_Invoice__c = :custInvoice1.Id];
		system.assertEquals(10, aeLines.size(), 'There should be 2 AE Lines for each of the allowances and the source doc line');
		set<Id> allowanceRuleIds = new set<Id>{arHdrApCR.Id, arHdrApDR.Id, arLineApCR.Id, arLineApDR.Id};
		for(Accounting_Entry_Line__c ael : aeLines){
			allowanceRuleIds.remove(ael.accounting_rule__c);
			if(ael.accounting_rule__r.allocation_type__c == 'Line'){
				system.assert(ael.customer_invoice_line__c != null,'Expecting the CIL lookup to be filled in for the line level allowance AELs');
			}
		}
		
		system.assertEquals(0, allowanceRuleIds.size(), 'All allowance rules should be represented by the accounting entry lines');
        
        test.stopTest();
        
        
 	}
 	

 	static testMethod void testAllowancesAccountingWithNoRules(){
 		
 		TestFuelQuery data = new TestFuelQuery();
 		//TestData.Accounting accting = new TestData.Accounting(data.company.Id);
 		
 		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = system.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = data.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
        insert ciLine1;
        
        Allowance_Type__c aType = new Allowance_Type__c();
        aType.Name = 'Test Allowance Type';
        aType.Allowance_Class__c = 'Manual';
        aType.Basis__c = 'Flat';
        aType.Manual__c = true;
        aType.Allow_Override__c = true;
        insert aType;

        Allowance_Applied__c apHdr = new Allowance_Applied__c();
        apHdr.Allowance_Type__c = aType.Id;
        apHdr.Customer_Invoice2__c = custInvoice1.Id;
        apHdr.allowance_amount__c = 1;
        apHdr.Unique_Key__c = '1';
        apHdr.Allowance_Class__c = 'Manual';
        
        Allowance_Applied__c apLine = new Allowance_Applied__c();
        apLine.Allowance_Type__c = aType.Id;
        apLine.Customer_Invoice_Line__c = ciLine1.Id;
        apLine.allowance_amount__c = 2;
        apLine.Unique_Key__c = '2';
        apLine.Allowance_Class__c = 'Manual';
        
        //FIN-615
        Allowance_Applied__c apHdr2 = new Allowance_Applied__c();
        apHdr2.Allowance_Type__c = aType.Id;
        apHdr2.Customer_Invoice2__c = custInvoice1.Id;
        apHdr2.allowance_amount__c = 3;
        apHdr2.Unique_Key__c = '3';
        apHdr2.Allowance_Class__c = 'Manual';
        
        Allowance_Applied__c apLine2 = new Allowance_Applied__c();
        apLine2.Allowance_Type__c = aType.Id;
        apLine2.Customer_Invoice_Line__c = ciLine1.Id;
        apLine2.allowance_amount__c = 4;
        apLine2.Unique_Key__c = '4';
        apLine2.Allowance_Class__c = 'Manual';
        
        insert new List<Allowance_Applied__c>{apHdr, apLine, apHdr2, apLine2}; //
        
        custInvoice1.finalized__c = true;
        update custInvoice1;
        
        test.startTest();
        
        CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
        cia.execute(new List<Customer_Invoice_Line__c>{ciLine1});
        
        List<Accounting_Entry_Line__c> aeLines = [SELECT Id, accounting_rule__c, customer_invoice_line__c, accounting_rule__r.allocation_type__c, allocation_id__c
        												FROM Accounting_Entry_Line__c
        												WHERE Accounting_Entry__r.Customer_Invoice__c = :custInvoice1.Id and allocation_id__c != null];
		system.assertEquals(8, aeLines.size(), 'There should be 2 AE Lines for each of the allowances and the source doc line');
		//set<Id> allowanceRuleIds = new set<Id>{arHdrApCR.Id, arHdrApDR.Id, arLineApCR.Id, arLineApDR.Id};
		for(Accounting_Entry_Line__c ael : aeLines){
			if(ael.allocation_id__c != null){
				system.assert(ael.accounting_rule__c == null,'Expected to have accounting rule null for allowance AELs');
			}
		}
        
        test.stopTest();
        
        
 	}

 		
 	static testMethod void testReverseRules(){
 		TestFuelQuery data = new TestFuelQuery();
		//Company__c company = fuel.company;
		
		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        //custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = system.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = data.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Adjustment';
        
        Customer_Invoice__c custInvoice2 = new Customer_Invoice__c();
        custInvoice2.Company__c = data.company.id;
		custInvoice2.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice2.Sold_To_Customer__c = data.customerSoldTo.id;
        //custInvoice2.Sales_Order__c = data.salesOrder.Id;
        custInvoice2.Date_Invoiced__c = system.now();
        custInvoice2.transaction_date__c = system.now();
        custInvoice2.status__c = 'Open';
        custInvoice2.Currency__c = data.company.Default_Transaction_Currency__c;
        custInvoice2.Invoice_Type__c = 'Adjustment';
        
        
        insert new List<Customer_Invoice__c>{custInvoice1, custInvoice2};
        
         List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        //ciLine1.Sales_Order_Line__c = data.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        //ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
        cils.add(ciLine1);
        
        Customer_Invoice_Line__c ciLine2 = new Customer_Invoice_Line__c();
        ciLine2.Quantity_Shipped__c = -5;
        ciLine2.Company__c = data.company.id;
        //ciLine2.Sales_Order_Line__c = data.salesOrderLine.id;
        ciLine2.Unit_Price__c = 10;
        //ciLine2.Sales_Order__c = data.salesOrder.id;
        ciLine2.Product__c = data.product.id ; 
        ciLine2.Discount_Percent__c = data.salesOrderLine.Discount_Percent__c;
        ciLine2.Customer_Invoice__c = custInvoice2.Id; 
        cils.add(ciLine2);
            
        insert cils;        
     
     	custInvoice1.Finalized__c = true;
     	custInvoice2.Finalized__c = true;
     	update new List<Customer_Invoice__c>{custInvoice1, custInvoice2};
     	Test.startTest();
     	AccountingService asv = new CustomerInvoiceAccounting();
     	asv.execute(cils);
     	Test.stopTest();
 	}
 	
 	static testMethod void testHistory(){
 		
 		TestFuelQuery data = new TestFuelQuery();
 		//TestData.Accounting accting = new TestData.Accounting(data.company.Id);
 		CIAccountingTestData ciActingtd = new CIAccountingTestData();

 		Accounting_Rule__c arHdrApCR = new Accounting_Rule__c();
 		arHdrApCR.Accounting_Standard__c = data.accountingStandard.Id;
 		arHdrApCR.Object_Name__c = 'Customer_Invoice__c';
 		//arHdrApCR.Company__c = data.company.Id;
 		arHdrApCR.transaction__c = 'Ship Invoice';
 		arHdrApCR.Allocation_Type__c = 'Header';
 		arHdrApCR.Allocation__c = 'Manual';
 		arHdrApCR.Rule_Type__c = 'CR';
 		arHdrApCR.GL_Account__c = data.receivablesGL.Id;
 		arHdrApCR.Effective_Start_Date__c = ciActingtd.effStartDate; 				 		 		
 		arHdrApCR.Default_GL_Account__c = true;
 		
 		Accounting_Rule__c arHdrApDR = new Accounting_Rule__c();
 		arHdrApDR.Accounting_Standard__c = data.accountingStandard.Id;
 		arHdrApDR.Object_Name__c = 'Customer_Invoice__c';
 		//arHdrApDR.Company__c = data.company.Id;
 		arHdrApDR.transaction__c = 'Ship Invoice';
 		arHdrApDR.Allocation_Type__c = 'Header';
 		arHdrApDR.Allocation__c = 'Manual';
 		arHdrApDR.Rule_Type__c = 'DR';
 		arHdrApDR.Default_GL_Account__c = false;
 		arHdrApDR.Effective_Start_Date__c = ciActingtd.effStartDate; 				 		 		 		
 		arHdrApDR.GL_Account_Reference_Value__c = 'Customer_Invoice_Line__r.Product__r.Item__r.Class__r.Revenue_GL_Account__c';
 		
 		Accounting_Rule__c arLineApCR = new Accounting_Rule__c();
 		arLineApCR.Accounting_Standard__c = data.accountingStandard.Id;
 		arLineApCR.Object_Name__c = 'Customer_Invoice__c';
 		//arLineApCR.Company__c = data.company.Id;
 		arLineApCR.transaction__c = 'Ship Invoice';
 		arLineApCR.subtransaction_type__c = 'Goods';
 		arLineApCR.Allocation_Type__c = 'Line';
 		arLineApCR.Allocation__c = 'Manual';
 		arLineApCR.Rule_Type__c = 'CR';
 		arLineApCR.GL_Account__c = data.receivablesGL.Id;
 		arLineApCR.Effective_Start_Date__c = ciActingtd.effStartDate; 				 		 		 		 		
 		arLineApCR.Default_GL_Account__c = true;
 		
 		Accounting_Rule__c arLineApDR = new Accounting_Rule__c();
 		arLineApDR.Accounting_Standard__c = data.accountingStandard.Id;
 		arLineApDR.Object_Name__c = 'Customer_Invoice__c';
 		//arLineApDR.Company__c = data.company.Id;
 		arLineApDR.transaction__c = 'Ship Invoice';
 		arLineApDR.subtransaction_type__c = 'Goods';
 		arLineApDR.Allocation_Type__c = 'Line';
 		arLineApDR.Allocation__c = 'Manual';
 		arLineApDR.Rule_Type__c = 'DR';
 		arLineApDR.Default_GL_Account__c = false;
 		arLineApDR.Effective_Start_Date__c = ciActingtd.effStartDate; 				 		 		 		 		 		
 		arLineApDR.GL_Account_Reference_Value__c = 'Customer_Invoice_Line__r.Product__r.Item__r.Class__r.Revenue_GL_Account__c';
 		
 		insert new List<Accounting_Rule__c>{arHdrApCR, arHdrApDR, arLineApCR, arLineApDR};
 		
 		Customer_Invoice__c custInvoice1 = new Customer_Invoice__c();
        custInvoice1.Company__c = data.company.id;
		custInvoice1.Bill_To_Customer__c = data.customerbillto.id;
        custInvoice1.Sold_To_Customer__c = data.customerSoldTo.id;
        custInvoice1.Sales_Order__c = data.salesOrder.Id;
        custInvoice1.Date_Invoiced__c = system.now();
        custInvoice1.transaction_date__c = system.now();
        custInvoice1.status__c = 'Open';
        custInvoice1.Currency__c = data.company.Default_Transaction_Currency__c;
        custInvoice1.Invoice_Type__c = 'Ship Invoice';
        insert custInvoice1;
        
        Customer_Invoice_Line__c ciLine1 = new Customer_Invoice_Line__c();
        ciLine1.Quantity_Shipped__c = 5;
        ciLine1.Company__c = data.company.id;
        ciLine1.Sales_Order_Line__c = data.salesOrderLine.id;
        ciLine1.Unit_Price__c = 10;
        ciLine1.Sales_Order__c = data.salesOrder.id;
        ciLine1.Product__c = data.product.id ; 
        ciLine1.Discount_Percent__c = data.salesOrderLine.Discount_Percent__c;
        ciLine1.Customer_Invoice__c = custInvoice1.Id; 
        insert ciLine1;
        
        Allowance_Type__c aType = new Allowance_Type__c();
        aType.Name = 'Test Allowance Type';
        aType.Allowance_Class__c = 'Manual';
        aType.Basis__c = 'Flat';
        aType.Manual__c = true;
        aType.Allow_Override__c = true;
        insert aType;

        Allowance_Applied__c apHdr = new Allowance_Applied__c();
        apHdr.Allowance_Type__c = aType.Id;
        apHdr.Customer_Invoice2__c = custInvoice1.Id;
        apHdr.allowance_amount__c = 1;
        apHdr.Unique_Key__c = '1';
        apHdr.Allowance_Class__c = 'Manual';
        
        Allowance_Applied__c apLine = new Allowance_Applied__c();
        apLine.Allowance_Type__c = aType.Id;
        apLine.Customer_Invoice_Line__c = ciLine1.Id;
        apLine.allowance_amount__c = 2;
        apLine.Unique_Key__c = '2';
        apLine.Allowance_Class__c = 'Manual';
        
        //FIN-615
        Allowance_Applied__c apHdr2 = new Allowance_Applied__c();
        apHdr2.Allowance_Type__c = aType.Id;
        apHdr2.Customer_Invoice2__c = custInvoice1.Id;
        apHdr2.allowance_amount__c = 3;
        apHdr2.Unique_Key__c = '3';
        apHdr2.Allowance_Class__c = 'Manual';
        
        Allowance_Applied__c apLine2 = new Allowance_Applied__c();
        apLine2.Allowance_Type__c = aType.Id;
        apLine2.Customer_Invoice_Line__c = ciLine1.Id;
        apLine2.allowance_amount__c = 4;
        apLine2.Unique_Key__c = '4';
        apLine2.Allowance_Class__c = 'Manual';
        
        insert new List<Allowance_Applied__c>{apHdr, apLine, apHdr2, apLine2}; //
        
        custInvoice1.finalized__c = true;
        update custInvoice1;
        
        test.startTest();
        
        CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
        cia.execute(new List<Customer_Invoice_Line__c>{ciLine1});
        
        List<Accounting_Entry_Line__c> aeLines = [SELECT Id, accounting_rule__c, Accounting_Entry__r.Status__c
        												FROM Accounting_Entry_Line__c
        												WHERE Accounting_Entry__r.Customer_Invoice__c = :custInvoice1.Id];
		system.assertEquals(10, aeLines.size(), 'There should be 2 AE Lines for each of the allowances and the source doc line');
		set<Id> allowanceRuleIds = new set<Id>{arHdrApCR.Id, arHdrApDR.Id, arLineApCR.Id, arLineApDR.Id};
		for(Accounting_Entry_Line__c ael : aeLines){
			allowanceRuleIds.remove(ael.accounting_rule__c);
			system.assertEquals('Active', ael.accounting_entry__r.status__c, 'Expected Active Entry ' + ael);
		}
		
		system.assertEquals(0, allowanceRuleIds.size(), 'All allowance rules should be represented by the accounting entry lines');
        
        //Now change the rules
        arLineApCR.GL_Account__c = data.cashGL.Id;
        update arLineApCR;
        
        AccountingRuleService.mAccountingRules.clear();
        cia.execute(new List<Customer_Invoice_line__c>{ciLine1});
        
        List<Accounting_Entry__c> aes = [SELECT Id, status__c
        												FROM Accounting_Entry__c
        												WHERE Customer_Invoice__c = :custInvoice1.Id];
		system.assertEquals(2, aes.size(), 'We should have 2 entries, the original (now obsolete) and the current active one');
		boolean hasActive = false;
		boolean hasObsolete = false;
		for(Accounting_Entry__c ae : aes){
			if(ae.status__c == 'Active'){
				hasActive = true;
			}else if(ae.status__c == 'Obsolete'){
				hasObsolete = true;
			}
		}
		
		system.assert(hasActive, 'We should have an active entry');
		system.assert(hasObsolete, 'We should have an obsolete entry');
        
        
        test.stopTest();
 	}

 	
 	
}