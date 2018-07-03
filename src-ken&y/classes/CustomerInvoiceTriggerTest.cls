@isTest
public with sharing class CustomerInvoiceTriggerTest {
    
    // TODO  build a test for  KNDY-2873 - Should pull payment terms from related Sales Order not the related Customer 
    
	static List<Customer_Invoice__c> custInvList; 
    static List<Customer__c> customerList;
    
 	// Test the Customer invoice after update
 	// After update can be triggered by updating / inserting / deleting any of the invoice lines
 	// 
    public static testMethod void test_Balance_Paid() {
        
        TestFuel data = new TestFuel();  
        List<Period__c> periodList = data.periodList;
        system.assert( data.custInv1 != null && data.salesOrderLines != null );
        
        test.startTest();
        custInvList = [Select id, Name, Status__c, Balance__c 
                                                 from Customer_Invoice__c where id = :data.custInv1.id];
        customerList = [Select id, Name, Parent_Customer__c, Top_Parent_Customer__r.Open_Invoices__c 
                                          from Customer__c where id = :data.customerBillTo.id]; 
        
        system.assertEquals('Open',custInvList[0].status__c);
        system.assertEquals(0, custInvList[0].Balance__c);
        
        Customer_Invoice_Line__c shipmentObj1 = new Customer_Invoice_Line__c();
        shipmentObj1.Company__c = data.company.id;
        shipmentObj1.Quantity_Shipped__c = 5;
        shipmentObj1.Unit_Price__c = 100;
        shipmentObj1.Product__c = data.salesOrderLines[0].Product__c;
        shipmentObj1.Location__c = data.salesOrderLines[0].Ship_From_Location__c;
        shipmentObj1.Customer_Invoice__c = data.custInv1.id;
        
        insert shipmentObj1;
        
        custInvList = [Select id, Name, Status__c,subtotal__c, Balance__c from Customer_Invoice__c where id = :data.custInv1.id]; 
        customerList = [Select id, Name, Parent_Customer__c, Top_Parent_Customer__r.Open_Invoices__c from Customer__c where id = :data.customerBillTo.id];
        
        system.assertEquals('Open', custInvList[0].status__c);
        system.assertEquals(500, custInvList[0].Balance__c);
        system.assertNotEquals(0, custInvList[0].subtotal__c);
         
        data.custInv1.Amount_Paid__c = 500;
        update data.custInv1;
        
        custInvList = [Select id, Name, Status__c, Balance__c, Date_Time_Paid__c from Customer_Invoice__c where id = :data.custInv1.id]; 
        customerList = [Select id, Name, Parent_Customer__c, Top_Parent_Customer__r.Open_Invoices__c from Customer__c where id = :data.customerBillTo.id];
        
        system.assertEquals('Closed', custInvList[0].status__c, ' expected that a paid invoice is closed');
        //system.assertEquals(system.now().format('yyyy/mm/dd hh:mm'), custInvList[0].Date_Time_Paid__c.format('yyyy/mm/dd hh:mm')); //otc-621
        system.assertEquals(true, KSE.areDateTimesClose(custInvList[0].Date_Time_Paid__c,system.now(),1 ).bCloseEnough);
        system.assertEquals(0, custInvList[0].Balance__c);
       
    }
    
   public static testMethod void test_Credit_Memo() {  
        TestFuel data = new TestFuel(); 
        List<Period__c> periodList = data.periodList;
        system.assert( data.company != null && data.customerBillTo != null && data.customerSoldTo!=null);
        
        Customer_Invoice__c custInv2 = new Customer_Invoice__c();
        custInv2.Company__c = data.company.id;
        custInv2.Invoice_Type__c = 'Miscellaneous';
        custInv2.Status__c = 'Open';
        custInv2.Bill_To_Customer__c = data.customerBillTo.id;
        custInv2.Sold_To_Customer__c = data.customerSoldTo.id;
        insert custInv2;
        
        Customer_Invoice_Line__c cil2 = new Customer_Invoice_Line__c();
        cil2.Customer_Invoice__c = custInv2.Id;
        cil2.Quantity_Shipped__c = -1;
        cil2.Unit_Price__c = 100;
        insert cil2;
        
        custInvList = [Select id, Name, Status__c, Balance__c 
                                                 from Customer_Invoice__c where id = :custInv2.id]; 
        customerList = [Select id, Name, Parent_Customer__c, Parent_Customer__r.Open_Invoices__c 
                                          from Customer__c where id = :data.customerBillTo.id];
        system.assertEquals('Open', custInvList[0].status__c);
        system.assertEquals(-100,custInvList[0].Balance__c);
        
        Customer_Receipt__c custReceipt = new Customer_Receipt__c();
		custReceipt.Amount_Received__c = 0;
		custReceipt.Company__c = data.company.Id;
		custReceipt.Customer__c = data.customerBillto.Id;
		custReceipt.Date_Received__c = system.today();
		custReceipt.Currency__c = TestFuel.currencyUSD.id;
		custReceipt.Type__c = CustomerReceiptService.TYPE_RECEIPT;
		insert custReceipt;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = custReceipt.Id;
		crl.Type__c = PaymentService.TYPE_CREDIT_MEMO;
		crl.Amount__c = 100;
		crl.Customer_Invoice__c = custInv2.Id; //KNDY-13995
		insert crl;
		
		
		Customer_Receipt_Line__c crl2 = new Customer_Receipt_Line__c();
    	crl2.Amount__c = 100;
    	crl2.Type__c = PaymentService.TYPE_OVERPAYMENT;
    	crl2.Customer_Receipt__c = custReceipt.Id;
    	insert crl2;
    	
    	custReceipt.finalized__c = true;
		update custReceipt;
		
        
        custInvList = [Select id, Name, Status__c, Balance__c, Date_Time_Paid__c, Total_Line_Amount__c, Amount_Paid__c, Credit_Applied__c, Total_Amount__c from Customer_Invoice__c where id = :custInv2.id]; 
        system.assertEquals('Closed', custInvList[0].status__c, custInvList);
        system.assertEquals(0, custInvList[0].Balance__c);
     
    }
    
    public static testMethod void test_Manual() {  
        TestFuel data = new TestFuel(); 
        system.assert( data.company != null && data.customerBillTo != null && data.customerSoldTo!=null);
    
        Customer_Invoice__c custInv3 = new Customer_Invoice__c();
        custInv3.Company__c = data.company.id;
        custInv3.Invoice_Type__c = 'Manual';
        custInv3.Status__c = 'Open';
        custInv3.Bill_To_Customer__c = data.customerBillTo.id;
        custInv3.Sold_To_Customer__c = data.customerSoldTo.id;
        insert custInv3;
        
        custInvList = [Select id, Name, Status__c, Balance__c from Customer_Invoice__c where id = :custInv3.id]; 
        customerList = [Select id, Name, Parent_Customer__c, Parent_Customer__r.Open_Invoices__c from Customer__c where id = :data.customerBillTo.id];
        
        system.assertEquals('Open', custInvList[0].status__c);
        system.assertEquals(0,custInvList[0].Balance__c);
        
       
        List<Customer_Invoice_Line__c> shipmentList = new List<Customer_Invoice_Line__c>();
        Customer_Invoice_Line__c shipmentObj3 = new Customer_Invoice_Line__c();
        shipmentObj3.Quantity_Shipped__c = 5;
        shipmentObj3.Company__c = data.company.id;
        shipmentObj3.Unit_Price__c = 100;
        shipmentObj3.Customer_Invoice__c = custInv3.id;
        shipmentList.add(shipmentObj3);
        
        Customer_Invoice_Line__c shipmentObj4 = new Customer_Invoice_Line__c();
        shipmentObj4.Quantity_Shipped__c = 5;
        shipmentObj4.Company__c = data.company.id;
        shipmentObj4.Unit_Price__c = 100;
        shipmentObj4.Customer_Invoice__c = custInv3.id;
        shipmentList.add(shipmentObj4);
        
        insert shipmentList;
		 
        custInvList = [Select id, Name, Status__c, Balance__c from Customer_Invoice__c where id in (:custInv3.id)]; 
        customerList = [Select id, Name, Parent_Customer__c, Parent_Customer__r.Open_Invoices__c from Customer__c where id = :data.customerBillTo.id];
        
        system.assertEquals('Open', custInvList[0].status__c);
        system.assertEquals(1000,custInvList[0].Balance__c);
       
     
        
        shipmentObj3.Unit_Price__c = 80;
        update shipmentObj3;
        
        custInvList = [Select id, Name, Status__c, Balance__c 
										from Customer_Invoice__c where id in (:custInv3.id)]; 
        customerList = [Select id, Name, Parent_Customer__c, Parent_Customer__r.Open_Invoices__c 
										from Customer__c where id = :data.customerBillTo.id];
       
        system.assertEquals('Open', custInvList[0].status__c);
        system.assertEquals(900, custInvList[0].Balance__c);
        //KNDY-4220 system.assertEquals(900, customerList[0].Parent_Customer__r.Open_Invoices__c);
       
        
        delete shipmentObj4;  // take the amount on the invoice down by 400
        
        custInvList = [Select id, Name, Status__c, Balance__c from Customer_Invoice__c where id in (:custInv3.id)]; 
        customerList = [Select id, Name, Parent_Customer__c, Parent_Customer__r.Open_Invoices__c from Customer__c where id = :data.customerBillTo.id];
   
        system.assertEquals('Open', custInvList[0].status__c);
        system.assertEquals(400, custInvList[0].Balance__c);
 //TODO       system.assertEquals(400, customerList[0].Parent_Customer__r.Open_Invoices__c);// TODO KNDY-4220
       
        custInv3.Amount_Paid__c = 400;
        update custInv3;
        custInvList = [Select id, Name, Status__c, Balance__c from Customer_Invoice__c where id in (:custInv3.id)]; 
        customerList = [Select id, Name, Parent_Customer__c, Parent_Customer__r.Open_Invoices__c from Customer__c where id = :data.customerBillTo.id];
       
        system.assertEquals('Closed', custInvList[0].status__c);
        system.assertEquals(0, custInvList[0].Balance__c);
// TODO       system.assertEquals(0, customerList[0].Parent_Customer__r.Open_Invoices__c); // TODO KNDY-4220
        
       
        
    }
    
    public static testMethod void test_InvoiceAddress() {  
        // address should copy from bill to customer to invoice , per : CustomerInvoiceService.setCustomerInformation( ) 
        
        TestFuel data = new TestFuel(); 
        system.assert( data.company != null && data.customerSoldTo!=null);
            
       	Customer_Invoice__c custInv4 = new Customer_Invoice__c();
        custInv4.Company__c = data.company.id;
        custInv4.Invoice_Type__c = 'Manual';
        custInv4.Status__c = 'Open';
        custInv4.Bill_To_Customer__c = data.customerBillTo.id;
        insert custInv4;
        
        custInvList = [Select id, Name, Status__c, Balance__c, Sold_To_Customer__c, Bill_To_Customer__c,
				        Sold_to_street__c, Sold_To_City__c, Sold_To_State__c, Sold_To_Zip_Code__c, Sold_To_Country__c,
        				Bill_to_street__c, Bill_To_City__c, Bill_To_State__c, Bill_To_Zip_Code__c, Bill_To_Country__c  
        				from Customer_Invoice__c where id in (:custInv4.id)];
        
        customerList = [Select id, Name, Parent_Customer__c, Street__c, City__c, State__c, Zip_Code__c, Country__c,
        										Parent_Customer__r.Street__c, Parent_Customer__r.City__c, Parent_Customer__r.State__c, 
        										Parent_Customer__r.Zip_Code__c, Parent_Customer__r.Country__c
        										from Customer__c 
        										where id = :data.customerBillTo.id ]; 
     
        system.assertEquals(customerList[0].Street__c , custInvList[0].Bill_to_street__c);
        system.assertEquals(customerList[0].City__c , custInvList[0].Bill_To_City__c);
        system.assertEquals(customerList[0].State__c , custInvList[0].Bill_To_State__c);
        system.assertEquals(customerList[0].Zip_Code__c , custInvList[0].Bill_To_Zip_Code__c);
        system.assertEquals(customerList[0].Country__c , custInvList[0].Bill_To_Country__c);
  
     }
     
     // Test Trigger for the status changes
     public static testMethod void test_StatusChanges() {
         
         TestFuel data = new TestFuel(); 
         system.assert(  data.custInv1 != null && data.company != null && data.customerSoldTo!=null && data.salesOrderLines != null);
         
         test.startTest();
        
         custInvList = [Select id, Name, Status__c, Balance__c from Customer_Invoice__c where id = :data.custInv1.id];
         customerList = [Select id, Name, Parent_Customer__c, Parent_Customer__r.Open_Invoices__c from Customer__c where id = :data.customerBillTo.id]; 
        
         system.assertEquals('Open',custInvList[0].status__c, 'expected new invoice is open');
         system.assertEquals(0, custInvList[0].Balance__c);
         

         Customer_Invoice_Line__c shipmentObj1 = new Customer_Invoice_Line__c();
         shipmentObj1.Company__c = data.company.id;
         shipmentObj1.Quantity_Shipped__c = 5;
         shipmentObj1.Unit_Price__c = 100;
         shipmentObj1.Product__c = data.salesOrderLines[0].Product__c;
         shipmentObj1.Location__c = data.salesOrderLines[0].Ship_From_Location__c;
         shipmentObj1.Customer_Invoice__c = data.custInv1.id;
         
         insert shipmentObj1;
         
         data.custInv1.Amount_Paid__c = 500;
         update data.custInv1;
         
         data.custInv1 = [Select id, Name, Status__c, Balance__c
                     from Customer_Invoice__c where id = :data.custInv1.id];
         
         system.assertEquals(0,data.custInv1.Balance__c);			
         system.assertEquals('Closed',data.custInv1.status__c);
         
         data.custInv1.Memo__c = 'Invoice Test';
         
         update data.custInv1;
         
         data.custInv1 = [Select id, Name, Status__c, Memo__c
                          from Customer_Invoice__c where id = :data.custInv1.id];
         
         system.assertEquals('Closed',data.custInv1.status__c);

         data.custInv1.Amount_Paid__c = 80;
         
         update data.custInv1;
         
         data.custInv1 = [Select id, Name, Status__c
                     from Customer_Invoice__c where id = :data.custInv1.id];
         
         system.assertEquals('Open', data.custInv1.status__c);
     
     	// KNDY-5849: Try deleting the customer invoice
     	delete data.custInv1;
     	
     	system.assertEquals(0, [select ID from Customer_Invoice__c where Id = :data.custInv1.Id].size());
     } 
     
     public static testMethod void test_NewCIwithInvalidPaymentTerm(){
     	TestFuel data = new TestFuel(); 
     	Payment_Term__c terms = data.terms;
     	terms.Type__c = null; // blank the type
     	update terms;
     	
     	Customer_Invoice__c ci = data.custInv1.clone();
     	try{
     		insert ci;
     	}
     	catch (Exception ex){
     		system.assert(ex.getMessage().contains(Label.Please_enter_Type_on_associated_Payment_Term), 'Unexpected Exception thrown: '+ ex.getMessage());
     	}
     }
}