@isTest
public with sharing class CustomerNewTest {

    public static string CompanyId;
    static Map<String,String> CustomerRecordTypes;
    public static void populateValues(){
        
        CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');
        
        Company__c testCompany;
        
        if(companyId == null ){
            
            testCompany = new Company__c(name='Kenandy');
                    testCompany.Comp_Currency__c = TestFuel.currencySGD.id;
                    testCompany.Consol_Currency__c = TestFuel.currencyEUR.id;
                    testCompany.Stat_Currency__c = TestFuel.currencyGBP.id;
                    testCompany.Subs_Currency__c = TestFuel.currencyUSD.id;
                    testCompany.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
            insert testCompany;
            CompanyId = testCompany.id;
        }
        
        //system.debug('populate_values_companyid'+CompanyId);
        
    }

    public static testmethod void createCorporateCustomer(){
        
        populateValues();
        Customer__c testCustomer = new Customer__c(name='Test Corporate Customer', recordtypeid = CustomerRecordTypes.get('Corporate_Parent') ,
        Company__c = CompanyId);
        
        CustomerNewExtension cn = new CustomerNewExtension(new Apexpages.Standardcontroller(testCustomer));
        cn.customer.recordtypeid=CustomerRecordTypes.get('Corporate_Parent');
        cn.RecordTypeDeveloperName = 'Corporate_Parent';
    	cn.getRecordTypes();
        
        system.assertNotEquals(null, cn.CopyFromParent);
        cn.doContinue();
        
        cn.customer = testCustomer;
            
        cn.doSave();
        
        Test.startTest();
        
        List<Customer__c> cList = [SELECT Id, Name FROM Customer__c where Name = 'Test Corporate Customer' ];
        
        System.assert( cList.size() == 1 );
        System.assert( cList[0].name == 'Test Corporate Customer');
        //System.assertEquals('Customer', cList[0].Address__r.Type);

        Test.stopTest();
        
    }
    
    public static testmethod void createBillToCustomer(){
        
        populateValues();
        
        Customer__c testParentCustomer = new Customer__c(name='Test Corporate Customer', recordtypeid = CustomerRecordTypes.get('Corporate_Parent'),
        Company__c = CompanyId);
        insert testParentCustomer;
        
        Customer__c testCustomer = new Customer__c(name='Test Billing Customer',parent_customer__c=testParentCustomer.id, recordtypeid = CustomerRecordTypes.get('Bill_To'));
        

        
        CustomerNewExtension cn = new CustomerNewExtension(new Apexpages.Standardcontroller(testCustomer));
        cn.customer.recordtypeid=CustomerRecordTypes.get('Bill_To');
        cn.customer.parent_customer__c = testParentCustomer.id;
        cn.RecordTypeDeveloperName = 'Bill_To';
        cn.CopyFromParent = true;
        cn.doContinue();
        
        cn.customer = testCustomer;
        
        
        //cn.customer.name = ''; //cause a DML exception 
        
        //cn.doSave();
        
        
        cn.customer.name = 'testBillCustomer';
        
        cn.doSave();
        
        Test.startTest();
        
        List<Customer__c> cList = [SELECT Id, Name FROM Customer__c where Name = 'testBillCustomer' ];
        
        System.assert( cList.size() == 1 , cn.customer);
        System.assert( cList[0].name == 'testBillCustomer');

        Test.stopTest();
    
        
    }
    
    public static testmethod void createSoldToCustomer(){
        
        populateValues();
        Customer__c testParentCustomer = new Customer__c(name='Test Corporate Customer', recordtypeid = CustomerRecordTypes.get('Corporate_Parent'),
        Company__c = CompanyId);
        insert testParentCustomer;
        Customer__c testBillingCustomer = new Customer__c(name='Test Billing Customer',parent_customer__c=testParentCustomer.id, recordtypeid = CustomerRecordTypes.get('Bill_To'),
        Company__c = CompanyId);
        insert testBillingCustomer;
        Customer__c testCustomer = new Customer__c(name='Test Sold Customer',parent_customer__c=testBillingCustomer.id, recordtypeid = CustomerRecordTypes.get('Sold_To'),
        Company__c = CompanyId);
        
        CustomerNewExtension cn = new CustomerNewExtension(new Apexpages.Standardcontroller(testCustomer));
        cn.customer.recordtypeid=CustomerRecordTypes.get('Sold_To');
        cn.RecordTypeDeveloperName = 'Sold_To';
        cn.CopyFromParent = false;
        cn.doContinue();
        
        cn.customer = testCustomer;
        cn.doSave();
        
        Test.startTest();
        
        List<Customer__c> cList = [SELECT Id, Name FROM Customer__c where Name = 'Test Sold Customer' ];
        
        System.assert( cList.size() == 1 );
        System.assert( cList[0].name == 'Test Sold Customer');
        //System.assertEquals('Customer', cList[0].Address__r.Type);

        Test.stopTest();
        
        
    }
    
    public static testmethod void updateBillToCustomer(){
		
		populateValues();
		Customer__c testCustomer = new Customer__c(name='Test Update Customer', recordtypeid = CustomerRecordTypes.get('Corporate_Parent'),
		Company__c = CompanyId);
		
		insert testCustomer;
		
		//Account address = new Account(name='address', BillingStreet = 'test Street');
		//insert address;
		
		Customer__c testBillToCustomer = new Customer__c(name='Test Update BillTo Customer', recordtypeid = CustomerRecordTypes.get('Bill_To'),
		Company__c = CompanyId,Parent_Customer__c = testCustomer.Id, Customer_Street__c = 'test Street');
		
		insert testBillToCustomer;
		
		
		
		CustomerEditExtension ce = new CustomerEditExtension(new Apexpages.Standardcontroller(testBillToCustomer));
		ce.customer.name = 'test';
		
		
		
		ce.customer.Customer_Street__c = 'testStreetChange';

		ce.customer.status__c = 'Inactive';
		ce.customer.name = 'test1';
		
		//ce.showPopup();
		ce.doSave();
		Test.startTest();

		Customer__c testBill = [ Select Id, Status__c, name, Customer_Street__c from Customer__c where id =: testBillToCustomer.id ];
		
		system.assert( testBill.Status__c == 'Inactive',testBill);
		system.assert( testBill.Name == 'test1');
		system.assert( testBill.Customer_Street__c == 'testStreetChange');

		Test.stopTest();
	}
	/* KNDY-10333
	public static testmethod void testUnlink(){
		
		populateValues();
		//Account address = new Account(name='address', BillingStreet = 'test Street');
		//insert address;
		
		Customer__c testCustomer = new Customer__c(name='Test Update Customer', recordtypeid = CustomerRecordTypes.get('Corporate_Parent'),
		Company__c = CompanyId,Customer_Street__c = 'test Street');
		insert testCustomer;
		
		Customer__c testBillToCustomer = new Customer__c(name='Test Update BillTo Customer', recordtypeid = CustomerRecordTypes.get('Bill_To'),
		Company__c = CompanyId,Parent_Customer__c = testCustomer.Id, Customer_Street__c = 'test Street');
		insert testBillToCustomer;
		
		CustomerEditExtension ce = new CustomerEditExtension(new Apexpages.Standardcontroller(testBillToCustomer));
		ce.customer.Customer_Street__c = 'test Change Street';
		ce.doSave();
		//ce.closePopup();
		//ce.showPopup();
		//ce.unLinkAddress();
		test.startTest();
		Customer__c testBillCustomer = [Select address__c, Customer_Street__c from Customer__c where id=:testBillToCustomer.id];
		Customer__c testCorpCustomer = [Select address__c, Customer_Street__c from Customer__c where id=:testCustomer.id];
		
		//System.assertNotEquals(String.ValueOf(testBillCustomer.address__c),String.ValueOf(testCorpCustomer.address__c));
		system.assert( testCorpCustomer.Customer_Street__c  == 'test Street', testCorpCustomer.Customer_Street__c+','+testBillCustomer.Customer_Street__c);
		system.assert( testBillCustomer.Customer_Street__c  == 'test Change Street');
		
		
		test.stopTest();
	}
    */
	
	public static testmethod void validateChangingParentCustomer(){
		
		populateValues();
		Customer__c testCustomer = new Customer__c(name='Test Update Customer', recordtypeid = CustomerRecordTypes.get('Corporate_Parent'),
		Company__c = CompanyId);
		
		insert testCustomer;
		
		//Account address = new Account(name='address', BillingStreet = 'test Street');
		//insert address;
		
		Customer__c testBillToCustomer = new Customer__c(name='Test Update BillTo Customer', recordtypeid = CustomerRecordTypes.get('Bill_To'),
		Company__c = CompanyId,Parent_Customer__c = testCustomer.Id, Customer_Street__c = 'test Street');
		
		insert testBillToCustomer;
		
		Customer__c testSoldToCustomer = new Customer__c(name='Test Sold Customer', Parent_Customer__c = testBillToCustomer.Id, 
                                                         RecordTypeId = CustomerRecordTypes.get('Sold_To'), Company__c = CompanyId);
        insert testSoldToCustomer;

		Customer__c testBill = [ Select Id, Status__c, name, Customer_Street__c from Customer__c where id =: testBillToCustomer.id ];
        testBill.Parent_Customer__c = testSoldToCustomer.Id;

        boolean sawException = false;
        
        try{
            update testBill;
        } catch(Exception e){
            String message = e.getMessage();
            System.assert(message.contains('Invalid Parent Record Type'));
            sawException = true;
        }

        System.assertEquals(true, sawException);

	}
	/* KNDY - 10333
	public static testmethod void changeAllRelatedAddresses(){
		
		populateValues();
		Account address = new Account(name='address', BillingStreet = 'test Street');
		insert address;
		
		Customer__c testCustomer = new Customer__c(name='Test Update Customer', recordtypeid = CustomerRecordTypes.get('Corporate_Parent'),
		Company__c = CompanyId,address__c = address.id);
		insert testCustomer;
		
		Customer__c testBillToCustomer = new Customer__c(name='Test Update BillTo Customer', recordtypeid = CustomerRecordTypes.get('Bill_To'),
		Company__c = CompanyId,Parent_Customer__c = testCustomer.Id, Address__c = address.id);
		insert testBillToCustomer;
		
		CustomerEditExtension ce = new CustomerEditExtension(new Apexpages.Standardcontroller(testBillToCustomer));
		
		ce.theAccount.BillingStreet = 'test Change Street';
		ce.showPopup();
		ce.closePopup();
		ce.showPopup();
		ce.continueSave();
		test.startTest();
		Customer__c testBillCustomer = [Select address__c, Address__r.BillingStreet from Customer__c where id=:testBillToCustomer.id];
		Customer__c testCorpCustomer = [Select address__c from Customer__c where id=:testCustomer.id];
		
		System.assertEquals(String.ValueOf(testBillCustomer.address__c),String.ValueOf(testCorpCustomer.address__c));
		system.assert( testBillCustomer.Address__r.BillingStreet == 'test Change Street' );
		
		test.stopTest();
	}
    */
    public static testmethod void testCancel(){
        populateValues();
        Customer__c testCustomer = new Customer__c(name='Test Corporate Customer', recordtypeid = CustomerRecordTypes.get('Corporate_Parent'),
        Company__c = CompanyId);
        CustomerNewExtension cn = new CustomerNewExtension(new Apexpages.Standardcontroller(testCustomer));
        cn.customer = testCustomer;
        Test.setCurrentPage(cn.doCancel());
        
        Test.StartTest();
        Schema.DescribeSObjectResult dsr = Customer__c.SObjectType.getDescribe();
        Test.StopTest();
        
        
        System.assert(ApexPages.currentPage().getUrl()=='/'+dsr.getKeyPrefix()+'/o');
    }
    
    public static testmethod void testCancelEdit(){
		populateValues();
		Customer__c testCustomer = new Customer__c(name='Test Corporate Customer', recordtypeid = CustomerRecordTypes.get('Corporate_Parent'),
		Company__c = CompanyId);
		
		insert testCustomer;
		CustomerEditExtension ce = new CustomerEditExtension(new Apexpages.Standardcontroller(testCustomer));
		
		Test.setCurrentPage(ce.doCancel());

		System.assert(ApexPages.currentPage().getUrl()=='/'+testCustomer.id);
	}
    
    public static testmethod void testLookupZipcode(){
        
        populateValues();
        Customer__c testCustomer = new Customer__c(name='Test Corporate Customer', recordtypeid = CustomerRecordTypes.get('Corporate_Parent'),
        Company__c = CompanyId, Customer_Street__c = '8 Wildwood Drive',Customer_State__c = 'CT', Customer_City__c = 'Old Lyme');
        
    
        CustomerNewExtension cn = new CustomerNewExtension(new Apexpages.Standardcontroller(testCustomer));
    
    
        cn.lookupZipcode();
    
        //Account a = new Account(name='Tester', BillingStreet='8 Wildwood Drive', 
        //    BillingCity ='Old Lyme', BillingState = 'CT');
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<String> AddressString  = ZipcodeLookup.callApiWithRequest(testCustomer.id, null, testCustomer.Customer_Street__c, testCustomer.Customer_City__c, testCustomer.Customer_State__c);
        if(AddressString != null){
            
            testCustomer.Customer_Street__c = AddressString[0];
            testCustomer.Customer_City__c = AddressString[1];
            testCustomer.Customer_State__c = AddressString[2];
            testCustomer.Customer_Zip_Code__c = AddressString[3];
             
        }   
        
        Test.stopTest();
        
        
        System.AssertEquals('06371-1844', testCustomer.Customer_Zip_Code__c);
    }
    
    public static testmethod void testLookupZipcodeEditErrorHandling(){
        
        populateValues();
        Customer__c testCustomer = new Customer__c(name='Test Corporate Customer', recordtypeid = CustomerRecordTypes.get('Corporate_Parent'),
        Company__c = CompanyId, Customer_Street__c = '8 Wildwood Drive',Customer_State__c = 'CT', Customer_City__c = 'Old Lyme');
        
        
        CustomerNewExtension cn = new CustomerNewExtension(new Apexpages.Standardcontroller(testCustomer));
        
        
        //Account a = new Account(name='Tester', BillingStreet='8 Wildwood Drive', 
        //    BillingCity ='Old Lyme', BillingState = 'CT');
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseErrorGenerator());
        //cn.theAccount = a;
        cn.lookupZipcode();

        Test.stopTest();
        system.assert(ApexPages.getMessages().size() > 0, ApexPages.getMessages() ); 
        //KNDY-3519
        //System.debug('check this message'+ApexPages.getMessages().get(0).getDetail());
        //system.assert(ApexPages.getMessages().get(0).getDetail().containsIgnoreCase('Address not found') );
    }
    
    public static testmethod void testLookupZipcodeEdit(){
		
		populateValues();
		Customer__c testCustomer = new Customer__c(name='Test Corporate Customer', recordtypeid =  CustomerRecordTypes.get('Corporate_Parent'),
		Company__c = CompanyId, Customer_Street__c = '8 Wildwood Drive',Customer_State__c = 'CT', Customer_City__c = 'Old Lyme');
		insert testCustomer;
		
		CustomerEditExtension ce = new CustomerEditExtension(new Apexpages.Standardcontroller(testCustomer));
		
		
		//Account a = new Account(name='Tester', BillingStreet='8 Wildwood Drive', 
  //          BillingCity ='Old Lyme', BillingState = 'CT');
    	
    		Test.startTest();
			Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    		//ce.theAccount = a;
    		ce.lookupZipcode();
    	//	a.BillingPostalCode = ZipcodeLookup.callApiWithRequest(a.id, null, a.BillingStreet, a.BillingCity, a.BillingState);
    			
    		
    		Test.stopTest();
			System.AssertEquals('06371-1844',ce.customer.Customer_Zip_Code__c);
	}
    
    public static testMethod void createCustomerWithAddressValidation(){
        
        CompanyId = 'test';
        
        populateValues();
        
        Customer__c testCustomer = new Customer__c(name='Test Corporate Customer', recordtypeid = CustomerRecordTypes.get('Corporate_Parent'),
                                                    Customer_Street__c = '8 Wildwood Drive',Customer_State__c = 'CT', Customer_City__c = 'Old Lyme');
        
        CustomerNewExtension cn = new CustomerNewExtension(new Apexpages.Standardcontroller(testCustomer));
        cn.customer.recordtypeid=CustomerRecordTypes.get('Corporate_Parent');
        cn.RecordTypeDeveloperName = 'Corporate_Parent';
        cn.getRecordTypes();
        cn.doContinue();
        
        cn.customer = testCustomer;
        
        
        //Account a = new Account(name='Tester', BillingStreet='8 Wildwood Drive', 
        //        BillingCity ='Old Lyme', BillingState = 'CT');
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        //cn.theAccount = a;
        cn.lookupZipcode();
        
        Test.stopTest();
        
        System.AssertEquals('06371-1844',cn.customer.Customer_Zip_Code__c);
        System.assertEquals('8 WILDWOOD DR', cn.customer.Customer_Street__c);
    }
    
    /** 
     * test that we can insert a bill to and the customer parent lookup will be 
     * populated correctly using only customer_Parent_identifier field
     */
    public static testMethod void testCustomerLoad() {
        TestFuel data = new TestFuel();
        system.assert( data.customerParent != null , ' create the parent');
        system.assert( data.customerParent.id != null , ' create the parent');
        system.assert( data.customerParent.Customer_identifier__c !=null , 'expected a customer identifier');
		
        system.assert( data.terms != null, 'create terms');
        system.assert( data.terms.Name != null ,' create terms name');
        data.customerBillTo = new Customer__c(); 
        data.customerBillTo.name = 'Customer Bill To 1';
        data.customerBillTo.recordTypeId = data.CustomerRecordTypes.get('Bill_To');
        data.customerBillTo.Company__c = data.company.id;
        // workflow coppies name to payment_term_unique if that changes this will also need to change
        data.customerBillTo.Payment_Term_Identifier__c = data.terms.Name; 
        
        //data.customerBillTo.Address__c = data.account.ID;
        data.customerBillTo.Credit_Limit__c = 100000.0;
        data.customerBillTo.Parent_Customer__c = null;
        data.customerBillTo.Customer_Identifier__c = 'BDTEST123'; 
        data.customerBillTo.Parent_Customer_Identifier__c = data.customerParent.Customer_identifier__c;
        insert data.customerBillTo;
 
        system.assert( data.customerBillTo != null ,' create bill to');
        data.customerBillTo = [ select id, Parent_Customer__c , payment_term__c
                          from Customer__c where id = :data.customerBillTo.id limit 1];
        system.assert( data.customerBillTo.Parent_Customer__c == data.customerParent.id , 
                      ' expected Parent_Customer__c to be set');
        
        system.assert( data.customerBillTo.Payment_term__c != null, ' expected terms lookup to be set');
    }

    public static testMethod void customerApproveDeactivateTest(){
        TestFuel data = new TestFuel();
        system.assert( data.customerParent != null , ' create the parent');
        system.assert( data.customerBillTo != null , ' create the Bill To');
        system.assert( data.customerSoldTo != null , ' create the Sold To');
        system.assert( data.customerShipTo != null , ' create the Ship To');
        system.assert( data.customerSite != null , ' create the Site');
        Set<Id> customerIds = new Set<Id> { data.customerParent.Id, data.customerBillTo.Id, data.customerSoldTo.Id, data.customerShipTo.Id, data.customerSite.Id };

        CustomerEditExtension custExt = new CustomerEditExtension(new Apexpages.Standardcontroller(data.customerParent));
        //Deactivate customer
        custExt.deactivate();

        List<Customer__c> inactiveCustomers = [Select Id,
                                              Status__c
                                         From Customer__c
                                        Where Id in :customerIds];

        for (Customer__c inactiveCust : inactiveCustomers) {
            System.assert(inactiveCust.Status__c == CustomerService.CUST_STATUS_INACTIVE, 'Customer is expected to be inactive : ' + inactiveCust);
        }

        //Approve customer
        custExt.approve();

        List<Customer__c> approvedCustomers = [Select Id,
                                                      Status__c
                                                 From Customer__c
                                                Where Id in :customerIds];

        for (Customer__c approvedCust : approvedCustomers) {
            System.assert(approvedCust.Status__c == CustomerService.CUST_STATUS_APPROVED, 'Customer is expected to be Approved : ' + approvedCust);
        }

    }

}