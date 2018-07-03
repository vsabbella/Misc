@isTest
private class ConfigureOTCTest {
    
    class ConfigureOTCTestData {
    	TestFuel fuel = new TestFuel();
    	
        User_Preference__c up = UserPreference.getInstance().Preference;
        {
        	up.Default_Company__c = fuel.company.id;
        	upsert up;
        }
        /* KNDY-10333
        Account originAddress = new Account(Name = 'TestOrigin');
        Account destAccount2 = new Account(Name = 'Dest Account 2');
        {	
        	insert new Account[] {         originAddress, destAccount2         };
        }
            
        Transit_Route__c tr = new Transit_Route__c(Destination__c = fuel.account.id,
                                                   Means_of_Transport__c = fuel.meansOfTransport.id, 
                                                   Origin__c = originAddress.Id,
                                                   Assessorial_Amount__c = 50,
                                                   CWT_Factor__c = 430,
                                                   Distance__c = 500,
                                                   Distance_Rate__c = 0.47,
                                                   Fuel_Allowance__c = 32.4,
                                                   Fuel_Rate__c = 5,
                                                   Line_Haul_Amount__c = 1000,
                                                   Transit_Time__c = 2,
                                                   Delivery_Method__c = 'Pickup');
		{	
			insert tr;
		}   
        */                                        
    }
    
    testMethod static void testConfigureOTCExtAndCustomerTrigger() {
        ConfigureOTCTestData testData = new ConfigureOTCTestData();
        
        Customer__c customerParent = testData.fuel.customerParent;
        customerParent.Fuel_Preference__c = '';
        update customerParent; 
        
        Test.startTest();
	        Test.setCurrentPage(Page.ConfigureOTC);        
	        ApexPages.currentPage().getParameters().put('id', testData.fuel.company.id);
	        ConfigureOTCExt ext = new ConfigureOTCExt( new ApexPages.StandardController( testData.fuel.company ) );
	        System.assertEquals(null, ext.otc.id);
	        
	        ext.otc.Parent_Level_Freight_Allowances_Only = true;
	        ext.onSave();
	        System.assertNotEquals(null, ext.otc.id);
	        System.assertEquals(false, TestHelper.hasPageMessage(ApexPages.Severity.FATAL, 'OTC Configuration Update Error:'));
	        
	        // reload 
	        ext = new ConfigureOTCExt( new ApexPages.StandardController( testData.fuel.company ) );
	        System.assertEquals(true, ext.otc.Parent_Level_Freight_Allowances_Only, 'ext.otc.Parent_Level_Freight_Allowances_Only__c should come true, as its set previously to that value');            
	        //ext.otc.Fuel_Allowance_Preference_None = 10;
	        ext.otc.Fuel_Allowance_Preference_Weekly = 20;
	        ext.otc.Fuel_Allowance_Preference_Monthly = 30;
	        ext.otc.Fuel_Allowance_Preference_Quarterly = 40;        
	        ext.onSave();  
        
        Test.stopTest();
        /* KNDY-10333 
        Transit_Route__c tr = [Select Fuel_Allowance__c, Distance_Rate__c from Transit_Route__c Where Id =:testData.tr.id limit 1];
        System.assertEquals(32.4, tr.Fuel_Allowance__c);
        System.assertEquals(0.47, tr.Distance_Rate__c);
        */
    }
    
    testMethod static void testFuelPreferenceWeeklyAndMonthly() {
        ConfigureOTCTestData testData = new ConfigureOTCTestData();   
        
        Customer__c customerParent = testData.fuel.customerParent;
        customerParent.Fuel_Preference__c = 'Weekly';
        update customerParent;  
        
        Test.startTest();
	    	Test.setCurrentPage(Page.ConfigureOTC);        
	        ApexPages.currentPage().getParameters().put('id', testData.fuel.company.id);
	        ConfigureOTCExt ext = new ConfigureOTCExt( new ApexPages.StandardController( testData.fuel.company ) );
	        ext.otc.Parent_Level_Freight_Allowances_Only = true;
	        ext.onSave();
	        
	        ext = new ConfigureOTCExt( new ApexPages.StandardController( testData.fuel.company ) );
	        ext.otc.Fuel_Allowance_Preference_Weekly = 20;
	        ext.otc.Fuel_Allowance_Preference_Monthly = 30;
	        ext.otc.Fuel_Allowance_Preference_Quarterly = 40;        
	        ext.onSave();
    		System.assertNotEquals(null, ext.otc.id);
	        System.assertEquals(false, TestHelper.hasPageMessage(ApexPages.Severity.FATAL, 'OTC Configuration Update Error:'));
    	Test.stopTest();
        /* KNDY-10333
        System.assertEquals(ext.otc.Fuel_Allowance_Preference_Weekly, [Select Fuel_Allowance__c, Distance_Rate__c from Transit_Route__c Where Id =:testData.tr.id limit 1].Fuel_Allowance__c);
        
        customerParent = testData.fuel.customerParent;
        customerParent.Fuel_Preference__c = 'Monthly';
        update customerParent;
        
        System.assertEquals(ext.otc.Fuel_Allowance_Preference_Monthly, [Select Fuel_Allowance__c from Transit_Route__c Where Id =:testData.tr.id].Fuel_Allowance__c);        
        
        // Fires Customer trigger to clean up the Fuel Allowance as no other customer is having the previous account address.
        customerParent.Address__c = testData.destAccount2.Id;
        update customerParent;
        
        System.assertEquals(0, [Select Fuel_Allowance__c from Transit_Route__c Where Id =:testData.tr.id].Fuel_Allowance__c);        
        
        // Fire Transit Route Trigger to update back the from the Latest Address from Customer
        testData.tr.Destination__c = testData.destAccount2.Id;
        update testData.tr;
        System.assertEquals(ext.otc.Fuel_Allowance_Preference_Monthly, [Select Fuel_Allowance__c from Transit_Route__c Where Id =:testData.tr.id].Fuel_Allowance__c);  
        */      
    }
    
}