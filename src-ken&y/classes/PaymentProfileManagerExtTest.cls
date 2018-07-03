@isTest
public class PaymentProfileManagerExtTest {
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
			data.salesOrderLines != null
			
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
	        resp.setBody(requestResponseBodies.get(reqRootName));
	    	return resp;
	    }
	}
     static testMethod void testExtensionCantCreateProfile_SoldTo(){
     	TestFuelQuery fuel = new TestFuelQuery();
     	Customer__c customerSoldTo = fuel.customerSoldTo;
     	PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(customerSoldTo));
     	system.assertEquals(false,ext.isValidCustomer,'should return false customer is '+customerSoldTo);
     	
     }
    static testMethod void testExtensionCreateProfile(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		
		Test.startTest();
		
			PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
        	system.assertEquals(true,ext.isValidCustomer,'should return false customer is '+custParent);
        	ext.ppd.creditCard.cardNumber = '4111111111111111';
        	ext.ppd.creditCard.expirationDate = '2020-12';
  			ext.ppd.creditCard.CCV = '111';
  			ext.ppd.emailAddress = 'test@kenandy.com';
        	ext.createPaymentProfile();
		
		Test.stopTest();
        
        List<Payment_Profile__c> pps = [SELECT Id, Name,Email_Address__c,
                                 	(SELECT Id FROM Payment_Methods__r)
                                 FROM Payment_Profile__c
                                 WHERE Customer__c = :custParent.Id];
        system.assertEquals(1, pps.size());
         system.assertEquals('test@kenandy.com', pps[0].Email_Address__c);
        system.assertEquals(1, pps[0].Payment_Methods__r.size());
        
    }

    static testMethod void testExtensionCreateProfile_MissingCCFields(){
        String expectedErrorMsg = 'Credit card number, expiration date and CCV are required';
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    
        TestFuelQuery fuel = new TestFuelQuery();
        Company__c c = fuel.Company;
        Customer__c custParent = fuel.customerParent;
        
        Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
        
        Test.startTest();
        
        // Credit card has no CCV and expiration date
        PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
        ext.ppd.creditCard.cardNumber = null;
        ext.ppd.emailAddress = 'test@kenandy.com';
        ext.ppd.creditCard.expirationDate = null;
        ext.ppd.creditCard.CCV = null;
        ext.createPaymentProfile();
        
        Test.stopTest();
        system.assertEquals(Apexpages.hasMessages(), true);
        system.assertEquals(Apexpages.getMessages().size(), 1);
        system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains(expectedErrorMsg));
    }
    
    //Authorize.net Payment Form Fields Test
    static testMethod void testExtensionCreateProfile_MissingBillToFirstName(){
        String expectedErrorMsg = 'Bill To First Name is required.';
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    
        TestFuelQuery fuel = new TestFuelQuery();
        Company__c c = fuel.Company;
        Customer__c custParent = fuel.customerParent;
        
        Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
        // Simulate error message response by authorize.net
        String response = requestResponseBodies.get('createCustomerProfileRequest');
        
        String errorResponse = response.replace('<text>Successful.</text>','<text>' + expectedErrorMsg +'</text>');
        String resultCodeResponse = errorResponse.replace('<resultCode>Ok</resultCode>', '<resultCode>Error</resultCode>');
        String errorCodeResponse = resultCodeResponse.replace('<code>I00001</code>', '<code>E00027</code>');
        requestResponseBodies.put('createCustomerProfileRequest', errorCodeResponse);
        
        Test.startTest();
        PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
        ext.ppd.creditCard.cardNumber = '4111111111111111';
        ext.ppd.emailAddress = 'test@kenandy.com';
        ext.ppd.creditCard.expirationDate = '2020-06';
        ext.ppd.creditCard.CCV = '111';
        ext.ppd.creditCard.firstName = null;
        ext.ppd.customerId = custParent.Id;
        ext.createPaymentProfile();
        Test.stopTest();
        system.assertEquals(Apexpages.hasMessages(), true);
        system.assertEquals(Apexpages.getMessages().size(), 1);
        system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains(expectedErrorMsg));
    }
    
    //Authorize.net Payment Form Fields Test
    static testMethod void testExtensionCreateProfile_MissingBillToCity(){
        String expectedErrorMsg = 'Bill To City is required.';
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    
        TestFuelQuery fuel = new TestFuelQuery();
        Company__c c = fuel.Company;
        Customer__c custParent = fuel.customerParent;
        
        Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
        // Simulate error message response by authorize.net
        String response = requestResponseBodies.get('createCustomerProfileRequest');
        
        String errorResponse = response.replace('<text>Successful.</text>','<text>' + expectedErrorMsg +'</text>');
        String resultCodeResponse = errorResponse.replace('<resultCode>Ok</resultCode>', '<resultCode>Error</resultCode>');
        String errorCodeResponse = resultCodeResponse.replace('<code>I00001</code>', '<code>E00027</code>');
        requestResponseBodies.put('createCustomerProfileRequest', errorCodeResponse);
        
        Test.startTest();
        PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
        ext.ppd.creditCard.cardNumber = '4111111111111111';
        ext.ppd.emailAddress = 'test@kenandy.com';
        ext.ppd.creditCard.expirationDate = '2020-06';
        ext.ppd.creditCard.CCV = '111';
        ext.ppd.creditCard.firstName = 'John';
        ext.ppd.creditCard.lastName = 'John';
        ext.ppd.creditCard.address = '222 Baker Street';
        ext.ppd.creditCard.city = null;
        ext.ppd.creditCard.state = 'CA';
        ext.ppd.creditCard.country = 'USA';
        ext.ppd.creditCard.zip = '90210';
        ext.ppd.creditCard.phone = '(555)555-5555';
        ext.ppd.creditCard.fax = '(555)555-5555';
        ext.ppd.customerId = custParent.Id;
        ext.createPaymentProfile();
        Test.stopTest();
        system.assertEquals(Apexpages.hasMessages(), true);
        system.assertEquals(Apexpages.getMessages().size(), 1);
        system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains(expectedErrorMsg));
    }
    
    static testMethod void testExtensionCreateMethod(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		
        Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
        
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		
		Test.startTest();
		
			PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
        	ext.togglePmtMethod();
        
        ext.ppd.creditCard.cardNumber = '4111111111111111';
        ext.ppd.creditCard.expirationDate = '2020-12';
        ext.ppd.creditCard.CCV = '111';
        	ext.createPaymentMethod();
		
		Test.stopTest();
        
        List<Payment_Method__c> pms = [SELECT Id, Name
                                 FROM Payment_Method__c
                                 WHERE Payment_Profile__c = :pp.Id];
        system.assertEquals(1, pms.size());
        system.assert(pms[0].Name.contains('12-2020'), '>>>> payment method :' + pms[0]);
        system.assert(pms[0].Name.contains('111'), '>>>> payment method :' + pms[0]);
    }
    
    static testMethod void testExtensionCreatePaymentMethod_NoCCV(){ //KNDY-10371
        String expectedErrorMsg = 'Credit card number, expiration date and CCV are required';
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
        TestFuelQuery fuel = new TestFuelQuery();
        Company__c c = fuel.Company;
        Customer__c custParent = fuel.customerParent;

        Payment_Profile__c pp = new Payment_Profile__c();
        pp.Customer__c = custParent.Id;
        pp.Gateway__c = 'Authorize.net';
        pp.Payment_Profile_ID__c = 'custId123';
        insert pp;

        Test.startTest();
        PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
        ext.togglePmtMethod();
        ext.ppd.creditCard.cardNumber = '4111111111111111';
        ext.ppd.creditCard.expirationDate = '2020-12';
        ext.ppd.creditCard.CCV = null;
        ext.createPaymentMethod();
        Test.stopTest();
        system.assertEquals(Apexpages.hasMessages(), true);
        system.assertEquals(Apexpages.getMessages().size(), 1);
        system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains(expectedErrorMsg));
    }
    
    static testMethod void testExtensionCreatePayment(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		
        Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
        
        Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
        
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		
		Test.startTest();
		
		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
        	ext.crl.Amount__c = 100;
        	boolean errorExists = false;
        	ext.createPayment();
        Test.stopTest();
        for( ApexPages.Message msg :ApexPages.GetMessages()){
            if(msg.getDetail()  == 'Please enter customer invoice or sales order.'){
                errorExists = true;
                break;
            }
        }
        system.assertEquals( errorExists,true, ApexPages.GetMessages());
    }
    
    static testMethod void testExtensionCreatePayment_SalesOrder(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
		TestFuelQuery fuel = new TestFuelQuery();
		List<Period__c> periods = fuel.periodList;
		Company__c c = fuel.Company;
		system.assertNotEquals(null, fuel.bankAccount.Id);
		Customer__c custParent = fuel.customerParent;
		custParent.Default_Bill_To_Customer__c = fuel.customerBillTo.Id;
		update custParent;
		Sales_Order__c salesOrder = fuel.salesOrder;
        Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
        
        Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
        
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		
		Test.startTest();
			Test.setCurrentPageReference(new PageReference('Page.PaymentProfileManager'));
			System.currentPageReference().getParameters().put('salesOrderId', salesOrder.Id);
			PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
			ext.paymentCCV = '123';
        	ext.crl.Amount__c = 100;
        	ext.createPayment();
		
		Test.stopTest();
        system.assertEquals(ext.paymentCCV,ext.ppd.creditCard.CCV,ext.ppd);
        List<Customer_Receipt__c> crs = [SELECT Id, Name, Finalized__c 
                                 FROM Customer_Receipt__c
                                 WHERE Payment_Method_3__c = :pm.Id
                                 AND Amount_Received__c = 100];
        system.assertEquals(1, crs.size(),ApexPages.getMessages());
         system.assertEquals(true, crs[0].Finalized__c,ApexPages.getMessages());
        list<Customer_Invoice__c> lCIs = [select id, Sales_Order__c, Bill_To_Customer__c from Customer_Invoice__c where Invoice_Type__c ='Prepayment'];
        system.assertEquals(1, lCIs.size());
        system.assertEquals(salesOrder.Id, lCIs[0].Sales_Order__c);
        system.assertEquals(fuel.customerBillTo.Id, lCIs[0].Bill_To_Customer__c);
    }
    
    static testMethod void testExtensionCreatePayment_SalesOrder_Declined(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		system.assertNotEquals(null, fuel.bankAccount.Id);
		Customer__c custParent = fuel.customerParent;
		custParent.Default_Bill_To_Customer__c = fuel.customerBillTo.Id;
		update custParent;
		Sales_Order__c salesOrder = fuel.salesOrder;
        Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
        
        Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
        
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		requestResponseBodies.put('createTransactionRequest', requestResponseBodies.get('createTransactionRequest').replace('<responseCode>1</responseCode>','<responseCode>2</responseCode>'));
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.PaymentProfileManager'));
		System.currentPageReference().getParameters().put('salesOrderId', salesOrder.Id);
		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
        	ext.crl.Amount__c = 100;
        	ext.createPayment();
		
		Test.stopTest();
        system.assertEquals(null,ext.ppd.creditCard.CCV,ext.ppd);
        List<Customer_Receipt__c> crs = [SELECT Id, Name, Finalized__c, Status__c  
                                 FROM Customer_Receipt__c
                                 WHERE Payment_Method_3__c = :pm.Id
                                 AND Amount_Received__c = 100];
        system.assertEquals(1, crs.size(),ApexPages.getMessages());
        system.assertEquals('Cancelled', crs[0].Status__c,ApexPages.getMessages());
    }
    
    static testMethod void testExtensionCreatePayment_BankAccountNotPopulated(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		c.Credit_Card_Bank_Account__c = null;
		update c;
		Customer__c custParent = fuel.customerParent;
		custParent.Default_Bill_To_Customer__c = fuel.customerBillTo.Id;
		update custParent;
		Sales_Order__c salesOrder = fuel.salesOrder;
        Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
        
        Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
        
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		requestResponseBodies.put('createTransactionRequest', requestResponseBodies.get('createTransactionRequest').replace('<responseCode>1</responseCode>','<responseCode>2</responseCode>'));
		Test.startTest();
			Test.setCurrentPageReference(new PageReference('Page.PaymentProfileManager'));
			System.currentPageReference().getParameters().put('salesOrderId', salesOrder.Id);
			PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
        	ext.crl.Amount__c = 100;
        	boolean errorExists = false;
        	ext.createPayment();
        	for( ApexPages.Message msg :ApexPages.GetMessages())
        	if(msg.getDetail()  == 'Please populate the Credit Card Bank Account lookup on the company.')
        	{
        		errorExists = true;
        		break;
        	}
        system.assertEquals( errorExists,true, ApexPages.GetMessages());
		
		Test.stopTest();
        
        
    }
    
    static testMethod void testExtensionCreatePayment_SalesOrder_HeldForReview(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		List<Period__c> periods = fuel.periodList;
 		system.assertNotEquals(null, fuel.bankAccount.Id);
		Customer__c custParent = fuel.customerParent;
		custParent.Default_Bill_To_Customer__c = fuel.customerBillTo.Id;
		update custParent;
		Sales_Order__c salesOrder = fuel.salesOrder;
        Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
 		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
        
        Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
 		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
        
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		requestResponseBodies.put('createTransactionRequest', requestResponseBodies.get('createTransactionRequest').replace('<responseCode>1</responseCode>','<responseCode>4</responseCode>'));
		Test.startTest();
			Test.setCurrentPageReference(new PageReference('Page.PaymentProfileManager'));
			System.currentPageReference().getParameters().put('salesOrderId', salesOrder.Id);
			PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
        	ext.crl.Amount__c = 100;
        	ext.createPayment();
		
		Test.stopTest();
        
        List<Customer_Receipt__c> crs = [SELECT Id, Name, Finalized__c, Status__c  
                                 FROM Customer_Receipt__c
                                 WHERE Payment_Method_3__c = :pm.Id
                                 AND Amount_Received__c = 100];
        system.assertEquals(1, crs.size(),ApexPages.getMessages());
        system.assertEquals('Held for Review', crs[0].Status__c,ApexPages.getMessages());
        system.assertEquals(false, crs[0].Finalized__c,ApexPages.getMessages());
    }
    
    static testMethod void testExtensionCreatePayment_WithBillTo(){
        
        insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
    	
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		system.assertNotEquals(null, fuel.bankAccount.Id);
		Customer__c custBillTo = fuel.customerBillTo;
		Sales_Order__c salesOrder = fuel.salesOrder;
        Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custBillTo.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
        
        Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
        
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		
		Test.startTest();
			Test.setCurrentPageReference(new PageReference('Page.PaymentProfileManager'));
			System.currentPageReference().getParameters().put('salesOrderId', salesOrder.Id);
			PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custBillTo));
        	ext.crl.Amount__c = 100;
        	ext.createPayment();
		
		Test.stopTest();
        
        List<Customer_Receipt__c> crs = [SELECT Id, Name, Finalized__c 
                                 FROM Customer_Receipt__c
                                 WHERE Payment_Method_3__c = :pm.Id
                                 AND Amount_Received__c = 100];
        system.assertEquals(1, crs.size(),ApexPages.getMessages());
         system.assertEquals(true, crs[0].Finalized__c,ApexPages.getMessages());
        list<Customer_Invoice__c> lCIs = [select id, Sales_Order__c, Bill_To_Customer__c from Customer_Invoice__c where Invoice_Type__c ='Prepayment'];
        system.assertEquals(1, lCIs.size());
        system.assertEquals(salesOrder.Id, lCIs[0].Sales_Order__c);
        system.assertEquals(fuel.customerBillTo.Id, lCIs[0].Bill_To_Customer__c);
    }
    
    // Without salesorder or customer invoice
	static testMethod void testExt_OnlyAmountInURL(){
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		custParent.Default_Bill_To_Customer__c = fuel.customerBillTo.Id;
		update custParent;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
        
        Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
		
		Test.startTest();
		
		// no amount in url
		Test.setCurrentPageReference(new PageReference('Page.PaymentProfileManager'));
		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
		ext.defaultAmount();
		system.assertEquals(Apexpages.hasMessages(), false, '>>>1. ' +Apexpages.getMessages());
		
		// invalid amount in url
		System.currentPageReference().getParameters().put('amount', '2.9***');
		ext.defaultAmount();
		system.assertEquals(Apexpages.getMessages().size(), 1);
		system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains(Label.Amount_in_url_must_be_a_decimal_or_integer));
		
		// extra spaces around amount in url
		system.currentPageReference().getParameters().put('amount', ' 2.9 ');
		ext.defaultAmount();
		system.assertEquals(ext.crl.Amount__c, 2.9 ,'>>>2. ' +Apexpages.getMessages());
		Test.stopTest();
	}
	
	// url amount higher and lower than si order total
	static testMethod void testExt_AmountInURLWithSI(){
		String urlAmount_High = '';
		String urlAmount_Low = '';
		TestFuelQuery fuel = new TestFuelQuery();
		insert new Service_Configuration__c(name = 'AuthorizeNetV1', username__c = 'apiLoginId', password__c = 'transactionKey', description__c = 'test');
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		custParent.Default_Bill_To_Customer__c = fuel.customerBillTo.Id;
		update custParent;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
		
		salesOrder = [Select Id, Order_Total__c from Sales_Order__c
				where Id = :salesOrder.Id];
		system.assert(salesOrder.Order_Total__c != null);
		urlAmount_High = (salesOrder.Order_Total__c + 1) + '';
		urlAmount_Low = (salesOrder.Order_Total__c - 1) + '';
		Test.setMock(HttpCalloutMock.class, new MockRestServiceResponse());
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.PaymentProfileManager'));
		System.currentPageReference().getParameters().put('salesOrderId', salesOrder.Id);
		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
	
		system.currentPageReference().getParameters().put('amount', urlAmount_Low);
		ext.crl.Sales_Order__c = salesOrder.Id;
		ext.crl.Customer_Invoice__c = null;
		ext.defaultAmount();
		system.assertEquals(ext.crl.Amount__c, Decimal.ValueOf(urlAmount_Low));
		system.assert(ext.disableCreatePaymentButton == false);
		system.assertEquals(Apexpages.hasMessages(), false, '>>>4' +Apexpages.getMessages());

		system.currentPageReference().getParameters().put('amount', urlAmount_High);
		ext.defaultAmount();
		system.assertEquals(ext.crl.Amount__c,Decimal.ValueOf(urlAmount_High));
		system.assert(ext.disableCreatePaymentButton == false);
		system.assertEquals(Apexpages.hasMessages(), true);
		system.assertEquals(Apexpages.getMessages().size(), 1);
		system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains('about to charge your customer more than the sales order total'),Apexpages.getMessages());
		//added to proceed with creating payment for high amount
		//ext.crl.Amount__c = 100;
        ext.createPayment();
		
		Test.stopTest();
        system.assertEquals(Decimal.ValueOf(urlAmount_High),1283.47);
        List<Customer_Receipt__c> crs = [SELECT Id, Name, Finalized__c 
                                 FROM Customer_Receipt__c
                                 WHERE Payment_Method_3__c = :pm.Id
                                 AND Amount_Received__c = :1283.47];
        system.assertEquals(1, crs.size(),ApexPages.getMessages());
         system.assertEquals(true, crs[0].Finalized__c,ApexPages.getMessages());
        list<Customer_Invoice__c> lCIs = [select id, Sales_Order__c, Bill_To_Customer__c from Customer_Invoice__c where Invoice_Type__c ='Prepayment'];
        system.assertEquals(1, lCIs.size());
        system.assertEquals(salesOrder.Id, lCIs[0].Sales_Order__c);
        system.assertEquals(fuel.customerBillTo.Id, lCIs[0].Bill_To_Customer__c);
        
        
		
	}
	
	// url amount higher and lower that CI balance
	static testMethod void testExt_AmountInURL_CIWithLines(){
		String urlAmount_High = '';
		String urlAmount_Low = '';
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		custParent.Default_Bill_To_Customer__c = fuel.customerBillTo.Id;
		update custParent;
		Customer_Invoice__c ci = fuel.custInv1;
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
		
		list<Customer_Invoice_Line__c> listCILs = new list<Customer_Invoice_Line__c>();
		listCILs.add(new Customer_Invoice_Line__c(Customer_Invoice__c = ci.id, Unit_Price__c = 1, Quantity_Shipped__c = 10, Extended_Price__c = 100));
		listCILs.add(new Customer_Invoice_Line__c(Customer_Invoice__c = ci.id, Unit_Price__c = 1, Quantity_Shipped__c = 10, Extended_Price__c = 100));
		listCILs.add(new Customer_Invoice_Line__c(Customer_Invoice__c = ci.id, Unit_Price__c = 2, Quantity_Shipped__c = 10, Extended_Price__c = 200));
		insert listCILs;
		
		ci = [Select Id, Balance__c from Customer_Invoice__c
				where Id = :ci.Id];
		system.assert(ci.Balance__c != null);
		urlAmount_High = (ci.Balance__c + 1) + '';
		urlAmount_Low = (ci.Balance__c - 1) + '';
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.PaymentProfileManager'));
		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
	
		system.currentPageReference().getParameters().put('amount', urlAmount_Low);
		ext.crl.Sales_Order__c = null;
		ext.crl.Customer_Invoice__c = ci.Id;
		ext.defaultAmount();
		system.assertEquals(ext.crl.Amount__c, Decimal.ValueOf(urlAmount_Low));
		system.assert(ext.disableCreatePaymentButton == false);
		system.assertEquals(Apexpages.hasMessages(), false, '>>>5' +Apexpages.getMessages());

		system.currentPageReference().getParameters().put('amount', urlAmount_High);
		ext.defaultAmount();
		system.assertEquals(ext.crl.Amount__c, Decimal.ValueOf(urlAmount_High), '>>> ext.crl: ' + ext.crl);
		system.assert(ext.disableCreatePaymentButton == true);
		system.assertEquals(Apexpages.hasMessages(), true);
		system.assertEquals(Apexpages.getMessages().size(), 1);
		system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains(Label.Cannot_charge_an_amount_greater_than_Customer_Invoice_Balance));
		Test.stopTest();
	}
	
	// url amount higher than CI balance 0.0
	static testMethod void testExt_AmountInURL_CIWithoutLines(){
		String urlAmount_High = '';
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		custParent.Default_Bill_To_Customer__c = fuel.customerBillTo.Id;
		update custParent;
		Customer_Invoice__c ci = fuel.custInv1;
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
				
		ci = [Select Id, Balance__c from Customer_Invoice__c
				where Id = :ci.Id];
		system.assert(ci.Balance__c != null);
		system.assert(ci.Balance__c == 0.0);
		urlAmount_High = (ci.Balance__c + 1) + '';
		
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.PaymentProfileManager'));
		PaymentProfileManagerExt ext1 = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
		system.currentPageReference().getParameters().put('amount', urlAmount_High);
		ext1.crl.Sales_Order__c = null;
		ext1.crl.Customer_Invoice__c = ci.Id;
		ext1.defaultAmount();
		system.assertEquals(ext1.crl.Amount__c, Decimal.ValueOf(urlAmount_High), '>>> ext1.crl: ' + ext1.crl);
		system.assert(ext1.disableCreatePaymentButton == true);
		system.assertEquals(Apexpages.hasMessages(), true);
		system.assertEquals(Apexpages.getMessages().size(), 1);
		system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains(Label.Cannot_charge_an_amount_greater_than_Customer_Invoice_Balance));
		Test.stopTest();
	}
	
	//amount change with url amount 
	static testMethod void testExtAmountChange_AmountInURL(){
		String urlAmount_Low = '';
		String highAmount = '';
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		custParent.Default_Bill_To_Customer__c = fuel.customerBillTo.Id;
		update custParent;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
		
		salesOrder = [Select Id, Order_Total__c from Sales_Order__c
				where Id = :salesOrder.Id];
		system.assert(salesOrder.Order_Total__c != null);
		urlAmount_Low = (salesOrder.Order_Total__c - 1) + '';
		highAmount = (salesOrder.Order_Total__c + 1) + '';
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.PaymentProfileManager'));
		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
	
		system.currentPageReference().getParameters().put('amount', urlAmount_Low);
		ext.crl.Sales_Order__c = salesOrder.Id;
		ext.crl.Customer_Invoice__c = null;
		ext.defaultAmount();
		// amount should be the url amount and not the SO order total
		system.assertEquals(ext.crl.Amount__c, Decimal.ValueOf(urlAmount_Low));
		system.assertNotEquals(ext.crl.Amount__c, salesorder.Order_Total__c);
		
		system.assert(ext.disableCreatePaymentButton == false);
		system.assertEquals(Apexpages.hasMessages(), false, '>>>4' +Apexpages.getMessages());
		
		// change the amount to a lower value
		ext.crl.Amount__c = Decimal.ValueOf(urlAmount_Low) - 1;
		ext.validateAmount();
		// amount should not be the url amount, or the so order total
		system.assertNotEquals(ext.crl.Amount__c, Decimal.ValueOf(urlAmount_Low));
		system.assertNotEquals(ext.crl.Amount__c, salesorder.Order_Total__c);
		
		system.assert(ext.disableCreatePaymentButton == false);
		system.assertEquals(Apexpages.hasMessages(), false, '>>>4' +Apexpages.getMessages());
		
		// change the amount to a higher value
		ext.crl.Amount__c = Decimal.ValueOf(highAmount);
		ext.validateAmount();
		// amount should not be the url amount, or the so order total
		system.assertNotEquals(ext.crl.Amount__c, Decimal.ValueOf(urlAmount_Low));
		system.assertNotEquals(ext.crl.Amount__c, salesorder.Order_Total__c);
		
		system.assert(ext.disableCreatePaymentButton == false);
		system.assertEquals(Apexpages.hasMessages(), true);
		system.assertEquals(Apexpages.getMessages().size(), 1);
		system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains('about to charge your customer more than the sales order total'),Apexpages.getMessages());
		Test.stopTest();
	}
	
	//amount change without url amount 
	static testMethod void testExtAmountChange_NoAmountInURL(){
		Decimal lowAmount ;
		Decimal highAmount ;
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		custParent.Default_Bill_To_Customer__c = fuel.customerBillTo.Id;
		update custParent;
		Customer_Invoice__c ci = fuel.custInv1;
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;
		
		list<Customer_Invoice_Line__c> listCILs = new list<Customer_Invoice_Line__c>();
		listCILs.add(new Customer_Invoice_Line__c(Customer_Invoice__c = ci.id, Unit_Price__c = 1, Quantity_Shipped__c = 10, Extended_Price__c = 100));
		listCILs.add(new Customer_Invoice_Line__c(Customer_Invoice__c = ci.id, Unit_Price__c = 1, Quantity_Shipped__c = 10, Extended_Price__c = 100));
		listCILs.add(new Customer_Invoice_Line__c(Customer_Invoice__c = ci.id, Unit_Price__c = 2, Quantity_Shipped__c = 10, Extended_Price__c = 200));
		insert listCILs;
		
		ci = [Select Id, Balance__c from Customer_Invoice__c
				where Id = :ci.Id];
		system.assert(ci.Balance__c != null);
		highAmount = ci.Balance__c + 1;
		lowAmount = ci.Balance__c - 1;
		Test.startTest();
		Test.setCurrentPageReference(new PageReference('Page.PaymentProfileManager'));
		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
		
		ext.crl.Sales_Order__c = null;
		ext.crl.Customer_Invoice__c = ci.Id;
		ext.defaultAmount();
		// amount should be ci`s balance
		system.assertEquals(ext.crl.Amount__c, ci.Balance__c);
		system.assert(ext.disableCreatePaymentButton == false);
		system.assertEquals(Apexpages.hasMessages(), false, '>>>5' +Apexpages.getMessages());
		
		// change the amount to a lower value
		ext.crl.Amount__c = lowAmount;
		ext.validateAmount();
		// amount should not be the ci balance
		system.assertNotEquals(ext.crl.Amount__c, ci.Balance__c);
		system.assert(ext.disableCreatePaymentButton == false);
		system.assertEquals(Apexpages.hasMessages(), false, '>>>4' +Apexpages.getMessages());
		
		// change the amount to a higher value
		ext.crl.Amount__c = highAmount;
		ext.validateAmount();
		// amount should not be the ci balance
		system.assertNotEquals(ext.crl.Amount__c, ci.Balance__c);
		
		system.assert(ext.disableCreatePaymentButton == true);
		system.assertEquals(Apexpages.hasMessages(), true);
		system.assertEquals(Apexpages.getMessages().size(), 1);
		system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains(Label.Cannot_charge_an_amount_greater_than_Customer_Invoice_Balance));

		Test.stopTest();
	}
	
	//  Tests for 
	//  Payment Profile for Top Parent Customer
	//  CIs with same PP customer  
	//  and SOs whose sold-To customer belong to PP customer
	static testMethod void testCreatePaymentButton_PPTopCustomer_SameCustomer(){ //KNDY-11812
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		Customer_Invoice__c ci = fuel.custInv1;
		Sales_Order__c so = fuel.salesOrder;
		
		Test.startTest();
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;

		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
		system.assert(ext.disableCreatePaymentButton == false);
		
		// Both CI and SO lookups exist
		ext.crl.Customer_Invoice__c = ci.Id;
		ext.crl.Sales_Order__c = so.Id;
		ext.defaultAmount();
		system.assert(ext.disableCreatePaymentButton == true);
		
		// Only CI lookup exists
		ext.crl.Sales_Order__c = null;
		ext.defaultAmount();
		system.assert(ext.disableCreatePaymentButton == false);
		
		// Only SO lookup exists
		ext.crl.Customer_Invoice__c = null;
		ext.crl.Sales_Order__c = so.Id;
		ext.defaultAmount();
		system.assert(ext.disableCreatePaymentButton == false);
				
		Test.stopTest();
	}
	

	
	//  Tests for 
	//  Payment Profile for Top Parent Customer
	//  CIs whose customer is different from PP customer  
	static testMethod void testCreatePaymentButtonCI_PPTopCustomer_DifferentCustomer(){ //KNDY-11812
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		
		Test.startTest();
		
		// Create customers for new company
		Company__c company2 = fuel.altCompany;
		
		Customer__c customerParent2 = fuel.customerParent.clone();
		customerParent2.name = company2.Name + ' Customer Corp Parent 2';
		customerParent2.Company__c = company2.id;
		customerParent2.Customer_Identifier__c = 'CP2TEST123';
		insert customerParent2;
		
		Customer__c custBillTo_2 = fuel.customerBillTo.clone();
		custBillTo_2.name = 'Customer Bill To 2';
		custBillTo_2.Customer_Identifier__c = 'BDTEST1234'; 
		custBillTo_2.Company__c = company2.id;
		custBillTo_2.Parent_Customer__c = customerParent2.id; 
		custBillTo_2.Top_Parent_Customer__c = customerParent2.id;
		
		Customer__c custSoldTo_2 = fuel.customerSoldTo.clone();
		custSoldTo_2.name = 'Customer Sold To 2';
		custSoldTo_2.Customer_Identifier__c = 'SDTEST1234'; 
		custSoldTo_2.Company__c = company2.id;
		custSoldTo_2.Top_Parent_Customer__c = customerParent2.id;

		List<Customer__c> customers = new List<Customer__c> {custBillTo_2,custSoldTo_2};
		insert customers;
		custSoldTo_2.Parent_Customer__c = custBillTo_2.id; 
		update customers;
		
		// Create CI for customer
		Customer_Invoice__c ci_2 = fuel.custInv1.clone();
		ci_2.Bill_To_Customer__c = custBillTo_2.id;
		ci_2.Sold_To_Customer__c = custSoldTo_2.id;
		insert ci_2;
		
		// Create Payment Profile for another company corp customer
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;

		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
		system.assert(ext.disableCreatePaymentButton == false);
		
		// Customer Invoice and Payment Profile are for different customer
		ext.crl.Sales_Order__c = null;
		ext.crl.Customer_Invoice__c = ci_2.Id;
		ext.defaultAmount();
		system.assert(ext.disableCreatePaymentButton == true);
		
		Test.stopTest();
	}
	
	//  Tests for 
	//  Payment Profile for Top Parent Customer
	//  SOs whose customer is different from PP customer  
	static testMethod void testCreatePaymentButtonSO_PPTopCustomer_DifferentCustomer(){ //KNDY-11812
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		Sales_Order__c so = fuel.salesOrder;
		
		Test.startTest();
		
		// Create customers for new company
		Company__c company2 = fuel.altCompany;
		
		Customer__c customerParent2 = fuel.customerParent.clone();
		customerParent2.name = company2.Name + ' Customer Corp Parent 2';
		customerParent2.Company__c = company2.id;
		customerParent2.Customer_Identifier__c = 'CP2TEST123';
		insert customerParent2;
		
		Customer__c custBillTo_2 = fuel.customerBillTo.clone();
		custBillTo_2.name = 'Customer Bill To 2';
		custBillTo_2.Customer_Identifier__c = 'BDTEST1234'; 
		custBillTo_2.Company__c = company2.id;
		custBillTo_2.Parent_Customer__c = customerParent2.id; 
		custBillTo_2.Top_Parent_Customer__c = customerParent2.id;
		
		Customer__c custSoldTo_2 = fuel.customerSoldTo.clone();
		custSoldTo_2.name = 'Customer Sold To 2';
		custSoldTo_2.Customer_Identifier__c = 'SDTEST1234'; 
		custSoldTo_2.Company__c = company2.id;
		custSoldTo_2.Top_Parent_Customer__c = customerParent2.id;
		
		Customer__c custShipTo_2 = fuel.customerShipTo.clone();
		custShipTo_2.name = 'Customer Ship To 2';
		custShipTo_2.Customer_Identifier__c = 'SHTEST1234'; 
		custShipTo_2.Company__c = company2.id;
		custShipTo_2.Top_Parent_Customer__c = customerParent2.id;
	
		List<Customer__c> customers = new List<Customer__c> {custBillTo_2,custSoldTo_2,custShipTo_2};
		insert customers;
		custSoldTo_2.Parent_Customer__c = custBillTo_2.id;
		custShipTo_2.Parent_Customer__c = custSoldTo_2.id; 
		update customers;
		
		// Create SO for customer
		Sales_Order__c so_2 = fuel.salesOrder.clone();
		so_2.Company__c = company2.id;
		so_2.Customer__c = custSoldTo_2.id;
		so_2.Ship_To__c = custShipTo_2.Id;
		so_2.Bill_To__c = custBillTo_2.Id;
		insert so_2;
		
		// Create Payment Profile for another company corp customer
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = custParent.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;

		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(custParent));
		system.assert(ext.disableCreatePaymentButton == false);
	
		// Sales Order and Payment Profile are for different customer
		ext.crl.Sales_Order__c = so_2.Id;
		ext.crl.Customer_Invoice__c = null;
		ext.defaultAmount();
		system.assert(ext.disableCreatePaymentButton == true);
		
		Test.stopTest();
	}
	
	//  Tests for 
	//  Payment Profile for Bill To Customer
	//  CIs whose Bill To customer same as PP customer,
	static testMethod void testCreatePaymentButtonCI_PPBillToCustomer_Valid(){ //KNDY-11812
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		Customer_Invoice__c ci = fuel.custInv1;
		Customer__c billToCustomer = fuel.customerBillTo;
		Sales_Order__c so = fuel.salesOrder;
		system.assert(ci.Bill_To_Customer__c == billToCustomer.Id);
		
		Test.startTest();
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = billToCustomer.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;

		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(billToCustomer));
		system.assert(ext.disableCreatePaymentButton == false);
		
		ext.crl.Customer_Invoice__c = ci.Id;
		ext.defaultAmount();
		system.assert(ext.disableCreatePaymentButton == false);
		Test.stopTest();
	}
	
	//  Tests for 
	//  Payment Profile for Bill To Customer
	//  Top Parent Customer has 2 Bill To Customers
	//  CIs whose Bill To customer is different as PP customer,
	//     and Customer is same as PP Bill To customer`s top parent customer
	static testMethod void testCreatePaymentButtonCI_PPBillToCustomer_Invalid(){ //KNDY-11812
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c customerParent = fuel.customerParent;
		Customer__c billToCustomer = fuel.customerBillTo;
		Customer_Invoice__c ci = fuel.custInv1;
		Sales_Order__c so = fuel.salesOrder;
		system.assert(ci.Bill_To_Customer__c == billToCustomer.Id);
		
		Customer__c custBillTo_2 = fuel.customerBillTo.clone();
		custBillTo_2.name = 'Customer Bill To 2';
		custBillTo_2.Customer_Identifier__c = 'BDTEST1234'; 
		custBillTo_2.Company__c = c.id;
		custBillTo_2.Parent_Customer__c = customerParent.id; 
		custBillTo_2.Top_Parent_Customer__c = customerParent.id;
		
		Customer__c custSoldTo_2 = fuel.customerSoldTo.clone();
		custSoldTo_2.name = 'Customer Sold To 2';
		custSoldTo_2.Customer_Identifier__c = 'SDTEST1234'; 
		custSoldTo_2.Company__c = c.id;
		custSoldTo_2.Top_Parent_Customer__c = customerParent.id;

		List<Customer__c> customers = new List<Customer__c> {custBillTo_2,custSoldTo_2};
		insert customers;
		custSoldTo_2.Parent_Customer__c = custBillTo_2.id; 
		update customers;
		
		// Create CI for customer
		Customer_Invoice__c ci_2 = fuel.custInv1.clone();
		ci_2.Bill_To_Customer__c = custBillTo_2.id;
		ci_2.Sold_To_Customer__c = custSoldTo_2.id;
		insert ci_2;
		
		Test.startTest();
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = billToCustomer.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;

		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(billToCustomer));
		system.assert(ext.disableCreatePaymentButton == false);
		
		ext.crl.Customer_Invoice__c = ci_2.Id;
		ext.defaultAmount();
		system.assert(ext.disableCreatePaymentButton == true);
		Test.stopTest();
	}
	
	//  Tests for 
	//  Payment Profile for Bill To Customer
	//  Prepayment CIs with no Bill To customer 
	//     and Customer is same as PP Bill To customer`s top parent customer
	static testMethod void testCreatePaymentButton_PrepaymentCI_PPBillToCustomer_Invalid(){ //KNDY-11812
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c customerParent = fuel.customerParent;
		Customer__c billToCustomer = fuel.customerBillTo;
		Customer_Invoice__c ci = fuel.custInv1;
		system.assert(ci.Bill_To_Customer__c == billToCustomer.Id);
		
		ci.Invoice_Type__c = 'Prepayment';
		ci.Bill_To_Customer__c = null;
		update ci;
		
		Test.startTest();
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = billToCustomer.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;

		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(billToCustomer));
		system.assert(ext.disableCreatePaymentButton == false);
		
		ext.crl.Customer_Invoice__c = ci.Id;
		ext.defaultAmount();
		system.assert(ext.disableCreatePaymentButton == true);
		Test.stopTest();
	}
	
	//  Tests for 
	//  Payment Profile for Bill To Customer
	//  SO whose Bill To customer same as PP customer,
	static testMethod void testCreatePaymentButtonSO_PPBillToCustomer_Valid(){ //KNDY-11812
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		Customer_Invoice__c ci = fuel.custInv1;
		Customer__c billToCustomer = fuel.customerBillTo;
		Sales_Order__c so = fuel.salesOrder;
		system.assert(ci.Bill_To_Customer__c == billToCustomer.Id);
		
		Test.startTest();
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = billToCustomer.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;

		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(billToCustomer));
		system.assert(ext.disableCreatePaymentButton == false);
		
		ext.crl.Sales_Order__c = so.Id;
		ext.defaultAmount();
		system.assert(ext.disableCreatePaymentButton == false);
		Test.stopTest();
	}
	
	//  Tests for 
	//  Payment Profile for Bill To Customer
	//  Top Parent Customer has 2 Bill To Customers
	//  SO whose Bill To customer is different from PP customer,
	//     and Sold To Customer`s Top Parent is same as PP Bill To customer`s top parent
	static testMethod void testCreatePaymentButtonSO_PPBillToCustomer_Invalid(){ //KNDY-11812
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c customerParent = fuel.customerParent;
		Customer__c billToCustomer = fuel.customerBillTo;
		Customer_Invoice__c ci = fuel.custInv1;
		Sales_Order__c so = fuel.salesOrder;
		system.assert(ci.Bill_To_Customer__c == billToCustomer.Id);
		
		Customer__c custBillTo_2 = fuel.customerBillTo.clone();
		custBillTo_2.name = 'Customer Bill To 2';
		custBillTo_2.Customer_Identifier__c = 'BDTEST1234'; 
		custBillTo_2.Company__c = c.id;
		custBillTo_2.Parent_Customer__c = customerParent.id; 
		custBillTo_2.Top_Parent_Customer__c = customerParent.id;
		
		Customer__c custSoldTo_2 = fuel.customerSoldTo.clone();
		custSoldTo_2.name = 'Customer Sold To 2';
		custSoldTo_2.Customer_Identifier__c = 'SDTEST1234'; 
		custSoldTo_2.Company__c = c.id;
		custSoldTo_2.Top_Parent_Customer__c = customerParent.id;
		
		Customer__c custShipTo_2 = fuel.customerShipTo.clone();
		custShipTo_2.name = 'Customer Ship To 2';
		custShipTo_2.Customer_Identifier__c = 'SHTEST1234'; 
		custShipTo_2.Company__c = c.id;
		custShipTo_2.Top_Parent_Customer__c = customerParent.id;

		List<Customer__c> customers = new List<Customer__c> {custBillTo_2,custSoldTo_2};
		insert customers;
		custSoldTo_2.Parent_Customer__c = custBillTo_2.id;
		custShipTo_2.Parent_Customer__c = custSoldTo_2.id; 
		update customers;
		
		// Create SO for customer
		Sales_Order__c so_2 = fuel.salesOrder.clone();
		so_2.Company__c = c.id;
		so_2.Customer__c = custSoldTo_2.id;
		so_2.Ship_To__c = custShipTo_2.Id;
		so_2.Bill_To__c = custBillTo_2.Id;
		insert so_2;
		
		Test.startTest();
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = billToCustomer.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;

		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(billToCustomer));
		system.assert(ext.disableCreatePaymentButton == false);
		
		ext.crl.Sales_Order__c = so_2.Id;
		ext.defaultAmount();
		system.assert(ext.disableCreatePaymentButton == true);
		Test.stopTest();
	}
	
	//  Tests for 
	//  Payment Profile for Sold To Customer
	//  CI and SO whose Sold To customer same as PP customer,
	static testMethod void testCreatePaymentButton_PPSoldToCustomer_Invalid(){ //KNDY-11812
		TestFuelQuery fuel = new TestFuelQuery();
		Company__c c = fuel.Company;
		Customer__c custParent = fuel.customerParent;
		Customer_Invoice__c ci = fuel.custInv1;
		Customer__c soldToCustomer = fuel.customerSoldTo;
		Sales_Order__c so = fuel.salesOrder;
		system.assert(ci.Sold_To_Customer__c == soldToCustomer.Id);
		system.assert(so.Customer__c == soldToCustomer.Id);
		
		Test.startTest();
		Payment_Profile__c pp = new Payment_Profile__c();
		pp.Customer__c = soldToCustomer.Id;
		pp.Gateway__c = 'Authorize.net';
		pp.Payment_Profile_ID__c = 'custId123';
		insert pp;
		
		Payment_Method__c pm = new Payment_Method__c();
		pm.Payment_Profile__c = pp.Id;
		pm.Payment_Method_ID__c = 'abc123';
		insert pm;

		PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(soldToCustomer));
		system.assert(ext.disableCreatePaymentButton == false);
		
		ext.crl.Customer_Invoice__c = ci.Id;
		ext.defaultAmount();
		system.assert(ext.disableCreatePaymentButton == true);
		ext.crl.Sales_Order__c = so.Id;
		ext.crl.Customer_Invoice__c = null;
		ext.defaultAmount();
		system.assert(ext.disableCreatePaymentButton == true);
		Test.stopTest();
	}

    static testMethod void testCreatePaymentButton_ClosedSO_Invalid(){ //KNDY-10289
        TestFuelQuery fuel = new TestFuelQuery();
        Company__c c = fuel.Company;
        Customer__c customerParent = fuel.customerParent;
        Sales_Order__c so = fuel.salesOrder;
        so.Status__c = 'Closed';
        update so;
        so = [Select Id, Status__c from Sales_Order__c
                 where Id = :so.Id];
        system.assert(so.Status__c == 'Closed', '>>> so: ' + so);
        
        Test.startTest();
        Payment_Profile__c pp = new Payment_Profile__c();
        pp.Customer__c = customerParent.Id;
        pp.Gateway__c = 'Authorize.net';
        pp.Payment_Profile_ID__c = 'custId123';
        insert pp;
        
        Payment_Method__c pm = new Payment_Method__c();
        pm.Payment_Profile__c = pp.Id;
        pm.Payment_Method_ID__c = 'abc123';
        insert pm;

        PaymentProfileManagerExt ext = new PaymentProfileManagerExt(new Apexpages.Standardcontroller(customerParent));
        system.assert(ext.disableCreatePaymentButton == false);
        
        ext.crl.Sales_Order__c = so.Id;
        ext.defaultAmount();
        system.assert(ext.disableCreatePaymentButton == true);
        system.assertEquals(Apexpages.hasMessages(), true);
        system.assertEquals(Apexpages.getMessages().size(), 1);
        system.assertEquals(True,Apexpages.getMessages()[0].getdetail().contains(Label.Unable_to_create_credit_card_payment_as_the_sales_order_is_closed));
        
        Test.stopTest();
    }
    
    @testVisible
    private static map<string, string> requestResponseBodies = new map<string, string>{
    	'getCustomerProfileRequest' 			=> 	'<?xml version="1.0" encoding="utf-8"?> <getCustomerProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <profile> <merchantCustomerId>custId123</merchantCustomerId> <description>some description</description> <email>mark@example.com</email> <customerProfileId>10000</customerProfileId> <paymentProfiles> <billTo> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> <faxNumber></faxNumber> </billTo> <customerPaymentProfileId>20000</customerPaymentProfileId> <payment> <creditCard> <cardNumber>XXXX1111</cardNumber> <expirationDate>XXXX</expirationDate> </creditCard> </payment> </paymentProfiles> <paymentProfiles> <customerPaymentProfileId>20001</customerPaymentProfileId> <payment> <bankAccount> <accountType>checking</accountType> <routingNumber>XXXX0000</routingNumber> <accountNumber>XXXX0000</accountNumber> <nameOnAccount>John Doe</nameOnAccount> <bankName>Bank of Washington</bankName> </bankAccount> </payment> </paymentProfiles> <shipToList> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> <faxNumber></faxNumber> </shipToList> <shipToList> <firstName>Jane</firstName> <lastName>Doe</lastName> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> </shipToList> </profile> </getCustomerProfileResponse>',
    	'createCustomerProfileRequest' 			=>	'<?xml version="1.0" encoding="UTF-8"?> <createCustomerProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <customerProfileId>38545475</customerProfileId> <customerPaymentProfileIdList> <numericString>35049701</numericString> </customerPaymentProfileIdList> <customerShippingAddressIdList /> <validationDirectResponseList> <string>1,1,1,(TESTMODE) This transaction has been approved.,000000,P,0,none,Test transaction for ValidateCustomerPaymentProfile.,1.00,CC,auth_only,Cust_Id_1450292633,,,,,,,,,,,ryan.sieve@kenandy.com,,,,,,,,,0.00,0.00,0.00,FALSE,none,939D83D40EDEAB16DCEC897FE84C3C85,,,,,,,,,,,,,XXXX1111,Visa,,,,,,,,,,,,,,,,</string> </validationDirectResponseList> </createCustomerProfileResponse>',
    	'createCustomerPaymentProfileRequest'	=>	'<?xml version="1.0" encoding="utf-8"?> <createCustomerPaymentProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <customerPaymentProfileId>20000</customerPaymentProfileId> <validationDirectResponse>1,1,1,This transaction has been approved.,000000,Y,2000000000,none,Test transaction for ValidateCustomerPaymentProfile.,0.01,CC,auth_only,custId123, John,Doe,,123 Main St.,Bellevue,WA,98004,USA,000-000-0000,,mark@example.com,,,,,,,,,0.00,0.00,0.00,,none, D18EB6B211FE0BBF556B271FDA6F92EE,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, </validationDirectResponse> </createCustomerPaymentProfileResponse>',
    	'createTransactionRequest'				=> 	'<?xml version="1.0" encoding="utf-8"?> <createTransactionResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <refId>123456</refId> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <transactionResponse> <responseCode>1</responseCode> <authCode>UGELQC</authCode> <avsResultCode>E</avsResultCode> <cavvResultCode /> <transId>2148061808</transId> <refTransID /> <transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash> <accountNumber>XXXX0015</accountNumber> <accountType>MasterCard</accountType> <message> <code>1</code> <description>This transaction has been approved.</description> </message> <userFields> <userField> <name>MerchantDefinedFieldName1</name> <value>MerchantDefinedFieldValue1</value> </userField> <userField> <name>favorite_color</name> <value>lavender</value> </userField> </userFields> </transactionResponse> </createTransactionResponse>',
    	'authenticateTestRequest'				=> 	'<?xml version="1.0" encoding="utf-8"?> <authenticateTestResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> </authenticateTestResponse>',
    	'getTransactionDetailsRequest'			=> 	'<?xml version="1.0" encoding="utf-8"?> <getTransactionDetailsResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"> <messages> <resultCode>Ok</resultCode> <message> <code>I00001</code> <text>Successful.</text> </message> </messages> <transaction> <transId>12345</transId> <refTransId>12345</refTransId> <splitTenderId>12345</splitTenderId> <submitTimeUTC>2010-08-30T17:49:20.757Z</submitTimeUTC> <submitTimeLocal>2010-08-30T13:49:20.757</submitTimeLocal> <transactionType>authCaptureTransaction</transactionType> <transactionStatus>capturedPendingSettlement</transactionStatus> <responseCode>1</responseCode> <responseReasonCode>1</responseReasonCode> <responseReasonDescription> Approval</responseReasonDescription> <authCode>000000</authCode> <AVSResponse>X</AVSResponse> <cardCodeResponse>M</cardCodeResponse> <CAVVResponse>2</CAVVResponse> <FDSFilterAction>authAndHold</FDSFilterAction> <FDSFilters> <FDSFilter> <name>Hourly Velocity Filter</name> <action>authAndHold</action> </FDSFilter> <FDSFilter> <name>Amount Filter</name> <action>report</action> </FDSFilter> </FDSFilters> <batch> <batchId>12345</batchId> <settlementTimeUTC>2010-08-30T17:49:20.757Z</settlementTimeUTC> <settlementTimeLocal>2010-08-30T13:49:20.757</settlementTimeLocal> <settlementState>settledSuccessfully</settlementState> </batch> <order> <invoiceNumber>INV00001</invoiceNumber> <description>some description</description> <purchaseOrderNumber>PO000001</purchaseOrderNumber> </order> <requestedAmount>5.00</requestedAmount> <authAmount>2.00</authAmount> <settleAmount>2.00</settleAmount> <tax> <amount>1.00</amount> <name>WA state sales tax</name> <description>Washington state sales tax</description> </tax> <shipping> <amount>2.00</amount> <name>ground based shipping</name> <description>Ground based 5 to 10 day shipping</description> </shipping> <duty> <amount>1.00</amount> </duty> <lineItems> <lineItem> <itemId>ITEM00001</itemId> <name>name of item sold</name> <description>Description of item sold</description> <quantity>1</quantity> <unitPrice>6.95</unitPrice> <taxable>true</taxable> </lineItem> <lineItem> <itemId>ITEM00001</itemId> <name>name of item sold</name> <description>Description of item sold</description> <quantity>1</quantity> <unitPrice>6.95</unitPrice> <taxable>true</taxable> </lineItem> </lineItems> <prepaidBalanceRemaining>30.00</prepaidBalanceRemaining> <taxExempt>false</taxExempt> <payment> <!-- either creditCard or bankAccount will be here --> <creditCard> <cardNumber>XXXX1111</cardNumber> <expirationDate>XXXX</expirationDate> <accountType>Visa</accountType> </creditCard> <!--<bankAccount> <routingNumber>XXXX0000</routingNumber> <accountNumber>XXXX0000</accountNumber> <nameOnAccount>John Doe</nameOnAccount> <echeckType>WEB</echeckType> </bankAccount>--> </payment> <customer> <type>individual</type> <id>ABC00001</id> <email>mark@example.com</email> </customer> <billTo> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> <phoneNumber>000-000-0000</phoneNumber> <faxNumber></faxNumber> </billTo> <shipTo> <firstName>John</firstName> <lastName>Doe</lastName> <company></company> <address>123 Main St.</address> <city>Bellevue</city> <state>WA</state> <zip>98004</zip> <country>USA</country> </shipTo> <recurringBilling>false</recurringBilling> <customerIP>0.0.0.0</customerIP> <subscription> <id>145521</id> <paynum>1</paynum> <marketType>eCommerce</marketType> <product>Card Not Present</product> <returnedItems> <returnedItem> <id>2148878904</id> <dateUTC>2014-05-12T21:22:44Z</dateUTC> <dateLocal>2014-05-12T14:22:44</dateLocal> <code>R02</code> <description>Account Closed</description> </returnedItem> </returnedItems> <solution> <id>A1000004</id> <name>Shopping Cart</name> </solution> <mobileDeviceId>2354578983274523978</mobileDeviceId> </subscription> </transaction> </getTransactionDetailsResponse>'									
    };
}