@isTest public  class HierarchyTest {
    
    public class TestData {  
        Map<String,String> CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');
        
        public Account account = new Account(); {
            account = new Account();
            account.name = 'Kenandy';
            account.billingstreet = '2055 Woodside Rd. Ste 110';
            account.billingcity = 'Redwood City';
            account.billingstate = 'CA';
            account.billingpostalcode = '94061';
            account.billingcountry = 'USA';
            account.shippingstreet = '2055 Woodside Rd. Ste 110';
            account.shippingcity = 'Redwood City';
            account.shippingstate = 'CA';
            account.shippingpostalcode = '94061';
            account.shippingcountry = 'USA';
            account.phone = '650-468-2000';
            account.fax = '650-468-2010';
            account.website = 'kenandy.com';
            insert account;
        }
        
        public Company__c company = new Company__c(); {
            company = new Company__c();
            company.name = 'Kenandy';
            company.Address__c = account.ID;
            company.A_Days__c = 30;
            company.B_Days__c = 60;
            company.Comp_Currency__c = TestFuel.currencySGD.id;
            company.Consol_Currency__c = TestFuel.currencyEUR.id;
            company.Stat_Currency__c = TestFuel.currencyGBP.id;
            company.Subs_Currency__c = TestFuel.currencyUSD.id;
            company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
            company.C_Days__c = 180;
            insert company;
        }  
        public Payment_Term__c terms = new Payment_Term__c(); {
            terms.name = '10% Net 30'; 
            terms.Description__c = 'Ten Percent Net 30 Days';
            terms.Discount_Days__c = 30;
            terms.Discount_Percent__c = 10;
            terms.Due_Days__c = 60;
            insert terms; 
        }
        public Customer__c customer = new Customer__c(); {
            customer.name = 'Customer-1';
            customer.Company__c = company.id;
            customer.Payment_Term__c = terms.ID;
            //customer.Address__c = account.ID;
            customer.Credit_Limit__c = 100000.0;
            customer.recordTypeId = CustomerRecordTypes.get('Corporate_Parent');
            insert customer;
        }
        public Customer__c customer2 = new Customer__c(); {
            customer2.name = 'Customer-2';
            customer2.Company__c = company.id;
            customer2.Payment_Term__c = terms.ID;
            //customer2.Address__c = account.ID;
            customer2.Parent_Customer__c = customer.id;
            customer2.Top_parent_customer__c = customer.id;
            customer2.recordTypeId = CustomerRecordTypes.get('Bill_To');
            insert customer2;
        }
    }
    
    
    public static testmethod void hierarchy_errors() {
        HierarchyTest.TestData data = new HierarchyTest.TestData();
        
        Hierarchy hh = new Hierarchy();

        boolean sawEx ; 
        
        // check several error conditions
        sawEx = false; 
        try { hh = new Hierarchy(); hh.getHierarchy( data.customer.id ); } catch( Exception e) { sawEx = true; }
        system.assert(sawEx, 'expected to have an exception about missing object name');
        
        sawEx = false; 
        try { hh = new Hierarchy(); 
            hh.sobjectName = 'Customer__c';
            hh.getHierarchy( data.customer.id ); } catch( Exception e) { sawEx = true; }
        system.assert(sawEx, 'expected to have an exception about missing parent field name');
        
        sawEx = false; 
        try { hh = new Hierarchy(); 
            hh.sobjectName = 'Customer__c';
            hh.parentFieldName = 'Parent_Customer__c';
            hh.getHierarchy( data.customer.id ); } catch( Exception e) { sawEx = true; }
        system.assert(sawEx, 'expected to have an exception about missing parent field name');
        
        sawEx = false; 
        try { hh = new Hierarchy(); 
            hh.sobjectName = 'Customer__c';
            hh.parentFieldName = 'Parent_Customer__c';
            hh.getHierarchy( null ); } catch( Exception e) { sawEx = true; }
        system.assert(sawEx, 'expected to have an exception about missing record id');
        
        sawEx = false; 
        try { hh = new Hierarchy(); 
            hh.sobjectName = 'Customer__c';
            hh.parentFieldName = 'Parent_Customer__c';
            hh.getHierarchy( null ); } catch( Exception e) { sawEx = true; }
        system.assert(sawEx, 'expected to have an exception about missing topParentFieldName');
        
        // now a valid hier
        hh = new Hierarchy(); 
        hh.sobjectName = 'Customer__c';
        hh.parentFieldName = 'Parent_Customer__c';
        hh.topParentFieldName = 'Top_Parent_Customer__c';
        Hierarchy.Node nod =  hh.getHierarchy( data.customer2.id );
        system.assertNotEquals(null, nod, 'epxected a valid node tree');
        
        // .debug(LoggingLevel.INFO, nod);
        
        system.assertEquals( data.customer.id, nod.node.id );
        system.assertEquals( data.customer2.id, nod.children[0].node.get('id') );
    }
    
    
}