/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 */
@isTest
private class DynatreeTest {

	class TestData {
		public Payment_Term__c terms = new Payment_Term__c(); {
	        terms.name = '10% Net 30'; 
	        terms.Description__c = 'Ten Percent Net 30 Days';
	        terms.Discount_Days__c = 30;
	        terms.Discount_Percent__c = 10;
	        terms.Due_Days__c = 60;
	        insert terms; 
	    }
	    public Company__c company = new Company__c(); {
	        company = new Company__c();
	        company.name = 'Kenandy';
	        company.A_Days__c = 30;
	        company.B_Days__c = 60;
	        company.C_Days__c = 180;
	        company.Comp_Currency__c = TestFuel.currencySGD.id;
	        company.Consol_Currency__c = TestFuel.currencyEUR.id;
	        company.Stat_Currency__c = TestFuel.currencyGBP.id;
	        company.Subs_Currency__c = TestFuel.currencyUSD.id;
	        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;	        
	        insert company;
	    }  
	    public Customer__c customer = new Customer__c(); {
	        customer.name = 'Customer-1';
	        customer.Company__c = company.id;
	        customer.Payment_Term__c = terms.ID;
	      //  customer.Address__c = soldtoaccount.ID;
	        customer.Credit_Limit__c = 100000.0;
	        insert customer;
	    }	 
	   	public Account remittoaccount = new Account(); {
		    remittoaccount = new Account();
		    remittoaccount.name = 'Remit-to Account';
		    remittoaccount.billingstreet = '1 Boardwalk Dr';
		    remittoaccount.billingcity = 'Santa Jose';
		    remittoaccount.billingstate = 'CA';
		    remittoaccount.billingpostalcode = '95205';
		    remittoaccount.phone = '408-555-1965';
		    remittoaccount.fax = '408-555-8341';
		    insert remittoaccount;
		}
		
		public map <string,string> rtMap = KSE.RecordTypeDevNameMap('Supplier__c');
        
        public Supplier__c supplier = new Supplier__c(); {
	        supplier.Name =  'Supplier-1';
	        supplier.Company__c = company.ID;
	        supplier.Tax_ID__c = 'tax ID';
	        supplier.Address__c = remittoaccount.ID;
	        supplier.Status__c = 'Active';
	        supplier.Payment_Term__c = terms.ID;
	        supplier.Type__c = 'Remit-To';
        	supplier.RecordTypeId = rtMap.get('Remit_To');
	        insert supplier;
	    }     
	}
	
	public static testmethod void t1() { 
		TestData data = new TestData(); 
	
		Hierarchy.Node nod =Dynatree.getHierarchy( data.customer.id , 'Overview') ;
		system.assertEquals( data.customer.id, nod.node.id);
	}

}