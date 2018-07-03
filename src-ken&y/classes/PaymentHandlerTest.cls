@isTest
public class PaymentHandlerTest {
	@testSetup static void ts() { 
		TestFuel data = new TestFuel();	
		// these asserts cause TestFuelQuery to insert data
		system.assert(		
			data.company != null &&
			data.customerSoldTo != null &&
			data.customerBillTo != null &&
			data.product_Misc != null &&
			data.product != null &&
			data.periodList != null &&
			data.salesOrder != null &&
			data.salesOrderLines != null &&
			data.paymentProfile != null &&
			data.paymentMethod != null
		);
		system.assert(
			data.custInv1 != null &&
			data.bankAccount != null &&
			data.altCompany != null);
	}
	public class MockRestServiceResponse implements HttpCalloutMock {
		
	    public HttpResponse respond(HttpRequest req) {
	    	
	    	string xmlBody = req.getBody();
	    	Dom.Document doc = new Dom.Document();
	    	doc.load(xmlBody);
	    	Dom.XMLNode reqRoot = doc.getRootElement();
	    	string reqRootName = reqRoot.getName();
	    	system.debug('reqRootName: ' + reqRootName);
	    	
	    	HttpResponse resp = new HttpResponse();
	    	resp.setHeader('Content-Type', 'text/xml');
	    	resp.setStatusCode(200);
	        resp.setBody(PaymentHandlerTest.requestResponseBodies.get(reqRootName));
	    	return resp;
	    }
	}
	
	public class MockRestServiceResponse1 implements HttpCalloutMock {
		
	    public HttpResponse respond(HttpRequest req) {
	    	
	    	string xmlBody = req.getBody();
	    	Dom.Document doc = new Dom.Document();
	    	doc.load(xmlBody);
	    	Dom.XMLNode reqRoot = doc.getRootElement();
	    	string reqRootName = reqRoot.getName();
	    	system.debug('reqRootName: ' + reqRootName);
	    	
	    	HttpResponse resp = new HttpResponse();
	    	resp.setHeader('Content-Type', 'text/xml');
	    	resp.setStatusCode(200);
	    	String body = '<?xml version="1.0" encoding="utf-8"?> <createTransactionResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <refId>123456</refId> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <transactionResponse> <responseCode>1</responseCode> <authCode>UGELQC</authCode> <avsResultCode>E</avsResultCode> <cavvResultCode /> <transId>2148061808</transId> <refTransID /> <transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash> <accountNumber>XXXX0015</accountNumber> <accountType>MasterCard</accountType> <messages><message> <code>1</code> <description>This transaction has been approved.</description> </message></messages> <userFields> <userField> <name>MerchantDefinedFieldName1</name> <value>MerchantDefinedFieldValue1</value> </userField> <userField> <name>favorite_color</name> <value>lavender</value> </userField> </userFields> </transactionResponse> </createTransactionResponse>';
	        resp.setBody(PaymentHandlerTest.requestResponseBodies.get(reqRootName));
	    	return resp;
	    }
	}
	
    static testMethod void testGetCustomerProfile() {
    	
    	insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
        TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		Payment_Profile__c pp = fuel.paymentProfile;

		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		
		Test.startTest();
		
		PaymentHandler ph = new PaymentHandler();
		string custProfileId = ph.getCustomerProfile(custParent.Id);   
		
		Test.stopTest();

		system.assertNotEquals(null, custProfileId);
		
		   
    }
    
    static testMethod void testCreateCustomerProfileRequest() {
    	
    	insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		
		PaymentHandler.PaymentProfileDetail ppd = new PaymentHandler.PaymentProfileDetail();
		ppd.customerId = custParent.Id;
		ppd.creditCard = new PaymentHandler.CreditCardDetail();
		ppd.creditCard.cardNumber = '4111111111111111';
		ppd.EmailAddress = 'test@kenandy.com';
		ppd.creditCard.expirationDate = '2020-12';
		ppd.creditCard.CCV = '111';
		ppd.creditCard.firstName = 'Joe';
		ppd.creditCard.lastName = 'Test';
		ppd.creditCard.company = 'Kenandy';
		ppd.creditCard.address = '303 Twin Dolphin Dr Suite 500';
		ppd.creditCard.city = 'Redwood City';
		ppd.creditCard.state = 'CA';
		ppd.creditCard.zip = '94065';
		ppd.creditCard.phone = '650-241-2283';
		ppd.formFields = new PaymentHandler.PaymentFormFields();
		ppd.formFields.billingFirstName = 'Joe';
		ppd.formFields.billingLastName = 'Test';
		ppd.formFields.billingCompany = 'Kenandy';
		ppd.formFields.billingAddress = '303 Twin Dolphin Dr Suite 500';
		ppd.formFields.billingCity = 'Redwood City';
		ppd.formFields.billingState = 'CA';
		ppd.formFields.billingZipCode = '94065';
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		
		Test.startTest();
		
		PaymentHandler ph = new PaymentHandler();
		Payment_Profile__c pp = ph.createPaymentProfile(ppd);   
		
		Test.stopTest();

		system.assertNotEquals(null, pp.Id);
		system.assertNotEquals(null, pp.Payment_Profile_ID__c);
		system.assertEquals('test@kenandy.com', pp.Email_Address__c);
		   
    }
    
    static testMethod void testCreatePaymentMethod(){
    	
    	insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
    	TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		Payment_Profile__c pp = fuel.paymentProfile;
		
		PaymentHandler.CreditCardDetail ccd = new PaymentHandler.CreditCardDetail();
		ccd.cardNumber = '4111111111111111';
		ccd.expirationDate = '2020-12';
		ccd.firstName = 'Joe';
		ccd.lastName = 'Test';
		ccd.company = 'Kenandy';
		ccd.address = '303 Twin Dolphin Dr Suite 500';
		ccd.city = 'Redwood City';
		ccd.state = 'CA';
		ccd.zip = '94065';
		ccd.phone = '650-241-2283';
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		
		Test.startTest();
		
		PaymentHandler ph = new PaymentHandler();
		Payment_Method__c pm = ph.createPaymentMethod(pp.Id, ccd);
		
		Test.stopTest();
		
		system.assertNotEquals(null, pm);
		system.assertNotEquals(null, pm.Id);
		system.assertNotEquals(null, pm.Payment_Method_ID__c);
		system.assertNotEquals(null, pm.Payment_Profile__c);
    }
    
    static testMethod void testChargePaymentMethod(){
    	
    	insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
    	TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		c.Credit_Card_Bank_Account__c = fuel.bankAccount.Id;
		update c;
        Customer_Invoice__c ci = new Customer_Invoice__c(Company__c = fuel.company.Id, Currency__c = fuel.currencyUSD.ID);
        insert ci;
		List<Period__c> periods = fuel.periodList;
		Customer__c custParent = fuel.customerParent;
		Payment_Profile__c pp = fuel.paymentProfile;
		Payment_Method__c pm = fuel.paymentMethod;
        pm.Name = 'Card XXXX8888/02-2020'; //correct format
        update pm;
		PaymentHandler.PaymentFormFields paymentFormFields = new PaymentHandler.PaymentFormFields();
		paymentFormFields.invoiceNumber = 'INV1';
		PaymentHandler.PaymentProfileDetail ppd = new PaymentHandler.PaymentProfileDetail();
		ppd.formFields = paymentFormFields;
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		
		Test.startTest();
		Boolean hasException = false;
		string exceptionStr = '';
		PaymentHandler.PaymentResponse pResponse;
		
        try{
			PaymentHandler ph = new PaymentHandler();
			pResponse =  ph.chargePaymentMethod(pm.Id, ci.ID, ppd, 10);
		}
		catch(Exception ex){
			hasException = true;
			exceptionStr = ex.getStacktracestring();
		}
		Test.stopTest();
		system.assertEquals(hasException, false, Apexpages.getMessages() +exceptionStr);
		system.assertNotEquals(null, pResponse.customerReceiptId);
		Customer_Receipt__c cr = [SELECT Id, Finalized__c, Reference_Number__c, Bank_Account_2__c FROM Customer_Receipt__c WHERE Id = :pResponse.customerReceiptId];
		system.assertEquals(true, cr.Finalized__c);
		system.assertEquals(fuel.bankAccount.Id, cr.Bank_Account_2__c);
		system.assertEquals('2148061808',cr.Reference_Number__c);
		
    }

    static testMethod void testChargePaymentMethod_SO(){ //KNDY-17864
    	List<Customer__c> customers = new List<Customer__c>();
    	insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
    	TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		c.Credit_Card_Bank_Account__c = fuel.bankAccount.Id;
		update c;
        Sales_Order__c so = fuel.salesOrder;
        Sales_Order__c soCopy = [Select id, status__c from Sales_Order__c where Id = :so.Id];
        system.assertNotEquals (soCopy.Status__c, 'Closed', so);
        
        //create multiple bill-to customers
        Customer__c billTo2 = fuel.customerBillTo.clone();
        billTo2.Customer_Identifier__c = fuel.customerBillTo.Customer_Identifier__c + '2';
        billTo2.Name = fuel.customerBillTo.Name + '2';
        Customer__c soldTo2 = fuel.customerSoldTo.clone();
        soldTo2.Customer_Identifier__c = fuel.customerSoldTo.Customer_Identifier__c + '2';
        soldTo2.Name = fuel.customerSoldTo.Name + '2';
        Customer__c shipTo2 = fuel.customerShipTo.clone();
        shipTo2.Customer_Identifier__c = fuel.customerShipTo.Customer_Identifier__c + '2';
        shipTo2.Name = fuel.customerShipTo.Name + '2';
        Customer__c billTo3 = fuel.customerBillTo.clone();
        billTo3.Customer_Identifier__c = fuel.customerBillTo.Customer_Identifier__c + '3';
        billTo3.Name = fuel.customerBillTo.Name + '3';
        Customer__c soldTo3 = fuel.customerSoldTo.clone();
        soldTo3.Customer_Identifier__c = fuel.customerSoldTo.Customer_Identifier__c + '3';
        soldTo3.Name = fuel.customerSoldTo.Name + '3';
        Customer__c shipTo3 = fuel.customerShipTo.clone();
        shipTo3.Customer_Identifier__c = fuel.customerShipTo.Customer_Identifier__c + '3';
        shipTo3.Name = fuel.customerShipTo.Name + '3';

        customers = new List<Customer__c> {billTo2, soldTo2, shipTo2,billTo3, soldTo3, shipTo3};
        insert customers;
        soldTo2.Parent_Customer__c = billTo2.Id;
        shipTo2.Parent_Customer__c = soldTo2.Id;
        soldTo3.Parent_Customer__c = billTo3.Id;
        shipTo3.Parent_Customer__c = soldTo3.Id;
        update customers;
        
		List<Period__c> periods = fuel.periodList;
		Customer__c custParent = fuel.customerParent;
		Payment_Profile__c pp = fuel.paymentProfile;
		Payment_Method__c pm = fuel.paymentMethod;
        pm.Name = 'Card XXXX8888/02-2020'; //correct format
        update pm;
		PaymentHandler.PaymentFormFields paymentFormFields = new PaymentHandler.PaymentFormFields();
		paymentFormFields.invoiceNumber = 'INV1';
		PaymentHandler.PaymentProfileDetail ppd = new PaymentHandler.PaymentProfileDetail();
		ppd.formFields = paymentFormFields;
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		
		Test.startTest();
		Boolean hasException = false;
		string exceptionStr = '';
		PaymentHandler.PaymentResponse pResponse;
		
        try{
			PaymentHandler ph = new PaymentHandler();
			pResponse =  ph.chargePaymentMethod(pm.Id, so.ID, ppd, 10);
		}
		catch(Exception ex){
			hasException = true;
			exceptionStr = ex.getStacktracestring();
		}
		Test.stopTest();
		system.assertEquals(hasException, false, Apexpages.getMessages() +exceptionStr);
		system.assertNotEquals(null, pResponse.customerReceiptId);
		Customer_Receipt__c cr = [SELECT Id, Finalized__c, Reference_Number__c, Bank_Account_2__c FROM Customer_Receipt__c WHERE Id = :pResponse.customerReceiptId];
		system.assertEquals(true, cr.Finalized__c);
		system.assertEquals(fuel.bankAccount.Id, cr.Bank_Account_2__c);
		system.assertEquals('2148061808',cr.Reference_Number__c);
		
    }
    //Authorize.net Payment Form Fields Test
    static testMethod void testChargePaymentMethod_MissingShipTo(){
        Set<String> expectedErrors = new Set<String>();
        expectedErrors.add('Ship To First Name is required.');
        expectedErrors.add('Ship To Last Name is required.');
        expectedErrors.add('Ship To Address is required.');
        expectedErrors.add('Ship To City is required.');
        expectedErrors.add('Ship To State/Province is required.');
        expectedErrors.add('Ship To Zip/Postal Code is required.');
        expectedErrors.add('Ship To Country is required.');

        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    
        TestFuelQuery fuel = new TestFuelQuery();
        Company__c c = fuel.Company;
        Customer__c custParent = fuel.customerParent;
        Payment_Profile__c pp = fuel.paymentProfile;
        Payment_Method__c pm = fuel.paymentMethod;

        // Simulate error message response by authorize.net
        String response = requestResponseBodies.get('createTransactionRequest');
        
        String errorResponse = response.replace('<text>Successful.</text>','<text> Unable to complete request </text>');
        String resultCodeResponse = errorResponse.replace('<resultCode>Ok</resultCode>', '<resultCode>Error</resultCode>');
        String errorCodeResponse = resultCodeResponse.replace('<code>I00001</code>', '<code>E00027</code>');
        
        String errors = '<errors>';
        for (String expectedError: expectedErrors){
            errors += '<error><errorText>'+ expectedError + '</errorText></error>';
        }
        errors += '</errors>';
        String transactionErrors = errorCodeResponse.replace('<errors></errors>', errors);
        requestResponseBodies.put('createTransactionRequest', transactionErrors);
        
        // ppd has no shipping info
        PaymentHandler.PaymentFormFields paymentFormFields = new PaymentHandler.PaymentFormFields();
        paymentFormFields.invoiceNumber = 'INV1';
        PaymentHandler.CreditCardDetail ccd = new PaymentHandler.CreditCardDetail();
        ccd.cardNumber = '4111111111111111';
        ccd.expirationDate = '12-2020';
        PaymentHandler.PaymentProfileDetail ppd = new PaymentHandler.PaymentProfileDetail();
        ppd.formFields = paymentFormFields;
        
        Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
        Test.startTest();
        Boolean hasException = false;
        try{
            PaymentHandler ph = new PaymentHandler();
            PaymentHandler.PaymentResponse pResponse =  ph.chargePaymentMethod(pm.Id, 'abc123', ppd, 10);
        }catch(Exception ex){
            hasException = true;
            system.assertEquals(Apexpages.hasMessages(), true);
            system.assert(Apexpages.getMessages().size() >= expectedErrors.size(), Apexpages.getMessages());
            for (String expectedError : expectedErrors){
                Boolean hasExpectedError = false;
                for (Apexpages.Message msg : Apexpages.getMessages()) {
                    if (msg.getDetail().contains(expectedError)){
                        hasExpectedError = true;
                    }
                }
                system.assert(hasExpectedError == true, Apexpages.getMessages());
            }
        }
        system.assert(hasException == true);
        Test.stopTest();
    }
    
    //Authorize.net Payment Form Fields Test
    static testMethod void testChargePaymentMethod_IncorrectNameFormat_MissingCCV(){
        Set<String> expectedErrors = new Set<String>();
        expectedErrors.add('Card Code is required.');
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    
        TestFuelQuery fuel = new TestFuelQuery();
        Company__c c = fuel.Company;
        Customer__c custParent = fuel.customerParent;
        Payment_Profile__c pp = fuel.paymentProfile;
        Payment_Method__c pm = fuel.paymentMethod;
        pm.Name = 'Card XXXX8888'; // incorrect format
        update pm;

        // Simulate error message response by authorize.net
        String response = requestResponseBodies.get('createTransactionRequest');
        
        String errorResponse = response.replace('<text>Successful.</text>','<text> Unable to complete request </text>');
        String resultCodeResponse = errorResponse.replace('<resultCode>Ok</resultCode>', '<resultCode>Error</resultCode>');
        String errorCodeResponse = resultCodeResponse.replace('<code>I00001</code>', '<code>E00027</code>');
        
        String errors = '<errors>';
        for (String expectedError: expectedErrors){
            errors += '<error><errorText>'+ expectedError + '</errorText></error>';
        }
        errors += '</errors>';
        String transactionErrors = errorCodeResponse.replace('<errors></errors>', errors);
        requestResponseBodies.put('createTransactionRequest', transactionErrors);
        
        // ppd has no shipping info
        PaymentHandler.PaymentFormFields paymentFormFields = new PaymentHandler.PaymentFormFields();
        paymentFormFields.invoiceNumber = 'INV1';
        PaymentHandler.PaymentProfileDetail ppd = new PaymentHandler.PaymentProfileDetail();
        ppd.formFields = paymentFormFields;
        
        Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
        Test.startTest();
        Boolean hasException = false;
        try{
            PaymentHandler ph = new PaymentHandler();
            PaymentHandler.PaymentResponse pResponse =  ph.chargePaymentMethod(pm.Id, 'abc123', ppd, 10);
        }catch(Exception ex){
            hasException = true;
            system.assertEquals(Apexpages.hasMessages(), true);
            system.assert(Apexpages.getMessages().size() >= expectedErrors.size(), Apexpages.getMessages());
            for (String expectedError : expectedErrors){
                Boolean hasExpectedError = false;
                for (Apexpages.Message msg : Apexpages.getMessages()) {
                    if (msg.getDetail().contains(expectedError)){
                        hasExpectedError = true;
                    }
                }
                system.assert(hasExpectedError == true, Apexpages.getMessages());
            }
        }
        system.assert(hasException == true);
        Test.stopTest();
    }
    
    static testMethod void testRefundTransaction(){
    	
    	insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
    	TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		c.Credit_Card_Bank_Account__c = fuel.bankAccount.Id;
		update c;
		List<Period__c> periods = fuel.periodList;
		Customer__c custParent = fuel.customerParent;
		Payment_Profile__c pp = fuel.paymentProfile;
		Payment_Method__c pm = fuel.paymentMethod;
		Sales_Order__c so = fuel.salesOrder;
		
		Customer_Receipt__c cr = new Customer_Receipt__c();
		cr.Amount_Received__c = 10;
		cr.Transaction_Date__c = system.now();
		cr.Currency__c = c.Default_Transaction_Currency__c;
		cr.Company__c = c.Id;
		cr.Customer__c = custParent.Id;
		cr.Payment_Method_3__c = pm.Id;
		cr.Transaction_ID__c = 'abc123';
		cr.Type__c = 'Receipt';
		
		insert cr;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Prepayment';
		crl.Sales_Order__c = so.Id;
		insert crl;
		
		cr.Finalized__c = true;
		update cr;
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		
		Test.startTest();
		
		PaymentHandler ph = new PaymentHandler();
		PaymentHandler.PaymentResponse pResponse = ph.refundTransaction(pm.Id, 'abc123', cr.ID, null);  
		
		Test.stopTest();
		
		system.assertNotEquals(null, pResponse.customerReceiptId);
		Customer_Receipt__c refundCR = [SELECT Id, Finalized__c, Bank_Account_2__c FROM Customer_Receipt__c WHERE Id = :pResponse.customerReceiptId];
		system.assertEquals(true, refundCR.Finalized__c);
		system.assertEquals(fuel.bankAccount.Id, refundCR.Bank_Account_2__c);
		
    }
    
    static testMethod void testCancelTransaction(){
    	
    	insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
    	TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		List<Period__c> periods = fuel.periodList;
		Customer__c custParent = fuel.customerParent;
		Payment_Profile__c pp = fuel.paymentProfile;
		Payment_Method__c pm = fuel.paymentMethod;
		
		Customer_Receipt__c cr = new Customer_Receipt__c();
		cr.Amount_Received__c = 10;
		cr.Transaction_Date__c = system.now();
		cr.Currency__c = c.Default_Transaction_Currency__c;
		cr.Company__c = c.Id;
		cr.Customer__c = custParent.Id;
		cr.Payment_Method_3__c = pm.Id;
		cr.Transaction_ID__c = 'abc123';
		cr.Type__c = 'Receipt';
		
		insert cr;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Prepayment';
		insert crl;
		
		cr.Finalized__c = true;
		update cr;
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		
		Test.startTest();
		
		PaymentHandler ph = new PaymentHandler();
		Boolean isSuccess = ph.voidTransaction('refId', 'abc123');
		
		Test.stopTest();
		
		system.assertEquals(true, isSuccess);
		
		
    }
    
    static testMethod void testGetTransactionDetails(){
    	insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
    	TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		List<Period__c> periods = fuel.periodList;
		Customer__c custParent = fuel.customerParent;
		Payment_Profile__c pp = fuel.paymentProfile;
		Payment_Method__c pm = fuel.PaymentMethod;
		
		Customer_Receipt__c cr = new Customer_Receipt__c();
		cr.Amount_Received__c = 10;
		cr.Transaction_Date__c = system.now();
		cr.Currency__c = c.Default_Transaction_Currency__c;
		cr.Company__c = c.Id;
		cr.Customer__c = custParent.Id;
		cr.Payment_Method_3__c = pm.Id;
		cr.Transaction_ID__c = 'abc123';
		cr.Type__c = 'Receipt';
		
		insert cr;
		
		Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
		crl.Customer_Receipt__c = cr.Id;
		crl.Amount__c = 10;
		crl.Type__c = 'Prepayment';
		insert crl;
		
		cr.Finalized__c = true;
		update cr;
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		
		Test.startTest();
		
		PaymentHandler ph = new PaymentHandler();
		PaymentHandler.TransactionDetail td = ph.getTransaction('abc123');
		
		Test.stopTest();
		
		system.assertNotEquals(null, td);
    }
    
    static testMethod void testConnection(){
    	
    	insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
    	Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
    	
    	Test.startTest();
		
		PaymentHandler ph = new PaymentHandler();
		Boolean isSuccess = ph.testConnection();
		
		Test.stopTest();
		
		system.assert(isSuccess);
    }
    
    @testVisible
    private static map<string, string> requestResponseBodies = new map<string, string>{
    	'getCustomerProfileRequest' 			=> 	'<?xml version="1.0" encoding="utf-8"?> <getCustomerProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <profile> <merchantCustomerId>custId123</merchantCustomerId> <description>some description</description> <email>mark@example.com</email> <customerProfileId>10000</customerProfileId> <paymentProfiles> <billTo> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> <faxNumber></faxNumber> </billTo> <customerPaymentProfileId>20000</customerPaymentProfileId> <payment> <creditCard> <cardNumber>XXXX1111</cardNumber> <expirationDate>XXXX</expirationDate> </creditCard> </payment> </paymentProfiles> <paymentProfiles> <customerPaymentProfileId>20001</customerPaymentProfileId> <payment> <bankAccount> <accountType>checking</accountType> <routingNumber>XXXX0000</routingNumber> <accountNumber>XXXX0000</accountNumber> <nameOnAccount>John Doe</nameOnAccount> <bankName>Bank of Washington</bankName> </bankAccount> </payment> </paymentProfiles> <shipToList> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> <faxNumber></faxNumber> </shipToList> <shipToList> <firstName>Jane</firstName> <lastName>Doe</lastName> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> </shipToList> </profile> </getCustomerProfileResponse>',
    	'createCustomerProfileRequest' 			=>	'<?xml version="1.0" encoding="UTF-8"?> <createCustomerProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <customerProfileId>38545475</customerProfileId> <customerPaymentProfileIdList> <numericString>35049701</numericString> </customerPaymentProfileIdList> <customerShippingAddressIdList /> <validationDirectResponseList> <string>1,1,1,(TESTMODE) This transaction has been approved.,000000,P,0,none,Test transaction for ValidateCustomerPaymentProfile.,1.00,CC,auth_only,Cust_Id_1450292633,,,,,,,,,,,ryan.sieve@kenandy.com,,,,,,,,,0.00,0.00,0.00,FALSE,none,939D83D40EDEAB16DCEC897FE84C3C85,,,,,,,,,,,,,XXXX1111,Visa,,,,,,,,,,,,,,,,</string> </validationDirectResponseList> </createCustomerProfileResponse>',
    	'createCustomerPaymentProfileRequest'	=>	'<?xml version="1.0" encoding="utf-8"?> <createCustomerPaymentProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <customerPaymentProfileId>20000</customerPaymentProfileId> <validationDirectResponse>1,1,1,This transaction has been approved.,000000,Y,2000000000,none,Test transaction for ValidateCustomerPaymentProfile.,0.01,CC,auth_only,custId123, John,Doe,,123 Main St.,Bellevue,WA,98004,USA,000-000-0000,,mark@example.com,,,,,,,,,0.00,0.00,0.00,,none, D18EB6B211FE0BBF556B271FDA6F92EE,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, </validationDirectResponse> </createCustomerPaymentProfileResponse>',
    	'createTransactionRequest'				=> 	'<?xml version="1.0" encoding="utf-8"?> <createTransactionResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <refId>123456</refId> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <transactionResponse> <responseCode>1</responseCode> <authCode>UGELQC</authCode> <avsResultCode>E</avsResultCode> <cavvResultCode /> <transId>2148061808</transId> <refTransID /><errors></errors> <transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash> <accountNumber>XXXX0015</accountNumber> <accountType>MasterCard</accountType> <message> <code>1</code> <description>This transaction has been approved.</description> </message> <userFields> <userField> <name>MerchantDefinedFieldName1</name> <value>MerchantDefinedFieldValue1</value> </userField> <userField> <name>favorite_color</name> <value>lavender</value> </userField> </userFields> </transactionResponse> </createTransactionResponse>',
    	'authenticateTestRequest'				=> 	'<?xml version="1.0" encoding="utf-8"?> <authenticateTestResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> </authenticateTestResponse>',
    	'getTransactionDetailsRequest'			=> 	'<?xml version="1.0" encoding="utf-8"?> <getTransactionDetailsResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <transaction> <transId>12345</transId> <refTransId>12345</refTransId> <splitTenderId>12345</splitTenderId> <submitTimeUTC>2010-08-30T17:49:20.757Z</submitTimeUTC> <submitTimeLocal>2010-08-30T13:49:20.757</submitTimeLocal> <transactionType>authCaptureTransaction</transactionType> <transactionStatus>capturedPendingSettlement</transactionStatus> <responseCode>1</responseCode> <responseReasonCode>1</responseReasonCode> <responseReasonDescription> Approval</responseReasonDescription> <authCode>000000</authCode> <AVSResponse>X</AVSResponse> <cardCodeResponse>M</cardCodeResponse> <CAVVResponse>2</CAVVResponse> <FDSFilterAction>authAndHold</FDSFilterAction> <FDSFilters> <FDSFilter> <name>Hourly Velocity Filter</name> <action>authAndHold</action> </FDSFilter> <FDSFilter> <name>Amount Filter</name> <action>report</action> </FDSFilter> </FDSFilters> <batch> <batchId>12345</batchId> <settlementTimeUTC>2010-08-30T17:49:20.757Z</settlementTimeUTC> <settlementTimeLocal>2010-08-30T13:49:20.757</settlementTimeLocal> <settlementState>settledSuccessfully</settlementState> </batch> <order> <invoiceNumber>INV00001</invoiceNumber> <description>some description</description> <purchaseOrderNumber>PO000001</purchaseOrderNumber> </order> <requestedAmount>5.00</requestedAmount> <authAmount>2.00</authAmount> <settleAmount>2.00</settleAmount> <tax> <amount>1.00</amount> <name>WA state sales tax</name> <description>Washington state sales tax</description> </tax> <shipping> <amount>2.00</amount> <name>ground based shipping</name> <description>Ground based 5 to 10 day shipping</description> </shipping> <duty> <amount>1.00</amount> </duty> <lineItems> <lineItem> <itemId>ITEM00001</itemId> <name>name of item sold</name> <description>Description of item sold</description> <quantity>1</quantity> <unitPrice>6.95</unitPrice> <taxable>true</taxable> </lineItem> <lineItem> <itemId>ITEM00001</itemId> <name>name of item sold</name> <description>Description of item sold</description> <quantity>1</quantity> <unitPrice>6.95</unitPrice> <taxable>true</taxable> </lineItem> </lineItems> <prepaidBalanceRemaining>30.00</prepaidBalanceRemaining> <taxExempt>false</taxExempt> <payment> <!-- either creditCard or bankAccount will be here --> <creditCard> <cardNumber>XXXX1111</cardNumber> <expirationDate>XXXX</expirationDate> <accountType>Visa</accountType> </creditCard> <!--<bankAccount> <routingNumber>XXXX0000</routingNumber> <accountNumber>XXXX0000</accountNumber> <nameOnAccount>John Doe</nameOnAccount> <echeckType>WEB</echeckType> </bankAccount>--> </payment> <customer> <type>individual</type> <id>ABC00001</id> <email>mark@example.com</email> </customer> <billTo> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> <faxNumber></faxNumber> </billTo> <shipTo> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> </shipTo> <recurringBilling>false</recurringBilling> <customerIP>0.0.0.0</customerIP> <subscription> <id>145521</id> <paynum>1</paynum> <marketType>eCommerce</marketType> <product>Card Not Present</product> <returnedItems> <returnedItem> <id>2148878904</id> <dateUTC>2014-05-12T21:22:44Z</dateUTC> <dateLocal>2014-05-12T14:22:44</dateLocal> <code>R02</code> <description>Account Closed</description> </returnedItem> </returnedItems> <solution> <id>A1000004</id> <name>Shopping Cart</name> </solution> <mobileDeviceId>2354578983274523978</mobileDeviceId> </subscription> </transaction> </getTransactionDetailsResponse>'									
    };
}