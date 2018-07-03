@isTest
private class CustomerAgingBatchTest {
  @testSetup static void ts() { 
    TestFuel data = new TestFuel(); 
    // these asserts cause TestFuelQuery to insert data
    system.assert(      
       data.company != null && 
       data.customerBillTo != null &&
       data.customerParent != null &&
       data.customerBillTo != null
    );
  }
  private static Customer_Invoice__c createAllowanceAccrualCI(){
    TestFuelQuery fuel = new TestFuelQuery();
    Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
    CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
    CustomerInvoice.Company__c = fuel.company.Id;
    CustomerInvoice.Invoice_Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL;
    CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
    CustomerInvoice.Date_Invoiced__c = system.now().addDays(-130);
    CustomerInvoice.Transaction_Date__c = Date.today();
    return CustomerInvoice;
  }
  
  private static Customer_Invoice_Line__c createAllowanceAccrualCIL(Customer_Invoice__c ci){
    Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
    cil.Customer_Invoice__c = ci.Id;
    cil.Quantity_Shipped__c = 1;
    cil.Unit_Price__c = -100;
    return cil;
  }
  
  static testMethod void test_greaterThan_90(){ 
     
    TestFuelQuery fuel = new TestFuelQuery();
     
    Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
	CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
    CustomerInvoice.Company__c = fuel.company.Id;
    CustomerInvoice.Invoice_Type__c = 'Manual';
    CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
    CustomerInvoice.Date_Invoiced__c = system.now().addDays(-130);
    CustomerInvoice.Transaction_Date__c = Date.today();
	Customer_Invoice__c CustomerInvoiceAA = createAllowanceAccrualCI();
	List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>{CustomerInvoice,CustomerInvoiceAA};
	insert cis;
	
	Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
	cil.Customer_Invoice__c = CustomerInvoice.Id;
	cil.Quantity_Shipped__c = 1;
	cil.Unit_Price__c = 100;
	Customer_Invoice_Line__c CustomerInvoiceLineAA = createAllowanceAccrualCIL(CustomerInvoiceAA);
	List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>{cil,CustomerInvoiceLineAA};
	insert cils;
	
	CustomerInvoice.Finalized__c = true;
	CustomerInvoiceAA.Finalized__c = true;
	update cis;
	
	test.startTest();
      CustomerAgingBatch agingBatch = new CustomerAgingBatch();
      agingBatch.runBatch(fuel.company.Id);
  	test.stopTest();
     
     cis = [select id, Status__c, Balance__c, Date_Invoiced__c, Amount_Past_Due__c, Date_Time_Paid__c, Days_Past_Due__c,  Days_to_Pay_30__c, Due_Date__c from Customer_Invoice__c where id in :cis];
     for (Customer_Invoice__c ci: cis){
         system.debug('CustomerInvoice '+ ci);
         system.assertEquals(100, ci.Days_Past_Due__c);
     }
     Customer__c billTo = [select Id, Name,  Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Current_Balance__c FROM Customer__c where id = :fuel.customerBillTo.Id limit 1];
     system.debug('billTo '+billTo);
     system.assertEquals(0,billTo.Current_Balance__c);
     system.assertEquals(0, billTo.X1_30_Days_Past_Due__c);
     system.assertEquals(0,billTo.X31_60_Days_Past_Due__c);
     system.assertEquals(0,billTo.X61_90_Days_Past_Due__c);
     system.assertEquals(100,billTo.More_Than_90_Days_Past_Due__c);
     
     Customer__c corp = [select Id, Name,  Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Current_Balance__c FROM Customer__c where id = :fuel.customerParent.Id limit 1];
     system.debug('corp '+corp);
     system.assertEquals(0,corp.Current_Balance__c);
     system.assertEquals(0, corp.X1_30_Days_Past_Due__c);
     system.assertEquals(0,corp.X31_60_Days_Past_Due__c);
     system.assertEquals(0,corp.X61_90_Days_Past_Due__c);
     system.assertEquals(100,corp.More_Than_90_Days_Past_Due__c);
     
    
  }  
  
  static testMethod void test_61_90(){ 
     
    TestFuelQuery fuel = new TestFuelquery();
     
    Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
	CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
    CustomerInvoice.Company__c = fuel.company.Id;
    CustomerInvoice.Invoice_Type__c = 'Manual';
    CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
    CustomerInvoice.Date_Invoiced__c = system.now().addDays(-100);
    CustomerInvoice.Transaction_Date__c = Date.today();
	Customer_Invoice__c CustomerInvoiceAA = createAllowanceAccrualCI();
	CustomerInvoiceAA.Date_Invoiced__c = system.now().addDays(-100);
	List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>{CustomerInvoice,CustomerInvoiceAA};
	insert cis;
		
	Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
	cil.Customer_Invoice__c = CustomerInvoice.Id;
	cil.Quantity_Shipped__c = 1;
	cil.Unit_Price__c = 100;
	Customer_Invoice_Line__c CustomerInvoiceLineAA = createAllowanceAccrualCIL(CustomerInvoiceAA);
	List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>{cil,CustomerInvoiceLineAA};
	insert cils;
	
	CustomerInvoice.Finalized__c = true;
	CustomerInvoiceAA.Finalized__c = true;
	update cis;
		
	test.startTest();
      CustomerAgingBatch agingBatch = new CustomerAgingBatch();
      agingBatch.runBatch(fuel.company.Id);
  	test.stopTest();

     cis = [select id, Status__c, Balance__c, Date_Invoiced__c, Amount_Past_Due__c, Date_Time_Paid__c, Days_Past_Due__c,  Days_to_Pay_30__c, Due_Date__c from Customer_Invoice__c where id in :cis];
     for (Customer_Invoice__c ci: cis){
         system.debug('CustomerInvoice '+ ci);
         system.assertEquals(70, ci.Days_Past_Due__c);
     }
     
     Customer__c billTo = [select Id, Name,  Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Current_Balance__c FROM Customer__c where id = :fuel.customerBillTo.Id limit 1];
     system.debug('billTo '+billTo);
     system.assertEquals(0,billTo.Current_Balance__c);
     system.assertEquals(0, billTo.X1_30_Days_Past_Due__c);
     system.assertEquals(0,billTo.X31_60_Days_Past_Due__c);
     system.assertEquals(100,billTo.X61_90_Days_Past_Due__c);
     system.assertEquals(0,billTo.More_Than_90_Days_Past_Due__c);
     
     Customer__c corp = [select Id, Name,  Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Current_Balance__c FROM Customer__c where id = :fuel.customerParent.Id limit 1];
     system.debug('corp '+corp);
     system.assertEquals(0,corp.Current_Balance__c);
     system.assertEquals(0, corp.X1_30_Days_Past_Due__c);
     system.assertEquals(0,corp.X31_60_Days_Past_Due__c);
     system.assertEquals(100,corp.X61_90_Days_Past_Due__c);
     system.assertEquals(0,corp.More_Than_90_Days_Past_Due__c);
     
    
  }  
    
  static testMethod void test_31_60(){ 
     
    TestFuelQuery fuel = new TestFuelQuery();
     
    Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
	CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
    CustomerInvoice.Company__c = fuel.company.Id;
    CustomerInvoice.Invoice_Type__c = 'Manual';
    CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
    CustomerInvoice.Date_Invoiced__c = system.now().addDays(-70);
    CustomerInvoice.Transaction_Date__c = Date.today();
	Customer_Invoice__c CustomerInvoiceAA = createAllowanceAccrualCI();
	CustomerInvoiceAA.Date_Invoiced__c = system.now().addDays(-70);
	List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>{CustomerInvoice,CustomerInvoiceAA};
	insert cis;
	
	Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
	cil.Customer_Invoice__c = CustomerInvoice.Id;
	cil.Quantity_Shipped__c = 1;
	cil.Unit_Price__c = 100;
	Customer_Invoice_Line__c CustomerInvoiceLineAA = createAllowanceAccrualCIL(CustomerInvoiceAA);
	List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>{cil,CustomerInvoiceLineAA};
	insert cils;
	
	CustomerInvoice.Finalized__c = true;
	CustomerInvoiceAA.Finalized__c = true;
	update cis;
	
	test.startTest();
      CustomerAgingBatch agingBatch = new CustomerAgingBatch();
      agingBatch.runBatch(fuel.company.Id);
  	test.stopTest();
     
     cis = [select id, Status__c, Balance__c, Date_Invoiced__c, Amount_Past_Due__c, Date_Time_Paid__c, Days_Past_Due__c,  Days_to_Pay_30__c, Due_Date__c from Customer_Invoice__c where id in :cis];
     for (Customer_Invoice__c ci: cis){
         system.debug('CustomerInvoice '+ ci);
         system.assertEquals(40, ci.Days_Past_Due__c);
     }
     
     Customer__c billTo = [select Id, Name,  Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Current_Balance__c FROM Customer__c where id = :fuel.customerBillTo.Id limit 1];
     system.debug('billTo '+billTo);
     system.assertEquals(0,billTo.Current_Balance__c);
     system.assertEquals(0, billTo.X1_30_Days_Past_Due__c);
     system.assertEquals(100,billTo.X31_60_Days_Past_Due__c);
     system.assertEquals(0,billTo.X61_90_Days_Past_Due__c);
     system.assertEquals(0,billTo.More_Than_90_Days_Past_Due__c);
     
     Customer__c corp = [select Id, Name,  Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Current_Balance__c FROM Customer__c where id = :fuel.customerParent.Id limit 1];
     system.debug('corp '+corp);
     system.assertEquals(0,corp.Current_Balance__c);
     system.assertEquals(0, corp.X1_30_Days_Past_Due__c);
     system.assertEquals(100,corp.X31_60_Days_Past_Due__c);
     system.assertEquals(0,corp.X61_90_Days_Past_Due__c);
     system.assertEquals(0,corp.More_Than_90_Days_Past_Due__c);
     
    
  }  
  
  static testMethod void test_1_30(){ 
     
    TestFuelQuery fuel = new TestFuelQuery();
     
    Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
	CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
    CustomerInvoice.Company__c = fuel.company.Id;
    CustomerInvoice.Invoice_Type__c = 'Manual';
    CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
    CustomerInvoice.Date_Invoiced__c = system.now().addDays(-50);
    CustomerInvoice.Transaction_Date__c = Date.today();
	Customer_Invoice__c CustomerInvoiceAA = createAllowanceAccrualCI();
	CustomerInvoiceAA.Date_Invoiced__c = system.now().addDays(-50);
	List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>{CustomerInvoice,CustomerInvoiceAA};
	insert cis;
	
	Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
	cil.Customer_Invoice__c = CustomerInvoice.Id;
	cil.Quantity_Shipped__c = 1;
	cil.Unit_Price__c = 100;
	Customer_Invoice_Line__c CustomerInvoiceLineAA = createAllowanceAccrualCIL(CustomerInvoiceAA);
	List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>{cil,CustomerInvoiceLineAA};
	insert cils;
	
	CustomerInvoice.Finalized__c = true;
	CustomerInvoiceAA.Finalized__c = true;
	update cis;
	
	test.startTest();
      CustomerAgingBatch agingBatch = new CustomerAgingBatch();
      agingBatch.runBatch(fuel.company.Id);
  	test.stopTest();
     
     cis = [select id, Status__c, Balance__c, Date_Invoiced__c, Amount_Past_Due__c, Date_Time_Paid__c, Days_Past_Due__c,  Days_to_Pay_30__c, Due_Date__c from Customer_Invoice__c where id in :cis];
     for (Customer_Invoice__c ci: cis){
         system.debug('CustomerInvoice '+ ci);
         system.assertEquals(20, ci.Days_Past_Due__c);
     }     
     Customer__c billTo = [select Id, Name,  Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Current_Balance__c FROM Customer__c where id = :fuel.customerBillTo.Id limit 1];
     system.debug('billTo '+billTo);
     system.assertEquals(0,billTo.Current_Balance__c);
     system.assertEquals(100, billTo.X1_30_Days_Past_Due__c);
     system.assertEquals(0,billTo.X31_60_Days_Past_Due__c);
     system.assertEquals(0,billTo.X61_90_Days_Past_Due__c);
     system.assertEquals(0,billTo.More_Than_90_Days_Past_Due__c);
     
     Customer__c corp = [select Id, Name,  Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Current_Balance__c FROM Customer__c where id = :fuel.customerParent.Id limit 1];
     system.debug('corp '+corp);
     system.assertEquals(0,corp.Current_Balance__c);
     system.assertEquals(100, corp.X1_30_Days_Past_Due__c);
     system.assertEquals(0,corp.X31_60_Days_Past_Due__c);
     system.assertEquals(0,corp.X61_90_Days_Past_Due__c);
     system.assertEquals(0,corp.More_Than_90_Days_Past_Due__c);
     
    
  }
  
  static testMethod void test_Current(){ 
     
    TestFuelQuery fuel = new TestFuelQuery();
     
    Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
	CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
    CustomerInvoice.Company__c = fuel.company.Id;
    CustomerInvoice.Invoice_Type__c = 'Manual';
    CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
    CustomerInvoice.Date_Invoiced__c = system.now().addDays(-10);
    CustomerInvoice.Transaction_Date__c = Date.today();
	Customer_Invoice__c CustomerInvoiceAA = createAllowanceAccrualCI();
	CustomerInvoiceAA.Date_Invoiced__c = system.now().addDays(-10);
	List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>{CustomerInvoice,CustomerInvoiceAA};
	insert cis;
	
	Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
	cil.Customer_Invoice__c = CustomerInvoice.Id;
	cil.Quantity_Shipped__c = 1;
	cil.Unit_Price__c = 100;
	Customer_Invoice_Line__c CustomerInvoiceLineAA = createAllowanceAccrualCIL(CustomerInvoiceAA);
	List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>{cil,CustomerInvoiceLineAA};
	insert cils;
	
	CustomerInvoice.Finalized__c = true;
	CustomerInvoiceAA.Finalized__c = true;
	update cis;
	
	test.startTest();
      CustomerAgingBatch agingBatch = new CustomerAgingBatch();
      agingBatch.runBatch(fuel.company.Id);
  	test.stopTest();
     
     cis = [select id, Status__c, Balance__c, Date_Invoiced__c, Amount_Past_Due__c, Date_Time_Paid__c, Days_Past_Due__c,  Days_to_Pay_30__c, Due_Date__c from Customer_Invoice__c where id in :cis];
     for (Customer_Invoice__c ci: cis){
         system.debug('CustomerInvoice '+ ci);
         system.assertEquals(0, ci.Days_Past_Due__c);
     }
     
     Customer__c billTo = [select Id, Name,  Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Current_Balance__c FROM Customer__c where id = :fuel.customerBillTo.Id limit 1];
     system.debug('billTo '+billTo);
     system.assertEquals(100,billTo.Current_Balance__c);
     system.assertEquals(0, billTo.X1_30_Days_Past_Due__c);
     system.assertEquals(0,billTo.X31_60_Days_Past_Due__c);
     system.assertEquals(0,billTo.X61_90_Days_Past_Due__c);
     system.assertEquals(0,billTo.More_Than_90_Days_Past_Due__c);
     Customer__c corp = [select Id, Name,  Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Current_Balance__c FROM Customer__c where id = :fuel.customerParent.Id limit 1];
     system.debug('corp '+corp);
     system.assertEquals(100,corp.Current_Balance__c);
     system.assertEquals(0, corp.X1_30_Days_Past_Due__c);
     system.assertEquals(0,corp.X31_60_Days_Past_Due__c);
     system.assertEquals(0,corp.X61_90_Days_Past_Due__c);
     system.assertEquals(0,corp.More_Than_90_Days_Past_Due__c);
     
    
  }
  
  static testMethod void test_Current_CloseCI(){ 
     
    TestFuelQuery fuel = new TestFuelQuery();
     
    Customer_Invoice__c CustomerInvoice = new Customer_Invoice__c();
	CustomerInvoice.Bill_To_Customer__c = fuel.customerBillTo.Id;
    CustomerInvoice.Company__c = fuel.company.Id;
    CustomerInvoice.Invoice_Type__c = 'Manual';
    CustomerInvoice.Status__c = CustomerInvoiceService.STATUS_OPEN;
    CustomerInvoice.Date_Invoiced__c = system.now().addDays(-10);
    CustomerInvoice.Transaction_Date__c = Date.today();
	Customer_Invoice__c CustomerInvoiceAA = createAllowanceAccrualCI();
	CustomerInvoiceAA.Date_Invoiced__c = system.now().addDays(-10);
	List<Customer_Invoice__c> cis = new List<Customer_Invoice__c>{CustomerInvoice,CustomerInvoiceAA};
	insert cis;
	
	Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
	cil.Customer_Invoice__c = CustomerInvoice.Id;
	cil.Quantity_Shipped__c = 1;
	cil.Unit_Price__c = 100;
	Customer_Invoice_Line__c CustomerInvoiceLineAA = createAllowanceAccrualCIL(CustomerInvoiceAA);
	List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>{cil,CustomerInvoiceLineAA};
	insert cils;
	
	CustomerInvoice.Finalized__c = true;
	CustomerInvoiceAA.Finalized__c = true;
	update cis;
	
	fuel.customerBillTo.Current_Balance__c = 100;
	update  fuel.customerBillTo;
	
	Customer__c billTo = [select Id, Name,  Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Current_Balance__c FROM Customer__c where id = :fuel.customerBillTo.Id limit 1];
    system.debug('billTo '+billTo);
    system.assertEquals(100,billTo.Current_Balance__c);
    
    CustomerInvoice.Amount_Paid__c = 100;
    CustomerInvoiceAA.Amount_Paid__c = 0;
    update cis;
	
     cis = [select id,Balance__c from Customer_Invoice__c where id in :cis];
     for (Customer_Invoice__c ci: cis){
        if ( ci.Id == CustomerInvoice.Id){
            system.assertEquals(0, ci.Balance__c);
        }
        else{
           system.assertEquals(-100, ci.Balance__c);
        }
     }
	test.startTest();
      CustomerAgingBatch agingBatch = new CustomerAgingBatch();
      agingBatch.runBatch(fuel.company.Id);
  	test.stopTest();
     
     
     cis = [select id, Status__c, Balance__c, Date_Invoiced__c, Amount_Past_Due__c, Date_Time_Paid__c, Days_Past_Due__c,  Days_to_Pay_30__c, Due_Date__c from Customer_Invoice__c where id in :cis];
     for (Customer_Invoice__c ci: cis){
         system.debug('CustomerInvoice '+ ci);
         system.assertEquals(0, ci.Days_Past_Due__c);
     }
     billTo = [select Id, Name,  Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Current_Balance__c FROM Customer__c where id = :fuel.customerBillTo.Id limit 1];
     system.debug('billTo '+billTo);
     system.assertEquals(0,billTo.Current_Balance__c);
     Customer__c corp = [select Id, Name,  Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Current_Balance__c FROM Customer__c where id = :fuel.customerParent.Id limit 1];
     system.debug('corp '+corp);
     system.assertEquals(0,corp.Current_Balance__c);
     
     
    
  }
}