@isTest
public with sharing class CompanyServiceTest {
    public static testmethod void mainTest() { 
        TestData data = new TestData();

		CompanyService cs = new CompanyService(new ApexPages.standardController(data.company));
        system.assertEquals( true, cs.doedit );
        system.assertEquals( null, cs.editCompany() ); 
        system.assertEquals( true, cs.doedit );
        cs.manageDefaults();
        cs.defaults.Preference.Default_Company__c = data.company.id;
        
        // Change in default company changes the membership of the user in public groups.
        // This needs to insert a setup object and might throw MIXED_DML_EXCEPTION. Hence the runAs().
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        system.runAs(currentUser){
        	Test.startTest();
        	cs.defaults.updateUserPreference();	
        	//Test.stopTest();
        }
        
        
        cs = new CompanyService(new ApexPages.standardController(data.company));
        system.assertEquals( false, cs.doedit );
        
        // test that the default was stored correctly by grabbing it again, this 
        // fails to re-query the db since it uses a singleton interface, result is this passes
        // but we never execute the constructor again after the first go... 
        system.assert( UserPreference.getInstance().Preference.Default_Company__c != null,' expected valid ID ');
        
        Purchase_Order__c po = data.purchaseOrder;
        CompanyService.setDefaultCompany(new List<sobject>{po}, true);
        // assert the result of setDefaultCompany
        system.assert ( [select id , company__c from Purchase_Order__c where id = :po.id limit 1].company__c != null);
        
        data.salesOrder.Sales_Order_Number__c = '010101';       
        data.salesOrder.Weight_UOM__c = data.uomList[0].ID;              
        data.salesOrder.Dimension_UOM__c = data.uomList[6].ID;
        update data.salesOrder;
        
        Sales_Order_Line__c lin = new Sales_Order_Line__c(
            sales_order_number__c='010101',
            company_identifier__c = data.company.Company_Identifier__c , 
            product__c = data.product.id,
            Weight_UOM__c = data.uomList[0].ID,              
            Dimension_UOM__c = data.uomList[6].ID,
            Quantity_Ordered__c = 1
            ); 
            
        insert lin; 
        system.assert( lin.id != null, ' could not create a line number using text lookups');
        system.assert( CompanyService.getDefaultCompanyId() == cs.defaults.preference.Default_Company__c );
    }
    
    public static testmethod void getBankAccountTest() { 
    	Testfuel data = new Testfuel();
    	/*GL_Account__c gl = new GL_Account__c();
    	gl.name='GL For Test';
    	insert gl;*/
    	
    	// Change in default company changes the membership of the user in public groups.
        // This needs to insert a setup object and might throw MIXED_DML_EXCEPTION. Hence the runAs().
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        system.runAs(currentUser){
        	Test.startTest();
        	
        	User_Preference__c up = new User_Preference__c();
			up.Default_Company__c = data.company.id;
			up.ownerID = userinfo.getUserID();
        	insert up;
        	
        	Test.stopTest();
        }
    	
    	Bank_Account__c bankaccount = new Bank_Account__c();
    	bankaccount.name = 'Wells Fargo';
    	bankaccount.company__c = data.company.id;
    	bankaccount.GL_Account__c = data.cashGL.id;
    	insert bankaccount;
    	
    	data.company.Disbursement_Bank_Account__c = bankaccount.id; 
    	update data.company;
    	
    	Apexpages.StandardController sc = new Apexpages.Standardcontroller( new Supplier_Payment__c() );
    	CompanyDefaultExt con = new CompanyDefaultExt( sc );
        system.assert( con!= null );
         
   
        Supplier_Payment__c sp = (Supplier_Payment__c)sc.getRecord();
        system.assertequals(data.company.id, sp.Company__c);
        system.assertequals(bankaccount.id, sp.Bank_Account__c);
    	 
        Boolean checkSupplierPymts = CompanyService.checkSupplierPaymentsAvailability(bankaccount);
        system.assertequals(true, checkSupplierPymts);
        
        //commented method for kndy-10268 deprecating bank_file__c object
        //Boolean checkBankFiles = CompanyService.checkBankFileAvailability(bankaccount);
        //system.assertequals(true, checkBankFiles);
    	 
    }
    //KNDY-18030 extended old method to get all bank account fields from company
    //KNDY-14482
    public static testmethod void getCompanyBankAccountTest() { 
    	Testfuel data = new Testfuel();
    	
    	
    	// Change in default company changes the membership of the user in public groups.
        // This needs to insert a setup object and might throw MIXED_DML_EXCEPTION. Hence the runAs().
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        system.runAs(currentUser){
        	Test.startTest();
        	
        	User_Preference__c up = new User_Preference__c();
			up.Default_Company__c = data.company.id;
			up.ownerID = userinfo.getUserID();
        	insert up;
        	
        	Test.stopTest();
        }
    	
    	Bank_Account__c bankaccount = new Bank_Account__c();
    	bankaccount.name = 'Bofa';
    	bankaccount.company__c = data.company.id;
    	bankaccount.GL_Account__c = data.cashGL.id;
    	insert bankaccount;
    	
    	data.company.Deposit_Bank_Account__c = bankaccount.id; 
    	update data.company;
    	
    	
        JSONResult result = CustomerReceiptManageExt.getCustomerReceipt(null, '');
        system.assert(result.total == 1, 'Customer receipt count does not match: ' + result.total);
        Customer_Receipt__c cr = (Customer_receipt__c)result.records[0];
        system.assert(cr.Bank_Account_2__c != null, 'Bank Account is null: ' + cr);
        
        system.assertequals(bankaccount.id, cr.Bank_Account_2__c);
    	 
        Boolean checkSupplierPymts = CompanyService.checkSupplierPaymentsAvailability(bankaccount);
        system.assertequals(true, checkSupplierPymts);
        
        //commented method for kndy-10268 deprecating bank_file__c object
        //Boolean checkBankFiles = CompanyService.checkBankFileAvailability(bankaccount);
        //system.assertequals(true, checkBankFiles);
    	 
    }
    public static testmethod void testWOFillLocations(){
        
        TestFuel fuel = new TestFuel();
        
        Work_Order__c wo = new Work_Order__c();
        wo.company__c = fuel.company.id;
        wo.facility__c = fuel.facility.id;
        
        Test.startTest();
        
        Apexpages.StandardController sc = new Apexpages.Standardcontroller( wo );
    	CompanyDefaultExt con = new CompanyDefaultExt( sc );
    	
    	Test.stopTest();
    	
    	system.assertEquals(wo.Complete_to_Location__c, null);
    	system.assertEquals(wo.MRB_Location__c, null);
    	system.assertEquals(wo.Default_WIP_Location__c, null);
    }
    
    static testMethod void testGLAccountUniqueness(){
    	GL_Type__c testGLT = new GL_Type__c();
    	testGLT.Name  = 'Current Assets';
		testGLT.Normal_Balance__c  = 'Debit';
		testGLT.Accounting_Type__c  = 'Assets';
		testGLT.Statement_Type__c  = 'Balance Sheet';
		testGLT.Account_Range_From__c = '10000';
		testGLT.Account_Range_To__c ='14999';
		insert testGLT;
		
    	GL_Account__c gl = new GL_Account__c();
    	gl.Name='GL For Test';
    	gl.gl_account_number__c = '11000';
    	gl.GL_Account_Name__c = 'Test';
    	gl.GL_Type__c = testGLT.id;
    	insert gl;
    	
    	try{
	    	GL_Account__c gl2 = new GL_Account__c();
	    	gl2.gl_account_number__c = '11000';
    		gl2.GL_Account_Name__c = 'Test';
    		gl2.GL_Type__c = testGLT.id;
	    	gl2.Name = 'GL For Test';
	    	insert gl2;
	    	system.assert(false, 'GL Account insertion did not fail.');
    	}catch(DMLException dmle){
    		system.assert(dmle.getDmlType(0) == StatusCode.DUPLICATE_VALUE, 'Expected duplicate value exception.');
    	}
    }
    
    static testmethod void test_LocationFindsFacilityUsingFacilityCode() {
        
        TestFuel data = new TestFuel();
        Company__c c = data.company;
        Facility__c f = data.facility;
        // insert a location with no facility id, just a facility code
        // it should be created under the facility using the location trigger
        Location__c location = new Location__c(
            Facility_Identifier__c = f.Primary_Key__c,
            name = 'Test Location 22'  );
		insert location;
		// test that we are a new location inside the facility
		location = [ select id, Facility__c from Location__c where id = :location.id limit 1];
		system.AssertEquals(f.id, location.Facility__c, ' epxected new location to live inside facility '+f);
		
		// ensure we can create a facility and have it join to a company using a trigger and text field
		// called company_identifier__c
		Facility__c facility = new Facility__c(
                        Name = data.company.Name + ' Facility-44',
                        Company_Identifier__c = c.Company_Identifier__c,
                        Primary_Key__c = 'FA044',
                        Description__c = 'Facility-44'
                    );
		insert facility;
		system.assert(facility.Company_Identifier__c.contains('KEN'));
		
		facility =  [ select id, Company__c from Facility__c where id = :facility.id limit 1];
		system.AssertEquals(c.id, facility.Company__c, ' epxected factility to be linked to company '+c);
        
    }
    
    public static testmethod void testCompanyName() { 
		TestFuel data = new TestFuel();    
    		system.assert( data.company != null );
    		// test whitelist of chars for company name
    		data.company.name = 'foo,.?&@!#\'~* _-:+; ';
    		update data.company;
    		system.assert( data.company != null );
    		
    }
}