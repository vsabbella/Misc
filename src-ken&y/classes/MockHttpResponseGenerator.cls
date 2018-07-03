@isTest
public class MockHttpResponseGenerator implements HttpCalloutMock{
	
	public HTTPResponse respond(HTTPRequest req) {
		// Create a fake response 
    
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');
        String responseXML = '<?xml version="1.0"?><ZipCodeLookupResponse><Address ID="0"><Address2>8 WILDWOOD DR</Address2><City>OLD LYME</City><State>CT</State><Zip5>06371</Zip5><Zip4>1844</Zip4></Address></ZipCodeLookupResponse>';
        res.setBody(responseXML);
        res.setStatusCode(200);
        System.assert(res.getBody()!=null);
        //System.debug('****in mock****'+res.getBody());
        return res;
	}
	
	
}