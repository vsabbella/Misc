@isTest
public with sharing class CustomerQuickCreateExtTest {

	public testmethod static void testCustomerQuickCreate() {

		TestFuel fuel = new TestFuel();

    	User_Preference__c up = new User_Preference__c();
		up.Default_Company__c = fuel.company.id;
		up.ownerID = UserInfo.getUserID();
    	insert up;

		ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Customer__c>());
		CustomerQuickCreateExt cQuickCreateExt = new CustomerQuickCreateExt(setCon);
		cQuickCreateExt.corpParent.Name = 'Corp 1';
		cQuickCreateExt.billTo.Name = 'Bill 1';
		cQuickCreateExt.soldTo.Name = 'Sold 1';
		cQuickCreateExt.shipTo.Name = 'Ship 1';

		cQuickCreateExt.initializeData();
		cQuickCreateExt.save();

		List<Customer__c> customer = [Select id, 
										   	 Name
									    from Customer__c
									   Where Name = 'Corp 1'];

		System.assertEquals(customer.size(), 1);
	}

	public testmethod static void testCustomerQuickCreateWithAccount() {

		TestFuel fuel = new TestFuel();

    	User_Preference__c up = new User_Preference__c();
		up.Default_Company__c = fuel.company.id;
		up.ownerID = UserInfo.getUserID();
    	insert up;

        PageReference pageRef = Page.CustomerQuickCreate;
		pageRef.getParameters().put('accid', fuel.account.id);
		Test.setCurrentPage(pageRef);

		ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Customer__c>());
		CustomerQuickCreateExt cQuickCreateExt = new CustomerQuickCreateExt(setCon);

		cQuickCreateExt.corpParent.Name = 'Corp 1';
		cQuickCreateExt.billTo.Name = 'Bill 1';
		cQuickCreateExt.soldTo.Name = 'Sold 1';
		cQuickCreateExt.shipTo.Name = 'Ship 1';

		cQuickCreateExt.initializeData();
        cQuickCreateExt.corpParent.Company__c = fuel.company.id;
		cQuickCreateExt.save();

		List<Customer__c> customer = [Select id, 
										   	 Name,
										   	 CRM_Account__c,
										   	 Customer_City__c
									    from Customer__c
									   Where Name = 'Corp 1'];

		System.assertEquals(customer.size(), 1);
		//Verify if account is set on the customer and if the billing city is equal to customer's billing city
		System.assertEquals(customer[0].CRM_Account__c, fuel.account.id);
		System.assertEquals(customer[0].Customer_City__c, fuel.account.billingcity);
	}
	
	    public testmethod static void testCustomerQuickCreateWOCustomSetting() {

		TestFuel fuel = new TestFuel();

    	User_Preference__c up = new User_Preference__c();
		up.Default_Company__c = fuel.company.id;
		up.ownerID = UserInfo.getUserID();
    	insert up;
		
        Configuration__c myConfig = New Configuration__c();
        myConfig.Name = 'CustomerQuickCreate_Site';
        myConfig.Value__c = 'yes';
        insert myConfig;
        
		ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Customer__c>());
		CustomerQuickCreateExt cQuickCreateExt = new CustomerQuickCreateExt(setCon);
		cQuickCreateExt.corpParent.Name = 'Corp 1';
		cQuickCreateExt.billTo.Name = 'Bill 1';
		cQuickCreateExt.soldTo.Name = 'Sold 1';
		cQuickCreateExt.shipTo.Name = 'Ship 1';
        cQuickCreateExt.site.Name = 'Site 1';

		cQuickCreateExt.initializeData();
		cQuickCreateExt.save();

		List<Customer__c> customer = [Select id, 
										   	 Name
									    from Customer__c
									   Where Name = 'Site 1'];

		System.assertEquals(customer.size(), 1);
        
        Configuration__c testConfig = [Select id, name from Configuration__c where name = 'CustomerQuickCreate_Site'];
        delete testConfig;
        
        cQuickCreateExt = new CustomerQuickCreateExt(setCon);
		cQuickCreateExt.corpParent.Name = 'Corp 2';
		cQuickCreateExt.billTo.Name = 'Bill 2';
		cQuickCreateExt.soldTo.Name = 'Sold 2';
		cQuickCreateExt.shipTo.Name = 'Ship 2';
        cQuickCreateExt.site.Name = 'Site 2';
        
		cQuickCreateExt.initializeData();
		cQuickCreateExt.save();

		customer = [Select id, 
										   	 Name
									    from Customer__c
									   Where Name = 'Site 2'];

		System.assertEquals(customer.size(), 0);
	}
}
