@isTest
private class CustomerInvoiceLineServiceTest {

    static testMethod void test_setLineNumbers() {
    	
    	
    	Customer_Invoice__c ci = new Customer_Invoice__c(Date_Invoiced__c = system.now(), Status__c = 'new', transaction_date__c = system.now());
    	insert ci;
    	
    	list<Customer_Invoice_Line__c> listCILs = new list<Customer_Invoice_Line__c>();
    	
    	listCILs.add(new Customer_Invoice_Line__c(Customer_Invoice__c = ci.id, Unit_Price__c = 1, Quantity_Shipped__c = 10, Extended_Price__c = 100));
    	listCILs.add(new Customer_Invoice_Line__c(Customer_Invoice__c = ci.id, Unit_Price__c = 1, Quantity_Shipped__c = 10, Extended_Price__c = 100));
    	listCILs.add(new Customer_Invoice_Line__c(Customer_Invoice__c = ci.id, Unit_Price__c = 2, Quantity_Shipped__c = 10, Extended_Price__c = 200, Line__c =311));
    	
    	insert listCILs;
    	
    	
    	for(Customer_Invoice_line__c cil : [Select id, Line__c, Extended_Price__c from Customer_Invoice_line__c where Customer_Invoice__c = :ci.Id])
    	{
    		system.assertNotEquals(null,cil.Line__c,'The Line number should never be null');
    		if(cil.Extended_Price__c == 200)
    			system.assertEquals(311,cil.Line__c,'User entered line number must be preserved');
    	}
    }
    
    static testMethod void test_setExtendedPrice_WFR() {
    	
    	
    	Customer_Invoice__c ci = new Customer_Invoice__c(Date_Invoiced__c = system.now(), Status__c = 'new', transaction_date__c = system.now());
    	insert ci;
    	
    	
    	insert new Customer_Invoice_Line__c(Customer_Invoice__c = ci.id, Unit_Price__c = 1, Quantity_Shipped__c = 100, Allowances__c = 10);
    	
    	Customer_Invoice_Line__c cil = [Select id, Line__c, Extended_Price__c from Customer_Invoice_line__c where Customer_Invoice__c = :ci.Id];
    	system.assertEquals(cil.Extended_Price__c, 110,'It should be unit price * qty shipped - allowances');
    	
    	cil.Freight_Allowance__c = 10;
    	update cil;
    	cil = [Select id, Line__c, Extended_Price__c from Customer_Invoice_line__c where Customer_Invoice__c = :ci.Id];
    	system.assertEquals(cil.Extended_Price__c, 100,'It should be unit price * qty shipped - allowances - Freight_Allowance__c');
    	
    }
    
    static testMethod void test_setExtendedPrice_Rounding() {
    	Customer_Invoice__c ci = new Customer_Invoice__c(Date_Invoiced__c = system.now(), Status__c = 'new', transaction_date__c = system.now());
    	insert ci;
    	
    	Customer_Invoice_Line__c cil1=new Customer_Invoice_Line__c(Customer_Invoice__c = ci.id, Unit_Price__c = 12.34, Quantity_Shipped__c = 13, Discount_Percent__c = 3.0);
    	Customer_Invoice_Line__c cil2=new Customer_Invoice_Line__c(Customer_Invoice__c = ci.id, Unit_Price__c = 2.565, Quantity_Shipped__c = 1, Discount_Percent__c = 0.0);//KNDY-19118

    	List<Customer_Invoice_Line__c> cils = new List<Customer_Invoice_Line__c>();
    	cils.add(cil1);
    	cils.add(cil2);
    	insert cils;
    	
    	cils = [Select id, Line__c, Extended_Price__c from Customer_Invoice_line__c where Customer_Invoice__c = :ci.Id];
    system.assertEquals(cils.size(), 2);
    	for ( Customer_Invoice_Line__c cil: cils){
    		if (cil.Id == cil1.Id){
    			system.assertEquals(cil.Extended_Price__c, 155.61,'Something went wrong');
    		}
    		else if (cil.Id == cil2.Id){//KNDY-19118
    			// 2.565 using half-up rounding is 2.57, half-even rounding is 2.56
    			system.assertEquals(cil.Extended_Price__c, 2.57,'Something went wrong');
    		}
    	}
    	
    }
}