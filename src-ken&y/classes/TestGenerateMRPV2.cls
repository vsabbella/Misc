/**
 * Tests for GenerateMRPbyFacilityExtV2, GenerateMRPExtV2, MRPServices
 * 
 */ 
@isTest
private class TestGenerateMRPV2 {
    
    /***** Test for MRP Generate by company *****/
	private static testMethod void testCompanySuccess() {
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
        
        Test.startTest() ;
            Test.setMock(HttpCalloutMock.class, new PostMrpGenerateSuccess ()) ;
            ApexPages.StandardController con = new ApexPages.StandardController (company);
            GenerateMRPExtV2 ext = new GenerateMRPExtV2 (con) ;
            system.assert ( ext.isButtonDisabled == false ) ;
            ext.generatePlan () ;
            system.assert ( ext.isButtonDisabled == true ) ;
        Test.stopTest() ;
	}
	
	// Test the invalid response the apex callout 
	// Exception caught by the future method
	private static testMethod void testCompanyFailure() {
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
        
        Test.startTest() ;
            Test.setMock(HttpCalloutMock.class, new PostMrpGenerateFailure ()) ;
            ApexPages.StandardController con = new ApexPages.StandardController (company);
            GenerateMRPExtV2 ext = new GenerateMRPExtV2 (con) ;
            ext.generatePlan () ;
        Test.stopTest() ;
	}
	
	private static testMethod void tesCompanytEmailInvocations () {
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
	    
	    Test.startTest() ;
            Test.setMock(HttpCalloutMock.class, new PostMrpGenerateSuccess ()) ;
            ApexPages.StandardController con = new ApexPages.StandardController (company);
            GenerateMRPExtV2 ext = new GenerateMRPExtV2 (con) ;
            system.assert ( ext.isButtonDisabled == false ) ;
            ext.generatePlan () ;
            
            List<Mrp_Run__c> mrpRuns = [SELECT id, Completion_Status__c FROM MRP_Run__c WHERE Completion_Status__c NOT IN ('Complete','Failure' ) ]  ;
            if ( mrpRuns.size() > 0 ) {
                MRP_Run__c run = mrpRuns.get(0) ;
                
                Mrp__c mrp = new Mrp__c () ;
                mrp.Mrp_Run__c = run.id ;
                insert mrp ;
                
                run.Completion_Status__c = 'Complete' ;
                update run ;
            }
        Test.stopTest() ;
        
	}
	
	/***** Test for MRP Generate by facility *****/
	private static testMethod void testFacilitySuccess() {
        TestFuel foo = new TestFuel () ;
        
        Facility__c facility = foo.facility ;
        facility.MRP_Backward_Horizon_in_Days__c = 3;
        facility.MRP_Demand_Time_Fence_in_Days__c = 5;
        facility.MRP_Forward_Horizon_in_Days__c = 2;
        facility.MRP_Planning_Time_Fence_in_Days__c = 3;
        facility.Use_Quantity_on_Hand_as_Supply_in_MRP__c = true ;
        facility.Use_Purchase_Orders_as_Supply_in_MRP__c = true ;
        facility.Use_Work_Orders_as_Supply_in_MRP__c = true ;
        facility.Use_Work_Orders_as_Demand_in_MRP__c = true ;
        facility.Use_Order_Forecast_as_Demand_in_MRP__c = true ;
        facility.Use_Sales_Orders_as_Demand_in_MRP__c = true ;
        facility.Use_Only_Level_Zero_QOH_as_Supply_in_MRP__c  = false ;
        facility.Planning_Calendar2__c = null ;
        facility.Receiving_Calendar2__c = null ;
        update facility ;
        
        Test.startTest() ;
            Test.setMock(HttpCalloutMock.class, new PostMrpGenerateSuccess ()) ;
            ApexPages.StandardController con = new ApexPages.StandardController (facility);
            GenerateMRPbyFacilityExtV2 ext = new GenerateMRPbyFacilityExtV2 (con) ;
            system.assert ( ext.isButtonDisabled == false ) ;
            ext.generatePlan () ;
            system.assert ( ext.isButtonDisabled == true ) ;
        Test.stopTest() ;
	}
	
	// Test the invalid response the apex callout 
	// Exception caught by the future method
	private static testMethod void testFacilityFailure() {
        TestFuel foo = new TestFuel () ;
        
        Facility__c facility = foo.facility ;
        facility.MRP_Backward_Horizon_in_Days__c = 3;
        facility.MRP_Demand_Time_Fence_in_Days__c = 5;
        facility.MRP_Forward_Horizon_in_Days__c = 2;
        facility.MRP_Planning_Time_Fence_in_Days__c = 3;
        facility.Use_Quantity_on_Hand_as_Supply_in_MRP__c = true ;
        facility.Use_Purchase_Orders_as_Supply_in_MRP__c = true ;
        facility.Use_Work_Orders_as_Supply_in_MRP__c = true ;
        facility.Use_Work_Orders_as_Demand_in_MRP__c = true ;
        facility.Use_Order_Forecast_as_Demand_in_MRP__c = true ;
        facility.Use_Sales_Orders_as_Demand_in_MRP__c = true ;
        facility.Use_Only_Level_Zero_QOH_as_Supply_in_MRP__c  = false ;
        facility.Planning_Calendar2__c = null ;
        facility.Receiving_Calendar2__c = null ;
        update facility ;
        
        Test.startTest() ;
            Test.setMock(HttpCalloutMock.class, new PostMrpGenerateFailure ()) ;
            ApexPages.StandardController con = new ApexPages.StandardController (facility);
            GenerateMRPbyFacilityExtV2 ext = new GenerateMRPbyFacilityExtV2 (con) ;
            ext.generatePlan () ;
        Test.stopTest() ;
	}
	
	
	/***** Mock for Http callouts *****/
	public class PostMrpGenerateSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Code":200,"Status":"OK"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class PostMrpGenerateFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Code":404,"Status":"Not Found"}');
            res.setStatusCode(404);
            return res;
        }
    }

}