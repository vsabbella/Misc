@isTest
private class TestGatewayExt {

	private static testMethod void testSuccess() {
        TestFuel foo = new TestFuel () ;
        
        Company__c company = foo.company ;
        company.MRP_Backward_Horizon_in_Days__c = 3;
        company.MRP_Demand_Time_Fence_in_Days__c = 5;
        company.MRP_Forward_Horizon_in_Days__c = 2;
        company.MRP_Planning_Time_Fence_in_Days__c = 3;
        company.Use_Quantity_on_Hand_as_Supply_in_MRP__c = true ;
        company.Use_Purchase_Orders_as_Supply_in_MRP__c = true ;
        company.Use_Work_Orders_as_Supply_in_MRP__c = true ;
        company.Use_Work_Orders_as_Demand_in_MRP__c = true ;
        company.Use_Order_Forecast_as_Demand_in_MRP__c = true ;
        company.Use_Sales_Orders_as_Demand_in_MRP__c = true ;
        company.Use_Only_Level_Zero_QOH_as_Supply_in_MRP__c  = false ;
        company.Planning_Calendar2__c = null ;
        company.Receiving_Calendar2__c = null ;
        update company ;
        
        User_Preference__c up = new User_Preference__c () ;
        up.Default_Company__c = company.id ;
        insert up ;
        
        Organization org = GatewayExt.org ;
        String urlSubStr = '' ;
        if ( org.IsSandbox ) {
            urlSubStr = 'test.salesforce.com' ;
        }
        else {
            urlSubStr = 'login.salesforce.com' ;
        }
        
        Test.startTest () ;
            ApexPages.StandardController con = new ApexPages.StandardController ( up ) ;
            GatewayExt oauth = new GatewayExt ( con ) ;
            PageReference pref = oauth.startDance1 () ;
            system.assert ( pref.getUrl().indexOf(urlSubStr)>-1 ) ;
            
            Test.setCurrentPageReference(new PageReference('/apex/OAuth'));
	        System.currentPageReference().getParameters().put('oauthsuccess', '1');
	        GatewayExt oauth2 = new GatewayExt ( con ) ;
	        system.assert ( ApexPages.hasMessages() ) ;
            
            Test.setCurrentPageReference(new PageReference('apex/OAuth'));
            System.currentPageReference().getParameters().put('error', 'testError');
	        GatewayExt oauth3 = new GatewayExt ( con ) ;
	        system.assert ( ApexPages.hasMessages() ) ;
	        
	        System.assert ( GatewayExt.isUserAuthorized() == true ) ;
        Test.stopTest() ;
	}
}