@isTest
private class TestJobMonitor {

	private static testMethod void testSuccess() {
        TestFuel foo = new TestFuel () ;
        
        Test.startTest() ;
            Test.setMock(HttpCalloutMock.class, new PostStatSuccess ()) ;
            JobMonitorExt.getBackgroundJobs () ;
        Test.stopTest() ;    
	}
	
	
	/***** Mock for Http callouts *****/
	public class PostStatSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Code":200,"Status":"OK"}');
            res.setStatusCode(200);
            return res;
        }
    }
}