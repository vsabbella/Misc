@isTest
public class SubledgerServiceTest {
    
    public static testMethod void testSubledgers(){
        
        TestFuel fuel = new TestFuel();
        
        List<Period__c> periods = fuel.periodList;
        Period__c p = periods[0];
        
        test.startTest();
        
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.AR, p, null,true);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.AP, p, null,true);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.RECEIVING, p, null,true);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.SHIPMENT, p, null,true);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.INVENTORY, p, null,true);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.FA, p, null,true);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.PERIOD, p, null,true);
        
        test.stopTest();
    }
    
    
    public static testMethod void testMultiCompany(){
    	
    	TestFuel fuel1 = new TestFuel();
    	List<Period__c> periods1 = fuel1.periodList;
    	Period__c p1;
    	for(Period__c p : periods1){
    		if(p.period_start__c <= system.now() && p.period_end__c > system.now()){
    			p1 = p;
    			break;
    		}
    	}
        
        Customer_Invoice__c custInv1 = new Customer_Invoice__c();
	    custInv1.Company__c = fuel1.company.id;
	    custInv1.Invoice_Type__c = 'Manual';
	    custInv1.Date_Invoiced__c = System.today();
	    custInv1.Sold_To_Customer__c = fuel1.customerSoldTo.id;
	    custInv1.Bill_To_Customer__c = fuel1.customerBillTo.id;
	    custInv1.Subtotal__c = 0;
	    custInv1.transaction_date__c = system.now();
	    custInv1.Currency__c = TestFuel.currencyUSD.id;
	    
	    insert custInv1;
	    
	    Customer_Invoice_Line__c custInvLine1 = new Customer_Invoice_Line__c();
	    custInvLine1.Company__c = fuel1.company.id;
	    custInvLine1.Quantity_Shipped__c = 2;
	    custInvLine1.Unit_Price__c = 7;
	    custInvLine1.Product__c = fuel1.product.id; 
	    custInvLine1.Discount_Percent__c = 0.2;
	    custInvLine1.Customer_Invoice__c = custInv1.id;
	    custInvLine1.Extended_Price__c = custInvLine1.Quantity_Shipped__c * custInvLine1.Unit_Price__c;
        insert custInvLine1;
        
        custInv1.finalized__c = true;
        update custInv1;

		List<Period__c> periods2 = fuel1.altCompanyPeriodList;
        Period__c p2;
        for(Period__c p : periods2){
    		if(p.period_start__c <= system.now() && p.period_end__c > system.now()){
    			p2 = p;
    			break;
    		}
    	}
        
     	test.startTest();
        system.assert(p1.period_start__c <= custInv1.Transaction_Date__c && custInv1.Transaction_Date__c < p1.period_end__c);
        
        List<Accounting_Entry__c> aes = [SELECT Id FROM Accounting_Entry__c WHERE Customer_Invoice__c = :custInv1.Id];
        system.assertEquals(0, aes.size(), aes);
        
        boolean ar1 = SubledgerService.isOpenForValidation(SubledgerService.Subledger.AR, p1, null,false);
        system.assertEquals(false, ar1, 'This subledger should not be open for validation');
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.AP, p1, null,false);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.RECEIVING, p1, null,false);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.SHIPMENT, p1, null,false);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.INVENTORY, p1, null,false);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.FA, p1, null,false);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.PERIOD, p1, null,false);
        
        boolean ar2 = SubledgerService.isOpenForValidation(SubledgerService.Subledger.AR, p2, null,false);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.AP, p2, null,false);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.RECEIVING, p2, null,false);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.SHIPMENT, p2, null,false);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.INVENTORY, p2, null,false);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.FA, p2, null,false);
        SubledgerService.isOpenForValidation(SubledgerService.Subledger.PERIOD, p2, null,false);
        
        test.stopTest();
        
        
    }
}