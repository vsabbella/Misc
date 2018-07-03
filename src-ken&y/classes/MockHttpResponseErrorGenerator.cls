@isTest
public class MockHttpResponseErrorGenerator implements HttpCalloutMock{
	
	public HTTPResponse respond(HTTPRequest req) {
		// Create a fake error response 
    
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');
        String responseXML = '<?xml version="1.0"?><Error><Number>-2147217951</Number><Source>EMI_Respond :EMI:clsEMI.ValidateParameters:clsEMI.ProcessRequest;SOLServerIntl.EMI_Respond</Source><Description>Address not found</Description><HelpFile></HelpFile><HelpContext>1000440</HelpContext></Error>';
        res.setBody(responseXML);
        res.setStatusCode(200);
        System.assert(res.getBody()!=null);
        return res;
	}
}