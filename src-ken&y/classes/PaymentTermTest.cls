@isTest
private class PaymentTermTest {

    static testMethod void testSuccess_Update() {
    	
        TestFuel fuel = new TestFuel();
        system.assert(fuel.terms.Id != null);
        
        fuel.terms.Name = 'New Name';
        update fuel.terms;
        fuel.terms = [select id, name from Payment_Term__c where id = :fuel.terms.id limit 1];
        system.assertEquals(fuel.terms.Name, 'New Name');
    }
    
    static testMethod void testSuccess_Delete() {
        TestFuel fuel = new TestFuel();
        system.assert(fuel.terms.Id != null);
        
        delete fuel.terms;
        list<Payment_Term__c> terms = [select id, name from Payment_Term__c ];
        system.assertEquals(terms.size(), 0);
    }
    
    static testMethod void testFail_Update() {
        
        
        TestFuel fuel = new TestFuel();
        system.assert(fuel.terms.Id != null);
        system.assert(fuel.custInv1.Id != null);
       
        fuel.terms.Name = 'New Name';
        try
        {
        	update fuel.terms;
        }
        catch(Exception ex)
        {
        	system.assert(ex.getMessage().contains(Label.CannotUpdateDeletePaymentTerms));
        }
        
        fuel.terms = [select id, name from Payment_Term__c where id = :fuel.terms.id limit 1];
        system.assertEquals(fuel.terms.Name, '2/10 Net 30');
   
    }
    
    static testMethod void testFail_Delete() {
        TestFuel fuel = new TestFuel();
        system.assert(fuel.terms.Id != null);
        system.assert(fuel.custInv1.Id != null);
       
        try
        {
        	delete fuel.terms;
        }
        catch(Exception ex)
        {
        	system.assert(ex.getMessage().contains(Label.CannotUpdateDeletePaymentTerms));
        }
        
        fuel.terms = [select id, name from Payment_Term__c where id = :fuel.terms.id limit 1];
        system.assertEquals(fuel.terms.Name, '2/10 Net 30');
    }
    
    static testMethod void PT_DueDayOfMonth () {
    	
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 6, Cut_Off_Day__c = 20, Months_Ahead__c = 0);
    	insert pt;
    	
    	pt = [Select Id from Payment_Term__c where Name = :'Test PT DDOM' limit 1];
    	system.assertNotEquals(null,pt.Id);
    }
    
    static testMethod void PT_DueDayOfMonth_failDayOFMonth_32 () {
    	
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 32, Cut_Off_Day__c = 20, Months_Ahead__c = 0);
    	
    	try {
    		insert pt;
    	}catch(Exception ex)
    	{
    		system.assert(ex.getMessage().contains('Day of month must be between 1 and 31'));
    	}
    	
    	list<Payment_Term__c> pts = [Select Id from Payment_Term__c where Name = :'Test PT DDOM' ];
    	system.assertEquals(0,pts.size());
    }
    
    static testMethod void PT_DueDayOfMonth_failDayOfMonth_0 () {
    	
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 0, Cut_Off_Day__c = 20, Months_Ahead__c = 0);
    	
    	try {
    		insert pt;
    	}catch(Exception ex)
    	{
    		system.assert(ex.getMessage().contains('Day of month must be between 1 and 31'));
    	}
    	
    	list<Payment_Term__c> pts = [Select Id from Payment_Term__c where Name = :'Test PT DDOM' ];
    	system.assertEquals(0,pts.size(), pts.size());
    }
    
    static testMethod void PT_DueDayOfMonth_failCutOffDay_0 () {
    	
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 6, Cut_Off_Day__c = 0, Months_Ahead__c = 0);
    	
    	try {
    		insert pt;
    	}catch(Exception ex)
    	{
    		system.assert(ex.getMessage().contains('Cut off day must be between 1 and 31'));
    	}
    	
    	list<Payment_Term__c> pts = [Select Id from Payment_Term__c where Name = :'Test PT DDOM' ];
    	system.assertEquals(0,pts.size());
    }
    
    static testMethod void PT_DueDayOfMonth_failCutOffDay_32 () {
    	
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 6, Cut_Off_Day__c = 32, Months_Ahead__c = 0);
    	
    	try {
    		insert pt;
    	}catch(Exception ex)
    	{
    		system.assert(ex.getMessage().contains('Cut off day must be between 1 and 31'));
    	}
    	
    	list<Payment_Term__c> pts = [Select Id from Payment_Term__c where Name = :'Test PT DDOM' ];
    	system.assertEquals(0,pts.size());
    }
    
    static testMethod void PT_DueDayOfMonth_failMonthsAhead_0 () {
    	
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 6, Cut_Off_Day__c = 20, Months_Ahead__c =-1);
    	
    	try {
    		insert pt;
    	}catch(Exception ex)
    	{
    		system.assert(ex.getMessage().contains('Months ahead must be between 0 and 12'));
    	}
    	
    	list<Payment_Term__c> pts = [Select Id from Payment_Term__c where Name = :'Test PT DDOM' ];
    	system.assertEquals(0,pts.size());
    }
    
    static testMethod void PT_DueDayOfMonth_failCutOffDay_13 () {
    	
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 6, Cut_Off_Day__c = 20, Months_Ahead__c = 13);
    	
    	try {
    		insert pt;
    	}catch(Exception ex)
    	{
    		system.assert(ex.getMessage().contains('Months ahead must be between 0 and 12'));
    	}
    	
    	list<Payment_Term__c> pts = [Select Id from Payment_Term__c where Name = :'Test PT DDOM' ];
    	system.assertEquals(0,pts.size());
    }
    
    static testMethod void PT_Type_Error_DueDays() {
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Due_Days__c = 30);
    	
    	try {
    		insert pt;
    	}catch(Exception ex)
    	{
    		system.assert(ex.getMessage().contains('Please enter due day of month, cut off day and months ahead for the selected payment term type.'));
    	}
    	
    	list<Payment_Term__c> pts = [Select Id from Payment_Term__c where Name = :'Test PT DDOM' ];
    	system.assertEquals(0,pts.size());
    }
    
    static testMethod void PT_Type_Error_DueDayOfMonth() {
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAYS,  Day_Of_Month__c = 6, Cut_Off_Day__c = 20, Months_Ahead__c = 3);
    	
    	try {
    		insert pt;
    	}catch(Exception ex)
    	{
    		system.assert(ex.getMessage().contains('Please enter due days for the selected payment term type.'));
    	}
    	
    	list<Payment_Term__c> pts = [Select Id from Payment_Term__c where Name = :'Test PT DDOM' ];
    	system.assertEquals(0,pts.size());
    }
    
    static testMethod void PT_PaymentDateOnCI_25_10_0_NormalCase() {
    	
    	TestFuel fuel = new TestFuel();
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 10, Cut_Off_Day__c = 25, Months_Ahead__c = 0);
    	insert pt;
    	
    	system.assertNotEquals(null,pt.Id);
    	
    	fuel.customerBillTo.Payment_Term__c = pt.Id;
    	update fuel.customerBillTo;
    	
    	Customer_Invoice__c ci = new Customer_Invoice__c(Company__c = fuel.company.Id, Bill_To_Customer__c = fuel.customerBillTo.Id, Invoice_Type__c = CustomerInvoiceService.TYPE_MANUAL, Date_Invoiced__c = DateTime.newInstance(2015, 6, 8) );
    	insert ci;
    	
    	ci = [select id, Due_Date__c from Customer_Invoice__c where id = :ci.Id limit 1];
    	system.assertEquals(Date.newInstance(2015,6,10),ci.Due_Date__c);
    	
    	
    }
    
    static testMethod void PT_PaymentDateOnCI_25_10_0_DueDate_aheadOf_InvoicedDate() {
    	
    	TestFuel fuel = new TestFuel();
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 10, Cut_Off_Day__c = 25, Months_Ahead__c = 0);
    	insert pt;
    	
    	system.assertNotEquals(null,pt.Id);
    	
    	fuel.customerBillTo.Payment_Term__c = pt.Id;
    	update fuel.customerBillTo;
    	
    	Customer_Invoice__c ci = new Customer_Invoice__c(Company__c = fuel.company.Id, Bill_To_Customer__c = fuel.customerBillTo.Id, Invoice_Type__c = CustomerInvoiceService.TYPE_MANUAL, Date_Invoiced__c = DateTime.newInstance(2015, 6, 10) );
    	insert ci;
    	
    	ci = [select id, Due_Date__c from Customer_Invoice__c where id = :ci.Id limit 1];
    	system.assertEquals(Date.newInstance(2015,7,10),ci.Due_Date__c);
    	
    	
    }
    
    static testMethod void PT_PaymentDateOnCI_25_10_0_aheadOf_CutOFFDay() {
    	
    	TestFuel fuel = new TestFuel();
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 10, Cut_Off_Day__c = 25, Months_Ahead__c = 0);
    	insert pt;
    	
    	system.assertNotEquals(null,pt.Id);
    	
    	fuel.customerBillTo.Payment_Term__c = pt.Id;
    	update fuel.customerBillTo;
    	
    	Customer_Invoice__c ci = new Customer_Invoice__c(Company__c = fuel.company.Id, Bill_To_Customer__c = fuel.customerBillTo.Id, Invoice_Type__c = CustomerInvoiceService.TYPE_MANUAL, Date_Invoiced__c = DateTime.newInstance(2015, 6, 26) );
    	insert ci;
    	
    	ci = [select id, Due_Date__c from Customer_Invoice__c where id = :ci.Id limit 1];
    	system.assertEquals(Date.newInstance(2015,7,10),ci.Due_Date__c);
    	
    	
    }
    
    static testMethod void PT_PaymentDateOnCI_25_10_1_NormalCase() {
    	
    	TestFuel fuel = new TestFuel();
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 10, Cut_Off_Day__c = 25, Months_Ahead__c = 1);
    	insert pt;
    	
    	system.assertNotEquals(null,pt.Id);
    	
    	fuel.customerBillTo.Payment_Term__c = pt.Id;
    	update fuel.customerBillTo;
    	
    	Customer_Invoice__c ci = new Customer_Invoice__c(Company__c = fuel.company.Id, Bill_To_Customer__c = fuel.customerBillTo.Id, Invoice_Type__c = CustomerInvoiceService.TYPE_MANUAL, Date_Invoiced__c = DateTime.newInstance(2015, 6, 8) );
    	insert ci;
    	
    	ci = [select id, Due_Date__c from Customer_Invoice__c where id = :ci.Id limit 1];
    	system.assertEquals(Date.newInstance(2015,7,10),ci.Due_Date__c);
    	
    	
    }
    
    static testMethod void PT_PaymentDateOnCI_25_10_1_DueDate_aheadOf_InvoicedDate() {
    	
    	TestFuel fuel = new TestFuel();
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 10, Cut_Off_Day__c = 25, Months_Ahead__c = 1);
    	insert pt;
    	
    	system.assertNotEquals(null,pt.Id);
    	
    	fuel.customerBillTo.Payment_Term__c = pt.Id;
    	update fuel.customerBillTo;
    	
    	Customer_Invoice__c ci = new Customer_Invoice__c(Company__c = fuel.company.Id, Bill_To_Customer__c = fuel.customerBillTo.Id, Invoice_Type__c = CustomerInvoiceService.TYPE_MANUAL, Date_Invoiced__c = DateTime.newInstance(2015, 6, 10) );
    	insert ci;
    	
    	ci = [select id, Due_Date__c from Customer_Invoice__c where id = :ci.Id limit 1];
    	system.assertEquals(Date.newInstance(2015,7,10),ci.Due_Date__c);
    	
    	
    }
    
    static testMethod void PT_PaymentDateOnCI_25_10_1_aheadOf_CutOFFDay() {
    	
    	TestFuel fuel = new TestFuel();
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 10, Cut_Off_Day__c = 25, Months_Ahead__c = 1);
    	insert pt;
    	
    	system.assertNotEquals(null,pt.Id);
    	
    	fuel.customerBillTo.Payment_Term__c = pt.Id;
    	update fuel.customerBillTo;
    	
    	Customer_Invoice__c ci = new Customer_Invoice__c(Company__c = fuel.company.Id, Bill_To_Customer__c = fuel.customerBillTo.Id, Invoice_Type__c = CustomerInvoiceService.TYPE_MANUAL, Date_Invoiced__c = DateTime.newInstance(2015, 6, 26) );
    	insert ci;
    	
    	ci = [select id, Due_Date__c from Customer_Invoice__c where id = :ci.Id limit 1];
    	system.assertEquals(Date.newInstance(2015,8,10),ci.Due_Date__c);
    	
    	
    }
    
    static testMethod void PT_PaymentDateOnCI_30_31_0_aheadOf_CutOFFDay() {
    	
    	TestFuel fuel = new TestFuel();
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 31, Cut_Off_Day__c = 30, Months_Ahead__c = 0);
    	insert pt;
    	
    	system.assertNotEquals(null,pt.Id);
    	
    	fuel.customerBillTo.Payment_Term__c = pt.Id;
    	update fuel.customerBillTo;
    	
    	Customer_Invoice__c ci = new Customer_Invoice__c(Company__c = fuel.company.Id, Bill_To_Customer__c = fuel.customerBillTo.Id, Invoice_Type__c = CustomerInvoiceService.TYPE_MANUAL, Date_Invoiced__c = DateTime.newInstance(2015, 2, 10) );
    	insert ci;
    	
    	ci = [select id, Due_Date__c from Customer_Invoice__c where id = :ci.Id limit 1];
    	system.assertEquals(Date.newInstance(2015,2,28),ci.Due_Date__c);
    	
    	
    }
    
    static testMethod void PT_PaymentDateOnCI_30_30_0_aheadOf_CutOFFDay() {
    	
    	TestFuel fuel = new TestFuel();
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 30, Cut_Off_Day__c = 30, Months_Ahead__c = 0);
    	insert pt;
    	
    	system.assertNotEquals(null,pt.Id);
    	
    	fuel.customerBillTo.Payment_Term__c = pt.Id;
    	update fuel.customerBillTo;
    	
    	Customer_Invoice__c ci = new Customer_Invoice__c(Company__c = fuel.company.Id, Bill_To_Customer__c = fuel.customerBillTo.Id, Invoice_Type__c = CustomerInvoiceService.TYPE_MANUAL, Date_Invoiced__c = DateTime.newInstance(2015, 2, 10) );
    	insert ci;
    	
    	ci = [select id, Due_Date__c from Customer_Invoice__c where id = :ci.Id limit 1];
    	system.assertEquals(Date.newInstance(2015,2,28),ci.Due_Date__c);
    	
    	
    }
    	
    static testMethod void PT_PaymentDateOnCI_30_29_0_aheadOf_CutOFFDay() {
    	
    	TestFuel fuel = new TestFuel();
    	Payment_Term__c pt = new Payment_Term__c (Name= 'Test PT DDOM', Type__c = KSE.PAYMENT_TERM_DUE_DAY_OF_MONTH, Day_Of_Month__c = 29, Cut_Off_Day__c = 30, Months_Ahead__c = 0);
    	insert pt;
    	
    	system.assertNotEquals(null,pt.Id);
    	
    	fuel.customerBillTo.Payment_Term__c = pt.Id;
    	update fuel.customerBillTo;
    	
    	Customer_Invoice__c ci = new Customer_Invoice__c(Company__c = fuel.company.Id, Bill_To_Customer__c = fuel.customerBillTo.Id, Invoice_Type__c = CustomerInvoiceService.TYPE_MANUAL, Date_Invoiced__c = DateTime.newInstance(2015, 2, 10) );
    	insert ci;
    	
    	ci = [select id, Due_Date__c from Customer_Invoice__c where id = :ci.Id limit 1];
    	system.assertEquals(Date.newInstance(2015,2,28),ci.Due_Date__c);
    	
    	
    }
    	
    
    
}